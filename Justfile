set unstable

just := just_executable()
podman := require('podman')

_default:
    @just --list --unsorted

podman-info:
    {{ podman }} info

build-image:
    {{ podman }} build \
        --cpp-flag="-DSOURCE_IMAGE=quay.io/centos-bootc/centos-bootc:c10s" \
        --cpp-flag="-DINCL_NAS=1" \
        --cpp-flag="-DINCL_VIRT=1" \
        --cpp-flag="-DINCL_NVIDIA=1" \
        --cpp-flag="-DINCL_ZFS=1" \
        --security-opt=label=disable \
        --cap-add=all \
        --device /dev/fuse \
        -t server:10 \
        -f Containerfile.in \
        .
