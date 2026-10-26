FROM alpine:latest

SHELL ["/bin/sh", "-euxo", "pipefail", "-c"]

ARG USER=wine

ENV PATH="$PATH:/home/$USER"

RUN <<'EOF'
runtimeDeps="
    ca-certificates
    doas
"
libraries="
    dbus-libs
    fontconfig
    freetype
    gnutls
    libpulse
    libxcomposite
    libxcursor
    libxfixes
    libxinerama
    libxrender
    libxxf86vm
    mesa-dri-gallium
    mesa-egl
    mesa-gl
    mesa-vulkan-ati
    mesa-vulkan-intel
    mesa-vulkan-swrast
    pipewire-alsa
    sdl2
    vulkan-loader
"
wine="
    wine
"
apk add --no-cache $runtimeDeps $libraries $wine

addgroup -g 1000 "$USER"
adduser -u 1000 -G "$USER" -s /bin/sh -D "$USER"
echo "permit nopass :$USER as root" > /etc/doas.d/doas.conf
EOF

USER $USER
WORKDIR /home/$USER

COPY --chmod="+x" docker-entrypoint.sh /usr/local/bin/
ENTRYPOINT ["docker-entrypoint.sh"]

CMD [ "sh" ]
