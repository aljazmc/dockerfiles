# aljazmc/actions-alpine

Self-hosted runner image for GitHub Actions on Alpine Linux for running with gh act.

[![Docker Pulls](https://img.shields.io/docker/pulls/aljazmc/actions-alpine)](https://hub.docker.com/r/aljazmc/actions-alpine) [![Docker Image Size](https://img.shields.io/docker/image-size/aljazmc/actions-alpine)](https://hub.docker.com/r/aljazmc/actions-alpine) [![Docker Stars](https://img.shields.io/docker/stars/aljazmc/actions-alpine)](https://hub.docker.com/r/aljazmc/actions-alpine)

[Docker Hub](https://hub.docker.com/r/aljazmc/actions-alpine) · [Source](https://github.com/aljazmc/dockerfiles/tree/main/actions/alpine) · [All images](https://github.com/aljazmc/dockerfiles)

## Overview

| | |
|---|---|
| **Base image** | `alpine:3.24.4` |
| **Software** | Node.js 26.13.1 (unofficial musl build, sha256 checked) |
| **Also included** | npm, git, ShellCheck, ruff, ffmpeg, findutils |
| **User** | `actions` (uid 1000) with passwordless `doas` (`doas apk add ...`) |
| **Tags** | `latest`, `3.24.4`, `3.24.4-YYYYMMDD` |

## Usage with Docker

```
## print Alpine Linux version
docker run aljazmc/actions-alpine cat /etc/alpine-release

## set yarn version to berry
docker run --rm aljazmc/actions-alpine yarn set version berry

## initialize a new project
docker run --rm -v .:/home/actions -w /home/node aljazmc/actions-alpine yarn init

## use shell inside the container to print environment variables
docker run --rm -it aljazmc/actions-alpine sh -c "printenv"
```

## Usage with Docker Compose

```
## docker-compose.yml file
services:
    node:
        image: aljazmc/actions-alpine
        working_dir: /home/actions
        volumes:
            - .:/home/actions
        environment:
            HOME: /home/actions
            NODE_ENV: development
        network_mode: host

## print corepack version
docker-compose run --rm node corepack -v

## set yarn version to berry
docker-compose run --rm node yarn set version berry

## initialize a new project
docker-compose run --rm node yarn init

## use shell inside the container to print environment variables
docker-compose run --rm node sh -c "printenv"
```

## Notes

- Not intended for production use.

## Tags

- `latest`: the newest build.
- `3.24.4`: the Alpine Linux version in the image, e.g. `aljazmc/actions-alpine:3.24.4`. Use it to stay on a known version.
- `3.24.4-YYYYMMDD`: the same version, built on that date (UTC), e.g. `3.24.4-20261124`. Every build gets its own tag that never moves, so use it where you need exactly the same image again.
- Corepack is pinned with `COREPACK_VERSION` in the Dockerfile (`npm install -g corepack@0.36.0`). Node.js is pinned to 26.13.1 with `NODE_VERSION`.

## License

Corepack is free and open-source software released under the [MIT License](https://github.com/nodejs/corepack/blob/main/LICENSE.md).
