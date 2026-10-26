#!/bin/bash

EXPECTED_BEVY_VERSION="0.20.0"
CONTAINER_USER=bevy

DOCKER_ARGS=(
--user "$CONTAINER_USER"
-v ".:/home/$CONTAINER_USER"
-w "/home/$CONTAINER_USER"
)

build() {

if [ ! -f docker-compose.yml ]; then
    cat <<-EOF > docker-compose.yml
services:
    bevy:
        image: aljazmc/bevy-buildforwindows
        working_dir: /home/$CONTAINER_USER
        user: $CONTAINER_USER
        volumes:
            - .:/home/$CONTAINER_USER
EOF
fi

docker build . -t aljazmc/bevy-buildforwindows

ACTUAL_BEVY_VERSION=$(docker run --rm "${DOCKER_ARGS[@]}" aljazmc/bevy-buildforwindows:latest "cargo generate-lockfile -q && cargo pkgid bevy" | sed 's/.*@//')
docker tag aljazmc/bevy-buildforwindows aljazmc/bevy-buildforwindows:"${ACTUAL_BEVY_VERSION}"
docker tag aljazmc/bevy-buildforwindows aljazmc/bevy-buildforwindows:latest

docker image ls
docker run --rm "${DOCKER_ARGS[@]}" aljazmc/bevy-buildforwindows:latest
docker run --rm "${DOCKER_ARGS[@]}" aljazmc/bevy-buildforwindows:latest "printenv"
docker compose run --rm bevy "rustc --version && cargo --version"
docker run --rm "${DOCKER_ARGS[@]}" aljazmc/bevy-buildforwindows:latest "cargo build --release --target x86_64-pc-windows-gnu && ls -l target/x86_64-pc-windows-gnu/release/hello.exe"

}

clean() {

docker image ls aljazmc/bevy-buildforwindows -q | sort -u | xargs -r docker rmi -f

find . -mindepth 1 -maxdepth 1 \
    | sed "
        /Dockerfile/d;
        /makeexe/d;
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

ACTUAL_BEVY_VERSION=$(docker run --rm "${DOCKER_ARGS[@]}" aljazmc/bevy-buildforwindows:latest "cargo generate-lockfile -q && cargo pkgid bevy" | sed 's/.*@//')

[[ "${ACTUAL_BEVY_VERSION}" == "${EXPECTED_BEVY_VERSION}" ]] || \
    { echo "ERROR: Unexpected bevy version"; exit 1; }

docker push -a aljazmc/bevy-buildforwindows

}

"$@"
