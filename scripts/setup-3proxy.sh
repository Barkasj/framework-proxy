#!/usr/bin/env bash

set -euo pipefail

if [[ "${EUID}" -ne 0 ]]; then
  echo "Jalankan sebagai root: sudo bash scripts/setup-3proxy.sh"
  exit 1
fi

PROXY_HTTP_PORT="${PROXY_HTTP_PORT:-3128}"
PROXY_SOCKS_PORT="${PROXY_SOCKS_PORT:-1080}"
PROXY_USERNAME="${PROXY_USERNAME:-proxyuser}"
PROXY_PASSWORD="${PROXY_PASSWORD:-}"

if [[ -z "${PROXY_PASSWORD}" ]]; then
  PROXY_PASSWORD="$(openssl rand -base64 24 | tr -d '=+/\n' | cut -c1-24)"
fi

INSTALL_ROOT="/opt/3proxy-src"
SOURCE_DIR="${INSTALL_ROOT}/3proxy"
BIN_PATH="/usr/local/bin/3proxy"
CONFIG_DIR="/etc/3proxy"
CONFIG_FILE="${CONFIG_DIR}/3proxy.cfg"
AUTH_FILE="${CONFIG_DIR}/.proxyauth"
SERVICE_FILE="/etc/systemd/system/3proxy.service"
LOG_DIR="/var/log/3proxy"

echo "[1/8] Installing dependencies..."
apt-get update
DEBIAN_FRONTEND=noninteractive apt-get install -y build-essential git ca-certificates curl openssl ufw

echo "[2/8] Preparing source directory..."
mkdir -p "${INSTALL_ROOT}"
if [[ -d "${SOURCE_DIR}/.git" ]]; then
  git -C "${SOURCE_DIR}" fetch --tags --force
  git -C "${SOURCE_DIR}" pull --ff-only
else
  rm -rf "${SOURCE_DIR}"
  git clone https://github.com/3proxy/3proxy.git "${SOURCE_DIR}"
fi

echo "[3/8] Building 3proxy..."
make -f Makefile.Linux -C "${SOURCE_DIR}"
install -m 0755 "${SOURCE_DIR}/bin/3proxy" "${BIN_PATH}"

echo "[4/8] Creating directories..."
mkdir -p "${CONFIG_DIR}" "${LOG_DIR}"

echo "[5/8] Writing auth file..."
cat > "${AUTH_FILE}" <<EOF
${PROXY_USERNAME}:CL:${PROXY_PASSWORD}
EOF
chmod 600 "${AUTH_FILE}"

echo "[6/8] Writing config..."
cat > "${CONFIG_FILE}" <<EOF
nserver 1.1.1.1
nserver 8.8.8.8
nscache 65536

log ${LOG_DIR}/3proxy.log D
rotate 30
logformat "- +_L%t.%. %N.%p %E %U %C:%c %R:%r %O %I %h %T"

timeouts 1 5 30 60 180 1800 15 60
maxconn 500
stacksize 65536

users \
  $/${AUTH_FILE}

authcache user,password 60
auth strong cache

deny * * 127.0.0.0/8,10.0.0.0/8,172.16.0.0/12,192.168.0.0/16,169.254.0.0/16
allow *

proxy -p${PROXY_HTTP_PORT} -a -n -osTCP_NODELAY -ocTCP_NODELAY

flush

authcache user,password 60
auth strong cache
deny * * 127.0.0.0/8,10.0.0.0/8,172.16.0.0/12,192.168.0.0/16,169.254.0.0/16
allow *

socks -p${PROXY_SOCKS_PORT}
EOF
chmod 600 "${CONFIG_FILE}"

echo "[7/8] Writing systemd service..."
cat > "${SERVICE_FILE}" <<EOF
[Unit]
Description=3proxy Proxy Server
After=network.target
Wants=network-online.target

[Service]
Type=simple
ExecStart=${BIN_PATH} ${CONFIG_FILE}
ExecReload=/bin/kill -SIGUSR1 \$MAINPID
KillMode=process
Restart=on-failure
RestartSec=60s
LimitNOFILE=65536
PrivateTmp=yes
NoNewPrivileges=true

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable 3proxy
systemctl restart 3proxy

echo "[8/8] Opening firewall if UFW is active..."
if command -v ufw >/dev/null 2>&1; then
  if ufw status | grep -qi "Status: active"; then
    ufw allow "${PROXY_HTTP_PORT}/tcp"
    ufw allow "${PROXY_SOCKS_PORT}/tcp"
  fi
fi

PUBLIC_IP="$(curl -4 -fsS https://ifconfig.me 2>/dev/null || true)"

echo
echo "3proxy ready"
echo "- HTTP Port : ${PROXY_HTTP_PORT}"
echo "- SOCKS Port: ${PROXY_SOCKS_PORT}"
echo "- Username  : ${PROXY_USERNAME}"
echo "- Password  : ${PROXY_PASSWORD}"
if [[ -n "${PUBLIC_IP}" ]]; then
  echo "- HTTP URL  : http://${PROXY_USERNAME}:${PROXY_PASSWORD}@${PUBLIC_IP}:${PROXY_HTTP_PORT}"
  echo "- SOCKS URL : socks5://${PROXY_USERNAME}:${PROXY_PASSWORD}@${PUBLIC_IP}:${PROXY_SOCKS_PORT}"
fi
