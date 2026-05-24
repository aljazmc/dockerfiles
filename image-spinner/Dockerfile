FROM alpine:latest

ENV PROFILENAME=test \
    PWD=/home/aljazmc \
    USER=aljazmc

SHELL ["/bin/sh", "-euxo", "pipefail", "-c"]

RUN <<EOT
runtimeDeps="
    abuild
    alpine-conf
    doas
    syslinux
    xorriso
    squashfs-tools
    grub
    mtools
    git
    ca-certificates
"
apk add --no-cache ${runtimeDeps}
addgroup -g 1000 $USER
adduser -u 1000 -G $USER -s /bin/sh -D $USER
addgroup $USER abuild
echo "permit nopass :$USER as root" > /etc/doas.d/doas.conf
EOT

USER $USER
WORKDIR /home/$USER

CMD ["sh","-c", "printenv"]
