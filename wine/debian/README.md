# aljazmc/wine-debian

The WineHQ development build on Debian, for running 32-bit and 64-bit Windows applications.

[![Docker pulls](https://img.shields.io/docker/pulls/aljazmc/wine-debian?logo=docker&logoColor=white)](https://hub.docker.com/r/aljazmc/wine-debian)
[![Image size](https://img.shields.io/docker/image-size/aljazmc/wine-debian/latest?logo=docker&logoColor=white)](https://hub.docker.com/r/aljazmc/wine-debian/tags)
[![Version](https://img.shields.io/docker/v/aljazmc/wine-debian?sort=semver&logo=docker&logoColor=white)](https://hub.docker.com/r/aljazmc/wine-debian/tags)
[![platforms: amd64 | arm64](https://img.shields.io/badge/platforms-amd64%20%7C%20arm64-2496ed?logo=docker&logoColor=white)](https://github.com/aljazmc/dockerfiles#building-and-testing)
[![Debian: 13.8](https://img.shields.io/badge/Debian-13.8-a81d33?logo=debian&logoColor=white)](https://hub.docker.com/_/debian)
[![Wine: 11.22](https://img.shields.io/badge/Wine-11.22-800000?logo=wine&logoColor=white)](https://www.winehq.org/license)
[![Wine license: LGPL-2.1-or-later](https://img.shields.io/badge/Wine%20license-LGPL--2.1--or--later-blue)](#license)
[![CI](https://github.com/aljazmc/dockerfiles/actions/workflows/ci.yml/badge.svg)](https://github.com/aljazmc/dockerfiles/actions/workflows/ci.yml)
[![Dockerfile license: MIT](https://img.shields.io/badge/Dockerfile%20license-MIT-blue)](https://github.com/aljazmc/dockerfiles/blob/main/LICENSE)

[Docker Hub](https://hub.docker.com/r/aljazmc/wine-debian) · [Source](https://github.com/aljazmc/dockerfiles/tree/main/wine/debian) · [All images](https://github.com/aljazmc/dockerfiles)

## Overview

| | |
|---|---|
| **Base image** | `debian:13.8` |
| **Software** | Wine 11.22 (WineHQ `winehq-devel`) |
| **Also included** | 32-bit and 64-bit Mesa, Vulkan and SDL2 libraries, GnuTLS, ShellCheck |
| **User** | `wine` (uid 1000) with passwordless `sudo` (`sudo apt-get install ...`) |
| **Tags** | `latest`, `11.22`, `11.22-YYYYMMDD` |

## Quick start

Run in an empty directory; the commands work on the files of the current directory, mounted as the home directory of the container. [CI](https://github.com/aljazmc/dockerfiles/actions/workflows/ci.yml) runs these commands to check that they work.

```sh
# open a shell, with the current directory as the home directory
docker run --rm -it -v .:/home/wine -w /home/wine aljazmc/wine-debian

# the Wine version
docker run --rm aljazmc/wine-debian wine --version

# run a Windows command, without a display
docker run --rm aljazmc/wine-debian wine cmd /c "echo Hello from cmd.exe"
```

## Usage with Docker Compose

```
## docker-compose.yml file
services:
    wine:
        image: aljazmc/wine-debian
        user: ${UID:-1000}:${GID:-1000}
        working_dir: /home/wine
        volumes:
            - .:/home/wine
            - /home/$USER/.Xauthority:/home/wine/.Xauthority
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
            HOME: /home/wine
            XDG_RUNTIME_DIR: /run/user/1000
        network_mode: host

## start container shell
docker compose run --rm wine sh -c "sh"

## use shell inside the container to print environment variables
docker compose run --rm wine sh -c "printenv"
```

## Notes

- The container user needs the host's `render`, `video` and `audio` groups (`group_add`) to use the GPU and the sound card. Without them, apps fall back to software rendering. The group ids differ between distributions: `stat -c %g /dev/dri/renderD128 /dev/dri/card0 /dev/snd/controlC0`.
- There is no X server or audio server inside the container. Apps use the host's X server (`DISPLAY`, `/tmp/.X11-unix`) and the host's PipeWire/PulseAudio (`XDG_RUNTIME_DIR`).
- On the first start of a new prefix Wine asks to install Wine Mono (needed for .NET applications) and Wine Gecko (needed for applications with an embedded browser). To skip both, set `WINEDLLOVERRIDES="mscoree,mshtml="`, e.g. `docker compose run --rm -e WINEDLLOVERRIDES="mscoree,mshtml=" wine sh -c "wineboot -i"`.
- 32-bit and 64-bit Windows applications are supported, with OpenGL and Vulkan (DXVK, VKD3D).

## Tags

- `latest`: the newest build.
- `11.22`: the Wine version in the image, e.g. `aljazmc/wine-debian:11.22`. Use it to stay on a known version.
- `11.22-YYYYMMDD`: the same version, built on that date (UTC), e.g. `11.22-20261122`. Every build gets its own tag that never moves, so use it where you need exactly the same image again.
- Wine is the WineHQ development build (`winehq-devel`), pinned with `WINE_VERSION` in the Dockerfile (`winehq-devel=11.22~*`).

## License

The Dockerfile, the scripts and this README are part of [aljazmc/dockerfiles](https://github.com/aljazmc/dockerfiles), released under the [MIT License](https://github.com/aljazmc/dockerfiles/blob/main/LICENSE).

The software in the image keeps its own license:

| Software | License | In the image |
|---|---|---|
| [Wine](https://www.winehq.org/license) | LGPL-2.1-or-later | `/usr/share/doc/winehq-devel/copyright` |

Every other package keeps its license too: `apk info --license <package>` shows it on Alpine, `/usr/share/doc/<package>/copyright` on Debian.
