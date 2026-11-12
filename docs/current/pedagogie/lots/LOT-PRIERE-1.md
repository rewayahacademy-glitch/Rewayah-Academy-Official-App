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

**Base de données** (`supabase/migrations/20261123930000_priere_serveur.sql`, une seule migration, aucun `DELETE`, `DROP` ni `TRUNCATE` : comptés, zéro ; seule la colonne `deleted_at` des tables existantes est nommée) :

- le calcul des cinq heures en SQL pur, `private.priere_calculer` (immuable), port ligne à ligne de `adhan` 2.0.0+1 : mêmes arrondis, même repli de haute latitude, douze méthodes ;
- le contrat avec la salle : `seance_pause_prevue_stock`, la vue `seance_pause_prevue`, la lecture `pause_prevue_seance(uuid)` ;
- le placement (`private.priere_placer`) et le remplissage : déclencheurs sur `sessions`, `remplacements_seance`, `prayer_settings`, `app_config`, et recalcul de nuit (`pg_cron` si l'extension existe, comme `ses_cloture_auto` ; sinon `priere_recalculer_maintenant()` par la direction, double authentification) ;
- les réglages de l'école (`app_config`, huit clés `priere.*`, validées par un déclencheur) ;
- `prayer_settings` : colonnes `methode_surcharge`, `ecole_asr_surcharge`, `assiste_vendredi`, `vendredi_debut`, `vendredi_fin`, `actif`, `defini_par`, `defini_le` ; lecture limitée à l'enseignant et à la direction ; écriture directe fermée ;
- les fonctions : `priere_lieu_definir`, `priere_lieu_retirer`, `priere_ajuster`, `priere_reglages_lire`, `priere_horaires_jour`, `priere_enseignants_liste`, `priere_lecture_creneau`, `priere_creneaux_sans_priere`, `priere_lecture_classe`, `priere_incoherences_enseignants`, `priere_recalculer_maintenant`.

**Preuve** : `tool/priere/generer_reference.dart` (référence `adhan`, 1 368 combinaisons : 8 lieux, 24 dates, 3 méthodes, 2 écoles d'Asr, plus les douze méthodes sur 3 lieux et 4 dates), `supabase/tests/fixtures/priere_reference_adhan.csv`, `supabase/tests/scenarios_priere_serveur.sql`.

**Application** (`lib/core/priere/pause_prevue.dart`, `lieu_priere.dart`, `service_priere.dart` ; `lib/features/priere_serveur/`) : « Mes heures de prière » (Compte de l'enseignant), « Lieux de prière » (page de la direction, ouverte depuis la section « La prière » de Configuration > Règles), le bloc « Prières et créneau » (fiche d'une classe), la section « La prière » de Configuration > Règles ; la journée de l'enseignant et l'accueil de l'élève lisent `pause_prevue_seance` ; textes fr et ar sous `priere.*`.

## Choix pris seul, écarts

1. **Marge de fin = au moins la durée de la pause.** L'arbitrage P6 dit 15 minutes, P5 permet 20 minutes (Ramadan, Maghrib) : une pause de 20 minutes placée à 15 minutes de la fin dépasserait l'heure de fin, contre P7. La zone « prière après le cours » commence donc à `max(marge de fin, durée de la pause)`.
2. **Le contrat est une vue, pas une table.** La règle « zéro `DELETE` » interdit de retirer une ligne quand la prière disparaît ; la ligne est marquée retirée dans `seance_pause_prevue_stock` et la vue la cache. Pour la salle, la lecture est la même.
3. **Pas de clé étrangère** de `seance_pause_prevue_stock.session_id` vers `sessions` : des opérations et des tests retirent des séances pour de bon, et `ON DELETE CASCADE` contiendrait le mot interdit. La vue ne montre que les séances qui existent.
4. **Fenêtre d'une prière** (choix entre deux prières, P4) : de son entrée à l'entrée de la prière suivante de la liste ; le Maghrib (environ 1 h 10) passe avant l'Isha.
5. **Le lieu retiré n'est pas effacé** (même raison) : la position est écrasée (0, 0, sans nom) et la ligne passe à `actif = false`.
6. **Colonnes héritées de `prayer_settings`** (`method`, `madhab`, `pause_minutes`, `alert_lead_minutes`) : conservées, plus lues. La durée vient de l'école ; la méthode et l'école d'Asr, de l'école ou de la surcharge.
7. **La position n'est plus lisible par la famille** : la politique `prayer_settings_parties_read` (ADR-017) ouvrait le lieu de l'enseignant aux élèves et aux tuteurs ; elle est restreinte à l'enseignant et à la direction. Quatre tests existants qui encodaient l'ancienne règle sont alignés (`scenarios_etape4`, `scenarios_sec_garde_5_invoker_droits`, `scenarios_af_liste_blanche_volatiles`, et `scenarios_fuseaux_connus` rendu vert en validant le fuseau par `fuseau_connu`).
8. **Contrôle du pays** (incohérences) : boîtes englobantes de 20 pays ; un pays hors table ne produit aucun signal. Le pays du compte est comparé au lieu de prière **et** à son propre fuseau (pour les pays de 30 degrés de longitude au plus, écart de plus d'une heure et demie), pour signaler le cas de la production (Guinée, Europe/Paris) avant même qu'un lieu soit posé. C'est un contrôle de vraisemblance, pas une vérité.
9. **Aperçu et « Pause de prière »** : l'écran de l'élève dit « Pause de prière / À HH:MM » (deux lignes) ; la journée de l'enseignant dit « Pause de prière » ; le nom de la prière reste dans « Mes heures de prière ».
10. **Heures lues dans le fuseau de la personne** par `heureChezMoi` (comme les autres lecteurs), pas dans le fuseau du lieu.
11. **Pas de nouvel onglet dans Configuration** : un onglet « Prière » décalait la barre de sections et cassait `admin_ad11` (AD-9, politique KYC, 400 % de texte, 1280x1024). La page « Lieux de prière » est donc une page à part (`/admin/configuration/priere`), ouverte par une ligne de la section « La prière » de Règles ; la barre y montre « Règles » comme actif.

## Ce qui reste faux, limité ou non prouvé

- **Aucun test sur staging ni en production.** La migration n'a jamais été appliquée à distance ; la salle n'a pas encore lu le contrat.
- **`pg_cron`** : absent des Postgres de test, donc la planification de nuit n'a pas tourné ; seule la fonction (`priere_recalculer_horizon`) est testée.
- **Le Ramadan** n'est qu'un booléen posé à la main.
- **Une prière dont le temps se termine pendant la séance** n'est pas traitée (seule l'entrée l'est).
- **Hautes latitudes** : sans lever ni coucher du soleil, aucune pause, une ligne au journal ; pas de calcul inventé.
- **Le module local** `lib/core/priere/horaires_priere.dart` et `reglages_priere.dart` reste dans le dépôt (autre lot de nettoyage) ; plus aucun écran ne l'appelle.
- **Langues autres que fr et ar** : non écrites (le dépôt n'en a que deux).
