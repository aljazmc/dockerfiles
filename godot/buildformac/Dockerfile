FROM debian:latest

SHELL ["/bin/bash", "-euxo", "pipefail", "-c"]

ARG DEBIAN_FRONTEND=noninteractive \
    GODOT_VERSION="4.7.2"

ENV USER=godot \
    XDG_DATA_HOME=/usr/local/share

RUN <<'EOT'
commonDeps=(
    ca-certificates
    curl
    libfontconfig1
    sudo
    unzip
)
macDeps=(
    xorriso
)
apt-get update
apt-get install --no-install-recommends "${commonDeps[@]}" "${macDeps[@]}" -y
rm -rf /var/lib/apt/lists/*
GODOT_URL="https://github.com/godotengine/godot/releases/download/${GODOT_VERSION}-stable"
cd /tmp
curl -fsSLO "$GODOT_URL/Godot_v${GODOT_VERSION}-stable_linux.x86_64.zip"
unzip -q "Godot_v${GODOT_VERSION}-stable_linux.x86_64.zip"
mv "Godot_v${GODOT_VERSION}-stable_linux.x86_64" /usr/local/bin/godot
curl -fsSLO "$GODOT_URL/Godot_v${GODOT_VERSION}-stable_export_templates.tpz"
unzip -q "Godot_v${GODOT_VERSION}-stable_export_templates.tpz" \
    'templates/version.txt' \
    'templates/icudt_godot.dat' \
    'templates/macos.zip'
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

COPY --chmod="+x" docker-entrypoint.sh makedmg /usr/local/bin/

USER $USER
WORKDIR /home/$USER

ENTRYPOINT ["docker-entrypoint.sh"]
