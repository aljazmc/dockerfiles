![Docker Pulls](https://img.shields.io/docker/pulls/aljazmc/bevy-buildforlinux) ![Docker Image Size](https://img.shields.io/docker/image-size/aljazmc/bevy-buildforlinux) ![Docker Stars](https://img.shields.io/docker/stars/aljazmc/bevy-buildforlinux)

# Docker image with Rust and the libraries for Bevy

[GitHub repository](https://github.com/aljazmc/dockerfiles/tree/main/bevy/buildforlinux)

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
--user bevy \
-e DISPLAY="$DISPLAY" \
-e XDG_RUNTIME_DIR=/run/user/1000 \
-v .:/home/bevy \
-v /home/$USER/.Xauthority:/home/bevy/.Xauthority \
-v $XDG_RUNTIME_DIR:/run/user/1000 \
-v /tmp/.X11-unix:/tmp/.X11-unix \
-v /var/lib/dbus/machine-id:/var/lib/dbus/machine-id \
-w /home/bevy \
aljazmc/bevy-buildforlinux:latest
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
--user bevy \
-e DISPLAY="$DISPLAY" \
-e XDG_RUNTIME_DIR=/run/user/1000 \
-v .:/home/bevy \
-v /home/$USER/.Xauthority:/home/bevy/.Xauthority \
-v $XDG_RUNTIME_DIR:/run/user/1000 \
-v /tmp/.X11-unix:/tmp/.X11-unix \
-v /var/lib/dbus/machine-id:/var/lib/dbus/machine-id \
-w /home/bevy \
aljazmc/bevy-buildforlinux:latest "cargo run --release"
```

###### GPU access:
The container user needs the host's `render`, `video` and `audio` groups to use the GPU and the sound card. Without them the game falls back to software rendering. The group ids differ between distributions, so look them up with `stat -c %g /dev/dri/renderD128 /dev/dri/card0 /dev/snd/controlC0`.

## use cases with docker compose

###### prepare a directory for development:
```
# docker-compose.yml example for GNU/Linux host
services:
    bevy:
        image: aljazmc/bevy-buildforlinux
        working_dir: /home/bevy
        user: bevy
        environment:
            DISPLAY: $DISPLAY
            XDG_RUNTIME_DIR: /run/user/1000
        volumes:
            - .:/home/bevy
            - /home/$USER/.Xauthority:/home/bevy/.Xauthority
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
docker compose run --rm bevy
```

###### afterwards append shell commands in the end:
```
docker compose run --rm bevy "cargo run --release"
```

## How to bundle the game

The first run creates a `hello` crate (`Cargo.toml` and `src/main.rs`) that depends on Bevy from crates.io, unless the files already exist. The Rust toolchain is installed in the image, crates are downloaded to `.cargo` and compiled to `target` in the project directory.

###### build and bundle the game:
```
docker compose run --rm bevy '
cargo build --release &&
rm -rf dist/hello && mkdir -p dist/hello &&
cp target/release/hello dist/hello/ && strip dist/hello/hello &&
{ [ ! -d assets ] || cp -r assets dist/hello/; } &&
tar -czf dist/hello-linux-x86_64.tar.gz -C dist hello
'
```

The result is the `dist/hello` directory and the `dist/hello-linux-x86_64.tar.gz` archive. Extract the archive on the target machine and run `./hello/hello`. Keep the `assets` directory next to the binary.

###### notes:
- The first build compiles all of Bevy and takes a while. Later builds reuse `target`.
- The binary is linked against Debian 13 (trixie), so the target machine needs glibc 2.41 or newer.
- The target machine needs libasound2, libudev1, X11 (libX11, libXcursor, libXi, libXrandr, libxkbcommon-x11) or Wayland (libwayland-client, libxkbcommon) and a Vulkan driver.

## How to make a self-extracting .sh archive

The `.sh` file is a small shell script with the game appended as a `.tar.gz` archive. When it starts, it extracts the game to a temporary directory, runs it with the same arguments, returns its exit code and deletes the directory when the game exits. It only needs `sh`, `tar`, `gzip` and `mktemp`, which every GNU/Linux distribution has.

###### the image contains this script as the `makesh` command ([source](https://github.com/aljazmc/dockerfiles/blob/main/bevy/buildforlinux/makesh)):
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
docker compose run --rm bevy "makesh dist/hello hello dist/hello.sh"
```

Run it after bundling the game (see above). The result is `dist/hello.sh`. Copy it to the target machine and start it with `./hello.sh`.

###### notes:
- usage: `makesh <directory> <executable in the directory> <output.sh>`. The whole directory is packed and the executable is started from inside it.
- The game is extracted on every start. If `/tmp` is mounted with `noexec`, point `TMPDIR` to another directory: `TMPDIR=~/.cache ./hello.sh`.
- The executable finds the `assets` directory because Bevy looks for it next to the executable.
- The requirements of the bundle (glibc 2.41 or newer, libasound2, libudev1, X11 or Wayland, Vulkan driver) apply to the `.sh` archive too.
