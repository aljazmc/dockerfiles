FROM alpine:latest

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
    squashfs-tools
    syslinux
    xorriso
"
apk add --no-cache ${runtimeDeps}
addgroup -g 1000 $USER
adduser -u 1000 -G $USER -s /bin/sh -D $USER
addgroup $USER abuild
echo "permit nopass :$USER as root" > /etc/doas.d/doas.conf
EOT

COPY --chmod="+x" docker-entrypoint.sh /usr/local/bin/

USER $USER
WORKDIR /home/$USER

ENTRYPOINT ["sh","-c"]

CMD ["docker-entrypoint.sh"]
