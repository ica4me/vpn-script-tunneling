#!/bin/bash

# ==========================================
# GOD MODE HIJACKER V3 (ULTIMATE FIX)
# Target: Debian 10/11/12 & Ubuntu 20.04/22.04/24.04
# Feature: Nginx 1.28.x Force, Smart Curl Rewrite, Port Isolation
# ==========================================

# --- KONFIGURASI ---
GITHUB_REPO_RAW="https://raw.githubusercontent.com/ica4me/vpn-script-tunneling/main"
TARGET_DOMAIN="cloud.potatonc.com"
MY_IP="127.0.0.1"
LOG_FILE="/var/log/godmode_hijack.log"

# Warna
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m'

clear
echo -e "${BLUE}=====================================================${NC}"
echo -e "${YELLOW}      GOD MODE HIJACKER V3 (NGINX/1.28.1 TARGET)     ${NC}"
echo -e "${BLUE}=====================================================${NC}"

# 1. CEK ROOT
if [ "$(id -u)" != "0" ]; then
    echo -e "${RED}[ERROR] Script harus dijalankan sebagai root!${NC}"
    exit 1
fi

# 2. PERSIAPAN LINGKUNGAN (MENCEGAH ERROR DPKG/APT)
echo -e "${GREEN}[+] Mempersiapkan Environment & Fix Log Error...${NC}"

# Hapus lock file jika ada
rm -f /var/lib/dpkg/lock-frontend
rm -f /var/lib/dpkg/lock
rm -f /var/cache/apt/archives/lock

# Fix struktur folder Apache yang sering error (sesuai log anda)
mkdir -p /etc/apache2/conf-available
mkdir -p /etc/apache2/sites-available
mkdir -p /etc/apache2/sites-enabled
[ ! -f /etc/apache2/envvars ] && touch /etc/apache2/envvars
[ ! -f /etc/apache2/apache2.conf ] && touch /etc/apache2/apache2.conf

# Fix struktur folder Nginx
mkdir -p /etc/nginx/conf.d
mkdir -p /etc/nginx/modules-enabled

# 3. INSTALL NGINX VERSI TERBARU (MAINLINE REPO)
echo -e "${GREEN}[+] Menginstall Nginx (Force Mainline Version)...${NC}"

# Install dependencies
apt-get update
apt-get install -y gnupg2 ca-certificates lsb-release ubuntu-keyring curl

# Deteksi OS untuk Repo Nginx
OS_ID=$(lsb_release -is | tr '[:upper:]' '[:lower:]')
OS_CODENAME=$(lsb_release -cs)

# Tambahkan Key & Repo Resmi Nginx
curl https://nginx.org/keys/nginx_signing.key | gpg --dearmor | tee /usr/share/keyrings/nginx-archive-keyring.gpg >/dev/null
echo "deb [signed-by=/usr/share/keyrings/nginx-archive-keyring.gpg] http://nginx.org/packages/mainline/${OS_ID} ${OS_CODENAME} nginx" | tee /etc/apt/sources.list.d/nginx.list

# Install Nginx
apt-get update
apt-get install -y nginx

# Verifikasi folder conf.d
sed -i 's/include \/etc\/nginx\/sites-enabled\/\*;/include \/etc\/nginx\/conf.d\/*.conf;/g' /etc/nginx/nginx.conf

# 4. INSTALL APACHE2 (SECONDARY)
echo -e "${GREEN}[+] Menginstall Apache2 (Secondary Port)...${NC}"
apt-get install -y apache2

# Ubah Port Apache ke 8555 & 8666 agar tidak bentrok dengan Nginx
sed -i 's/Listen 80/Listen 8555\nListen 8666/g' /etc/apache2/ports.conf
# Pastikan envvars terisi jika kosong
if [ ! -s /etc/apache2/envvars ]; then
    echo "export APACHE_RUN_USER=www-data" >> /etc/apache2/envvars
    echo "export APACHE_RUN_GROUP=www-data" >> /etc/apache2/envvars
    echo "export APACHE_LOG_DIR=/var/log/apache2" >> /etc/apache2/envvars
fi

# 5. PASANG FAKE DATA (MOCKING)
echo -e "${GREEN}[+] Membuat Data Lisensi Palsu (Bypass)...${NC}"
mkdir -p /etc/hijack_data

# Data Auth json
cat > /etc/hijack_data/auth_bypass.json <<EOF
{"statusCode":200,"status":"true","data":{"name_client":"GOD_MODE","chat_id":"0","address":"$(curl -s ifconfig.me)","domain":"google.com","key_client":"bypass","x_api_client":"bypass","type_script":"premium","pemilik_client":"Me","status":"active","script":"none","date_exp":"2099-12-31"}}
EOF

# Version
echo "latest" > /etc/hijack_data/version_bypass.txt

# Secure Key
echo '{"status":"active","key":"bypass"}' > /etc/hijack_data/secure_bypass.json

# 6. SETUP DNS SPOOFING
sed -i "/$TARGET_DOMAIN/d" /etc/hosts
echo "$MY_IP $TARGET_DOMAIN" >> /etc/hosts

# 7. PEMASANGAN CURL WRAPPER (SANGAT KRUSIAL)
echo -e "${GREEN}[+] Memasang Smart Curl Wrapper (Logic Rewrite)...${NC}"

# Backup Binary Asli
if [ -f /usr/bin/curl ]; then
    mv /usr/bin/curl /usr/bin/curl_orig
fi

# Buat Script Wrapper
cat > /usr/bin/curl <<EOF
#!/bin/bash

# ==========================================
# CURL HIJACKER V3 - LOGIC REWRITE
# ==========================================

LOG_FILE="$LOG_FILE"
TIMESTAMP=\$(date "+%Y-%m-%d %H:%M:%S")
ORIG_ARGS="\$@"
ARGS=("\$@")
NEW_ARGS=()

# Target Repos
REPO_AUTH="${GITHUB_REPO_RAW}/auth"
REPO_MAIN="${GITHUB_REPO_RAW}"

# Flag Trigger
IS_DOWNLOAD=0

for ((i=0; i<\${#ARGS[@]}; i++)); do
    ARG="\${ARGS[\$i]}"
    
    # 1. DETEKSI URL TARGET
    if [[ "\$ARG" == *"cloud.potatonc.com"* ]]; then
        
        # --- MAPPING KHUSUS (SESUAI REQUEST) ---
        
        # A. Auth Newspall
        if [[ "\$ARG" == *"/v2/newspall"* ]]; then
             NEW_URL="\${REPO_AUTH}/newspall"
             
        # B. Auth Info
        elif [[ "\$ARG" == *"/v2/info"* ]]; then
             NEW_URL="\${REPO_AUTH}/info"
             
        # C. Get Version
        elif [[ "\$ARG" == *"/v2/getversion"* ]]; then
             NEW_URL="\${REPO_AUTH}/getversion"
             
        # D. Secure GetKey
        elif [[ "\$ARG" == *"/v2/secure/getkeyandauth"* ]]; then
             NEW_URL="\${REPO_AUTH}/getkeyandauth"
             
        # --- MAPPING DOWNLOAD CONFIG (NGINX/APACHE) ---
        
        elif [[ "\$ARG" == *"/v2/download/"* ]]; then
             FILENAME=\$(basename "\$ARG")
             
             # Normalisasi nama file jika perlu
             case "\$FILENAME" in
                "nginxdefault.conf") REAL_FILE="nginxdefault.conf" ;;
                "publicagent.conf") REAL_FILE="publicagent.conf" ;;
                "bdsm.conf") REAL_FILE="bdsm.conf" ;;
                "stepsister.conf") REAL_FILE="stepsister.conf" ;;
                "nginxcdn") REAL_FILE="nginxcdn" ;; # p0t4t0.conf
                *) REAL_FILE="\$FILENAME" ;;
             esac
             
             # Arahkan ke root repo atau subfolder jika ada
             # Asumsi file config ada di root repo vpn-script-tunneling main branch?
             # Atau sesuaikan path ini:
             NEW_URL="\${REPO_MAIN}/\${REAL_FILE}"
             IS_DOWNLOAD=1
             
        else
             # Default Fallback
             NEW_URL="\$ARG"
        fi
        
        # Ganti Argument URL dengan URL Baru
        NEW_ARGS+=("\$NEW_URL")
        
        # Logging
        echo "[\$TIMESTAMP] HIJACK: \$ARG -> \$NEW_URL" >> \$LOG_FILE
        
    else
        # Argumen Biasa (Keep as is)
        NEW_ARGS+=("\$ARG")
    fi
done

# EKSEKUSI CURL ASLI DENGAN ARGUMEN BARU
/usr/bin/curl_orig -k -L "\${NEW_ARGS[@]}"
EXIT_CODE=\$?

exit \$EXIT_CODE
EOF

chmod +x /usr/bin/curl

# 8. FINISHING & RESTART SERVICE
echo -e "${GREEN}[+] Restarting Services...${NC}"

# Enable Services
systemctl enable nginx
systemctl enable apache2

# Restart Nginx
systemctl restart nginx
if systemctl is-active --quiet nginx; then
    echo -e "${GREEN} -> Nginx OK (Version: $(nginx -v 2>&1))${NC}"
else
    echo -e "${RED} -> Nginx Failed to Start! Cek config.${NC}"
fi

# Restart Apache
systemctl restart apache2
if systemctl is-active --quiet apache2; then
    echo -e "${GREEN} -> Apache2 OK (Listening on 8555/8666)${NC}"
else
    echo -e "${RED} -> Apache2 Failed to Start!${NC}"
fi

# Cek Port
echo -e "${YELLOW}[*] Listening Ports:${NC}"
ss -tulpn | grep -E 'nginx|apache'

echo -e "${GREEN}=====================================================${NC}"
echo -e "${GREEN}      INSTALLASI SELESAI - SIAP DI-BULLY SCRIPT LAIN ${NC}"
echo -e "${GREEN}=====================================================${NC}"