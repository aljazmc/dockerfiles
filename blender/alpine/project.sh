#!/bin/bash

GROUP_IDS=($(stat -c %g /dev/dri/renderD* /dev/dri/card* /dev/snd/controlC* 2>/dev/null | sort -un | sed '/^0$/d'))
GROUP_ADD=$(printf '            - "%s"\n' "${GROUP_IDS[@]}")

build() {

docker build . -t aljazmc/blender-alpine

ACTUAL_BLENDER_VERSION=$(docker run --rm aljazmc/blender-alpine blender --version | sed -n "1s/^Blender \([0-9.]*\).*/\1/p")
docker tag aljazmc/blender-alpine aljazmc/blender-alpine:"${ACTUAL_BLENDER_VERSION}"
docker tag aljazmc/blender-alpine aljazmc/blender-alpine:latest

docker run --rm aljazmc/blender-alpine sh -c "printenv"
docker image ls

}

clean() {

docker image ls aljazmc/blender-alpine -q | sort -u | xargs -r docker rmi -f

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

config() {

if [[ ! -f docker-compose.yml ]]; then
    cat << EOF > docker-compose.yml
services:
    blender:
        image: aljazmc/blender-alpine
        user: $(id -u):$(id -g)
        working_dir: /home/blender
        volumes:
            - .:/home/blender
            - /home/$USER/.Xauthority:/home/blender/.Xauthority
            - /run/user/$(id -u):/run/user/1000
            - /tmp/.X11-unix:/tmp/.X11-unix
            - /var/lib/dbus/machine-id:/var/lib/dbus/machine-id
        devices:
            - /dev/dri:/dev/dri
            - /dev/snd:/dev/snd
${GROUP_IDS[*]:+        group_add:
$GROUP_ADD
}        environment:
            DISPLAY: $DISPLAY
            HOME: /home/blender
            XDG_RUNTIME_DIR: /run/user/1000
        network_mode: host
EOF
fi

}

publish() {

docker push -a aljazmc/blender-alpine

}

"$@"
