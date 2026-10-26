![Docker Pulls](https://img.shields.io/docker/pulls/aljazmc/heaps-buildforlinux) ![Docker Image Size](https://img.shields.io/docker/image-size/aljazmc/heaps-buildforlinux) ![Docker Stars](https://img.shields.io/docker/stars/aljazmc/heaps-buildforlinux)

# Docker image with Heaps, Haxe, Neko and Hashlink

[GitHub repository](https://github.com/aljazmc/dockerfiles/tree/main/heaps/buildforlinux)

## use cases with docker:

###### prepare a directory for development:
```
docker run \
--device /dev/dri:/dev/dri \
--device /dev/snd:/dev/snd \
--group-add "$(stat -c %g /dev/dri/renderD128)" \
--group-add "$(stat -c %g /dev/dri/card0)" \
--group-add "$(stat -c %g /dev/snd/controlC0)" \
--network=host \
--user heaps \
-e DISPLAY="$DISPLAY" \
-e XDG_RUNTIME_DIR=/run/user/1000 \
-v .:/home/heaps \
-v /home/$USER/.Xauthority:/home/heaps/.Xauthority \
-v $XDG_RUNTIME_DIR:/run/user/1000 \
-v /tmp/.X11-unix:/tmp/.X11-unix \
-v /var/lib/dbus/machine-id:/var/lib/dbus/machine-id \
-w /home/heaps \
aljazmc/heaps-buildforlinux:latest
```

###### afterwards append shell commands in the end:
```
docker run \
--device /dev/dri:/dev/dri \
--device /dev/snd:/dev/snd \
--group-add "$(stat -c %g /dev/dri/renderD128)" \
--group-add "$(stat -c %g /dev/dri/card0)" \
--group-add "$(stat -c %g /dev/snd/controlC0)" \
--network=host \
--user heaps \
-e DISPLAY="$DISPLAY" \
-e XDG_RUNTIME_DIR=/run/user/1000 \
-v .:/home/heaps \
-v /home/$USER/.Xauthority:/home/heaps/.Xauthority \
-v $XDG_RUNTIME_DIR:/run/user/1000 \
-v /tmp/.X11-unix:/tmp/.X11-unix \
-v /var/lib/dbus/machine-id:/var/lib/dbus/machine-id \
-w /home/heaps \
aljazmc/heaps-buildforlinux:latest "haxe compile.hxml && hl hello.hl"
```

###### GPU access:
The container user needs the host's `render`, `video` and `audio` groups to use the GPU and the sound card. Without them the game falls back to software rendering. The group ids differ between distributions, so look them up with `stat -c %g /dev/dri/renderD128 /dev/dri/card0 /dev/snd/controlC0`.

## use cases with docker compose

###### prepare a directory for development:
```
# docker-compose.yml example for GNU/Linux host
services:
    heaps:
        image: aljazmc/heaps-buildforlinux
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
        group_add:
            - "992" # render group: stat -c %g /dev/dri/renderD128
            - "44"  # video group: stat -c %g /dev/dri/card0
            - "29"  # audio group: stat -c %g /dev/snd/controlC0
        network_mode: host

# command
docker compose run --rm heaps
```

###### afterwards append shell commands in the end:
```
docker compose run --rm heaps "haxe compile.hxml && hl hello.hl"
```

## How to bundle static libraries

A compiled `.hl` file needs the HashLink runtime (`hl`, `libhl.so`, `*.hdll`) and the libraries the `.hdll` files depend on (SDL3, OpenAL, libpng, libturbojpeg, libvorbis, libuv, ...). To run the game on a machine without Haxe and HashLink installed, copy all of them next to the `.hl` file together with a small launcher script.

###### the image contains this script as the `bundle` command ([source](https://github.com/aljazmc/dockerfiles/blob/main/heaps/buildforlinux/bundle)):
```
#!/bin/bash
set -e

HL_FILE="${1:-hello.hl}"
NAME="$(basename "$HL_FILE" .hl)"
DIST="dist/$NAME"
HDLLS=(fmt heaps openal sdl ui uv)
BUNDLE_LIBS="libSDL3|libopenal|libpng16|libturbojpeg|libvorbis|libogg|libuv|libsndio|libdecor|libmbed|libsqlite3"

rm -rf "$DIST"
mkdir -p "$DIST"

cp "$HL_FILE" "$(command -v hl)" /usr/local/lib/libhl.so "$DIST"/
for HDLL in "${HDLLS[@]}"; do
    cp /usr/local/lib/"$HDLL".hdll "$DIST"/
done
if [ -d res ]; then
    cp -r res "$DIST"/
fi

ldd "$DIST"/*.hdll \
    | awk '/=> \// {print $3}' \
    | grep -E "/($BUNDLE_LIBS)[^/]*$" \
    | sort -u \
    | xargs -r cp -L -t "$DIST"/

cat <<EOF > "$DIST/$NAME"
#!/bin/sh
cd "\$(dirname "\$0")"
export LD_LIBRARY_PATH="\$PWD\${LD_LIBRARY_PATH:+:\$LD_LIBRARY_PATH}"
exec ./hl $NAME.hl "\$@"
EOF
chmod +x "$DIST/$NAME"

tar -czf "dist/$NAME.tar.gz" -C dist "$NAME"
```

###### compile and bundle the project:
```
docker compose run --rm heaps "haxe compile.hxml && bundle hello.hl"
```

The result is the `dist/hello` directory and the `dist/hello.tar.gz` archive. To run the game, extract the archive on the target machine and start the launcher:
```
tar -xzf hello.tar.gz
./hello/hello
```

###### notes:
- `HDLLS` lists the HashLink libraries that are copied. Add `ssl`, `sqlite` or `mysql` if the project uses them. Their dependencies are picked up automatically. To change the lists, copy the command into the project (`cp /usr/local/bin/bundle .`), edit it and run `./bundle` instead.
- `BUNDLE_LIBS` lists the libraries that are copied from the image. Everything else, such as glibc, X11, Wayland, GPU drivers, ALSA, PulseAudio and PipeWire, is expected on the target machine.
- If the project loads resources from the `res` directory at runtime (`hxd.Res.initLocal()`), the directory is copied too. With `hxd.Res.initEmbed()` the resources are already inside the `.hl` file.
- The libraries come from Debian 13 (trixie), so the target machine needs glibc 2.41 or newer (e.g. Debian 13, Ubuntu 25.04, Fedora 42 or newer) and an X11 or Wayland desktop.
- The launcher sets `LD_LIBRARY_PATH` to its own directory, so the bundled libraries are used instead of the system ones.

## How to make a self-extracting .sh archive

The `.sh` file is a small shell script with the game appended as a `.tar.gz` archive. When it starts, it extracts the game to a temporary directory, runs it with the same arguments, returns its exit code and deletes the directory when the game exits. It only needs `sh`, `tar`, `gzip` and `mktemp`, which every GNU/Linux distribution has.

###### the image contains this script as the `makesh` command ([source](https://github.com/aljazmc/dockerfiles/blob/main/heaps/buildforlinux/makesh)):
```
#!/bin/bash
set -e

DIR="${1:?usage: makesh <directory> <executable in the directory> <output.sh>}"
RUN="${2:?usage: makesh <directory> <executable in the directory> <output.sh>}"
OUT="${3:?usage: makesh <directory> <executable in the directory> <output.sh>}"

cat <<EOF > "$OUT"
#!/bin/sh
set -e
TMP="\$(mktemp -d)"
trap 'rm -rf "\$TMP"' EXIT
trap 'exit 130' INT TERM HUP
ARCHIVE="\$(awk '/^__ARCHIVE__\$/ { print NR + 1; exit }' "\$0")"
tail -n +"\$ARCHIVE" "\$0" | tar -xz -C "\$TMP"
"\$TMP/$RUN" "\$@"
exit \$?
__ARCHIVE__
EOF
tar -czf - -C "$DIR" . >> "$OUT"
chmod +x "$OUT"
```

###### create the archive:
```
docker compose run --rm heaps "haxe compile.hxml && bundle hello.hl && makesh dist/hello hello dist/hello.sh"
```

The result is `dist/hello.sh`. Copy it to the target machine and start it with `./hello.sh`.

###### notes:
- usage: `makesh <directory> <executable in the directory> <output.sh>`. The whole directory is packed and the executable is started from inside it.
- The game is extracted on every start. If `/tmp` is mounted with `noexec`, point `TMPDIR` to another directory: `TMPDIR=~/.cache ./hello.sh`.
- The requirements of the bundle (glibc 2.41 or newer, X11 or Wayland desktop) apply to the `.sh` archive too.
