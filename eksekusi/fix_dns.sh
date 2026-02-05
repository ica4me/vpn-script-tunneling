#!/bin/bash

# Pastikan script dijalankan sebagai root
if [ "$(id -u)" != "0" ]; then
   echo "Harap jalankan script ini sebagai root!"
   exit 1
fi

echo "[*] Memulai konfigurasi DNS..."

# 1. Buka kunci file (chattr -i) terlebih dahulu
# Ini penting: Jika file sudah immutable sebelumnya, perintah 'rm' akan gagal tanpa ini.
if [ -f "/etc/resolv.conf" ]; then
    chattr -i /etc/resolv.conf > /dev/null 2>&1
fi

# 2. Hapus file atau symlink lama
rm -f /etc/resolv.conf

# 3. Buat file baru dengan isi yang diminta
cat > /etc/resolv.conf <<EOF
nameserver 1.1.1.1
nameserver 8.8.8.8
EOF

# 4. Kunci file agar Immutable (Tidak bisa diedit/dihapus siapapun, termasuk root)
chattr +i /etc/resolv.conf

# Verifikasi hasil
echo "[+] File /etc/resolv.conf berhasil diperbarui."
echo "[+] Isi file saat ini:"
echo "---------------------------------"
cat /etc/resolv.conf
echo "---------------------------------"
echo "[+] Status Atribut File (i = immutable):"
lsattr /etc/resolv.conf