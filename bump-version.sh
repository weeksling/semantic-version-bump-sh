#!/bin/bash

find_latest_semver() {
  pattern="^v([0-9]+\.[0-9]+\.[0-9]+)\$"
  versions=$(for tag in $(git tag); do
    [[ "$tag" =~ $pattern ]] && echo "${BASH_REMATCH[1]}"
  done)
  if [ -z "$versions" ];then
    echo 0.0.0
  else
    echo "$versions" | tr '.' ' ' | sort -nr -k 1 -k 2 -k 3 | tr ' ' '.' | head -1
  fi
}

# Arguments: $1=current_version
determine_bump_from_commits() {
    log=$(git log v$1..HEAD)
    
    MAJOR=0
    MINOR=0
    PATCH=0

    ## Check commit bodies for "BREAKING CHANGE"
    if [[ "$log" =~ "BREAKING CHANGE" ]]; then
        MAJOR=1
    fi
    # Check commit heading for commit type
    for commit in $(git log --format="%s" v$1..HEAD); do
        if [[ "$commit" =~ ^feat(\(.+\):|:) ]]; then
            MINOR=1
        elif [[ "$commit" =~ ^(fix|chore|docs|perf|refactor|test|style)(\(.+\):|:) ]]; then
            PATCH=1
        fi
    done
    
    if [ $MAJOR == 1 ]; then
        echo 3
    elif [ $MINOR == 1 ]; then
        echo 2
    elif [ $PATCH == 1 ]; then
        echo 1
    else echo 0
    fi
}

# Versions: $1=bump_type(0=nothing, 1=patch, 2=minor, 3=major), $2=current_version
bump() {
    if [ "$1" == "3" ]; then
        echo $2 | awk -F. \
            '{printf("v%d.%d.%d", $1+1, 0 , 0)}'
    elif [ "$1" == "2" ]; then
        echo $2 | awk -F. \
            '{printf("v%d.%d.%d", $1, $2+1, 0)}'
    elif [ "$1" == "1" ]; then
        echo $2 | awk -F. \
            '{printf("v%d.%d.%d", $1, $2 , $3+1)}'
    fi
}


LAST_VERSION=$(find_latest_semver)
BUMP=$(determine_bump_from_commits $LAST_VERSION)
echo $(bump $BUMP $LAST_VERSION)
exit 0
