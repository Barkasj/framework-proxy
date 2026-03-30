# Shadowsocks server dengan shadowsocks-rust

## Kenapa shadowsocks-rust?

Implementasi ini ringan, cepat, modern, dan cocok untuk VPS Ubuntu.

## Fitur yang disiapkan oleh script

- Mengambil rilis terbaru `shadowsocks-rust` dari GitHub
- Menginstall binary `ssserver` ke `/usr/local/bin`
- Membuat config JSON untuk server
- Menambahkan systemd service
- Membuka port via UFW bila tersedia

## Cara pakai

```bash
chmod +x scripts/setup-shadowsocks.sh

sudo \
  SS_PORT=8388 \
  SS_METHOD=chacha20-ietf-poly1305 \
  SS_PASSWORD='password-atau-key-kuat' \
  bash scripts/setup-shadowsocks.sh
```

## Environment variable

- `SS_PORT` — default `8388`
- `SS_METHOD` — default `chacha20-ietf-poly1305`
- `SS_PASSWORD` — wajib disarankan diisi

Jika `SS_PASSWORD` kosong, script akan membuat secret acak.

## Testing

Client Shadowsocks perlu dikonfigurasi dengan:

- server: `IP_VPS`
- port: `8388`
- method: sesuai `SS_METHOD`
- password: sesuai `SS_PASSWORD`

Lalu arahkan browser/tool scraping ke local SOCKS port dari client Shadowsocks Anda.

## Kapan lebih bagus daripada HTTP proxy?

- Saat Anda ingin trafik tidak terlalu terlihat seperti proxy HTTP biasa
- Saat jaringan lokal/ISP lebih restriktif
- Saat Anda butuh fleksibilitas SOCKS-based workflow

## Catatan penting

- Ini tetap bukan full VPN.
- Untuk scraping, Shadowsocks membantu sisi transport, tapi tidak mengatasi fingerprint browser atau reputasi IP.
