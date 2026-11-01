#!/bin/bash

EXPECTED_BEVY_VERSION="0.20"
CONTAINER_USER=bevy
GROUP_IDS=($(stat -c %g /dev/dri/renderD* /dev/dri/card* /dev/snd/controlC* 2>/dev/null | sort -un | sed '/^0$/d'))
GROUP_ADD=$(printf '            - "%s"\n' "${GROUP_IDS[@]}")

DOCKER_ARGS=(
--device /dev/dri:/dev/dri
--device /dev/snd:/dev/snd
"${GROUP_IDS[@]/#/--group-add=}"
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
    bevy:
        image: aljazmc/bevy-buildforlinux
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
${GROUP_IDS[*]:+        group_add:
$GROUP_ADD
}        network_mode: host
EOF
fi

docker build . -t aljazmc/bevy-buildforlinux

ACTUAL_BEVY_VERSION=$(docker run --rm "${DOCKER_ARGS[@]}" aljazmc/bevy-buildforlinux:latest "cargo generate-lockfile -q && cargo pkgid bevy" | sed 's/.*@//')
docker tag aljazmc/bevy-buildforlinux aljazmc/bevy-buildforlinux:"${ACTUAL_BEVY_VERSION}"
docker tag aljazmc/bevy-buildforlinux aljazmc/bevy-buildforlinux:latest

docker image ls
docker run --rm "${DOCKER_ARGS[@]}" aljazmc/bevy-buildforlinux:latest
docker run --rm "${DOCKER_ARGS[@]}" aljazmc/bevy-buildforlinux:latest "printenv"
docker compose run --rm bevy "rustc --version && cargo --version"
docker run --rm "${DOCKER_ARGS[@]}" aljazmc/bevy-buildforlinux:latest "cargo run --release"

}

clean() {

docker image ls aljazmc/bevy-buildforlinux -q | sort -u | xargs -r docker rmi -f

find . -mindepth 1 -maxdepth 1 \
    | sed "
        /Dockerfile/d;
        /makesh/d;
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

ACTUAL_BEVY_VERSION=$(docker run --rm "${DOCKER_ARGS[@]}" aljazmc/bevy-buildforlinux:latest "cargo generate-lockfile -q && cargo pkgid bevy" | sed 's/.*@//')

[[ "${ACTUAL_BEVY_VERSION}" == "${EXPECTED_BEVY_VERSION}".* ]] || \
    { echo "ERROR: Unexpected bevy version"; exit 1; }

docker push -a aljazmc/bevy-buildforlinux

}

"$@"
