#!/bin/bash
# SessionStart : prépare Flutter pour que chaque agent puisse vérifier un lot.
set -u
if [ -d /opt/flutter/bin ] && [ -n "${CLAUDE_ENV_FILE:-}" ]; then
  echo 'export PATH="/opt/flutter/bin:$PATH"' >> "$CLAUDE_ENV_FILE"
  export PATH="/opt/flutter/bin:$PATH"
fi
if [ "${CLAUDE_CODE_REMOTE:-}" = "true" ] && command -v flutter >/dev/null 2>&1; then
  cd "${CLAUDE_PROJECT_DIR:-.}" && timeout 300 flutter pub get >/dev/null 2>&1 || true
fi
cat <<'TXT'
Rappel Rewayah Academy : un garde-fou refuse automatiquement les écritures dans supabase/, .github/, vercel.json, pubspec.yaml, site-public/, parcours_offres, services et adaptateurs *_supabase.dart, tout push vers main, tout push --force, et toute action d'écriture sur la production. Vérifier un lot : dart run slang ; dart run build_runner build --delete-conflicting-outputs ; dart analyze --fatal-infos ; flutter test ; dart run tool/verifier_jetons.dart ; dart run tool/verifier_revue.dart.
TXT
exit 0
