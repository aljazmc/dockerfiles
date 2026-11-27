# aljazmc's dockerfiles

[![ci](https://github.com/aljazmc/dockerfiles/actions/workflows/ci.yml/badge.svg)](https://github.com/aljazmc/dockerfiles/actions/workflows/ci.yml)
[![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)
[![Docker Hub](https://img.shields.io/badge/Docker%20Hub-21%20images-2496ed?logo=docker&logoColor=white)](https://hub.docker.com/u/aljazmc)
[![Docker pulls](https://img.shields.io/badge/pulls-9%2C000%2B-2496ed?logo=docker&logoColor=white)](https://hub.docker.com/u/aljazmc)
[![Alpine 3.24.4](https://img.shields.io/badge/Alpine-3.24.4-0d597f?logo=alpinelinux&logoColor=white)](https://alpinelinux.org/)
[![Debian 13.7](https://img.shields.io/badge/Debian-13.7-a81d33?logo=debian&logoColor=white)](https://www.debian.org/)
[![ShellCheck](https://img.shields.io/badge/ShellCheck-checked-4eaa25?logo=gnubash&logoColor=white)](https://www.shellcheck.net/)
[![Conventional Commits](https://img.shields.io/badge/Conventional%20Commits-1.0.0-fe5196?logo=conventionalcommits&logoColor=white)](https://www.conventionalcommits.org/)

Docker images for rendering, media conversion, game development, Windows app testing and building Alpine Linux ISO images. Most images come in an Alpine Linux and a Debian variant. They all follow the same conventions: a non-root user with uid 1000, passwordless `doas` or `sudo`, and a pinned version of the main software that the image is also tagged with.

All images are published on Docker Hub under [aljazmc](https://hub.docker.com/u/aljazmc). Each image's own README explains how to use it.

## Features

- **21 images, two families.** Actions, Blender, Inkscape, FluidSynth, Wine,
  X11 and Node in Alpine and Debian flavours, Godot and Heaps build images
  for Linux, Windows and macOS, and `image-spinner` for custom Alpine ISOs.
- **Pinned and tagged.** Every image starts from `debian:13.7` or
  `alpine:3.24.4` and is pushed as `latest`, with its software version and
  with that version plus the build date.
- **Tested before it is pushed.** `project.sh publish` pushes an image only
  after it builds and its smoke test runs its main tools.
- **SBOMs and vulnerability scans.** `project.sh scan` writes a CycloneDX
  SBOM of every image and lists its known vulnerabilities with Trivy.
- **GUI apps on the host's display.** The images use the host's X server,
  GPU and PipeWire or PulseAudio, and run as a non-root user with uid 1000.

## Images

| Image | Base | Software | Description |
|---|---|---|---|
| [actions-alpine](actions/alpine) | Alpine 3.24 | Node | Node.js 26 (unofficial musl build), Corepack, docker, shellcheck, ruff and git. |
| [actions-debian](actions/debian) | Debian 13 | Node | Node.js 26 (official build, GPG verified), Corepack, docker, shellcheck, ruff and git. |
| [blender-alpine](blender/alpine) | Alpine 3.24 | Blender 5.1 | Alpine package of Blender using Alpine's system Python, with FFmpeg and pytest. |
| [blender-debian](blender/debian) | Debian 13 | Blender 5.2 | Debian forky (testing) package of Blender using the system Python, with FFmpeg and pytest. |
| [fluidsynth-alpine](fluidsynth/alpine) | Alpine 3.24 | FluidSynth 2.5 | Renders MIDI to audio. TimGM6mb soundfont, FFmpeg, Python 3 with NumPy and pytest. |
| [fluidsynth-debian](fluidsynth/debian) | Debian 13 | FluidSynth 2.4 | Renders MIDI to audio. FluidR3 soundfont, FFmpeg, Python 3 with NumPy, mido, rtmidi and pytest. |
| [godot-buildforlinux](godot/buildforlinux) | Debian 13 | Godot 4.7 | Exports and runs games for GNU/Linux. `makesh` packs a game into one self-extracting `.sh`. |
| [godot-buildformac](godot/buildformac) | Debian 13 | Godot 4.7 | Exports ad-hoc signed macOS `.app` bundles. `makedmg` creates `.dmg` images. |
| [godot-buildforwindows](godot/buildforwindows) | Debian 13 | Godot 4.7 | Exports games as a single Windows `.exe`. |
| [heaps-buildforlinux](heaps/buildforlinux) | Debian 13 | Heaps 2.1 | Haxe, Neko and HashLink. `bundle` ships the game with its libraries, `makesh` packs it into one `.sh`. |
| [heaps-buildformac](heaps/buildformac) | Debian 13 | Heaps 2.1 | Haxe, Neko and the macOS build of HashLink. `bundle` creates an `.app`, `makedmg` a `.dmg`. |
| [heaps-buildforwindows](heaps/buildforwindows) | Debian 13 | Heaps 2.1 | Haxe, Neko, the Windows build of HashLink, mingw-w64 and NSIS. `makeexe` creates a single `.exe`. |
| [image-spinner](image-spinner) | Alpine 3.24 | Alpine 3.24 | `abuild`, GRUB, syslinux, squashfs-tools and xorriso for building custom ISO images with `mkimage.sh`. |
| [inkscape-alpine](inkscape/alpine) | Alpine 3.24 | Inkscape 1.4.2 | Inkscape with every Python extension and the import/export helpers. |
| [inkscape-debian](inkscape/debian) | Debian 13 | Inkscape 1.4 | Inkscape with every Python extension and the import/export helpers. |
| [node-alpine](node/alpine) | Alpine 3.24 | Node.js 26 | Node.js 26 (unofficial musl build), Corepack and git. |
| [node-debian](node/debian) | Debian 13 | Node.js 26 | Node.js 26 (official build, GPG verified), Corepack and git. |
| [wine-alpine](wine/alpine) | Alpine 3.24 | Wine 11.0 | Stable Wine release for 32-bit and 64-bit Windows applications. |
| [wine-debian](wine/debian) | Debian 13 | Wine 11.22 | WineHQ development build for 32-bit and 64-bit Windows applications. |
| [x11-alpine](x11/alpine) | Alpine 3.24 | libX11 1.8 | xterm, GTK 2, Mesa, Vulkan and audio libraries. A base for GUI apps that use the host's X server. |
| [x11-debian](x11/debian) | Debian 13 | libX11 1.8 | xterm, GTK 2 engines, Mesa, Vulkan and audio libraries. A base for GUI apps that use the host's X server. |

Every image includes [ShellCheck](https://www.shellcheck.net/) from its distribution's repository. The images whose work is Python scripts (blender-*, fluidsynth-* and inkscape-*) also include [Ruff](https://docs.astral.sh/ruff/), installed with pip at 0.17.6, the version the GitHub Actions of the profile's repositories use.

### Alpine or Debian?

- **Alpine** images are smaller, but they use musl instead of glibc, so binaries built on glibc distributions (Debian, Ubuntu, Fedora, ...) don't run in them.
- **Debian** images are larger, but they run glibc binaries and, where Debian's package is too old, take the package from Debian testing or ship the upstream build (for example Blender from Debian forky and Wine from WineHQ).

## Tags

Every image is published with three tags:

| Tag | Meaning |
|---|---|
| `latest` | The newest build. |
| `<version>` | The version of the software the image is named after, e.g. `aljazmc/blender-debian:5.2.4` or `aljazmc/godot-buildforlinux:4.7.2`. |
| `<version>-<YYYYMMDD>` | The same version, built on that date (UTC), e.g. `aljazmc/blender-debian:5.2.4-20261122`. Every build gets its own tag that never moves. |

These versions are pinned in the Dockerfiles (`BLENDER_VERSION`, `GODOT_VERSION`, ...), so a version tag always refers to the same version of the software. Two images are tagged differently: `image-spinner` with its Alpine Linux version and the `x11` images with their libX11 version. Use `<version>` to stay on a version of the software, and `<version>-<YYYYMMDD>` to stay on one exact build.

The rest of the system isn't pinned. Every build first runs `apt-get upgrade` (Debian) or `apk upgrade` (Alpine), so it includes the latest bug and security fixes of the base distribution. A rebuild with the same version of the main software moves `latest` and `<version>` to the new image. The dated tag of the previous build keeps pointing to it, unless the rebuild happens on the same day, which overwrites it.

A rebuild isn't bit-for-bit reproducible, because the upgraded packages change over time. To get exactly the same image again, use a dated tag or the image digest (`aljazmc/<image>@sha256:...`).

## Quick start

```sh
# open a shell in a container, with the current directory mounted as the home directory
docker run --rm -it -v .:/home/blender -w /home/blender aljazmc/blender-alpine sh

# render frame 1 of scene.blend
docker run --rm -v .:/home/blender -w /home/blender aljazmc/blender-alpine:5.1.2 \
    sh -c "blender -b scene.blend -o //render_#### -f 1"
```

Each image's README has examples for `docker run` and Docker Compose.

## Running GUI applications

The images don't contain an X server or an audio server. GUI apps use the host's X server and the host's PipeWire or PulseAudio:

- mount `/tmp/.X11-unix` and `~/.Xauthority`, and pass `DISPLAY`,
- mount `$XDG_RUNTIME_DIR` to `/run/user/1000` for audio,
- pass `/dev/dri` and `/dev/snd`, and add the host's `render`, `video` and `audio` groups to the container user (`--group-add` or `group_add`). The group ids differ between distributions: `stat -c %g /dev/dri/renderD128 /dev/dri/card0 /dev/snd/controlC0`. Without these groups, apps fall back to software rendering.

The container user has uid 1000, so files it creates in a mounted directory belong to the first user on most hosts.

## Building and testing

`project.sh` builds every directory that contains a `Dockerfile`. The image name is the directory path with `/` replaced by `-`, e.g. `godot/buildforlinux` becomes `aljazmc/godot-buildforlinux`.

```sh
./project.sh publish            # build, smoke test, tag and push every image
./project.sh clean              # remove all local aljazmc/* images
./project.sh scan [image...]    # write SBOMs and list HIGH and CRITICAL vulnerabilities
./project.sh changed main HEAD  # list the images whose directory changed between two commits

tests/smoke_test.sh             # build every image and check that its tools run
tests/smoke_test.sh x11-alpine  # build and check a single image
tests/project_test.sh           # test publish with docker stubbed out
tests/arguments_test.sh         # test that bad input is rejected, and clean
tests/scan_test.sh              # test scan with docker and Trivy stubbed out
tests/smoke_cases_test.sh       # test that every image has a smoke case
tests/repo_test.sh              # check pinned bases, READMEs and entrypoints
tests/regression_test.sh        # check that no fixed bug has come back
```

`publish` only pushes an image after it has been built and has passed its smoke test. It tags the image `latest`, with the version reported by the software in the image and with that version plus the build date (UTC). Every image is built for `linux/amd64` and `linux/arm64`. CI runs `shellcheck` on every shell script and every test except `tests/smoke_test.sh` on every push to `main` and every pull request. It also builds and smoke-tests the images whose directory the push or pull request changed, found with `./project.sh changed`, and pushes nothing; a change outside the image directories builds no image. The tests need only bash and git, and `shellcheck` for `tests/regression_test.sh`.

### SBOM and vulnerability scanning

`./project.sh scan` runs [Trivy](https://trivy.dev) from its Docker image (`aquasec/trivy`, pinned in `project.sh`), so nothing has to be installed. For every image, or only the images given, e.g. `./project.sh scan x11-alpine wine-debian`, it:

1. writes a [CycloneDX](https://cyclonedx.org) SBOM, the list of every package and library in the image, to `sbom/<image>.cdx.json`,
2. checks that SBOM for known vulnerabilities and prints them as a table.

It scans the local image, or pulls it from Docker Hub when there is none. The vulnerability database is downloaded on the first run and cached in `~/.cache/trivy`. The command exits with 1 if any image has a vulnerability of the selected severity.

| Variable | Default | Meaning |
|---|---|---|
| `SEVERITY` | `HIGH,CRITICAL` | Severities to report, e.g. `SEVERITY=CRITICAL` or `SEVERITY=LOW,MEDIUM,HIGH,CRITICAL`. |
| `IGNORE_UNFIXED` | unset | Set to `1` to hide vulnerabilities that have no fixed version yet. |

The SBOM covers what is installed in the image at build time. The heaps images install Heaps and its haxelib libraries on the first start, and HashLink is built from source, so these don't show up in their SBOMs.

To build a single image locally:

```sh
docker build -t aljazmc/inkscape-debian inkscape/debian
```

## License

The Dockerfiles and scripts in this repository are released under the [MIT License](LICENSE). The software in the images keeps its own license; each image's README links to it.
