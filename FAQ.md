# Cayo FAQ
Notes from a newcomer for other newcomers

## Table of Contents
1. [Cayo Images](###Images)
2. [Installation - Anaconda](###Anaconda)
3. [Installation - Podman](###Podman)
4. [Common Issues](###Common%20Issues)

### Images
We currently have 2 images for Cayo, one is based off of Centos 10 Stream and one based off of Fedora 42.  The reason for this is that one issue encountered on older hardware (my own being a box running an AMD FX-8320 + 32GB RAM), is that CentOS requires a CPU that meets [x86-64-v3 requirements](https://en.wikipedia.org/wiki/X86-64#Microarchitecture_levels).  At this point in time, Fedora 42 does not have this limitation.
- https://ghcr.io/ublue-os/cayo:10 (CentOS)
- https://ghcr.io/ublue-os/cayo:42 (Fedora)

## Installation
There are multiple ways to install Cayo on your system.  Here are a couple based off the official [bootc install methods](https://docs.fedoraproject.org/en-US/bootc/bare-metal/) page.  __This section is a work in progress.__

### Anaconda [WIP]
There is work in progress on an Anaconda based ISO installer.  Please check back later when it is ready for end user consumption.

### Podman
One of the simplest ways (for now) is to boot from a [Fedora CoreOS Live DVD ISO](https://fedoraproject.org/coreos/download?stream=stable).

#### Minimum Memory Requirements for Podman Based Install
Due to everything running from a ramdisk, it's easy for it to fill up during download and extraction of packages.  Here are my findings for installing the Cayo images via Podman:
- Cayo:10 (CentOS base) - 8GB RAM minimum
- Cayo:42 (Fedora base) - 12GB RAM minimum

You can scale the RAM back afterward if you wish, it only needs the extra RAM for the package files that are downloaded and extracted during installation.

An authorized key file will be needed for the root user to allow login over SSH after installation.  I did the following from a virtual machine booted from the Fedora CoreOS Live DVD (where id_rsa.pub is my public SSH key for the client I will be logging into the new install from):
```
mkdir .ssh
curl http://[lab_webserver]:[port_number]/id_rsa.pub > .ssh/authorized_keys
```

The id_rsa.pub file was served up from a directory using a basic python http server on my PC.
```
cd /path/where/file/is
python -m http.server [port_number]
```

#### Cayo:10 (CentOS) Install:
Assumptions made:  My hard drive is /dev/sda and the authorized_keys file is created in the step above.
```
sudo podman run \
--rm --privileged \
--pid=host \
-v /dev:/dev \
-v /var/lib/containers:/var/lib/containers \
-v ~/.ssh:/temp
--security-opt label=type:unconfined_t \
ghcr.io/ublue-os/cayo:10 \
bootc install to-disk /dev/sda --root-ssh-authorized-keys /temp/authorized_keys
```

#### Cayo:42 (Fedora) Install:
Assumptions made:  My hard drive is /dev/sda and the authorized_keys file is created in the step above.  __NOTE:  Fedora does not provide a default root filesystem type, so we must specify this manually as a bootc argument at install.__
```
sudo podman run \
--rm --privileged \
--pid=host \
-v /dev:/dev \
-v /var/lib/containers:/var/lib/containers \
-v ~/.ssh:/temp
--security-opt label=type:unconfined_t \
ghcr.io/ublue-os/cayo:42 \
bootc install to-disk /dev/sda --root-ssh-authorized-keys /temp/authorized_keys --filesystem xfs
```

## Common Issues
- __Podman install errors out with "out of space" issues.__  
Check that you've assigned enough RAM for the ramdisk, 8GB for Cayo:10, 12GB for Cayo:42
- __Cannot log in after installation.__  
Was the argument for --root-ssh-authorized-keys provided to the bootc command?
- __Install fails, unable to find --root-ssh-authorized-keys file.__
The path you provide to bootc is the path inside the container, not on the host ramdisk environment.  In the examples above, this was `/temp` which was mapped from `~/.ssh` in the ramdisk environment.

## Disclaimer
All information is provided as is from my own trial and error in my HomeLab as someone new to the project - the goal is to help other newcomers get up and running quickly and easily.  
Running HTTP servers locally without SSL is a security risk and should not be done in a production environment.