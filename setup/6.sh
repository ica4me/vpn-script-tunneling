#!/bin/bash

# --- [FIX] NON-INTERACTIVE MODE ---
export DEBIAN_FRONTEND=noninteractive

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
# Tambahkan dependensi kompilasi yang sering hilang di Debian 12
PKG="apt-get install -y -o Dpkg::Options::=--force-confdef -o Dpkg::Options::=--force-confold"
IPMOD="$(cat /root/.ipmod | tr -d '\n')"
CURL="curl -$IPMOD -LksS --max-time 30"

apt-get update
$PKG build-essential libpcre2-dev libssl-dev zlib1g-dev liblua5.3-dev libsystemd-dev

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

InstallHaproxy() {
  cd /opt
  
  # Pastikan file haproxy-3.0.5.tar.gz di repo Anda tidak rusak (berukuran 4MB+)
  DownloadFile "haproxy.tar.gz" "$REPOSITORY/haproxy-3.0.5.tar.gz" "Archive"
  
  # --- [FIX] DYNAMIC FOLDER DETECTION ---
  # Hapus folder lama jika ada sisa kegagalan sebelumnya
  rm -rf haproxy-* tar -xzf haproxy.tar.gz
  rm -f haproxy.tar.gz
  
  # Otomatis masuk ke folder hasil ekstrak tanpa peduli nama versinya
  cd haproxy-* || { ResultErr "Folder HAProxy tidak ditemukan!"; exit 1; }
  
  ResultSuccess "Memulai Kompilasi HAProxy..."
  make clean
  make -j $(nproc) TARGET=linux-glibc \
        USE_PCRE2=1 USE_PCRE2_JIT=1 USE_OPENSSL=1 USE_LUA=1 USE_SLZ=1 USE_SYSTEMD=1 USE_PROMEX=1 DEBUG=
        
  make install || { ResultErr "Gagal install HAProxy!"; exit 1; }
  
  cd ..
  rm -rf haproxy-*
  mkdir -p /libc64
  Workdir
}

Workdir() {
  cd
  mkdir -p /etc/haproxy
  mkdir -p /usr/sbin/potatonc
  
  # Pastikan file binary hasil compile sudah ada
  if [[ -f "/usr/local/sbin/haproxy" ]]; then
      cp /usr/local/sbin/haproxy /usr/sbin/
      cp /usr/local/sbin/haproxy /usr/sbin/library
  else
      ResultErr "Binary HAProxy tidak ditemukan di /usr/local/sbin/"
  fi
  
  # Ambil file pendukung
  DownloadFile "/usr/sbin/potatonc/p0t4t0.lst" "$REPOSITORY/haproxycdn" "CDN"
  
  # Download module library sesuai koneksi IPv6
  if [[ -z $(curl -6 --connect-timeout 5 --max-time 10 https://v6.ipinfo.io -sS 2>/dev/null) ]]; then
    DownloadFile "/libc64/module" "$REPOSITORY/haproxymodulenew4" "Service-M"
  else
    DownloadFile "/libc64/module" "$REPOSITORY/haproxymodulenew" "Service-M"
  fi
  
  DownloadFile "/etc/systemd/system/local.service" "$REPOSITORY/haproxylocalservice" "Service-HA"
  DownloadFile "/etc/haproxy/haproxy.cfg" "$REPOSITORY/haproxy.cfg" "Config-HA"
  
  echo "" >> /libc64/module
  
  SystemdHaproxy
  
  # Konfigurasi Akhir
  sed -i 's/mode http/mode tcp/g' /etc/haproxy/haproxy.cfg
  systemctl daemon-reload
  systemctl enable haproxy local 2>/dev/null
}

SystemdHaproxy() {
cat > /etc/systemd/system/haproxy.service <<-END
[Unit]
Description=HAProxy Load Balancer
After=network-online.target rsyslog.service
Wants=network-online.target

[Service]
Environment="CONFIG=/etc/haproxy/haproxy.cfg" "PIDFILE=/run/haproxy.pid"
ExecStartPre=/usr/sbin/haproxy -f \$CONFIG -c -q
ExecStart=/usr/sbin/haproxy -Ws -f \$CONFIG -p \$PIDFILE
ExecReload=/usr/sbin/haproxy -f \$CONFIG -c -q
ExecReload=/bin/kill -USR2 \$MAINPID
KillMode=mixed
Restart=always
Type=notify

[Install]
WantedBy=multi-user.target
END
}

MAIN() {
  InstallHaproxy
  ResultSuccess "Script 6.sh (HAProxy) Completed Successfully"
}

MAIN