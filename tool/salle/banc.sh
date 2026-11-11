#!/bin/bash
# Banc de la salle : remplace le LiveKit de la pile LOCALE (tool/e2e/pile.sh)
# par un LiveKit place derriere le relais qui abime le reseau
# (tool/salle/reseau_degrade.mjs). Rien ne sort de la machine.
#
#   navigateur --UDP--> relais (passerelle:7882) --UDP--> LiveKit (conteneur:7882)
#
# LiveKit annonce l'adresse de la passerelle : tout le media passe par le relais,
# qui applique un profil par flux (pertes, latence, debit, coupure).
# Usage : tool/salle/banc.sh [demarrer|arreter]
set -euo pipefail
DEPOT="$(cd "$(dirname "$0")/../.." && pwd)"
TRAVAIL="${E2E_TRAVAIL:-/tmp/e2e-pile}"
RESEAU=supabase_network_rewayah-e2e

# Sans cette regle, LiveKit (conteneur) joint le navigateur (hote) en direct
# et le media contourne le relais : on ne laisse sortir son UDP que vers les
# ports du relais (20000 a 20999).
regle() { # -I ou -D, ip du conteneur
  iptables "$1" INPUT -s "$2" -p udp --sport 7882 ! --dport 20000:20999 -j DROP 2>/dev/null || true
}

arreter() {
  pkill -f "tool/salle/reseau_degrade.mjs" 2>/dev/null || true
  if [ -f "$TRAVAIL/banc.regle" ]; then
    # shellcheck disable=SC2046
    regle -D $(cat "$TRAVAIL/banc.regle"); rm -f "$TRAVAIL/banc.regle"
  fi
  docker rm -f e2e-livekit >/dev/null 2>&1 || true
}

demarrer() {
  arreter
  PASSERELLE=$(docker network inspect "$RESEAU" -f '{{(index .IPAM.Config 0).Gateway}}')
  cat > "$TRAVAIL/livekit-banc.yaml" <<YAML
port: 7880
rtc:
  udp_port: 7882
  tcp_port: 7881
  use_external_ip: false
  node_ip: ${PASSERELLE}
keys:
  devkey: secret_e2e_local_livekit_0123456789abcdef
webhook:
  api_key: devkey
  urls:
    - http://${PASSERELLE}:54321/functions/v1/livekit-webhook
logging:
  level: info
YAML
  IMAGE=$(docker ps -a --format '{{.Image}}' | grep livekit-server | head -1 || true)
  IMAGE=${IMAGE:-$(docker images --format '{{.Repository}}:{{.Tag}}' | grep livekit-server | head -1)}
  # Signalisation publiee sur l'hote ; le media (UDP 7882) ne l'est PAS : il
  # n'est joignable que par le relais.
  docker run -d --name e2e-livekit --network "$RESEAU" -p 7880:7880 \
    -v "$TRAVAIL/livekit-banc.yaml:/livekit.yaml:ro" \
    "$IMAGE" --config /livekit.yaml --bind 0.0.0.0 >/dev/null
  sleep 2
  IP_LK=$(docker inspect e2e-livekit -f "{{(index .NetworkSettings.Networks \"$RESEAU\").IPAddress}}")
  regle -I "$IP_LK"; echo "$IP_LK" > "$TRAVAIL/banc.regle"
  (setsid nohup node "$DEPOT/tool/salle/reseau_degrade.mjs" "$PASSERELLE" 7882 "$IP_LK" 7882 7890 \
     > "$TRAVAIL/relais_udp.log" 2>&1 < /dev/null &)
  for _ in $(seq 20); do curl -sf http://127.0.0.1:7880 >/dev/null && break; sleep 1; done
  for _ in $(seq 20); do curl -sf http://127.0.0.1:7890/flux >/dev/null && break; sleep 1; done
  echo "Banc pret : LiveKit $IP_LK derriere le relais ${PASSERELLE}:7882 ; pilotage http://127.0.0.1:7890"
}

case "${1:-demarrer}" in
  demarrer) demarrer ;;
  arreter) arreter ;;
  *) echo "usage : $0 [demarrer|arreter]"; exit 2 ;;
esac
