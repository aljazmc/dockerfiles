FROM debian:latest

SHELL ["/bin/bash", "-euxo", "pipefail", "-c"]

ARG DEBIAN_FRONTEND=noninteractive

ENV USER=heaps

RUN <<'EOT'
runtimeDeps=(
    haxe
    libapr1t64
    libgc1
    libgtk-3-0t64
    libmariadb3
    libmbedcrypto16
    libmbedtls21
    libmbedx509-7
    libneko2
    libpcre2-8-0
    libpulse0
    libsqlite3-0
    neko
    pipewire-bin
    rsync
    sudo
    zlib1g
)
buildDeps=(
    ca-certificates
    g++
    git
    libglu1-mesa-dev
    libmbedtls-dev
    libopenal-dev
    libpng-dev
    libsdl3-dev
    libsqlite3-dev
    libturbojpeg0-dev
    libuv1-dev
    libvorbis-dev
    make
)
apt-get update
apt-get install --no-install-recommends "${runtimeDeps[@]}" "${buildDeps[@]}" -y
rm -rf /var/lib/apt/lists/*
mkdir -p /usr/src/hashlink /usr/lib/haxe/lib
cd /usr/src/hashlink
git clone --depth 1 --branch latest https://github.com/HaxeFoundation/hashlink .
make
make install
ldconfig
make clean
rm -rf .git
EOT

RUN <<EOT
groupadd --gid 1000 "$USER"
useradd --uid 1000 --gid "$USER" --shell /bin/bash --create-home "$USER"
echo "$USER:$USER" | chpasswd
echo "${USER} ALL=(ALL) NOPASSWD:ALL" > "/etc/sudoers.d/90-$USER"
EOT

COPY --chmod="+x" docker-entrypoint.sh /usr/local/bin/

USER $USER
WORKDIR /home/$USER

ENTRYPOINT ["docker-entrypoint.sh"]
