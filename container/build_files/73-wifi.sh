set ${CI:+-x} -euo pipefail

# /*
# NOTE: THIS IS AN EXTENSION CANDIDATE
# */

# /*
### install wifi support
# */
dnf -y install \
    NetworkManager-wifi \
    atheros-firmware \
    brcmfmac-firmware \
    iwlegacy-firmware \
    iwlwifi-dvm-firmware \
    iwlwifi-mvm-firmware \
    mt7xxx-firmware \
    nxpwireless-firmware \
    realtek-firmware \
    tiwilink-firmware
