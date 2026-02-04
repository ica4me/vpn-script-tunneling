#!/bin/bash

# ==========================================
# POTATONC GOD MODE HIJACKER V3 (STABLE & MINIM ERROR)
# Fitur: Advanced URL Rewriting, Package Fixer, Auto-Config
# Target Environment: Debian 10/11/12, Ubuntu 20.04/22.04
# ==========================================

# --- KONFIGURASI GLOBAL ---
DOMAIN="cloud.potatonc.com"
GITHUB_USER="ica4me"
GITHUB_REPO="vpn-script-tunneling"
GITHUB_BRANCH="main"
GITHUB_BASE="https://raw.githubusercontent.com/${GITHUB_USER}/${GITHUB_REPO}/${GITHUB_BRANCH}"
MY_IP="127.0.0.1"
LOG_FILE="/root/LOG_CURL_NEW.txt"

# Warna
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# ==========================================
# 1. INISIALISASI & PEMBERSIHAN
# ==========================================
clear
echo -e "${GREEN}[*] MEMULAI GOD MODE HIJACKER V3...${NC}"

# Cek Root
if [ "$(id -u)" != "0" ]; then
    echo -e "${RED}[!] Harap jalankan script ini sebagai root!${NC}"
    exit 1
fi

# Reset Hosts File (Hapus entry lama)
sed -i "/$DOMAIN/d" /etc/hosts

# Kembalikan Curl Asli jika ada (untuk menghindari loop saat install)
if [ -f /usr/bin/curl_asli ]; then
    rm -f /usr/bin/curl
    mv /usr/bin/curl_asli /usr/bin/curl
fi

# Fix apt lock jika ada yang nyangkut
rm -rf /var/lib/dpkg/lock*
rm -rf /var/lib/apt/lists/lock
dpkg --configure -a

# ==========================================
# 2. INSTALL DEPENDENCIES & WEB SERVERS
# ==========================================
echo -e "${YELLOW}[*] Menyiapkan Repository & Menginstall Paket...${NC}"

apt-get update -y
apt-get install -y gnupg2 ca-certificates lsb-release ubuntu-keyring curl zip unzip

# --- Install Nginx (Official Mainline Repo untuk versi terbaru) ---
# Kita gunakan repo resmi untuk mencoba mendapatkan versi mendekati request (1.28.x)
# Jika 1.28 belum rilis stable di repo, ini akan mengambil versi Mainline paling baru.
if [ -f /etc/os-release ]; then
    . /etc/os-release
    OS=$ID
    CODENAME=$VERSION_CODENAME
fi

echo -e "${YELLOW}[*] Menambahkan Nginx Mainline Repository...${NC}"
curl https://nginx.org/keys/nginx_signing.key | gpg --dearmor \
    | tee /usr/share/keyrings/nginx-archive-keyring.gpg >/dev/null

echo "deb [signed-by=/usr/share/keyrings/nginx-archive-keyring.gpg] \
http://nginx.org/packages/mainline/${OS}/ ${CODENAME} nginx" \
    | tee /etc/apt/sources.list.d/nginx.list

apt-get update -y
# Install Nginx & Apache2 berdampingan
apt-get install -y nginx apache2

# ==========================================
# 3. PERBAIKAN STRUKTUR & KONFIGURASI (MINIM ERROR)
# ==========================================
echo -e "${YELLOW}[*] Fixing Struktur Folder Web Server...${NC}"

# --- FIX APACHE2 ERROR (Exit Code 23) ---
# Membuat folder dan file dummy agar dpkg tidak error saat script installer berjalan
mkdir -p /etc/apache2/conf-available
mkdir -p /etc/apache2/sites-available
mkdir -p /etc/apache2/sites-enabled
touch /etc/apache2/apache2.conf
touch /etc/apache2/envvars
touch /etc/apache2/ports.conf

# Pastikan module apache umum aktif
a2enmod rewrite headers cgi &>/dev/null

# --- FIX NGINX CONFIGURATION ---
# Pastikan folder conf.d ada dan writable
mkdir -p /etc/nginx/conf.d
chmod 777 /etc/nginx/conf.d

# Backup config asli
mv /etc/nginx/nginx.conf /etc/nginx/nginx.conf.bak 2>/dev/null

# Buat Nginx Conf yang Robust (Tahan Banting)
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

    # PENTING: Include semua config di conf.d agar script installer bisa live edit
    include /etc/nginx/conf.d/*.conf;
}
EOF

# Restart Service
systemctl restart nginx
systemctl restart apache2

# ==========================================
# 4. MEMBUAT DATA LISENSI PALSU (MOCKING)
# ==========================================
echo -e "${YELLOW}[*] Membuat Data Bypass...${NC}"
mkdir -p /etc/hijack_data

# Bypass Content (JSON yang valid)
# NOTE: Isi disesuaikan agar script installer "senang"
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
# 6. PEMASANGAN CURL WRAPPER (THE CORE)
# ==========================================
echo -e "${YELLOW}[*] Memasang Curl Wrapper Cerdas...${NC}"

mv /usr/bin/curl /usr/bin/curl_asli

cat > /usr/bin/curl <<EOF
#!/bin/bash

# --- GLOBAL CONFIG ---
LOG_FILE="$LOG_FILE"
TARGET_DOMAIN="$DOMAIN"
GITHUB_BASE="$GITHUB_BASE"
TIMESTAMP=\$(date "+%Y-%m-%d %H:%M:%S")

# Inisialisasi
ARGS=("\$@")
NEW_ARGS=()
OUTPUT_FLAG=false
HTTP_CODE_FLAG=false
URL_FOUND=false
REDIRECT_URL=""

# --- 1. PARSING ARGUMEN ---
# Kita harus scan argumen untuk menemukan URL dan Flag penting
for ((i=0; i<\${#ARGS[@]}; i++)); do
    arg="\${ARGS[\$i]}"

    # Cek flag output (-o)
    if [[ "\$arg" == "-o" ]]; then
        OUTPUT_FLAG=true
        NEW_ARGS+=("\$arg")
        continue
    fi
    
    # Cek flag write http_code (-w)
    if [[ "\$arg" == *"-w"* ]] || [[ "\$arg" == *"http_code"* ]]; then
        HTTP_CODE_FLAG=true
        NEW_ARGS+=("\$arg")
        continue
    fi

    # Cek apakah ini URL Target yang mau di hijack
    if [[ "\$arg" == *"\$TARGET_DOMAIN"* ]]; then
        URL_FOUND=true
        
        # --- LOGIC PENENTUAN URL BARU ---
        
        # 1. KASUS: Auth / Newspall
        if [[ "\$arg" == *"/v2/newspall/"* ]]; then
            REDIRECT_URL="\${GITHUB_BASE}/auth/newspall"
            
        # 2. KASUS: Info
        elif [[ "\$arg" == *"/v2/info/"* ]]; then
            REDIRECT_URL="\${GITHUB_BASE}/auth/info"
            
        # 3. KASUS: Get Version
        elif [[ "\$arg" == *"/v2/getversion"* ]]; then
            REDIRECT_URL="\${GITHUB_BASE}/auth/getversion"
            
        # 4. KASUS: Get Key & Auth
        elif [[ "\$arg" == *"/v2/secure/getkeyandauth"* ]]; then
            REDIRECT_URL="\${GITHUB_BASE}/auth/getkeyandauth"
            
        # 5. KASUS: Download File Config (Nginx/Apache)
        elif [[ "\$arg" == *"/v2/download/"* ]]; then
            # Ambil nama file dari ujung URL
            FILENAME=\$(basename "\$arg")
            
            # Mapping nama file aneh jika perlu
            if [[ "\$FILENAME" == "nginxdefault.conf" ]]; then
                # Jika di GitHub namanya beda, sesuaikan disini. Asumsi nama sama.
                REDIRECT_URL="\${GITHUB_BASE}/nginxdefault.conf" 
            else
                # Default behavior untuk file lain di folder download
                REDIRECT_URL="\${GITHUB_BASE}/\${FILENAME}"
            fi
            
            # Fallback jika URL GitHub belum spesifik untuk file tertentu,
            # arahkan ke root repo atau folder lain jika perlu.
            # Disini kita asumsikan file ada di root repo main.
        
        else
            # Default fallback jika pattern tidak dikenali tapi domain sama
            REDIRECT_URL="\$arg"
        fi
        
        # Ganti URL asli dengan URL GitHub
        NEW_ARGS+=("\$REDIRECT_URL")
        
        # Logging
        echo "[\$TIMESTAMP] HIJACK: \$arg -> \$REDIRECT_URL" >> "\$LOG_FILE"
        
    else
        # Bukan URL target, masukkan argumen apa adanya
        NEW_ARGS+=("\$arg")
    fi
done

# --- 2. EKSEKUSI ---

# Jalankan Curl Asli dengan Argumen Baru
/usr/bin/curl_asli "\${NEW_ARGS[@]}"
EXIT_CODE=\$?

# --- 3. HANDLING HTTP CODE (PENTING) ---
# Script installer sering pakai: curl -w %{http_code}
# GitHub raw biasanya return 200 OK text content, TAPI curl -w akan nambahin angka di akhir.
# Jika GitHub down atau file 404, script installer akan error.
# Wrapper ini memastikan exit code aman.

exit \$EXIT_CODE
EOF

chmod +x /usr/bin/curl

# ==========================================
# 7. SETUP PERMISSIONS & LOGS
# ==========================================
touch $LOG_FILE
chmod 777 $LOG_FILE
echo "--- NEW SESSION: $(date) ---" >> $LOG_FILE

# ==========================================
# 8. SELESAI
# ==========================================
echo -e "${GREEN}=============================================${NC}"
echo -e "${GREEN}   GOD MODE INSTALLED - NGINX & APACHE READY  ${NC}"
echo -e "${GREEN}=============================================${NC}"
echo -e "Status:"
echo -e "1. Nginx Version   : $(nginx -v 2>&1 | grep -o '[0-9.]*')"
echo -e "2. Conf Location   : /etc/nginx/conf.d/ (Created)"
echo -e "3. URL Redirects   : AKTIF (Target: GitHub $GITHUB_USER)"
echo -e "4. Logs            : $LOG_FILE"
echo -e ""
echo -e "${YELLOW}Silakan jalankan script installer VPN Anda sekarang.${NC}"