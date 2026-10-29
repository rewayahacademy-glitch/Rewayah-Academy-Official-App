# Lot créneaux : état à la passation, 29/10/2026, 22 h UTC

Passation demandée par le pilote (décision du directeur du 29/10 : un autre agent reprend les créneaux). Rapport détaillé : `LOT-CRENEAUX-2026-10-29.md` ; décisions : `DECISION-CLASSES-HORAIRES-MIXITE-2026-10-29.md` ; fiche et arbitrages : `FICHE-CRENEAUX-2026-10-29.md`.

## Ce qui est prouvé, et ce qui ne l'est pas

- Rien n'est appliqué ni prouvé en production ni sur staging.
- Scénarios SQL rejoués sur Postgres 16 local, chacun sur une base neuve : mêmes résultats que `main` (7 rouges déjà rouges sur `main`), plus `scenarios_classe_plusieurs_creneaux.sql` vert.
- Tests Flutter ciblés verts (`creneau_classe_test`, `classe_form_1_test`, `form_l2_selecteur_personne_test`) ; `dart analyze --fatal-infos` propre, `verifier_jetons` propre, `verifier_revue` à 1074 (le socle de `main`). **La suite Flutter complète tournait encore au moment de pousser** : son résultat n'est pas connu.

## Ce qui est fait

- Serveur, une migration : `supabase/migrations/20261029170000_classe_plusieurs_creneaux.sql`. **Son numéro est hors de la réserve des créneaux (2026103010xxxx, consigne du pilote du 29/10) : à renommer avant toute application.** Elle contient un `DELETE` dans le corps d'une fonction.
  - `sessions.motif_annulation`, `groupes.mixte` ;
  - `private.annuler_seances_creneau`, `private.classe_creneau_garde` ;
  - `public.retirer_creneau_classe_admin`, `public.modifier_creneau_classe_admin`, `public.creer_classe_creneaux_admin` (genre et fuseau enregistrés enfin), `public.regler_genre_classe_admin` ;
  - `classes_admin_page` dit « mixte » pour une classe mixte (remplacement vérifié dans son corps, empreinte F86 suivie).
- Écrans : « Nouvelle classe » à trois créneaux par défaut (« Autres créneaux de la semaine ») ; menu de la classe « Créneaux et genre » (liste, modifier, retirer, ajouter, genre hommes, femmes ou mixte, motif exigé).
- Libellés français (`admin.groupes.formulaire.*`, `admin.groupes.reglagesClasse.*`) et leurs sources ; pas d'arabe (cette partie de l'administration n'en a pas).

## Ce qui reste

1. Renommer la migration dans la réserve 2026103010xxxx, puis l'appliquer (staging, puis production).
2. La durée par créneau (le directeur : « jour + heure + durée ») : non faite ; elle touche le contrôle des chevauchements de l'enseignant dans plusieurs fonctions du serveur.
3. Résultat de la suite Flutter complète ; corriger ce qui serait rouge.
4. Ajouter `scenarios_classe_plusieurs_creneaux.sql` à `ci.yml` (zone du directeur).
5. Fusion de `main`, puis la preuve du directeur (gestes dans `LOT-CRENEAUX-2026-10-29.md`).

## Fichiers touchés

- `supabase/migrations/20261029170000_classe_plusieurs_creneaux.sql` (nouveau), `supabase/tests/scenarios_classe_plusieurs_creneaux.sql` (nouveau), `supabase/tests/scenarios_af_liste_blanche_volatiles.sql`, `supabase/tests/scenarios_classes_plafond_par_enseignant.sql`.
- `lib/core/admin/creneaux_classe.dart`, `lib/core/admin/creneaux_classe_supabase.dart`, `lib/core/admin/classes_admin_supabase.dart`, `lib/core/admin/enseignants_classe.dart`, `lib/core/capacites/port_creation_classe.dart`, `lib/core/capacites/creation_classe_supabase.dart` (nouveau), `lib/core/capacites/port_enseignants_classe.dart` (`GenreClasse.mixte`).
- `lib/features/admin_groupes/groupes_page.dart`, `lib/features/admin_groupes/feuille_reglages_classe.dart` (nouveau), `lib/features/admin_groupes/genre_classe_libelles.dart`, `lib/features/admin_pilotage/pilotage_libelles.dart`, `lib/features/demo/classe_form_demo.dart`, `lib/features/demo/pilotage_demo.dart`.
- `assets/i18n/fr.i18n.json`, `lib/core/i18n/strings*.g.dart`, `tool/libelles_sources.json`.
- Tests : `test/features/admin_groupes/creneau_classe_test.dart`, `test/features/classe_form_1_test.dart`, `test/features/form_l2_selecteur_personne_test.dart`, `test/features/support_form_l2.dart`.
- Docs : `docs/current/FICHE-CRENEAUX-2026-10-29.md`, `DECISION-CLASSES-HORAIRES-MIXITE-2026-10-29.md`, `LOT-CRENEAUX-2026-10-29.md`, `CRENEAUX-ETAT.md` ; et, sans lien avec les créneaux, `LISTE-ATTENTE-2026-10-29.md`, `FICHE-FRAICHEUR-NOTIFICATIONS-2026-10-27.md` (lignes 10 à 15 prouvées le 29/10).
