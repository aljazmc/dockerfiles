#!/bin/sh
set -e

PROFILENAME="test"

# where to clone aports from, tried in turn: Alpine's GitLab, which refuses
# some cloud machines, e.g. GitHub's runners, with HTTP 418, then its mirror
# on GitHub; set APORTS_URL to use other ones
APORTS_URL="${APORTS_URL:-https://gitlab.alpinelinux.org/alpine/aports.git https://github.com/alpinelinux/aports.git}"

if ! ls ~/.abuild/*.rsa > /dev/null 2>&1; then
    abuild-keygen -a -n
fi

if [ ! -f aports/README.md ]; then
    TMP_DIR="$(mktemp -d /tmp/temp.XXXXXX)"
    # mktemp makes it 700, and rsync -a gives that to aports/: open it, so a
    # host user other than uid 1000 can read the tree in their own directory
    chmod 755 "$TMP_DIR"
    # fail rather than ask for a password, as there is no terminal to ask on
    export GIT_TERMINAL_PROMPT=0
    for url in $APORTS_URL; do
        git clone --depth=1 "$url" "$TMP_DIR" && break
        echo "Cloning $url failed, trying the next one" >&2
    done
    if [ ! -f "$TMP_DIR/README.md" ]; then
        echo "ERROR: could not clone aports from any of: $APORTS_URL" >&2
        rm -rf "$TMP_DIR"
        exit 1
    fi
    rsync -avuq "$TMP_DIR"/ aports/
    rm -rf "$TMP_DIR"
fi

if [ ! -f aports/scripts/mkimg.$PROFILENAME.sh ]; then
cat <<-EOF > aports/scripts/mkimg.$PROFILENAME.sh
profile_$PROFILENAME() {
        profile_virt
        kernel_cmdline="unionfs_size=512M console=tty0 console=ttyS0,115200"
        syslinux_serial="0 115200"
        kernel_addons="zfs"
        apks="\$apks iscsi-scst zfs-scripts zfs zfs-utils-py
                cciss_vol_status lvm2 mdadm mkinitfs mtools nfs-utils
                parted rsync sfdisk syslinux util-linux xfsprogs
                dosfstools ntfs-3g
        "
        local _k _a
        for _k in \$kernel_flavors; do
                apks="\$apks linux-\$_k"
                for _a in \$kernel_addons; do
                        apks="\$apks \$_a-\$_k"
                done
        done
        apks="\$apks linux-firmware"
}
EOF

chmod +x aports/scripts/mkimg.$PROFILENAME.sh
fi

echo ""
echo "Configure aports/scripts/mkimg.$PROFILENAME.sh and run:"
echo ""
echo "docker run -it --rm --user aljazmc -v .:/home/aljazmc -w /home/aljazmc aljazmc/image-spinner:latest \"sh aports/scripts/mkimage.sh --tag edge --outdir iso --arch x86_64 --repository https://dl-cdn.alpinelinux.org/alpine/edge/main --repository https://dl-cdn.alpinelinux.org/alpine/edge/community --profile $PROFILENAME\""
echo ""
echo "to build your very own Alpine ISO"

exec "$@"
