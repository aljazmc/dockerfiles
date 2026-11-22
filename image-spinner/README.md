# aljazmc/image-spinner

Everything needed to build custom Alpine Linux ISO images with `mkimage.sh` from aports.

[![Docker Pulls](https://img.shields.io/docker/pulls/aljazmc/image-spinner)](https://hub.docker.com/r/aljazmc/image-spinner) [![Docker Image Size](https://img.shields.io/docker/image-size/aljazmc/image-spinner)](https://hub.docker.com/r/aljazmc/image-spinner) [![Docker Stars](https://img.shields.io/docker/stars/aljazmc/image-spinner)](https://hub.docker.com/r/aljazmc/image-spinner)

[Docker Hub](https://hub.docker.com/r/aljazmc/image-spinner) · [Source](https://github.com/aljazmc/dockerfiles/tree/main/image-spinner) · [All images](https://github.com/aljazmc/dockerfiles)

## Overview

| | |
|---|---|
| **Base image** | `alpine:3.24.4` |
| **Software** | Alpine Linux 3.24.4 build tools |
| **Also included** | abuild, alpine-conf, git, GRUB, syslinux, mtools, squashfs-tools, xorriso, rsync |
| **User** | `aljazmc` (uid 1000) with passwordless `doas` (`doas apk add ...`) |
| **Tags** | `latest`, `3.24.4`, `3.24.4-YYYYMMDD` |

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

Alpine Linux [aports](https://github.com/alpinelinux/aports) (GitHub mirror of [gitlab.alpinelinux.org/alpine/aports](https://gitlab.alpinelinux.org/alpine/aports)) has no single license: every package is released under its own free and open-source license, declared in the `license` field of its `APKBUILD`.
