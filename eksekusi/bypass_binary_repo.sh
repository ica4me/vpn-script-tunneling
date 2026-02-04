#!/bin/bash

# ==========================================
# POTATONC GOD MODE HIJACKER V3 (STABLE & LIVE EDIT)
# Fix: Nginx 1.28.1 Source Compile, Apache Port 8555
# Support: Debian 10+, Ubuntu 20.04+
# ==========================================

# --- KONFIGURASI ---
DOMAIN="cloud.potatonc.com"
GITHUB_REPO="https://raw.githubusercontent.com/ica4me/vpn-script-tunneling/main"
MY_IP="127.0.0.1"
LOG_FILE="/root/LOG_CURL_HIJACK.txt"
NGINX_VER="1.28.1" # Versi yang dipaksa (Jika belum rilis, script akan fallback ke stable)

# --- WARNA ---
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

clear
echo -e "${GREEN}=============================================${NC}"
echo -e "${GREEN}   GOD MODE HIJACKER V3 (NGINX ${NGINX_VER})   ${NC}"
echo -e "${GREEN}=============================================${NC}"

if [ "$(id -u)" != "0" ]; then
   echo -e "${RED}[!] Harap jalankan script ini sebagai root!${NC}"
   exit 1
fi

# ==========================================
# 1. PERSIAPAN SISTEM & DEPENDENSI
# ==========================================
echo -e "${YELLOW}[*] Update repository & Install Dependencies...${NC}"
apt-get update -y
# Install build tools untuk compile nginx & tools dasar
apt-get install -y build-essential libpcre3 libpcre3-dev zlib1g zlib1g-dev libssl-dev unzip curl gnupg2 ca-certificates lsb-release

# ==========================================
# 2. PERSIAPAN DATA BYPASS (MOCKING)
# ==========================================
echo -e "${YELLOW}[*] Membuat Data Lisensi Palsu (Bypass)...${NC}"
mkdir -p /etc/hijack_data

# Data Mocking (JSON Valid)
cat > /etc/hijack_data/auth_bypass.json <<EOF
{"statusCode":200,"status":"true","data":{"name_client":"Admin","chat_id":"0","address":"$(curl -s ifconfig.me)","domain":"google.com","key_client":"bypass","x_api_client":"bypass","type_script":"premium","pemilik_client":"Me","status":"active","script":"none","date_exp":"2099-12-31"}}
EOF
echo "latest" > /etc/hijack_data/version_bypass.txt
echo '{"status":"active","key":"bypass"}' > /etc/hijack_data/secure_bypass.json

# ==========================================
# 3. INSTALL APACHE2 (PORT 8555)
# ==========================================
echo -e "${YELLOW}[*] Mengkonfigurasi Apache2 di Port 8555...${NC}"
apt-get install apache2 -y

# Fix Error Envvars (Sesuai Log Error Anda)
mkdir -p /etc/apache2
touch /etc/apache2/envvars
if ! grep -q "APACHE_RUN_USER" /etc/apache2/envvars; then
    echo "export APACHE_RUN_USER=www-data" >> /etc/apache2/envvars
    echo "export APACHE_RUN_GROUP=www-data" >> /etc/apache2/envvars
    echo "export APACHE_PID_FILE=/var/run/apache2/apache2.pid" >> /etc/apache2/envvars
    echo "export APACHE_RUN_DIR=/var/run/apache2" >> /etc/apache2/envvars
    echo "export APACHE_LOCK_DIR=/var/lock/apache2" >> /etc/apache2/envvars
    echo "export APACHE_LOG_DIR=/var/log/apache2" >> /etc/apache2/envvars
fi

# Ubah Port Apache ke 8555 agar tidak bentrok dengan Nginx
sed -i "s/Listen 80/Listen 8555/g" /etc/apache2/ports.conf
sed -i "s/<VirtualHost \*:80>/<VirtualHost \*:8555>/g" /etc/apache2/sites-available/000-default.conf

# Restart Apache
systemctl restart apache2

# ==========================================
# 4. INSTALL NGINX (COMPILE SOURCE / REPO)
# ==========================================
echo -e "${YELLOW}[*] Menyiapkan Nginx...${NC}"

# Hapus Nginx bawaan jika ada
apt-get remove nginx nginx-common nginx-full -y --purge

# Cek apakah kita compile atau install repo (Untuk versi 1.28.1 kita coba compile)
# Jika versi source tidak ditemukan, fallback ke main repo
echo -e "${YELLOW}[*] Mencoba Compile Nginx ${NGINX_VER}...${NC}"

cd /tmp
wget http://nginx.org/download/nginx-${NGINX_VER}.tar.gz
if [ $? -eq 0 ]; then
    tar -zxvf nginx-${NGINX_VER}.tar.gz
    cd nginx-${NGINX_VER}
    ./configure --prefix=/etc/nginx \
                --sbin-path=/usr/sbin/nginx \
                --conf-path=/etc/nginx/nginx.conf \
                --error-log-path=/var/log/nginx/error.log \
                --http-log-path=/var/log/nginx/access.log \
                --pid-path=/var/run/nginx.pid \
                --lock-path=/var/run/nginx.lock \
                --http-client-body-temp-path=/var/cache/nginx/client_temp \
                --http-proxy-temp-path=/var/cache/nginx/proxy_temp \
                --http-fastcgi-temp-path=/var/cache/nginx/fastcgi_temp \
                --http-uwsgi-temp-path=/var/cache/nginx/uwsgi_temp \
                --http-scgi-temp-path=/var/cache/nginx/scgi_temp \
                --user=nginx \
                --group=nginx \
                --with-http_ssl_module \
                --with-http_realip_module \
                --with-http_stub_status_module \
                --with-threads
    make
    make install
    echo -e "${GREEN}[OK] Nginx ${NGINX_VER} Compiled!${NC}"
else
    echo -e "${RED}[!] Source ${NGINX_VER} tidak ditemukan (belum rilis?), Menggunakan Repository Resmi Nginx.${NC}"
    # Fallback ke Repo Resmi
    curl https://nginx.org/keys/nginx_signing.key | gpg --dearmor \
        | tee /usr/share/keyrings/nginx-archive-keyring.gpg >/dev/null
    echo "deb [signed-by=/usr/share/keyrings/nginx-archive-keyring.gpg] \
    http://nginx.org/packages/mainline/ubuntu `lsb_release -cs` nginx" \
        | tee /etc/apt/sources.list.d/nginx.list
    apt-get update
    apt-get install nginx -y
fi

# Buat User Nginx jika belum ada
id -u nginx &>/dev/null || useradd -r -s /sbin/nologin nginx
mkdir -p /var/cache/nginx

# PASTIKAN CONFIG DISIMPAN DI CONF.D
echo -e "${YELLOW}[*] Memaksa struktur config ke /etc/nginx/conf.d/...${NC}"
mkdir -p /etc/nginx/conf.d
mkdir -p /etc/nginx/sites-enabled
mkdir -p /etc/nginx/sites-available

# Tulis Nginx.conf Utama yang membaca conf.d
cat > /etc/nginx/nginx.conf <<EOF
user nginx;
worker_processes auto;
pid /var/run/nginx.pid;
include /etc/nginx/modules-enabled/*.conf;

events {
    worker_connections 768;
}

http {
    sendfile on;
    tcp_nopush on;
    tcp_nodelay on;
    keepalive_timeout 65;
    types_hash_max_size 2048;

    include /etc/nginx/mime.types;
    default_type application/octet-stream;

    ssl_protocols TLSv1 TLSv1.1 TLSv1.2 TLSv1.3;
    ssl_prefer_server_ciphers on;

    access_log /var/log/nginx/access.log;
    error_log /var/log/nginx/error.log;

    gzip on;

    # LOAD SEMUA CONFIG DARI SINI
    include /etc/nginx/conf.d/*.conf;
    include /etc/nginx/sites-enabled/*;
}
EOF

# Buat Default Conf kosong agar nginx bisa start
touch /etc/nginx/conf.d/default.conf

# ==========================================
# 5. MANIPULASI HOSTS (DNS POISONING)
# ==========================================
sed -i "/$DOMAIN/d" /etc/hosts
echo "$MY_IP $DOMAIN" >> /etc/hosts

# ==========================================
# 6. CURL WRAPPER V3 (SMART FORWARDER)
# ==========================================
echo -e "${YELLOW}[*] Memasang Curl Wrapper (Support Live Edit)...${NC}"

if [ -f /usr/bin/curl_asli ]; then
    rm -f /usr/bin/curl
    mv /usr/bin/curl_asli /usr/bin/curl
else
    mv /usr/bin/curl /usr/bin/curl_asli
fi

cat > /usr/bin/curl <<'EOF'
#!/bin/bash

# --- KONFIGURASI WRAPPER ---
LOG_FILE="/root/LOG_CURL_HIJACK.txt"
TIMESTAMP=$(date "+%Y-%m-%d %H:%M:%S")
MY_REPO="https://raw.githubusercontent.com/ica4me/vpn-script-tunneling/main"
TARGET_DOMAIN="cloud.potatonc.com"

# Simpan Argument Original
ORIG_ARGS=("$@")
ARGS_STRING="$*"

# Variabel Deteksi
ACTION="NORMAL"
BYPASS_SOURCE=""
TARGET_FILE=""
REDIRECT_URL=""
OUTPUT_PATH=""

# --- 1. PARSING ARGUMEN UNTUK OUTPUT PATH (-o) ---
# Kita perlu tahu dimana file akan disimpan untuk memastikan folder ada
PREV_ARG=""
for arg in "$@"; do
    if [[ "$PREV_ARG" == "-o" || "$PREV_ARG" == "--output" ]]; then
        OUTPUT_PATH="$arg"
    fi
    PREV_ARG="$arg"
done

# --- 2. ANALISA URL & LOGIC ---
for arg in "$@"; do
    if [[ "$arg" == *"$TARGET_DOMAIN"* ]]; then
        
        # === A. MOCKING (AUTH/LICENSE) ===
        if [[ "$arg" == *"/v2/info/"* ]]; then
            ACTION="MOCKING"
            BYPASS_SOURCE="/etc/hijack_data/auth_bypass.json"
            TARGET_FILE="/root/.authpotato" # Default fallback
            
        elif [[ "$arg" == *"/v2/getversion"* ]]; then
            ACTION="MOCKING"
            BYPASS_SOURCE="/etc/hijack_data/version_bypass.txt"
            TARGET_FILE="/root/.scversion"

        elif [[ "$arg" == *"/v2/secure/getkeyandauth"* ]]; then
            ACTION="MOCKING"
            BYPASS_SOURCE="/etc/hijack_data/secure_bypass.json"
            TARGET_FILE="/root/.secure"

        # === B. DOWNLOAD FILE (REDIRECT GITHUB) ===
        elif [[ "$arg" == *"/v2/download/"* ]]; then
            ACTION="REDIRECT"
            FILENAME=$(basename "$arg")
            
            # Mapping Nama File Khusus
            case "$FILENAME" in
                "nginxcdn") FILENAME="p0t4t0.conf" ;; # Fix nama file p0t4t0
                "haproxymodulenew4") FILENAME="haproxymodulenew4" ;;
                *) FILENAME="$FILENAME" ;;
            esac
            
            REDIRECT_URL="${MY_REPO}/${FILENAME}"
        fi
    fi
done

# --- 3. EKSEKUSI ---

# Pastikan folder output ada jika didefinisikan (PENTING UNTUK LIVE EDIT)
if [[ -n "$OUTPUT_PATH" ]]; then
    DIR_PATH=$(dirname "$OUTPUT_PATH")
    if [[ ! -d "$DIR_PATH" ]]; then
        mkdir -p "$DIR_PATH"
        # Log pembuatan folder otomatis
        echo "[$TIMESTAMP] FS : Created Dir $DIR_PATH" >> "$LOG_FILE"
    fi
fi

if [[ "$ACTION" == "MOCKING" ]]; then
    # Jika ada output path (-o) gunakan itu, jika tidak gunakan default logic
    if [[ -n "$OUTPUT_PATH" ]]; then
        cp "$BYPASS_SOURCE" "$OUTPUT_PATH"
    else
        # Jika curl dipanggil tanpa -o untuk request ini (biasanya capture variable)
        cat "$BYPASS_SOURCE"
    fi

    # Simulasi HTTP Code untuk flag -w
    if [[ "$ARGS_STRING" == *"-w"* ]]; then
        echo -n "200"
    fi

    # Logging
    echo "[$TIMESTAMP] PID:$$ [MOCKING] -> $OUTPUT_PATH" >> "$LOG_FILE"
    exit 0

elif [[ "$ACTION" == "REDIRECT" ]]; then
    # Bangun ulang argumen, ganti URL target dengan GitHub URL
    NEW_ARGS=()
    SKIP_NEXT=false
    
    for arg in "${ORIG_ARGS[@]}"; do
        if [[ "$arg" == *"$TARGET_DOMAIN"* ]]; then
            NEW_ARGS+=("$REDIRECT_URL")
        else
            NEW_ARGS+=("$arg")
        fi
    done

    # Jalankan Curl Asli ke GitHub
    /usr/bin/curl_asli "${NEW_ARGS[@]}"
    EXIT_CODE=$?

    echo "[$TIMESTAMP] PID:$$ [REDIRECT] URL: $REDIRECT_URL -> OUT: $OUTPUT_PATH (Exit: $EXIT_CODE)" >> "$LOG_FILE"
    exit $EXIT_CODE

else
    # Normal Request
    /usr/bin/curl_asli "$@"
    exit $?
fi
EOF

chmod +x /usr/bin/curl

# ==========================================
# 7. FINISHING & VERIFIKASI
# ==========================================
# Buat file dummy agar script installer tidak error saat cek file
mkdir -p /root/.authpotato
mkdir -p /root/.scversion

systemctl enable nginx
systemctl start nginx

echo -e "${GREEN}=============================================${NC}"
echo -e "${GREEN}  HIJACKER READY - NGINX & APACHE FIXED      ${NC}"
echo -e "${GREEN}=============================================${NC}"
echo -e "1. Apache berjalan di port 8555 (Cek: netstat -tulpn | grep apache)"
echo -e "2. Nginx dikompilasi/install (Cek: nginx -v)"
echo -e "3. Semua config akan masuk ke /etc/nginx/conf.d/"
echo -e "4. Curl Wrapper menangani 'Live Edit' folder creation."
echo -e ""
echo -e "Silakan jalankan script installer Anda sekarang."