set ${CI:+-x} -euo pipefail

# /*
# NOTE: THIS IS AN EXTENSION CANDIDATE
# */

# /*
### install intel container support
# */
dnf -y install \
    intel-compute-runtime
