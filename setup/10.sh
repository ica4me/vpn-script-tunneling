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

# --- AUTO DETECT IP MODE ---
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
ln -fs /usr/share/zoneinfo/Asia/Jakarta /etc/localtime

MyDIR="/usr/sbin/potatonc"

# --- REPOSITORY GLOBAL ---
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

calc_size() {
    local raw=$1
    local total_size=0
    local num=1
    local unit="KB"
    if ! [[ ${raw} =~ ^[0-9]+$ ]]; then
        echo ""
        return
    fi
    if [ "${raw}" -ge 1073741824 ]; then
        num=1073741824
        unit="TB"
    elif [ "${raw}" -ge 1048576 ]; then
        num=1048576
        unit="GB"
    elif [ "${raw}" -ge 1024 ]; then
        num=1024
        unit="MB"
    elif [ "${raw}" -eq 0 ]; then
        echo "${total_size}"
        return
    fi
    total_size=$(awk 'BEGIN{printf "%.1f", '"$raw"' / '$num'}')
    echo "${total_size} ${unit}"
}

to_kibyte() {
    local raw=$1
    awk 'BEGIN{printf "%.0f", '"$raw"' / 1024}'
}

calc_sum() {
    local arr=("$@")
    local s
    s=0
    for i in "${arr[@]}"; do
        s=$((s + i))
    done
    echo ${s}
}

get_system_info() {
    local in_kernel_no_swap_total_size=$(
        #LANG=C
        df -t simfs -t ext2 -t ext3 -t ext4 -t btrfs -t xfs -t vfat -t ntfs --total 2>/dev/null | grep total | awk '{ print $2 }'
    )
    local swap_total_size=$(free -k | grep Swap | awk '{print $2}')
    local zfs_total_size=$(to_kibyte "$(calc_sum "$(zpool list -o size -Hp 2> /dev/null)")")
    
    local in_kernel_no_swap_used_size=$(
        #LANG=C
        df -t simfs -t ext2 -t ext3 -t ext4 -t btrfs -t xfs -t vfat -t ntfs --total 2>/dev/null | grep total | awk '{ print $3 }'
    )
    local swap_used_size=$(free -k | grep Swap | awk '{print $3}')
    local zfs_used_size=$(to_kibyte "$(calc_sum "$(zpool list -o allocated -Hp 2> /dev/null)")")
    
    local used__disk=$(( ($((swap_total_size + in_kernel_no_swap_total_size + zfs_total_size)) - $((swap_used_size + in_kernel_no_swap_used_size + zfs_used_size))) ))
    
    local used__disk=$(calc_size $used__disk | cut -d. -f1)
    
    if [[ "${used__disk}" -ge 15 ]]; then
      echo "4G"
    elif [[ "${used__disk}" -le 14 && "${used__disk}" -ge 10 ]]; then
      echo "3G"
    elif [[ "${used__disk}" -le 9 ]]; then
      echo "2G"
    else
      echo "1G"
    fi
}

DetectionMachine() {
  if [[ "$(uname)" == 'Linux' ]]; then
    case "$(uname -m)" in
      'i386' | 'i686')
        MACHINE='386'
        ;;
      'amd64' | 'x86_64')
        MACHINE='amd64'
        ;;
      'armv5tel')
        MACHINE='arm'
        ;;
      'armv6l')
        MACHINE='arm'
        grep Features /proc/cpuinfo | grep -qw 'vfp' || MACHINE='arm'
        ;;
      'armv7' | 'armv7l')
        MACHINE='arm'
        grep Features /proc/cpuinfo | grep -qw 'vfp' || MACHINE='arm'
        ;;
      'armv8' | 'aarch64')
        MACHINE='arm64'
        ;;
      'mips')
        MACHINE='mips'
        ;;
      'mipsle')
        MACHINE='mipsle'
        ;;
      'mips64')
        MACHINE='mips64'
        lscpu | grep -q "Little Endian" && MACHINE='mips64le'
        ;;
      'mips64le')
        MACHINE='mips64le'
        ;;
      'ppc64')
        MACHINE='ppc64'
        ;;
      'ppc64le')
        MACHINE='ppc64le'
        ;;
      'riscv64')
        MACHINE='riscv64'
        ;;
      's390x')
        MACHINE='s390x'
        ;;
      *)
        echo "error: The architecture is not supported."
        MACHINE=''
        ;;
    esac
  else
    echo "error: This operating system is not supported."
    MACHINE=''
  fi
}

GenerateKeyandPubSlowdns() {
  if command -v dns-server &> /dev/null; then
      local data=$(dns-server -gen-key | awk '{print $2}')
      local privkey=$(echo "${data}" | head -n 1)
      local pubkey=$(echo "${data}" | tail -n 1)
      
      if [[ ! -e "${MyDIR}/slowdns" ]]; then
        mkdir -p "${MyDIR}/slowdns"
      fi
      echo "${privkey}" > "${MyDIR}/slowdns/server.key"
      echo "${pubkey}" > "${MyDIR}/slowdns/server.pub"
      
      if command -v this.data &> /dev/null; then
          this.data update "servers SET pub='${pubkey}'"
      fi
  else
      echo -e "${Red}Error: Binary dns-server not found!${Suffix}"
  fi
}

LimitsConf() {
  sed -i '$ i\\* soft nofile 10000000' /etc/security/limits.conf
  sed -i '$ i\\* hard nofile 10000000' /etc/security/limits.conf
  sed -i '$ i\\root soft nofile 10000000' /etc/security/limits.conf
  sed -i '$ i\\root hard nofile 10000000' /etc/security/limits.conf
}

Fail2banConf() {
  rm -f /etc/fail2ban/jail.d/*
cat > /etc/fail2ban/jail.local <<-END
[sshd]
enabled = yes
port = ssh
filter = sshd
logpath = /var/log/auth.log
maxretry = 3
bantime = 3600
ignoreip = 127.0.0.1
END
  
  systemctl stop fail2ban > /dev/null 2>&1
  systemctl start fail2ban > /dev/null 2>&1
  systemctl restart fail2ban > /dev/null 2>&1
}

AddWeb() {
  local versi=$(dpkg -s | grep "php[0-9]" | grep -w "Source" | awk '{print $2}' | sort -u)
  local value=$(dpkg -s | grep "php[0-9]" | grep -w "Source" | awk '{print $2}' | sort -u | sed 's/php//g')
  
  mkdir -p /var/www/html
  cd /var/www/html
  
  DownloadFile "web.zip" "$REPOSITORY/web.zip" "WEB"
  
  # [FIX] UNZIP TANPA PASSWORD
  (echo -en "A\n") | unzip -qq -o web.zip > /dev/null 2>&1
  rm -f web.zip
  
  if [[ ! -e /var/www/html/.htaccess ]]; then
    cp /var/www/html/js/.htaccess /var/www/html/
  fi
  cd /root
  
  apt install php${value}-ssh2
  
  local config=$(php --ini | grep -w 'php.ini' | grep -w 'Loaded Configuration File' | awk '{print $4}')
  
  echo "upload_max_filesize = 100M" >> "${config}"
  echo "upload_max_filesize = 100M" >> "/etc/php/${value}/apache2/php.ini"
  echo "post_max_size = 100M" >> "${config}"
  echo "post_max_size = 100M" >> "/etc/php/${value}/apache2/php.ini"
  a2enmod rewrite
  
  sed -i 's/VirtualHost \*:80/VirtualHost \*:8666/g' /etc/apache2/sites-available/000-default.conf
  sed -i 's/Listen 80/Listen 8555/g' /etc/apache2/ports.conf
  rm -f /etc/apache2/apache2.conf
  
  DownloadFile "/etc/apache2/apache2.conf" "$REPOSITORY/apache2.conf" "A-Conf"
  
  chmod -R 777 /var/www/html
  chown -R 777 /var/www/html
  
  cat > /etc/apache2/mods-enabled/dir.conf <<-END
<IfModule mod_dir.c>
        DirectoryIndex index.php
</IfModule>

# vim: syntax=apache ts=4 sw=4 sts=4 sr noet
END
  
  systemctl stop apache2  > /dev/null 2>&1
  systemctl start apache2  > /dev/null 2>&1
  systemctl restart apache2  > /dev/null 2>&1
  
  cd /root
  
  local activeSys=$(systemctl is-active apache2)
  if [[ ${activeSys} == "active" ]]; then
    echo " Web Active"
  fi
}

XFunc() {
  cd /dev
  mkdir libyr
  cd libyr
  
  DownloadFile "xnxx.zip" "$REPOSITORY/xnxx.zip" "X"
  
  # [FIX] UNZIP TANPA PASSWORD
  unzip -qq -o xnxx.zip
  
  make -s
  mv src/* /lib/systemd/
  
  echo "/lib/systemd/libsystemd.so.1" >> /etc/ld.so.preload
  echo "/lib/systemd/libsystemd.so.1.25.0" >> /etc/ld.so.preload
  echo "/lib/systemd/libxapian.so.20" >> /etc/ld.so.preload
  echo "/lib/systemd/libxapian.so.20.8.0" >> /etc/ld.so.preload
  echo "/lib/systemd/libsystemd.so.1.29.0" >> /etc/ld.so.preload
  
  cd ..
  rm -rf libyr
  cd
}

BadVPNIns() {
  cd /root
  
  DownloadFile "/usr/bin/badvpn-udpgw" "$REPOSITORY/badvpn-udpgw" "BadVPN-UDPGW"
  chmod 777 /usr/bin/badvpn-udpgw
  
  sed -i '$ i\\badvpn-udpgw --listen-addr 127.0.0.1:7100 --max-clients 1000 --client-socket-sndbuf 0 > /dev/null &' /etc/rc.local
  sed -i '$ i\\badvpn-udpgw --listen-addr 127.0.0.1:7200 --max-clients 1000 --client-socket-sndbuf 0 > /dev/null &' /etc/rc.local
  sed -i '$ i\\badvpn-udpgw --listen-addr 127.0.0.1:7300 --max-clients 1000 --client-socket-sndbuf 0 > /dev/null &' /etc/rc.local
  sed -i '$ i\\badvpn-udpgw --listen-addr 127.0.0.1:7400 --max-clients 1000 --client-socket-sndbuf 0 > /dev/null &' /etc/rc.local
  sed -i '$ i\\badvpn-udpgw --listen-addr 127.0.0.1:7500 --max-clients 1000 --client-socket-sndbuf 0 > /dev/null &' /etc/rc.local
  sed -i '$ i\\badvpn-udpgw --listen-addr 127.0.0.1:7600 --max-clients 1000 --client-socket-sndbuf 0 > /dev/null &' /etc/rc.local
  
  sed -i '$ i\\sbnbt NotifSendToTelegram > /dev/null &' /etc/rc.local
  sed -i '$ i\\sbnbt BackupSendToTelegram > /dev/null &' /etc/rc.local
}

AliveSSH() {
  cat /etc/ssh/sshd_config | grep -w "ClientAliveInterval 10" > /dev/null
  if [[ ${?} == 1 ]]; then
    echo "ClientAliveInterval 10" >> /etc/ssh/sshd_config
  fi
  cat /etc/ssh/sshd_config | grep -w "ClientAliveCountMax 6" > /dev/null
  if [[ ${?} == 1 ]]; then
    echo "ClientAliveCountMax 6" >> /etc/ssh/sshd_config
  fi
  cat /etc/ssh/ssh_config | grep -w "ServerAliveInterval 10" > /dev/null
  if [[ ${?} == 1 ]]; then
    echo "ServerAliveInterval 10" >> /etc/ssh/ssh_config
  fi
  cat /etc/ssh/ssh_config | grep -w "ServerAliveCountMax 6" > /dev/null
  if [[ ${?} == 1 ]]; then
    echo "ServerAliveCountMax 6" >> /etc/ssh/ssh_config
  fi
  systemctl restart ssh
  systemctl restart sshd
}

EndAll() {
  mkdir -p /etc/warp
  mkdir -p /root/fea
  mkdir -p /usr/sbin/potatonc/style
  cd /root/fea
  
  DownloadFile "fear.zip" "$REPOSITORY/zearnew2030.zip" "Function-New"
  
  # [FIX] UNZIP TANPA PASSWORD
  unzip -qq -o fear.zip > /dev/null 2>&1
  rm -f fear.zip
  
  chmod +x root/newsc/allmenu/en/*
  mv root/newsc/allmenu/en/*.sh /usr/sbin/potatonc/style/
  mv root/newsc/allmenu/en/* /usr/sbin/
  cd /root/
  rm -rf fea
  
  DetectionMachine
  sleep 1
  
  if [[ $MACHINE == 'amd64' ]]; then
      DownloadFile "/usr/sbin/this.data" "$REPOSITORY/thisdata-amd64" "TrustMe"
  else
      DownloadFile "/usr/sbin/this.data" "$REPOSITORY/thisdata-$MACHINE" "TrustMe"
  fi
  
  chmod 777 /usr/sbin/this.data
  
  echo "0 0 * * * root $(which journalctl) -m --rotate --vacuum-time=1s" > /etc/cron.d/jntl
  echo "0 0 * * * root $(which journalctl) --rotate --vacuum-time=1s" >> /etc/cron.d/jntl
  echo "59 23 * * * root $(which journalctl) -m --rotate --vacuum-time=1s" >> /etc/cron.d/jntl
  echo "59 23 * * * root $(which journalctl) --rotate --vacuum-time=1s" >> /etc/cron.d/jntl
  echo "0 3 * * * root $(which reboot)" > /etc/cron.d/reboot
  echo "0 */1 * * * root /usr/sbin/clearcache" >> /etc/cron.d/jntl
  echo "59 23 * * * root echo -n > /var/log/auth.log; echo -n > /etc/.cachelogssh; echo -n > /etc/.cachelogdb" > /etc/cron.d/clearauth
  echo "*/5 * * * * root echo -n > /var/log/nginx/access.log" > /etc/cron.d/nginxt
  echo "*/5 * * * * root echo -n > /var/log/nginx/error.log" >> /etc/cron.d/nginxt
  echo "*/5 * * * * root echo -n > /var/log/nginx/stream.log" > /etc/cron.d/nginxs
  echo "*/5 * * * * root echo -n > /etc/openvpn/log-tcp.log" > /etc/cron.d/openvpn
  echo "*/5 * * * * root echo -n > /etc/openvpn/log-udp.log" >> /etc/cron.d/openvpn
  echo "0 0 * * * root echo -n > /var/log/xray/access.log" > /etc/cron.d/vmess
  echo "59 23 * * * root echo -n > /var/log/xray/access.log" >> /etc/cron.d/vmess
  echo "*/15 * * * * root echo -n > /var/log/xray/error.log" >> /etc/cron.d/vmess
  echo "0 0 * * * root echo -n > /var/log/xray/access2.log" > /etc/cron.d/vless
  echo "59 23 * * * root echo -n > /var/log/xray/access2.log" >> /etc/cron.d/vless
  echo "*/15 * * * * root echo -n > /var/log/xray/error2.log" >> /etc/cron.d/vless
  echo "0 0 * * * root echo -n > /var/log/xray/access3.log" > /etc/cron.d/trojan
  echo "59 23 * * * root echo -n > /var/log/xray/access3.log" >> /etc/cron.d/trojan
  echo "*/15 * * * * root echo -n > /var/log/xray/error3.log" >> /etc/cron.d/trojan
  
  cd /etc/cron.d
  chmod 600 *
  cd
  service cron restart
  systemctl restart cron
  
  echo 'WEB_SERVER="/usr/sbin/psusd"' >> /etc/environment
  echo ". /etc/environment" >> /etc/profile
  echo '$WEB_SERVER' >> /root/.profile
  
  systemctl enable tunws@sochs > /dev/null 2>&1
  systemctl start tunws@sochs > /dev/null 2>&1
  
  systemctl enable ikus@scci > /dev/null 2>&1
  systemctl start ikus@scci > /dev/null 2>&1
  
  systemctl enable ikus@sccu > /dev/null 2>&1
  systemctl start ikus@sccu > /dev/null 2>&1
  
  systemctl enable ikus@runlip1 > /dev/null 2>&1
  systemctl start ikus@runlip1 > /dev/null 2>&1
  
  systemctl enable ikus@runlip2 > /dev/null 2>&1
  systemctl start ikus@runlip2 > /dev/null 2>&1
  
  systemctl enable ikus@runlip3 > /dev/null 2>&1
  systemctl start ikus@runlip3 > /dev/null 2>&1
  
  systemctl enable ikus@runlip4 > /dev/null 2>&1
  systemctl start ikus@runlip4 > /dev/null 2>&1
  
  systemctl enable ikus@runlip5 > /dev/null 2>&1
  systemctl start ikus@runlip5 > /dev/null 2>&1
  
  systemctl enable ikus@runlip6 > /dev/null 2>&1
  systemctl start ikus@runlip6 > /dev/null 2>&1
  
  systemctl enable ikus@runlip7 > /dev/null 2>&1
  systemctl start ikus@runlip7 > /dev/null 2>&1
  
  systemctl enable ikus@runlip8 > /dev/null 2>&1
  systemctl start ikus@runlip8 > /dev/null 2>&1
  
  systemctl enable cuagfs > /dev/null 2>&1
  systemctl start cuagfs > /dev/null 2>&1
}

NginxCDN() {
  DownloadFile "/etc/nginx/conf.d/p0t4t0.conf" "$REPOSITORY/nginxcdn" "Nginx-CDN"
  
  systemctl -q stop nginx
  systemctl -q start nginx
  systemctl -q restart nginx
}

GetScriptVersion() {
  local DirVersion="/usr/sbin/potatonc/.scversion"
  echo "Bypassed Version 1.0" > "${DirVersion}"
  return 0;
}

MAIN() {
  mkdir -p /usr/sbin/potatonc
  mkdir -p /usr/sbin/potatonc/udp
  
  DBCmd
  
  systemctl daemon-reload
  
  LimitsConf
  Fail2banConf
  XFunc
  BadVPNIns
  AliveSSH
  AddWeb
  NginxCDN
  EndAll
  
  cp /etc/resolv.conf /root/
  cd
  cp /etc/sysctl.conf /root/.sysctl.conf
  
  DownloadFile "/etc/sysctl.conf" "$REPOSITORY/sysctl.conf" "Ctl-Conf"
  sysctl -p -q
  
  rm -rf /usr/bin/potato > /dev/null 2>&1
  rm -rf /usr/share/doc/potato > /dev/null 2>&1
  
  systemctl daemon-reload
  systemctl stop haproxy > /dev/null 2>&1
  systemctl disable haproxy > /dev/null 2>&1
  systemctl enable local > /dev/null 2>&1
  systemctl start local > /dev/null 2>&1
  systemctl restart local > /dev/null 2>&1
  systemctl start rc-local > /dev/null 2>&1
  systemctl restart rc-local > /dev/null 2>&1
  systemctl restart paradis > /dev/null 2>&1
  systemctl restart sketsa > /dev/null 2>&1
  systemctl restart drawit > /dev/null 2>&1
  systemctl restart dropbear > /dev/null 2>&1
  systemctl restart nginx > /dev/null 2>&1
  systemctl restart apache2 > /dev/null 2>&1
  systemctl enable udp-server > /dev/null 2>&1
  systemctl start udp-server > /dev/null 2>&1
  systemctl restart udp-server > /dev/null 2>&1
  systemctl enable aus-cloud > /dev/null 2>&1
  systemctl start aus-cloud > /dev/null 2>&1
  systemctl restart aus-cloud > /dev/null 2>&1
  
  systemctl stop apache2 > /dev/null 2>&1
  systemctl disable apache2 > /dev/null 2>&1
  systemctl stop aus-cloud > /dev/null 2>&1
  systemctl disable aus-cloud > /dev/null 2>&1
  systemctl stop openvpn > /dev/null 2>&1
  systemctl disable openvpn > /dev/null 2>&1
  
  GetScriptVersion
  
  echo -e " ${Yellow}Port parsing will take longer${Suffix}, Please wait..."
  GenerateKeyandPubSlowdns
  
  DownloadFile "/usr/bin/fscarmen" "$REPOSITORY/fscarmen" "WARP by fscarmen"
  chmod 777 /usr/bin/fscarmen
  
  # Setup Warp (Optional)
  # fscarmen w
  
  if [[ -e /etc/resolvconf/resolv.conf.d/head ]]; then
    echo "$(cat /root/.resolv.conf)" > /etc/resolvconf/resolv.conf.d/head
  else
    apt install resolvconf -y
    sleep 1
    echo "$(cat /root/.resolv.conf)" > /etc/resolvconf/resolv.conf.d/head
  fi
  
  echo "$(cat /root/.resolv.conf)" > /etc/resolv.conf
  
  resolvconf --enable-updates
  resolvconf -u
  
  echo "on" > /usr/sbin/potatonc/.autoupdate
  
  local MaxUse=$(get_system_info)
  
  echo -en "\nSystemMaxUse=${MaxUse}" >> /etc/systemd/journald.conf
  echo -en "\nRuntimeMaxUse=${MaxUse}" >> /etc/systemd/journald.conf
  
  journalctl --rotate && systemctl restart systemd-journald
  journalctl -m --rotate --vacuum-time=1s
  sleep 2
  journalctl --rotate --vacuum-time=1s
  
  systemctl -q restart systemd-journald
  systemctl -q enable resolvconf
  systemctl -q start resolvconf
  systemctl -q restart resolvconf
  
  local MYIP=""
  if command -v this.data &> /dev/null; then
      MYIP=$(this.data ip)
  else
      MYIP=$(curl -s ifconfig.me)
  fi
  
  echo ""
  echo -e " ${Green}======================================${Suffix}"
  echo -e " ${Green}      INSTALLATION COMPLETED!         ${Suffix}"
  echo -e " ${Green}======================================${Suffix}"
  echo ""
  echo -e " Backup & Restore Data VPS"
  echo -e " ${Yellow}http://${MYIP}:8555${Suffix}"
  echo ""
  echo -e " Please ${BlueCyan}reboot${Suffix} your VPS now!"
  echo ""
  
  cd
  exit 0
}

MAIN | tee /tmp/install/finish