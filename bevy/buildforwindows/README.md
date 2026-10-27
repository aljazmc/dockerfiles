![Docker Pulls](https://img.shields.io/docker/pulls/aljazmc/bevy-buildforwindows) ![Docker Image Size](https://img.shields.io/docker/image-size/aljazmc/bevy-buildforwindows) ![Docker Stars](https://img.shields.io/docker/stars/aljazmc/bevy-buildforwindows)

# Docker image with Rust and mingw-w64 for Bevy

[GitHub repository](https://github.com/aljazmc/dockerfiles/tree/main/bevy/buildforwindows)

## use cases with docker:

###### prepare a directory for development:
```
docker run \
--user bevy \
-v .:/home/bevy \
-w /home/bevy \
aljazmc/bevy-buildforwindows:latest
```

###### afterwards append shell commands in the end:
```
docker run \
--user bevy \
-v .:/home/bevy \
-w /home/bevy \
aljazmc/bevy-buildforwindows:latest "cargo build --release --target x86_64-pc-windows-gnu"
```

## use cases with docker compose

###### prepare a directory for development:
```
# docker-compose.yml example
services:
    bevy:
        image: aljazmc/bevy-buildforwindows
        working_dir: /home/bevy
        user: bevy
        volumes:
            - .:/home/bevy

# command
docker compose run --rm bevy
```

###### afterwards append shell commands in the end:
```
docker compose run --rm bevy "cargo build --release --target x86_64-pc-windows-gnu"
```

## How to bundle the game

The first run creates a `hello` crate that depends on Bevy from crates.io and an empty `assets` directory, unless they already exist. `src/main.rs` sets up the window and adds the `HelloPlugin` from `src/hello.rs`, which shows a centered greeting in a 960x540 view that the camera scales to fit the window (so the layout doesn't depend on the window size). Add further parts of the game as plugins in modules of their own. The Rust toolchain with the `x86_64-pc-windows-gnu` target is installed in the image, crates are downloaded to `.cargo` and compiled to `target` in the project directory.

###### build and bundle the game:
```
docker compose run --rm bevy '
cargo build --release --target x86_64-pc-windows-gnu &&
rm -rf dist/hello-win64 && mkdir -p dist/hello-win64 &&
cp target/x86_64-pc-windows-gnu/release/hello.exe dist/hello-win64/ &&
x86_64-w64-mingw32-strip dist/hello-win64/hello.exe &&
{ [ ! -d assets ] || cp -r assets dist/hello-win64/; } &&
cd dist && zip -qr hello-win64.zip hello-win64
'
```

The result is the `dist/hello-win64` directory and the `dist/hello-win64.zip` archive. Extract the archive on a 64-bit Windows machine and run `hello.exe`. Keep the `assets` directory next to the executable.

###### notes:
- The first build compiles all of Bevy and takes a while. Later builds reuse `target`.
- `CARGO_TARGET_X86_64_PC_WINDOWS_GNU_RUSTFLAGS="-C target-feature=+crt-static"` is set in the image, so the executable doesn't need any MinGW runtime DLLs. Check with `x86_64-w64-mingw32-objdump -p hello.exe | grep "DLL Name"`.
- The executable isn't signed, so SmartScreen may ask for confirmation: "More info" → "Run anyway".
- The image only builds for Windows, it can't run the game. The game can be tested on Linux with Wine, e.g. with the [aljazmc/wine-debian](https://hub.docker.com/r/aljazmc/wine-debian) image.
- There is no `bevy/buildformac`: building for macOS needs the Apple SDK, which may only be used on Apple hardware and can't be shipped in an image.

## How to make a single executable .exe

`makeexe` packs the bundle into one self-extracting `.exe` with [NSIS](https://nsis.sourceforge.io) (`makensis` is installed in the image). When it starts, it silently extracts the bundle to a temporary directory, runs the game from there with the same arguments, returns its exit code and deletes the directory when the game exits.

###### the image contains this script as the `makeexe` command ([source](https://github.com/aljazmc/dockerfiles/blob/main/bevy/buildforwindows/makeexe)):
```
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
```

###### create the executable:
```
docker compose run --rm bevy "makeexe dist/hello-win64 hello.exe dist/hello.exe"
```

Run it after bundling the game (see above). The result is `dist/hello.exe`, a single file that runs on 64-bit Windows.

###### notes:
- usage: `makeexe <directory> <executable in the directory> <output.exe>`. The whole directory is packed and the executable is started from inside it, so files next to it (DLLs, `hlboot.dat`, `assets`, ...) are found.
- The `.exe` has the default NSIS icon. To use your own, copy the command into the project (`cp /usr/local/bin/makeexe .`), add `Icon "icon.ico"` below `OutFile` and run `./makeexe` instead.
- Self-extracting executables are sometimes flagged by antivirus heuristics or SmartScreen. Signing the `.exe` helps.
- Without files in the `assets` directory the compiled `hello.exe` already is a single file and doesn't need to be packed.
- The game runs from a temporary directory that is removed when it exits, so write files that should persist, like saved games, to the user's data directory (`%APPDATA%`), not to the working directory.
