set unstable

just := just_executable()
podman := require('podman')
sudoif := if `id -u` != '0' { 'sudo' } else { '' }

_default:
    @just --list --unsorted

podman-info:
    {{ sudoif }} {{ podman }} info

build-image:
    {{ sudoif }} {{ podman }} build \
        --security-opt=label=disable \
        --cap-add=all \
        --device /dev/fuse \
        -t server:10 \
        -f Containerfile \
        .
