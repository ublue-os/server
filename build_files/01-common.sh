#!/usr/bin/env bash
set -xeuo pipefail

# See https://github.com/CentOS/centos-bootc/issues/191
mkdir -m 0700 -p /var/roothome /var/opt

# make /usr/local and /opt writable
mkdir -m 0755 -p /var/opt /var/usrlocal
ln -sf /var/opt /opt
ln -sf /var/usrlocal /usr/local

# remove subscription manager
dnf -y remove \
  libdnf-plugin-subscription-manager \
  python3-subscription-manager-rhsm \
  subscription-manager \
  subscription-manager-rhsm-certificates

# enable CRB, EPEL and other repos
dnf config-manager --set-enabled crb
dnf -y install epel-release
dnf -y upgrade epel-release

# packages which are more or less what we'd find in CoreOS
# other than ignition, coreos-installer, moby-engine, etc
dnf -y install --setopt=install_weak_deps=False \
  audit \
  git-core \
  intel-compute-runtime \
  ipcalc \
  iscsi-initiator-utils \
  python3-dnf-plugin-versionlock \
  rsync \
  ssh-key-dir

# Kernel Swap to Kernel signed with our MOK
pushd /tmp/kernel-rpms
#shellcheck disable=SC1083
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

dnf versionlock add kernel kernel-core kernel-modules kernel-modules-core kernel-modules-extra
