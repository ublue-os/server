# /*
#shellcheck disable=SC2174
# */

set -xeuo pipefail

# /*
# See https://github.com/CentOS/centos-bootc/issues/191
# */
mkdir -m 0700 -p /var/roothome

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
# Install Packages
# */
dnf -y --setopt=install_weak_deps=False install \
    python3-dnf-plugin-versionlock \
    systemd-resolved

# /*
# Ensure systemd-resolved is enabled
# */
cat >/usr/lib/systemd/system-preset/91-cayo-resolved.preset <<'EOF'
enable systemd-resolved.service
EOF
cat >/usr/lib/tmpfiles.d/cayo-resolved.conf <<'EOF'
L /etc/resolv.conf - - - - ../run/systemd/resolve/stub-resolv.conf
EOF

systemctl preset systemd-resolved.service
