![Docker Pulls](https://img.shields.io/docker/pulls/aljazmc/wine-alpine) ![Docker Image Size](https://img.shields.io/docker/image-size/aljazmc/wine-alpine) ![Docker Stars](https://img.shields.io/docker/stars/aljazmc/wine-alpine)

# Docker image with Wine on Alpine Linux

[GitHub repository](https://github.com/aljazmc/dockerfiles/tree/main/wine/alpine)

## > Examples with docker:

```
## start container shell
docker run --rm -it -v .:/home/wine -w /home/wine aljazmc/wine-alpine sh -c "sh"

## use shell inside the container to print environment variables
docker run --rm -it -v .:/home/wine -w /home/wine aljazmc/wine-alpine sh -c "printenv"
```

## > Examples with docker compose:

```
## docker-compose.yml file
services:
    wine:
        image: aljazmc/wine-alpine
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

## > Notes
- not intended for production use.
- passwordless doas (`doas apk add ...`)
- the container user needs the host's `render`, `video` and `audio` groups (`group_add`) to use the GPU and the sound card. Without them, apps fall back to software rendering. The group ids differ between distributions: `stat -c %g /dev/dri/renderD128 /dev/dri/card0 /dev/snd/controlC0`.
- there is no X server or audio server inside the container. Apps use the host's X server (`DISPLAY`, `/tmp/.X11-unix`) and the host's PipeWire/PulseAudio (`XDG_RUNTIME_DIR`).
- on the first start of a new prefix Wine asks to install Wine Mono (needed for .NET applications) and Wine Gecko (needed for applications with an embedded browser). To skip both, set `WINEDLLOVERRIDES="mscoree,mshtml="`, e.g. `docker compose run --rm -e WINEDLLOVERRIDES="mscoree,mshtml=" wine sh -c "wineboot -i"`.
- 32-bit and 64-bit Windows applications are supported, with OpenGL and Vulkan (DXVK, VKD3D).

## > License

Wine is free and open-source software released under the GNU Lesser General Public License (LGPL) v2.1+: [LICENSE](https://github.com/wine-mirror/wine/blob/master/LICENSE), [COPYING.LIB](https://github.com/wine-mirror/wine/blob/master/COPYING.LIB) (GitHub mirror of [gitlab.winehq.org/wine/wine](https://gitlab.winehq.org/wine/wine)).
