FROM debian:latest

SHELL ["/bin/bash", "-euxo", "pipefail", "-c"]

ARG DEBIAN_FRONTEND=noninteractive

ENV USER=heaps

RUN <<'EOT'
commonDeps=(
    ca-certificates
    git
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
    libsqlite3-0
    neko
    rsync
    sudo
    zlib1g
)
linuxDeps=(
    g++
    libglu1-mesa-dev
    libmbedtls-dev
    libopenal-dev
    libpng-dev
    libpulse0
    libsdl3-dev
    libsndio7.0
    libsqlite3-dev
    libturbojpeg0-dev
    libuv1-dev
    libvorbis-dev
    make
    pipewire-bin
)
apt-get update
apt-get install --no-install-recommends "${commonDeps[@]}" "${linuxDeps[@]}" -y
rm -rf /var/lib/apt/lists/*
mkdir -p /usr/src/hashlink
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

COPY --chmod="+x" bundle docker-entrypoint.sh makesh /usr/local/bin/

USER $USER
WORKDIR /home/$USER

ENTRYPOINT ["docker-entrypoint.sh"]
