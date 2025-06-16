#!/usr/bin/env bash
set -xeuo pipefail

# Ensure Initramfs is generated
KERNEL_VERSION="$(rpm -q --queryformat="%{EVR}.%{ARCH}" kernel-core)"

export DRACUT_NO_XATTR=1
/usr/bin/dracut --no-hostonly --kver "$KERNEL_VERSION" --reproducible --zstd -v --add ostree -f "/lib/modules/$KERNEL_VERSION/initramfs.img"

chmod 0600 /lib/modules/"$KERNEL_VERSION"/initramfs.img

# Ensure only one kernel/initramfs is present
KERNEL_VERSION="$(rpm -q kernel-core --queryformat '%{EVR}.%{ARCH}')"

for kernel_dir in /usr/lib/modules/*; do
    echo "$kernel_dir"
    if [[ "$kernel_dir" != "/usr/lib/modules/$KERNEL_VERSION" ]]; then
        echo "Removing $kernel_dir"
        rm -rf "$kernel_dir"
    fi
done

# Remove Versionlocks
dnf versionlock clear
