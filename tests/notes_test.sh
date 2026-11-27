#!/bin/bash
#
# Test for `project.sh notes`, which CI uses to write the notes of a GitHub
# release. It runs project.sh on a throwaway git repository, with DOCKERFILES_DIR, with
# conventional commits and tags, and checks that
#   - the commits since the previous tag are sorted into features, fixes,
#     documentation and other changes, in order, each with its short hash
#   - a scope is shown in bold and a breaking change is marked
#   - a commit that isn't conventional goes to the other changes
#   - the images whose directory changed are listed, and none when none did
#   - the message of an annotated tag comes first, a lightweight tag adds none
#   - without an earlier tag, the notes cover every commit and every image
#
# Usage: tests/notes_test.sh

# shellcheck source=tests/lib.sh
. "$(dirname "$0")/lib.sh"

REPO="$TMP/repo"
mkdir -p "$REPO"
cd "$REPO" || exit 1
git init -q
git() { command git -c user.name=test -c user.email=test@example.invalid "$@"; }

# commit <message>: commit everything
commit() { git add -A; git commit -qm "$1"; }

for dir in alpha/alpine alpha/debian solo; do
    mkdir -p "$dir"
    echo "FROM scratch" > "$dir/Dockerfile"
done
commit "feat: three images"
git tag v1

echo "RUN true" >> alpha/alpine/Dockerfile
commit "fix: alpha/alpine runs"
echo "notes" > README.md
commit "docs: a README"
echo "more" >> README.md
commit "feat(publish)!: push from CI"
echo "even more" >> README.md
commit "chore: tidy up"
echo "and more" >> README.md
commit "Update README.md"
git tag -a v2 -m "A summary written by hand." -m "Second paragraph."

echo "last" >> README.md
commit "docs: one more line"
git tag v3

# notes <arguments...>: the notes, in $TMP/notes
notes() { DOCKERFILES_DIR="$REPO" "$ROOT/project.sh" notes "$@" > "$TMP/notes" 2> "$TMP/stderr"; }
has() { grep -qxF -- "$1" "$TMP/notes"; }
lacks() { ! grep -q -- "$1" "$TMP/notes"; }
hash_of() { git log --format=%h --grep="^$1\$" -n1; }

notes "" v2
check "starts with the message of the annotated tag" \
    [ "$(head -n3 "$TMP/notes")" = "$(printf 'A summary written by hand.\n\nSecond paragraph.')" ]
# shellcheck disable=SC2016 # the backticks are Markdown, not a command
check "lists the image that changed since v1" has '- `aljazmc/alpha-alpine`'
check "lists no image that didn't change" lacks 'alpha-debian\|solo'
check "sorts a feature, with its scope in bold and marked breaking" \
    has "- **publish:** push from CI (breaking) ($(hash_of 'feat(publish)!: push from CI'))"
check "sorts a fix" has "- alpha/alpine runs ($(hash_of 'fix: alpha/alpine runs'))"
check "sorts documentation" has "- a README ($(hash_of 'docs: a README'))"
check "puts chores in the other changes" has "- tidy up ($(hash_of 'chore: tidy up'))"
check "puts a commit that isn't conventional in the other changes" \
    has "- Update README.md ($(hash_of 'Update README.md'))"
sections=$(grep '^## ' "$TMP/notes" | paste -sd'|')
check "orders the sections (got: $sections)" \
    [ "$sections" = "## Images|## Features|## Fixes|## Documentation|## Other changes" ]
check "leaves out the commits of earlier releases" lacks "three images"

notes "" v3
check "a lightweight tag adds no summary" [ "$(head -n1 "$TMP/notes")" = "## Images" ]
check "says when no image changed" has "No image changed."
check "covers only the commits since the previous tag" \
    [ "$(grep -c '^- ' "$TMP/notes")" -eq 1 ]

notes "" v1
check "without an earlier tag, lists every image" \
    [ "$(grep -c '^- `aljazmc/' "$TMP/notes")" -eq 3 ]
check "without an earlier tag, covers every commit" has "- three images ($(hash_of 'feat: three images'))"

notes v1 v3
check "takes an explicit base" [ "$(grep -c '^- [^`]' "$TMP/notes")" -eq 6 ]

finish
