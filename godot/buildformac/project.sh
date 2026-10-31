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
        image: aljazmc/godot-buildformac
        working_dir: /home/$CONTAINER_USER
        user: $CONTAINER_USER
        volumes:
            - .:/home/$CONTAINER_USER
EOF
fi

docker build . -t aljazmc/godot-buildformac

ACTUAL_GODOT_VERSION=$(docker run --rm "${DOCKER_ARGS[@]}" aljazmc/godot-buildformac:latest "godot --version" | sed 's/\.stable.*//')
docker tag aljazmc/godot-buildformac aljazmc/godot-buildformac:"${ACTUAL_GODOT_VERSION}"
docker tag aljazmc/godot-buildformac aljazmc/godot-buildformac:latest

docker image ls
docker run --rm "${DOCKER_ARGS[@]}" aljazmc/godot-buildformac:latest
docker run --rm "${DOCKER_ARGS[@]}" aljazmc/godot-buildformac:latest "printenv"
docker compose run --rm godot "godot --version"
docker run --rm "${DOCKER_ARGS[@]}" aljazmc/godot-buildformac:latest "godot --headless --import && godot --headless --export-release macOS build/macos/hello.zip && ls -l build/macos/hello.zip"

}

clean() {

docker image ls aljazmc/godot-buildformac -q | sort -u | xargs -r docker rmi -f

find . -mindepth 1 -maxdepth 1 \
    | sed "
        /Dockerfile/d;
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

ACTUAL_GODOT_VERSION=$(docker run --rm "${DOCKER_ARGS[@]}" aljazmc/godot-buildformac:latest "godot --version" | sed 's/\.stable.*//')

[[ "${ACTUAL_GODOT_VERSION}" == "${EXPECTED_GODOT_VERSION}" ]] || \
    { echo "ERROR: Unexpected godot version"; exit 1; }

docker push -a aljazmc/godot-buildformac && readme

}

hublogin() {

printf '{"username": "%s", "password": "%s"}' "$1" "$2" \
    | curl -fs -H "Content-Type: application/json" -d @- https://hub.docker.com/v2/users/login/ \
    | sed -n 's/.*"token": *"\([^"]*\)".*/\1/p'

}

readme() {

local repository=aljazmc/godot-buildformac config helper credentials username secret jwt
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

"$@"
