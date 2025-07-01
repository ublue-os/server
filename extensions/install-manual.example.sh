#!/bin/bash
set -euo pipefail
if [[ -n "$debug" ]]; then
  set -x
fi

if [[ "${UID}" == "0" ]]; then
  SUDO=""
else
  SUDO="sudo"
fi

cd rootfs

echo "➡️ Installing youki"
${SUDO} install -D -m 755 ../binaries/youki usr/bin/youki
${SUDO} install -D -m 644 ../binaries/LICENSE usr/share/licenses/youki/LICENSE

${SUDO} chown -R root: usr
