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
  ipcalc \
  iscsi-initiator-utils \
  rsync \
  ssh-key-dir
