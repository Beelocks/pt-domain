#!/bin/bash
set -euo pipefail

# === Konfigurasi ===
NAABU_FILTERED="02-scans/naabu_filtered.txt"

# --- Pemantauan Real-time ---
log "Menjalankan pemantauan real-time dengan gowitness..."
gowitness file -f "${NAABU_FILTERED}" --delay 5 || { echo "Error: GoWitness monitoring gagal."; exit 1; }

log "Pemantauan selesai."
