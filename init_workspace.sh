#!/bin/bash
DOMAIN=$1

# Buat struktur direktori
mkdir -p {00-info,01-subs,02-scans,03-vulns,04-exploit,05-report,wordlists}/{asn,whois,contacts}

# Inisialisasi file scope
echo "# $DOMAIN Pentest Scope" > 00-info/scope.txt
echo -e "\n## Network Boundaries\n- IP Ranges: TBD" >> 00-info/scope.txt

# Set file permissions
chmod 600 00-info/credentials.txt
chmod 644 00-info/scope.txt

echo "[+] Workspace for $DOMAIN created successfully!"
