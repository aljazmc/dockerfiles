# aljazmc/fluidsynth-debian

FluidSynth with a General MIDI soundfont and FFmpeg on Debian, for rendering MIDI files to audio.

[![Docker pulls](https://img.shields.io/docker/pulls/aljazmc/fluidsynth-debian?logo=docker&logoColor=white)](https://hub.docker.com/r/aljazmc/fluidsynth-debian)
[![Image size](https://img.shields.io/docker/image-size/aljazmc/fluidsynth-debian/latest?logo=docker&logoColor=white)](https://hub.docker.com/r/aljazmc/fluidsynth-debian/tags)
[![Version](https://img.shields.io/docker/v/aljazmc/fluidsynth-debian?sort=semver&logo=docker&logoColor=white)](https://hub.docker.com/r/aljazmc/fluidsynth-debian/tags)
[![platforms: amd64 | arm64](https://img.shields.io/badge/platforms-amd64%20%7C%20arm64-2496ed?logo=docker&logoColor=white)](https://github.com/aljazmc/dockerfiles#building-and-testing)
[![Debian: 13.8](https://img.shields.io/badge/Debian-13.8-a81d33?logo=debian&logoColor=white)](https://hub.docker.com/_/debian)
[![FluidSynth: 2.4.4](https://img.shields.io/badge/FluidSynth-2.4.4-2f6db5)](https://github.com/FluidSynth/fluidsynth/blob/master/LICENSE)
[![FluidSynth license: LGPL-2.1-or-later](https://img.shields.io/badge/FluidSynth%20license-LGPL--2.1--or--later-blue)](#license)
[![CI](https://github.com/aljazmc/dockerfiles/actions/workflows/ci.yml/badge.svg)](https://github.com/aljazmc/dockerfiles/actions/workflows/ci.yml)
[![Dockerfile license: MIT](https://img.shields.io/badge/Dockerfile%20license-MIT-blue)](https://github.com/aljazmc/dockerfiles/blob/main/LICENSE)

[Docker Hub](https://hub.docker.com/r/aljazmc/fluidsynth-debian) · [Source](https://github.com/aljazmc/dockerfiles/tree/main/fluidsynth/debian) · [All images](https://github.com/aljazmc/dockerfiles)

## Overview

| | |
|---|---|
| **Base image** | `debian:13.8` |
| **Software** | FluidSynth 2.4.4 (Debian package) |
| **Also included** | FluidR3 General MIDI soundfont (`/usr/share/sounds/sf2/FluidR3_GM.sf2`), FFmpeg, Python 3 with NumPy, mido, rtmidi, pytest, pip and venv, ShellCheck, Ruff 0.17.6 (pip) |
| **User** | `fluidsynth` (uid 1000) with passwordless `sudo` (`sudo apt-get install ...`) |
| **Tags** | `latest`, `2.4.4`, `2.4.4-YYYYMMDD` |

## Quick start

Run in an empty directory; the commands work on the files of the current directory, mounted as the home directory of the container. [CI](https://github.com/aljazmc/dockerfiles/actions/workflows/ci.yml) runs these commands to check that they work.

<!-- quickstart setup
printf "MThd\000\000\000\006\000\000\000\001\000\140MTrk\000\000\000\014\000\220\074\100\140\200\074\100\000\377\057\000" > song.mid
-->

```sh
# open a shell, with the current directory as the home directory
docker run --rm -it -v .:/home/fluidsynth -w /home/fluidsynth aljazmc/fluidsynth-debian

# render song.mid to song.wav with the bundled soundfont
docker run --rm -v .:/home/fluidsynth -w /home/fluidsynth aljazmc/fluidsynth-debian fluidsynth -ni -F song.wav /usr/share/sounds/sf2/FluidR3_GM.sf2 song.mid

# encode it to song.mp3 with FFmpeg
docker run --rm -v .:/home/fluidsynth -w /home/fluidsynth aljazmc/fluidsynth-debian ffmpeg -i song.wav song.mp3
```

<!-- quickstart check
test -s song.wav
test -s song.mp3
-->

## Usage with Docker Compose

```
## docker-compose.yml file
services:
    fluidsynth:
        image: aljazmc/fluidsynth-debian
        user: ${UID:-1000}:${GID:-1000}
        working_dir: /home/fluidsynth
        volumes:
            - .:/home/fluidsynth
            - /home/$USER/.Xauthority:/home/fluidsynth/.Xauthority
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
        environment:
            DISPLAY: $DISPLAY
            HOME: /home/fluidsynth
            XDG_RUNTIME_DIR: /run/user/1000
        network_mode: host

## start container shell
docker compose run --rm fluidsynth sh -c "sh"

## render song.mid to song.mp3
docker compose run --rm fluidsynth sh -c "fluidsynth -ni -F song.wav /usr/share/sounds/sf2/default-GM.sf2 song.mid && ffmpeg -i song.wav song.mp3"
```

## Notes

- The container user needs the host's `render`, `video` and `audio` groups (`group_add`) to use the GPU and the sound card. Without them, apps fall back to software rendering. The group ids differ between distributions: `stat -c %g /dev/dri/renderD128 /dev/dri/card0 /dev/snd/controlC0`.
- There is no X server or audio server inside the container. Apps use the host's X server (`DISPLAY`, `/tmp/.X11-unix`) and the host's PipeWire/PulseAudio (`XDG_RUNTIME_DIR`).
- The default General MIDI soundfont is `/usr/share/sounds/sf2/default-GM.sf2` (FluidR3).

## Tags

- `latest`: the newest build.
- `2.4.4`: the FluidSynth version in the image, e.g. `aljazmc/fluidsynth-debian:2.4.4`. Use it to stay on a known version.
- `2.4.4-YYYYMMDD`: the same version, built on that date (UTC), e.g. `2.4.4-20261122`. Every build gets its own tag that never moves, so use it where you need exactly the same image again.
- FluidSynth is the Debian `fluidsynth` package, pinned with `FLUIDSYNTH_VERSION` in the Dockerfile (`fluidsynth=2.4.4*`), so Debian security updates of 2.4.4 are still installed.

## License

The Dockerfile, the scripts and this README are part of [aljazmc/dockerfiles](https://github.com/aljazmc/dockerfiles), released under the [MIT License](https://github.com/aljazmc/dockerfiles/blob/main/LICENSE).

The software in the image keeps its own license:

| Software | License | In the image |
|---|---|---|
| [FluidSynth](https://github.com/FluidSynth/fluidsynth/blob/master/LICENSE) | LGPL-2.1-or-later | `/usr/share/doc/fluidsynth/copyright` |

Every other package keeps its license too: `apk info --license <package>` shows it on Alpine, `/usr/share/doc/<package>/copyright` on Debian.
