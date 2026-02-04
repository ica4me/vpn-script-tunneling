#!/bin/bash

# ==========================================
# POTATONC GOD MODE HIJACKER V5 (HYBRID FIX)
# Fitur: Apache Port 8555, Nginx Port 81
# Logic: Auth Local Mocking (100% Success) + Download Redirect
# ==========================================

# --- KONFIGURASI GLOBAL ---
DOMAIN="cloud.potatonc.com"
GITHUB_USER="ica4me"
GITHUB_REPO="vpn-script-tunneling"
GITHUB_BRANCH="main"
GITHUB_BASE="https://raw.githubusercontent.com/${GITHUB_USER}/${GITHUB_REPO}/${GITHUB_BRANCH}"
MY_IP="127.0.0.1"
LOG_FILE="/root/LOG_CURL_NEW.txt"

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
echo -e "${GREEN}[*] MEMULAI GOD MODE V5 (HYBRID FIX)...${NC}"
echo -e "${GREEN}[*] TARGET: Nginx=$NGINX_PORT | Apache=$APACHE_PORT${NC}"

if [ "$(id -u)" != "0" ]; then
    echo -e "${RED}[!] Harap jalankan sebagai root!${NC}"
    exit 1
fi

sed -i "/$DOMAIN/d" /etc/hosts

# Safety restore
if [ -f /usr/bin/curl_asli ]; then
    rm -f /usr/bin/curl
    mv /usr/bin/curl_asli /usr/bin/curl
fi

# Fix Locks
rm -rf /var/lib/dpkg/lock*
rm -rf /var/lib/apt/lists/lock
dpkg --configure -a

# ==========================================
# 2. INSTALL SERVER
# ==========================================
echo -e "${YELLOW}[*] Menyiapkan Repository & Menginstall Paket...${NC}"

apt-get update -y
apt-get install -y gnupg2 ca-certificates lsb-release ubuntu-keyring curl zip unzip

# Nginx Repo
if [ -f /etc/os-release ]; then
    . /etc/os-release
    OS=$ID
    CODENAME=$VERSION_CODENAME
fi
curl -s https://nginx.org/keys/nginx_signing.key | gpg --dearmor | tee /usr/share/keyrings/nginx-archive-keyring.gpg >/dev/null
echo "deb [signed-by=/usr/share/keyrings/nginx-archive-keyring.gpg] http://nginx.org/packages/mainline/${OS}/ ${CODENAME} nginx" | tee /etc/apt/sources.list.d/nginx.list

apt-get update -y
apt-get install -y nginx apache2

# ==========================================
# 3. SETTING PORT (8555 & 81)
# ==========================================
echo -e "${YELLOW}[*] Configuring Ports...${NC}"
systemctl stop nginx apache2

# --- APACHE (8555) ---
mkdir -p /etc/apache2/conf-available
mkdir -p /etc/apache2/sites-available
mkdir -p /etc/apache2/sites-enabled
touch /etc/apache2/apache2.conf
touch /etc/apache2/envvars
touch /etc/apache2/ports.conf

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
# 4. DATA LISENSI PALSU (Source Local)
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
# 5. DNS SPOOFING
# ==========================================
echo "$MY_IP $DOMAIN" >> /etc/hosts

# ==========================================
# 6. CURL WRAPPER HYBRID (THE FIX)
# ==========================================
echo -e "${YELLOW}[*] Memasang Curl Wrapper Hybrid...${NC}"

mv /usr/bin/curl /usr/bin/curl_asli

cat > /usr/bin/curl <<EOF
#!/bin/bash

# Config
LOG_FILE="$LOG_FILE"
TARGET_DOMAIN="$DOMAIN"
GITHUB_BASE="$GITHUB_BASE"

# Init Vars
ARGS=("\$@")
NEW_ARGS=()
MODE="NORMAL"
LOCAL_SOURCE=""
OUTPUT_FILE=""
USE_HTTP_CODE=false

# --- PARSING ---
for ((i=0; i<\${#ARGS[@]}; i++)); do
    arg="\${ARGS[\$i]}"

    # Cek Output File (-o)
    if [[ "\$arg" == "-o" ]]; then
        # Ambil argumen berikutnya sebagai nama file
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
        
        # === MODE MOCKING (Copy Lokal - GARANSI SUKSES) ===
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
            
        # === MODE REDIRECT (Download File dari GitHub) ===
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
            echo "[HIJACK-DL] \$arg -> \$REDIRECT_URL" >> "\$LOG_FILE"
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
    # Jika Mocking, kita copy file lokal ke target (-o)
    # Ini meniru perilaku V2 yang sukses
    
    if [[ -n "\$OUTPUT_FILE" && -f "\$LOCAL_SOURCE" ]]; then
        cp "\$LOCAL_SOURCE" "\$OUTPUT_FILE"
        echo "[HIJACK-MOCK] Copied \$LOCAL_SOURCE -> \$OUTPUT_FILE" >> "\$LOG_FILE"
    fi
    
    # Jika installer minta http_code (curl -w ...), kita print 200
    if [ "\$USE_HTTP_CODE" = true ]; then
        echo -n "200"
    fi
    
    exit 0

else
    # Jika Normal / Redirect, jalankan curl asli
    /usr/bin/curl_asli "\${NEW_ARGS[@]}"
    exit \$?
fi
EOF

chmod +x /usr/bin/curl
touch $LOG_FILE
chmod 777 $LOG_FILE

# ==========================================
# 7. SELESAI
# ==========================================
echo -e "${GREEN}=============================================${NC}"
echo -e "${GREEN}   GOD MODE INSTALLED (HYBRID STABLE)        ${NC}"
echo -e "${GREEN}=============================================${NC}"
echo -e "Status:"
echo -e "1. Apache2 Port    : $APACHE_PORT"
echo -e "2. Nginx Port      : $NGINX_PORT"
echo -e "3. Auth Method     : LOCAL MOCK (Anti-Gagal)"
echo -e "4. Download Source : GitHub Redirect"
echo -e ""
echo -e "${YELLOW}Silakan jalankan script installer VPN Anda sekarang.${NC}"