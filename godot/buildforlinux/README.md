![Docker Pulls](https://img.shields.io/docker/pulls/aljazmc/godot-buildforlinux) ![Docker Image Size](https://img.shields.io/docker/image-size/aljazmc/godot-buildforlinux) ![Docker Stars](https://img.shields.io/docker/stars/aljazmc/godot-buildforlinux)

# Docker image with Godot and the Linux export templates

[GitHub repository](https://github.com/aljazmc/dockerfiles/tree/main/godot/buildforlinux)

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
--user godot \
-e DISPLAY="$DISPLAY" \
-e XDG_RUNTIME_DIR=/run/user/1000 \
-v .:/home/godot \
-v /home/$USER/.Xauthority:/home/godot/.Xauthority \
-v $XDG_RUNTIME_DIR:/run/user/1000 \
-v /tmp/.X11-unix:/tmp/.X11-unix \
-v /var/lib/dbus/machine-id:/var/lib/dbus/machine-id \
-w /home/godot \
aljazmc/godot-buildforlinux:latest
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
--user godot \
-e DISPLAY="$DISPLAY" \
-e XDG_RUNTIME_DIR=/run/user/1000 \
-v .:/home/godot \
-v /home/$USER/.Xauthority:/home/godot/.Xauthority \
-v $XDG_RUNTIME_DIR:/run/user/1000 \
-v /tmp/.X11-unix:/tmp/.X11-unix \
-v /var/lib/dbus/machine-id:/var/lib/dbus/machine-id \
-w /home/godot \
aljazmc/godot-buildforlinux:latest "godot --headless --import && godot --headless --export-release Linux build/linux/hello.x86_64 && build/linux/hello.x86_64"
```

###### GPU access:
The container user needs the host's `render`, `video` and `audio` groups to use the GPU and the sound card. Without them the game falls back to software rendering. The group ids differ between distributions, so look them up with `stat -c %g /dev/dri/renderD128 /dev/dri/card0 /dev/snd/controlC0`.

## use cases with docker compose

###### prepare a directory for development:
```
# docker-compose.yml example for GNU/Linux host
services:
    godot:
        image: aljazmc/godot-buildforlinux
        working_dir: /home/godot
        user: godot
        environment:
            DISPLAY: $DISPLAY
            XDG_RUNTIME_DIR: /run/user/1000
        volumes:
            - .:/home/godot
            - /home/$USER/.Xauthority:/home/godot/.Xauthority
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
docker compose run --rm godot
```

###### afterwards append shell commands in the end:
```
docker compose run --rm godot "godot --headless --import && godot --headless --export-release Linux build/linux/hello.x86_64 && build/linux/hello.x86_64"
```

## How to export the project

The first run creates a small project and an `export_presets.cfg` with a `Linux` preset, unless the files already exist: `project.godot` with a 960x540 viewport that is scaled to fit the window (so the layout doesn't depend on the window size), `main.tscn` as the main scene and `hello.tscn` with a label centered in the viewport, which `main.tscn` instances. Add further parts of the game as scenes of their own. The image contains the Godot editor (`godot`) and the Linux export templates (x86_64 and arm64).

###### export and run the game:
```
docker compose run --rm godot "godot --headless --import && godot --headless --export-release Linux build/linux/hello.x86_64 && build/linux/hello.x86_64"
```

###### open the editor:
```
docker compose run --rm godot "godot --editor"
```

###### bundle the game:
```
docker compose run --rm godot "tar -czf build/hello-linux-x86_64.tar.gz -C build/linux hello.x86_64"
```

Extract the archive on the target machine and run `./hello.x86_64`.

###### notes:
- `binary_format/embed_pck=true` puts the game data inside the executable. Without it, keep `hello.pck` next to `hello.x86_64`.
- For an arm64 build, set `binary_format/architecture="arm64"` in `export_presets.cfg`.
- `--import` imports the project's resources first. It is only needed when resources were added or changed outside of the editor.
- `build/.gdignore` keeps Godot from importing the exported files.
- The official export templates run on any x86_64 GNU/Linux with glibc 2.28 or newer and an X11 or Wayland desktop with a Vulkan or OpenGL 3.3 driver.

## How to make a self-extracting .sh archive

The `.sh` file is a small shell script with the game appended as a `.tar.gz` archive. When it starts, it extracts the game to a temporary directory, runs it with the same arguments, returns its exit code and deletes the directory when the game exits. It only needs `sh`, `tar`, `gzip` and `mktemp`, which every GNU/Linux distribution has.

###### the image contains this script as the `makesh` command ([source](https://github.com/aljazmc/dockerfiles/blob/main/godot/buildforlinux/makesh)):
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
docker compose run --rm godot "godot --headless --import && godot --headless --export-release Linux build/linux/hello.x86_64 && makesh build/linux hello.x86_64 build/hello.sh"
```

The result is `build/hello.sh`. Copy it to the target machine and start it with `./hello.sh`.

###### notes:
- usage: `makesh <directory> <executable in the directory> <output.sh>`. The whole directory is packed and the executable is started from inside it.
- The game is extracted on every start. If `/tmp` is mounted with `noexec`, point `TMPDIR` to another directory: `TMPDIR=~/.cache ./hello.sh`.
- With `binary_format/embed_pck=true` the exported `hello.x86_64` already is a single file. The `.sh` archive is useful when the game needs more files next to the executable, e.g. GDExtension libraries or a separate `hello.pck`.
