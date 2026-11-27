#!/bin/bash
#
# Test for `project.sh changed`, which CI uses to build only the images
# whose directory a push or pull request changed. It runs a copy of
# project.sh in a throwaway git repository of a few image directories and
# checks that
#   - a change to an image directory lists that image, and only it
#   - a range of commits lists every image changed in any of them
#   - changes outside the image directories list nothing
#   - a deleted image is not listed, since there is nothing to build
#   - a directory is not mistaken for another whose name it starts with
#   - without arguments, it compares the last commit with its parent
#   - a base that isn't a commit, like the zeros GitHub sends for a new
#     branch, falls back to the parent of the head
#
# Usage: tests/changed_test.sh

# shellcheck source=tests/lib.sh
. "$(dirname "$0")/lib.sh"

REPO="$TMP/repo"
mkdir -p "$REPO"
cp "$ROOT/project.sh" "$REPO/"
cd "$REPO" || exit 1
git init -q
git() { command git -c user.name=test -c user.email=test@example.invalid "$@"; }

# commit <message>: commit everything, print the commit
commit() {
    git add -A
    git commit -qm "$1"
    git rev-parse HEAD
}

for dir in alpha/alpine alpha/alpine-edge alpha/debian beta/buildforlinux solo; do
    mkdir -p "$dir"
    echo "FROM scratch" > "$dir/Dockerfile"
    echo "# $dir" > "$dir/README.md"
done
echo "# repository" > README.md
c0=$(commit "five images")

echo "RUN true" >> alpha/alpine/Dockerfile
c1=$(commit "change alpha/alpine")

echo "more" >> README.md
mkdir -p tests && echo "#!/bin/sh" > tests/a_test.sh
c2=$(commit "change files outside the images")

echo "notes" > solo/NOTES.md
c3=$(commit "add a file to solo")

git rm -rq beta/buildforlinux
c4=$(commit "delete beta/buildforlinux")

echo "RUN true" >> alpha/alpine-edge/Dockerfile
c5=$(commit "change alpha/alpine-edge")

# expect <description> <expected images> <changed arguments...>
expect() {
    local description=$1 expected=$2 actual
    shift 2
    actual=$(./project.sh changed "$@" 2> "$TMP/stderr" | paste -sd' ')
    if [ "$actual" = "$expected" ]; then
        pass "$description"
    else
        fail "$description: expected '$expected', got '$actual'"
    fi
}

expect "a changed Dockerfile lists its image" "alpha-alpine" "$c0" "$c1"
expect "a range lists every image changed in it" "alpha-alpine solo" "$c0" "$c3"
expect "changes outside the images list nothing" "" "$c1" "$c2"
expect "a new file in an image directory lists it" "solo" "$c2" "$c3"
expect "a deleted image is not listed" "" "$c3" "$c4"
expect "alpha/alpine-edge is not mistaken for alpha/alpine" "alpha-alpine-edge" "$c4" "$c5"
expect "without arguments, the last commit" "alpha-alpine-edge"

ZEROS=0000000000000000000000000000000000000000
expect "a base of zeros compares the head with its parent" "alpha-alpine" "$ZEROS" "$c1"
check "a base of zeros says so on stderr" grep -q "is not a commit" "$TMP/stderr"
expect "a base that doesn't exist compares the head with its parent" "solo" \
    deadbeef "$c3"

# and the command is still rejected with a wrong name
status=0
./project.sh change > /dev/null 2>&1 || status=$?
check "an unknown command near changed is rejected" [ "$status" -eq 1 ]

finish
