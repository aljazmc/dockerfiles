FROM debian:latest

SHELL ["/bin/bash", "-euxo", "pipefail", "-c"]

ARG DEBIAN_FRONTEND=noninteractive \
    USER=wine

ENV PATH="$PATH:/home/$USER"

RUN <<'EOF'
runtimeDeps=(
    ca-certificates
    sudo
)
buildDeps=(
    gpg
    wget
)
libraries=(
    libdbus-1-3
    libegl1
    libfontconfig1
    libfreetype6
    libgl1
    libgl1-mesa-dri
    libglx-mesa0
    libgnutls30t64
    libsdl2-2.0-0
    libvulkan1
    libxcomposite1
    libxcursor1
    libxfixes3
    libxi6
    libxinerama1
    libxrandr2
    libxrender1
    libxxf86vm1
    mesa-vulkan-drivers
    libdbus-1-3:i386
    libegl1:i386
    libfontconfig1:i386
    libfreetype6:i386
    libgl1-mesa-dri:i386
    libgl1:i386
    libglx-mesa0:i386
    libgnutls30t64:i386
    libsdl2-2.0-0:i386
    libvulkan1:i386
    libxcomposite1:i386
    libxcursor1:i386
    libxfixes3:i386
    libxi6:i386
    libxinerama1:i386
    libxrandr2:i386
    libxrender1:i386
    libxxf86vm1:i386
    mesa-vulkan-drivers:i386
)
wine=(
    winehq-devel
)
apt-get update
apt-get install --no-install-recommends "${runtimeDeps[@]}" "${buildDeps[@]}" -y

dpkg --add-architecture i386
wget -NP /etc/apt/sources.list.d/ https://dl.winehq.org/wine-builds/debian/dists/trixie/winehq-trixie.sources

mkdir -pm755 /etc/apt/keyrings
wget -O - https://dl.winehq.org/wine-builds/winehq.key | gpg --dearmor -o /etc/apt/keyrings/winehq-archive.key -

apt-get update
apt-get install --no-install-recommends "${libraries[@]}" "${wine[@]}" -y
apt-get purge --auto-remove "${buildDeps[@]}" -y
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
