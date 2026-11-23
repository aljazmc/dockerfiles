FROM alpine:3.24.4

SHELL ["/bin/sh", "-euxo", "pipefail", "-c"]

ARG FLUIDSYNTH_VERSION=2.5.4 \
    RUFF_VERSION=0.17.6 \
    USER=fluidsynth

ENV LANG=C \
    LC_ALL=C \
    PATH="$PATH:/home/$USER" \
    SOUNDFONT=/usr/share/soundfonts/default.sf2

RUN <<'EOF'
runtimeDeps="
    bash
    doas
    ffmpeg
    findutils
    fluidsynth~$FLUIDSYNTH_VERSION
    libpulse
    pipewire-alsa
    shellcheck
    soundfont-timgm
"
python="
    py3-numpy
    py3-pip
    py3-pytest
    python3
"
apk upgrade --no-cache
apk add --no-cache $runtimeDeps $python
pip3 install --no-cache-dir --break-system-packages "ruff==$RUFF_VERSION"

addgroup -g 1000 "$USER"
adduser -u 1000 -G "$USER" -s /bin/sh -D "$USER"
echo "permit nopass :$USER as root" > /etc/doas.d/doas.conf
EOF

USER $USER
WORKDIR /home/$USER

COPY --chmod="+x" docker-entrypoint.sh /usr/local/bin/
ENTRYPOINT ["docker-entrypoint.sh"]

CMD [ "sh" ]
