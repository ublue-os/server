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
    iwlegacy-firmware \
    iwlwifi-dvm-firmware \
    iwlwifi-mvm-firmware \
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

# set pretty name for NAS image
SOURCE_VERSION="$(grep ^VERSION_ID= /usr/lib/os-release|cut -f2 -d=|tr -d \")"
SOURCE_NAME="$(grep ^NAME= /usr/lib/os-release|cut -f2 -d=|tr -d \")"
sed -i "s|^PRETTY_NAME=.*|PRETTY_NAME=\"Cayo NAS (Version $IMAGE_VERSION / FROM $SOURCE_NAME $SOURCE_VERSION)\"|" /usr/lib/os-release

# Tmpfiles fix for pcp
cat > /usr/lib/tmpfiles.d/pcp-cayo.conf<<'EOF'
d /var/lib/pcp/config/pmda 0775 pcp pcp -
d /var/lib/pcp/config/pmie 0775 pcp pcp -
d /var/lib/pcp/config/pmlogger 0775 pcp pcp -
d /var/lib/pcp/tmp 0775 pcp pcp -
d /var/lib/pcp/tmp/bash 0775 pcp pcp -
d /var/lib/pcp/tmp/json 0775 pcp pcp -
d /var/lib/pcp/tmp/mmv 0775 pcp pcp -
d /var/lib/pcp/tmp/pmie 0775 pcp pcp -
d /var/lib/pcp/tmp/pmlogger 0775 pcp pcp -
d /var/lib/pcp/tmp/pmproxy 0775 pcp pcp -
d /var/log/pcp 0775 pcp pcp -
d /var/log/pcp/pmcd 0775 pcp pcp -
d /var/log/pcp/pmfind 0775 pcp pcp -
d /var/log/pcp/pmie 0775 pcp pcp -
d /var/log/pcp/pmlogger 0775 pcp pcp -
d /var/log/pcp/pmproxy 0775 pcp pcp -
d /var/log/pcp/sa 0775 pcp pcp -
EOF
