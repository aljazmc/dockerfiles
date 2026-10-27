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

mkdir -p res src

if [ ! -f /home/"$USER"/src/Main.hx ]; then
    cat <<-EOF > src/Main.hx
class Main extends hxd.App {

    public static inline var WIDTH = 960;
    public static inline var HEIGHT = 540;

    override function init() {
        // files in res/, embedded into the compiled game
        hxd.Res.initEmbed();
        var window = hxd.Window.getInstance();
        window.title = "Hello";
        window.resize(WIDTH, HEIGHT);
        // the scene always shows a WIDTH x HEIGHT area, scaled to fit the window
        s2d.scaleMode = LetterBox(WIDTH, HEIGHT);
        engine.backgroundColor = 0x1a1a26;
        new Hello(s2d);
    }

    static function main() {
        new Main();
    }

}
EOF
fi

if [ ! -f /home/"$USER"/src/Hello.hx ]; then
    cat <<-EOF > src/Hello.hx
/** A greeting in the middle of the scene. **/
class Hello extends h2d.Object {

    static inline var SCALE = 4;

    public function new( ?parent : h2d.Object ) {
        super(parent);
        var text = new h2d.Text(hxd.res.DefaultFont.get(), this);
        text.text = "Hello Hashlink!";
        text.textAlign = Center;
        text.maxWidth = Main.WIDTH / SCALE;
        text.setScale(SCALE);
        text.y = (Main.HEIGHT - text.textHeight * SCALE) / 2;
    }

}
EOF
fi

}

setup >&2

if [ "$#" -gt 0 ]; then
    exec bash -c "$*"
fi
