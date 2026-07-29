FROM debian:latest

SHELL ["/bin/bash", "-euxo", "pipefail", "-c"]

ARG DEBIAN_FRONTEND=noninteractive \
    USER=aljazmc

ENV PATH="/home/$USER/.local/bin:$PATH"

RUN <<'EOF'
runtimeDeps=(
    ca-certificates
    curl
    gpg
    groff
    sudo
    unzip
)
apt-get update
apt-get install --no-install-recommends ${runtimeDeps[@]} -y
apt-get dist-clean

groupadd --gid 1000 $USER
useradd --uid 1000 --gid $USER --shell /bin/bash --create-home $USER
echo "$USER:$USER" | chpasswd
echo "${USER} ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/90-$USER

rm -rf /tmp/*
EOF

USER $USER
WORKDIR /home/$USER

COPY docker-entrypoint.sh /usr/local/bin/
ENTRYPOINT ["docker-entrypoint.sh"]

CMD [ "bash" ]
