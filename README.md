# framework-proxy

Panduan dan script bootstrap untuk menyiapkan:

- proxy server utama berbasis **3proxy**
- **Shadowsocks** server berbasis **shadowsocks-rust**

Target utama: **Ubuntu VPS**, untuk **scraping/bot**, **privasi dasar**, dan penggunaan proxy yang **bukan full VPN**.

## Isi repo

- `docs/setup-guide.md` — ringkasan riset, perbandingan, dan rekomendasi pemakaian
- `docs/http-proxy.md` — panduan proxy server dengan 3proxy
- `docs/shadowsocks.md` — panduan Shadowsocks dengan shadowsocks-rust
- `scripts/setup-3proxy.sh` — bootstrap 3proxy
- `scripts/setup-http-proxy.sh` — bootstrap HTTP proxy lama berbasis Squid
- `scripts/setup-shadowsocks.sh` — bootstrap Shadowsocks

## Quick start

### 1) Proxy server utama (3proxy)

```bash
chmod +x scripts/setup-3proxy.sh
sudo PROXY_USERNAME=proxyuser PROXY_PASSWORD='ganti-password-kuat' \
  bash scripts/setup-3proxy.sh
```

Default port:

- HTTP proxy: `3128`
- SOCKS5: `1080`

### 2) Alternatif HTTP proxy lama (Squid)

```bash
chmod +x scripts/setup-http-proxy.sh
sudo PROXY_USERNAME=proxyuser PROXY_PASSWORD='ganti-password-kuat' \
  bash scripts/setup-http-proxy.sh
```

Default port: `3128`

### 3) Shadowsocks

```bash
chmod +x scripts/setup-shadowsocks.sh
sudo SS_PASSWORD='ganti-password-atau-key-kuat' \
  bash scripts/setup-shadowsocks.sh
```

Default port: `8388`

## Kapan pakai yang mana?

- Pakai **3proxy** bila tujuan utama Anda adalah **proxy server cepat di VPS** untuk scraping, tools, bot, HTTP proxy, atau SOCKS5.
- Pakai **Shadowsocks** bila butuh trafik yang lebih sulit dikenali sebagai proxy biasa, atau jaringan target/ISP lebih ketat.
- Pakai **Squid** bila Anda memang butuh HTTP proxy klasik dengan gaya konfigurasi yang lebih tradisional.

## Catatan

- Ini **bukan VPN penuh**.
- Untuk target anti-bot yang agresif, **IP VPS datacenter** tetap bisa diblokir walau sudah memakai proxy sendiri.
- Gunakan sesuai hukum lokal dan syarat layanan target.
