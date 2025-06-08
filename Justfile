set unstable

just := just_executable()
podman := require('podman')

_default:
    @just --list --unsorted

podman-info:
    {{ podman }} info

[private]
image-funcs:= '''
function image-get() {
    if [ -z "${1}" ]; then
      echo "image-get: requires a key argument"
      exit 1
    fi
    KEY="${1}"
    data=$(IFS='' yq -Mr "explode(.)|.images|.$image-$variant-$version-$flavor|.$KEY" images.yaml)
    echo ${data}
}
function image-local() {
    localImage="localhost/$(image-get name):$(image-get version)"
    echo ${localImage}
}
function image-remote() {
  remoteImage="$(image-get registry)/$(image-get org)/$(image-get name):$(image-get version)"
  echo ${remoteImage}
}
'''
[private]
pull-retry := '''
function pull-retry() {
    local target="$1"
    local retries=3
    trap "exit 1" SIGINT
    while [ $retries -gt 0 ]; do
        ' + PODMAN + ' pull $target && break
        (( retries-- ))
    done
    if ! (( retries )); then
        echo "' + style('error') +' Unable to pull ${target/@*/}...' + NORMAL +'" >&2
        exit 1
    fi
    trap - SIGINT
}
'''

[group('Utility')]
check-valid-image $image="server" $variant="base" $version="10" $flavor="main":
    #!/usr/bin/bash
    set -e
    {{ image-funcs }}
    imageName=$(image-get name)
    if [[ "null" == "$imageName" ]]; then
        echo "ERROR Invalid inputs: no matching image definition found for: ${image}-${variant}-${version}-${flavor}"
        exit 1
    fi

[group('Utility')]
gen-tags $image="server" $variant="base" $version="10" $flavor="main":
    #!/usr/bin/bash
    set -e

    # Generate Timestamp with incrementing version point
    TIMESTAMP="$(date +%Y%m%d)"
    #LIST_TAGS="$(mktemp)"
    # TODO: some work we can do here to check the version in the CentOS labels
    #while [[ ! -s "$LIST_TAGS" ]]; do
    #    skopeo list-tags docker://registry/$image_name > "$LIST_TAGS"
    #done
    #if [[ $(cat "$LIST_TAGS" | jq "any(.Tags[]; contains(\"$fedora_version-$TIMESTAMP\"))") == "true" ]]; then
    #    POINT="1"
    #    while $(cat "$LIST_TAGS" | jq -e "any(.Tags[]; contains(\"$fedora_version-$TIMESTAMP.$POINT\"))")
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
    COMMIT_TAGS=("$SHA_SHORT-$version")
    BUILD_TAGS=("${version}" "$version-$TIMESTAMP")

    COMMIT_TAGS+=("$SHA_SHORT-$version" "$version")
    BUILD_TAGS+=("$version" "$version-$TIMESTAMP")
    declare -A output
    output["BUILD_TAGS"]="${BUILD_TAGS[*]}"
    output["COMMIT_TAGS"]="${COMMIT_TAGS[*]}"
    output["TIMESTAMP"]="$TIMESTAMP"
    echo "${output[@]@K}"

# Build a Container
alias build := build-container
[group('Container')]
build-container $image="server" $variant="base" $version="10" $flavor="main":
    #!/usr/bin/bash
    set -x -e

    {{ just }} check-valid-image $image $variant $version $flavor

    {{ image-funcs }}

    # Verify Source: do after upstream starts signing images

    # Tags
    declare -A gen_tags="($({{ just }} gen-tags $image $variant $version $flavor))"
    if [[ "${github:-}" =~ pull_request ]]; then
        tags=(${gen_tags["COMMIT_TAGS"]})
    else
        tags=(${gen_tags["BUILD_TAGS"]})
    fi
    TIMESTAMP="${gen_tags["TIMESTAMP"]}"
    TAGS=()
    for tag in "${tags[@]}"; do
        TAGS+=("--tag" "localhost/$(image-get name):$tag")
    done

    # Labels
    VERSION="$version.$TIMESTAMP"
    #KERNEL_VERSION= TODO may need to inspect the container contents for this
    LABELS=(
        "--label" "org.opencontainers.image.title=$(image-get name)"
        "--label" "org.opencontainers.image.version=${VERSION}"
        "--label" "org.opencontainers.image.description=$(image-get description)"
        #"--label" "ostree.linux=${KERNEL_VERSION}"
        "--label" "io.artifacthub.package.readme-url=https://raw.githubusercontent.com/$(image-get registry)/$(image-get org)/$(image-get repo)/main/README.md"
        "--label" "io.artifacthub.package.logo-url=https://avatars.githubusercontent.com/u/120078124?s=200&v=4"
    )

    # BuildArgs
    BUILD_ARGS=(
        "--security-opt=label=disable"
        "--cap-add=all"
        "--device" "/dev/fuse"
        "--cpp-flag=-DSOURCE_IMAGE=$(image-get from)"
    )
    for FLAG in $(image-get "cppFlags[]"); do
        BUILD_ARGS+=("--cpp-flag=-D$FLAG=1")
    done

    # Build Image
    {{ podman }} build -f Containerfile.in "${BUILD_ARGS[@]}" "${LABELS[@]}" "${TAGS[@]}" .

