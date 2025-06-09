#!/usr/bin/env bash
set -xeuo pipefail

# install base server NVIDIA packages 
echo "TODO: add ublue-os/akmods NVIDIA install here"
# repo for nvidia rpms
#curl -L https://negativo17.org/repos/fedora-nvidia.repo -o /etc/yum.repos.d/fedora-nvidia.repo
#
#rpm-ostree install /tmp/rpms/akmods-nvidia/ucore/ublue-os-ucore-nvidia*.rpm
#sed -i '0,/enabled=0/{s/enabled=0/enabled=1/}' /etc/yum.repos.d/nvidia-container-toolkit.repo
#
#rpm-ostree install \
#    /tmp/rpms/akmods-nvidia/kmods/kmod-nvidia*.rpm \
#    nvidia-driver-cuda \
#    nvidia-container-toolkit
