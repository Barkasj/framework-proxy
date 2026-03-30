#!/usr/bin/env bash

set -euo pipefail

if [[ "${EUID}" -ne 0 ]]; then
  echo "Jalankan sebagai root: sudo bash scripts/setup-http-proxy.sh"
  exit 1
fi

PROXY_PORT="${PROXY_PORT:-3128}"
PROXY_USERNAME="${PROXY_USERNAME:-proxyuser}"
PROXY_PASSWORD="${PROXY_PASSWORD:-}"

if [[ -z "${PROXY_PASSWORD}" ]]; then
  PROXY_PASSWORD="$(openssl rand -base64 24 | tr -d '=+/\n' | cut -c1-24)"
fi

SQUID_CONF="/etc/squid/squid.conf"
SQUID_PASSWD="/etc/squid/passwd"

echo "[1/6] Installing packages..."
apt-get update
DEBIAN_FRONTEND=noninteractive apt-get install -y squid apache2-utils openssl ufw

echo "[2/6] Backing up existing config if present..."
if [[ -f "${SQUID_CONF}" ]]; then
  cp "${SQUID_CONF}" "${SQUID_CONF}.bak.$(date +%Y%m%d%H%M%S)"
fi

echo "[3/6] Writing auth credentials..."
htpasswd -bc "${SQUID_PASSWD}" "${PROXY_USERNAME}" "${PROXY_PASSWORD}"
chmod 640 "${SQUID_PASSWD}"
chown proxy:proxy "${SQUID_PASSWD}" 2>/dev/null || true

echo "[4/6] Writing squid config..."
cat > "${SQUID_CONF}" <<EOF
http_port ${PROXY_PORT}

auth_param basic program /usr/lib/squid/basic_ncsa_auth ${SQUID_PASSWD}
auth_param basic realm proxy
auth_param basic credentialsttl 2 hours
acl authenticated proxy_auth REQUIRED

acl SSL_ports port 443
acl Safe_ports port 80
acl Safe_ports port 443
acl Safe_ports port 1025-65535
acl CONNECT method CONNECT

http_access deny !Safe_ports
http_access deny CONNECT !SSL_ports
http_access allow authenticated
http_access deny all

access_log stdio:/var/log/squid/access.log
cache_log /var/log/squid/cache.log
pid_filename /run/squid.pid

coredump_dir /var/spool/squid
EOF

echo "[5/6] Enabling service..."
systemctl enable squid
systemctl restart squid

echo "[6/6] Opening firewall if UFW is active..."
if command -v ufw >/dev/null 2>&1; then
  if ufw status | grep -qi "Status: active"; then
    ufw allow "${PROXY_PORT}/tcp"
  fi
fi

PUBLIC_IP="$(curl -4 -fsS https://ifconfig.me 2>/dev/null || true)"

echo
echo "HTTP proxy ready"
echo "- Port     : ${PROXY_PORT}"
echo "- Username : ${PROXY_USERNAME}"
echo "- Password : ${PROXY_PASSWORD}"
if [[ -n "${PUBLIC_IP}" ]]; then
  echo "- Test URL : http://${PROXY_USERNAME}:${PROXY_PASSWORD}@${PUBLIC_IP}:${PROXY_PORT}"
fi
