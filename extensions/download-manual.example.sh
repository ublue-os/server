#!/bin/bash
set -euo pipefail
if [[ -n "$debug" ]]; then
  set -x
fi

mkdir binaries
cd binaries

version="0.5.3" # TODO
if [[ "${arch}" == "x86_64" ]]; then
  sha256sum="173b8998cd0abf22e38e36611b34cc19a16431b353dd893e3d988cfc77b4e6ac"
else
  sha256sum="a15dfe9a1eec2d595b9a972a8a0fa1a919ee3d3523e77ca8c22099bfadf7e88d"
fi

echo "⬇️ Downloading youki"
curl --location --fail --output "youki-${version}-${arch}-gnu.tar.gz" \
  "https://github.com/youki-dev/youki/releases/download/v${version}/youki-${version}-${arch}-gnu.tar.gz"
echo "${sha256sum}  youki-${version}-${arch}-gnu.tar.gz" | sha256sum --check

# Version & metadata
echo "${version}" >../version
echo "${sha256sum} youki-${version}-${arch}-gnu.tar.gz" >../inputs

tar xf youki-${version}-${arch}-gnu.tar.gz
rm youki-${version}-${arch}-gnu.tar.gz README.md
