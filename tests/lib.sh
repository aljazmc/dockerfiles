# shellcheck shell=bash
#
# Shared by the tests: the repository root, a temporary directory removed on
# exit, the images, and PASS/FAIL reporting. Source it, then end the test
# with `finish`.

set -uo pipefail

ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT
failures=0

pass() { echo "PASS: $*"; }
fail() { echo "FAIL: $*"; failures=$((failures + 1)); }

# check <description> <command...>: PASS if the command succeeds
check() {
    local description=$1
    shift
    if "$@"; then pass "$description"; else fail "$description"; fi
}

# every directory with a tracked Dockerfile, e.g. "godot/buildforlinux"
image_dirs() {
    git -C "$ROOT" ls-files '*Dockerfile' | xargs -n1 dirname | sort
}

# every image name, e.g. "godot-buildforlinux"
images() {
    local dir
    while read -r dir; do echo "${dir//\//-}"; done < <(image_dirs)
}

finish() {
    [ "$failures" -eq 0 ]
}
