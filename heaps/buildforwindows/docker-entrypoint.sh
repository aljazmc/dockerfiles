#!/bin/bash
set -e

USER=heaps

setup() {

sudo chown -R "$USER" .

if [ ! -d /home/"$USER"/haxelib ]; then
    haxelib setup haxelib
    haxelib --global update haxelib

    haxelib fixrepo

    haxelib install format
    haxelib dev hashlink /usr/src/hashlink/other/haxelib
    haxelib dev hldx /usr/src/hashlink/libs/directx
    haxelib dev hlopenal /usr/src/hashlink/libs/openal
    haxelib dev hlsdl /usr/src/hashlink/libs/sdl
    haxelib install heaps
    haxelib install utest
fi

}

setup >&2

if [ "$#" -gt 0 ]; then
    exec bash -c "$*"
fi
