#!/bin/bash

export DEBIAN_FRONTEND=noninteractive

NIC=$(ip -4 route ls | grep default | grep -Po '(?<=dev )(\S+)' | head -1)

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

IPForward() {
  echo 1 > /proc/sys/net/ipv4/ip_forward
  echo "net.ipv4.ip_forward = 1" >> /etc/sysctl.conf
}

InstallOHP() {
  # FIX: Menggunakan variabel global $REPOSITORY
  DownloadFile "/usr/sbin/potatohp" "$REPOSITORY/potatohp" "OHP"
  chmod +x /usr/sbin/potatohp
  
  # get /etc/potato.ohp
  DownloadFile "/etc/potato.ohp" "$REPOSITORY/potato.ohp" "OHP"
  chmod +x /etc/potato.ohp
  
  # systemd ohp
  cat > /etc/systemd/system/potato-ohp.service <<-END
[Unit]
Description=/etc/potato.ohp
ConditionPathExists=/etc/potato.ohp
[Service]
Type=simple
ExecStart=/etc/potato.ohp start
TimeoutSec=0
StandardOutput=tty
RemainAfterExit=yes
SysVStartPriority=99
[Install]
WantedBy=multi-user.target
END
}

InstallOpenVPN() {
  DBCmd
  $PKG openvpn
  mkdir -p /var/www/html
  mkdir -p /etc/iptables
  
  local myip=$($DB "SELECT address FROM servers" | sed '/^$/d')
  local myip2="s/aldiblues/$myip/g"
  local dmn=$($DB "SELECT domain FROM servers" | sed '/^$/d')
  local is_domain="s/aldiblues/$dmn/g"
  
  # FIX: Nama file disesuaikan dengan standar repo Anda
  DownloadFile "/etc/openvpn/server.crt" "$REPOSITORY/openvpnserver.crt" "Cert-Server-OpenVPN"
  DownloadFile "/etc/openvpn/server.key" "$REPOSITORY/openvpnserver.key" "Key-Server-OpenVPN"
  DownloadFile "/etc/openvpn/ca.crt" "$REPOSITORY/openvpnca.crt" "Ca-OpenVPN"
  DownloadFile "/etc/openvpn/dh.pem" "$REPOSITORY/openvpndh.pem" "DH-OpenVPN"
  
  DownloadFile "/etc/openvpn/server-tcp-1194.conf" "$REPOSITORY/server-tcp-1194.conf" "Config-TCP"
  DownloadFile "/etc/openvpn/server-udp-25000.conf" "$REPOSITORY/server-udp-25000.conf" "Config-UDP"
  
  DownloadFile "/var/www/html/myvpn-tcp-80.ovpn" "$REPOSITORY/myvpn-tcp-80.ovpn" "OVPN-TCP"
  DownloadFile "/var/www/html/myvpn-ssl-443.ovpn" "$REPOSITORY/myvpn-ssl-443.ovpn" "OVPN-SSL"
  DownloadFile "/var/www/html/myvpn-udp-25000.ovpn" "$REPOSITORY/myvpn-udp-25000.ovpn" "OVPN-UDP"
  DownloadFile "/var/www/html/potato-ohp.ovpn" "$REPOSITORY/potato-ohp.ovpn" "OVPN-OHP"
  DownloadFile "/var/www/html/Potato-modem.ovpn" "$REPOSITORY/Potato-modem.ovpn" "OVPN-OHP-MODEM"
  
  systemctl enable openvpn@server-tcp-1194 > /dev/null 2>&1
  systemctl start openvpn@server-tcp-1194 > /dev/null 2>&1
  
  systemctl enable openvpn@server-udp-25000 > /dev/null 2>&1
  systemctl start openvpn@server-udp-25000 > /dev/null 2>&1
  
  # input ca & replace domain
  # [PENTING] Pastikan file OVPN di GitHub berisi kata 'aldiblues' pada baris remote
  sed -i $is_domain /var/www/html/myvpn-tcp-80.ovpn
  sed -i $is_domain /var/www/html/myvpn-ssl-443.ovpn
  sed -i $is_domain /var/www/html/myvpn-udp-25000.ovpn
  sed -i $is_domain /var/www/html/Potato-modem.ovpn
  sed -i $is_domain /var/www/html/potato-ohp.ovpn
  
{
echo "<ca>"
cat "/etc/openvpn/ca.crt"
echo "</ca>"
} >>/var/www/html/myvpn-tcp-80.ovpn

{
echo "<ca>"
cat "/etc/openvpn/ca.crt"
echo "</ca>"
} >>/var/www/html/myvpn-ssl-443.ovpn

{
echo "<ca>"
cat "/etc/openvpn/ca.crt"
echo "</ca>"
} >>/var/www/html/myvpn-udp-25000.ovpn

{
echo "<ca>"
cat "/etc/openvpn/ca.crt"
echo "</ca>"
} >>/var/www/html/Potato-modem.ovpn

{
echo "<ca>"
cat "/etc/openvpn/ca.crt"
echo "</ca>"
} >>/var/www/html/potato-ohp.ovpn
  
  zip -qq myvpn-config.zip /var/www/html/myvpn-tcp-80.ovpn /var/www/html/myvpn-ssl-443.ovpn /var/www/html/myvpn-udp-25000.ovpn /var/www/html/Potato-modem.ovpn /var/www/html/potato-ohp.ovpn
  
  mv myvpn-config.zip /var/www/html/
  
  InstallOHP
  
  if [[ -z $(iptables -L -t nat | grep "10.8.0.0") ]]; then
    iptables -t nat -A POSTROUTING -s 10.8.0.0/24 -o $NIC -j MASQUERADE
  fi
  if [[ -z $(iptables -L -t nat | grep "20.8.0.0") ]]; then
    iptables -t nat -A POSTROUTING -s 20.8.0.0/24 -o $NIC -j MASQUERADE
  fi
  iptables-save > /etc/iptables/rules.v4
  iptables-save > /etc/iptables.up.rules
  netfilter-persistent save
  netfilter-persistent reload
  service openvpn restart
  systemctl restart openvpn@server-tcp-1194 > /dev/null 2>&1
  systemctl restart openvpn@server-udp-25000 > /dev/null 2>&1
  systemctl enable potato-ohp > /dev/null 2>&1
  systemctl start potato-ohp > /dev/null 2>&1
}

MAIN() {
  InstallOpenVPN
  IPForward
}

MAIN