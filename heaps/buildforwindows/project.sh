#!/bin/bash

EXPECTED_HEAPS_VERSION="2.1.0"
CONTAINER_USER=heaps

DOCKER_ARGS=(
--user "$CONTAINER_USER"
-v ".:/home/$CONTAINER_USER"
-w "/home/$CONTAINER_USER"
)

build() {

if [ ! -f docker-compose.yml ]; then
    cat <<-EOF > docker-compose.yml
services:
    heaps:
        image: aljazmc/heaps-buildforwindows
        working_dir: /home/$CONTAINER_USER
        user: $CONTAINER_USER
        volumes:
            - .:/home/$CONTAINER_USER
EOF
fi

docker build . -t aljazmc/heaps-buildforwindows

ACTUAL_HEAPS_VERSION=$(docker run --rm "${DOCKER_ARGS[@]}" aljazmc/heaps-buildforwindows:latest "haxelib list heaps" | sed 's/.*\[\(.*\)\]/\1/')
docker tag aljazmc/heaps-buildforwindows aljazmc/heaps-buildforwindows:"${ACTUAL_HEAPS_VERSION}"
docker tag aljazmc/heaps-buildforwindows aljazmc/heaps-buildforwindows:latest

docker image ls
docker run --rm "${DOCKER_ARGS[@]}" aljazmc/heaps-buildforwindows:latest
docker run --rm "${DOCKER_ARGS[@]}" aljazmc/heaps-buildforwindows:latest "printenv"
docker compose run --rm heaps "haxelib list"
docker run --rm "${DOCKER_ARGS[@]}" aljazmc/heaps-buildforwindows:latest "haxe compile.hxml && ls -l hello.hl"
docker run --rm "${DOCKER_ARGS[@]}" aljazmc/heaps-buildforwindows:latest '
haxe -cp src -lib format -lib heaps -lib hlsdl -hl out/main.c -main Main &&
x86_64-w64-mingw32-gcc -O2 -std=c11 -municode \
    -I out -I "$HASHLINK_WIN64/include" out/main.c -o hello.exe \
    -L "$HASHLINK_WIN64" -l:libhl.lib -l:fmt.lib -l:heaps.lib -l:openal.lib -l:sdl.lib -l:ui.lib -l:uv.lib \
    -ldbghelp &&
ls -l hello.exe
'

}

clean() {

docker image ls aljazmc/heaps-buildforwindows -q | sort -u | xargs -r docker rmi -f

find . -mindepth 1 -maxdepth 1 \
    | sed "
        /Dockerfile/d;
        /bundle/d;
        /makeexe/d;
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

ACTUAL_HEAPS_VERSION=$(docker run --rm "${DOCKER_ARGS[@]}" aljazmc/heaps-buildforwindows:latest "haxelib list heaps" | sed 's/.*\[\(.*\)\]/\1/')

[[ "${ACTUAL_HEAPS_VERSION}" == "${EXPECTED_HEAPS_VERSION}" ]] || \
    { echo "ERROR: Unexpected heapsio version"; exit 1; }

docker push -a aljazmc/heaps-buildforwindows

}

"$@"
