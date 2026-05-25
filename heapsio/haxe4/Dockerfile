FROM debian:latest

SHELL ["/bin/bash", "-euxo", "pipefail", "-c"]

ENV DEBIAN_FRONTEND=noninteractive \ 
    PATH=/usr/src/hashlink:$PATH \
    USER=aljazmc

RUN <<'EOT'
runtimeDeps=(
    ca-certificates
    git 
    libgc1
    libmariadb3
    libmbedcrypto16
    libmbedtls21
    libmbedx509-7
    libpcre2-8-0
    libsqlite3-0
    rsync
    sudo
    zlib1g
    haxe
    libapache2-mod-neko
    libneko2
    neko
    neko-dev
)
apt-get update
apt-get install ${runtimeDeps[@]} -y --no-install-recommends
EOT

RUN <<'EOT'
buildDeps=(
    g++
    libglu1-mesa-dev
    libmbedtls-dev
    libopenal-dev
    libpng-dev
    libsdl2-dev
    libsqlite3-dev
    libturbojpeg0-dev
    libuv1-dev
    libvorbis-dev
    make
)
    apt-get update
    apt-get install ${buildDeps[@]} -y --no-install-recommends
    mkdir -p /usr/src/hashlink /usr/lib/haxe/lib
    cd /usr/src/hashlink
    git clone https://github.com/HaxeFoundation/hashlink .
    git checkout latest
    make
    make install
    # apt-get purge -y --auto-remove ${buildDeps[@]}
EOT

RUN <<EOT
groupadd --gid 1000 $USER
useradd --uid 1000 --gid $USER --shell /bin/bash --create-home $USER
echo "$USER:$USER" | chpasswd
echo "${USER} ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/90-$USER
EOT

USER $USER
WORKDIR /home/$USER

CMD [ "haxe" ]
