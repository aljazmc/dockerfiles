![Docker Pulls](https://img.shields.io/docker/pulls/aljazmc/wine-debian) ![Docker Image Size](https://img.shields.io/docker/image-size/aljazmc/wine-debian) ![Docker Stars](https://img.shields.io/docker/stars/aljazmc/wine-debian)

# Docker image with wine

[GitHub repository](https://github.com/aljazmc/dockerfiles/tree/main/wine/debian)

## use cases with docker:

###### start container shell
```
docker run --rm -it -v .:/home/wine -w /home/wine aljazmc/wine-debian sh -c "bash"
```

###### use shell inside the container to print environment variables
```
docker run --rm -it -v .:/home/wine -w /home/wine aljazmc/wine-debian sh -c "printenv"
```

## use cases with docker-compose:

docker-compose.yml file
```
services:
    wine:
        image: aljazmc/wine-debian
        user: $(id -u):$(id -g)
        working_dir: /home/wine
        volumes:
            - .:/home/wine
            - /home/$USER/.Xauthority:/home/wine/.Xauthority
            - /run/user/$(id -u):/run/user/1000
            - /tmp/.X11-unix:/tmp/.X11-unix
            - /var/lib/dbus/machine-id:/var/lib/dbus/machine-id
        devices:
            - /dev/dri:/dev/dri
            - /dev/snd:/dev/snd
        environment:
            DISPLAY: $DISPLAY
            HOME: /home/wine
            XDG_RUNTIME_DIR: /run/user/$(id -u)
        network_mode: host
```

###### start container shell
```
docker-compose run --rm wine sh -c "sh"
```

###### use shell inside the container to print environment variables
```
docker-compose run --rm wine sh -c "printenv"
```

##### notes
- not intended for production use.
- passwordless sudo

