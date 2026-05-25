#!/bin/bash
# BY: MAUVADAO
# VER: $

EVO="https://raw.githubusercontent.com/mauvadao4g/EvoDoMau/refs/heads/main/evoInstall.sh"

SSL="https://raw.githubusercontent.com/mauvadao4g/EvoDoMau/refs/heads/main/setup_ssl.sh"

echo "1 => EVOLUTION API"
echo "2 => SSL CERTIFICADO"
echo "0 => SAIR"
echo "..."

read -p "Deseja instalar qual serviço: " xd

case "$xd" in
    1)
        [[ -f evoInstall.sh ]] && {
            bash evoInstall.sh
            exit 0
        } || {
            bash <(wget -qO- "$EVO")
            exit 0
        }
    ;;

    2)
        [[ -f setup_ssl.sh ]] && {
            bash setup_ssl.sh
            exit 0
        } || {
            bash <(wget -qO- "$SSL")
            exit 0
        }
    ;;

    0)
        echo "Saindo ..."
        sleep 2
        exit 0
    ;;

    *)
        echo "Opcao invalida!"
    ;;
esac