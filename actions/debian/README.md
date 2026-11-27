# aljazmc/actions-debian

A Debian image for running GitHub Actions workflows locally with [act](https://github.com/nektos/act), or as a CI job container: Node.js, Corepack, the Docker CLI, git, FFmpeg, ShellCheck and Ruff.

[![Docker pulls](https://img.shields.io/docker/pulls/aljazmc/actions-debian?logo=docker&logoColor=white)](https://hub.docker.com/r/aljazmc/actions-debian)
[![Image size](https://img.shields.io/docker/image-size/aljazmc/actions-debian/latest?logo=docker&logoColor=white)](https://hub.docker.com/r/aljazmc/actions-debian/tags)
[![Version](https://img.shields.io/docker/v/aljazmc/actions-debian?sort=semver&logo=docker&logoColor=white)](https://hub.docker.com/r/aljazmc/actions-debian/tags)
[![platforms: amd64 | arm64](https://img.shields.io/badge/platforms-amd64%20%7C%20arm64-2496ed?logo=docker&logoColor=white)](https://github.com/aljazmc/dockerfiles#building-and-testing)
[![Debian: 13.7](https://img.shields.io/badge/Debian-13.7-a81d33?logo=debian&logoColor=white)](https://hub.docker.com/_/debian)
[![Node.js: 26.13.1](https://img.shields.io/badge/Node.js-26.13.1-5fa04e?logo=nodedotjs&logoColor=white)](https://github.com/nodejs/node/blob/main/LICENSE)
[![Node.js license: MIT](https://img.shields.io/badge/Node.js%20license-MIT-blue)](#license)
[![CI](https://github.com/aljazmc/dockerfiles/actions/workflows/ci.yml/badge.svg)](https://github.com/aljazmc/dockerfiles/actions/workflows/ci.yml)
[![Dockerfile license: MIT](https://img.shields.io/badge/Dockerfile%20license-MIT-blue)](https://github.com/aljazmc/dockerfiles/blob/main/LICENSE)

[Docker Hub](https://hub.docker.com/r/aljazmc/actions-debian) · [Source](https://github.com/aljazmc/dockerfiles/tree/main/actions/debian) · [All images](https://github.com/aljazmc/dockerfiles)

## Overview

| | |
|---|---|
| **Base image** | `debian:13.7`, upgraded to 13.8 when it is built |
| **Software** | Node.js 26.13.1 (official build, GPG verified) with Corepack 0.36.0 |
| **Also included** | npm, Yarn (through Corepack), git, Docker CE CLI with buildx and compose, FFmpeg, Python 3 with NumPy, mido, rtmidi and pytest, ShellCheck, Ruff 0.17.6 (pip) |
| **User** | `actions` (uid 1000) with passwordless `sudo` (`sudo apt-get install ...`) |
| **Tags** | `latest`, `13.8`, `13.8-YYYYMMDD` (the Debian version) |

## Quick start

Run in an empty directory; the commands work on the files of the current directory, mounted as the home directory of the container. [CI](https://github.com/aljazmc/dockerfiles/actions/workflows/ci.yml) runs these commands to check that they work.

<!-- quickstart setup
printf '#!/bin/sh\necho "hello $1"\n' > hello.sh
printf 'print("hello")\n' > hello.py
-->

```sh
# open a shell, with the current directory as the home directory
docker run --rm -it -v .:/home/actions -w /home/actions aljazmc/actions-debian

# the tools a CI job gets
docker run --rm aljazmc/actions-debian sh -c "node --version && corepack --version && git --version && docker --version && ruff version"

# lint the shell scripts and the Python code of the current directory
docker run --rm -v .:/home/actions -w /home/actions aljazmc/actions-debian sh -c "shellcheck *.sh && ruff check --no-cache ."
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
- `13.8`: the Debian Linux version in the image, e.g. `aljazmc/actions-debian:13.7`. Use it to stay on a known version.
- `13.8-YYYYMMDD`: the same version, built on that date (UTC), e.g. `13.7-20261124`. Every build gets its own tag that never moves, so use it where you need exactly the same image again.
- Corepack is pinned with `COREPACK_VERSION` in the Dockerfile (`npm install -g corepack@0.36.0`). Node.js is pinned to 26.13.1 with `NODE_VERSION`.

## License

The Dockerfile, the scripts and this README are part of [aljazmc/dockerfiles](https://github.com/aljazmc/dockerfiles), released under the [MIT License](https://github.com/aljazmc/dockerfiles/blob/main/LICENSE).

The software in the image keeps its own license:

| Software | License | In the image |
|---|---|---|
| [Node.js](https://github.com/nodejs/node/blob/main/LICENSE) | MIT | `/usr/local/LICENSE` |

Every other package keeps its license too: `apk info --license <package>` shows it on Alpine, `/usr/share/doc/<package>/copyright` on Debian.
