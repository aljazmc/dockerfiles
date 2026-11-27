# aljazmc/node-debian

Node.js, Corepack and git on Debian, for projects that use Yarn Berry or pnpm.

[![Docker Pulls](https://img.shields.io/docker/pulls/aljazmc/node-debian)](https://hub.docker.com/r/aljazmc/node-debian) [![Docker Image Size](https://img.shields.io/docker/image-size/aljazmc/node-debian)](https://hub.docker.com/r/aljazmc/node-debian) [![Docker Stars](https://img.shields.io/docker/stars/aljazmc/node-debian)](https://hub.docker.com/r/aljazmc/node-debian)

[Docker Hub](https://hub.docker.com/r/aljazmc/node-debian) · [Source](https://github.com/aljazmc/dockerfiles/tree/main/node/debian) · [All images](https://github.com/aljazmc/dockerfiles)

## Overview

| | |
|---|---|
| **Base image** | `debian:13.7` |
| **Software** | Node 26.13.1 |
| **Also included** | Node.js 26.13.1 (official build, GPG verified), corepack, npm, git, ShellCheck |
| **User** | `node` (uid 1000) with passwordless `sudo` (`sudo apt-get install ...`) |
| **Tags** | `latest`, `26.13.1`, `26.13.1-YYYYMMDD` |

## Usage with Docker

```
## print node version
docker run --rm aljazmc/node-debian node -v

## set yarn version to berry
docker run --rm aljazmc/node-debian yarn set version berry

## initialize a new project
docker run --rm -v .:/home/node -w /home/node aljazmc/node-debian yarn init

## use shell inside the container to print environment variables
docker run --rm -it aljazmc/node-debian sh -c "printenv"
```

## Usage with Docker Compose

```
## docker-compose.yml file
services:
    node:
        image: aljazmc/node-debian
        working_dir: /home/node
        volumes:
            - .:/home/node
        environment:
            HOME: /home/node
            NODE_ENV: development
        network_mode: host

## print node version
docker-compose run --rm node node -v

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
- `26.13.1`: the Node version in the image, e.g. `aljazmc/node-debian:26.13.1`. Use it to stay on a known version.
- `26.13.1-YYYYMMDD`: the same version, built on that date (UTC), e.g. `26.13.1-20261122`. Every build gets its own tag that never moves, so use it where you need exactly the same image again.
- Corepack is pinned with `COREPACK_VERSION` in the Dockerfile (`npm install -g node@26.13.1`). Node.js is pinned to 26.13.0 with `NODE_VERSION`.

## License

Node is free and open-source software released under the [MIT License](https://github.com/nodejs/node/blob/main/LICENSE.md).
