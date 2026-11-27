# aljazmc/image-spinner

The Alpine Linux build tools, for building custom Alpine ISO images with `mkimage.sh` from the aports tree.

[![Docker pulls](https://img.shields.io/docker/pulls/aljazmc/image-spinner?logo=docker&logoColor=white)](https://hub.docker.com/r/aljazmc/image-spinner)
[![Image size](https://img.shields.io/docker/image-size/aljazmc/image-spinner/latest?logo=docker&logoColor=white)](https://hub.docker.com/r/aljazmc/image-spinner/tags)
[![Version](https://img.shields.io/docker/v/aljazmc/image-spinner?sort=semver&logo=docker&logoColor=white)](https://hub.docker.com/r/aljazmc/image-spinner/tags)
[![platforms: amd64 | arm64](https://img.shields.io/badge/platforms-amd64%20%7C%20arm64-2496ed?logo=docker&logoColor=white)](https://github.com/aljazmc/dockerfiles#building-and-testing)
[![Alpine: 3.24.4](https://img.shields.io/badge/Alpine-3.24.4-0d597f?logo=alpinelinux&logoColor=white)](https://hub.docker.com/_/alpine)
[![Alpine: 3.24.4](https://img.shields.io/badge/Alpine-3.24.4-0d597f?logo=alpinelinux&logoColor=white)](https://gitlab.alpinelinux.org/alpine/abuild)
[![Alpine license: GPL-2.0-only](https://img.shields.io/badge/Alpine%20license-GPL--2.0--only-blue)](#license)
[![CI](https://github.com/aljazmc/dockerfiles/actions/workflows/ci.yml/badge.svg)](https://github.com/aljazmc/dockerfiles/actions/workflows/ci.yml)
[![Dockerfile license: MIT](https://img.shields.io/badge/Dockerfile%20license-MIT-blue)](https://github.com/aljazmc/dockerfiles/blob/main/LICENSE)

[Docker Hub](https://hub.docker.com/r/aljazmc/image-spinner) · [Source](https://github.com/aljazmc/dockerfiles/tree/main/image-spinner) · [All images](https://github.com/aljazmc/dockerfiles)

## Overview

| | |
|---|---|
| **Base image** | `alpine:3.24.4` |
| **Software** | Alpine Linux 3.24.4 build tools: abuild, alpine-conf, `mkimage.sh` of the aports tree |
| **Also included** | abuild, alpine-conf, git, GRUB, syslinux, mtools, squashfs-tools, xorriso, rsync, ShellCheck |
| **User** | `aljazmc` (uid 1000) with passwordless `doas` (`doas apk add ...`) |
| **Tags** | `latest`, `3.24.4`, `3.24.4-YYYYMMDD` |

## Quick start

Run in an empty directory; the commands work on the files of the current directory, mounted as the home directory of the container. [CI](https://github.com/aljazmc/dockerfiles/actions/workflows/ci.yml) runs these commands to check that they work.

```sh
# prepare the current directory: a signing key, and the aports tree cloned the first time
docker run --rm -v .:/home/aljazmc -w /home/aljazmc aljazmc/image-spinner

# the options of mkimage.sh, which builds the ISO
docker run --rm -v .:/home/aljazmc -w /home/aljazmc aljazmc/image-spinner "sh aports/scripts/mkimage.sh --help"
```

<!-- quickstart check
test -f aports/scripts/mkimage.sh
test -f aports/scripts/mkimg.test.sh
-->

## Workflow with Docker

### 1. Prepare a directory
```
docker run --rm -v .:/home/aljazmc -w /home/aljazmc aljazmc/image-spinner:latest
```
### 2. Configure aports/scripts/mkimg.test.sh according to your preferences

### 3. Generate the iso with
```
docker run -it --rm --user aljazmc -v .:/home/aljazmc -w /home/aljazmc aljazmc/image-spinner:latest "sh aports/scripts/mkimage.sh --tag edge --outdir iso --arch x86_64 --repository https://dl-cdn.alpinelinux.org/alpine/edge/main --repository https://dl-cdn.alpinelinux.org/alpine/edge/community --profile test"
```

## Workflow with Docker Compose

### 1. Prepare a directory
```
# docker-compose.yml
services:
    spinner:
        image: aljazmc/image-spinner
        working_dir: /home/aljazmc
        volumes:
            - .:/home/aljazmc
        environment:
            HOME: /home/aljazmc
        network_mode: host

# command
docker compose run --rm spinner
```
### 2. Configure aports/scripts/mkimg.test.sh according to your preferences

### 3. Generate the iso with
```
docker compose run --rm spinner "sh aports/scripts/mkimage.sh --tag edge --outdir iso --arch x86_64 --repository https://dl-cdn.alpinelinux.org/alpine/edge/main --repository https://dl-cdn.alpinelinux.org/alpine/edge/community --profile test"
```

## Notes

- If `aports/README.md` file doesn't exist, aports github repository is cloned into temporary folder and then moved into `aports` folder.

## Tags

- `latest`: the newest build.
- `3.24.4`: the Alpine Linux version in the image, e.g. `aljazmc/image-spinner:3.24.4`. Use it to stay on a known version.
- `3.24.4-YYYYMMDD`: the same version, built on that date (UTC), e.g. `3.24.4-20261122`. Every build gets its own tag that never moves, so use it where you need exactly the same image again.
- Alpine Linux is the version of the `alpine:3.24.4` base image.

## License

The Dockerfile, the scripts and this README are part of [aljazmc/dockerfiles](https://github.com/aljazmc/dockerfiles), released under the [MIT License](https://github.com/aljazmc/dockerfiles/blob/main/LICENSE).

The software in the image keeps its own license:

| Software | License | In the image |
|---|---|---|
| [abuild](https://gitlab.alpinelinux.org/alpine/abuild) | GPL-2.0-only | `apk info --license abuild` |
| [alpine-conf](https://gitlab.alpinelinux.org/alpine/alpine-conf) | MIT | `apk info --license alpine-conf` |

Every other package keeps its license too: `apk info --license <package>` shows it on Alpine, `/usr/share/doc/<package>/copyright` on Debian.
