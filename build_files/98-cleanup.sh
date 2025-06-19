#!/usr/bin/env bash
set -xeuo pipefail

# /*
# Ensure Initramfs is generated
# */
KERNEL_VERSION="$(rpm -q --queryformat="%{EVR}.%{ARCH}" kernel-core)"

export DRACUT_NO_XATTR=1
/usr/bin/dracut --no-hostonly --kver "$KERNEL_VERSION" --reproducible --zstd -v --add ostree -f "/lib/modules/$KERNEL_VERSION/initramfs.img"

chmod 0600 /lib/modules/"$KERNEL_VERSION"/initramfs.img

# /*
# Ensure only one kernel/initramfs is present
# */
KERNEL_VERSION="$(rpm -q kernel-core --queryformat '%{EVR}.%{ARCH}')"

kernel_dirs=("$(ls -1 /usr/lib/modules)")
if [[ ${#kernel_dirs[@]} -gt 1 ]]; then
    for kernel_dir in "${kernel_dirs[@]}"; do
        echo "$kernel_dir"
        if [[ "$kernel_dir" != "$KERNEL_VERSION" ]]; then
            echo "Removing $kernel_dir"
            rm -rf "/usr/lib/modules/$kernel_dir"
        fi
    done
fi

# /*
# Remove Versionlocks (Needs dnf cache to run)
# */
dnf versionlock clear
