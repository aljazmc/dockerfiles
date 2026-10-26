![Docker Pulls](https://img.shields.io/docker/pulls/aljazmc/godot-buildformac) ![Docker Image Size](https://img.shields.io/docker/image-size/aljazmc/godot-buildformac) ![Docker Stars](https://img.shields.io/docker/stars/aljazmc/godot-buildformac)

# Docker image with Godot and the macOS export templates

[GitHub repository](https://github.com/aljazmc/dockerfiles/tree/main/godot/buildformac)

## use cases with docker:

###### prepare a directory for development:
```
docker run \
--user godot \
-v .:/home/godot \
-w /home/godot \
aljazmc/godot-buildformac:latest
```

###### afterwards append shell commands in the end:
```
docker run \
--user godot \
-v .:/home/godot \
-w /home/godot \
aljazmc/godot-buildformac:latest "godot --headless --import && godot --headless --export-release macOS build/macos/hello.zip"
```

## use cases with docker compose

###### prepare a directory for development:
```
# docker-compose.yml example
services:
    godot:
        image: aljazmc/godot-buildformac
        working_dir: /home/godot
        user: godot
        volumes:
            - .:/home/godot

# command
docker compose run --rm godot
```

###### afterwards append shell commands in the end:
```
docker compose run --rm godot "godot --headless --import && godot --headless --export-release macOS build/macos/hello.zip"
```

## How to export the project

The first run creates a small project (`project.godot`, `main.tscn`) and an `export_presets.cfg` with a `macOS` preset, unless the files already exist. The image contains the Godot editor (`godot`) and the macOS export template (universal: Apple Silicon and Intel).

###### export the game:
```
docker compose run --rm godot "godot --headless --import && godot --headless --export-release macOS build/macos/hello.zip"
```

The result is the `build/macos/hello.zip` archive with `Hello.app` inside. Extract it on a Mac and open `Hello.app`.

###### notes:
- macOS exports need `textures/vram_compression/import_etc2_astc=true` in `project.godot`, otherwise the export fails with a configuration error. The generated project already has it. Add it to your own projects too.
- `application/bundle_identifier` is required. Change `com.example.hello` to your own identifier.
- `codesign/codesign=1` signs the app ad-hoc with Godot's built-in signer. Without a signature the app doesn't start on Apple Silicon.
- The app isn't notarized, so macOS blocks it on the first start. Allow it in "System Settings" → "Privacy & Security" → "Open Anyway", or remove the quarantine flag with `xattr -dr com.apple.quarantine Hello.app`.
- `--import` imports the project's resources first. It is only needed when resources were added or changed outside of the editor.
- `build/.gdignore` keeps Godot from importing the exported files.

## How to make a .dmg disk image

Applications for macOS are `.app` bundles and they are usually distributed in a `.dmg` disk image. Opening the `.dmg` shows the app next to a link to the `Applications` folder, and the app is installed by dragging it there. `makedmg` creates such an image with `xorriso` (installed in the image).

###### the image contains this script as the `makedmg` command ([source](https://github.com/aljazmc/dockerfiles/blob/main/godot/buildformac/makedmg)):
```
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
```

###### create the disk image:
```
docker compose run --rm godot "godot --headless --import && godot --headless --export-release macOS build/macos/hello.zip && unzip -oq build/macos/hello.zip -d build/macos && makedmg build/macos/Hello.app build/hello.dmg"
```

The result is `build/hello.dmg`. Open it on a Mac and drag `Hello.app` to `Applications`.

###### notes:
- usage: `makedmg <app bundle> <output.dmg>`
- The image is an uncompressed hybrid ISO 9660 / HFS+ image with an Apple partition map, which macOS mounts like any other `.dmg`. Compressed `.dmg` images (UDZO) can only be created with `hdiutil` on macOS.
- Browsers mark downloaded `.dmg` files with the quarantine flag and macOS passes it on to the app, so the notes about Gatekeeper above apply to the app copied from the `.dmg` too.
- Godot can export a `.dmg` directly only on macOS, on other systems it exports a `.zip`. The commands above extract the `.app` from the `.zip` first.
- The ad-hoc signature of the app is kept, because it is stored inside the `.app` bundle.
