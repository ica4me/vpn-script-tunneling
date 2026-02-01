#!/bin/bash
# Installer Master - Auto Download & Execute (Optimized for Debian 12 & Ubuntu)
# Version: 2.0 (Bypass & Lifetime Edition)

# --- KONFIGURASI REPOSITORY ---
# Pastikan URL ini mengarah ke folder 'setup' di GitHub Anda
REPO_URL="https://raw.githubusercontent.com/ica4me/vpn-script-tunneling/main/setup"
# REPO_ROOT digunakan untuk mengambil file di luar folder setup (seperti menu/api)
REPO_ROOT="https://raw.githubusercontent.com/ica4me/vpn-script-tunneling/main"
WORK_DIR="/root/SCRIPT_SIAP_PAKAI"

# Warna
Green="\033[32m"
Red="\033[31m"
Yellow="\033[33m"
Suffix="\033[0m"

# Header
clear
echo -e "${Green}======================================${Suffix}"
echo -e "${Green}   INSTALLER VPN PREMIUM (BYPASS)     ${Suffix}"
echo -e "${Green}======================================${Suffix}"
echo ""

# ---------------------------------------------------------
# TAHAP 1: INSTALL TOOLS PENDUKUNG (Pre-Requisites)
# ---------------------------------------------------------
echo -e "${Green}>>> TAHAP 1: Menginstall Tools Wajib...${Suffix}"

# [FIX] Non-Interactive Mode agar tidak muncul pop-up di Debian 12
export DEBIAN_FRONTEND=noninteractive
export APT_LISTCHANGES_FRONTEND=none

apt-get update -y
apt-get install -y curl jq wget screen build-essential zip unzip git net-tools \
gnupg lsb-release sqlite3 bc libncurses5-dev libssl-dev python-is-python3

echo -e "${Green}[OK] Tools berhasil diinstall.${Suffix}"
echo ""

# ---------------------------------------------------------
# TAHAP 2: DOWNLOAD SCRIPT 1 s/d 11
# ---------------------------------------------------------
echo -e "${Green}>>> TAHAP 2: Mendownload Script Installer (1-11)...${Suffix}"

rm -rf "$WORK_DIR"
mkdir -p "$WORK_DIR"
cd "$WORK_DIR"

# Loop download dari 1 sampai 11 (Termasuk bypass script)
for i in {1..11}; do
    FILE_NAME="${i}.sh"
    DOWNLOAD_URL="${REPO_URL}/${FILE_NAME}"
    
    echo -n "    - Download ${FILE_NAME} ... "
    wget -q "$DOWNLOAD_URL" -O "$FILE_NAME"
    
    if [ -s "$FILE_NAME" ]; then
        chmod +x "$FILE_NAME"
        sed -i 's/\r$//' "$FILE_NAME"
        echo -e "${Green}[SUKSES]${Suffix}"
    else
        echo -e "${Red}[GAGAL]${Suffix}"
        exit 1
    fi
done
echo ""

# ---------------------------------------------------------
# TAHAP 3: EKSEKUSI BERURUTAN
# ---------------------------------------------------------
echo -e "${Green}>>> TAHAP 3: Menjalankan Installer...${Suffix}"

run_part() {
    local script_name="$1.sh"
    echo -e "${Green}======================================${Suffix}"
    echo -e "${Green}>>> [RUNNING] Bagian $1 ($script_name)...${Suffix}"
    echo -e "${Green}======================================${Suffix}"
    
    # Jalankan script dengan source (.) agar environment tetap terjaga
    ./"$script_name"
    
    if [ $? -ne 0 ]; then
        echo -e "${Red}>>> [WARNING] Script $script_name selesai dengan error.${Suffix}"
        sleep 2
    fi
    echo ""
}

# Eksekusi loop 1 s/d 11 (Bagian 11 akan melakukan bypass lisensi otomatis)
for i in {1..11}; do
    run_part "$i"
    sleep 1
done

# ---------------------------------------------------------
# TAHAP 4: FINAL CHECK (Menu Fix)
# ---------------------------------------------------------
echo -e "${Green}>>> TAHAP 4: Finalizing Permissions...${Suffix}"
chmod +x /usr/sbin/menu 2>/dev/null
chmod +x /usr/sbin/potatonewapi-amd64 2>/dev/null
chmod +x /usr/sbin/this.data 2>/dev/null

# ---------------------------------------------------------
# SELESAI
# ---------------------------------------------------------
echo -e "${Green}======================================${Suffix}"
echo -e "${Green}      SEMUA INSTALASI SELESAI!        ${Suffix}"
echo -e "${Green}    SILAKAN KETIK 'menu' UNTUK CEK    ${Suffix}"
echo -e "${Green}======================================${Suffix}"

# Bersihkan file installer
cd /root
rm -rf "$WORK_DIR"