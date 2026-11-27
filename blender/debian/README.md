# aljazmc/blender-debian

Blender from Debian forky (testing) and FFmpeg on Debian, for headless rendering and Python scripting.

[![Docker Pulls](https://img.shields.io/docker/pulls/aljazmc/blender-debian)](https://hub.docker.com/r/aljazmc/blender-debian) [![Docker Image Size](https://img.shields.io/docker/image-size/aljazmc/blender-debian)](https://hub.docker.com/r/aljazmc/blender-debian) [![Docker Stars](https://img.shields.io/docker/stars/aljazmc/blender-debian)](https://hub.docker.com/r/aljazmc/blender-debian)

[Docker Hub](https://hub.docker.com/r/aljazmc/blender-debian) · [Source](https://github.com/aljazmc/dockerfiles/tree/main/blender/debian) · [All images](https://github.com/aljazmc/dockerfiles)

## Overview

| | |
|---|---|
| **Base image** | `debian:13.7` |
| **Software** | Blender 5.2.x (Debian forky package, using the system Python) |
| **Also included** | FFmpeg, NumPy, pytest, Ruff 0.17.6, ShellCheck |
| **User** | `blender` (uid 1000) with passwordless `sudo` (`sudo apt-get install ...`) |
| **Tags** | `latest`, `5.2.4`, `5.2.4-YYYYMMDD` |

## Usage with Docker

```
## start container shell
docker run --rm -it -v .:/home/blender -w /home/blender aljazmc/blender-debian sh -c "bash"

## render frame 1 of scene.blend to render_0001.png
docker run --rm -it -v .:/home/blender -w /home/blender aljazmc/blender-debian sh -c "blender -b scene.blend -o //render_#### -f 1"
```

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
- `5.2.4`: the Blender version in the image, e.g. `aljazmc/blender-debian:5.2.4`. Use it to stay on a known version.
- `5.2.4-YYYYMMDD`: the same version, built on that date (UTC), e.g. `5.2.4-20261122`. Every build gets its own tag that never moves, so use it where you need exactly the same image again.
- Blender is the Debian forky package, pinned to the 5.2 series with `BLENDER_VERSION` in the Dockerfile, so the newest 5.2.x package in forky is installed.

## License

Blender is free and open-source software released primarily under the GNU General Public License (GPL) v2+ (or v3+ for binaries): [COPYING](https://github.com/blender/blender/blob/main/COPYING), [GPL v2](https://github.com/blender/blender/blob/main/doc/license/GPL-license.txt), [GPL v3](https://github.com/blender/blender/blob/main/doc/license/GPL3-license.txt). The licenses of bundled third-party code are in [doc/license](https://github.com/blender/blender/tree/main/doc/license).
