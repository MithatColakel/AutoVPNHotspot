#!/bin/bash

set -e
cd "$(dirname "$0")"

if [ ! -f "./settings.env" ]; then
    echo "❌ settings.env bulunamadı"
    exit 1
fi

source ./settings.env

echo "[+] Hotspot (create_ap) başlatılıyor..."
sudo pkill create_ap || true
sudo create_ap "$HOTSPOT_INTERFACE" "$WG_INTERFACE" "$HOTSPOT_SSID" "$HOTSPOT_PASSWORD"
