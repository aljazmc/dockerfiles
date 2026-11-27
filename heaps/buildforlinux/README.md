# aljazmc/heaps-buildforlinux

Haxe, Neko, HashLink and the Heaps game engine, for compiling Heaps games and bundling them with their libraries for GNU/Linux.

[![Docker pulls](https://img.shields.io/docker/pulls/aljazmc/heaps-buildforlinux?logo=docker&logoColor=white)](https://hub.docker.com/r/aljazmc/heaps-buildforlinux)
[![Image size](https://img.shields.io/docker/image-size/aljazmc/heaps-buildforlinux/latest?logo=docker&logoColor=white)](https://hub.docker.com/r/aljazmc/heaps-buildforlinux/tags)
[![Version](https://img.shields.io/docker/v/aljazmc/heaps-buildforlinux?sort=semver&logo=docker&logoColor=white)](https://hub.docker.com/r/aljazmc/heaps-buildforlinux/tags)
[![platforms: amd64 | arm64](https://img.shields.io/badge/platforms-amd64%20%7C%20arm64-2496ed?logo=docker&logoColor=white)](https://github.com/aljazmc/dockerfiles#building-and-testing)
[![Debian: 13.7](https://img.shields.io/badge/Debian-13.7-a81d33?logo=debian&logoColor=white)](https://hub.docker.com/_/debian)
[![Heaps: 2.1.0](https://img.shields.io/badge/Heaps-2.1.0-f68712?logo=haxe&logoColor=white)](https://github.com/HeapsIO/heaps/blob/master/LICENSE)
[![Heaps license: MIT](https://img.shields.io/badge/Heaps%20license-MIT-blue)](#license)
[![CI](https://github.com/aljazmc/dockerfiles/actions/workflows/ci.yml/badge.svg)](https://github.com/aljazmc/dockerfiles/actions/workflows/ci.yml)
[![Dockerfile license: MIT](https://img.shields.io/badge/Dockerfile%20license-MIT-blue)](https://github.com/aljazmc/dockerfiles/blob/main/LICENSE)

[Docker Hub](https://hub.docker.com/r/aljazmc/heaps-buildforlinux) · [Source](https://github.com/aljazmc/dockerfiles/tree/main/heaps/buildforlinux) · [All images](https://github.com/aljazmc/dockerfiles)

## Overview

| | |
|---|---|
| **Base image** | `debian:13.7` |
| **Software** | Heaps 2.1.0 (installed from haxelib on the first start) |
| **Also included** | Haxe, Neko, HashLink (built from source), g++, SDL3, OpenAL, `bundle` and `makesh`, ShellCheck |
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
docker run --rm -v .:/home/heaps -w /home/heaps aljazmc/heaps-buildforlinux "haxe --version && haxelib list heaps"

# compile the project of the current directory to hello.hl
docker run --rm -v .:/home/heaps -w /home/heaps aljazmc/heaps-buildforlinux "haxe compile.hxml"

# bundle it with HashLink and its libraries: dist/hello and dist/hello.tar.gz
docker run --rm -v .:/home/heaps -w /home/heaps aljazmc/heaps-buildforlinux "bundle hello.hl"
```

<!-- quickstart check
test -x dist/hello/hello
test -s dist/hello.tar.gz
-->

## GPU access

The container user needs the host's `render`, `video` and `audio` groups to use the GPU and the sound card. Without them the game falls back to software rendering. The group ids differ between distributions, so look them up with `stat -c %g /dev/dri/renderD128 /dev/dri/card0 /dev/snd/controlC0`.

## Usage with Docker Compose

```
## docker-compose.yml example for GNU/Linux host
services:
    heaps:
        image: aljazmc/heaps-buildforlinux
        working_dir: /home/heaps
        user: heaps
        environment:
            DISPLAY: $DISPLAY
            XDG_RUNTIME_DIR: /run/user/1000
        volumes:
            - .:/home/heaps
            - /home/$USER/.Xauthority:/home/heaps/.Xauthority
            - $XDG_RUNTIME_DIR:/run/user/1000
            - /tmp/.X11-unix:/tmp/.X11-unix
            - /var/lib/dbus/machine-id:/var/lib/dbus/machine-id
        devices:
            - /dev/dri:/dev/dri
            - /dev/snd:/dev/snd
        group_add:
            - "992" # render group: stat -c %g /dev/dri/renderD128
            - "44"  # video group: stat -c %g /dev/dri/card0
            - "29"  # audio group: stat -c %g /dev/snd/controlC0
        network_mode: host

## the first start installs Heaps and its libraries with haxelib
docker compose run --rm heaps

## run commands in the container:
docker compose run --rm heaps "haxe compile.hxml && hl hello.hl"
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

A compiled `.hl` file needs the HashLink runtime (`hl`, `libhl.so`, `*.hdll`) and the libraries the `.hdll` files depend on (SDL3, OpenAL, libpng, libturbojpeg, libvorbis, libuv, ...). To run the game on a machine without Haxe and HashLink installed, copy all of them next to the `.hl` file together with a small launcher script.

```
## the image contains this script as the `bundle` command ([source](https://github.com/aljazmc/dockerfiles/blob/main/heaps/buildforlinux/bundle)):
#!/bin/bash
set -e

HL_FILE="${1:-hello.hl}"
NAME="$(basename "$HL_FILE" .hl)"
DIST="dist/$NAME"
HDLLS=(fmt heaps openal sdl ui uv)
BUNDLE_LIBS="libSDL3|libopenal|libpng16|libturbojpeg|libvorbis|libogg|libuv|libsndio|libdecor|libmbed|libsqlite3"

rm -rf "$DIST"
mkdir -p "$DIST"

cp "$HL_FILE" "$(command -v hl)" /usr/local/lib/libhl.so "$DIST"/
for HDLL in "${HDLLS[@]}"; do
    cp /usr/local/lib/"$HDLL".hdll "$DIST"/
done
if [ -d res ]; then
    cp -r res "$DIST"/
fi

ldd "$DIST"/*.hdll \
    | awk '/=> \// {print $3}' \
    | grep -E "/($BUNDLE_LIBS)[^/]*$" \
    | sort -u \
    | xargs -r cp -L -t "$DIST"/

cat <<EOF > "$DIST/$NAME"
#!/bin/sh
cd "\$(dirname "\$0")"
export LD_LIBRARY_PATH="\$PWD\${LD_LIBRARY_PATH:+:\$LD_LIBRARY_PATH}"
exec ./hl $NAME.hl "\$@"
EOF
chmod +x "$DIST/$NAME"

tar -czf "dist/$NAME.tar.gz" -C dist "$NAME"

## compile and bundle the project:
docker compose run --rm heaps "haxe compile.hxml && bundle hello.hl"

## the result is the `dist/hello` directory and the `dist/hello.tar.gz` archive. To run the game, extract the archive on the target machine and start the launcher:
tar -xzf hello.tar.gz
./hello/hello
```

### Notes
- `HDLLS` lists the HashLink libraries that are copied. Add `ssl`, `sqlite` or `mysql` if the project uses them. Their dependencies are picked up automatically. To change the lists, copy the command into the project (`cp /usr/local/bin/bundle .`), edit it and run `./bundle` instead.
- `BUNDLE_LIBS` lists the libraries that are copied from the image. Everything else, such as glibc, X11, Wayland, GPU drivers, ALSA, PulseAudio and PipeWire, is expected on the target machine.
- If the project loads resources from the `res` directory at runtime (`hxd.Res.initLocal()`), the directory is copied too. With `hxd.Res.initEmbed()` the resources are already inside the `.hl` file.
- The libraries come from Debian 13 (trixie), so the target machine needs glibc 2.41 or newer (e.g. Debian 13, Ubuntu 25.04, Fedora 42 or newer) and an X11 or Wayland desktop.
- The launcher sets `LD_LIBRARY_PATH` to its own directory, so the bundled libraries are used instead of the system ones.

## How to make a self-extracting .sh archive

The `.sh` file is a small shell script with the game appended as a `.tar.gz` archive. When it starts, it extracts the game to a temporary directory, runs it with the same arguments, returns its exit code and deletes the directory when the game exits. It only needs `sh`, `tar`, `gzip` and `mktemp`, which every GNU/Linux distribution has.

```
## the image contains this script as the `makesh` command ([source](https://github.com/aljazmc/dockerfiles/blob/main/heaps/buildforlinux/makesh)):
#!/bin/bash
set -e

DIR="${1:?usage: makesh <directory> <executable in the directory> <output.sh>}"
RUN="${2:?usage: makesh <directory> <executable in the directory> <output.sh>}"
OUT="${3:?usage: makesh <directory> <executable in the directory> <output.sh>}"

cat <<EOF > "$OUT"
#!/bin/sh
set -e
TMP="\$(mktemp -d)"
trap 'rm -rf "\$TMP"' EXIT
trap 'exit 130' INT TERM HUP
ARCHIVE="\$(awk '/^__ARCHIVE__\$/ { print NR + 1; exit }' "\$0")"
tail -n +"\$ARCHIVE" "\$0" | tar -xz -C "\$TMP"
"\$TMP/$RUN" "\$@"
exit \$?
__ARCHIVE__
EOF
tar -czf - -C "$DIR" . >> "$OUT"
chmod +x "$OUT"

## create the archive:
docker compose run --rm heaps "haxe compile.hxml && bundle hello.hl && makesh dist/hello hello dist/hello.sh"
```

The result is `dist/hello.sh`. Copy it to the target machine and start it with `./hello.sh`.

### Notes
- Usage: `makesh <directory> <executable in the directory> <output.sh>`. The whole directory is packed and the executable is started from inside it.
- The game is extracted on every start. If `/tmp` is mounted with `noexec`, point `TMPDIR` to another directory: `TMPDIR=~/.cache ./hello.sh`.
- The requirements of the bundle (glibc 2.41 or newer, X11 or Wayland desktop) apply to the `.sh` archive too.
- The game runs from a temporary directory that is removed when it exits, so write files that should persist, like saved games, to the user's data directory (`$XDG_DATA_HOME`, by default `~/.local/share`). `hxd.Save` writes to the working directory by default.

## Tags

- `latest`: the newest build.
- `2.1.0`: the Heaps version in the image, e.g. `aljazmc/heaps-buildforlinux:2.1.0`. Use it to stay on a known version.
- `2.1.0-YYYYMMDD`: the same version, built on that date (UTC), e.g. `2.1.0-20261122`. Every build gets its own tag that never moves, so use it where you need exactly the same image again.
- Heaps is installed from haxelib on the first start of the container (into `~/haxelib`), pinned with the `HEAPS_VERSION` environment variable set in the Dockerfile. An existing `~/haxelib` directory is kept as it is.

## License

The Dockerfile, the scripts and this README are part of [aljazmc/dockerfiles](https://github.com/aljazmc/dockerfiles), released under the [MIT License](https://github.com/aljazmc/dockerfiles/blob/main/LICENSE).

The software in the image keeps its own license:

| Software | License | In the image |
|---|---|---|
| [Heaps](https://github.com/HeapsIO/heaps/blob/master/LICENSE) | MIT | `~/haxelib/heaps/*/LICENSE` after the first start |

Every other package keeps its license too: `apk info --license <package>` shows it on Alpine, `/usr/share/doc/<package>/copyright` on Debian.
