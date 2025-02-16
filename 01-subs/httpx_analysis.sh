#!/bin/bash
set -euo pipefail

# === Konfigurasi ===
NAABU_FILTERED="02-scans/naabu_filtered.txt"        # Input dari Naabu yang difilter
OUTPUT_DIR="02-scans"
HTTPX_JSON="${OUTPUT_DIR}/httpx.json"
SCREENSHOT_DIR="${OUTPUT_DIR}/screenshots"
VULN_DIR="03-vulns"
AQUATONE_OUTPUT="05-report/aquatone_screens"

# === Fungsi Logging ===
log() {
  echo "[*] $(date '+%Y-%m-%d %H:%M:%S') - $*"
}

# === Persiapan ===
mkdir -p "${OUTPUT_DIR}" "${SCREENSHOT_DIR}" "${VULN_DIR}"

log "Memulai analisis web fingerprinting dengan httpx untuk target dari ${NAABU_FILTERED}"

# --- Httpx Scan ---
httpx -l "${NAABU_FILTERED}" \
  -title \
  -tech-detect \
  -status-code \
  -content-length \
  -jarm \
  -cdn \
  -http2 \
  -websocket \
  -screenshot \
  -screenshot-dir "${SCREENSHOT_DIR}" \
  -json \
  -random-agent \
  -follow-redirects \
  -timeout 10 \
  -retries 2 \
  -threads 100 \
  -custom-headers '{"X-Forwarded-For": "127.0.0.1", "Referer": "https://google.com"}' \
  -o "${HTTPX_JSON}" || { echo "Error: Httpx scan gagal."; exit 1; }

log "Httpx scan selesai. Hasil disimpan di ${HTTPX_JSON}"

# --- Post-Processing Canggih ---
log "Melakukan post-processing untuk deteksi kerentanan teknologi tua..."

# Ekstrak tech PHP 5.6 yang rentan
jq -r 'select(.tech | contains(["php/5.6"])) | .url' "${HTTPX_JSON}" > "${VULN_DIR}/old_php.txt" || { echo "Error: Ekstrak tech PHP gagal."; exit 1; }

# Analisis JARM Fingerprint
jq -r '.url + ":" + .jarm' "${HTTPX_JSON}" > "${OUTPUT_DIR}/jarm_fingerprints.csv" || { echo "Error: JARM Fingerprint gagal."; exit 1; }

# Generate laporan visual dengan aquatone
log "Membuat laporan visual dengan Aquatone..."
cat "${HTTPX_JSON}" | jq -r '.url' | aquatone -out "${AQUATONE_OUTPUT}" || { echo "Error: Aquatone gagal."; exit 1; }

# --- Pembersihan ---
log "Script selesai dengan sukses."
