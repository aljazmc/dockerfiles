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
    haxelib dev hlopenal /usr/src/hashlink/libs/openal
    haxelib dev hlsdl /usr/src/hashlink/libs/sdl
    haxelib install heaps
    haxelib install utest
fi

if [ ! -f /home/"$USER"/compile.hxml ]; then
    cat <<-EOF > compile.hxml
-cp src
-lib format
-lib heaps
-lib hlsdl
-hl hello.hl
-main Main
EOF
fi

if [ ! -f /home/"$USER"/src/Main.hx ]; then
    mkdir -p src
    cat <<-EOF > src/Main.hx
class Main extends hxd.App {
    override function init() {
        var tf = new h2d.Text(hxd.res.DefaultFont.get(), s2d);
        tf.text = "Hello Hashlink!";
    }
    static function main() {
        new Main();
    }
}
EOF
fi

}

setup >&2

if [ "$#" -gt 0 ]; then
    exec bash -c "$*"
fi
