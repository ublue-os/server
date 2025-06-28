set -xeuo pipefail

# /*
# Tailscale Repo
# */
dnf config-manager addrepo --from-repofile=https://pkgs.tailscale.com/stable/fedora/tailscale.repo
dnf config-manager setopt tailscale-stable.enabled=0

dnf -y install --enablerepo='tailscale-stable' tailscale

# /*
# Install MergerFS
# */
/run/build_files/github-release-install.sh trapexit/mergerfs "fc$(rpm -E %fedora).$(uname -m)"
