set -xeuo pipefail

# /*
# enable Kmods SIG repos
# */
dnf -y install "https://mirror.stream.centos.org/SIGs/$(rpm --eval '%{?rhel}/kmods/%{_arch}/repos-main/Packages/c/centos-repos-kmods-%{?rhel}-2.el%{?rhel}.noarch.rpm')"
dnf -y install centos-release-kmods
dnf config-manager --set-enabled centos-kmods-rebuild

# /*
# install desired kmods and utils
# */
dnf -y install \
    btrfs-progs \
    kmod-aacraid \
    kmod-btrfs \
    kmod-be2iscsi \
    kmod-be2net \
    kmod-hpsa \
    kmod-lpfc \
    kmod-megaraid_sas \
    kmod-mpt3sas \
    kmod-mptsas \
    kmod-mptspi \
    kmod-ntfs3 \
    kmod-qla2xxx

# /* Broken
#    kmod-vbox-guest-additions
# */

# /*
# typically we disable extra repos, but like CRB and EPEL
# this repo is from CentOS so we leave it enabled
# */
