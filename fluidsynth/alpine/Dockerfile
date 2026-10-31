FROM alpine:latest

SHELL ["/bin/sh", "-euxo", "pipefail", "-c"]

ARG USER=fluidsynth

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
    fluidsynth
    libpulse
    pipewire-alsa
    soundfont-timgm
"
python="
    py3-numpy
    py3-pip
    python3
"
apk add --no-cache $runtimeDeps $python

addgroup -g 1000 "$USER"
adduser -u 1000 -G "$USER" -s /bin/sh -D "$USER"
echo "permit nopass :$USER as root" > /etc/doas.d/doas.conf
EOF

USER $USER
WORKDIR /home/$USER

COPY --chmod="+x" docker-entrypoint.sh /usr/local/bin/
ENTRYPOINT ["docker-entrypoint.sh"]

CMD [ "sh" ]
