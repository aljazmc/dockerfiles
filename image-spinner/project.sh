#!/bin/bash

IMAGE_SPINNER_VERSION="0.0.0"
PROFILENAME="test"

build() {

mkdir -p home
docker build . -t aljazmc/image-spinner-alpine
docker tag aljazmc/image-spinner-alpine aljazmc/image-spinner-alpine:"${IMAGE_SPINNER_VERSION}"
docker tag aljazmc/image-spinner-alpine aljazmc/image-spinner-alpine:latest

docker image ls
docker run --user aljazmc:aljazmc -v ./home:/home/aljazmc aljazmc/image-spinner-alpine sh -c "abuild-keygen -a -n"
docker run --user aljazmc:aljazmc -v ./home:/home/aljazmc aljazmc/image-spinner-alpine sh -c "git clone --depth=1 https://gitlab.alpinelinux.org/alpine/aports.git"

cat <<-EOF > home/aports/scripts/mkimg.$PROFILENAME.sh
profile_$PROFILENAME() {
        profile_standard
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

docker run --user aljazmc:aljazmc -v ./home:/home/aljazmc aljazmc/image-spinner-alpine sh -c "chmod +x aports/scripts/mkimg.$PROFILENAME.sh && aports/scripts/mkimg.$PROFILENAME.sh --tag edge --outdir iso --arch x86_64 --repository https://dl-cdn.alpinelinux.org/alpine/edge/main --profile $PROFILENAME"

}

clean() {

docker system prune -af --volumes

find . -mindepth 1 -maxdepth 1 \
| sed "/Dockerfile/d;/README.md/d;/project.sh/d" \
| xargs -I {} rm -rf {}

}

combo() {

./project.sh clean \
&& ./project.sh build

}

publish() {

docker push -a aljazmc/image-spinner-alpine

}

"$@"
