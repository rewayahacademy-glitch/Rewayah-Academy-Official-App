# X2-18 — IMPLÉMENTÉ, VÉRIFICATION SQL BLOQUÉE

## Source de vérité

Contrat v2: `docs/current/CONTRAT-CPT-BR-18-19.md`, commit source
`7231d321c7bae2d8642b10f661df8b0c0cdd1b15`, déjà inclus par le merge de X2-17.

## Livré dans cette branche

- `exports_comptables`: journal append-only, RLS admin (toutes lignes) et
  comptable (ses lignes), avec identifiant, période ou sélection, nombre,
  texte CSV, auteur et clé d'idempotence.
- RPC `SECURITY INVOKER` pour le rapport mensuel et la sélection de 1 à 500
  payouts; période Europe/Paris configurable, 5 000 lignes maximum, erreurs
  `22023`/`54000`, idempotence utilisateur, CSV UTF-8 BOM séparé par `;`,
  dates locales, montants décimaux, neutralisation des cellules-formules.
- L'export sélectionné ne lit et ne sérialise que `payout_methods.kind` et
  `profile_id`; `details` est exclu.
- Adaptateur Dart renvoyant strictement `reference` et `lignes`, sans fabriquer
  ou télécharger de fichier. Le téléchargement reste hors du port actuel.
- Scénario SQL couvrant rapport/sélection, idempotence, format, neutralisation,
  détails privés, sélection invalide, ACL et plafond.
- Test Dart ciblé: 3/3 réussis; `dart format` et `git diff --check` propres.

## Limites / arbitrage de sécurité

- PostgreSQL local n'est pas disponible: `psql` absent et Docker Desktop
  injoignable (`dockerDesktopLinuxEngine` absent). Le scénario SQL n'a pas été
  rejoué. Aucun accès base distante n'a été tenté.
- Pour que les RPC invoker puissent insérer dans le journal, l'adaptateur SQL
  doit donner `INSERT` à `authenticated` et le permettre par RLS aux comptes
  actifs admin/comptable. Cela autorise aussi ces comptes à insérer directement
  des lignes arbitraires dans la table, en dehors des RPC. Le contrat ne donne
  pas de mécanisme invoker pour rendre l'insertion exclusive aux RPC. À arbitrer
  avant acceptation du journal en production (p. ex. helper privé F86 approuvé).
- Aucun scénario de permission réel ou d'absence d'accès Data API n'est prouvé
  dans cette session.

## Mise a jour du 2026-10-12

- Merge sans force de `codex2/x2-17` a jour, incluant `c9c5b2338e36eef512ac5a1786a3b23aa48409b4`.
- X2-18 demeure PARTIEL: le scenario SQL n'est pas rejoue et l'insertion directe arbitraire dans `exports_comptables` reste possible pour les comptes finance. L'interdire tout en gardant les RPC `SECURITY INVOKER` capables d'inserer exige un mecanisme approuve; F86 n'est pas disponible ici. Aucun changement d'ACL non prouve n'est applique.

## Revue Claude A120 — correctif appliqué

- Le journal n'accorde plus INSERT à `authenticated`; l'ancienne policy d'insertion est supprimée. Le scénario tente un INSERT comptable forgé et exige `42501`.
- Les RPC invoker délèguent la génération CSV, le compte de lignes et l'insertion à `codex2_private.creer_export_comptable`, fonction SECURITY DEFINER avec `search_path = ''`, garde de compte actif/rôle finance, et ACL fermée à anon/service_role. Le schéma privé n'est pas ajouté aux schémas PostgREST.
- Le scénario relève `md5(pg_get_functiondef(...))` et vérifie `prosecdef`, `search_path` et les privilèges. Le SHA du md5 exige le rejeu PostgreSQL.
- Correction du générateur de 5001 lignes (`g` remplacé par `n`) et merge de la correction X2-17 A119.
- Non rejoué localement : `psql`/PostgreSQL absent; attente d'un nouveau contrôle Claude. Le helper SECURITY DEFINER reste à comparer au protocole F86 complet, non présent dans ce checkout.
