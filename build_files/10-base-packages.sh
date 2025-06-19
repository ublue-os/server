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
    NetworkManager-wifi \
    cockpit-networkmanager \
    cockpit-podman \
    cockpit-selinux \
    cockpit-storaged \
    cockpit-system \
    distrobox \
    duperemove \
    firewalld \
    hdparm \
    iwlegacy-firmware \
    iwlwifi-dvm-firmware \
    iwlwifi-mvm-firmware \
    man-db \
    man-pages \
    open-vm-tools \
    pcp-zeroconf \
    qemu-guest-agent \
    samba \
    samba-usershares \
    tailscale \
    tmux \
    usbutils \
    wireguard-tools \
    xdg-dbus-proxy \
    xdg-user-dirs

dnf config-manager --set-disabled tailscale-stable

dnf -y copr enable ublue-os/staging
dnf -y install snapraid
# dnf -y install sanoid
dnf -y copr disable ublue-os/staging
