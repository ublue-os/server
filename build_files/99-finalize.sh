# /*
#shellcheck disable=SC2114,SC2174
# */

set -eoux pipefail

# /*
# Cleanup /run/build_files
# */
rm -rf /run/build_files

# /*
# Make Sure /tmp and /var are in proper state
# */
rm -rf /tmp
rm -rf /var
mkdir -m 1777 /tmp
mkdir -m 1777 -p /var/tmp

ostree container commit
