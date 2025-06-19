# /*
#shellcheck disable=SC2174,SC2114
# */

set -xeuo pipefail

# /*
# See https://github.com/CentOS/centos-bootc/issues/191
# */
mkdir -m 0700 -p /var/roothome

# /*
# make /usr/local and /opt writable
# */
mkdir -p /var/{opt,usrlocal}
rm -rf /opt /usr/local
ln -sf var/opt /opt
ln -sf ../var/usrlocal /usr/local

# /*
# remove subscription manager
# */
dnf -y remove \
  libdnf-plugin-subscription-manager \
  python3-subscription-manager-rhsm \
  subscription-manager \
  subscription-manager-rhsm-certificates

# /*
# enable CRB, EPEL and other repos
# */
dnf config-manager --set-enabled crb
dnf -y install epel-release
dnf -y upgrade epel-release

# /*
# packages which are more or less what we'd find in CoreOS
# other than ignition, coreos-installer, moby-engine, etc
# */
dnf -y install --setopt=install_weak_deps=False \
  audit \
  git-core \
  intel-compute-runtime \
  ipcalc \
  iscsi-initiator-utils \
  python3-dnf-plugin-versionlock \
  rsync \
  ssh-key-dir

# /*
# Configure Updates
# */
sed -i 's|^ExecStart=.*|ExecStart=/usr/bin/bootc update --quiet|' /usr/lib/systemd/system/bootc-fetch-apply-updates.service
sed -i 's|^OnUnitInactiveSec=.*|OnUnitInactiveSec=7d\nPersistent=true|' /usr/lib/systemd/system/bootc-fetch-apply-updates.timer
sed -i 's|#AutomaticUpdatePolicy.*|AutomaticUpdatePolicy=stage|' /etc/rpm-ostreed.conf
sed -i 's|#LockLayering.*|LockLayering=true|' /etc/rpm-ostreed.conf

# /*
# Zram Generator
# */
cat >/usr/lib/systemd/zram-generator.conf <<'EOF'
[zram0]
zram-size = min(ram, 8192)
EOF
