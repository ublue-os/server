#!/usr/bin/bash

set -eoux pipefail

dnf clean all
rm -rf /tmp/* || true

ostree container commit
