#!/bin/bash

GROUP_IDS=($(stat -c %g /dev/dri/renderD* /dev/dri/card* /dev/snd/controlC* 2>/dev/null | sort -un | sed '/^0$/d'))
GROUP_ADD=$(printf '            - "%s"\n' "${GROUP_IDS[@]}")

build() {

docker build . -t aljazmc/x11-alpine

ACTUAL_X11_VERSION=$(docker run --rm aljazmc/x11-alpine apk version -v libx11 | sed -n 's/^libx11-\([0-9.]*\)-r.*/\1/p')
docker tag aljazmc/x11-alpine aljazmc/x11-alpine:"${ACTUAL_X11_VERSION}"
docker tag aljazmc/x11-alpine aljazmc/x11-alpine:latest

docker run --rm aljazmc/x11-alpine sh -c "printenv"
docker image ls

}

clean() {

docker image ls aljazmc/x11-alpine -q | sort -u | xargs -r docker rmi -f

find . -mindepth 1 -maxdepth 1 \
    | sed "
        /Dockerfile/d;
        /README.md/d;
        /docker-entrypoint.sh/d;
        /gog_defcon_2.0.0.5.sh/d;
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
    x11:
        image: aljazmc/x11-alpine
        user: $(id -u):$(id -g)
        working_dir: /home/x11
        volumes:
            - .:/home/x11
            - /home/$USER/.Xauthority:/home/x11/.Xauthority
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
            HOME: /home/x11
            XDG_RUNTIME_DIR: /run/user/1000
        network_mode: host
EOF
fi

}

publish() {

docker push -a aljazmc/x11-alpine

}

"$@"
