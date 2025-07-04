# Cayo FAQ


## Table of Contents
1. [Cayo Images](#images)
2. [Installation - Anaconda](#anaconda-work-in-progress)
3. [Installation - Podman](#podman)
4. [Common Issues](#common-issues)

### Images
Cayo currently offers two primary images: one based on CentOS 10 and another on Fedora 42. The rationale for providing both images addresses hardware compatibility.

Specifically, the CentOS-based image necessitates a CPU that meets [x86-64-v3 requirements](https://en.wikipedia.org/wiki/X86-64#Microarchitecture_levels).  At this point in time, Fedora does not have this hardware limitation.

- https://ghcr.io/ublue-os/cayo:centos (CentOS)
- https://ghcr.io/ublue-os/cayo:fedora (Fedora)

## Installation
Multiple methods are available for installing Cayo.

The following sections describe installation procedures based on the official [bootc install methods](https://docs.fedoraproject.org/en-US/bootc/bare-metal/) documentation.
__NOTE:__ _This section is a work in progress_.

### Anaconda [Work In Progress]
An Anaconda based ISO installer is currently under development.  Please check back for updates regarding its release for testing and general availability.

### Podman
One of the most straightforward installation methods currently available (at the time of this writing) involves booting from a [Fedora CoreOS Live DVD ISO](https://fedoraproject.org/coreos/download?stream=stable).

#### Minimum Memory Requirements for Podman Based Install
Due to the installation process running from within a RAM disk, it's crucial that the target machine has adequate RAM to avoid "out of space" errors.

The following minimum RAM allocations are recommended for successful installations of Cayo images via Podman:

- `cayo:centos` - 8GB RAM minimum
- `cayo:fedora` - 12GB RAM minimum

The allocated RAM can be scaled back after the installation is complete, as the additional RAM is only required for temporary package files that are downloaded and extracted during the installation phase.

An authorized key file is required for the `root` user to enable SSH access after installation.

The following steps illustrate how the author achieved this on a virtual machine booted from the Fedora CoreOS Live DVD.

Assuming `id_rsa.pub` is the public SSH key for the client connecting to the new installation:
```
mkdir .ssh
curl http://[lab_webserver]:[port_number]/id_rsa.pub > .ssh/authorized_keys
```

The id_rsa.pub file was served up from a directory using a basic python http server on the author's PC.
```
cd /path/where/file/is
python -m http.server [port_number]
```


#### `cayo:centos` Install:
The following command assumes the target hard drive is `/dev/sda` and the `authorized_keys` file has been created as described above.
```
sudo podman run \
--rm --privileged \
--pid=host \
-v /dev:/dev \
-v /var/lib/containers:/var/lib/containers \
-v ~/.ssh:/temp \
--security-opt label=type:unconfined_t \
ghcr.io/ublue-os/cayo:centos \
bootc install to-disk /dev/sda --root-ssh-authorized-keys /temp/authorized_keys
```

#### `cayo:fedora` Install:
The following command assumes the target hard drive is `/dev/sda` and the `authorized_keys` file has been created as described above.

__NOTE:__  Fedora-based installations require explicit specification of the root filesystem type, using the `bootc` argument `--filesystem` at install.
```
sudo podman run \
--rm --privileged \
--pid=host \
-v /dev:/dev \
-v /var/lib/containers:/var/lib/containers \
-v ~/.ssh:/temp \
--security-opt label=type:unconfined_t \
ghcr.io/ublue-os/cayo:fedora \
bootc install to-disk /dev/sda --root-ssh-authorized-keys /temp/authorized_keys --filesystem xfs
```

## Common Issues
- __Podman install errors out with "out of space" issues.__
Verify that sufficient RAM has been allocated for the RAM disk.  The minimum recommended values are 8GB for Cayo:10 and 12GB for Cayo:42.

- __Unable to log in after installation.__
Confirm that the `--root-ssh-authorized-keys` argument was provided to the `bootc` command during installation.

- __Installation fails, unable to find `--root-ssh-authorized-keys` file.__
The path provided to bootc refers to the path within _the container_, not the host RAM disk environment.  In the examples provided `/temp` inside the container was mapped from `~/.ssh` inside the RAM disk environment.

## Disclaimer
All information is provided "as is" and is based on observations and experiences of the author. The objective is to assist new users in deploying Cayo for the first time.  Running HTTP servers without SSL poses a security risk and is not recommended in production environments.