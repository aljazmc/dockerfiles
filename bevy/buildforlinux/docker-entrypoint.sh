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

mkdir -p assets src

if [ ! -f /home/"$USER"/src/main.rs ]; then
    cat <<-EOF > src/main.rs
mod hello;

use bevy::prelude::*;

fn main() {
    App::new()
        .add_plugins(DefaultPlugins.set(WindowPlugin {
            primary_window: Some(Window {
                title: "Hello".into(),
                resolution: (960, 540).into(),
                ..default()
            }),
            ..default()
        }))
        .insert_resource(ClearColor(Color::srgb(0.1, 0.1, 0.15)))
        .add_plugins(hello::HelloPlugin)
        .run();
}
EOF
fi

if [ ! -f /home/"$USER"/src/hello.rs ]; then
    cat <<-EOF > src/hello.rs
use bevy::camera::ScalingMode;
use bevy::prelude::*;

/// Size of the visible area in world units, scaled by the camera to fit the window.
const VIEW_WIDTH: f32 = 960.;
const VIEW_HEIGHT: f32 = 540.;

pub struct HelloPlugin;

impl Plugin for HelloPlugin {
    fn build(&self, app: &mut App) {
        app.add_systems(Startup, setup);
    }
}

fn setup(mut commands: Commands) {
    commands.spawn((
        Camera2d,
        Projection::Orthographic(OrthographicProjection {
            scaling_mode: ScalingMode::AutoMin { min_width: VIEW_WIDTH, min_height: VIEW_HEIGHT },
            ..OrthographicProjection::default_2d()
        }),
    ));
    commands.spawn((Text2d::new("Hello Bevy!"), TextFont::from_font_size(48.)));
}
EOF
fi

}

setup >&2

if [ "$#" -gt 0 ]; then
    exec bash -c "$*"
fi
