#!/bin/bash
set -e

echo "[swarm-init] Запуск на $(hostname)"

MANAGER_IP=$(ip -4 addr show | grep -oP '(?<=inet\s)192\.168\.56\.\d+' | head -1)

if [ -z "$MANAGER_IP" ]; then
    echo "[swarm-init] ОШИБКА: не нашёл IP в 192.168.56.0/24"
    echo "[swarm-init] Все IP-адреса:"
    hostname -I
    exit 1
fi

echo "[swarm-init] Определён IP манагера: $MANAGER_IP"

if docker info 2>/dev/null | grep -q "Swarm: active"; then
    echo "[swarm-init] Swarm уже активен, пропускаем init"
else
    docker swarm init --advertise-addr "$MANAGER_IP"
fi

mkdir -p /home/vagrant/project/swarm

WORKER_TOKEN=$(docker swarm join-token -q worker)
echo -n "$WORKER_TOKEN" > /home/vagrant/project/swarm/worker-token.txt
echo -n "$MANAGER_IP" > /home/vagrant/project/swarm/manager-ip.txt

chown -R vagrant:vagrant /home/vagrant/project/swarm

echo "[swarm-init] Токен и IP сохранены в /home/vagrant/project/swarm/"
echo "[swarm-init] Текущее состояние Swarm:"
docker node ls
