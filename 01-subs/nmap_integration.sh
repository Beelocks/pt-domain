#!/bin/bash
set -euo pipefail

# === Konfigurasi ===
NAABU_FILTERED="02-scans/naabu_filtered.txt"
OUTPUT_DIR="02-scans"

# --- Service detail scan untuk port 8080, 8443 ---
log "Menjalankan Nmap untuk detail service port 8080 dan 8443..."
nmap -sV -sC -p 8080,8443 -iL "${NAABU_FILTERED}" -oN "${OUTPUT_DIR}/nmap_special.txt" || { echo "Error: Nmap service scan gagal."; exit 1; }

# --- Deteksi Kerentanan Langsung ---
log "Menjalankan Nmap untuk deteksi kerentanan langsung pada port 80 dan 443..."
nmap --script vuln -p 80,443 -iL "${NAABU_FILTERED}" -oN "${OUTPUT_DIR}/nmap_vuln.txt" || { echo "Error: Nmap vuln scan gagal."; exit 1; }

log "Nmap scan selesai. Hasil disimpan di ${OUTPUT_DIR}."
