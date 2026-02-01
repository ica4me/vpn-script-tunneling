#!/bin/bash

# --- [FIX] NON-INTERACTIVE MODE ---
export DEBIAN_FRONTEND=noninteractive
export APT_LISTCHANGES_FRONTEND=none

Yellow='\033[0;33m'
Blue='\033[0;34m'
Purple='\033[0;35m'
Green="\033[32m"
Red="\033[31m"
Suffix="\033[0m"

# --- [FIX] AUTO DETECT IP MODE ---
if [[ ! -f /root/.ipmod ]]; then
    if curl -s4 https://google.com > /dev/null; then
        echo "4" > /root/.ipmod
    else
        echo "6" > /root/.ipmod
    fi
fi

source /etc/os-release
# Gunakan force-confold agar tidak bertanya saat menimpa config lama
PKG="apt-get install -y -o Dpkg::Options::=--force-confdef -o Dpkg::Options::=--force-confold"
IPMOD="$(cat /root/.ipmod | tr -d '\n')"
CURL="curl -$IPMOD -LksS --max-time 30"

# Fix broken packages sebelum mulai
apt-get autoremove -y
apt-get --fix-broken install -y
apt-get update

# --- [FIX] REPOSITORY GLOBAL ---
REPOSITORY="https://raw.githubusercontent.com/ica4me/vpn-script-tunneling/main"

ResultErr() {
  echo -e " $Red$1$Suffix"
}

ResultSuccess() {
  echo -e " $Green$1$Suffix"
}

CurlWRStatusCode() {
  $CURL -H "x-api-key: potato" -w "%{http_code}" -o "$@"
}

DownloadFile() {
  for (( ; ; ))
  do
    sleep 2
    if [[ $(CurlWRStatusCode "$1" "$2") == 200 ]]; then
      ResultSuccess "Downloading $3 success"
      break
    else
      ResultErr "Downloading $3 failed"
    fi
    echo " Try again in 4 seconds"
    sleep 2
  done
}

# --- [FIX] DROPBEAR 2019 FOR MODERN DISTROS ---
SSHDropbear2019() {
    # Install dependencies yang dibutuhkan binary 2019
    $PKG libtomcrypt1 libtommath1 zlib1g

    local n_BIN="dropbear-bin_2019.deb"
    local n_INI="dropbear-initramfs_2019.deb"
    local n_RUN="dropbear-run_2019.deb"
    
    DownloadFile "/etc/pam.d/common-password" "$REPOSITORY/commonpassword" "simple-password"
    DownloadFile "/etc/ssh/sshd_config" "$REPOSITORY/sshdconfig" "SSH"
    
    # Tambahkan shells nologin jika belum ada
    grep -qxF '/bin/false' /etc/shells || echo "/bin/false" >> /etc/shells
    grep -qxF '/usr/sbin/nologin' /etc/shells || echo "/usr/sbin/nologin" >> /etc/shells
    
    DownloadFile "/opt/$n_BIN" "$REPOSITORY/$n_BIN" "sbear-1"
    DownloadFile "/opt/$n_INI" "$REPOSITORY/$n_INI" "sbear-2"
    DownloadFile "/opt/$n_RUN" "$REPOSITORY/$n_RUN" "sbear-3"
    
    # Install manual dengan penanganan error agar tidak berhenti di tengah
    dpkg -i /opt/$n_BIN /opt/$n_INI /opt/$n_RUN || apt-get install -y -f
    
    rm -f /opt/$n_BIN /opt/$n_INI /opt/$n_RUN
    
    DownloadFile "/etc/banner.com" "$REPOSITORY/bannercom" "Banner"
    DownloadFile "/etc/default/dropbear" "$REPOSITORY/dropbear" "Dropbear"
    
    chmod 644 /etc/banner.com
    chmod 644 /etc/default/dropbear
    
    systemctl daemon-reload
    systemctl restart ssh sshd dropbear 2>/dev/null
    
    mkdir -p /tmp/sshudp/connected /tmp/sshudp/disconnected
}

# --- [FIX] UDP CUSTOM & OHP ---
AddSshUDP() {
    mkdir -p /usr/sbin/potatonc/udp
    
    # Ambil binary UDP-Custom (Pastikan di GitHub namanya udpserver2)
    DownloadFile "/usr/sbin/potatonc/udp/udp-server" "$REPOSITORY/udpserver2" "UDP-Custom"
    DownloadFile "/usr/sbin/potatonc/udp/config.json" "$REPOSITORY/udpjson2" "UDP-Json"
    DownloadFile "/etc/systemd/system/udp-server.service" "$REPOSITORY/udpservice" "UDP-Service"
    
    # Ambil binary OHP (Sering terlewat sebelumnya)
    DownloadFile "/usr/bin/ohp" "$REPOSITORY/ohp" "OHP-Binary"
    
    # DNS Server & Client
    DownloadFile "/usr/sbin/dns-server" "$REPOSITORY/dnsserver" "DNS-Server"
    DownloadFile "/usr/sbin/dns-client" "$REPOSITORY/dnsclient" "DNS-Client"
    
    # Permissions
    chmod +x /usr/bin/ohp
    chmod +x /usr/sbin/dns-server /usr/sbin/dns-client
    chmod +x /usr/sbin/potatonc/udp/udp-server
    
    systemctl daemon-reload
    systemctl enable udp-server
    systemctl start udp-server
}

MAIN() {
    SSHDropbear2019
    AddSshUDP
    ResultSuccess "Script 2.sh Completed Successfully"
}

MAIN