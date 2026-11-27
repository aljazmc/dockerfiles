# aljazmc/godot-buildformac

Godot with its macOS export templates, for exporting ad-hoc signed macOS `.app` bundles of Godot games and packing them into `.dmg` images.

[![Docker pulls](https://img.shields.io/docker/pulls/aljazmc/godot-buildformac?logo=docker&logoColor=white)](https://hub.docker.com/r/aljazmc/godot-buildformac)
[![Image size](https://img.shields.io/docker/image-size/aljazmc/godot-buildformac/latest?logo=docker&logoColor=white)](https://hub.docker.com/r/aljazmc/godot-buildformac/tags)
[![Version](https://img.shields.io/docker/v/aljazmc/godot-buildformac?sort=semver&logo=docker&logoColor=white)](https://hub.docker.com/r/aljazmc/godot-buildformac/tags)
[![platforms: amd64 | arm64](https://img.shields.io/badge/platforms-amd64%20%7C%20arm64-2496ed?logo=docker&logoColor=white)](https://github.com/aljazmc/dockerfiles#building-and-testing)
[![Debian: 13.8](https://img.shields.io/badge/Debian-13.8-a81d33?logo=debian&logoColor=white)](https://hub.docker.com/_/debian)
[![Godot: 4.7.2](https://img.shields.io/badge/Godot-4.7.2-478cbf?logo=godotengine&logoColor=white)](https://godotengine.org/license/)
[![Godot license: MIT](https://img.shields.io/badge/Godot%20license-MIT-blue)](#license)
[![CI](https://github.com/aljazmc/dockerfiles/actions/workflows/ci.yml/badge.svg)](https://github.com/aljazmc/dockerfiles/actions/workflows/ci.yml)
[![Dockerfile license: MIT](https://img.shields.io/badge/Dockerfile%20license-MIT-blue)](https://github.com/aljazmc/dockerfiles/blob/main/LICENSE)

[Docker Hub](https://hub.docker.com/r/aljazmc/godot-buildformac) · [Source](https://github.com/aljazmc/dockerfiles/tree/main/godot/buildformac) · [All images](https://github.com/aljazmc/dockerfiles)

## Overview

| | |
|---|---|
| **Base image** | `debian:13.8` |
| **Software** | Godot 4.7.2 (official build) with export templates |
| **Also included** | `makedmg` (`.dmg` disk images), xorriso, ShellCheck |
| **User** | `godot` (uid 1000) with passwordless `sudo` (`sudo apt-get install ...`) |
| **Tags** | `latest`, `4.7.2`, `4.7.2-YYYYMMDD` |

## Quick start

Run in an empty directory; the commands work on the files of the current directory, mounted as the home directory of the container. [CI](https://github.com/aljazmc/dockerfiles/actions/workflows/ci.yml) runs these commands to check that they work.

<!-- quickstart setup
cat > project.godot <<'EOF'
config_version=5

[application]

config/name="Hello"
run/main_scene="res://hello.tscn"

[rendering]

renderer/rendering_method="gl_compatibility"
textures/vram_compression/import_etc2_astc=true
EOF
cat > hello.tscn <<'EOF'
[gd_scene format=3]

[node name="Hello" type="Label"]
text = "Hello Godot!"
EOF
cat > export_presets.cfg <<'EOF'
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
-->

```sh
# the Godot version and its export templates
docker run --rm aljazmc/godot-buildformac "godot --headless --version && ls \$XDG_DATA_HOME/godot/export_templates/*"

# export the project with its macOS preset: an ad-hoc signed Hello.app in a zip
docker run --rm -v .:/home/godot -w /home/godot aljazmc/godot-buildformac "godot --headless --import && mkdir -p build/macos && godot --headless --export-release macOS build/macos/hello.zip"

# unpack it and make build/hello.dmg
docker run --rm -v .:/home/godot -w /home/godot aljazmc/godot-buildformac "unzip -oq build/macos/hello.zip -d build/macos && makedmg build/macos/Hello.app build/hello.dmg"
```

<!-- quickstart check
test -d build/macos/Hello.app
test -s build/hello.dmg
-->

## Usage with Docker Compose

```
## docker-compose.yml example
services:
    godot:
        image: aljazmc/godot-buildformac
        working_dir: /home/godot
        user: godot
        volumes:
            - .:/home/godot

## run commands in the container:
docker compose run --rm godot "godot --headless --import && mkdir -p build/macos && godot --headless --export-release macOS build/macos/hello.zip"
```

## How to export the project

The commands expect a Godot 4 project in the current directory with an `export_presets.cfg` that has a `macOS` preset, like this one. A universal build, for Intel and Apple silicon Macs, also needs `textures/vram_compression/import_etc2_astc=true` in the `[rendering]` section of `project.godot`. Godot doesn't create the output directory, so the commands do.

```ini
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
```

```
## export the game:
docker compose run --rm godot "godot --headless --import && mkdir -p build/macos && godot --headless --export-release macOS build/macos/hello.zip"
```

The result is the `build/macos/hello.zip` archive with `Hello.app` inside. Extract it on a Mac and open `Hello.app`.

### Notes
- MacOS exports need `textures/vram_compression/import_etc2_astc=true` in `project.godot`, otherwise the export fails with a configuration error. The generated project already has it. Add it to your own projects too.
- `application/bundle_identifier` is required. Change `com.example.hello` to your own identifier.
- `codesign/codesign=1` signs the app ad-hoc with Godot's built-in signer. Without a signature the app doesn't start on Apple Silicon.
- The app isn't notarized, so macOS blocks it on the first start. Allow it in "System Settings" → "Privacy & Security" → "Open Anyway", or remove the quarantine flag with `xattr -dr com.apple.quarantine Hello.app`.
- `--import` imports the project's resources first. It is only needed when resources were added or changed outside of the editor.
- `build/.gdignore` keeps Godot from importing the exported files.

## How to make a .dmg disk image

Applications for macOS are `.app` bundles and they are usually distributed in a `.dmg` disk image. Opening the `.dmg` shows the app next to a link to the `Applications` folder, and the app is installed by dragging it there. `makedmg` creates such an image with `xorriso` (installed in the image).

```
## the image contains this script as the `makedmg` command ([source](https://github.com/aljazmc/dockerfiles/blob/main/godot/buildformac/makedmg)):
#!/bin/bash
set -e

APP="${1:?usage: makedmg <app bundle> <output.dmg>}"
OUT="${2:?usage: makedmg <app bundle> <output.dmg>}"
NAME="$(basename "$APP" .app)"
STAGE="$(mktemp -d)"
chmod 755 "$STAGE"

cp -a "$APP" "$STAGE"/
ln -s /Applications "$STAGE/Applications"
rm -f "$OUT"
xorriso -as mkisofs -quiet -V "$NAME" -hfsplus -R -o "$OUT" "$STAGE"
rm -rf "$STAGE"

## create the disk image:
docker compose run --rm godot "godot --headless --import && mkdir -p build/macos && godot --headless --export-release macOS build/macos/hello.zip && unzip -oq build/macos/hello.zip -d build/macos && makedmg build/macos/Hello.app build/hello.dmg"
```

The result is `build/hello.dmg`. Open it on a Mac and drag `Hello.app` to `Applications`.

### Notes
- Usage: `makedmg <app bundle> <output.dmg>`.
- The image is an uncompressed hybrid ISO 9660 / HFS+ image with an Apple partition map, which macOS mounts like any other `.dmg`. Compressed `.dmg` images (UDZO) can only be created with `hdiutil` on macOS.
- Browsers mark downloaded `.dmg` files with the quarantine flag and macOS passes it on to the app, so the notes about Gatekeeper above apply to the app copied from the `.dmg` too.
- Godot can export a `.dmg` directly only on macOS, on other systems it exports a `.zip`. The commands above extract the `.app` from the `.zip` first.
- The ad-hoc signature of the app is kept, because it is stored inside the `.app` bundle.

## Tags

- `latest`: the newest build.
- `4.7.2`: the Godot version in the image, e.g. `aljazmc/godot-buildformac:4.7.2`. Use it to stay on a known version.
- `4.7.2-YYYYMMDD`: the same version, built on that date (UTC), e.g. `4.7.2-20261122`. Every build gets its own tag that never moves, so use it where you need exactly the same image again.
- Godot is the official build and export templates from GitHub, pinned with `GODOT_VERSION` in the Dockerfile.

## License

The Dockerfile, the scripts and this README are part of [aljazmc/dockerfiles](https://github.com/aljazmc/dockerfiles), released under the [MIT License](https://github.com/aljazmc/dockerfiles/blob/main/LICENSE).

The software in the image keeps its own license:

| Software | License | In the image |
|---|---|---|
| [Godot Engine](https://godotengine.org/license/) | MIT | `godot --headless --version`, [godotengine.org/license](https://godotengine.org/license/) |

Every other package keeps its license too: `apk info --license <package>` shows it on Alpine, `/usr/share/doc/<package>/copyright` on Debian.
