#!/bin/bash

# ==========================================
# POTATONC GOD MODE HIJACKER V4 (FIX CONF)
# Fix: Mengizinkan p0t4t0.conf sebagai Master Config
# ==========================================

# KONFIGURASI
DOMAIN="cloud.potatonc.com"
GITHUB_REPO="https://raw.githubusercontent.com/ica4me/vpn-script-tunneling/main"
MY_IP="127.0.0.1"
LOG_FILE="/root/LOG_CURL_NEW.txt"

# Warna
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

export DEBIAN_FRONTEND=noninteractive

clear
echo -e "${GREEN}=============================================${NC}"
echo -e "${GREEN}    GOD MODE HIJACKER V4 (FIX NGINX)         ${NC}"
echo -e "${GREEN}=============================================${NC}"

# 1. Cek Root
if [ "$(id -u)" != "0" ]; then
    echo -e "${RED}[!] Harap jalankan script ini sebagai root!${NC}"
    exit 1
fi

# 2. Kill Process
systemctl stop nginx apache2 > /dev/null 2>&1
killall -9 nginx apache2 php-fpm > /dev/null 2>&1

# 3. Mocking Data (Tetap)
mkdir -p /etc/hijack_data
cat > /etc/hijack_data/auth_bypass.json <<EOF
{"statusCode":200,"status":"true","data":{"name_client":"Admin","chat_id":"0","address":"$(curl -s ifconfig.me)","domain":"google.com","key_client":"bypass","x_api_client":"bypass","type_script":"premium","pemilik_client":"Me","status":"active","script":"none","date_exp":"2099-12-31"}}
EOF
echo "latest" > /etc/hijack_data/version_bypass.txt
echo '{"status":"active","key":"bypass"}' > /etc/hijack_data/secure_bypass.json

# 4. Install Nginx & Apache
echo -e "${YELLOW}[*] Menginstall Nginx & Apache2...${NC}"
apt-get update -y
apt-get install -y gnupg2 curl lsb-release

# Add Nginx Repo (Mainline)
OS=$(lsb_release -is | tr '[:upper:]' '[:lower:]')
CODENAME=$(lsb_release -cs)
if [ "$OS" == "ubuntu" ]; then
    curl https://nginx.org/keys/nginx_signing.key | gpg --dearmor | tee /usr/share/keyrings/nginx-archive-keyring.gpg >/dev/null
    echo "deb [signed-by=/usr/share/keyrings/nginx-archive-keyring.gpg] http://nginx.org/packages/mainline/ubuntu $CODENAME nginx" | tee /etc/apt/sources.list.d/nginx.list
elif [ "$OS" == "debian" ]; then
    curl https://nginx.org/keys/nginx_signing.key | gpg --dearmor | tee /usr/share/keyrings/nginx-archive-keyring.gpg >/dev/null
    echo "deb [signed-by=/usr/share/keyrings/nginx-archive-keyring.gpg] http://nginx.org/packages/mainline/debian $CODENAME nginx" | tee /etc/apt/sources.list.d/nginx.list
fi

apt-get update -y
apt-get install -y nginx apache2 zip unzip

# 5. FIX PORT APACHE (Agar tidak bentrok 80)
sed -i 's/Listen 80/Listen 8555/g' /etc/apache2/ports.conf
sed -i 's/<VirtualHost \*:80>/<VirtualHost \*:8555>/g' /etc/apache2/sites-available/000-default.conf

# 6. FIX NGINX STRUCTURE (Bagian Penting)
echo -e "${YELLOW}[*] Mempersiapkan Folder Nginx...${NC}"
mkdir -p /etc/nginx/conf.d
chmod -R 777 /etc/nginx/conf.d

# DNS Spoofing
sed -i "/$DOMAIN/d" /etc/hosts
echo "$MY_IP $DOMAIN" >> /etc/hosts

# 7. PASANG CURL WRAPPER (Updated Logic)
if [ -f /usr/bin/curl_asli ]; then
    rm -f /usr/bin/curl
else
    mv /usr/bin/curl /usr/bin/curl_asli
fi

cat > /usr/bin/curl <<EOF
#!/bin/bash

# --- KONFIGURASI WRAPPER ---
LOG_FILE="$LOG_FILE"
TIMESTAMP=\$(date "+%Y-%m-%d %H:%M:%S")
MY_REPO="$GITHUB_REPO"
TARGET_DOMAIN="$DOMAIN"

ORIG_ARGS="\$*"
ACTION="NORMAL"
BYPASS_SOURCE=""
FINAL_URL=""

# --- ANALISA ARGUMEN ---
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
            # Mapping Nama File
            case "\$FILENAME" in
                "haproxymodulenew4") FILENAME="haproxymodulenew4" ;;
                "nginxcdn") FILENAME="nginx.conf" ;; 
                *) FILENAME="\$FILENAME" ;;
            esac
            FINAL_URL="\${MY_REPO}/\${FILENAME}"
        fi
    fi
done

# --- EKSEKUSI ---
if [[ "\$ACTION" == "MOCKING" ]]; then
    # Cari output file (-o)
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
    # Rebuild Args
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
        
        # Cek jika target download adalah p0t4t0.conf
        if [[ "\$PREV_ARG" == "-o" && "\$arg" == *"/p0t4t0.conf" ]]; then
            IS_P0T4T0="1"
            TARGET_PATH="\$arg"
        fi
        PREV_ARG="\$arg"
    done
    
    # Jalankan Curl
    /usr/bin/curl_asli "\${NEW_ARGS[@]}"
    EXIT_CODE=\$?
    
    # === AUTO FIX KHUSUS p0t4t0.conf ===
    if [[ "\$IS_P0T4T0" == "1" && "\$EXIT_CODE" == "0" ]]; then
        # 1. Pastikan nginx.conf utama hanya memanggil p0t4t0.conf
        echo "include \$TARGET_PATH;" > /etc/nginx/nginx.conf
        mkdir -p /etc/nginx/conf.d/ # Jaga-jaga
        
        # 2. Hapus baris 'include *.conf' di dalam p0t4t0.conf agar tidak LOOPING
        #    Karena file ini ada di conf.d, jika dia include conf.d/*.conf, dia akan panggil dirinya sendiri.
        sed -i 's/include \/etc\/nginx\/conf.d\/\*\.conf;/#include_loop_prevented;/g' "\$TARGET_PATH"
        
        # 3. Log Fix
        echo "[\$TIMESTAMP] [AUTO-FIX] Configured nginx.conf -> \$TARGET_PATH & Removed Loop." >> "\$LOG_FILE"
    fi
    
    exit \$EXIT_CODE

else
    /usr/bin/curl_asli "\$@"
    exit \$?
fi
EOF

chmod +x /usr/bin/curl
chmod 777 $LOG_FILE

# 8. Service Restart
echo -e "${YELLOW}[*] Restarting Services...${NC}"
systemctl daemon-reload
systemctl restart apache2
systemctl restart nginx

echo -e "${GREEN}=============================================${NC}"
echo -e "${GREEN}          INSTALASI SELESAI (V4)             ${NC}"
echo -e "${GREEN}=============================================${NC}"
echo -e "Sekarang p0t4t0.conf akan otomatis dijadikan Master Config"
echo -e "setelah didownload oleh script installer Anda."