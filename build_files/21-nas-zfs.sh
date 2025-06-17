#!/usr/bin/env bash
set -xeuo pipefail

# TODO: missing mbuffer dependency for sanoid on EPEL 10
### install NAS server ZFS packages
# dnf -y copr enable ublue-os/staging
# dnf -y install sanoid
# dnf -y copr disable ublue-os/staging


# add ZFS maintenance tasks
cat > /usr/lib/systemd/system/zfs-scrub-monthly@.timer <<'EOF'
[Unit]
Description=Monthly zpool scrub timer for %i
Documentation=man:zpool-scrub(8)

[Timer]
OnCalendar=monthly
Persistent=true
RandomizedDelaySec=1h
Unit=zfs-scrub@%i.service

[Install]
WantedBy=timers.target
EOF

cat > /usr/lib/systemd/system/zfs-scrub-weekly@.timer <<'EOF'
[Unit]
Description=Weekly zpool scrub timer for %i
Documentation=man:zpool-scrub(8)

[Timer]
OnCalendar=weekly
Persistent=true
RandomizedDelaySec=1h
Unit=zfs-scrub@%i.service

[Install]
WantedBy=timers.target
EOF

cat > /usr/lib/systemd/system/zfs-scrub@.service <<'EOF'
[Unit]
Description=zpool scrub on %i
Documentation=man:zpool-scrub(8)
Requires=zfs.target
After=zfs.target
ConditionACPower=true
ConditionPathIsDirectory=/sys/module/zfs

[Service]
EnvironmentFile=-@initconfdir@/zfs
ExecStart=/bin/sh -c '\
if /usr/sbin/zpool status %i | grep -q "scrub in progress"; then\
exec /usr/sbin/zpool wait -t scrub %i;\
else exec /usr/sbin/zpool scrub -w %i; fi'
ExecStop=-/bin/sh -c '/usr/sbin/zpool scrub -p %i 2>/dev/null || true'
EOF


# add cockpit plugin for ZFS management
curl --fail --retry 15 --retry-all-errors -sSL -o /tmp/cockpit-zfs-manager-api.json \
    "https://api.github.com/repos/45Drives/cockpit-zfs-manager/releases/latest"
CZM_TGZ_URL=$(jq -r .tarball_url /tmp/cockpit-zfs-manager-api.json)
curl --fail --retry 15 --retry-all-errors -sSL -o /tmp/cockpit-zfs-manager.tar.gz "${CZM_TGZ_URL}"

mkdir -p /tmp/cockpit-zfs-manager
tar -zxvf /tmp/cockpit-zfs-manager.tar.gz -C /tmp/cockpit-zfs-manager --strip-components=1
mv /tmp/cockpit-zfs-manager/polkit-1/actions/* /usr/share/polkit-1/actions/
mv /tmp/cockpit-zfs-manager/polkit-1/rules.d/* /usr/share/polkit-1/rules.d/
mv /tmp/cockpit-zfs-manager/zfs /usr/share/cockpit

curl --fail --retry 15 --retry-all-errors -sSL -o /tmp/cockpit-zfs-manager-font-fix.sh \
    https://raw.githubusercontent.com/45Drives/scripts/refs/heads/main/cockpit_font_fix/fix-cockpit.sh
chmod +x /tmp/cockpit-zfs-manager-font-fix.sh
/tmp/cockpit-zfs-manager-font-fix.sh

rm -rf /tmp/cockpit-zfs-manager*