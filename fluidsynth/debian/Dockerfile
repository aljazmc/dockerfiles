FROM debian:13.7

SHELL ["/bin/bash", "-euxo", "pipefail", "-c"]

ARG DEBIAN_FRONTEND=noninteractive \
    FLUIDSYNTH_VERSION=2.4.4 \
    RUFF_VERSION=0.17.6 \
    USER=fluidsynth

ENV LANG=C \
    LC_ALL=C \
    PATH="$PATH:/home/$USER"

RUN <<'EOF'
runtimeDeps=(
    ffmpeg
    fluid-soundfont-gm
    "fluidsynth=$FLUIDSYNTH_VERSION*"
    libpulse0
    pipewire-alsa
    shellcheck
    sudo
)
python=(
    python3
    python3-mido
    python3-numpy
    python3-pip
    python3-pytest
    python3-rtmidi
    python3-venv
)
apt-get update
apt-get upgrade -y
apt-get install -y --no-install-recommends "${runtimeDeps[@]}" "${python[@]}"
pip3 install --no-cache-dir --break-system-packages --root-user-action=ignore "ruff==$RUFF_VERSION"
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
