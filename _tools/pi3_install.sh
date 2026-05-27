#!/bin/bash
# BY: MAUVADAO
# AUTO INSTALL EVOLUTION API ARM64 SEM DOCKER
# OTIMIZADO PRA RASPBERRY PI 3 1GB

clear

[[ $EUID -ne 0 ]] && {
  echo "Execute como root"
  exit 1
}

read -p "IP ou dominio da VPS/Pi: " DOMAIN
read -p "API KEY: " APIKEY

APP_DIR="/opt/evolution-api"

msg() {
  echo -e "\e[1;32m$1\e[0m"
}

error() {
  echo -e "\e[1;31m$1\e[0m"
}

install_packages() {

  msg "Atualizando sistema..."

  apt update -y
  apt upgrade -y

  msg "Instalando dependencias..."

  apt install -y \
  curl \
  wget \
  git \
  unzip \
  sudo \
  nano \
  htop \
  chromium-browser \
  ffmpeg \
  ca-certificates \
  build-essential \
  python3 \
  python3-pip

}

install_node() {

  msg "Instalando NodeJS 20..."

  curl -fsSL https://deb.nodesource.com/setup_20.x | bash -

  apt install -y nodejs

  node -v || {
    error "Falha ao instalar NodeJS"
    exit 1
  }

}

create_swap() {

  if swapon --show | grep -q "/swapfile"; then
    msg "SWAP ja existe"
    return
  fi

  msg "Criando SWAP 2GB..."

  fallocate -l 2G /swapfile
  chmod 600 /swapfile
  mkswap /swapfile
  swapon /swapfile

  grep -q "/swapfile" /etc/fstab || \
  echo '/swapfile none swap sw 0 0' >> /etc/fstab

}

install_zram() {

  msg "Instalando ZRAM..."

  apt install -y zram-tools

  cat > /etc/default/zramswap <<EOF
ALGO=zstd
PERCENT=75
EOF

  systemctl restart zramswap || true

}

install_evolution() {

  msg "Baixando Evolution API..."

  rm -rf $APP_DIR

  git clone https://github.com/EvolutionAPI/evolution-api.git $APP_DIR

  cd $APP_DIR || exit 1

  msg "Instalando dependencias npm..."

  npm install --omit=dev

  msg "Criando .env..."

  cat > .env <<EOF
SERVER_TYPE=http
SERVER_PORT=8080
SERVER_URL=http://$DOMAIN:8080

CORS_ORIGIN=*

DEL_INSTANCE=false

DATABASE_ENABLED=false

CACHE_REDIS_ENABLED=false

RABBITMQ_ENABLED=false

WEBSOCKET_ENABLED=false

PUSHER_ENABLED=false

TYPEBOT_ENABLED=false

CHATWOOT_ENABLED=false

OPENAI_ENABLED=false

S3_ENABLED=false

AUTHENTICATION_API_KEY=$APIKEY

PUPPETEER_EXECUTABLE_PATH=/usr/bin/chromium-browser

PUPPETEER_ARGS=--no-sandbox,--disable-setuid-sandbox,--disable-dev-shm-usage,--disable-gpu,--single-process,--no-zygote
EOF

  msg "Compilando..."

  npm run build

}

create_service() {

  msg "Criando systemd..."

  cat > /etc/systemd/system/evolution.service <<EOF
[Unit]
Description=Evolution API
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=$APP_DIR
ExecStart=/usr/bin/npm run start:prod
Restart=always
RestartSec=10

# LIMITES RAM
Environment=NODE_OPTIONS=--max-old-space-size=512

[Install]
WantedBy=multi-user.target
EOF

  systemctl daemon-reload
  systemctl enable evolution
  systemctl restart evolution

}

optimize_ram() {

  msg "Otimizando RAM..."

  if grep -q "gpu_mem" /boot/config.txt; then
    sed -i 's/^gpu_mem=.*/gpu_mem=16/g' /boot/config.txt
  else
    echo "gpu_mem=16" >> /boot/config.txt
  fi

}

final_msg() {

clear

echo -e "\e[1;32m=====================================\e[0m"
echo -e "\e[1;32m EVOLUTION API INSTALADA COM SUCESSO\e[0m"
echo -e "\e[1;32m=====================================\e[0m"

echo
echo "URL:"
echo "http://$DOMAIN:8080"
echo
echo "API KEY:"
echo "$APIKEY"
echo

echo "COMANDOS:"
echo
echo "systemctl status evolution"
echo "systemctl restart evolution"
echo "journalctl -u evolution -f"
echo

free -h

}

install_packages
install_node
create_swap
install_zram
install_evolution
create_service
optimize_ram
final_msg
