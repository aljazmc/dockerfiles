#!/bin/bash
#
# Test for project.sh: runs `publish` with docker and sleep stubbed out and
# checks that exactly one image is built per Dockerfile directory, from the
# right directory, under the right image name.
#
# Usage: tests/project_test.sh

set -euo pipefail

ROOT=$(cd "$(dirname "$0")/.." && pwd)
TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT

# Stub docker: record "<cwd> <args>" for every build, ignore everything else.
mkdir -p "$TMP/bin"
cat > "$TMP/bin/docker" <<STUB
#!/bin/bash
if [ "\$1" = build ]; then
    echo "\${PWD#$ROOT/} \$*" >> "$TMP/builds"
fi
STUB
printf '#!/bin/sh\n' > "$TMP/bin/sleep"
chmod +x "$TMP/bin/docker" "$TMP/bin/sleep"
touch "$TMP/builds"

cd "$ROOT"
PATH="$TMP/bin:$PATH" ./project.sh publish > /dev/null

# Expected: every directory with a Dockerfile, built as aljazmc/<dir with / -> ->.
git ls-files '*Dockerfile' | xargs -n1 dirname | sort |
    while read -r dir; do
        echo "$dir build . -t aljazmc/${dir//\//-}"
    done > "$TMP/expected"

sort "$TMP/builds" > "$TMP/actual"

if diff -u "$TMP/expected" "$TMP/actual"; then
    echo "PASS: project.sh publish builds $(wc -l < "$TMP/expected") images correctly"
else
    echo "FAIL: project.sh publish builds differ from expected (see diff above)"
    exit 1
fi
