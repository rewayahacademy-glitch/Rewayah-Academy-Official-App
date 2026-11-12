# LOT-PRIERE-1 : la prière à l'heure (fiche de lot)

Branche `claude/priere-serveur`, migration réservée `20261123930000_priere_serveur.sql`. Autorité : l'architecte pédagogique (session `session_0163KjryPfZgaNMo9E82VTQx`). Décision : `PRIERE.md`. **Statut : en construction (12/11/2026). Cette fiche est mise à jour à la fin du lot.**

## Réutilisé

- `prayer_settings` (migration 0005) : lieu, fuseau, ajustements (−30 à +30, garde `guard_prayer_adjustments`). Ses colonnes `method`, `madhab`, `pause_minutes`, `alert_lead_minutes` restent mais ne sont plus lues (la méthode et l'école viennent de l'école, la durée de la pause aussi).
- `app_config` et son modèle de validation par déclencheur (comme `reglages_remplacement_valider`) ; `public.log_sensitive_access` pour le journal de la direction.
- `sessions` (`started_at`, `ended_at`, `groupe_id`), `session_participants`, `groupe_membres`, `remplacements_seance` et `private.c29_enseignant_effectif_session` (l'enseignant qui enseigne réellement, remplaçant compris), `groupes` (`weekday`, `hour_local`, `timezone_iana`), `groupe_creneaux`, `teacher_profiles` (`country`, `timezone_iana`).
- Le paquet Dart `adhan` 2.0.0+1, déjà dans `pubspec.yaml`, comme **référence de la preuve** du calcul SQL (pas comme calcul de production).
- Les textes `priere.*` existants (noms des cinq prières, annonce) ; le composant de journée de l'enseignant et l'accueil de l'élève comme lecteurs.
- Le schéma de planification `pg_cron` posé seulement si l'extension existe (comme `ses_cloture_auto`, `fac_relances`).

## Créé

(à compléter à la fin du lot)

## Choix pris seul, écarts

(à compléter à la fin du lot)
