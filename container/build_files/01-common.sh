# /*
#shellcheck disable=SC2174,SC2114
# */

set ${CI:+-x} -euo pipefail

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
# remove any wifi support from base
# */
dnf -y remove \
  atheros-firmware \
  brcmfmac-firmware \
  iwlegacy-firmware \
  iwlwifi-dvm-firmware \
  iwlwifi-mvm-firmware \
  mt7xxx-firmware \
  nxpwireless-firmware \
  realtek-firmware \
  tiwilink-firmware

# /*
# packages which are more or less what we'd find in CoreOS
# other than ignition, coreos-installer, moby-engine, etc
# */
dnf -y install --setopt=install_weak_deps=False \
  audit \
  git-core \
  ipcalc \
  iscsi-initiator-utils \
  rsync \
  ssh-key-dir

# /*
# Zram Generator
# */
cat >/usr/lib/systemd/zram-generator.conf <<'EOF'
[zram0]
zram-size = min(ram, 8192)
EOF

# /*
# Configure Updates
# */
sed -i 's|^ExecStart=.*|ExecStart=/usr/bin/bootc update --quiet|' /usr/lib/systemd/system/bootc-fetch-apply-updates.service
sed -i 's|^OnUnitInactiveSec=.*|OnUnitInactiveSec=7d\nPersistent=true|' /usr/lib/systemd/system/bootc-fetch-apply-updates.timer
sed -i 's|#AutomaticUpdatePolicy.*|AutomaticUpdatePolicy=stage|' /etc/rpm-ostreed.conf
sed -i 's|#LockLayering.*|LockLayering=true|' /etc/rpm-ostreed.conf
