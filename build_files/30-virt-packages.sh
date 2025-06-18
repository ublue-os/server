#!/usr/bin/env bash
set -xeuo pipefail

### install virt server packages
dnf -y copr enable ublue-os/packages

### server hci packages which are mostly what we added in ucore-hci
dnf -y install --setopt=install_weak_deps=False \
    cockpit-machines \
    libvirt-client \
    libvirt-daemon-kvm \
    ublue-os-libvirt-workarounds \
    virt-install

### sysusers.d for libvirtdbus
cat >/usr/lib/sysusers.d/libvirt-dbus.conf <<'EOF'
u libvirtdbus - 'Libvirt D-Bus bridge' - -
EOF

dnf -y copr disable ublue-os/packages

# set pretty name for HCI image
SOURCE_VERSION="$(grep ^VERSION_ID= /usr/lib/os-release|cut -f2 -d=|tr -d \")"
SOURCE_NAME="$(grep ^NAME= /usr/lib/os-release|cut -f2 -d=|tr -d \")"
sed -i "s|^PRETTY_NAME=.*|PRETTY_NAME=\"Cayo HCI (Version $IMAGE_VERSION / FROM $SOURCE_NAME $SOURCE_VERSION)\"|" /usr/lib/os-release