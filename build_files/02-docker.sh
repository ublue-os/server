#!/usr/bin/env bash
set -xeuo pipefail

# setup docker instead of moby-engine as in CoreOS
dnf config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo

dnf -y install --setopt=install_weak_deps=False \
  docker-ce \
  docker-ce-cli \
  containerd.io \
  docker-buildx-plugin \
  docker-compose-plugin \

# prefer to have docker-compose available for legacy muscle-memory
ln -s /usr/libexec/docker/cli-plugins/docker-compose /usr/bin/docker-compose

# docker sysctl.d
mkdir -p /usr/lib/sysctl.d
echo "net.ipv4.ip_forward = 1" >/usr/lib/sysctl.d/docker-ce.conf

dnf config-manager --set-disabled docker-ce-stable
# TODO: check default service state (should be disabled)
# TODO: handle group problem with bootc container lint
