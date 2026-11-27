# aljazmc's dockerfiles

[![ci](https://github.com/aljazmc/dockerfiles/actions/workflows/ci.yml/badge.svg)](https://github.com/aljazmc/dockerfiles/actions/workflows/ci.yml)
[![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)
[![Docker Hub](https://img.shields.io/badge/Docker%20Hub-21%20images-2496ed?logo=docker&logoColor=white)](https://hub.docker.com/u/aljazmc)
[![Docker pulls](https://img.shields.io/badge/pulls-18%2C000%2B-2496ed?logo=docker&logoColor=white)](https://hub.docker.com/u/aljazmc)
[![Platforms: amd64 and arm64](https://img.shields.io/badge/platforms-amd64%20%7C%20arm64-2496ed?logo=docker&logoColor=white)](#building-and-testing)
[![Alpine 3.24.4](https://img.shields.io/badge/Alpine-3.24.4-0d597f?logo=alpinelinux&logoColor=white)](https://alpinelinux.org/)
[![Debian 13.7](https://img.shields.io/badge/Debian-13.7-a81d33?logo=debian&logoColor=white)](https://www.debian.org/)
[![Trivy: scanned in CI](https://img.shields.io/badge/Trivy-scanned%20in%20CI-1904da?logo=trivy&logoColor=white)](#sbom-and-vulnerability-scanning)
[![SBOM: CycloneDX](https://img.shields.io/badge/SBOM-CycloneDX-1a4d7a?logo=owasp&logoColor=white)](#sbom-and-vulnerability-scanning)
[![Dependabot](https://img.shields.io/badge/Dependabot-enabled-025e8c?logo=dependabot&logoColor=white)](.github/dependabot.yml)
[![Coverage: kcov in CI](https://img.shields.io/badge/coverage-kcov%20in%20CI-2088ff?logo=githubactions&logoColor=white)](https://github.com/aljazmc/dockerfiles/actions/workflows/ci.yml)
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

[Dependabot](.github/dependabot.yml) proposes the updates of the pins it can read every week, as pull requests that CI builds and smoke-tests: the base images in the `FROM` lines, one pull request for the Debian images and one for the Alpine ones, and the GitHub Actions of the workflows. The versions of the software in `ARG` lines, such as `BLENDER_VERSION`, are updated by hand.

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

## Troubleshooting

The examples use `blender-debian`, whose user is `blender`. Every image has its own user, named after the software (`x11`, `wine`, `godot`, ...), with uid 1000 and the home directory `/home/<user>`.

### Permissions on GNU/Linux

**Files the container writes belong to someone else, or it can't write to the mounted directory.** The container user has uid 1000. If yours is different (`id -u`), run the container as you, and point `HOME` at the mounted directory:

```sh
docker run --rm -it --user "$(id -u):$(id -g)" -e HOME=/home/blender \
    -v .:/home/blender -w /home/blender aljazmc/blender-debian bash
```

The prompt then shows `I have no name!`, and `sudo` or `doas` don't work, because your uid has no entry in the image's `/etc/passwd`; everything else does. The heaps images are the exception: their entrypoint gives the working directory to their user with `sudo chown -R heaps .` on every start, so they need uid 1000 and fail with `--user`. To take back files a container created, run `sudo chown -R "$(id -u):$(id -g)" .` on the host.

In Docker Compose, the examples' `user: ${UID:-1000}:${GID:-1000}` reads `UID` and `GID` from the environment, but shells don't export them. Write them to a `.env` file next to `docker-compose.yml`, which Compose reads:

```sh
printf 'UID=%s\nGID=%s\n' "$(id -u)" "$(id -g)" > .env
```

**`Permission denied` on the mounted directory although the uids match.** SELinux, on Fedora, RHEL and their relatives, keeps containers out of directories that aren't labelled for them. Add `:z` to the mount: `-v .:/home/blender:z`.

**Files belong to an unknown uid such as `100999`, with rootless Docker or Podman.** They map the uids of a container to a range of your own. With rootless Docker, root in the container is you, so run with `--user root`. With Podman, `--userns=keep-id` keeps your uid inside the container.

**`permission denied while trying to connect to the Docker daemon socket`.** Your user is not in the `docker` group. Add it with `sudo usermod -aG docker "$USER"`, then log out and in again. The `docker` group is as powerful as root; rootless Docker avoids it.

**`Permission denied` on `/dev/dri/renderD128` or `/dev/snd/...`, or apps render in software.** The container user needs the host's `render`, `video` and `audio` groups, by number, as [Running GUI applications](#running-gui-applications) shows. `--group-add` works together with `--user`.

**`Authorization required, but no authorization protocol specified` or `cannot open display`.** The X server refuses the container. On Wayland desktops, XWayland often keeps its cookie in the file named by `$XAUTHORITY` rather than `~/.Xauthority`, so mount that one: `-v "${XAUTHORITY:-$HOME/.Xauthority}:/home/blender/.Xauthority:ro"`. With `--user`, also pass `-e HOME=/home/blender`: for a uid the image doesn't know, Docker sets `HOME` to `/`, where X looks for the cookie in vain. Or let your own user in without a cookie, which works when the container runs with your uid: `xhost +SI:localuser:"$(id -un)"`.

**No sound although `$XDG_RUNTIME_DIR` is mounted.** The PipeWire and PulseAudio sockets in it are only open to your uid. Run the container with your uid, as above, and pass `-e XDG_RUNTIME_DIR=/run/user/1000`.

### Sharing audio and video devices

#### GNU/Linux

Containers use the host's devices and servers directly:

| What | Flags |
|---|---|
| Display (X11, or XWayland on Wayland) | `-v /tmp/.X11-unix:/tmp/.X11-unix -e DISPLAY`, and the X cookie, see above |
| Sound through PipeWire or PulseAudio, the usual way | `-v "$XDG_RUNTIME_DIR:/run/user/1000" -e XDG_RUNTIME_DIR=/run/user/1000` |
| Sound card directly, through ALSA | `--device /dev/snd --group-add <audio gid>`; without a sound server only one program at a time can use the card |
| GPU: Intel, AMD, or NVIDIA with nouveau | `--device /dev/dri --group-add <render gid> --group-add <video gid>` |
| GPU: NVIDIA with its own driver | `--gpus all`, with the [NVIDIA Container Toolkit](https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/latest/install-guide.html) installed on the host |
| Webcam or capture card | `--device /dev/video0 --group-add <video gid>` |

The group ids come from `stat -c %g /dev/dri/renderD128 /dev/dri/card0 /dev/snd/controlC0`. Put together:

```sh
docker run --rm -it --user "$(id -u):$(id -g)" -e HOME=/home/x11 \
    -v /tmp/.X11-unix:/tmp/.X11-unix -e DISPLAY \
    -v "${XAUTHORITY:-$HOME/.Xauthority}:/home/x11/.Xauthority:ro" \
    -v "$XDG_RUNTIME_DIR:/run/user/1000" -e XDG_RUNTIME_DIR=/run/user/1000 \
    --device /dev/dri --group-add "$(stat -c %g /dev/dri/renderD128)" \
    --group-add "$(stat -c %g /dev/dri/card0)" \
    aljazmc/x11-debian xterm
```

#### macOS

Docker Desktop runs containers in a Linux virtual machine, so it can't pass the Mac's GPU, sound card, camera or USB devices to a container. Display and sound go over the network instead, to `host.docker.internal`, the name of the Mac inside the containers. The images are built for `linux/arm64` too, so they run natively on Apple silicon.

- **Display:** install [XQuartz](https://www.xquartz.org), enable *Allow connections from network clients* in its settings (Security), and restart it. Then allow local clients with `xhost +localhost` in an XQuartz terminal, and run the container with `-e DISPLAY=host.docker.internal:0`. Apps render in software, with the Mesa of the image.
- **Sound:** run a PulseAudio server on the Mac, for example from Homebrew (`brew install pulseaudio`), that accepts connections over TCP: `pulseaudio --load="module-native-protocol-tcp auth-anonymous=1" --exit-idle-time=-1 --daemon`. Then run the container with `-e PULSE_SERVER=tcp:host.docker.internal:4713`. Anonymous access lets anything that reaches port 4713 play sound, so keep the macOS firewall on.
- **Camera and USB devices:** not possible with Docker Desktop. Run Linux in a virtual machine that passes the device through, and Docker inside it as on GNU/Linux.

```sh
docker run --rm -it -e DISPLAY=host.docker.internal:0 \
    -e PULSE_SERVER=tcp:host.docker.internal:4713 aljazmc/x11-debian xterm
```

#### Windows

Use WSL 2: its WSLg gives every WSL distribution a display (X11 and Wayland) and a PulseAudio server. Run Docker from the shell of a WSL distribution, such as Ubuntu, not from PowerShell; Microsoft's [WSLg container sample](https://github.com/microsoft/wslg/blob/main/samples/container/Containers.md) installs Docker Engine in the distribution itself.

- **Display and sound:** mount WSLg's sockets and pass its variables:

  ```sh
  docker run --rm -it \
      -v /tmp/.X11-unix:/tmp/.X11-unix -v /mnt/wslg:/mnt/wslg \
      -e DISPLAY -e WAYLAND_DISPLAY -e XDG_RUNTIME_DIR -e PULSE_SERVER \
      aljazmc/x11-debian xterm
  ```

- **GPU:** add `--device /dev/dxg -v /usr/lib/wsl:/usr/lib/wsl -e LD_LIBRARY_PATH=/usr/lib/wsl/lib`. Mesa then renders on the Windows GPU through its D3D12 driver, if the image's Mesa includes it; otherwise apps render in software.
- **Camera and USB devices:** attach them to WSL with [usbipd-win](https://learn.microsoft.com/en-us/windows/wsl/connect-usb). In PowerShell, `usbipd list` and `usbipd bind --busid <busid>` as administrator, then `usbipd attach --wsl --busid <busid>`. The device then appears in WSL, e.g. as `/dev/video0`, and goes to the container with `--device` as on GNU/Linux. While attached, Windows can't use it.
- **Files:** keep projects in the WSL file system (`~`), not under `/mnt/c`, where mounts are much slower.

### Interactive shell

Most images start a shell when they are given no command: `bash` on Debian and on `actions-alpine`, `sh` on the other Alpine images.

```sh
docker run --rm -it -v .:/home/blender -w /home/blender aljazmc/blender-debian
```

A session in `x11-alpine`, recorded on 27 November 2026: the shell runs as the image's user, with uid 1000 and the mounted directory as its home, and `doas sh` opens a root shell (`sudo -i` on Debian). The `~ $` prompt is the user's, `#` is root's.

```console
$ docker run --rm -it -v .:/home/x11 -w /home/x11 aljazmc/x11-alpine
~ $ id
uid=1000(x11) gid=1000(x11) groups=1000(x11),1000(x11)
~ $ echo $HOME $PWD
/home/x11 /home/x11
~ $ doas sh
/home/x11 # id
uid=0(root) gid=0(root) groups=0(root),0(root),1(bin),2(daemon),3(sys),4(adm),6(disk),10(wheel),11(floppy),20(dialout),26(tape),27(video)
/home/x11 # exit
~ $ exit
```

| Image | How to get a shell |
|---|---|
| `node-*` | They start Node.js's REPL; give the shell as the command: `docker run --rm -it aljazmc/node-debian bash` (`sh` on `node-alpine`). |
| `godot-*`, `heaps-*` | They have no default command and stop at once without one; give `bash`. They run their arguments as one shell string, so `"godot --headless --version && ls"` works as well. |
| `heaps-*` | Their entrypoint first installs Heaps and its libraries with haxelib, which needs the network; `--entrypoint bash` skips it. |
| `image-spinner` | Its default command sets up the aports tree, cloning it the first time; give `sh` for a shell instead. |

- **A root shell:** `sudo -i` in the Debian images, `doas sh` in the Alpine ones, or run the container with `--user root`.
- **A shell in a running container:** `docker exec -it <container> bash`, or `sh` on Alpine. A detached container needs a command that keeps running, e.g. `docker run -d --name blender aljazmc/blender-debian sleep infinity`.
- **Docker Compose:** `docker compose run --rm <service> bash` starts a new container, `docker compose exec <service> bash` opens a shell in a running one.
- **`the input device is not a TTY`:** `-t` needs a terminal. In scripts, CI or with piped input, drop `-t` and keep `-i`. In Git Bash on Windows, run the command through `winpty`, and set `MSYS_NO_PATHCONV=1` so it doesn't turn `/home/blender` into a Windows path.

## Building and testing

`project.sh` builds every directory that contains a `Dockerfile`. The image name is the directory path with `/` replaced by `-`, e.g. `godot/buildforlinux` becomes `aljazmc/godot-buildforlinux`.

```sh
./project.sh publish            # build, smoke test, tag and push every image
./project.sh clean              # remove all local aljazmc/* images
./project.sh scan [image...]    # write SBOMs and list HIGH and CRITICAL vulnerabilities
./project.sh changed main HEAD  # list the images whose directory changed between two commits
./project.sh lint               # check every Dockerfile for HIGH and CRITICAL misconfigurations
./project.sh coverage           # measure how much of project.sh the tests run, in coverage/
./project.sh notes              # write release notes for the commits since the last tag

tests/smoke_test.sh             # build every image and check that its tools run
tests/smoke_test.sh x11-alpine  # build and check a single image
tests/project_test.sh           # test publish with docker stubbed out
tests/arguments_test.sh         # test that bad input is rejected, and clean
tests/scan_test.sh              # test scan with docker and Trivy stubbed out
tests/smoke_cases_test.sh       # test that every image has a smoke case
tests/repo_test.sh              # check pinned bases, READMEs and entrypoints
tests/regression_test.sh        # check that no fixed bug has come back
tests/changed_test.sh           # test project.sh changed in a throwaway git repository
tests/coverage_test.sh          # test project.sh coverage with docker stubbed out
tests/notes_test.sh             # test project.sh notes in a throwaway git repository
```

`publish` only pushes an image after it has been built and has passed its smoke test. It tags the image `latest`, with the version reported by the software in the image and with that version plus the build date (UTC). Every image is built for `linux/amd64` and `linux/arm64`. CI runs `shellcheck` on every shell script and every test except `tests/smoke_test.sh` on every push to `main` and every pull request. It measures the coverage of `project.sh` and `tests/smoke_test.sh` by those tests with `./project.sh coverage`, which runs them under [kcov](https://github.com/SimonKagstrom/kcov) from its Docker image, writes the table to the job summary and keeps the HTML report as an artifact. It checks every Dockerfile for misconfigurations with `./project.sh lint`, which needs no image and takes seconds, and builds and smoke-tests the images whose directory the push or pull request changed, found with `./project.sh changed`. It scans those images with `IGNORE_UNFIXED=1 FAIL_ON=CRITICAL ./project.sh scan`, so a `CRITICAL` vulnerability with a fix fails the job, and keeps their SBOMs as an artifact of the run. It pushes nothing; a change outside the image directories builds no image. The tests need only bash and git, and `shellcheck` for `tests/regression_test.sh`.

### Releases

Every tag `v*`, e.g. `v2026.11.28`, gets a GitHub release, made by the `release` workflow. Its notes come from `./project.sh notes`: the message of the tag when it is annotated, so a release can say in words what it brings, then the images whose directory changed since the previous tag and the commits, sorted by their [Conventional Commits](https://www.conventionalcommits.org/) type into features, fixes, documentation and other changes.

```sh
./project.sh notes                                  # preview the notes of the next release
git tag -a v2026.11.28 -m "What this release brings"
git push origin v2026.11.28
```

A release is a record of the repository, not of the images: they are still published with `./project.sh publish`.

### SBOM and vulnerability scanning

`./project.sh scan` runs [Trivy](https://trivy.dev) from its Docker image (`aquasec/trivy`, pinned in `project.sh`), so nothing has to be installed. For every image, or only the images given, e.g. `./project.sh scan x11-alpine wine-debian`, it:

1. writes a [CycloneDX](https://cyclonedx.org) SBOM, the list of every package and library in the image, to `sbom/<image>.cdx.json`,
2. checks that SBOM for known vulnerabilities and prints them as a table.

It scans the local image, or pulls it from Docker Hub when there is none. The vulnerability database is downloaded on the first run and cached in `~/.cache/trivy`. The command exits with 1 if any image has a vulnerability of the selected severity.

| Variable | Default | Meaning |
|---|---|---|
| `SEVERITY` | `HIGH,CRITICAL` | Severities to report, e.g. `SEVERITY=CRITICAL` or `SEVERITY=LOW,MEDIUM,HIGH,CRITICAL`. |
| `IGNORE_UNFIXED` | unset | Set to `1` to hide vulnerabilities that have no fixed version yet. |
| `FAIL_ON` | `SEVERITY` | Severities that make the command exit with 1, e.g. `FAIL_ON=CRITICAL` to list `HIGH` and `CRITICAL` vulnerabilities but fail only on `CRITICAL` ones. |

The SBOM covers what is installed in the image at build time. The heaps images install Heaps and its haxelib libraries on the first start, and HashLink is built from source, so these don't show up in their SBOMs.

`./project.sh lint` runs Trivy's misconfiguration checks on the Dockerfiles themselves, such as `sudo` in a `RUN` or an `apt-get install` that could stop for a prompt. It needs no image, so it takes seconds, and CI runs it on every push. It reports `HIGH` and `CRITICAL` findings and exits with 1 if there are any; `SEVERITY` works as for `scan`. With `SEVERITY=LOW` it also lists the missing `HEALTHCHECK` of every image, which these tool images, not services, don't need.

To build a single image locally:

```sh
docker build -t aljazmc/inkscape-debian inkscape/debian
```

## License

The Dockerfiles and scripts in this repository are released under the [MIT License](LICENSE). The software in the images keeps its own license; each image's README links to it.
