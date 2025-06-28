set ${CI:+-x} -euo pipefail

# /*
# Tailscale Repo
# */
dnf config-manager --add-repo https://pkgs.tailscale.com/stable/centos/"$(rpm -E %centos)"/tailscale.repo
dnf config-manager --set-disabled tailscale-stable

dnf -y install --enablerepo='tailscale-stable' tailscale

# /*
# Install MergerFS
# */
/run/build_files/github-release-install.sh trapexit/mergerfs "el$(rpm -E %centos).$(uname -m)"
