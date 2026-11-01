#!/bin/bash

EXPECTED_COREPACK_VERSION="0.36.0"

build() {

docker build . -t aljazmc/corepack-alpine

ACTUAL_COREPACK_VERSION=$(docker run --rm aljazmc/corepack-alpine sh -c "corepack -v")
docker tag aljazmc/corepack-alpine aljazmc/corepack-alpine:"${ACTUAL_COREPACK_VERSION}"
docker tag aljazmc/corepack-alpine aljazmc/corepack-alpine:latest

docker run --rm aljazmc/corepack-alpine sh -c "printenv"
docker image ls

}

clean() {

docker image ls aljazmc/corepack-alpine -q | sort -u | xargs -r docker rmi -f

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
    ./project.sh update && \
    ./project.sh build

}

config() {

if [[ ! -f docker-compose.yml ]]; then
    cat << EOF > docker-compose.yml
services:
    node:
        image: aljazmc/corepack-alpine
        working_dir: $PWD
        volumes:
            - .:$PWD
        environment:
            HOME: $PWD
        network_mode: host
EOF
fi

}

publish() {

ACTUAL_COREPACK_VERSION=$(docker run --rm aljazmc/corepack-alpine sh -c "corepack -v")

[[ "${ACTUAL_COREPACK_VERSION}" == "${EXPECTED_COREPACK_VERSION}" ]] || \
    { echo "ERROR: Unexpected corepack version"; exit 1; }

docker push -a aljazmc/corepack-alpine

}

"$@"
