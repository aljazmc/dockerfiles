#!/bin/bash

build() {

docker build . -t aljazmc/wine-debian

docker tag aljazmc/wine-debian aljazmc/wine-debian:"0.0.0"
docker tag aljazmc/wine-debian aljazmc/wine-debian:latest

docker run aljazmc/wine-debian sh -c "printenv"
docker image ls

}

clean() {

docker system prune -af --volumes

find . -mindepth 1 -maxdepth 1 \
| sed "
    /Dockerfile/d;
    /README.md/d;
    /docker-entrypoint.sh/d;
    /project.sh/d;
    /setup_defcon_1.6_(20793).exe/d;
" \
| xargs -I {} rm -rf {}

}

combo() {

    ./project.sh clean && \
    ./project.sh build

}

config() {

if [[ ! -f docker-compose.yml ]]; then
    cat << EOF > docker-compose.yml
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
            XDG_RUNTIME_DIR: $XDG_RUNTIME_DIR
        network_mode: host
EOF
fi

}

publish() {

docker push -a aljazmc/wine-debian

}

"$@"
