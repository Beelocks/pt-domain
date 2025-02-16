#!/bin/bash
set -euo pipefail

# === Konfigurasi ===
TARGET="example.com"                           # Ganti dengan domain target
OUTPUT_DIR="01-subs"
ACTIVE_OUTPUT="${OUTPUT_DIR}/active_brute.txt"
WORDLIST="${HOME}/wordlists/subdomains/top1m-200k.txt"      # Path ke wordlist umum
COMMON_PREFIXES="${HOME}/wordlists/subdomains/common-prefixes.txt"  # Path ke daftar prefix umum
TEMP_PREFIX="active_temp"
RESOLVERS_FILE="resolvers.txt"

# === Fungsi Logging ===
log() {
  echo "[*] $(date '+%Y-%m-%d %H:%M:%S') - $*"
}

# === Persiapan ===
mkdir -p "${OUTPUT_DIR}"

log "Memulai Active Bruteforce untuk ${TARGET}"

# --- Persiapan Resolver dengan dnsvalidator ---
log "Mengambil dan memvalidasi resolvers..."
dnsvalidator -tL https://public-dns.info/nameservers.txt -threads 50 -o "${RESOLVERS_FILE}" || { echo "Error: dnsvalidator gagal."; exit 1; }
if [ ! -s "${RESOLVERS_FILE}" ]; then
  echo "Error: File resolvers kosong."
  exit 1
fi

# --- Lapis 1: Brute-force dengan wordlist umum ---
log "Lapis 1: Menjalankan brute-force dengan wordlist..."
shuffledns -d "${TARGET}" \
  -w "${WORDLIST}" \
  -r "${RESOLVERS_FILE}" \
  -o "${TEMP_PREFIX}1.txt" \
  -massdns ./massdns \
  -nf massdns.out || { echo "Error: Lapis 1 gagal."; exit 1; }

# --- Lapis 2: Permutasi cerdas dengan dnsgen ---
log "Lapis 2: Menghasilkan permutasi subdomain..."
dnsgen "${OUTPUT_DIR}/passive_initial.txt" | \
  shuffledns -d "${TARGET}" -r "${RESOLVERS_FILE}" \
  -o "${TEMP_PREFIX}2.txt" || { echo "Error: Lapis 2 gagal."; exit 1; }

# --- Lapis 3: Kombinasi karakter khusus ---
log "Lapis 3: Menghasilkan kombinasi dengan prefix umum..."
comb -list "${COMMON_PREFIXES}" -o comb_temp.txt || { echo "Error: comb gagal."; exit 1; }
dnsx -l comb_temp.txt -d "${TARGET}" -silent | \
  awk '{print $1"." "'"${TARGET}"'"}' > "${TEMP_PREFIX}3.txt" || { echo "Error: Lapis 3 gagal."; exit 1; }

# --- Gabungkan dan validasi hasil brute-force ---
log "Menggabungkan hasil brute-force..."
cat ${TEMP_PREFIX}*.txt 2>/dev/null | \
  anew | \
  dnsx -silent -rcode noerror -retry 2 -r "${RESOLVERS_FILE}" | \
  awk '{print $1}' > "${ACTIVE_OUTPUT}" || { echo "Error: Penggabungan hasil brute-force gagal."; exit 1; }

log "Active Bruteforce selesai. Hasil disimpan di ${ACTIVE_OUTPUT}"

# --- Pembersihan temporary file ---
log "Membersihkan file temporary..."
rm -f ${TEMP_PREFIX}*.txt comb_temp.txt

log "Script selesai dengan sukses."
