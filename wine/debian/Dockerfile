FROM debian:latest

SHELL ["/bin/bash", "-euxo", "pipefail", "-c"]

ARG DEBIAN_FRONTEND=noninteractive \
    USER=wine

ENV PATH="$PATH:/home/$USER"

RUN <<'EOF'
runtimeDeps=(
    ca-certificates
    gpg
    gpg-agent
    libatomic1
    openbox
    sudo
    xauth
    xinit
    xorg
    xterm
    wget
)
libraries=(
    libgl-dev
    libglx-dev
    libglu1-mesa-dev
    libmbedtls-dev
    libopenal-dev
    libpng-dev
    libsdl3-dev
    libsqlite3-dev
    libturbojpeg0-dev
    libuv1-dev
    libvorbis-dev
    libvulkan-dev
    mesa-common-dev
)
wine=(
    winehq-devel
)
apt-get update
apt-get install --no-install-recommends ${runtimeDeps[@]} ${libraries[@]} -y

dpkg --add-architecture i386
wget -NP /etc/apt/sources.list.d/ https://dl.winehq.org/wine-builds/debian/dists/trixie/winehq-trixie.sources

mkdir -pm755 /etc/apt/keyrings
wget -O - https://dl.winehq.org/wine-builds/winehq.key | gpg --dearmor -o /etc/apt/keyrings/winehq-archive.key -

apt update
apt-get install --install-recommends ${wine[@]} -y
apt-get dist-clean

groupadd --gid 1000 $USER
useradd --uid 1000 --gid $USER --shell /bin/bash --create-home $USER
echo "$USER:$USER" | chpasswd
echo "${USER} ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/90-$USER
EOF

USER $USER
WORKDIR /home/$USER

COPY --chmod="+x" docker-entrypoint.sh /usr/local/bin/
ENTRYPOINT ["docker-entrypoint.sh"]

CMD [ "bash" ]
