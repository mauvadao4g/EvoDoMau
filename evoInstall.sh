#!/bin/bash
# MAUVADAO - EVOLUTION API INSTALLER
# VER: 1.1.0
# DATA: 2026-05-25

set -e

# ============================
# 🌐 CONFIGURAÇÃO INICIAL
# ============================

IP=$(curl -s ifconfig.me || curl -s ipinfo.io/ip)
PORTA=8080
PHONE_VERSION='2.3000.1037786138'

echo "🌍 IP DETECTADO: $IP"
sleep 1

# ============================
# 🐳 GERENCIAMENTO DOCKER
# ============================

echo "------------------------------------------------"
echo "OPÇÕES DE INSTALAÇÃO DOCKER:"
echo "1) Limpeza Total (Remove TUDO e reinstala - Recomendado para VPS nova)"
echo "2) Manter Atual (Apenas instala dependências se faltarem)"
echo "------------------------------------------------"
read -p "Escolha uma opção [1-2]: " DOCKER_OPT

if [[ "$DOCKER_OPT" == "1" ]]; then
    echo "[+] Realizando limpeza completa do Docker..."
    systemctl stop docker || true
    systemctl stop containerd || true
    apt remove -y docker docker-engine docker.io containerd containerd.io || true
    apt autoremove -y
    rm -rf /var/lib/docker
    rm -rf /var/lib/containerd
    apt-mark unhold containerd containerd.io docker docker.io || true
    dpkg --configure -a || true
    apt --fix-broken install -y || true
else
    echo "[+] Mantendo instalação atual do Docker. Verificando dependências..."
fi

# ============================
# 🐳 INSTALANDO/ATUALIZANDO DOCKER
# ============================

echo "[+] Configurando repositório e instalando Docker..."
apt update -y
apt install -y ca-certificates curl gnupg lsb-release

if [ ! -f /etc/apt/keyrings/docker.gpg ]; then
    install -m 0755 -d /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
    chmod a+r /etc/apt/keyrings/docker.gpg
fi

if [ ! -f /etc/apt/sources.list.d/docker.list ]; then
    echo \
    "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
    https://download.docker.com/linux/ubuntu \
    $(. /etc/os-release && echo $VERSION_CODENAME) stable" \
    > /etc/apt/sources.list.d/docker.list
fi

apt update -y
apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# ============================
# 🚀 INICIANDO DOCKER
# ============================

systemctl daemon-reload
systemctl enable containerd
systemctl restart containerd
systemctl enable docker
systemctl restart docker || true

# ============================
# ⚙️ CONFIGURAÇÕES EVOLUTION
# ============================

echo "[+] Criando estrutura Evolution..."
mkdir -p /opt/evolution-api
cd /opt/evolution-api

# Coleta de dados interativa
echo "------------------------------------------------"
read -p "TOKEN GLOBAL (Enter para aleatório): " TOKEN
[[ -z "$TOKEN" ]] && TOKEN="$(openssl rand -hex 12)"

read -p "CHAVE OPENAI (Enter para ignorar): " OPENAI_KEY
[[ -z "$OPENAI_KEY" ]] && OPENAI_KEY="sua_chave_aqui"
echo "------------------------------------------------"

APIKEY="$(openssl rand -hex 12)"
USER_POST='postgres'
PASS_POST="$(openssl rand -hex 12)"
DB_NAME='evolution'

# ============================
# ⚙️ CRIANDO .ENV
# ============================

echo "[+] Criando .env..."

cat > .env <<EOF
SERVER_URL=http://$IP:${PORTA}

AUTHENTICATION_API_KEY=${TOKEN}
AUTHENTICATION_TYPE=apikey

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
OPENAI_MODEL=gpt-4o-mini

# REDIS
CACHE_REDIS_ENABLED=true
CACHE_REDIS_URI=redis://redis:6379/6
CACHE_REDIS_PREFIX_KEY=evolution
CACHE_REDIS_SAVE_INSTANCES=false
CACHE_LOCAL_ENABLED=false
EOF

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
      - "127.0.0.1:6379:6379"

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
# ⏳ AGUARDANDO E STATUS
# ============================

echo "[+] Aguardando inicialização (15s)..."
sleep 15

echo "[+] STATUS DOS CONTAINERS:"
docker ps

echo ""
echo "======================================"
echo "PAINEL: http://$IP:${PORTA}"
echo "TOKEN GLOBAL: $TOKEN"
echo "======================================"

cat <<EOF > credenciais.txt
PAINEL: http://$IP:${PORTA}
TOKEN_GLOBAL: $TOKEN
APIKEY: $APIKEY
OPENAI_KEY: $OPENAI_KEY
USER_POSTGRES: $USER_POST
PASSWORD_POSTGRES: $PASS_POST
DB_NAME: $DB_NAME
EOF

echo "[+] Credenciais salvas em /opt/evolution-api/credenciais.txt"
