FROM alpine:3.24.4

SHELL ["/bin/sh", "-euxo", "pipefail", "-c"]

ARG TARGETARCH \
    COREPACK_VERSION="0.36.0" \
    NODE_VERSION="26.13.1" \
    RUFF_VERSION="0.17.6" \
    USER=actions

ENV COREPACK_ENABLE_DOWNLOAD_PROMPT=0 \
    PATH="$PATH:/home/$USER:/home/$USER/.yarn/releases"

RUN <<EOF
runtimeDeps="
    bash
    ca-certificates
    curl
    doas
    ffmpeg
    findutils
    git
    libstdc++
    shellcheck
"
pythonDeps="
    py3-cattrs
    py3-numpy
    py3-pip
    py3-pytest
    py3-requests
"
dockerDeps="
    docker
    docker-cli-compose
"
apk upgrade --no-cache
apk add --no-cache $runtimeDeps $pythonDeps $dockerDeps
pip3 install --no-cache-dir --break-system-packages "ruff==$RUFF_VERSION"

addgroup -g 1000 "$USER"
adduser -u 1000 -G "$USER" -s /bin/sh -D "$USER"
echo "permit nopass :$USER as root" > /etc/doas.d/doas.conf
addgroup "$USER" docker

ARCH=""
case "${TARGETARCH}" in
    amd64) ARCH='x64' ;;
    arm64) ARCH='arm64' ;;
    *) echo "Unsupported architecture: ${TARGETARCH}"; exit 1 ;;
esac

NODE_TARBALL="node-v${NODE_VERSION}-linux-${ARCH}-musl.tar.xz"

curl -fsSLO --compressed "https://unofficial-builds.nodejs.org/download/release/v${NODE_VERSION}/${NODE_TARBALL}"
curl -fsSLO --compressed "https://unofficial-builds.nodejs.org/download/release/v${NODE_VERSION}/SHASUMS256.txt"

grep "${NODE_TARBALL}\$" SHASUMS256.txt | sha256sum -c -
tar -xJf "${NODE_TARBALL}" -C /usr/local --strip-components=1 --no-same-owner
ln -s /usr/local/bin/node /usr/local/bin/nodejs

rm "${NODE_TARBALL}" SHASUMS256.txt

if [ "$ARCH" = "x64" ]; then
find /usr/local/include/node/openssl/archs -mindepth 1 -maxdepth 1 | sed "/linux-x86_64/d" | xargs -I {} rm -rf {}
else
find /usr/local/include/node/openssl/archs -mindepth 1 -maxdepth 1 | sed "/linux-arm64/d" | xargs -I {} rm -rf {}
fi

rm -rf /tmp/*

docker --version
node --version
npm --version
EOF

RUN npm install -g "corepack@$COREPACK_VERSION"

USER $USER
WORKDIR /home/$USER

COPY docker-entrypoint.sh /usr/local/bin/
ENTRYPOINT ["docker-entrypoint.sh"]

CMD [ "bash" ]
