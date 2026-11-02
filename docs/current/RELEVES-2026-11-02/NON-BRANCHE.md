# Relevé du code non branché, vérifié dans le code (02/11/2026)

Relevé en lecture seule sur `origin/main` 58f6b7978 (worktree `/home/user/wt-releve`, après NOTIFS-L6 #137).
Aucun fichier du dépôt modifié, aucun commit, aucun appel Supabase, Vercel ou GitHub.
Seul effet de bord : `dart run tool/verifier_branchement.dart --lister` a créé `.dart_tool/` (ignoré par git, `git status` propre).

## Ce qui est faux, bloqué ou non prouvé, d'abord

- **Personne ne peut écrire un message en production, aucun rôle.** `portCapacitesCommunicationsProvider` vaut `CapacitesCommunicationsIndisponibles` (`lib/core/communications/capacites_communication.dart:113`), jamais surchargé dans `lib/main.dart`. La capacité `ecrireDansFil` est donc fausse partout : composer masqué (`lib/features/com_messages/fil_contextuel.dart:225`, `messages_page.dart:427-432`), aucune conversation nouvelle (`entree_messages_contexte.dart:328-333`). La direction n'a pas non plus « Publier une annonce » depuis Communications (`administration_communications_page.dart:200-205`). L'inventaire du 31/10 disait seulement « la famille ne peut pas écrire » : c'est faux, c'est tout le monde. Aucune fonction SQL de capacités `com_*` n'existe (les 14 `com_*` sont toutes appelées ; aucune ne rend des capacités).
- **La Bibliothèque est vide pour tous sauf la direction**, dans la salle comme ailleurs : `portCatalogueProvider` vaut `CatalogueLocal()` vide (`lib/core/tc_bibliotheque/donnees_catalogue.dart:32-34`). La salle (`salle_seance/bibliotheque_seance.dart` → `tc_catalogue/surface_bibliotheque.dart:127`), `/tc/bibliotheque` (entrée dans `compte/compte_page.dart:94-100`) affichent un catalogue vide comme s'il n'y avait rien. La page Ressources de la classe du tuteur dit « pas encore reliée » (`classe_tuteur/ressources_classe_page.dart:36-39`).
- **Les signalements des enseignants (dont la sécurité d'un enfant) ne sont lus par personne dans l'application.** `deposer_student_concern` est appelé (`core/tc_parcours/signalement_supabase.dart`), mais la file de la direction `signalements_ouverts_direction()` (`supabase/migrations/20261018160000_pe_protection_enfants.sql:280`) n'a aucun appel Dart. Les « Alertes urgentes » de l'accueil direction restent `AlertesIndisponibles` (`lib/core/alertes/port_alertes.dart:26-41`).
- **Le second adulte du foyer n'a aucun écran en production** alors que l'invitation est branchée côté port : `portInvitationConjointProvider` est surchargé (`main.dart`), mais `InviterConjointPage`, `AjouterMaFamillePage`, `InvitationRecuePage`, `RepriseFoyerPage`, `PlaceConjointPage` ne sont atteints que par `features/demo/demo_adulte_page.dart`. Le vérificateur R1 les voit « atteints » (même fichier que l'adaptateur) : angle mort de R1.
- **« Ma classe » de l'élève adulte n'a pas de route** : `MaClasseAdultePage` (`lib/features/ma_classe_adulte/ma_classe_adulte_page.dart:124`) n'est référencée par aucune route ; l'adaptateur `EspaceAdulteSupabase.maClasse()` existe et est surchargé (`main.dart`), migration `20261102700000_eleve_adulte_lectures.sql`.
- **Le contrôleur n'a jamais de mission** : `missionControleProvider` rend toujours `null` (`lib/features/controleur/mission_controle.dart:100-101`), alors que `ma_mission_controle` et `demarrer_mission_controle` existent (`20261012130005_rech_back_4_d3_fresh_missions.sql`, `20261011210000_c29_control_mission_lifecycle.sql:222`). L'envoi du compte rendu est `EnvoiCompteRenduIndisponible` (`compte_rendu_controle.dart:217`).
- Le vérificateur R1 (`tool/verifier_branchement.dart`) rend exactement les **50** fichiers de `tool/branchement_tolere.txt` (relancé ce jour, `--lister`). Il ne voit ni les bouchons de fournisseurs, ni les écrans importés mais sans route. Le présent relevé ajoute ce qu'il ne voit pas.
- Rien ici n'est prouvé en production. « Branché » veut dire « raccordé dans le code de `main` ». Les migrations datées du 02 au 04/11 ne sont pas vérifiées comme installées sur la base distante (aucun accès, par consigne).

## Méthode (reproductible)

1. Fichiers non atteints : `dart run tool/verifier_branchement.dart --lister` → 50 fichiers, identiques à la liste tolérée.
2. Fournisseurs : extraction de 613 déclarations `final ...Provider = ...` de `lib/` (hors `features/demo`, `_dev`), filtrage des valeurs par défaut neutres (`*Indisponible*`, `*Memoire*`, `CatalogueLocal`, `=> null`, `UnimplementedError`, `_NonBranche`, `Selon(demo: Env.playgroundActif)`), puis recherche d'un `.overrideWith` dans `lib/main.dart`, `core/capacites/revue_dossiers_depuis_validation.dart:448` et `features/bienvenue_enseignant/prerequis_enseignant_supabase.dart:40` (seules surcharges de production hors portées locales de la salle, `salle_page.dart:2328-2335` et `salle_seance/portee_outils_salle.dart:31-33`).
3. Implémentations : pour chaque port neutre, recherche de `implements <Port>` hors démo. Aucun adaptateur Supabase n'existe pour les ports listés « serveur à finir » ou « adaptateur à écrire » ci-dessous, sauf mention.
4. Écrans : recherche de chaque classe `Widget` publique de `lib/features` et `lib/core` référencée hors de son fichier (122 candidats, triés à la main ; les sous-widgets internes ne sont pas listés).
5. SQL : 536 fonctions créées par `supabase/migrations/*.sql` comparées aux chaînes littérales du code Dart et des fonctions Edge ; inverse : 183 noms passés à `.rpc(...)` ou à un enveloppeur, tous présents dans une migration (**aucun appel Dart vers une RPC inexistante trouvé**).
6. Edge : chaque dossier de `supabase/functions` cherché dans `lib/` (`functions.invoke`), les migrations et `.github/workflows`.
7. i18n : 249 textes de `assets/i18n/fr.i18n.json` contenant « pas encore », « bientôt », « indisponible »… rapprochés de leur écran ; seuls ceux affichés en production sans panne sont repris.

Les tests cités existent dans `test/` ; **ils n'ont pas été lancés** par ce relevé (`testé localement` = inconnu).

Légende taille : S < 1 h, M 1-3 h, L > 3 h (un agent). Besoin : C = client seul, SQL = migration, EDGE = fonction Edge, DEC = décision du directeur manquante.

---

## 1. Salle (`/salle`)

| # | Élément (ce que c'est) | Fichiers | Qui le voit | Pour brancher | Qualité, preuve | Taille | Dépendances, remarque |
|---|---|---|---|---|---|---|---|
| S1 | Bibliothèque de la séance (catalogue, ranger, présenter) lit un catalogue local vide | `lib/core/tc_bibliotheque/donnees_catalogue.dart:32`, `catalogue_local.dart:26`, `port_catalogue.dart:99-119`, `features/tc_catalogue/surface_bibliotheque.dart:127`, `features/salle_seance/bibliotheque_seance.dart` | enseignant, élève (salle) ; tuteur, élève (`/tc/bibliotheque`) | C + SQL : un `CatalogueSupabase implements PortCatalogue`. `pourGroupe` → `ressources_du_groupe` (0033:742, 0035) ; lecture d'un fichier → EDGE `bibliotheque-lecture` (existe, jamais appelée) + `autoriser_lecture_version` (`20261011152845_c35`). `tous`/`recents`/`derniereLecture` : `library_get_catalogue` est **réservée à la direction** (`20261016100600_cap29_catalogue_correctif.sql:42`), donc une lecture non-direction est à écrire | Écrans testés (`test/` : 11 fichiers citent `surface_bibliotheque`, 7 `catalogue_local`) ; contrat stable (`catalogue_local.dart` : « le corps des méthodes change, pas le contrat ») | L | Décision Bibliothèque du 30/10 (`DECISION-BIBLIOTHEQUE-ET-RESTES-2026-10-30.md` §1) : seul le contenu est un chantier long. 0035 notée « non appliquée » en septembre (`supabase/migrations/LISEZ-MOI-0035-0037-non-appliquees.md`) : état distant inconnu |
| S2 | Pause programmée de la classe | `lib/core/pause_seance/port_pause_seance.dart:242-291`, `features/fiche_groupe/bloc_pause_classe.dart:148-160`, `fiche_groupe_page.dart:359` | enseignant (fiche de classe : bloc « indisponible » affiché) | C : adaptateur `PauseSeanceSupabase` sur `pause_reglage_lire`, `pause_reglage_ecrire`, `pause_seance_demarrer`, `pause_seance_etat`, `pause_seance_terminer` (`20261012061517_x2_22_pause_seance.sql`, toutes sans appel Dart), surcharge dans `main.dart` | Contrat écrit `docs/current/CONTRAT_PORT_PAUSE_SEANCE.md` ; double de démo `pause_seance_demonstration.dart` ; tests `test/core/pause_seance/port_pause_seance_test.dart`, `test/features/fiche_groupe_pause/` | M | La pause pendant la séance (côté salle) n'est consommée nulle part hors fiche : à vérifier avec la fiche d'écran |
| S3 | Âge de l'élève (tutoiement d'un mineur dans la salle) | `lib/core/accessibilite/age_eleve.dart:31-46` ; lu `features/salle/salle_page.dart:1778`, `:1955` | élève (tout le monde est vouvoyé) | SQL ou C : aucune lecture d'âge côté client ; `birth_date`, `est_mineur`, `tranche_age` existent en base (grep migrations) | Port pur, trivial | S-M | Source à choisir (DEC légère) |
| S4 | Cartes de la classe | `lib/core/tc_groupe/cartes_classe.dart:257-281`, `features/tc_espace_groupe/bloc_cartes_classe.dart`, `feuille_carte_classe.dart` | tuteur, élève, enseignant (espace de classe `/tc/groupes/:id`, « Les cartes de la classe ne sont pas encore ouvertes ») | SQL + C : aucune fonction serveur | 11 fichiers de test | L | Serveur à écrire |
| S5 | `signalement_seance.dart` (« Signaler un besoin » depuis la salle) | `lib/features/salle_seance/signalement_seance.dart` | personne (non atteint) | **Ne pas brancher** : doublon de `ouvrirSignalement` / `SignalerBesoin` (`fiche_groupe/fiche_eleve_enseignant.dart`), branché | 0 test | - | Toléré, suppression proposée 08/11 |
| S6 | Ancien dock, après-cours, support actif, sélecteur de bibliothèque | `features/tc_dock/*`, `features/tc_flux_academique/*`, `core/tc_parcours/{port_post_cours,post_cours_vm,feedback_memoire,rotation_feedback}.dart`, `features/tc_catalogue/{class_library_picker.dart,support_actif/*}` | personne | **Ne pas brancher** : doublons de `salle_seance/barre_outils_salle.dart`, `features/cahier`, `bibliotheque_seance`/`panneau_bibliotheque_salle` | - | - | Tolérés, suppression proposée 08/11 (décision du directeur) |
| S7 | État partagé générique et transport temps réel | `core/tc_etat_partage/providers_tc_etat_partage.dart` (`portEtatPartageProvider`), `core/tc_realtime/providers_tc_realtime.dart` (`TransportIndisponible`), `core/tc_coran/navigation_coran.dart` (`portEtatPartageCoranProvider` = null) | personne | **Ne pas brancher** : aucun consommateur hors de leur fichier ; la salle a son adaptateur (`EtatPartageSupabase` surchargé dans `main.dart`, synchro `salle_page.dart:2328`) | - | - | Code mort atteint (R1 ne le voit pas) |
| S8 | `PreCours`, `EncreDeLaSalle` | `features/salle/pre_vol_classe.dart:130`, `features/salle/encre_salle.dart:29` | personne | Widgets sans aucun usage (fichiers importés pour d'autres symboles) | - | S | À supprimer ou réutiliser (DEC) |
| S9 | Séance en arrière-plan et portée des outils | `core/tc_classe/session_persistante.dart`, `features/salle_seance/portee_outils_salle.dart` | - | **Déjà branchés** depuis le 31/10 (`app_router.dart:2752-2766`, `salle_page.dart:207`, `barre_seance_en_direct.dart`). Inventaire du 31/10 §A périmé sur ce point | - | - | - |
| S10 | Chrono de la salle (exemple R3) | `salle_seance/depuis_salle.dart:42,97`, `salle_page.dart:1962` | - | **Déjà branché** (PR #113) | - | - | - |

## 2. Classes (enseignant et direction)

| # | Élément | Fichiers | Qui le voit | Pour brancher | Qualité, preuve | Taille | Dépendances |
|---|---|---|---|---|---|---|---|
| C1 | Préparation de la prochaine séance, objectif et page de reprise par élève | `features/fiche_groupe/preparation_seance.dart` (`preparationSeanceProvider` et `projectionElevesProvider` = null/vide) ; lus par `fiche_groupe_page.dart`, `cahier/cahier_page.dart`, `revue_groupe/revue_groupe_page.dart`, `salle/salle_page.dart` | enseignant | SQL + C : `groupe_roster_enseignant` (0033:787) et `derniere_position_groupe` (0033:1417) existent sans appel Dart ; aucune fonction « préparation » | Démo seule | L | Contenu à préciser (fiche d'écran) |
| C2 | Progression de la classe, « séance annulée » sur la carte | `features/tc_espace_groupe/emplacements_groupe.dart` (`progressionGroupeProvider` = null, `seanceAnnuleeProvider` = false) | enseignant, tuteur | Progression : SQL absent pour l'enseignant. Annulée : DEC (la carte suit `horloge_classe`, qui ignore les séances annulées : `20261025040000_horloge_classe_et_concierge_tuteur.sql:87`) | - | M-L | DEC |
| C3 | « Classes disponibles » dans Créneaux | `features/creneaux/creneaux_page.dart:27` (`offresClassesProvider` = null), `DetailOffrePage` `:204` | enseignant (section masquée) | **Ne pas brancher** : contraire à `DECISION-OFFRES-GROUPES-2026-10-09.md` (seule l'administration publie) ; à retirer | - | S | DEC (retrait) |
| C4 | Choix d'une classe déjà créée par la famille (catalogue) | `core/capacites/port_catalogue_classes.dart:140-165`, `features/classe_tuteur/catalogue_classes_page.dart` | tuteur (entrées détournées vers le parcours depuis #101) | **Ne pas brancher** : remplacé par le parcours offre puis horaire (DECISION-OFFRES du 09/10) | - | - | - |
| C5 | Réaffecter une classe, désigner un remplaçant | `features/admin_planning/feuille_reaffectation.dart:32`, `feuille_remplacant.dart:33` | direction | **Déjà branchés** (#96, #104 ; `planning_page.dart:45-46`, `main.dart` `portRemplacementsDirectionProvider`) | - | - | Migrations `20261102400000`, `20261103100000` : installation distante inconnue |

## 3. Inscription, admission

| # | Élément | Fichiers | Qui le voit | Pour brancher | Qualité | Taille | Dépendances |
|---|---|---|---|---|---|---|---|
| I1 | Demander un créneau personnalisé | aucun écran | tuteur | C (écran) : `demander_creneau_personnalise`, `etat_creneau_personnalise`, `retirer_creneau_personnalise` (`0049_creneau_personnalise_ouvert_au_quota.sql:168`) sans appel Dart | - | L | DEC (le parcours des offres l'exclut-il ?) |
| I2 | Anciennes fonctions de demandes horaires | `mes_demandes_horaires`, `refuser_demande_horaire`, `retirer_demande_horaire`, `suivi_demandes_horaires_foyer_utc`, `completer_niveau_demande_horaire`, `pool_offre`, `offres_admin`, `classes_a_confirmer_admin`, `eleves_sans_enseignant` (migrations 0005, 0043, 0071, 0072) ; interfaces `core/offres/port_demandes_horaires.dart` (non atteint) | personne | **Ne pas brancher sans lecture** : recouvrent `admin_regroupements`, la frise et le suivi, branchés (`main.dart` `portFriseDemandesProvider`, `portSuiviDemandesProvider`) | - | - | Probablement remplacées ; à confirmer avant toute suppression |
| I3 | Profils enfants créés depuis une demande d'admission | `core/admission/profils_demande.dart:143-157` | - | **Déjà branché** (adaptateur Supabase par défaut, EDGE `creer-profil-enfant`) | - | - | - |

## 4. Recrutement, candidats

| # | Élément | Fichiers | Qui le voit | Pour brancher | Qualité | Taille | Dépendances |
|---|---|---|---|---|---|---|---|
| R1 | Dépôt de la pièce d'identité dans le coffre R2 | EDGE `supabase/functions/piece-identite-depot`, `piece-identite-confirme` : **aucun appel** (Dart, migrations, workflows hors `ci.yml`). Le client dépose dans le seau Supabase `kyc` (`lib/core/dossier/service_dossier.dart:202-227`) | candidat enseignant, tuteur (dépôt) ; direction (lecture via `piece-identite-acces`, qui lit les deux stockages, `index.ts:25-128`) | C : appeler `piece-identite-depot` puis PUT puis `piece-identite-confirme` dans `ServiceDossierSupabase.deposerPiece` | Fonctions Edge commentées et testées en CI (`ci.yml`) ; bascule `storage_backend` prévue | M | DEC + secrets R2 configurés en production : inconnu |
| R2 | Le reste du recrutement | `main.dart` (`portMaCandidatureProvider`, `portAutresCompetencesProvider`, `portCandidaturesDirectionProvider`, invitations enseignant et comptable) | - | **Branché** | - | - | - |

## 5. Finance (direction, comptable, enseignant, famille)

Tous ces ports valent leur classe `*Indisponible*` en production, sans adaptateur Supabase dans `lib/` et sans surcharge dans `main.dart`. Les écrans existent, ont une route et affichent « indisponible ».

| # | Élément | Port (fichier) | Écrans, qui le voit | Serveur | Qualité | Taille | Dépendances |
|---|---|---|---|---|---|---|---|
| F1 | Trésorerie (résumé, coffres, historique, prévision, transferts) | `core/capacites/port_tresorerie.dart:138-200` | comptable (onglet Trésorerie, `features/comptable/tresorerie/*`) ; `Routes.comptableTresorerie` | SQL : seules des mutations existent (`decider_tresorerie_montant`, `decider_tresorerie_duree`, `reprendre_alimentation_tresorerie`, `abandonner_reprise_tresorerie`, `20261012120101_x2_17_treasury_triggers.sql:428`), aucune lecture | 16 fichiers de test | L | DEC finance (Boucle 4) |
| F2 | Encaissements, rapprochement | `port_encaissements.dart:204`, `port_rapprochement.dart:156` | comptable (`/comptable/tresorerie/encaissements`) | SQL absent (`rech_d4_rechercher_reference_finance` existe mais dépend des encaissements) | 13 tests | L | F1 |
| F3 | Aujourd'hui du comptable | `port_aujourdhui_comptable.dart:210-235` | comptable (premier onglet, `/comptable`) | SQL absent | 11 tests | L | F1, F2 |
| F4 | Obligations des contractuels | `port_obligations_contractuels.dart:233` | comptable (`/comptable/paiements/contractuels`) | SQL absent | 14 tests | L | DEC |
| F5 | Bénéficiaires de paiement, versements (payout), « Recevoir mes paiements » | `port_beneficiaires_paiement.dart:139`, `port_payout.dart:266`, `port_mes_moyens_paiement.dart:163`, `port_capacite_payout.dart` (non atteint, toléré) | comptable ; enseignant (`compte_page` `RubriqueRecevoirPaiements`, `features/paiements_recus/*`) | SQL absent ; prestataire de versement non choisi | 30 tests (bénéficiaires) | L | DEC prestataire |
| F6 | Vue globale, réserve stratégique, délégation financière | `port_finance_direction.dart:298-315`, `port_politique_reserve.dart:196-225`, `port_delegation_finance.dart:300-370` | direction (`features/admin_finance/finance_page.dart` → `VueGlobaleFinanceBloc`, `ReserveDelegationPage`) | SQL absent | 7 tests (vue globale) | L | DEC |
| F7 | Export des rapports | `port_export_rapports.dart:53-63` | comptable (action masquée si indisponible, `comptable/graphiques/action_export.dart`) | SQL ou EDGE absent | - | M | - |
| F8 | Reçus et factures téléchargeables | `port_recus.dart:22-35` ; `features/foyer/fiche/finances_page.dart` (`BoutonRecu`) | tuteur, élève adulte | SQL partiel : `emettre_factures_mois` (`20261017171000_fac_b_01_factures_mensuelles.sql`) émet, aucune lecture famille ni document | - | L | DEC (forme du reçu) |
| F9 | Ce qui est branché | `main.dart` : politiques commerciales, politique famille, paiements saisis, validations, paie (`portObligationsPayablesProvider`), séries, recharge Stripe, revenus enseignant, finances adulte, accès | - | **Branché** | - | - | Stripe réel non prouvé |

## 6. Famille (tuteur)

| # | Élément | Fichiers | Qui le voit | Pour brancher | Qualité | Taille | Dépendances |
|---|---|---|---|---|---|---|---|
| FA1 | Second adulte : inviter, invitation envoyée | `features/foyer/invitation_conjoint.dart:215` (`InviterConjointPage`), `ajouter_ma_famille.dart:21` (`part of`) | tuteur titulaire : **aucune entrée** (démo seule) | C : routes et entrée depuis `foyer_page.dart` ; adaptateur **déjà surchargé** (`InvitationConjointSupabase`, `inviter_conjoint`, `annuler_invitation_conjoint`, 0053) | 35 fichiers de test citent `invitation_conjoint` | M | Un seul lot avec FA2-FA4 (cohérence) |
| FA2 | Invitation reçue par le second adulte | `features/foyer/acceptation_invitation.dart:135-152` (`_ReponseIndisponible`, `invitationRecueProvider` lève) ; `InvitationRecuePage`, `InvitationSansComptePage` | second adulte : aucune route | C : adaptateur sur `mon_invitation_en_cours`, `repondre_invitation_conjoint` (0053, sans appel Dart) + routes | 0 test au nom du fichier | M | FA1 |
| FA3 | Reprise du foyer par le second adulte | `features/foyer/reprise_foyer.dart:136-149` (`_RepriseIndisponible`), `RepriseFoyerPage`, `RepriseTitulairePage` | second adulte, titulaire : aucune route | C : adaptateur sur `deposer_reprise_foyer`, `etat_reprise_foyer`, `refuser_reprise_foyer` (0098/0099, sans appel Dart) ; côté direction déjà branché (`portReprisesAdminProvider`) | 2 tests | M | FA1 |
| FA4 | Place du second adulte, quitter le forfait famille | `features/foyer/place_adulte.dart` (`foyerTitulaireProvider` lève), `sortie_forfait.dart:63-76` (`PlaceConjointPage`, `DelaiPlacePage`) | titulaire, second adulte | SQL absent (aucune fonction « sortie ») | 14 tests (`place_adulte`) | L | DEC |
| FA5 | Créer mon propre profil élève (titulaire) | route `ajouter?pour=moi` → `CreerMonProfilIndisponible` **en dur** (`lib/core/router/app_router.dart:1007-1013`, `foyer_page.dart:318-323`) | tuteur titulaire (« sera proposé prochainement ») | C : l'adaptateur `ProfilEleveTitulaireSupabase` est **déjà surchargé** (`main.dart`, migration `0052_profil_eleve_titulaire.sql:72`) mais seul `compte/donnees_compte.dart:73` lit `existe()` ; écrire l'écran de confirmation qui appelle `creer()` | 6 tests (`creer_mon_profil`) | M | Lien avec l'élève adulte (FN-112) |
| FA6 | Couleur du profil d'un enfant | `core/capacites/port_accents_profils.dart:25-64`, `features/foyer/fiche/couleur_page.dart` | tuteur (fiche enfant : « Pas encore disponible ») | SQL absent | 2 tests | M | - |
| FA7 | Ressources, progression, travail d'une classe (pages tuteur) | `features/classe_tuteur/ressources_classe_page.dart:36` | tuteur | Ressources : voir S1. Progression et travail : **branchés** (`portProgressionFamilleProvider`, `assignationsFamilleProvider` dans `main.dart`) | - | - | S1 |
| FA8 | Résumé de séance pour la famille | `core/capacites/port_resume_seance_famille.dart` (non atteint, toléré) ; serveur `resume_seance_famille`, `enregistrer_resume_seance` (0054) sans appel Dart | personne | **Doublon probable** du compte rendu branché (`compte_rendu_famille`, `20261018190000_ped_cahier_partage.sql:651`) : ne pas brancher sans DEC | - | - | - |
| FA9 | Observer la séance | `core/config/env.dart:74-112` (forcé faux hors `developpement`/`staging`) | tuteur | DEC : recette et signature (serveur `entrer_observation`, 0033:1086) | - | - | DEC |
| FA10 | `soldes_foyer.dart`, `child_card.dart` | `features/compte/soldes_foyer.dart`, `core/widgets/child_card.dart` | personne | Non atteints, tolérés (suppression proposée 08/11). Les soldes sont montrés par `foyer/fiche/finances_page.dart`, branché | - | - | - |

## 7. Élève (enfant en Interface guidée, élève adulte)

| # | Élément | Fichiers | Qui le voit | Pour brancher | Qualité | Taille | Dépendances |
|---|---|---|---|---|---|---|---|
| E1 | Ma classe de l'élève adulte | `features/ma_classe_adulte/ma_classe_adulte_page.dart:113-160` | élève adulte : **aucune route** | C : une route (et une entrée) ; port et adaptateur déjà là (`EspaceAdulteSupabase.maClasse`, `participants_classe_eleve_adulte`) | 8 tests | S-M | Barre adulte fixée par `mots-rewayah` (`nav_shell.dart:105-126` : Aujourd'hui, Apprendre, Suivi, Profil) : où mettre l'entrée = DEC |
| E2 | Mon espace de l'élève adulte | `features/mon_espace_adulte/mon_espace_adulte_page.dart:155` (`monEspaceAdulteProvider` lève `CapaciteIndisponible`) | élève adulte (non atteint ; son Profil part vers `/tuteur/compte`) | SQL absent pour la vue composite | 25 tests | M-L | Toléré « étape 3 FN-112 », échéance 15/11 |
| E3 | Mon espace en Interface guidée, demander l'interface standard | `features/accueil_eleve/mon_espace_accessibilite.dart` (non atteint), `core/accessibilite/port_demande_presentation.dart` (non atteint) | élève enfant | C : `demander_presentation_standard` (`0080_age_presentation_requests.sql:106`) sans appel Dart | 1 test | M | Toléré « étape 3 », 15/11 ; `port_demande_presentation` proposé à la suppression le 08/11 : **contradiction** entre les deux lignes |
| E4 | Coran en Interface guidée (« Reprendre ») | `features/accueil_eleve/coran_accessibilite.dart` (`CoranAccessibilite`, démo seule) | élève enfant | C : choisir la page selon l'interface (`0007` `:98` déjà lu par `service_coran`) | 5 tests | S-M | DEC (entrée de la barre) |
| E5 | Après la séance en Interface guidée | `features/accueil_eleve/apres_seance_accessibilite.dart:69` (`ApresSeanceAccessibilite`, démo seule ; le fichier est importé par `salle_page.dart:85` pour d'autres symboles) | élève enfant | C : à poser en sortie de salle ; travail à venir déjà branché (`portTravailAVenirProvider`) | 5 tests | M | Fiche d'écran à confirmer |
| E6 | `/tc/groupes` (mes classes, espace de classe) | `features/tc_mes_groupes/routes_tc_a.dart:37`, seule entrée `salle_page.dart:1061`, `:1726`, `:1785` | élève, tuteur (redirigé vers l'accueil, `redirection.dart:411-419`) | DEC : entrée de menu | Lecture réelle (`port_groupes.dart:41`) | S | DEC |
| E7 | Besoin d'aide sur l'Accueil standard, « Mes demandes » de l'adulte | `accueil_eleve_selon_presentation.dart:46` ; `routes_accueil_adulte.dart:75` (route sans entrée hors `suivi_famille_page.dart:81`) | élève | C | - | S | DEC (barre) |

## 8. Enseignant

| # | Élément | Fichiers | Qui le voit | Pour brancher | Qualité | Taille | Dépendances |
|---|---|---|---|---|---|---|---|
| EN1 | Photo publique | `features/profil_enseignant/photo_publique.dart:66-82` (`_EnvoiNonBranche`), ouverte depuis `profil_enseignant_page.dart:224` et `bienvenue_page.dart` | enseignant (l'envoi échoue) | C : envoi dans le seau `photos_enseignants` (créé `0030_tc_socle.sql:208`, politique `20261017110900_af_l2_09_storage_policies.sql:33`), puis écrire `teacher_profiles.photo_storage_key` (lu `0033_tc_vues_rpc.sql:157`) ; droit d'écriture de la colonne : **à vérifier** | 10 tests | M | Éventuelle petite RPC si la colonne n'est pas modifiable par l'enseignant |
| EN2 | Pause programmée | voir S2 | enseignant | - | - | M | - |
| EN3 | Préparation, progression, séance annulée | voir C1, C2 | enseignant | - | - | - | - |
| EN4 | Anomalies de la revue courte | `features/revue_groupe/anomalies_revue.dart:104` | enseignant | SQL : `0024_qualite_pedagogique.sql:107` réservée à la direction | - | M | DEC (ouvrir à l'enseignant ?) |
| EN5 | Communauté enseignants | `features/com_communaute/*`, entrée `journee_page.dart:1009` (masquée tant que la capacité manque, `entree_communaute.dart`) | enseignant (rien d'affiché) | SQL + C absents | - | L | Hors boucles 1 à 4 |

## 9. Direction (et contrôleur)

| # | Élément | Fichiers | Qui le voit | Pour brancher | Qualité | Taille | Dépendances |
|---|---|---|---|---|---|---|---|
| D1 | Alertes urgentes et file des signalements | `core/alertes/port_alertes.dart:26-41` ; `features/alertes/section_alertes.dart` dans `admin_tableau/tableau_de_bord_page.dart` (« Les alertes ne sont pas encore disponibles ») | direction | C : un adaptateur sur `signalements_ouverts_direction()` (existe, sans appel) couvre les signalements ; le temps réel et la gravité (DASH-BR-03/04) demandent du SQL | 2 tests | M (signalements) / L (alertes complètes) | DEC : la file des signalements est-elle « les alertes » ? |
| D2 | Recherche de la direction | `core/recherche/port_recherche.dart:120` (`moteursRechercheProvider` vide) ; 14 fichiers `features/recherche/domaines/**` non atteints | direction, tuteur, élève (entrée masquée : `rechercheServieProvider` faux, `app_router.dart:2977-2986`) | C : les moteurs actuels filtrent des ports locaux (aucun appel Supabase dans les 14 fichiers) ; à réécrire sur `rech_d1_rechercher_classes`, `rech_d1_rechercher_supports`, `rech_d1_curseur_*`, `rechercher_personne_par_matricule`, `rech_d4_rechercher_reference_finance` (aucune appelée) et EDGE `recherche-enseignants` (jamais appelée) | Tests présents (1 à 3 par moteur) ; à refaire côté source | L | Tolérés « étape Listes », 30/11 ; `rech_d4` dépend de F2 |
| D3 | Mission et compte rendu du contrôleur | `features/controleur/mission_controle.dart:100` (null), `compte_rendu_controle.dart:155,217` | contrôleur (`controle_page.dart:73-86`) | C : adaptateur sur `ma_mission_controle`, `demarrer_mission_controle`. Envoi du compte rendu : **aucune fonction d'envoi trouvée** (seulement `controleur_lister_rapports`, `mes_rapports_en_attente`) → SQL | 27 + 22 tests | M (mission) + L (envoi) | Accorder la capacité de contrôle (`accorder_capacite_controle`, `retirer_capacite_controle`, `c29_control_capabilities.sql:50`) : aucun écran direction |
| D4 | Politique de relecture des pièces selon le genre | `core/capacites/port_politique_revue_kyc.dart:43-64`, `features/admin_configuration_politique_kyc/politique_revue_kyc_page.dart` (onglet caché) | direction | SQL absent | - | M | DEC |
| D5 | Publier une évaluation aux familles | serveur `publier_evaluation`, `changer_affichage_evaluation`, `evaluation_publiee_lignes` (`20261013010000_imm_back_2_evaluation_codes.sql`) sans appel Dart ; `core/admin/service_evaluations.dart` n'appelle que planifier, enregistrer, annuler | direction, famille | C | - | M | Fiche d'écran à écrire |
| D6 | Studio, modération | `features/com_studio/port_studio.dart:342-376`, `port_activite_studio.dart:347` ; `core/communications/moderation.dart:183-217` ; entrée `admin_domaine.dart:154`, `app_router.dart:1855` | direction (page « indisponible ») | SQL + C absents | - | L | Hors boucles |
| D7 | Communications : publier une annonce d'académie | voir « faux d'abord » ; `features/com_annonces/administration_communications_page.dart:200-205`, `port_regles_audience.dart:75` (`ReglesAudienceIndisponibles`, matrice d'audience) | direction | SQL : fonction de capacités + règles d'audience ; C : deux adaptateurs | 9 tests | M | N1 |

## 10. Communications et communauté

| # | Élément | Fichiers | Qui le voit | Pour brancher | Qualité | Taille | Dépendances |
|---|---|---|---|---|---|---|---|
| N1 | Capacités de communication (écrire dans un fil, publier, programmer, vocal) | `core/communications/capacites_communication.dart:86-130` | **tous les rôles** : aucun composer, aucune nouvelle conversation | SQL (petite fonction de capacités par rôle et objet, le serveur reste la barrière ; `com_envoyer_message` existe déjà) + C (adaptateur, surcharge) | 14 tests | M | Priorité haute : bloque les messages de tous |
| N2 | Messages vocaux | `features/com_vocal/port_enregistreur_vocal.dart:180-232`, `envoi_vocal.dart:85` | personne (masqué) | SQL + C + stockage | - | L | N1, hors boucles |
| N3 | Pièces jointes, éléments enregistrés, brouillons | `core/communications/port_pieces_jointes.dart:233`, `port_elements_enregistres.dart:45`, `port_brouillons.dart` (mémoire) | studio, communauté | SQL + C | - | L | Hors boucles |
| N4 | Communauté, garde de promotion | `features/com_communaute/port_communaute.dart:252-532`, `port_garde_promotion.dart:116` | enseignant (masqué) | SQL + C absents | - | L | Hors boucles |

## 11. Notifications

| # | Élément | Fichiers | Qui le voit | Pour brancher | Qualité | Taille | Dépendances |
|---|---|---|---|---|---|---|---|
| NO1 | Liste des notifications | `features/notifications/notifications_supabase_provider.dart:11-25` | tous | **Branché** par repli (le port par défaut `NotificationsIndisponibles`, `core/capacites/port_notifications.dart:288`, est remplacé par `NotificationsSupabase` à la lecture) | - | - | - |
| NO2 | Préférences de notification | `features/compte/preferences_page.dart:81-84` (« Pas encore disponibles dans l'application », ligne fixe) | tuteur | SQL + C ; Web Push décidé le 01/11 (`DECISION-PUSH-2026-11-01.md`) | - | L | DEC (contenu des préférences) |

## 12. Autres (compte, réglages, code mort)

| # | Élément | Fichiers | Qui le voit | Pour brancher | Taille | Remarque |
|---|---|---|---|---|---|---|
| A1 | Langue arabe « Bientôt disponible », fuseau « non disponible », confidentialité inerte | `features/compte/compte_page.dart:124-129`, `:382-395`, `:465-470` | tous (Mon espace, Réglages) | Arabe : `assets/i18n/ar.i18n.json` a 9 903 textes contre 10 565 en français ; DEC (qualité, RTL). Fuseau : `mon_fuseau` est lu (`service_planning.dart`), aucune écriture. Confidentialité : SQL absent | M à L | DEC |
| A2 | Widgets sans aucun usage | `core/mouvement/apparition_douce.dart:74` (`ListeEchelonnee`), `core/widgets/avatar_nom.dart:479` (`AvatarSansImage`), `features/presence_correction/presence_correction_page.dart` (`PresenceCorrectionPage` ; le panneau, lui, est branché dans `cahier_page.dart:1171`), `core/widgets/pastilles_comptable.dart` (`PastilleObligationContractuel`, démo) | personne | Supprimer ou réutiliser | S | DEC (suppression) |
| A3 | Liste tolérée R1 : 34 suppressions proposées (doublons, données de démo hors `features/demo`, interfaces sans usage), 14 moteurs de recherche (D2), 2 écrans adultes (E2, E3) | `tool/branchement_tolere.txt` | - | Voir D2, E2, E3, S5, S6 | - | Échéances 08/11, 15/11, 30/11 |
| A4 | Mushaf 15 lignes | `core/tc_coran/layout_lignes_indisponible.dart` | - | **Branché** (`Env.mushaf15L` vrai par défaut, `env.dart:43-51`) | - | - |
| A5 | Rappel discret, concierge, horloge, groupes | `core/tc_classe/rappel_discret.dart`, `core/tc_groupe/concierge_seance.dart:52-57`, `core/tc_horloge/port_horloge_seance.dart:55-66`, `core/tc_groupe/port_groupes.dart:39-49` | - | **Branchés** (Supabase hors `PLAYGROUND`, forcé à faux en production, `flutter-deploy.yml:133`) | - | - |

---

## Modules en double d'un module branché (NE PAS brancher, le dire au directeur)

| Module non branché | Module branché qui fait déjà la chose |
|---|---|
| `features/salle_seance/signalement_seance.dart` | `fiche_groupe/fiche_eleve_enseignant.dart` (`SignalerBesoin`, `ouvrirSignalement`) + `portSignalementProvider` |
| `features/tc_dock/teaching_dock.dart`, `puce_intention.dart` | `features/salle_seance/barre_outils_salle.dart` |
| `features/tc_flux_academique/*`, `core/tc_parcours/{port_post_cours,post_cours_vm,feedback_memoire,rotation_feedback}.dart` | `features/cahier` (cahier de transmission) |
| `features/tc_catalogue/support_actif/*`, `class_library_picker.dart` | `salle_seance/bibliotheque_seance.dart`, `panneau_bibliotheque_salle.dart` |
| `core/tc_etat_partage/providers_tc_etat_partage.dart` (`portEtatPartageProvider`), `core/tc_realtime` (`TransportIndisponible`) | `EtatPartageSupabase` (`portEtatPartagePersistantProvider`, `main.dart`) et la synchro de la salle |
| `core/capacites/port_resume_seance_famille.dart` (+ SQL `resume_seance_famille`, 0054) | `compte_rendu_famille` (`20261018190000_ped_cahier_partage.sql:651`), branché |
| `core/offres/port_demandes_horaires.dart` (+ SQL anciennes des demandes horaires) | `admin_regroupements`, frise et suivi des demandes (branchés) |
| `core/capacites/port_catalogue_classes.dart`, `creneaux_page.dart` `offresClassesProvider` | Parcours offre puis horaire (DECISION-OFFRES du 09/10) |
| `features/compte/soldes_foyer.dart` | `features/foyer/fiche/finances_page.dart` |

## Fonctions Edge jamais appelées par l'application

| Fonction | Statut | Pour brancher |
|---|---|---|
| `piece-identite-depot`, `piece-identite-confirme` | Non appelées ; dépôt fait dans le seau Supabase `kyc` | R1 (C, M) + DEC + secrets R2 |
| `bibliotheque-lecture` | Non appelée | S1 |
| `recherche-enseignants` | Non appelée, rien dans les migrations | D2 |
| `archive-seance-acces` | Non appelée ; aucun enregistrement réel côté client (arbitrage ouvert, `CLAUDE.md`) | DEC |
| `livekit-webhook`, `stripe-webhook`, `courriels-envoi`, `courriel-desinscription` | Appelées par un tiers (LiveKit, Stripe), par la base (`20261023120000_courriels_sortants.sql`) ou par un lien de courriel : **normal** | - |

## Fonctions SQL sans appel Dart (annexe brute)

Liste produite par machine : fonction créée dans `supabase/migrations`, absente de toute chaîne littérale de `lib/` et de `supabase/functions`. Beaucoup sont des aides internes (gardes, déclencheurs, `app_*`, `x217_*`, `cap29_guard_*`) : **normal**. Celles qui servent un élément ci-dessus y sont citées. Les autres, accordées à `authenticated` et sans usage évident, sont à lire avant toute action :

`accorder_capacite_controle`, `retirer_capacite_controle`, `ma_capacite_controle_active`, `ma_mission_controle`, `demarrer_mission_controle` (D3) ; `pause_*` (S2) ; `ressources_du_groupe` (S1) ; `groupe_roster_enseignant`, `derniere_position_groupe` (C1) ; `rech_d1_*`, `rech_d4_rechercher_reference_finance`, `rechercher_personne_par_matricule` (D2) ; `signalements_ouverts_direction` (D1) ; `deposer_reprise_foyer`, `etat_reprise_foyer`, `refuser_reprise_foyer`, `repondre_invitation_conjoint`, `mon_invitation_en_cours` (FA2, FA3) ; `demander_presentation_standard` (E3) ; `demander_creneau_personnalise`, `etat_creneau_personnalise`, `retirer_creneau_personnalise` (I1) ; `publier_evaluation`, `changer_affichage_evaluation`, `evaluation_publiee_lignes` (D5) ; `decider_tresorerie_*`, `reprendre_alimentation_tresorerie`, `abandonner_reprise_tresorerie` (F1) ; `resume_seance_famille`, `enregistrer_resume_seance` (FA8, doublon) ; `mes_demandes_horaires`, `refuser_demande_horaire`, `retirer_demande_horaire`, `suivi_demandes_horaires_foyer_utc`, `completer_niveau_demande_horaire`, `pool_offre`, `offres_admin`, `classes_a_confirmer_admin`, `eleves_sans_enseignant` (I2) ; à classer : `doit_demander_feedback`, `enseignants_pour`, `enseignants_pour_classe`, `geler_archive_seance`, `maj_eleve_pedagogie`, `peut_poser_disponibilite`, `ses_cloturer_seances_echues_maintenant`, `transitions_fuseau_a_venir`, `video_config_lire`, `lire_demandes_presentation_en_attente` (remplacée par `..._avec_fuseau`, appelée).

Fichier brut complet (210 lignes, colonnes : nom, nombre de références SQL, GRANT authenticated, REVOKE, déclencheur) : `/tmp/claude-0/-home-user-Rewayah-Academy-Official-App/da13279c-7dff-58e4-8640-5ab98c509cf5/scratchpad/fn_unused.txt`.

**Inverse** : aucun appel Dart vers une RPC absente des migrations (183 noms vérifiés).

## Textes « pas encore », « bientôt » réellement affichés en production (hors panne)

| Texte (clé) | Écran | Rôle | Cause |
|---|---|---|---|
| « Bientôt disponible » (`compte.arabeDetail`, `compte.confidentialiteDetail`) | `compte/compte_page.dart:126`, `:384`, `:468` | tous | A1 |
| « Pas encore disponibles dans l'application » (`compte.tuteur.pagePreferences.notificationsDetail`) | `compte/preferences_page.dart:84` | tuteur | NO2 |
| « Suivre vous-même les cours … sera proposé prochainement » (`foyer.monProfil.*`, `adulte.famille.monProfilIndisponible*`) | `foyer/creer_mon_profil_indisponible.dart` | tuteur | FA5 |
| « Pas encore disponible » couleur (`ficheEleve.lignes.couleurIndisponible`) | `foyer/fiche_eleve_page.dart` | tuteur | FA6 |
| « La bibliothèque de la classe n'est pas encore reliée » (`classe.pageRessources.indisponible`) | `classe_tuteur/ressources_classe_page.dart` | tuteur | S1 |
| « Les cartes de la classe ne sont pas encore ouvertes » (`classe.cartes.indisponibleTitre`) | `tc_espace_groupe/bloc_cartes_classe.dart` | tuteur, élève, enseignant | S4 |
| « Bientôt disponible / rattaché prochainement » (`tc.groupe.emplacement.nonBranche*`) | `tc_espace_groupe/emplacements_groupe.dart` (`EmplacementNonBranche`) | tuteur, enseignant | C1, C2 |
| « Le parcours, les objectifs … ne sont pas encore ouverts à l'enseignant » (`tc.classe.fiche.sansPedagogieDetail`) | `salle/fiche_seance.dart` | enseignant | C1 |
| « Les alertes ne sont pas encore disponibles » (`alertes.indisponibleTitre`) | `alertes/section_alertes.dart` | direction | D1 |
| « Pas encore disponible / Cette fonction n'est pas encore disponible ici » (`com.socle.composants.etats.*`) | `com_annonces/administration_communications_page.dart`, `file_moderation.dart` | direction | D6, D7 |
| Page pause « indisponible » | `fiche_groupe/bloc_pause_classe.dart:154-160` | enseignant | S2 |
| Pages comptable (`comptable.*.erreurIndisponible`, `comptable.direction.enregistrementIndisponible`) | `comptable/**`, `paiements_recus/recevoir_paiements_page.dart`, `admin_finance/reserve_delegation/composants_politique.dart` | comptable, direction, enseignant | F1-F6 |

Les autres textes (« La salle n'est pas encore disponible », « Votre professeur n'est pas encore arrivé », « non confirmé », états de panne) décrivent un état réel ou une panne, pas un manque de branchement.

## Inconnu ou non vérifiable

- **Installation des migrations sur la base distante** (notamment `0035`, et toutes celles du 02 au 04/11) : aucun accès Supabase par consigne. Le document du 24/10 dit 262/262 appliquées à cette date ; rien n'est prouvé depuis.
- **Secrets R2 en production** (`stockageConfigure('supports')`, `stockageConfigure` pour le coffre d'identité) : inconnu, conditionne S1 et R1.
- **Droit de l'enseignant d'écrire `teacher_profiles.photo_storage_key`** (EN1) : politique RLS non relue.
- **Lecture non-direction du catalogue** (`tous`, `récents`, `dernière lecture` de S1) : `20261011112954_cap29_library_visibility.sql` et `20261011113000_cap29_group_scope_via_existing_views.sql` ne créent aucune fonction ; s'ils posent des politiques RLS de lecture directe, une lecture par table est possible. Non relu.
- **Envoi du compte rendu du contrôleur** (D3) : aucune fonction d'envoi trouvée par nom ; une écriture directe sous RLS n'a pas été cherchée.
- **Résultat des tests** : aucun `flutter test` lancé ; « tests présents » ne veut pas dire « verts ».
- **Faux positifs possibles** de l'annexe SQL : un nom construit dynamiquement côté Dart (concaténation) ne serait pas vu. Aucun cas trouvé, mais non exclu.
- **Push Web** (DECISION-PUSH du 01/11) : aucun code de service worker relu ; état inconnu.
