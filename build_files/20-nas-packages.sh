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
#    rclone \
#    snapraid \

### install packages direct from github
# TODO: needs a request to trapexit for el10 build
#/ctx/github-release-install.sh trapexit/mergerfs "el${RELEASE}.x86_64"
