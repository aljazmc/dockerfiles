#!/bin/bash

EXPECTED_COREPACK_VERSION="0.36.0"

build() {

docker build . -t aljazmc/corepack-debian

ACTUAL_COREPACK_VERSION=$(docker run --rm aljazmc/corepack-debian sh -c "corepack -v")
docker tag aljazmc/corepack-debian aljazmc/corepack-debian:"${ACTUAL_COREPACK_VERSION}"
docker tag aljazmc/corepack-debian aljazmc/corepack-debian:latest

docker run --rm aljazmc/corepack-debian sh -c "printenv"
docker image ls

}

clean() {

docker image ls aljazmc/corepack-debian -q | sort -u | xargs -r docker rmi -f

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
        image: aljazmc/corepack-debian
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

ACTUAL_COREPACK_VERSION=$(docker run --rm aljazmc/corepack-debian sh -c "corepack -v")

[[ "${ACTUAL_COREPACK_VERSION}" == "${EXPECTED_COREPACK_VERSION}" ]] || \
    { echo "ERROR: Unexpected corepack version"; exit 1; }

docker push -a aljazmc/corepack-debian && readme

}

hublogin() {

printf '{"username": "%s", "password": "%s"}' "$1" "$2" \
    | curl -fs -H "Content-Type: application/json" -d @- https://hub.docker.com/v2/users/login/ \
    | sed -n 's/.*"token": *"\([^"]*\)".*/\1/p'

}

readme() {

local repository=aljazmc/corepack-debian config helper credentials username secret jwt
[[ $(wc -c < README.md) -le 25000 ]] || \
    { echo "ERROR: README.md is larger than Docker Hub's 25000 byte limit"; exit 1; }

if [[ -n "${DOCKERHUB_TOKEN}" ]]; then
    username=${DOCKERHUB_USERNAME:-aljazmc}
    secret=${DOCKERHUB_TOKEN}
else
    ## credentials saved by docker login, in a credential helper or in config.json
    config="${DOCKER_CONFIG:-$HOME/.docker}/config.json"
    helper=$(tr -d ' \n\t' 2>/dev/null < "${config}" | sed -n 's/.*"credsStore":"\([^"]*\)".*/\1/p')
    if [[ -n "${helper}" ]]; then
        credentials=$(echo "https://index.docker.io/v1/" | "docker-credential-${helper}" get 2>/dev/null | tr -d ' \n\t')
        username=$(sed -n 's/.*"Username":"\([^"]*\)".*/\1/p' <<< "${credentials}")
        secret=$(sed -n 's/.*"Secret":"\([^"]*\)".*/\1/p' <<< "${credentials}")
    else
        credentials=$(tr -d ' \n\t' 2>/dev/null < "${config}" \
            | sed -n 's|.*"https://index.docker.io/v1/":{"auth":"\([^"]*\)".*|\1|p' | base64 -d 2>/dev/null)
        username=${credentials%%:*}
        secret=${credentials#*:}
    fi
    username=${DOCKERHUB_USERNAME:-${username:-aljazmc}}
fi

[[ -n "${secret}" ]] && jwt=$(hublogin "${username}" "${secret}")

if [[ -z "${jwt}" && -z "${DOCKERHUB_TOKEN}" ]]; then
    [[ -n "${secret}" ]] && echo "The credentials saved by docker login don't work for the Docker Hub API."
    read -rsp "Docker Hub access token for ${username}: " secret
    echo
    jwt=$(hublogin "${username}" "${secret}")
fi
[[ -n "${jwt}" ]] || { echo "ERROR: Docker Hub login failed"; exit 1; }

curl -fsS -o /dev/null -X PATCH -H "Authorization: JWT ${jwt}" \
    --data-urlencode full_description@README.md \
    "https://hub.docker.com/v2/repositories/${repository}/" \
    || { echo "ERROR: README.md upload failed"; exit 1; }
echo "README.md uploaded to https://hub.docker.com/r/${repository}"

}

update() {

LATEST_COREPACK_VERSION="$(docker run --rm aljazmc/corepack-alpine sh -c "NODE_OPTIONS='--no-warnings' npm --silent init --yes &> /dev/null && NODE_OPTIONS='--no-warnings' yarn add corepack --silent &&  NODE_OPTIONS='--no-warnings' yarn info corepack --silent | grep latest | sed \"s/latest\:\ \'//g;s/\'//g;s/\ //g\"")"
# echo $LATEST_COREPACK_VERSION

sed -i "s/^EXPECTED_COREPACK_VERSION=.*/EXPECTED_COREPACK_VERSION=\"$LATEST_COREPACK_VERSION\"/" project.sh

LATEST_NODE_VERSION=$(wget -qO- https://nodejs.org/dist/index.json | grep '"linux-x64"' | grep -v -m 1 '^{"version":"v[^"]*-' | sed 's/^{"version":"v\([^"]*\)".*/\1/')
# echo $LATEST_NODE_VERSION

[[ -n "${LATEST_NODE_VERSION}" ]] || \
    { echo "ERROR: Unable to get latest node version"; exit 1; }

sed -i "s/^\ \ \ \ NODE_VERSION=.*/    NODE_VERSION=\"$LATEST_NODE_VERSION\" \\\/" Dockerfile

}


"$@"
