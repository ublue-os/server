#!/usr/bin/env bash
set -xeuo pipefail

RELEASE="$(rpm -E %centos)"
### install NAS server packages

### server nas packages which are mostly what we added in ucore
dnf -y install --setopt=install_weak_deps=False \
    NetworkManager-wifi \
    cockpit-storaged \
    distrobox \
    hdparm \
    pcp-zeroconf \
    samba \
    samba-usershares \
    usbutils \
    xdg-dbus-proxy \
    xdg-user-dirs

# TODO: these require EPEL packages to be built for el10
#    duperemove \

dnf -y copr enable ublue-os/staging
dnf -y install snapraid
dnf -y copr disable ublue-os/staging

### install packages direct from github
### NOTE: we need to get proper arch for these packages rather than hard coding
/ctx/github-release-install.sh rclone/rclone "linux-amd64"
/ctx/github-release-install.sh trapexit/mergerfs "el${RELEASE}.x86_64"
