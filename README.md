# aljazmc's dockerfiles

## > corepack
Docker image with corepack, node and git. To be used in development by yarn berry enthusiasts.
 
[aljazmc/corepack-debian](https://hub.docker.com/repository/docker/aljazmc/corepack-debian) ![Docker Pulls](https://img.shields.io/docker/pulls/aljazmc/corepack-debian) ![Docker Image Size](https://img.shields.io/docker/image-size/aljazmc/corepack-debian) ![Docker Stars](https://img.shields.io/docker/stars/aljazmc/corepack-debian)

[aljazmc/corepack-alpine](https://hub.docker.com/repository/docker/aljazmc/corepack-alpine) ![Docker Pulls](https://img.shields.io/docker/pulls/aljazmc/corepack-alpine) ![Docker Image Size](https://img.shields.io/docker/image-size/aljazmc/corepack-alpine) ![Docker Stars](https://img.shields.io/docker/stars/aljazmc/corepack-alpine)

### corepack-debian examples
#### with docker:
```
# print corepack version
docker run --rm aljazmc/corepack-debian corepack -v

# set yarn version to berry
docker run --rm aljazmc/corepack-debian yarn set version berry

# initialize a new project in folder "myproject"
mkdir myproject && docker run --rm -v ./myproject:/home/node -w /home/node aljazmc/corepack-debian yarn init

# use shell inside the container to print environment variables
docker run --rm -it aljazmc/corepack-debian sh -c "printenv"

```
#### with docker-compose:
```
docker-compose.yml file
--------------------------------------------------------------
services:
    node:
        image: aljazmc/corepack-debian
        working_dir: /home/node
        volumes:
            - ./myproject:/home/node
        environment:
            HOME: /home/node
            NODE_ENV: development
        network_mode: host
--------------------------------------------------------------
# print corepack version
docker-compose run --rm node corepack -v

# set yarn version to berry
docker-compose run --rm node yarn set version berry

# initialize a new project in folder "myproject"
mkdir myproject && docker-compose run --rm node yarn init

# use shell inside the container to print environment variables
docker-compose run --rm node sh -c "printenv"

```
##### notes
- not intended for production use.
- passwordless sudo

### corepack-alpine examples
#### with docker:
```
# print corepack version
docker run --rm aljazmc/corepack-alpine corepack -v

# set yarn version to berry
docker run --rm aljazmc/corepack-alpine yarn set version berry

# initialize a new project in folder "myproject"
mkdir myproject && docker run --rm -v ./myproject:/home/node -w /home/node aljazmc/corepack-alpine yarn init

# use shell inside the container to print environment variables
docker run --rm -it aljazmc/corepack-alpine sh -c "printenv"

```
#### with docker-compose:
```
docker-compose.yml file
--------------------------------------------------------------
services:
    node:
        image: aljazmc/corepack-alpine
        working_dir: /home/node
        volumes:
            - ./myproject:/home/node
        environment:
            HOME: /home/node
            NODE_ENV: development
        network_mode: host
--------------------------------------------------------------
# print corepack version
docker-compose run --rm node corepack -v

# set yarn version to berry
docker-compose run --rm node yarn set version berry

# initialize a new project in folder "myproject"
mkdir myproject && docker-compose run --rm node yarn init

# use shell inside the container to print environment variables
docker-compose run --rm node sh -c "printenv"

```
##### notes
- not intended for production use.
- passwordless doas
