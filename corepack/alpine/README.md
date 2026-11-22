# aljazmc/corepack-alpine

Node.js, Corepack and git on Alpine Linux, for projects that use Yarn Berry or pnpm.

[![Docker Pulls](https://img.shields.io/docker/pulls/aljazmc/corepack-alpine)](https://hub.docker.com/r/aljazmc/corepack-alpine) [![Docker Image Size](https://img.shields.io/docker/image-size/aljazmc/corepack-alpine)](https://hub.docker.com/r/aljazmc/corepack-alpine) [![Docker Stars](https://img.shields.io/docker/stars/aljazmc/corepack-alpine)](https://hub.docker.com/r/aljazmc/corepack-alpine)

[Docker Hub](https://hub.docker.com/r/aljazmc/corepack-alpine) · [Source](https://github.com/aljazmc/dockerfiles/tree/main/corepack/alpine) · [All images](https://github.com/aljazmc/dockerfiles)

## Overview

| | |
|---|---|
| **Base image** | `alpine:3.24.4` |
| **Software** | Corepack 0.36.0 |
| **Also included** | Node.js 26.13.0 (unofficial musl build, sha256 checked), npm, git |
| **User** | `node` (uid 1000) with passwordless `doas` (`doas apk add ...`) |
| **Tags** | `latest`, `0.36.0` |

## Usage with Docker

```
## print corepack version
docker run --rm aljazmc/corepack-alpine corepack -v

## set yarn version to berry
docker run --rm aljazmc/corepack-alpine yarn set version berry

## initialize a new project
docker run --rm -v .:/home/node -w /home/node aljazmc/corepack-alpine yarn init

## use shell inside the container to print environment variables
docker run --rm -it aljazmc/corepack-alpine sh -c "printenv"
```

## Usage with Docker Compose

```
## docker-compose.yml file
services:
    node:
        image: aljazmc/corepack-alpine
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
- `0.36.0`: the Corepack version in the image, e.g. `aljazmc/corepack-alpine:0.36.0`. Use it to stay on a known version.
- Corepack is pinned with `COREPACK_VERSION` in the Dockerfile (`npm install -g corepack@0.36.0`). Node.js is pinned to 26.13.0 with `NODE_VERSION`.

## License

Corepack is free and open-source software released under the [MIT License](https://github.com/nodejs/corepack/blob/main/LICENSE.md).
