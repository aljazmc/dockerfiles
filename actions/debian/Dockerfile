FROM debian:13.7

SHELL ["/bin/bash", "-euxo", "pipefail", "-c"]

ARG COREPACK_VERSION="0.36.0" \
    DEBIAN_FRONTEND=noninteractive \
    NODE_VERSION="26.13.1" \
    RUFF_VERSION="0.17.6" \
    USER=actions

ENV ACTIONS_ENABLE_DOWNLOAD_PROMPT=0 \
    PATH="$PATH:/home/$USER:/home/$USER/.yarn/releases"

RUN <<'EOF'
runtimeDeps=(
    ca-certificates
    curl
    dirmngr
    git
    gpg
    gpg-agent
    libatomic1
    shellcheck
    sudo
    tar
    xz-utils
)
pythonDeps=(
    python3
    python3-mido
    python3-numpy
    python3-pip
    python3-pytest
    python3-rtmidi
    python3-venv
)
dockerDeps=(
    docker-ce
    docker-ce-cli
    containerd.io
    docker-buildx-plugin
    docker-compose-plugin
)
apt-get update
apt-get upgrade -y
apt-get install --no-install-recommends "${runtimeDeps[@]}" "${pythonDeps[@]}" -y
pip3 install --no-cache-dir --break-system-packages --root-user-action=ignore "ruff==$RUFF_VERSION"
apt-get dist-clean

install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/debian/gpg -o /etc/apt/keyrings/docker.asc
chmod a+r /etc/apt/keyrings/docker.asc

echo "Types: deb" > /etc/apt/sources.list.d/docker.sources
echo "URIs: https://download.docker.com/linux/debian" >> /etc/apt/sources.list.d/docker.sources
echo "Suites: trixie" >> /etc/apt/sources.list.d/docker.sources
echo "Components: stable" >> /etc/apt/sources.list.d/docker.sources
echo "Architectures: amd64" >> /etc/apt/sources.list.d/docker.sources
echo "Signed-By: /etc/apt/keyrings/docker.asc" >> /etc/apt/sources.list.d/docker.sources

apt-get update
apt-get upgrade -y
apt-get install --no-install-recommends  "${dockerDeps[@]}" -y

groupadd --gid 1000 "$USER"
useradd --uid 1000 --gid "$USER" --shell /bin/bash --create-home "$USER"
echo "$USER:$USER" | chpasswd
echo "${USER} ALL=(ALL) NOPASSWD:ALL" > "/etc/sudoers.d/90-$USER"
usermod -aG docker "$USER"

for key in 5BE8A3F6C8A5C01D106C0AD820B1A390B168D356 DD792F5973C6DE52C432CBDAC77ABFA00DDBF2B7 CC68F5A3106FF448322E48ED27F5E38D5B0A215F 8FCCA13FEF1D0C2E91008E09770F7A9A5AE15600 890C08DB8579162FEE0DF9DB8BEAB4DFCF555EF4 C82FA3AE1CBEDC6BE46B9360C43CEC45C17AB93C 108F52B48DB57BB0CC439B2997B01419BD92F80A A363A499291CBBC940DD62E41F10027AF002F8B0;
do
    { gpg --batch --keyserver hkps://keys.openpgp.org --recv-keys "$key" && gpg --batch --fingerprint "$key"; } || \
    { gpg --batch --keyserver keyserver.ubuntu.com --recv-keys "$key" && gpg --batch --fingerprint "$key"; } ;
done

curl -fsSLO --compressed "https://nodejs.org/dist/v${NODE_VERSION}/node-v${NODE_VERSION}-linux-x64.tar.xz"
curl -fsSLO --compressed "https://nodejs.org/dist/v${NODE_VERSION}/SHASUMS256.txt.asc"

gpg --batch --decrypt --output SHASUMS256.txt SHASUMS256.txt.asc
gpgconf --kill all
rm -rf ~/.gnupg
grep " node-v${NODE_VERSION}-linux-x64.tar.xz\$" SHASUMS256.txt | sha256sum -c -
tar -xJf "node-v${NODE_VERSION}-linux-x64.tar.xz" -C /usr/local --strip-components=1 --no-same-owner
ln -s /usr/local/bin/node /usr/local/bin/nodejs

rm "node-v${NODE_VERSION}-linux-x64.tar.xz" SHASUMS256.txt.asc SHASUMS256.txt
rm -rf /tmp/*

docker --version
node --version
npm --version
EOF

USER $USER
WORKDIR /home/$USER

RUN sudo npm install -g "corepack@$COREPACK_VERSION"

COPY docker-entrypoint.sh /usr/local/bin/
ENTRYPOINT ["docker-entrypoint.sh"]

CMD [ "node" ]
