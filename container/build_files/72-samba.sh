set ${CI:+-x} -euo pipefail

# /*
# NOTE: THIS IS AN EXTENSION CANDIDATE
# */

# /*
### install samba support
# */
dnf -y install \
    samba \
    samba-usershares
