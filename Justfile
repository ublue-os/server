set unstable := true

just := just_executable()
podman := require('podman')
podman-remote := which('podman-remote') || podman + ' --remote'
builddir := shell('mkdir -p $1 && echo $1', absolute_path(env('CAYO_BUILD', 'build')))
image := "cayo"
variant := "base"
version := "10"
flavor := "main"

# Source Images

rechunker := shell("yq '.images.rechunker.source' images.yaml")
bootc-image-builder := shell("yq '.images.bootc-image-builder.source' images.yaml")

_default:
    @just --list --unsorted

podman-info:
    {{ podman }} info

[private]
PRIVKEY := env('HOME') / '.local/share/containers/podman/machine/machine'
[private]
PUBKEY := PRIVKEY + '.pub'
[private]
default-inputs := '
: ${image:=' + image + '}
: ${variant:=' + variant + '}
: ${version:=' + version + '}
: ${flavor:=' + flavor + '}
'
[private]
get-names := '''
just check-valid-image $image $variant $flavor $version

function image-get() {
    if [ -z "$1" ]; then
      echo "image-get: requires a key argument"
      exit 1
    fi
    KEY="${1}"
    data=$(IFS='' yq -Mr "explode(.)|.images|.$image-$variant-$flavor-$version|.$KEY" images.yaml)
    echo ${data}
}
source_image="$(image-get source)"
image_org="$(image-get org)"
image_registry="$(image-get registry)"
image_repo="$(image-get repo)"
image_name="$(image-get name)"
image_version="$(image-get version)"
image_description="$(image-get description)"
image_cpp_flags="$(image-get cppFlags[])"
'''
[private]
build-missing := '
cmd="' + just + ' build $image $variant $flavor $version"
if ! ' + podman + ' image exists "localhost/$image_name:$image_version"; then
    echo "' + style('warning') + 'Warning' + NORMAL + ': Container Does Not Exist..." >&2
    echo "' + style('warning') + 'Will Run' + NORMAL + ': ' + style('command') + '$cmd' + NORMAL + '" >&2
    seconds=5
    while [ $seconds -gt 0 ]; do
        printf "\rTime remaining: ' + style('error') + '%d' + NORMAL + ' seconds to cancel" $seconds >&2
        sleep 1
        (( seconds-- ))
    done
    echo "" >&2
    echo "' + style('warning') + 'Running' + NORMAL + ': ' + style('command') + '$cmd' + NORMAL + '" >&2
    $cmd
fi
'

[group('Utility')]
check-valid-image $image="" $variant="" $flavor="" $version="":
    #!/usr/bin/env bash
    set -e
    {{ default-inputs }}
    data=$(IFS='' yq -Mr "explode(.)|.images|.$image-$variant-$flavor-$version" images.yaml)
    if [[ "null" == "$data" ]]; then
        echo "ERROR Invalid inputs: no matching image definition found for: ${image}-${variant}-${flavor}-${version}"
        exit 1
    fi

[group('Utility')]
gen-tags $image="" $variant="" $flavor="" $version="":
    #!/usr/bin/env bash
    set -e
    {{ default-inputs }}
    {{ get-names }}
    # Generate Timestamp with incrementing version point
    TIMESTAMP="$(date +%Y%m%d)"
    #LIST_TAGS="$(mktemp)"
    # TODO: some work we can do here to check the version in the CentOS labels
    #while [[ ! -s "$LIST_TAGS" ]]; do
    #    skopeo list-tags docker://registry/$image_name > "$LIST_TAGS"
    #done
    #if [[ $(cat "$LIST_TAGS" | jq "any(.Tags[]; contains(\"$image_version-$TIMESTAMP\"))") == "true" ]]; then
    #    POINT="1"
    #    while $(cat "$LIST_TAGS" | jq -e "any(.Tags[]; contains(\"$image_version-$TIMESTAMP.$POINT\"))")
    #    do
    #        (( POINT++ ))
    #    done
    #fi

    if [[ -n "${POINT:-}" ]]; then
        TIMESTAMP="$TIMESTAMP.$POINT"
    fi

    # Add a sha tag for tracking builds during a pull request
    SHA_SHORT="$(git rev-parse --short HEAD)"

    # Define Versions
    COMMIT_TAGS=("$image_version" "$SHA_SHORT-$image_version")
    BUILD_TAGS=("$image_version" "$image_version-$TIMESTAMP")

    declare -A output
    output["BUILD_TAGS"]="${BUILD_TAGS[*]}"
    output["COMMIT_TAGS"]="${COMMIT_TAGS[*]}"
    output["TIMESTAMP"]="$TIMESTAMP"
    echo "${output[@]@K}"

# Check Just Syntax
[group('Just')]
check:
    #!/usr/bin/env bash
    find . -type f -name "*.just" | while read -r file; do
        echo "Checking syntax: $file" >&2
        {{ just }} --unstable --fmt --check -f $file
    done
    echo "Checking syntax: Justfile" >&2
    {{ just }} --unstable --fmt --check -f Justfile

# Fix Just Syntax
[group('Just')]
fix:
    #!/usr/bin/env bash
    find . -type f -name "*.just" | while read -r file; do
        echo "Checking syntax: $file" >&2
        {{ just }} --unstable --fmt -f $file
    done
    echo "Checking syntax: Justfile" >&2
    {{ just }} --unstable --fmt -f Justfile || { exit 1; }

# Run a Container

alias run := run-container

[group('Container')]
run-container $image="" $variant="" $flavor="" $version="":
    #!/usr/bin/env bash
    set -eou pipefail
    {{ default-inputs }}
    {{ get-names }}
    {{ build-missing }}
    echo "{{ style('warning') }}Running:{{ NORMAL }} {{ style('command') }}{{ just }} run -it --rm localhost/$image_name:$image_version bash -l {{ NORMAL }}"
    {{ podman }} run -it --rm "localhost/$image_name:$image_version" bash -l || exit 0

# Build a Container

alias build := build-container

[group('Container')]
build-container $image="" $variant="" $flavor="" $version="":
    #!/usr/bin/env bash
    set -xeou pipefail
    {{ default-inputs }}
    {{ just }} check-valid-image $image $variant $flavor $version
    {{ get-names }}
    # Verify Source: do after upstream starts signing images

    # Tags
    declare -A gen_tags="($({{ just }} gen-tags $image $variant $flavor $version))"
    if [[ "${github:-}" =~ pull_request ]]; then
        tags=(${gen_tags["COMMIT_TAGS"]})
    else
        tags=(${gen_tags["BUILD_TAGS"]})
    fi
    TIMESTAMP="${gen_tags["TIMESTAMP"]}"
    TAGS=()
    for tag in "${tags[@]}"; do
        TAGS+=("--tag" "localhost/$image_name:$tag")
    done

    # Pull akmods-zfs image with retry as we always need it for kernel and ZFS
    {{ podman }} pull --retry 3 "$image_registry/$image_org/akmods-zfs:centos-stream$version"

    # Labels
    IMAGE_VERSION="$image_version.$TIMESTAMP"
    KERNEL_VERSION="$(skopeo inspect containers-storage:$image_registry/$image_org/akmods-zfs:centos-stream$version | jq -r '.Labels["ostree.linux"]')"
    LABELS=(
        "--label" "containers.bootc=1"
        "--label" "io.artifacthub.package.deprecated=false"
        "--label" "io.artifacthub.package.keywords=bootc,centos,cayo,ublue,universal-blue"
        "--label" "io.artifacthub.package.logo-url=https://avatars.githubusercontent.com/u/120078124?s=200&v=4"
        "--label" "io.artifacthub.package.maintainers=[{\"name\": \"bsherman\", \"email\": \"benjamin@holyarmy.org\"}]"
        "--label" "io.artifacthub.package.readme-url=https://raw.githubusercontent.com/$image_registry/$image_org/$image_repo/main/README.md"
        "--label" "org.opencontainers.image.created=$(date -u +%Y\-%m\-%d\T%H\:%M\:%S\Z)"
        "--label" "org.opencontainers.image.description=$image_description"
        "--label" "org.opencontainers.image.license=Apache-2.0"
        "--label" "org.opencontainers.image.source=https://raw.githubusercontent.com/ublue-os/cayo/refs/heads/main/Containerfile.in"
        "--label" "org.opencontainers.image.title=$image_name"
        "--label" "org.opencontainers.image.url=https://github.com/$image_org/$image_repo"
        "--label" "org.opencontainers.image.vendor=$image_org"
        "--label" "org.opencontainers.image.version=${IMAGE_VERSION}"
        "--label" "ostree.linux=${KERNEL_VERSION}"
    )

    # BuildArgs
    BUILD_ARGS=(
        "--security-opt=label=disable"
        "--cap-add=all"
        "--device" "/dev/fuse"
        "--build-arg=IMAGE_VERSION=$IMAGE_VERSION"
        "--cpp-flag=-DSOURCE_IMAGE=$source_image"
        "--cpp-flag=-DZFS=$image_registry/$image_org/akmods-zfs:centos-stream$version"
    )
    for FLAG in $image_cpp_flags; do
        case "${FLAG:-}" in
        "NVIDIA")
            BUILD_ARGS+=("--cpp-flag=-D$FLAG=$image_registry/$image_org/akmods-nvidia:centos-stream$version")
            ;;
        *)
            BUILD_ARGS+=("--cpp-flag=-D$FLAG=1")
            ;;
        esac
    done

    # Pull source and akmods images with retry (akmods-zfs pulled above)
    {{ podman }} pull --retry 3 "$source_image"
    {{ if flavor == 'nvidia' { podman + ' pull --retry 3 "$image_registry/$image_org/akmods-nvidia:centos-stream$version"' } else { '' } }}

    # Build Image
    {{ podman }} build -f Containerfile.in "${BUILD_ARGS[@]}" "${LABELS[@]}" "${TAGS[@]}" .

# HHD-Dev Rechunk Image
hhd-rechunk $image="" $variant="" $flavor="" $version="":
    #!/usr/bin/env bash
    {{ default-inputs }}
    {{ just }} check-valid-image $image $variant $flavor $version
    {{ get-names }}
    mkdir -p {{ builddir / "$image_name" }}
    {{ if shell('id -u') != '0' { podman + ' unshare -- ' + just + ' hhd-rechunk $image $variant $flavor $version; exit $?' } else { '' } }}

    set -xeou pipefail

    # Labels
    VERSION="$({{ podman }} inspect localhost/$image_name:$version --format '{{{{ index .Config.Labels "org.opencontainers.image.version" }}')"
    LABELS="$({{ podman }} inspect localhost/$image_name:$version | jq -r '.[].Config.Labels | to_entries | map("\(.key)=\(.value|tostring)")|.[]')"
    CREF=$({{ podman }} create localhost/$image_name:$version bash)
    OUT_NAME="$image_name.tar"
    MOUNT="$({{ podman }} mount $CREF)"

    {{ podman }} pull --retry 3 "{{ rechunker }}"

    {{ podman }} run --rm \
        --security-opt label=disable \
        --volume "$MOUNT":/var/tree \
        --env TREE=/var/tree \
        --user 0:0 \
        {{ rechunker }} \
        /sources/rechunk/1_prune.sh

    {{ podman }} run --rm \
        --security-opt label=disable \
        --volume "$MOUNT":/var/tree \
        --volume "cache_ostree:/var/ostree" \
        --env TREE=/var/tree \
        --env REPO=/var/ostree/repo \
        --env RESET_TIMESTAMP=1 \
        --user 0:0 \
        {{ rechunker }} \
        /sources/rechunk/2_create.sh

    {{ podman }} unmount "$CREF"
    {{ podman }} rm "$CREF"
    {{ if env("CI", "") != "" { just + ' clean $image $variant $flavor $version localhost' } else { '' } }}

    {{ podman }} run --rm \
        --security-opt label=disable \
        --volume "{{ builddir / "$image_name" }}:/workspace" \
        --volume "{{ justfile_dir() }}:/var/git" \
        --volume cache_ostree:/var/ostree \
        --env REPO=/var/ostree/repo \
        --env PREV_REF="$image_registry/$image_org/$image_name:$version" \
        --env LABELS="$LABELS" \
        --env OUT_NAME="$OUT_NAME" \
        --env VERSION="$VERSION" \
        --env VERSION_FN=/workspace/version.txt \
        --env OUT_REF="oci-archive:$OUT_NAME" \
        --env GIT_DIR="/var/git" \
        --user 0:0 \
        {{ rechunker }} \
        /sources/rechunk/3_chunk.sh
    {{ podman }} volume rm cache_ostree
    {{ if env("CI", "") != "" { 'mv ' + builddir / '$image_name' / '$image_name.tar $image_name.tar ' } else { '' } }}

# Removes all Tags of an image from container storage.
[group('Utility')]
clean $image $variant $flavor $version $registry="":
    #!/usr/bin/env bash
    set -eou pipefail

    : "${registry:=localhost}"
    {{ get-names }}
    declare -a CLEAN="($({{ podman }} image list $registry/$image_name --noheading --format 'table {{{{ .ID }}' | uniq))"
    if [[ -n "${CLEAN[@]:-}" ]]; then
        {{ podman }} rmi -f "${CLEAN[@]}"
    fi

# Login to GHCR
[group('CI')]
@login-to-ghcr $user $token:
    echo "$token" | {{ podman }} login ghcr.io -u "$user" --password-stdin
    echo "$token" | docker login ghcr.io -u "$user" --password-stdin

# Push Images to Registry
[group('CI')]
push-to-registry $image $variant $flavor $version $destination="" $transport="":
    #!/usr/bin/bash
    set ${SET_X:+-x} -eou pipefail

    {{ default-inputs }}
    {{ get-names }}
    {{ build-missing }}

    : "${destination:=$image_registry/$image_org}"
    : "${transport:="docker://"}"

    declare -a TAGS="($({{ podman }} image list localhost/$image_name:$image_version --noheading --format 'table {{{{ .Tag }}'))"
    for tag in "${TAGS[@]}"; do
        for i in {1..5}; do
            {{ podman }} push "localhost/$image_name:$image_version" "$transport$destination/$image_name:$tag" 2>&1 && break || sleep $((5 * i));
        done

# Podmaon Machine Init
init-machine:
    #!/usr/bin/env bash
    set -ou pipefail
    {{ podman }} machine init \
        --rootful \
        --memory $(( 1024 * 8 )) \
        --volume "{{ justfile_dir() + ":" + justfile_dir() }}" \
        --volume "{{ env('HOME') + ":" + env('HOME') }}" 2>>{{ builddir }}/error.log
    ec=$?
    if [ $ec = 125 ] && ! grep -q 'VM already exists' {{ builddir }}/error.log; then
        printf '{{ style('error') }}Error:{{ NORMAL }} %s\n' "$(tail -n1 {{ builddir }}/error.log | sed -E 's/Error:\s//')" >&2
        exit $ec
    fi
    exit 0

# Start Podman Machine
start-machine: init-machine
    #!/usr/bin/env bash
    set -ou pipefail
    {{ podman }} machine start 2>>{{ builddir }}/error.log
    ec=$?
    if [ $ec = 125 ] && ! grep -q 'already running' {{ builddir }}/error.log; then
        printf '{{ style('error') }}Error:{{ NORMAL }} %s\n' "$(tail -n1 {{ builddir }}/error.log | sed -E 's/Error:\s//')" >&2
        exit $ec
    fi
    exit 0

build-disk $image="" $variant="" $flavor="" $version="" $registry="": start-machine
    #!/usr/bin/env bash
    {{ default-inputs }}
    : "${registry:=localhost}"
    {{ get-names }}
    set -eou pipefail
    # Create Build Dir
    mkdir -p {{ builddir }}/$image_name

    # Process Template
    cp iso_files/disk.toml {{ builddir }}/$image_name/disk.toml
    sed -i "s|<SSHPUBKEY>|$(cat {{ PUBKEY }})|" {{ builddir }}/$image_name/disk.toml

    # Load image into rootful podman-machine
    if ! {{ podman }} image exists $registry/$image_name:$version; then
        echo "{{ style('error') }}Error:{{ NORMAL }} Image \"$registry/$image_name:$version\" not in image-store" >&2
        exit 1
    fi
    if ! {{ podman-remote }} image exists $registry/$image_name:$version; then
        COPYTMP="$(mktemp -p {{ builddir }} -d -t podman_scp.XXXXXXXXXX)" && trap 'rm -rf $COPYTMP' EXIT SIGINT
        TMPDIR="$COPYTMP" {{ podman }} image scp $registry/$image_name:$version podman-machine-default-root::
        rm -rf "$COPYTMP"
    fi

    # Pull Bootc Image Builder
    {{ podman-remote }} pull --retry 3 {{ bootc-image-builder }}

    # Build Disk Image
    {{ podman-remote }} run \
        --rm \
        -it \
        --privileged \
        --pull=newer \
        --security-opt label=type:unconfined_t \
        -v {{ builddir }}/$image_name/disk.toml:/config.toml:ro \
        -v {{ builddir }}/$image_name:/output \
        -v /var/lib/containers/storage:/var/lib/containers/storage \
        quay.io/centos-bootc/bootc-image-builder:latest \
        {{ if env('CI', '') != '' { '--progress verbose' } else { '--progress term' } }} \
        --type qcow2 \
        --use-librepo=True \
        --rootfs xfs \
        $registry/$image_name:$version

run-disk $image="" $variant="" $flavor="" $version="" $registry="":
    #!/usr/bin/env bash
    {{ default-inputs }}
    : "${registry:=localhost}"
    {{ get-names }}
    set -ou pipefail
    if [ ! -f {{ builddir }}/$image_name/qcow2/disk.qcow2 ]; then
        echo "{{ style('error') }}Error:{{ NORMAL }} Disk Image \"$image_name\" not built" >&2 && exit 1
    fi

    {{ require('macadam') }} init \
        --ssh-identity-path {{ PRIVKEY }} \
        --username root 2>>{{ builddir }}/error.log \
        {{ builddir }}/$image_name/qcow2/disk.qcow2
    ec=$?
    if [ $ec = 125 ] && ! grep -q 'VM already exists' {{ builddir }}/error.log; then
        printf '{{ style('error') }}Error:{{ NORMAL }} %s\n' "$(tail -n1 {{ builddir }}/error.log | sed -E 's/Error:\s//')" >&2
    fi

    macadam start 2>>{{ builddir }}/error.log
    ec=$?
    if [ $ec = 125 ] && ! grep -q 'already running' {{ builddir }}/error.log; then
        printf '{{ style('error') }}Error:{{ NORMAL }} %s\n' "$(tail -n1 {{ builddir }}/error.log | sed -E 's/Error:\s//')" >&2
        printf '{{ style('error') }}Error:{{ NORMAL }} %s\n' "$(tail -n1 ${XDG_RUNTIME_DIR:-/run/user/$(id -u)}/macadam/gvproxy.log)" >&2
        exit $?
    fi
    macadam ssh -- cat /etc/os-release
    macadam ssh -- systemctl status
