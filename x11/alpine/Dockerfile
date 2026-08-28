FROM alpine:latest

SHELL ["/bin/sh", "-euxo", "pipefail", "-c"]

ARG USER=x11

ENV PATH="$PATH:/home/$USER"

RUN <<EOF
runtimeDeps="
    bash
    doas
    openbox
    pipewire
    pipewire-alsa
    pipewire-pulse
    wireplumber
    xauth
    xinit
    xorg-server
    xterm
"
libraries="
    gcompat
    glu-dev
    libjpeg-turbo-dev
    libpng-dev
    libstdc++
    libuv-dev
    libvorbis-dev
    mbedtls-dev
    mesa-dev
    openal-soft-dev
    sdl3-dev
    sqlite-dev
    vulkan-loader-dev
"
apk add --no-cache ${runtimeDeps} ${libraries}

addgroup -g 1000 $USER
adduser -u 1000 -G $USER -s /bin/sh -D $USER
echo "permit nopass :$USER as root" > /etc/doas.d/doas.conf

rm -rf /tmp/*
EOF

USER $USER
WORKDIR /home/$USER

COPY --chmod="+x" docker-entrypoint.sh /usr/local/bin/
ENTRYPOINT ["docker-entrypoint.sh"]

CMD [ "sh" ]
