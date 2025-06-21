# /*
#shellcheck disable=SC1083
# */

set -eoux pipefail

# /*
### Kernel Swap to Kernel signed with our MOK
# */

find /tmp/kernel-rpms

pushd /tmp/kernel-rpms
CACHED_VERSION=$(find kernel-*.rpm | grep -P "kernel-\d+\.\d+\.\d+-\d+$(rpm -E %{dist})" | sed -E 's/kernel-//;s/\.rpm//')
popd
KERNEL_VERSION="$(rpm -q 'kernel' | sed -E 's/kernel-//')"

if [[ "${CACHED_VERSION}" == "$KERNEL_VERSION" ]]; then
  dnf -y --allowerasing install /tmp/kernel-rpms/kernel-core-"$CACHED_VERSION".rpm
else
  dnf -y --allowerasing install \
    /tmp/kernel-rpms/kernel-"$CACHED_VERSION".rpm \
    /tmp/kernel-rpms/kernel-core-"$CACHED_VERSION".rpm \
    /tmp/kernel-rpms/kernel-modules-"$CACHED_VERSION".rpm \
    /tmp/kernel-rpms/kernel-modules-core-"$CACHED_VERSION".rpm \
    /tmp/kernel-rpms/kernel-modules-extra-"$CACHED_VERSION".rpm
fi

# /*
### Version Lock kernel pacakges
# */
dnf versionlock add kernel kernel-core kernel-modules kernel-modules-core kernel-modules-extra
