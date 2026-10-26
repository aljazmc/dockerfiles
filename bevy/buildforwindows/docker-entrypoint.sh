#!/bin/bash
set -e

USER=bevy

setup() {

sudo chown -R "$USER" .

if [ ! -f /home/"$USER"/Cargo.toml ]; then
    cat <<-EOF > Cargo.toml
[package]
name = "hello"
version = "0.1.0"
edition = "2024"

[dependencies]
bevy = "$BEVY_VERSION"

[profile.dev]
opt-level = 1

[profile.dev.package."*"]
opt-level = 3
EOF
fi

if [ ! -f /home/"$USER"/src/main.rs ]; then
    mkdir -p src
    cat <<-EOF > src/main.rs
use bevy::prelude::*;

fn main() {
    App::new()
        .add_plugins(DefaultPlugins)
        .add_systems(Startup, setup)
        .run();
}

fn setup(mut commands: Commands) {
    commands.spawn(Camera2d);
    commands.spawn(Text::new("Hello Bevy!"));
}
EOF
fi

}

setup >&2

if [ "$#" -gt 0 ]; then
    exec bash -c "$*"
fi
