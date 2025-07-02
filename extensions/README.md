# Cayo Extensions

The extensions in the `/extensions` folder are the "official" extensions for Cayo. They are built with every Cayo release in CI, to ensure that they work.

## Extension Definitions

The extension build process is defined in the `extensions.yaml` file. Like the `images.yaml` file in the root, `extensions.yaml` uses anchors and aliases.

A hint to see the expanded contents:

> `yq -r "explode(.)|.extensions" extensions.yaml`

A minimal extension definition looks like this:

```yaml
vim-centos-10:
  description: "VIM Editor"
  name: vim
  packages:
    - vim
  image: "localhost/cayo:centos10"
```

A more complex definition looks like this:

```yaml
docker-ce-fedora-42:
  description: "Docker CE"
  name: docker-ce
  upholds:
    - "docker.socket"
  packages:
    - docker-ce
    - docker-ce-cli
    - containerd.io
    - docker-buildx-plugin
    - docker-compose-plugin
  files:
    - usr
  external_repos:
    - "https://download.docker.com/linux/fedora/docker-ce.repo"
  image: "localhost/cayo:fedora42"
```

### Field Definitions

TODO

## Build Process

`clean`:

`download-rpms`:

`download-manual`:

`version`:

`inputs`:

`setup-rootfs`:

`install-rpms`:

`install-files`:

`install-manual`:

`move-etc`:

`validate`:

`reset-selinux-labels`:

`build-erofs`:

## Building Locally


## Building in CI