#!/bin/bash
#
# Static checks of the repository, the conventions every image follows:
#   - every FROM line names a base with a pinned version, no latest or edge
#   - every image directory has a README titled "# aljazmc/<image>" and an
#     executable docker-entrypoint.sh
#   - the README's image table lists every image once, linking its
#     directory, and its Docker Hub badge counts them
#   - project.sh reads a version for every image, so none is tagged by date
#     alone
#
# Usage: tests/repo_test.sh

# shellcheck source=tests/lib.sh
. "$(dirname "$0")/lib.sh"
cd "$ROOT" || exit 1

mapfile -t DIRS < <(image_dirs)
mapfile -t IMAGES < <(images)

# FROM <image>:<tag> [AS <stage>], where <tag> has a digit and isn't a
# moving tag; FROM <stage> is fine when an earlier line named it
unpinned=()
for dir in "${DIRS[@]}"; do
    stages=()
    while read -r _ base _ stage; do
        if [[ " ${stages[*]} " == *" $base "* ]]; then
            :
        elif [[ ! "$base" =~ ^[^:@]+(:[^:]*[0-9][^:]*|@sha256:[0-9a-f]{64})$ ]] ||
            [[ "$base" =~ :(latest|edge|testing|sid|unstable)$ ]]; then
            unpinned+=("$dir/Dockerfile: $base")
        fi
        [ -n "${stage:-}" ] && stages+=("$stage")
    done < <(grep -iE '^FROM[[:space:]]' "$dir/Dockerfile")
done
check "every FROM line pins its base${unpinned[*]:+; not: ${unpinned[*]}}" \
    [ "${#unpinned[@]}" -eq 0 ]

missing=()
for dir in "${DIRS[@]}"; do
    image=${dir//\//-}
    [ "$(head -n1 "$dir/README.md" 2> /dev/null)" = "# aljazmc/$image" ] ||
        missing+=("$dir/README.md")
    [ "$(git ls-files -s "$dir/docker-entrypoint.sh" | cut -d' ' -f1)" = 100755 ] ||
        missing+=("$dir/docker-entrypoint.sh")
done
check "every image has its README and an executable entrypoint${missing[*]:+; not: ${missing[*]}}" \
    [ "${#missing[@]}" -eq 0 ]

# the README's image table: | [<image>](<dir>) | ...
grep -oE '^\| \[[a-z0-9-]+\]\([a-z0-9/-]+\)' README.md |
    sed -E 's/^\| \[([^]]+)\]\(([^)]+)\)/\1 \2/' | sort > "$TMP/actual"
for dir in "${DIRS[@]}"; do
    echo "${dir//\//-} $dir"
done | sort > "$TMP/expected"
if diff -u "$TMP/expected" "$TMP/actual"; then
    pass "the README lists every image once, linking its directory"
else
    fail "the README's image table differs (see diff above)"
fi

check "the README's Docker Hub badge counts ${#IMAGES[@]} images" \
    grep -qF "Docker%20Hub-${#IMAGES[@]}%20images" README.md

# project.sh's version() names every image in a case pattern
patterns=$(sed -n '/^version() {/,/^}/p' project.sh |
    grep -oE '^ +[a-z0-9*|-]+\)' | tr -d ' )' | tr '|' '\n')
unversioned=()
for image in "${IMAGES[@]}"; do
    known=no
    while read -r pattern; do
        # shellcheck disable=SC2053 # the pattern is a glob on purpose
        [[ "$image" == $pattern ]] && [ "$pattern" != '*' ] && known=yes
    done <<< "$patterns"
    [ "$known" = yes ] || unversioned+=("$image")
done
check "project.sh reads a version for every image${unversioned[*]:+; not: ${unversioned[*]}}" \
    [ "${#unversioned[@]}" -eq 0 ]

finish
