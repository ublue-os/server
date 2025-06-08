FROM quay.io/centos-bootc/centos-bootc:stream10

RUN <<EOF
set -xeuo pipefail

# See https://github.com/CentOS/centos-bootc/issues/191
mkdir -m 0700 -p /var/roothome /var/opt 

# make /usr/local and /opt writable
mkdir -m 0755 -p /var/opt /var/usrlocal
ln -s /var/opt /opt
ln -s /var/usrlocal /usr/local

# remove subscription manager
dnf -y remove \
  libdnf-plugin-subscription-manager \
  python3-subscription-manager-rhsm \
  subscription-manager \
  subscription-manager-rhsm-certificates

# enable CRB, EPEL and other repos
dnf config-manager --set-enabled crb
dnf config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
dnf -y install epel-release
dnf -y upgrade

### packages which are more or less what we'd find in CoreOS
dnf -y install --setopt=install_weak_deps=False \
  audit \
  docker-ce \
  docker-ce-cli \
  containerd.io \
  docker-buildx-plugin \
  docker-compose-plugin \
  git-core \
  ipcalc \
  iscsi-initiator-utils \
  rsync \
  ssh-key-dir

# prefer to have docker-compose available for legacy muscle-memory
ln -s /usr/libexec/docker/cli-plugins/docker-compose /usr/bin/docker-compose

# Docker sysctl.d
mkdir -p /usr/lib/sysctl.d
echo "net.ipv4.ip_forward = 1" >/usr/lib/sysctl.d/docker-ce.conf

# disable repos by default
for R in docker-ce; do
  REPO="/etc/yum.repos.d/${R}.repo"
  if [ -f "${REPO}" ]; then
    sed -i "s@enabled=1@enabled=0@" "${REPO}"
  fi
done

# post-build operations
dnf clean all
rm /var/{log,cache,lib}/* -rf
systemctl preset-all
bootc container lint
EOF
