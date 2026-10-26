#!/bin/bash
set -e

USER=godot

setup() {

sudo chown -R "$USER" .

if [ ! -f /home/"$USER"/project.godot ]; then
    cat <<-EOF > project.godot
config_version=5

[application]

config/name="Hello"
run/main_scene="res://main.tscn"

[rendering]

renderer/rendering_method="gl_compatibility"
renderer/rendering_method.mobile="gl_compatibility"
textures/vram_compression/import_etc2_astc=true
EOF
fi

if [ ! -f /home/"$USER"/main.tscn ]; then
    cat <<-EOF > main.tscn
[gd_scene format=3]

[node name="Main" type="Node2D"]

[node name="Label" type="Label" parent="."]
offset_right = 200.0
offset_bottom = 40.0
text = "Hello Godot!"
EOF
fi

if [ ! -f /home/"$USER"/export_presets.cfg ]; then
    cat <<-EOF > export_presets.cfg
[preset.0]

name="macOS"
platform="macOS"
runnable=true
export_filter="all_resources"
include_filter=""
exclude_filter=""
export_path="build/macos/hello.zip"

[preset.0.options]

binary_format/architecture="universal"
application/bundle_identifier="com.example.hello"
codesign/codesign=1
notarization/notarization=0
EOF
fi

mkdir -p build/macos
touch build/.gdignore

}

setup >&2

if [ "$#" -gt 0 ]; then
    exec bash -c "$*"
fi
