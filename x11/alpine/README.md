![Docker Pulls](https://img.shields.io/docker/pulls/aljazmc/x11-alpine) ![Docker Image Size](https://img.shields.io/docker/image-size/aljazmc/x11-alpine) ![Docker Stars](https://img.shields.io/docker/stars/aljazmc/x11-alpine)

# Docker image with x11 on Alpine Linux

[GitHub repository](https://github.com/aljazmc/dockerfiles/tree/main/x11/alpine)

## > Examples with docker:

```
## start container shell
docker run --rm -it -v .:/home/x11 -w /home/x11 aljazmc/x11-alpine sh -c "sh"

## use shell inside the container to print environment variables
docker run --rm -it -v .:/home/x11 -w /home/x11 aljazmc/x11-alpine sh -c "printenv"
```

## > Examples with docker compose:

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

## > Notes
- not intended for production use.
- passwordless doas (`doas apk add ...`)
- the container user needs the host's `render`, `video` and `audio` groups (`group_add`) to use the GPU and the sound card. Without them, apps fall back to software rendering. The group ids differ between distributions: `stat -c %g /dev/dri/renderD128 /dev/dri/card0 /dev/snd/controlC0`.
- there is no X server or audio server inside the container. Apps use the host's X server (`DISPLAY`, `/tmp/.X11-unix`) and the host's PipeWire/PulseAudio (`XDG_RUNTIME_DIR`).
- Alpine Linux uses musl instead of glibc, so binaries built on glibc distributions (e.g. Debian, Ubuntu, Fedora) don't run here. Use Alpine packages or programs built on Alpine.

## > License

The X Window System libraries from X.Org are free and open-source software released mostly under the MIT/X11 license and similar permissive licenses: [X.Org licenses](https://www.x.org/releases/current/doc/xorg-docs/License.html). Each component has its own `COPYING` file in its repository on [gitlab.freedesktop.org/xorg](https://gitlab.freedesktop.org/xorg).
