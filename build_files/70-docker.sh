set -xeuo pipefail

# /*
# NOTE: THIS IS AN EXTENSION CANDIDATE
# */

# /*
# setup docker instead of moby-engine as in CoreOS
# */
dnf config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo

dnf -y install --setopt=install_weak_deps=False \
  docker-ce \
  docker-ce-cli \
  containerd.io \
  docker-buildx-plugin \
  docker-compose-plugin

# /*
# prefer to have docker-compose available for legacy muscle-memory
# */
ln -s /usr/libexec/docker/cli-plugins/docker-compose /usr/bin/docker-compose

# /*
# docker sysctl.d
# */
mkdir -p /usr/lib/sysctl.d
echo "net.ipv4.ip_forward = 1" >/usr/lib/sysctl.d/docker-ce.conf

dnf config-manager --set-disabled docker-ce-stable

# /*
# Disable the docker socket by default
# */
sed -i 's/enable docker/disable docker/' /usr/lib/systemd/system-preset/90-default.preset
systemctl preset docker.service docker.socket

# /*
# sysusers.d for docker
# */
cat >/usr/lib/sysusers.d/docker.conf <<'EOF'
g docker -
EOF
