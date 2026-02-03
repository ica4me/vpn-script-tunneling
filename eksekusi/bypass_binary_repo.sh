#!/bin/bash

# ==========================================
# Binary Request Hijacker (Man-in-the-Middle Local)
# Tested on: Debian 10+, Ubuntu 20+
# ==========================================

DOMAIN="cloud.potatonc.com"
TARGET_URL="https://raw.githubusercontent.com/ica4me/vpn-script-tunneling/main"
CERT_DIR="/etc/nginx/ssl/hijack"
MY_IP="127.0.0.1"

# Warna
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${GREEN}[*] Memulai proses pembajakan request sistem untuk binary...${NC}"

# 1. Cek Root
if [ "$(id -u)" != "0" ]; then
   echo -e "${RED}[!] Jalankan sebagai root!${NC}"
   exit 1
fi

# 2. Install Dependencies (Nginx & OpenSSL)
echo -e "${GREEN}[*] Menginstall Nginx dan OpenSSL...${NC}"
apt-get update -y
apt-get install nginx openssl ca-certificates -y

# 3. Setup Direktori SSL
mkdir -p $CERT_DIR

# 4. Buat Sertifikat Self-Signed yang "Terlihat Sah"
echo -e "${GREEN}[*] Membuat sertifikat SSL palsu untuk $DOMAIN...${NC}"

# Buat Private Key
openssl genrsa -out $CERT_DIR/hijack.key 2048

# Buat Config OpenSSL sementara untuk SAN (Subject Alternative Name)
cat > $CERT_DIR/openssl.cnf <<EOF
[req]
distinguished_name = req_distinguished_name
req_extensions = v3_req
prompt = no
[req_distinguished_name]
C = ID
ST = Jakarta
L = Jakarta
O = Security
CN = $DOMAIN
[v3_req]
keyUsage = keyEncipherment, dataEncipherment
extendedKeyUsage = serverAuth
subjectAltName = @alt_names
[alt_names]
DNS.1 = $DOMAIN
EOF

# Generate CSR dan Certificate
openssl req -new -key $CERT_DIR/hijack.key -out $CERT_DIR/hijack.csr -config $CERT_DIR/openssl.cnf
openssl x509 -req -days 3650 -in $CERT_DIR/hijack.csr -signkey $CERT_DIR/hijack.key -out $CERT_DIR/hijack.crt -extensions v3_req -extfile $CERT_DIR/openssl.cnf

# 5. Inject Sertifikat ke System Trust Store
# Ini penting agar binary tidak menganggap sertifikat kita palsu (jika binary cek CA store OS)
echo -e "${GREEN}[*] Menanamkan sertifikat ke sistem trusted store...${NC}"
cp $CERT_DIR/hijack.crt /usr/local/share/ca-certificates/$DOMAIN.crt
update-ca-certificates

# 6. Konfigurasi Nginx untuk Redirect
echo -e "${GREEN}[*] Mengkonfigurasi Nginx Server Block...${NC}"

cat > /etc/nginx/conf.d/hijack_$DOMAIN.conf <<EOF
server {
    listen 443 ssl;
    server_name $DOMAIN;

    ssl_certificate $CERT_DIR/hijack.crt;
    ssl_certificate_key $CERT_DIR/hijack.key;

    # Tangkap request ke /v2/download
    location /v2/download {
        # Redirect 302 (Temporary) ke URL GitHub
        return 302 $TARGET_URL;
    }

    # Fallback untuk path lain (opsional)
    location / {
        return 404;
    }
}
EOF

# Restart Nginx
systemctl restart nginx

# 7. Manipulasi /etc/hosts (DNS Spoofing)
echo -e "${GREEN}[*] Memanipulasi /etc/hosts...${NC}"

# Hapus entry lama jika ada untuk menghindari duplikat
sed -i "/$DOMAIN/d" /etc/hosts

# Tambahkan entry baru
echo "$MY_IP $DOMAIN" >> /etc/hosts

echo -e "------------------------------------------"
echo -e "${GREEN}[SUCCESS] Sistem berhasil dimanipulasi!${NC}"
echo -e "Sekarang VPS ini mengira '$DOMAIN' ada di localhost."
echo -e "Setiap request dari binary ke:"
echo -e " -> $DOMAIN/v2/download"
echo -e "Akan otomatis dibelokkan Nginx ke:"
echo -e " -> $TARGET_URL"
echo -e "------------------------------------------"