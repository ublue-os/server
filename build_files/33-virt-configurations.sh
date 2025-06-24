set -xeuo pipefail

# /*
# NOTE: LIBVIRT IS AN EXTENSION CANDIDATE
# This will cease to exist when the extension is released.
# */

# /*
# set pretty name for HCI image
# */
SOURCE_VERSION="$(grep ^VERSION_ID= /usr/lib/os-release | cut -f2 -d= | tr -d \")"
SOURCE_NAME="$(grep ^NAME= /usr/lib/os-release | cut -f2 -d= | tr -d \")"
sed -i "s|^PRETTY_NAME=.*|PRETTY_NAME=\"Cayo HCI (Version $IMAGE_VERSION / FROM $SOURCE_NAME $SOURCE_VERSION)\"|" /usr/lib/os-release
