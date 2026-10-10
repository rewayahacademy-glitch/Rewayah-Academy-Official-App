#!/bin/bash
# PostToolUse (Bash) : signale tout de suite une zone interdite modifiée, quel que soit le moyen.
cd "${CLAUDE_PROJECT_DIR:-.}" 2>/dev/null || exit 0
git rev-parse -q --verify MERGE_HEAD >/dev/null 2>&1 && exit 0
modifs=$(git status --porcelain -- supabase .github vercel.json pubspec.yaml site-public lib/features/parcours_offres 2>/dev/null)
if [ -n "$modifs" ]; then
  echo "Garde-fou : une zone interdite a été modifiée. Annuler ces changements (git checkout/restore) avant toute autre action :" >&2
  echo "$modifs" >&2
  exit 2
fi
exit 0
