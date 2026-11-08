# Preuves d'absence d'usage : les 18 lignes « supprimé le 08/11 » (agent A, 08/11/2026)

**Lecture seule. Rien n'est supprimé ni déplacé** : chaque geste attend l'accord du directeur sur cette liste précise.

**Ce qui était faux.** J'avais annoncé 17 lignes au pilote ; la liste en compte **18**. Elle a 21 lignes en tout : ces 18, plus `mon_espace_adulte` (non branché, décision du pilote) et deux moteurs de recherche (après la boucle 1).

**Méthode.** Sur `main` 7959b541, pour chaque fichier : `git grep -l <nom du fichier> -- lib test tool`. Chaque occurrence trouvée dans `lib/` a été relue, pour séparer un vrai `import` d'un simple commentaire. Ne comptent pas comme « atteint en production » : `lib/features/demo/` et `lib/features/_dev/` (`tool/verifier_branchement.dart:38-39`).

**Ce que la PR 366 couvre, et ce qui lui manque.** Sa liste (`docs/orchestration/garde-cap/DEFAUTS-SIGNALES-PAR-LE-DIRECTEUR.md`, ligne 184) nomme 14 de ces 18 fichiers et le doublon réel de chacun. Il lui manque deux choses :
- les 4 fichiers de démonstration de la recherche. Elle les renvoie aux « lots de H », alors que la liste des tolérés les marque « à déplacer sous `lib/features/demo/` » ;
- la preuve, fichier par fichier : les importeurs, comptés.

## Tableau

Le seul importeur de production possible serait un fichier de `lib/` hors `demo/` et `_dev/`. **Il n'y en a aucun pour les 18.**

| # | Fichier | Importé dans `lib/` | Importé par les tests | Geste proposé |
|---|---|---|---|---|
| 1 | `core/capacites/acces_foyer_depuis_eleves.dart` | aucun (une seule mention, en commentaire : `port_acces_foyer.dart:148`) | `compte/adaptateurs_compte_test`, `compte/support_compte` | supprimer (doublon de `AccesFoyerSupabase`) |
| 2 | `core/capacites/avis_demonstration.dart` | aucun | `admin_avis/avis_page_test`, `avis_public/avis_public_page_test` | déplacer sous `demo/` (double de test) |
| 3 | `core/capacites/courriels_demonstration.dart` | aucun | `admin_courriels/courriels_page_test` | déplacer sous `demo/` |
| 4 | `core/capacites/langues_communication_demonstration.dart` | aucun | `admin_courriels/courriels_page_test`, `compte/langue_courriels_page_test` | déplacer sous `demo/` |
| 5 | `core/capacites/port_capacite_payout.dart` | `features/demo/comptable/paiements_demo.dart:21` (démo) | `comptable/paiements/confirmation_payout_test`, `support_paiements` | à trancher avec la dette GARDE-VERSEMENTS (PR 366) |
| 6 | `core/capacites/port_preferences_persistantes.dart` | aucun | `capacites/ports_capacites_test`, `fixtures/tuteur/faux_capacites` | supprimer, tests compris |
| 7 | `core/capacites/port_resume_seance_famille.dart` | aucun | `capacites/ports_capacites_test`, `fixtures/tuteur/faux_capacites` | supprimer (doublon de `compte_rendu_famille`) |
| 8 | `core/identite/matricule_demo.dart` | `features/demo/mode_demonstration.dart:49` (démo) | `compte/ligne_matricule_test` | déplacer sous `demo/` |
| 9 | `core/recherche/corpus_demo_recherche.dart` | `core/recherche/moteurs_demo_recherche.dart:1` (lui-même toléré) | `core/recherche/controleur_recherche_test` | déplacer sous `demo/` (zone de H) |
| 10 | `core/recherche/moteur_recherche_demo.dart` | `corpus_demo_recherche.dart:2` et `moteurs_demo_recherche.dart` (tolérés) | 4 tests de la recherche, 2 captures | déplacer sous `demo/` (zone de H) |
| 11 | `core/recherche/moteurs_demo_recherche.dart` | `features/demo/mode_demonstration.dart:59` (démo) | 5 tests de la recherche, 2 captures | déplacer sous `demo/` (zone de H) |
| 12 | `core/router/ecran_a_construire.dart` | aucun | **aucun** (0 référence) | supprimer |
| 13 | `core/tc_horloge/duree_academique.dart` | aucun | `teaching_core/q/q02_entree_precoce_presence_test` | supprimer (le serveur fait foi : `etat_presence`) |
| 14 | `core/tc_observation/capacites_observateur.dart` | aucun | `teaching_core/q/q04_capacites_admin_controleur_test` | supprimer ou déplacer sous `test/` |
| 15 | `core/tc_realtime/transport_memoire.dart` | aucun | `salle_synchro_test`, `tb_recette/recette_synchro_test`, `teaching_core/f/etat_partage_seance_test`, `protocole_canaux_test` | déplacer sous `test/` (double de test) |
| 16 | `core/widgets/child_card.dart` | `features/_dev/galerie/catalogue_galerie.dart:56` (galerie, outil de développement) | `core/widgets/pastille_etat_seance_test`, `widgets/composants_test` | supprimer, avec son entrée de galerie |
| 17 | `features/compte/soldes_foyer.dart` | aucun | `adulte_recette/recette_ea12_test`, `finance_recette/recette_fi_roles_test`, `foyer/paiements_foyer_adulte_test` | supprimer (doublon de `SyntheseSoldesFoyer`) |
| 18 | `features/recherche/domaines/familles_eleves/resolution_ra_demo.dart` | `features/demo/mode_demonstration.dart:82` (démo) | 4 tests de la recherche, 1 capture | déplacer sous `demo/` (zone de H) |

## Ce qu'il faut savoir avant tout geste

- **Aucun de ces 18 fichiers n'est atteint par l'application de production.**
- **Supprimer un fichier casse les tests qui l'importent.** Chaque suppression emporte ses tests, ou les fait passer par le module réel. Chaque déplacement corrige les chemins d'import. Le compte des tests touchés est dans la colonne « tests ».
- **Les fichiers 9, 10, 11 et 18 sont dans la zone de H** (la recherche). Ce relevé ne dit pas qui fera le geste.
- **Le fichier 5** (`port_capacite_payout`) reste lié à la dette GARDE-VERSEMENTS. Il n'est pas tranché ici.
