FROM alpine:3.24.4

SHELL ["/bin/sh", "-euxo", "pipefail", "-c"]

ARG LIBX11_VERSION=1.8.14 \
    USER=x11

ENV LANG=C \
    LC_ALL=C \
    PATH="$PATH:/home/$USER"

RUN <<'EOF'
runtimeDeps="
    doas
    gtk+2.0
    libpulse
    pipewire-alsa
    xterm
"
libraries="
    libdecor
    libvorbis
    libx11~$LIBX11_VERSION
    libxcursor
    libxi
    libxinerama
    libxkbcommon
    libxkbcommon-x11
    libxrandr
    libxscrnsaver
    mesa-dri-gallium
    mesa-egl
    mesa-gl
    mesa-vulkan-ati
    mesa-vulkan-intel
    mesa-vulkan-nouveau
    mesa-vulkan-swrast
    vulkan-loader
    wayland-libs-client
    wayland-libs-cursor
    wayland-libs-egl
"
apk upgrade --no-cache
apk add --no-cache $runtimeDeps $libraries

addgroup -g 1000 "$USER"
adduser -u 1000 -G "$USER" -s /bin/sh -D "$USER"
echo "permit nopass :$USER as root" > /etc/doas.d/doas.conf
EOF

USER $USER
WORKDIR /home/$USER

COPY --chmod="+x" docker-entrypoint.sh /usr/local/bin/
ENTRYPOINT ["docker-entrypoint.sh"]

CMD [ "sh" ]
