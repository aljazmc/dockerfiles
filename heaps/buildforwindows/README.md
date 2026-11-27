# aljazmc/heaps-buildforwindows

Haxe, Neko, the Windows build of HashLink, mingw-w64, NSIS and the Heaps game engine, for compiling Heaps games into a single Windows `.exe`.

[![Docker pulls](https://img.shields.io/docker/pulls/aljazmc/heaps-buildforwindows?logo=docker&logoColor=white)](https://hub.docker.com/r/aljazmc/heaps-buildforwindows)
[![Image size](https://img.shields.io/docker/image-size/aljazmc/heaps-buildforwindows/latest?logo=docker&logoColor=white)](https://hub.docker.com/r/aljazmc/heaps-buildforwindows/tags)
[![Version](https://img.shields.io/docker/v/aljazmc/heaps-buildforwindows?sort=semver&logo=docker&logoColor=white)](https://hub.docker.com/r/aljazmc/heaps-buildforwindows/tags)
[![platforms: amd64 | arm64](https://img.shields.io/badge/platforms-amd64%20%7C%20arm64-2496ed?logo=docker&logoColor=white)](https://github.com/aljazmc/dockerfiles#building-and-testing)
[![Debian: 13.7](https://img.shields.io/badge/Debian-13.7-a81d33?logo=debian&logoColor=white)](https://hub.docker.com/_/debian)
[![Heaps: 2.1.0](https://img.shields.io/badge/Heaps-2.1.0-f68712?logo=haxe&logoColor=white)](https://github.com/HeapsIO/heaps/blob/master/LICENSE)
[![Heaps license: MIT](https://img.shields.io/badge/Heaps%20license-MIT-blue)](#license)
[![CI](https://github.com/aljazmc/dockerfiles/actions/workflows/ci.yml/badge.svg)](https://github.com/aljazmc/dockerfiles/actions/workflows/ci.yml)
[![Dockerfile license: MIT](https://img.shields.io/badge/Dockerfile%20license-MIT-blue)](https://github.com/aljazmc/dockerfiles/blob/main/LICENSE)

[Docker Hub](https://hub.docker.com/r/aljazmc/heaps-buildforwindows) · [Source](https://github.com/aljazmc/dockerfiles/tree/main/heaps/buildforwindows) · [All images](https://github.com/aljazmc/dockerfiles)

## Overview

| | |
|---|---|
| **Base image** | `debian:13.7` |
| **Software** | Heaps 2.1.0 (installed from haxelib on the first start) |
| **Also included** | Haxe, Neko, HashLink for Windows (x86_64), mingw-w64, NSIS, `bundle` and `makeexe`, ShellCheck |
| **User** | `heaps` (uid 1000) with passwordless `sudo` (`sudo apt-get install ...`) |
| **Tags** | `latest`, `2.1.0`, `2.1.0-YYYYMMDD` |

## Quick start

Run in an empty directory; the commands work on the files of the current directory, mounted as the home directory of the container. [CI](https://github.com/aljazmc/dockerfiles/actions/workflows/ci.yml) runs these commands to check that they work.

<!-- quickstart setup
mkdir -p src
cat > compile.hxml <<'EOF'
-cp src
-lib format
-lib heaps
-lib hlsdl
-hl hello.hl
-main Main
EOF
cat > src/Main.hx <<'EOF'
class Main extends hxd.App {
    override function init() {
        new h2d.Text(hxd.res.DefaultFont.get(), s2d).text = "Hello Heaps!";
    }
    static function main() {
        new Main();
    }
}
EOF
-->

```sh
# the first start installs Heaps and its libraries with haxelib, into ~/haxelib
docker run --rm -v .:/home/heaps -w /home/heaps aljazmc/heaps-buildforwindows "haxe --version && haxelib list heaps"

# compile the project of the current directory to hello.hl
docker run --rm -v .:/home/heaps -w /home/heaps aljazmc/heaps-buildforwindows "haxe compile.hxml"

# bundle it with hl.exe and make one dist/hello.exe
docker run --rm -v .:/home/heaps -w /home/heaps aljazmc/heaps-buildforwindows "bundle hello.hl && makeexe dist/hello-win64 hello.exe dist/hello.exe"
```

<!-- quickstart check
test -s dist/hello.exe
-->

## Usage with Docker Compose

```
## docker-compose.yml example
services:
    heaps:
        image: aljazmc/heaps-buildforwindows
        working_dir: /home/heaps
        user: heaps
        volumes:
            - .:/home/heaps

## the first start installs Heaps and its libraries with haxelib
docker compose run --rm heaps

## run commands in the container:
docker compose run --rm heaps "haxe compile.hxml"
```

## How to bundle the game with its libraries

The commands expect a Heaps project in the current directory with a `compile.hxml` that compiles it to `hello.hl`, like this one, and the sources in `src`:

```hxml
-cp src
-lib format
-lib heaps
-lib hlsdl
-hl hello.hl
-main Main
```

The image contains the Windows build of HashLink (`hl.exe`, `libhl.dll`, `*.hdll`, `SDL3.dll`, `OpenAL32.dll`, `vcruntime140.dll`, import libraries and headers) in `$HASHLINK_WIN64` (`/usr/local/hashlink-win64`). It is the same HashLink version as the Haxe libraries (`hlsdl`, `hldx`, ...) installed in the container, so a project compiled in the container runs on Windows when all of these files are copied next to it.

```
## the image contains this script as the `bundle` command ([source](https://github.com/aljazmc/dockerfiles/blob/main/heaps/buildforwindows/bundle)):
#!/bin/bash
set -e

INPUT="${1:-hello.hl}"
NAME="$(basename "${INPUT%.*}")"
DIST="dist/$NAME-win64"
HDLLS=(fmt heaps openal sdl ui uv)
DLLS=(libhl OpenAL32 SDL3 vcruntime140)

rm -rf "$DIST" "$DIST.zip"
mkdir -p "$DIST"

case "$INPUT" in
    *.hl)
        cp "$HASHLINK_WIN64/hl.exe" "$DIST/$NAME.exe"
        cp "$INPUT" "$DIST/hlboot.dat"
        ;;
    *.exe)
        cp "$INPUT" "$DIST/$NAME.exe"
        ;;
    *)
        echo "ERROR: expected a .hl or .exe file"
        exit 1
        ;;
esac
for HDLL in "${HDLLS[@]}"; do
    cp "$HASHLINK_WIN64/$HDLL.hdll" "$DIST"/
done
for DLL in "${DLLS[@]}"; do
    cp "$HASHLINK_WIN64/$DLL.dll" "$DIST"/
done
if [ -d res ]; then
    cp -r res "$DIST"/
fi

(cd dist && zip -qr "$NAME-win64.zip" "$NAME-win64")

## option 1: bundle HashLink bytecode
docker compose run --rm heaps "haxe compile.hxml && bundle hello.hl"

## `hl.exe` is copied as `hello.exe` and `hello.hl` as `hlboot.dat`. `hl.exe` started without arguments runs `hlboot.dat` from the current directory, so double clicking `hello.exe` starts the game.

## option 2: bundle a native executable (HL/C, compiled with mingw-w64)

## Save this as `compile-hlc.hxml`:
-cp src
-lib format
-lib heaps
-lib hlsdl
-hl out/main.c
-main Main

## Compile the generated C code to `hello.exe` and bundle it:
docker compose run --rm heaps '
haxe compile-hlc.hxml &&
x86_64-w64-mingw32-gcc -O2 -std=c11 -municode \
    -I out -I "$HASHLINK_WIN64/include" out/main.c -o hello.exe \
    -L "$HASHLINK_WIN64" -l:libhl.lib -l:fmt.lib -l:heaps.lib -l:openal.lib -l:sdl.lib -l:ui.lib -l:uv.lib \
    -ldbghelp &&
bundle hello.exe
'
```

### Result

Both options create the `dist/hello-win64` directory and the `dist/hello-win64.zip` archive. Extract the archive on a 64-bit Windows machine and run `hello.exe`.

### Notes
- `HDLLS` and `DLLS` list the files copied from `$HASHLINK_WIN64`. Add `ssl`, `sqlite` or `mysql` to `HDLLS` if the project uses them (and `-l:ssl.lib` etc. to the HL/C command). To change the lists, copy the command into the project (`cp /usr/local/bin/bundle .`), edit it and run `./bundle` instead.
- To use DirectX instead of SDL, replace `-lib hlsdl` with `-lib hldx` in the `.hxml` file and add `directx` to `HDLLS` (`-l:directx.lib` for HL/C).
- If the project loads resources from the `res` directory at runtime (`hxd.Res.initLocal()`), the directory is copied too. With `hxd.Res.initEmbed()` the resources are already inside the compiled file.
- The image only builds for Windows, it can't run the game. The bundle can be tested on Linux with Wine, e.g. with the [aljazmc/wine-debian](https://hub.docker.com/r/aljazmc/wine-debian) image: `cd dist/hello-win64 && wine hello.exe`.

## How to make a single executable .exe

`makeexe` packs the bundle into one self-extracting `.exe` with [NSIS](https://nsis.sourceforge.io) (`makensis` is installed in the image). When it starts, it silently extracts the bundle to a temporary directory, runs the game from there with the same arguments, returns its exit code and deletes the directory when the game exits.

```
## the image contains this script as the `makeexe` command ([source](https://github.com/aljazmc/dockerfiles/blob/main/heaps/buildforwindows/makeexe)):
#!/bin/bash
set -e

DIR="${1:?usage: makeexe <directory> <executable in the directory> <output.exe>}"
RUN="${2:?usage: makeexe <directory> <executable in the directory> <output.exe>}"
OUT="${3:?usage: makeexe <directory> <executable in the directory> <output.exe>}"
NSI="$(mktemp --suffix=.nsi)"

cat <<EOF > "$NSI"
Unicode true
SetCompressor /SOLID lzma
RequestExecutionLevel user
SilentInstall silent
Name "$(basename "$OUT" .exe)"
OutFile "$OUT"
!include FileFunc.nsh

Section
    InitPluginsDir
    SetOutPath "\$PLUGINSDIR\\app"
    File /r "$DIR/*"
    \${GetParameters} \$0
    ExecWait '"\$PLUGINSDIR\\app\\$RUN" \$0' \$1
    SetOutPath "\$TEMP"
    StrCpy \$2 0
    retry:
        RMDir /r "\$PLUGINSDIR\\app"
        IfFileExists "\$PLUGINSDIR\\app" 0 done
        IntOp \$2 \$2 + 1
        IntCmp \$2 50 done
        Sleep 100
        Goto retry
    done:
    SetErrorLevel \$1
SectionEnd
EOF
makensis -NOCD -V2 "$NSI"
rm "$NSI"

## create the executable:
docker compose run --rm heaps "haxe compile.hxml && bundle hello.hl && makeexe dist/hello-win64 hello.exe dist/hello.exe"
```

The result is `dist/hello.exe`, a single file that runs on 64-bit Windows. It works the same way for both bundle options (HashLink bytecode and HL/C).

### Notes
- Usage: `makeexe <directory> <executable in the directory> <output.exe>`. The whole directory is packed and the executable is started from inside it, so files next to it (DLLs, `hlboot.dat`, `assets`, ...) are found.
- The `.exe` has the default NSIS icon. To use your own, copy the command into the project (`cp /usr/local/bin/makeexe .`), add `Icon "icon.ico"` below `OutFile` and run `./makeexe` instead.
- Self-extracting executables are sometimes flagged by antivirus heuristics or SmartScreen. Signing the `.exe` helps.
- The game runs from a temporary directory that is removed when it exits, so write files that should persist, like saved games, to the user's data directory (`%APPDATA%`). `hxd.Save` writes to the working directory by default.

## Tags

- `latest`: the newest build.
- `2.1.0`: the Heaps version in the image, e.g. `aljazmc/heaps-buildforwindows:2.1.0`. Use it to stay on a known version.
- `2.1.0-YYYYMMDD`: the same version, built on that date (UTC), e.g. `2.1.0-20261122`. Every build gets its own tag that never moves, so use it where you need exactly the same image again.
- Heaps is installed from haxelib on the first start of the container (into `~/haxelib`), pinned with the `HEAPS_VERSION` environment variable set in the Dockerfile. An existing `~/haxelib` directory is kept as it is.

## License

The Dockerfile, the scripts and this README are part of [aljazmc/dockerfiles](https://github.com/aljazmc/dockerfiles), released under the [MIT License](https://github.com/aljazmc/dockerfiles/blob/main/LICENSE).

The software in the image keeps its own license:

| Software | License | In the image |
|---|---|---|
| [Heaps](https://github.com/HeapsIO/heaps/blob/master/LICENSE) | MIT | `~/haxelib/heaps/*/LICENSE` after the first start |

Every other package keeps its license too: `apk info --license <package>` shows it on Alpine, `/usr/share/doc/<package>/copyright` on Debian.
