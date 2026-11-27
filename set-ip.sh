#!/usr/bin/env bash
# Detecta o IP da máquina (ou usa o informado) e aplica no lab.
# Uso: ./set-ip.sh            -> detecta sozinho
#      ./set-ip.sh 127.0.0.1  -> força um IP (ex.: teste no WSL)
set -euo pipefail
cd "$(dirname "$0")"

IP="${1:-$(ip -4 route get 1.1.1.1 | awk '{for(i=1;i<=NF;i++) if($i=="src"){print $(i+1); exit}}')}"
[ -n "$IP" ] || { echo "Não consegui detectar o IP"; exit 1; }

# .env: troca a linha LAB_IP ou cria se não existir
if grep -q '^LAB_IP=' .env; then
  sed -i "s/^LAB_IP=.*/LAB_IP=$IP/" .env
else
  echo "LAB_IP=$IP" >> .env
fi

# dnsmasq: só mexe se ele estiver configurado nesta máquina
if [ -f /etc/dnsmasq.d/lab.conf ]; then
  sudo sed -i -e "s#^listen-address=.*#listen-address=$IP#" \
              -e "s#^address=/lab.internal/.*#address=/lab.internal/$IP#" /etc/dnsmasq.d/lab.conf
  sudo systemctl restart dnsmasq
fi

docker compose up -d     # o Compose percebe que o LAB_IP mudou e recria só o LiveKit
echo "Lab configurado no IP $IP"
