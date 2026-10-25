![Docker Pulls](https://img.shields.io/docker/pulls/aljazmc/heaps) ![Docker Image Size](https://img.shields.io/docker/image-size/aljazmc/heaps) ![Docker Stars](https://img.shields.io/docker/stars/aljazmc/heaps)

# Docker image with Heaps, Haxe, Neko and Hashlink

[GitHub repository](https://github.com/aljazmc/dockerfiles/tree/main/heaps/buildforlinux)

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
-v /home/$USER/.Xauthority:/home/heaps/.Xauthority \
-v $XDG_RUNTIME_DIR:/run/user/1000 \
-v /tmp/.X11-unix:/tmp/.X11-unix \
-v /var/lib/dbus/machine-id:/var/lib/dbus/machine-id \
-w /home/heaps \
aljazmc/heaps:latest
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
-v /home/$USER/.Xauthority:/home/heaps/.Xauthority \
-v $XDG_RUNTIME_DIR:/run/user/1000 \
-v /tmp/.X11-unix:/tmp/.X11-unix \
-v /var/lib/dbus/machine-id:/var/lib/dbus/machine-id \
-w /home/heaps \
aljazmc/heaps:latest "haxe compile.hxml && hl hello.hl"
```

## use cases with docker compose

###### prepare a directory for development:
```
# docker-compose.yml example for GNU/Linux host
services:
    heaps:
        image: aljazmc/heaps
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

A compiled `.hl` file needs the HashLink runtime (`hl`, `libhl.so`, `*.hdll`) and the libraries the `.hdll` files depend on (SDL3, OpenAL, libpng, libturbojpeg, libvorbis, libuv, ...). To run the game on a machine without Haxe and HashLink installed, copy all of them next to the `.hl` file together with a small launcher script.

###### save this script as `bundle.sh` in the project directory and make it executable (`chmod +x bundle.sh`):
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
docker compose run --rm heaps "haxe compile.hxml && ./bundle.sh hello.hl"
```

The result is the `dist/hello` directory and the `dist/hello.tar.gz` archive. To run the game, extract the archive on the target machine and start the launcher:
```
tar -xzf hello.tar.gz
./hello/hello
```

###### notes:
- `HDLLS` lists the HashLink libraries that are copied. Add `ssl`, `sqlite` or `mysql` if the project uses them. Their dependencies are picked up automatically.
- `BUNDLE_LIBS` lists the libraries that are copied from the image. Everything else, such as glibc, X11, Wayland, GPU drivers, ALSA, PulseAudio and PipeWire, is expected on the target machine.
- If the project loads resources from the `res` directory at runtime (`hxd.Res.initLocal()`), the directory is copied too. With `hxd.Res.initEmbed()` the resources are already inside the `.hl` file.
- The libraries come from Debian 13 (trixie), so the target machine needs glibc 2.41 or newer (e.g. Debian 13, Ubuntu 25.04, Fedora 42 or newer) and an X11 or Wayland desktop.
- The launcher sets `LD_LIBRARY_PATH` to its own directory, so the bundled libraries are used instead of the system ones.
