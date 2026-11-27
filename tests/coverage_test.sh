#!/bin/bash
#
# Test for `project.sh coverage`, with docker stubbed out. It runs project.sh
# on a temporary directory, with DOCKERFILES_DIR, and checks that
#   - it runs tests/coverage.sh once, in the kcov image pinned by digest
#   - the repository is mounted read-only, and coverage/ next to project.sh
#     writable, where the report goes
#   - the job summary of GitHub Actions is passed into the container only
#     when GITHUB_STEP_SUMMARY is set
#   - it exits with the status of the run, so a failing test fails it
#
# Usage: tests/coverage_test.sh

# shellcheck source=tests/lib.sh
. "$(dirname "$0")/lib.sh"

# Stub docker: record every call, starting with "CALL"; fail when
# COVERAGE_FAILS is set.
mkdir -p "$TMP/bin" "$TMP/work"
cat > "$TMP/bin/docker" <<STUB
#!/bin/bash
echo "CALL \$*" >> "$TMP/calls"
[ -z "\${COVERAGE_FAILS:-}" ]
STUB
chmod +x "$TMP/bin/docker"

# coverage <env...>: run coverage with a fresh record, set $status
coverage() {
    : > "$TMP/calls"
    status=0
    env -u GITHUB_STEP_SUMMARY PATH="$TMP/bin:$PATH" "$@" \
        DOCKERFILES_DIR="$TMP/work" "$ROOT/project.sh" coverage > "$TMP/output" 2>&1 || status=$?
}

kcov=$(sed -nE 's/^KCOV=(.*)$/\1/p' "$ROOT/project.sh")

coverage
runs_once() {
    [ "$(grep -c '^CALL ' "$TMP/calls")" -eq 1 ] &&
        grep -qF -- "--entrypoint bash $kcov tests/coverage.sh --in-container /coverage" "$TMP/calls" &&
        grep -qF -- "-e OWNER=$(id -u):$(id -g)" "$TMP/calls"
}
check "runs tests/coverage.sh once in the pinned kcov image" runs_once
pinned_by_digest() { [[ "$kcov" == kcov/kcov@sha256:* ]]; }
check "pins kcov by digest" pinned_by_digest
check "mounts the repository read-only" \
    grep -qF -- "-v $TMP/work:/src:ro" "$TMP/calls"
report_next_to_project() {
    grep -qF -- "-v $TMP/work/coverage:/coverage" "$TMP/calls" &&
        [ -d "$TMP/work/coverage" ]
}
check "writes the report to coverage/ next to project.sh" report_next_to_project
no_summary() { ! grep -q summary "$TMP/calls"; }
check "passes no job summary outside GitHub Actions" no_summary
check "exits 0 when the tests pass" [ "$status" -eq 0 ]

touch "$TMP/summary.md"
coverage GITHUB_STEP_SUMMARY="$TMP/summary.md"
check "passes the job summary of GitHub Actions into the container" \
    grep -qF -- "-v $TMP/summary.md:/summary.md -e GITHUB_STEP_SUMMARY=/summary.md" "$TMP/calls"

coverage COVERAGE_FAILS=1
check "exits 1 when a test fails" [ "$status" -eq 1 ]

finish
