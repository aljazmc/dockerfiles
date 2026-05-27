![Docker Pulls](https://img.shields.io/docker/pulls/aljazmc/heaps) ![Docker Image Size](https://img.shields.io/docker/image-size/aljazmc/heaps) ![Docker Stars](https://img.shields.io/docker/stars/aljazmc/heaps)

# Docker image with Heaps, Haxe, Neko and Hashlink.

[GitHub repository](https://github.com/aljazmc/dockerfiles/tree/main/heaps)

## Use cases:

###### Run this command in Linux terminal to create a `home` dir and prepare a shared volume for development:
```
mkdir -p home;
docker run
--device /dev/dri:/dev/dri \
--device /dev/snd:/dev/snd \
--network=host \
--user "$USER" \
-e DISPLAY="$DISPLAY" \
-e XDG_RUNTIME_DIR="$XDG_RUNTIME_DIR" \
-v ./home:/home/aljazmc \
-v /home/$USER/.Xauthority:/home/aljazmc/.Xauthority \
-v /run/user/$(id -u):/run/user/$(id -u) \
-v /tmp/.X11-unix:/tmp.X11-unix \
-v /var/lib/dbus/machine-id:/var/lib/dbus/machine-id \
-w /home/aljazmc \
aljazmc/heaps:latest
```

###### Afterwards you could just append shell commands in the end like this:
```
docker run 
--device /dev/dri:/dev/dri \
--device /dev/snd:/dev/snd \
--network=host \
--user "$USER" \
-e DISPLAY="$DISPLAY" \
-e XDG_RUNTIME_DIR="$XDG_RUNTIME_DIR" \
-v ./home:/home/aljazmc \
-v /home/$USER/.Xauthority:/home/aljazmc/.Xauthority \
-v /run/user/$(id -u):/run/user/$(id -u) \
-v /tmp/.X11-unix:/tmp.X11-unix \
-v /var/lib/dbus/machine-id:/var/lib/dbus/machine-id \
-w /home/aljazmc \
aljazmc/heaps:latest "haxe compile.hxml && hl hello.hl"
```
