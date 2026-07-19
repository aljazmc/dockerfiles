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
| sed "
    /Dockerfile/d;
    /README.md/d;
    /docker-entrypoint.sh/d;
    /project.sh/d;
" \
| xargs -I {} rm -rf {}

}

combo() {

./project.sh clean && ./project.sh update && ./project.sh build

}

publish() {

ACTUAL_COREPACK_VERSION=$(docker run aljazmc/corepack-alpine sh -c "corepack -v")

[[ "${ACTUAL_COREPACK_VERSION}" == "${EXPECTED_COREPACK_VERSION}" ]] || \
    { echo "ERROR: Unexpected corepack version"; exit; }

docker push -a aljazmc/corepack-alpine

}

update() {

LATEST_COREPACK_VERSION="$(docker run --rm aljazmc/corepack-alpine sh -c "NODE_OPTIONS='--no-warnings' npm --silent init --yes &> /dev/null && NODE_OPTIONS='--no-warnings' yarn add corepack --silent &&  NODE_OPTIONS='--no-warnings' yarn info corepack --silent | grep latest | sed \"s/latest\:\ \'//g;s/\'//g;s/\ //g\"")"
# echo $LATEST_COREPACK_VERSION

sed -i "s/^EXPECTED_COREPACK_VERSION=.*/EXPECTED_COREPACK_VERSION=\"$LATEST_COREPACK_VERSION\"/" project.sh

LATEST_NODE_VERSION=$(wget -q https://unofficial-builds.nodejs.org/download/release 1>/dev/null && cat release | sed '/v[0-9]/!d;s/<a\ href="//g;s/\/.*//;/v8\./d;s/v//g' | tail -n 1 && rm release)
# echo $LATEST_NODE_VERSION

sed -i "s/^ARG\ NODE_VERSION=.*/ARG NODE_VERSION=\"$LATEST_NODE_VERSION\" \\\/" Dockerfile

LATEST_SHA_NUMBER=$(wget -q https://unofficial-builds.nodejs.org/download/release/v${LATEST_NODE_VERSION}/node-v${LATEST_NODE_VERSION}-linux-x64-musl.tar.xz && sha256sum node-v${LATEST_NODE_VERSION}-linux-x64-musl.tar.xz | awk '{print $1}' && rm node-v${LATEST_NODE_VERSION}-linux-x64-musl.tar.xz)
# echo $LATEST_SHA_NUMBER

sed -i "s/^\ \ \ \ SHA=.*/    SHA=\"$LATEST_SHA_NUMBER\" \\\/" Dockerfile

}

"$@"
