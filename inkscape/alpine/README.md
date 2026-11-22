# aljazmc/inkscape-alpine

Inkscape with full Python 3 extension support on Alpine Linux, for converting and exporting SVG files.

[![Docker Pulls](https://img.shields.io/docker/pulls/aljazmc/inkscape-alpine)](https://hub.docker.com/r/aljazmc/inkscape-alpine) [![Docker Image Size](https://img.shields.io/docker/image-size/aljazmc/inkscape-alpine)](https://hub.docker.com/r/aljazmc/inkscape-alpine) [![Docker Stars](https://img.shields.io/docker/stars/aljazmc/inkscape-alpine)](https://hub.docker.com/r/aljazmc/inkscape-alpine)

[Docker Hub](https://hub.docker.com/r/aljazmc/inkscape-alpine) · [Source](https://github.com/aljazmc/dockerfiles/tree/main/inkscape/alpine) · [All images](https://github.com/aljazmc/dockerfiles)

## Overview

| | |
|---|---|
| **Base image** | `alpine:3.24.4` |
| **Software** | Inkscape 1.4.2 (Alpine package) |
| **Also included** | Python 3 extension modules, ImageMagick, Ghostscript, fig2dev, rsvg-convert, libwmf, aspell, Ruby, xterm |
| **User** | `inkscape` (uid 1000) with passwordless `doas` (`doas apk add ...`) |
| **Tags** | `latest`, `1.4.2`, `1.4.2-YYYYMMDD` |

## Usage with Docker

```
## start container shell
docker run --rm -it -v .:/home/inkscape -w /home/inkscape aljazmc/inkscape-alpine sh -c "sh"

## export drawing.svg to drawing.pdf
docker run --rm -it -v .:/home/inkscape -w /home/inkscape aljazmc/inkscape-alpine sh -c "inkscape drawing.svg --export-type=pdf"
```

## Usage with Docker Compose

```
## docker-compose.yml file
services:
    inkscape:
        image: aljazmc/inkscape-alpine
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
- Not intended for production use.
- The container user needs the host's `render`, `video` and `audio` groups (`group_add`) to use the GPU and the sound card. Without them, apps fall back to software rendering. The group ids differ between distributions: `stat -c %g /dev/dri/renderD128 /dev/dri/card0 /dev/snd/controlC0`.
- There is no X server or audio server inside the container. Apps use the host's X server (`DISPLAY`, `/tmp/.X11-unix`) and the host's PipeWire/PulseAudio (`XDG_RUNTIME_DIR`).
- Alpine Linux uses musl instead of glibc, so binaries built on glibc distributions (e.g. Debian, Ubuntu, Fedora) don't run here. Use Alpine packages or programs built on Alpine.
- Every bundled Python extension works, including the GTK based ones (`python3-gi`), plotter output (`pyserial`), web image import (`requests`), optimized SVG (`scour`) and the import/export helpers (`ghostscript`, `fig2dev`, `imagemagick`, `libwmf`, `rsvg-convert`).
- `scour` is installed with `pip` because Alpine only packages it in the testing repository.
- `bash` and `findutils` (GNU `find`) are included for bash scripts that use `find -printf`.

## Tags

- `latest`: the newest build.
- `1.4.2`: the Inkscape version in the image, e.g. `aljazmc/inkscape-alpine:1.4.2`. Use it to stay on a known version.
- `1.4.2-YYYYMMDD`: the same version, built on that date (UTC), e.g. `1.4.2-20261122`. Every build gets its own tag that never moves, so use it where you need exactly the same image again.
- Inkscape is the Alpine `inkscape` package, pinned with `INKSCAPE_VERSION` in the Dockerfile (`inkscape~1.4.2`).

## License

Inkscape is free and open-source software released primarily under the GNU General Public License (GPL) v2+ (or v3+ for binaries): [COPYING](https://gitlab.com/inkscape/inkscape/-/blob/master/COPYING), [LICENSES](https://gitlab.com/inkscape/inkscape/-/tree/master/LICENSES).
