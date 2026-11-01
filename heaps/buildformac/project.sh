#!/bin/bash

EXPECTED_HEAPS_VERSION="2.1.0"
CONTAINER_USER=heaps

DOCKER_ARGS=(
--user "$CONTAINER_USER"
-v ".:/home/$CONTAINER_USER"
-w "/home/$CONTAINER_USER"
)

build() {

if [ ! -f docker-compose.yml ]; then
    cat <<-EOF > docker-compose.yml
services:
    heaps:
        image: aljazmc/heaps-buildformac
        working_dir: /home/$CONTAINER_USER
        user: $CONTAINER_USER
        volumes:
            - .:/home/$CONTAINER_USER
EOF
fi

docker build . -t aljazmc/heaps-buildformac

ACTUAL_HEAPS_VERSION=$(docker run --rm "${DOCKER_ARGS[@]}" aljazmc/heaps-buildformac:latest "haxelib list heaps" | sed 's/.*\[\(.*\)\]/\1/')
docker tag aljazmc/heaps-buildformac aljazmc/heaps-buildformac:"${ACTUAL_HEAPS_VERSION}"
docker tag aljazmc/heaps-buildformac aljazmc/heaps-buildformac:latest

docker image ls
docker run --rm "${DOCKER_ARGS[@]}" aljazmc/heaps-buildformac:latest
docker run --rm "${DOCKER_ARGS[@]}" aljazmc/heaps-buildformac:latest "printenv"
docker compose run --rm heaps "haxelib list"
docker run --rm "${DOCKER_ARGS[@]}" aljazmc/heaps-buildformac:latest "haxe compile.hxml && ls -l hello.hl"

}

clean() {

docker image ls aljazmc/heaps-buildformac -q | sort -u | xargs -r docker rmi -f

find . -mindepth 1 -maxdepth 1 \
    | sed "
        /Dockerfile/d;
        /bundle/d;
        /makedmg/d;
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

ACTUAL_HEAPS_VERSION=$(docker run --rm "${DOCKER_ARGS[@]}" aljazmc/heaps-buildformac:latest "haxelib list heaps" | sed 's/.*\[\(.*\)\]/\1/')

[[ "${ACTUAL_HEAPS_VERSION}" == "${EXPECTED_HEAPS_VERSION}" ]] || \
    { echo "ERROR: Unexpected heapsio version"; exit 1; }

docker push -a aljazmc/heaps-buildformac

}

"$@"
