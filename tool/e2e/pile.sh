#!/bin/bash
# Monte la pile LOCALE des tests de bout en bout : Supabase (base, auth, Mailpit,
# fonctions Edge), LiveKit en mode --dev, puis construit et sert l'application.
# Rien ne sort vers la production : URL et cles sont celles de la pile locale.
#
# Usage : tool/e2e/pile.sh [demarrer|construire|servir|arreter]   (defaut : tout)
# Variables : E2E_TRAVAIL (defaut /tmp/e2e-pile), E2E_PORT_APP (defaut 8090).
set -euo pipefail
DEPOT="$(cd "$(dirname "$0")/../.." && pwd)"
TRAVAIL="${E2E_TRAVAIL:-/tmp/e2e-pile}"
PORT_APP="${E2E_PORT_APP:-8090}"
APP="http://127.0.0.1:${PORT_APP}"
SUPA="npx --yes supabase@2.122.0"
export PATH="/opt/flutter/bin:$PATH"
mkdir -p "$TRAVAIL"

docker_pret() {
  if ! docker info >/dev/null 2>&1; then
    (nohup dockerd >/tmp/dockerd.log 2>&1 &)
    for _ in $(seq 30); do docker info >/dev/null 2>&1 && return; sleep 1; done
    echo "dockerd ne demarre pas (voir /tmp/dockerd.log)"; exit 1
  fi
}

demarrer() {
  docker_pret
  # Copie de supabase/ adaptee au local (le depot n'est jamais modifie).
  python3 "$DEPOT/tool/e2e/preparer_config.py" "$DEPOT" "$TRAVAIL" "$APP"
  (cd "$TRAVAIL" && { $SUPA status >/dev/null 2>&1 || $SUPA start; })
  (cd "$TRAVAIL" && $SUPA status -o env) > "$TRAVAIL/statut.env"
  # shellcheck disable=SC1091
  . "$TRAVAIL/statut.env"
  # Passerelle du reseau de la pile : joignable du navigateur (hote) ET des
  # fonctions Edge (conteneur). LiveKit tourne sur le reseau de l'hote.
  PASSERELLE=$(docker network inspect supabase_network_rewayah-e2e -f '{{(index .IPAM.Config 0).Gateway}}')
  cat > "$TRAVAIL/livekit.yaml" <<YAML
port: 7880
rtc:
  tcp_port: 7881
  port_range_start: 50000
  port_range_end: 50100
  use_external_ip: false
  node_ip: ${PASSERELLE}
keys:
  devkey: secret_e2e_local_livekit_0123456789abcdef
webhook:
  api_key: devkey
  urls:
    - http://127.0.0.1:54321/functions/v1/livekit-webhook
YAML
  docker rm -f e2e-livekit >/dev/null 2>&1 || true
  docker run -d --name e2e-livekit --network host \
    -v "$TRAVAIL/livekit.yaml:/livekit.yaml:ro" \
    livekit/livekit-server:latest --config /livekit.yaml --bind 0.0.0.0 >/dev/null
  cat > "$TRAVAIL/fonctions.env" <<ENV
LIVEKIT_CLOUD_API_KEY=devkey
LIVEKIT_CLOUD_API_SECRET=secret_e2e_local_livekit_0123456789abcdef
LIVEKIT_CLOUD_WS_URL=ws://${PASSERELLE}:7880
LIVEKIT_SELFHOST_WS_URL=ws://${PASSERELLE}:7880
COURRIEL_TRANSPORT=journal
DENO_TLS_CA_STORE=mozilla,system
STUDENT_EMAIL_DOMAIN=eleves.example.com
APP_ORIGINES=${APP}
RECHERCHE_CURSOR_SECRET=e2e_local_curseur_0123456789abcdef
LIBRARY_UPLOAD_CONFIRMATION_HMAC_KEY=e2e_local_hmac_0123456789abcdef
ENV
  # Relais HTTPS : l'application exige une SUPABASE_URL en https.
  if [ ! -f "$TRAVAIL/cert.pem" ]; then
    openssl req -x509 -newkey rsa:2048 -nodes -days 30 -subj "/CN=127.0.0.1" \
      -addext "subjectAltName=IP:127.0.0.1" \
      -keyout "$TRAVAIL/cle.pem" -out "$TRAVAIL/cert.pem" 2>/dev/null
  fi
  pkill -f "tool/e2e/relais_https.mjs" 2>/dev/null || true
  (nohup node "$DEPOT/tool/e2e/relais_https.mjs" "$TRAVAIL/cert.pem" "$TRAVAIL/cle.pem" 54331 \
     > "$TRAVAIL/relais.log" 2>&1 < /dev/null &)
  pkill -f "supabase@2.122.0 functions serve" 2>/dev/null || true
  (cd "$TRAVAIL" && nohup $SUPA functions serve --env-file "$TRAVAIL/fonctions.env" \
     > "$TRAVAIL/fonctions.log" 2>&1 < /dev/null &)
  sleep 12
  # Le conteneur des fonctions telecharge ses modules (jsr.io, npm) a travers
  # le proxy de l'environnement : il doit faire confiance a son certificat.
  if [ -f /root/.ccr/ca-bundle.crt ]; then
    docker exec supabase_edge_runtime_rewayah-e2e sh -c \
      "cat $TRAVAIL/supabase/functions/_ca/ca.crt >> /etc/ssl/certs/ca-certificates.crt"
  fi
  echo "Pile prete : API $API_URL ; Mailpit $MAILPIT_URL ; LiveKit ws://${PASSERELLE}:7880 ; app $APP"
}

construire() {
  # shellcheck disable=SC1091
  . "$TRAVAIL/statut.env"
  cd "$DEPOT"
  # URL : le relais https (Env refuse http). Cle : la cle publiable locale
  # (la cle anon JWT locale porte iss=supabase-demo, refusee par Env).
  flutter pub get >/dev/null
  dart run slang >/dev/null
  flutter build web --release \
    --dart-define=SUPABASE_URL="https://127.0.0.1:54331" \
    --dart-define=SUPABASE_ANON_KEY="$PUBLISHABLE_KEY" \
    --dart-define=AUTH_PAR_MOT_DE_PASSE=true \
    --dart-define=ENVIRONNEMENT=developpement \
    --output "$TRAVAIL/web"
}

servir() {
  pkill -f "tool/e2e/serveur.mjs" 2>/dev/null || true
  (nohup node "$DEPOT/tool/e2e/serveur.mjs" "$TRAVAIL/web" "$PORT_APP" > "$TRAVAIL/serveur.log" 2>&1 < /dev/null &)
  sleep 1
  echo "Application servie sur $APP"
}

arreter() {
  pkill -f "supabase@2.122.0 functions serve" 2>/dev/null || true
  pkill -f "tool/e2e/serveur.mjs" 2>/dev/null || true
  pkill -f "tool/e2e/relais_https.mjs" 2>/dev/null || true
  docker rm -f e2e-livekit >/dev/null 2>&1 || true
  (cd "$TRAVAIL" && $SUPA stop --no-backup) || true
}

case "${1:-tout}" in
  demarrer) demarrer ;;
  construire) construire ;;
  servir) servir ;;
  arreter) arreter ;;
  tout) demarrer; construire; servir ;;
  *) echo "usage : $0 [demarrer|construire|servir|arreter]"; exit 2 ;;
esac
