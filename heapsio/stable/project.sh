#!/bin/bash

EXPECTED_HEAPS_IO_VERSION="2.1.0"

DOCKER_ARGS=(
--device /dev/dri:/dev/dri
--device /dev/snd:/dev/snd
--network=host
--user "$USER"
-e DISPLAY="$DISPLAY"
-e XDG_RUNTIME_DIR="$XDG_RUNTIME_DIR"
-v ./home:/home/aljazmc
-v /home/aljazmc/.Xauthority:/home/aljazmc/.Xauthority
-v /run/user/1000:/run/user/1000
-v /tmp/.X11-unix:/tmp.X11-unix
-v /var/lib/dbus/machine-id:/var/lib/dbus/machine-id
-w /home/aljazmc
)

build() {

mkdir -p home
docker build . -t aljazmc/heapsio-stable

ACTUAL_HEAPS_IO_VERSION=$(docker run --rm "${DOCKER_ARGS[@]}" aljazmc/heapsio-stable:latest "docker-entrypoint.sh > /dev/null 2>&1 && haxelib info heaps | grep Version |sed 's/Version\:\ //g'")
docker tag aljazmc/heapsio-stable aljazmc/heapsio-stable:"${ACTUAL_HEAPS_IO_VERSION}"
docker tag aljazmc/heapsio-stable aljazmc/heapsio-stable:latest

docker image ls
docker run "${DOCKER_ARGS[@]}" aljazmc/heapsio-stable:latest
docker run "${DOCKER_ARGS[@]}" aljazmc/heapsio-stable:latest "printenv"
docker run "${DOCKER_ARGS[@]}" aljazmc/heapsio-stable:latest "haxe compile.hxml && hl hello.hl"

}

clean() {

docker system prune -af --volumes

find . -mindepth 1 -maxdepth 1 \
| sed "/Dockerfile/d;/README.md/d;/docker-entrypoint.sh/d;/project.sh/d" \
| xargs -I {} rm -rf {}

}

combo() {

./project.sh clean && ./project.sh build

}

publish() {

ACTUAL_HEAPS_IO_VERSION=$(docker run --rm "${DOCKER_ARGS[@]}" aljazmc/heapsio-stable:latest "docker-entrypoint.sh > /dev/null 2>&1 && haxelib info heaps | grep Version |sed 's/Version\:\ //g'")

[[ "${ACTUAL_HEAPS_IO_VERSION}" == "${EXPECTED_HEAPS_IO_VERSION}" ]] || \
    { echo "ERROR: Unexpected heapsio version"; exit; }

docker push -a aljazmc/heapsio-stable

}

"$@"
