#!/usr/bin/env bash

set -eoux pipefail
RELEASE="$(rpm -E %centos)"

### install packages direct from github
### NOTE: ARM support will require use of proper arch rather than hard coding
/ctx/github-release-install.sh rclone/rclone "linux-amd64"
/ctx/github-release-install.sh trapexit/mergerfs "el${RELEASE}.$(uname -m)"
