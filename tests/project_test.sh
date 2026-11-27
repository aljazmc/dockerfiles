#!/bin/bash
#
# Test for project.sh: runs `publish` with docker stubbed out and checks that
#   - exactly one multiarch image is built per Dockerfile directory, from the
#     right directory, under the right image name
#   - every image that builds is loaded for its smoke test, after the build
#     and before the smoke test, so it tests what was just built
#   - every image is pushed, except one that fails to build, which isn't
#     smoke-tested either, and one whose smoke test fails
#   - the version of every pushed image is read from the image
#   - every pushed image is tagged latest, <version> and <version>-<date>,
#     or latest and <date> when its version can't be read
#   - publish exits non-zero when an image was not pushed
#   - publish with image names publishes only those, and fails an unknown one
#   - an image whose build can't be loaded isn't smoke-tested or pushed, and
#     a failed push fails publish, both naming the image
#   - on a throwaway tree, an image that project.sh has no version for is
#     tagged latest and the date, without asking the image
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
    # the images whose load or push the last run makes fail
    [[ " \$* " == *" --load -t aljazmc/\${STUB_FAIL_LOAD:-none} "* ]] && exit 1
    [[ " \$* " == *" --push "* && " \$* " == *" aljazmc/\${STUB_FAIL_PUSH:-none}:"* ]] && exit 1
    if [[ " \$* " != *" --push "* ]]; then
        echo "\${PWD#$ROOT/} \$*" >> "$TMP/builds"
        echo "\$*" >> "$TMP/events"
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
            echo "smoke \$image" >> "$TMP/events"
        elif [[ " \$* " == *" --entrypoint sh "* ]]; then
            echo "aljazmc/\$image" >> "$TMP/versions"
        fi
        [[ " \$* " == *" --entrypoint sh aljazmc/$NO_VERSION "* ]] && exit 0
        echo "version 1.2.3"
        [[ " \$* " != *" aljazmc/$FAIL_SMOKE "* ]] ;;
esac
STUB
chmod +x "$TMP/bin/docker"
touch "$TMP/builds" "$TMP/tags" "$TMP/pushes" "$TMP/smoked" "$TMP/versions" "$TMP/events"

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
{ grep -- "--platform" "$TMP/builds" || true; } | sort > "$TMP/actual"
if diff -u "$TMP/expected" "$TMP/actual"; then
    echo "PASS: builds all ${#DIRS[@]} images from the right directories"
else
    echo "FAIL: builds differ from expected (see diff above)"
    failures=$((failures + 1))
fi

# Every image that built loaded from its own directory, except the one that
# failed to build, between its build and its smoke test.
for dir in "${DIRS[@]}"; do
    [ "${dir//\//-}" = "$FAIL_BUILD" ] && continue
    echo "$dir buildx build --load -t aljazmc/${dir//\//-} ."
done > "$TMP/expected"
{ grep -- "--load" "$TMP/builds" || true; } | sort > "$TMP/actual"
if diff -u "$TMP/expected" "$TMP/actual"; then
    echo "PASS: loads every image that built, for its smoke test"
else
    echo "FAIL: loads differ from expected (see diff above)"
    failures=$((failures + 1))
fi
ordered=yes
while read -r image; do
    built=$(grep -n -- "--platform .* -t aljazmc/$image \.\$" "$TMP/events" | head -n1 | cut -d: -f1 || true)
    loaded=$(grep -n -- "--load -t aljazmc/$image \.\$" "$TMP/events" | head -n1 | cut -d: -f1 || true)
    smoked=$(grep -nx "smoke $image" "$TMP/events" | head -n1 | cut -d: -f1 || true)
    [ -n "$built" ] && [ -n "$loaded" ] && [ -n "$smoked" ] &&
        [ "$built" -lt "$loaded" ] && [ "$loaded" -lt "$smoked" ] || ordered="no: $image"
done < <(sed -n 's/^smoke //p' "$TMP/events")
if [ "$ordered" = yes ]; then
    echo "PASS: smoke-tests every image after building and loading it"
else
    echo "FAIL: smoke-tests an image before building and loading it ($ordered)"
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

# publish with image names: only those, and an unknown one fails
: > "$TMP/builds"
: > "$TMP/pushes"
status=0
PATH="$TMP/bin:$PATH" ./project.sh publish node-alpine no-such-image > "$TMP/output" 2>&1 || status=$?
if [ "$(sort -u "$TMP/pushes")" = "aljazmc/node-alpine" ] &&
    ! grep -qv "aljazmc/node-alpine \.\$" "$TMP/builds" &&
    [ "$status" -ne 0 ] && grep -qx "not pushed: no-such-image" "$TMP/output"; then
    echo "PASS: publishes only the images given, and fails an unknown one"
else
    echo "FAIL: publish node-alpine no-such-image: exit $status, pushes $(paste -sd' ' "$TMP/pushes")"
    tail -n 5 "$TMP/output"
    failures=$((failures + 1))
fi

# a load and a push that fail
: > "$TMP/smoked"
status=0
STUB_FAIL_LOAD=node-alpine STUB_FAIL_PUSH=node-debian PATH="$TMP/bin:$PATH" \
    ./project.sh publish node-alpine node-debian > "$TMP/output" 2>&1 || status=$?
if grep -qx "aljazmc/node-alpine: loading the build failed, not pushing" "$TMP/output" &&
    ! grep -qx "node-alpine" "$TMP/smoked" &&
    grep -qx "aljazmc/node-debian: push failed" "$TMP/output" &&
    [ "$status" -ne 0 ] && grep -qx "not pushed: node-alpine node-debian" "$TMP/output"; then
    echo "PASS: a failed load stops the smoke test and the push, a failed push fails publish"
else
    echo "FAIL: publish with a failing load and push: exit $status"
    tail -n 5 "$TMP/output"
    failures=$((failures + 1))
fi

# an image without a version rule, on a throwaway tree whose smoke test passes
TREE="$TMP/tree"
mkdir -p "$TREE/tests" "$TREE/other/alpine"
echo "FROM scratch" > "$TREE/other/alpine/Dockerfile"
printf '#!/bin/sh\nexit 0\n' > "$TREE/tests/smoke_test.sh"
chmod +x "$TREE/tests/smoke_test.sh"
: > "$TMP/tags"
: > "$TMP/versions"
status=0
DOCKERFILES_DIR="$TREE" PATH="$TMP/bin:$PATH" "$ROOT/project.sh" publish other-alpine \
    > "$TMP/output" 2>&1 || status=$?
if [ "$status" -eq 0 ] && [ ! -s "$TMP/versions" ] &&
    [ "$(sort "$TMP/tags" | paste -sd' ')" = "aljazmc/other-alpine:$DATE aljazmc/other-alpine:latest" ]; then
    echo "PASS: tags an image without a version rule latest and $DATE, without asking it"
else
    echo "FAIL: an image without a version rule: exit $status, tags $(paste -sd' ' "$TMP/tags")"
    failures=$((failures + 1))
fi

[ "$failures" -eq 0 ]
