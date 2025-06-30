# Contribute to Cayo

We welcome your contribution! But what does it mean to contribute?

Often it seems like writing code is the only way to contribute to an open source project, but there are many more ways.

The first way, **install and use Cayo!**

Next, **please provide feedback!** We want to hear about any issues you experience, but it is also great to hear success stories!

Where can feedback be provided?

- [GitHub issues](https://github.com/ublue-os/cayo/issues)
- [Discourse forums, look for the Cayo/uCore category](https://universal-blue.discourse.group/)
- [Discord chat, join the #cayo-server channel (select Cayo/uCore Server users)](https://discord.gg/WEu6BdFEtp)

**Help others.** Yep, it is incredibly helpful when users of a project answer questions posed by other users. This can be done in same locations above.

Beyond the above we also welcome contributions to this GitHub repository. This can generally be:

- adding or editing documentation
- code development

These are covered with more detail below.

## Documentation

Docs. You're reading one right now.

As the project is new, we don't have much here yet, but you could change that.

Here are links which can help learn to write better docs:
- https://justsimply.dev/
- https://kubernetes.io/docs/contribute/style/style-guide/

Also, we use [Conventional Commits](https://www.conventionalcommits.org/) even for documentation.
The most relevant thing here for docs contributors, please start your commit message something like:

```
docs: corrected typo on foo FAQ entry
```

Before making significant changes to something which already exists, please discuss first, either in a GitHub issue,
(create one if it's a new idea/question) or chat with the team in Discord.

## Code Development

The same documentation and Conventional Commits links from above apply to code contributors. 

Definitely discuss any potential significant changes with the team, either in GitHub or Discord, before starting. Better communication up front leads to better interactions and a more welcome response to contributed code.

For example, don't simply create a PR with a bugfix, first check if a bug already has an issue filed, create an issue if it does not. Offer to fix in the initial description or comments as other contributors reply. This helps avoid duplicated efforts and rejected pull requests.

### Tools to Build/Develop
To build a Cayo image you need the following tools:
- bash
- cpp
- jq
- just
- podman
- skopeo
- yq

Additionally, the following tools are used for development/testing:
- macadam
- podman-machine
- sed

### Dev Container
To provide a consistent development environment that contains all of the necessary tools, the repo contains a `devcontainer.json`. [Dev Containers](https://containers.dev/) allows you to use a container as fully featured dev environment with all dependencies provided. To use the `devcontainer.json`, we recommend using [DevPod](https://devpod.sh/) (Available as a Flatpak, on Windows, and MacOS), [Devcontainers/CLI](https://github.com/devcontainers/cli) (Available in Brew/NPM), or through VSCode's [Remote Devcontainers Extension](https://code.visualstudio.com/docs/devcontainers/containers). Additionally, we recommend using `podman` as your container engine for running your Devcontainer; however, you can use `docker`. Within the Devcontainer, you will use `podman`, `docker` cannot be used to build the container image. DevPod is especially nice for allowing you to use any editor that supports remote development with SSH. Additionally, you have `dnf` within the devcontainer to use `vim` or your favorite terminal editor.

### Building Cayo

Cayo uses `just` with recipes defined in the `Justfile` to build and test images. The starting recipe is:

```bash
just build cayo
```
Which will build the base Cayo image. Several of the recipes accept parameters. For `just build` the following parameters (in order):

- "variant" (centos and fedora)
- "version" (10 and 42, current centos and fedora versions)

At any time you can pass an empty string `""` to use the default value for that parameter:
```bash
just build fedora 42
```
This will build a `cayo:42` image from Fedora 42, which is the default of `just build`.

```bash
just build centos 10
```
Which will build a `cayo:10` image from CentOS 10.


To see what the available recipes are and their parameters just run:
```bash
just
```
To get an overview of what's available. Reminder, parameters in `just` are positional and do not have a key/value pair on the commandline.

### Testing Cayo
Currently, Cayo's CI pipeline builds images in each PR. However, you can test locally before submitting your PR. There are two primary methods for doing local testing: Container Testing and VM Testing.

#### Container Testing
Often, the changes we are making do not require a fully running system. In this case, we can use `just run-container` to do a `podman run` of your Container Image. You will be dropped into bash shell inside the Container and will be able to inspect the filesystem. This is useful if you are adding a file, or making some other static change to the Image. When you exit the Container, `podman` will clean it up for you.
```bash
just run-container
```
If your target container does not already exist in the image store, it will autobuild first.

#### VM Testing
Other times, we need an actual running system in order to make sure the Image is working correctly. For this we use [Bootc Image Builder](https://osbuild.org/docs/bootc/) which can build a `qcow2`, `raw`, `iso`, and other formats. Since we are developing inside of Devcontainer (and using the recommended `podman` container engine), we do not have access to the system's real root. Building a Container disk-image requires the ability to create filesystems, partition disks, and other "real" root required tasks. To accomplish this, we use a `podman machine`. Podman has the ability to manage a well-integrated `qemu` instance that `podman` can interact with `podman-remote` and `podman --remote`.

In our case, we use Bootc Image Builder to build a `qcow2` disk-image, that we can then boot using [macadam](https://github.com/crc-org/macadam/). To build a disk-image, first make sure you have built a container image.
```bash
just build
```
Next, you can build the Disk Image with Bootc Image Builder and set up a vm with `macadam`:
```bash
just build-disk
just run-disk
```
You can connect to the VM after setting it up with `macadam`
```bash
macadam ssh
```
When you are done with your VM you can use the following to shutdown and cleanup the connection sockets.
```bash
macadam rm -f
```
You should use a VM to test functions that require systemd and bootc directly.

### Developer Considerations
We use `cpp` to preprocess the Containerfile. `podman` and `buildah` both have direct support for using `cpp` on template files. Since it is built-in, we use `cpp` for handling some flow-control. Much like a C project can have conditional includes, we can do the same with our Containerfile. `cpp` works by expanding C macros which are prefixed with a `#`. Unfortunately, `#` is the symbol for Comments in both the Containerfile and in Bash. Thus, we have to do the following.
1. Scripts that are included into the Containerfile using `#include` cannot have a Shebang line. This will throw a warning from `cpp`. Instead, we pass the heredoc to `bash` directly. Note, this method does allow you to pass to any scripting language, just do not include the Shebang. We recommend using ShellCheck for static analysis and have explicitly turned off Shebang checks in this repo because of this. You also do not need to set the executable bit for included scripts.
2. When using comments, you must wrap the comment with a C-style comment. `cpp` will remove this automatically in the final Containerfile. This also means that you cannot include comments that start with `#` in any file you heredoc into the container.
```
# /*
# My Comment is Here
# */
```
3. To view a rendered Containerfile, they are located under the `build/$variant-$version/Containerfile`
