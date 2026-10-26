![Docker Pulls](https://img.shields.io/docker/pulls/aljazmc/godot-buildforwindows) ![Docker Image Size](https://img.shields.io/docker/image-size/aljazmc/godot-buildforwindows) ![Docker Stars](https://img.shields.io/docker/stars/aljazmc/godot-buildforwindows)

# Docker image with Godot and the Windows export templates

[GitHub repository](https://github.com/aljazmc/dockerfiles/tree/main/godot/buildforwindows)

## use cases with docker:

###### prepare a directory for development:
```
docker run \
--user godot \
-v .:/home/godot \
-w /home/godot \
aljazmc/godot-buildforwindows:latest
```

###### afterwards append shell commands in the end:
```
docker run \
--user godot \
-v .:/home/godot \
-w /home/godot \
aljazmc/godot-buildforwindows:latest "godot --headless --import && godot --headless --export-release \"Windows Desktop\" build/windows/hello.exe"
```

## use cases with docker compose

###### prepare a directory for development:
```
# docker-compose.yml example
services:
    godot:
        image: aljazmc/godot-buildforwindows
        working_dir: /home/godot
        user: godot
        volumes:
            - .:/home/godot

# command
docker compose run --rm godot
```

###### afterwards append shell commands in the end:
```
docker compose run --rm godot "godot --headless --import && godot --headless --export-release \"Windows Desktop\" build/windows/hello.exe"
```

## How to export the project

The first run creates a small project (`project.godot`, `main.tscn`) and an `export_presets.cfg` with a `Windows Desktop` preset, unless the files already exist. The image contains the Godot editor (`godot`) and the Windows export templates (x86_64 and arm64).

###### export and bundle the game:
```
docker compose run --rm godot '
godot --headless --import &&
godot --headless --export-release "Windows Desktop" build/windows/hello.exe &&
cd build/windows && zip -q ../hello-win64.zip hello.exe
'
```

The result is `build/windows/hello.exe` and the `build/hello-win64.zip` archive. Extract the archive on a 64-bit Windows machine and run `hello.exe`.

###### notes:
- `binary_format/embed_pck=true` puts the game data inside the executable. Without it, keep `hello.pck` next to `hello.exe`.
- For an arm64 build, set `binary_format/architecture="arm64"` in `export_presets.cfg`.
- `--import` imports the project's resources first. It is only needed when resources were added or changed outside of the editor.
- `build/.gdignore` keeps Godot from importing the exported files.
- The executable isn't signed, so SmartScreen may ask for confirmation: "More info" → "Run anyway".
- The image only builds for Windows, it can't run the game. The game can be tested on Linux with Wine, e.g. with the [aljazmc/wine-debian](https://hub.docker.com/r/aljazmc/wine-debian) image.

## How to make a single executable .exe

Nothing else is needed: with `binary_format/embed_pck=true` (set in the generated `export_presets.cfg`) the exported `build/windows/hello.exe` already is a single executable with the game data inside. Copy it to a 64-bit Windows machine and run it.

###### notes:
- If the project needs more files next to the executable, e.g. GDExtension DLLs or a separate `hello.pck`, pack them into one self-extracting `.exe` with NSIS like in [heaps/buildforwindows](https://github.com/aljazmc/dockerfiles/tree/main/heaps/buildforwindows) (`makensis` isn't installed in this image: `sudo apt-get update && sudo apt-get install nsis`).
