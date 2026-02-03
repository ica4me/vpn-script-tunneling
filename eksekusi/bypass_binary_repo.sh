#!/bin/bash

# ==========================================
# POTATONC GOD MODE HIJACKER
# Fitur: Auto URL Fix, GitHub Redirect, & LICENSE BYPASS (MOCKING)
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
echo -e "${GREEN}   GOD MODE HIJACKER (LICENSE BYPASS)        ${NC}"
echo -e "${GREEN}=============================================${NC}"

# 1. Cek Root
if [ "$(id -u)" != "0" ]; then
   echo -e "${RED}[!] Harap jalankan script ini sebagai root!${NC}"
   exit 1
fi

# 2. Persiapan File "Master" (Data Palsu untuk Bypass)
echo -e "${YELLOW}[*] Membuat Data Lisensi Palsu (Bypass)...${NC}"
mkdir -p /etc/hijack_data

# A. File: .authpotato (Data Lisensi Aktif)
cat > /etc/hijack_data/auth_bypass.json <<EOF
{"statusCode":200,"status":"true","data":{"name_client":"Admin","chat_id":"0","address":"$(curl -s ifconfig.me)","domain":"google.com","key_client":"bypass","x_api_client":"bypass","type_script":"premium","pemilik_client":"Me","status":"active","script":"none","date_exp":"2099-12-31"}}
EOF

# B. File: .scversion (Versi Terbaru)
echo "latest" > /etc/hijack_data/version_bypass.txt

# C. File: .secure (Auth Key)
echo '{"status":"active","key":"bypass"}' > /etc/hijack_data/secure_bypass.json

# 3. Bersihkan Konfigurasi Lama
sed -i "/$DOMAIN/d" /etc/hosts
if [ -f /usr/bin/curl_asli ]; then
    rm -f /usr/bin/curl
    mv /usr/bin/curl_asli /usr/bin/curl
fi

# 4. Install Dependencies
apt-get update -y
apt-get install curl zip -y

# 5. Manipulasi Hosts (DNS Spoofing) - Tetap diperlukan sebagai cadangan
echo -e "${YELLOW}[*] Mengalihkan DNS Lokal...${NC}"
echo "$MY_IP $DOMAIN" >> /etc/hosts

# 6. PASANG SMART CURL WRAPPER (THE BRAIN)
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
    
    # 1. FIX URL CACAT (awalan /v2/)
    if [[ "\$arg" == /v2/* ]]; then
        arg="https://\${TARGET_DOMAIN}\${arg}"
    fi

    # 2. DETEKSI URL TARGET
    if [[ "\$arg" == *"\$TARGET_DOMAIN"* ]]; then
        
        # === KATEGORI A: REQUEST LISENSI/INFO ===
        if [[ "\$arg" == *"/v2/info/"* ]]; then
            ACTION="MOCKING"
            BYPASS_SOURCE="/etc/hijack_data/auth_bypass.json"
            TARGET_FILE="/root/.authpotato" # Sesuai permintaan Anda
        
        elif [[ "\$arg" == *"/v2/getversion"* ]]; then
            ACTION="MOCKING"
            BYPASS_SOURCE="/etc/hijack_data/version_bypass.txt"
            TARGET_FILE="/root/.scversion"
        
        elif [[ "\$arg" == *"/v2/secure/getkeyandauth"* ]]; then
            ACTION="MOCKING"
            BYPASS_SOURCE="/etc/hijack_data/secure_bypass.json"
            TARGET_FILE="/root/.secure"

        # === KATEGORI B: REQUEST DOWNLOAD FILE ===
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
# EKSEKUSI BERDASARKAN AKSI
# ---------------------------------------------------------

if [[ "\$ACTION" == "MOCKING" ]]; then
    # --- MODE PENIPUAN (MOCKING) ---
    # Kita tidak internetan, kita langsung tulis file dan bilang "200 OK"
    
    # 1. Tulis isi file palsu ke target
    cp "\$BYPASS_SOURCE" "\$TARGET_FILE"
    
    # 2. Simulasi Output HTTP Code (PENTING: Binary curl -w %{http_code} butuh output ini)
    # Cek apakah ada flag -w di argumen asli
    if [[ "\$ORIG_ARGS" == *"-w"* ]]; then
        echo -n "200"
    fi
    
    # 3. Log Sukses Palsu
    {
      echo "[$TIMESTAMP] PID:\$$ [MOCKING]"
      echo "REQ : \$ORIG_ARGS"
      echo "ACT : Bypassed -> \$TARGET_FILE"
      echo "STAT: SUCCESS (Fake 200 OK)"
      echo "----------------------------------------------------------------"
    } >> "\$LOG_FILE"
    
    exit 0

elif [[ "\$ACTION" == "REDIRECT" ]]; then
    # --- MODE DOWNLOAD (REDIRECT GITHUB) ---
    
    # Bangun ulang argumen dengan URL baru
    NEW_ARGS=()
    for arg in "\$@"; do
        # Fix URL Cacat lagi untuk argumen
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
      echo "[$TIMESTAMP] PID:\$$ [REDIRECT]"
      echo "REQ : \$ORIG_ARGS"
      echo "TO  : \$FINAL_URL"
      echo "STAT: Exit Code \$EXIT_CODE"
      echo "----------------------------------------------------------------"
    } >> "\$LOG_FILE"
    
    exit \$EXIT_CODE

else
    # --- MODE NORMAL ---
    /usr/bin/curl_asli "\$@"
    exit \$?
fi
EOF

# Beri izin eksekusi
chmod +x /usr/bin/curl

# Reset Log
echo "--- GOD MODE LOG STARTED ---" > $LOG_FILE
chmod 777 $LOG_FILE

# 7. Verifikasi
echo -e "${GREEN}=============================================${NC}"
echo -e "${GREEN}   SIAP DIJALANKAN                           ${NC}"
echo -e "${GREEN}=============================================${NC}"
echo -e "Script ini sekarang akan:"
echo -e "1. ${GREEN}REDIRECT${NC} semua download ke GitHub Anda."
echo -e "2. ${GREEN}MOCKING${NC} (Memalsukan) request Auth/Info/Version."
echo -e "   -> Jadi binary TIDAK AKAN mendownload auth dari internet,"
echo -e "   -> tapi langsung mengambil data 'Lolos' dari lokal VPS."
echo -e ""
echo -e "Silakan jalankan installer binary sekarang!"