![Docker Pulls](https://img.shields.io/docker/pulls/aljazmc/inkscape-debian) ![Docker Image Size](https://img.shields.io/docker/image-size/aljazmc/inkscape-debian) ![Docker Stars](https://img.shields.io/docker/stars/aljazmc/inkscape-debian)

# Docker image with Inkscape and Python 3 extensions

[GitHub repository](https://github.com/aljazmc/dockerfiles/tree/main/inkscape/debian)

## use cases with docker:

###### start container shell
```
docker run --rm -it -v .:/home/inkscape -w /home/inkscape aljazmc/inkscape-debian sh -c "bash"
```

###### export drawing.svg to drawing.pdf
```
docker run --rm -it -v .:/home/inkscape -w /home/inkscape aljazmc/inkscape-debian sh -c "inkscape drawing.svg --export-type=pdf"
```

## use cases with docker compose:

docker-compose.yml file
```
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
```

###### start container shell
```
docker compose run --rm inkscape sh -c "sh"
```

###### export drawing.svg to drawing.pdf
```
docker compose run --rm inkscape sh -c "inkscape drawing.svg --export-type=pdf"
```

##### notes
- not intended for production use.
- passwordless sudo
- the container user needs the host's `render`, `video` and `audio` groups (`group_add`) to use the GPU and the sound card. Without them, apps fall back to software rendering. The group ids differ between distributions: `stat -c %g /dev/dri/renderD128 /dev/dri/card0 /dev/snd/controlC0`.
- there is no X server or audio server inside the container. Apps use the host's X server (`DISPLAY`, `/tmp/.X11-unix`) and the host's PipeWire/PulseAudio (`XDG_RUNTIME_DIR`).

- every bundled Python extension works, including the GTK based ones (`python3-gi`), plotter output (`pyserial`), web image import (`requests`), optimized SVG (`scour`) and the import/export helpers (`ghostscript`, `fig2dev`, `imagemagick`, `libwmf`, `rsvg-convert`).

## license

Inkscape is free and open-source software released primarily under the GNU General Public License (GPL) v2+ (or v3+ for binaries): [COPYING](https://gitlab.com/inkscape/inkscape/-/blob/master/COPYING), [LICENSES](https://gitlab.com/inkscape/inkscape/-/tree/master/LICENSES).
