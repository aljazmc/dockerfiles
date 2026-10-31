#!/bin/bash

EXPECTED_BEVY_VERSION="0.20"
CONTAINER_USER=bevy
GROUP_IDS=($(stat -c %g /dev/dri/renderD* /dev/dri/card* /dev/snd/controlC* 2>/dev/null | sort -un | sed '/^0$/d'))
GROUP_ADD=$(printf '            - "%s"\n' "${GROUP_IDS[@]}")

DOCKER_ARGS=(
--device /dev/dri:/dev/dri
--device /dev/snd:/dev/snd
"${GROUP_IDS[@]/#/--group-add=}"
--network=host
--user "$CONTAINER_USER"
-e DISPLAY="$DISPLAY"
-e XDG_RUNTIME_DIR=/run/user/1000
-v ".:/home/$CONTAINER_USER"
-v "/home/$USER/.Xauthority:/home/$CONTAINER_USER/.Xauthority"
-v "$XDG_RUNTIME_DIR:/run/user/1000"
-v /tmp/.X11-unix:/tmp/.X11-unix
-v /var/lib/dbus/machine-id:/var/lib/dbus/machine-id
-w "/home/$CONTAINER_USER"
)

build() {

if [ ! -f docker-compose.yml ]; then
    cat <<-EOF > docker-compose.yml
services:
    bevy:
        image: aljazmc/bevy-buildforlinux
        working_dir: /home/$CONTAINER_USER
        user: $CONTAINER_USER
        environment:
            DISPLAY: $DISPLAY
            XDG_RUNTIME_DIR: /run/user/1000
        volumes:
            - .:/home/$CONTAINER_USER
            - /home/$USER/.Xauthority:/home/$CONTAINER_USER/.Xauthority
            - $XDG_RUNTIME_DIR:/run/user/1000
            - /tmp/.X11-unix:/tmp/.X11-unix
            - /var/lib/dbus/machine-id:/var/lib/dbus/machine-id
        devices:
            - /dev/dri:/dev/dri
            - /dev/snd:/dev/snd
${GROUP_IDS[*]:+        group_add:
$GROUP_ADD
}        network_mode: host
EOF
fi

docker build . -t aljazmc/bevy-buildforlinux

ACTUAL_BEVY_VERSION=$(docker run --rm "${DOCKER_ARGS[@]}" aljazmc/bevy-buildforlinux:latest "cargo generate-lockfile -q && cargo pkgid bevy" | sed 's/.*@//')
docker tag aljazmc/bevy-buildforlinux aljazmc/bevy-buildforlinux:"${ACTUAL_BEVY_VERSION}"
docker tag aljazmc/bevy-buildforlinux aljazmc/bevy-buildforlinux:latest

docker image ls
docker run --rm "${DOCKER_ARGS[@]}" aljazmc/bevy-buildforlinux:latest
docker run --rm "${DOCKER_ARGS[@]}" aljazmc/bevy-buildforlinux:latest "printenv"
docker compose run --rm bevy "rustc --version && cargo --version"
docker run --rm "${DOCKER_ARGS[@]}" aljazmc/bevy-buildforlinux:latest "cargo run --release"

}

clean() {

docker image ls aljazmc/bevy-buildforlinux -q | sort -u | xargs -r docker rmi -f

find . -mindepth 1 -maxdepth 1 \
    | sed "
        /Dockerfile/d;
        /makesh/d;
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

ACTUAL_BEVY_VERSION=$(docker run --rm "${DOCKER_ARGS[@]}" aljazmc/bevy-buildforlinux:latest "cargo generate-lockfile -q && cargo pkgid bevy" | sed 's/.*@//')

[[ "${ACTUAL_BEVY_VERSION}" == "${EXPECTED_BEVY_VERSION}".* ]] || \
    { echo "ERROR: Unexpected bevy version"; exit 1; }

docker push -a aljazmc/bevy-buildforlinux && readme

}

hublogin() {

printf '{"username": "%s", "password": "%s"}' "$1" "$2" \
    | curl -fs -H "Content-Type: application/json" -d @- https://hub.docker.com/v2/users/login/ \
    | sed -n 's/.*"token": *"\([^"]*\)".*/\1/p'

}

readme() {

local repository=aljazmc/bevy-buildforlinux config helper credentials username secret jwt
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
