#!/bin/bash
# MAUVADAO
# VER: 1.0.1
# DATA: sáb 25 abr 2026 17:49:47 -03

set -e

# ============================
# 🌐 CONFIG
# ============================

IP=$(curl -s ifconfig.me || curl -s ipinfo.io/ip)

PORTA=8080
read -p "TOKEN GLOBAL: "  TOKEN
[[ -z "$TOKEN" ]] && {
TOKEN="$(openssl rand -hex 3)"
}
APIKEY="$(openssl rand -hex 3)"
OPENAI_KEY="sua_openay_key_aqui"
USER_POST='postgres'
PASS_POST="$(openssl rand -hex 8)"
DB_NAME='evolution'

PHONE_VERSION='2.3000.1037786138'


echo "🌍 IP: $IP"
sleep 2

# ============================
# 🔄 RESTART DOCKER
# ============================

_docker_restart() {
    docker compose down || true
    docker compose up -d
}

# ============================
# 🧹 LIMPEZA DOCKER
# ============================

echo "[+] Limpando Docker antigo e corrigindo conflitos..."

systemctl stop docker || true
systemctl stop containerd || true

apt remove -y docker docker-engine docker.io containerd containerd.io || true
apt autoremove -y

rm -rf /var/lib/docker
rm -rf /var/lib/containerd

apt-mark unhold containerd containerd.io docker docker.io || true

dpkg --configure -a || true
apt --fix-broken install -y || true

# ============================
# 🐳 INSTALANDO DOCKER
# ============================

echo "[+] Instalando Docker oficial..."

apt update -y
apt install -y ca-certificates curl gnupg lsb-release

install -m 0755 -d /etc/apt/keyrings

curl -fsSL https://download.docker.com/linux/ubuntu/gpg \
| gpg --dearmor -o /etc/apt/keyrings/docker.gpg

chmod a+r /etc/apt/keyrings/docker.gpg

echo \
"deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
https://download.docker.com/linux/ubuntu \
$(. /etc/os-release && echo $VERSION_CODENAME) stable" \
> /etc/apt/sources.list.d/docker.list

apt update -y

apt install -y \
docker-ce \
docker-ce-cli \
containerd.io \
docker-buildx-plugin \
docker-compose-plugin

apt install -y docker-compose

# ============================
# 🚀 INICIANDO DOCKER
# ============================

echo "[+] Subindo serviços base..."

systemctl daemon-reexec
systemctl daemon-reload

systemctl enable containerd
systemctl restart containerd

sleep 3

systemctl enable docker
systemctl restart docker || true

sleep 5

if ! systemctl is-active --quiet docker; then
    echo "[!] Docker não subiu, tentando correção extra..."
    systemctl restart containerd
    systemctl restart docker || true
fi

# ============================
# 📁 ESTRUTURA EVOLUTION
# ============================

echo "[+] Criando estrutura Evolution..."

mkdir -p /opt/evolution-api
cd /opt/evolution-api

IP=$(curl -s ifconfig.me || curl -s ipinfo.io/ip)

# ============================
# ⚙️ CRIANDO .ENV
# ============================

echo "[+] Criando .env..."

env2() {

cat > .env <<EOF
SERVER_URL=http://$IP:${PORTA}

AUTHENTICATION_API_KEY=${TOKEN}
AUTHENTICATION_TYPE=${APIKEY}

# POSTGRESQL
DATABASE_ENABLED=true
DATABASE_PROVIDER=postgresql

DATABASE_CONNECTION_URI=postgresql://${USER_POST}:${PASS_POST}@postgres:5432/${DB_NAME}

DATABASE_CONNECTION_CLIENT_NAME=evolution_exchange

DATABASE_SAVE_DATA_INSTANCE=true
DATABASE_SAVE_DATA_NEW_MESSAGE=true
DATABASE_SAVE_MESSAGE_UPDATE=true
DATABASE_SAVE_DATA_CONTACTS=true
DATABASE_SAVE_DATA_CHATS=true
DATABASE_SAVE_DATA_LABELS=true
DATABASE_SAVE_DATA_HISTORIC=true

# WHATSAPP
CONFIG_SESSION_PHONE_VERSION=${PHONE_VERSION}

# OPENAI
OPENAI_ENABLED=true
OPENAI_API_KEY=${OPENAI_KEY}
OPENAI_MODEL=gpt-4.1-mini

# REDIS
CACHE_REDIS_ENABLED=true
CACHE_REDIS_URI=redis://redis:6379/6
CACHE_REDIS_PREFIX_KEY=evolution
CACHE_REDIS_SAVE_INSTANCES=false
CACHE_LOCAL_ENABLED=false
EOF

}

env2

# ============================
# 🐋 DOCKER COMPOSE
# ============================

echo "[+] Criando docker-compose.yml..."

cat > docker-compose.yml <<EOF
version: '3.8'

services:

  postgres:
    image: postgres:15
    container_name: postgres
    restart: always

    environment:
      POSTGRES_USER: ${USER_POST}
      POSTGRES_PASSWORD: ${PASS_POST}
      POSTGRES_DB: ${DB_NAME}

    ports:
      - "127.0.0.1:5432:5432"

    volumes:
      - postgres_data:/var/lib/postgresql/data

  redis:
    image: redis:7
    container_name: redis
    restart: always

    ports:
      - "6379:6379"

  evolution_api:
    image: atendai/evolution-api:v2.2.3
    container_name: evolution_api
    restart: always

    depends_on:
      - postgres
      - redis

    ports:
      - "${PORTA}:${PORTA}"

    env_file:
      - .env

volumes:
  postgres_data:
EOF

# ============================
# 🚀 SUBINDO CONTAINERS
# ============================

echo "[+] Subindo containers..."

docker compose down || true
docker compose up -d

# ============================
# ⏳ AGUARDANDO
# ============================

echo "[+] Aguardando inicialização..."

sleep 15

# ============================
# 📊 STATUS
# ============================

echo "[+] STATUS:"
docker ps

echo ""
echo "======================================"
echo "PAINEL: http://$IP:${PORTA}"
echo "API KEY: $TOKEN"
echo "======================================"

sleep 5

curl -sL http://${IP}:${PORTA} \
|| echo "API não respondeu, verifique os logs do container evolution_api"

cat <<EOF > credenciais.txt
PAINEL: http://$IP:${PORTA}
TOKEN_GLOBAL: $TOKEN
APIKEY: $APIKEY
OPENAI: $OPENAI_KEY
USER_POSTGREE: $USER_POST
PASSWORD_POSTGREE: $PASS_POST
DB_POSTGREE: $DB_NAME
EOF