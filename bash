# 1. Buat struktur direktori utama
mkdir -p ~/pt-domain/{00-info,01-subs,02-scans,03-vulns,04-exploit,05-report,wordlists}

# 2. Buat subdirektori khusus
mkdir -p ~/pt-domain/00-info/{asn,whois,contacts}
mkdir -p ~/pt-domain/wordlists/{api,subdomains,dirs,params}

# 3. Inisialisasi file penting
touch ~/pt-domain/00-info/scope.txt
touch ~/pt-domain/00-info/credentials.txt
echo "# Pentest Notes" > ~/pt-domain/00-info/notes.md

# 4. Download wordlists umum (Opsional)
wget -qO- https://gist.githubusercontent.com/jhaddix/86d5a795fae0f8191401/raw/7115757328b1a7d9dd2a435a3d144f691d4c24e0/all.txt -P ~/pt-domain/wordlists/dirs/
wget -qO- https://raw.githubusercontent.com/danielmiessler/SecLists/master/Discovery/DNS/subdomains-top1million-110000.txt -P ~/pt-domain/wordlists/subdomains/
