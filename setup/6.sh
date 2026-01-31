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

InstallHaproxy() {
  DBCmd
  
  cd /opt
  
  # FIX: Menggunakan variabel global $REPOSITORY
  # Pastikan file haproxy-3.0.5.tar.gz ada di repo Anda
  DownloadFile "haproxy.tar.gz" "$REPOSITORY/haproxy-3.0.5.tar.gz" "Archive"
  
  tar -xzf haproxy.tar.gz &> /dev/null
  rm -f haproxy.tar.gz
  
  # Hati-hati, folder hasil ekstrak harus sesuai versi tarball
  cd haproxy-3.0.5
  make clean
  make -j $(nproc) TARGET=linux-glibc \
                USE_PCRE2=1 USE_PCRE2_JIT=1 USE_OPENSSL=1 USE_LUA=1 USE_SLZ=1 USE_SYSTEMD=1 USE_PROMEX=1 DEBUG=
  make install
  cd ..
  rm -rf haproxy-3.0.5
  cd ..
  mkdir -p libc64
  Workdir
}

Workdir() {
  cd
  mkdir -p /etc/haproxy
  cp /usr/local/sbin/haproxy /usr/sbin/
  mv /usr/local/sbin/haproxy /usr/sbin/library
  
  # FIX: Nama file di repo harus 'haproxycdn'
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
  
  sed -i 's/mode http/mode tcp/g' /etc/haproxy/haproxy.cfg
}

SystemdHaproxy() {
cat > /etc/systemd/system/haproxy.service <<-END
[Unit]
Description=HAProxy Load Balancer
Documentation=man:haproxy(1)
Documentation=file:/usr/share/doc/haproxy/configuration.txt.gz
After=network-online.target rsyslog.service
Wants=network-online.target

[Service]
EnvironmentFile=-/etc/default/haproxy
EnvironmentFile=-/etc/sysconfig/haproxy
Environment="CONFIG=/etc/haproxy/haproxy.cfg" "PIDFILE=/run/haproxy.pid" "EXTRAOPTS=-S /run/haproxy-master.sock"
ExecStartPre=/usr/sbin/haproxy -Ws -f \$CONFIG -c -q \$EXTRAOPTS
ExecStart=/usr/sbin/haproxy -Ws -f \$CONFIG -p \$PIDFILE \$EXTRAOPTS
ExecReload=/usr/sbin/haproxy -Ws -f \$CONFIG -c -q \$EXTRAOPTS
ExecReload=/bin/kill -USR2 \$MAINPID
KillMode=mixed
Restart=always
SuccessExitStatus=143
Type=notify

[Install]
WantedBy=multi-user.target
END
}

MAIN() {
  InstallHaproxy
}

MAIN