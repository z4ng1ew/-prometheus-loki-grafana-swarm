#!/bin/bash
set -e

TOKEN_FILE="/home/vagrant/project/swarm/worker-token.txt"
MANAGER_IP_FILE="/home/vagrant/project/swarm/manager-ip.txt"

echo "[swarm-join] Подключение $(hostname) к Swarm"

if docker info 2>/dev/null | grep -q "Swarm: active"; then
    echo "[swarm-join] $(hostname) уже в Swarm, пропускаем"
    exit 0
fi

if [ ! -f "$TOKEN_FILE" ] || [ ! -f "$MANAGER_IP_FILE" ]; then
    echo "[swarm-join] ОШИБКА: не найдены файлы $TOKEN_FILE или $MANAGER_IP_FILE"
    echo "[swarm-join] Проверь, что manager01 успешно провижился"
    exit 1
fi

WORKER_TOKEN=$(cat "$TOKEN_FILE" | tr -d '\r' | xargs)
MANAGER_IP=$(cat "$MANAGER_IP_FILE" | tr -d '\r' | xargs)

if [[ ! "$WORKER_TOKEN" =~ ^SWMTKN-1- ]]; then
    echo "[swarm-join] ОШИБКА: токен не похож на валидный."
    echo "[swarm-join] Содержимое файла токена:"
    xxd "$TOKEN_FILE" | head -5
    exit 1
fi

if [[ ! "$MANAGER_IP" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    echo "[swarm-join] ОШИБКА: IP менеджера не валидный: '$MANAGER_IP'"
    exit 1
fi

echo "[swarm-join] Подключаюсь к менеджеру $MANAGER_IP:2377"

docker swarm join --token "$WORKER_TOKEN" "$MANAGER_IP:2377"

echo "[swarm-join] $(hostname) успешно подключён к Swarm"
