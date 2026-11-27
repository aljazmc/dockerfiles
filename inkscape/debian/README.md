# aljazmc/inkscape-debian

Inkscape with its Python extensions and import and export helpers on Debian, for converting and exporting drawings from the command line.

[![Docker pulls](https://img.shields.io/docker/pulls/aljazmc/inkscape-debian?logo=docker&logoColor=white)](https://hub.docker.com/r/aljazmc/inkscape-debian)
[![Image size](https://img.shields.io/docker/image-size/aljazmc/inkscape-debian/latest?logo=docker&logoColor=white)](https://hub.docker.com/r/aljazmc/inkscape-debian/tags)
[![Version](https://img.shields.io/docker/v/aljazmc/inkscape-debian?sort=semver&logo=docker&logoColor=white)](https://hub.docker.com/r/aljazmc/inkscape-debian/tags)
[![platforms: amd64 | arm64](https://img.shields.io/badge/platforms-amd64%20%7C%20arm64-2496ed?logo=docker&logoColor=white)](https://github.com/aljazmc/dockerfiles#building-and-testing)
[![Debian: 13.8](https://img.shields.io/badge/Debian-13.8-a81d33?logo=debian&logoColor=white)](https://hub.docker.com/_/debian)
[![Inkscape: 1.4](https://img.shields.io/badge/Inkscape-1.4-000000?logo=inkscape&logoColor=white)](https://inkscape.org/about/license/)
[![Inkscape license: GPL-2.0-or-later](https://img.shields.io/badge/Inkscape%20license-GPL--2.0--or--later-blue)](#license)
[![CI](https://github.com/aljazmc/dockerfiles/actions/workflows/ci.yml/badge.svg)](https://github.com/aljazmc/dockerfiles/actions/workflows/ci.yml)
[![Dockerfile license: MIT](https://img.shields.io/badge/Dockerfile%20license-MIT-blue)](https://github.com/aljazmc/dockerfiles/blob/main/LICENSE)

[Docker Hub](https://hub.docker.com/r/aljazmc/inkscape-debian) · [Source](https://github.com/aljazmc/dockerfiles/tree/main/inkscape/debian) · [All images](https://github.com/aljazmc/dockerfiles)

## Overview

| | |
|---|---|
| **Base image** | `debian:13.8` |
| **Software** | Inkscape 1.4 (Debian package) |
| **Also included** | Python 3 extension modules, ImageMagick, Ghostscript, fig2dev, rsvg-convert, libwmf, aspell, Ruby, xterm, ShellCheck, Ruff 0.17.6 (pip) |
| **User** | `inkscape` (uid 1000) with passwordless `sudo` (`sudo apt-get install ...`) |
| **Tags** | `latest`, `1.4`, `1.4-YYYYMMDD` |

## Quick start

Run in an empty directory; the commands work on the files of the current directory, mounted as the home directory of the container. [CI](https://github.com/aljazmc/dockerfiles/actions/workflows/ci.yml) runs these commands to check that they work.

<!-- quickstart setup
printf '<svg xmlns="http://www.w3.org/2000/svg" width="200" height="100"><rect width="200" height="100" fill="#2496ed"/></svg>\n' > drawing.svg
-->

```sh
# open a shell, with the current directory as the home directory
docker run --rm -it -v .:/home/inkscape -w /home/inkscape aljazmc/inkscape-debian

# export drawing.svg to drawing.pdf
docker run --rm -v .:/home/inkscape -w /home/inkscape aljazmc/inkscape-debian inkscape drawing.svg -o drawing.pdf

# and to a 400 pixels wide drawing.png
docker run --rm -v .:/home/inkscape -w /home/inkscape aljazmc/inkscape-debian inkscape drawing.svg -w 400 -o drawing.png
```

<!-- quickstart check
test -s drawing.pdf
test -s drawing.png
-->

## Usage with Docker Compose

```
## docker-compose.yml file
services:
    inkscape:
        image: aljazmc/inkscape-debian
        user: ${UID:-1000}:${GID:-1000}
        working_dir: /home/inkscape
        volumes:
            - .:/home/inkscape
            - /home/$USER/.Xauthority:/home/inkscape/.Xauthority
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
            HOME: /home/inkscape
            XDG_RUNTIME_DIR: /run/user/1000
        network_mode: host

## start container shell
docker compose run --rm inkscape sh -c "sh"

## export drawing.svg to drawing.pdf
docker compose run --rm inkscape sh -c "inkscape drawing.svg --export-type=pdf"
```

## Notes

- The container user needs the host's `render`, `video` and `audio` groups (`group_add`) to use the GPU and the sound card. Without them, apps fall back to software rendering. The group ids differ between distributions: `stat -c %g /dev/dri/renderD128 /dev/dri/card0 /dev/snd/controlC0`.
- There is no X server or audio server inside the container. Apps use the host's X server (`DISPLAY`, `/tmp/.X11-unix`) and the host's PipeWire/PulseAudio (`XDG_RUNTIME_DIR`).
- Every bundled Python extension works, including the GTK based ones (`python3-gi`), plotter output (`pyserial`), web image import (`requests`), optimized SVG (`scour`) and the import/export helpers (`ghostscript`, `fig2dev`, `imagemagick`, `libwmf`, `rsvg-convert`).

## Tags

- `latest`: the newest build.
- `1.4`: the Inkscape version in the image, e.g. `aljazmc/inkscape-debian:1.4`. Use it to stay on a known version.
- `1.4-YYYYMMDD`: the same version, built on that date (UTC), e.g. `1.4-20261122`. Every build gets its own tag that never moves, so use it where you need exactly the same image again.
- Inkscape is the Debian `inkscape` package, pinned with `INKSCAPE_VERSION` in the Dockerfile (`inkscape=1.4-*`), so Debian updates of 1.4 are still installed.

## License

The Dockerfile, the scripts and this README are part of [aljazmc/dockerfiles](https://github.com/aljazmc/dockerfiles), released under the [MIT License](https://github.com/aljazmc/dockerfiles/blob/main/LICENSE).

The software in the image keeps its own license:

| Software | License | In the image |
|---|---|---|
| [Inkscape](https://inkscape.org/about/license/) | GPL-2.0-or-later | `/usr/share/doc/inkscape/copyright` |

Every other package keeps its license too: `apk info --license <package>` shows it on Alpine, `/usr/share/doc/<package>/copyright` on Debian.
