FROM alpine:3.24.4

ARG TARGETARCH

ENV USER=aljazmc

SHELL ["/bin/sh", "-euxo", "pipefail", "-c"]

RUN <<EOT
runtimeDeps="
    abuild
    alpine-conf
    ca-certificates
    doas
    git
    grub
    mtools
    rsync
    shellcheck
    squashfs-tools
    xorriso
"
apk upgrade --no-cache
apk add --no-cache ${runtimeDeps}
# syslinux, with isohybrid, boots PCs from the ISO; Alpine has it only for x86
if [ "$TARGETARCH" = amd64 ]; then
    apk add --no-cache syslinux
fi
addgroup -g 1000 "$USER"
adduser -u 1000 -G "$USER" -s /bin/sh -D "$USER"
addgroup "$USER" abuild
echo "permit nopass :$USER as root" > /etc/doas.d/doas.conf
EOT

COPY --chmod="+x" docker-entrypoint.sh /usr/local/bin/

USER $USER
WORKDIR /home/$USER

ENTRYPOINT ["sh","-c"]

CMD ["docker-entrypoint.sh"]
