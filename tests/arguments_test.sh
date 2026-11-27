#!/bin/bash
#
# Bad input is rejected: project.sh without a command, with an unknown
# command or with one of its helpers (version, image_name) prints its usage
# and exits 1, and tests/smoke_test.sh fails an image that doesn't exist,
# all without calling docker. And `project.sh clean` removes the images of
# every directory with a Dockerfile, and nothing else.
#
# Usage: tests/arguments_test.sh

# shellcheck source=tests/lib.sh
. "$(dirname "$0")/lib.sh"

# Stub docker: record every call; `image ls aljazmc/<image> -q` lists one id
# for that image.
mkdir -p "$TMP/bin"
cat > "$TMP/bin/docker" <<STUB
#!/bin/bash
echo "\$*" >> "$TMP/calls"
if [ "\$1 \$2" = "image ls" ]; then
    echo "id-\${3#aljazmc/}"
fi
exit 0
STUB
chmod +x "$TMP/bin/docker"

# rejects <description> <expected output> <command...>: exits 1, prints the
# expected output and never calls docker
rejects() {
    local description=$1 expected=$2 status=0
    shift 2
    : > "$TMP/calls"
    (cd "$ROOT" && PATH="$TMP/bin:$PATH" "$@") > "$TMP/output" 2>&1 || status=$?
    if [ "$status" -ne 1 ]; then
        fail "$description: expected exit 1, got $status"
    elif ! grep -qF -- "$expected" "$TMP/output"; then
        fail "$description: expected '$expected' in: $(head -n3 "$TMP/output")"
    elif [ -s "$TMP/calls" ]; then
        fail "$description: called docker: $(head -n1 "$TMP/calls")"
    else
        pass "$description"
    fi
}

rejects "project.sh without a command" "Usage:" ./project.sh
rejects "project.sh with an unknown command" "Usage:" ./project.sh deploy
rejects "project.sh with the helper image_name" "Usage:" \
    ./project.sh image_name foo/bar
rejects "project.sh with the helper version" "Usage:" \
    ./project.sh version x11-alpine
rejects "smoke_test.sh with an image that doesn't exist" \
    "no directory with a Dockerfile" tests/smoke_test.sh --no-build no-such-image
rejects "smoke_test.sh with a directory that isn't an image" \
    "no directory with a Dockerfile" tests/smoke_test.sh --no-build tests

# clean lists the images of every directory and removes exactly those
: > "$TMP/calls"
status=0
(cd "$ROOT" && PATH="$TMP/bin:$PATH" ./project.sh clean) > "$TMP/output" 2>&1 || status=$?
check "project.sh clean exits 0" [ "$status" -eq 0 ]
images | sed 's/^/rmi -f id-/' > "$TMP/expected"
grep '^rmi ' "$TMP/calls" | sort > "$TMP/actual"
if diff -u "$TMP/expected" "$TMP/actual"; then
    pass "project.sh clean removes the images of all $(wc -l < "$TMP/expected") directories"
else
    fail "project.sh clean removes other images than expected (see diff above)"
fi

finish
