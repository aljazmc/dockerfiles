#!/bin/sh
set -e

PROFILENAME="test"

abuild-keygen -a -n

test -d aports || git clone --depth=1 https://gitlab.alpinelinux.org/alpine/aports.git

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
                apache2
	        mariadb mariadb-client
	        php php85-curl php85-dom php85-exif php85-fileinfo php85-fpm php85-mysqlnd php85-mysqli php85-apache2 php85-openssl php85-xml php85-zip
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

echo ""
echo "Configure aports/scripts/mkimg.$PROFILENAME.sh and run:"
echo ""
echo "docker run -it --rm --user aljazmc -v ./home:/home/aljazmc -w /home/aljazmc aljazmc/image-spinner:latest \"sh aports/scripts/mkimage.sh --tag edge --outdir iso --arch x86_64 --repository https://dl-cdn.alpinelinux.org/alpine/edge/main --profile $PROFILENAME\""
echo ""
echo "to build your very own Alpine ISO"
