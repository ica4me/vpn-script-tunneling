#!/bin/bash

# Warna untuk output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}==========================================${NC}"
echo -e "${GREEN}    NGINX CONFIG FIXER (AUTO-REPAIR)      ${NC}"
echo -e "${GREEN}==========================================${NC}"

# 1. Backup file asli
echo -e "${YELLOW}[1/5] Membackup nginx.conf asli...${NC}"
if [ -f /etc/nginx/nginx.conf ]; then
    cp /etc/nginx/nginx.conf /etc/nginx/nginx.conf.backup_$(date +%F_%T)
    echo "Backup tersimpan."
else
    echo "File nginx.conf tidak ditemukan, membuat baru..."
    touch /etc/nginx/nginx.conf
fi

# 2. Ubah isi nginx.conf utama menjadi SATU BARIS penunjuk ke p0t4t0
echo -e "${YELLOW}[2/5] Mengatur Master Config...${NC}"
echo "include /etc/nginx/conf.d/p0t4t0.conf;" > /etc/nginx/nginx.conf
echo "Master config diarahkan ke p0t4t0.conf."

# 3. Matikan looping di p0t4t0.conf
echo -e "${YELLOW}[3/5] Mencegah Infinite Loop di p0t4t0.conf...${NC}"
if [ -f /etc/nginx/conf.d/p0t4t0.conf ]; then
    sed -i 's/include \/etc\/nginx\/conf.d\/\*\.conf;/#include_loop_prevented;/g' /etc/nginx/conf.d/p0t4t0.conf
    echo "Loop prevented."
else
    echo -e "${RED}[!] ERROR: File /etc/nginx/conf.d/p0t4t0.conf TIDAK DITEMUKAN!${NC}"
    echo "Pastikan file tersebut sudah didownload sebelum menjalankan script ini."
    exit 1
fi

# 4. Pastikan folder log ada
echo -e "${YELLOW}[4/5] Memperbaiki Folder Log...${NC}"
mkdir -p /var/log/nginx
touch /var/log/nginx/access.log
touch /var/log/nginx/error.log
chmod 755 /var/log/nginx
echo "Folder log siap."

# 5. Test Config & Restart
echo -e "${YELLOW}[5/5] Testing Konfigurasi Nginx...${NC}"
nginx -t

if [ $? -eq 0 ]; then
    echo -e "${GREEN}------------------------------------------${NC}"
    echo -e "${GREEN} [OK] KONFIGURASI VALID! MESTART NGINX... ${NC}"
    echo -e "${GREEN}------------------------------------------${NC}"
    systemctl restart nginx
    systemctl status nginx --no-pager
else
    echo -e "${RED}------------------------------------------${NC}"
    echo -e "${RED} [!] KONFIGURASI MASIH ERROR!             ${NC}"
    echo -e "${RED}------------------------------------------${NC}"
    echo "Silakan cek pesan error di atas."
fi