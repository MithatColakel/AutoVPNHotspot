#!/bin/bash

set -e
cd "$(dirname "$0")"

if [ ! -f "./settings.env" ]; then
    echo "❌ settings.env bulunamadı"
    exit 1
fi

source ./settings.env

echo "[+] WireGuard yapılandırması oluşturuluyor..."
cat <<EOF > wg0.conf
[Interface]
PrivateKey = $WG_PRIVATE_KEY
Address = $WG_ADDRESS
DNS = $WG_DNS

[Peer]
PublicKey = $WG_PEER_PUBLIC_KEY
Endpoint = $WG_ENDPOINT
AllowedIPs = $WG_ALLOWED_IPS
PersistentKeepalive = $WG_KEEPALIVE
EOF

echo "[+] WireGuard başlatılıyor..."
sudo wg-quick down ./wg0.conf 2>/dev/null || true
sudo wg-quick up ./wg0.conf
