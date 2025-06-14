#!/usr/bin/env bash
set -xeuo pipefail

### install base server NVIDIA packages
dnf -y install /tmp/akmods-nv-rpms/ublue-os/ublue-os-nvidia-addons-*.rpm

sed -i '0,/enabled=0/{s/enabled=0/enabled=1/}' /etc/yum.repos.d/negativo17-epel-nvidia.repo
sed -i '0,/enabled=0/{s/enabled=0/enabled=1/}' /etc/yum.repos.d/nvidia-container-toolkit.repo

KERNEL_VR="$(rpm -q "kernel" --queryformat '%{VERSION}-%{RELEASE}')"
dnf -y install \
    nvidia-container-toolkit \
    nvidia-driver-cuda \
    /tmp/akmods-nv-rpms/kmods/kmod-nvidia*"${KERNEL_VR}"*.rpm
