#!/usr/bin/env bash
# Appelle un outil de Praxis (praxis-mcp) pour la routine horaire : voir
# docs/current/BUREAU-EQUIPE/PRAXIS/ROUTINE-PRAXIS.md.
#
# Usage : tool/praxis_appel.sh <outil> '<arguments JSON>'
#   ex. : tool/praxis_appel.sh etat '{}'
#         tool/praxis_appel.sh boite '{"filtre":"attend","limite":20}'
#
# La cle « routine » n'est JAMAIS dans ce fichier ni dans l'environnement du processus : l'environnement
# dedie `praxis-routine` la garde comme secret reseau et son proxy remplace la cle factice ci-dessous
# (forme prx_ + 64 chiffres hexadecimaux, exigee par le serveur avant toute lecture en base) par la vraie.
# Si la substitution ne se fait pas, le serveur repond cle_refusee : la routine s'arrete.
#
# L'adresse du serveur vient de PRAXIS_URL (non secrete) ; a defaut, celle du projet de production.
set -euo pipefail

outil="${1:?outil manquant}"
arguments="${2:-{\}}"
url="${PRAXIS_URL:-https://gggmtelinlpseweouyav.supabase.co/functions/v1/praxis-mcp}"
cle_factice="prx_0000000000000000000000000000000000000000000000000000000000000000"

corps=$(python3 -I - "$outil" "$arguments" <<'PY'
import json, sys
outil, arguments = sys.argv[1], sys.argv[2]
print(json.dumps({"jsonrpc": "2.0", "id": 1, "method": "tools/call",
                  "params": {"name": outil, "arguments": json.loads(arguments)}}))
PY
)

exec curl --silent --show-error --max-time 25 \
  --request POST "$url" \
  --header "Authorization: Bearer ${cle_factice}" \
  --header "Content-Type: application/json" \
  --data "$corps"
