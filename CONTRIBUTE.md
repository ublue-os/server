# Contribute to Cayo

## Tools
To build a Cayo image you need the following tools:
- bash
- cpp
- jq
- just
- podman
- skopeo
- yq

Additionally, the following tools are used as well for development/testing:
- macadam
- podman-machine
- sed

## Dev Container
To provide a consistent development environment that contains all of the necessary tools, the repo contains a `devcontainer.json`. [Dev Containers](https://containers.dev/) allows you to use a container as fully featured dev environment with all dependencies provided. To use the `devcontainer.json`, we recommend using [DevPod](https://devpod.sh/) (Available as a Flatpak, on Windows, and MacOS), [Devcontainers/CLI](https://github.com/devcontainers/cli) (Available in Brew/NPM), or through VSCode's [Remote Devcontainers Extension](https://code.visualstudio.com/docs/devcontainers/containers). Additionally, we recommend using `podman` as your container engine for running your Devcontainer; however, you can use `docker`. Within the Devcontainer, you will use `podman`, `docker` cannot be used to build the container image. DevPod is especially nice for allowing you to use any editor that supports remote development with SSH. Additionally, you have `dnf` within the devcontainer to use `vim` or your favorite terminal editor.

## Building Cayo

Building the image uses the `Justfile` with `just`.
```
> just build cayo
```
Will build the base Cayo image. You can provide the following parameters (in order) to `just build`:
- "image" (Always Cayo right now)
- "variant" (base and hci)
- "flavor" (main and nvidia)
- "version" (Currently only 10)
At any time you can pass an empty string to use the default value:
```
> just build "" hci "" 10
```
Will build a `cayo-hci:10` image.

## Testing Cayo
Please test your changes before submitting you PR. To support that, we provide the following convenience recipes to interact with your built Container Image.

### Container Testing
Often, the changes we are making do not require a fully running system. In this case, we can use `just run-container` to do a `podman run` of your Container Image. You will be dropped into bash shell inside the Container and will be able to inspect the filesystem. This is useful if you are adding a file, or making some other static change to the Image. When you exit the Container, `podman` will clean it up for you.

#### VM Testing
Other times, we need an actual running system in order to make sure the Image is working correctly. For this we use [Bootc Image Builder](https://osbuild.org/docs/bootc/) which can build a `qcow2`, `raw`, `iso`, and other formats. Since we are developing inside of Devcontainer (and using the recommended `podman` container engine), we do not have acces to they systems real root. Building a Container disk-image, requires the ability to create filesystems, partition disks, and other "real" root required tasks. To accomplish this, we use a `podman machine`. Podman has the ability to manage a well integrated `qemu` instance that `podman` can interact with `podman-remote` and `podman --remote`.

In our case, we use Bootc Image Builder to build a `qcow2` disk-image, that we can then boot using [macadam](https://github.com/crc-org/macadam/). To build a disk-image, first make sure you have built a container image.
```
> just build
```
Next, you can build the Disk Image with Bootc Image Builder:
```
> just build-disk
```
After building the disk you can set up a VM:
```
> just run-disk
```
You can connect to the VM after setting it up with `macadam`
```
> macadam ssh
```
`macadam` is derived from the same code base as `podman machine`. When you are done with the VM you can remove it with:
```
> macadam rm -f
```
Which will shutdown your VM and cleanup the management sockets it setup.

You should use a VM to test functions that require systemd and bootc directly.

## Developer Considerations
We use `cpp` to preprocess the Containerfile. `cpp` works by expanding C macros which are prefixed with a `#`. Unfortunately, `#` is the symbol for Comments in both the Containerfile and in Bash. Thus, we have to do the following.
1. Scripts that are included into the Containerfile using `#include` cannot have a Shebang line. This will throw a warning from `cpp`. Instead, we pass the heredoc to `bash` directly. Note, this method does allow you to pass to any scripting language, just do not include the Shebang. We recommend using ShellCheck for static analysis and have explicitly turned off Shebang checks in this repo because of this. You also do not need to set the executable bit for included scripts.
2. When using comments, you must wrap the comment with a C-style comment. `cpp` will remove this automatically in the final Containerfile. This also means that you cannot include comments that start with `#` in any file you heredoc into the container.
```
# /*
# My Comment is Here
# */
```
3. To view a rendered Containerfile, they are located under the `build/$image_name/Containerfile`
