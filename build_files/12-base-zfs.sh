set -xeuo pipefail

# /*
# Get Kernel Version
# */
KERNEL_VRA="$(rpm -q "kernel" --queryformat '%{EVR}.%{ARCH}')"

# /*
### install ZFS packages
# */
dnf -y install \
    /tmp/akmods-zfs-rpms/kmods/zfs/kmod-zfs-"${KERNEL_VRA}"-*.rpm \
    /tmp/akmods-zfs-rpms/kmods/zfs/libnvpair3-*.rpm \
    /tmp/akmods-zfs-rpms/kmods/zfs/libuutil3-*.rpm \
    /tmp/akmods-zfs-rpms/kmods/zfs/libzfs6-*.rpm \
    /tmp/akmods-zfs-rpms/kmods/zfs/libzpool6-*.rpm \
    /tmp/akmods-zfs-rpms/kmods/zfs/python3-pyzfs-*.rpm \
    /tmp/akmods-zfs-rpms/kmods/zfs/zfs-*.rpm \
    /tmp/akmods-zfs-rpms/kmods/zfs/other/zfs-dracut-*.rpm

# /*
# depmod ran automatically with zfs 2.1 but not with 2.2
# */
depmod -a "${KERNEL_VRA}"

# /*
### install ZFS related packages
# */
dnf -y copr enable ublue-os/staging
dnf -y install \
    mbuffer \
    pv \
    sanoid
dnf -y copr disable ublue-os/staging
