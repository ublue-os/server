#!/usr/bin/env bash
set -xeuo pipefail

### install base server ZFS packages and sanoid dependencies
dnf -y install \
    pv \
    /tmp/akmods-zfs-rpms/kmods/zfs/*.rpm \
    /tmp/akmods-zfs-rpms/kmods/zfs/other/zfs-dracut-*.rpm

# depmod ran automatically with zfs 2.1 but not with 2.2
KERNEL_VRA="$(rpm -q "kernel" --queryformat '%{VERSION}-%{RELEASE}.%{ARCH}')"
depmod -a -v "${KERNEL_VRA}"
