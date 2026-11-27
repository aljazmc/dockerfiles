# aljazmc/x11-alpine

A base image for GUI applications on Alpine Linux that use the host's X server, GPU and sound.

[![Docker pulls](https://img.shields.io/docker/pulls/aljazmc/x11-alpine?logo=docker&logoColor=white)](https://hub.docker.com/r/aljazmc/x11-alpine)
[![Image size](https://img.shields.io/docker/image-size/aljazmc/x11-alpine/latest?logo=docker&logoColor=white)](https://hub.docker.com/r/aljazmc/x11-alpine/tags)
[![Version](https://img.shields.io/docker/v/aljazmc/x11-alpine?sort=semver&logo=docker&logoColor=white)](https://hub.docker.com/r/aljazmc/x11-alpine/tags)
[![platforms: amd64 | arm64](https://img.shields.io/badge/platforms-amd64%20%7C%20arm64-2496ed?logo=docker&logoColor=white)](https://github.com/aljazmc/dockerfiles#building-and-testing)
[![Alpine: 3.24.4](https://img.shields.io/badge/Alpine-3.24.4-0d597f?logo=alpinelinux&logoColor=white)](https://hub.docker.com/_/alpine)
[![libX11: 1.8.14](https://img.shields.io/badge/libX11-1.8.14-f28834?logo=xdotorg&logoColor=white)](https://gitlab.freedesktop.org/xorg/lib/libx11/-/blob/master/COPYING)
[![libX11 license: X11 (MIT)](https://img.shields.io/badge/libX11%20license-X11%20(MIT)-blue)](#license)
[![CI](https://github.com/aljazmc/dockerfiles/actions/workflows/ci.yml/badge.svg)](https://github.com/aljazmc/dockerfiles/actions/workflows/ci.yml)
[![Dockerfile license: MIT](https://img.shields.io/badge/Dockerfile%20license-MIT-blue)](https://github.com/aljazmc/dockerfiles/blob/main/LICENSE)

[Docker Hub](https://hub.docker.com/r/aljazmc/x11-alpine) · [Source](https://github.com/aljazmc/dockerfiles/tree/main/x11/alpine) · [All images](https://github.com/aljazmc/dockerfiles)

## Overview

| | |
|---|---|
| **Base image** | `alpine:3.24.4` |
| **Software** | libX11 1.8.14 |
| **Also included** | xterm, GTK 2, Mesa, Vulkan, Wayland client libraries, PipeWire ALSA plugin, PulseAudio client, ShellCheck |
| **User** | `x11` (uid 1000) with passwordless `doas` (`doas apk add ...`) |
| **Tags** | `latest`, `1.8.14`, `1.8.14-YYYYMMDD` |

## Quick start

Run in an empty directory; the commands work on the files of the current directory, mounted as the home directory of the container. [CI](https://github.com/aljazmc/dockerfiles/actions/workflows/ci.yml) runs these commands to check that they work.

```sh
# open a shell, with the current directory as the home directory
docker run --rm -it -v .:/home/x11 -w /home/x11 aljazmc/x11-alpine

# the xterm version; on the host's display, see Docker Compose below
docker run --rm aljazmc/x11-alpine xterm -version
```

## Usage with Docker Compose

```
## docker-compose.yml file
services:
    x11:
        image: aljazmc/x11-alpine
        user: ${UID:-1000}:${GID:-1000}
        working_dir: /home/x11
        volumes:
            - .:/home/x11
            - /home/$USER/.Xauthority:/home/x11/.Xauthority
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
            HOME: /home/x11
            XDG_RUNTIME_DIR: /run/user/1000
        network_mode: host

## start container shell
docker compose run --rm x11 sh -c "sh"

## use shell inside the container to print environment variables
docker compose run --rm x11 sh -c "printenv"
```

## Notes

- Not intended for production use.
- The container user needs the host's `render`, `video` and `audio` groups (`group_add`) to use the GPU and the sound card. Without them, apps fall back to software rendering. The group ids differ between distributions: `stat -c %g /dev/dri/renderD128 /dev/dri/card0 /dev/snd/controlC0`.
- There is no X server or audio server inside the container. Apps use the host's X server (`DISPLAY`, `/tmp/.X11-unix`) and the host's PipeWire/PulseAudio (`XDG_RUNTIME_DIR`).
- Alpine Linux uses musl instead of glibc, so binaries built on glibc distributions (e.g. Debian, Ubuntu, Fedora) don't run here. Use Alpine packages or programs built on Alpine.

## Tags

- `latest`: the newest build.
- `1.8.14`: the libX11 version in the image, e.g. `aljazmc/x11-alpine:1.8.14`. Use it to stay on a known version.
- `1.8.14-YYYYMMDD`: the same version, built on that date (UTC), e.g. `1.8.14-20261122`. Every build gets its own tag that never moves, so use it where you need exactly the same image again.
- libX11 is the Alpine `libx11` package, pinned with `LIBX11_VERSION` in the Dockerfile (`libx11~1.8.14`).

## License

The Dockerfile, the scripts and this README are part of [aljazmc/dockerfiles](https://github.com/aljazmc/dockerfiles), released under the [MIT License](https://github.com/aljazmc/dockerfiles/blob/main/LICENSE).

The software in the image keeps its own license:

| Software | License | In the image |
|---|---|---|
| [libX11](https://gitlab.freedesktop.org/xorg/lib/libx11/-/blob/master/COPYING) | X11 (MIT) | `apk info --license libx11` |

Every other package keeps its license too: `apk info --license <package>` shows it on Alpine, `/usr/share/doc/<package>/copyright` on Debian.
