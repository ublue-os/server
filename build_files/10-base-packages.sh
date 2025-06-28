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
dnf -y install --setopt=install_weak_deps=False \
    cockpit-networkmanager \
    cockpit-podman \
    cockpit-selinux \
    cockpit-storaged \
    cockpit-system \
    distrobox \
    duperemove \
    firewalld \
    hdparm \
    man-db \
    man-pages \
    open-vm-tools \
    pcp-zeroconf \
    qemu-guest-agent \
    snapraid \
    tmux \
    usbutils \
    wireguard-tools \
    xdg-dbus-proxy \
    xdg-user-dirs


# /* Currently missing dependencies
# dnf -y copr enable ublue-os/staging
# dnf -y install sanoid
# dnf -y copr disable ublue-os/staging
# */

# /*
### install packages direct from github
### NOTE: ARM support will require use of proper arch rather than hard coding
# */
/run/build_files/github-release-install.sh rclone/rclone "linux-amd64"
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
