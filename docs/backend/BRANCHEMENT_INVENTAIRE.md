# Inventaire de branchement des adaptateurs réels (REVUE-BACKEND-CODEX, phase 1)

Lecture seule. Base : `origin/ccr-1b1bfa0b-m1kvkk` @ 5176f0b9. Rédigé le 11/10/2026 (nuit) par la session Claude 01JpB27h. Aucun adaptateur Supabase, aucun `supabase/`, aucun câblage `lib/main.dart` n'a été touché.

## 1. Ce que dit l'inventaire en trois lignes

1. **Aucune branche d'adaptateur n'est dans ccr.** ccr contient 3 adaptateurs dans `lib/core/capacites` (classes du foyer, consentements, identité du titulaire) et 4 dans `tc_*` ; seuls l'adaptateur des classes du foyer et la revue des dossiers sont câblés dans `lib/main.dart`.
2. **Presque toutes les RPC visées sont absentes de ccr** (52 migrations) et présentes dans `codex/backend-canon-fixes` @ ea1a0da9 (102 migrations) ou dans une migration propre à la branche de l'adaptateur. Brancher un adaptateur sans sa migration donne une RPC introuvable.
3. **Seules les branches C-11 bis, C-22 (safe), C-29 et B-04 contiennent canon-fixes.** DELEG-FIN-1, B-09 et X2-15 à X2-18 sont à fusionner avec ea1a0da9 avant ccr (verdicts A587 et A588).

## 2. Sources et statuts

- Questions A586-A593 (verdicts de nuit, non-auteur) et Codex2 A100-A120. Renvois ponctuels à Questions A529-A532, A554 et A561 pour des adaptateurs absents de ces plages. Les numéros sont ceux des lignes des onglets.
- **confirmé** : verdict CONFIRMÉ non contredit. **changes** : CHANGES REQUESTED non levé. **présent, non revu** : adaptateur sur une branche, aucun verdict dans les sources ci-dessus (ce n'est pas un échec). **absent** : aucun adaptateur nulle part (ccr et branches `origin/codex*`) ; le port n'a que son double « Indisponible », une démo ou un double mémoire.
- « Branche @ SHA » = pointe de la branche au moment de l'inventaire (fetch du 11/10, 21 h). Le blob est celui du fichier adaptateur.
- Non prouvé ici : tout comportement à l'exécution. Cet inventaire est de la lecture de code, de dépôt et de fiches de revue ; aucun test n'a été relancé.

## 3. Ports de `lib/core/capacites` avec adaptateur ou chemin de substitution

| Port | Fichier du port | Adaptateur | Branche @ SHA | Cible serveur | Serveur : migration | Statut | Preuve et réserves |
| :-- | :-- | :-- | :-- | :-- | :-- | :-- | :-- |
| PortNotifications, PortLectureNotifications | port_notifications.dart | `lib/core/capacites/notifications_supabase.dart` (blob 421bcc0d) | `codex/backend-b09-adaptateur` @ b09ade4c | table `notifications` (REST sous RLS), pas de RPC | table et producteurs B-09 de `codex/backend-canon-fixes` ; le diff de la branche ne contient aucune migration | **confirmé** | A588 (2 fichiers, 5/5 verts, analyze 0) ; A556 et A563 sur 6f3554d9. Réserve : base fdf6854b sans ea1a0da9, fusionner avant ccr |
| PortDelegationFinance, PortControleDelegation | port_delegation_finance.dart | `lib/core/capacites/port_delegation_finance_supabase.dart` (b171cff8) | `codex/deleg-fin-1-serveur` @ f6227c64 | RPC `enregistrer_delegation_finance`, `lire_delegation_finance`, `journal_delegation_finance`, `renouveler_delegation_finance`, `suspendre_toutes_delegations_finance`, `reactiver_delegation_finance`, `annuler_sortie_delegation_finance`, `sorties_en_attente_delegation_finance` | `20261011230000_deleg_fin_1_server.sql`, `20261012000000_deleg_fin_1_renewal_validation.sql` (sur la branche, absents de ccr et de canon-fixes) | **confirmé** | A587 : scenarios_deleg_fin_1 vert, mutation détectée, test Dart 1/1, analyze 0. Réserves : base fdf6854b sans ea1a0da9 (0084, F70) ; 1 seul test Dart pour 8 RPC |
| PortSeriesTresorerie | port_series_tresorerie.dart | `lib/core/capacites/series_tresorerie_supabase.dart` (2aed19c3) | `codex2/x2-17` @ c9c5b233 | RPC `series_tresorerie` (INVOKER) | `20261011203606_codex2_cpt_br_18_series.sql` et table de règles de rémunération (branche, hors ccr) | **changes** | Codex2 A119 : scénario rouge 42501 (ligne 141), 1 info analyze (test Dart l. 44). Lot PARTIEL : alimentation, reprise, `remuneration_due_seance`, politique d'allocation non livrés |
| PortExportRapports | port_export_rapports.dart | `lib/core/capacites/export_rapports_supabase.dart` (a9702c2d) | `codex2/x2-18` @ 16650768 | RPC `exporter_rapport_comptable`, `exporter_selection_comptable` (INVOKER) | `20261011204643_codex2_cpt_br_19_exports.sql` (branche, hors ccr) | **changes** | Codex2 A120 : journal `exports_comptables` falsifiable (INSERT direct d'un comptable), scénario 42703 ; embarque le rouge de X2-17 |
| PortProgressionFamille | port_progression_famille.dart | `lib/core/capacites/progression_famille_supabase.dart` (2 variantes : 6e18b715 et be7f62b5) | `codex/backend-a81-f69-hardening` @ e6eb0024 (6e18b715) ; `codex/backend-c22-age-presentation` @ aee75a4d et `codex/backend-f2-after-c` @ b6440e9f (be7f62b5) | RPC `progression_famille` | `0054_seance_resumes_famille.sql` (canon-fixes, absent de ccr) | **présent, non revu** | Aucun verdict dans les sources. Deux variantes du fichier : à trancher avant câblage |
| PortResumeSeanceFamille | port_resume_seance_famille.dart | `lib/core/capacites/resume_seance_famille_supabase.dart` (2 variantes : c65a3f9f et 97bee76a) | `codex/backend-a81-f69-hardening` @ e6eb0024 (c65a3f9f) ; `codex/backend-c22-age-presentation` @ aee75a4d et `codex/backend-f2-after-c` @ b6440e9f (97bee76a) | RPC `resume_seance_famille` | `0054_seance_resumes_famille.sql` (canon-fixes) | **présent, non revu** | Idem : deux variantes |
| PortSupport | port_support.dart | `lib/core/capacites/support_supabase.dart` (c2b322d3) | `codex/backend-f2-b13-admin-rls` @ 00601b47 ; `codex/backend-f2-after-c` @ b6440e9f ; `codex/backend-c22-age-presentation` @ aee75a4d | RPC `canal_support` | `0062_canal_support.sql` (canon-fixes) | **présent, non revu** | Aucun verdict. C-34 (support actif séance/groupe) reste bloqué côté serveur |
| PortEnseignantsClasse | port_enseignants_classe.dart | `lib/core/capacites/enseignants_classe_supabase.dart` (a72511d3) | `codex/backend-c22-age-presentation` @ aee75a4d ; `codex/backend-f2-after-c` @ b6440e9f | RPC `enseignants_pour_classe` | `0083_free_teacher_slots_real_overlap.sql` (canon-fixes) | **présent, non revu** | Aucun verdict |
| PortClassesFoyer | port_classes_foyer.dart | `lib/core/capacites/classes_foyer_supabase.dart` | **ccr** (5176f0b9) | table `groupe_membres` et vue `mes_groupes_famille_v` | vues et RLS de ccr | **en place et câblé** | Seul adaptateur de `lib/core/capacites` branché dans `lib/main.dart` (`_surchargesAppReelle`). Pas de verdict dans les sources |
| PortConsentements | port_consentements.dart | `lib/core/capacites/consentements_supabase.dart` | **ccr** | table `contract_acceptances` via `ServiceAcceptations` et `ServiceDossier.accepterContrat` | RLS `contract_acceptances_self_read` ; garde de signature 0089 dans canon-fixes | **présent dans ccr, non câblé** | Pas de surcharge dans `main.dart`. Aucun verdict. Dépend de la signature d'empreinte (F70) côté serveur |
| PortIdentiteTitulaire | port_identite_titulaire.dart | `lib/core/capacites/identite_titulaire_supabase.dart` | **ccr** | table `profiles` (`first_name`, `last_name`, `account_status`, fournisseur) | RLS de ccr | **présent dans ccr, non câblé** | Pas de surcharge dans `main.dart`. Aucun verdict |
| PortRevueDossiers | port_revue_dossiers.dart | `lib/core/capacites/revue_dossiers_depuis_validation.dart` (`RevueDossiersDepuisValidation`, pas un adaptateur Supabase dédié) | **ccr** | services de validation existants | le verdict d'accès aux pièces KYC vient de `verdict_acces_dossier_kyc` (0091, canon-fixes) | **en place et câblé** (`surchargeRevueDossiersProduction`) | L'aperçu de pièce reste fermé en production tant que `PortAccesPiecesKyc` n'est pas branché (annexe) |
| PortAccesFoyer, PortMonAcces | port_acces_foyer.dart | `lib/core/capacites/acces_foyer_depuis_eleves.dart` (dérivé des élèves) | **ccr** | déduit du service élèves | aucune | **en place (dérivé)** | Aucun adaptateur Supabase prévu à ce jour |
| PortCreationClasse | port_creation_classe.dart | `CreationClasseParServiceGroupes` dans `port_creation_classe.dart` | **ccr** | service Groupes (`creer_groupe` côté serveur) | `creer_groupe` (8 arguments, DEFINER, voir SEC_PROD_27.md) | **en place (via service)** | Pas d'adaptateur dédié. Chemin cible : « Créer la classe » (C-11 bis) |

## 4. Ports de `lib/core/capacites` sans adaptateur (statut : absent)

| Port | Fichier | Remarque |
| :-- | :-- | :-- |
| PortAccentsProfils | port_accents_profils.dart | double mémoire seulement |
| PortAujourdhuiComptable | port_aujourdhui_comptable.dart | Indisponible seulement |
| PortBeneficiairesPaiement | port_beneficiaires_paiement.dart | Indisponible seulement |
| PortCapacitePayout | port_capacite_payout.dart | Indisponible seulement |
| PortCatalogueClasses | port_catalogue_classes.dart | démo seulement |
| PortEncaissements | port_encaissements.dart | démo seulement |
| PortFinanceDirection | port_finance_direction.dart | Indisponible seulement |
| PortMesFinances | port_mes_finances.dart | démo seulement |
| PortMesMoyensPaiement | port_mes_moyens_paiement.dart | Indisponible seulement |
| PortObligationsContractuels | port_obligations_contractuels.dart | Indisponible seulement |
| PortObligationsPayables | port_obligations_payables.dart | Indisponible seulement |
| PortPaiementsFoyer | port_paiements_foyer.dart | Indisponible seulement |
| PortPayout | port_payout.dart | démo seulement |
| PortPolitiqueReserve | port_politique_reserve.dart | Indisponible seulement |
| PortPolitiqueRevueKyc | port_politique_revue_kyc.dart | Indisponible seulement |
| PortPolitiquesCommerciales | port_politiques_commerciales.dart | Indisponible seulement |
| PortPreferencesPersistantes | port_preferences_persistantes.dart | Indisponible seulement ; B-16 sans source serveur |
| PortProfilEleveTitulaire | port_profil_eleve_titulaire.dart | l'adaptateur existant sur branche implémente `PortProfilEleveTitulaireServeur` (annexe), pas ce port |
| PortRapprochement | port_rapprochement.dart | Indisponible seulement |
| PortRechargeFoyer | port_recharge_foyer.dart | B-05 : ledger incomplet |
| PortRecus | port_recus.dart | Indisponible seulement |
| PortRevenusEnseignant | port_revenus_enseignant.dart | Indisponible seulement |
| PortTresorerie | port_tresorerie.dart | démo seulement ; X2-17 ne livre que la lecture `series_tresorerie` |
| PortValidationsFinance | port_validations_finance.dart | Indisponible seulement |

Les ports finance (encaissements, payout, trésorerie, réserve, validations, reçus, revenus, recharge, rapprochement, obligations) n'ont pas de contrat serveur : X2-17 et X2-18 ne couvrent que `series_tresorerie` et les exports, et la confirmation webhook (FI-BR-06) n'existe pas.

## 5. Annexe : adaptateurs sur branches pour des ports hors `lib/core/capacites`

Hors périmètre demandé mais ils conditionnent le câblage.

| Port | Adaptateur | Branche @ SHA | Cible serveur | Statut | Preuve |
| :-- | :-- | :-- | :-- | :-- | :-- |
| PortReponsePresentation | `lib/core/accessibilite/reponse_presentation_supabase.dart` (680a066d) | `codex/backend-c22-presentation-adapter-safe` @ d7aca318 (contient canon-fixes) | RPC `accepter_demande_presentation`, `refuser_demande_presentation`, `lire_demandes_presentation_en_attente(_avec_fuseau)` ; `20261011200000_c22_presentation_timezone_projection.sql` | **confirmé** | A591 : test 4/4, analyze 0. Réserve : l'isolement entre foyers de la lecture n'est pas testé |
| PortReprisesAdmin | `lib/core/foyer/reprises_admin_supabase.dart` (ce76924c) | `codex/backend-b04-reprise-canon` @ 434c4e23 (contient canon-fixes) | RPC `lister_reprises_admin`, `decider_reprise_foyer`, `deposer_reprise_foyer`, `refuser_reprise_foyer`, `etat_reprise_foyer` ; `0099_b04_titulaire_refusal_terminal.sql` | **confirmé** | A590 : 4/4 verts, réserve de couverture. Une autre variante existe sur `codex/backend-c23-reprise-adapter` : ne pas brancher les deux |
| PortStatutsSignature | `lib/core/recrutement/port_statuts_signature_supabase.dart` (3cc50ad2) | `codex/backend-canon-fixes` @ ea1a0da9 et branches filles | RPC `teacher_signature_statuses` (0089) | **confirmé** | Questions A554 (fdf6854b) : 6 tests verts |
| PortTirageControle | `lib/core/controle/port_tirage_controle_supabase.dart` (879756e7) | `codex/backend-c29-effective-teacher` @ c6df477c (contient canon-fixes) | RPC `candidats_cible_tirage`, `capacites_tirage_controle`, `declarer_conflit_mission`, `enregistrer_regles_tirage`, `historique_tirages`, `lire_regles_tirage` ; migrations C-29 | **changes** | A586 : 23514 `notifications_evenement_check`, la démo du tirage ne compile plus, scénarios inexécutables |
| PortRegroupementsAdmin (C-11 bis) | `lib/core/offres/regroupements_c11bis_supabase.dart` (1c3d6485) | `codex/backend-c11bis-adapter` @ aaa7e4c6 | RPC `regroupements_c11bis_admin`, `creer_classe_depuis_regroupement(uuid,uuid,text)`, `affecter_enseignant_classe_c11bis` | **présent, non revu** (serveur : **changes**) | Le serveur `codex/backend-c11bis-f74-canon` @ a67dc964 est CHANGES REQUESTED (A589 : 22P02, identifiant de regroupement text contre uuid). Adaptateur et serveur doivent suivre la même clé |
| PortRegroupementsPages (C-25) | `lib/core/offres/regroupements_pages_supabase.dart` (fb63ebcc) | `codex/backend-c25-c11bis-followup` @ b083506f | Edge `regroupements-pages` (JWT) | **présent, non revu** | Dépend de C-11 bis ; pas de projection canonique publiée |
| PortFriseDemandes (C-20) | `lib/core/offres/frise_demandes_supabase.dart` (56cfb452) | `codex/backend-c20-frise-2` @ aa2981c7 ; aussi `codex2/x2-07` à `x2-09` | RPC `suivi_demandes_horaires_foyer_utc`, vue `demande_evenements_foyer_v` ; `20261011183000_c20_utc_instants.sql` | **présent, non revu** | Test de projection UTC passé selon Codex ; aucun verdict Claude dans les sources |
| PortSuiviDemandes (C-10) | `lib/core/offres/port_suivi_demandes_supabase.dart` (bd2bbca4) et `demandes_suivi_supabase.dart` (9d0c5f58) | `codex/backend-a81-f69-hardening` @ e6eb0024 ; `codex/backend-c22-age-presentation` @ aee75a4d | RPC `suivi_demandes_horaires_foyer` (0076), table `demandes_horaires_famille` | **présent, non revu** | Deux fichiers pour un même port : en choisir un |
| PortDemandesHorairesFamille, PortRegroupementsDemandesHoraires | `lib/core/offres/demandes_horaires_supabase.dart` (7a5adaa9) | `codex/backend-a81-f69-hardening` @ e6eb0024 | RPC `demander_creneau_personnalise`, `mes_demandes_horaires`, `regroupements_demandes_horaires_admin` | **présent, non revu** | Dépend de C-11 bis (la clé de regroupement change) |
| PortCapaciteEleve (A81/C-24) | `lib/core/session/port_capacite_eleve_supabase.dart` (3 variantes : 9b4e17ee, cdb62aff, d2a48595) | `codex/backend-a81-c24-adapter` @ 43fbd2d6 ; `codex/backend-a81-f69-hardening` @ e6eb0024 | RPC `ma_capacite_eleve` (0090) | **présent, non revu** | Trois variantes ; la plus récente est d2a48595 |
| PortAccesPiecesKyc (C-21) | `lib/core/dossier/port_acces_pieces_kyc_supabase.dart` (feccf3d1, caa00243) | `codex/backend-c21-canon-adapter` @ 4515660e ; `codex/backend-c17-signature-status` @ e4851c5e | RPC `verdict_acces_dossier_kyc`, `ma_exception_kyc_active` (0091) | **présent, non revu** | Aucun verdict dans les sources |
| PortInvitationConjoint, PortReponseInvitation, PortLectureInvitationRecue (B-03) | `lib/core/foyer/invitation_foyer_supabase.dart` (3ec95773), ou `invitations_conjoint_supabase.dart` et `lecture_invitation_recue_supabase.dart` | `codex/backend-foyer-ports` @ 78940327 ; `codex/backend-c22-age-presentation` @ aee75a4d | RPC `inviter_conjoint`, `repondre_invitation_conjoint`, `annuler_invitation_conjoint`, `mon_invitation_en_cours` (0053) | **présent, non revu** | Questions A532 (Codex) : 11/11. Deux découpages du même port à départager |
| PortProfilEleveTitulaireServeur | `lib/core/foyer/profil_eleve_titulaire_supabase.dart` (ae3d7a9e) | `codex/backend-a81-f69-hardening` @ e6eb0024 | RPC `creer_profil_eleve_titulaire`, `profil_eleve_titulaire_existe` (0052) | **présent, non revu** | Implémente `PortProfilEleveTitulaireServeur`, pas le port de `lib/core/capacites` |
| PortIncidentsSeances | `lib/core/admin/incidents_seances_supabase.dart` (44b6c301) | `codex2/x2-15` @ c08e769b | RPC `lister_incidents_seances` (INVOKER) ; `20261011200000_x2_15_incidents_rpc.sql` | adaptateur et SQL **confirmés** ; scénario **changes** | Codex2 A106 : fixture sans `account_status`, `service_role` à révoquer, périmètre controller à resserrer (TODO C-29) |
| PortPlanningDirection | `lib/core/admin/planning_direction_supabase.dart` (c70ef6d6) | `codex2/x2-16` @ f662f419 | RPC `lister_planning_direction` (INVOKER) ; `20261011201000_x2_16_planning_rpc.sql` | adaptateur et SQL **confirmés** ; scénario **changes** | Idem ; `p_lundi` est calculé à minuit du fuseau de l'appareil, pas Europe/Paris |
| PortEtatPartagePersistant, PortAnnotations, PortAssignations, PortFeedback, PortSignalement (Teaching Core) | `lib/core/tc_etat_partage/etat_partage_supabase.dart`, `tc_outils/annotations_supabase.dart`, `tc_outils/assignations_supabase.dart`, `tc_parcours/feedback_supabase.dart`, `tc_parcours/signalement_supabase.dart` | `codex/backend-f2-b13-admin-rls` @ 00601b47 ; `codex/backend-c22-age-presentation` @ aee75a4d ; `codex/backend-f2-after-c` @ b6440e9f | RPC `publier_etat_partage` (0033, **dans ccr**), `effacer_etat_partage`, `tc_poser_annotation_marqueur`, `tc_annuler_derniere_annotation` (0061), `soumettre_feedback`, `question_feedback_pour`, `tendance_feedback_comprehension` (0065), `deposer_student_concern`, `mes_student_concerns`, `transmettre_student_concern` (0059) ; tables `session_shared_content`, `annotation_*`, `learning_assignment` | **présent, non revu** | B-13, B-14, B-15, B-11 : décisions en attente dans Questions |
| Groupes, horloge, historique d'observations | `lib/core/tc_groupe/groupes_supabase.dart`, `tc_horloge/horloge_supabase.dart`, `tc_observation/historique_observations_supabase.dart`, `historique_observations_admin_supabase.dart` | **ccr** | vue `mes_groupes_famille_v`, RPC `maintenant_serveur`, table `guardian_session_visit` | **en place** | Non câblés dans `lib/main.dart` (hors périmètre de cette phase) |

## 6. Serveur livré sans port Dart

| Lot | Branche @ SHA | Statut | Remarque |
| :-- | :-- | :-- | :-- |
| CAP29-3 | `codex/backend-cap29-review-fixes` @ 40821d81 | **confirmé** (Questions A561) | `library_get_detail` et gardes ; aucun port Dart de lecture sur ccr |
| C-35 lecture bibliothèque | `codex/backend-cap29-c35` @ 208737cb | **changes** (A592) | parenthèse du postflight, `v_access_policy` NULL, scénario inexécutable ; lecture par Edge `bibliotheque-lecture` et RPC `autoriser_lecture_version` |
| X2-19 rejeu de base | `codex2/x2-19` @ 00308058 | relecture OK avec 3 notes (Codex2 A109) | outil de rejeu, sans effet applicatif |

## 7. Ordre de dépendance à respecter avant tout câblage

1. **Fusionner `codex/backend-canon-fixes` @ ea1a0da9 dans ccr** et corriger ses 5 scénarios rouges (Questions A593 : b08, b18, etape3, etape4, offres_personnalisees). Sans cela, aucune des RPC `progression_famille`, `ma_capacite_eleve`, `canal_support`, `enseignants_pour_classe`, `verdict_acces_dossier_kyc` n'existe sur la base de ccr.
2. Adaptateurs **confirmés** à brancher en premier (après 1) : notifications (b09ade4c), DELEG-FIN-1 (f6227c64, avec fusion de ea1a0da9), reprises admin (434c4e23), réponse de présentation (d7aca318), statuts de signature.
3. À **ne pas** brancher avant levée des « changes » : séries de trésorerie (X2-17), exports (X2-18), tirage de contrôle (C-29), regroupements C-11 bis.
4. À **revoir** (aucun verdict) avant branchement : progression, résumé de séance, support, enseignants de classe, capacité élève, accès pièces KYC, invitations, suivi et frise, Teaching Core. Plusieurs ont **deux ou trois variantes du même fichier** sur des branches différentes : en choisir une seule avant fusion.
5. Pour chaque adaptateur branché, vérifier la signature et l'ACL de la RPC dans `docs/backend/catalogue-canon-fixes/INDEX.csv` (branche `claude/catalogue-canon-fixes`) ; pour les RPC propres à une branche, rejouer d'abord la migration.
