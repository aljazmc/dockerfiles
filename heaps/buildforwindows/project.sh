#!/bin/bash

EXPECTED_HEAPS_VERSION="2.1.0"
CONTAINER_USER=heaps

DOCKER_ARGS=(
--device /dev/dri:/dev/dri
--device /dev/snd:/dev/snd
--network=host
--user "$CONTAINER_USER"
-e DISPLAY="$DISPLAY"
-e XDG_RUNTIME_DIR="$XDG_RUNTIME_DIR"
-v .:/home/$CONTAINER_USER
-v /home/"$USER"/.Xauthority:/home/$CONTAINER_USER/.Xauthority
-v /run/user/"$(id -u)":/run/user/1000
-v /tmp/.X11-unix:/tmp.X11-unix
-v /var/lib/dbus/machine-id:/var/lib/dbus/machine-id
-w /home/$CONTAINER_USER
)

build() {

if [ ! -f docker-compose.yml ]; then
    cat <<-EOF > docker-compose.yml
services:
    heaps:
        image: aljazmc/heaps-buildforwindows
        working_dir: /home/$CONTAINER_USER
        user: $CONTAINER_USER
        environment:
            DISPLAY: $DISPLAY
            XDG_RUNTIME_DIR: $XDG_RUNTIME_DIR
        volumes:
            - .:/home/$CONTAINER_USER
            - /home/$USER/.Xauthority:/home/$CONTAINER_USER/.Xauthority
            - /run/user/$(id -u):/run/user/1000
            - /tmp/.X11-unix:/tmp/.X11-unix
            - /var/lib/dbus/machine-id:/var/lib/dbus/machine-id
        devices:
            - /dev/dri:/dev/dri
            - /dev/snd:/dev/snd
        network_mode: host
EOF
fi

docker build . -t aljazmc/heaps-buildforwindows

ACTUAL_HEAPS_VERSION=$(docker run --rm "${DOCKER_ARGS[@]}" aljazmc/heaps-buildforwindows:latest "docker-entrypoint.sh > /dev/null 2>&1 && haxelib info heaps | grep Version | sed 's/Version\:\ //g'")
docker tag aljazmc/heaps-buildforwindows aljazmc/heaps-buildforwindows:"${ACTUAL_HEAPS_VERSION}"
docker tag aljazmc/heaps-buildforwindows aljazmc/heaps-buildforwindows:latest

docker image ls
docker run "${DOCKER_ARGS[@]}" aljazmc/heaps-buildforwindows:latest
docker run "${DOCKER_ARGS[@]}" aljazmc/heaps-buildforwindows:latest "printenv"
docker run "${DOCKER_ARGS[@]}" aljazmc/heaps-buildforwindows:latest "haxe compile.hxml && hl hello.hl"

}

clean() {

docker system prune -af --volumes

find . -mindepth 1 -maxdepth 1 \
    | sed "
        /Dockerfile/d;
        /README.md/d;
        /docker-entrypoint.sh/d;
        /project.sh/d;
    " \
    | xargs -I {} rm -rf {}

}

combo() {

    ./project.sh clean && \
    ./project.sh build

}

publish() {

ACTUAL_HEAPS_VERSION=$(docker run --rm "${DOCKER_ARGS[@]}" aljazmc/heaps-buildforwindows:latest "docker-entrypoint.sh > /dev/null 2>&1 && haxelib info heaps | grep Version | sed 's/Version\:\ //g'")

[[ "${ACTUAL_HEAPS_VERSION}" == "${EXPECTED_HEAPS_VERSION}" ]] || \
    { echo "ERROR: Unexpected heapsio version"; exit; }

docker push -a aljazmc/heaps-buildforwindows

}

"$@"
