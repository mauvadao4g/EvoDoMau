#!/bin/bash
# MAUVADAO SSL AUTO
# nginx + certbot + proxy 8080

set -e

dominio="seu_dominio"
email="seu_email@gmail.com"
file="/etc/nginx/sites-available/evolution"

echo "[+] Instalando dependencias..."
apt update -y
apt install -y nginx certbot

echo "[+] Parando nginx pra liberar porta 80..."
systemctl stop nginx || true

echo "[+] Gerando certificado SSL..."
certbot certonly --standalone \
  -d "$dominio" \
  --non-interactive \
  --agree-tos \
  -m "$email"

echo "[+] Limpando config default..."
rm -f /etc/nginx/sites-enabled/default
rm -f /etc/nginx/sites-available/default

echo "[+] Criando config nginx..."
cat > "$file" <<EOF
server {
    listen 80;
    server_name $dominio;

    return 301 https://\$host\$request_uri;
}

server {
    listen 443 ssl;
    server_name $dominio;

    ssl_certificate /etc/letsencrypt/live/$dominio/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/$dominio/privkey.pem;

    location / {
        proxy_pass http://127.0.0.1:8080;

        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;

        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection "upgrade";
    }
}
EOF

echo "[+] Ativando site..."
ln -sf "$file" /etc/nginx/sites-enabled/

echo "[+] Testando nginx..."
nginx -t

echo "[+] Subindo nginx..."
systemctl start nginx
systemctl enable nginx

# Adiciona auto-renovação:
crontab -l 2>/dev/null | grep -q certbot || \
(crontab -l 2>/dev/null; echo "0 3 * * * certbot renew --quiet && systemctl reload nginx") | crontab -

sleep 3

echo "[+] Testando HTTPS..."
curl -I https://$dominio || true

echo "------------------------"
echo "OK: https://$dominio"
echo "Manager: https://$dominio/manager"
echo "------------------------"

cat <<EOF

Observações rápidas (importantes)
Porta 80 precisa estar livre → por isso ele para o nginx antes
DNS do domínio tem que apontar pro VPS
Email é obrigatório pro certbot
Não use certbot --nginx aqui porque você ainda não tem config pronta

EOF
