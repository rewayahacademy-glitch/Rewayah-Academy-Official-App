# Comptable V1 : découpage

Étapes du tableau YAADEN, ordre 1400 à 1474, plus CPT-Q (ATTEND, 2017). CPT-0 complète ce fichier avec la liste des fichiers de chaque étape.

```
CPT-0 ─► CPT-F ─┬─► CPT-JOUR (voie CPT) ──────────────────────┐
   (après       ├─► CPT-PAY-1 ─► CPT-PAY-2 ────────────────┤
  FI-VAGUE-     ├─► CPT-TRES-1 ─► CPT-TRES-2 ──────────────┤
   CORR)        ├─► CPT-ENC-1 ─► CPT-ENC-2 ────────────────┼─► CPT-FUS ─┬─► CPT-CAPT ─► CPT-R ─► CPT-RC
                ├─► CPT-BEN-1 ─► CPT-BEN-2 ────────────────┤            └─► CPT-COM (après COM-FUS)
                ├─► CPT-CTR-1 ─────────────────────────────┤
                └─► CPT-DIR-1 ─────────────────────────────┘
CPT-0 ─► CPT-Q (directeur, seulement si CPT-0 trouve un point bloquant)
```

## Règles anti-conflit

- Une voie = une sous-branche = un worktree = un dossier `lib/features/comptable/<module>/` = un espace i18n `comptable.<module>.*` = un fichier de fixtures.
- Tout ce qui serait partagé (routes, navigation du rôle, ports, composants SensitiveAmount et statuts) est posé UNE FOIS par CPT-F. Une voie qui a besoin d'y toucher s'arrête et écrit une ligne pour CPT-FUS, sans modifier.
- CPT-DIR-1 est la seule voie qui touche des fichiers de la Finance Direction (17_finance) ; CPT-BEN-2 la seule qui touche la surface Compte du bénéficiaire.
- La voie CPT (base) et la voie FIN (Finance V1) ne tournent jamais en même temps sur les mêmes fichiers : CPT-F attend FI-VAGUE-CORR.
- Seules les sessions cloud prennent ces étapes (directeur, 04/10) ; la session locale du poste A n'y touche pas.

| Ordre | Étape | Voie | Dépend de | Modèle | Titre |
|---|---|---|---|---|---|
| 1400 | CPT-0 | CPT | — | Opus, 35 min, lecture seule | Préparation Comptable V1 (FIN-L0) : UX_REVIEW_FINANCE_COMPTABLE_L0, DEVOIR_DE_REGARD_FINANCE, CPT-BR, fichiers par étape |
| 1401 | CPT-F | CPT | CPT-0, FI-VAGUE-CORR | Opus, 35 min | Socle Comptable (FIN-L1) : branche ui/comptable-v1, shell et navigation du rôle, routes de toutes les surfaces, SensitiveAmount, statuts, view models, fixtures §44, ports neutres |
| 1402 | CPT-JOUR | CPT | CPT-F | Opus, 35 min | Aujourd'hui du Comptable (FIN-L2) : FIN-CPT-W01 et premier écran de M01, file d'attention, alertes, carte Réserve stratégique en lecture |
| 1410 | CPT-PAY-1 | CPT-PAY | CPT-F | Opus, 35 min | Paiements à effectuer (FIN-L3a) : liste W02 avec filtres, détail explicable W03, versions mobile M01 (Paiements, Détail) |
| 1411 | CPT-PAY-2 | CPT-PAY | CPT-PAY-1 | Opus, 35 min | Payer (FIN-L3b) : PayoutConfirmationSheet, lot avec préflight, Validation supplémentaire, auto-payout bloqué, infos manquantes |
| 1420 | CPT-TRES-1 | CPT-TRES | CPT-F | Opus, 35 min | Trésorerie & coffres (FIN-L5a) : W04 et M02 écran 1, 7 coffres, TreasuryVaultCard, StrategicReserveCard et ses indicateurs |
| 1421 | CPT-TRES-2 | CPT-TRES | CPT-TRES-1 | Opus, 35 min | Mouvements entre coffres (FIN-L5b) : TreasuryInternalTransfer, Alimenter la Réserve stratégique, retrait sensible, historique, prévision |
| 1430 | CPT-ENC-1 | CPT-ENC | CPT-F | Opus, 35 min | Encaissements (FIN-L6a) : W05 table avec filtres et panneau détail, M02 écran 2 |
| 1431 | CPT-ENC-2 | CPT-ENC | CPT-ENC-1 | Opus, 35 min | Rapprochement et remboursements (FIN-L6b) : ReconciliationWorkspace, doublon potentiel, avoirs |
| 1440 | CPT-BEN-1 | CPT-BEN | CPT-F | Opus, 35 min | Bénéficiaires vus par le Comptable (FIN-L4a) : W07 profil de paiement masqué, Relancer, Demander une mise à jour, Suspendre |
| 1441 | CPT-BEN-2 | CPT-BEN | CPT-BEN-1 | Opus, 35 min | Recevoir mes paiements (FIN-L4b) : surface personnelle de l'enseignant et du contractuel, notice infos manquantes, bénéficiaire externe invité |
| 1450 | CPT-CTR-1 | CPT-CTR | CPT-F | Opus, 35 min | Contractuels & obligations (FIN-L7) : W06, récurrent et ponctuel, Nouvelle obligation selon délégation, vue des approbations |
| 1460 | CPT-DIR-1 | CPT-DIR | CPT-F | Opus, 35 min | Delta Direction (FIN-L8) : StrategicReservePolicyPanel et FinanceDelegationPolicyPanel dans la Finance Direction existante |
| 1470 | CPT-FUS | CPT | CPT-JOUR, CPT-PAY-2, CPT-TRES-2, CPT-ENC-2, CPT-BEN-2, CPT-CTR-1, CPT-DIR-1 | Opus, 35 min | Fusion Comptable : 6 sous-branches dans ui/comptable-v1, liens d'Aujourd'hui vers les vrais écrans, suite complète |
| 1471 | CPT-COM | CPT | CPT-FUS, COM-FUS | Sonnet, 30 min | Relancer branché sur les vrais Messages métier de Communications V1 (R-FIN-20) |
| 1472 | CPT-CAPT | CPT | CPT-FUS | Sonnet, 35 min | Recette visuelle Comptable : captures 390 et 1440, clair et sombre, 320 texte ×2, RTL, R-FIN-24 à 29 |
| 1473 | CPT-R | VERIF | CPT-CAPT | Opus, 35 min, autre session | Revue croisée Comptable V1 : ordre de regard §59 (16 questions), sécurité §47, recettes R-FIN-01 à 29 |
| 1474 | CPT-RC | CPT | CPT-R | Opus, 35 min | Corrections de la revue Comptable, suite complète et fermeture selon les critères §61 |
| 2017 | CPT-Q | ATTEND | CPT-0 | Directeur | Questions Comptable V1 au directeur (seulement si CPT-0 trouve un point bloquant) |

## Détail

### CPT-0 — Préparation Comptable V1 (FIN-L0) : UX_REVIEW_FINANCE_COMPTABLE_L0, DEVOIR_DE_REGARD_FINANCE, CPT-BR, fichiers par étape

Spec §58 FIN-L0 et §4 : aucune ligne de code. Lire 20_comptable/00_REPRISE.md, la spec V/ et les 11 maquettes V/CPT-H*. Inventaire sur origin/ui/finance-v1 (la plus avancée en Finance) : route /comptable (routes.dart:450, app_router.dart:1020 affiche aujourd'hui ComptePage), AppRole.accountant, shells, Finance foyer / enseignant / Direction (17_finance), composants argent existants (montants, statuts, lignes), ports et démo, tests, tokens. Matrice Garder / Améliorer / Ajouter / Supprimer. Pour chaque écran FIN-CPT-W01 à W07 et M01-M02 : entrée réelle et shell réel. Pour chaque composant §39, dire l'existant à réutiliser (fichier:ligne) ou « à créer ». Livrer dans 20_comptable/ : UX_REVIEW_FINANCE_COMPTABLE_L0.md, DEVOIR_DE_REGARD_FINANCE.md (rubriques §4), CPT-BR.md (contrats serveur : FinanceProvider, PayoutCapabilityPort, TeacherPayableObligation, FinanceDelegationPolicy, coffres, rapprochement), QUESTIONS.md (seulement ce qui bloque, avec recommandation), et compléter 02_DECOUPAGE.md avec la LISTE DES FICHIERS de chaque étape (aucun fichier commun entre deux voies parallèles en dehors de ceux que CPT-F pose une fois pour toutes).

### CPT-F — Socle Comptable (FIN-L1) : branche ui/comptable-v1, shell et navigation du rôle, routes de toutes les surfaces, SensitiveAmount, statuts, view models, fixtures §44, ports neutres

Créer ui/comptable-v1 + worktree D:\RA_TUTEUR\cpt depuis origin/ui/finance-v1 (dernier commit, après FI-VAGUE-CORR), puis les 6 sous-branches poussées sans worktree : ui/cpt-pay, ui/cpt-tres, ui/cpt-enc, ui/cpt-ben, ui/cpt-ctr, ui/cpt-dir. ANTI-CONFLIT : ce socle pose UNE FOIS tout ce que les voies se partageraient : routes et entrées de navigation de toutes les surfaces (pages vides « en préparation » remplacées ensuite), dossiers lib/features/comptable/<module>/ vides par voie, espaces i18n comptable.<module>.* séparés, un fichier de fixtures par module, ports neutres (FinanceProvider, PayoutCapabilityPort, PayoutPort, ReconciliationPort, MessagesMetierPort pour Relancer) avec démo hors production. Composants : SensitiveAmount (masqués par défaut à chaque session, longueur fixe, lu « Montant masqué »), FinanceAmountVisibilityToggle (état de session, jamais conservé), MoneyAmount et FinancialStatusChip en réutilisant l'existant de Finance si présent (CPT-0), statuts §15 et §24.1 lisibles sans couleur. Tests R-FIN-01 à 03. Fait : sous-branches poussées, analyze 0, tests verts.

### CPT-JOUR — Aujourd'hui du Comptable (FIN-L2) : FIN-CPT-W01 et premier écran de M01, file d'attention, alertes, carte Réserve stratégique en lecture

Sur ui/comptable-v1 (worktree D:\RA_TUTEUR\cpt), fichiers lib/features/comptable/aujourdhui/ seulement. Spec §29, §12, §28, §11. Répondre à « Que dois-je faire maintenant ? » : 9 zones, pas de graphiques en surnombre. Chaque ligne ouvre l'écran canonique (règle §5.1) par sa route posée dans CPT-F, sans dépendre du code des autres voies. AvailableTreasurySummary : la Trésorerie libre est le chiffre central, jamais le solde brut comme argent dépensable. Chaque KPI répond à une question opératoire, sinon une ligne dans DEVOIR_DE_REGARD_FINANCE.md.

### CPT-PAY-1 — Paiements à effectuer (FIN-L3a) : liste W02 avec filtres, détail explicable W03, versions mobile M01 (Paiements, Détail)

Branche ui/cpt-pay, worktree D:\RA_TUTEUR\cpt-pay, fichiers lib/features/comptable/paiements/ seulement. Spec §13, §14.4-14.5, §15, §30, §31. Montant en lecture seule, jamais un TextField (R-FIN-16) ; lignes de calcul avec leur source ; « Signaler un écart » sans champ de correction (R-FIN-17) ; encart permanent §31. Consolidation par bénéficiaire, la Classe reste un filtre. Mobile : tables transformées en listes.

### CPT-PAY-2 — Payer (FIN-L3b) : PayoutConfirmationSheet, lot avec préflight, Validation supplémentaire, auto-payout bloqué, infos manquantes

Spec §7.5, §20, §21, §40, §41, §47. La confirmation montre toujours le montant exact (R-FIN-04), jamais « Payer $•••• ». Lot : « Sélectionner tous les paiements prêts », jamais « Payer absolument tout » ; « 18 prêts / 3 exclus », seuls les prêts partent (R-FIN-22, 23). Paiement sensible : « Demander validation ». Le Comptable ne voit pas « Payer » pour lui-même : « Traitement par un autre responsable requis » (R-FIN-15). Aucun « Réussi » sur simple appui : états du port seulement (§5.3). Pas de contournement par fractionnement d'un lot.

### CPT-TRES-1 — Trésorerie & coffres (FIN-L5a) : W04 et M02 écran 1, 7 coffres, TreasuryVaultCard, StrategicReserveCard et ses indicateurs

Branche ui/cpt-tres, worktree D:\RA_TUTEUR\cpt-tres, fichiers lib/features/comptable/tresorerie/ seulement. Spec §8, §9, §11, §32. Titre toujours « Réserve stratégique » (R-FIN-05) ; objectif en mois ou montant fixe (R-FIN-06, 07) ; aucune valeur commerciale codée en dur (R-FIN-08, 09 : 10 USD et 1 000 000 USD rendent tous deux) ; états §49 Réserve.

### CPT-TRES-2 — Mouvements entre coffres (FIN-L5b) : TreasuryInternalTransfer, Alimenter la Réserve stratégique, retrait sensible, historique, prévision

Spec §9.5, §10, §32. Mouvement vers une protection : délégable. Sortie d'un coffre protégé : sensible, « Validation supplémentaire requise » ; retrait de la Réserve sans capability bloqué (R-FIN-10). Interdits §10.4 prouvés par des tests (Fonds clients, Taxes, déficit masqué).

### CPT-ENC-1 — Encaissements (FIN-L6a) : W05 table avec filtres et panneau détail, M02 écran 2

Branche ui/cpt-enc, worktree D:\RA_TUTEUR\cpt-enc, fichiers lib/features/comptable/encaissements/ seulement. Spec §24, §33. États §24.1 ; « Confirmé » seulement sur retour du port (§24.3). Panneau : brut, frais, net, référence, prestataire, foyer, affectation, rapprochement. Réutiliser les lignes de transaction de la Finance Direction si CPT-0 les trouve.

### CPT-ENC-2 — Rapprochement et remboursements (FIN-L6b) : ReconciliationWorkspace, doublon potentiel, avoirs

Spec §25, §26, §48. États : automatique, à vérifier, rapproché, conflit, sans correspondance, doublon potentiel. Remboursements : le Comptable voit et exécute selon la politique, il ne la réécrit pas. Journal par opération (§48) sans inventer d'audit serveur.

### CPT-BEN-1 — Bénéficiaires vus par le Comptable (FIN-L4a) : W07 profil de paiement masqué, Relancer, Demander une mise à jour, Suspendre

Branche ui/cpt-ben, worktree D:\RA_TUTEUR\cpt-ben, fichiers lib/features/comptable/beneficiaires/ seulement. Spec §16, §19, §27.2-27.3, §35. Aucun bouton « Modifier coordonnées » pour le Comptable ni l'Admin (R-FIN-11, 12). Coordonnées masquées (« Orange Money •••• 4423 »). Relancer passe par le MessagesMetierPort posé dans CPT-F (objet « Profil de paiement », message modèle §27.3) : aucune messagerie Finance (R-FIN-21).

### CPT-BEN-2 — Recevoir mes paiements (FIN-L4b) : surface personnelle de l'enseignant et du contractuel, notice infos manquantes, bénéficiaire externe invité

Spec §17, §18, §19, §27.1, §38. Chercher d'abord la route Compte existante (CPT-0) ; le bénéficiaire seul ajoute, remplace, supprime, choisit sa méthode préférée (R-FIN-13). États : aucun moyen, incomplet, en vérification, vérifié, suspendu, action requise. Notice « Informations de paiement à compléter » + « Configurer mes paiements » (R-FIN-19). Externe sans compte : état « Invitation envoyée ». Aucune coordonnée réelle conservée : port neutre.

### CPT-CTR-1 — Contractuels & obligations (FIN-L7) : W06, récurrent et ponctuel, Nouvelle obligation selon délégation, vue des approbations

Branche ui/cpt-ctr, worktree D:\RA_TUTEUR\cpt-ctr, fichiers lib/features/comptable/contractuels/ seulement. Spec §22, §23, §34. Le montant manuel n'existe qu'à la création de l'obligation, figé après approbation (« Karim Studio - Facture #024 - 350 USD » → « Payer 350 USD »). Ajustements enseignants : ligne indépendante avec motif, source, auteur, validation. « Nouvelle obligation » seulement pour les rôles autorisés. Formulaire : préremplir, proposer, saisir en dernier (K-57).

### CPT-DIR-1 — Delta Direction (FIN-L8) : StrategicReservePolicyPanel et FinanceDelegationPolicyPanel dans la Finance Direction existante

Branche ui/cpt-dir, worktree D:\RA_TUTEUR\cpt-dir. Spec §9.2-9.6, §21, §37. Pas de second système Finance Direction : les deux panneaux s'ajoutent aux surfaces existantes de 17_finance (fichiers exacts donnés par CPT-0 ; aucune autre voie ne les touche). Modes de réserve : montant fixe, couverture en mois ; alimentation : désactivée, fixe, pourcentage, jusqu'à l'objectif, proposée ; cadences §9.4. Délégation §21.2. Aucun plafond commercial codé en dur.

### CPT-FUS — Fusion Comptable : 6 sous-branches dans ui/comptable-v1, liens d'Aujourd'hui vers les vrais écrans, suite complète

K-14 : une seule session, merge --no-ff, union i18n + slang, jamais main. Remplacer les pages « en préparation » de CPT-F par les écrans livrés. analyze 0. Suite complète par dossiers sous flutter-verrou, tous les dossiers cités. Carte des fonctions avec routes réelles dans 20_comptable/CARTE_FONCTIONS.md.

### CPT-COM — Relancer branché sur les vrais Messages métier de Communications V1 (R-FIN-20)

Remplacer l'implémentation du MessagesMetierPort par le fil métier contextuel de COM-MSG (fusionné par COM-FUS). Test qui tape « Relancer » depuis la vraie coquille du Comptable et arrive dans le fil « Profil de paiement ».

### CPT-CAPT — Recette visuelle Comptable : captures 390 et 1440, clair et sombre, 320 texte ×2, RTL, R-FIN-24 à 29

Captures de chaque écran W01-W07, M01-M02 et des deux panneaux Direction, montants masqués et affichés, données de démo §44. Ouvrir soi-même chaque capture (K-61). Écarts relevés en lignes, pas corrigés dans cette étape.

### CPT-R — Revue croisée Comptable V1 : ordre de regard §59 (16 questions), sécurité §47, recettes R-FIN-01 à 29

Par une session qui n'a écrit aucun code de la vague. Rapport 20_comptable/REVUE_CPT-R.md : chaque R-FIN avec preuve (test ou capture), chaque question §59 avec réponse.

### CPT-RC — Corrections de la revue Comptable, suite complète et fermeture selon les critères §61

Corriger les écarts de CPT-R, relancer toute la suite (K-29), citer le dernier passage. Les critères §61 cochés un par un avec preuve.

### CPT-Q — Questions Comptable V1 au directeur (seulement si CPT-0 trouve un point bloquant)

Une page web unique (K-21), chaque question avec exemple et recommandation. Les parties non bloquées continuent (spec §4).

## Règle de style et frontière (toutes étapes)

STYLE (directeur 04/10, K-63) : maquette = composition seulement (zones, proportions, densité, place des actions) ; thème Rewayah en vigueur, aucune couleur, police, rayon, ombre ou identité « banque » venue des maquettes (K-37 : sinon une ligne TH-2) ; shell réel du rôle Comptable. FRONTEND SEULEMENT (spec §1) : aucun serveur, aucune vraie coordonnée, aucun vrai paiement. Sources : 20_comptable/00_REPRISE.md.
