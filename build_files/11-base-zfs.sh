#!/usr/bin/env bash
set -xeuo pipefail

### install base server ZFS packages
#dnf -y install https://zfsonlinux.org/epel/zfs-release-2-3$(rpm --eval "%{dist}").noarch.rpm
#dnf config-manager --disable zfs
#dnf config-manager --enable zfs-kmod
#dnf -y install zfs pv
#dnf config-manager --disable zfs-kmod
echo "TODO: add ublue-os/akmods ZFS install here"
