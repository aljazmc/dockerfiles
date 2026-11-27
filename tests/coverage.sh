#!/bin/bash
#
# Coverage of the core scripts, project.sh and tests/smoke_test.sh, by the
# tests that run without building images: runs every tests/*_test.sh but
# smoke_test.sh under kcov, merges the results and prints how much of each
# script they run. The report is in <output>/index.html, with
# cobertura.xml and coverage.json next to it. With GITHUB_STEP_SUMMARY set,
# as in CI, the table goes to the job summary too.
#
# Needs kcov; `./project.sh coverage` runs it in the pinned kcov image, so
# nothing has to be installed. Exits 1 if a test fails.
#
# Usage: tests/coverage.sh [output directory, default coverage]

set -uo pipefail

ROOT=$(cd "$(dirname "$0")/.." && pwd)
OUT=${1:-$ROOT/coverage}
INCLUDE="$ROOT/project.sh,$ROOT/tests/smoke_test.sh"

command -v kcov > /dev/null || { echo "kcov is not installed; run ./project.sh coverage" >&2; exit 1; }

# empty, not removed: in ./project.sh coverage it is a mount point
mkdir -p "$OUT"
find "$OUT" -mindepth 1 -delete
mkdir -p "$OUT/runs"

status=0
runs=()
for test in "$ROOT"/tests/*_test.sh; do
    name=$(basename "$test" .sh)
    [ "$name" = smoke_test ] && continue
    # kcov traces bash with xtrace, so keep the test's output in a log
    if kcov --include-path="$INCLUDE" "$OUT/runs/$name" "$test" > "$OUT/runs/$name.log" 2>&1; then
        echo "PASS: $name ($(grep -c '^PASS' "$OUT/runs/$name.log") checks)"
    else
        echo "FAIL: $name"
        grep -E '^(FAIL|SKIP)' "$OUT/runs/$name.log" | sed 's/^/    /'
        status=1
    fi
    runs+=("$OUT/runs/$name")
done

kcov --merge "$OUT/merged" "${runs[@]}" > /dev/null
# the merged report, with its data, at the top of the output directory
cp -r "$OUT/merged/kcov-merged/." "$OUT/"
cp -r "$OUT/merged/data" "$OUT/"

# one line per file of coverage.json:
#   {"file": "/w/project.sh", "percent_covered": "51.16", "covered_lines": "44", "total_lines": "86"},
table() {
    echo "| Script | Covered | Lines |"
    echo "|---|---:|---:|"
    # shellcheck disable=SC2016 # the backticks are Markdown, not a command
    sed -nE 's|.*"file": "'"$ROOT"'/([^"]+)", "percent_covered": "([0-9.]+)", "covered_lines": "([0-9]+)", "total_lines": "([0-9]+)".*|\| `\1` \| \2 % \| \3 of \4 \||p' "$OUT/coverage.json"
    # the totals, after the list of files
    local percent covered total
    percent=$(sed -nE 's/^  "percent_covered": "([0-9.]+)",$/\1/p' "$OUT/coverage.json")
    covered=$(sed -nE 's/^  "covered_lines": ([0-9]+),$/\1/p' "$OUT/coverage.json")
    total=$(sed -nE 's/^  "total_lines": ([0-9]+),$/\1/p' "$OUT/coverage.json")
    echo "| **All** | **$percent %** | $covered of $total |"
}

echo
table
echo
# REPORT names the report as the caller sees it, outside a container
echo "Report: ${REPORT:-$OUT/index.html}"

if [ -n "${GITHUB_STEP_SUMMARY:-}" ]; then
    { echo "### Coverage of the core scripts"; echo; table; } >> "$GITHUB_STEP_SUMMARY"
fi

exit "$status"
