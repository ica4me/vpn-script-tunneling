#!/bin/bash

# ==========================================
# POTATONC GOD MODE HIJACKER V3
# Fitur: Auto URL Fix, License Mocking
# Support: Nginx 1.28.1 & Apache2 Latest (Co-existence)
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

clear
echo -e "${GREEN}=============================================${NC}"
echo -e "${GREEN}   GOD MODE V3 (SPECIFIC VERSIONS)           ${NC}"
echo -e "${GREEN}=============================================${NC}"

# 1. Cek Root
if [ "$(id -u)" != "0" ]; then
   echo -e "${RED}[!] Harap jalankan script ini sebagai root!${NC}"
   exit 1
fi

# 2. Persiapan File "Master" (Data Palsu untuk Bypass)
echo -e "${YELLOW}[*] Membuat Data Lisensi Palsu (Bypass)...${NC}"
mkdir -p /etc/hijack_data

# A. File: .authpotato
cat > /etc/hijack_data/auth_bypass.json <<EOF
{"statusCode":200,"status":"true","data":{"name_client":"Admin","chat_id":"0","address":"$(curl -s ifconfig.me)","domain":"google.com","key_client":"bypass","x_api_client":"bypass","type_script":"premium","pemilik_client":"Me","status":"active","script":"none","date_exp":"2099-12-31"}}
EOF

# B. File: .scversion
echo "latest" > /etc/hijack_data/version_bypass.txt

# C. File: .secure
echo '{"status":"active","key":"bypass"}' > /etc/hijack_data/secure_bypass.json

# 3. Bersihkan Konfigurasi Lama & Curl
sed -i "/$DOMAIN/d" /etc/hosts
if [ -f /usr/bin/curl_asli ]; then
    rm -f /usr/bin/curl
    mv /usr/bin/curl_asli /usr/bin/curl
fi

# 4. Install Dependencies & Web Servers (CUSTOM VERSION)
echo -e "${YELLOW}[*] Menyiapkan Repository & Install Web Server...${NC}"

# Install prerequisites
apt-get update -y
apt-get install curl zip gnupg2 ca-certificates lsb-release ubuntu-keyring -y 2>/dev/null

# --- INSTALL NGINX (Versi Spesifik via Official Repo) ---
echo -e "${YELLOW}[*] Menambahkan Repo Nginx Official...${NC}"
# Tambahkan Key Nginx
curl https://nginx.org/keys/nginx_signing.key | gpg --dearmor \
    | tee /usr/share/keyrings/nginx-archive-keyring.gpg >/dev/null

# Tambahkan Repo (Menggunakan Mainline untuk versi terbaru)
echo "deb [signed-by=/usr/share/keyrings/nginx-archive-keyring.gpg] \
http://nginx.org/packages/mainline/ubuntu `lsb_release -cs` nginx" \
    | tee /etc/apt/sources.list.d/nginx.list

apt-get update -y

echo -e "${YELLOW}[*] Menginstall Nginx 1.28.1 & Apache2...${NC}"
# Coba install versi spesifik, jika gagal (karena belum rilis di repo), ambil latest
apt-get install nginx=1.28.1* -y || apt-get install nginx -y

# --- INSTALL APACHE2 (Versi Terbaru) ---
apt-get install apache2 -y

# 5. CONFIG CO-EXISTENCE (Agar Nginx & Apache Jalan Bareng)
echo -e "${YELLOW}[*] Mengatur Port Apache agar tidak bentrok...${NC}"
# Pindahkan Apache ke port 8888 agar Nginx bisa pakai port 80
sed -i 's/80/8888/g' /etc/apache2/ports.conf
sed -i 's/:80/:8888/g' /etc/apache2/sites-available/*.conf

# Restart keduanya
systemctl restart apache2
systemctl restart nginx

# 6. PERBAIKAN STRUKTUR FOLDER (Sesuai Log Error Exit Code 23)
echo -e "${YELLOW}[*] Memperbaiki Struktur Folder...${NC}"

# Fix Apache Folder
mkdir -p /etc/apache2
mkdir -p /etc/apache2/conf-available
mkdir -p /etc/apache2/sites-available
touch /etc/apache2/apache2.conf
touch /etc/apache2/envvars

# Fix Nginx Folder
mkdir -p /etc/nginx/conf.d
touch /etc/nginx/nginx.conf
touch /etc/nginx/conf.d/default.conf

# 7. Manipulasi Hosts (DNS Spoofing)
echo -e "${YELLOW}[*] Mengalihkan DNS Lokal...${NC}"
echo "$MY_IP $DOMAIN" >> /etc/hosts

# 8. PASANG SMART CURL WRAPPER
echo -e "${YELLOW}[*] Memasang God-Mode Curl Wrapper...${NC}"

# Backup Curl Asli
mv /usr/bin/curl /usr/bin/curl_asli

# Buat Script Curl Cerdas
cat > /usr/bin/curl <<EOF
#!/bin/bash

# --- KONFIGURASI ---
LOG_FILE="$LOG_FILE"
TIMESTAMP=\$(date "+%Y-%m-%d %H:%M:%S")
MY_REPO="$GITHUB_REPO"
TARGET_DOMAIN="$DOMAIN"

# Simpan Argumen Asli
ORIG_ARGS="\$*"

# Variabel Status
ACTION="NORMAL"
BYPASS_CONTENT=""
TARGET_FILE=""

# ---------------------------------------------------------
# ANALISA URL & TENTUKAN AKSI
# ---------------------------------------------------------
for arg in "\$@"; do
    
    # 1. FIX URL CACAT
    if [[ "\$arg" == /v2/* ]]; then
        arg="https://\${TARGET_DOMAIN}\${arg}"
    fi

    # 2. DETEKSI URL TARGET
    if [[ "\$arg" == *"\$TARGET_DOMAIN"* ]]; then
        
        # === MOCKING (AUTH) ===
        if [[ "\$arg" == *"/v2/info/"* ]]; then
            ACTION="MOCKING"
            BYPASS_SOURCE="/etc/hijack_data/auth_bypass.json"
            TARGET_FILE="/root/.authpotato"
        
        elif [[ "\$arg" == *"/v2/getversion"* ]]; then
            ACTION="MOCKING"
            BYPASS_SOURCE="/etc/hijack_data/version_bypass.txt"
            TARGET_FILE="/root/.scversion"
        
        elif [[ "\$arg" == *"/v2/secure/getkeyandauth"* ]]; then
            ACTION="MOCKING"
            BYPASS_SOURCE="/etc/hijack_data/secure_bypass.json"
            TARGET_FILE="/root/.secure"

        # === REDIRECT (DOWNLOAD) ===
        elif [[ "\$arg" == *"/v2/download/"* ]]; then
            ACTION="REDIRECT"
            FILENAME=\$(basename "\$arg")
            
            # Mapping Nama File
            case "\$FILENAME" in
                "haproxymodulenew4") FILENAME="haproxymodulenew4" ;;
                "potatonewapi-amd64") FILENAME="potatonewapi-amd64" ;;
                "xnxx.zip") FILENAME="xnxx.zip" ;;
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
    # Mode Penipuan
    cp "\$BYPASS_SOURCE" "\$TARGET_FILE"
    
    if [[ "\$ORIG_ARGS" == *"-w"* ]]; then
        echo -n "200"
    fi
    
    {
      echo "[\$TIMESTAMP] PID:\$$ [MOCKING]"
      echo "REQ : \$ORIG_ARGS"
      echo "ACT : Bypassed -> \$TARGET_FILE"
      echo "STAT: SUCCESS (Fake 200 OK)"
      echo "----------------------------------------------------------------"
    } >> "\$LOG_FILE"
    exit 0

elif [[ "\$ACTION" == "REDIRECT" ]]; then
    # Mode Download GitHub
    NEW_ARGS=()
    for arg in "\$@"; do
        if [[ "\$arg" == /v2/* ]]; then
             arg="https://\${TARGET_DOMAIN}\${arg}"
        fi
        if [[ "\$arg" == *"\$TARGET_DOMAIN"* ]]; then
            NEW_ARGS+=("\$FINAL_URL")
        else
            NEW_ARGS+=("\$arg")
        fi
    done
    
    /usr/bin/curl_asli "\${NEW_ARGS[@]}"
    EXIT_CODE=\$?
    
    {
      echo "[\$TIMESTAMP] PID:\$$ [REDIRECT]"
      echo "REQ : \$ORIG_ARGS"
      echo "TO  : \$FINAL_URL"
      echo "STAT: Exit Code \$EXIT_CODE"
      echo "----------------------------------------------------------------"
    } >> "\$LOG_FILE"
    exit \$EXIT_CODE

else
    # Mode Normal
    /usr/bin/curl_asli "\$@"
    exit \$?
fi
EOF

chmod +x /usr/bin/curl

# Reset Log
echo "--- GOD MODE V3 LOG STARTED ---" > $LOG_FILE
chmod 777 $LOG_FILE

# 9. Verifikasi
echo -e "${GREEN}=============================================${NC}"
echo -e "${GREEN}   SYSTEM READY (NGINX 1.28 & APACHE)        ${NC}"
echo -e "${GREEN}=============================================${NC}"
echo -e "Script telah diperbaiki:"
echo -e "1. Repo Nginx Official ditambahkan (Target v1.28.1)."
echo -e "2. Apache dipindah ke port 8888 (Agar Nginx 80 lancar)."
echo -e "3. Mocking & Redirect tetap aktif."
echo -e ""
echo -e "Silakan jalankan installer binary sekarang!"