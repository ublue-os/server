set ${CI:+-x} -euo pipefail

dnf -y --setopt=install_weak_deps=False install dnf5-plugins

# /*
# sysusers for libutmpter. Remove when https://koji.fedoraproject.org/koji/search?terms=libutempter-1.2.1-18.fc43&type=build&match=exact is the version
# */
cat >/usr/lib/sysusers.d/cayo-utempter.conf <<'EOF'
g utempter 35
EOF
