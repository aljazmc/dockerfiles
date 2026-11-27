#!/bin/bash
#
# Test for project.sh: runs `publish` with docker stubbed out and checks that
#   - exactly one multiarch image is built per Dockerfile directory, from the
#     right directory, under the right image name
#   - every image is pushed, except one whose smoke test fails
#   - every pushed image is tagged latest, <version> and <version>-<date>,
#     or latest and <date> when its version can't be read
#   - publish exits non-zero when an image was not pushed
#
# Usage: tests/project_test.sh

set -euo pipefail

ROOT=$(cd "$(dirname "$0")/.." && pwd)
TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT

# The image whose smoke test is made to fail.
FAIL_SMOKE=x11-alpine
# The image whose version can't be read.
NO_VERSION="image-spinner"

# Stub docker: record "<cwd> <args>" for every `buildx build`, and for every
# `buildx build --push` the image it pushes and each of its tags instead; make
# `docker run` report version 1.2.3 (nothing for the version of $NO_VERSION)
# and fail for $FAIL_SMOKE, ignore everything else.
mkdir -p "$TMP/bin"
cat > "$TMP/bin/docker" <<STUB
#!/bin/bash
if [ "\$1 \$2" = "buildx build" ]; then
    if [[ " \$* " != *" --push "* ]]; then
        echo "\${PWD#$ROOT/} \$*" >> "$TMP/builds"
        exit 0
    fi
    args=("\$@")
    for i in "\${!args[@]}"; do
        [ "\${args[i]}" = -t ] && echo "\${args[i + 1]}" >> "$TMP/tags"
    done
    for i in "\${!args[@]}"; do
        [ "\${args[i]}" = -t ] && { echo "\${args[i + 1]%%:*}" >> "$TMP/pushes"; break; }
    done
    exit 0
fi
case "\$1" in
    run)
        [[ " \$* " == *" --entrypoint sh aljazmc/$NO_VERSION "* ]] && exit 0
        echo "version 1.2.3"
        [[ " \$* " != *" aljazmc/$FAIL_SMOKE "* ]] ;;
esac
STUB
chmod +x "$TMP/bin/docker"
touch "$TMP/builds" "$TMP/tags" "$TMP/pushes"

cd "$ROOT"
status=0
PATH="$TMP/bin:$PATH" ./project.sh publish > "$TMP/output" 2>&1 || status=$?
DATE=$(date -u +%Y%m%d)

mapfile -t DIRS < <(git ls-files '*Dockerfile' | xargs -n1 dirname | sort)
failures=0

# Every directory with a Dockerfile, built as aljazmc/<dir with / -> ->.
for dir in "${DIRS[@]}"; do
    echo "$dir buildx build --platform linux/amd64,linux/arm64 -t aljazmc/${dir//\//-} ."
done > "$TMP/expected"
sort "$TMP/builds" > "$TMP/actual"
if diff -u "$TMP/expected" "$TMP/actual"; then
    echo "PASS: builds all ${#DIRS[@]} images from the right directories"
else
    echo "FAIL: builds differ from expected (see diff above)"
    failures=$((failures + 1))
fi

# Every image pushed, except the one that failed its smoke test.
for dir in "${DIRS[@]}"; do
    echo "aljazmc/${dir//\//-}"
done | grep -vx "aljazmc/$FAIL_SMOKE" > "$TMP/expected"
sort "$TMP/pushes" > "$TMP/actual"
if diff -u "$TMP/expected" "$TMP/actual"; then
    echo "PASS: pushes every image except $FAIL_SMOKE, whose smoke test failed"
else
    echo "FAIL: pushes differ from expected (see diff above)"
    failures=$((failures + 1))
fi

# Every pushed image tagged latest, with its version and with version-date,
# or with the date alone when there is no version.
while read -r image; do
    if [ "$image" = "aljazmc/$NO_VERSION" ]; then
        printf '%s\n' "$image:latest" "$image:$DATE"
    else
        printf '%s\n' "$image:latest" "$image:1.2.3" "$image:1.2.3-$DATE"
    fi
done < "$TMP/expected" | sort > "$TMP/expected-tags"
sort "$TMP/tags" > "$TMP/actual"
if diff -u "$TMP/expected-tags" "$TMP/actual"; then
    echo "PASS: tags every pushed image latest, 1.2.3 and 1.2.3-$DATE, $NO_VERSION latest and $DATE"
else
    echo "FAIL: tags differ from expected (see diff above)"
    failures=$((failures + 1))
fi

if [ "$status" -ne 0 ] && grep -q "not pushed: $FAIL_SMOKE" "$TMP/output"; then
    echo "PASS: exits $status and reports $FAIL_SMOKE as not pushed"
else
    echo "FAIL: expected a non-zero exit and 'not pushed: $FAIL_SMOKE', got exit $status:"
    tail -n 5 "$TMP/output"
    failures=$((failures + 1))
fi

[ "$failures" -eq 0 ]
