set -xeuo pipefail

dnf -y --setopt=install_weak_deps=False install dnf5-plugins

# /*
# Remove Moby
# */

dnf -y remove \
    containerd \
    docker-cli \
    moby-engine \
    runc
