#!/bin/bash

EXPECTED_GODOT_VERSION="4.7.2"
CONTAINER_USER=godot

DOCKER_ARGS=(
--user "$CONTAINER_USER"
-v ".:/home/$CONTAINER_USER"
-w "/home/$CONTAINER_USER"
)

build() {

if [ ! -f docker-compose.yml ]; then
    cat <<-EOF > docker-compose.yml
services:
    godot:
        image: aljazmc/godot-buildforwindows
        working_dir: /home/$CONTAINER_USER
        user: $CONTAINER_USER
        volumes:
            - .:/home/$CONTAINER_USER
EOF
fi

docker build . -t aljazmc/godot-buildforwindows

ACTUAL_GODOT_VERSION=$(docker run --rm "${DOCKER_ARGS[@]}" aljazmc/godot-buildforwindows:latest "godot --version" | sed 's/\.stable.*//')
docker tag aljazmc/godot-buildforwindows aljazmc/godot-buildforwindows:"${ACTUAL_GODOT_VERSION}"
docker tag aljazmc/godot-buildforwindows aljazmc/godot-buildforwindows:latest

docker image ls
docker run --rm "${DOCKER_ARGS[@]}" aljazmc/godot-buildforwindows:latest
docker run --rm "${DOCKER_ARGS[@]}" aljazmc/godot-buildforwindows:latest "printenv"
docker compose run --rm godot "godot --version"
docker run --rm "${DOCKER_ARGS[@]}" aljazmc/godot-buildforwindows:latest "godot --headless --import && godot --headless --export-release \"Windows Desktop\" build/windows/hello.exe && ls -l build/windows/hello.exe"

}

clean() {

docker image ls aljazmc/godot-buildforwindows -q | sort -u | xargs -r docker rmi -f

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

ACTUAL_GODOT_VERSION=$(docker run --rm "${DOCKER_ARGS[@]}" aljazmc/godot-buildforwindows:latest "godot --version" | sed 's/\.stable.*//')

[[ "${ACTUAL_GODOT_VERSION}" == "${EXPECTED_GODOT_VERSION}" ]] || \
    { echo "ERROR: Unexpected godot version"; exit 1; }

docker push -a aljazmc/godot-buildforwindows

}

"$@"
