#!/usr/bin/env bash
set -xeuo pipefail

### install base server packages

### add ublue-os specific packages
dnf -y copr enable ublue-os/packages
dnf -y install ublue-os-signing
mv /etc/containers/policy.json /etc/containers/policy.json-upstream
mv /usr/etc/containers/policy.json /etc/containers/
rm -fr /usr/etc
dnf -y copr disable ublue-os/packages

### server base packages which are mostly what we added in ucore-minimal
dnf config-manager --add-repo https://pkgs.tailscale.com/stable/centos/9/tailscale.repo

dnf -y install --setopt=install_weak_deps=False \
  cockpit-networkmanager \
  cockpit-podman \
  cockpit-selinux \
  cockpit-system \
  firewalld \
  man-db \
  man-pages \
  open-vm-tools \
  qemu-guest-agent \
  tailscale \
  tmux \
  wireguard-tools

dnf config-manager --set-disabled tailscale-stable

# /*
# Cockpit Web Service unit
# */
cat > /usr/lib/systemd/system/cockpit.service<<'EOF'
[Unit]
Description=Cockpit Container
After=network-online.target
Wants=network-online.target
RequiresMountsFor=%t/containers
RequiresMountsFor=/

[X-Container]
Image=quay.io/cockpit/ws:latest
ContainerName=cockpit-ws
Environment=NAME=cockpit-ws

#flag for autoupdates
Label=io.containers.autoupdate=registry

Volume=/:/host
PodmanArgs=--pid host --privileged
Exec=/container/label-run

[Service]
Restart=always
Environment=PODMAN_SYSTEMD_UNIT=%n
KillMode=mixed
ExecStopPost=-/usr/bin/podman rm -f -i --cidfile=%t/%N.cid
ExecStopPost=-rm -f %t/%N.cid
Delegate=yes
Type=notify
NotifyAccess=all
SyslogIdentifier=%N
ExecStart=/usr/bin/podman run --name=ws --cidfile=%t/%N.cid --replace --rm --cgroups=split --sdnotify=conmon -d -v /:/host --env NAME=ws --label io.containers.autoupdate=registry --pid host --privileged quay.io/cockpit/ws:latest /container/label-run

[Install]
WantedBy=default.target
EOF

### set variant and url for unique identification
sed -i 's|^HOME_URL=.*|HOME_URL="https://projectcayo.org"|' /usr/lib/os-release
echo 'VARIANT="Cayo"' >> /usr/lib/os-release
echo 'VARIANT_ID="cayo"' >> /usr/lib/os-release
# if VARIANT ever gets added to CentOS we'll need these instead
#sed -i 's|^VARIANT=.*|VARIANT="Cayo"|' /usr/lib/os-release
#sed -i 's|^VARIANT_ID=.*|VARIANT_ID="cayo"|' /usr/lib/os-release

# set pretty name for base image
SOURCE_VERSION="$(grep ^VERSION_ID= /usr/lib/os-release|cut -f2 -d=|tr -d \")"
SOURCE_NAME="$(grep ^NAME= /usr/lib/os-release|cut -f2 -d=|tr -d \")"
sed -i "s|^PRETTY_NAME=.*|PRETTY_NAME=\"Cayo (Version $IMAGE_VERSION / FROM $SOURCE_NAME $SOURCE_VERSION)\"|" /usr/lib/os-release