# Lot créneaux : état au 30/10/2026

Reprise du lot par l'agent de construction n° 2 (consigne du pilote du 29/10 au soir). Rapport détaillé : `LOT-CRENEAUX-2026-10-29.md` ; décisions : `DECISION-CLASSES-HORAIRES-MIXITE-2026-10-29.md` ; fiche et arbitrages : `FICHE-CRENEAUX-2026-10-29.md`.

## Ce qui est faux, bloqué ou non prouvé, d'abord

- **Rien n'est appliqué ni prouvé en production ni sur staging.**
- Arabe des clés du lot (accord du pilote du 30/10) : ajouté pour `admin.groupes.formulaire.*` et `admin.groupes.reglagesClasse.*` du lot ; les tests `ar_domaines_test` et `elision_test` sont verts. La note de passation « pas d'arabe, cette partie de l'administration n'en a pas » était fausse.
- Durée par créneau à l'écran (décision relayée par le pilote le 30/10) : un menu « Durée » par créneau dans « Nouvelle classe » et dans « Modifier ce créneau » (« Durée de la classe » par défaut, sinon 30 à 120 minutes) ; la liste des créneaux dit la durée quand elle n'est pas celle de la classe ; la durée seule modifiée dit « Durée enregistrée ». Libellés fr et ar. Non essayé en production.
- Les scénarios SQL rejoués sur Postgres 16 local, chacun sur une copie neuve de la base : 129 verts, 7 rouges, **les mêmes 7 que sur `main`** (même message, même ligne) ; le seul écart est `scenarios_classe_plusieurs_creneaux.sql`, vert. Cinq des 7 rouges s'arrêtent sur « cannot ALTER TABLE ... pending trigger events » ; rejoués à part, avec les déclencheurs différés rendus immédiats (copie locale, non versionnée), `scenarios_classes_duree_affectation`, `scenarios_classes_duree_bout_en_bout`, `scenarios_cand_l1b_forme_compte`, `scenarios_fac_e_paie_par_eleve` et `scenarios_ses_cloture_auto` sont verts sur cette branche.

## Ce qui est fait

- Serveur, une migration : `supabase/migrations/20261030100000_classe_plusieurs_creneaux.sql` (renommée le 30/10 depuis `20261029170000`, dans la réserve du lot). Deux mots de suppression dans des corps de fonction (`DELETE` du retrait d'un créneau, `delete` du déclencheur d'ancrage) : aucun `DROP`, aucun `TRUNCATE`.
  - `sessions.motif_annulation`, `groupes.mixte`, **`groupe_creneaux.duree_minutes`** (15 à 240, vide = durée de la classe) ;
  - `private.annuler_seances_creneau`, `private.classe_creneau_garde`, `app_private.creneaux_de_classe` (chaque créneau avec sa durée), `app_private.duree_seance_de_classe` ;
  - `public.retirer_creneau_classe_admin`, `public.modifier_creneau_classe_admin` (**reçoit la nouvelle durée** ; la durée seule modifiée réaligne les séances à venir sans les annuler), `public.creer_classe_creneaux_admin` (genre, fuseau, **« duree » par créneau**, créneaux de la classe contrôlés entre eux), `public.regler_genre_classe_admin`, `public.ajouter_creneau_classe_admin` à quatre arguments (avec la durée ; celle à trois reste) ;
  - durée par créneau lue par : génération des séances (`materialiser_seances_groupe`, `seance_a_rejoindre`, `horloge_classe`), prédicat de l'enseignant (`verifier_affectation_enseignant_base` : charge, couverture par les disponibilités, chevauchements), contrôle des créneaux entre eux et contre les séances déjà générées (`verifier_horaire_contre_seances_planifiees`), propositions d'enseignants (`enseignants_pour_classe`, `enseignants_pour_public`), transfert d'un élève (`transferer_eleve`), réalignement (`seances_a_venir_a_realigner`) ; le contrôle de `groupe_creneaux` repasse quand seule la durée change ; l'ancre déplacée garde sa durée (`groupe_creneau_ancre`) ; empreintes F86 suivies ;
  - `classes_admin_page` dit « mixte » pour une classe mixte.
- Écrans : « Nouvelle classe » à trois créneaux par défaut ; menu de la classe « Créneaux et genre ». Deux libellés de ce lot reformulés le 30/10 (ils redisaient « hors ligne » et « connexion », test `etat_sans_donnees_test`).

## Ce qui reste

1. Ajouter `scenarios_classe_plusieurs_creneaux.sql` à `ci.yml` (zone du directeur).
2. PR, fusion, migration (pilote), puis la preuve du directeur (gestes dans `LOT-CRENEAUX-2026-10-29.md`).

## Fichiers touchés

- `supabase/migrations/20261030100000_classe_plusieurs_creneaux.sql` (nouveau), `supabase/tests/scenarios_classe_plusieurs_creneaux.sql` (nouveau), `supabase/tests/scenarios_af_liste_blanche_volatiles.sql`, `supabase/tests/scenarios_classes_plafond_par_enseignant.sql`.
- `lib/core/admin/creneaux_classe.dart`, `lib/core/admin/creneaux_classe_supabase.dart`, `lib/core/admin/classes_admin_supabase.dart`, `lib/core/admin/enseignants_classe.dart`, `lib/core/capacites/port_creation_classe.dart`, `lib/core/capacites/creation_classe_supabase.dart` (nouveau), `lib/core/capacites/port_enseignants_classe.dart` (`GenreClasse.mixte`).
- `lib/features/admin_groupes/groupes_page.dart`, `lib/features/admin_groupes/feuille_reglages_classe.dart` (nouveau), `lib/features/admin_groupes/genre_classe_libelles.dart`, `lib/features/admin_pilotage/pilotage_libelles.dart`, `lib/features/demo/classe_form_demo.dart`, `lib/features/demo/pilotage_demo.dart`.
- `assets/i18n/fr.i18n.json`, `lib/core/i18n/strings*.g.dart`, `tool/libelles_sources.json`.
- Tests : `test/features/admin_groupes/creneau_classe_test.dart`, `test/features/classe_form_1_test.dart`, `test/features/form_l2_selecteur_personne_test.dart`, `test/features/support_form_l2.dart`.
- Docs : `docs/current/FICHE-CRENEAUX-2026-10-29.md`, `DECISION-CLASSES-HORAIRES-MIXITE-2026-10-29.md`, `LOT-CRENEAUX-2026-10-29.md`, `CRENEAUX-ETAT.md` ; et, sans lien avec les créneaux, `LISTE-ATTENTE-2026-10-29.md`, `FICHE-FRAICHEUR-NOTIFICATIONS-2026-10-27.md` (lignes 10 à 15 prouvées le 29/10).
