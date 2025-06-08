#!/usr/bin/env bash
set -xeuo pipefail

# disable repos by default
for R in docker-ce; do
  REPO="/etc/yum.repos.d/${R}.repo"
  if [ -f "${REPO}" ]; then
    sed -i "s@enabled=1@enabled=0@" "${REPO}"
  fi
done
