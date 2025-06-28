set ${CI:+-x} -euo pipefail

dnf -y --setopt=install_weak_deps=False install dnf5-plugins
