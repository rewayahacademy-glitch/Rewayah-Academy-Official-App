#!/bin/bash
# Joue les parcours dans l'ordre des dependances de donnees et reporte chaque
# verdict dans docs/current/ETAT-OUVERTURE.md. Le parcours 6 attend la cloture
# de la seance (fin + 30 min) ; la 3e etape du parcours 8 se joue a part
# (node tool/e2e/parcours_8.mjs --apres) une fois la seance d'adultes close.
set -u
cd "$(dirname "$0")/../.."
for n in 2 3 4 5 1 8; do
  node "tool/e2e/parcours_$n.mjs" | grep -v "console :"
  node tool/e2e/etat.mjs "$n" >/dev/null
done
