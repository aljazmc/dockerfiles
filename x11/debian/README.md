![Docker Pulls](https://img.shields.io/docker/pulls/aljazmc/x11-debian) ![Docker Image Size](https://img.shields.io/docker/image-size/aljazmc/x11-debian) ![Docker Stars](https://img.shields.io/docker/stars/aljazmc/x11-debian)

# Docker image with x11

[GitHub repository](https://github.com/aljazmc/dockerfiles/tree/main/x11/debian)

## use cases with docker:

###### start container shell
```
docker run --rm -it -v .:/home/x11 -w /home/x11 aljazmc/x11-debian sh -c "bash"
```

###### use shell inside the container to print environment variables
```
docker run --rm -it -v .:/home/x11 -w /home/x11 aljazmc/x11-debian sh -c "printenv"
```

## use cases with docker-compose:

docker-compose.yml file
```
services:
    x11:
        image: aljazmc/x11-debian
        user: $(id -u):$(id -g)
        working_dir: /home/x11
        volumes:
            - .:/home/x11
            - /home/$USER/.Xauthority:/home/x11/.Xauthority
            - /run/user/$(id -u):/run/user/1000
            - /tmp/.X11-unix:/tmp/.X11-unix
            - /var/lib/dbus/machine-id:/var/lib/dbus/machine-id
        devices:
            - /dev/dri:/dev/dri
            - /dev/snd:/dev/snd
        environment:
            DISPLAY: $DISPLAY
            HOME: /home/x11
            XDG_RUNTIME_DIR: /run/user/$(id -u)
        network_mode: host
```

###### start container shell
```
docker-compose run --rm x11 sh -c "sh"
```

###### use shell inside the container to print environment variables
```
docker-compose run --rm x11 sh -c "printenv"
```

##### notes
- not intended for production use.
- passwordless sudo

