# aljazmc/corepack-debian

Node.js, Corepack and git on Debian, for projects that use Yarn Berry or pnpm.

[![Docker Pulls](https://img.shields.io/docker/pulls/aljazmc/corepack-debian)](https://hub.docker.com/r/aljazmc/corepack-debian) [![Docker Image Size](https://img.shields.io/docker/image-size/aljazmc/corepack-debian)](https://hub.docker.com/r/aljazmc/corepack-debian) [![Docker Stars](https://img.shields.io/docker/stars/aljazmc/corepack-debian)](https://hub.docker.com/r/aljazmc/corepack-debian)

[Docker Hub](https://hub.docker.com/r/aljazmc/corepack-debian) · [Source](https://github.com/aljazmc/dockerfiles/tree/main/corepack/debian) · [All images](https://github.com/aljazmc/dockerfiles)

## Overview

| | |
|---|---|
| **Base image** | `debian:13.7` |
| **Software** | Corepack 0.36.0 |
| **Also included** | Node.js 26.13.1 (official build, GPG verified), npm, git, ShellCheck |
| **User** | `node` (uid 1000) with passwordless `sudo` (`sudo apt-get install ...`) |
| **Tags** | `latest`, `0.36.0`, `0.36.0-YYYYMMDD` |

## Usage with Docker

```
## print corepack version
docker run --rm aljazmc/corepack-debian corepack -v

## set yarn version to berry
docker run --rm aljazmc/corepack-debian yarn set version berry

## initialize a new project
docker run --rm -v .:/home/node -w /home/node aljazmc/corepack-debian yarn init

## use shell inside the container to print environment variables
docker run --rm -it aljazmc/corepack-debian sh -c "printenv"
```

## Usage with Docker Compose

```
## docker-compose.yml file
services:
    node:
        image: aljazmc/corepack-debian
        working_dir: /home/node
        volumes:
            - .:/home/node
        environment:
            HOME: /home/node
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
- `0.36.0`: the Corepack version in the image, e.g. `aljazmc/corepack-debian:0.36.0`. Use it to stay on a known version.
- `0.36.0-YYYYMMDD`: the same version, built on that date (UTC), e.g. `0.36.0-20261122`. Every build gets its own tag that never moves, so use it where you need exactly the same image again.
- Corepack is pinned with `COREPACK_VERSION` in the Dockerfile (`npm install -g corepack@0.36.0`). Node.js is pinned to 26.13.0 with `NODE_VERSION`.

## License

Corepack is free and open-source software released under the [MIT License](https://github.com/nodejs/corepack/blob/main/LICENSE.md).
