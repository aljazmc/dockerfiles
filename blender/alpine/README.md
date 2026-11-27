# aljazmc/blender-alpine

Blender and FFmpeg on Alpine Linux, for rendering scenes and running Python scripts in Blender without a window.

[![Docker pulls](https://img.shields.io/docker/pulls/aljazmc/blender-alpine?logo=docker&logoColor=white)](https://hub.docker.com/r/aljazmc/blender-alpine)
[![Image size](https://img.shields.io/docker/image-size/aljazmc/blender-alpine/latest?logo=docker&logoColor=white)](https://hub.docker.com/r/aljazmc/blender-alpine/tags)
[![Version](https://img.shields.io/docker/v/aljazmc/blender-alpine?sort=semver&logo=docker&logoColor=white)](https://hub.docker.com/r/aljazmc/blender-alpine/tags)
[![platforms: amd64 | arm64](https://img.shields.io/badge/platforms-amd64%20%7C%20arm64-2496ed?logo=docker&logoColor=white)](https://github.com/aljazmc/dockerfiles#building-and-testing)
[![Alpine: 3.24.4](https://img.shields.io/badge/Alpine-3.24.4-0d597f?logo=alpinelinux&logoColor=white)](https://hub.docker.com/_/alpine)
[![Blender: 5.1.2](https://img.shields.io/badge/Blender-5.1.2-e87d0d?logo=blender&logoColor=white)](https://www.blender.org/about/license/)
[![Blender license: GPL-2.0-or-later](https://img.shields.io/badge/Blender%20license-GPL--2.0--or--later-blue)](#license)
[![CI](https://github.com/aljazmc/dockerfiles/actions/workflows/ci.yml/badge.svg)](https://github.com/aljazmc/dockerfiles/actions/workflows/ci.yml)
[![Dockerfile license: MIT](https://img.shields.io/badge/Dockerfile%20license-MIT-blue)](https://github.com/aljazmc/dockerfiles/blob/main/LICENSE)

[Docker Hub](https://hub.docker.com/r/aljazmc/blender-alpine) · [Source](https://github.com/aljazmc/dockerfiles/tree/main/blender/alpine) · [All images](https://github.com/aljazmc/dockerfiles)

## Overview

| | |
|---|---|
| **Base image** | `alpine:3.24.4` |
| **Software** | Blender 5.1.2 (Alpine package, with Alpine's system Python) |
| **Also included** | FFmpeg, Python 3 with `bpy`, NumPy, pytest and Requests, xterm, bash, ShellCheck, Ruff 0.17.6 (pip) |
| **User** | `blender` (uid 1000) with passwordless `doas` (`doas apk add ...`) |
| **Tags** | `latest`, `5.1.2`, `5.1.2-YYYYMMDD` |

## Quick start

Run in an empty directory; the commands work on the files of the current directory, mounted as the home directory of the container. [CI](https://github.com/aljazmc/dockerfiles/actions/workflows/ci.yml) runs these commands to check that they work.

<!-- quickstart setup
docker run --rm -v .:/home/blender -w /home/blender aljazmc/blender-alpine blender -b --factory-startup --python-expr "import bpy; bpy.context.scene.render.resolution_percentage = 25; bpy.ops.wm.save_as_mainfile(filepath='scene.blend')"
-->

```sh
# open a shell, with the current directory as the home directory
docker run --rm -it -v .:/home/blender -w /home/blender aljazmc/blender-alpine

# render frame 1 of scene.blend to render_0001.png
docker run --rm -v .:/home/blender -w /home/blender aljazmc/blender-alpine blender -b scene.blend -o //render_#### -f 1

# encode the rendered frames to render.mp4 with FFmpeg
docker run --rm -v .:/home/blender -w /home/blender aljazmc/blender-alpine ffmpeg -framerate 24 -i render_%04d.png render.mp4
```

<!-- quickstart check
test -s render_0001.png
test -s render.mp4
-->

## Usage with Docker Compose

```
## docker-compose.yml file
services:
    blender:
        image: aljazmc/blender-alpine
        user: ${UID:-1000}:${GID:-1000}
        working_dir: /home/blender
        volumes:
            - .:/home/blender
            - /home/$USER/.Xauthority:/home/blender/.Xauthority
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
        environment:
            DISPLAY: $DISPLAY
            HOME: /home/blender
            XDG_RUNTIME_DIR: /run/user/1000
        network_mode: host

## start container shell
docker compose run --rm blender sh -c "sh"

## render frame 1 of scene.blend to render_0001.png
docker compose run --rm blender sh -c "blender -b scene.blend -o //render_#### -f 1"
```

## Notes

- The container user needs the host's `render`, `video` and `audio` groups (`group_add`) to use the GPU and the sound card. Without them, apps fall back to software rendering. The group ids differ between distributions: `stat -c %g /dev/dri/renderD128 /dev/dri/card0 /dev/snd/controlC0`.
- There is no X server or audio server inside the container. Apps use the host's X server (`DISPLAY`, `/tmp/.X11-unix`) and the host's PipeWire/PulseAudio (`XDG_RUNTIME_DIR`).
- Alpine Linux uses musl instead of glibc, so binaries built on glibc distributions (e.g. Debian, Ubuntu, Fedora) don't run here.
- Blender uses Alpine's system Python, so `blender -b file.blend --python script.py` works.
- `ffmpeg` is included for encoding rendered frames into video.
- `bash` and `findutils` (GNU `find`) are included for bash scripts that use `find -printf`.

## Tags

- `latest`: the newest build.
- `5.1.2`: the Blender version in the image, e.g. `aljazmc/blender-alpine:5.1.2`. Use it to stay on a known version.
- `5.1.2-YYYYMMDD`: the same version, built on that date (UTC), e.g. `5.1.2-20261122`. Every build gets its own tag that never moves, so use it where you need exactly the same image again.
- Blender is the Alpine `blender` package, pinned to the 5.1 series with `BLENDER_VERSION` in the Dockerfile (`blender~5.1`), so the newest 5.1.x patch release in Alpine 3.24 is installed.

## License

The Dockerfile, the scripts and this README are part of [aljazmc/dockerfiles](https://github.com/aljazmc/dockerfiles), released under the [MIT License](https://github.com/aljazmc/dockerfiles/blob/main/LICENSE).

The software in the image keeps its own license:

| Software | License | In the image |
|---|---|---|
| [Blender](https://www.blender.org/about/license/) | GPL-2.0-or-later | `apk info --license blender` |

Every other package keeps its license too: `apk info --license <package>` shows it on Alpine, `/usr/share/doc/<package>/copyright` on Debian.
