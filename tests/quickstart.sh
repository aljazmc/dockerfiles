#!/bin/bash
#
# Runs the quick start of READMEs, to check that it works as written: the
# first ```sh block of the "## Quick start" section, in an empty directory,
# with the images from Docker Hub. Each README passes when every command of
# its block succeeds and its checks hold.
#
# Two HTML comments in the section, which GitHub doesn't show, help:
#   <!-- quickstart setup ... -->   commands run before the block, to make
#                                   the sample files it uses, e.g. scene.blend
#   <!-- quickstart check ... -->   commands run after it, to check that it
#                                   made what it promises, e.g. test -s out.png
#
# There is no terminal in CI, so `docker run -it` runs as `docker run -i`
# with nothing on its input: a shell it starts exits at once.
#
# Usage: tests/quickstart.sh [README.md | image...]    default: README.md
#   an image, e.g. x11-alpine, stands for its README, x11/alpine/README.md

set -uo pipefail

ROOT=$(cd "$(dirname "$0")/.." && pwd)
cd "$ROOT" || exit 1
[ "$#" -gt 0 ] || set -- README.md

TMP=$(mktemp -d)
trap 'cleanup; rm -rf "$TMP"' EXIT

# the containers' users have uid 1000, which may not be ours: let them write
# to the work directory, and remove what they leave from inside a container
cleanup() {
    [ -d "$TMP/work" ] || return 0
    docker run --rm -v "$TMP/work:/work" alpine:3.24.4 \
        sh -c 'rm -rf /work/* /work/.[!.]*' > /dev/null 2>&1
    rm -rf "$TMP/work"
}

# section <README> <name>: the lines of the comment "<!-- quickstart <name>"
# or, for "block", of the first ```sh block, in the "## Quick start" section
section() {
    awk -v want="$2" '
        /^## / { inside = ($0 == "## Quick start") }
        !inside { next }
        $0 == "<!-- quickstart " want { comment = 1; next }
        comment && $0 == "-->" { comment = 0; next }
        comment { print; next }
        want == "block" && !done && $0 == "```sh" { block = 1; next }
        block && $0 == "```" { block = 0; done = 1; next }
        block { print }
    ' "$1"
}

failed=()

for readme in "$@"; do

    # an image name: the README of its directory
    if [[ "$readme" != *.md ]]; then
        dir=$(git ls-files '*Dockerfile' | xargs -n1 dirname |
            while read -r d; do [ "${d//\//-}" = "$readme" ] && echo "$d"; done)
        if [ -z "$dir" ]; then
            echo "==> $readme"
            echo "    no directory with a Dockerfile for this image"
            failed+=("$readme")
            continue
        fi
        readme="$dir/README.md"
    fi

    echo "==> $readme"
    section "$readme" block > "$TMP/block.sh"
    if [ ! -s "$TMP/block.sh" ]; then
        echo "    no \`\`\`sh block in a \"## Quick start\" section"
        failed+=("$readme")
        continue
    fi
    section "$readme" setup > "$TMP/setup.sh"
    section "$readme" check > "$TMP/check.sh"
    sed -i -E 's/(docker( compose)? (run|exec)[^#]*) -(it|ti)( |$)/\1 -i\5/' "$TMP/block.sh"

    cleanup
    mkdir -p "$TMP/work"
    chmod 0777 "$TMP/work"

    status=0
    for part in setup block check; do
        [ -s "$TMP/$part.sh" ] || continue
        # every line is shown as it runs, comments too, all of it indented;
        # -v, not -x, since kcov traces with xtrace when it measures coverage
        (cd "$TMP/work" && bash -euvo pipefail "$TMP/$part.sh") \
            < /dev/null 2>&1 | sed 's/^/    | /'
        status=${PIPESTATUS[0]}
        if [ "$status" -ne 0 ]; then
            echo "    FAIL: the $part exited with $status"
            break
        fi
    done
    if [ "$status" -eq 0 ]; then
        echo "    PASS"
    else
        failed+=("$readme")
    fi

done

echo
echo "$(( $# - ${#failed[@]} )) passed, ${#failed[@]} failed"
if [ "${#failed[@]}" -gt 0 ]; then
    printf '  failed: %s\n' "${failed[@]}"
    exit 1
fi
