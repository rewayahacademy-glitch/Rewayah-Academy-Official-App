# LOT-PRIERE-2 : la prière sans formulaire (13/11/2026)

Retour du directeur sur PRIERE-1 en production : « Je ne vais jamais remplir ces formulaires moches et anciens. Si l'app ne peut pas calculer elle-même tout ça alors à toi de régler cela. » Arbitrage de l'architecte pédagogique : lot « zéro saisie ». Décision : `docs/current/pedagogie/PRIERE.md` § 3 ter. Branche : `claude/priere-serveur` (restée sur la tête de `main` après la fusion de #452, par avance rapide, sans réécriture d'historique) ; migration `20261124500000_priere_zero_saisie.sql` (PRIERE-1, `20261123930000`, n'est pas modifiée).

## Réutilisé

`priere_ma_position` s'écrit dans `prayer_settings` et déclenche le recalcul de PRIERE-1 (déclencheur sur `prayer_settings`) ; `private.priere_reglages` garde sa forme (CREATE OR REPLACE) et tout PRIERE-1 en profite sans changement ; `priere_lieu_definir`, `priere_lieu_retirer`, `priere_horaires_jour`, les lectures de créneaux, la vue et le contrat de la salle sont inchangés. Composants du système de design : `ActionPrincipale`, `SettingRow`, `CarteLignes`, `MenuFiltre`, `ControleSegmente`, `LienFleche`, `AppBottomSheet`, `EmptyState`, `Skeleton`. Le motif `export ... if (dart.library.js_interop)` de `lib/core/agent/recharger_adresse.dart`.

## Créé

- **Migration** : `priere.methode_selon_pays` (réglage, validé) ; `prayer_settings.lieu_source` ; `private.priere_methode_zone` (neuf fuseaux) et `private.priere_methode_origine` ; `private.priere_reglages` (surcharge > pays > académie) ; `priere_lieu_definir` marque le lieu « direction » ; `priere_ma_position(numeric, numeric, text)` ; `private.priere_lieu_auto(uuid, text, numeric, numeric, text)` ; `priere_reglages_lire` (méthode appliquée, origine, source) ; `priere_enseignants_vue()` ; `priere_corriger(...)`. 28 Ko, 560 lignes, un seul bloc, ni `BEGIN` ni `COMMIT`, aucun `DROP`/`DELETE`/`TRUNCATE` (les occurrences sont `deleted_at`).
- **Application** : `lib/core/priere/position_appareil*.dart` (lecture de la position et du fuseau de l'appareil par `dart:js_interop`) ; service (`partagerPosition`, `vueEnseignants`, `corriger`) ; bouton « Utiliser ma position » de « Mes heures de prière » ; liste à lire de la direction et feuille « Corriger » ; section « La prière » des Règles (phrases, interrupteurs, valeurs chiffrées repliées) ; textes fr et ar sous `priere.*`.
- **Preuves** : `supabase/tests/scenarios_priere_zero_saisie.sql` ; tests Flutter par le vrai routeur et par page ; captures 390 et 1440, clair et sombre, fr et ar, dans `docs/current/captures/E2E/priere-serveur/`.

## Choix pris seul, écarts

1. **Branche** : la branche `claude/priere-zero-saisie` n'a pas été poussée. Le garde-fou de la session n'autorise que `claude/priere-serveur` ; elle a repris la tête de `main` (avance rapide). La migration porte bien le numéro `20261124500000` demandé.
2. **L'automatique ne remplace pas la position de l'enseignant** : une position partagée par l'enseignant (plus précise qu'un centre-ville) l'emporte sur `private.priere_lieu_auto`. Seul un lieu `auto` plus ancien est remplacé.
3. **Lieu posé par la direction** : l'enseignant ne peut pas le remplacer d'un toucher (refus « lieu posé par la direction », dit en mots) ; la direction le retire, puis l'enseignant (ou la ville) repose.
4. **Fonction de correction séparée** (`priere_corriger`) : corriger le vendredi ou la méthode ne repasse pas par la pose du lieu, qui aurait marqué le lieu « direction » et bloqué l'enseignant et la ville.
5. **Pays déduit du fuseau, neuf fuseaux seulement** (PRIERE.md § 3 ter) ; l'Amérique du Nord et le Moon Sighting Committee ne sont pas déduits.
6. **Position arrondie à 2 décimales, ville à 3** (centre-ville, donnée publique).
7. **Hors web** : la lecture de la position n'est pas disponible (aucun paquet n'a été ajouté : `pubspec.yaml` est protégé) ; l'écran dit « Position non partagée » et la direction peut poser le lieu.
8. **`public.lieux` (lot horloge, `20261123943000_lieux.sql`)** : ce lot ne pose aucun déclencheur dessus (celui du lot horloge relaie déjà) et ne livre plus de fonction de déclencheur. À l'installation, si la table existe, `private.priere_rattraper_villes()` rattrape UNE fois les villes d'enseignants déjà enregistrées (jamais un foyer, jamais par-dessus un lieu de la direction ou de l'enseignant, erreur d'une ligne avalée avec avertissement) ; sans la table, rien.
8 bis. **Ordre avec le lot horloge** : prouvé sur Postgres nu dans les trois ordres (horloge avant avec deux villes d'enseignant déjà là : 2 lieux posés en `auto`, lieu de la direction intact ; horloge après : le déclencheur relaie ; horloge absente : rien). Plus de limite « villes non rattrapées ».
9. **Clés de textes devenues inutiles** (`priere.direction.feuille.apercu`, `apercuVide`, `vendrediOui`, `vendrediNon`, `methodeEcole`, `ecoleEcole`) : laissées en place, aucune suppression.

## Ce qui reste faux, limité ou non prouvé

- Aucun test sur staging ni en production. La lecture de la position a été exécutée dans un vrai Chromium (Playwright, position et fuseau simulés) : accord → latitude, longitude et `Africa/Conakry` lus ; refus → « position non partagée ». Pas sur un téléphone réel, ni dans l'application construite (`flutter build web`) : les tests Flutter remplacent la lecture.
- Le fuseau de l'appareil peut différer du fuseau réel de la personne (appareil mal réglé) : l'écran des « à vérifier » le signale déjà (fuseau et longitude), sans corriger.
- Un enseignant sur un appareil sans géolocalisation (ou hors web) ne peut rien partager : il dépend de la direction.
