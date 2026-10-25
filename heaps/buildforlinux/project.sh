#!/bin/bash

EXPECTED_HEAPS_VERSION="2.1.0"
CONTAINER_USER=heaps

DOCKER_ARGS=(
--device /dev/dri:/dev/dri
--device /dev/snd:/dev/snd
--network=host
--user "$CONTAINER_USER"
-e DISPLAY="$DISPLAY"
-e XDG_RUNTIME_DIR=/run/user/1000
-v ".:/home/$CONTAINER_USER"
-v "/home/$USER/.Xauthority:/home/$CONTAINER_USER/.Xauthority"
-v "$XDG_RUNTIME_DIR:/run/user/1000"
-v /tmp/.X11-unix:/tmp/.X11-unix
-v /var/lib/dbus/machine-id:/var/lib/dbus/machine-id
-w "/home/$CONTAINER_USER"
)

build() {

if [ ! -f docker-compose.yml ]; then
    cat <<-EOF > docker-compose.yml
services:
    heaps:
        image: aljazmc/heaps
        working_dir: /home/$CONTAINER_USER
        user: $CONTAINER_USER
        environment:
            DISPLAY: $DISPLAY
            XDG_RUNTIME_DIR: /run/user/1000
        volumes:
            - .:/home/$CONTAINER_USER
            - /home/$USER/.Xauthority:/home/$CONTAINER_USER/.Xauthority
            - $XDG_RUNTIME_DIR:/run/user/1000
            - /tmp/.X11-unix:/tmp/.X11-unix
            - /var/lib/dbus/machine-id:/var/lib/dbus/machine-id
        devices:
            - /dev/dri:/dev/dri
            - /dev/snd:/dev/snd
        network_mode: host
EOF
fi

docker build . -t aljazmc/heaps

ACTUAL_HEAPS_VERSION=$(docker run --rm "${DOCKER_ARGS[@]}" aljazmc/heaps:latest "haxelib list heaps" | sed 's/.*\[\(.*\)\]/\1/')
docker tag aljazmc/heaps aljazmc/heaps:"${ACTUAL_HEAPS_VERSION}"
docker tag aljazmc/heaps aljazmc/heaps:latest

docker image ls
docker run --rm "${DOCKER_ARGS[@]}" aljazmc/heaps:latest
docker run --rm "${DOCKER_ARGS[@]}" aljazmc/heaps:latest "printenv"
docker compose run --rm heaps "haxelib list"
docker run --rm "${DOCKER_ARGS[@]}" aljazmc/heaps:latest "haxe compile.hxml && hl hello.hl"

}

clean() {

docker image ls aljazmc/heaps -q | sort -u | xargs -r docker rmi -f

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

ACTUAL_HEAPS_VERSION=$(docker run --rm "${DOCKER_ARGS[@]}" aljazmc/heaps:latest "haxelib list heaps" | sed 's/.*\[\(.*\)\]/\1/')

[[ "${ACTUAL_HEAPS_VERSION}" == "${EXPECTED_HEAPS_VERSION}" ]] || \
    { echo "ERROR: Unexpected heapsio version"; exit 1; }

docker push -a aljazmc/heaps

}

"$@"
