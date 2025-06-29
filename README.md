# Cayo: a Universal Blue server project

*This project is a work in progress!*

Cayo is a Linux server system intended for container and storage workloads  using included tools like Podman and ZFS. It is suitable for installation on bare metal or virtual machines, and Cockpit provides easy management. Extensions optionally provide features such as Docker CE, NVIDIA drivers, WiFi support, Samba and Virtual Machine hosting with libvirt. Cayo is a bootc image built on the solid foundations of CentOS and Fedora.

## Quick Summary

This project builds a server image similar to [uCore](https://github.com/ublue-os/ucore) but based on bootc images provided by CentOS and Fedora.

Similarities to uCore:

- bootc/rpm-ostree "immutable" rootfs (CoreOS itself is now built on bootc)
- opinionated, includs many of the common tools found in uCore
- auto-update capabilities

Differences from uCore:

- built on bootc not CoreOS
- built on CentOS with it's default longterm kernel or Fedora with a longterm kernel, both currently are version 6.12
- installation via [existing bootc install methods](https://docs.fedoraproject.org/en-US/bootc/bare-metal/) or an Anaconda ISO rather than coreos-install with required butane/ignition
- features will be provided as system extensions (systemd sysext) instead of via various images with tags (eg, minimal, hci and nvidia)

The most noticeable difference for most users will be:

- new/different ways to install
- a slower pace of updates for the kernel
- if using CentOS-based Cayo, system packages will also be updated at a slower pace

## New Ideas in CI and Development Processes

As time goes on and Universal Blue projects have evolved, our build scripts have gotten more powerful, but also more difficult to read.

*A major goal with Cayo is to create new, healthier patterns for building Universal Blue images.* We want tooling which is easy to follow, both for existing maintainers and any other interested party. Enabling local developement and testing is a high priority, and doing this right means our GitHub Actions workflows can be very simple.

How we are improving our CI and Dev:

1. use a `images.yaml` file to define the set of images and all key "static" inputs required for a build (some tags and labels are generated or inspected)
2. use `just` recipies to manage the build related functions, providing same local build commands as used in CI
3. use Podman's native C preprocssor(CPP) support for flow control not otherwise available in a Containerfile
4. use devcontainer for a consistent build environment both locally and in CI

`images.yaml` uses anchors and aliases. A hint to see the expanded contents:

> `yq -r "explode(.)|.images" images.yaml`

The Justfile may still seem a bit complicated but reading image information from YAML is cleaner than the bash arrays previously used in other repos.

The CPP conditional logic in the Containerfile provides several benefits.

- we removed a layer of abstraction, no longer using a single "build.sh" which in turn calls different scripts conditionally based on build-args
- we need VERY few podman build-args
- we regain the typical "podman build" behavior of caching each successful layer of an image build, which greatly improves speed of development

*Another goal is to make installing and using Cayo better than its sibling, uCore.*

- choosing which image to install should be simple, only have to choose Cayo based on Fedora or CentOS
- we will ship only a single image `cayo` rather than three as in uCore (well two, based on CentOS and Fedora)
  - we will use systemd sysext to provide the features which previously required multiple images
  - we can ship *fewer packages* in the `cayo` image but have *more features* because of this approach
  - an example of more features: we'll ship both nvidia-proprietary (support Maxwell/Pascal but not the latest GPUs) plus nvidia-open (support Turing and later GPUs) rather than a single nvidia driver variant in uCore, but enabling this will be less hassle than switching to a completely different image
  - an example of fewer packages: wifi support (firmwares and other packages) are moving to an extension so that's not wasted space on any machine without wifi
- we will ship an ISO installer
  - a common request for uCore was a way to install other than the official CoreOS methods, we can do this with Cayo as we are not tied to the CoreOS paradigms
  - bootc-image-builder provides easy access to this
- we will ship qcow2 images, etc
  - previously we did not have a way to build native uCore VM disk images, bootc-image-builder provides this capability for bootc images like Cayo
- ZFS is included by default
  - yes, this change was recently made in uCore as well, but ZFS is a powerful tool core to the Cayo experience
- system configuration tools will be included
  - ignition is powerful, but not every wants it, so it's not required
  - ignition MAY still be used, though!
  - we also plan to include cloud-init as alternative (pending testing and validation)
- longterm release kernels (both on CentOS and Fedora) provide  confidence that updates will not render a system unusable due to  kernel regression

## About the Name

"Cayo" (KYE-oh) comes from "key" or "reef" in Spanish—think a solid foundation and unlocking potential.

Conceptually, the "key" unlocks possibilities, and hints at islands that open up new horizons. "Reef" evokes a resilient, interconnected chain—strong and foundational, like a reef hosting diverse organisms. This fits the idea of a server hosting many services, which Cayo achieves through the capabilities and strength of proven technologies like Podman and ZFS, built upon a solid base provided by the CentOS and Fedora projects.
