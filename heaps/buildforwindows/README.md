![Docker Pulls](https://img.shields.io/docker/pulls/aljazmc/heaps-buildforwindows) ![Docker Image Size](https://img.shields.io/docker/image-size/aljazmc/heaps-buildforwindows) ![Docker Stars](https://img.shields.io/docker/stars/aljazmc/heaps-buildforwindows)

# Docker image with Heaps, Haxe, Neko and Hashlink... and mingw-w64.

[GitHub repository](https://github.com/aljazmc/dockerfiles/tree/main/heaps/buildforwindows)

## use cases with docker:

###### prepare a directory for development:
```
docker run \
--device /dev/dri:/dev/dri \
--device /dev/snd:/dev/snd \
--network=host \
--user heaps \
-e DISPLAY="$DISPLAY" \
-e XDG_RUNTIME_DIR=/run/user/1000 \
-v .:/home/heaps \
-v /home/"$USER"/.Xauthority:/home/heaps/.Xauthority \
-v "$XDG_RUNTIME_DIR":/run/user/1000 \
-v /tmp/.X11-unix:/tmp/.X11-unix \
-v /var/lib/dbus/machine-id:/var/lib/dbus/machine-id \
-w /home/heaps \
aljazmc/heaps-buildforwindows:latest
```

###### afterwards append shell commands in the end:
```
docker run \
--device /dev/dri:/dev/dri \
--device /dev/snd:/dev/snd \
--network=host \
--user heaps \
-e DISPLAY="$DISPLAY" \
-e XDG_RUNTIME_DIR=/run/user/1000 \
-v .:/home/heaps \
-v /home/"$USER"/.Xauthority:/home/heaps/.Xauthority \
-v "$XDG_RUNTIME_DIR":/run/user/1000 \
-v /tmp/.X11-unix:/tmp/.X11-unix \
-v /var/lib/dbus/machine-id:/var/lib/dbus/machine-id \
-w /home/heaps \
aljazmc/heaps-buildforwindows:latest "haxe compile.hxml && hl hello.hl"
```

## use cases with docker compose

###### prepare a directory for development:
```
# docker-compose.yml example for GNU/Linux host
services:
    heaps:
        image: aljazmc/heaps-buildforwindows
        working_dir: /home/heaps
        user: heaps
        environment:
            DISPLAY: $DISPLAY
            XDG_RUNTIME_DIR: /run/user/1000
        volumes:
            - .:/home/heaps
            - /home/$USER/.Xauthority:/home/heaps/.Xauthority
            - $XDG_RUNTIME_DIR:/run/user/1000
            - /tmp/.X11-unix:/tmp/.X11-unix
            - /var/lib/dbus/machine-id:/var/lib/dbus/machine-id
        devices:
            - /dev/dri:/dev/dri
            - /dev/snd:/dev/snd
        network_mode: host

# command
docker compose run --rm heaps
```

###### afterwards append shell commands in the end:
```
docker compose run --rm heaps "haxe compile.hxml && hl hello.hl"
```


## How to bundle static libraries

The image contains the Windows build of HashLink (`hl.exe`, `libhl.dll`, `*.hdll`, `SDL3.dll`, `OpenAL32.dll`, `vcruntime140.dll`, import libraries and headers) in `$HASHLINK_WIN64` (`/usr/local/hashlink-win64`). It is the same HashLink version as the Linux one, so a project compiled in the container runs on Windows when all of these files are copied next to it.

###### save this script as `bundle.sh` in the project directory and make it executable (`chmod +x bundle.sh`):
```
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
```

###### option 1: bundle HashLink bytecode
```
docker compose run --rm heaps "haxe compile.hxml && ./bundle.sh hello.hl"
```

`hl.exe` is copied as `hello.exe` and `hello.hl` as `hlboot.dat`. `hl.exe` started without arguments runs `hlboot.dat` from the current directory, so double clicking `hello.exe` starts the game.

###### option 2: bundle a native executable (HL/C, compiled with mingw-w64)

Save this as `compile-hlc.hxml`:
```
-cp src
-lib format
-lib heaps
-lib hlsdl
-hl out/main.c
-main Main
```

Compile the generated C code to `hello.exe` and bundle it:
```
docker compose run --rm heaps '
haxe compile-hlc.hxml &&
x86_64-w64-mingw32-gcc -O2 -std=c11 -municode \
    -I out -I "$HASHLINK_WIN64/include" out/main.c -o hello.exe \
    -L "$HASHLINK_WIN64" -l:libhl.lib -l:fmt.lib -l:heaps.lib -l:openal.lib -l:sdl.lib -l:ui.lib -l:uv.lib \
    -ldbghelp &&
./bundle.sh hello.exe
'
```

###### result

Both options create the `dist/hello-win64` directory and the `dist/hello-win64.zip` archive. Extract the archive on a 64-bit Windows machine and run `hello.exe`.

###### notes:
- `HDLLS` and `DLLS` list the files copied from `$HASHLINK_WIN64`. Add `ssl`, `sqlite` or `mysql` to `HDLLS` if the project uses them (and `-l:ssl.lib` etc. to the HL/C command).
- To use DirectX instead of SDL, replace `-lib hlsdl` with `-lib hldx` in the `.hxml` file and add `directx` to `HDLLS` (`-l:directx.lib` for HL/C).
- If the project loads resources from the `res` directory at runtime (`hxd.Res.initLocal()`), the directory is copied too. With `hxd.Res.initEmbed()` the resources are already inside the compiled file.
- The bundle can be tested on Linux with Wine: `cd dist/hello-win64 && wine hello.exe`.
