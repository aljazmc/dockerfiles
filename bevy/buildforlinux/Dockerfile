FROM debian:latest

SHELL ["/bin/bash", "-euxo", "pipefail", "-c"]

ARG DEBIAN_FRONTEND=noninteractive

ENV BEVY_VERSION="0.20" \
    RUSTUP_HOME=/usr/local/rustup \
    USER=bevy

RUN <<'EOT'
commonDeps=(
    ca-certificates
    g++
    git
    rustup
    sudo
)
linuxDeps=(
    libasound2-dev
    libudev-dev
    libvulkan1
    libwayland-dev
    libx11-6
    libxcursor1
    libxi6
    libxkbcommon-dev
    libxkbcommon-x11-0
    libxrandr2
    mesa-vulkan-drivers
    pipewire-alsa
    pipewire-bin
    pkgconf
)
apt-get update
apt-get install --no-install-recommends "${commonDeps[@]}" "${linuxDeps[@]}" -y
rm -rf /var/lib/apt/lists/*
rustup set profile minimal
rustup default stable
EOT

RUN <<EOT
groupadd --gid 1000 "$USER"
useradd --uid 1000 --gid "$USER" --shell /bin/bash --create-home "$USER"
echo "$USER:$USER" | chpasswd
echo "${USER} ALL=(ALL) NOPASSWD:ALL" > "/etc/sudoers.d/90-$USER"
chown -R "$USER:$USER" "$RUSTUP_HOME"
EOT

COPY --chmod="+x" docker-entrypoint.sh makesh /usr/local/bin/

USER $USER
WORKDIR /home/$USER

ENTRYPOINT ["docker-entrypoint.sh"]
