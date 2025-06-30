set unstable := true

just := just_executable()
podman := require('podman')
podman-remote := which('podman-remote') || podman + ' --remote'
builddir := shell('mkdir -p $1 && echo $1', absolute_path(env('CAYO_BUILD', 'build')))
image := "cayo"
variant := env('CAYO_VARIANT', shell('yq ".defaults.variant" images.yaml'))
version := env('CAYO_VERSION', shell('yq ".defaults.version" images.yaml'))

# Source Images

rechunker := shell("yq '.images.rechunker.source' images.yaml")
bootc-image-builder := shell("yq '.images.bootc-image-builder.source' images.yaml")
qemu := shell("yq '.images.qemu.source' images.yaml")

_default:
    @just --list --unsorted

[private]
PRIVKEY := env('HOME') / '.local/share/containers/podman/machine/machine'
[private]
PUBKEY := PRIVKEY + '.pub'
[private]
default-inputs := '
: ${variant:=' + variant + '}
: ${version:=' + version + '}
'
[private]
get-names := just + ' check-valid-image $variant $version
function image-get() {
    if [ -z "$1" ]; then
      echo "image-get: requires a key argument"
      exit 1
    fi
    KEY="${1}"
    data=$(IFS="" yq -Mr "explode(.)|.images|.' + image + '-$variant-$version|.$KEY" images.yaml)
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
'
[private]
build-missing := '
cmd="' + just + ' build $variant $version"
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
[private]
logsum := '''
log_sum() { echo "$1" >> ${GITHUB_STEP_SUMMARY:-/dev/stdout}; }
log_sum "# Push to GHCR result"
log_sum "\`\`\`"
'''

[group('Utility')]
check-valid-image $variant="" $version="":
    #!/usr/bin/env bash
    set -e
    {{ default-inputs }}
    data=$(IFS='' yq -Mr "explode(.)|.images|.{{ image }}-$variant-$version" images.yaml)
    if [[ "null" == "$data" ]]; then
        echo "ERROR Invalid inputs: no matching image definition found for: {{ image }}-${variant}-${version}"
        exit 1
    fi

[group('Utility')]
gen-tags $variant="" $version="":
    #!/usr/bin/env bash
    {{ default-inputs }}
    {{ get-names }}
    set ${CI:+-x} -eou pipefail
    # Generate Timestamp with incrementing version point
    TIMESTAMP="$(date +%Y%m%d)"
    LIST_TAGS="$(mktemp)"
    while [[ ! -s "$LIST_TAGS" ]]; do
       skopeo list-tags docker://$image_registry/$image_org/$image_name > "$LIST_TAGS"
    done
    if [[ $(cat "$LIST_TAGS" | jq "any(.Tags[]; contains(\"$image_version-$TIMESTAMP\"))") == "true" ]]; then
       POINT="1"
       while $(cat "$LIST_TAGS" | jq -e "any(.Tags[]; contains(\"$image_version-$TIMESTAMP.$POINT\"))")
       do
           (( POINT++ ))
       done
    fi

    if [[ -n "${POINT:-}" ]]; then
        TIMESTAMP="$TIMESTAMP.$POINT"
    fi

    # Add a sha tag for tracking builds during a pull request
    SHA_SHORT="$(git rev-parse --short HEAD)"

    # Define Versions
    COMMIT_TAGS=()
    if [[ -n "{{ env('GITHUB_PR_NUMBER', '') }}" ]]; then
        COMMIT_TAGS=("$image_version" "pr-$image_version-$SHA_SHORT" "pr-$image_version-{{ env('GITHUB_PR_NUMBER', '') }}")
    fi
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
[no-exit-message]
run-container $variant="" $version="":
    #!/usr/bin/env bash
    set -eou pipefail
    {{ default-inputs }}
    {{ get-names }}
    {{ build-missing }}
    echo "{{ style('warning') }}Running:{{ NORMAL }} {{ style('command') }}{{ just }} run -it --rm localhost/$image_name:$image_version bash -l {{ NORMAL }}"
    {{ podman }} run -it --rm "localhost/$image_name:$image_version" bash -l

# Build a Container

alias build := build-container

[group('Container')]
build-container $variant="" $version="":
    #!/usr/bin/env bash
    {{ default-inputs }}
    {{ just }} check-valid-image $variant $version
    {{ get-names }}
    mkdir -p {{ builddir / '$variant-$version' }}
    set ${CI:+-x} -eou pipefail
    # Verify Source: do after upstream starts signing images

    # Tags
    declare -A gen_tags="($({{ just }} gen-tags $variant $version))"
    if [[ "{{ env('GITHUB_EVENT_NAME', '') }}" =~ pull_request ]]; then
        tags=(${gen_tags["COMMIT_TAGS"]})
    else
        tags=(${gen_tags["BUILD_TAGS"]})
    fi
    TIMESTAMP="${gen_tags["TIMESTAMP"]}"
    TAGS=()
    for tag in "${tags[@]}"; do
        TAGS+=("--tag" "localhost/$image_name:$tag")
    done
    AKMODS_ZFS_IMAGE=$(yq ".images.${image_name}-${variant}-${version}.zfs" images.yaml)

    # Pull akmods-zfs image with retry as we always need it for kernel and ZFS
    {{ podman }} pull --retry 3 $AKMODS_ZFS_IMAGE
    # Pull source and akmods images with retry
    {{ podman }} pull --retry 3 "$source_image"

    # Labels
    IMAGE_VERSION="$image_version.$TIMESTAMP"
    KERNEL_VERSION="$({{ podman }} inspect $AKMODS_ZFS_IMAGE --format '{{{{ index .Labels "ostree.linux" }}')"
    LABELS=(
        "--label" "containers.bootc=1"
        "--label" "io.artifacthub.package.deprecated=false"
        "--label" "io.artifacthub.package.keywords=bootc,cayo,centos,fedora,ublue,universal-blue"
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
    KERNEL_NAME="kernel"
    if [[ "$AKMODS_ZFS_IMAGE" =~ longterm ]];then
        KERNEL_NAME="kernel-longterm"
    fi

    # BuildArgs
    BUILD_ARGS=(
        "--security-opt=label=disable"
        "--cap-add=all"
        "--device" "/dev/fuse"
        "--cpp-flag=-DIMAGE_VERSION_ARG=IMAGE_VERSION=$IMAGE_VERSION"
        "--cpp-flag=-DKERNEL_NAME_ARG=KERNEL_NAME=$KERNEL_NAME"
        "--cpp-flag=-DSOURCE_IMAGE=$source_image"
        "--cpp-flag=-DZFS=$AKMODS_ZFS_IMAGE"
    )
    for FLAG in $image_cpp_flags; do
        BUILD_ARGS+=("--cpp-flag=-D$FLAG")
    done
    {{ if env('CI', '') != '' { 'BUILD_ARGS+=("--cpp-flag=-DCI_SETX")' } else { '' } }}

    # Render Containerfile
    flags=()
    for f in "${BUILD_ARGS[@]}"; do
        if [[ "$f" =~ cpp-flag ]]; then
            flags+=("${f#*flag=}")
        fi
    done
    {{ require('cpp') }} -E -traditional Containerfile.in ${flags[@]} > {{ builddir / '$variant-$version/Containerfile' }}
    labels="LABEL"
    for l in "${LABELS[@]}"; do
        if [[ "$l" != "--label" ]]; then
            labels+=" $(jq -R <<< "${l%%=*}")=$(jq -R <<< "${l#*=}")"
        fi
    done
    echo "$labels" >> {{ builddir / '$variant-$version/Containerfile' }}
    sed -i '/^$/d;/^#.*$/d' {{ builddir / '$variant-$version/Containerfile' }}

    # Build Image
    {{ podman }} build -f Containerfile.in "${BUILD_ARGS[@]}" "${LABELS[@]}" "${TAGS[@]}" {{ justfile_dir() }}

    ## Temporary HACK
    ## build samba extension
    cd extensions/samba
    just build localhost/cayo:42 x86_64

build-extension-container $variant="" $version="":
    #!/usr/bin/env bash
    {{ default-inputs }}
    {{ just }} check-valid-image $variant $version
    {{ get-names }}
    mkdir -p {{ builddir / '$variant-$version' }}
    set ${CI:+-x} -eou pipefail
    # Verify Source: do after upstream starts signing images

    # Tags
    declare -A gen_tags="($({{ just }} gen-tags $variant $version))"
    if [[ "{{ env('GITHUB_EVENT_NAME', '') }}" =~ pull_request ]]; then
        tags=(${gen_tags["COMMIT_TAGS"]})
    else
        tags=(${gen_tags["BUILD_TAGS"]})
    fi
    TIMESTAMP="${gen_tags["TIMESTAMP"]}"
    TAGS=()
    for tag in "${tags[@]}"; do
        TAGS+=("--tag" "localhost/$image_name:$tag")
    done
    AKMODS_ZFS_IMAGE=$(yq ".images.${image_name}-${variant}-${version}.zfs" images.yaml)

    # Pull akmods-zfs image with retry as we always need it for kernel and ZFS
    {{ podman }} pull --retry 3 $AKMODS_ZFS_IMAGE
    # Pull source and akmods images with retry
    {{ podman }} pull --retry 3 "$source_image"

    # Labels
    IMAGE_VERSION="$image_version.$TIMESTAMP"
    KERNEL_VERSION="$({{ podman }} inspect $AKMODS_ZFS_IMAGE --format '{{{{ index .Labels "ostree.linux" }}')"
    LABELS=(
        "--label" "containers.bootc=1"
        "--label" "io.artifacthub.package.deprecated=false"
        "--label" "io.artifacthub.package.keywords=bootc,cayo,centos,fedora,ublue,universal-blue"
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
    KERNEL_NAME="kernel"
    if [[ "$AKMODS_ZFS_IMAGE" =~ longterm ]];then
        KERNEL_NAME="kernel-longterm"
    fi

    # BuildArgs
    BUILD_ARGS=(
        "--security-opt=label=disable"
        "--cap-add=all"
        "--device" "/dev/fuse"
        "--cpp-flag=-DIMAGE_VERSION_ARG=IMAGE_VERSION=$IMAGE_VERSION"
        "--cpp-flag=-DKERNEL_NAME_ARG=KERNEL_NAME=$KERNEL_NAME"
        "--cpp-flag=-DSOURCE_IMAGE=$source_image"
        "--cpp-flag=-DZFS=$AKMODS_ZFS_IMAGE"
    )
    for FLAG in $image_cpp_flags; do
        BUILD_ARGS+=("--cpp-flag=-D$FLAG")
    done
    {{ if env('CI', '') != '' { 'BUILD_ARGS+=("--cpp-flag=-DCI_SETX")' } else { '' } }}

    # Render Containerfile
    flags=()
    for f in "${BUILD_ARGS[@]}"; do
        if [[ "$f" =~ cpp-flag ]]; then
            flags+=("${f#*flag=}")
        fi
    done
    {{ require('cpp') }} -E -traditional Containerfile.sysext.in ${flags[@]} > {{ builddir / '$variant-$version/Containerfile.sysext' }}
    labels="LABEL"
    for l in "${LABELS[@]}"; do
        if [[ "$l" != "--label" ]]; then
            labels+=" $(jq -R <<< "${l%%=*}")=$(jq -R <<< "${l#*=}")"
        fi
    done
    echo "$labels" >> {{ builddir / '$variant-$version/Containerfile.sysext' }}
    sed -i '/^$/d;/^#.*$/d' {{ builddir / '$variant-$version/Containerfile.sysext' }}

    # Build Image
    {{ podman }} build -f Containerfile.sysext.in "${BUILD_ARGS[@]}" "${LABELS[@]}" "${TAGS[@]}" {{ justfile_dir() }}



# HHD-Dev Rechunk Image
hhd-rechunk $variant="" $version="":
    #!/usr/bin/env bash
    {{ default-inputs }}
    {{ just }} check-valid-image $variant $version
    {{ get-names }}
    mkdir -p {{ builddir / '$variant-$version' }}
    {{ if shell('id -u') != '0' { podman + ' unshare -- ' + just + ' hhd-rechunk $variant $version; exit $?' } else { '' } }}

    set ${CI:+-x} -eou pipefail

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
    {{ if env("CI", "") != "" { just + ' clean $variant $version localhost' } else { '' } }}

    {{ podman }} run --rm \
        --security-opt label=disable \
        --volume "{{ builddir / '$variant-$version' }}:/workspace" \
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
    {{ if env("CI", "") != "" { 'mv ' + builddir / '$variant-$version/$image_name.tar ' + justfile_dir() / '$image_name.tar' } else { '' } }}

# Removes all Tags of an image from container storage.
[group('Utility')]
clean $variant $version $registry="":
    #!/usr/bin/env bash
    set -eou pipefail

    : "${registry:=localhost}"
    {{ get-names }}
    declare -a CLEAN="($({{ podman }} image list $registry/$image_name --noheading --format 'table {{{{ .ID }}' | uniq))"
    if [[ -n "${CLEAN[@]:-}" ]]; then
        {{ podman }} rmi -f "${CLEAN[@]}"
    fi

# Secureboot
secureboot variant="" version="":
    #!/usr/bin/bash
    {{ default-inputs }}
    {{ just }} check-valid-image $variant $version
    {{ get-names }}
    mkdir -p {{ builddir / '$variant-$version' }}
    cd {{ builddir / '$variant-$version' }}
    set ${CI:+-x} -euo pipefail
    kernel_release=$({{ podman }} inspect $image_name:$version --format '{{{{ index .Labels "ostree.linux" }}')
    TMP=$({{ podman }} create localhost/$image_name:$version bash)
    TMPDIR="$(mktemp -d -p .)"
    trap 'rm -rf $TMPDIR' SIGINT EXIT
    {{ podman }} cp "$TMP":/usr/lib/modules/${kernel_release}/vmlinuz $TMPDIR/vmlinuz
    {{ podman }} rm -f $TMP
    curl --retry 3 -Lo "$TMPDIR"/kernel-sign.der https://github.com/ublue-os/kernel-cache/raw/main/certs/public_key.der
    curl --retry 3 -Lo "$TMPDIR"/akmods.der https://github.com/ublue-os/kernel-cache/raw/main/certs/public_key_2.der
    openssl x509 -in "$TMPDIR"/kernel-sign.der -out "$TMPDIR"/kernel-sign.crt
    openssl x509 -in "$TMPDIR"/akmods.der -out "$TMPDIR"/akmods.crt
    sbverify --list $TMPDIR/vmlinuz
    if ! sbverify --cert "$TMPDIR/kernel-sign.crt" "$TMPDIR/vmlinuz" || ! sbverify --cert "$TMPDIR/akmods.crt" "$TMPDIR/vmlinuz"; then
        echo "Secureboot Signature Failed...."
        exit 1
    fi

# Login to GHCR
[group('CI')]
@login-to-ghcr:
    {{ podman }} login ghcr.io -u "$GITHUB_ACTOR"  -p "$GITHUB_TOKEN"

# Push Images to Registry
[group('CI')]
push-to-registry $variant="" $version="" $destination="" $transport="":
    #!/usr/bin/bash
    {{ if env('COSIGN_PRIVATE_KEY', '') != '' { 'printf "%s" "$COSIGN_PRIVATE_KEY" > /tmp/cosign.key' } else { '' } }}
    {{ if env('CI', '') != '' { logsum } else { '' } }}

    {{ default-inputs }}
    {{ get-names }}

    set ${CI:+-x} -eou pipefail

    : "${destination:=$image_registry/$image_org}"
    : "${transport:="docker://"}"

    declare -a TAGS=($({{ podman }} image list localhost/$image_name:$image_version --noheading --format 'table {{{{ .Tag }}'))
    for tag in "${TAGS[@]}"; do
        for i in {1..5}; do
            {{ podman }} push {{ if env('COSIGN_PRIVATE_KEY', '') != '' { '--sign-by-sigstore-private-key=/tmp/cosign.key --sign-passphrase-file=/dev/null' } else { '' } }} "localhost/$image_name:$image_version" "$transport$destination/$image_name:$tag" 2>&1 && break || sleep $((5 * i));
            if [[ $i -eq '5' ]]; then
                exit 1
            fi
        done
        {{ if env('CI', '') != '' { 'log_sum $destination/$image_name:$tag' } else { '' } }}
    done
    {{ if env('CI', '') != '' { 'log_sum "\`\`\`"' } else { '' } }}

# Podmaon Machine Init
init-machine:
    #!/usr/bin/env bash
    set -ou pipefail
    ram_size="$(( $(free --mega | awk '/^Mem:/{print $7}') / 2 ))"
    ram_size="$(( ram_size >= 16384 ? 16384 : $(( ram_size >= 8192 ? 8192 : $(( ram_size >= 4096 ? 4096 : $(( ram_size >= 2048 ? 2048 : $(( ram_size >= 1024 ? 1024 : 0 )) )) )) )) ))"
    {{ podman-remote }} machine init \
        --rootful \
        --memory "${ram_size}" \
        --volume "{{ justfile_dir() + ":" + justfile_dir() }}" \
        --volume "{{ env('HOME') + ":" + env('HOME') }}" 2>{{ builddir }}/error.log
    ec=$?
    if [ $ec != 0 ] && ! grep -q 'VM already exists' {{ builddir }}/error.log; then
        printf '{{ style('error') }}Error:{{ NORMAL }} %s\n' "$(sed -E 's/Error:\s//' {{ builddir }}/error.log)" >&2
        exit $ec
    fi
    exit 0

# Start Podman Machine
start-machine: init-machine
    #!/usr/bin/env bash
    set -ou pipefail
    {{ podman }} machine start 2>{{ builddir }}/error.log
    ec=$?
    if [ $ec != 0 ] && ! grep -q 'already running' {{ builddir }}/error.log; then
        printf '{{ style('error') }}Error:{{ NORMAL }} %s\n' "$(sed -E 's/Error:\s//' {{ builddir }}/error.log)" >&2
        exit $ec
    fi
    exit 0

build-disk $variant="" $version="" $registry="": start-machine
    #!/usr/bin/env bash
    {{ default-inputs }}
    : "${registry:=localhost}"
    {{ get-names }}
    fq_name="$registry/$image_name:$version"
    set -eou pipefail
    # Create Build Dir
    mkdir -p {{ builddir / '$variant-$version' }}

    # Process Template
    cp iso_files/disk.toml {{ builddir / '$variant-$version/disk.toml' }}
    sed -i "s|<SSHPUBKEY>|$(cat {{ PUBKEY }})|" {{ builddir / '$variant-$version/disk.toml' }}

    # Load image into rootful podman-machine
    if ! {{ podman-remote }} image exists $fq_name && ! {{ podman }} image exists $fq_name; then
        echo "{{ style('error') }}Error:{{ NORMAL }} Image \"$fq_name\" not in image-store" >&2
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
        -v {{ builddir / '$variant-$version' }}/disk.toml:/config.toml:ro \
        -v {{ builddir / '$variant-$version' }}:/output \
        -v /var/lib/containers/storage:/var/lib/containers/storage \
        quay.io/centos-bootc/bootc-image-builder:latest \
        {{ if env('CI', '') != '' { '--progress verbose' } else { '--progress auto' } }} \
        --type qcow2 \
        --use-librepo=True \
        --rootfs xfs \
        $fq_name

run-disk $variant="" $version="" $registry="":
    #!/usr/bin/env bash
    {{ default-inputs }}
    : "${registry:=localhost}"
    {{ get-names }}
    set -ou pipefail
    if [ ! -f {{ builddir / '$variant-$version/qcow2/disk.qcow2' }} ]; then
        echo "{{ style('error') }}Error:{{ NORMAL }} Disk Image \"$image_name-$version-$variant\" not built" >&2 && exit 1
    fi

    {{ require('macadam') }} init \
        --ssh-identity-path {{ PRIVKEY }} \
        --username root \
        {{ builddir / '$variant-$version/qcow2/disk.qcow2' }} 2> {{ builddir }}/error.log
    ec=$?
    if [ $ec != 0 ] && ! grep -q 'VM already exists' {{ builddir }}/error.log; then
        printf '{{ style('error') }}Error:{{ NORMAL }} %s\n' "$(sed -E 's/Error:\s//' {{ builddir }}/error.log)" >&2
    fi

    macadam start 2>{{ builddir }}/error.log
    ec=$?
    if [ $ec != 0 ] && ! grep -q 'already running' {{ builddir }}/error.log; then
        printf '{{ style('error') }}Error:{{ NORMAL }} %s\n' "$(sed -E 's/Error:\s//' {{ builddir }}/error.log)" >&2
        printf '{{ style('error') }}Error:{{ NORMAL }} %s\n' "$(tail -n1 ${XDG_RUNTIME_DIR:-/run/user/$(id -u)}/macadam/gvproxy.log)" >&2
        exit $?
    fi
    macadam ssh -- cat /etc/os-release
    macadam ssh -- systemctl status

build-iso $variant="" $version="" $registry="": start-machine
    #!/usr/bin/env bash
    {{ default-inputs }}
    : "${registry:=localhost}"
    {{ get-names }}
    fq_name="$registry/$image_name:$version"
    set -eou pipefail
    # Create Build Dir
    mkdir -p {{ builddir / '$variant-$version' }}

    # Process Template
    cp iso_files/iso.toml {{ builddir / '$variant-$version/iso.toml' }}
    sed -i "s|<URL>|$fq_name|" {{ builddir / '$variant-$version/iso.toml' }}
    if [[ $registry == "localhost" ]]; then
        sed -i "s|<SIGPOLICY>||" {{ builddir / '$variant-$version/iso.toml' }}
    else
        sed -i "s|<SIGPOLICY>| --enforce-container-sigpolicy|" {{ builddir / '$variant-$version/iso.toml' }}
    fi

    # Load image into rootful podman-machine
    if ! {{ podman-remote }} image exists $fq_name && ! {{ podman }} image exists $fq_name; then
        echo "{{ style('error') }}Error:{{ NORMAL }} Image \"$fq_name\" not in image-store" >&2
        exit 1
    fi
    if ! {{ podman-remote }} image exists $registry/$image_name:$version; then
        COPYTMP="$(mktemp -p {{ builddir }} -d -t podman_scp.XXXXXXXXXX)" && trap 'rm -rf $COPYTMP' EXIT SIGINT
        TMPDIR="$COPYTMP" {{ podman }} image scp $registry/$image_name:$version podman-machine-default-root::
        rm -rf "$COPYTMP"
    fi

    # Pull Bootc Image Builder
    {{ podman-remote }} pull --retry 3 {{ bootc-image-builder }}

    # Build ISO
    {{ podman-remote }} run \
        --rm \
        -it \
        --privileged \
        --pull=newer \
        --security-opt label=type:unconfined_t \
        -v {{ builddir / '$variant-$version/iso.toml' }}:/config.toml:ro \
        -v {{ builddir / '$variant-$version' }}:/output \
        -v /var/lib/containers/storage:/var/lib/containers/storage \
        quay.io/centos-bootc/bootc-image-builder:latest \
        {{ if env('CI', '') != '' { '--progress verbose' } else { '--progress auto' } }} \
        --type anaconda-iso \
        --use-librepo=True \
        $registry/$image_name:$version

run-iso $variant="" $version="":
    #!/usr/bin/env bash
    {{ default-inputs }}
    {{ get-names }}
    set -euo pipefail
    if [ ! -f {{ builddir / '$variant-$version/bootiso/install.iso' }} ]; then
        echo "{{ style('error') }}Error:{{ NORMAL }} Install ISO \"$image_name-$variant-$version\" not built" >&2 && exit 1
    fi
    # Determine an available port to use
    port=8006
    while grep -q :${port} <<< $(ss -tunalp); do
        port=$(( port + 1 ))
    done
    echo "Using Port: ${port}"
    echo "Connect to http://localhost:${port}"

    # Needs to be on the podman-machine due to dnsmasq requesting excessive UIDs/GIDs

    # Ram Size
    ram_size="$({{ podman-remote }} machine inspect | jq -r '.[].Resources.Memory')"
    ram_size="$(( ram_size / 2))"
    ram_size="$(( ram_size >= 8192 ? 8192 : $(( ram_size >= 4096 ? 4096 : $(( ram_size >= 2048 ? 2048 : $(( ram_size >= 1024 ? 1024 : 0 )) )) )) ))"
    if [ $ram_size = "0" ]; then
        echo "{{ style('error') }}Error:{{ NORMAL }} Not Enough Memory configured in podman machine" >&2 && exit 1
    fi

    # CPU Cores
    cpu_cores="$(( $({{ podman-remote }} machine inspect | jq -r '.[].Resources.CPUs') / 2 ))"
    cpu_cores="$(( cpu_cores > 0 ? cpu_cores : 1 ))"

    # Pull qemu container
    {{ podman-remote }} pull --retry 3 {{ qemu }}

    # Set up the arguments for running the VM
    run_args=()
    run_args+=(--rm)
    run_args+=(--publish "127.0.0.1:${port}:8006")
    run_args+=(--env "CPU_CORES=$cpu_cores")
    run_args+=(--env "RAM_SIZE=${ram_size}M")
    run_args+=(--env "DISK_SIZE=20G")
    run_args+=(--env "TPM=Y")
    run_args+=(--env "BOOT_MODE=windows_secure")
    run_args+=(--device=/dev/kvm)
    run_args+=(--device=/dev/net/tun)
    run_args+=(--cap-add NET_ADMIN)
    run_args+=(--volume "{{ builddir / '$variant-$version/bootiso/install.iso' }}":"/boot.iso")

    # Run the VM and open the browser to connect
    {{ podman-remote }} run "${run_args[@]}" {{ qemu }}

ext-targets:
    #!/usr/bin/env bash
    set -eou pipefail
    cd extensions/samba
    just targets
