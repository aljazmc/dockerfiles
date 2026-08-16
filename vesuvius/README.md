![Docker Pulls](https://img.shields.io/docker/pulls/aljazmc/vesuvius) ![Docker Image Size](https://img.shields.io/docker/image-size/aljazmc/vesuvius) ![Docker Stars](https://img.shields.io/docker/stars/aljazmc/vesuvius)

# Docker image with everything necessary to quickly set up Vesuvius challenge development environment.

[GitHub repository](https://github.com/aljazmc/dockerfiles/tree/main/vesuvius)

## use cases with docker:

###### install aws cli and kickstart bash
```
docker run --rm -v .:/home/aljazmc -w /home/aljazmc aljazmc/vesuvius
```

## use cases with docker compose:

###### install aws cli and kickstart bash
```
# docker-compose.yml
services:
    vesuvius:
        image: aljazmc/vesuvius
        working_dir: /home/aljazmc
        volumes:
            - .:/home/aljazmc
        environment:
            HOME: /home/aljazmc
        network_mode: host

# command
docker compose run --rm vesuvius
```

##### notes
- passwordless sudo

