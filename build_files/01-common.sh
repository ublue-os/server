#!/usr/bin/env bash
set -xeuo pipefail

# See https://github.com/CentOS/centos-bootc/issues/191
#shellcheck disable=SC2174
mkdir -m 0700 -p /var/roothome

# make /usr/local and /opt writable
mkdir -p /var/{opt,usrlocal}
#shellcheck disable=SC2114
rm -rf /opt /usr/local
ln -sf var/opt /opt
ln -sf ../var/usrlocal /usr/local

# remove subscription manager
dnf -y remove \
  libdnf-plugin-subscription-manager \
  python3-subscription-manager-rhsm \
  subscription-manager \
  subscription-manager-rhsm-certificates

# enable CRB, EPEL and other repos
dnf config-manager --set-enabled crb
dnf -y install epel-release
dnf -y upgrade epel-release

# packages which are more or less what we'd find in CoreOS
# other than ignition, coreos-installer, moby-engine, etc
dnf -y install --setopt=install_weak_deps=False \
  audit \
  git-core \
  intel-compute-runtime \
  ipcalc \
  iscsi-initiator-utils \
  python3-dnf-plugin-versionlock \
  rsync \
  ssh-key-dir

# Kernel Swap to Kernel signed with our MOK
pushd /tmp/kernel-rpms
#shellcheck disable=SC1083
CACHED_VERSION=$(find kernel-*.rpm | grep -P "kernel-\d+\.\d+\.\d+-\d+$(rpm -E %{dist})" | sed -E 's/kernel-//;s/\.rpm//')
popd
KERNEL_VERSION="$(rpm -q 'kernel' | sed -E 's/kernel-//')"

if [[ "${CACHED_VERSION}" == "$KERNEL_VERSION" ]]; then
  dnf -y --allowerasing install /tmp/kernel-rpms/kernel-core-"$CACHED_VERSION".rpm
else
  dnf -y --allowerasing install \
    /tmp/kernel-rpms/kernel-"$CACHED_VERSION".rpm \
    /tmp/kernel-rpms/kernel-core-"$CACHED_VERSION".rpm \
    /tmp/kernel-rpms/kernel-modules-"$CACHED_VERSION".rpm \
    /tmp/kernel-rpms/kernel-modules-core-"$CACHED_VERSION".rpm \
    /tmp/kernel-rpms/kernel-modules-extra-"$CACHED_VERSION".rpm
fi

dnf versionlock add kernel kernel-core kernel-modules kernel-modules-core kernel-modules-extra

# AKMODS certificate
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
