#!/usr/bin/env bash
# REGISTRE (pilote et garde-cap, 11/11/2026, ordre du directeur : « ne plus
# perdre un seul lot »). Relevé des branches distantes qui ne sont pas
# ancêtres de origin/main : date du dernier commit, branche, PR à sa tête,
# fusionnée ou non, nombre de commits hors de main.
#
# Git seul, lecture seule : `git fetch` met à jour les références locales du
# clone (option --sans-fetch pour s'en passer), `git ls-remote` lit les PR.
# Aucune écriture distante, aucun appel à l'API GitHub.
#
# Usage : tool/registre_lots.sh [--sans-fetch] [--tsv]
#   --tsv : une ligne par branche, colonnes séparées par des tabulations,
#           sans résumé (pour un tableur ou un tri).
#
# Statuts :
#   livrée          une PR à la tête de la branche est fusionnée dans main
#                   (« (#N) » d'un squash ou « Merge pull request #N »)
#   PR non fusionnée  une PR à sa tête, absente du journal de main
#   sans PR         des commits hors de main, aucune PR à sa tête
# Lancé par le pilote avant chaque série de fusions ; contrôlé par le
# garde-cap (docs/current/REGISTRE-LOTS.md, « Règle de méthode »).

set -euo pipefail

fetch=1
tsv=0
for a in "$@"; do
  case "$a" in
    --sans-fetch) fetch=0 ;;
    --tsv) tsv=1 ;;
    *) echo "option inconnue : $a" >&2; exit 2 ;;
  esac
done

if [ "$fetch" = 1 ]; then
  git fetch --quiet --prune origin '+refs/heads/*:refs/remotes/origin/*'
fi

tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT

# PR à la tête de chaque commit : « sha numéro ».
git ls-remote origin 'refs/pull/*/head' |
  sed -E 's#^([0-9a-f]+)\s+refs/pull/([0-9]+)/head$#\1 \2#' |
  sort > "$tmp/pr_tetes"

# PR fusionnées d'après le journal de main.
git log origin/main --format='%s' |
  grep -oE '\(#[0-9]+\)|Merge pull request #[0-9]+' |
  grep -oE '[0-9]+' | sort -u > "$tmp/pr_fusionnees"

livrees=0; ouvertes=0; sans=0
lignes="$tmp/lignes"
: > "$lignes"

while IFS= read -r ref; do
  branche=${ref#origin/}
  [ "$branche" = "HEAD" ] && continue
  [ "$branche" = "main" ] && continue
  if git merge-base --is-ancestor "$ref" origin/main 2>/dev/null; then
    continue
  fi
  sha=$(git rev-parse "$ref")
  date=$(git log -1 --format='%cs' "$ref")
  hors=$(git rev-list --count "origin/main..$ref")
  prs=$(awk -v s="$sha" '$1 == s { print $2 }' "$tmp/pr_tetes" | sort -n | paste -sd, -)
  statut="sans PR"
  if [ -n "$prs" ]; then
    statut="PR non fusionnée"
    for n in ${prs//,/ }; do
      if grep -qx "$n" "$tmp/pr_fusionnees"; then statut="livrée"; fi
    done
  fi
  case "$statut" in
    livrée) livrees=$((livrees + 1)) ;;
    "PR non fusionnée") ouvertes=$((ouvertes + 1)) ;;
    *) sans=$((sans + 1)) ;;
  esac
  printf '%s\t%s\t%s\t%s\t%s\n' "$date" "$branche" "${prs:--}" "$statut" "$hors" >> "$lignes"
done < <(git for-each-ref --format='%(refname:short)' refs/remotes/origin)

if [ "$tsv" = 1 ]; then
  sort -r "$lignes"
  exit 0
fi

echo "Relevé du $(date -u +%Y-%m-%dT%H:%MZ), main = $(git rev-parse --short origin/main)"
echo "Branches hors de main : $((livrees + ouvertes + sans))"
echo "  livrées (PR fusionnée)      : $livrees"
echo "  PR non fusionnée            : $ouvertes"
echo "  commits hors de main sans PR : $sans"
echo
printf 'date\tbranche\tPR\tstatut\tcommits hors main\n'
sort -r "$lignes"
