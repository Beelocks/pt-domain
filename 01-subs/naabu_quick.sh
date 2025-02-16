#!/bin/bash
set -euo pipefail

# === Konfigurasi ===
SUBS_FILE="01-subs/final_subs.txt"                 # File input subdomain
OUTPUT_DIR="02-scans"
NAABU_OUTPUT="${OUTPUT_DIR}/naabu_quick.txt"
FILTERED_OUTPUT="${OUTPUT_DIR}/naabu_filtered.txt"
EXCLUDE_PORTS=":22$|:25$"                          # Port yang dikecualikan (misal SSH/SMTP)
RATE="5000"                                        # Rate per detik
TOP_PORTS="2000"                                   # Jumlah port teratas yang akan di-scan

# === Fungsi Logging ===
log() {
  echo "[*] $(date '+%Y-%m-%d %H:%M:%S') - $*"
}

# === Persiapan ===
mkdir -p "${OUTPUT_DIR}"

log "Memulai Naabu Port Scanning dengan subdomain list dari ${SUBS_FILE}"

# --- Scan cepat dengan Naabu ---
naabu -list "${SUBS_FILE}" \
  -top-ports "${TOP_PORTS}" \
  -rate "${RATE}" \
  -retries 3 \
  -exclude-cdn \
  -verify \
  -ec \
  -stats \
  -scan-all-ips \
  -nmap-cli 'nmap -sS -T4 --max-retries 1 --script discovery' \
  -o "${NAABU_OUTPUT}" \
  -silent || { echo "Error: Naabu scan gagal."; exit 1; }

log "Naabu scan selesai. Hasil disimpan di ${NAABU_OUTPUT}"

# --- Filter dan validasi hasil ---
log "Memfilter hasil Naabu (menghapus port ${EXCLUDE_PORTS})"
cat "${NAABU_OUTPUT}" | \
  awk -F':' '{print $1":"$2}' | \
  grep -Ev "${EXCLUDE_PORTS}" | \
  sort -u | \
  anew > "${FILTERED_OUTPUT}" || { echo "Error: Filtering gagal."; exit 1; }

log "Hasil filtered disimpan di ${FILTERED_OUTPUT}"

log "Naabu Quick Scan selesai dengan sukses."
