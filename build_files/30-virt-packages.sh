#!/usr/bin/env bash
set -xeuo pipefail

### install virt server packages

### server hci packages which are mostly what we added in ucore-hci
dnf -y install --setopt=install_weak_deps=False \
    cockpit-machines \
    libvirt-client \
    libvirt-daemon-kvm \
    virt-install

### sysusers.d for libvirtdbus
cat >/usr/lib/sysusers.d/libvirt-dbus.conf <<'EOF'
u libvirtdbus - 'Libvirt D-Bus bridge' - -
EOF
