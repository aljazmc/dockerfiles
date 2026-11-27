#!/bin/bash
#
# Test for tests/smoke_test.sh, with docker stubbed out, so it needs no
# images and runs in CI. It checks that
#   - every image has a smoke case: a directory renamed or added without one
#     fails here, before anything is built or pushed
#   - every image is built from its own directory under its own name
#   - the check that runs in every container is valid shell
#   - the heaps images skip their entrypoint, which needs the network
#   - a failing check fails the run and names the image
#   - on a throwaway tree: an image without a smoke case fails without being
#     built, and one that fails to build fails without being run
#
# Usage: tests/smoke_cases_test.sh

# shellcheck source=tests/lib.sh
. "$(dirname "$0")/lib.sh"

# The image whose check is made to fail.
FAIL_CHECK=wine-debian

# Stub docker: record "<image> <args>" for every build, save the check of
# every run to checks/<image>.sh and record how it was run, and fail the run
# of $FAIL_CHECK.
mkdir -p "$TMP/bin" "$TMP/checks"
cat > "$TMP/bin/docker" <<STUB
#!/bin/bash
case "\$1" in
    build)
        echo "\$*" >> "$TMP/builds"
        ;;
    run)
        args=("\$@")
        for arg in "\${args[@]}"; do
            [[ "\$arg" == aljazmc/* ]] && image=\${arg#aljazmc/} && break
        done
        printf '%s' "\${args[-1]}" > "$TMP/checks/\$image.sh"
        if [[ " \$* " == *" --entrypoint sh "* ]]; then
            echo "\$image bypass" >> "$TMP/runs"
        else
            echo "\$image entrypoint" >> "$TMP/runs"
        fi
        [ "\$image" != "$FAIL_CHECK" ]
        ;;
esac
STUB
chmod +x "$TMP/bin/docker"
touch "$TMP/builds" "$TMP/runs"

status=0
PATH="$TMP/bin:$PATH" "$ROOT/tests/smoke_test.sh" > "$TMP/output" 2>&1 || status=$?

mapfile -t IMAGES < <(images)
mapfile -t DIRS < <(image_dirs)

if grep -q "no smoke test defined" "$TMP/output"; then
    fail "every image has a smoke case; missing: $(grep -B1 "no smoke test defined" "$TMP/output" | sed -n 's/^==> //p' | paste -sd' ')"
else
    pass "every image of the ${#IMAGES[@]} has a smoke case"
fi

for dir in "${DIRS[@]}"; do
    echo "build -t aljazmc/${dir//\//-} $dir"
done | sort > "$TMP/expected"
sort "$TMP/builds" > "$TMP/actual"
if diff -u "$TMP/expected" "$TMP/actual"; then
    pass "builds every image from its own directory"
else
    fail "builds differ from expected (see diff above)"
fi

invalid=()
for image in "${IMAGES[@]}"; do
    if [ ! -s "$TMP/checks/$image.sh" ]; then
        invalid+=("$image (not run)")
    elif ! sh -n "$TMP/checks/$image.sh" 2> /dev/null; then
        invalid+=("$image")
    fi
done
check "the check of every image is valid shell${invalid[*]:+; not: ${invalid[*]}}" \
    [ "${#invalid[@]}" -eq 0 ]

bypassed=$(awk '$2 == "bypass" {print $1}' "$TMP/runs" | sort | paste -sd' ')
expected=$(images | grep '^heaps-' | paste -sd' ')
check "only the heaps images skip their entrypoint (got: $bypassed)" \
    [ "$bypassed" = "$expected" ]

reports_failed_check() {
    [ "$status" -ne 0 ] &&
        grep -q "$(( ${#IMAGES[@]} - 1 )) passed, 1 failed" "$TMP/output" &&
        grep -q "failed: $FAIL_CHECK" "$TMP/output"
}
check "a failing check fails the run and names $FAIL_CHECK" reports_failed_check

# A throwaway tree: x11/alpine, whose build fails, and nocase/alpine, which
# has no smoke case.
TREE="$TMP/tree"
mkdir -p "$TREE/tests" "$TREE/x11/alpine" "$TREE/nocase/alpine"
echo "FROM scratch" | tee "$TREE/x11/alpine/Dockerfile" > "$TREE/nocase/alpine/Dockerfile"
cat > "$TMP/bin/docker" <<STUB
#!/bin/bash
echo "\$*" >> "$TMP/tree-calls"
[ "\$1" = build ] && exit 1
exit 0
STUB
: > "$TMP/tree-calls"
status=0
DOCKERFILES_DIR="$TREE" PATH="$TMP/bin:$PATH" "$ROOT/tests/smoke_test.sh" \
    > "$TMP/tree-output" 2>&1 || status=$?
no_case() {
    grep -q "no smoke test defined for this image" "$TMP/tree-output" &&
        ! grep -q "aljazmc/nocase-alpine" "$TMP/tree-calls"
}
check "an image without a smoke case fails without being built" no_case
build_fails() {
    grep -q "FAIL: build failed" "$TMP/tree-output" &&
        ! grep -q "^run .*aljazmc/x11-alpine" "$TMP/tree-calls"
}
check "an image that fails to build fails without being run" build_fails
both_fail() {
    [ "$status" -eq 1 ] && grep -q "0 passed, 2 failed" "$TMP/tree-output"
}
check "both fail the run" both_fail

finish
