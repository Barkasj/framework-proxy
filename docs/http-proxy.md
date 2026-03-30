# Proxy server dengan 3proxy

## Kenapa 3proxy?

3proxy lebih cocok sebagai proxy server utama di VPS bila prioritas Anda adalah **speed**, **footprint ringan**, dan **dukungan HTTP + SOCKS5**.

## Fitur yang disiapkan oleh script

- Install dependency build dan compile `3proxy`
- Membuat file auth user/password
- Menulis config `3proxy.cfg` yang aman dan ringan
- Menyalakan HTTP proxy dan SOCKS5
- Membuka port via UFW bila tersedia
- Menyalakan service via systemd

## Cara pakai

```bash
chmod +x scripts/setup-3proxy.sh

sudo \
  PROXY_HTTP_PORT=3128 \
  PROXY_SOCKS_PORT=1080 \
  PROXY_USERNAME=proxyuser \
  PROXY_PASSWORD='password-kuat' \
  bash scripts/setup-3proxy.sh
```

## Environment variable

- `PROXY_HTTP_PORT` — default `3128`
- `PROXY_SOCKS_PORT` — default `1080`
- `PROXY_USERNAME` — default `proxyuser`
- `PROXY_PASSWORD` — wajib disarankan diisi

Kalau `PROXY_PASSWORD` tidak diisi, script akan membuat password acak dan menampilkannya di akhir.

## Testing

Contoh uji dengan `curl`:

```bash
curl -x http://proxyuser:password-kuat@IP_VPS:3128 https://httpbin.org/ip

curl --proxy socks5h://proxyuser:password-kuat@IP_VPS:1080 https://httpbin.org/ip
```

## Integrasi ke Python requests

```python
proxies = {
    "http": "http://proxyuser:password-kuat@IP_VPS:3128",
    "https": "http://proxyuser:password-kuat@IP_VPS:3128",
}
```

Untuk SOCKS5, gunakan package tambahan seperti `requests[socks]`.

## Catatan penting

- 3proxy cocok untuk **proxy server**, bukan full system tunnel.
- 3proxy unggul untuk speed dan ringan, tapi tetap bukan alat untuk menyelesaikan reputasi IP yang buruk.
- Jika butuh trafik terenkripsi antar client-server proxy, pertimbangkan `shadowsocks-rust`.

## File yang dibuat oleh script

- Binary: `/usr/local/bin/3proxy`
- Config: `/etc/3proxy/3proxy.cfg`
- Auth file: `/etc/3proxy/.proxyauth`
- Log: `/var/log/3proxy/3proxy.log`
- Service: `/etc/systemd/system/3proxy.service`
