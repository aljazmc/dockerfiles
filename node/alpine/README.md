# aljazmc/node-alpine

Node.js, Node and git on Alpine Linux, for projects that use Yarn Berry or pnpm.

[![Docker Pulls](https://img.shields.io/docker/pulls/aljazmc/node-alpine)](https://hub.docker.com/r/aljazmc/node-alpine) [![Docker Image Size](https://img.shields.io/docker/image-size/aljazmc/node-alpine)](https://hub.docker.com/r/aljazmc/node-alpine) [![Docker Stars](https://img.shields.io/docker/stars/aljazmc/node-alpine)](https://hub.docker.com/r/aljazmc/node-alpine)

[Docker Hub](https://hub.docker.com/r/aljazmc/node-alpine) · [Source](https://github.com/aljazmc/dockerfiles/tree/main/node/alpine) · [All images](https://github.com/aljazmc/dockerfiles)

## Overview

| | |
|---|---|
| **Base image** | `alpine:3.24.4` |
| **Software** | Node 26.13.1 |
| **Also included** | Node.js 26.13.1 (unofficial musl build, sha256 checked), npm, git, ShellCheck |
| **User** | `node` (uid 1000) with passwordless `doas` (`doas apk add ...`) |
| **Tags** | `latest`, `26.13.1`, `26.13.1-YYYYMMDD` |

## Usage with Docker

```
## print node version
docker run --rm aljazmc/node-alpine node -v

## set yarn version to berry
docker run --rm aljazmc/node-alpine yarn set version berry

## initialize a new project
docker run --rm -v .:/home/node -w /home/node aljazmc/node-alpine yarn init

## use shell inside the container to print environment variables
docker run --rm -it aljazmc/node-alpine sh -c "printenv"
```

## Usage with Docker Compose

```
## docker-compose.yml file
services:
    node:
        image: aljazmc/node-alpine
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
- `26.13.1`: the Node version in the image, e.g. `aljazmc/node-alpine:26.13.1`. Use it to stay on a known version.
- `26.13.1-YYYYMMDD`: the same version, built on that date (UTC), e.g. `26.13.1-20261122`. Every build gets its own tag that never moves, so use it where you need exactly the same image again.
- Corepack is pinned with `COREPACK_VERSION` in the Dockerfile (`npm install -g node@26.13.1`). Node.js is pinned to 26.13.0 with `NODE_VERSION`.

## License

Node is free and open-source software released under the [MIT License](https://github.com/nodejs/node/blob/main/LICENSE.md).
