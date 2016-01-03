#!/bin/sh

# Script to automatically import sources from http://www.ch-werner.de/sqliteodbc/ into this git repo
# The import-tars.perl script is a modified version of http://git.kernel.org/cgit/git/git.git/tree/contrib/fast-import/import-tars.perl?id=2a94552887ecbaa8b848a92eb607e032d77c8a2c
# to remove the common root directory to be able to do the cherry-pick (as the .tar.gz downloaded always contains a root directory named like "sqliteodbc-0.xxx/")

set -e

base_url=http://www.ch-werner.de/sqliteodbc/

update_source() {
	local version="$1"
	local tagname="sqliteodbc-${version}"
	local tarname="${tagname}.tar.gz"
	local url="${base_url}${tarname}"
	
	curl "$url" > "$tarname"
	
	GIT_AUTHOR_NAME='Christian Werner' GIT_AUTHOR_EMAIL='chw@ch-werner.de' perl import-tars.perl "$tarname"
	
	git cherry-pick -Xtheirs "$tagname" &&
	git branch -D import-tars &&
	git tag -d "$tagname"
	rm "$tarname"
}

current_version=$(cat ../VERSION)
echo current version : $current_version

versions=$(curl -s $base_url  | sed -nre 's/[[:space:]]*<A HREF="sqliteodbc-([^\r\n"]+)\.tar\.gz">.*/\1/pg' | uniq | sed -n "/${current_version}/q;p")

echo "$versions" | sed '1!G;h;$!d' | while read x; do
	if [ ! -z "$x" ]; then
		update_source "$x"
	fi
done
