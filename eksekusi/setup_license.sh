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

echo -e "${GREEN}[+] Memulai Setup Fake License Environment...${NC}"

# --- 1. Install Dependencies ---
echo -e "[+] Memastikan tools terinstall (curl, jq)..."
apt-get update -qq
apt-get install -y curl jq -qq

# --- 2. Ambil Data VPS ---
echo -e "[+] Mengambil data jaringan VPS..."
IPVPS_DATA=$(curl -s ipinfo.io)
MY_IP=$(echo "$IPVPS_DATA" | jq -r '.ip')
MY_CITY=$(echo "$IPVPS_DATA" | jq -r '.city')
MY_REGION=$(echo "$IPVPS_DATA" | jq -r '.region')
MY_COUNTRY=$(echo "$IPVPS_DATA" | jq -r '.country')
MY_LOC=$(echo "$IPVPS_DATA" | jq -r '.loc')
MY_ORG=$(echo "$IPVPS_DATA" | jq -r '.org')
MY_POSTAL=$(echo "$IPVPS_DATA" | jq -r '.postal')
MY_TIMEZONE=$(echo "$IPVPS_DATA" | jq -r '.timezone')

# Bersihkan nama ISP dari nomor ASN (contoh: "AS12345 Google" menjadi "Google")
MY_ISP_CLEAN=$(echo "$MY_ORG" | sed 's/^AS[0-9]* //')

# --- 3. Definisi File ---

# Jika file sudah ada dan immutable, buka dulu kuncinya agar bisa ditimpa
chattr -i /root/.authpotato /root/.ipmod /root/.ipvps /root/.mycity /root/.myip /root/.myisp /root/.scversion /root/.secure 2>/dev/null

# 1. .authpotato
echo -e "[+] Membuat /root/.authpotato"
echo "999 Days" > /root/.authpotato

# 2. .ipmod
echo -e "[+] Membuat /root/.ipmod"
echo "4" > /root/.ipmod

# 3. .ipvps (Format JSON persis dari ipinfo + field readme)
echo -e "[+] Membuat /root/.ipvps"
cat <<EOF > /root/.ipvps
{
  "ip": "$MY_IP",
  "city": "$MY_CITY",
  "region": "$MY_REGION",
  "country": "$MY_COUNTRY",
  "loc": "$MY_LOC",
  "org": "$MY_ORG",
  "postal": "$MY_POSTAL",
  "timezone": "$MY_TIMEZONE",
  "readme": "https://ipinfo.io/missingauth"
}
EOF

# 4. .mycity
echo -e "[+] Membuat /root/.mycity"
echo "$MY_CITY" > /root/.mycity

# 5. .myip
echo -e "[+] Membuat /root/.myip"
echo "$MY_IP" > /root/.myip

# 6. .myisp
echo -e "[+] Membuat /root/.myisp"
echo "$MY_ISP_CLEAN" > /root/.myisp

# 7. .scversion
echo -e "[+] Membuat /root/.scversion"
cat <<EOF > /root/.scversion
{
  "statusCode": 200,
  "status": true,
  "message": "SUCCESS",
  "data": {
    "name_version": "SPv07.01.26",
    "old_version": 1,
    "new_version": 3,
    "updated_at": "2026-01-07T15:26:36.000Z"
  }
}
EOF

# 8. .secure (IP disesuaikan dengan VPS saat ini, sisa data hardcoded sesuai request)
echo -e "[+] Membuat /root/.secure"
cat <<EOF > /root/.secure
{
  "statusCode": 200,
  "status": true,
  "message": "SUCCESS",
  "data": {
    "id": 6398,
    "name_client": "vsdowp17",
    "bot_client": "",
    "chat_id": 0,
    "date_exp": "2026-03-02",
    "address": "$MY_IP",
    "domain": "tcorpplhdm.keenam.my.id",
    "key_client": "potatoIVM5zi1o2tfOEcD1eoeWwY0WXrlwlX",
    "x_api_client": "potato0OlZFdO2lvlcZm6QVyUnYVJcFt5KII",
    "total_renew": 0,
    "total_change": 0,
    "permission_change": 3,
    "permission_install": 2,
    "status_install": "OFF",
    "type_script": "ALL",
    "pemilik_client": "Nirezz",
    "status": "month",
    "status_bot": "no",
    "created_at": "2026-01-31T13:38:51.000Z",
    "updated_at": "2026-02-02T12:02:43.000Z",
    "expired_at": "2026-01-31T13:38:51.000Z",
    "price": "9000.00",
    "version": "v2",
    "step_install": "null",
    "script": "http://scriptcjxrq91ay.potatonc.my.id:2086/f"
  }
}
EOF

# --- 4. Kunci File (Immutable) ---
echo -e "[+] Mengunci file (Immutable)..."
chattr +i /root/.authpotato
chattr +i /root/.ipmod
chattr +i /root/.ipvps
chattr +i /root/.mycity
chattr +i /root/.myip
chattr +i /root/.myisp
chattr +i /root/.scversion
chattr +i /root/.secure

echo -e "${GREEN}[DONE] Semua file telah dibuat dan dikunci.${NC}"