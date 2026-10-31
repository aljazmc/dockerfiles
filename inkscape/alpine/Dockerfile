FROM alpine:latest

SHELL ["/bin/sh", "-euxo", "pipefail", "-c"]

ARG USER=inkscape

ENV LANG=C \
    LC_ALL=C \
    PATH="$PATH:/home/$USER"

RUN <<'EOF'
runtimeDeps="
    aspell
    aspell-en
    bash
    doas
    fig2dev
    findutils
    font-dejavu
    ghostscript
    imagemagick
    inkscape
    libwmf
    rsvg-convert
    ruby
    xterm
"
python="
    gtksourceview4
    py3-beautifulsoup4
    py3-cairo
    py3-cssselect
    py3-gobject3
    py3-html5lib
    py3-lxml
    py3-numpy
    py3-packaging
    py3-parsing
    py3-pillow
    py3-pip
    py3-platformdirs
    py3-pyserial
    py3-requests
    py3-tinycss2
    python3
"
libraries="
    libxcursor
    libxi
    libxinerama
    libxkbcommon
    libxkbcommon-x11
    libxrandr
    libxscrnsaver
    mesa-dri-gallium
    mesa-egl
    mesa-gl
    wayland-libs-client
    wayland-libs-cursor
    wayland-libs-egl
"
apk add --no-cache $runtimeDeps $python $libraries

# scour is only packaged in Alpine's testing repository
pip3 install --no-cache-dir --break-system-packages scour

addgroup -g 1000 "$USER"
adduser -u 1000 -G "$USER" -s /bin/sh -D "$USER"
echo "permit nopass :$USER as root" > /etc/doas.d/doas.conf
EOF

USER $USER
WORKDIR /home/$USER

COPY --chmod="+x" docker-entrypoint.sh /usr/local/bin/
ENTRYPOINT ["docker-entrypoint.sh"]

CMD [ "sh" ]
