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
    # shellcheck disable=SC2016 # heaps-*: expanded inside the container
    case "$1" in
        actions-alpine)  cmd='cat /etc/alpine-release' ;;
        actions-debian)  cmd='cat /etc/debian_version' ;;
        blender-*)       cmd='blender --version' ;;
        corepack-*)      cmd='corepack --version' ;;
        fluidsynth-*)    cmd='fluidsynth --version' ;;
        godot-*)         cmd='godot --headless --version' ;;
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

## multiarch dependencies
docker run --privileged --rm tonistiigi/binfmt --install all

## build date (UTC), the same for every image of this run, e.g. "20261122"
date=$(date -u +%Y%m%d)

for dir in $DIRS; do

    image=$(image_name "$dir")

    ## only push images that build and pass their smoke test
    if ! (cd "$dir" && docker buildx build --platform linux/amd64,linux/arm64 -t "aljazmc/$image" . ); then
        echo "aljazmc/$image: build failed, not pushing"
        failed+=("$image")
    elif ! tests/smoke_test.sh --no-build "$image"; then
        echo "aljazmc/$image: smoke test failed, not pushing"
        failed+=("$image")
    else
        docker buildx imagetools create -t "aljazmc/$image:latest" "aljazmc/$image"
        tag=$(version "$image")
        if [ -n "$tag" ]; then
            docker buildx imagetools create -t "aljazmc/$image:$tag" "aljazmc/$image"
            ## e.g. "5.2.4-20261122", a tag that always points to this build
            docker buildx imagetools create -t "aljazmc/$image:$tag-$date" "aljazmc/$image"
        else
            docker buildx imagetools create -t "aljazmc/$image:$date" "aljazmc/$image"
        fi
	( \
            cd "$dir" && \
            docker buildx build \
            --platform linux/amd64,linux/arm64 \
            --push \
            -t "aljazmc/$image" \
            -t "aljazmc/$image:$tag" \
            -t "aljazmc/$image:$tag-$date" \
            -t "aljazmc/$image:latest" \
	    . \
        )
    fi

    docker image ls "aljazmc/$image" -q | sort -u | xargs -r docker rmi -f
done

if [ "${#failed[@]}" -gt 0 ]; then
    echo "not pushed: ${failed[*]}"
    exit 1
fi

}

## write an SBOM of every image (or of the given images, e.g. "x11-alpine") to
## sbom/<image>.cdx.json and list its HIGH and CRITICAL vulnerabilities, using
## the Trivy image, so nothing has to be installed; scans the local image, or
## pulls it from Docker Hub if it isn't there
##
##   SEVERITY=CRITICAL ./project.sh scan       only list CRITICAL vulnerabilities
##   IGNORE_UNFIXED=1 ./project.sh scan        skip vulnerabilities without a fix
scan() {

TRIVY=aquasec/trivy:0.76.2
SEVERITY=${SEVERITY:-HIGH,CRITICAL}
unfixed=()
[ -n "${IGNORE_UNFIXED:-}" ] && unfixed=(--ignore-unfixed)
CACHE=${XDG_CACHE_HOME:-$HOME/.cache}/trivy
mkdir -p sbom "$CACHE"

if [ "$#" -gt 0 ]; then
    images=("$@")
else
    mapfile -t images < <(for dir in $DIRS; do image_name "$dir"; done)
fi

trivy() {
    docker run --rm \
        --user "$(id -u):$(id -g)" \
        --group-add "$(stat -c %g /var/run/docker.sock)" \
        -v /var/run/docker.sock:/var/run/docker.sock \
        -v "$CACHE:/cache" \
        -v "$PWD/sbom:/sbom" \
        "$TRIVY" --cache-dir /cache --quiet "$@"
}

failed=()
vulnerable=()

for image in "${images[@]}"; do

    echo "==> aljazmc/$image"

    if ! trivy image --format cyclonedx --output "/sbom/$image.cdx.json" "aljazmc/$image"; then
        echo "aljazmc/$image: SBOM failed"
        failed+=("$image")
        continue
    fi
    echo "SBOM: sbom/$image.cdx.json"

    if ! trivy sbom --scanners vuln --severity "$SEVERITY" "${unfixed[@]}" --exit-code 1 "/sbom/$image.cdx.json"; then
        vulnerable+=("$image")
    fi

done

[ "${#vulnerable[@]}" -gt 0 ] && echo "$SEVERITY vulnerabilities in: ${vulnerable[*]}"
[ "${#failed[@]}" -gt 0 ] && echo "not scanned: ${failed[*]}"
[ "${#vulnerable[@]}" -eq 0 ] && [ "${#failed[@]}" -eq 0 ]

}

if declare -F "$1" > /dev/null; then
    "$@"
else
    echo "Usage: $0 {clean|publish|scan [image...]}"
    exit 1
fi
