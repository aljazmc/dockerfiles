# aljazmc/fluidsynth-debian

FluidSynth, FFmpeg and Python 3 on Debian, for rendering MIDI to audio.

[![Docker Pulls](https://img.shields.io/docker/pulls/aljazmc/fluidsynth-debian)](https://hub.docker.com/r/aljazmc/fluidsynth-debian) [![Docker Image Size](https://img.shields.io/docker/image-size/aljazmc/fluidsynth-debian)](https://hub.docker.com/r/aljazmc/fluidsynth-debian) [![Docker Stars](https://img.shields.io/docker/stars/aljazmc/fluidsynth-debian)](https://hub.docker.com/r/aljazmc/fluidsynth-debian)

[Docker Hub](https://hub.docker.com/r/aljazmc/fluidsynth-debian) · [Source](https://github.com/aljazmc/dockerfiles/tree/main/fluidsynth/debian) · [All images](https://github.com/aljazmc/dockerfiles)

## Overview

| | |
|---|---|
| **Base image** | `debian:13.7` |
| **Software** | FluidSynth 2.4.4 (Debian package) |
| **Also included** | FluidR3 General MIDI soundfont, FFmpeg, Python 3 with NumPy, mido, rtmidi, pytest, pip and venv, ShellCheck, Ruff 0.17.6 (pip) |
| **User** | `fluidsynth` (uid 1000) with passwordless `sudo` (`sudo apt-get install ...`) |
| **Tags** | `latest`, `2.4.4`, `2.4.4-YYYYMMDD` |

## Usage with Docker

```
## start container shell
docker run --rm -it -v .:/home/fluidsynth -w /home/fluidsynth aljazmc/fluidsynth-debian sh -c "bash"

## render song.mid to song.mp3
docker run --rm -it -v .:/home/fluidsynth -w /home/fluidsynth aljazmc/fluidsynth-debian sh -c "fluidsynth -ni -F song.wav /usr/share/sounds/sf2/default-GM.sf2 song.mid && ffmpeg -i song.wav song.mp3"
```

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

FluidSynth is free and open-source software released under the [GNU Lesser General Public License (LGPL) v2.1+](https://github.com/FluidSynth/fluidsynth/blob/master/LICENSE).
