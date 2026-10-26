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

docker push -a aljazmc/image-spinner

}

"$@"
