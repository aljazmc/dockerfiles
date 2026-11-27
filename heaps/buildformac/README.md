# aljazmc/heaps-buildformac

Haxe, Neko, the macOS build of HashLink and the Heaps game engine, for compiling Heaps games into macOS `.app` bundles and `.dmg` images.

[![Docker pulls](https://img.shields.io/docker/pulls/aljazmc/heaps-buildformac?logo=docker&logoColor=white)](https://hub.docker.com/r/aljazmc/heaps-buildformac)
[![Image size](https://img.shields.io/docker/image-size/aljazmc/heaps-buildformac/latest?logo=docker&logoColor=white)](https://hub.docker.com/r/aljazmc/heaps-buildformac/tags)
[![Version](https://img.shields.io/docker/v/aljazmc/heaps-buildformac?sort=semver&logo=docker&logoColor=white)](https://hub.docker.com/r/aljazmc/heaps-buildformac/tags)
[![platforms: amd64 | arm64](https://img.shields.io/badge/platforms-amd64%20%7C%20arm64-2496ed?logo=docker&logoColor=white)](https://github.com/aljazmc/dockerfiles#building-and-testing)
[![Debian: 13.7](https://img.shields.io/badge/Debian-13.7-a81d33?logo=debian&logoColor=white)](https://hub.docker.com/_/debian)
[![Heaps: 2.1.0](https://img.shields.io/badge/Heaps-2.1.0-f68712?logo=haxe&logoColor=white)](https://github.com/HeapsIO/heaps/blob/master/LICENSE)
[![Heaps license: MIT](https://img.shields.io/badge/Heaps%20license-MIT-blue)](#license)
[![CI](https://github.com/aljazmc/dockerfiles/actions/workflows/ci.yml/badge.svg)](https://github.com/aljazmc/dockerfiles/actions/workflows/ci.yml)
[![Dockerfile license: MIT](https://img.shields.io/badge/Dockerfile%20license-MIT-blue)](https://github.com/aljazmc/dockerfiles/blob/main/LICENSE)

[Docker Hub](https://hub.docker.com/r/aljazmc/heaps-buildformac) · [Source](https://github.com/aljazmc/dockerfiles/tree/main/heaps/buildformac) · [All images](https://github.com/aljazmc/dockerfiles)

## Overview

| | |
|---|---|
| **Base image** | `debian:13.7` |
| **Software** | Heaps 2.1.0 (installed from haxelib on the first start) |
| **Also included** | Haxe, Neko, HashLink for macOS (x86_64), `bundle` and `makedmg`, xorriso, zip, ShellCheck |
| **User** | `heaps` (uid 1000) with passwordless `sudo` (`sudo apt-get install ...`) |
| **Tags** | `latest`, `2.1.0`, `2.1.0-YYYYMMDD` |

## Quick start

Run in an empty directory; the commands work on the files of the current directory, mounted as the home directory of the container. [CI](https://github.com/aljazmc/dockerfiles/actions/workflows/ci.yml) runs these commands to check that they work.

<!-- quickstart setup
mkdir -p src
cat > compile.hxml <<'EOF'
-cp src
-lib format
-lib heaps
-lib hlsdl
-hl hello.hl
-main Main
EOF
cat > src/Main.hx <<'EOF'
class Main extends hxd.App {
    override function init() {
        new h2d.Text(hxd.res.DefaultFont.get(), s2d).text = "Hello Heaps!";
    }
    static function main() {
        new Main();
    }
}
EOF
-->

```sh
# the first start installs Heaps and its libraries with haxelib, into ~/haxelib
docker run --rm -v .:/home/heaps -w /home/heaps aljazmc/heaps-buildformac "haxe --version && haxelib list heaps"

# compile the project of the current directory to hello.hl
docker run --rm -v .:/home/heaps -w /home/heaps aljazmc/heaps-buildformac "haxe compile.hxml"

# bundle it into dist/hello.app and make dist/hello.dmg
docker run --rm -v .:/home/heaps -w /home/heaps aljazmc/heaps-buildformac "bundle hello.hl && makedmg dist/hello.app dist/hello.dmg"
```

<!-- quickstart check
test -d dist/hello.app
test -s dist/hello.dmg
-->

## Usage with Docker Compose

```
## docker-compose.yml example
services:
    heaps:
        image: aljazmc/heaps-buildformac
        working_dir: /home/heaps
        user: heaps
        volumes:
            - .:/home/heaps

## the first start installs Heaps and its libraries with haxelib
docker compose run --rm heaps

## run commands in the container:
docker compose run --rm heaps "haxe compile.hxml"
```

## How to bundle the game with its libraries

The commands expect a Heaps project in the current directory with a `compile.hxml` that compiles it to `hello.hl`, like this one, and the sources in `src`:

```hxml
-cp src
-lib format
-lib heaps
-lib hlsdl
-hl hello.hl
-main Main
```

The image contains the macOS (x86_64) build of HashLink (`hl`, `libhl.2.dylib`, `libopenal.1.dylib`, `*.hdll` and headers) in `$HASHLINK_MACOS` (`/usr/local/hashlink-macos`). SDL3 is linked into `sdl.hdll`, so no other libraries are needed. It is the same HashLink version as the Haxe libraries (`hlsdl`, ...) installed in the container, so a project compiled in the container runs on macOS when all of these files are copied into an `.app` bundle.

```
###### the image contains this script as the `bundle` command ([source](https://github.com/aljazmc/dockerfiles/blob/main/heaps/buildformac/bundle)):
#!/bin/bash
set -e

HL_FILE="${1:-hello.hl}"
NAME="$(basename "$HL_FILE" .hl)"
APP="dist/$NAME.app"
HDLLS=(fmt heaps openal sdl ui uv)
DYLIBS=(libhl.2 libopenal.1)

rm -rf "$APP" "dist/$NAME-macos.zip"
mkdir -p "$APP/Contents/MacOS"

cp "$HL_FILE" "$APP/Contents/MacOS/$NAME.hl"
cp "$HASHLINK_MACOS/hl" "$APP/Contents/MacOS"/
for HDLL in "${HDLLS[@]}"; do
    cp "$HASHLINK_MACOS/$HDLL.hdll" "$APP/Contents/MacOS"/
done
for DYLIB in "${DYLIBS[@]}"; do
    cp -L "$HASHLINK_MACOS/$DYLIB.dylib" "$APP/Contents/MacOS"/
done
if [ -d res ]; then
    cp -r res "$APP/Contents/MacOS"/
fi

cat <<EOF > "$APP/Contents/MacOS/launcher"
#!/bin/sh
cd "\$(dirname "\$0")"
exec ./hl $NAME.hl "\$@"
EOF
chmod +x "$APP/Contents/MacOS/launcher" "$APP/Contents/MacOS/hl"

cat <<EOF > "$APP/Contents/Info.plist"
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>launcher</string>
    <key>CFBundleIdentifier</key>
    <string>com.example.$NAME</string>
    <key>CFBundleName</key>
    <string>$NAME</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0</string>
    <key>NSHighResolutionCapable</key>
    <true/>
</dict>
</plist>
EOF

(cd dist && zip -qry "$NAME-macos.zip" "$NAME.app")

## compile and bundle the project:
docker compose run --rm heaps "haxe compile.hxml && bundle hello.hl"
```

The result is the `dist/hello.app` bundle and the `dist/hello-macos.zip` archive. Extract the archive on a Mac and open `hello.app`.

### Notes
- `HDLLS` lists the HashLink libraries that are copied. Add `ssl` or `sqlite` if the project uses them. To change the lists, copy the command into the project (`cp /usr/local/bin/bundle .`), edit it and run `./bundle` instead.
- If the project loads resources from the `res` directory at runtime (`hxd.Res.initLocal()`), the directory is copied too. With `hxd.Res.initEmbed()` the resources are already inside the `.hl` file.
- `hl` reads the `.hl` file from the current directory, so `launcher` changes to `Contents/MacOS` before it starts the game.
- The HashLink JIT only exists for x86_64. On Apple Silicon the game runs through Rosetta 2 (macOS asks to install it the first time).
- Only HashLink bytecode can be bundled. A native HL/C build for macOS needs the Apple SDK and its compiler, which can't be shipped in this image.
- The bundle isn't signed or notarized. macOS blocks apps downloaded from the internet, so right click `hello.app` and choose "Open", or remove the quarantine flag with `xattr -dr com.apple.quarantine hello.app`.
- Change `com.example.$NAME` in `Info.plist` to your own bundle identifier.

## How to make a .dmg disk image

Applications for macOS are `.app` bundles and they are usually distributed in a `.dmg` disk image. Opening the `.dmg` shows the app next to a link to the `Applications` folder, and the app is installed by dragging it there. `makedmg` creates such an image with `xorriso` (installed in the image).

```
## the image contains this script as the `makedmg` command ([source](https://github.com/aljazmc/dockerfiles/blob/main/heaps/buildformac/makedmg)):
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
docker compose run --rm heaps "haxe compile.hxml && bundle hello.hl && makedmg dist/hello.app dist/hello.dmg"
```

The result is `dist/hello.dmg`. Open it on a Mac and drag `hello.app` to `Applications`.

### Notes
- Usage: `makedmg <app bundle> <output.dmg>`.
- The image is an uncompressed hybrid ISO 9660 / HFS+ image with an Apple partition map, which macOS mounts like any other `.dmg`. Compressed `.dmg` images (UDZO) can only be created with `hdiutil` on macOS.
- Browsers mark downloaded `.dmg` files with the quarantine flag and macOS passes it on to the app, so the notes about Gatekeeper above apply to the app copied from the `.dmg` too.
- An app started directly from the mounted `.dmg` runs from a read-only directory, and `launcher` changes to `Contents/MacOS`, so write files that should persist, like saved games, to `~/Library/Application Support`. `hxd.Save` writes to the working directory by default.

## Tags

- `latest`: the newest build.
- `2.1.0`: the Heaps version in the image, e.g. `aljazmc/heaps-buildformac:2.1.0`. Use it to stay on a known version.
- `2.1.0-YYYYMMDD`: the same version, built on that date (UTC), e.g. `2.1.0-20261122`. Every build gets its own tag that never moves, so use it where you need exactly the same image again.
- Heaps is installed from haxelib on the first start of the container (into `~/haxelib`), pinned with the `HEAPS_VERSION` environment variable set in the Dockerfile. An existing `~/haxelib` directory is kept as it is.

## License

The Dockerfile, the scripts and this README are part of [aljazmc/dockerfiles](https://github.com/aljazmc/dockerfiles), released under the [MIT License](https://github.com/aljazmc/dockerfiles/blob/main/LICENSE).

The software in the image keeps its own license:

| Software | License | In the image |
|---|---|---|
| [Heaps](https://github.com/HeapsIO/heaps/blob/master/LICENSE) | MIT | `~/haxelib/heaps/*/LICENSE` after the first start |

Every other package keeps its license too: `apk info --license <package>` shows it on Alpine, `/usr/share/doc/<package>/copyright` on Debian.
