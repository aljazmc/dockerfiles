#!/bin/bash

EXPECTED_COREPACK_VERSION="0.35.0"

build() {

docker build . -t aljazmc/corepack-alpine

ACTUAL_COREPACK_VERSION=$(docker run aljazmc/corepack-alpine sh -c "corepack -v")
docker tag aljazmc/corepack-alpine aljazmc/corepack-alpine:"${ACTUAL_COREPACK_VERSION}"
docker tag aljazmc/corepack-alpine aljazmc/corepack-alpine:latest

docker run aljazmc/corepack-alpine sh -c "printenv"
docker image ls

}

clean() {

docker system prune -af --volumes

find . -mindepth 1 -maxdepth 1 \
| sed "/Dockerfile/d;/README.md/d;/docker-entrypoint.sh/d;/project.sh/d" \
| xargs -I {} rm -rf {}

}

combo() {

./project.sh clean && ./project.sh build

}

publish() {

ACTUAL_COREPACK_VERSION=$(docker run aljazmc/corepack-alpine sh -c "corepack -v")

[[ "${ACTUAL_COREPACK_VERSION}" == "${EXPECTED_COREPACK_VERSION}" ]] || \
    { echo "ERROR: Unexpected corepack version"; exit; }

docker push -a aljazmc/corepack-alpine

}

"$@"
