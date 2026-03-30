# Setup guide: proxy server terbaik untuk Ubuntu VPS

## Ringkasannya

Untuk Ubuntu VPS dengan kebutuhan **scraping/bot** dan **privasi dasar**:

- **3proxy**: rekomendasi utama untuk proxy server cepat dan ringan di VPS.
- **Shadowsocks**: lebih cocok jika Anda ingin trafik tidak terlalu terlihat seperti proxy biasa atau menghadapi jaringan yang lebih restriktif.
- **Squid**: alternatif HTTP proxy klasik, tetapi bukan pilihan utama untuk latency serendah mungkin.

Kalau tujuan Anda **bukan VPN penuh**, dua opsi ini memang lebih tepat daripada OpenVPN/WireGuard.

---

## Perbandingan cepat

| Aspek | 3proxy | Shadowsocks | Squid |
|---|---|---|---|
| Use case utama | HTTP/SOCKS proxy cepat | Proxy terenkripsi ringan | HTTP proxy klasik |
| Setup | Relatif mudah | Sedikit lebih kompleks | Mudah-menengah |
| Performa | Sangat cepat | Cepat, ada overhead enkripsi | Baik, tapi lebih berat |
| Deteksi sebagai proxy | Lebih mudah | Lebih sulit | Lebih mudah |
| Cocok untuk scraping | Sangat cocok | Cocok | Cocok |
| UDP support | SOCKS use case tertentu | Ya | Tidak fokus |
| Full VPN | Tidak | Tidak | Tidak |

---

## Rekomendasi praktis

### Pilih 3proxy bila:

- Anda butuh **proxy server cepat**
- Anda ingin **HTTP proxy dan SOCKS5** dalam satu server
- Anda fokus ke scraping, bot, tools, atau chaining proxy
- Anda ingin overhead serendah mungkin di VPS

### Pilih Shadowsocks bila:

- Anda ingin lapisan privasi tambahan di jaringan lokal/ISP
- Anda butuh trafik yang lebih tidak menonjol dibanding proxy HTTP biasa
- Anda ingin alternatif ketika proxy HTTP biasa lebih mudah diblokir

---

### Pilih Squid bila:

- Anda memang ingin HTTP proxy klasik
- Anda nyaman dengan pendekatan konfigurasi Squid
- Anda tidak mengejar latency serendah mungkin

## Rekomendasi saya untuk kebutuhan Anda

Untuk **scraping/bot dan privasi**, tanpa kebutuhan full-tunnel VPN:

1. Mulai dari **3proxy** sebagai proxy server utama.
2. Siapkan **Shadowsocks** sebagai opsi kedua untuk target yang lebih sensitif atau jaringan yang lebih restriktif.
3. Pakai **Squid** hanya jika Anda memang butuh gaya HTTP proxy klasik.
4. Jika target tetap memblokir, masalahnya biasanya bukan software proxy-nya, tapi **reputasi IP datacenter**.

---

## Port yang umum dipakai

- 3proxy HTTP: `3128`
- 3proxy SOCKS5: `1080`
- Shadowsocks: `8388`

Kalau perlu menyamarkan trafik lebih baik di jaringan tertentu, Shadowsocks sering dipasang di port seperti `443`, tetapi itu tetap bukan jaminan lolos semua inspeksi atau anti-bot.

---

## Keamanan minimum

### Proxy server

- Jangan buka proxy tanpa auth
- Batasi akses dengan firewall jika memungkinkan
- Gunakan password kuat
- Pantau log dan koneksi aktif

### Shadowsocks

- Gunakan password/key kuat
- Jangan pakai cipher lama
- Update binary secara berkala
- Simpan config dengan permission ketat

---

## Struktur file di repo ini

- `docs/http-proxy.md`
- `docs/shadowsocks.md`
- `scripts/setup-3proxy.sh`
- `scripts/setup-http-proxy.sh`
- `scripts/setup-shadowsocks.sh`

---

## Disclaimer operasional

- Proxy sendiri membantu routing dan privasi dasar, tapi **tidak otomatis membuat scraping Anda tidak terdeteksi**.
- Banyak situs memblokir berdasarkan fingerprint browser, TLS, rate limit, cookie, behavior, dan reputasi ASN/IP.
- Gunakan rate limit, retry, rotation, dan hygiene request yang baik.
