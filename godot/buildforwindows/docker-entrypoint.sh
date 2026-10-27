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

[display]

window/size/viewport_width=960
window/size/viewport_height=540
window/stretch/mode="canvas_items"
window/stretch/aspect="keep"

[rendering]

renderer/rendering_method="gl_compatibility"
renderer/rendering_method.mobile="gl_compatibility"
EOF
fi

if [ ! -f /home/"$USER"/main.tscn ]; then
    cat <<-EOF > main.tscn
[gd_scene load_steps=2 format=3]

[ext_resource type="PackedScene" path="res://hello.tscn" id="1"]

[node name="Main" type="Node"]

[node name="Hello" parent="." instance=ExtResource("1")]
EOF
fi

if [ ! -f /home/"$USER"/hello.tscn ]; then
    cat <<-EOF > hello.tscn
[gd_scene format=3]

[node name="Hello" type="Label"]
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
grow_horizontal = 2
grow_vertical = 2
theme_override_font_sizes/font_size = 48
text = "Hello Godot!"
horizontal_alignment = 1
vertical_alignment = 1
EOF
fi

if [ ! -f /home/"$USER"/export_presets.cfg ]; then
    cat <<-EOF > export_presets.cfg
[preset.0]

name="Windows Desktop"
platform="Windows Desktop"
runnable=true
export_filter="all_resources"
include_filter=""
exclude_filter=""
export_path="build/windows/hello.exe"

[preset.0.options]

binary_format/embed_pck=true
binary_format/architecture="x86_64"
EOF
fi

mkdir -p build/windows
touch build/.gdignore

}

setup >&2

if [ "$#" -gt 0 ]; then
    exec bash -c "$*"
fi
