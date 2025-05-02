#!/bin/bash

set -e

echo "=== WireGuard + Hotspot Otomatik Kurulum Başlatılıyor ==="

# --- 0. Gerekli paketlerin kurulumu ---
echo "[+] Gerekli paketler yükleniyor..."
sudo apt update
sudo apt install -y libgtk-3-dev build-essential gcc g++ pkg-config make \
    hostapd libqrencode-dev libpng-dev wireguard curl git dnsmasq \
    software-properties-common

sudo add-apt-repository -y ppa:lakinduakash/lwh
sudo apt update
sudo apt install -y linux-wifi-hotspot

# --- 1. WireGuard bilgilerini al ---
echo -e "\n🔐 WireGuard ayarlarını giriniz:"
read -p "PrivateKey: " WG_PRIVATE_KEY
read -p "PublicKey (Server): " WG_PUBLIC_KEY
read -p "PresharedKey: " WG_PRESHARED_KEY
read -p "Endpoint (ip:port): " WG_ENDPOINT
read -p "Local IP (örnek: 10.0.0.2/24): " WG_ADDRESS

# --- 2. Ağ arayüzlerini göster ve seçtir ---
echo -e "\n📡 Mevcut ağ arayüzleri:"
ip link | awk -F: '/^[0-9]+: / {print " - " $2}' | sed 's/^[ \t]*//'

read -p "Wi-Fi arayüzü (örn: wlan0): " WIFI_IFACE
read -p "İnternet çıkışı yapılacak arayüz (örn: wg0): " INTERNET_IFACE
read -p "Hotspot SSID: " HOTSPOT_SSID
read -p "Hotspot Şifre: " HOTSPOT_PASSWORD

# --- 3. WireGuard yapılandırma dosyası ---
echo "[+] /etc/wireguard/wg0.conf yazılıyor..."
sudo mkdir -p /etc/wireguard
sudo tee /etc/wireguard/wg0.conf > /dev/null <<EOF
[Interface]
PrivateKey = $WG_PRIVATE_KEY
Address = $WG_ADDRESS
DNS = 1.1.1.1

[Peer]
PublicKey = $WG_PUBLIC_KEY
PresharedKey = $WG_PRESHARED_KEY
Endpoint = $WG_ENDPOINT
AllowedIPs = 0.0.0.0/0
PersistentKeepalive = 25
EOF

sudo chmod 600 /etc/wireguard/wg0.conf

# --- 4. Hotspot yapılandırma dosyası (detaylı create_ap.conf) ---
echo "[+] /etc/create_ap.conf yazılıyor..."
sudo tee /etc/create_ap.conf > /dev/null <<EOF
WIFI_IFACE=$WIFI_IFACE
INTERNET_IFACE=$INTERNET_IFACE
SSID=$HOTSPOT_SSID
PASSPHRASE=$HOTSPOT_PASSWORD
CHANNEL=default
GATEWAY=192.168.12.1
WPA_VERSION=2
ETC_HOSTS=0
DHCP_DNS=gateway
NO_DNS=0
NO_DNSMASQ=0
HIDDEN=0
MAC_FILTER=0
MAC_FILTER_ACCEPT=/etc/hostapd/hostapd.accept
ISOLATE_CLIENTS=0
SHARE_METHOD=nat
IEEE80211N=0
IEEE80211AC=0
IEEE80211AX=0
HT_CAPAB=[HT40+]
VHT_CAPAB=
DRIVER=nl80211
NO_VIRT=0
COUNTRY=
FREQ_BAND=2.4
NEW_MACADDR=
DAEMONIZE=0
NO_HAVEGED=0
USE_PSK=0
DHCP_HOSTS=
EOF

# --- 5. Servisleri aktif et ve başlat ---
echo "[+] Servisler etkinleştiriliyor..."
sudo systemctl daemon-reexec
sudo systemctl daemon-reload
sudo systemctl enable wg-quick@wg0.service
sudo systemctl enable create_ap.service

echo "[+] Servisler başlatılıyor..."
sudo systemctl start wg-quick@wg0.service
sudo systemctl start create_ap.service

sudo sysctl -w net.ipv6.conf.all.disable_ipv6=1
sudo sysctl -w net.ipv6.conf.default.disable_ipv6=1

# --- 6. Tamamlandı ---
echo -e "\n✅ Kurulum tamamlandı!"
echo "🌐 VPN bağlantısı ve Hotspot artık sistem başlangıcında otomatik olarak devreye girecek."
echo "📡 Hotspot SSID: $HOTSPOT_SSID"
echo "🛜 VPN arayüzü: $WG_ADDRESS → $WG_ENDPOINT"
