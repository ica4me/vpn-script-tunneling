#!/bin/bash

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

export DEBIAN_FRONTEND=noninteractive
PKG="apt-get install -y"

# --- [FIX] AUTO DETECT IP MODE (PENTING!) ---
# Karena binary installer dibuang, kita harus deteksi manual IPv4/IPv6
if [[ ! -f /root/.ipmod ]]; then
    if curl -s4 https://google.com > /dev/null; then
        echo "4" > /root/.ipmod
    else
        echo "6" > /root/.ipmod
    fi
fi

IPMOD="$(cat /root/.ipmod | tr -d '\n')"
CURL="curl -$IPMOD -LksS --max-time 30"
mkdir -p /tmp/install
TEMP="/tmp/install"

# --- REPOSITORY ANDA ---
# Pastikan 'potato.db', 'cert.crt', dll ada di ROOT repository (bukan di folder setup)
REPOSITORY="https://raw.githubusercontent.com/ica4me/vpn-script-tunneling/main"

cp /etc/resolv.conf /root/.resolv.conf

source /etc/os-release

# Fix debconf agar tidak muncul dialog
echo iptables-persistent iptables-persistent/autosave_v4 boolean true | debconf-set-selections
echo iptables-persistent iptables-persistent/autosave_v6 boolean true | debconf-set-selections

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

Lane() {
  echo -e " ${BlueCyan}————————————————————————————————————————${Suffix}"
}

ISRoot() {
  local dir="/usr/sbin/potatonc"
  
  if [ $EUID -ne 0 ]; then
    LOGO | tee ${TEMP}/isRoot
    echo -e " ${Red}You need to run this script as ${Yellow}root${Suffix}" | tee -a ${TEMP}/isRoot
    rm -rf "$dir" > /dev/null 2>&1
    Credit_Potato | tee -a ${TEMP}/isRoot
    exit 1
  fi
}

OpenVZ() {
  local dir="/usr/sbin/potatonc"
  
  if [ $(systemd-detect-virt) == "openvz" ]; then
    LOGO | tee ${TEMP}/openvz
    echo -e " ${Red}OpenVZ is not supported${Suffix}" | tee -a ${TEMP}/openvz
    rm -rf "$dir" > /dev/null 2>&1
    Credit_Potato | tee -a ${TEMP}/openvz
    exit 1
  fi
}

ScriptInstallatiosIfExists() {
  local dir="/usr/sbin/potatonc"
  
  if [ -e "$dir" ]; then
    LOGO | tee ${TEMP}/check
    echo -e "     ${Green}You have installed the script${Suffix}" | tee -a ${TEMP}/check
    echo "" | tee -a ${TEMP}/check
    echo -e " ${BlueCyan}=====================================================${Suffix}" | tee -a ${TEMP}/check
    echo "" | tee -a ${TEMP}/check
    #rm -rf "$dir" > /dev/null 2>&1
    Credit_Potato | tee -a ${TEMP}/check
    exit 1
  fi
}

InstallPythonDua() {
  # --- METODE UNIVERSAL (Menggunakan Source Code TGZ) ---
  echo -e " ${Green}Installing Python 2.7 from Source...${Suffix}"
  cd /tmp
  
  # Download file source yang ada di GitHub Anda (ROOT REPO)
  DownloadFile "Python-2.7.18.tgz" "$REPOSITORY/Python-2.7.18.tgz" "Py-Source"
  
  tar xzf Python-2.7.18.tgz
  cd Python-2.7.18
  ./configure --enable-optimizations
  make altinstall
  
  if [[ -e /usr/bin/python ]]; then
    rm -f /usr/bin/python
  fi
  
  ln -s "/usr/local/bin/python2.7" "/usr/bin/python"
  
  cd ..
  rm -rf Python-2.7.18
  rm -f Python-2.7.18.tgz
}

InstallDependencies() {
  apt --fix-broken install
  $PKG wget
  $PKG curl
  $PKG git
  $PKG ruby
  $PKG zip
  $PKG unzip
  $PKG gawk
  $PKG iptables
  $PKG iptables-persistent
  $PKG netfilter-persistent
  $PKG net-tools
  $PKG openssl
  $PKG ca-certificates
  $PKG gnupg
  $PKG '^gnupg[2-9]+$'
  $PKG lsb-release
  $PKG gcc
  $PKG make
  $PKG cmake
  $PKG screen
  $PKG socat
  $PKG apt-transport-https
  $PKG gnupg1
  $PKG dnsutils
  $PKG cron
  $PKG chrony
  $PKG libssl-dev
  $PKG '^libpcre[0-9\.\-]+$'
  $PKG '^libpcre[0-9\.\-]+dev$'
  $PKG zlib1g-dev
  $PKG nscd
  $PKG jq
  $PKG '^liblua[0-9\.\-]+$'
  $PKG '^lua[0-9\.\-]+$'
  $PKG '^liblua[0-9\.\-]+dev$'
  $PKG libsystemd-dev
  $PKG util-linux
  $PKG build-essential
  $PKG '^python[0-9]+-pip$'
  $PKG ntpdate
  $PKG software-properties-common
  $PKG sqlite3
  $PKG '^libsqlite[1-9\.\-]+dev$'
  $PKG '^sqlite[1-9\.\-]+$'
  $PKG fail2ban
  $PKG '^libssh[1-9\.\-]+$'
  $PKG '^libssh[1-9\.\-]+dev$'
  $PKG '^php[1-9\.\-]+$'
  $PKG '^php[1-9\.\-]+dev$'
  $PKG apache2
  $PKG libapache2-mod-php
  $PKG coreutils
  
  apt-get autoremove -y

  if [[ $ID == 'ubuntu' ]]; then
    $PKG ubuntu-keyring
  fi
  if [[ $ID == 'debian' ]]; then
    $PKG debian-archive-keyring
    $PKG python-is-python3
  fi
  
  if [[ -n $(which python) ]]; then
    python --version &> /tmp/.python
    if [[ -z $(cat /tmp/.python | grep "^Python 2") ]]; then
      rm -f $(which python)
      if [[ -e /usr/bin/python2 ]]; then
        ln -s "/usr/bin/python2" "/usr/bin/python"
      else
        InstallPythonDua
      fi
    fi
  else
    if [[ -e /usr/bin/python2 ]]; then
      ln -s "/usr/bin/python2" "/usr/bin/python"
    else
      InstallPythonDua
    fi
  fi
  
  $PKG '^php[1-9\.\-]+ssh2$'
  apt --fix-broken install
  systemctl stop apache2  > /dev/null 2>&1
}

PkgIns() {
  $PKG $1
}

CheckPkg() {
  dpkg -s $1 &> /dev/null

  if [ $? -eq 0 ]; then
    echo -e " Package $Green$1$Suffix is installed!"
  else
    echo -e " Package $Red$1$Suffix is NOT installed!"
    echo ""
    echo -e " Try to install Package $Yellow$1$Suffix"
    echo ""
    PkgIns $1
  fi
}

DeleteRowsDB() {
  DBCmd
  
  if [[ ! -z $($DB "SELECT * FROM servers") ]]; then
    $DB "DELETE FROM servers"
  fi
  if [[ ! -z $($DB "SELECT * FROM account_sshs") ]]; then
    $DB "DELETE FROM account_sshs"
  fi
  if [[ ! -z $($DB "SELECT * FROM account_vmesses") ]]; then
    $DB "DELETE FROM account_vmesses"
  fi
  if [[ ! -z $($DB "SELECT * FROM account_vlesses") ]]; then
    $DB "DELETE FROM account_vlesses"
  fi
  if [[ ! -z $($DB "SELECT * FROM account_trojans") ]]; then
    $DB "DELETE FROM account_trojans"
  fi
}

DownloadDB() {
  InstallDependencies
  CheckPkg "curl"
  CheckPkg "jq"
  CheckPkg "sqlite3"
  local dir="/usr/sbin/potatonc"
  if [ ! -e "$dir" ]; then
    mkdir -p $dir
    
    for (( ; ; ))
    do
      sleep 2
      if [[ $(CurlWRStatusCode "$dir/potato.db" "$REPOSITORY/potato.db") == 200 ]]; then
        DeleteRowsDB
        ResultSuccess "Downloading success"
        break
      else
        # Jika gagal, tampilkan pesan error tapi jangan cat file html error
        ResultErr "Downloading failed (potato.db)"
      fi
      echo " Try again in 4 seconds"
      sleep 2
    done
  else
    for (( ; ; ))
    do
      sleep 2
      if [[ $(CurlWRStatusCode "$dir/potato.db" "$REPOSITORY/potato.db") == 200 ]]; then
        DeleteRowsDB
        ResultSuccess "Downloading success"
        break
      else
        ResultErr "Downloading failed (potato.db)"
      fi
      echo " Try again in 4 seconds"
      sleep 2
    done
  fi
}

DBCmd() {
  local dir="/usr/sbin/potatonc/potato.db"
  DB="sqlite3 $dir"
}

GetData_DB() {
  local host=$(cat "/root/.ipvps")
  # Bypass License Check
  local repo='{"statusCode":200,"status":"true","data":{"name_client":"Bypassed","chat_id":"0","address":"'$host'","domain":"domain.com","key_client":"bypass","x_api_client":"bypass","type_script":"premium","pemilik_client":"Me","status":"active","script":"none","date_exp":"2099-12-31"}}'

  local myisp="Local ISP"
  local mycity="Local City"
  local mycountry="ID"

  local name_client="Admin"
  local chat_id="0"
  local myip="$host"
  local domain="domain.com"
  local key="bypass"
  local auth="bypass"
  local type_script="premium"
  local order_by="Me"
  local status="active"
  local script="none"
    
  $DB "INSERT INTO servers (address, isp, city, key, auth, order_by, name_client, type_script, domain, status, os, chat_id) VALUES ('$myip', '$myisp', '$mycity', '$key', '$auth', '$order_by', '$name_client', '$type_script', '$domain', '$status', '$PRETTY_NAME', '$chat_id')"
  echo "$myip" > ~/.myip
  echo "$myisp" > ~/.myisp
  echo "$mycity" > ~/.mycity
  sleep 1
  # [PENTING] Update URL Repo ke Database agar script selanjutnya membaca URL yang benar
  $DB "UPDATE servers SET repository='$REPOSITORY'"
  sleep 1
  
  MYIP=$($DB "SELECT address FROM servers" | sed '/^$/d')
  MYISP="$myisp"
  MYCITY="$mycity"
  MYCOUNTRY="$mycountry"
  MYKEY=$($DB "SELECT key FROM servers" | sed '/^$/d')
  ORDERBY=$($DB "SELECT order_by FROM servers" | sed '/^$/d')
  NAME_CLIENT=$($DB "SELECT name_client FROM servers" | sed '/^$/d')
  AUTH=$($DB "SELECT auth FROM servers" | sed '/^$/d')
  LINK_URL="$script"
  MYDATE="2099-12-31"
}

CheckIpv4v6() {
  if [[ $IPMOD == '4' ]]; then
    CurlWRFull "/root/.ipvps" "ipinfo.io"
  fi
  if [[ $IPMOD == '6' ]]; then
    if [[ -z $(wget --inet6-only -qO- v6.ipinfo.io) ]]; then
      CurlWRFull "/root/.ipvps" "ifconfig.co/ip"
    else
      CurlWRFull "/root/.ipvps" "v6.ipinfo.io"
    fi
  fi
}

IZIN_Potato() { 
  echo -e "${Green}License Bypassed Successfully!${Suffix}"; 
  CheckPkg "curl"
  CheckPkg "jq"
  
  CheckIpv4v6
  
  DownloadDB
  GetData_DB
  
  SendBOT
  GetCertandProfile
  NeoFetch
}

GetCertandProfile() {
  local dir="/usr/sbin/potatonc/cert"
  mkdir -p "$dir"
  
  DownloadFile "$dir/cert.crt" "$REPOSITORY/cert.crt" "DB-Cert"
  DownloadFile "$dir/cert.key" "$REPOSITORY/cert.key" "DB-Key"
  
  cat "$dir/cert.crt" "$dir/cert.key" > "$dir/cert.pem"
  
  if [[ $MYCOUNTRY == 'ID' ]]; then
    DownloadFile "/root/.profile" "$REPOSITORY/dotprofileID" "Profile"
    chmod +x /root/.profile
  else
    DownloadFile "/root/.profile" "$REPOSITORY/dotprofile" "Profile"
    chmod +x /root/.profile
  fi
}

NeoFetch() {
  # Coba install dari APT dulu, lebih cepat
  $PKG neofetch
  if ! command -v neofetch &> /dev/null; then
      # Jika tidak ada di repo (jarang terjadi), compile manual
      git clone https://github.com/dylanaraps/neofetch
      cd neofetch
      make install
      make PREFIX=/usr/local install
      cd ..
      rm -rf neofetch
  fi
}

SendBOT() { 
  echo "Telegram Laporan Di-BLOKIR"; 
  return 0;
}

LOGO() {
  clear
  echo -e ""
  echo -e " ${BlueCyan}=====================================================${Suffix}" 
  echo -e " ${BlueCyan}|           ${Green}Script VPS Tunneling by Potato          ${BlueCyan}|" 
  echo -e " ${BlueCyan}=====================================================${Suffix}" 
  echo -e ""
  echo -e " ${BlueCyan}=====================================================${Suffix}" 
  echo -e ""
}

Credit_Potato() {
  echo -e "" 
  echo -e "        ---------------------------------------"
  echo -e "             Terimakasih sudah menggunakan-"
  echo -e "                Script Credit by Potato"
  echo -e "        ---------------------------------------"
  echo -e ""
}

NotifFalse() {
  echo "IP Not Allowed (Tapi bohong, sudah di-bypass)"
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

MAIN() {
  ISRoot
  OpenVZ
  ScriptInstallatiosIfExists
  apt --fix-broken install -y
  apt-get autoremove -y
  
  IZIN_Potato
}

MAIN