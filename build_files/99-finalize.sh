#!/usr/bin/bash
#shellcheck disable=SC2115

set -eoux pipefail

# Cleanup extra directories in /usr/lib/modules
KERNEL_VERSION="$(rpm -q kernel-core --queryformat '%{EVR}.%{ARCH}')"

for kernel_dir in /usr/lib/modules/*; do
    echo "$kernel_dir"
    if [[ "$kernel_dir" != "/usr/lib/modules/$KERNEL_VERSION" ]]; then
        echo "Removing $kernel_dir"
        rm -rf "$kernel_dir"
    fi
done

# Make Sure /tmp and /var are in proper state
rm -rf /tmp/*
rm -rf /var/*
mkdir -p /var/tmp
chmod -R 1777 /var/tmp

ostree container commit
