FROM debian:13.7

SHELL ["/bin/bash", "-euxo", "pipefail", "-c"]

ARG TARGETARCH \
    DEBIAN_FRONTEND=noninteractive \
    GODOT_VERSION="4.7.2"

ENV USER=godot \
    XDG_DATA_HOME=/usr/local/share

RUN <<'EOT'
commonDeps=(
    ca-certificates
    curl
    libfontconfig1
    shellcheck
    sudo
    unzip
)
windowsDeps=(
    zip
)
apt-get update
apt-get upgrade -y
apt-get install -y --no-install-recommends "${commonDeps[@]}" "${windowsDeps[@]}"
rm -rf /var/lib/apt/lists/*

ARCH=""
case "${TARGETARCH}" in
    amd64) ARCH='x86_64' ;;
    arm64) ARCH='arm64' ;;
    *) echo "Unsupported architecture: ${TARGETARCH}"; exit 1 ;;
esac

GODOT_URL="https://github.com/godotengine/godot/releases/download/${GODOT_VERSION}-stable"
cd /tmp
curl -fsSLO "$GODOT_URL/Godot_v${GODOT_VERSION}-stable_linux.${ARCH}.zip"
unzip -q "Godot_v${GODOT_VERSION}-stable_linux.${ARCH}.zip"
mv "Godot_v${GODOT_VERSION}-stable_linux.${ARCH}" /usr/local/bin/godot
curl -fsSLO "$GODOT_URL/Godot_v${GODOT_VERSION}-stable_export_templates.tpz"
unzip -q "Godot_v${GODOT_VERSION}-stable_export_templates.tpz" \
    'templates/version.txt' \
    'templates/icudt_godot.dat' \
    'templates/windows_*_arm64*.exe' \
    'templates/windows_*_x86_64*.exe'
TEMPLATES_DIR="$XDG_DATA_HOME/godot/export_templates/$(cat templates/version.txt)"
mkdir -p "$TEMPLATES_DIR"
mv templates/* "$TEMPLATES_DIR"/
rm -rf templates ./*.zip ./*.tpz
EOT

RUN <<EOT
groupadd --gid 1000 "$USER"
useradd --uid 1000 --gid "$USER" --shell /bin/bash --create-home "$USER"
echo "$USER:$USER" | chpasswd
echo "${USER} ALL=(ALL) NOPASSWD:ALL" > "/etc/sudoers.d/90-$USER"
chown -R "$USER:$USER" "$XDG_DATA_HOME/godot"
EOT

COPY --chmod="+x" docker-entrypoint.sh /usr/local/bin/

USER $USER
WORKDIR /home/$USER

ENTRYPOINT ["docker-entrypoint.sh"]
