FROM debian:latest

SHELL ["/bin/bash", "-euxo", "pipefail", "-c"]

ARG DEBIAN_FRONTEND=noninteractive

ENV BEVY_VERSION="0.20" \
    RUSTUP_HOME=/usr/local/rustup \
    CARGO_TARGET_X86_64_PC_WINDOWS_GNU_RUSTFLAGS="-C target-feature=+crt-static" \
    USER=bevy

RUN <<'EOT'
commonDeps=(
    ca-certificates
    g++
    git
    rustup
    sudo
)
windowsDeps=(
    gcc-mingw-w64-x86-64
    nsis
    zip
)
apt-get update
apt-get install --no-install-recommends "${commonDeps[@]}" "${windowsDeps[@]}" -y
rm -rf /var/lib/apt/lists/*
rustup set profile minimal
rustup default stable
rustup target add x86_64-pc-windows-gnu
EOT

RUN <<EOT
groupadd --gid 1000 "$USER"
useradd --uid 1000 --gid "$USER" --shell /bin/bash --create-home "$USER"
echo "$USER:$USER" | chpasswd
echo "${USER} ALL=(ALL) NOPASSWD:ALL" > "/etc/sudoers.d/90-$USER"
chown -R "$USER:$USER" "$RUSTUP_HOME"
EOT

COPY --chmod="+x" docker-entrypoint.sh makeexe /usr/local/bin/

USER $USER
WORKDIR /home/$USER

ENTRYPOINT ["docker-entrypoint.sh"]
