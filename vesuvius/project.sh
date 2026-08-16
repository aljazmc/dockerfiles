#!/bin/bash

VESUVIUS_VERSION="0.0.0"

build() {

if [[ ! -f docker-compose.yml ]]; then
    cat << EOF > docker-compose.yml
services:
    vesuvius:
        image: aljazmc/vesuvius
        working_dir: /home/aljazmc
        volumes:
            - .:/home/aljazmc
        environment:
            HOME: /home/aljazmc
        network_mode: host
EOF
fi

docker build . -t aljazmc/vesuvius

ACTUAL_VESUVIUS_VERSION="${VESUVIUS_VERSION}"
docker tag aljazmc/vesuvius aljazmc/vesuvius:"${ACTUAL_VESUVIUS_VERSION}"
docker tag aljazmc/vesuvius aljazmc/vesuvius:latest

docker run -v .:/home/aljazmc aljazmc/vesuvius
docker run -v .:/home/aljazmc aljazmc/vesuvius sh -c "printenv"
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

docker push -a aljazmc/vesuvius

}

"$@"
