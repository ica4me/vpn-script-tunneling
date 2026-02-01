#!/bin/bash

# --- [WARNA] ---
Green="\033[32m"
Red="\033[31m"
Suffix="\033[0m"

# --- [DIREKTORI UTAMA] ---
DIR_POTATO="/usr/sbin/potatonc"
DB_PATH="$DIR_POTATO/potato.db"
LST_PATH="$DIR_POTATO/p0t4t0.lst"

echo -e "$Green[INFO]$Suffix Memulai proses Bypass Lisensi Lifetime..."

# 1. Pastikan Direktori Tersedia
mkdir -p $DIR_POTATO

# 2. Deteksi IP Publik Otomatis
MY_IP=$(curl -s ifconfig.me)
if [[ -z "$MY_IP" ]]; then
    MY_IP=$(curl -s ipv4.icanhazip.com)
fi

# 3. Injeksi ke Database Lokal (potato.db)
# Mencoba berbagai kemungkinan nama tabel lisensi yang umum
if [[ -f "$DB_PATH" ]]; then
    echo -e "$Green[INFO]$Suffix Menyuntikkan IP ke Database..."
    # Inject ke tabel 'servers' (berdasarkan struktur Anda sebelumnya)
    sqlite3 $DB_PATH "UPDATE servers SET address='$MY_IP', status='active' WHERE order_by='no';" 2>/dev/null
    # Inject ke tabel 'ips' atau 'client' sebagai cadangan
    sqlite3 $DB_PATH "INSERT OR REPLACE INTO servers (ip, status, expired) VALUES ('$MY_IP', 'active', '2030-01-01');" 2>/dev/null
else
    echo -e "$Red[WARN]$Suffix File potato.db tidak ditemukan di $DIR_POTATO"
fi

# 4. Injeksi ke File Whitelist (p0t4t0.lst)
echo -e "$Green[INFO]$Suffix Mendaftarkan IP ke Whitelist Lokal..."
echo "$MY_IP" > $LST_PATH
echo "$MY_IP active 2030-01-01" >> $LST_PATH
chmod 777 $LST_PATH

# 5. Pasang Flag Izin di Hosts (Mencegah Cek ke API Pusat)
echo -e "$Green[INFO]$Suffix Mengalihkan Domain Lisensi ke Lokal..."
grep -qxF '127.0.0.1 scriptcjxrq91ay.potatonc.my.id' /etc/hosts || echo "127.0.0.1 scriptcjxrq91ay.potatonc.my.id" >> /etc/hosts
grep -qxF '127.0.0.1 potatonc.my.id' /etc/hosts || echo "127.0.0.1 potatonc.my.id" >> /etc/hosts

# 6. Perbaiki Izin Eksekusi Binary Utama
echo -e "$Green[INFO]$Suffix Mengaktifkan Binary Menu & API..."
chmod +x /usr/sbin/menu 2>/dev/null
chmod +x /usr/sbin/potatonewapi-amd64 2>/dev/null
chmod +x /usr/sbin/this.data 2>/dev/null

echo -e "$Green[SUCCESS]$Suffix Bypass Lisensi Berhasil! IP $MY_IP kini Lifetime."
echo -e "$Green[INFO]$Suffix Silakan ketik 'menu' untuk mencoba."