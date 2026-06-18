FROM alpine:latest

SHELL ["/bin/sh", "-euxo", "pipefail", "-c"]

ARG NODE_VERSION="26.3.1" \
    USER=node

ENV COREPACK_ENABLE_DOWNLOAD_PROMPT=0 \
    PATH="$PATH:/home/$USER:/home/$USER/.yarn/releases"

RUN <<EOF
apk add --no-cache ca-certificates doas git libstdc++
apk add --no-cache --virtual .build-deps curl

addgroup -g 1000 $USER
adduser -u 1000 -G $USER -s /bin/sh -D $USER
echo "permit nopass :$USER as root" > /etc/doas.d/doas.conf

if [ -n "3e113c229caf9ae5e1fa681e4e8dd0979d8c36eed743d6c5b607cc8a66a7f3ed" ]; then
    curl -fsSLO --compressed "https://unofficial-builds.nodejs.org/download/release/v${NODE_VERSION}/node-v${NODE_VERSION}-linux-x64-musl.tar.xz"
    echo "3e113c229caf9ae5e1fa681e4e8dd0979d8c36eed743d6c5b607cc8a66a7f3ed node-v${NODE_VERSION}-linux-x64-musl.tar.xz" | sha256sum -c -
    tar -xJf "node-v${NODE_VERSION}-linux-x64-musl.tar.xz" -C /usr/local --strip-components=1 --no-same-owner
    ln -s /usr/local/bin/node /usr/local/bin/nodejs
    rm -f "node-v${NODE_VERSION}-linux-x64-musl.tar.xz"
    find /usr/local/include/node/openssl/archs -mindepth 1 -maxdepth 1 | sed "/linux-x86_64/d" | xargs -I {} rm -rf {}
fi

apk del .build-deps
rm -rf /tmp/*

node --version
npm --version
EOF

USER $USER
WORKDIR /home/$USER

RUN doas npm install -g corepack

COPY docker-entrypoint.sh /usr/local/bin/
ENTRYPOINT ["docker-entrypoint.sh"]

CMD [ "node" ]
