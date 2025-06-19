set -eoux pipefail

# /*
### OS Release
# set variant and url for unique identification
# */
sed -i 's|^HOME_URL=.*|HOME_URL="https://projectcayo.org"|' /usr/lib/os-release
echo 'VARIANT="Cayo"' >>/usr/lib/os-release
echo 'VARIANT_ID="cayo"' >>/usr/lib/os-release
# /*
# if VARIANT ever gets added to CentOS we'll need these instead
#sed -i 's|^VARIANT=.*|VARIANT="Cayo"|' /usr/lib/os-release
#sed -i 's|^VARIANT_ID=.*|VARIANT_ID="cayo"|' /usr/lib/os-release
# */

# /*
# set pretty name for base image
# */
SOURCE_VERSION="$(grep ^VERSION_ID= /usr/lib/os-release | cut -f2 -d= | tr -d \")"
SOURCE_NAME="$(grep ^NAME= /usr/lib/os-release | cut -f2 -d= | tr -d \")"
sed -i "s|^PRETTY_NAME=.*|PRETTY_NAME=\"Cayo (Version $IMAGE_VERSION / FROM $SOURCE_NAME $SOURCE_VERSION)\"|" /usr/lib/os-release

# /*
# AKMODS certificate
# */
mkdir -p /etc/pki/akmods/certs
cat >/etc/pki/akmods/certs/akmods-ublue.pem <<'EOF'
-----BEGIN CERTIFICATE-----
MIIFtjCCA56gAwIBAgIUffh69d7nONn6wvijghk3S+ChgKcwDQYJKoZIhvcNAQEL
BQAwdTEXMBUGA1UECgwOVW5pdmVyc2FsIEJsdWUxFzAVBgNVBAsMDmtlcm5lbCBz
aWduaW5nMRUwEwYDVQQDDAx1Ymx1ZSBrZXJuZWwxKjAoBgkqhkiG9w0BCQEWG3Nl
Y3VyaXR5QHVuaXZlcnNhbC1ibHVlLm9yZzAgFw0yNDA3MTEwMzA3MDlaGA8yMTI0
MDYxNzAzMDcwOVowdTEXMBUGA1UECgwOVW5pdmVyc2FsIEJsdWUxFzAVBgNVBAsM
Dmtlcm5lbCBzaWduaW5nMRUwEwYDVQQDDAx1Ymx1ZSBrZXJuZWwxKjAoBgkqhkiG
9w0BCQEWG3NlY3VyaXR5QHVuaXZlcnNhbC1ibHVlLm9yZzCCAiIwDQYJKoZIhvcN
AQEBBQADggIPADCCAgoCggIBAJrjC/NmzXRnUWisoRu8vUKr8jq7QqlYWVSdT2jv
suA9qyQ/GKBg5A7kBV+XpKJCV1M7QkiUvQ7nn2pAYZAjWbRABBcoHlN1eFg7wTVP
1C+wV5mdsXO/fBs896GCRcI2Na+HJQ3o2m8PdCWGzgOYJCe9zHIwdbm6mPjgw56p
Ic50c7OHqU3qFsFZTXrJkq/cvyyr+Ue6j4JcJERm1IVMktRJ6nZ7NmmWjYTGSlBQ
l9YIT2DktSzihxM9f23R1RujdFmy6I6pMwSB3F4ehhFWlgvZa1/AGaXg7dE06RwT
8A5U+fb3iV/V66JaisiL8rISvmY7a5LMRMGRNlVF54JeF08N/w/ylOQb6cSE6H6U
g60hn2sbFy0S7rHQKXb8ZA5Y59na4EfLRnGGJQDWT+znsBTkJ730GvrbWzA1Hfzw
azeHQXSzyWf3h+d7tRM9DwjGz3RZ4YNQuttD3NcBBo/x8QZtOjbJGmPNg3k1OQ6m
0nSBCf7lbtD9KMoGfAf2hF0y+Pw43AARhJyhrzzIvhUYXtj/jPn+qQa7x+h/LBqd
RVXqYRTnDddqM8OW8/m2oNRWAAqfrCxfNZjD5x1/1trzuw4flLM4xMxEele8x0d1
rLoAfUIWU0FjWIJF1mCtrpXKNtfSpAyXylxzGTADGPAW+JrALu5/nVZGq8aBtQJO
Slp7AgMBAAGjPDA6MAwGA1UdEwEB/wQCMAAwCwYDVR0PBAQDAgeAMB0GA1UdDgQW
BBQsJQYVWLUCDEsNnKVgYuAMbNsEajANBgkqhkiG9w0BAQsFAAOCAgEAUp+arzHK
6qsFtCL++BSJCManvz9tb5IwiqQXyQgh2XmOcALh/JN63evdc2/ECdBBD9qO/0H+
a8u59A9C4EqghKFtTsb50vbMgJe/naAxuWU98oT9eqnAMnHJnr4FWY5rGP3hbxbt
51h5nUmcX5dpgOfFmu3bPpPYii9Ky/wN/KGAQBB7eOErbwRZHVFBtlKdN9Vz1UH0
LVa1LyPyz8F60Yfjz0waQxm7T0Idx74yCJbb1PX/1s71FHSOqSlFFycYsN5bBbS8
DPTThxjcQjMpRHR+hhW6vPVflphRExGtBY3FP/rOZbWS+LlEJlWmkBD8WPMbt71f
DSpf3R9St7NJu6KtuiCAbrGpkGmhKYQOVVNNO5Uz127UlC7Llt7KUh+ftfIVPGuF
yBAhV5jW2T+5FbT9fARITlD33TaAXgzALkchz1+koiYhxW3SPVdjbkzowae5V+D9
yp7kemY3yBT269D7BOwlPAzr2ncSbm6v54s59Wx60rOKq087FakK33YDPdd7guqw
m5lQWiEMWIS5MHsNDcqeaisz3KPe5KEaP2BEkBuVdZGBLwelO8SCJDoQH3ULK3mh
L0nu7LfehYBEdj0ZaBIO6V2ej+Cx1uR7Cf4PKlLja/IAymEj6a8OJMN6+0pfX3u8
DaO51gzKIn1Aumx5L76B64rp7LVWRpnwGPs=
-----END CERTIFICATE-----
EOF
openssl x509 -inform pem -in /etc/pki/akmods/certs/akmods-ublue.pem -out /etc/pki/akmods/certs/akmods-ublue.der

# /*
### Configuration
# */

# /*
# Duperemove configuration
# */
cat >/etc/default/duperemove <<'EOF'
HashDir=/var/lib/duperemove
OPTIONS="--skip-zeroes --hash=xxhash"
EOF

# /*
### TMPFILES.D
# */

# /*
# Tmpfiles rpm-state
# */
mkdir -p /var/lib/rpm-state
cat >/usr/lib/tmpfiles.d/cayo-rpm-state.conf <<'EOF'
d /var/lib/rpm-state - - - -
EOF

# /*
# Tmpfiles pcp
# */
cat >/usr/lib/tmpfiles.d/cayo-pcp.conf <<'EOF'
d /var/lib/pcp/config/pmda 0775 pcp pcp -
d /var/lib/pcp/config/pmie 0775 pcp pcp -
d /var/lib/pcp/config/pmlogger 0775 pcp pcp -
d /var/lib/pcp/tmp 0775 pcp pcp -
d /var/lib/pcp/tmp/bash 0775 pcp pcp -
d /var/lib/pcp/tmp/json 0775 pcp pcp -
d /var/lib/pcp/tmp/mmv 0775 pcp pcp -
d /var/lib/pcp/tmp/pmie 0775 pcp pcp -
d /var/lib/pcp/tmp/pmlogger 0775 pcp pcp -
d /var/lib/pcp/tmp/pmproxy 0775 pcp pcp -
d /var/log/pcp 0775 pcp pcp -
d /var/log/pcp/pmcd 0775 pcp pcp -
d /var/log/pcp/pmfind 0775 pcp pcp -
d /var/log/pcp/pmie 0775 pcp pcp -
d /var/log/pcp/pmlogger 0775 pcp pcp -
d /var/log/pcp/pmproxy 0775 pcp pcp -
d /var/log/pcp/sa 0775 pcp pcp -
EOF

# /*
# Tmpfiles duperemove
# */
cat >/usr/lib/tmpfiles.d/cayo-duperemove.conf <<'EOF'
d /var/lib/duperemove - - - -
EOF

# /*
### Systemd Units
# */

# /*
# add ZFS maintenance tasks
# */
cat >/usr/lib/systemd/system/zfs-scrub-monthly@.timer <<'EOF'
[Unit]
Description=Monthly zpool scrub timer for %i
Documentation=man:zpool-scrub(8)

[Timer]
OnCalendar=monthly
Persistent=true
RandomizedDelaySec=1h
Unit=zfs-scrub@%i.service

[Install]
WantedBy=timers.target
EOF

cat >/usr/lib/systemd/system/zfs-scrub-weekly@.timer <<'EOF'
[Unit]
Description=Weekly zpool scrub timer for %i
Documentation=man:zpool-scrub(8)

[Timer]
OnCalendar=weekly
Persistent=true
RandomizedDelaySec=1h
Unit=zfs-scrub@%i.service

[Install]
WantedBy=timers.target
EOF

cat >/usr/lib/systemd/system/zfs-scrub@.service <<'EOF'
[Unit]
Description=zpool scrub on %i
Documentation=man:zpool-scrub(8)
Requires=zfs.target
After=zfs.target
ConditionACPower=true
ConditionPathIsDirectory=/sys/module/zfs

[Service]
EnvironmentFile=-@initconfdir@/zfs
ExecStart=/bin/sh -c '\
if /usr/sbin/zpool status %i | grep -q "scrub in progress"; then\
exec /usr/sbin/zpool wait -t scrub %i;\
else exec /usr/sbin/zpool scrub -w %i; fi'
ExecStop=-/bin/sh -c '/usr/sbin/zpool scrub -p %i 2>/dev/null || true'
EOF

# /*
### Cockpit Plugin
# */

# /*
# add cockpit plugin for ZFS management
# */
curl --fail --retry 15 --retry-all-errors -sSL -o /tmp/cockpit-zfs-manager-api.json \
    "https://api.github.com/repos/45Drives/cockpit-zfs-manager/releases/latest"
CZM_TGZ_URL=$(jq -r .tarball_url /tmp/cockpit-zfs-manager-api.json)
curl --fail --retry 15 --retry-all-errors -sSL -o /tmp/cockpit-zfs-manager.tar.gz "${CZM_TGZ_URL}"

mkdir -p /tmp/cockpit-zfs-manager
tar -zxvf /tmp/cockpit-zfs-manager.tar.gz -C /tmp/cockpit-zfs-manager --strip-components=1
cp -a /tmp/cockpit-zfs-manager/polkit-1/actions/. /usr/share/polkit-1/actions/
cp -a /tmp/cockpit-zfs-manager/polkit-1/rules.d/. /usr/share/polkit-1/rules.d/
mv /tmp/cockpit-zfs-manager/zfs /usr/share/cockpit

curl --fail --retry 15 --retry-all-errors -sSL -o /tmp/cockpit-zfs-manager-font-fix.sh \
    https://raw.githubusercontent.com/45Drives/scripts/refs/heads/main/cockpit_font_fix/fix-cockpit.sh
chmod +x /tmp/cockpit-zfs-manager-font-fix.sh
/tmp/cockpit-zfs-manager-font-fix.sh

rm -rf /tmp/cockpit-zfs-manager*
