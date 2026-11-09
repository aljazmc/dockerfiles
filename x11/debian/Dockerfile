FROM debian:latest

SHELL ["/bin/bash", "-euxo", "pipefail", "-c"]

ARG DEBIAN_FRONTEND=noninteractive \
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
    libvulkan1
    libwayland-client0
    libwayland-cursor0
    libwayland-egl1
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
