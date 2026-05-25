#!/bin/bash
# MAUVADAO
# VER: 1.0.0
# DATA: dom 10 mai 2026 09:16:59 -03

_info(){
cat <<EOF
✔️ Opção mais simples (recomendada)

Usar Nginx + Certbot

🔧 Ideia geral:
Seu container continua rodando em :8080
Nginx escuta na :81 e :443
Nginx encaminha pro container
Certbot gera SSL grátis (Let's Encrypt)

EOF
}


# 1. Instalar
apt update
apt install nginx certbot python3-certbot-nginx -y

# 2. Criar config do site
dominio='seu_dominio'
file='/etc/nginx/sites-available/evolution'
cat >"$file" <<'EOF'
server {
    listen 80;
    server_name \$dominio;

    location / {
        proxy_pass http://127.0.0.1:8080;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }
}

EOF

# 3. Ativar
ln -s /etc/nginx/sites-available/evolution /etc/nginx/sites-enabled/
nginx -t
systemctl restart nginx


# 4. Gerar HTTPS
certbot --nginx -d $dominio
echo '------------------------------------------'
cat <<EOF
Ele vai:

gerar certificado
editar config automaticamente

💡 Resultado final
Você acessa: https://seu_dominio/manager/
Sem precisar mexer no container.

⚠️ Dicas importantes
Porta 80 e 443 precisam estar liberadas
DNS do domínio precisa apontar pro seu servidor
Não usa :8080 no HTTPS (isso fica interno)
EOF
echo '------------------------------------------'
