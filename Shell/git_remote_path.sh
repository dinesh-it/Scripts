#!/bin/bash

REPO=`git rev-parse --show-toplevel`

if [[ $? -ne 0 ]]
then
    echo "Not in git repo"
    exit 1
fi

file=${1:-''};
remote=${2:-'origin'};

git_branch=`git rev-parse --abbrev-ref HEAD 2>/dev/null`
relative_path=`git rev-parse --show-prefix|sed "s/\/$//"`

GIT_REMOTE_URL_UNFINISHED=`git config --get remote.$remote.url|sed -s "s/^ssh/http/; s/git@//; s/.git$//;" | sed -s "s/:/\//;"`
GIT_REMOTE_URL="$(dirname $GIT_REMOTE_URL_UNFINISHED)/$(basename $GIT_REMOTE_URL_UNFINISHED)"

git_branch_in_url=`echo $git_branch| sed 's/\//%2F/g'`
echo "https://${GIT_REMOTE_URL}/tree/$git_branch_in_url/$relative_path/$file"
