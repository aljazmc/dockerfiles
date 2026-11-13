![Docker Pulls](https://img.shields.io/docker/pulls/aljazmc/heaps-buildforwindows) ![Docker Image Size](https://img.shields.io/docker/image-size/aljazmc/heaps-buildforwindows) ![Docker Stars](https://img.shields.io/docker/stars/aljazmc/heaps-buildforwindows)

# Docker image with Heaps, Haxe, Neko and the Windows build of Hashlink... and mingw-w64.

[GitHub repository](https://github.com/aljazmc/dockerfiles/tree/main/heaps/buildforwindows)

## > Examples with docker:

```
## prepare a directory for development:
docker run \
--user heaps \
-v .:/home/heaps \
-w /home/heaps \
aljazmc/heaps-buildforwindows:latest

## afterwards append shell commands in the end:
docker run \
--user heaps \
-v .:/home/heaps \
-w /home/heaps \
aljazmc/heaps-buildforwindows:latest "haxe compile.hxml"
```

## > Examples with docker compose

```
## prepare a directory for development:
## docker-compose.yml example
services:
    heaps:
        image: aljazmc/heaps-buildforwindows
        working_dir: /home/heaps
        user: heaps
        volumes:
            - .:/home/heaps

## command
docker compose run --rm heaps

## afterwards append shell commands in the end:
docker compose run --rm heaps "haxe compile.hxml"
```

## > How to bundle static libraries

The first run creates a small project, unless the files already exist: `compile.hxml`, `src/Main.hx`, which sets up the window and a 960x540 scene that is scaled to fit the window (so the layout doesn't depend on the window size), `src/Hello.hx` with a centered greeting, and an empty `res` directory for resources, which `Main` embeds into the compiled game with `hxd.Res.initEmbed()`. Add further parts of the game as classes of their own.

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

## > Result

Both options create the `dist/hello-win64` directory and the `dist/hello-win64.zip` archive. Extract the archive on a 64-bit Windows machine and run `hello.exe`.

## > Notes:
- `HDLLS` and `DLLS` list the files copied from `$HASHLINK_WIN64`. Add `ssl`, `sqlite` or `mysql` to `HDLLS` if the project uses them (and `-l:ssl.lib` etc. to the HL/C command). To change the lists, copy the command into the project (`cp /usr/local/bin/bundle .`), edit it and run `./bundle` instead.
- to use DirectX instead of SDL, replace `-lib hlsdl` with `-lib hldx` in the `.hxml` file and add `directx` to `HDLLS` (`-l:directx.lib` for HL/C).
- ff the project loads resources from the `res` directory at runtime (`hxd.Res.initLocal()`), the directory is copied too. With `hxd.Res.initEmbed()` the resources are already inside the compiled file.
- the image only builds for Windows, it can't run the game. The bundle can be tested on Linux with Wine, e.g. with the [aljazmc/wine-debian](https://hub.docker.com/r/aljazmc/wine-debian) image: `cd dist/hello-win64 && wine hello.exe`.

## > How to make a single executable .exe

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

## > Notes:
- usage: `makeexe <directory> <executable in the directory> <output.exe>`. The whole directory is packed and the executable is started from inside it, so files next to it (DLLs, `hlboot.dat`, `assets`, ...) are found.
- the `.exe` has the default NSIS icon. To use your own, copy the command into the project (`cp /usr/local/bin/makeexe .`), add `Icon "icon.ico"` below `OutFile` and run `./makeexe` instead.
- self-extracting executables are sometimes flagged by antivirus heuristics or SmartScreen. Signing the `.exe` helps.
- the game runs from a temporary directory that is removed when it exits, so write files that should persist, like saved games, to the user's data directory (`%APPDATA%`). `hxd.Save` writes to the working directory by default.

## > License

Heaps is free and open-source software released under the [MIT License](https://github.com/HeapsIO/heaps/blob/master/LICENSE).
