#!/bin/bash
#
# Smoke tests for every image in this repository: build the image, start a
# container from it and check that the main tools it ships actually run.
#
# Usage: tests/smoke_test.sh [--no-build] [image...]
#
#   --no-build  test the existing aljazmc/<image> images instead of building
#               them first (docker pulls any image that is missing locally)
#   image...    only test these images, e.g. "x11-alpine godot-buildforlinux"
#               (default: every directory with a Dockerfile)
#
# Every image must have a case in smoke(); an image without one fails, so new
# images can't slip through untested.

# The checks are shell code that runs inside the container, so their $vars are
# meant to stay unexpanded here.
# shellcheck disable=SC2016

set -uo pipefail

ROOT=$(cd "$(dirname "$0")/.." && pwd)
cd "$ROOT" || exit 1

BUILD=1
if [ "${1:-}" = "--no-build" ]; then
    BUILD=0
    shift
fi

LOG=$(mktemp)
trap 'rm -f "$LOG"' EXIT

# Shared by every check: helpers, plus what all images promise (a uid 1000
# user that can become root without a password).
PRELUDE='
set -e
need() { for c in "$@"; do command -v "$c" > /dev/null || { echo "missing command: $c"; exit 1; }; done; }
[ "$(id -u)" = 1000 ] || { echo "expected uid 1000, got $(id -u)"; exit 1; }
if command -v doas > /dev/null; then doas true; else sudo -n true; fi
cd "$(mktemp -d)"
'

# A one-note MIDI file, written with octal escapes so any printf can do it.
MIDI='printf "MThd\000\000\000\006\000\000\000\001\000\140MTrk\000\000\000\014\000\220\074\100\140\200\074\100\000\377\057\000" > note.mid'

SVG='printf "<svg xmlns=\"http://www.w3.org/2000/svg\" width=\"16\" height=\"16\"><rect width=\"16\" height=\"16\" fill=\"red\"/></svg>" > in.svg'

HAXE_MAIN='printf "class Main { static function main() trace(\"smoke ok\"); }\n" > Main.hx'

# smoke <image>: set RUN and CHECK for an image, or return 1 if it has none.
#
# RUN says how CHECK is passed to the container:
#   exec     entrypoint ends in exec "$@", so run it as: sh -c CHECK
#   string   entrypoint runs its arguments as one shell string: CHECK
#   bypass   skip the entrypoint (it needs network to set up): sh -c CHECK
smoke() {
    case "$1" in
        actions-alpine|actions-debian)
            RUN="exec"
            CHECK='
                need node npm corepack git shellcheck ruff
                node -e "console.log(\"node\", process.version)"
                echo "npm $(npm --version), corepack $(corepack --version)"
                git --version
                shellcheck --version
                ruff version
            '
            ;;
        blender-alpine|blender-debian)
            RUN="exec"
            CHECK='
                need blender ffmpeg
                blender -b --factory-startup --python-expr "import bpy; print(\"BPY\", bpy.app.version_string)" | grep BPY
                ffmpeg -hide_banner -version | head -n1
            '
            if [ "$1" = blender-alpine ]; then
                CHECK+='need xterm
                python3 -c "import bpy, numpy, pytest; print(\"bpy, numpy and pytest\", pytest.__version__)"'
            fi
            if [ "$1" = blender-debian ]; then
                # AVIF needs a libheif encoder plugin, which Debian packages separately
                CHECK+='blender -b --factory-startup --python-exit-code 1 --python-expr "import numpy, pytest; print(\"PYTEST\", pytest.__version__)" | grep PYTEST
                blender -b --factory-startup --python-exit-code 1 --python-expr "
import bpy
scene = bpy.context.scene
scene.render.resolution_x = scene.render.resolution_y = 16
scene.render.image_settings.file_format = \"AVIF\"
scene.render.filepath = \"$PWD/out.avif\"
bpy.ops.render.render(write_still=True)
" > /dev/null 2>&1
                test -s out.avif && echo "rendered out.avif"'
            fi
            ;;
        node-alpine|node-debian)
            RUN="exec"
            CHECK='
                need node npm corepack git
                node -e "console.log(\"node\", process.version)"
                echo "npm $(npm --version), corepack $(corepack --version)"
                git --version
            '
            ;;
        fluidsynth-alpine|fluidsynth-debian)
            RUN="exec"
            CHECK="
                need fluidsynth ffmpeg python3
                $MIDI
                sf=\${SOUNDFONT:-/usr/share/sounds/sf2/FluidR3_GM.sf2}
                fluidsynth -ni -F out.wav \"\$sf\" note.mid > /dev/null 2>&1
                test -s out.wav && echo 'rendered note.mid to out.wav'
                ffmpeg -hide_banner -loglevel error -i out.wav out.flac && test -s out.flac && echo 'encoded out.wav to out.flac'
                python3 -c 'import numpy; print(\"numpy\", numpy.__version__)'
            "
            if [ "$1" = fluidsynth-alpine ] || [ "$1" = fluidsynth-debian ]; then
                CHECK+="python3 -m pytest --version
"
            fi
            if [ "$1" = fluidsynth-debian ]; then
                CHECK+="python3 -c 'import mido, rtmidi; print(\"mido and rtmidi ok\")'"
            fi
            ;;
        godot-buildforlinux|godot-buildformac|godot-buildforwindows)
            RUN="string"
            case "$1" in
                *linux)   template=linux_release.x86_64;       tools="makesh" ;;
                *mac)     template=macos.zip;                  tools="makedmg xorriso" ;;
                *windows) template=windows_release_x86_64.exe; tools="zip" ;;
            esac
            CHECK="
                need godot $tools
                echo \"godot \$(godot --headless --version)\"
                ls \"\$XDG_DATA_HOME\"/godot/export_templates/*/$template
            "
            ;;
        heaps-buildforlinux|heaps-buildformac|heaps-buildforwindows)
            RUN="bypass"
            CHECK="
                need haxe haxelib neko bundle
                echo \"haxe \$(haxe --version)\"
                $HAXE_MAIN
                haxe --main Main --hl main.hl && test -s main.hl && echo 'compiled Main.hx to main.hl'
            "
            case "$1" in
                *linux)   CHECK+='need hl makesh; hl main.hl | grep "smoke ok"' ;;
                *mac)     CHECK+='need makedmg xorriso zip; ls "$HASHLINK_MACOS/hl"' ;;
                *windows) CHECK+='need makeexe makensis x86_64-w64-mingw32-gcc; ls "$HASHLINK_WIN64/hl.exe"; x86_64-w64-mingw32-gcc --version | head -n1' ;;
            esac
            ;;
        image-spinner)
            RUN="string"
            CHECK='
                need abuild abuild-keygen git grub-mkimage mcopy mksquashfs rsync xorriso isohybrid
                id -nG | grep -qw abuild && echo "user is in the abuild group"
                xorriso -version 2>&1 | head -n1
            '
            ;;
        inkscape-alpine|inkscape-debian)
            RUN="exec"
            CHECK="
                need inkscape convert gs fig2dev rsvg-convert aspell ruby
                inkscape --version 2> /dev/null
                $SVG
                inkscape in.svg -o out.png 2> /dev/null && test -s out.png && echo 'exported in.svg to out.png'
                python3 -c 'import lxml, numpy, scour, gi; print(\"python extension modules ok\")'
            "
            ;;
        wine-alpine|wine-debian)
            RUN="exec"
            CHECK='
                need wine wineserver
                wine --version
            '
            ;;
        x11-alpine|x11-debian)
            RUN="exec"
            CHECK='
                need xterm
                xterm -version
            '
            ;;
        *)
            return 1
            ;;
    esac
    # every image lints shell scripts, and the images with Python lint Python
    CHECK+='
                need shellcheck
                printf "#!/bin/sh\necho \"\$1\"\n" > lint.sh
                shellcheck lint.sh && echo "shellcheck $(shellcheck --version | sed -n "s/^version: //p"): lint.sh is clean"
            '
    case "$1" in
        blender-*|fluidsynth-*|inkscape-*)
            CHECK+='
                need ruff
                printf "print(\"lint\")\n" > lint.py
                ruff check --no-cache --quiet lint.py && echo "$(ruff --version): lint.py is clean"
            '
            ;;
    esac
}

mapfile -t DIRS < <(find . -name Dockerfile -not -path './.git/*' -exec dirname {} \; | sed 's/^\.\///' | sort)

declare -A KNOWN
for dir in "${DIRS[@]}"; do
    KNOWN[${dir//\//-}]=$dir
done

if [ "$#" -gt 0 ]; then
    IMAGES=("$@")
else
    IMAGES=("${DIRS[@]//\//-}")
fi

PASSED=()
FAILED=()

for image in "${IMAGES[@]}"; do

    tag="aljazmc/$image"
    echo "==> $image"

    if [ -z "${KNOWN[$image]:-}" ]; then
        echo "    no directory with a Dockerfile for this image"
        FAILED+=("$image")
        continue
    fi

    if ! smoke "$image"; then
        echo "    no smoke test defined for this image, add one to smoke() in $0"
        FAILED+=("$image")
        continue
    fi

    if [ "$BUILD" = 1 ]; then
        echo "    building ${KNOWN[$image]}"
        if ! docker build -t "$tag" "${KNOWN[$image]}" > "$LOG" 2>&1; then
            tail -n 30 "$LOG" | sed 's/^/    | /'
            echo "    FAIL: build failed"
            FAILED+=("$image")
            continue
        fi
    fi

    case "$RUN" in
        exec)   cmd=(docker run --rm "$tag" sh -c "$PRELUDE$CHECK") ;;
        string) cmd=(docker run --rm "$tag" "$PRELUDE$CHECK") ;;
        bypass) cmd=(docker run --rm --entrypoint sh "$tag" -c "$PRELUDE$CHECK") ;;
    esac

    if "${cmd[@]}" > "$LOG" 2>&1; then
        sed 's/^/    | /' "$LOG"
        echo "    PASS"
        PASSED+=("$image")
    else
        sed 's/^/    | /' "$LOG"
        echo "    FAIL"
        FAILED+=("$image")
    fi

done

echo
echo "${#PASSED[@]} passed, ${#FAILED[@]} failed"
if [ "${#FAILED[@]}" -gt 0 ]; then
    printf '  failed: %s\n' "${FAILED[@]}"
    exit 1
fi
