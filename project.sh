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

    docker image ls "aljazmc/$image" -q | sort -u | xargs -r docker rmi -f

done

}

publish() {

failed=()

for dir in $DIRS; do

    image=$(image_name "$dir")

    ## only push images that build and pass their smoke test
    if ! (cd "$dir" && docker build . -t "aljazmc/$image"); then
        echo "aljazmc/$image: build failed, not pushing"
        failed+=("$image")
    elif ! tests/smoke_test.sh --no-build "$image"; then
        echo "aljazmc/$image: smoke test failed, not pushing"
        failed+=("$image")
    else
        docker tag "aljazmc/$image" "aljazmc/$image:latest"
        docker push -a "aljazmc/$image"
    fi

    docker image ls "aljazmc/$image" -q | sort -u | xargs -r docker rmi -f

    ## it's important to be nice
    sleep 30

done

if [ "${#failed[@]}" -gt 0 ]; then
    echo "not pushed: ${failed[*]}"
    exit 1
fi

}

if declare -F "$1" > /dev/null; then
    "$1"
else
    echo "Usage: $0 {clean|publish}"
    exit 1
fi
