#!/bin/bash

# ==========================================
# POTATONC GOD MODE HIJACKER V6 (DEBUG EDITION)
# Fitur: Hybrid Mocking + Deep Error Logging
# ==========================================

# --- KONFIGURASI GLOBAL ---
DOMAIN="cloud.potatonc.com"
GITHUB_USER="ica4me"
GITHUB_REPO="vpn-script-tunneling"
GITHUB_BRANCH="main"
GITHUB_BASE="https://raw.githubusercontent.com/${GITHUB_USER}/${GITHUB_REPO}/${GITHUB_BRANCH}"
MY_IP="127.0.0.1"
LOG_FILE="/root/LOG_CURL_DEBUG.txt"

# --- KONFIGURASI PORT ---
APACHE_PORT=8555
NGINX_PORT=81

# Warna
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# ==========================================
# 1. INISIALISASI
# ==========================================
clear
echo -e "${GREEN}[*] MEMULAI GOD MODE V6 (DEBUG LOGGING)...${NC}"
echo -e "${GREEN}[*] Log File akan disimpan di: $LOG_FILE${NC}"

if [ "$(id -u)" != "0" ]; then
    echo -e "${RED}[!] Harap jalankan sebagai root!${NC}"
    exit 1
fi

sed -i "/$DOMAIN/d" /etc/hosts

# Safety restore curl asli jika ada
if [ -f /usr/bin/curl_asli ]; then
    rm -f /usr/bin/curl
    mv /usr/bin/curl_asli /usr/bin/curl
fi

# Fix Locks & Dependencies
rm -rf /var/lib/dpkg/lock*
rm -rf /var/lib/apt/lists/lock
dpkg --configure -a

echo -e "${YELLOW}[*] Menyiapkan Environment...${NC}"
apt-get update -y
apt-get install -y gnupg2 ca-certificates lsb-release curl zip unzip nginx apache2

# ==========================================
# 2. SETTING PORT (8555 & 81)
# ==========================================
echo -e "${YELLOW}[*] Configuring Ports...${NC}"
systemctl stop nginx apache2

# --- APACHE (8555) ---
mkdir -p /etc/apache2/conf-available /etc/apache2/sites-available /etc/apache2/sites-enabled
touch /etc/apache2/apache2.conf /etc/apache2/envvars /etc/apache2/ports.conf

# Reset ports.conf
echo "Listen $APACHE_PORT" > /etc/apache2/ports.conf
echo "<IfModule ssl_module>" >> /etc/apache2/ports.conf
echo "    Listen 443" >> /etc/apache2/ports.conf
echo "</IfModule>" >> /etc/apache2/ports.conf
echo "<IfModule mod_gnutls.c>" >> /etc/apache2/ports.conf
echo "    Listen 443" >> /etc/apache2/ports.conf
echo "</IfModule>" >> /etc/apache2/ports.conf

sed -i "s/Listen 80/Listen $APACHE_PORT/g" /etc/apache2/ports.conf 2>/dev/null
sed -i "s/:80/:$APACHE_PORT/g" /etc/apache2/sites-available/*.conf
sed -i "s/:8080/:$APACHE_PORT/g" /etc/apache2/sites-available/*.conf

# --- NGINX (81) ---
mkdir -p /etc/nginx/conf.d
chmod 777 /etc/nginx/conf.d

cat > /etc/nginx/nginx.conf <<EOF
user  nginx;
worker_processes  auto;
error_log  /var/log/nginx/error.log notice;
pid        /var/run/nginx.pid;
events { worker_connections  1024; }
http {
    include       /etc/nginx/mime.types;
    default_type  application/octet-stream;
    log_format  main  '\$remote_addr - \$remote_user [\$time_local] "\$request" '
                      '\$status \$body_bytes_sent "\$http_referer" '
                      '"\$http_user_agent" "\$http_x_forwarded_for"';
    access_log  /var/log/nginx/access.log  main;
    sendfile        on;
    keepalive_timeout  65;
    include /etc/nginx/conf.d/*.conf;
}
EOF

cat > /etc/nginx/conf.d/default.conf <<EOF
server {
    listen       $NGINX_PORT;
    server_name  localhost;
    location / {
        root   /usr/share/nginx/html;
        index  index.html index.htm;
    }
    error_page   500 502 503 504  /50x.html;
    location = /50x.html { root   /usr/share/nginx/html; }
}
EOF

systemctl restart apache2
systemctl restart nginx

# ==========================================
# 3. DATA LISENSI PALSU (Source Local)
# ==========================================
echo -e "${YELLOW}[*] Membuat Data Bypass Lokal...${NC}"
mkdir -p /etc/hijack_data

# Auth Data
cat > /etc/hijack_data/auth.json <<EOF
{"statusCode":200,"status":"true","data":{"name_client":"Admin God Mode","chat_id":"123456","address":"$MY_IP","domain":"$DOMAIN","key_client":"potatopremium","x_api_client":"bypass-key","type_script":"premium","pemilik_client":"God","status":"active","script":"none","date_exp":"2099-12-31","limit_ip":"999"}}
EOF

# Version & Key
echo "latest" > /etc/hijack_data/version.txt
echo '{"status":"active","key":"potatopremium"}' > /etc/hijack_data/secure.json

# ==========================================
# 4. DNS SPOOFING
# ==========================================
echo "$MY_IP $DOMAIN" >> /etc/hosts

# ==========================================
# 5. CURL WRAPPER (DEBUGGING MODE)
# ==========================================
echo -e "${YELLOW}[*] Memasang Curl Wrapper dengan LOG PENCATAT ERROR...${NC}"

mv /usr/bin/curl /usr/bin/curl_asli

cat > /usr/bin/curl <<EOF
#!/bin/bash

# --- CONFIG ---
LOG_FILE="$LOG_FILE"
TARGET_DOMAIN="$DOMAIN"
GITHUB_BASE="$GITHUB_BASE"

# --- VARS ---
ARGS=("\$@")
NEW_ARGS=()
MODE="NORMAL"
LOCAL_SOURCE=""
OUTPUT_FILE=""
USE_HTTP_CODE=false
TARGET_URL_LOG=""

# --- PARSING ---
for ((i=0; i<\${#ARGS[@]}; i++)); do
    arg="\${ARGS[\$i]}"

    # Cek Output File (-o)
    if [[ "\$arg" == "-o" ]]; then
        next_index=\$((i + 1))
        OUTPUT_FILE="\${ARGS[\$next_index]}"
        NEW_ARGS+=("\$arg")
        continue
    fi
    
    # Cek flag http_code (-w)
    if [[ "\$arg" == *"-w"* ]] || [[ "\$arg" == *"http_code"* ]]; then
        USE_HTTP_CODE=true
        NEW_ARGS+=("\$arg")
        continue
    fi

    # Cek Target Domain
    if [[ "\$arg" == *"\$TARGET_DOMAIN"* ]]; then
        
        # === MODE MOCKING (Auth Lokal) ===
        if [[ "\$arg" == *"/v2/newspall/"* ]]; then
            MODE="MOCK"
            LOCAL_SOURCE="/etc/hijack_data/auth.json"
        elif [[ "\$arg" == *"/v2/info/"* ]]; then
            MODE="MOCK"
            LOCAL_SOURCE="/etc/hijack_data/auth.json"
        elif [[ "\$arg" == *"/v2/getversion"* ]]; then
            MODE="MOCK"
            LOCAL_SOURCE="/etc/hijack_data/version.txt"
        elif [[ "\$arg" == *"/v2/secure/getkeyandauth"* ]]; then
            MODE="MOCK"
            LOCAL_SOURCE="/etc/hijack_data/secure.json"
            
        # === MODE REDIRECT (Download GitHub) ===
        elif [[ "\$arg" == *"/v2/download/"* ]]; then
            MODE="REDIRECT"
            FILENAME=\$(basename "\$arg")
            if [[ "\$FILENAME" == "nginxdefault.conf" ]]; then
                REDIRECT_URL="\${GITHUB_BASE}/nginxdefault.conf" 
            else
                REDIRECT_URL="\${GITHUB_BASE}/\${FILENAME}"
            fi
            
            # Ganti URL di argumen
            NEW_ARGS+=("\$REDIRECT_URL")
            TARGET_URL_LOG="\$REDIRECT_URL"
            continue
            
        else
            # Default URL (tidak diubah)
            NEW_ARGS+=("\$arg")
        fi
        
    else
        NEW_ARGS+=("\$arg")
    fi
done

# --- EKSEKUSI ---

if [[ "\$MODE" == "MOCK" ]]; then
    # Mocking: Copy file lokal
    if [[ -n "\$OUTPUT_FILE" && -f "\$LOCAL_SOURCE" ]]; then
        cp "\$LOCAL_SOURCE" "\$OUTPUT_FILE"
        echo "[MOCK-SUCCESS] Copied \$LOCAL_SOURCE -> \$OUTPUT_FILE" >> "\$LOG_FILE"
    fi
    if [ "\$USE_HTTP_CODE" = true ]; then
        echo -n "200"
    fi
    exit 0

elif [[ "\$MODE" == "REDIRECT" ]]; then
    # Redirect: Download dari GitHub + LOGGING ERROR
    
    # Buat file temp untuk menangkap error
    STDERR_TMP=\$(mktemp)
    
    # Jalankan curl asli, tangkap stderr ke file temp
    /usr/bin/curl_asli "\${NEW_ARGS[@]}" 2> "\$STDERR_TMP"
    EXIT_CODE=\$?
    
    # Baca error
    ERROR_MSG=\$(cat "\$STDERR_TMP")
    rm "\$STDERR_TMP"
    
    # LOGGING
    if [ \$EXIT_CODE -ne 0 ]; then
        echo "================== [DOWNLOAD ERROR] ==================" >> "\$LOG_FILE"
        echo "Time      : \$(date)" >> "\$LOG_FILE"
        echo "Target    : \$TARGET_URL_LOG" >> "\$LOG_FILE"
        echo "Exit Code : \$EXIT_CODE" >> "\$LOG_FILE"
        echo "Error Log : \$ERROR_MSG" >> "\$LOG_FILE"
        echo "======================================================" >> "\$LOG_FILE"
    else
        echo "[DOWNLOAD-OK] \$TARGET_URL_LOG" >> "\$LOG_FILE"
    fi
    
    exit \$EXIT_CODE

else
    # Normal request
    /usr/bin/curl_asli "\$@"
    exit \$?
fi
EOF

chmod +x /usr/bin/curl
# Buat file log baru/kosong
echo "--- NEW SESSION LOG START ---" > $LOG_FILE
chmod 777 $LOG_FILE

# ==========================================
# 6. SELESAI
# ==========================================
echo -e "${GREEN}=============================================${NC}"
echo -e "${GREEN}   GOD MODE V6 INSTALLED (DEBUG MODE)        ${NC}"
echo -e "${GREEN}=============================================${NC}"
echo -e "Sekarang, jalankan script installer VPN Anda."
echo -e "Jika terjadi error 'Download Failed', segera cek log dengan perintah:"
echo -e "${YELLOW}cat $LOG_FILE${NC}"
echo -e ""