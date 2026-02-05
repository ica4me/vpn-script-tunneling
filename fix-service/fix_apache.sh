#!/bin/bash

# Warna
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${GREEN}==========================================${NC}"
echo -e "${GREEN}      APACHE2 PORT FIXER (PORT 8555)      ${NC}"
echo -e "${GREEN}==========================================${NC}"

# 1. Ubah ports.conf
echo -e "${YELLOW}[1/4] Mengubah Listen Port ke 8555...${NC}"
if [ -f /etc/apache2/ports.conf ]; then
    # Ubah Listen 80 -> Listen 8555
    sed -i 's/Listen 80/Listen 8555/g' /etc/apache2/ports.conf
    # Jaga-jaga jika ada Listen 8080 atau lainnya, pastikan hanya 8555 yang aktif untuk http
    echo "OK: ports.conf diperbarui."
else
    echo -e "${RED}[!] File /etc/apache2/ports.conf tidak ditemukan!${NC}"
fi

# 2. Ubah VirtualHost default
echo -e "${YELLOW}[2/4] Mengubah VirtualHost Default...${NC}"
if [ -f /etc/apache2/sites-available/000-default.conf ]; then
    sed -i 's/<VirtualHost \*:80>/<VirtualHost \*:8555>/g' /etc/apache2/sites-available/000-default.conf
    echo "OK: 000-default.conf diperbarui."
else
    echo -e "${RED}[!] File /etc/apache2/sites-available/000-default.conf tidak ditemukan!${NC}"
fi

# 3. Enable & Start Service
echo -e "${YELLOW}[3/4] Menyalakan Service Apache2...${NC}"
systemctl daemon-reload
systemctl enable apache2
systemctl restart apache2

# 4. Verifikasi
echo -e "${YELLOW}[4/4] Cek Status...${NC}"
sleep 2

if systemctl is-active --quiet apache2; then
    echo -e "${GREEN}------------------------------------------${NC}"
    echo -e "${GREEN} [SUKSES] Apache2 Aktif & Running!        ${NC}"
    echo -e "${GREEN}------------------------------------------${NC}"
    echo "Cek Port:"
    netstat -tulpn | grep apache2
else
    echo -e "${RED}------------------------------------------${NC}"
    echo -e "${RED} [GAGAL] Apache2 Masih Mati/Error         ${NC}"
    echo -e "${RED}------------------------------------------${NC}"
    systemctl status apache2 --no-pager
fi