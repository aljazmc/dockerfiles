# aljazmc/actions-debian

Self-hosted runner for GitHub Actions on Debian Linux for running with gh act

[![Docker Pulls](https://img.shields.io/docker/pulls/aljazmc/actions-debian)](https://hub.docker.com/r/aljazmc/actions-debian) [![Docker Image Size](https://img.shields.io/docker/image-size/aljazmc/actions-debian)](https://hub.docker.com/r/aljazmc/actions-debian) [![Docker Stars](https://img.shields.io/docker/stars/aljazmc/actions-debian)](https://hub.docker.com/r/aljazmc/actions-debian)

[Docker Hub](https://hub.docker.com/r/aljazmc/actions-debian) · [Source](https://github.com/aljazmc/dockerfiles/tree/main/actions/debian) · [All images](https://github.com/aljazmc/dockerfiles)

## Overview

| | |
|---|---|
| **Base image** | `debian:13.7` |
| **Software** | Node.js 26.13.1 (official build, GPG verified) |
| **Also included** | npm, corepack, docker, ShellCheck, ruff and git |
| **User** | `actions` (uid 1000) with passwordless `sudo` (`sudo apt-get install ...`) |
| **Tags** | `latest`, `13.7`, `13.7-YYYYMMDD` |

## Usage with Docker

```
## print corepack version
docker run --rm aljazmc/actions-debian corepack -v

## set yarn version to berry
docker run --rm aljazmc/actions-debian yarn set version berry

## initialize a new project
docker run --rm -v .:/home/actions -w /home/node aljazmc/actions-debian yarn init

## use shell inside the container to print environment variables
docker run --rm -it aljazmc/actions-debian sh -c "printenv"
```

## Usage with Docker Compose

```
## docker-compose.yml file
services:
    node:
        image: aljazmc/actions-debian
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
- `13.7`: the Debian Linux version in the image, e.g. `aljazmc/actions-debian:13.7`. Use it to stay on a known version.
- `13.7-YYYYMMDD`: the same version, built on that date (UTC), e.g. `13.7-20261124`. Every build gets its own tag that never moves, so use it where you need exactly the same image again.
- Corepack is pinned with `COREPACK_VERSION` in the Dockerfile (`npm install -g corepack@0.36.0`). Node.js is pinned to 26.13.1 with `NODE_VERSION`.

## License

Corepack is free and open-source software released under the [MIT License](https://github.com/nodejs/corepack/blob/main/LICENSE.md).
