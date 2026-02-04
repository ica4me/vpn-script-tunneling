#!/bin/bash

# ==========================================
# POTATONC GOD MODE HIJACKER V3 (STABLE)
# Optimized for Debian & Ubuntu
# Features: Nginx Mainline, Port Fix, Smart Curl
# ==========================================

# KONFIGURASI
DOMAIN="cloud.potatonc.com"
GITHUB_REPO="https://raw.githubusercontent.com/ica4me/vpn-script-tunneling/main"
MY_IP="127.0.0.1"
LOG_FILE="/root/LOG_CURL_NEW.txt"
NGINX_VER_REQ="1.28" # Target versi (Mainline)

# Warna
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

export DEBIAN_FRONTEND=noninteractive

clear
echo -e "${GREEN}=============================================${NC}"
echo -e "${GREEN}    GOD MODE HIJACKER V3 (DEBIAN/UBUNTU)     ${NC}"
echo -e "${GREEN}=============================================${NC}"

# 1. Cek Root
if [ "$(id -u)" != "0" ]; then
    echo -e "${RED}[!] Harap jalankan script ini sebagai root!${NC}"
    exit 1
fi

# 2. Kill Process yang Mengganggu Port
echo -e "${YELLOW}[*] Membersihkan port dan proses lama...${NC}"
systemctl stop nginx apache2 > /dev/null 2>&1
killall -9 nginx apache2 php-fpm > /dev/null 2>&1

# 3. Persiapan File "Master" (Mocking Data)
echo -e "${YELLOW}[*] Membuat Data Lisensi Palsu (Bypass)...${NC}"
mkdir -p /etc/hijack_data

# Data Mocking
cat > /etc/hijack_data/auth_bypass.json <<EOF
{"statusCode":200,"status":"true","data":{"name_client":"Admin","chat_id":"0","address":"$(curl -s ifconfig.me)","domain":"google.com","key_client":"bypass","x_api_client":"bypass","type_script":"premium","pemilik_client":"Me","status":"active","script":"none","date_exp":"2099-12-31"}}
EOF
echo "latest" > /etc/hijack_data/version_bypass.txt
echo '{"status":"active","key":"bypass"}' > /etc/hijack_data/secure_bypass.json

# 4. Tambah Repo Nginx Mainline (Agar dapat versi terbaru/1.28.x)
echo -e "${YELLOW}[*] Menambahkan Repository Nginx Mainline...${NC}"
apt-get update -y
apt-get install -y gnupg2 ca-certificates lsb-release ubuntu-keyring curl

# Deteksi OS untuk Repo yang tepat
OS=$(lsb_release -is | tr '[:upper:]' '[:lower:]')
CODENAME=$(lsb_release -cs)

if [ "$OS" == "ubuntu" ]; then
    curl https://nginx.org/keys/nginx_signing.key | gpg --dearmor \
    | tee /usr/share/keyrings/nginx-archive-keyring.gpg >/dev/null
    echo "deb [signed-by=/usr/share/keyrings/nginx-archive-keyring.gpg] \
    http://nginx.org/packages/mainline/ubuntu $CODENAME nginx" \
    | tee /etc/apt/sources.list.d/nginx.list
elif [ "$OS" == "debian" ]; then
    curl https://nginx.org/keys/nginx_signing.key | gpg --dearmor \
    | tee /usr/share/keyrings/nginx-archive-keyring.gpg >/dev/null
    echo "deb [signed-by=/usr/share/keyrings/nginx-archive-keyring.gpg] \
    http://nginx.org/packages/mainline/debian $CODENAME nginx" \
    | tee /etc/apt/sources.list.d/nginx.list
fi

# 5. Install Dependencies & Web Servers
echo -e "${YELLOW}[*] Menginstall Nginx & Apache2...${NC}"
apt-get update -y
# Hapus versi lama jika ada agar bersih
apt-get remove nginx nginx-common nginx-full -y > /dev/null 2>&1
# Install versi baru
apt-get install -y nginx apache2 zip unzip

# 6. FIX FOLDER & PERMISSION (Crucial untuk Live Edit)
echo -e "${YELLOW}[*] Memperbaiki Struktur Folder & Permission...${NC}"

# Fix Apache
mkdir -p /etc/apache2/conf-available
mkdir -p /etc/apache2/sites-available
touch /etc/apache2/apache2.conf
touch /etc/apache2/envvars

# Fix Nginx (Wajib conf.d sesuai request)
mkdir -p /etc/nginx/conf.d
mkdir -p /etc/nginx/sites-available
mkdir -p /etc/nginx/sites-enabled

# Hapus default config bawaan nginx agar tidak bentrok
rm -f /etc/nginx/conf.d/default.conf

# Set Permission agar bisa di-write oleh script lain (Live Edit)
chmod -R 777 /etc/nginx/conf.d
chmod -R 777 /etc/apache2

# 7. KONFIGURASI PORT (Sesuaikan dengan ss -tulpn)
echo -e "${YELLOW}[*] Mengkonfigurasi Port Apache ke 8555...${NC}"
# Paksa Apache pindah ke 8555 agar Nginx bisa pakai 80/443/dll
sed -i 's/Listen 80/Listen 8555/g' /etc/apache2/ports.conf
sed -i 's/<VirtualHost \*:80>/<VirtualHost \*:8555>/g' /etc/apache2/sites-available/000-default.conf

# 8. DNS Spoofing
sed -i "/$DOMAIN/d" /etc/hosts
echo "$MY_IP $DOMAIN" >> /etc/hosts

# 9. PASANG SMART CURL WRAPPER (HIJACKER)
echo -e "${YELLOW}[*] Memasang Curl Wrapper (Fix Concurrency)...${NC}"

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

# Simpan Argumen Asli
ORIG_ARGS="\$*"

# Inisialisasi
ACTION="NORMAL"
BYPASS_SOURCE=""
TARGET_FILE=""
FINAL_URL=""

# ---------------------------------------------------------
# ANALISA ARGUMEN (Looping Cerdas)
# ---------------------------------------------------------
# Kita harus cek argumen satu per satu untuk menemukan URL target
for arg in "\$@"; do
    
    # 1. FIX URL CACAT (awalan /v2/)
    if [[ "\$arg" == /v2/* ]]; then
        arg="https://\${TARGET_DOMAIN}\${arg}"
    fi

    # 2. DETEKSI REQUEST KE DOMAIN TARGET
    if [[ "\$arg" == *"\$TARGET_DOMAIN"* ]]; then
        
        # === KATEGORI A: REQUEST LISENSI/INFO (MOCKING) ===
        if [[ "\$arg" == *"/v2/info/"* ]]; then
            ACTION="MOCKING"
            BYPASS_SOURCE="/etc/hijack_data/auth_bypass.json"
            TARGET_FILE="/root/.authpotato" # Default fallback
        
        elif [[ "\$arg" == *"/v2/getversion"* ]]; then
            ACTION="MOCKING"
            BYPASS_SOURCE="/etc/hijack_data/version_bypass.txt"
            TARGET_FILE="/root/.scversion"
        
        elif [[ "\$arg" == *"/v2/secure/getkeyandauth"* ]]; then
            ACTION="MOCKING"
            BYPASS_SOURCE="/etc/hijack_data/secure_bypass.json"
            TARGET_FILE="/root/.secure"

        # === KATEGORI B: DOWNLOAD FILE CONFIG (REDIRECT GITHUB) ===
        elif [[ "\$arg" == *"/v2/download/"* ]]; then
            ACTION="REDIRECT"
            # Ambil nama file dari URL
            FILENAME=\$(basename "\$arg")
            
            # Mapping Nama File Khusus
            case "\$FILENAME" in
                "haproxymodulenew4") FILENAME="haproxymodulenew4" ;;
                "nginxcdn") FILENAME="nginx.conf" ;; # Contoh mapping
                *) FILENAME="\$FILENAME" ;;
            esac
            
            FINAL_URL="\${MY_REPO}/\${FILENAME}"
        fi
    fi
done

# ---------------------------------------------------------
# EKSEKUSI
# ---------------------------------------------------------

if [[ "\$ACTION" == "MOCKING" ]]; then
    # --- MODE MOCKING ---
    # Jika ada flag -o di command asli, kita harus menulis ke file itu
    # Cari nilai setelah -o
    OUTPUT_PATH=""
    PREV_ARG=""
    for arg in "\$@"; do
        if [[ "\$PREV_ARG" == "-o" ]]; then
            OUTPUT_PATH="\$arg"
        fi
        PREV_ARG="\$arg"
    done

    # Jika ketemu output path, copy file palsu ke sana
    if [[ ! -z "\$OUTPUT_PATH" ]]; then
        cp "\$BYPASS_SOURCE" "\$OUTPUT_PATH"
    else
        # Jika tidak ada -o, output ke stdout (jarang terjadi di script installer)
        cat "\$BYPASS_SOURCE"
    fi

    # Simulasi HTTP 200 untuk curl -w %{http_code}
    if [[ "\$ORIG_ARGS" == *"-w"* ]]; then
        echo -n "200"
    fi
    
    # Log Silent
    echo "[\$TIMESTAMP] [MOCKING] \$ORIG_ARGS" >> "\$LOG_FILE"
    exit 0

elif [[ "\$ACTION" == "REDIRECT" ]]; then
    # --- MODE REDIRECT (DOWNLOAD) ---
    
    # Kita harus membangun ulang command curl tapi mengganti URL target dengan GitHub
    # Kita simpan semua argumen, tapi ganti URLnya saja.
    
    NEW_ARGS=()
    for arg in "\$@"; do
        if [[ "\$arg" == *"\$TARGET_DOMAIN"* || "\$arg" == /v2/* ]]; then
            NEW_ARGS+=("\$FINAL_URL")
        else
            NEW_ARGS+=("\$arg")
        fi
    done
    
    # Jalankan Curl Asli dengan URL Baru
    /usr/bin/curl_asli "\${NEW_ARGS[@]}"
    EXIT_CODE=\$?
    
    echo "[\$TIMESTAMP] [REDIRECT] \$FINAL_URL (Code: \$EXIT_CODE)" >> "\$LOG_FILE"
    exit \$EXIT_CODE

else
    # --- MODE NORMAL (INTERNET BIASA) ---
    /usr/bin/curl_asli "\$@"
    exit \$?
fi
EOF

chmod +x /usr/bin/curl
chmod 777 $LOG_FILE

# 10. Restart Service
echo -e "${YELLOW}[*] Merestart Service (Nginx & Apache)...${NC}"
systemctl daemon-reload
systemctl restart apache2
systemctl restart nginx

# Cek Status Nginx
NGINX_STATUS=$(systemctl is-active nginx)
APACHE_STATUS=$(systemctl is-active apache2)
INSTALLED_VER=$(nginx -v 2>&1)

echo -e "${GREEN}=============================================${NC}"
echo -e "${GREEN}          INSTALASI SELESAI                  ${NC}"
echo -e "${GREEN}=============================================${NC}"
echo -e "Nginx Status  : $NGINX_STATUS"
echo -e "Apache Status : $APACHE_STATUS (Port 8555)"
echo -e "Versi Nginx   : $INSTALLED_VER"
echo -e "Folder Conf   : /etc/nginx/conf.d/ (Writeable)"
echo -e ""
echo -e "${YELLOW}Catatan:${NC} Apache berjalan di port 8555."
echo -e "Script installer lain sekarang bisa menulis config ke /etc/nginx/conf.d/"
echo -e "tanpa error permission atau bentrok port."
echo -e "${GREEN}=============================================${NC}"