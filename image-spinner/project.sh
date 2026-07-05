#!/bin/bash

IMAGE_SPINNER_VERSION="0.0.0"

build() {

mkdir -p home
docker build . -t aljazmc/image-spinner
docker tag aljazmc/image-spinner aljazmc/image-spinner:"${IMAGE_SPINNER_VERSION}"
docker tag aljazmc/image-spinner aljazmc/image-spinner:latest

docker image ls
docker run --user aljazmc:aljazmc -v ./home:/home/aljazmc aljazmc/image-spinner

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

docker push -a aljazmc/image-spinner

}

"$@"
