#!/bin/bash
# PostToolUse (Bash) : signale tout de suite une zone interdite modifiée, quel que soit le moyen.
# Lit le cwd de l'appel dans le JSON reçu sur stdin (worktree compris), repli CLAUDE_PROJECT_DIR.
entree=$(cat 2>/dev/null)
dir=""
for py in python3 python; do
  command -v "$py" >/dev/null 2>&1 || continue
  dir=$(printf '%s' "$entree" | "$py" -c 'import json,sys
try:
    print(json.load(sys.stdin).get("cwd") or "")
except Exception:
    print("")' 2>/dev/null) && break
  dir=""
done
[ -n "$dir" ] && [ -d "$dir" ] || dir="${CLAUDE_PROJECT_DIR:-.}"
cd "$dir" 2>/dev/null || exit 0
top=$(git rev-parse --show-toplevel 2>/dev/null) || exit 0
cd "$top" || exit 0

zones=(.github vercel.json pubspec.yaml lib/features/parcours_offres  ':(glob).claude/settings*.json' .claude/hooks)

en_cours=""
for r in MERGE_HEAD CHERRY_PICK_HEAD REVERT_HEAD REBASE_HEAD; do
  git rev-parse -q --verify "$r" >/dev/null 2>&1 && en_cours="$r"
done
for f in SQUASH_MSG rebase-merge rebase-apply; do
  [ -e "$(git rev-parse --git-path "$f" 2>/dev/null)" ] && en_cours="${en_cours:-$f}"
done

if [ -n "$en_cours" ]; then
  # Fusion, cherry-pick, revert, rebase ou squash en cours : les fichiers amenés par
  # ChatGPT sont attendus. Seul un conflit dans la zone backend est signalé.
  conflits=$(git diff --name-only --diff-filter=U -- "${zones[@]}" 2>/dev/null)
  if [ -n "$conflits" ]; then
    echo "Garde-fou : conflit dans une zone interdite ($en_cours en cours). Ne pas le résoudre soi-même :" >&2
    echo "  en conflit sous supabase/ : git merge --abort (ou cherry-pick/rebase --abort) et renvoyer à ChatGPT." >&2
    echo "$conflits" | sed 's/^/  /' >&2
    exit 2
  fi
  exit 0
fi

modifs=$(git status --porcelain --untracked-files=all -- "${zones[@]}" 2>/dev/null)
[ -z "$modifs" ] && exit 0
suivis=$(printf '%s\n' "$modifs" | grep -v '^??' | cut -c4-)
nonsuivis=$(printf '%s\n' "$modifs" | grep '^??' | cut -c4-)
echo "Garde-fou : une zone interdite a été modifiée. Annuler avant toute autre action :" >&2
if [ -n "$suivis" ]; then
  echo "  fichiers suivis modifiés : git restore --staged --worktree -- <chemin>" >&2
  printf '%s\n' "$suivis" | sed 's/^/    /' >&2
fi
if [ -n "$nonsuivis" ]; then
  echo "  fichiers non suivis créés : les supprimer avec git clean -f -- <chemin> (rm y est refusé par le garde-fou)" >&2
  printf '%s\n' "$nonsuivis" | sed 's/^/    /' >&2
fi
exit 2
