FROM alpine:edge

SHELL ["/bin/sh", "-euxo", "pipefail", "-c"]

ARG USER=blender \
    BLENDER_VERSION=5.2

ENV LANG=C \
    LC_ALL=C \
    PATH="$PATH:/home/$USER"

RUN <<'EOF'
runtimeDeps="
    bash
    blender~$BLENDER_VERSION
    blender-headless~$BLENDER_VERSION
    blender-shared~$BLENDER_VERSION
    doas
    ffmpeg
    findutils
    libpulse
    pipewire-alsa
    py3-blender
    py3-cattrs
    py3-numpy
    py3-requests
    xterm
"
libraries="
    libdecor
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
