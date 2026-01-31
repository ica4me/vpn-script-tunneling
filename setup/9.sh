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
NIC=$(ip -4 route ls | grep default | grep -Po '(?<=dev )(\S+)' | head -1)
apt --fix-broken install -y
apt update

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

mkdir -p /usr/sbin/potatonc/style
mkdir -p /usr/sbin/potatonc/sshdb
mkdir -p /etc/potatonc/limit/sshdb
mkdir -p /usr/sbin/potatonc/udp
echo "10m" > /usr/sbin/potatonc/mebot
echo "10m" > /usr/sbin/potatonc/bckbot

BlockTorrent() {
  # Block string torrent umum
  iptables -A FORWARD -m string --algo bm --string "BitTorrent" -j DROP
  iptables -A FORWARD -m string --algo bm --string "BitTorrent protocol" -j DROP
  iptables -A FORWARD -m string --algo bm --string "peer_id=" -j DROP
  iptables -A FORWARD -m string --algo bm --string ".torrent" -j DROP
  iptables -A FORWARD -m string --algo bm --string "announce.php?passkey=" -j DROP
  iptables -A FORWARD -m string --algo bm --string "torrent" -j DROP
  iptables -A FORWARD -m string --algo bm --string "announce" -j DROP
  iptables -A FORWARD -m string --algo bm --string "info_hash" -j DROP
  iptables -A FORWARD -m string --algo bm --string "/default.ida?" -j DROP
  iptables -A FORWARD -m string --algo bm --string ".exe?/c+dir" -j DROP
  iptables -A FORWARD -m string --algo bm --string ".exe?/c_tftp" -j DROP
  
  # Block Torrent keys (redundant tapi aman)
  iptables -A FORWARD -m string --algo kmp --string "peer_id" -j DROP
  iptables -A FORWARD -m string --algo kmp --string "BitTorrent" -j DROP
  iptables -A FORWARD -m string --algo kmp --string "BitTorrent protocol" -j DROP
  iptables -A FORWARD -m string --algo kmp --string "bittorrent-announce" -j DROP
  iptables -A FORWARD -m string --algo kmp --string "announce.php?passkey=" -j DROP
  
  # Block Distributed Hash Table (DHT) keywords
  iptables -A FORWARD -m string --algo kmp --string "find_node" -j DROP
  iptables -A FORWARD -m string --algo kmp --string "info_hash" -j DROP
  iptables -A FORWARD -m string --algo kmp --string "get_peers" -j DROP
  iptables -A FORWARD -m string --algo kmp --string "announce" -j DROP
  iptables -A FORWARD -m string --algo kmp --string "announce_peers" -j DROP
  
  local Exists=$(iptables -L | grep -w "fail2ban_dump")
  if [[ "${Exists}" == "" ]]; then
    iptables -F fail2ban_dump
    iptables -N fail2ban_dump
    iptables -I INPUT -p tcp -j fail2ban_dump
    iptables -I OUTPUT -p tcp -j fail2ban_dump
  fi
  
  local Exists=$(iptables -L | grep -w "fail2ban_rest")
  if [[ "${Exists}" == "" ]]; then
    iptables -F fail2ban_rest
    iptables -N fail2ban_rest
    iptables -I INPUT -p tcp -j fail2ban_rest
    iptables -I OUTPUT -p tcp -j fail2ban_rest
  fi
  
  iptables-save > /etc/iptables/rules.v4
  iptables-save > /etc/iptables.up.rules
  netfilter-persistent save
  netfilter-persistent reload
}

iptablesAll() {
  # Allow Web Ports
  iptables -I INPUT -m state --state NEW -m tcp -p tcp --dport 80 -j ACCEPT
  iptables -I INPUT -m state --state NEW -m udp -p udp --dport 80 -j ACCEPT
  iptables -I INPUT -m state --state NEW -m tcp -p tcp --dport 443 -j ACCEPT
  iptables -I INPUT -m state --state NEW -m udp -p udp --dport 443 -j ACCEPT
  
  # Allow SSH & Dropbear Ports
  iptables -I INPUT -m state --state NEW -m tcp -p tcp --dport 22 -j ACCEPT
  iptables -I INPUT -m state --state NEW -m tcp -p tcp --dport 2202 -j ACCEPT
  iptables -I INPUT -m state --state NEW -m udp -p udp --dport 2202 -j ACCEPT
  iptables -I INPUT -m state --state NEW -m tcp -p tcp --dport 143 -j ACCEPT
  iptables -I INPUT -m state --state NEW -m udp -p udp --dport 143 -j ACCEPT
  iptables -I INPUT -m state --state NEW -m tcp -p tcp --dport 444 -j ACCEPT
  iptables -I INPUT -m state --state NEW -m udp -p udp --dport 444 -j ACCEPT
  iptables -I INPUT -m state --state NEW -m tcp -p tcp --dport 90 -j ACCEPT
  iptables -I INPUT -m state --state NEW -m udp -p udp --dport 90 -j ACCEPT
  iptables -I INPUT -m state --state NEW -m tcp -p tcp --dport 69 -j ACCEPT
  iptables -I INPUT -m state --state NEW -m udp -p udp --dport 69 -j ACCEPT
  
  # Allow Other VPN Ports
  iptables -I INPUT -m state --state NEW -m tcp -p tcp --dport 2222 -j ACCEPT
  iptables -I INPUT -m state --state NEW -m udp -p udp --dport 2222 -j ACCEPT
  iptables -I INPUT -m state --state NEW -m tcp -p tcp --dport 8080 -j ACCEPT
  iptables -I INPUT -m state --state NEW -m udp -p udp --dport 8080 -j ACCEPT
  iptables -I INPUT -m state --state NEW -m tcp -p tcp --dport 7788 -j ACCEPT
  iptables -I INPUT -m state --state NEW -m udp -p udp --dport 7788 -j ACCEPT
  iptables -I INPUT -m state --state NEW -m tcp -p tcp --dport 8443 -j ACCEPT
  iptables -I INPUT -m state --state NEW -m udp -p udp --dport 8443 -j ACCEPT
  iptables -I INPUT -m state --state NEW -m tcp -p tcp --dport 8484 -j ACCEPT
  iptables -I INPUT -m state --state NEW -m udp -p udp --dport 8484 -j ACCEPT
  iptables -I INPUT -m state --state NEW -m tcp -p tcp --dport 8555 -j ACCEPT
  iptables -I INPUT -m state --state NEW -m udp -p udp --dport 8555 -j ACCEPT
  iptables -I INPUT -m state --state NEW -m tcp -p tcp --dport 81 -j ACCEPT
  iptables -I INPUT -m state --state NEW -m udp -p udp --dport 81 -j ACCEPT
  
  # Allow Cloudflare/Websocket Ports
  iptables -I INPUT -m state --state NEW -m tcp -p tcp --dport 2082 -j ACCEPT
  iptables -I INPUT -m state --state NEW -m udp -p udp --dport 2082 -j ACCEPT
  iptables -I INPUT -m state --state NEW -m tcp -p tcp --dport 2083 -j ACCEPT
  iptables -I INPUT -m state --state NEW -m udp -p udp --dport 2083 -j ACCEPT
  iptables -I INPUT -m state --state NEW -m tcp -p tcp --dport 8880 -j ACCEPT
  iptables -I INPUT -m state --state NEW -m udp -p udp --dport 8880 -j ACCEPT
  iptables -I INPUT -m state --state NEW -m tcp -p tcp --dport 2052 -j ACCEPT
  iptables -I INPUT -m state --state NEW -m udp -p udp --dport 2052 -j ACCEPT
  iptables -I INPUT -m state --state NEW -m tcp -p tcp --dport 2053 -j ACCEPT
  iptables -I INPUT -m state --state NEW -m udp -p udp --dport 2053 -j ACCEPT
  
  # Allow Additional Ports
  iptables -I INPUT -m state --state NEW -m tcp -p tcp --dport 9088 -j ACCEPT
  iptables -I INPUT -m state --state NEW -m udp -p udp --dport 9088 -j ACCEPT
  iptables -I INPUT -m state --state NEW -m tcp -p tcp --dport 9080 -j ACCEPT
  iptables -I INPUT -m state --state NEW -m udp -p udp --dport 9080 -j ACCEPT
  
  local Exists=$(iptables -L | grep -w "fail2ban_dump")
  if [[ "${Exists}" == "" ]]; then
    iptables -F fail2ban_dump
    iptables -N fail2ban_dump
    iptables -I INPUT -p tcp -j fail2ban_dump
    iptables -I OUTPUT -p tcp -j fail2ban_dump
  fi
  
  local Exists=$(iptables -L | grep -w "fail2ban_rest")
  if [[ "${Exists}" == "" ]]; then
    iptables -F fail2ban_rest
    iptables -N fail2ban_rest
    iptables -I INPUT -p tcp -j fail2ban_rest
    iptables -I OUTPUT -p tcp -j fail2ban_rest
  fi
  
  iptables-save > /etc/iptables/rules.v4
  iptables-save > /etc/iptables.up.rules
  netfilter-persistent save
  netfilter-persistent reload
}

AddSwapDuaGB() {
  # Cek apakah swap sudah ada
  if [[ $(cat /proc/swaps | grep "swapfile") ]]; then
      echo "Swap file already exists. Skipping."
      return
  fi

  # Buat Swap (1GB atau 2GB tergantung space)
  dd if=/dev/zero of=/swapfile1 bs=1024 count=1048576
  dd if=/dev/zero of=/swapfile2 bs=1024 count=1048576
  mkswap /swapfile1 > /dev/null 2>&1
  mkswap /swapfile2 > /dev/null 2>&1
  chown root:root /swapfile1 > /dev/null 2>&1
  chown root:root /swapfile2 > /dev/null 2>&1
  chmod 0600 /swapfile1 > /dev/null 2>&1
  chmod 0600 /swapfile2 > /dev/null 2>&1
  swapon /swapfile1 > /dev/null 2>&1
  swapon /swapfile2 > /dev/null 2>&1
  sed -i '$ i\/swapfile1        swap swap    defaults    0 0' /etc/fstab > /dev/null 2>&1
  sed -i '$ i\/swapfile2        swap swap    defaults    0 0' /etc/fstab > /dev/null 2>&1
}

MAIN() {
  apt --fix-broken install -y
  BlockTorrent
  iptablesAll
  AddSwapDuaGB
}

MAIN