#!/bin/bash

set -e

echo "[+] Gerekli paketler yükleniyor..."
sudo apt update
sudo apt install -y libgtk-3-dev build-essential gcc g++ pkg-config make \
    hostapd libqrencode-dev libpng-dev wireguard curl git dnsmasq \
    software-properties-common

sudo add-apt-repository -y ppa:lakinduakash/lwh
sudo apt update
sudo apt install -y linux-wifi-hotspot

echo "[+] Kurulum dizini oluşturuluyor..."
INSTALL_DIR="/opt/wg-hotspot"
sudo mkdir -p "$INSTALL_DIR"

echo "[+] Script dosyaları kopyalanıyor..."
sudo cp start-wireguard.sh start-hotspot.sh settings.env "$INSTALL_DIR"
sudo chmod +x "$INSTALL_DIR"/*.sh

echo "[+] systemd servisleri oluşturuluyor..."

# WireGuard servis
sudo tee /etc/systemd/system/wireguard-autostart.service > /dev/null <<EOF
[Unit]
Description=Auto-start WireGuard
After=network.target

[Service]
ExecStart=$INSTALL_DIR/start-wireguard.sh
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF

# Hotspot servis
sudo tee /etc/systemd/system/hotspot-autostart.service > /dev/null <<EOF
[Unit]
Description=Auto-start Hotspot
After=network.target

[Service]
ExecStart=$INSTALL_DIR/start-hotspot.sh
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable wireguard-autostart.service
sudo systemctl enable hotspot-autostart.service

echo "✅ Kurulum tamamlandı. Sistemin açılışında WireGuard ve Hotspot ayrı ayrı başlayacak."
