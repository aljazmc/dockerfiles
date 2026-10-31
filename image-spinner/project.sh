#!/bin/bash

build() {

if [[ ! -f docker-compose.yml ]]; then
    cat << EOF > docker-compose.yml
services:
    spinner:
        image: aljazmc/image-spinner
        working_dir: /home/aljazmc
        volumes:
            - .:/home/aljazmc
        environment:
            HOME: /home/aljazmc
        network_mode: host
EOF
fi

docker build . -t aljazmc/image-spinner
ACTUAL_ALPINE_VERSION=$(docker run --rm aljazmc/image-spinner "cat /etc/alpine-release")
docker tag aljazmc/image-spinner aljazmc/image-spinner:"${ACTUAL_ALPINE_VERSION}"
docker tag aljazmc/image-spinner aljazmc/image-spinner:latest

docker image ls
docker run --rm --user aljazmc:aljazmc -v .:/home/aljazmc aljazmc/image-spinner

}

clean() {

docker image ls aljazmc/image-spinner -q | sort -u | xargs -r docker rmi -f

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

docker push -a aljazmc/image-spinner && readme

}

hublogin() {

printf '{"username": "%s", "password": "%s"}' "$1" "$2" \
    | curl -fs -H "Content-Type: application/json" -d @- https://hub.docker.com/v2/users/login/ \
    | sed -n 's/.*"token": *"\([^"]*\)".*/\1/p'

}

readme() {

local repository=aljazmc/image-spinner config helper credentials username secret jwt
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
