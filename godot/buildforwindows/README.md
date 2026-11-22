# aljazmc/godot-buildforwindows

Godot with the Windows export templates, for exporting Godot games for Windows from Linux.

[![Docker Pulls](https://img.shields.io/docker/pulls/aljazmc/godot-buildforwindows)](https://hub.docker.com/r/aljazmc/godot-buildforwindows) [![Docker Image Size](https://img.shields.io/docker/image-size/aljazmc/godot-buildforwindows)](https://hub.docker.com/r/aljazmc/godot-buildforwindows) [![Docker Stars](https://img.shields.io/docker/stars/aljazmc/godot-buildforwindows)](https://hub.docker.com/r/aljazmc/godot-buildforwindows)

[Docker Hub](https://hub.docker.com/r/aljazmc/godot-buildforwindows) · [Source](https://github.com/aljazmc/dockerfiles/tree/main/godot/buildforwindows) · [All images](https://github.com/aljazmc/dockerfiles)

## Overview

| | |
|---|---|
| **Base image** | `debian:13.7` |
| **Software** | Godot 4.7.2 (official build) with export templates |
| **Also included** | zip |
| **User** | `godot` (uid 1000) with passwordless `sudo` (`sudo apt-get install ...`) |
| **Tags** | `latest`, `4.7.2` |

## Usage with Docker

```
## prepare a directory for development:
docker run \
--user godot \
-v .:/home/godot \
-w /home/godot \
aljazmc/godot-buildforwindows:latest

## afterwards append shell commands in the end:
docker run \
--user godot \
-v .:/home/godot \
-w /home/godot \
aljazmc/godot-buildforwindows:latest "godot --headless --import && godot --headless --export-release \"Windows Desktop\" build/windows/hello.exe"
```

## Usage with Docker Compose

```
## prepare a directory for development:
## docker-compose.yml example
services:
    godot:
        image: aljazmc/godot-buildforwindows
        working_dir: /home/godot
        user: godot
        volumes:
            - .:/home/godot

## command
docker compose run --rm godot

## afterwards append shell commands in the end:
docker compose run --rm godot "godot --headless --import && godot --headless --export-release \"Windows Desktop\" build/windows/hello.exe"
```

## How to export the project

The first run creates a small project and an `export_presets.cfg` with a `Windows Desktop` preset, unless the files already exist: `project.godot` with a 960x540 viewport that is scaled to fit the window (so the layout doesn't depend on the window size), `main.tscn` as the main scene and `hello.tscn` with a label centered in the viewport, which `main.tscn` instances. Add further parts of the game as scenes of their own. The image contains the Godot editor (`godot`) and the Windows export templates (x86_64 and arm64).

```
## export and bundle the game:
docker compose run --rm godot '
godot --headless --import &&
godot --headless --export-release "Windows Desktop" build/windows/hello.exe &&
cd build/windows && zip -q ../hello-win64.zip hello.exe
'
```

The result is `build/windows/hello.exe` and the `build/hello-win64.zip` archive. Extract the archive on a 64-bit Windows machine and run `hello.exe`.

### Notes
- `binary_format/embed_pck=true` puts the game data inside the executable. Without it, keep `hello.pck` next to `hello.exe`.
- For an arm64 build, set `binary_format/architecture="arm64"` in `export_presets.cfg`.
- `--import` imports the project's resources first. It is only needed when resources were added or changed outside of the editor.
- `build/.gdignore` keeps Godot from importing the exported files.
- The executable isn't signed, so SmartScreen may ask for confirmation: "More info" → "Run anyway".
- The image only builds for Windows, it can't run the game. The game can be tested on Linux with Wine, e.g. with the [aljazmc/wine-debian](https://hub.docker.com/r/aljazmc/wine-debian) image.

## How to make a single executable .exe

Nothing else is needed: with `binary_format/embed_pck=true` (set in the generated `export_presets.cfg`) the exported `build/windows/hello.exe` already is a single executable with the game data inside. Copy it to a 64-bit Windows machine and run it.

### Notes
- If the project needs more files next to the executable, e.g. GDExtension DLLs or a separate `hello.pck`, pack them into one self-extracting `.exe` with NSIS like in [heaps/buildforwindows](https://github.com/aljazmc/dockerfiles/tree/main/heaps/buildforwindows) (`makensis` isn't installed in this image: `sudo apt-get update && sudo apt-get install nsis`).

## Tags

- `latest`: the newest build.
- `4.7.2`: the Godot version in the image, e.g. `aljazmc/godot-buildforwindows:4.7.2`. Use it to stay on a known version.
- Godot is the official build and export templates from GitHub, pinned with `GODOT_VERSION` in the Dockerfile.

## License

Godot is free and open-source software released under the [MIT License](https://github.com/godotengine/godot/blob/master/LICENSE.txt). The licenses of bundled third-party code are listed in [COPYRIGHT.txt](https://github.com/godotengine/godot/blob/master/COPYRIGHT.txt).
