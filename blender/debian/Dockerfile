FROM debian:13.7

SHELL ["/bin/bash", "-euxo", "pipefail", "-c"]

ARG BLENDER_VERSION=5.2 \
    DEBIAN_FRONTEND=noninteractive \
    DRACO_VERSION=2.2.0 \
    RUFF_VERSION=0.17.6 \
    USER=blender

ENV LANG=C \
    LC_ALL=C \
    PATH="$PATH:/home/$USER:/home/$USER/.local/bin"

RUN cat <<"EOF" | tee /etc/apt/sources.list.d/forky.sources
Types: deb
URIs: http://deb.debian.org/debian
Suites: forky
Components: main contrib non-free non-free-firmware
Signed-By: /usr/share/keyrings/debian-archive-keyring.gpg
EOF

# RUN cat <<"EOF" | tee /etc/apt/preferences.d/99-pinning
# Package: *
# Pin: release n=trixie
# Pin-Priority: 900
# 
# Package: *
# Pin: release n=forky
# Pin-Priority: 100
# EOF

RUN <<'EOF'
runDeps=(
    ca-certificates
    sudo
    xterm
    python3-all
    python3-cattr
    python3-numpy
    python3-pip
    python3-pytest
    python3-requests
)
blenderDeps=(
    ffmpeg
    shellcheck
)
apt-get update
apt-get full-upgrade -y
apt-get install -y --no-install-recommends "${runDeps[@]}" "${blenderDeps[@]}"
apt-get install -y -t forky "blender=$BLENDER_VERSION*"
python3 -m pip install --no-cache-dir --root-user-action=ignore --break-system-packages --disable-pip-version-check "ruff==$RUFF_VERSION"
python3 -m pip install --no-cache-dir --root-user-action=ignore --break-system-packages --disable-pip-version-check --target=/usr/share/blender/scripts/modules "DracoPy==$DRACO_VERSION"

apt-get autoremove -y
apt-get dist-clean

groupadd --gid 1000 "$USER"
useradd --uid 1000 --gid "$USER" --shell /bin/bash --create-home "$USER"
echo "$USER:$USER" | chpasswd
echo "${USER} ALL=(ALL) NOPASSWD:ALL" > "/etc/sudoers.d/90-$USER"
EOF

USER $USER
WORKDIR /home/$USER

COPY --chmod="+x" docker-entrypoint.sh /usr/local/bin/
ENTRYPOINT ["docker-entrypoint.sh"]

CMD [ "bash" ]
