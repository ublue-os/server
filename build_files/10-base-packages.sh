#!/usr/bin/env bash
set -xeuo pipefail

### install base server packages

### add ublue-os specific packages
dnf -y copr enable ublue-os/packages
dnf -y install ublue-os-signing
mv /etc/containers/policy.json /etc/containers/policy.json-upstream
mv /usr/etc/containers/policy.json /etc/containers/
rm -fr /usr/etc
dnf -y copr disable ublue-os/packages

### server base packages which are mostly what we added in ucore-minimal
dnf config-manager --add-repo https://pkgs.tailscale.com/stable/centos/9/tailscale.repo

dnf -y install --setopt=install_weak_deps=False \
  cockpit-networkmanager \
  cockpit-podman \
  cockpit-selinux \
  cockpit-system \
  firewalld \
  man-db \
  man-pages \
  open-vm-tools \
  qemu-guest-agent \
  tailscale \
  tmux \
  wireguard-tools
