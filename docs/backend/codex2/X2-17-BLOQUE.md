# X2-17 — PARTIEL, alimentation BLOQUÉE

## Source de vérité reçue

Le contrat v2 est `docs/current/CONTRAT-CPT-BR-18-19.md`, commit source
`7231d321c7bae2d8642b10f661df8b0c0cdd1b15`, intégré à cette branche. Il fixe
la référence USD, les sept coffres, `series_tresorerie()` et l'interdiction
d'inventer une rémunération par séance.

## Livré dans cette branche

- Migration additive: `tresorerie_mouvements` append-only, lecture RLS réservée
  aux comptes actifs admin/comptable, configuration du fuseau et USD, RPC
  `SECURITY INVOKER` retournant les sept coffres, six mois, trente jours,
  soldes et variations dans le format du port.
- Adaptateur Dart strict, sans agrégat côté client; scénario SQL couvrant les
  dimensions, le transfert inclus aux soldes/exclu des flux, le rôle comptable,
  le refus enseignant et les ACL anon/service role.
- Test Dart ciblé: 4/4 réussis; `dart format` et `git diff --check` propres.

## Bloqueur restant selon le contrat

Avant tout code, la source suivante a été signalée dans Codex2!A112:

- Aucune source serveur de rémunération d'enseignant par séance trouvée dans
  migrations/fonctions. Le « 4 USD/h » de `01_PRODUIT_ET_PARCOURS.md` est une
  référence de scénario, pas un taux codable.
- `wallet_entries` ne distingue pas les crédits effectivement confirmés par
  un webhook; aucune Edge Function ni RPC du dépôt ne l'alimente. Il n'y a
  donc pas de signal vérifiable pour déclencher les mouvements de paiement,
  prestation acquise et remboursement dans leur transaction source.

En conséquence, cette branche ne branche aucune alimentation automatique et
ne peut pas être déclarée complète. Il faut citer la fonction serveur de
rémunération et la source transactionnelle des événements confirmés avant de
compléter cette partie. Aucun taux ni événement n'a été supposé.

## Preuves et limites

- `flutter test --no-pub test/core/capacites/series_tresorerie_supabase_test.dart`:
  4 réussis.
- `dart analyze --fatal-infos` a dépassé 90 secondes sans terminer après son
  message d'initialisation; interrompu. Le test Dart a compilé et exécuté le
  fichier.
- Scénario SQL écrit mais non rejoué: `psql` n'est pas installé et aucun
  PostgreSQL local n'a été démarré. Aucun accès distant utilisé.
- Vérification de la définition SQL et de l'ACL dynamique par PostgreSQL
  restent à faire par le rejeu de Claude.
