# Consignes communes aux agents de lot - nuit du 16 au 17/10/2026

Écrit par l'orchestrateur de nuit. Chaque agent de lot lit ce fichier, puis sa fiche, et rien d'autre que ce que sa fiche nomme dans « Ce qu'il faut lire ».

## Personne ne te répondra cette nuit

- Tu ne poses aucune question et tu n'attends aucune réponse. Le directeur dort.
- Quand ta fiche dit « s'arrêter et demander » : tu t'arrêtes, tu ne commits rien de douteux, et tu écris le cas dans ton rapport (ce que tu as vu, la commande, la sortie, ce que tu proposes). L'orchestrateur décide au cycle suivant.
- Quand un choix est technique (nom, implémentation, ordre) : tu le fais toi-même, au plus simple, et tu le dis dans le rapport.

## Zones

- Le directeur a levé la zone réservée à Codex (fiche « Maintenant », 16/10) : un agent Claude écrit dans `supabase/migrations/`, `supabase/tests/` et les adaptateurs `*_supabase.dart` quand sa fiche les autorise. Les fiches qui disent « Codex » valent pour toi.
- Toujours interdits : `.github/`, `site-public/`, `vercel.json`, `pubspec.yaml`, `lib/core/theme/`, `lib/features/parcours_offres/`, `.claude/`, les écrans publics d'avant connexion, tout secret.
- Aucune connexion à un projet Supabase distant (ni STAGING `xldmmlrnxyabdtvxqbyy`, ni production `gggmtelinlpseweouyav`). Aucun outil `mcp__Supabase__*`. Les migrations se rejouent sur ton Postgres local seulement.
- Tu ne touches qu'aux fichiers autorisés par ta fiche. Si le critère exige un autre fichier, tu t'arrêtes et tu le dis.

## Ton poste de travail

- Ton worktree est donné dans ta consigne (`/home/user/lots/<ID>`), sur ta branche `lots/<ID>-<mot>`, partie de `origin/claude/backend-reprise`. Tu travailles et tu commits là, nulle part ailleurs. Tu ne pousses pas, tu n'ouvres pas de PR : l'orchestrateur s'en charge.
- Les fiches et documents d'audit sont dans `/home/user/Rewayah-Academy-Official-App/docs/audit-final/` (lecture seule pour toi).
- Postgres 17 : Docker tourne. Lance TON conteneur avec le nom et le port donnés dans ta consigne, jamais un autre :
  `docker run -d --name pg-<ID> -e POSTGRES_HOST_AUTH_METHOD=trust -p 127.0.0.1:<PORT>:5432 postgres:17`
  puis `until pg_isready -h 127.0.0.1 -p <PORT>; do sleep 1; done`. Remplace le port 55432 des fiches par le tien. Une base neuve par rejeu (`create database x`, ou `template`). `docker rm -f pg-<ID>` à la fin.
- Rejeu complet : `psql -h 127.0.0.1 -p <PORT> -U postgres -d <base> -v ON_ERROR_STOP=1 -q -f supabase/tests/stub_auth.sql`, puis chaque `supabase/migrations/*.sql` dans l'ordre du nom, puis les scénarios.
- Fichiers de travail : dans `/tmp/claude-0/-home-user-Rewayah-Academy-Official-App/37ff0dc5-64c8-5d90-a02d-24473d02f0f3/scratchpad/<ID>/` seulement, jamais à la racine du scratchpad ni dans `/tmp`.
- Scénario de refus : vérifier SQLSTATE 42501 exactement ; une erreur de clé étrangère ou de contrainte ne prouve pas un refus.
- Flutter : `/tmp/claude-0/-home-user-Rewayah-Academy-Official-App/37ff0dc5-64c8-5d90-a02d-24473d02f0f3/scratchpad/flutter/bin` à ajouter au `PATH` (seulement si ta fiche touche `lib/` ou `test/`).
- Jamais `sleep` pour attendre autre chose que ton propre Postgres.

## Écriture

- Français. Pas de tiret cadratin, pas de symbole de section, pas d'emoji, pas de formule creuse. Libellés d'interface en français et en arabe.
- Commit avec le message de ta fiche, terminé par :
  `Co-Authored-By: Claude <noreply@anthropic.com>`

## Ton rapport (30 lignes au plus, c'est ta réponse finale)

```
LOT : <ID>   BRANCHE : lots/<ID>-<mot>   SHA : <court>
CRITÈRE : atteint | non atteint | partiel (lequel des points)
PREUVES : une ligne par commande, avec son résultat chiffré
FICHIERS : git diff --stat origin/claude/backend-reprise
ARRÊT : (si la fiche t'a fait t'arrêter) quoi, pourquoi, ce que tu proposes
PIÈGES : erreurs payées, une ligne chacune (qui deviennent des lignes de « Pièges connus »)
```

Un « atteint » sans commande qui le prouve est refusé.
