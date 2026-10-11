# COMPTA-RECON-1 : écart entre la spec Finance opérationnelle / Comptable V1 et le code livré

Date : 11/10/2026. Lecture seule de `lib/`, aucune exécution (Flutter n'est pas installé : les tests cités sont lus, pas rejoués).

**Résultat : 77 exigences mesurées, 67 présentes, 6 partielles, 4 absentes.**

## 1. Sources et périmètre

- Spec : `docs/entrants/2026-10-10/compta/REWAYAH_FINANCE_OPERATIONNELLE_COMPTABLE_V1.md` sur `origin/docs/specs-entrantes-2026-10-10` @ `db050205` (2235 lignes ; recettes R-FIN-01 à 29 aux §50-57, écrans W01-W07 §29-35, mobiles M01-M02 §36, composants §39, critères de fin §61).
- Maquettes : 11 fichiers PNG dans le même dossier (la fiche en annonce 10 ; le dossier en contient 11, dont `Rewayah-3 (1).png` et `Rewayah-5 (1).png`, variantes de `-3` et `-5`). La planche `multicanal-2` regroupe W01 à W06 et M01 à M03 (téléphones en sombre) ; les 10 autres sont des variantes de W01 « Aujourd'hui », en clair pour la plupart, en sombre pour `Rewayah-4`, `Rewayah-3 (1)`, `en français-6` et `en mode sombre-1`.
- Code mesuré : `claude/compta-recon` = `ccr-1b1bfa0b-m1kvkk` @ `b6715e16`. `ui/comptable-v1` @ `3ce54981` et `ui/finance-v1` @ `65cf51d2` ont été comparées aux dossiers `lib/features/comptable`, `lib/features/admin_finance`, `lib/core/widgets/comptable` : ccr contient tout ce que contiennent ces branches, plus `fil_profil_paiement_page.dart` (CPT-COM). Aucune preuve n'a donc été prise sur ces branches.
- Les fiches CPT-FUS (fait), CPT-DIR-2 (vérifiée @ 1ef64e06 puis 3ce54981), CPT-VAL-1 (vérifiée @ b26add64) et FI-DIR-1 (vérifiée @ 65cf51d2) ont été lues. Leurs mesures ne sont pas reprises comme preuves : seul le code a été relu, les fiches n'ont servi qu'à repérer les écarts déjà connus.
- Statut : « présent » = le code porte l'exigence entière ; « partiel » = une partie nommée manque ; « absent » = rien dans `lib/`.
- Tous les chemins sont relatifs à la racine du dépôt.

## 2. Tableau exigence, statut, preuve, écart

| Réf. | Exigence | Statut | Preuve (chemin:ligne) | Écart |
| :-- | :-- | :-- | :-- | :-- |
| R-FIN-01 | Montants sensibles masqués à l'entrée Finance | présent | `lib/core/comptable/visibilite_montants.dart:26-32 ; lib/core/widgets/montant_sensible.dart:69` | - |
| R-FIN-02 | « Afficher les montants » révèle | présent | `lib/core/widgets/bascule_montants.dart:48-65 ; lib/core/comptable/visibilite_montants.dart:36` | - |
| R-FIN-03 | Nouvelle session : remasqué | présent | `lib/core/comptable/visibilite_montants.dart:31 (build rejoué à chaque identité de session) ; test/core/comptable/visibilite_montants_test.dart` | - |
| R-FIN-04 | La confirmation payout montre toujours le montant exact | présent | `lib/features/comptable/paiements/confirmation/confirmation_payout.dart:4,630,718,788 (MontantArgent, jamais MontantSensible)` | - |
| R-FIN-05 | Titre « Réserve stratégique » fixe | présent | `lib/core/widgets/comptable/carte_reserve_strategique.dart:17,82` | - |
| R-FIN-06 | Objectif « N mois de charges essentielles » | présent | `lib/core/widgets/comptable/carte_reserve_strategique.dart:95 (objectifMois, pluriels fr et ar)` | - |
| R-FIN-07 | Objectif fixe : montant cible affiché | présent | `lib/core/widgets/comptable/carte_reserve_strategique.dart:102-103` | - |
| R-FIN-08 | Allocation auto 10 USD affichée telle quelle | présent | `lib/core/capacites/port_politique_reserve.dart:95 (montantAuto, aucune plage) ; test/features/comptable/tresorerie/tresorerie_page_test.dart` | - |
| R-FIN-09 | Allocation 1 000 000 USD : aucun hardcode | présent | `lib/features/admin_finance/reserve_delegation/strategic_reserve_policy_panel.dart ; test strategic_reserve_policy_panel_test.dart` | - |
| R-FIN-10 | Retrait Réserve sans capacité : bloqué | présent | `lib/features/comptable/tresorerie/tresorerie_page.dart:506-610 (retrait / retraitBloque)` | - |
| R-FIN-11 | Comptable : aucun « Modifier les coordonnées » | présent | `lib/features/comptable/beneficiaires/profil_paiement_page.dart:19,357-364 ; test beneficiaires_test.dart` | - |
| R-FIN-12 | Admin : aucun « Modifier les coordonnées » | présent | `test/features/comptable/beneficiaires/r_fin_12_admin_test.dart (aucune action de ce nom dans lib/)` | - |
| R-FIN-13 | Le bénéficiaire ajoute / modifie ses coordonnées | présent | `lib/features/paiements_recus/recevoir_paiements_page.dart:8-22,120-148` | - |
| R-FIN-14 | Coordonnées récemment changées : payout sensible | présent | `lib/features/comptable/paiements/detail_paiement_page.dart:260 (alerteMethodeRecente) ; core/capacites/port_delegation_finance.dart:coordonneesRecentesSecondeValidation, joursCoordonneesRecentes` | - |
| R-FIN-15 | Comptable payé : pas de CTA Payer, « Traitement par un autre responsable requis » | présent | `lib/features/comptable/paiements/detail_paiement_page.dart:251-254,285 ; core/comptable/statuts_comptable.dart:204 ; assets/i18n/fr.i18n.json:8555` | - |
| R-FIN-16 | Montant enseignant en lecture seule | présent | `lib/features/comptable/paiements/ligne_obligation.dart:6-7 (MontantSensible, aucun TextField dans paiements/**)` | - |
| R-FIN-17 | Écart signalé : aucun champ de correction | présent | `lib/features/comptable/paiements/signaler_ecart.dart ; detail_paiement_page.dart:485-490` | - |
| R-FIN-18 | Recalcul source : détail et total à jour | présent | `lib/features/comptable/paiements/confirmation/confirmation_payout.dart:21-23 (version refusée, « montant recalculé ») ; detail_paiement_page.dart:13-14` | - |
| R-FIN-19 | Infos manquantes : notice visible du bénéficiaire | présent | `lib/features/paiements_recus/recevoir_paiements_page.dart:10-12 ; rubrique_recevoir_paiements.dart` | - |
| R-FIN-20 | Relancer ouvre Messages métier contextuel | présent | `lib/features/comptable/beneficiaires/fil_profil_paiement_page.dart:1 ; core/router/routes.dart:867-868 ; core/capacites (PortMessagesMetier) features/com_messages/port_messages_metier.dart:201` | - |
| R-FIN-21 | Aucune messagerie Finance nouvelle | présent | `lib/features/comptable/beneficiaires/profil_paiement_page.dart:13-16 (FilContextuel du socle Communications)` | - |
| R-FIN-22 | Lot 12 prêts + 2 bloqués : exclusion affichée | présent | `lib/features/comptable/paiements/confirmation/confirmation_payout.dart:513-515,691-708,749-764` | - |
| R-FIN-23 | Aucun paiement bloqué envoyé avec le lot | présent | `lib/features/comptable/paiements/confirmation/confirmation_payout.dart:12,473,539 (confirmation des seuls prêts, exclusions décidées par le preflight)` | Aucun test ne porte la mention R-FIN-23 (grep test/ : R-FIN-22 seul). |
| R-FIN-24 | Surfaces Finance sur le design system Rewayah | présent | `lib/core/widgets/comptable/*, core/widgets/montant_sensible.dart ; aucun nouveau jeton (fiche CPT-FUS : jetons 39 -> 39)` | Non remesuré ici (pas de Flutter). Aucun test ne cite R-FIN-24. |
| R-FIN-25 | Aucun thème hybride sidebar noire / contenu blanc | présent | `Coque réelle du rôle : core/router/app_router.dart:64-75 (pages dans PageShell) ; aucune sidebar sombre dans lib/features/comptable` | Les maquettes 4, 3(1), 6 portent la sidebar noire : non reprise (conforme à §3.3). |
| R-FIN-26 | High-fi divergentes harmonisées | présent | `docs/current/CATALOGUE_ECRANS_COMPTABLE.md (13 écrans + ADM-18, ADM-19 sur le thème en vigueur)` | - |
| R-FIN-27 | DM Sans pour les titres | présent | `lib/core/theme/app_typography.dart:28-29,142` | - |
| R-FIN-28 | Plus Jakarta Sans conservée | présent | `lib/core/theme/app_typography.dart:26,310` | - |
| R-FIN-29 | Desktop réel 1440 | présent | `docs/current/captures/CPT-*/ *_1440x900@1_{light,dark}.png (ex. CPT-BEN, CPT-CAPT)` | Captures existantes, non rejouées. Aucun test ne cite R-FIN-29. |
| W01 | Aujourd'hui : 9 zones (résumé, Réserve, à traiter, échéances, encaissements, paiements, alertes, activité, accès rapides) | présent | `lib/features/comptable/aujourdhui/aujourdhui_page.dart:118-226 ; zones_aujourdhui.dart:217,248,287,325,361,388 ; file_attention.dart:109` | - |
| W02 | Paiements à effectuer : table 9 colonnes, filtres, voir/payer/relancer/payer sélection | présent | `lib/features/comptable/paiements/ligne_obligation.dart:74-135 ; paiements_page.dart:75,324-358 (filtres type, statut, classe, période)` | - |
| W03 | Détail paiement : identité, total, lignes, destination masquée, historique, preuve, alertes, Payer maintenant, encart permanent | présent | `lib/features/comptable/paiements/detail_paiement_page.dart:182-214,296,341,434,573-609,625-660,670-693` | - |
| W04 | Trésorerie et coffres : total, libre, protégé, transit, coffres, Réserve, transfert, historique, prévision | présent | `lib/features/comptable/tresorerie/tresorerie_page.dart:335 (prévision),419 (historique) ; transfert/transfert_interne.dart ; carte_coffre.dart` | - |
| W05 | Encaissements et rapprochement : table, 7 filtres, panneau brut/frais/net/ref/prestataire/foyer/affectation | présent | `lib/features/comptable/encaissements/encaissements_page.dart:1-19 ; contenu_encaissement.dart:105-128 ; rapprochement/espace_rapprochement.dart` | - |
| W06 | Contractuels : obligations, à approuver, à payer, historique ; Nouvelle obligation selon capacité | présent | `lib/features/comptable/contractuels/contractuels_page.dart:1-10 ; nouvelle_obligation_page.dart:64-74` | - |
| W07 | État du profil de paiement : identité, méthode masquée, statut, pays, devise, modif., vérif., capacité, historique ; Relancer, Demander une mise à jour, Voir le fil, Suspendre | partiel | `lib/features/comptable/beneficiaires/profil_paiement_page.dart:1-19,357-364 ; carte_profil_paiement.dart` | Pas de bouton « Voir le fil » distinct : le fil s'ouvre par Relancer (route routes.dart:867 existe). |
| M01 | Mobile : Aujourd'hui, Paiements, Détail | présent | `lib/features/comptable/aujourdhui/aujourdhui_page.dart:227 (_Telephone) ; paiements/ligne_obligation.dart (carte) ; barre_selection.dart` | - |
| M02 | Mobile : Trésorerie, Encaissements, Alertes | présent | `lib/tresorerie_page.dart ; encaissements_page.dart ; aujourdhui_page.dart:280 (_FileComplete, ?vue=attention)` | - |
| §39 | 21 composants partagés réutilisés ou créés (SensitiveAmount ... FinanceActivityRow) | présent | `lib/core/widgets/montant_sensible.dart, bascule_montants.dart, montant_argent.dart, pastille_financiere.dart, ligne_moyen_paiement.dart, resume_soldes.dart, comptable/*, features/comptable/{tresorerie/carte_coffre,paiements/barre_selection,aujourdhui/file_attention}.dart (21 sur 21 retrouvés)` | - |
| §8 | 7 coffres canoniques, protégé / libre | présent | `lib/core/comptable/statuts_comptable.dart:315-340` | - |
| §9.2 | Objectif dynamique : montant fixe ou couverture en mois | présent | `lib/core/comptable/modeles_comptable.dart:169 ; core/capacites/port_politique_reserve.dart:82-89` | - |
| §9.3 | Règle d'alimentation : désactivée, fixe, pourcentage, jusqu'à l'objectif, proposition | présent | `lib/core/capacites/port_politique_reserve.dart:20-36` | - |
| §9.4 | Cadence : clôture, hebdo, mensuelle, après encaissement, manuelle | présent | `lib/core/capacites/port_politique_reserve.dart:40-56` | - |
| §9.5 | Alimenter par le Comptable ; retrait = validation supplémentaire | présent | `lib/features/comptable/tresorerie/tresorerie_page.dart:451,584-613` | - |
| §9.7 | Indicateurs : objectif, actuel, manque, %, mode, dernière et prochaine allocation, statut | présent | `lib/core/comptable/modeles_comptable.dart:186-219 ; lib/core/comptable/statuts_comptable.dart:293-312 (6 états §49)` | - |
| §9.6 / §37 | StrategicReservePolicyPanel : titre, objectif, mois, cible, règle, montant, %, cadence, seuil, retrait validé ; priorité | partiel | `lib/features/admin_finance/reserve_delegation/strategic_reserve_policy_panel.dart ; core/capacites/port_politique_reserve.dart:79-115` | La « priorité » citée en §9.6 n'existe ni dans le panneau ni dans le port (grep priorite : 0). |
| §21.2 / §37 | FinanceDelegationPolicyPanel : pouvoirs, seuils, exceptions, lots, remboursements, auto-payout, réserve, premier payout, méthode modifiée, opérations sensibles | partiel | `lib/features/admin_finance/reserve_delegation/finance_delegation_policy_panel.dart:1-12 ; core/capacites/port_delegation_finance.dart:40-61` | Pouvoirs, 3 plafonds, lots, remboursements, réserve, premier paiement, coordonnées récentes, 3 règles fixes : présents. « Exceptions » et « opérations sensibles » comme réglages : absents (grep : 0). |
| §10 | Mouvements entre coffres, entrant délégable, sortant sensible, interdictions | présent | `lib/features/comptable/tresorerie/transfert/transfert_interne.dart ; tresorerie_page.dart:11 (aucune allocation modifiable)` | - |
| §11 | Trésorerie réellement libre au centre, jamais le solde brut | présent | `lib/core/widgets/comptable/resume_tresorerie.dart:12-16,40-57` | - |
| §12 | 17 métriques prioritaires (chacune doit répondre à une question) | partiel | `lib/core/widgets/comptable/resume_tresorerie.dart:55-57 ; core/comptable/modeles_comptable.dart:146-165 ; aujourdhui_page.dart:31` | 13 sur 17 portées (détenue, libre, protégés, 7 coffres, remboursements, non rapprochées, échoués, infos manquantes via alertes). Absentes : encaissements période, décaissements période, revenu acquis, créances. Écart assumé (aujourdhui_page.dart:31 : « aucun Revenu acquis ») mais jamais tranché par fiche. |
| §13 | Obligation payable : période, détail par Classe, remplacements, bonus, devise, montant, statut, source, méthode, échéance ; montant jamais un champ | présent | `lib/core/capacites/port_obligations_payables.dart:20 ; detail_paiement_page.dart:434-570` | - |
| §14 | Paiement individuel, par sélection, « tous les prêts », consolidé par bénéficiaire, filtre Classe | présent | `lib/features/comptable/paiements/paiements_page.dart:13,75,167,241 ; barre_selection.dart` | - |
| §15 | 13 états de paiement sortant minimum | présent | `lib/core/comptable/statuts_comptable.dart:13-60 (15 valeurs)` | - |
| §16 | Profil bénéficiaire : statut, représentation masquée, demander mise à jour, relancer, suspendre, marquer « vérification requise » selon capacité | partiel | `lib/core/comptable/statuts_comptable.dart:161-200 (ActionFinance) ; profil_paiement_page.dart:357-364` | Aucune action « marquer la méthode comme nécessitant vérification » (ActionFinance n'en a pas). |
| §17 / §38 | Recevoir mes paiements : ajouter, remplacer, supprimer, préférée ; 6 états | présent | `lib/features/paiements_recus/recevoir_paiements_page.dart:8-22 ; etat_mes_moyens.dart:36-51 ; core/router/routes.dart:888` | - |
| §18 | Bénéficiaire externe : état « Invitation envoyée » | présent | `lib/core/comptable/statuts_comptable.dart:133-135 ; features/comptable/contractuels/obligation_contractuel_page.dart:11-12,65-67` | - |
| §19 | Changement de coordonnées : en vérification, suspension temporaire | présent | `lib/core/comptable/statuts_comptable.dart:114-136 ; features/comptable/beneficiaires/feuille_suspension.dart` | - |
| §21.3-4 | Paiement standard vs sensible (premier paiement, coordonnées récentes, hors seuil, fournisseur, non approuvée) | présent | `lib/core/comptable/statuts_comptable.dart:201-232 (RaisonBlocage, 10 raisons) ; detail_paiement_page.dart:246-290` | - |
| §22-23 | Contractuels récurrent / ponctuel, montant manuel à la création seulement, ajustements en lignes indépendantes | présent | `lib/core/comptable/statuts_comptable.dart:354-381 ; features/comptable/contractuels/nouvelle_obligation_page.dart:64-74,409-495 ; detail_paiement_page.dart:501` | - |
| §24 | Encaissements : 9 états, colonnes, « Confirmé » seulement par le prestataire | présent | `lib/core/comptable/statuts_comptable.dart:62-90 ; encaissements/contenu_encaissement.dart:4-7` | - |
| §25 | Rapprochement : 6 états | présent | `lib/core/comptable/statuts_comptable.dart:92-112 ; encaissements/rapprochement/panneau_rapprochement.dart` | - |
| §26 | Remboursements et avoirs : demande, motif, montant, état, approbation | présent | `lib/core/comptable/statuts_comptable.dart:384-400 ; encaissements/rapprochement/remboursements_avoirs.dart ; feuille_remboursement.dart` | - |
| §27.1-27.3 | Communications intégrées : notice, ligne « Infos manquantes » + Relancer, fil « Profil de paiement » + message modèle | présent | `lib/features/comptable/beneficiaires/profil_paiement_page.dart:13-16 ; fil_profil_paiement_page.dart:1` | - |
| §27.4 | Notifications automatiques (infos manquantes, vérification, payout proche, échoué, confirmé) | absent | - | Dépend du serveur (spec : « selon futur backend ») ; aucun contrat CPT-BR ne la porte dans lib/. |
| §28 | 12 alertes Comptable minimum | présent | `lib/core/comptable/statuts_comptable.dart:248-291 (12 types)` | - |
| §40-41 | Confirmation : bénéficiaire, montant exact, destination, frais, contrôles ; lot : préflight, prêts/exclus, un seul envoi par clé d'idempotence | présent | `lib/features/comptable/paiements/confirmation/confirmation_payout.dart:4-27,250,307,621-664` | - |
| §42 | PayoutCapabilityPort : 5 retours | présent | `lib/core/capacites/port_capacite_payout.dart:42 ; lib/core/comptable/statuts_comptable.dart:141-159` | - |
| §43 | FX et frais : devises, taux, date, frais, coût FX, envoyé, reçu attendu | présent | `lib/core/capacites/port_payout.dart:56-91` | - |
| §44 | Données de démonstration (15 ens., 5 contractuels, 12 prêts, 2 infos manquantes, ...) | présent | `lib/features/demo/comptable/paiements_demo.dart:3-9 ; aujourdhui_demo.dart ; encaissements_demo.dart ; direction_demo.dart` | Seul le décompte annoncé en tête de paiements_demo.dart a été lu, les autres décomptes (3 encaissements, 2 rapprochements) non recomptés. |
| §45-46 | Responsive et accessibilité (320 x2, RTL, libellés, « Montant masqué », statut non coloré) | présent | `lib/core/widgets/montant_sensible.dart:101-103 ; test/features/comptable/socle/{mise_en_page_320,entete_320,arabe_comptable}_test.dart ; fusion/demo_320_x2_test.dart` | - |
| §47-48 | Sécurité UX et journal (initiateur, date, source, ancien/nouvel état, preuve, provider, référence) | présent | `lib/features/comptable/paiements/detail_paiement_page.dart:670 ; encaissements/donnees_encaissements.dart:117 ; rapprochement/donnees_rapprochement.dart:34 (CPT-BR-17)` | - |
| §49 | États UI : chargement, vide, erreur, erreur partielle, indisponible, hors ligne, permission insuffisante, masqué, révélé, pending, retry | partiel | `lib/features/comptable/tresorerie/tresorerie_page.dart:13 (cinq états par bloc) ; confirmation_payout.dart:27 (hors ligne, réponse perdue)` | « Erreur partielle » et « permission insuffisante » : aucune occurrence dans features/comptable (grep partielle/insuffisante : 0 hors EtatEncaissement.partiellementRembourse). Cas lié : decision_validation.dart:603-605, une erreur de journal s'affiche comme vide. |
| §1.1 | Frontend seul : aucun serveur, aucune vraie coordonnée, aucun vrai paiement | présent | `lib/core/capacites/port_*.dart (production = CapaciteIndisponible('CPT-BR-nn')) ; pas de supabase/ dans le lot` | - |
| MAQ-1 | Maquettes : graphiques (flux 30 j, répartition par coffre en anneau, vue d'ensemble, entrées/sorties) | absent | `lib/features/comptable/tresorerie/tresorerie_page.dart:10-11 (« aucun graphique, DR-09 »)` | Absent par décision (spec §29 « ne pas saturer de graphiques », K-63). 9 maquettes sur 11 en portent. À confirmer par le directeur, pas à coder. |
| MAQ-2 | Maquettes : entrée « Rapports », « Exporter le rapport / la sélection », carte « Centre de messages » | absent | - | Hors spec §6 à §36 (aucune exigence). Entrées de navigation et exports absents de lib/features/comptable. |
| MAQ-3 | Maquettes : variations (+12 %, +18 %) sur les KPI | absent | `lib/features/comptable/aujourdhui/aujourdhui_page.dart:31` | Écartées (« aucune variation »), cohérent avec §12.2 mais non tracé par fiche. |
| MAQ-4 | Maquettes : thèmes clair et sombre, coque réelle, mobile sombre M01-M03 | présent | `docs/current/captures/CPT-CAPT/*_{light,dark}* ; CPT-BEN, CPT-COM` | Composition reprise, palette et coque du thème en vigueur (K-63). M03 (contractuels / confirmation mobile) : écrans présents (contractuels_page, confirmation_payout en feuille). |

Note de lecture : les 29 lignes R-FIN comptent chacune pour une exigence ; les lignes `§` regroupent les règles de la spec que les recettes ne couvrent pas. Les écrans W/M et le §39 sont comptés une fois chacun. Les lignes `MAQ-` sont les éléments des maquettes que la spec n'exige pas et que le code ne reprend pas.

## 3. Écarts classés

### 3.1 Bloquants pour BR-1 (le serveur ne peut pas être branché tel quel)

1. **Les 17 contrats CPT-BR sont tous non branchés.** En production chaque port renvoie `CapaciteIndisponible('CPT-BR-nn')` et la page affiche « en préparation » : CPT-BR-01 `core/capacites/port_obligations_payables.dart:168`, -02 `port_payout.dart:270`, -03 `port_aujourdhui_comptable.dart:216`, -04 `port_tresorerie.dart:175`, -05 `port_tresorerie.dart:176`, -06 `port_beneficiaires_paiement.dart:143`, -07 `port_encaissements.dart:208`, -08 `port_obligations_contractuels.dart:238`, -09 `port_validations_finance.dart:211`, -10 `port_capacite_payout.dart:55`, -12 `port_politique_reserve.dart:200`, -13 `port_delegation_finance.dart:172`, -14 `port_rapprochement.dart:160`, -15 `port_encaissements.dart:209`, -16 `port_mes_moyens_paiement.dart:167` ; -11 (fil métier) passe par `features/com_messages/port_messages_metier.dart:201` ; -17 (journal) n'est qu'un type de retour (`encaissements/donnees_encaissements.dart:117`). C'est le contenu même de BR-1 : tant que rien n'est rendu, aucune des 77 exigences n'est vérifiable avec de vraies données.
2. **Métriques §12 sans champ dans le contrat** : `SyntheseTresorerie` (`core/comptable/modeles_comptable.dart:146-165`) n'a ni encaissements ni décaissements de période, ni revenu acquis, ni créances. À trancher avant d'écrire CPT-BR-03 et -04, sinon la migration devra être rouverte.
3. **Action « marquer la méthode comme nécessitant vérification » (§16.2)** absente de `ActionFinance` (`core/comptable/statuts_comptable.dart:161-200`) : à décider avant CPT-BR-06, car l'action est portée par le contrat des permissions.
4. **Champ « priorité » de la Réserve (§9.6)** absent de `PolitiqueReserve` (`core/capacites/port_politique_reserve.dart:79-115`) : même remarque pour CPT-BR-12.
5. **Notifications automatiques §27.4** : aucun contrat ne les porte (aucune occurrence dans `lib/features/comptable`) ; à ajouter au périmètre BR-1 ou à reporter explicitement.

### 3.2 À faire côté écran (voie CPT)

1. **Bouton « Voir le fil » (W07, §35)** : le fil s'ouvre seulement par « Relancer » ; ajouter l'accès direct (`profil_paiement_page.dart:357-364`, route déjà en `core/router/routes.dart:867`).
2. **Panneau de délégation (§21.2, §37)** : « exceptions » et « opérations sensibles » comme réglages absents de `features/admin_finance/reserve_delegation/finance_delegation_policy_panel.dart`. Dépend de la décision 3.1.4/3.1.2 pour le contrat ; le champ d'écran est à ouvrir après.
3. **États UI §49** : « erreur partielle » et « permission insuffisante » sans rendu dédié dans `features/comptable`. Cas connu et confirmé : `features/admin_finance/a_valider/decision_validation.dart:603-605`, une erreur de chargement du journal s'affiche comme « historique vide » (relevé par CPT-VAL-1, non corrigé).
4. **Tests nommés manquants** : aucun test ne porte R-FIN-23, R-FIN-24 ni R-FIN-29 (grep `test/`) ; R-FIN-25 à 28 non plus. Le comportement est dans le code (lignes R-FIN-23 à R-FIN-29 du tableau), la couverture est à écrire.
5. **Écarts hérités des fiches, non remesurés** : `catalogue_galerie_test` rouge depuis CPT-F (4 composants sans entrée de catalogue : `bascule_montants`, `montant_sensible`, `pastilles_comptable`, `ligne_destination`, voir CPT-FUS « reste ») ; masque RTL non isolé dans `core/widgets/montant_sensible.dart` (fichier gelé, CPT-DIR-2) ; données de démonstration en français affichées en arabe (CPT-DIR-2).

### 3.3 Décisions à demander avant de coder (pas des écarts à ouvrir en fiche)

- Graphiques des maquettes (MAQ-1) : 9 maquettes sur 11 en portent (flux 30 jours, anneau de répartition des coffres, entrées/sorties). Le code n'en a aucun, par décision écrite (`features/comptable/tresorerie/tresorerie_page.dart:10-11`, spec §29 « ne pas saturer »). Si le directeur les veut, c'est une nouvelle fiche avec jeton de couleur (K-37).
- Entrée « Rapports », exports, carte « Centre de messages », variations en pourcentage (MAQ-2, MAQ-3) : hors spec, hors code ; à confirmer comme abandonnés.
- Composition des maquettes reprise, palette et coque non reprises (sidebar noire des maquettes 4, 3 (1), 6 : refusée par §3.3 et R-FIN-25).

### 3.4 Côté serveur (Codex, zone K-68)

Tout ce qui relève de `supabase/**` : les 17 contrats ci-dessus et leurs RPC (liste attendue dans `docs/current/CPT-VAL-1.md` pour CPT-BR-09), l'idempotence et le préflight des payouts (`port_payout.dart:6,187`), la confirmation par le prestataire (§24.3), les notifications (§27.4), les limites réelles de la politique de Réserve (§9.3 : « la validation serveur décidera »). Le front est prêt à les recevoir (ports typés) ; aucun écart côté client n'y est lié, hors 3.1.2 à 3.1.5.

## 4. Limites de la mesure

- Aucune exécution : ni `flutter test`, ni `dart analyze`, ni rendu. Les tests et captures sont cités par leur existence dans le dépôt.
- Les décomptes de la démonstration (§44) ne sont recomptés que pour `paiements_demo.dart` (en-tête) ; les captures 1440 n'ont pas été comparées visuellement aux maquettes une à une, seulement par composition (zones présentes ou non).
- Le dossier `20_comptable/` (UX_REVIEW, CPT-BR.md, CARTE_FONCTIONS) vit sur `pilotage/tuteur-v1`, non présent dans cette branche : non lu.
