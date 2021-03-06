#!/bin/sh

#
# user_project_updated.sh
#
# Developed by Dinesh Dharmalingam
#
# Changelog:
# 2019-03-06 - created
#
# Script to check if the users home directory contains PAMS in its path name has a 
# modified file in the last n number of days (default 7 days)

# Optional number of days argument
n_days=${1:-7};
users=$(cat /etc/passwd | cut -f 1 -d ':' | sort | uniq)
RED='\033[01;31m'
GREEN='\033[01;32m'

for u in $users
do
	dir="/home/$u"
	if [ -e $dir ]
	then
		# Find if a directory path contains PAMS got modified file in last n_days
		# Check only for perl, css, html, javascript files
		modified=$(find $dir -path '*PAMS*' \( ! -regex '.*/\..*' \) \
			\( -name '*.pm' -o -name '*.pl' -o -name '*.js' -o -name '*.tt' \
			-o -name '*.css' -o -name '*.t' -o -name '*.scss' -o -name '*.xml' \
			-o -name '*.java' -o -name '*.class' -o -name '*.h' -o -name '*.m' \
			\) \
			-type f -mtime -$n_days -exec stat -c '%U' {} \; -quit)
		if [ $modified ]
		then
			echo -e "${GREEN}$u Done!"
		else
			echo -e "${RED}$u Not done a backup in last $n_days day(s)"
		fi
	fi
done

# Re-init the terminal default colors
tput init
