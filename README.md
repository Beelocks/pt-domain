# pt-domain
Direktori Kerja Penetration Testing yang terstruktur dan siap menjalankan semua tools
_____________________________________________________________________________________________

# 1. Subdomain Enumeration (Passive)
cd ~/pt-domain

# Subfinder dengan filter khusus 
subfinder -d example.com -o 01-subs/passive_initial.txt -sources censys,otx -silent

# Amass pasif dengan API keys
amass enum -passive -d example.com -config ~/amass/config.ini -o 01-subs/amass_passive.txt

# Gabungkan hasil dan filter
cat 01-subs/*.txt | anew 01-subs/combined.txt | tee -a 00-info/notes.md
_____________________________________________________________________________________________

# 2. Active DNS Bruteforce

# Gunakan shuffledns dengan resolvers khusus
shuffledns -d example.com -w wordlists/subdomains/top1m.txt -r wordlists/resolvers.txt -o 01-subs/active_brute.txt

# Filter subdomain unik
comm -23 01-subs/active_brute.txt 01-subs/combined.txt > 01-subs/new_subs.txt

_____________________________________________________________________________________________

# 3. Port Scanning dengan Naabu

# Scan cepat port umum
naabu -list 01-subs/combined.txt -top-ports 100 -o 02-scans/naabu_quick.txt -silent

# Scan mendalam untuk host spesifik
echo "admin.example.com" | naabu -p - -scan-all-ips -nmap-cli 'nmap -sV -sC -oN 02-scans/nmap_admin.txt'

_____________________________________________________________________________________________

# 4. HTTP Service Detection

# Deteksi layanan web
httpx -l 02-scans/naabu_quick.txt -title -tech-detect -status-code -json -o 02-scans/httpx.json

# Ekstrak host hidup
jq -r '.url' 02-scans/httpx.json > 02-scans/live_hosts.txt

# Contoh output httpx.json
{
  "url": "http://admin.example.com",
  "title": "Login Portal",
  "status-code": 200,
  "tech": ["jquery", "apache", "php/5.6.40"],
  "webserver": "Apache/2.4.29"
}

_____________________________________________________________________________________________

# 5. Vulnerability Scanning dengan Nuclei

# Update templates dulu
nuclei -ut

# Scan kerentanan kritis
nuclei -l 02-scans/live_hosts.txt -t ~/nuclei-templates/ \
  -severity critical -tags rce,sqli -o 03-vulns/critical_findings.txt

# Contoh command untuk XSS
nuclei -u https://example.com/search?q=test -t xss.yaml -var payload='"><script>alert(1)</script>'

_____________________________________________________________________________________________

# 6. SQL Injection Testing

# Ekstrak parameter dari hasil crawling
cat 03-vulns/crawl_data.txt | grep '?' | uro | tee 03-vulns/params.txt

# Scan SQLi dengan SQLMap
sqlmap -m 03-vulns/params.txt --batch --risk 3 --level 5 --output-dir=03-vulns/sqlmap_out

# Contoh exploit berhasil
[INFO] GET parameter 'id' is vulnerable
[INFO] dumped database 'users'

_____________________________________________________________________________________________

# 7. Directory Fuzzing dengan FFuf

ffuf -w wordlists/dirs/common.txt \
  -u https://example.com/FUZZ \
  -mc 200,403 \
  -rate 100 \
  -o 03-vulns/ffuf_scan.json \
  -of json

# Hasil dalam JSON
{
  "results": [
    {
      "url": "https://example.com/admin",
      "status": 200,
      "length": 1234
    }
  ]
}

_____________________________________________________________________________________________

# 8. JavaScript Analysis

# Ekstrak URL JS
katana -list 02-scans/live_hosts.txt -jc -o 03-vulns/js_urls.txt

# Cari secret
secretfinder -i 03-vulns/js_urls.txt -o 03-vulns/secrets.txt

# Contoh temuan
Found AWS Key in login.js: AKIAXXXXXXXXXXXXXXXX

_____________________________________________________________________________________________

# 9. Reporting

# Generate visual report
cat 02-scans/live_hosts.txt | aquatone -out 05-report/aquatone

# Buat laporan HTML nuclei
nuclei -l 02-scans/live_hosts.txt -severity critical -json | jq '.' | ansi2html > 05-report/critical_vulns.html

# Contoh isi notes.md
echo "## Critical Findings\n- SQLi di /search.php" >> 00-info/notes.md

_____________________________________________________________________________________________

# Workflow

graph TD
    A[Subdomain Enum] --> B[Port Scan]
    B --> C{Port 80/443?}
    C -->|Ya| D[Web Scanning]
    C -->|Tidak| E[Service Fingerprint]
    D --> F[Vuln Assessment]
    E --> F
    F --> G[Exploit Validation]
    G --> H[Reporting]

Tips Eksekusi:

- Mulai dengan scope jelas di 00-info/scope.txt

- Dokumentasi semua command di 00-info/notes.md

- Simpan credentials di 00-info/credentials.txt terenkripsi

- Gunakan filter anew untuk menghindari duplikasi

- Backup harian dengan tar -czvf backup_$(date +%s).tar.gz ~/pt-domain









