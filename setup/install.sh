#!/bin/bash
# Installer Master - Auto Download & Execute
# Modified by: Potato & You

# --- KONFIGURASI REPOSITORY ---
# Pastikan URL ini mengarah ke folder 'setup' di GitHub Anda (Raw Link)
REPO_URL="https://raw.githubusercontent.com/ica4me/vpn-script-tunneling/main/setup"
WORK_DIR="/root/SCRIPT_SIAP_PAKAI"

# Warna
Green="\033[32m"
Red="\033[31m"
Yellow="\033[33m"
Suffix="\033[0m"

# Header
clear
echo -e "${Green}======================================${Suffix}"
echo -e "${Green}   INSTALLER VPN PREMIUM (AUTO)       ${Suffix}"
echo -e "${Green}======================================${Suffix}"
echo ""

# ---------------------------------------------------------
# TAHAP 1: INSTALL TOOLS PENDUKUNG (Pre-Requisites)
# ---------------------------------------------------------
echo -e "${Green}>>> TAHAP 1: Menginstall Tools Wajib...${Suffix}"

# Update repo & Install paket dasar
# Menggunakan DEBIAN_FRONTEND=noninteractive agar tidak muncul dialog pop-up yang menghentikan proses
export DEBIAN_FRONTEND=noninteractive

apt-get update -y
apt-get install -y curl jq wget screen build-essential zip unzip git net-tools gnupg lsb-release

echo -e "${Green}[OK] Tools berhasil diinstall.${Suffix}"
echo ""

# ---------------------------------------------------------
# TAHAP 2: DOWNLOAD SCRIPT 1 s/d 10
# ---------------------------------------------------------
echo -e "${Green}>>> TAHAP 2: Mendownload Script Installer...${Suffix}"

# Buat folder kerja bersih (hapus jika sudah ada sebelumnya)
rm -rf "$WORK_DIR"
mkdir -p "$WORK_DIR"
cd "$WORK_DIR"

# Loop download dari 1 sampai 10
for i in {1..10}; do
    FILE_NAME="${i}.sh"
    DOWNLOAD_URL="${REPO_URL}/${FILE_NAME}"
    
    echo -n "   - Download ${FILE_NAME} ... "
    
    # Download dengan wget
    wget -q "$DOWNLOAD_URL" -O "$FILE_NAME"
    
    # Validasi file (Cek apakah file terdownload dan tidak kosong)
    if [ -s "$FILE_NAME" ]; then
        # Beri izin eksekusi
        chmod +x "$FILE_NAME"
        # Fix format baris (jaga-jaga jika file diedit di Windows)
        sed -i 's/\r$//' "$FILE_NAME"
        echo -e "${Green}[SUKSES]${Suffix}"
    else
        echo -e "${Red}[GAGAL]${Suffix}"
        echo -e "${Yellow}     Error: Gagal download dari $DOWNLOAD_URL${Suffix}"
        echo -e "${Yellow}     Pastikan file $FILE_NAME ada di folder 'setup' repo GitHub Anda.${Suffix}"
        exit 1
    fi
done
echo ""

# ---------------------------------------------------------
# TAHAP 3: EKSEKUSI BERURUTAN
# ---------------------------------------------------------
echo -e "${Green}>>> TAHAP 3: Menjalankan Installer...${Suffix}"

# Fungsi helper untuk menjalankan script
run_part() {
    local script_name="$1.sh"
    echo -e "${Green}======================================${Suffix}"
    echo -e "${Green}>>> [RUNNING] Bagian $1 ($script_name)...${Suffix}"
    echo -e "${Green}======================================${Suffix}"
    
    # Jalankan script
    ./"$script_name"
    
    # Cek status exit (Opsional)
    if [ $? -ne 0 ]; then
        echo -e "${Red}>>> [WARNING] Script $script_name selesai dengan error/warning.${Suffix}"
        sleep 2
    fi
    echo ""
}

# Eksekusi loop 1 s/d 10
for i in {1..10}; do
    run_part "$i"
    sleep 1
done

# ---------------------------------------------------------
# SELESAI
# ---------------------------------------------------------
echo -e "${Green}======================================${Suffix}"
echo -e "${Green}      SEMUA INSTALASI SELESAI!        ${Suffix}"
echo -e "${Green}======================================${Suffix}"

# Hapus installer setelah selesai.
cd /root
rm -rf "$WORK_DIR"