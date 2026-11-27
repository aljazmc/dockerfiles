# aljazmc/godot-buildforlinux

Godot with its Linux export templates, for exporting Godot games for GNU/Linux and packing them into one self-extracting `.sh`.

[![Docker pulls](https://img.shields.io/docker/pulls/aljazmc/godot-buildforlinux?logo=docker&logoColor=white)](https://hub.docker.com/r/aljazmc/godot-buildforlinux)
[![Image size](https://img.shields.io/docker/image-size/aljazmc/godot-buildforlinux/latest?logo=docker&logoColor=white)](https://hub.docker.com/r/aljazmc/godot-buildforlinux/tags)
[![Version](https://img.shields.io/docker/v/aljazmc/godot-buildforlinux?sort=semver&logo=docker&logoColor=white)](https://hub.docker.com/r/aljazmc/godot-buildforlinux/tags)
[![platforms: amd64 | arm64](https://img.shields.io/badge/platforms-amd64%20%7C%20arm64-2496ed?logo=docker&logoColor=white)](https://github.com/aljazmc/dockerfiles#building-and-testing)
[![Debian: 13.8](https://img.shields.io/badge/Debian-13.8-a81d33?logo=debian&logoColor=white)](https://hub.docker.com/_/debian)
[![Godot: 4.7.2](https://img.shields.io/badge/Godot-4.7.2-478cbf?logo=godotengine&logoColor=white)](https://godotengine.org/license/)
[![Godot license: MIT](https://img.shields.io/badge/Godot%20license-MIT-blue)](#license)
[![CI](https://github.com/aljazmc/dockerfiles/actions/workflows/ci.yml/badge.svg)](https://github.com/aljazmc/dockerfiles/actions/workflows/ci.yml)
[![Dockerfile license: MIT](https://img.shields.io/badge/Dockerfile%20license-MIT-blue)](https://github.com/aljazmc/dockerfiles/blob/main/LICENSE)

[Docker Hub](https://hub.docker.com/r/aljazmc/godot-buildforlinux) · [Source](https://github.com/aljazmc/dockerfiles/tree/main/godot/buildforlinux) · [All images](https://github.com/aljazmc/dockerfiles)

## Overview

| | |
|---|---|
| **Base image** | `debian:13.8` |
| **Software** | Godot 4.7.2 (official build) with export templates |
| **Also included** | `makesh` (self-extracting `.sh` archives), Mesa, Vulkan, PipeWire, ShellCheck |
| **User** | `godot` (uid 1000) with passwordless `sudo` (`sudo apt-get install ...`) |
| **Tags** | `latest`, `4.7.2`, `4.7.2-YYYYMMDD` |

## Quick start

Run in an empty directory; the commands work on the files of the current directory, mounted as the home directory of the container. [CI](https://github.com/aljazmc/dockerfiles/actions/workflows/ci.yml) runs these commands to check that they work.

<!-- quickstart setup
cat > project.godot <<'EOF'
config_version=5

[application]

config/name="Hello"
run/main_scene="res://hello.tscn"

[rendering]

renderer/rendering_method="gl_compatibility"
textures/vram_compression/import_etc2_astc=true
EOF
cat > hello.tscn <<'EOF'
[gd_scene format=3]

[node name="Hello" type="Label"]
text = "Hello Godot!"
EOF
cat > export_presets.cfg <<'EOF'
[preset.0]

name="Linux"
platform="Linux"
runnable=true
export_filter="all_resources"
include_filter=""
exclude_filter=""
export_path="build/linux/hello.x86_64"

[preset.0.options]

binary_format/embed_pck=true
binary_format/architecture="x86_64"
EOF
-->

```sh
# the Godot version and its export templates
docker run --rm aljazmc/godot-buildforlinux "godot --headless --version && ls \$XDG_DATA_HOME/godot/export_templates/*"

# export the project of the current directory with its Linux preset
docker run --rm -v .:/home/godot -w /home/godot aljazmc/godot-buildforlinux "godot --headless --import && mkdir -p build/linux && godot --headless --export-release Linux build/linux/hello.x86_64"

# pack the game into one self-extracting build/hello.sh
docker run --rm -v .:/home/godot -w /home/godot aljazmc/godot-buildforlinux "makesh build/linux hello.x86_64 build/hello.sh"
```

<!-- quickstart check
test -x build/linux/hello.x86_64
test -x build/hello.sh
-->

## GPU access

The container user needs the host's `render`, `video` and `audio` groups to use the GPU and the sound card. Without them the game falls back to software rendering. The group ids differ between distributions, so look them up with `stat -c %g /dev/dri/renderD128 /dev/dri/card0 /dev/snd/controlC0`.

## Usage with Docker Compose

```
# docker-compose.yml example
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

## run commands in the container:
docker compose run --rm godot "godot --headless --import && mkdir -p build/linux && godot --headless --export-release Linux build/linux/hello.x86_64 && build/linux/hello.x86_64"
```

## How to export the project

The commands expect a Godot 4 project in the current directory with an `export_presets.cfg` that has a `Linux` preset, like this one. Godot doesn't create the output directory, so the commands do.

```ini
[preset.0]

name="Linux"
platform="Linux"
runnable=true
export_filter="all_resources"
include_filter=""
exclude_filter=""
export_path="build/linux/hello.x86_64"

[preset.0.options]

binary_format/embed_pck=true
binary_format/architecture="x86_64"
```

```
## export and run the game:
docker compose run --rm godot "godot --headless --import && mkdir -p build/linux && godot --headless --export-release Linux build/linux/hello.x86_64 && build/linux/hello.x86_64"

## open the editor:
docker compose run --rm godot "godot --editor"

## bundle the game:
docker compose run --rm godot "tar -czf build/hello-linux-x86_64.tar.gz -C build/linux hello.x86_64"
```

Extract the archive on the target machine and run `./hello.x86_64`.

### Notes
- `binary_format/embed_pck=true` puts the game data inside the executable. Without it, keep `hello.pck` next to `hello.x86_64`.
- For an arm64 build, set `binary_format/architecture="arm64"` in `export_presets.cfg`.
- `--import` imports the project's resources first. It is only needed when resources were added or changed outside of the editor.
- `build/.gdignore` keeps Godot from importing the exported files.
- The official export templates run on any x86_64 GNU/Linux with glibc 2.28 or newer and an X11 or Wayland desktop with a Vulkan or OpenGL 3.3 driver.

## How to make a self-extracting .sh archive

The `.sh` file is a small shell script with the game appended as a `.tar.gz` archive. When it starts, it extracts the game to a temporary directory, runs it with the same arguments, returns its exit code and deletes the directory when the game exits. It only needs `sh`, `tar`, `gzip` and `mktemp`, which every GNU/Linux distribution has.

```
## the image contains this script as the `makesh` command ([source](https://github.com/aljazmc/dockerfiles/blob/main/godot/buildforlinux/makesh)):
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

## create the archive:
docker compose run --rm godot "godot --headless --import && mkdir -p build/linux && godot --headless --export-release Linux build/linux/hello.x86_64 && makesh build/linux hello.x86_64 build/hello.sh"
```

The result is `build/hello.sh`. Copy it to the target machine and start it with `./hello.sh`.

### Notes
- Usage: `makesh <directory> <executable in the directory> <output.sh>`. The whole directory is packed and the executable is started from inside it.
- The game is extracted on every start. If `/tmp` is mounted with `noexec`, point `TMPDIR` to another directory: `TMPDIR=~/.cache ./hello.sh`.
- With `binary_format/embed_pck=true` the exported `hello.x86_64` already is a single file. The `.sh` archive is useful when the game needs more files next to the executable, e.g. GDExtension libraries or a separate `hello.pck`.

## Tags

- `latest`: the newest build.
- `4.7.2`: the Godot version in the image, e.g. `aljazmc/godot-buildforlinux:4.7.2`. Use it to stay on a known version.
- `4.7.2-YYYYMMDD`: the same version, built on that date (UTC), e.g. `4.7.2-20261122`. Every build gets its own tag that never moves, so use it where you need exactly the same image again.
- Godot is the official build and export templates from GitHub, pinned with `GODOT_VERSION` in the Dockerfile.

## License

The Dockerfile, the scripts and this README are part of [aljazmc/dockerfiles](https://github.com/aljazmc/dockerfiles), released under the [MIT License](https://github.com/aljazmc/dockerfiles/blob/main/LICENSE).

The software in the image keeps its own license:

| Software | License | In the image |
|---|---|---|
| [Godot Engine](https://godotengine.org/license/) | MIT | `godot --headless --version`, [godotengine.org/license](https://godotengine.org/license/) |

Every other package keeps its license too: `apk info --license <package>` shows it on Alpine, `/usr/share/doc/<package>/copyright` on Debian.
