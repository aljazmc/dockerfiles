# aljazmc/blender-debian

Blender and FFmpeg from Debian forky (testing), for rendering scenes and running Python scripts in Blender without a window.

[![Docker pulls](https://img.shields.io/docker/pulls/aljazmc/blender-debian?logo=docker&logoColor=white)](https://hub.docker.com/r/aljazmc/blender-debian)
[![Image size](https://img.shields.io/docker/image-size/aljazmc/blender-debian/latest?logo=docker&logoColor=white)](https://hub.docker.com/r/aljazmc/blender-debian/tags)
[![Version](https://img.shields.io/docker/v/aljazmc/blender-debian?sort=semver&logo=docker&logoColor=white)](https://hub.docker.com/r/aljazmc/blender-debian/tags)
[![platforms: amd64 | arm64](https://img.shields.io/badge/platforms-amd64%20%7C%20arm64-2496ed?logo=docker&logoColor=white)](https://github.com/aljazmc/dockerfiles#building-and-testing)
[![Debian: forky](https://img.shields.io/badge/Debian-forky-a81d33?logo=debian&logoColor=white)](https://hub.docker.com/_/debian)
[![Blender: 5.2.3](https://img.shields.io/badge/Blender-5.2.3-e87d0d?logo=blender&logoColor=white)](https://www.blender.org/about/license/)
[![Blender license: GPL-2.0-or-later](https://img.shields.io/badge/Blender%20license-GPL--2.0--or--later-blue)](#license)
[![CI](https://github.com/aljazmc/dockerfiles/actions/workflows/ci.yml/badge.svg)](https://github.com/aljazmc/dockerfiles/actions/workflows/ci.yml)
[![Dockerfile license: MIT](https://img.shields.io/badge/Dockerfile%20license-MIT-blue)](https://github.com/aljazmc/dockerfiles/blob/main/LICENSE)

[Docker Hub](https://hub.docker.com/r/aljazmc/blender-debian) · [Source](https://github.com/aljazmc/dockerfiles/tree/main/blender/debian) · [All images](https://github.com/aljazmc/dockerfiles)

## Overview

| | |
|---|---|
| **Base image** | `debian:13.8`, upgraded to Debian forky (testing) for Blender 5.2 |
| **Software** | Blender 5.2.3 (Debian forky package, with the system Python) |
| **Also included** | FFmpeg, Python 3 with NumPy, pytest, cattrs and Requests, DracoPy, xterm, ShellCheck, Ruff 0.17.6 (pip) |
| **User** | `blender` (uid 1000) with passwordless `sudo` (`sudo apt-get install ...`) |
| **Tags** | `latest`, `5.2.3`, `5.2.3-YYYYMMDD` |

## Quick start

Run in an empty directory; the commands work on the files of the current directory, mounted as the home directory of the container. [CI](https://github.com/aljazmc/dockerfiles/actions/workflows/ci.yml) runs these commands to check that they work.

<!-- quickstart setup
docker run --rm -v .:/home/blender -w /home/blender aljazmc/blender-debian blender -b --factory-startup --python-expr "import bpy; bpy.context.scene.render.resolution_percentage = 25; bpy.ops.wm.save_as_mainfile(filepath='scene.blend')"
-->

```sh
# open a shell, with the current directory as the home directory
docker run --rm -it -v .:/home/blender -w /home/blender aljazmc/blender-debian

# render frame 1 of scene.blend to render_0001.png
docker run --rm -v .:/home/blender -w /home/blender aljazmc/blender-debian blender -b scene.blend -o //render_#### -f 1

# encode the rendered frames to render.mp4 with FFmpeg
docker run --rm -v .:/home/blender -w /home/blender aljazmc/blender-debian ffmpeg -framerate 24 -i render_%04d.png render.mp4
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
        image: aljazmc/blender-debian
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
- Blender is the Debian forky (testing) package, pinned to the 5.2 series with `BLENDER_VERSION` in the Dockerfile. It runs on the system Python 3, so modules installed with `apt-get install python3-...` are available in `bpy` scripts.
- Debian builds Blender without Alembic and USD, so `bpy.ops.wm.alembic_export` and `bpy.ops.wm.usd_export` are missing. Every other image, video and 3D format works, including AVIF (`libheif-plugin-aomenc` is installed for it), glTF, FBX, OBJ, PLY and STL.
- pytest is installed in the system Python. `bpy` only imports inside Blender, so run tests through it: `blender -b --factory-startup --python-exit-code 1 --python-expr "import sys, pytest; sys.exit(pytest.main([]))"`. Pass pytest's arguments in the list (for example `pytest.main(["-x", "tests"])`), since `sys.argv` holds Blender's own arguments. The exit code is pytest's.
- `ffmpeg` is included for encoding rendered frames into video.

## Tags

- `latest`: the newest build.
- `5.2.3`: the Blender version in the image, e.g. `aljazmc/blender-debian:5.2.3`. Use it to stay on a known version.
- `5.2.3-YYYYMMDD`: the same version, built on that date (UTC), e.g. `5.2.3-20261122`. Every build gets its own tag that never moves, so use it where you need exactly the same image again.
- Blender is the Debian forky package, pinned to the 5.2 series with `BLENDER_VERSION` in the Dockerfile, so the newest 5.2.x package in forky is installed.

## License

The Dockerfile, the scripts and this README are part of [aljazmc/dockerfiles](https://github.com/aljazmc/dockerfiles), released under the [MIT License](https://github.com/aljazmc/dockerfiles/blob/main/LICENSE).

The software in the image keeps its own license:

| Software | License | In the image |
|---|---|---|
| [Blender](https://www.blender.org/about/license/) | GPL-2.0-or-later | `/usr/share/doc/blender/copyright` |

Every other package keeps its license too: `apk info --license <package>` shows it on Alpine, `/usr/share/doc/<package>/copyright` on Debian.
