![Docker Pulls](https://img.shields.io/docker/pulls/aljazmc/fluidsynth-debian) ![Docker Image Size](https://img.shields.io/docker/image-size/aljazmc/fluidsynth-debian) ![Docker Stars](https://img.shields.io/docker/stars/aljazmc/fluidsynth-debian)

# Docker image with FluidSynth, FFmpeg and Python 3

[GitHub repository](https://github.com/aljazmc/dockerfiles/tree/main/fluidsynth/debian)

## > Examples with docker:

```
## start container shell
docker run --rm -it -v .:/home/fluidsynth -w /home/fluidsynth aljazmc/fluidsynth-debian sh -c "bash"

## render song.mid to song.mp3
docker run --rm -it -v .:/home/fluidsynth -w /home/fluidsynth aljazmc/fluidsynth-debian sh -c "fluidsynth -ni -F song.wav /usr/share/sounds/sf2/default-GM.sf2 song.mid && ffmpeg -i song.wav song.mp3"
```

## > Examples with docker compose:

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

## > Notes

- passwordless sudo
- the container user needs the host's `render`, `video` and `audio` groups (`group_add`) to use the GPU and the sound card. Without them, apps fall back to software rendering. The group ids differ between distributions: `stat -c %g /dev/dri/renderD128 /dev/dri/card0 /dev/snd/controlC0`.
- there is no X server or audio server inside the container. Apps use the host's X server (`DISPLAY`, `/tmp/.X11-unix`) and the host's PipeWire/PulseAudio (`XDG_RUNTIME_DIR`).
- the default General MIDI soundfont is `/usr/share/sounds/sf2/default-GM.sf2` (FluidR3).

## > License

FluidSynth is free and open-source software released under the [GNU Lesser General Public License (LGPL) v2.1+](https://github.com/FluidSynth/fluidsynth/blob/master/LICENSE).
