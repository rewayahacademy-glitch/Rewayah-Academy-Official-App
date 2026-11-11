# Code présent mais non branché, relevé du 11/11/2026

Relevé de A sur `main` `9ae1f7695`, demandé par le pilote le 11/11/2026. Il remplace, comme
point de départ de tout lot, `INVENTAIRE-NON-BRANCHE-2026-10-31.md`. L'ancien fichier reste tel
quel. **Ce relevé ne décide rien et ne change aucune règle** : il dit où en est chaque module
de l'ancien relevé.

## Méthode et limites

- **Atteint** : `dart run tool/verifier_branchement.dart --lister` liste les fichiers de `lib/`
  qu'aucun import ne relie à `lib/main.dart`. Le 11/11, il en liste **4**, tous tolérés
  (`tool/branchement_tolere.txt`). Tout autre fichier existant de `lib/` est atteint.
- **Fournisseur branché** : sa valeur de production lit le serveur. Soit il est surchargé dans
  `lib/main.dart`, soit il lit un port qui l'est. **Bouchon** : sa valeur par défaut rend une
  implémentation « indisponible » et rien ne la surcharge hors démonstration.
- **Supprimé** : le fichier n'existe plus ; le commit de suppression est donné.
- **Lot** : la PR où la ligne de `lib/main.dart` apparaît pour la première fois. Quand la
  première apparition est la PR 191, qui a déplacé ces lignes, le lot d'origine est **inconnu**.
- « Branché » veut dire raccordé dans le code. **Rien n'y est prouvé par le directeur en
  production.** Aucun numéro de ligne n'a été relu à la main au-delà de ceux cités.
- Les références aux migrations de l'ancien relevé ne sont pas revérifiées : on ne lit pas la
  base de production depuis ce lot.

## Ce qui a changé depuis le 31/10, d'abord

- **Branchés depuis** :
  - l'accueil, Ma classe et l'historique de l'élève adulte ;
  - les alertes de la direction ;
  - le second adulte du foyer (sauf `foyerTitulaireProvider`) ;
  - la revue des dossiers (K1) ;
  - la photo publique ;
  - la pause de séance ;
  - la reprise et le travail à préparer de chaque élève ;
  - la couleur du profil ;
  - la recherche (classes, supports, enseignants, matricule) ;
  - la Bibliothèque de la classe ;
  - la séance en arrière-plan ;
  - « Créer mon profil élève ».
- **Supprimés depuis** : les modules marqués « supprimé » ci-dessous, en trois lots (PR 204,
  PR 388 et le lot M1-A8-lib), plus `garde_sortie_salle.dart` (PR 94).
- **Toujours des bouchons** : les finances de la direction et du comptable, les reçus, les cartes
  de classe, le catalogue des classes, la modération, le Studio, la sortie du forfait famille,
  `foyerTitulaireProvider`, la politique de relecture des pièces et « Séance annulée ».

## A. Pendant la séance (`/salle`)

| Module (ancien relevé) | État au 11/11 | Preuve | Lot |
|---|---|---|---|
| `session_persistante.dart`, `port_session_persistante.dart` | branché | importé par `lib/features/salle/salle_page.dart` et `lib/features/salle_seance/barre_seance_en_direct.dart` | PR 204 (note du 08/11 de l'ancien relevé) |
| `salle_seance/portee_outils_salle.dart` | branché | fichier atteint ; même raccord que la ligne précédente (note du 08/11) | PR 204 |
| `salle_seance/signalement_seance.dart` | atteint (fichier relié à `main.dart`) ; usage en salle non relu | annexe | inconnu |
| `portLayoutMushafProvider` | branché | `lib/core/tc_coran/layout_lignes_indisponible.dart:57` : `Env.mushaf15LActif ? LayoutMadina15()` | déjà branché le 31/10 |
| `portCartesClasseProvider` | bouchon | `lib/core/tc_groupe/cartes_classe.dart:281` : `PortCartesClasseIndisponible`, aucune surcharge | — |
| `tc_etat_partage` (`portEtatPartageProvider`) | atteint ; sa persistance est surchargée | `lib/core/tc_etat_partage/providers_tc_etat_partage.dart:29` ; `portEtatPartagePersistantProvider` surchargé (`lib/main.dart:712`) | inconnu |
| `tc_flux_academique/` | presque entièrement supprimé ; restent `carte_feedback_seance.dart` et `tendance_feedback_classe.dart` | `ls lib/features/tc_flux_academique` | PR 204 |
| `tc_parcours/port_post_cours.dart` | supprimé | commit `fccd2f6b8` | PR 204 |
| `tc_dock/teaching_dock.dart`, `puce_intention.dart` | supprimés ; restent `barre_stylet.dart`, `couche_annotation.dart`, `feuille_choix.dart` | commit `fccd2f6b8` | PR 204 |
| `tc_catalogue/support_actif/` | supprimé | commit `d731081ce` | PR M1-A8-lib (numéro non lu) |
| `class_library_picker.dart` | supprimé | commit `fccd2f6b8` | PR 204 |
| `core/tc_horloge/duree_academique.dart` | supprimé | commit `735ffd14a` | PR 388 |
| `tc_observation/capacites_observateur.dart` | supprimé | commit `735ffd14a` | PR 388 |
| `core/router/garde_sortie_salle.dart` (cité) | supprimé | commit `8c4401795` | PR 94 |

## B. Familles, tuteurs, adultes

| Module | État au 11/11 | Preuve | Lot |
|---|---|---|---|
| `accueilAdulteProvider`, `maClasseAdulteProvider`, `historiqueSeancesAdulteProvider` | branchés | ils lisent `portEspaceAdulteProvider`, surchargé dans `lib/main.dart:285` ; routes `/eleve/adulte` (`lib/features/accueil_adulte/routes_accueil_adulte.dart`) et Ma classe (`lib/features/foyer/routes_n2_foyer_adulte.dart:58`) | inconnu (DASH-EA-PROD d'après le commentaire de `accueil_adulte_page.dart:32`) |
| `portRepriseFoyerProvider` | branché | `lib/main.dart:811` | inconnu |
| `portReponseInvitationProvider` | branché | `lib/main.dart:805` | inconnu |
| `invitationRecueProvider` | branché | `lib/main.dart:808` | inconnu |
| `foyerTitulaireProvider` | bouchon | `lib/features/foyer/place_adulte.dart:135` : `throw CapaciteIndisponible('foyer_titulaire')` | — |
| `portSortieForfaitProvider` | bouchon | `lib/features/foyer/sortie_forfait.dart:76` : `_SortieIndisponible` | — |
| `portAlertesProvider` | branché | `lib/main.dart:906` : `AlertesSupabase` | inconnu |
| `mon_espace_adulte_page.dart` | non atteint, toléré | `tool/branchement_tolere.txt` : « branché à l'étape 3 (élève adulte, FN-112) », échéance 15/11/2026 | — |
| `mon_espace_accessibilite.dart` | branché | importé par `lib/core/router/app_router.dart` | inconnu |
| `soldes_foyer.dart`, `child_card.dart`, `port_resume_seance_famille.dart` | supprimés | commit `735ffd14a` | PR 388 |
| `core/offres/port_demandes_horaires.dart` | supprimé | commit `fccd2f6b8` | PR 204 |

## C. Direction, comptabilité

| Module | État au 11/11 | Preuve |
|---|---|---|
| `portTresorerieProvider`, `portEncaissementsProvider`, `portRapprochementProvider`, `portObligationsContractuelsProvider`, `portDelegationFinanceProvider`, `portControleDelegationProvider`, `portExportRapportsProvider`, `portFinanceDirectionProvider`, `portPayoutProvider`, `portBeneficiairesPaiementProvider`, `portAujourdhuiComptableProvider`, `portPolitiqueReserveProvider`, `portPolitiqueRevueKycProvider`, `portCatalogueClassesProvider`, `portRecusProvider` | bouchons | valeur par défaut « Indisponible » dans chaque fichier de `lib/core/capacites/` (par exemple `port_tresorerie.dart:218`, `port_obligations_contractuels.dart:274`, `port_recus.dart:32`, `port_catalogue_classes.dart:163`) ; aucune surcharge hors démonstration |
| `portObligationsPayablesProvider` | branché | `lib/main.dart:659` (déjà corrigé dans l'ancien relevé, §E) |
| `portRevueDossiersProvider` | branché | `surchargeRevueDossiersProduction`, posé dans `lib/main.dart:292` |
| `portMesMoyensPaiementProvider` | déplacé dans la démonstration (`lib/features/demo/comptable/port_mes_moyens_paiement.dart:205`) ; la paie de l'enseignant passe par `port_coordonnees_versement.dart` (`lib/main.dart:87`) | commit `a11bd7f40`, FINANCE-ENSEIGNANT (lot 9) |
| `port_capacite_payout.dart` | non atteint, toléré | `tool/branchement_tolere.txt` : « supprimé le 08/11 », échéance 08/11/2026 **dépassée** |
| `moteursRechercheProvider` | branché | `lib/main.dart:377` : `moteursRechercheProduction` ; PR 347 (RECHERCHE-LIVRAISON) |
| `features/recherche/domaines/finance_communications/` (`moteur_finances.dart`, `moteurs_finance_communications.dart`) | non atteints, tolérés | `tool/branchement_tolere.txt`, échéance 30/11/2026 |

## D. Sans besoin dans les Boucles 1 à 4

| Module | État au 11/11 | Preuve |
|---|---|---|
| `portGardePromotionProvider` | bouchon | `lib/features/com_communaute/port_garde_promotion.dart:249` |
| `portModerationProvider` | bouchon | `lib/core/communications/moderation.dart:217` |
| `envoiPhotoPubliqueProvider` | branché | `lib/main.dart:391` ; PR 212 (PHOTOS-2a) |
| `fabriqueLecteurQrProvider` | branché selon l'appareil | `lib/core/appairage/lecteur_qr.dart:114` : `LecteurQrMobileScanner` quand `lecteurQrDisponibleProvider` est vrai |
| `ecran_a_construire.dart` | supprimé | commit `735ffd14a`, PR 388 |

## E. Tri des quatre rôles : lignes qui ont changé

Les lignes « branchée en production » de l'ancien §E ne sont pas réécrites une par une. Leurs
fichiers Flutter cités existent et sont atteints (liste en annexe), sauf les 4 tolérés. Une ligne
absente du tableau ci-dessous n'a pas changé d'état, à la connaissance de ce relevé.

| Fonction (ancien §E) | Ancien classement | État au 11/11 | Preuve | Lot |
|---|---|---|---|---|
| Élève adulte : bouton Rejoindre, accueil, dernières séances | « faux ou bloqué », branchable | branché | `portEspaceAdulteProvider`, `lib/main.dart:285` | inconnu |
| Toutes mes séances passées (adulte) | branchable | branché | même port ; route `Routes.eleveAdulteSeances` | inconnu |
| Ma classe adulte | branchable, sans route | branché | `lib/features/foyer/routes_n2_foyer_adulte.dart:58` | inconnu |
| Suivre mes demandes (adulte) | branchable, sans entrée | entrée présente | `lib/features/suivi_famille/suivi_famille_page.dart:81` (`liste: Routes.eleveAdulteDemandes`) | inconnu |
| Mon espace en Interface guidée | branchable | atteint par le routeur | `lib/core/router/app_router.dart` importe `mon_espace_accessibilite.dart` | inconnu |
| Coran en Interface guidée (`coran_accessibilite.dart`) | branchable, non importé | atteint | importé par `lib/features/tc_mushaf/mushaf_page.dart` | inconnu |
| Mon espace adulte | serveur à finir | non atteint, toléré | `tool/branchement_tolere.txt` (15/11/2026) | — |
| Besoin d'aide, Accueil standard | sans entrée | **toujours sans entrée** | `Routes.eleveAide` n'est lu que par `accueil_eleve_selon_presentation.dart:46` (Interface guidée) et `mon_espace_accessibilite.dart:313` | — |
| Bibliothèque, ressources de la classe (élève, famille, enseignant) | branchable | branché | `portCatalogueProvider` → `CatalogueSupabase`, `lib/main.dart:370` | PR 207 (N4 écrans) |
| Objectif et page de reprise de chaque élève (enseignant) | branchable | branché | `portProjectionsElevesProvider`, `lib/main.dart:758` | PR 395 (PROJECTION-ELEVES) |
| Pause programmée de la classe | branchable | branché | `portPauseSeanceProvider`, `lib/main.dart:669` | PR 202 (N3 S2) |
| Photo publique | branchable | branché | `envoiPhotoPubliqueProvider`, `lib/main.dart:391` | PR 212 (PHOTOS-2a) |
| « Séance annulée » sur la fiche de classe | branchable | **toujours faux** | `lib/features/tc_espace_groupe/emplacements_groupe.dart:297-298` : `seanceAnnuleeProvider` rend `false` ; lu par `entree_groupe.dart:89` | — |
| Cartes de classe | serveur à finir | bouchon | `lib/core/tc_groupe/cartes_classe.dart:281` | — |
| Moyen de paiement de l'enseignant | serveur à finir | remplacé par « Mes coordonnées de versement » | `port_coordonnees_versement.dart`, `lib/main.dart:87` | FINANCE-ENSEIGNANT, lot 9 (commit `a11bd7f40`) |
| Couleur du profil | serveur à finir | branché | `portAccentsProfilsProvider`, `lib/main.dart:789` | COULEUR-PROFIL (commit `c2b8f28af`) |
| Créer mon propre profil élève | branchable | branché | `lib/features/foyer/creer_mon_profil_page.dart` ; route `lib/core/router/app_router.dart:1116` | N2 ; profil déjà présent : PR 423 |
| Second adulte : inviter, place, accepter, reprise | branchable | branché, sauf `foyerTitulaireProvider` | `lib/main.dart:805`, `:808`, `:811` ; `place_adulte.dart:135` reste un bouchon | inconnu |
| Écrire un message (famille) | serveur à finir | capacités lues au serveur ; ce que le serveur ouvre à la famille n'est pas relu ici | `portCapacitesCommunicationsProvider`, `lib/main.dart:888` | inconnu |
| Rechercher (famille) ; recherche par matricule, classes et supports (direction) | branchable | branché | `moteursRechercheProvider`, `lib/main.dart:377` ; `resolution_ra_supabase.dart` importé par `lib/main.dart` | PR 347 |
| Recherche : référence de paiement | serveur à finir | non atteint, toléré | `tool/branchement_tolere.txt` (30/11/2026) | — |
| Alertes urgentes (direction) | serveur à finir | branché | `portAlertesProvider`, `lib/main.dart:906` | inconnu |
| Désigner un remplaçant | présent dans le code | atteint | `feuille_remplacant.dart` importé par `lib/features/admin_planning/planning_page.dart` | inconnu |
| Choisir une classe déjà créée (catalogue) | serveur à finir | bouchon ; les trois entrées lisent `catalogueClassesOuvert` | `accueil_famille_page.dart:467`, `suivi_famille_page.dart:156`, `fiche/inscription_page.dart:118` | PR du tri des rôles (31/10) |
| Observer la séance (tuteur) | branchable, forcé à faux | non relu en détail | `Env.observationTuteurReelleActive`, `lib/core/config/env.dart:90` | — |
| Modération, Studio | serveur à finir | bouchons | `moderation.dart:217` ; `com_studio/port_studio.dart:376` | — |
| Reçus, factures (famille) | serveur à finir | bouchon | `port_recus.dart:32` | — |
| Quitter le forfait famille | serveur à finir | bouchon | `sortie_forfait.dart:76` | — |
| Politique de relecture des pièces | serveur à finir | bouchon | `port_politique_revue_kyc.dart:58` | — |
| Finances de la direction et du comptable | serveur à finir | bouchons | §C ci-dessus | — |
| Confier une classe qui a déjà un enseignant | serveur à finir | non relu (serveur) | — | — |

## F. Dette du halo vert

Inchangée : section F de l'ancien relevé, écrite le 11/11/2026 par le garde-cap.

## Annexe : fichiers Flutter cités par l'ancien relevé, tous atteints le 11/11/2026

Relevé automatique : chemin résolu sous `lib/`, absent de la liste de
`tool/verifier_branchement.dart --lister`. Les fichiers supprimés ou non atteints sont dans
les sections ci-dessus.

- `lib/core/accessibilite/port_demande_presentation.dart`
- `lib/core/admin/service_admin.dart`
- `lib/core/admin/service_comptes.dart`
- `lib/core/admin/service_configuration.dart`
- `lib/core/admin/service_diagnostics.dart`
- `lib/core/admin/service_groupes.dart`
- `lib/core/alertes/port_alertes.dart`
- `lib/core/appairage/service_appairage.dart`
- `lib/core/appairage/service_enfant.dart`
- `lib/core/capacites/port_accents_profils.dart`
- `lib/core/capacites/port_aujourdhui_comptable.dart`
- `lib/core/capacites/port_catalogue_classes.dart`
- `lib/core/capacites/port_delegation_finance.dart`
- `lib/core/capacites/port_finance_direction.dart`
- `lib/core/capacites/port_politique_reserve.dart`
- `lib/core/capacites/port_politique_revue_kyc.dart`
- `lib/core/capacites/port_recus.dart`
- `lib/core/communications/capacites_communication.dart`
- `lib/core/communications/moderation.dart`
- `lib/core/config/env.dart`
- `lib/core/coran/service_coran.dart`
- `lib/core/enseignant/depot_cahiers.dart`
- `lib/core/enseignant/service_enseignant.dart`
- `lib/core/foyer/port_creation_profil_eleve.dart`
- `lib/core/journal/service_journal.dart`
- `lib/core/pause_seance/port_pause_seance.dart`
- `lib/core/planning/cours_du_moment.dart`
- `lib/core/planning/service_planning.dart`
- `lib/core/presence/service_presence.dart`
- `lib/core/profil/service_declaration.dart`
- `lib/core/profil/service_profil_enseignant.dart`
- `lib/core/recherche/port_recherche.dart`
- `lib/core/router/app_router.dart`
- `lib/core/router/redirection.dart`
- `lib/core/suivi/service_suivi.dart`
- `lib/core/tc_bibliotheque/donnees_catalogue.dart`
- `lib/core/tc_classe/port_session_persistante.dart`
- `lib/core/tc_classe/session_persistante.dart`
- `lib/core/tc_coran/layout_lignes_indisponible.dart`
- `lib/core/tc_groupe/cartes_classe.dart`
- `lib/core/tc_groupe/port_groupes.dart`
- `lib/core/tc_observation/port_politique_observation.dart`
- `lib/core/widgets/nav_shell.dart`
- `lib/features/acces_finance/acces_finance.dart`
- `lib/features/accueil_adulte/accueil_adulte_page.dart`
- `lib/features/accueil_adulte/historique_seances_adulte_page.dart`
- `lib/features/accueil_adulte/routes_accueil_adulte.dart`
- `lib/features/accueil_eleve/accueil_accessibilite.dart`
- `lib/features/accueil_eleve/accueil_eleve_page.dart`
- `lib/features/accueil_eleve/accueil_eleve_selon_presentation.dart`
- `lib/features/accueil_eleve/coran_accessibilite.dart`
- `lib/features/accueil_eleve/mon_espace_accessibilite.dart`
- `lib/features/accueil_famille/accueil_famille_page.dart`
- `lib/features/admin_groupes/feuille_creneau.dart`
- `lib/features/admin_groupes/groupes_page.dart`
- `lib/features/admin_planning/feuille_remplacant.dart`
- `lib/features/admin_regroupements/feuille_classe_regroupement.dart`
- `lib/features/admin_tableau/tableau_de_bord_page.dart`
- `lib/features/bienvenue_enseignant/bienvenue_page.dart`
- `lib/features/cahier/cahier_page.dart`
- `lib/features/classe_tuteur/rejoindre_avec_eleve.dart`
- `lib/features/com_annonces/publier_annonce_classe_page.dart`
- `lib/features/com_communaute/port_communaute.dart`
- `lib/features/com_studio/port_studio.dart`
- `lib/features/compte/compte_page.dart`
- `lib/features/compte/compte_tuteur_page.dart`
- `lib/features/creneaux/creneaux_page.dart`
- `lib/features/demo/comptable/port_mes_moyens_paiement.dart`
- `lib/features/demo/demo_accessibilite_page.dart`
- `lib/features/demo/demo_adulte_page.dart`
- `lib/features/demo/mode_demonstration.dart`
- `lib/features/enseignant_classes/mes_classes_page.dart`
- `lib/features/fiche_groupe/fiche_eleve_enseignant.dart`
- `lib/features/fiche_groupe/fiche_groupe_page.dart`
- `lib/features/fiche_groupe/preparation_seance.dart`
- `lib/features/foyer/acceptation_invitation.dart`
- `lib/features/foyer/fiche/inscription_page.dart`
- `lib/features/foyer/foyer_page.dart`
- `lib/features/foyer/invitation_conjoint.dart`
- `lib/features/foyer/place_adulte.dart`
- `lib/features/foyer/reprise_foyer.dart`
- `lib/features/foyer/sortie_forfait.dart`
- `lib/features/journee/journee_page.dart`
- `lib/features/ma_classe_adulte/ma_classe_adulte_page.dart`
- `lib/features/notifications/notifications_page.dart`
- `lib/features/notifications/notifications_supabase_provider.dart`
- `lib/features/parcours_offres/parcours_offres_page.dart`
- `lib/features/profil_enseignant/photo_publique.dart`
- `lib/features/profil_enseignant/profil_enseignant_page.dart`
- `lib/features/recherche/domaines/classes_supports/moteurs_classes_supports.dart`
- `lib/features/recherche/domaines/familles_eleves/port_resolution_ra.dart`
- `lib/features/remplacements/remplacements_page.dart`
- `lib/features/revenus_enseignant/revenus_enseignant_page.dart`
- `lib/features/revue_groupe/anomalies_revue.dart`
- `lib/features/salle/salle_page.dart`
- `lib/features/salle_seance/barre_outils_salle.dart`
- `lib/features/salle_seance/barre_seance_en_direct.dart`
- `lib/features/salle_seance/portee_outils_salle.dart`
- `lib/features/salle_seance/signalement_seance.dart`
- `lib/features/suivi_famille/suivi_famille_page.dart`
- `lib/features/tc_dock/barre_stylet.dart`
- `lib/features/tc_dock/couche_annotation.dart`
- `lib/features/tc_dock/feuille_choix.dart`
- `lib/features/tc_espace_groupe/emplacements_groupe.dart`
- `lib/features/tc_flux_academique/carte_feedback_seance.dart`
- `lib/features/tc_mes_groupes/routes_tc_a.dart`
- `lib/features/tc_mushaf/mushaf_page.dart`
- `lib/main.dart`
- `test/widgets/entree_groupe_test.dart`
