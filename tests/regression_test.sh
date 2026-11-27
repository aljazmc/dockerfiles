#!/bin/bash
#
# Regression tests: one check per kind of bug that a fix: commit repaired,
# named after the commits, so the bug can't come back unnoticed. Every check
# fails on the code before its fix. They read the files only, so they run in
# CI without building anything.
#
# Fixes covered elsewhere:
#   00aa160 misplaced shellcheck directive: the ShellCheck job of CI
#   the tags of an image without a version: tests/project_test.sh
#   helpers run as commands by project.sh: tests/arguments_test.sh
#   AVIF without a libheif encoder in blender-debian: tests/smoke_test.sh
# Not testable: 0a58aab removed a redundant `mkdir -p home`.
#
# Needs shellcheck for the first check, which is skipped without it.
#
# Usage: tests/regression_test.sh

# shellcheck source=tests/lib.sh
. "$(dirname "$0")/lib.sh"
cd "$ROOT" || exit 1

mapfile -t DOCKERFILES < <(git ls-files '*Dockerfile')

# a53a899 0fe763d cdbddc0 f065405 a76b713 12b4e39 d60b3bf: unquoted $USER
# and arrays in the build scripts. The scripts of RUN heredocs pass
# ShellCheck at warning level, in the shell the Dockerfile's SHELL names.
# The options of SHELL, such as -euxo pipefail, become a set line, so that
# ShellCheck knows a failing command stops the build. (Info-level notes stay
# allowed: the Alpine scripts split their package lists on purpose.)
mkdir -p "$TMP/run"
for dockerfile in "${DOCKERFILES[@]}"; do
    # SHELL ["/bin/bash", "-euxo", "pipefail", "-c"] -> /bin/bash -euxo pipefail
    read -r shell options < <(sed -nE 's/^SHELL \[(.*)\]/\1/p' "$dockerfile" |
        head -n1 | tr -d '",' | sed -E 's/ -c$//')
    shell=${shell:-/bin/sh}
    # pipefail is not POSIX, though the sh of Alpine has it
    [ "$shell" = /bin/sh ] && options=${options/o pipefail/}
    awk -v out="$TMP/run/${dockerfile//\//_}" -v shell="$shell" \
        -v options="${options:-}" '
        match($0, /^RUN <<-?["\x27]?[A-Za-z_]+["\x27]?$/) {
            word = $0
            sub(/^RUN <<-?["\x27]?/, "", word)
            sub(/["\x27]?$/, "", word)
            file = out "." ++n ".sh"
            print "#!" shell > file
            if (options != "") print "set " options > file
            next
        }
        word != "" && $0 == word { close(file); word = ""; next }
        word != "" { print > file }
    ' "$dockerfile"
done
scripts=("$TMP"/run/*.sh)
if ! command -v shellcheck > /dev/null; then
    echo "SKIP: the RUN scripts pass ShellCheck (shellcheck not installed)"
elif shellcheck -S warning "${scripts[@]}" > "$TMP/shellcheck" 2>&1; then
    pass "the ${#scripts[@]} RUN scripts of the ${#DOCKERFILES[@]} Dockerfiles pass ShellCheck"
else
    sed "s|$TMP/run/||" "$TMP/shellcheck" | grep -E '^In |SC[0-9]+' | head -n 20
    fail "the RUN scripts pass ShellCheck (see above)"
fi
check "every Dockerfile's RUN scripts were found" \
    [ "$(printf '%s\n' "${scripts[@]}" | sed -E 's/\.[0-9]+\.sh$//' | sort -u | wc -l)" -eq "${#DOCKERFILES[@]}" ]
# ShellCheck notes an unquoted $USER only at info level, so look for it
# outside double quotes directly
unquoted_user=$(for script in "${scripts[@]}"; do
    sed -E 's/"([^"\\]|\\.)*"//g' "$script" | grep -nE '\$\{?USER\b' |
        sed "s|^|$(basename "$script" | sed -E 's/\.[0-9]+\.sh$//; s|_|/|g'):|"
done | paste -sd' ')
check "the RUN scripts quote \$USER${unquoted_user:+; not: $unquoted_user}" \
    [ -z "$unquoted_user" ]

# a53a899 0fe763d cdbddc0: an error message followed by a bare `exit`,
# which exits 0. Every exit after an ERROR names a non-zero status.
bare=$(git grep -nE 'ERROR.*;[[:space:]]*exit[[:space:]]*(;[[:space:]]*)?\}' | paste -sd' ')
check "no ERROR is followed by a bare exit${bare:+; in: $bare}" [ -z "$bare" ]

# cdbddc0 f065405: DEBIAN_FRONTEND set with ENV, so it stayed set in the
# image. It is a build ARG only.
env_frontend=()
for dockerfile in "${DOCKERFILES[@]}"; do
    # join continuation lines, then look at the ENV instructions
    sed -e ':a' -e '/\\$/N; s/\\\n//; ta' "$dockerfile" |
        grep -qE '^ENV .*DEBIAN_FRONTEND' && env_frontend+=("$dockerfile")
done
check "DEBIAN_FRONTEND is never an ENV${env_frontend[*]:+; in: ${env_frontend[*]}}" \
    [ "${#env_frontend[@]}" -eq 0 ]

# a76b713: `exec $@` in an entrypoint split arguments with spaces. Every
# entrypoint execs its arguments quoted.
unquoted=()
for entrypoint in $(git ls-files '*docker-entrypoint.sh'); do
    grep -qE '^[[:space:]]*exec ("\$@"|bash -c "\$\*")' "$entrypoint" ||
        unquoted+=("$entrypoint")
done
check "every entrypoint execs its arguments quoted${unquoted[*]:+; not: ${unquoted[*]}}" \
    [ "${#unquoted[@]}" -eq 0 ]

# f065405: README examples ran aljazmc/heaps, an image that doesn't exist.
# Every aljazmc/<image> in a README is an image of this repository.
mapfile -t IMAGES < <(images)
unknown=()
while read -r name; do
    # aljazmc/dockerfiles is this repository, not an image
    [ "$name" = dockerfiles ] && continue
    [[ " ${IMAGES[*]} " == *" $name "* ]] || unknown+=("$name")
done < <(git ls-files '*README.md' |
    xargs grep -ohE '(github\.com/|hub\.docker\.com/u/)?aljazmc/[a-z0-9][a-z0-9-]*' |
    grep -vE '^(github\.com|hub\.docker\.com/u)/' | sed 's|^aljazmc/||' | sort -u)
check "the READMEs name only images of this repository${unknown[*]:+; unknown: ${unknown[*]}}" \
    [ "${#unknown[@]}" -eq 0 ]

# 12b4e39 d60b3bf cdbddc0 f065405: Compose examples with $(id -u), which
# Compose doesn't run. They use ${UID:-1000} and $XDG_RUNTIME_DIR instead.
substituted=$(git ls-files '*README.md' |
    xargs grep -nE '^[[:space:]]+(user:|- |[A-Za-z_]+:).*\$\(' | paste -sd' ')
check "no Compose example uses command substitution${substituted:+; in: $substituted}" \
    [ -z "$substituted" ]

# 9e8a2d3: images built without upgrading their base, missing its security
# fixes. Every Debian image upgrades with apt-get, every Alpine one with apk.
stale=()
for dockerfile in "${DOCKERFILES[@]}"; do
    case "$(grep -m1 '^FROM' "$dockerfile")" in
        *debian*) grep -qE 'apt-get (full-|dist-)?upgrade' "$dockerfile" ||
                      stale+=("$dockerfile") ;;
        *alpine*) grep -q 'apk upgrade' "$dockerfile" || stale+=("$dockerfile") ;;
    esac
done
check "every build upgrades its base${stale[*]:+; not: ${stale[*]}}" \
    [ "${#stale[@]}" -eq 0 ]

# a6899ec b84d84e d655502 e3e2dd7 e7814b2: packages added after the image
# failed at run time. They are still installed.
REQUIRED=(
    "a6899ec blender/alpine blender-headless blender-shared py3-blender py3-cattrs py3-numpy py3-requests"
    "b84d84e heaps/buildforlinux libsndio7.0"
    "b84d84e heaps/buildformac libsndio7.0"
    "b84d84e heaps/buildforwindows libsndio7.0"
    "b84d84e x11/debian libsndio7.0"
    "d655502 x11/debian libvorbisfile3"
    "e3e2dd7 x11/alpine libvorbis"
    "e7814b2 actions/debian python-is-python3"
)
dropped=()
for line in "${REQUIRED[@]}"; do
    read -r commit dir packages <<< "$line"
    for package in $packages; do
        # a package on a line of its own, maybe with a version: blender~5.1
        grep -qE "^[[:space:]]+${package//./\\.}(~[^[:space:]]*)?[[:space:]]*\\\\?$" \
            "$dir/Dockerfile" || dropped+=("$package in $dir ($commit)")
    done
done
check "the packages added by fixes are still installed${dropped[*]:+; dropped: ${dropped[*]}}" \
    [ "${#dropped[@]}" -eq 0 ]

# bb4b99f: syslinux removed from image-spinner, since Alpine has it only for
# x86, and isohybrid with it. It is installed on amd64.
check "image-spinner installs syslinux, with isohybrid, on amd64" \
    grep -qE '^[[:space:]]+apk add --no-cache syslinux$' image-spinner/Dockerfile

# 52230ef's CI run: image-spinner left aports/ with mktemp's mode 700, so
# a host user other than uid 1000 couldn't read it. The clone is opened first.
# shellcheck disable=SC2016 # $TMP_DIR is the text to find, not a variable
check "image-spinner makes the aports tree readable for every host user" \
    grep -qE '^[[:space:]]+chmod 755 "\$TMP_DIR"$' image-spinner/docker-entrypoint.sh

# 698640c: COREPACK_ENABLE_DOWNLOAD_PROMPT renamed by mistake, so corepack
# asked before every download. Every image with corepack turns it off.
prompting=()
for dockerfile in "${DOCKERFILES[@]}"; do
    grep -q corepack "$dockerfile" &&
        ! grep -q 'COREPACK_ENABLE_DOWNLOAD_PROMPT=0' "$dockerfile" &&
        prompting+=("$dockerfile")
done
check "corepack never asks before a download${prompting[*]:+; in: ${prompting[*]}}" \
    [ "${#prompting[@]}" -eq 0 ]

# tests/lib.sh had no shebang, so the ShellCheck job of CI, which picks
# scripts by their shebang, linted no test. Every .sh file has one.
headless=()
for script in $(git ls-files '*.sh'); do
    head -n1 "$script" | grep -qE '^#!.*/(env )?(ba|da|k)?sh\b' ||
        headless+=("$script")
done
check "every .sh file has a shebang, so CI lints it${headless[*]:+; not: ${headless[*]}}" \
    [ "${#headless[@]}" -eq 0 ]

finish
