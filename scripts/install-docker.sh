#!/bin/bash
set -e

echo "[install-docker] Старт на $(hostname)"

echo "[install-docker] Свободное место ДО расширения:"
df -h /

export DEBIAN_FRONTEND=noninteractive
apt-get update -q
apt-get install -y -q cloud-guest-utils

ROOT_DEVICE=$(findmnt -n -o SOURCE /)
DISK_DEVICE=$(lsblk -ndo PKNAME "$ROOT_DEVICE")
PART_NUM=$(echo "$ROOT_DEVICE" | grep -oE '[0-9]+$')

echo "[install-docker] Корневой раздел: $ROOT_DEVICE (диск /dev/$DISK_DEVICE, раздел $PART_NUM)"

growpart "/dev/$DISK_DEVICE" "$PART_NUM" || true
resize2fs "$ROOT_DEVICE" || true

echo "[install-docker] Свободное место ПОСЛЕ расширения:"
df -h /


echo "[install-docker] Текущие интерфейсы:"
ip -4 addr show

SECOND_IFACE=$(ip -o link show | awk -F': ' '$2 != "lo" && $2 !~ /^vir/ {print $2}' | sed 's/@.*//' | sort | sed -n '2p')
if [ -n "$SECOND_IFACE" ]; then
    echo "[install-docker] Найден второй интерфейс: $SECOND_IFACE"
    
    if ! ip -4 addr show "$SECOND_IFACE" | grep -q "inet "; then
        echo "[install-docker] У $SECOND_IFACE нет IP, поднимаем через netplan"
        
        cat > /etc/netplan/60-vagrant.yaml << NETPLAN
network:
  version: 2
  renderer: networkd
  ethernets:
    $SECOND_IFACE:
      dhcp4: true
NETPLAN
        chmod 600 /etc/netplan/60-vagrant.yaml
        netplan apply || true
        sleep 3
    fi
fi

echo "[install-docker] Все IP после настройки:"
ip -4 addr show

apt-get install -y -q ca-certificates curl gnupg lsb-release

install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg \
  | gpg --dearmor --yes -o /etc/apt/keyrings/docker.gpg
chmod a+r /etc/apt/keyrings/docker.gpg

echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
  https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" \
  > /etc/apt/sources.list.d/docker.list

apt-get update -q
apt-get install -y -q docker-ce docker-ce-cli containerd.io \
  docker-buildx-plugin docker-compose-plugin

usermod -aG docker vagrant
systemctl enable docker
systemctl start docker

echo "[install-docker] Готово. Версия: $(docker --version)"
