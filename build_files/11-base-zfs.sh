#!/usr/bin/env bash
set -xeuo pipefail

### install base server ZFS packages and sanoid dependencies
dnf -y install \
    pv \
    /tmp/akmods-zfs-rpms/kmods/zfs/*.rpm \
    /tmp/akmods-zfs-rpms/kmods/zfs/other/zfs-dracut-*.rpm
# NOTE: maybe we need to be careful about installing only the kmod-zfs which matches KERNEL_VR
# eg, KERNEL_VR="$(rpm -q "kernel" --queryformat '%{VERSION}-%{RELEASE}')"
#  dnf install -y  /tmp/akmods-zfs-rpms/kmods/zfs-kmod-*"${KERNEL_VR}"*.rpm

# depmod ran automatically with zfs 2.1 but not with 2.2
KERNEL_VRA="$(rpm -q "kernel" --queryformat '%{VERSION}-%{RELEASE}.%{ARCH}')"
depmod -a -v "${KERNEL_VRA}"
