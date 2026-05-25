#!/bin/bash

EXPECTED_HEAPS_IO_VERSION="2.1.0"

build() {

if [[ ! -f home/compile.hxml ]]; then
    mkdir -p home
    cat <<-EOF > home/compile.hxml
-cp src
-lib format
-lib heaps
-lib hlsdl
-hl hello.hl
-main Main
EOF
fi

if [[ ! -f home/docker-compose.yml ]]; then
    mkdir -p home
    cat <<-EOF > home/docker-compose.yml
services:
    heapsio:
        build: .
        working_dir: /home/$USER
        user: $PROJECT_UID:$PROJECT_GID
        environment:
            DISPLAY: $DISPLAY
            XDG_RUNTIME_DIR: $XDG_RUNTIME_DIR
        volumes:
            - .:/home/$USER
            - ./haxelib:/usr/lib/haxe/lib
            - /tmp/.X11-unix:/tmp/.X11-unix
            - /run/user/${PROJECT_UID}:/run/user/${PROJECT_UID}
            - /var/lib/dbus/machine-id:/var/lib/dbus/machine-id
            - ~/.Xauthority:/root/.Xauthority
        devices:
            - /dev/dri:/dev/dri
            - /dev/snd:/dev/snd
        network_mode: host
EOF
fi

if [[ ! -f home/src/Main.hx ]]; then
    mkdir home/src
    cat <<-EOF > home/src/Main.hx
class Main extends hxd.App {
    override function init() {
        var tf = new h2d.Text(hxd.res.DefaultFont.get(), s2d);
        tf.text = "Hello Hashlink !";
    }
    static function main() {
        new Main();
    }
}
EOF
fi

docker build . -t aljazmc/heapsio-debian

#ACTUAL_HEAPS_IO_VERSION=$(docker run --rm aljazmc/heapsio-debian:latest sh -c "haxelib info heaps | grep Version |sed 's/Version\:\ //g'")
#docker tag aljazmc/heapsio-debian aljazmc/heapsio-debian:"${ACTUAL_HEAPS_IO_VERSION}"
docker tag aljazmc/heapsio-debian aljazmc/heapsio-debian:latest

docker run aljazmc/heapsio-debian:latest sh -c "printenv"
docker image ls
docker run \
--device /dev/dri:/dev/dri \
--device /dev/snd:/dev/snd \
-e DISPLAY="$DISPLAY" \
-e XDG_RUNTIME_DIR="$XDG_RUNTIME_DIR" \
-e PATH="/usr/src/hashlink:$PATH" \
-v ./home:/home/aljazmc \
-v /run/user/1000:/run/user/1000 \
-v /home/aljazmc/.Xauthority:/home/aljazmc/.Xauthority \
-v /tmp/.X11-unix:/tmp.X11-unix \
-v /var/lib/dbus/machine-id:/var/lib/dbus/machine-id \
-w /home/aljazmc \
--network=host \
aljazmc/heapsio-debian:latest sh -c "\
haxelib setup haxelib \
&& haxelib install format \
&& haxelib install heaps \
&& haxelib install hlopenal \
&& haxelib install hlsdl \
&& haxelib install hldx \
&& haxe compile.hxml \
&& hl hello.hl"


if [[ ! -f home/compile.hxml ]]; then
    cat <<-EOF > home/compile.hxml
-cp src
-lib format
-lib heaps
-lib hlsdl
-hl hello.hl
-main Main
EOF
fi

if [[ ! -f home/docker-compose.yml ]]; then
    cat <<-EOF > home/docker-compose.yml
services:
    heapsio:
        build: .
        working_dir: /home/$USER
        user: $PROJECT_UID:$PROJECT_GID
        environment:
            DISPLAY: $DISPLAY
            XDG_RUNTIME_DIR: $XDG_RUNTIME_DIR
        volumes:
            - .:/home/$USER
            - ./haxelib:/usr/lib/haxe/lib
            - /tmp/.X11-unix:/tmp/.X11-unix
            - /run/user/${PROJECT_UID}:/run/user/${PROJECT_UID}
            - /var/lib/dbus/machine-id:/var/lib/dbus/machine-id
            - ~/.Xauthority:/root/.Xauthority
        devices:
            - /dev/dri:/dev/dri
            - /dev/snd:/dev/snd
        network_mode: host
EOF
fi

if [[ ! -f home/src/Main.hx ]]; then
    mkdir home/src
    cat <<-EOF > home/src/Main.hx
class Main extends hxd.App {
    override function init() {
        var tf = new h2d.Text(hxd.res.DefaultFont.get(), s2d);
        tf.text = "Hello Hashlink !";
    }
    static function main() {
        new Main();
    }
}
EOF
fi

}

clean() {

docker system prune -af --volumes

find . -mindepth 1 -maxdepth 1 \
| sed "/Dockerfile/d;/README.md/d;/project.sh/d" \
| xargs -I {} rm -rf {}

}

combo() {

./project.sh clean && ./project.sh build

}

publish() {

ACTUAL_HEAPS_IO_VERSION=$(docker run --rm aljazmc/heapsio-debian:latest sh -c "haxelib info heaps | grep Version |sed 's/Version\:\ //g'")

[[ "${ACTUAL_HEAPS_IO_VERSION}" == "${EXPECTED_HEAPS_IO_VERSION}" ]] || \
    { echo "ERROR: Unexpected heapsio version"; exit; }

docker push -a aljazmc/heapsio-debian

}

"$@"
