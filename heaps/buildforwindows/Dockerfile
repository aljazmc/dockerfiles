FROM debian:latest

SHELL ["/bin/bash", "-euxo", "pipefail", "-c"]

ARG DEBIAN_FRONTEND=noninteractive

ENV HASHLINK_WIN64=/usr/local/hashlink-win64 \
    USER=heaps

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
    libsndio7.0
    libsqlite3-0
    neko
    rsync
    sudo
    zlib1g
)
windowsDeps=(
    curl
    gcc-mingw-w64-x86-64
    nsis
    unzip
    zip
)
apt-get update
apt-get install --no-install-recommends "${commonDeps[@]}" "${windowsDeps[@]}" -y
rm -rf /var/lib/apt/lists/*
mkdir -p /usr/src/hashlink
cd /usr/src/hashlink
git clone --depth 1 --branch latest https://github.com/HaxeFoundation/hashlink .
HASHLINK_COMMIT="$(git rev-parse --short=7 HEAD)"
rm -rf .git
cd /tmp
curl -fsSLO "https://github.com/HaxeFoundation/hashlink/releases/download/latest/hashlink-${HASHLINK_COMMIT}-win64.zip"
unzip -q "hashlink-${HASHLINK_COMMIT}-win64.zip"
mv "hashlink-${HASHLINK_COMMIT}-win64" "$HASHLINK_WIN64"
rm "hashlink-${HASHLINK_COMMIT}-win64.zip"
EOT

RUN <<EOT
groupadd --gid 1000 "$USER"
useradd --uid 1000 --gid "$USER" --shell /bin/bash --create-home "$USER"
echo "$USER:$USER" | chpasswd
echo "${USER} ALL=(ALL) NOPASSWD:ALL" > "/etc/sudoers.d/90-$USER"
EOT

COPY --chmod="+x" bundle docker-entrypoint.sh makeexe /usr/local/bin/

USER $USER
WORKDIR /home/$USER

ENTRYPOINT ["docker-entrypoint.sh"]
