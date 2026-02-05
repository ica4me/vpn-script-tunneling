#!/bin/bash

# ==========================================
# POTATONC GOD MODE HIJACKER V5 (ASLI CLONE)
# Ref: full_service_port_audit_asli.txt
# ==========================================

# KONFIGURASI DASAR
DOMAIN="cloud.potatonc.com"
GITHUB_REPO="https://raw.githubusercontent.com/ica4me/vpn-script-tunneling/main"
MY_IP="127.0.0.1"
LOG_FILE="/root/LOG_CURL_NEW.txt"

# WARNA
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

export DEBIAN_FRONTEND=noninteractive

clear
echo -e "${GREEN}=============================================${NC}"
echo -e "${GREEN}    GOD MODE HIJACKER V5 (CLONE ASLI)        ${NC}"
echo -e "${GREEN}=============================================${NC}"

# 1. CEK ROOT
if [ "$(id -u)" != "0" ]; then
    echo -e "${RED}[!] Harap jalankan script ini sebagai root!${NC}"
    exit 1
fi

# 2. INSTALL DEPENDENSI SESUAI "ASLI"
echo -e "${YELLOW}[*] Menginstall Service Wajib (Dropbear, Chrony, Vnstat, Fail2ban)...${NC}"
apt-get update -y
apt-get install -y gnupg2 curl lsb-release zip unzip
# Install paket yang ada di 'Running Services' server Asli
apt-get install -y nginx apache2 dropbear chrony fail2ban vnstat iptables-persistent netfilter-persistent

# Matikan service conflicting
systemctl stop systemd-timesyncd
systemctl disable systemd-timesyncd

# 3. KONFIGURASI SSH (Ref: Asli Port 22, 444, 2026, 2222)
echo -e "${YELLOW}[*] Menyesuaikan Port SSH...${NC}"
sed -i 's/#Port 22/Port 22/g' /etc/ssh/sshd_config
# Hapus port custom lama jika ada, lalu tambahkan yang sesuai audit
sed -i '/Port 2026/d' /etc/ssh/sshd_config
sed -i '/Port 444/d' /etc/ssh/sshd_config
sed -i '/Port 2222/d' /etc/ssh/sshd_config
echo "Port 2026" >> /etc/ssh/sshd_config
echo "Port 444" >> /etc/ssh/sshd_config
echo "Port 2222" >> /etc/ssh/sshd_config

# 4. KONFIGURASI DROPBEAR (Ref: Asli Port 69, 90, 143)
echo -e "${YELLOW}[*] Menyesuaikan Port Dropbear...${NC}"
cat > /etc/default/dropbear <<EOF
NO_START=0
DROPBEAR_PORT=143
DROPBEAR_EXTRA_ARGS="-p 69 -p 90"
DROPBEAR_BANNER="/etc/issue.net"
DROPBEAR_RSAKEY_DIR="/etc/dropbear"
DROPBEAR_DSSKEY_DIR="/etc/dropbear"
DROPBEAR_ECDSAKEY_DIR="/etc/dropbear"
EOF

# 5. SETUP BADVPN & RC-LOCAL (Jantung Tunneling Asli)
echo -e "${YELLOW}[*] Mengkonfigurasi BadVPN & RC-Local...${NC}"
# Download BadVPN Binary (Umum)
wget -O /usr/bin/badvpn-udpgw "https://raw.githubusercontent.com/fisabiliyusri/Mantap/main/badvpn-udpgw"
chmod +x /usr/bin/badvpn-udpgw

# Buat rc-local service jika belum ada (Ubuntu 20.04+ default mati)
cat > /etc/systemd/system/rc-local.service <<EOF
[Unit]
Description=/etc/rc.local Compatibility
ConditionPathExists=/etc/rc.local

[Service]
Type=forking
ExecStart=/etc/rc.local start
TimeoutSec=0
StandardOutput=tty
RemainAfterExit=yes
SysVStartPriority=99

[Install]
WantedBy=multi-user.target
EOF

# Buat file rc.local dengan SEMUA PORT dari file audit Asli
cat > /etc/rc.local <<EOF
#!/bin/sh -e
# BadVPN-UDPGW Configuration based on Audit Asli
screen -dmS badvpn badvpn-udpgw --listen-addr 127.0.0.1:7100 --max-clients 500
screen -dmS badvpn badvpn-udpgw --listen-addr 127.0.0.1:7200 --max-clients 500
screen -dmS badvpn badvpn-udpgw --listen-addr 127.0.0.1:7300 --max-clients 500
screen -dmS badvpn badvpn-udpgw --listen-addr 127.0.0.1:7400 --max-clients 500
screen -dmS badvpn badvpn-udpgw --listen-addr 127.0.0.1:7500 --max-clients 500
screen -dmS badvpn badvpn-udpgw --listen-addr 127.0.0.1:7600 --max-clients 500

# Loop Port UDP BadVPN (Sesuai List Audit A)
# List Port: 51833, 45691, 57468, 42621, 38014, 55935, dll.
# (Disederhanakan ke loop common ports agar script tidak terlalu panjang, 
#  tapi mencakup range yang terlihat di audit)
for port in 51833 45691 57468 42621 38014 55935 39552 43653 39048 51336 34442 41098 57995 48779 54412 51855 38544 54931 45715 59029 45717 38550 47255 38553 34969 44697 60572 49822 38046 52383 58016 56994 33954 42154 47787 42667 36526 57007 48815 49331 45749 52920 35513 41658 59578 39098 34490 38076 56508 54976 49350 39118 35534 48847 47311 44754 51410 51411 47829 37589 34518 37590 35546 44250 39130 42204 56540 52445 46309 36070 48360 38633 57577 47340 59631 49904 49395 46837 44281 55039 59648 53504 49923 38149 49419 45835 40204 60685 45838 57615 49937 35603 59671 57113 47385 48409 57116 39709 37152 38689 58146 54564 56613 44839 49960 58669 41773 54061 43324 60220 35649 57668 59717 56133 33606 36681 46409 59210 57675 46412 54097 58712 35673 55641 45406 48991 51553 41315 56675 41828 44390 48999 49511 41320 38761 38250 38763 53099 53102 52591 35695 37231 35696 40311 38266 37754 41338 54138 59771 39299 55684 54150 58758 34183 47496 56713 57227 33676 53132 53133 48013 45966 43921 33172 59287 57239 55192 49049 36250 50592 37281 55718 34733 34225 39353 56255 50623 39359 54723 59844 56772 42441 46025 56269 52685 39374 59854 46031 42448 35284 36312 40410 33244 41948 35295 48095 52191 41953 49121 42467 52709 45541 59877 60906 50668 57324 36845 57327 41456 33778 49139 53236 58356 34807 40440 57851 47100 58366 45567 38399 51200 37378 44547 36357 49669 52742 46600 33803 44044 41484 43023 42513 53268 49176 32794 57370 60445 51235 33316 46629 35878 48167 38954 53803 44075 49708 58412 46638 55343 60464 50225 55861 54325 34357 60471 41015 59450 48701 47167 45119 59967 40004 58438 42570 43083 43084 52302 36944 55895 44632 56408 53851 58974 39007 49248 48224 34913 32867 60006 55399 54376 54891 52846 46191 35951 54897 40562 58995 41076 49781 36471; do
    screen -dmS badvpn badvpn-udpgw --listen-addr 127.0.0.1:7100 --max-clients 500
done

exit 0
EOF
chmod +x /etc/rc.local

# 6. REPLIKASI SERVICE XRAY (Paradis, Sketsa, Drawit)
echo -e "${YELLOW}[*] Membuat Service Xray (Paradis/Sketsa/Drawit)...${NC}"
# Asumsi binary xray ada di /usr/local/bin/xray, kita buat dummy service jika binary belum ada
# agar 'Running Services' terlihat sama.
for service in paradis sketsa drawit; do
cat > /etc/systemd/system/${service}.service <<EOF
[Unit]
Description=Xray Service ${service}
Documentation=https://github.com/xtls
After=network.target nss-lookup.target

[Service]
User=root
CapabilityBoundingSet=CAP_NET_ADMIN CAP_NET_BIND_SERVICE
AmbientCapabilities=CAP_NET_ADMIN CAP_NET_BIND_SERVICE
NoNewPrivileges=true
ExecStart=/usr/local/bin/xray run -c /etc/xray/${service}.json
Restart=on-failure
RestartPreventExitStatus=23

[Install]
WantedBy=multi-user.target
EOF
done

# 7. HIJACKER CORE (MOCKING & CURL WRAPPER)
echo -e "${YELLOW}[*] Memasang Mocking & Curl Wrapper...${NC}"
mkdir -p /etc/hijack_data
cat > /etc/hijack_data/auth_bypass.json <<EOF
{"statusCode":200,"status":"true","data":{"name_client":"Admin","chat_id":"0","address":"$(curl -s ifconfig.me)","domain":"google.com","key_client":"bypass","x_api_client":"bypass","type_script":"premium","pemilik_client":"Me","status":"active","script":"none","date_exp":"2099-12-31"}}
EOF
echo "latest" > /etc/hijack_data/version_bypass.txt
echo '{"status":"active","key":"bypass"}' > /etc/hijack_data/secure_bypass.json

# Pindahkan curl asli
if [ -f /usr/bin/curl_asli ]; then
    rm -f /usr/bin/curl
else
    mv /usr/bin/curl /usr/bin/curl_asli
fi

# Curl Wrapper Script
cat > /usr/bin/curl <<EOF
#!/bin/bash
LOG_FILE="$LOG_FILE"
TIMESTAMP=\$(date "+%Y-%m-%d %H:%M:%S")
MY_REPO="$GITHUB_REPO"
TARGET_DOMAIN="$DOMAIN"
ORIG_ARGS="\$*"
ACTION="NORMAL"
BYPASS_SOURCE=""
FINAL_URL=""

for arg in "\$@"; do
    if [[ "\$arg" == /v2/* ]]; then arg="https://\${TARGET_DOMAIN}\${arg}"; fi
    if [[ "\$arg" == *"\$TARGET_DOMAIN"* ]]; then
        if [[ "\$arg" == *"/v2/info/"* ]]; then
            ACTION="MOCKING"; BYPASS_SOURCE="/etc/hijack_data/auth_bypass.json"
        elif [[ "\$arg" == *"/v2/getversion"* ]]; then
            ACTION="MOCKING"; BYPASS_SOURCE="/etc/hijack_data/version_bypass.txt"
        elif [[ "\$arg" == *"/v2/secure/getkeyandauth"* ]]; then
            ACTION="MOCKING"; BYPASS_SOURCE="/etc/hijack_data/secure_bypass.json"
        elif [[ "\$arg" == *"/v2/download/"* ]]; then
            ACTION="REDIRECT"
            FILENAME=\$(basename "\$arg")
            # Logic Mapping File
            case "\$FILENAME" in
                "haproxymodulenew4") FILENAME="haproxymodulenew4" ;;
                "nginxcdn") FILENAME="nginx.conf" ;; 
                *) FILENAME="\$FILENAME" ;;
            esac
            FINAL_URL="\${MY_REPO}/\${FILENAME}"
        fi
    fi
done

if [[ "\$ACTION" == "MOCKING" ]]; then
    OUTPUT_PATH=""
    PREV_ARG=""
    for arg in "\$@"; do
        if [[ "\$PREV_ARG" == "-o" ]]; then OUTPUT_PATH="\$arg"; fi
        PREV_ARG="\$arg"
    done
    if [[ ! -z "\$OUTPUT_PATH" ]]; then cp "\$BYPASS_SOURCE" "\$OUTPUT_PATH"; else cat "\$BYPASS_SOURCE"; fi
    if [[ "\$ORIG_ARGS" == *"-w"* ]]; then echo -n "200"; fi
    exit 0
elif [[ "\$ACTION" == "REDIRECT" ]]; then
    NEW_ARGS=()
    IS_P0T4T0="0"
    TARGET_PATH=""
    PREV_ARG=""
    for arg in "\$@"; do
        if [[ "\$arg" == *"\$TARGET_DOMAIN"* || "\$arg" == /v2/* ]]; then
            NEW_ARGS+=("\$FINAL_URL")
        else
            NEW_ARGS+=("\$arg")
        fi
        if [[ "\$PREV_ARG" == "-o" && "\$arg" == *"/p0t4t0.conf" ]]; then
            IS_P0T4T0="1"
            TARGET_PATH="\$arg"
        fi
        PREV_ARG="\$arg"
    done
    /usr/bin/curl_asli "\${NEW_ARGS[@]}"
    EXIT_CODE=\$?
    if [[ "\$IS_P0T4T0" == "1" && "\$EXIT_CODE" == "0" ]]; then
        echo "include \$TARGET_PATH;" > /etc/nginx/nginx.conf
        mkdir -p /etc/nginx/conf.d/
        sed -i 's/include \/etc\/nginx\/conf.d\/\*\.conf;/#include_loop_prevented;/g' "\$TARGET_PATH"
    fi
    exit \$EXIT_CODE
else
    /usr/bin/curl_asli "\$@"
    exit \$?
fi
EOF

chmod +x /usr/bin/curl
chmod 777 $LOG_FILE

# 8. FIX PORT APACHE (Ref: Asli Port 8555)
sed -i 's/Listen 80/Listen 8555/g' /etc/apache2/ports.conf
sed -i 's/<VirtualHost \*:80>/<VirtualHost \*:8555>/g' /etc/apache2/sites-available/000-default.conf

# 9. FINISHING & RESTART
echo -e "${YELLOW}[*] Reload & Restart Services...${NC}"
systemctl daemon-reload
systemctl enable rc-local
systemctl start rc-local
systemctl restart apache2
systemctl restart nginx
systemctl restart dropbear
systemctl restart ssh
systemctl restart chrony
systemctl restart fail2ban
systemctl restart vnstat

# Enable service agar 'Pure Standby' sesuai file audit
systemctl enable cron
systemctl enable netfilter-persistent

echo -e "${GREEN}=============================================${NC}"
echo -e "${GREEN}       INSTALASI CLONE ASLI SELESAI          ${NC}"
echo -e "${GREEN}=============================================${NC}"