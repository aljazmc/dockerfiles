#!/bin/bash
#
# Test for project.sh: runs `publish` with docker and sleep stubbed out and
# checks that
#   - exactly one image is built per Dockerfile directory, from the right
#     directory, under the right image name
#   - every image is pushed, except one whose smoke test fails
#   - publish exits non-zero when an image was not pushed
#
# Usage: tests/project_test.sh

set -euo pipefail

ROOT=$(cd "$(dirname "$0")/.." && pwd)
TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT

# The image whose smoke test is made to fail.
FAIL_SMOKE=x11-alpine

# Stub docker: record "<cwd> <args>" for every build and the image for every
# push, make `docker run` fail for $FAIL_SMOKE, ignore everything else.
mkdir -p "$TMP/bin"
cat > "$TMP/bin/docker" <<STUB
#!/bin/bash
case "\$1" in
    build) echo "\${PWD#$ROOT/} \$*" >> "$TMP/builds" ;;
    push)  echo "\${@: -1}" >> "$TMP/pushes" ;;
    run)   [[ " \$* " != *" aljazmc/$FAIL_SMOKE "* ]] ;;
esac
STUB
printf '#!/bin/sh\n' > "$TMP/bin/sleep"
chmod +x "$TMP/bin/docker" "$TMP/bin/sleep"
touch "$TMP/builds" "$TMP/pushes"

cd "$ROOT"
status=0
PATH="$TMP/bin:$PATH" ./project.sh publish > "$TMP/output" 2>&1 || status=$?

mapfile -t DIRS < <(git ls-files '*Dockerfile' | xargs -n1 dirname | sort)
failures=0

# Every directory with a Dockerfile, built as aljazmc/<dir with / -> ->.
for dir in "${DIRS[@]}"; do
    echo "$dir build . -t aljazmc/${dir//\//-}"
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

if [ "$status" -ne 0 ] && grep -q "not pushed: $FAIL_SMOKE" "$TMP/output"; then
    echo "PASS: exits $status and reports $FAIL_SMOKE as not pushed"
else
    echo "FAIL: expected a non-zero exit and 'not pushed: $FAIL_SMOKE', got exit $status:"
    tail -n 5 "$TMP/output"
    failures=$((failures + 1))
fi

[ "$failures" -eq 0 ]
