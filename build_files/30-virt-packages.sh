set -xeuo pipefail

# /*
### install virt server packages
# */
dnf -y copr enable ublue-os/packages

# /*
### server hci packages which are mostly what we added in ucore-hci
# */
dnf -y install --setopt=install_weak_deps=False \
    cockpit-machines \
    libvirt-client \
    libvirt-daemon-kvm \
    ublue-os-libvirt-workarounds \
    virt-install

dnf -y copr disable ublue-os/packages
