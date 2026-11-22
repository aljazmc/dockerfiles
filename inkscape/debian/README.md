# aljazmc/inkscape-debian

Inkscape with full Python 3 extension support on Debian, for converting and exporting SVG files.

[![Docker Pulls](https://img.shields.io/docker/pulls/aljazmc/inkscape-debian)](https://hub.docker.com/r/aljazmc/inkscape-debian) [![Docker Image Size](https://img.shields.io/docker/image-size/aljazmc/inkscape-debian)](https://hub.docker.com/r/aljazmc/inkscape-debian) [![Docker Stars](https://img.shields.io/docker/stars/aljazmc/inkscape-debian)](https://hub.docker.com/r/aljazmc/inkscape-debian)

[Docker Hub](https://hub.docker.com/r/aljazmc/inkscape-debian) · [Source](https://github.com/aljazmc/dockerfiles/tree/main/inkscape/debian) · [All images](https://github.com/aljazmc/dockerfiles)

## Overview

| | |
|---|---|
| **Base image** | `debian:13.7` |
| **Software** | Inkscape 1.4 (Debian package) |
| **Also included** | Python 3 extension modules, ImageMagick, Ghostscript, fig2dev, rsvg-convert, libwmf, aspell, Ruby, xterm |
| **User** | `inkscape` (uid 1000) with passwordless `sudo` (`sudo apt-get install ...`) |
| **Tags** | `latest`, `1.4` |

## Usage with Docker

```
## start container shell
docker run --rm -it -v .:/home/inkscape -w /home/inkscape aljazmc/inkscape-debian sh -c "bash"

## export drawing.svg to drawing.pdf
docker run --rm -it -v .:/home/inkscape -w /home/inkscape aljazmc/inkscape-debian sh -c "inkscape drawing.svg --export-type=pdf"
```

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
- Inkscape is the Debian `inkscape` package, pinned with `INKSCAPE_VERSION` in the Dockerfile (`inkscape=1.4-*`), so Debian updates of 1.4 are still installed.

## License

Inkscape is free and open-source software released primarily under the GNU General Public License (GPL) v2+ (or v3+ for binaries): [COPYING](https://gitlab.com/inkscape/inkscape/-/blob/master/COPYING), [LICENSES](https://gitlab.com/inkscape/inkscape/-/tree/master/LICENSES).
