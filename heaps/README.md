![Docker Pulls](https://img.shields.io/docker/pulls/aljazmc/heaps) ![Docker Image Size](https://img.shields.io/docker/image-size/aljazmc/heaps) ![Docker Stars](https://img.shields.io/docker/stars/aljazmc/heaps)

# Docker image with Heaps, Haxe, Neko and Hashlink

[GitHub repository](https://github.com/aljazmc/dockerfiles/tree/main/heaps)

## use cases with docker:

###### prepare a directory for development:
```
docker run
--device /dev/dri:/dev/dri \
--device /dev/snd:/dev/snd \
--network=host \
--user "$USER" \
-e DISPLAY="$DISPLAY" \
-e XDG_RUNTIME_DIR="$XDG_RUNTIME_DIR" \
-v .:/home/aljazmc \
-v /home/$USER/.Xauthority:/home/aljazmc/.Xauthority \
-v /run/user/$(id -u):/run/user/1000 \
-v /tmp/.X11-unix:/tmp.X11-unix \
-v /var/lib/dbus/machine-id:/var/lib/dbus/machine-id \
-w /home/aljazmc \
aljazmc/heaps:latest
```

###### afterwards append shell commands in the end:
```
docker run 
--device /dev/dri:/dev/dri \
--device /dev/snd:/dev/snd \
--network=host \
--user "$USER" \
-e DISPLAY="$DISPLAY" \
-e XDG_RUNTIME_DIR="$XDG_RUNTIME_DIR" \
-v ./home:/home/aljazmc \
-v /home/$USER/.Xauthority:/home/aljazmc/.Xauthority \
-v /run/user/$(id -u):/run/user/1000 \
-v /tmp/.X11-unix:/tmp.X11-unix \
-v /var/lib/dbus/machine-id:/var/lib/dbus/machine-id \
-w /home/aljazmc \
aljazmc/heaps:latest "haxe compile.hxml && hl hello.hl"
```

## use cases with docker compose

###### prepare a directory for development:
```
# docker-compose.yml example for GNU/Linux host
services:
    heaps:
        image: aljazmc/heaps
        working_dir: /home/aljazmc
        user: $USER
        environment:
            DISPLAY: $DISPLAY
            XDG_RUNTIME_DIR: $XDG_RUNTIME_DIR
        volumes:
            - .:/home/aljazmc
            - /home/$USER/.Xauthority:/root/.Xauthority
            - /run/user/$(id -u):/run/user/1000
            - /tmp/.X11-unix:/tmp/.X11-unix
            - /var/lib/dbus/machine-id:/var/lib/dbus/machine-id
        devices:
            - /dev/dri:/dev/dri
            - /dev/snd:/dev/snd
        network_mode: host

# command
docker compose run --rm heaps
```

###### afterwards append shell commands in the end:
```
docker compose run --rm heaps "haxe compile.hxml && hl hello.hl"
```

