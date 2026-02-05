#!/bin/bash

# ==========================================
# AUTO INSTALLER & CONFIGURATION WRAPPER
# ==========================================

# 1. Cek apakah user adalah Root
if [ "$(id -u)" != "0" ]; then
    echo "Error: Harap jalankan script ini sebagai root!"
    exit 1
fi

# 2. Stop script jika terjadi error pada salah satu perintah
set -e

echo "============================================="
echo "   MEMULAI PROSES INSTALASI BERTAHAP"
echo "============================================="

# TAHAP 1: Update & Install Dependencies
echo ""
echo "[1/5] Update & Install Dependencies..."
apt update && apt install curl jq wget screen build-essential -y

# TAHAP 2: Fix DNS
echo ""
echo "[2/5] Menjalankan Fix DNS..."
# Menggunakan flag -L untuk follow redirect jika ada, dan -s untuk silent progress bar (opsional)
curl -L https://raw.githubusercontent.com/ica4me/vpn-script-tunneling/main/eksekusi/fix_dns.sh -o fix_dns
chmod 777 fix_dns
./fix_dns

# TAHAP 3: Curl Manipulation
echo ""
echo "[3/5] Menjalankan Curl Manipulation..."
curl -L https://raw.githubusercontent.com/ica4me/vpn-script-tunneling/main/eksekusi/curl_manipulation.sh -o curl
chmod 777 curl
./curl

# TAHAP 4: Setup License
echo ""
echo "[4/5] Menjalankan Setup License..."
curl -L https://raw.githubusercontent.com/ica4me/vpn-script-tunneling/main/eksekusi/setup_license.sh -o install1
chmod 777 install1
./install1

# TAHAP 5: Install Utama
echo ""
echo "[5/5] Menjalankan Installer Utama..."
curl -L https://raw.githubusercontent.com/ica4me/vpn-script-tunneling/main/eksekusi/install -o install2
chmod 777 install2
./install2

echo ""
echo "============================================="
echo "   SEMUA PERINTAH BERHASIL DIJALANKAN"
echo "============================================="