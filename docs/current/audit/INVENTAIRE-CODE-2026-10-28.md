# Inventaire du code, 28/10/2026

**Ce que je n'ai pas pu vérifier :** rien n'a été testé dans un navigateur ni en production. Les citations dans les documents sont des recherches de texte sur les noms de fichiers : un compte peut être trop haut quand un mot est courant (par exemple `admin`) ou trop bas quand le document cite une classe et non le fichier. La source map attribue 6,75 Mo sur 15,1 Mo de main.dart.js ; le reste n'est rattaché à aucune source. Je n'ai pas lu les trois documents que CLAUDE.md impose aussi (`08`, `BOUCLE-1_PLAN`, `DESIGN-GOV`) : ils sont hors de ta liste. Je n'ai pas non plus fait la reprise du suivi « surface » prévue au démarrage, parce que ta demande l'a remplacée.

Base : `origin/claude/admiring-brown-r6ai72-audit` @ `45778cc`, HEAD détachée. Rien n'a été supprimé, modifié, commité ni poussé : `git status` est propre. Le build s'est fait dans une copie (`git archive` vers `/tmp/src`).

## Totaux par colonne (lignes)

Méthode de comptage : pour chaque dossier, seules ses lignes atteignables ; les 37 fichiers non atteignables sont comptés à part. Ainsi, aucune ligne n'est comptée deux fois. `app.dart` et `main.dart` sont hors du compte.

| Colonne | Lignes |
| :-- | --: |
| GARDER-BRANCHÉ | 395 012 |
| GARDER-EN-ATTENTE | 40 669 |
| FUSIONNER | 2 205 |
| SUPPRIMER | 1 326 |
| **Total** | **439 212** |

## Les suppressions les plus sûres (j'en ai trouvé neuf, pas dix)

Je n'ai trouvé que neuf fichiers qui remplissent la règle (orphelin et cité nulle part, ou remplacé par une décision datée). Je n'ai pas cherché un dixième pour arriver au compte.

1. `lib/core/router/ecran_a_construire.dart` (39) : orphelin, 0 test, « feuille de route temporaire » de l'étape 2.
2. `lib/core/tc_classe/port_session_persistante.dart` (88) : seul importeur, un fichier lui-même orphelin.
3. `lib/core/tc_classe/session_persistante.dart` (426) : orphelin, cité nulle part ; la salle dérive sa phase par `VueSalle.depuis`.
4. `lib/core/capacites/port_preferences_persistantes.dart` (40) : orphelin ; `core/preferences/preferences_locales.dart` fait ce travail.
5. `lib/features/demo/support_actif_demo.dart` (115) : double de démonstration orphelin.
6. `lib/core/capacites/courriels_demonstration.dart` (190) : double orphelin.
7. `lib/core/capacites/langues_communication_demonstration.dart` (77) : double orphelin.
8. `lib/core/capacites/avis_demonstration.dart` (249) : double orphelin.
9. `lib/features/tc_catalogue/class_library_picker.dart` (102) : remplacé par `panneau_bibliotheque_salle.dart`, décision du 26/10/2026 (`PLAN-SALLE-COMPOSITION-2026-10-26.md`, validé à 08:40).

Réserve : les fichiers 2 à 9 sont importés par des tests sous `test/` (de 1 à 3 chacun). Il faut supprimer ces tests en même temps, ou les déplacer.

## Graphe des imports

Le script `/tmp/inv/graphe.py` suit `import`, `export`, `part` et les imports conditionnels, en relatif et en `package:rewayah_academy/`, à partir de `lib/main.dart`.

- `lib/` contient 1 231 fichiers .dart.
- **1 194 sont atteignables** (434 686 lignes).
- **37 ne le sont pas** (5 291 lignes ; liste plus bas).
- La note de CLAUDE.md selon laquelle les lots TC D, F et H sont « non branchés depuis main » est dépassée : `tc_realtime`, `tc_etat_partage` et `tc_outils` sont atteignables à 100 %. Restent hors graphe : `tc_flux_academique` (0 sur 4), 4 fichiers de `tc_parcours`, 2 de `tc_dock` et 1 de `tc_realtime`.

## Code de démonstration, galerie ou essai encore relié au routeur

| Élément | Lien au routeur | Dans le build de production ? |
| :-- | :-- | :-- |
| `features/demo/` (60 fichiers, 28 148 lignes) | Neuf familles de routes `/demo/*` (`app_router.dart` l.2202-2210, `redirection.dart` l.48-69), protégées à l'exécution par `environnementAutoriseDemo` | **Oui : 213 Ko de main.dart.js**, compilé avec `ENVIRONNEMENT=production`. Le filtre se fait à l'exécution ; dart2js n'élimine pas ce code |
| `features/demo/mode_demonstration`, `racine_demonstrable`, `repere_demonstration`, `dossiers_demo` | Importés par `main.dart` et `connexion_page.dart` | Oui |
| `features/demo/enseignant_demo.dart` | Importé par un écran réel : `features/creneaux/creneaux_page.dart` | Oui |
| `features/_dev/galerie`, `_dev/playground` | `/_galerie` sous `if (Env.galerieActive)` ; playground par `main.dart` | Non : 0 octet (constante de compilation à false) |
| `features/tc_mes_groupes` (`/tc/groupes`) | `routes_tc_a.dart` | Oui ; CLAUDE.md : groupes de démonstration (`core/tc_groupe/demonstration_groupes.dart`) |
| Doubles « démo » dans du code atteignable | `core/offres/offres_admin_demo.dart`, `core/identite/matricule_demo.dart`, `core/pause_seance/pause_seance_demonstration.dart`, `core/recherche/{corpus,moteurs,moteur}_*demo*`, `core/tc_horloge/demonstration_horloge.dart`, `core/capacites/partage_pedagogique_demonstration.dart`, `features/recherche/domaines/familles_eleves/resolution_ra_demo.dart` | Selon leur importeur (non mesuré un par un) |

## Doublons

| Fonction | Composants en concurrence | Lequel garder | Ce qu'il faut y reporter |
| :-- | :-- | :-- | :-- |
| Bibliothèque en salle | `salle_seance/panneau_bibliotheque_salle.dart` (357, décision 26/10), `salle_seance/bibliotheque_seance.dart` (383), `salle_seance/panneau_supports.dart` (406), `salle_seance/selecteur_ressources.dart` (164), `tc_catalogue/class_library_picker.dart` (102, orphelin) ; tous sur `tc_catalogue/surface_bibliotheque.dart` | `panneau_bibliotheque_salle` + `surface_bibliotheque` | L'ordre Récents / Cette classe / Tous / Recherche (`selecteur_ressources`), « Remplacer un support » (`bibliotheque_seance`, TB-8). C'est le doublon §2.1 du mandat (« Afficher le Coran » contre « Présenter ») |
| Dock d'outils | `salle_seance/dock_seance.dart` (630) + `barre_outils_salle.dart` (446) ; `tc_dock/teaching_dock.dart` (504, orphelin) | `dock_seance` + `barre_outils_salle` | Rien tant que CLAUDE.md interdit de supprimer `tc_dock` |
| Suivi des demandes | `suivi_demandes/suivi_demandes_page.dart` (545) et `suivi_famille/suivi_famille_page.dart` (560), sur une même route via `SuiviDemandesEntree` | `suivi_famille` | `changement_classe_page`, `carte_suivi_demandes` |
| Liste des classes et groupes | `enseignant_classes` (Mes classes, ENS-09), `tc_mes_groupes` (démo), `classe_tuteur`, `tc_espace_groupe`, `fiche_groupe` | `enseignant_classes` (enseignant), `classe_tuteur` (tuteur) | Retirer `/tc/groupes` après report |
| Navigation | `core/widgets/nav_shell.dart` (NavShell), `core/widgets/admin_shell.dart` (rail admin), `salle_seance/rail_seance.dart` (rail enseignant CLV-06, importé seulement par `resultat_seance.dart`), `core/comptable/navigation_comptable.dart` | `NavShell` (+ `AdminShell` pour la direction) | Les entrées de `RailSeance` (Journée, Classes, Ressources, Profil) |
| API des demandes de créneau | `core/offres/port_demandes_horaires.dart` (orphelin), `frise_demandes_supabase.dart`, `demandes_suivi_supabase.dart` | `demandes_suivi_supabase` | Le regroupement admin, si absent (à vérifier) |
| « Aller à » du Coran (pas un doublon, une absence) | `tc_mushaf/navigation_coran_feuille.dart` (page, sourate, juz, référence) n'est utilisé que par `mushaf_page.dart` et `accueil_eleve/coran_accessibilite.dart`, **jamais par `salle_seance/` ni `salle/`** | — | Probable cause du §2.3 du mandat (« présent non branché » dans la salle) ; non prouvé à l'écran |
| Noms proches, mais pas des doublons | `admin_candidature` (fiche, ADM-21) et `admin_candidatures` (file, ADM-20) ; `suivi_eleve`, `suivi_foyer`, `suivi_famille` (trois sujets différents) | Les deux | — |

## Build web

Fait avec Flutter 3.47.8 stable, `flutter build web --release --source-maps`, les mêmes `--dart-define` que la CI (`ENVIRONNEMENT=production`, `GALERIE=false`, `PLAYGROUND=false`) et des valeurs Supabase factices. Compilation en 196 s.

- **`main.dart.js` : 15 105 949 octets (15,1 Mo) ; 3,43 Mo en gzip -9.**
- `main.dart.js_1.part.js` : 2,71 Mo (358 Ko en gzip).
- `build/web` complet : 68 Mo (dont les variantes wasm de canvaskit, de 3,5 à 7,3 Mo chacune).

**Les vingt plus gros contributeurs de main.dart.js** (source map ; octets attribués) :

| # | Source | Octets |
| --: | :-- | --: |
| 1 | `lib/core/i18n/strings_fr.g.dart` | 1 053 008 |
| 2 | flutter_localizations `generated_material_localizations.dart` | 176 346 |
| 3 | moteur `font_fallbacks.dart` | 157 871 |
| 4 | `lib/core/i18n/strings.g.dart` | 135 000 |
| 5 | moteur `font_fallback_data.dart` | 89 039 |
| 6 | flutter `widgets/framework.dart` | 57 859 |
| 7 | (non attribué dans les segments) | 55 521 |
| 8 | flutter `material/theme_data.dart` | 46 464 |
| 9 | sdk `js_util_patch.dart` | 45 393 |
| 10 | `lib/core/theme/app_color_pair.dart` | 43 114 |
| 11 | flutter `widgets/basic.dart` | 36 930 |
| 12 | `dart:ui geometry.dart` | 35 038 |
| 13 | flutter_localizations `generated_widgets_localizations.dart` | 34 164 |
| 14 | flutter `rendering/object.dart` | 32 155 |
| 15 | sdk `internal/iterable.dart` | 31 929 |
| 16 | flutter `widgets/editable_text.dart` | 29 617 |
| 17 | flutter_localizations `generated_cupertino_localizations.dart` | 29 189 |
| 18 | flutter `rendering/box.dart` | 27 896 |
| 19 | flutter `material/input_decorator.dart` | 25 485 |
| 20 | `lib/features/admin_finance/politiques_commerciales.dart` | 25 200 |

Par dossier : `lib/core/i18n` 1,21 Mo · paquet flutter 1,16 Mo · sdk dart 0,48 Mo · moteur web 0,45 Mo · flutter_localizations 0,26 Mo · **`lib/features/demo` 0,21 Mo** · `lib/core/widgets` 0,17 Mo · livekit_client 0,14 Mo · `lib/features/salle_seance` 0,11 Mo. Tout `lib/` : 3,54 Mo attribués.

## Classement de chaque dossier de lib/core et lib/features

« GARDER-BRANCHÉ » = atteignable depuis main.dart. L'importeur cité est le premier dans l'ordre alphabétique, avec « +n » pour les autres.

| Chemin | Lignes atteignables (sur total) | Colonne | Preuve |
| :-- | --: | :-- | :-- |
| `lib/core/accessibilite/` | 1799 (sur 1799) | GARDER-BRANCHÉ | 13/13 fichiers atteignables ; importé par `lib/app.dart +152` |
| `lib/core/admin/` | 7175 (sur 7175) | GARDER-BRANCHÉ | 30/30 fichiers atteignables ; importé par `lib/core/capacites/enseignants_classe_supabase.dart +77` |
| `lib/core/agent/` | 579 (sur 579) | GARDER-BRANCHÉ | 6/6 fichiers atteignables ; importé par `lib/core/session/source_session_agent.dart +5` |
| `lib/core/alertes/` | 136 (sur 136) | GARDER-BRANCHÉ | 2/2 fichiers atteignables ; importé par `lib/core/router/app_router.dart +7` |
| `lib/core/appairage/` | 1537 (sur 1537) | GARDER-BRANCHÉ | 8/8 fichiers atteignables ; importé par `lib/core/cache/secure/stockage_securise.dart +35` |
| `lib/core/auth/` | 113 (sur 113) | GARDER-BRANCHÉ | 1/1 fichiers atteignables ; importé par `lib/core/session/deconnexion.dart +6` |
| `lib/core/cache/` | 3805 (sur 3805) | GARDER-BRANCHÉ | 5/5 fichiers atteignables ; importé par `lib/core/appairage/profils_locaux.dart +10` |
| `lib/core/candidature/` | 5079 (sur 5079) | GARDER-BRANCHÉ | 15/15 fichiers atteignables ; importé par `lib/core/dossier/etat_dossier.dart +35` |
| `lib/core/capacites/` | 12605 (sur 13253) | GARDER-BRANCHÉ | 71/77 fichiers atteignables ; importé par `lib/core/accessibilite/accueil_accessibilite_supabase.dart +257` |
| `lib/core/classes/` | 42 (sur 42) | GARDER-BRANCHÉ | 1/1 fichiers atteignables ; importé par `lib/core/admin/bibliotheque_admin_supabase.dart +5` |
| `lib/core/communications/` | 1755 (sur 1755) | GARDER-BRANCHÉ | 12/12 fichiers atteignables ; importé par `lib/core/capacites/port_notifications.dart +47` |
| `lib/core/comptable/` | 932 (sur 932) | GARDER-BRANCHÉ | 4/4 fichiers atteignables ; importé par `lib/core/capacites/port_aujourdhui_comptable.dart +80` |
| `lib/core/config/` | 279 (sur 279) | GARDER-BRANCHÉ | 2/2 fichiers atteignables ; importé par `lib/core/capacites/port_partage_pedagogique.dart +16` |
| `lib/core/conformite/` | 60 (sur 60) | GARDER-BRANCHÉ | 1/1 fichiers atteignables ; importé par `lib/features/admin_configuration_protection_enfants/protection_enfants_page.dart +3` |
| `lib/core/controle/` | 806 (sur 806) | GARDER-BRANCHÉ | 3/3 fichiers atteignables ; importé par `lib/features/admin_tirage/tirage_libelles.dart +7` |
| `lib/core/coran/` | 713 (sur 713) | GARDER-BRANCHÉ | 2/2 fichiers atteignables ; importé par `lib/core/enseignant/modeles_enseignant.dart +22` |
| `lib/core/domain/` | 536 (sur 536) | GARDER-BRANCHÉ | 1/1 fichiers atteignables ; importé par `lib/app.dart +129` |
| `lib/core/dossier/` | 1182 (sur 1182) | GARDER-BRANCHÉ | 8/8 fichiers atteignables ; importé par `lib/core/capacites/consentements_supabase.dart +28` |
| `lib/core/enseignant/` | 1828 (sur 1828) | GARDER-BRANCHÉ | 7/7 fichiers atteignables ; importé par `lib/core/fraicheur/veille_fraicheur.dart +21` |
| `lib/core/finance/` | 1080 (sur 1080) | GARDER-BRANCHÉ | 10/10 fichiers atteignables ; importé par `lib/core/capacites/mes_donnees_supabase.dart +92` |
| `lib/core/formulaires/` | 168 (sur 168) | GARDER-BRANCHÉ | 1/1 fichiers atteignables ; importé par `lib/features/admin_demandes/demandes_page.dart +8` |
| `lib/core/foyer/` | 756 (sur 756) | GARDER-BRANCHÉ | 5/5 fichiers atteignables ; importé par `lib/features/accueil_famille/accueil_famille_page.dart +30` |
| `lib/core/fraicheur/` | 401 (sur 401) | GARDER-BRANCHÉ | 5/5 fichiers atteignables ; importé par `lib/app.dart +3` |
| `lib/core/i18n/` | 79916 (sur 79916) | GARDER-BRANCHÉ | 15/15 fichiers atteignables ; importé par `lib/app.dart +559` |
| `lib/core/icons/` | 1079 (sur 1079) | GARDER-BRANCHÉ | 1/1 fichiers atteignables ; importé par `lib/core/admin/admin_domaine.dart +300` |
| `lib/core/identite/` | 144 (sur 144) | GARDER-BRANCHÉ | 3/3 fichiers atteignables ; importé par `lib/features/compte/ligne_matricule.dart +2` |
| `lib/core/import_inscriptions/` | 1312 (sur 1312) | GARDER-BRANCHÉ | 4/4 fichiers atteignables ; importé par `lib/features/admin_import_inscriptions/import_inscriptions_page.dart +1` |
| `lib/core/journal/` | 330 (sur 330) | GARDER-BRANCHÉ | 1/1 fichiers atteignables ; importé par `lib/features/admin_journal/journal_page.dart +3` |
| `lib/core/marque/` | 805 (sur 805) | GARDER-BRANCHÉ | 10/10 fichiers atteignables ; importé par `lib/core/widgets/brand_logo.dart +5` |
| `lib/core/matching/` | 133 (sur 133) | GARDER-EN-ATTENTE | Importé par `core/admin/service_admin.dart` ; remplacé pour l'inscription par la classe précréée (00, contradictions résolues ; CLAUDE.md), mais les disponibilités restent utiles |
| `lib/core/mouvement/` | 470 (sur 470) | GARDER-BRANCHÉ | 5/5 fichiers atteignables ; importé par `lib/core/accessibilite/commandes_masquables.dart +24` |
| `lib/core/observabilite/` | 252 (sur 252) | GARDER-BRANCHÉ | 2/2 fichiers atteignables ; importé par `lib/core/auth/service_auth.dart +24` |
| `lib/core/offres/` | 3719 (sur 3834) | GARDER-BRANCHÉ | 16/17 fichiers atteignables ; importé par `lib/core/admin/creneaux_classe_supabase.dart +35` |
| `lib/core/partage_offre/` | 605 (sur 605) | GARDER-BRANCHÉ | 7/7 fichiers atteignables ; importé par `lib/features/partage_offre/carte_partage.dart +5` |
| `lib/core/pause_seance/` | 408 (sur 408) | GARDER-BRANCHÉ | 2/2 fichiers atteignables ; importé par `lib/features/demo/demo_salle_page.dart +4` |
| `lib/core/planning/` | 548 (sur 548) | GARDER-BRANCHÉ | 2/2 fichiers atteignables ; importé par `lib/core/admin/classes_admin_supabase.dart +49` |
| `lib/core/preferences/` | 445 (sur 445) | GARDER-BRANCHÉ | 1/1 fichiers atteignables ; importé par `lib/app.dart +12` |
| `lib/core/presence/` | 537 (sur 537) | GARDER-BRANCHÉ | 2/2 fichiers atteignables ; importé par `lib/core/enseignant/modeles_enseignant.dart +28` |
| `lib/core/priere/` | 410 (sur 410) | GARDER-BRANCHÉ | 4/4 fichiers atteignables ; importé par `lib/core/planning/journee.dart +7` |
| `lib/core/profil/` | 376 (sur 376) | GARDER-BRANCHÉ | 3/3 fichiers atteignables ; importé par `lib/core/capacites/consentements_supabase.dart +14` |
| `lib/core/protection_enfants/` | 98 (sur 98) | GARDER-BRANCHÉ | 1/1 fichiers atteignables ; importé par `lib/features/admin_configuration_protection_enfants/protection_enfants_page.dart +3` |
| `lib/core/recherche/` | 1570 (sur 1570) | GARDER-BRANCHÉ | 9/9 fichiers atteignables ; importé par `lib/core/router/app_router.dart +17` |
| `lib/core/recrutement/` | 1061 (sur 1061) | GARDER-BRANCHÉ | 8/8 fichiers atteignables ; importé par `lib/features/admin_candidatures/candidatures_page.dart +15` |
| `lib/core/regles/` | 260 (sur 260) | GARDER-BRANCHÉ | 1/1 fichiers atteignables ; importé par `lib/features/_dev/playground/faux.dart +5` |
| `lib/core/reseau/` | 246 (sur 246) | GARDER-BRANCHÉ | 3/3 fichiers atteignables ; importé par `lib/core/fraicheur/veille_fraicheur.dart +150` |
| `lib/core/router/` | 4971 (sur 5010) | GARDER-BRANCHÉ | 7/8 fichiers atteignables ; importé par `lib/app.dart +176` |
| `lib/core/seance_famille/` | 659 (sur 659) | GARDER-BRANCHÉ | 2/2 fichiers atteignables ; importé par `lib/core/capacites/port_catalogue_classes.dart +16` |
| `lib/core/session/` | 1142 (sur 1142) | GARDER-BRANCHÉ | 8/8 fichiers atteignables ; importé par `lib/app.dart +69` |
| `lib/core/suivi/` | 207 (sur 207) | GARDER-BRANCHÉ | 2/2 fichiers atteignables ; importé par `lib/core/fraicheur/veille_fraicheur.dart +8` |
| `lib/core/tc_bibliotheque/` | 2357 (sur 2357) | GARDER-BRANCHÉ | 17/17 fichiers atteignables ; importé par `lib/core/admin/enseignants_classe.dart +65` |
| `lib/core/tc_classe/` | 1082 (sur 1596) | GARDER-BRANCHÉ | 7/9 fichiers atteignables ; importé par `lib/core/session/session_controleur.dart +13` |
| `lib/core/tc_coran/` | 2751 (sur 2751) | GARDER-BRANCHÉ | 18/18 fichiers atteignables ; importé par `lib/core/session/session_controleur.dart +13` |
| `lib/core/tc_etat_partage/` | 1266 (sur 1266) | GARDER-BRANCHÉ | 9/9 fichiers atteignables ; importé par `lib/core/session/session_controleur.dart +10` |
| `lib/core/tc_groupe/` | 1822 (sur 1822) | GARDER-BRANCHÉ | 12/12 fichiers atteignables ; importé par `lib/core/accessibilite/accueil_accessibilite_supabase.dart +121` |
| `lib/core/tc_horloge/` | 1568 (sur 1594) | GARDER-BRANCHÉ | 7/8 fichiers atteignables ; importé par `lib/core/accessibilite/accueil_accessibilite_supabase.dart +28` |
| `lib/core/tc_observation/` | 2798 (sur 2886) | GARDER-BRANCHÉ | 15/16 fichiers atteignables ; importé par `lib/features/admin_groupes/feuille_observation_groupe.dart +23` |
| `lib/core/tc_outils/` | 4061 (sur 4061) | GARDER-BRANCHÉ | 18/18 fichiers atteignables ; importé par `lib/core/session/session_controleur.dart +38` |
| `lib/core/tc_parcours/` | 1452 (sur 2197) | GARDER-BRANCHÉ | 11/15 fichiers atteignables ; importé par `lib/core/accessibilite/accueil_accessibilite_supabase.dart +13` |
| `lib/core/tc_realtime/` | 1037 (sur 1175) | GARDER-BRANCHÉ | 8/9 fichiers atteignables ; importé par `lib/core/tc_etat_partage/providers_tc_etat_partage.dart +5` |
| `lib/core/tc_telechargement/` | 504 (sur 504) | GARDER-BRANCHÉ | 4/4 fichiers atteignables ; importé par `lib/core/tc_bibliotheque/catalogue_local.dart +12` |
| `lib/core/theme/` | 2507 (sur 2507) | GARDER-BRANCHÉ | 13/13 fichiers atteignables ; importé par `lib/app.dart +518` |
| `lib/core/version/` | 181 (sur 181) | GARDER-BRANCHÉ | 5/5 fichiers atteignables ; importé par `lib/app.dart` |
| `lib/core/video/` | 2041 (sur 2041) | GARDER-BRANCHÉ | 6/6 fichiers atteignables ; importé par `lib/core/tc_classe/session_persistante.dart +23` |
| `lib/core/widgets/` | 31283 (sur 31283) | GARDER-BRANCHÉ | 105/105 fichiers atteignables ; importé par `lib/app.dart +448` |
| `lib/features/_dev/` | 7209 (sur 7209) | GARDER-EN-ATTENTE | Galerie et playground, CLAUDE.md « État du code » (GALERIE/PLAYGROUND à false en production). 0 octet dans main.dart.js |
| `lib/features/acces_finance/` | 567 (sur 567) | GARDER-BRANCHÉ | 2/2 fichiers atteignables ; importé par `lib/features/accueil_adulte/accueil_adulte_page.dart +12` |
| `lib/features/accueil_adulte/` | 923 (sur 923) | GARDER-BRANCHÉ | 3/3 fichiers atteignables ; importé par `lib/core/router/app_router.dart +2` |
| `lib/features/accueil_eleve/` | 3042 (sur 3042) | GARDER-BRANCHÉ | 6/6 fichiers atteignables ; importé par `lib/core/router/app_router.dart +4` |
| `lib/features/accueil_famille/` | 2060 (sur 2060) | GARDER-BRANCHÉ | 7/7 fichiers atteignables ; importé par `lib/core/fraicheur/veille_fraicheur.dart +16` |
| `lib/features/admin_acces_agents/` | 620 (sur 620) | GARDER-BRANCHÉ | 1/1 fichiers atteignables ; importé par `lib/core/router/app_router.dart` |
| `lib/features/admin_avis/` | 1189 (sur 1189) | GARDER-BRANCHÉ | 2/2 fichiers atteignables ; importé par `lib/core/router/app_router.dart` |
| `lib/features/admin_candidature/` | 3298 (sur 3298) | GARDER-BRANCHÉ | 7/7 fichiers atteignables ; importé par `lib/core/router/app_router.dart` |
| `lib/features/admin_candidatures/` | 1540 (sur 1540) | GARDER-BRANCHÉ | 4/4 fichiers atteignables ; importé par `lib/core/router/app_router.dart +3` |
| `lib/features/admin_comptes/` | 528 (sur 528) | GARDER-BRANCHÉ | 1/1 fichiers atteignables ; importé par `lib/core/router/app_router.dart` |
| `lib/features/admin_configuration_conservation_donnees/` | 133 (sur 133) | GARDER-BRANCHÉ | 1/1 fichiers atteignables ; importé par `lib/core/router/app_router.dart` |
| `lib/features/admin_configuration_fonctionnalites/` | 107 (sur 107) | GARDER-BRANCHÉ | 1/1 fichiers atteignables ; importé par `lib/core/router/app_router.dart` |
| `lib/features/admin_configuration_politique_kyc/` | 183 (sur 183) | GARDER-BRANCHÉ | 1/1 fichiers atteignables ; importé par `lib/core/router/app_router.dart` |
| `lib/features/admin_configuration_protection_enfants/` | 358 (sur 358) | GARDER-BRANCHÉ | 1/1 fichiers atteignables ; importé par `lib/core/router/app_router.dart` |
| `lib/features/admin_configuration_regles/` | 200 (sur 200) | GARDER-BRANCHÉ | 1/1 fichiers atteignables ; importé par `lib/core/router/app_router.dart` |
| `lib/features/admin_courriels/` | 963 (sur 963) | GARDER-BRANCHÉ | 1/1 fichiers atteignables ; importé par `lib/core/router/app_router.dart` |
| `lib/features/admin_demandes/` | 799 (sur 799) | GARDER-BRANCHÉ | 1/1 fichiers atteignables ; importé par `lib/core/router/app_router.dart` |
| `lib/features/admin_dossiers/` | 3729 (sur 3729) | GARDER-BRANCHÉ | 10/10 fichiers atteignables ; importé par `lib/core/router/app_router.dart +2` |
| `lib/features/admin_finance/` | 8181 (sur 8181) | GARDER-BRANCHÉ | 17/17 fichiers atteignables ; importé par `lib/core/router/app_router.dart +3` |
| `lib/features/admin_fusion/` | 789 (sur 789) | GARDER-BRANCHÉ | 2/2 fichiers atteignables ; importé par `lib/features/admin_groupes/groupes_page.dart` |
| `lib/features/admin_groupes/` | 4253 (sur 4253) | GARDER-BRANCHÉ | 11/11 fichiers atteignables ; importé par `lib/core/router/app_router.dart +6` |
| `lib/features/admin_import_inscriptions/` | 1178 (sur 1178) | GARDER-BRANCHÉ | 2/2 fichiers atteignables ; importé par `lib/core/router/app_router.dart` |
| `lib/features/admin_invitations/` | 411 (sur 411) | GARDER-BRANCHÉ | 1/1 fichiers atteignables ; importé par `lib/core/router/app_router.dart` |
| `lib/features/admin_journal/` | 968 (sur 968) | GARDER-BRANCHÉ | 2/2 fichiers atteignables ; importé par `lib/core/router/app_router.dart +1` |
| `lib/features/admin_observations/` | 1133 (sur 1133) | GARDER-BRANCHÉ | 2/2 fichiers atteignables ; importé par `lib/core/router/app_router.dart +1` |
| `lib/features/admin_offres/` | 873 (sur 873) | GARDER-BRANCHÉ | 5/5 fichiers atteignables ; importé par `lib/core/router/app_router.dart` |
| `lib/features/admin_pedagogie_bibliotheque/` | 3816 (sur 3816) | GARDER-BRANCHÉ | 8/8 fichiers atteignables ; importé par `lib/core/router/app_router.dart` |
| `lib/features/admin_pedagogie_diagnostics/` | 325 (sur 325) | GARDER-BRANCHÉ | 1/1 fichiers atteignables ; importé par `lib/core/router/app_router.dart` |
| `lib/features/admin_pedagogie_evaluations/` | 717 (sur 717) | GARDER-BRANCHÉ | 1/1 fichiers atteignables ; importé par `lib/core/router/app_router.dart` |
| `lib/features/admin_pedagogie_programmes/` | 1062 (sur 1062) | GARDER-BRANCHÉ | 1/1 fichiers atteignables ; importé par `lib/core/router/app_router.dart` |
| `lib/features/admin_pedagogie_progression/` | 586 (sur 586) | GARDER-BRANCHÉ | 1/1 fichiers atteignables ; importé par `lib/core/router/app_router.dart` |
| `lib/features/admin_pedagogie_qualite/` | 363 (sur 363) | GARDER-BRANCHÉ | 1/1 fichiers atteignables ; importé par `lib/core/router/app_router.dart` |
| `lib/features/admin_pilotage/` | 747 (sur 747) | GARDER-BRANCHÉ | 2/2 fichiers atteignables ; importé par `lib/core/router/app_router.dart` |
| `lib/features/admin_planning/` | 312 (sur 312) | GARDER-BRANCHÉ | 3/3 fichiers atteignables ; importé par `lib/core/router/app_router.dart +1` |
| `lib/features/admin_regroupements/` | 1426 (sur 1426) | GARDER-BRANCHÉ | 3/3 fichiers atteignables ; importé par `lib/core/router/app_router.dart +8` |
| `lib/features/admin_reprises/` | 310 (sur 310) | GARDER-BRANCHÉ | 1/1 fichiers atteignables ; importé par `lib/core/router/app_router.dart` |
| `lib/features/admin_suppressions/` | 450 (sur 450) | GARDER-BRANCHÉ | 1/1 fichiers atteignables ; importé par `lib/core/router/app_router.dart` |
| `lib/features/admin_tableau/` | 934 (sur 934) | GARDER-BRANCHÉ | 3/3 fichiers atteignables ; importé par `lib/core/router/app_router.dart +2` |
| `lib/features/admin_tirage/` | 1105 (sur 1105) | GARDER-BRANCHÉ | 2/2 fichiers atteignables ; importé par `lib/core/router/app_router.dart` |
| `lib/features/admin_traitement/` | 685 (sur 685) | GARDER-BRANCHÉ | 2/2 fichiers atteignables ; importé par `lib/core/router/app_router.dart` |
| `lib/features/agent_entree/` | 180 (sur 180) | GARDER-BRANCHÉ | 1/1 fichiers atteignables ; importé par `lib/core/router/app_router.dart` |
| `lib/features/alertes/` | 463 (sur 463) | GARDER-BRANCHÉ | 4/4 fichiers atteignables ; importé par `lib/core/router/app_router.dart +1` |
| `lib/features/appareils/` | 1883 (sur 1883) | GARDER-BRANCHÉ | 6/6 fichiers atteignables ; importé par `lib/core/router/app_router.dart +1` |
| `lib/features/avis_public/` | 904 (sur 904) | GARDER-BRANCHÉ | 2/2 fichiers atteignables ; importé par `lib/core/router/app_router.dart` |
| `lib/features/bienvenue_enseignant/` | 443 (sur 443) | GARDER-BRANCHÉ | 2/2 fichiers atteignables ; importé par `lib/core/router/app_router.dart +2` |
| `lib/features/cahier/` | 2408 (sur 2408) | GARDER-BRANCHÉ | 5/5 fichiers atteignables ; importé par `lib/core/router/app_router.dart +1` |
| `lib/features/candidature/` | 5153 (sur 5153) | GARDER-BRANCHÉ | 13/13 fichiers atteignables ; importé par `lib/core/router/app_router.dart +6` |
| `lib/features/classe_tuteur/` | 3468 (sur 3468) | GARDER-BRANCHÉ | 10/10 fichiers atteignables ; importé par `lib/core/fraicheur/veille_fraicheur.dart +5` |
| `lib/features/code_conduite/` | 255 (sur 255) | GARDER-BRANCHÉ | 1/1 fichiers atteignables ; importé par `lib/features/dossier/accords_page.dart +1` |
| `lib/features/com_annonces/` | 3795 (sur 3795) | GARDER-BRANCHÉ | 12/12 fichiers atteignables ; importé par `lib/core/router/app_router.dart +7` |
| `lib/features/com_communaute/` | 4624 (sur 4624) | GARDER-BRANCHÉ | 12/12 fichiers atteignables ; importé par `lib/core/router/app_router.dart +2` |
| `lib/features/com_messages/` | 2679 (sur 2679) | GARDER-BRANCHÉ | 10/10 fichiers atteignables ; importé par `lib/core/router/app_router.dart +12` |
| `lib/features/com_studio/` | 5287 (sur 5287) | GARDER-BRANCHÉ | 16/16 fichiers atteignables ; importé par `lib/core/router/app_router.dart +3` |
| `lib/features/com_vocal/` | 2057 (sur 2057) | GARDER-BRANCHÉ | 5/5 fichiers atteignables ; importé par `lib/features/com_messages/fil_contextuel.dart +4` |
| `lib/features/comptable/` | 12697 (sur 12697) | GARDER-BRANCHÉ | 41/41 fichiers atteignables ; importé par `lib/core/router/app_router.dart +3` |
| `lib/features/compte/` | 4227 (sur 4451) | GARDER-BRANCHÉ | 16/17 fichiers atteignables ; importé par `lib/core/router/app_router.dart +21` |
| `lib/features/connexion/` | 1735 (sur 1735) | GARDER-BRANCHÉ | 5/5 fichiers atteignables ; importé par `lib/core/router/app_router.dart +5` |
| `lib/features/consentements/` | 573 (sur 573) | GARDER-BRANCHÉ | 3/3 fichiers atteignables ; importé par `lib/core/router/app_router.dart +8` |
| `lib/features/controleur/` | 4270 (sur 4270) | GARDER-BRANCHÉ | 14/14 fichiers atteignables ; importé par `lib/core/router/app_router.dart +8` |
| `lib/features/creneaux/` | 1444 (sur 1444) | GARDER-EN-ATTENTE | Routé ; même remarque que core/matching (CLAUDE.md) ; importe `features/demo/enseignant_demo.dart` |
| `lib/features/demo/` | 28033 (sur 28148) | GARDER-EN-ATTENTE | Routes `/demo/*` dans `app_router.dart` l.2202-2210 ; `main.dart` importe `mode_demonstration`, `racine_demonstrable`, `repere_demonstration`, `dossiers_demo` ; `creneaux_page.dart` importe `enseignant_demo`. Présent dans le build de production : 213 Ko de main.dart.js |
| `lib/features/dossier/` | 2091 (sur 2091) | GARDER-BRANCHÉ | 5/5 fichiers atteignables ; importé par `lib/core/router/app_router.dart +3` |
| `lib/features/eleve_connexion/` | 1878 (sur 1878) | GARDER-BRANCHÉ | 3/3 fichiers atteignables ; importé par `lib/core/router/app_router.dart` |
| `lib/features/enseignant_classes/` | 355 (sur 355) | GARDER-BRANCHÉ | 1/1 fichiers atteignables ; importé par `lib/core/router/app_router.dart +2` |
| `lib/features/fiche_groupe/` | 2044 (sur 2044) | GARDER-BRANCHÉ | 4/4 fichiers atteignables ; importé par `lib/core/router/app_router.dart +5` |
| `lib/features/foyer/` | 11238 (sur 11238) | GARDER-BRANCHÉ | 26/26 fichiers atteignables ; importé par `lib/core/fraicheur/veille_fraicheur.dart +17` |
| `lib/features/inscription/` | 1122 (sur 1122) | GARDER-BRANCHÉ | 7/7 fichiers atteignables ; importé par `lib/core/router/app_router.dart +2` |
| `lib/features/journee/` | 2091 (sur 2091) | GARDER-BRANCHÉ | 2/2 fichiers atteignables ; importé par `lib/core/router/app_router.dart +4` |
| `lib/features/juridique/` | 489 (sur 489) | GARDER-BRANCHÉ | 2/2 fichiers atteignables ; importé par `lib/core/router/app_router.dart +1` |
| `lib/features/ma_classe_adulte/` | 355 (sur 355) | GARDER-BRANCHÉ | 1/1 fichiers atteignables ; importé par `lib/core/fraicheur/veille_fraicheur.dart +2` |
| `lib/features/mfa_controleur/` | 614 (sur 614) | GARDER-BRANCHÉ | 3/3 fichiers atteignables ; importé par `lib/core/router/app_router.dart` |
| `lib/features/mon_espace_adulte/` | 655 (sur 655) | GARDER-BRANCHÉ | 2/2 fichiers atteignables ; importé par `lib/features/accueil_adulte/routes_accueil_adulte.dart +2` |
| `lib/features/notifications/` | 1113 (sur 1113) | GARDER-BRANCHÉ | 5/5 fichiers atteignables ; importé par `lib/core/fraicheur/veille_fraicheur.dart +3` |
| `lib/features/paiements_recus/` | 697 (sur 697) | GARDER-BRANCHÉ | 4/4 fichiers atteignables ; importé par `lib/core/router/app_router.dart +3` |
| `lib/features/parcours_offres/` | 1462 (sur 1462) | GARDER-BRANCHÉ | 3/3 fichiers atteignables ; importé par `lib/core/router/app_router.dart +1` |
| `lib/features/partage_offre/` | 2537 (sur 2537) | GARDER-BRANCHÉ | 7/7 fichiers atteignables ; importé par `lib/core/router/app_router.dart +1` |
| `lib/features/presence_correction/` | 490 (sur 490) | GARDER-BRANCHÉ | 2/2 fichiers atteignables ; importé par `lib/features/cahier/cahier_page.dart` |
| `lib/features/presentation_tuteur/` | 304 (sur 304) | GARDER-BRANCHÉ | 1/1 fichiers atteignables ; importé par `lib/core/router/app_router.dart +1` |
| `lib/features/profil_enseignant/` | 1723 (sur 1723) | GARDER-BRANCHÉ | 3/3 fichiers atteignables ; importé par `lib/core/router/app_router.dart +2` |
| `lib/features/protection_enfants/` | 139 (sur 139) | GARDER-BRANCHÉ | 2/2 fichiers atteignables ; importé par `lib/features/fiche_groupe/fiche_eleve_enseignant.dart +1` |
| `lib/features/recherche/` | 1137 (sur 1921) | GARDER-BRANCHÉ | 9/18 fichiers atteignables ; importé par `lib/core/router/app_router.dart +2` |
| `lib/features/recrutement/` | 753 (sur 753) | GARDER-BRANCHÉ | 2/2 fichiers atteignables ; importé par `lib/core/router/app_router.dart +2` |
| `lib/features/remplacements/` | 507 (sur 507) | GARDER-BRANCHÉ | 1/1 fichiers atteignables ; importé par `lib/core/router/app_router.dart +1` |
| `lib/features/revenus_enseignant/` | 1066 (sur 1066) | GARDER-BRANCHÉ | 2/2 fichiers atteignables ; importé par `lib/core/router/app_router.dart +2` |
| `lib/features/revue_groupe/` | 351 (sur 351) | GARDER-BRANCHÉ | 2/2 fichiers atteignables ; importé par `lib/core/router/app_router.dart` |
| `lib/features/salle/` | 6211 (sur 6211) | GARDER-BRANCHÉ | 10/10 fichiers atteignables ; importé par `lib/core/router/app_router.dart +6` |
| `lib/features/salle_enseignant/` | 1065 (sur 1065) | GARDER-BRANCHÉ | 4/4 fichiers atteignables ; importé par `lib/features/salle/salle_page.dart` |
| `lib/features/salle_seance/` | 21152 (sur 21152) | GARDER-BRANCHÉ | 42/42 fichiers atteignables ; importé par `lib/features/admin_courriels/courriels_page.dart +17` |
| `lib/features/suivi_demandes/` | 1204 (sur 1204) | FUSIONNER | Même route que suivi_famille : `SuiviDemandesEntree` (suivi_famille_page.dart l.87-96) choisit l'un ou l'autre. **Garder `features/suivi_famille`** (R20, 10/10) ; y reporter `changement_classe_page.dart` (fusion/transfert, 10/10) et `carte_suivi_demandes.dart` (carte de l'accueil famille) |
| `lib/features/suivi_eleve/` | 326 (sur 326) | GARDER-BRANCHÉ | 1/1 fichiers atteignables ; importé par `lib/core/router/app_router.dart` |
| `lib/features/suivi_famille/` | 697 (sur 697) | GARDER-BRANCHÉ | 2/2 fichiers atteignables ; importé par `lib/core/router/app_router.dart +2` |
| `lib/features/suivi_foyer/` | 2700 (sur 2700) | GARDER-BRANCHÉ | 9/9 fichiers atteignables ; importé par `lib/core/router/app_router.dart +15` |
| `lib/features/talents/` | 2419 (sur 2419) | GARDER-BRANCHÉ | 10/10 fichiers atteignables ; importé par `lib/core/router/app_router.dart +4` |
| `lib/features/tc_catalogue/` | 1695 (sur 2060) | GARDER-BRANCHÉ | 8/11 fichiers atteignables ; importé par `lib/core/router/app_router.dart +10` |
| `lib/features/tc_dock/` | 1473 (sur 2009) | GARDER-BRANCHÉ | `barre_stylet`, `couche_annotation`, `feuille_choix` importés par `salle_seance/ecriture_seance.dart` ; `teaching_dock` et `puce_intention` non atteignables (CLAUDE.md : ne pas supprimer) |
| `lib/features/tc_espace_groupe/` | 3266 (sur 3266) | GARDER-BRANCHÉ | 7/7 fichiers atteignables ; importé par `lib/features/accueil_adulte/accueil_adulte_page.dart +10` |
| `lib/features/tc_flux_academique/` | 0 (sur 954) | GARDER-EN-ATTENTE | 0/4 atteignable ; CLAUDE.md « ne pas les supprimer » ; LISTE-ATTENTE-2026-10-27 (avis de l'élève) ; INVENTAIRE-CONSTRUIT-NON-BRANCHE-2026-10-24 |
| `lib/features/tc_mes_groupes/` | 886 (sur 886) | FUSIONNER | `/tc/groupes` (routes_tc_a) ; CLAUDE.md : groupes de démonstration, « à rebrancher sur les vraies données ». **Garder `features/classe_tuteur`** ; y reporter la liste « Mes groupes » si elle manque, puis retirer `/tc/groupes` |
| `lib/features/tc_mushaf/` | 4105 (sur 4105) | GARDER-BRANCHÉ | 13/13 fichiers atteignables ; importé par `lib/core/router/app_router.dart +4` |
| `lib/features/tc_observation_ui/` | 5082 (sur 5082) | GARDER-BRANCHÉ | 16/16 fichiers atteignables ; importé par `lib/core/router/app_router.dart +2` |

## Classement de chaque fichier non atteignable (37)

| Chemin | Lignes | Colonne | Preuve |
| :-- | --: | :-- | :-- |
| `lib/core/capacites/acces_foyer_depuis_eleves.dart` | 63 | GARDER-EN-ATTENTE | importé par personne ; Orphelin ; sert l'objectif Tuteur 1 du mandat §5 (voir le foyer). 2 tests |
| `lib/core/capacites/avis_demonstration.dart` | 249 | SUPPRIMER | importé par personne ; Double « en mémoire » orphelin, cité nulle part ; 2 tests (à déplacer sous test/ si encore utiles) |
| `lib/core/capacites/courriels_demonstration.dart` | 190 | SUPPRIMER | importé par personne ; Double orphelin, cité nulle part ; 1 test |
| `lib/core/capacites/langues_communication_demonstration.dart` | 77 | SUPPRIMER | importé par personne ; Double orphelin, cité nulle part ; 2 tests |
| `lib/core/capacites/port_preferences_persistantes.dart` | 40 | SUPPRIMER | importé par personne ; Orphelin, cité nulle part ; fonction tenue par `core/preferences/preferences_locales.dart` (atteignable). 2 tests à retirer avec |
| `lib/core/capacites/port_resume_seance_famille.dart` | 29 | GARDER-EN-ATTENTE | importé par personne ; Cité dans docs/current/PED-APRES (REGISTRE_FONCTIONS, AUDIT_ETAPE0, SPEC_VERTICALE_V1) |
| `lib/core/offres/port_demandes_horaires.dart` | 115 | FUSIONNER | importé par personne ; Orphelin ; `frise_demandes_supabase.dart` et `demandes_suivi_supabase.dart` (atteignables) portent la même API. **Garder `demandes_suivi_supabase.dart`** ; y reporter l'API de regroupement admin sans identité si elle n'y est pas (à vérifier) |
| `lib/core/router/ecran_a_construire.dart` | 39 | SUPPRIMER | importé par personne ; Orphelin, 0 test, cité nulle part ; « feuille de route temporaire » de l'étape 2 (septembre) |
| `lib/core/tc_classe/port_session_persistante.dart` | 88 | SUPPRIMER | importé par `session_persistante.dart` ; Importé seulement par `session_persistante.dart` (orphelin) ; cité nulle part |
| `lib/core/tc_classe/session_persistante.dart` | 426 | SUPPRIMER | importé par personne ; Orphelin, cité nulle part ; la phase reste dérivée par `VueSalle.depuis` (atteignable). 1 test |
| `lib/core/tc_horloge/duree_academique.dart` | 26 | GARDER-EN-ATTENTE | importé par personne ; Orphelin ; forme exécutable de la décision D-13 (durée créditée) : doute |
| `lib/core/tc_observation/capacites_observateur.dart` | 88 | GARDER-EN-ATTENTE | importé par personne ; Orphelin ; forme exécutable de D-14/15/16 ; objectif Tuteur 7 (observer) |
| `lib/core/tc_parcours/feedback_memoire.dart` | 144 | GARDER-EN-ATTENTE | importé par personne ; tc_parcours protégé par CLAUDE.md ; chaîne post-cours / feedback (tc_flux_academique) |
| `lib/core/tc_parcours/port_post_cours.dart` | 330 | GARDER-EN-ATTENTE | importé par `panneau_post_cours.dart` ; tc_parcours protégé par CLAUDE.md ; chaîne post-cours / feedback (tc_flux_academique) |
| `lib/core/tc_parcours/post_cours_vm.dart` | 130 | GARDER-EN-ATTENTE | importé par `port_post_cours.dart`, `panneau_post_cours.dart` ; tc_parcours protégé par CLAUDE.md ; chaîne post-cours / feedback (tc_flux_academique) |
| `lib/core/tc_parcours/rotation_feedback.dart` | 141 | GARDER-EN-ATTENTE | importé par `feedback_memoire.dart` ; tc_parcours protégé par CLAUDE.md ; rotation_feedback cité par LISTE-ATTENTE-2026-10-27 |
| `lib/core/tc_realtime/transport_memoire.dart` | 138 | GARDER-EN-ATTENTE | importé par personne ; Double de test déclaré ; dossier tc_realtime protégé par CLAUDE.md. 4 tests |
| `lib/features/compte/soldes_foyer.dart` | 224 | GARDER-EN-ATTENTE | importé par personne ; Orphelin ; EA-9 (soldes), Boucle 4 paiement. 3 tests |
| `lib/features/demo/support_actif_demo.dart` | 115 | SUPPRIMER | importé par personne ; Double de démonstration orphelin, cité nulle part ; 1 test |
| `lib/features/recherche/domaines/classes_supports/moteur_classes_groupes.dart` | 103 | GARDER-EN-ATTENTE | importé par `moteurs_classes_supports.dart` ; Domaines de RECH-1, cités par INVENTAIRE-CONSTRUIT-NON-BRANCHE-2026-10-24 (« quatre domaines », adaptateurs à écrire) |
| `lib/features/recherche/domaines/classes_supports/moteur_supports_catalogue.dart` | 81 | GARDER-EN-ATTENTE | importé par `moteurs_classes_supports.dart` ; Domaines de RECH-1, cités par INVENTAIRE-CONSTRUIT-NON-BRANCHE-2026-10-24 (« quatre domaines », adaptateurs à écrire) |
| `lib/features/recherche/domaines/classes_supports/moteurs_classes_supports.dart` | 19 | GARDER-EN-ATTENTE | importé par personne ; Domaines de RECH-1, cités par INVENTAIRE-CONSTRUIT-NON-BRANCHE-2026-10-24 (« quatre domaines », adaptateurs à écrire) |
| `lib/features/recherche/domaines/enseignants_pedagogie_controle/moteur_controle_mission.dart` | 107 | GARDER-EN-ATTENTE | importé par `moteurs_enseignants_pedagogie_controle.dart` ; Domaines de RECH-1, cités par INVENTAIRE-CONSTRUIT-NON-BRANCHE-2026-10-24 (« quatre domaines », adaptateurs à écrire) |
| `lib/features/recherche/domaines/enseignants_pedagogie_controle/moteurs_enseignants.dart` | 227 | GARDER-EN-ATTENTE | importé par `moteurs_enseignants_pedagogie_controle.dart` ; Domaines de RECH-1, cités par INVENTAIRE-CONSTRUIT-NON-BRANCHE-2026-10-24 (« quatre domaines », adaptateurs à écrire) |
| `lib/features/recherche/domaines/enseignants_pedagogie_controle/moteurs_enseignants_pedagogie_controle.dart` | 29 | GARDER-EN-ATTENTE | importé par personne ; Domaines de RECH-1, cités par INVENTAIRE-CONSTRUIT-NON-BRANCHE-2026-10-24 (« quatre domaines », adaptateurs à écrire) |
| `lib/features/recherche/domaines/finance_communications/moteur_fils.dart` | 121 | GARDER-EN-ATTENTE | importé par `moteurs_finance_communications.dart` ; Domaines de RECH-1, cités par INVENTAIRE-CONSTRUIT-NON-BRANCHE-2026-10-24 (« quatre domaines », adaptateurs à écrire) |
| `lib/features/recherche/domaines/finance_communications/moteur_finances.dart` | 75 | GARDER-EN-ATTENTE | importé par `moteurs_finance_communications.dart` ; Domaines de RECH-1, cités par INVENTAIRE-CONSTRUIT-NON-BRANCHE-2026-10-24 (« quatre domaines », adaptateurs à écrire) |
| `lib/features/recherche/domaines/finance_communications/moteurs_finance_communications.dart` | 22 | GARDER-EN-ATTENTE | importé par personne ; Domaines de RECH-1, cités par INVENTAIRE-CONSTRUIT-NON-BRANCHE-2026-10-24 (« quatre domaines », adaptateurs à écrire) |
| `lib/features/tc_catalogue/class_library_picker.dart` | 102 | SUPPRIMER | importé par personne ; Remplacé par `salle_seance/panneau_bibliotheque_salle.dart`, décision du directeur du 26/10/2026 (PLAN-SALLE-COMPOSITION-2026-10-26, validé 08:40) ; `panneau_supports.dart` dit en être repris. Cité seulement dans le dossier maître du 14/10, antérieur |
| `lib/features/tc_catalogue/support_actif/presenter_port.dart` | 89 | GARDER-EN-ATTENTE | importé par personne ; CAP29-G ; sert l'objectif Enseignant 4 / Élève 3 du mandat (présenter, suivre) |
| `lib/features/tc_catalogue/support_actif/support_actif_classe.dart` | 174 | GARDER-EN-ATTENTE | importé par personne ; CAP29-G, idem |
| `lib/features/tc_dock/puce_intention.dart` | 32 | GARDER-EN-ATTENTE | importé par personne ; CLAUDE.md (tc_dock protégé) |
| `lib/features/tc_dock/teaching_dock.dart` | 504 | GARDER-EN-ATTENTE | importé par personne ; CLAUDE.md (lots TC, ne pas supprimer) ; INVENTAIRE-CONSTRUIT-NON-BRANCHE-2026-10-24. Doublon fonctionnel de `salle_seance/dock_seance.dart` |
| `lib/features/tc_flux_academique/bloc_avant_prochain_cours.dart` | 196 | GARDER-EN-ATTENTE | importé par personne ; CLAUDE.md ; dossier maître 14/10 ; INVENTAIRE 24/10 ; LISTE-ATTENTE 27/10 |
| `lib/features/tc_flux_academique/carte_feedback_seance.dart` | 130 | GARDER-EN-ATTENTE | importé par personne ; CLAUDE.md ; dossier maître 14/10 ; INVENTAIRE 24/10 ; LISTE-ATTENTE 27/10 |
| `lib/features/tc_flux_academique/feuille_signalement.dart` | 288 | GARDER-EN-ATTENTE | importé par personne ; CLAUDE.md ; dossier maître 14/10 ; INVENTAIRE 24/10 ; LISTE-ATTENTE 27/10 |
| `lib/features/tc_flux_academique/panneau_post_cours.dart` | 340 | GARDER-EN-ATTENTE | importé par personne ; CLAUDE.md ; dossier maître 14/10 ; INVENTAIRE 24/10 ; LISTE-ATTENTE 27/10 |

## Outils (hors dépôt)

`/tmp/inv/graphe.py` (graphe), `/tmp/inv/dirs.py` (agrégats), `/tmp/inv/table.py` (classement), `/tmp/inv/sm.py` (source map). Copiés dans `/mnt/session/outputs/outils/`.
