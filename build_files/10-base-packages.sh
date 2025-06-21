set -xeuo pipefail

# /*
### install base server packages
# */

# /*
### add ublue-os specific packages
# */
dnf -y copr enable ublue-os/packages
dnf -y install ublue-os-signing
mv /etc/containers/policy.json /etc/containers/policy.json-upstream
mv /usr/etc/containers/policy.json /etc/containers/
rm -fr /usr/etc
dnf -y copr disable ublue-os/packages

# /*
### server base packages which are mostly what we added in ucore-minimal
# */
dnf config-manager --add-repo https://pkgs.tailscale.com/stable/centos/"$(rpm -E %centos)"/tailscale.repo

dnf -y install --setopt=install_weak_deps=False \
    NetworkManager-wifi \
    cockpit-networkmanager \
    cockpit-podman \
    cockpit-selinux \
    cockpit-storaged \
    cockpit-system \
    distrobox \
    duperemove \
    firewalld \
    hdparm \
    iwlegacy-firmware \
    iwlwifi-dvm-firmware \
    iwlwifi-mvm-firmware \
    man-db \
    man-pages \
    open-vm-tools \
    pcp-zeroconf \
    qemu-guest-agent \
    samba \
    samba-usershares \
    tailscale \
    tmux \
    usbutils \
    wireguard-tools \
    xdg-dbus-proxy \
    xdg-user-dirs

dnf config-manager --set-disabled tailscale-stable

dnf -y copr enable ublue-os/staging
dnf -y install snapraid
dnf -y copr disable ublue-os/staging

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

# /*
### set variant and url for unique identification
# */
sed -i 's|^HOME_URL=.*|HOME_URL="https://projectcayo.org"|' /usr/lib/os-release
echo 'VARIANT="Cayo"' >> /usr/lib/os-release
echo 'VARIANT_ID="cayo"' >> /usr/lib/os-release
# /*
# if VARIANT ever gets added to CentOS we'll need these instead
#sed -i 's|^VARIANT=.*|VARIANT="Cayo"|' /usr/lib/os-release
#sed -i 's|^VARIANT_ID=.*|VARIANT_ID="cayo"|' /usr/lib/os-release
# */

# /*
### install packages direct from github
### NOTE: ARM support will require use of proper arch rather than hard coding
# */
/run/build_files/github-release-install.sh rclone/rclone "linux-amd64"
/run/build_files/github-release-install.sh trapexit/mergerfs "el$(rpm -E %centos).$(uname -m)"
