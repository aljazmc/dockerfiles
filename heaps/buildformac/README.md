![Docker Pulls](https://img.shields.io/docker/pulls/aljazmc/heaps-buildformac) ![Docker Image Size](https://img.shields.io/docker/image-size/aljazmc/heaps-buildformac) ![Docker Stars](https://img.shields.io/docker/stars/aljazmc/heaps-buildformac)

# Docker image with Heaps, Haxe, Neko and the macOS build of Hashlink.

[GitHub repository](https://github.com/aljazmc/dockerfiles/tree/main/heaps/buildformac)

## use cases with docker:

###### prepare a directory for development:
```
docker run \
--user heaps \
-v .:/home/heaps \
-w /home/heaps \
aljazmc/heaps-buildformac:latest
```

###### afterwards append shell commands in the end:
```
docker run \
--user heaps \
-v .:/home/heaps \
-w /home/heaps \
aljazmc/heaps-buildformac:latest "haxe compile.hxml"
```

## use cases with docker compose

###### prepare a directory for development:
```
# docker-compose.yml example
services:
    heaps:
        image: aljazmc/heaps-buildformac
        working_dir: /home/heaps
        user: heaps
        volumes:
            - .:/home/heaps

# command
docker compose run --rm heaps
```

###### afterwards append shell commands in the end:
```
docker compose run --rm heaps "haxe compile.hxml"
```

## How to bundle static libraries

The image contains the macOS (x86_64) build of HashLink (`hl`, `libhl.2.dylib`, `libopenal.1.dylib`, `*.hdll` and headers) in `$HASHLINK_MACOS` (`/usr/local/hashlink-macos`). SDL3 is linked into `sdl.hdll`, so no other libraries are needed. It is the same HashLink version as the Haxe libraries (`hlsdl`, ...) installed in the container, so a project compiled in the container runs on macOS when all of these files are copied into an `.app` bundle.

###### the image contains this script as the `bundle` command ([source](https://github.com/aljazmc/dockerfiles/blob/main/heaps/buildformac/bundle)):
```
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
```

###### compile and bundle the project:
```
docker compose run --rm heaps "haxe compile.hxml && bundle hello.hl"
```

The result is the `dist/hello.app` bundle and the `dist/hello-macos.zip` archive. Extract the archive on a Mac and open `hello.app`.

###### notes:
- `HDLLS` lists the HashLink libraries that are copied. Add `ssl` or `sqlite` if the project uses them. To change the lists, copy the command into the project (`cp /usr/local/bin/bundle .`), edit it and run `./bundle` instead.
- If the project loads resources from the `res` directory at runtime (`hxd.Res.initLocal()`), the directory is copied too. With `hxd.Res.initEmbed()` the resources are already inside the `.hl` file.
- `hl` reads the `.hl` file from the current directory, so `launcher` changes to `Contents/MacOS` before it starts the game.
- The HashLink JIT only exists for x86_64. On Apple Silicon the game runs through Rosetta 2 (macOS asks to install it the first time).
- Only HashLink bytecode can be bundled. A native HL/C build for macOS needs the Apple SDK and its compiler, which can't be shipped in this image.
- The bundle isn't signed or notarized. macOS blocks apps downloaded from the internet, so right click `hello.app` and choose "Open", or remove the quarantine flag with `xattr -dr com.apple.quarantine hello.app`.
- Change `com.example.$NAME` in `Info.plist` to your own bundle identifier.

## How to make a .dmg disk image

Applications for macOS are `.app` bundles and they are usually distributed in a `.dmg` disk image. Opening the `.dmg` shows the app next to a link to the `Applications` folder, and the app is installed by dragging it there. `makedmg` creates such an image with `xorriso` (installed in the image).

###### the image contains this script as the `makedmg` command ([source](https://github.com/aljazmc/dockerfiles/blob/main/heaps/buildformac/makedmg)):
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
docker compose run --rm heaps "haxe compile.hxml && bundle hello.hl && makedmg dist/hello.app dist/hello.dmg"
```

The result is `dist/hello.dmg`. Open it on a Mac and drag `hello.app` to `Applications`.

###### notes:
- usage: `makedmg <app bundle> <output.dmg>`
- The image is an uncompressed hybrid ISO 9660 / HFS+ image with an Apple partition map, which macOS mounts like any other `.dmg`. Compressed `.dmg` images (UDZO) can only be created with `hdiutil` on macOS.
- Browsers mark downloaded `.dmg` files with the quarantine flag and macOS passes it on to the app, so the notes about Gatekeeper above apply to the app copied from the `.dmg` too.
