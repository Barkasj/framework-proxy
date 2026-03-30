#!/usr/bin/env bash

set -euo pipefail

if [[ "${EUID}" -ne 0 ]]; then
  echo "Jalankan sebagai root: sudo bash scripts/setup-shadowsocks.sh"
  exit 1
fi

SS_PORT="${SS_PORT:-8388}"
SS_METHOD="${SS_METHOD:-chacha20-ietf-poly1305}"
SS_PASSWORD="${SS_PASSWORD:-}"

if [[ -z "${SS_PASSWORD}" ]]; then
  SS_PASSWORD="$(openssl rand -base64 32 | tr -d '=+/\n' | cut -c1-32)"
fi

BIN_DIR="/usr/local/bin"
CONFIG_DIR="/etc/shadowsocks-rust"
CONFIG_FILE="${CONFIG_DIR}/config.json"
SERVICE_FILE="/etc/systemd/system/shadowsocks-rust.service"
TMP_DIR="$(mktemp -d)"

cleanup() {
  rm -rf "${TMP_DIR}"
}
trap cleanup EXIT

detect_asset_name() {
  local arch
  arch="$(uname -m)"

  case "${arch}" in
    x86_64)
      echo "x86_64-unknown-linux-gnu"
      ;;
    aarch64|arm64)
      echo "aarch64-unknown-linux-gnu"
      ;;
    *)
      echo "Unsupported architecture: ${arch}" >&2
      exit 1
      ;;
  esac
}

echo "[1/7] Installing dependencies..."
apt-get update
DEBIAN_FRONTEND=noninteractive apt-get install -y curl python3 tar openssl ufw

echo "[2/7] Resolving latest shadowsocks-rust release..."
ASSET_SUFFIX="$(detect_asset_name)"
RELEASE_JSON="${TMP_DIR}/release.json"
curl -fsSL https://api.github.com/repos/shadowsocks/shadowsocks-rust/releases/latest -o "${RELEASE_JSON}"

DOWNLOAD_URL="$({ python3 - "${RELEASE_JSON}" "${ASSET_SUFFIX}" <<'PY'
import json
import sys

release_path = sys.argv[1]
suffix = sys.argv[2]

with open(release_path, 'r', encoding='utf-8') as fh:
    data = json.load(fh)

for asset in data.get('assets', []):
    name = asset.get('name', '')
    if name.endswith(f"{suffix}.tar.xz"):
        print(asset['browser_download_url'])
        break
else:
    raise SystemExit(f"No release asset found for suffix: {suffix}")
PY
} )"

ARCHIVE_PATH="${TMP_DIR}/shadowsocks-rust.tar.xz"

echo "[3/7] Downloading release asset..."
curl -fsSL "${DOWNLOAD_URL}" -o "${ARCHIVE_PATH}"

echo "[4/7] Installing ssserver binary..."
tar -xJf "${ARCHIVE_PATH}" -C "${TMP_DIR}"
install -m 0755 "${TMP_DIR}/ssserver" "${BIN_DIR}/ssserver"

echo "[5/7] Writing config..."
mkdir -p "${CONFIG_DIR}"
cat > "${CONFIG_FILE}" <<EOF
{
  "server": "0.0.0.0",
  "server_port": ${SS_PORT},
  "password": "${SS_PASSWORD}",
  "method": "${SS_METHOD}",
  "timeout": 7200,
  "mode": "tcp_and_udp"
}
EOF
chmod 600 "${CONFIG_FILE}"

echo "[6/7] Writing systemd service..."
cat > "${SERVICE_FILE}" <<EOF
[Unit]
Description=Shadowsocks Rust Server
After=network.target

[Service]
Type=simple
ExecStart=${BIN_DIR}/ssserver -c ${CONFIG_FILE}
Restart=on-failure
RestartSec=3
LimitNOFILE=65535

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable shadowsocks-rust
systemctl restart shadowsocks-rust

echo "[7/7] Opening firewall if UFW is active..."
if command -v ufw >/dev/null 2>&1; then
  if ufw status | grep -qi "Status: active"; then
    ufw allow "${SS_PORT}/tcp"
    ufw allow "${SS_PORT}/udp"
  fi
fi

PUBLIC_IP="$(curl -4 -fsS https://ifconfig.me 2>/dev/null || true)"

echo
echo "Shadowsocks ready"
echo "- Server   : ${PUBLIC_IP:-<IP_VPS>}"
echo "- Port     : ${SS_PORT}"
echo "- Method   : ${SS_METHOD}"
echo "- Password : ${SS_PASSWORD}"
