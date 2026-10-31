FROM debian:latest

SHELL ["/bin/bash", "-euxo", "pipefail", "-c"]

ARG DEBIAN_FRONTEND=noninteractive \
    USER=blender \
    BLENDER_VERSION=5.2

ENV LANG=C \
    LC_ALL=C \
    PATH="$PATH:/home/$USER"

RUN <<'EOF'
buildDeps=(
    ca-certificates
    curl
    xz-utils
)
runtimeDeps=(
    ffmpeg
    gtk2-engines-murrine
    gtk2-engines-pixbuf
    libpulse0
    pipewire-alsa
    sudo
    xterm
)
libraries=(
    libdecor-0-0
    libegl1
    libgl1
    libgl1-mesa-dri
    libglx-mesa0
    libice6
    libsm6
    libvulkan1
    libwayland-client0
    libwayland-cursor0
    libwayland-egl1
    libx11-6
    libxcursor1
    libxext6
    libxfixes3
    libxi6
    libxinerama1
    libxkbcommon-x11-0
    libxkbcommon0
    libxrandr2
    libxrender1
    libxss1
    libxxf86vm1
    mesa-vulkan-drivers
)
apt-get update
apt-get install --no-install-recommends "${buildDeps[@]}" "${runtimeDeps[@]}" "${libraries[@]}" -y

BLENDER_URL="https://download.blender.org/release/Blender${BLENDER_VERSION}"
BLENDER_LATEST=$(curl -fsSL "${BLENDER_URL}/" \
    | grep -oE "blender-${BLENDER_VERSION//./\\.}\.[0-9]+-linux-x64\.tar\.xz" \
    | sed -E 's/^blender-(.*)-linux-x64\.tar\.xz$/\1/' \
    | sort -uV | tail -n 1)
BLENDER_ARCHIVE="blender-${BLENDER_LATEST}-linux-x64.tar.xz"
curl -fsSLo "/tmp/${BLENDER_ARCHIVE}" "${BLENDER_URL}/${BLENDER_ARCHIVE}"
curl -fsSL "${BLENDER_URL}/blender-${BLENDER_LATEST}.sha256" \
    | grep " ${BLENDER_ARCHIVE}\$" \
    | sed "s|  |  /tmp/|" \
    | sha256sum -c -
mkdir -p /opt/blender
tar -xJf "/tmp/${BLENDER_ARCHIVE}" -C /opt/blender --strip-components=1
rm "/tmp/${BLENDER_ARCHIVE}"
ln -s /opt/blender/blender /usr/local/bin/blender

apt-get purge "${buildDeps[@]}" -y
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
