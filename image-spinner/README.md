![Docker Pulls](https://img.shields.io/docker/pulls/aljazmc/image-spinner) ![Docker Image Size](https://img.shields.io/docker/image-size/aljazmc/image-spinner) ![Docker Stars](https://img.shields.io/docker/stars/aljazmc/image-spinner)

# Docker image with everything necessary to create custom Alpine Linux distributions.

[GitHub repository](https://github.com/aljazmc/dockerfiles/tree/main/image-spinner)

## workflow with docker:

##### 1.) prepare a directory:
```
docker run --rm -v .:/home/aljazmc -w /home/aljazmc aljazmc/image-spinner:latest
```
##### 2.) configure aports/scripts/mkimg.test.sh according to your preferences

##### 3.) generate the iso with:
```
docker run -it --rm --user aljazmc -v .:/home/aljazmc -w /home/aljazmc aljazmc/image-spinner:latest "sh aports/scripts/mkimage.sh --tag edge --outdir iso --arch x86_64 --repository https://dl-cdn.alpinelinux.org/alpine/edge/main --repository https://dl-cdn.alpinelinux.org/alpine/edge/community --profile test"
```

## workflow with docker compose:

##### 1.) prepare a directory:
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

docker compose run --rm spinner
```
##### 2.) configure aports/scripts/mkimg.test.sh according to your preferences

##### 3.) generate the iso with:
```
docker compose run --rm spinner "sh aports/scripts/mkimage.sh --tag edge --outdir iso --arch x86_64 --repository https://dl-cdn.alpinelinux.org/alpine/edge/main --repository https://dl-cdn.alpinelinux.org/alpine/edge/community --profile test"
```
