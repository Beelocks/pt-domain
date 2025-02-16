#!/bin/bash
set -euo pipefail

# === Konfigurasi ===
TARGET="example.com"                           # Ganti dengan domain target
OUTPUT_DIR="01-subs"
PASSIVE_OUTPUT="${OUTPUT_DIR}/passive_initial.txt"
TEMP_PREFIX="passive_temp"
# Pastikan variabel lingkungan GITHUB_TOKEN sudah diset jika ingin menggunakan fitur GitHub
GITHUB_TOKEN="${GITHUB_TOKEN:-}"

# === Fungsi Logging ===
log() {
  echo "[*] $(date '+%Y-%m-%d %H:%M:%S') - $*"
}

# === Persiapan ===
mkdir -p "${OUTPUT_DIR}"

log "Memulai Passive Enumeration untuk ${TARGET}"

# --- 1. Subfinder: Kombinasi 15+ sumber intelijen ---
log "Menjalankan subfinder..."
subfinder -d "${TARGET}" -silent \
  -s 'censys,otx,shodan,securitytrails,passivetotal,riddler,bufferover,threatminer,anubis,alienvault' \
  -o "${TEMP_PREFIX}1.txt" || { echo "Error: subfinder gagal."; exit 1; }

# --- 2. Certificate Transparency dengan crt.sh ---
log "Mengambil data dari crt.sh..."
curl -s "https://crt.sh/?q=%25.${TARGET}&output=json" | \
  jq -r '.[].name_value' | \
  sed -e 's/\*\.//g' -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//' | \
  grep -E "^([a-zA-Z0-9]+(-[a-zA-Z0-9]+)*\.)+${TARGET}$" > "${TEMP_PREFIX}2.txt" || { echo "Error: Pengambilan crt.sh gagal."; exit 1; }

# --- 3. Waybackurls: Ekstraksi pola khusus ---
log "Menjalankan waybackurls..."
waybackurls "${TARGET}" | \
  grep -Eo "([a-zA-Z0-9_-]+\.){1,}${TARGET}" | \
  awk -F/ '{print $1}' | sort -u > "${TEMP_PREFIX}3.txt" || { echo "Error: waybackurls gagal."; exit 1; }

# --- 4. URLScan.io dengan paginasi ---
log "Mengambil data dari URLScan.io..."
for i in {0..5}; do
  curl -s "https://urlscan.io/api/v1/search/?q=domain:${TARGET}&offset=$((i*1000))" | \
    jq -r '.results[].page.domain'
done | grep "${TARGET}$" > "${TEMP_PREFIX}4.txt" || { echo "Error: URLScan.io gagal."; exit 1; }

# --- 5. GitHub Leaks Search ---
if [ -z "${GITHUB_TOKEN}" ]; then
  log "WARNING: GITHUB_TOKEN tidak diset. Melewati pencarian GitHub."
else
  log "Mengambil data subdomain dari GitHub..."
  github-subdomains -t "${GITHUB_TOKEN}" -d "${TARGET}" > "${TEMP_PREFIX}5.txt" || { echo "Error: GitHub subdomains gagal."; exit 1; }
fi

# --- 6. AlienVault OTX ---
log "Mengambil data dari AlienVault OTX..."
curl -s "https://otx.alienvault.com/api/v1/indicators/hostname/${TARGET}/passive_dns" | \
  jq -r '.passive_dns[].hostname' | \
  grep -E "^[a-zA-Z0-9.-]+\.${TARGET}$" > "${TEMP_PREFIX}6.txt" || { echo "Error: AlienVault OTX gagal."; exit 1; }

# --- Gabungkan, deduplikasi, dan validasi ---
log "Menggabungkan dan memvalidasi hasil..."
cat ${TEMP_PREFIX}*.txt 2>/dev/null | \
  anew | \
  grep -Ev '^(dev|test|stage)\.' | \
  dnsx -silent -retry 2 -rcode noerror,nxdomain | \
  awk '{print $1}' > "${PASSIVE_OUTPUT}" || { echo "Error: Penggabungan hasil gagal."; exit 1; }

log "Passive Enumeration selesai. Hasil disimpan di ${PASSIVE_OUTPUT}"

# --- Pembersihan temporary file ---
log "Membersihkan file temporary..."
rm -f ${TEMP_PREFIX}*.txt

log "Script selesai dengan sukses."by 
