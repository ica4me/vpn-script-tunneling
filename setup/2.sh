#!/bin/bash

export DEBIAN_FRONTEND=noninteractive

Yellow='\033[0;33m'
Blue='\033[0;34m'
Purple='\033[0;35m'
Green="\033[32m"
Red="\033[31m"
WhiteB="\e[5;37;40m"
BlueCyan="\e[5;36;40m"
Green_background="\033[42;37m"
Red_background="\033[41;37m"
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
PKG="apt-get install -y"
IPMOD="$(cat /root/.ipmod | tr -d '\n')"
CURL="curl -$IPMOD -LksS --max-time 30"
apt --fix-broken install -y
apt update

# --- [FIX] REPOSITORY GLOBAL ---
REPOSITORY="https://raw.githubusercontent.com/ica4me/vpn-script-tunneling/main"

ResultErr() {
  echo ""
  echo -e " $Red$1$Suffix"
  echo ""
}

ResultSuccess() {
  echo ""
  echo -e " $Green$1$Suffix"
  echo ""
}

CurlWRFull() {
  $CURL -H "x-api-key: potato" -w @- -o "$@" <<'EOF'
    Response Code  :  %{response_code}\n
    Status Code    :  %{http_code}\n
    Time Lookup    :  %{time_namelookup}\n
    Time Connect   :  %{time_connect}\n
    Time App Conn  :  %{time_appconnect}\n
    Time Total     :  %{time_total}\n
    ---------------------------------------\n
    Size Download  :  %{size_download}\n
    Speed Download :  %{speed_download}\n
EOF
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
      #cat "$1"
      ResultErr "Downloading $3 failed"
    fi
    echo " Try again in 4 seconds"
    sleep 2
  done
}

DBCmd() {
  local dir="/usr/sbin/potatonc/potato.db"
  DB="sqlite3 $dir"
}

SSHDropbear() {
  # Fungsi ini sepertinya opsi alternatif (tidak dipanggil di MAIN), tapi kita perbaiki juga path-nya
  DBCmd
  
  $PKG dropbear
  
  DownloadFile "/etc/pam.d/common-password" "$REPOSITORY/commonpassword" "simple-password"
  chmod +x /etc/pam.d/common-password
  
  DownloadFile "/etc/ssh/sshd_config" "$REPOSITORY/sshdconfig" "SSH"
  chmod 777 /etc/ssh/sshd_config
  
  # install dropbear
  echo "/bin/false" >> /etc/shells
  echo "/usr/sbin/nologin" >> /etc/shells
  
  DownloadFile "/etc/banner.com" "$REPOSITORY/bannercom" "Banner"
  DownloadFile "/etc/default/dropbear" "$REPOSITORY/dropbear" "Dropbear"
  
  chmod 777 /etc/banner.com
  chmod 777 /etc/default/dropbear
  /etc/init.d/dropbear restart > /dev/null 2>&1
  systemctl -q restart ssh
  systemctl -q restart sshd
  systemctl -q restart dropbear
  
  mkdir -p /tmp/sshudp/connected
  mkdir -p /tmp/sshudp/disconnected
}

SSHDropbear2019() {
  DBCmd
  
  local n_ORI="dropbear_2019.deb"
  local n_BIN="dropbear-bin_2019.deb"
  local n_INI="dropbear-initramfs_2019.deb"
  local n_RUN="dropbear-run_2019.deb"
  
  DownloadFile "/etc/pam.d/common-password" "$REPOSITORY/commonpassword" "simple-password"
  chmod +x /etc/pam.d/common-password
  
  DownloadFile "/etc/ssh/sshd_config" "$REPOSITORY/sshdconfig" "SSH"
  chmod 777 /etc/ssh/sshd_config
  
  echo "/bin/false" >> /etc/shells
  echo "/usr/sbin/nologin" >> /etc/shells
  
  $PKG libtomcrypt1
  $PKG libtommath1
  
  DownloadFile "/opt/$n_BIN" "$REPOSITORY/$n_BIN" "sbear-1"
  DownloadFile "/opt/$n_INI" "$REPOSITORY/$n_INI" "sbear-2"
  DownloadFile "/opt/$n_RUN" "$REPOSITORY/$n_RUN" "sbear-3"
  
  dpkg -i /opt/$n_BIN
  dpkg -i /opt/$n_INI
  dpkg -i /opt/$n_RUN
  
  rm -f /opt/$n_BIN
  rm -f /opt/$n_INI
  rm -f /opt/$n_RUN
  
  apt-get install -f
  
  update-initramfs -u
  
  DownloadFile "/etc/banner.com" "$REPOSITORY/bannercom" "Banner"
  DownloadFile "/etc/default/dropbear" "$REPOSITORY/dropbear" "Dropbear"
  
  chmod 777 /etc/banner.com
  chmod 777 /etc/default/dropbear
  
  systemctl daemon-reload
  /etc/init.d/dropbear restart > /dev/null 2>&1
  systemctl -q restart ssh
  systemctl -q restart sshd
  systemctl -q restart dropbear
  
  mkdir -p /tmp/sshudp/connected
  mkdir -p /tmp/sshudp/disconnected
}

WebMinXMLParse() {
  # install webmin
  cd
  # Link Webmin ini biarkan dari source aslinya
  wget https://github.com/potatonc/webmin/raw/master/webmin_1.910_all.deb
  dpkg --install webmin_1.910_all.deb;
  #apt-get -y -f install;
  sed -i 's/ssl=1/ssl=0/g' /etc/webmin/miniserv.conf
  rm -f webmin_1.910_all.deb
  /etc/init.d/webmin restart
  
  # xml parser
  cd
  apt-get install -y libxml-parser-perl
}

AddSshUDP() {
  mkdir -p /usr/sbin/potatonc/udp
  
  if [[ -e "/usr/sbin/potatonc/udp/udp-server" ]]; then
    systemctl -q stop udp-server
    rm -f "/usr/sbin/potatonc/udp/udp-server"
  fi
  
  # [PERHATIAN] Pastikan nama file di repo Anda adalah 'udpserver2'
  # Jika di folder Anda namanya 'udp-server', rename dulu di GitHub atau ubah skrip ini
  DownloadFile "/usr/sbin/potatonc/udp/udp-server" "$REPOSITORY/udpserver2" "UDP-Custom"
  
  DownloadFile "/usr/sbin/potatonc/udp/config.json" "$REPOSITORY/udpjson2" "UDP-Json"
  
  DownloadFile "/etc/systemd/system/udp-server.service" "$REPOSITORY/udpservice" "UDP-Service"
  
  DownloadFile "/usr/sbin/dns-server" "$REPOSITORY/dnsserver" "DNS-Server"
  
  DownloadFile "/usr/sbin/dns-client" "$REPOSITORY/dnsclient" "DNS-Client"
  
  chmod 777 /usr/sbin/dns-server
  chmod 777 /usr/sbin/dns-client
  chmod 777 /usr/sbin/potatonc/udp/udp-server
  systemctl -q enable udp-server
  systemctl -q start udp-server
}

MAIN() {
  SSHDropbear2019
  AddSshUDP
}

MAIN