set ${CI:+-x} -euo pipefail

# /*
# NOTE: THIS IS AN EXTENSION CANDIDATE
# */

# /*
### install base server NVIDIA packages
# */
dnf -y install /tmp/akmods-nv-rpms/ublue-os/ublue-os-nvidia-addons-*.rpm

dnf config-manager --set-enabled epel-nvidia
dnf config-manager --set-enabled nvidia-container-toolkit

KERNEL_VR="$(rpm -q "kernel" --queryformat '%{VERSION}-%{RELEASE}')"
dnf -y install \
    nvidia-container-toolkit \
    nvidia-driver-cuda \
    /tmp/akmods-nv-rpms/kmods/kmod-nvidia*"${KERNEL_VR}"*.rpm

dnf config-manager --set-disabled epel-nvidia
dnf config-manager --set-disabled nvidia-container-toolkit

# /*
### Nvidia specific configurations
# */
semodule --verbose --install /usr/share/selinux/packages/nvidia-container.pp
systemctl preset ublue-nvctk-cdi.service
