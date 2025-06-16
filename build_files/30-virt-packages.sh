#!/usr/bin/env bash
set -xeuo pipefail

### install virt server packages

### server hci packages which are mostly what we added in ucore-hci
dnf -y install --setopt=install_weak_deps=False \
    cockpit-machines \
    libvirt-client \
    libvirt-daemon-kvm \
    virt-install

### sysusers.d for libvirtdbus
cat >/usr/lib/sysusers.d/libvirt-dbus.conf <<'EOF'
u libvirtdbus - 'Libvirt D-Bus bridge' - -
EOF

### Libvirt SELinux Labeling Workarounds
cat >/usr/lib/systemd/system/libvirt-restorecon.service <<'EOF'
[Unit]
Description=Workaround to relabel libvirt files and directories
ConditionPathIsDirectory=/var/lib/libvirt/
ConditionPathIsDirectory=/var/log/libvirt/
After=local-fs.target systemd-tmpfiles-setup.service

[Service]
Type=oneshot
ExecStart=-/usr/sbin/restorecon -R /var/log/libvirt/
ExecStart=-/usr/sbin/restorecon -R /var/lib/libvirt/
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
EOF

cat >/usr/lib/systemd/system-preset/80-libvirt-restorecon.preset <<'EOF'
enable libvirt-restorecon.service
EOF

systemctl preset libvirt-restorecon.service
