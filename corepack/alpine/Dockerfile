FROM alpine:latest

ARG NODE_VERSION="26.2.0" \
    USER=node

ENV COREPACK_ENABLE_DOWNLOAD_PROMPT=0 \
    PATH="$PATH:/home/$USER:/home/$USER/.yarn/releases"

RUN apk add --no-cache doas git libstdc++ \
    && apk add --no-cache --virtual .build-deps curl \
    && addgroup -g 1000 $USER \
    && adduser -u 1000 -G $USER -s /bin/sh -D $USER \
    && echo "permit nopass :$USER as root" > /etc/doas.d/doas.conf \
    && if [ -n "3224ba9c6ae722120971e9424a6c2e0552c8b6ce89cf9dcc36e17485d661aff7" ]; then \
        set -eu; \
        curl -fsSLO --compressed "https://unofficial-builds.nodejs.org/download/release/v${NODE_VERSION}/node-v${NODE_VERSION}-linux-x64-musl.tar.xz"; \
        echo "3224ba9c6ae722120971e9424a6c2e0552c8b6ce89cf9dcc36e17485d661aff7 node-v${NODE_VERSION}-linux-x64-musl.tar.xz" | sha256sum -c - \
        && tar -xJf "node-v${NODE_VERSION}-linux-x64-musl.tar.xz" -C /usr/local --strip-components=1 --no-same-owner \
        && ln -s /usr/local/bin/node /usr/local/bin/nodejs; \ 
    fi \
    && rm -f "node-v${NODE_VERSION}-linux-x64-musl.tar.xz" \
    && find /usr/local/include/node/openssl/archs -mindepth 1 -maxdepth 1 | sed "/linux-x86_64/d" | xargs -I {} rm -rf {} \
    && apk del .build-deps \
    && node --version \
    && npm --version \
    && rm -rf /tmp/*

USER $USER
WORKDIR /home/$USER

RUN doas npm install -g corepack

COPY docker-entrypoint.sh /usr/local/bin/
ENTRYPOINT ["docker-entrypoint.sh"]

CMD [ "node" ]
