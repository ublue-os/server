# Cayo: a Universal Blue server project

Welcome to our work in progress!

## Overview

This will be a server image similar to [uCore](https://github.com/ublue-os/ucore) but based on CentOS bootc.

Similarities to uCore:

- bootc/rpm-ostree "immutable" rootfs (CoreOS itself is now built on bootc)
- three basic offerings will remain: "light-ish", "NAS" and "HCI"(NAS+virt)
- opinionated, likely including all the same common tools we had in uCore
- auto-update capabilities

Differences from uCore:

- built on bootc not CoreOS
- built on EL (Enterprise Linux, eg CentOS) not Fedora
- installation via [existing bootc install methods](https://docs.fedoraproject.org/en-US/bootc/bare-metal/) rather than coreos-install+butane/ignition

The most noticeable difference for most users will be:

- a slower pace of updates on packages and kernel, owing to the use of an EL base
- a different way to install

## CI/Build Changes

As time goes on and our projects have evolved, our build scripts have gotten more powerful, but also more difficult to read.

Our hope here is to use this project to experiment with ways of building our images which are easier to follow, both for existing maintainers and any other interested party.

The primary goal here: **we want to grok the build process without having to study so many parts**.

How we'll do this:

1. use a YAML file to define the set of images and all key "static" inputs required for a build (some tags and labels are generated or inspected)
2. use `just` recipies to manage the build related functions, providing same local build commands as used in CI
3. use Podman's native C preprocssor(CPP) support for flow control not otherwise available in a Containerfile
4. use devcontainer for a consistent build environment both locally and in CI


The YAML uses anchors and aliases. A hint to see the expanded contents:

> `yq -r "explode(.)|.images" images.yaml`


The Justfile is still a bit complicated but reading image information from YAML is cleaner than more complicated bash arrays it previously used.

The CPP conditional logic in the Containerfile provides several benefits.
- we removed a layer of abstraction, no longer using a single "build.sh" which in turn calls different scripts conditionally based on build-args
- we need VERY few podman build-args
- we regain the typical "podman build" behavior of caching each successful layer of an image build, which greatly improves speed of development


## About the Name

"Cayo" (KYE-oh) comes from "key" or "reef" in Spanish—think a solid foundation and unlocking potential.

Conceptually, the "key" unlocks possibilities, and hints at islands that open up new horizons. "Reef" evokes a resilient, interconnected chain—strong and foundational, like a reef hosting diverse organisms. This fits the idea of a server hosting many services, which Cayo achieves through the stability and strength of an Enterprise Linux base hosting containerized applications.

