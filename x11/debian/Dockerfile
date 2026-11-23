FROM debian:13.7

SHELL ["/bin/bash", "-euxo", "pipefail", "-c"]

ARG DEBIAN_FRONTEND=noninteractive \
    LIBX11_VERSION=1.8.12 \
    USER=x11

ENV LANG=C \
    LC_ALL=C \
    PATH="$PATH:/home/$USER"

RUN <<'EOF'
runtimeDeps=(
    gtk2-engines-murrine
    gtk2-engines-pixbuf
    libpulse0
    pipewire-alsa
    shellcheck
    sudo
    xterm
)
libraries=(
    libdecor-0-0
    libegl1
    libgl1
    libgl1-mesa-dri
    libglx-mesa0
    libsndio7.0
    libvorbisfile3
    libvulkan1
    libwayland-client0
    libwayland-cursor0
    libwayland-egl1
    "libx11-6=2:$LIBX11_VERSION-*"
    libxcursor1
    libxi6
    libxinerama1
    libxkbcommon-x11-0
    libxkbcommon0
    libxrandr2
    libxss1
    mesa-vulkan-drivers
)
apt-get update
apt-get upgrade -y
apt-get install --no-install-recommends "${runtimeDeps[@]}" "${libraries[@]}" -y
apt-get dist-clean

groupadd --gid 1000 "$USER"
useradd --uid 1000 --gid "$USER" --shell /bin/bash --create-home "$USER"
echo "$USER:$USER" | chpasswd
echo "${USER} ALL=(ALL) NOPASSWD:ALL" > "/etc/sudoers.d/90-$USER"
EOF

USER $USER
WORKDIR /home/$USER

COPY --chmod="+x" docker-entrypoint.sh /usr/local/bin/
ENTRYPOINT ["docker-entrypoint.sh"]

CMD [ "bash" ]
