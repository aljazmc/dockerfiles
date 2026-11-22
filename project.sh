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

## version of the software the image is named after, read from the built
## image, e.g. "5.2.3" for blender-alpine; prints nothing if it can't tell
version() {
    case "$1" in
        blender-*)       cmd='blender --version' ;;
        corepack-*)      cmd='corepack --version' ;;
        fluidsynth-*)    cmd='fluidsynth --version' ;;
        godot-*)         cmd='godot --headless --version' ;;
        # shellcheck disable=SC2016 # expanded inside the container
        heaps-*)         cmd='echo "$HEAPS_VERSION"' ;;
        image-spinner)   cmd='cat /etc/alpine-release' ;;
        inkscape-*)      cmd='inkscape --version' ;;
        wine-*)          cmd='wine --version' ;;
        x11-*)           cmd='apk list -I libx11 || dpkg-query -W libx11-6' ;;
        *)               return ;;
    esac
    docker run --rm --entrypoint sh "aljazmc/$1" -c "$cmd" 2> /dev/null |
        grep -oE '[0-9]+(\.[0-9]+)+' | head -n1
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
        tag=$(version "$image") && [ -n "$tag" ] && docker tag "aljazmc/$image" "aljazmc/$image:$tag"
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
