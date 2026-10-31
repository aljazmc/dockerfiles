FROM debian:latest

SHELL ["/bin/bash", "-euxo", "pipefail", "-c"]

ARG DEBIAN_FRONTEND=noninteractive \
    USER=inkscape

ENV LANG=C \
    LC_ALL=C \
    PATH="$PATH:/home/$USER"

RUN <<'EOF'
runtimeDeps=(
    aspell
    aspell-en
    fig2dev
    fonts-dejavu
    ghostscript
    imagemagick
    inkscape
    libimage-magick-perl
    librsvg2-bin
    libwmf-bin
    ruby
    sudo
    xterm
)
python=(
    gir1.2-gtk-3.0
    gir1.2-gtksource-4
    python3
    python3-bs4
    python3-cairo
    python3-cssselect
    python3-gi
    python3-gi-cairo
    python3-html5lib
    python3-lxml
    python3-numpy
    python3-packaging
    python3-pil
    python3-platformdirs
    python3-pyparsing
    python3-requests
    python3-scour
    python3-serial
    python3-tinycss2
    python3-webencodings
)
libraries=(
    libegl1
    libgl1
    libgl1-mesa-dri
    libglx-mesa0
    libwayland-client0
    libwayland-cursor0
    libwayland-egl1
    libxcursor1
    libxi6
    libxinerama1
    libxkbcommon-x11-0
    libxkbcommon0
    libxrandr2
    libxss1
)
apt-get update
apt-get install --no-install-recommends "${runtimeDeps[@]}" "${python[@]}" "${libraries[@]}" -y
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
