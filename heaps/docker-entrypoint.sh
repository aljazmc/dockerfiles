#!/bin/bash
set -e

sudo chown -R "$USER" .

if [ ! -d /home/"$USER"/haxelib ]; then
    haxelib setup haxelib
    haxelib --global update haxelib

    haxelib fixrepo

    haxelib install format
    haxelib install hashlink
    haxelib install heaps
    haxelib install hlopenal
    haxelib install hlsdl
    haxelib install hldx
fi

if [ ! -f /home/"$USER"/compile.hxml ]; then
    mkdir -p home
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
    mkdir src
    cat <<-EOF > src/Main.hx
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
