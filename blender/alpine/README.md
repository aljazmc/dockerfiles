![Docker Pulls](https://img.shields.io/docker/pulls/aljazmc/blender-alpine) ![Docker Image Size](https://img.shields.io/docker/image-size/aljazmc/blender-alpine) ![Docker Stars](https://img.shields.io/docker/stars/aljazmc/blender-alpine)

# Docker image with Blender and FFmpeg on Alpine Linux

[GitHub repository](https://github.com/aljazmc/dockerfiles/tree/main/blender/alpine)

## use cases with docker:

###### start container shell
```
docker run --rm -it -v .:/home/blender -w /home/blender aljazmc/blender-alpine sh -c "sh"
```

###### render frame 1 of scene.blend to render_0001.png
```
docker run --rm -it -v .:/home/blender -w /home/blender aljazmc/blender-alpine sh -c "blender -b scene.blend -o //render_#### -f 1"
```

## use cases with docker compose:

docker-compose.yml file
```
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
```

###### start container shell
```
docker compose run --rm blender sh -c "sh"
```

###### render frame 1 of scene.blend to render_0001.png
```
docker compose run --rm blender sh -c "blender -b scene.blend -o //render_#### -f 1"
```

##### notes
- not intended for production use.
- passwordless doas (`doas apk add ...`)
- the container user needs the host's `render`, `video` and `audio` groups (`group_add`) to use the GPU and the sound card. Without them, apps fall back to software rendering. The group ids differ between distributions: `stat -c %g /dev/dri/renderD128 /dev/dri/card0 /dev/snd/controlC0`.
- there is no X server or audio server inside the container. Apps use the host's X server (`DISPLAY`, `/tmp/.X11-unix`) and the host's PipeWire/PulseAudio (`XDG_RUNTIME_DIR`).
- Alpine Linux uses musl instead of glibc, so binaries built on glibc distributions (e.g. Debian, Ubuntu, Fedora) don't run here. Use Alpine packages or programs built on Alpine.
- based on `alpine:edge`, because Blender 5.2 is only packaged in Alpine's edge repository (the stable `alpine:latest` has an older Blender). Edge is a rolling release, so rebuilds can pick up newer versions of other packages.
- Blender is the Alpine `blender` package, pinned to the 5.2 series (`blender~5.2`), so any 5.2.x patch release is accepted. The image is also tagged with the exact installed version (e.g. `5.2.3`). The build fails when edge moves to Blender 5.3 or newer.
- Blender uses Alpine's system Python, so `blender -b file.blend --python script.py` works.
- `ffmpeg` is included for encoding rendered frames into video.
- `bash` and `findutils` (GNU `find`) are included for bash scripts that use `find -printf`.

## license

Blender is free and open-source software released primarily under the GNU General Public License (GPL) v2+ (or v3+ for binaries): [COPYING](https://github.com/blender/blender/blob/main/COPYING), [GPL v2](https://github.com/blender/blender/blob/main/doc/license/GPL-license.txt), [GPL v3](https://github.com/blender/blender/blob/main/doc/license/GPL3-license.txt). The licenses of bundled third-party code are in [doc/license](https://github.com/blender/blender/tree/main/doc/license).
