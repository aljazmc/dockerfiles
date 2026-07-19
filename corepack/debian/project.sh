#!/bin/bash

EXPECTED_COREPACK_VERSION="0.35.0"

build() {

docker build . -t aljazmc/corepack-debian

ACTUAL_COREPACK_VERSION=$(docker run aljazmc/corepack-debian sh -c "corepack -v")
docker tag aljazmc/corepack-debian aljazmc/corepack-debian:"${ACTUAL_COREPACK_VERSION}"
docker tag aljazmc/corepack-debian aljazmc/corepack-debian:latest

docker run aljazmc/corepack-debian sh -c "printenv"
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

./project.sh clean && ./project.sh build

}

publish() {

ACTUAL_COREPACK_VERSION=$(docker run aljazmc/corepack-debian sh -c "corepack -v")

[[ "${ACTUAL_COREPACK_VERSION}" == "${EXPECTED_COREPACK_VERSION}" ]] || \
    { echo "ERROR: Unexpected corepack version"; exit; }

docker push -a aljazmc/corepack-debian

}

update() {

LATEST_COREPACK_VERSION="$(docker run --rm aljazmc/corepack-alpine sh -c "NODE_OPTIONS='--no-warnings' npm --silent init --yes &> /dev/null && NODE_OPTIONS='--no-warnings' yarn add corepack --silent &&  NODE_OPTIONS='--no-warnings' yarn info corepack --silent | grep latest | sed \"s/latest\:\ \'//g;s/\'//g;s/\ //g\"")"
# echo $LATEST_COREPACK_VERSION

sed -i "s/^EXPECTED_COREPACK_VERSION=.*/EXPECTED_COREPACK_VERSION=\"$LATEST_COREPACK_VERSION\"/" project.sh

LATEST_NODE_VERSION=$(wget -q https://nodejs.org/dist/ &>/dev/null && cat index.html | sed '/dist/d;/v[0-9]\./d;s/\/.*//;s/<a\ href="v//g;/^<$/d' | tail -n 1 && rm index.html)
# echo $LATEST_NODE_VERSION

sed -i "s/^\ \ \ \ NODE_VERSION=.*/    NODE_VERSION=\"$LATEST_NODE_VERSION\" \\\/" Dockerfile

}


"$@"
