#!/bin/bash
set -euo pipefail

if [[ "${UID}" == "0" ]]; then
  SUDO=""
else
  SUDO="sudo"
fi

pwd
mkdir src && cd src

echo "➡️ building cockpit-zfs"
${SUDO} dnf install libzfs5-devel python3-devel -y
${SUDO} pip3 install Cython==0.29.35
${SUDO} git clone https://github.com/45Drives/python3-libzfs.git && cd python3-libzfs
