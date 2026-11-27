# aljazmc/node-debian

Node.js with Corepack for Yarn Berry and pnpm on Debian, for JavaScript projects.

[![Docker pulls](https://img.shields.io/docker/pulls/aljazmc/node-debian?logo=docker&logoColor=white)](https://hub.docker.com/r/aljazmc/node-debian)
[![Image size](https://img.shields.io/docker/image-size/aljazmc/node-debian/latest?logo=docker&logoColor=white)](https://hub.docker.com/r/aljazmc/node-debian/tags)
[![Version](https://img.shields.io/docker/v/aljazmc/node-debian?sort=semver&logo=docker&logoColor=white)](https://hub.docker.com/r/aljazmc/node-debian/tags)
[![platforms: amd64 | arm64](https://img.shields.io/badge/platforms-amd64%20%7C%20arm64-2496ed?logo=docker&logoColor=white)](https://github.com/aljazmc/dockerfiles#building-and-testing)
[![Debian: 13.8](https://img.shields.io/badge/Debian-13.8-a81d33?logo=debian&logoColor=white)](https://hub.docker.com/_/debian)
[![Node.js: 26.13.1](https://img.shields.io/badge/Node.js-26.13.1-5fa04e?logo=nodedotjs&logoColor=white)](https://github.com/nodejs/node/blob/main/LICENSE)
[![Node.js license: MIT](https://img.shields.io/badge/Node.js%20license-MIT-blue)](#license)
[![CI](https://github.com/aljazmc/dockerfiles/actions/workflows/ci.yml/badge.svg)](https://github.com/aljazmc/dockerfiles/actions/workflows/ci.yml)
[![Dockerfile license: MIT](https://img.shields.io/badge/Dockerfile%20license-MIT-blue)](https://github.com/aljazmc/dockerfiles/blob/main/LICENSE)

[Docker Hub](https://hub.docker.com/r/aljazmc/node-debian) · [Source](https://github.com/aljazmc/dockerfiles/tree/main/node/debian) · [All images](https://github.com/aljazmc/dockerfiles)

## Overview

| | |
|---|---|
| **Base image** | `debian:13.8` |
| **Software** | Node.js 26.13.1 (official build, GPG verified) with Corepack 0.36.0 |
| **Also included** | npm, Yarn (through Corepack), git, bash, ShellCheck |
| **User** | `node` (uid 1000) with passwordless `sudo` (`sudo apt-get install ...`) |
| **Tags** | `latest`, `26.13.1`, `26.13.1-YYYYMMDD` |

## Quick start

Run in an empty directory; the commands work on the files of the current directory, mounted as the home directory of the container. [CI](https://github.com/aljazmc/dockerfiles/actions/workflows/ci.yml) runs these commands to check that they work.

```sh
# open the REPL of Node.js
docker run --rm -it aljazmc/node-debian

# the versions of Node.js, npm and Corepack
docker run --rm aljazmc/node-debian sh -c "node --version && npm --version && corepack --version"

# set up a Yarn Berry project in the current directory
docker run --rm -v .:/home/node -w /home/node aljazmc/node-debian yarn init -2
```

<!-- quickstart check
test -f package.json
test -f yarn.lock
-->

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

The Dockerfile, the scripts and this README are part of [aljazmc/dockerfiles](https://github.com/aljazmc/dockerfiles), released under the [MIT License](https://github.com/aljazmc/dockerfiles/blob/main/LICENSE).

The software in the image keeps its own license:

| Software | License | In the image |
|---|---|---|
| [Node.js](https://github.com/nodejs/node/blob/main/LICENSE) | MIT | `/usr/local/LICENSE` |

Every other package keeps its license too: `apk info --license <package>` shows it on Alpine, `/usr/share/doc/<package>/copyright` on Debian.
