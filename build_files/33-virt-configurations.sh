#!/usr/bin/env bash

set -eoux pipefail

# /*
### sysusers.d for libvirtdbus
# */
cat >/usr/lib/sysusers.d/libvirt-dbus.conf <<'EOF'
u libvirtdbus - 'Libvirt D-Bus bridge' - -
EOF

# /*
# set pretty name for HCI image
# */
SOURCE_VERSION="$(grep ^VERSION_ID= /usr/lib/os-release|cut -f2 -d=|tr -d \")"
SOURCE_NAME="$(grep ^NAME= /usr/lib/os-release|cut -f2 -d=|tr -d \")"
sed -i "s|^PRETTY_NAME=.*|PRETTY_NAME=\"Cayo HCI (Version $IMAGE_VERSION / FROM $SOURCE_NAME $SOURCE_VERSION)\"|" /usr/lib/os-release
