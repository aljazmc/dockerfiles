[aljazmc/image-spinner](https://hub.docker.com/repository/docker/aljazmc/image-spinner) ![Docker Pulls](https://img.shields.io/docker/pulls/aljazmc/image-spinner) ![Docker Image Size](https://img.shields.io/docker/image-size/aljazmc/image-spinner) ![Docker Stars](https://img.shields.io/docker/stars/aljazmc/image-spinner)

# Docker image with everything necessary to create custom Alpine Linux distributions.

[GitHub repository](https://github.com/aljazmc/dockerfiles/tree/main/image-spinner)

Quick Workflow Example

1.) create a directory `home`:
```
mkdir -p home
```
2.) run docker image with home mounted into it:
```
docker run --rm -v ./home:/home/aljazmc -w /home/aljazmc aljazmc/image-spinner:latest
```
3.) configure aports/scripts/mkimg.test.sh according to your preference

4.) generate the iso with:
```
docker run -it --rm --user aljazmc -v ./home:/home/aljazmc -w /home/aljazmc aljazmc/image-spinner:latest "sh aports/scripts/mkimage.sh --tag edge --outdir iso --arch x86_64 --repository https://dl-cdn.alpinelinux.org/alpine/edge/main --profile"
```
