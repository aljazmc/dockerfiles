#!/bin/bash

cd "$(dirname "$0")" || exit 1

## every directory containing a Dockerfile, e.g. "godot/buildforlinux"
DIRS=$(
    find . -name Dockerfile -not -path './.git/*' -exec dirname {} \; |
    sed 's/^\.\///' |
    sort
)

## image name is the directory path with "/" replaced by "-"
image_name() {
    echo "${1//\//-}"
}

clean() {

for dir in $DIRS; do

    image=$(image_name "$dir")

    docker image ls aljazmc/$image -q | sort -u | xargs -r docker rmi -f

done

}

publish() {

for dir in $DIRS; do

    image=$(image_name "$dir")

    (
        cd "$dir" || exit 1
        docker build . -t aljazmc/$image
        docker tag aljazmc/$image aljazmc/$image:latest
        docker push -a aljazmc/$image
        docker image ls aljazmc/$image -q | sort -u | xargs -r docker rmi -f
    )

    ## it's important to be nice
    sleep 30

done

}

if declare -F "$1" > /dev/null; then
    "$1"
else
    echo "Usage: $0 {clean|publish}"
    exit 1
fi
