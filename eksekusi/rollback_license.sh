#!/bin/bash

# --- Konfigurasi Warna ---
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# --- Cek Root ---
if [[ $EUID -ne 0 ]]; then
   echo -e "${RED}Script ini harus dijalankan sebagai root!${NC}" 
   exit 1
fi

echo -e "${RED}[!] Memulai Rollback/Penghapusan...${NC}"

FILES=(
    "/root/.authpotato"
    "/root/.ipmod"
    "/root/.ipvps"
    "/root/.mycity"
    "/root/.myip"
    "/root/.myisp"
    "/root/.scversion"
    "/root/.secure"
)

for FILE in "${FILES[@]}"; do
    if [ -f "$FILE" ]; then
        echo -n "Memproses $FILE ... "
        # Buka kunci immutable
        chattr -i "$FILE"
        # Hapus file
        rm -f "$FILE"
        echo -e "${GREEN}Terhapus${NC}"
    else
        echo -e "$FILE ${RED}Tidak ditemukan${NC}"
    fi
done

echo -e "${GREEN}[DONE] Sistem bersih kembali.${NC}"