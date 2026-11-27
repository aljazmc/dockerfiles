#!/bin/bash
#
# Test for project.sh: runs `publish` with docker stubbed out and checks that
#   - exactly one multiarch image is built per Dockerfile directory, from the
#     right directory, under the right image name
#   - every image is pushed, except one that fails to build, which isn't
#     smoke-tested either, and one whose smoke test fails
#   - the version of every pushed image is read from the image
#   - every pushed image is tagged latest, <version> and <version>-<date>,
#     or latest and <date> when its version can't be read
#   - publish exits non-zero when an image was not pushed
#
# Usage: tests/project_test.sh

set -euo pipefail

ROOT=$(cd "$(dirname "$0")/.." && pwd)
TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT

# The image whose build is made to fail.
FAIL_BUILD=wine-alpine
# The image whose smoke test is made to fail.
FAIL_SMOKE=x11-alpine
# The image whose version can't be read.
NO_VERSION="image-spinner"

# Stub docker: record "<cwd> <args>" for every `buildx build` and fail it for
# $FAIL_BUILD, and for every `buildx build --push` record the image it pushes
# and each of its tags instead; record the image of every `docker run`, as a
# version query or a smoke test, make it report version 1.2.3 (nothing for
# the version of $NO_VERSION) and fail the smoke test of $FAIL_SMOKE; ignore
# everything else.
mkdir -p "$TMP/bin"
cat > "$TMP/bin/docker" <<STUB
#!/bin/bash
if [ "\$1 \$2" = "buildx build" ]; then
    if [[ " \$* " != *" --push "* ]]; then
        echo "\${PWD#$ROOT/} \$*" >> "$TMP/builds"
        [[ " \$* " != *" -t aljazmc/$FAIL_BUILD "* ]]
        exit
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
        for arg in "\$@"; do
            [[ "\$arg" == aljazmc/* ]] && image=\${arg#aljazmc/} && break
        done
        # the smoke test's check starts with its helpers, a version query not
        if [[ "\${*: -1}" == *"need()"* ]]; then
            echo "\$image" >> "$TMP/smoked"
        elif [[ " \$* " == *" --entrypoint sh "* ]]; then
            echo "aljazmc/\$image" >> "$TMP/versions"
        fi
        [[ " \$* " == *" --entrypoint sh aljazmc/$NO_VERSION "* ]] && exit 0
        echo "version 1.2.3"
        [[ " \$* " != *" aljazmc/$FAIL_SMOKE "* ]] ;;
esac
STUB
chmod +x "$TMP/bin/docker"
touch "$TMP/builds" "$TMP/tags" "$TMP/pushes" "$TMP/smoked" "$TMP/versions"

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

# Every image pushed, except the one that failed to build and the one that
# failed its smoke test.
for dir in "${DIRS[@]}"; do
    echo "aljazmc/${dir//\//-}"
done | grep -vx -e "aljazmc/$FAIL_BUILD" -e "aljazmc/$FAIL_SMOKE" > "$TMP/expected"
sort "$TMP/pushes" > "$TMP/actual"
if diff -u "$TMP/expected" "$TMP/actual"; then
    echo "PASS: pushes every image except $FAIL_BUILD, which failed to build, and $FAIL_SMOKE, whose smoke test failed"
else
    echo "FAIL: pushes differ from expected (see diff above)"
    failures=$((failures + 1))
fi

# An image that failed to build is not smoke-tested.
if grep -qx "$FAIL_BUILD" "$TMP/smoked"; then
    echo "FAIL: smoke-tests $FAIL_BUILD, which failed to build"
    failures=$((failures + 1))
else
    echo "PASS: doesn't smoke-test $FAIL_BUILD, which failed to build"
fi

# The version of every pushed image read from the image, and of no other.
sort -u "$TMP/versions" > "$TMP/actual"
if diff -u "$TMP/expected" "$TMP/actual"; then
    echo "PASS: reads the version of every pushed image"
else
    echo "FAIL: version queries differ from the pushed images (see diff above)"
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

if [ "$status" -ne 0 ] && grep -qx "not pushed: $FAIL_BUILD $FAIL_SMOKE" "$TMP/output"; then
    echo "PASS: exits $status and reports $FAIL_BUILD and $FAIL_SMOKE as not pushed"
else
    echo "FAIL: expected a non-zero exit and 'not pushed: $FAIL_BUILD $FAIL_SMOKE', got exit $status:"
    tail -n 5 "$TMP/output"
    failures=$((failures + 1))
fi

[ "$failures" -eq 0 ]
