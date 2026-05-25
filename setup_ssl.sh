#!/bin/bash
# MAUVADAO SSL UNIFICADO
# Nginx + Certbot (Plugin Nginx)

set -e

echo "------------------------------------------------"
echo "   CONFIGURAÇÃO SSL - EVOLUTION API"
echo "------------------------------------------------"

# Coleta de dados
read -p "Digite seu domínio (ex: api.meusite.com): " dominio
read -p "Digite seu e-mail para o SSL: " email

if [[ -z "$dominio" || -z "$email" ]]; then
    echo "[!] Domínio e e-mail são obrigatórios."
    exit 1
fi

file="/etc/nginx/sites-available/evolution"

echo "[+] Instalando Nginx e Certbot..."
apt update -y
apt install -y nginx certbot python3-certbot-nginx

# Criar configuração base do Nginx (Porta 80)
echo "[+] Criando configuração base do Nginx..."
cat > "$file" <<EOF
server {
    listen 80;
    server_name $dominio;

    location / {
        proxy_pass http://127.0.0.1:8080;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        
        # Suporte a WebSockets
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection "upgrade";
    }
}
EOF

# Ativar site
ln -sf "$file" /etc/nginx/sites-enabled/
rm -f /etc/nginx/sites-enabled/default

# Testar e reiniciar Nginx
nginx -t
systemctl restart nginx

echo "[+] Solicitando certificado SSL com Certbot..."
# O comando abaixo gera o certificado e altera o arquivo do Nginx automaticamente para HTTPS
certbot --nginx -d "$dominio" --non-interactive --agree-tos -m "$email" --redirect

echo "[+] Configurando auto-renovação..."
crontab -l 2>/dev/null | grep -q certbot || \
(crontab -l 2>/dev/null; echo "0 3 * * * certbot renew --quiet && systemctl reload nginx") | crontab -

echo "------------------------------------------------"
echo "✅ TUDO OK! SSL configurado com sucesso."
echo "Acesse: https://$dominio"
echo "------------------------------------------------"
