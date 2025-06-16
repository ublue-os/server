set unstable := true

just := just_executable()
podman := require('podman')

_default:
    @just --list --unsorted

podman-info:
    {{ podman }} info

[private]
default-inputs := '
: ${image:=server}
: ${variant:=base}
: ${version:=10}
: ${flavor:=main}
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
image_registry="$(image-get registry)/$(image-get org)"
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
[private]
pull-retry := '
function pull-retry() {
    local target="$1"
    local retries=3
    trap "exit 1" SIGINT
    while [ $retries -gt 0 ]; do
        ' + podman + ' pull $target && break
        (( retries-- ))
    done
    if ! (( retries )); then
        echo "' + style('error') + ' Unable to pull ${target/@*/}...' + NORMAL + '" >&2
        exit 1
    fi
    trap - SIGINT
}
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
    echo "{{ style('warning') }}Running:{{ NORMAL }} {{ style('command') }}{{ just }} run -it --rm localhost/$image_name:$image_version bash {{ NORMAL }}"
    {{ podman }} run -it --rm "localhost/$image_name:$image_version" bash || exit 0

# Build a Container

alias build := build-container

[group('Container')]
build-container $image="" $variant="" $flavor="" $version="":
    #!/usr/bin/env bash
    set -xeou pipefail
    {{ default-inputs }}
    {{ just }} check-valid-image $image $variant $flavor $version
    {{ get-names }}
    {{ pull-retry }}
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

    # Labels
    VERSION="$image_version.$TIMESTAMP"
    #KERNEL_VERSION= TODO may need to inspect the container contents for this
    LABELS=(
        "--label" "org.opencontainers.image.title=$image_name"
        "--label" "org.opencontainers.image.version=${VERSION}"
        "--label" "org.opencontainers.image.description=$image_description"
        #"--label" "ostree.linux=${KERNEL_VERSION}"
        "--label" "io.artifacthub.package.readme-url=https://raw.githubusercontent.com/$image_registry/$image_repo/main/README.md"
        "--label" "io.artifacthub.package.logo-url=https://avatars.githubusercontent.com/u/120078124?s=200&v=4"
    )

    # BuildArgs
    BUILD_ARGS=(
        "--security-opt=label=disable"
        "--cap-add=all"
        "--device" "/dev/fuse"
        "--cpp-flag=-DSOURCE_IMAGE=$source_image"
        "--cpp-flag=-DZFS=$image_registry/akmods-zfs:centos-stream$version"
    )
    for FLAG in $image_cpp_flags; do
        case "${FLAG:-}" in
        "NVIDIA")
            BUILD_ARGS+=("--cpp-flag=-D$FLAG=$image_registry/akmods-nvidia:centos-stream$version")
            ;;
        *)
            BUILD_ARGS+=("--cpp-flag=-D$FLAG=1")
            ;;
        esac
    done

    # Pull Images with retry
    pull-retry "$source_image"
    pull-retry "$image_registry/akmods-zfs:centos-stream$version"
    {{ if flavor == 'nvidia' { 'pull-retry "$image_registry/akmods-nvidia:centos-stream$version"
' } else { '' } }}
    # Build Image
    {{ podman }} build -f Containerfile.in "${BUILD_ARGS[@]}" "${LABELS[@]}" "${TAGS[@]}" .

# Removes all Tags of an image from container storage.
[group('Utility')]
clean $image $variant $flavor $version $registry="":
    #!/usr/bin/env bash
    set -xeou pipefail

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

    : "${destination:=$image_registry}"
    : "${transport:="docker://"}"

    declare -a TAGS="($({{ podman }} image list localhost/$image_name:$image_version --noheading --format 'table {{{{ .Tag }}'))"
    for tag in "${TAGS[@]}"; do
        for i in {1..5}; do
            {{ podman }} push "localhost/$image_name:$image_version" "$transport$destination/$image_name:$tag" 2>&1 && break || sleep $((5 * i));
        done
