#!/bin/bash
#
# Test for tests/quickstart.sh, with docker stubbed out. It runs a copy of
# the script in a throwaway repository of fake READMEs and checks that
#   - the setup comment, the ```sh block and the check comment of the
#     "## Quick start" section run in that order, in one empty directory
#   - only the first ```sh block of that section runs, nothing outside it
#   - `docker run -it` runs as `docker run -i`, with nothing on its input
#   - a failing command or check fails the README, and the run, and names it
#   - a README without a quick start fails
#   - an image name stands for the README of its directory
#
# Usage: tests/quickstart_test.sh

# shellcheck source=tests/lib.sh
. "$(dirname "$0")/lib.sh"

REPO="$TMP/repo"
mkdir -p "$REPO/tests" "$REPO/tool/alpine" "$TMP/bin"
cp "$ROOT/tests/quickstart.sh" "$REPO/tests/"

# Stub docker: record the arguments, and with -i, as docker reads its input
# only then, what was on it.
cat > "$TMP/bin/docker" <<STUB
#!/bin/bash
input=""
[[ " \$* " == *" -i "* ]] && input=\$(cat)
echo "\$* | stdin: \${input:-empty}" >> "$TMP/calls"
STUB
chmod +x "$TMP/bin/docker"

# a README whose quick start makes files, and checks them
cat > "$REPO/README.md" <<'EOF'
# Example

```sh
touch outside-the-section
```

## Quick start

<!-- quickstart setup
pwd > setup-ran-in
touch input.txt
-->

```sh
# the setup made input.txt here
test -f input.txt
docker run --rm -it aljazmc/tool-alpine sh
cp input.txt output.txt
```

```sh
touch second-block
```

<!-- quickstart check
test -f output.txt
test "$(cat setup-ran-in)" = "$PWD"
test ! -e outside-the-section
test ! -e second-block
-->

## Next section

```sh
touch after-the-section
```
EOF

# an image README whose check fails
cat > "$REPO/tool/alpine/README.md" <<'EOF'
# aljazmc/tool-alpine

## Quick start

```sh
touch made.txt
```

<!-- quickstart check
test -f missing.txt
-->
EOF
echo "FROM scratch" > "$REPO/tool/alpine/Dockerfile"

# a README without a quick start
printf '# Nothing\n\n## Usage\n\nNone.\n' > "$REPO/NOTHING.md"

(cd "$REPO" && git init -q && git add -A)

# quickstart <arguments...>: run it, set $status
quickstart() {
    : > "$TMP/calls"
    status=0
    PATH="$TMP/bin:$PATH" "$REPO/tests/quickstart.sh" "$@" > "$TMP/output" 2>&1 || status=$?
}

quickstart README.md
check "runs the setup, the block and the check of the quick start" \
    grep -qx "    PASS" "$TMP/output"
check "exits 0 when the quick start works" [ "$status" -eq 0 ]
check "runs docker run -it as docker run -i, with nothing on its input" \
    grep -qx "run --rm -i aljazmc/tool-alpine sh | stdin: empty" "$TMP/calls"
check "shows every command it runs" grep -qxF '    | cp input.txt output.txt' "$TMP/output"

quickstart tool-alpine
check "an image name stands for the README of its directory" \
    grep -qx "==> tool/alpine/README.md" "$TMP/output"
check "a failing check fails the README" grep -qx "    FAIL: the check exited with 1" "$TMP/output"
fails_the_run() {
    [ "$status" -eq 1 ] && grep -qx "  failed: tool/alpine/README.md" "$TMP/output"
}
check "and the run, naming the README" fails_the_run

quickstart NOTHING.md
no_quick_start() {
    [ "$status" -eq 1 ] && grep -q 'no ```sh block in a "## Quick start" section' "$TMP/output"
}
check "a README without a quick start fails" no_quick_start

quickstart no-such-image
check "an unknown image fails" \
    grep -q "no directory with a Dockerfile for this image" "$TMP/output"

quickstart README.md tool-alpine
check "counts the passed and the failed READMEs" grep -qx "1 passed, 1 failed" "$TMP/output"

finish
