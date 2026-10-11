# BR1-CARTE : carte du branchement serveur (préparation du 15/10/2026)

Statut de preuve : `présent dans le code` (lecture du code de `ccr-1b1bfa0b-m1kvkk` @ 744dac49, le 10/10/2026).
Rien n'est `testé sur staging` ni `déployé` ici. Ce document ne câble rien : il inventorie.

## 0. Ce que ce relevé ne sait pas

- **L'onglet Contrats n'est pas consultable depuis le dépôt** (la feuille de liaison de `COHABITATION.md` est hors dépôt). La colonne « Contrat » ne
  reprend donc que les identifiants `C-xx` écrits dans le fichier du port lui-même. « CONTRAT NON RETROUVÉ » veut dire : aucun `C-xx` dans le fichier
  du port, pas que le contrat n'existe pas. À confirmer ligne par ligne dans l'onglet.
- Les « écrans qui le lisent » viennent d'une recherche de texte (nom du provider ou du type du port) dans `lib/`, hors `features/demo` et `features/_dev`.
  C'est un bon repère, pas une analyse de flux : un écran qui passe par un intermédiaire peut manquer.
- Le rôle de rangement est le rôle dominant des dossiers qui lisent le port. Un port lu par plusieurs rôles figure une seule fois, dans le rôle dominant.
- Les adaptateurs des branches `codex/*` sont ceux présents dans l'arbre de la branche au 10/10 (nom de classe, branche, SHA). Aucune n'a été fusionnée ni testée ici.

## 1. Comment la production branche aujourd'hui

- `lib/main.dart` ne surcharge que : `portClassesFoyerProvider` (adaptateur Supabase), `surchargeRevueDossiersProduction` et, pour l'observation par un agent, `sourceSessionProvider`.
- Les trente et quelques `Service*` (auth, dossier, planning, admin, appairage, coran, etc.) ont par défaut leur implémentation Supabase : ils sont réels en production.
- Les ports `Port*` sont autre chose : leur provider par défaut est, selon le cas, `null` (l'écran se vide), `*Indisponible` (état « indisponible »), une mémoire non persistante, ou
  **lève `UnimplementedError`**. Seuls 16 ports ont un adaptateur réel par défaut (voir § 3, état « branché »).
- Les classes `*Demo`, `*Demonstration`, `*Memoire`, `*Fixtures` ne sont installées que par les surcharges de `lib/features/demo/**` et de `_dev/**`.

## 2. La démonstration peut-elle s'allumer en production ? (constat, sans modification)

Constat : **non, par construction, mais la garantie repose sur la valeur de `ENVIRONNEMENT` injectée par le workflow, qu'aucun test ne rejoue sur le workflow lui-même.**

1. `environnementAutoriseDemo` (`lib/features/demo/mode_demonstration.dart:103`) refuse si l'environnement contient `prod`, s'il est vide, ou si la compilation est de publication (`kReleaseMode`) sans `ENVIRONNEMENT` déclaré (`Env.environnementDeclare`, DEMO-ENV-1).
2. `flutter-deploy.yml` passe `ENVIRONNEMENT=production` pour `main` hors pull request, `staging` sinon, plus `GALERIE=false`, `PLAYGROUND=false`, `AUTH_PAR_MOT_DE_PASSE=false`. Ces trois bascules valent aussi `false` par défaut (`lib/core/config/env.dart`).
3. Chaque route de démonstration (`demo_*_page.dart`, 11 fichiers) retourne une liste vide si la garde refuse ; la porte sans session de `lib/core/router/redirection.dart:57` est sous la même garde ; `?demo=tuteur` et `?demo=admin` (`main.dart`) aussi, et leurs fonctions de surcharge lèvent une `StateError` hors environnement autorisé.
4. Test : `test/features/demo/mode_demonstration_test.dart` rejoue la garde (publication avec et sans `ENVIRONNEMENT`, valeurs `production`, `Production`, vide).
5. À noter : **les aperçus de pull request (`staging`) ouvrent toutes les démonstrations, par conception.** Seul `main` les ferme. Et un build de publication fait à la main sans `--dart-define=ENVIRONNEMENT=…` les ferme aussi (c'est voulu).
6. Deux ports restent en mémoire **sans passer par la garde**, dans la production réelle : `PortEtatPartagePersistant` (`EtatPartageMemoire`) et `PortPositionDock` (`PositionDockMemoire`). Ce n'est pas de la démonstration visible, mais les données ne survivent pas à la session.
7. **Corrigé par SALLE-ROBUSTE (10/10 soir)** : les cinq ports qui levaient `UnimplementedError` par défaut (`PortAnnotations`, `PortAssignations`, `PortFeedback`, `PortSignalement`, `PortPostCours`) rendent maintenant une implémentation « indisponible » (`AnnotationsIndisponibles`, `AssignationsIndisponibles`, `FeedbackIndisponible`, `SignalementIndisponible`, `PostCoursIndisponible`, toutes marquées `PortIndisponible`). Lectures vides ou `null`, écritures qui lèvent `FonctionIndisponible` (`lib/core/tc_outils/fonction_indisponible.dart`) ; les écrans la disent (`t.tc.indisponible`) : le dock ne propose plus Marquer, Révision et Stylet, la feuille de signalement n'affiche plus son bouton, le panneau post-cours dit la limite sans bouton « réessayer », la carte de feedback n'affiche rien. Preuve : `test/teaching_core/salle_robuste_test.dart` (12 tests, dont 5 d'écran rouges sans la correction d'interface). L'état de cette ligne dans le tableau du § 3 reste « prêt à brancher » ou « adaptateur manquant » : seul le défaut a changé.
8. **`PortEtatPartagePersistant` et `PortPositionDock` : pas de fuite en production, relevé du 10/10.** Les deux implémentations par défaut (`EtatPartageMemoire`, `PositionDockMemoire`) sont des cartes en mémoire du processus : aucune importation de stockage, de réseau ni de journal, rien d'écrit sur disque, rien d'envoyé. Elles disparaissent au rechargement de la page. Corrigé ensuite (11/10) : `SessionControleur` oublie cette mémoire (`memoiresDeSalle` : état partagé, position du dock, outils, file de récitation, page de lecture, cadence des rappels) dès que l'identifiant du profil change, déconnexion comme autre compte ; test `test/teaching_core/memoire_par_compte_test.dart`. Reste vrai : l'état partagé d'une séance n'est pas durable, un rechargement le perd. Aucun branchement n'est modifié.

## 3. Ports par rôle

### Famille (tuteur, foyer) (26 ports)

| Port | Provider de production actuel | Adaptateur réel | Contrat | État | Écrans qui le lisent |
| :--- | :--- | :--- | :--- | :--- | :--- |
| `PortCatalogueClasses` | portCatalogueClassesProvider: Indisponible | aucun sur ccr ni codex/* | C-14 | ADAPTATEUR MANQUANT (Codex) | classe_tuteur |
| `PortFriseDemandes` | portFriseDemandesProvider: null (écran vide) | aucun sur ccr ni codex/* | C-20 | ADAPTATEUR MANQUANT (Codex) | suivi_famille |
| `PortReponsePresentation` | portReponsePresentationProvider: null (écran vide) | aucun sur ccr ni codex/* | C-22 | ADAPTATEUR MANQUANT (Codex) | presentation_tuteur |
| `PortSignatureContrat` | portSignatureContratProvider: null (écran vide) | aucun sur ccr ni codex/* | C-15, C-16 | ADAPTATEUR MANQUANT (Codex) | dossier, recrutement |
| `PortVerificationInvitation` | portVerificationInvitationProvider: null (écran vide) | aucun sur ccr ni codex/* | C-13, C-14 | ADAPTATEUR MANQUANT (Codex) | inscription/etapes, recrutement |
| `PortClassesFoyer` | portClassesFoyerProvider: Indisponible | main.dart (surcharge _surchargesAppReelle) | C-12 | branché | accueil_famille, classe_tuteur, foyer, tc_observation_ui |
| `PortConsentements` | consentementsLotAProvider: adaptateur réel, portConsentementsProvider: service/local | défaut du provider (ConsentementsSupabase) | — | branché | consentements, core:capacites |
| `PortCreationProfilEleve` | portCreationProfilEleveProvider: service/local | défaut : ServiceAppairage | — | branché | foyer, core:foyer |
| `PortSeancesFamille` | portSeancesFamilleProvider: service/local | défaut : ServicePlanning | — | branché | accueil_famille, classe_tuteur |
| `PortStatutCodeAppairage` | portStatutCodeAppairageProvider: adaptateur réel | défaut du provider | — | branché | appareils |
| `PortAccentsProfils` | portAccentsProfilsProvider: Indisponible | aucun sur ccr ni codex/* | — | CONTRAT NON RETROUVÉ | foyer/fiche |
| `PortAccesFoyer` | portAccesFoyerProvider: Indisponible | aucun sur ccr ni codex/* | — | CONTRAT NON RETROUVÉ | compte, core:capacites, core:finance |
| `PortMesFinances` | portMesFinancesProvider: Indisponible | aucun sur ccr ni codex/* | — | CONTRAT NON RETROUVÉ | acces_finance, mon_espace_adulte, core:capacites |
| `PortMonAcces` | portMonAccesProvider: Indisponible | aucun sur ccr ni codex/* | — | CONTRAT NON RETROUVÉ | acces_finance, accueil_eleve |
| `PortPaiementsFoyer` | portPaiementsFoyerProvider: Indisponible | aucun sur ccr ni codex/* | — | CONTRAT NON RETROUVÉ | compte, foyer, foyer/fiche, mon_espace_adulte, core:capacites |
| `PortPolitiquesCommerciales` | portPolitiquesCommercialesProvider: Indisponible | aucun sur ccr ni codex/* | — | CONTRAT NON RETROUVÉ | admin_finance, foyer |
| `PortRechargeFoyer` | portRechargeFoyerProvider: Indisponible | aucun sur ccr ni codex/* | — | CONTRAT NON RETROUVÉ | foyer, core:capacites |
| `PortRecus` | portRecusProvider: Indisponible | aucun sur ccr ni codex/* | — | CONTRAT NON RETROUVÉ | foyer/fiche |
| `PortCatalogue` | portCatalogueProvider: service/local | — | — | local | classe_tuteur, tc_espace_groupe, core:tc_bibliotheque, core:tc_groupe |
| `PortHistoriqueObservations` | portHistoriqueObservationsProvider: Indisponible | HistoriqueObservationsSupabase (ccr), non câblé | — | PRÊT À BRANCHER | suivi_foyer |
| `PortIdentiteTitulaire` | portIdentiteTitulaireProvider: Indisponible | IdentiteTitulaireSupabase (ccr), non câblé | — | PRÊT À BRANCHER | compte |
| `PortAssignations` | assignationsFamilleProvider: null (écran vide), portAssignationsProvider: Indisponible typé (SALLE-ROBUSTE, ne lève plus) | AssignationsSupabase · backend-f2-b13-admin-rls@00601b47 | — | PRÊT À BRANCHER (fusion codex) | classe_tuteur, tc_dock, core:tc_outils, core:tc_parcours |
| `PortProfilEleveTitulaire` | portProfilEleveTitulaireProvider: Indisponible | ProfilEleveTitulaireSupabase · backend-adult-kyc-contract@7afc8a2b | — | PRÊT À BRANCHER (fusion codex) | compte, foyer |
| `PortProgressionFamille` | portProgressionFamilleProvider: Indisponible | ProgressionFamilleSupabase · backend-adult-kyc-contract@7afc8a2b | — | PRÊT À BRANCHER (fusion codex) | classe_tuteur |
| `PortSuiviDemandes` | portSuiviDemandesProvider: null (écran vide) | PortSuiviDemandesSupabase · backend-offres-adapters@392fe0c5 | C-05, C-10 bis | PRÊT À BRANCHER (fusion codex) | suivi_demandes |
| `PortSupport` | portSupportProvider: Indisponible | SupportSupabase · backend-f2-after-c@b6440e9f | — | PRÊT À BRANCHER (fusion codex) | compte |

### Élève (1 ports)

| Port | Provider de production actuel | Adaptateur réel | Contrat | État | Écrans qui le lisent |
| :--- | :--- | :--- | :--- | :--- | :--- |
| `PortNavigationCoran` | portNavigationCoranProvider: service/local | — | — | local | accueil_eleve, tc_mushaf, core:tc_coran |

### Enseignant (18 ports)

| Port | Provider de production actuel | Adaptateur réel | Contrat | État | Écrans qui le lisent |
| :--- | :--- | :--- | :--- | :--- | :--- |
| `PortCorpusCoran` | portCorpusCoranProvider: service/local | défaut : ServiceCoran | — | branché | cahier, core:tc_coran |
| `PortHorlogeSeance` | portHorlogeSeanceProvider: service/local | défaut du provider (HorlogeSeanceSupabase, hors PLAYGROUND) | — | branché | tc_classe_live, core:tc_groupe, core:tc_horloge |
| `PortPolitiqueObservation` | portPolitiqueObservationProvider: adaptateur réel | défaut du provider | — | branché | admin_groupes, tc_observation_ui, core:tc_observation |
| `PortRosterEnseignant` | portRosterEnseignantProvider: adaptateur réel | défaut du provider (RosterEnseignantSupabase) | — | branché | tc_espace_groupe, core:tc_classe, core:tc_groupe, core:tc_parcours |
| `PortAgeEleve` | portAgeEleveProvider: service/local (valeur « inconnue » par défaut) | aucun sur ccr ni codex/* | — | CONTRAT NON RETROUVÉ | salle, tc_classe_live |
| `PortCartesClasse` | portCartesClasseProvider: Indisponible | aucun sur ccr ni codex/* | — | CONTRAT NON RETROUVÉ | tc_espace_groupe |
| `PortLayoutMushaf` | portLayoutMushafProvider: Indisponible | aucun sur ccr ni codex/* | — | CONTRAT NON RETROUVÉ | tc_classe_live, tc_mushaf, core:tc_coran |
| `PortMesMoyensPaiement` | portMesMoyensPaiementProvider: Indisponible | aucun sur ccr ni codex/* | — | CONTRAT NON RETROUVÉ | paiements_recus |
| `PortRemplacements` | portRemplacementsProvider: null (écran vide) | aucun sur ccr ni codex/* | — | CONTRAT NON RETROUVÉ | remplacements, core:offres |
| `PortRevenusEnseignant` | portRevenusEnseignantProvider: Indisponible | aucun sur ccr ni codex/* | — | CONTRAT NON RETROUVÉ | revenus_enseignant |
| `PortTravailAVenir` | portTravailAVenirProvider: null (écran vide) | aucun sur ccr ni codex/* | — | CONTRAT NON RETROUVÉ | tc_espace_groupe, tc_flux_academique, core:tc_groupe |
| `PortEnregistrementFichier` | portEnregistrementFichierProvider: service/local | — | — | local | tc_catalogue |
| `PortEtatOffline` | portEtatOfflineProvider: service/local | — | — | local | tc_catalogue, core:tc_parcours, core:tc_telechargement |
| `PortPostCours` | portPostCoursProvider: Indisponible typé (SALLE-ROBUSTE, ne lève plus) | — | — | local | tc_flux_academique |
| `PortRappelDiscret` | portRappelDiscretProvider: service/local | — | — | local | tc_classe_live, core:tc_classe, core:tc_realtime, core:video |
| `PortAnnotations` | portAnnotationsProvider: Indisponible typé (SALLE-ROBUSTE, ne lève plus) | AnnotationsSupabase · backend-f2-b13-admin-rls@00601b47 | — | PRÊT À BRANCHER (fusion codex) | tc_dock |
| `PortFeedback` | portFeedbackProvider: Indisponible typé (SALLE-ROBUSTE, ne lève plus) | FeedbackSupabase · backend-f2-after-c@b6440e9f | — | PRÊT À BRANCHER (fusion codex) | tc_flux_academique, core:tc_parcours |
| `PortSignalement` | portSignalementProvider: Indisponible typé (SALLE-ROBUSTE, ne lève plus) | SignalementSupabase · backend-f2-b13-admin-rls@00601b47 | — | PRÊT À BRANCHER (fusion codex) | tc_classe_live, tc_flux_academique, core:communications |

### Contrôleur (2 ports)

| Port | Provider de production actuel | Adaptateur réel | Contrat | État | Écrans qui le lisent |
| :--- | :--- | :--- | :--- | :--- | :--- |
| `PortEchanges` | portEchangesProvider: Indisponible | aucun sur ccr ni codex/* | — | CONTRAT NON RETROUVÉ | controleur |
| `PortHistorique` | portHistoriqueProvider: Indisponible | aucun sur ccr ni codex/* | — | CONTRAT NON RETROUVÉ | controleur |

### Comptable (9 ports)

| Port | Provider de production actuel | Adaptateur réel | Contrat | État | Écrans qui le lisent |
| :--- | :--- | :--- | :--- | :--- | :--- |
| `PortAujourdhuiComptable` | portAujourdhuiComptableProvider: Indisponible | aucun sur ccr ni codex/* | — | CONTRAT NON RETROUVÉ | comptable/aujourdhui |
| `PortBeneficiairesPaiement` | portBeneficiairesPaiementProvider: Indisponible | aucun sur ccr ni codex/* | — | CONTRAT NON RETROUVÉ | comptable/beneficiaires |
| `PortEncaissements` | portEncaissementsProvider: Indisponible | aucun sur ccr ni codex/* | — | CONTRAT NON RETROUVÉ | comptable/encaissements, comptable/encaissements/rapprochement |
| `PortObligationsContractuels` | portObligationsContractuelsProvider: Indisponible | aucun sur ccr ni codex/* | — | CONTRAT NON RETROUVÉ | comptable/contractuels |
| `PortObligationsPayables` | portObligationsPayablesProvider: Indisponible | aucun sur ccr ni codex/* | — | CONTRAT NON RETROUVÉ | comptable/paiements, comptable/paiements/confirmation |
| `PortPayout` | portPayoutProvider: Indisponible | aucun sur ccr ni codex/* | — | CONTRAT NON RETROUVÉ | comptable/paiements/confirmation |
| `PortRapprochement` | portRapprochementProvider: Indisponible | aucun sur ccr ni codex/* | — | CONTRAT NON RETROUVÉ | comptable/encaissements, comptable/encaissements/rapprochement |
| `PortRelancePaiement` | portRelancePaiementProvider: Indisponible | aucun sur ccr ni codex/* | — | CONTRAT NON RETROUVÉ | comptable/beneficiaires |
| `PortTresorerie` | portTresorerieProvider: Indisponible | aucun sur ccr ni codex/* | — | CONTRAT NON RETROUVÉ | comptable/tresorerie, comptable/tresorerie/transfert |

### Administration et direction (14 ports)

| Port | Provider de production actuel | Adaptateur réel | Contrat | État | Écrans qui le lisent |
| :--- | :--- | :--- | :--- | :--- | :--- |
| `PortAccesPiecesKyc` | portAccesPiecesKycProvider: null (écran vide) | aucun sur ccr ni codex/* | C-21 | ADAPTATEUR MANQUANT (Codex) | admin_dossiers |
| `PortInvitationsEnseignant` | portInvitationsEnseignantProvider: null (écran vide) | aucun sur ccr ni codex/* | C-13, C-14 | ADAPTATEUR MANQUANT (Codex) | admin_invitations |
| `PortReprisesAdmin` | portReprisesAdminProvider: null (écran vide) | aucun sur ccr ni codex/* | C-23 | ADAPTATEUR MANQUANT (Codex) | admin_reprises |
| `PortCreationClasse` | portCreationClasseProvider: service/local | défaut : ServiceGroupes | — | branché | admin_groupes |
| `PortDelegationFinance` | portDelegationFinanceProvider: Indisponible | aucun sur ccr ni codex/* | — | CONTRAT NON RETROUVÉ | admin_finance, admin_finance/reserve_delegation |
| `PortFinanceDirection` | portFinanceDirectionProvider: Indisponible | aucun sur ccr ni codex/* | — | CONTRAT NON RETROUVÉ | admin_finance |
| `PortFusionClasses` | portFusionClassesProvider: null (écran vide) | aucun sur ccr ni codex/* | — | CONTRAT NON RETROUVÉ | admin_fusion |
| `PortPolitiqueReserve` | portPolitiqueReserveProvider: Indisponible | aucun sur ccr ni codex/* | — | CONTRAT NON RETROUVÉ | admin_finance, admin_finance/reserve_delegation, comptable/tresorerie |
| `PortPolitiqueRevueKyc` | portPolitiqueRevueKycProvider: Indisponible | aucun sur ccr ni codex/* | — | CONTRAT NON RETROUVÉ | admin_configuration_politique_kyc |
| `PortRevueDossiers` | portRevueDossiersProvider: Indisponible | aucun sur ccr ni codex/* | — | CONTRAT NON RETROUVÉ | admin_dossiers, core:capacites, core:recrutement |
| `PortTirageControle` | portTirageControleProvider: null (écran vide) | aucun sur ccr ni codex/* | — | CONTRAT NON RETROUVÉ | admin_tirage |
| `PortValidationsFinance` | portValidationsFinanceProvider: Indisponible | aucun sur ccr ni codex/* | — | CONTRAT NON RETROUVÉ | admin_finance, admin_finance/a_valider, comptable/validation |
| `PortHistoriqueObservationsAdmin` | portHistoriqueObservationsAdminProvider: Indisponible | HistoriqueObservationsAdminSupabase (ccr), non câblé | — | PRÊT À BRANCHER | admin_observations |
| `PortRegroupementsAdmin` | portRegroupementsAdminProvider: null (écran vide) | RegroupementsAdminSupabase · backend-f2-after-c@b6440e9f | C-11 bis | PRÊT À BRANCHER (fusion codex) | admin_regroupements, core:offres |

### Transversal (communications, salle, Teaching Core, session) (45 ports)

| Port | Provider de production actuel | Adaptateur réel | Contrat | État | Écrans qui le lisent |
| :--- | :--- | :--- | :--- | :--- | :--- |
| `PortStatutsSignature` | portStatutsSignatureProvider: null (écran vide) | aucun sur ccr ni codex/* | C-17 | ADAPTATEUR MANQUANT (Codex) | — |
| `PortAnnonceObservation` | portAnnonceObservationProvider: adaptateur réel | défaut du provider | — | branché | — |
| `PortAnnonceObservationEnfant` | portAnnonceObservationEnfantProvider: adaptateur réel | défaut du provider | — | branché | — |
| `PortEtatPartage` | portEtatPartageCoranProvider: null (écran vide), portEtatPartageProvider: service/local | défaut : ServiceEtatPartage sur le temps réel | — | branché | core:tc_coran, core:tc_etat_partage, core:tc_parcours |
| `PortGroupes` | portGroupesProvider: service/local | défaut du provider (GroupesSupabase, hors PLAYGROUND) | — | branché | core:tc_groupe |
| `PortRealtimePedagogique` | portRealtimePedagogiqueProvider: service/local | défaut : service temps réel | — | branché | core:tc_classe, core:tc_etat_partage, core:tc_outils, core:tc_realtime |
| `PortVisiteObservation` | portVisiteObservationProvider: adaptateur réel | défaut du provider | — | branché | core:tc_observation |
| `PortAccueilAccessibilite` | portAccueilAccessibiliteProvider: Indisponible | aucun sur ccr ni codex/* | — | CONTRAT NON RETROUVÉ | — |
| `PortActiviteStudio` | portActiviteStudioProvider: Indisponible | aucun sur ccr ni codex/* | — | CONTRAT NON RETROUVÉ | com_studio |
| `PortAlertes` | portAlertesProvider: Indisponible | aucun sur ccr ni codex/* | — | CONTRAT NON RETROUVÉ | — |
| `PortAnnonces` | portAnnoncesProvider: Indisponible | aucun sur ccr ni codex/* | — | CONTRAT NON RETROUVÉ | com_annonces, notifications |
| `PortCapacitePayout` | portCapacitePayoutProvider: Indisponible | aucun sur ccr ni codex/* | — | CONTRAT NON RETROUVÉ | — |
| `PortCapacitesCommunications` | portCapacitesCommunicationsProvider: Indisponible | aucun sur ccr ni codex/* | — | CONTRAT NON RETROUVÉ | — |
| `PortClassesAdmin` | portClassesAdminProvider: null (écran vide) | aucun sur ccr ni codex/* | — | CONTRAT NON RETROUVÉ | — |
| `PortCommunaute` | portCommunauteProvider: Indisponible | aucun sur ccr ni codex/* | — | CONTRAT NON RETROUVÉ | com_communaute |
| `PortDemandePresentation` | aucun provider | aucun sur ccr ni codex/* | — | CONTRAT NON RETROUVÉ | — |
| `PortElementsEnregistres` | portElementsEnregistresProvider: Indisponible | aucun sur ccr ni codex/* | — | CONTRAT NON RETROUVÉ | com_communaute, com_studio |
| `PortEnregistreurVocal` | portEnregistreurVocalProvider: Indisponible | aucun sur ccr ni codex/* | — | CONTRAT NON RETROUVÉ | com_vocal |
| `PortEnvoiVocal` | portEnvoiVocalProvider: Indisponible | aucun sur ccr ni codex/* | — | CONTRAT NON RETROUVÉ | com_messages, com_studio |
| `PortGardePromotion` | portGardePromotionProvider: Indisponible | aucun sur ccr ni codex/* | — | CONTRAT NON RETROUVÉ | com_communaute |
| `PortLectureNotifications` | aucun provider | aucun sur ccr ni codex/* | — | CONTRAT NON RETROUVÉ | — |
| `PortLectureVocale` | portLectureVocaleProvider: Indisponible | aucun sur ccr ni codex/* | — | CONTRAT NON RETROUVÉ | com_vocal |
| `PortMessagesMetier` | portMessagesMetierProvider: Indisponible | aucun sur ccr ni codex/* | — | CONTRAT NON RETROUVÉ | com_messages, core:capacites |
| `PortModeration` | portModerationProvider: Indisponible | aucun sur ccr ni codex/* | — | CONTRAT NON RETROUVÉ | com_annonces, com_communaute |
| `PortPilotage` | portPilotageProvider: null (écran vide) | aucun sur ccr ni codex/* | — | CONTRAT NON RETROUVÉ | — |
| `PortPolitiquePiecesJointes` | portPolitiquePiecesJointesProvider: Indisponible | aucun sur ccr ni codex/* | — | CONTRAT NON RETROUVÉ | core:widgets |
| `PortPositionDock` | portPositionDockProvider: mémoire (non persistante) | aucun sur ccr ni codex/* | — | CONTRAT NON RETROUVÉ | — |
| `PortPreferencesPersistantes` | portPreferencesPersistantesProvider: Indisponible | aucun sur ccr ni codex/* | — | CONTRAT NON RETROUVÉ | core:comptable |
| `PortReglesAudience` | portReglesAudienceProvider: Indisponible | aucun sur ccr ni codex/* | — | CONTRAT NON RETROUVÉ | com_annonces |
| `PortRegroupementsPages` | portRegroupementsPagesProvider: null (écran vide) | aucun sur ccr ni codex/* | — | CONTRAT NON RETROUVÉ | — |
| `PortRepriseFoyer` | portRepriseFoyerProvider: Indisponible | aucun sur ccr ni codex/* | — | CONTRAT NON RETROUVÉ | — |
| `PortSortieForfait` | portSortieForfaitProvider: Indisponible | aucun sur ccr ni codex/* | — | CONTRAT NON RETROUVÉ | — |
| `PortStudio` | portStudioProvider: Indisponible | aucun sur ccr ni codex/* | — | CONTRAT NON RETROUVÉ | com_studio |
| `PortBrouillons` | portBrouillonsProvider: service/local | — | — | local | com_communaute, com_studio, core:communications, core:widgets |
| `PortSessionPersistante` | portSessionPersistanteProvider: service/local | — | — | local | core:tc_classe |
| `PortTelechargement` | portTelechargementProvider: service/local | — | — | local | core:tc_bibliotheque, core:tc_telechargement |
| `PortVersionsRessource` | portVersionsRessourceProvider: service/local | — | — | local | core:tc_bibliotheque |
| `PortTransportDonnees` | portTransportDonneesProvider: Indisponible | AdaptateurTransportLiveKit (ccr), non câblé | — | PRÊT À BRANCHER | core:tc_etat_partage, core:tc_realtime |
| `PortCapaciteEleve` | portCapaciteEleveProvider: service/local (valeur « inconnue » par défaut) | PortCapaciteEleveSupabase · backend-adult-kyc-contract@7afc8a2b | C-24 | PRÊT À BRANCHER (fusion codex) | core:session |
| `PortEnseignantsClasse` | portEnseignantsClasseProvider: Indisponible | EnseignantsClasseSupabase · backend-f2-after-c@b6440e9f | — | PRÊT À BRANCHER (fusion codex) | core:admin |
| `PortEtatPartagePersistant` | portEtatPartagePersistantProvider: mémoire (non persistante) | EtatPartageSupabase · backend-f2-b13-admin-rls@00601b47 | — | PRÊT À BRANCHER (fusion codex) | core:tc_etat_partage |
| `PortInvitationConjoint` | portInvitationConjointProvider: Indisponible | InvitationConjointSupabase · backend-f2-after-c@b6440e9f | — | PRÊT À BRANCHER (fusion codex) | — |
| `PortNotifications` | portNotificationsProvider: Indisponible | NotificationsSupabase · backend-notifications@af26dd62 | — | PRÊT À BRANCHER (fusion codex) | notifications |
| `PortReponseInvitation` | portReponseInvitationProvider: Indisponible | ReponseInvitationSupabase · backend-f2-after-c@b6440e9f | — | PRÊT À BRANCHER (fusion codex) | — |
| `PortResumeSeanceFamille` | portResumeSeanceFamilleProvider: Indisponible | ResumeSeanceFamilleSupabase · backend-adult-kyc-contract@7afc8a2b | — | PRÊT À BRANCHER (fusion codex) | — |

## 4. Écrans qui resteraient en démonstration (ou vides) si on branchait aujourd'hui

Un écran figure ici dès qu'un de ses ports n'est ni branché ni local : il affiche alors l'état « indisponible », un écran vide (`null`), une mémoire non persistante, ou lève `UnimplementedError`. Une seule ligne par dossier de `lib/features/`.

| Écran (dossier) | Ports non branchés |
| :--- | :--- |
| `acces_finance` | PortMesFinances, PortMonAcces |
| `accueil_eleve` | PortMonAcces |
| `admin_configuration_politique_kyc` | PortPolitiqueRevueKyc |
| `admin_dossiers` | PortAccesPiecesKyc, PortRevueDossiers |
| `admin_finance` | PortDelegationFinance, PortFinanceDirection, PortPolitiqueReserve, PortPolitiquesCommerciales, PortValidationsFinance |
| `admin_finance/a_valider` | PortValidationsFinance |
| `admin_finance/reserve_delegation` | PortDelegationFinance, PortPolitiqueReserve |
| `admin_fusion` | PortFusionClasses |
| `admin_invitations` | PortInvitationsEnseignant |
| `admin_observations` | PortHistoriqueObservationsAdmin |
| `admin_regroupements` | PortRegroupementsAdmin |
| `admin_reprises` | PortReprisesAdmin |
| `admin_tirage` | PortTirageControle |
| `classe_tuteur` | PortAssignations, PortCatalogueClasses, PortProgressionFamille |
| `com_annonces` | PortAnnonces, PortModeration, PortReglesAudience |
| `com_communaute` | PortCommunaute, PortElementsEnregistres, PortGardePromotion, PortModeration |
| `com_messages` | PortEnvoiVocal, PortMessagesMetier |
| `com_studio` | PortActiviteStudio, PortElementsEnregistres, PortEnvoiVocal, PortStudio |
| `com_vocal` | PortEnregistreurVocal, PortLectureVocale |
| `comptable/aujourdhui` | PortAujourdhuiComptable |
| `comptable/beneficiaires` | PortBeneficiairesPaiement, PortRelancePaiement |
| `comptable/contractuels` | PortObligationsContractuels |
| `comptable/encaissements` | PortEncaissements, PortRapprochement |
| `comptable/encaissements/rapprochement` | PortEncaissements, PortRapprochement |
| `comptable/paiements` | PortObligationsPayables |
| `comptable/paiements/confirmation` | PortObligationsPayables, PortPayout |
| `comptable/tresorerie` | PortPolitiqueReserve, PortTresorerie |
| `comptable/tresorerie/transfert` | PortTresorerie |
| `comptable/validation` | PortValidationsFinance |
| `compte` | PortAccesFoyer, PortIdentiteTitulaire, PortPaiementsFoyer, PortProfilEleveTitulaire, PortSupport |
| `controleur` | PortEchanges, PortHistorique |
| `dossier` | PortSignatureContrat |
| `foyer` | PortPaiementsFoyer, PortPolitiquesCommerciales, PortProfilEleveTitulaire, PortRechargeFoyer |
| `foyer/fiche` | PortAccentsProfils, PortPaiementsFoyer, PortRecus |
| `inscription/etapes` | PortVerificationInvitation |
| `mon_espace_adulte` | PortMesFinances, PortPaiementsFoyer |
| `notifications` | PortAnnonces, PortNotifications |
| `paiements_recus` | PortMesMoyensPaiement |
| `presentation_tuteur` | PortReponsePresentation |
| `recrutement` | PortSignatureContrat, PortVerificationInvitation |
| `remplacements` | PortRemplacements |
| `revenus_enseignant` | PortRevenusEnseignant |
| `salle` | PortAgeEleve |
| `suivi_demandes` | PortSuiviDemandes |
| `suivi_famille` | PortFriseDemandes |
| `suivi_foyer` | PortHistoriqueObservations |
| `tc_classe_live` | PortAgeEleve, PortLayoutMushaf, PortSignalement |
| `tc_dock` | PortAnnotations, PortAssignations |
| `tc_espace_groupe` | PortCartesClasse, PortTravailAVenir |
| `tc_flux_academique` | PortFeedback, PortSignalement, PortTravailAVenir |
| `tc_mushaf` | PortLayoutMushaf |

## 5. Les dix manques les plus bloquants pour le lancement

Classés par ce qui empêche un parcours réel de bout en bout (famille inscrite, demande, classe, séance, suivi), pas par taille de travail.

1. **Demande et suivi de la famille** : `PortSuiviDemandes` a un adaptateur sur `codex/backend-offres-adapters@392fe0c5` (non fusionné) ; `PortFriseDemandes` (`null`, C-20) n'en a aucun. Sans eux, la famille ne voit ni état ni frise.
2. **Création des classes par l'administration** : `PortRegroupementsAdmin` (adaptateur sur `codex/backend-f2-after-c@b6440e9f`, non fusionné) ; `PortRegroupementsPages`, `PortFusionClasses`, `PortClassesAdmin`, `PortPilotage` : `null`, aucun adaptateur. La décision « Créer la classe » ne peut pas se faire.
3. **Catalogue des classes** : `PortCatalogueClasses` (C-14) est `Indisponible`, la branche `codex/backend-catalogue-classes` ne porte que du SQL. Aucun adaptateur Dart : la famille ne peut pas choisir une classe.
4. **Capacité « élève autonome »** : `PortCapaciteEleve` retourne « inconnu » par défaut ; l'adaptateur est sur `codex/backend-adult-kyc-contract@7afc8a2b` (C-24). Sans lui, l'élève adulte n'entre pas dans son espace.
5. **Notifications de la famille à chaque étape** (décision du 09/10) : `PortNotifications` a un adaptateur sur `codex/backend-notifications@af26dd62` ; `PortLectureNotifications` n'a rien.
6. **Salle de cours : persistance et signalements** : `PortAnnotations`, `PortAssignations`, `PortFeedback`, `PortSignalement`, `PortPostCours` ne lèvent plus (SALLE-ROBUSTE) mais restent indisponibles ; `PortEtatPartagePersistant` et `PortPositionDock` sont en mémoire. Adaptateurs sur `codex/backend-f2-b13-admin-rls@00601b47` et `backend-f2-after-c@b6440e9f`, pas fusionnés. Le transport des données (`PortTransportDonnees`) reste `TransportIndisponible` alors que `AdaptateurTransportLiveKit` existe sur ccr : à câbler.
7. **Compte et identité** : `PortIdentiteTitulaire` a son adaptateur sur ccr, non câblé (un `overrideWithValue` dans `main.dart`) ; `PortProfilEleveTitulaire` : adaptateur sur la branche adult-kyc. L'écran Compte reste indisponible.
8. **Recrutement des enseignants** : `PortInvitationsEnseignant`, `PortVerificationInvitation`, `PortSignatureContrat`, `PortStatutsSignature` : `null`, contrats C-13 à C-17, aucun adaptateur Dart (`codex/backend-teacher-recruitment` ne porte pas de code Dart). Pas d'enseignant réel invité ni signataire.
9. **Finance** (comptable, direction, famille, enseignant) : une quinzaine de ports `Indisponible` ou `null` sans adaptateur (`PortPaiementsFoyer`, `PortMesFinances`, `PortEncaissements`, `PortTresorerie`, `PortRevenusEnseignant`, `PortMesMoyensPaiement`, `PortValidationsFinance`, …). Aucune de ces fonctions n'est utilisable en production aujourd'hui.
10. **Revue des dossiers (KYC) et communications** : `PortRevueDossiers` et `PortAccesPiecesKyc` (C-21) sans adaptateur (la revue passe par la surcharge dédiée de `main.dart`) ; tous les ports `com_*` (annonces, messages, studio, vocal, communauté, modération) sont `Indisponible`, la partie serveur est chez Codex.

À câbler sans attendre Codex : `PortIdentiteTitulaire`, `PortHistoriqueObservations`, `PortHistoriqueObservationsAdmin` et `PortTransportDonnees` ont leur adaptateur sur ccr et ne sont pas surchargés.

## 6. Méthode

Inventaire par script (lecture de `lib/**/*.dart`) : classes `Port*`, providers qui les exposent et ce qu'ils retournent par défaut, implémentations, lecteurs ; adaptateurs `*Supabase` des 35 branches `origin/codex/*` comparées à ccr ; garde de démonstration relue dans `mode_demonstration.dart`, `redirection.dart`, `main.dart` et `flutter-deploy.yml`. Aucun fichier de `supabase/`, `.github/`, `pubspec.yaml`, `vercel.json`, `site-public/`, `parcours_offres`, aucun service ni adaptateur n'a été modifié.
