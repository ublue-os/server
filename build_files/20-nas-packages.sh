#!/usr/bin/env bash
set -xeuo pipefail

RELEASE="$(rpm -E %centos)"
### install NAS server packages

### server nas packages which are mostly what we added in ucore
dnf -y install --setopt=install_weak_deps=False \
    NetworkManager-wifi \
    cockpit-storaged \
    distrobox \
    duperemove \
    hdparm \
    pcp-zeroconf \
    samba \
    samba-usershares \
    usbutils \
    xdg-dbus-proxy \
    xdg-user-dirs

dnf -y copr enable ublue-os/staging
dnf -y install snapraid
dnf -y copr disable ublue-os/staging

### install packages direct from github
### NOTE: ARM support will require use of proper arch rather than hard coding
/ctx/github-release-install.sh rclone/rclone "linux-amd64"
/ctx/github-release-install.sh trapexit/mergerfs "el${RELEASE}.x86_64"
