# Comptable V1 : découpage

Étapes du tableau YAADEN, ordre 1400 à 1474, plus CPT-Q (ATTEND, 2017). CPT-0 complète ce fichier avec la liste des fichiers de chaque étape : voir « Fichiers par étape » en fin de fichier (fait le 04/10).

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

## Fichiers par étape (CPT-0, 04/10/2026)

Écrit par CPT-0 sur `origin/ui/finance-v1` @ `5198107f` (numéros de ligne à revérifier par CPT-F après FI-VAGUE-CORR). Justification des choix : `UX_REVIEW_FINANCE_COMPTABLE_L0.md` (§3 shell, §4 composants, §5 écrans) et `DEVOIR_DE_REGARD_FINANCE.md`.

### Règle de propriété

1. **CPT-F crée tous les fichiers partagés** (liste A) et **un fichier de départ par voie** pour chaque page, port et fichier de démonstration (liste B), avec leur API définitive (nom de classe, constructeur, méthodes du port, nom de la fonction de surcharges de démonstration).
2. Après CPT-F, **chaque fichier a un seul propriétaire** : la liste A est gelée (aucune voie ne la modifie ; un besoin = une ligne « pour CPT-FUS » dans le rapport de la voie, sans modifier), sauf les deux fichiers dont le propriétaire est nommé ; chaque fichier de la liste B appartient à sa voie seule.
3. Une voie peut **créer** tout nouveau fichier sous ses dossiers (liste C) ; elle **importe** les fichiers des autres sans jamais les modifier.
4. Trois fichiers sont modifiés par plusieurs voies et **jamais fusionnés à la main** : `assets/i18n/fr.i18n.json` (chaque voie n'écrit que dans son sous-bloc `comptable.<module>`), `tool/libelles_sources.json`, `lib/core/i18n/strings*.g.dart` (régénérés). CPT-FUS fait l'union, puis `dart run slang`. `assets/i18n/ar.i18n.json` n'est touché par personne.
5. Interdits de toutes les étapes : `main`, PR, `supabase/`, `.github/`, `vercel.json`, `pubspec.yaml`, valeurs des jetons `lib/core/theme`, Coran, `dart_define.json`, secrets (K-19) ; aucun fichier de la vague FIN hors de ceux nommés ici ; aucune couleur, police, durée inventée (K-37, K-63).

### A. Fichiers partagés posés par CPT-F (gelés ensuite)

| Fichier | Ce que CPT-F y pose | Propriétaire après CPT-F |
|---|---|---|
| `lib/core/router/routes.dart` | Constantes et aides de toutes les routes : `/comptable`, `/comptable/paiements`, `/comptable/paiements/obligation/:obligationId`, `/comptable/paiements/contractuels`, `/comptable/paiements/contractuels/nouvelle`, `/comptable/paiements/contractuels/obligation/:obligationId`, `/comptable/paiements/beneficiaires`, `/comptable/paiements/beneficiaires/:beneficiaireId`, `/comptable/tresorerie`, `/comptable/tresorerie/encaissements`, `/comptable/tresorerie/encaissements/:encaissementId`, `/comptable/tresorerie/rapprochement`, `/compte/paiements-recus`, `/admin/finance/reserve-delegation`, `/demo/comptable` ; aides de filtre (`?filtre=`, `?type=`, `?classe=`, `?action=alimenter`, `?vue=attention`) ; `estTacheFocalisee` si une page de détail cache la barre basse. | gelé |
| `lib/core/router/app_router.dart` | Coquille `StatefulShellRoute.indexedStack` du Comptable (modèle contrôleur, `:962`) à trois branches + `/compte` ; toutes les routes ci-dessus vers les pages de la liste B (les constructeurs ne prennent que des `String` : identifiant, filtre brut) ; remplacement de `ComptePage` nue (`:1256-1260`) ; `/compte/paiements-recus` en `_CoquilleSecondaire` ; `/admin/finance/reserve-delegation` dans `AdminShell` ; `...routesDemoComptable(Env.environnement)`. | gelé |
| `lib/core/widgets/nav_shell.dart` | `destinationsPour(AppRole.accountant)` : Aujourd'hui, Paiements, Trésorerie, Compte (`:217`), commentaire mis à jour. | gelé |
| `lib/core/admin/admin_domaine.dart` | Troisième entrée de `ongletsFinance()` (`:181`) : « Réserve et délégation ». | gelé |
| `lib/features/admin_finance/finance_page.dart` | Valeur `OngletFinance.reserveDelegation` et son cas vers `ReserveDelegationPage`. Seule retouche d'un fichier FIN. | gelé |
| `lib/features/demo/demo_finance_page.dart` | Ajout de `...surchargesDemoDirection()` aux surcharges de la démonstration Finance, et de l'onglet dans ses adresses. | gelé |
| `lib/core/icons/app_icons.dart` | **Toutes** les icônes de la vague (`UX_REVIEW` §6.1). | gelé |
| `lib/core/comptable/visibilite_montants.dart` | État de session de la visibilité (Riverpod, en mémoire, remis à masqué à chaque session ; jamais `PortPreferencesPersistantes`). | gelé |
| `lib/core/comptable/statuts_comptable.dart` | Énumérations : 15 états du paiement sortant (§15), 9 états d'encaissement (§24.1), 6 états de rapprochement (§25), 6+1 états du profil de paiement (§38 + « Invitation envoyée »), 5 retours de capacité (§42), actions permises et raisons de blocage (`CPT-BR.md` §1), types d'alerte (§28) avec leur liste (DR-10), états de la Réserve (§49). | gelé |
| `lib/core/comptable/navigation_comptable.dart` | `ongletsPaiementsComptable()` (À effectuer, Contractuels, Bénéficiaires), `ongletsTresorerieComptable()` (Coffres, Encaissements, Rapprochement). | gelé |
| `lib/core/widgets/montant_sensible.dart` | `SensitiveAmount` (masque de longueur fixe par devise, « Montant masqué », chiffres tabulaires). | gelé |
| `lib/core/widgets/bascule_montants.dart` | `FinanceAmountVisibilityToggle` (« Afficher les montants » / « Masquer les montants »). | gelé |
| `lib/core/widgets/pastilles_comptable.dart` | Habits de `StatusPill` pour chaque énumération d'état ci-dessus, dont `FinanceProviderStatus`. | gelé |
| `lib/core/widgets/ligne_destination.dart` | `LigneDestinationMasquee` (`PaymentMethodRow` du personnel). | gelé |
| `lib/core/widgets/comptable/ligne_activite.dart` | `FinanceActivityRow` (§48). | gelé |
| `lib/core/widgets/comptable/resume_tresorerie.dart` | `AvailableTreasurySummary` (Trésorerie libre au centre). | **CPT-TRES-1** (CPT-JOUR importe seulement) |
| `lib/core/widgets/comptable/carte_reserve_strategique.dart` | `StrategicReserveCard` en lecture (titre fixe, objectif selon le mode). | **CPT-TRES-1** (CPT-JOUR importe seulement) |
| `lib/features/demo/demo_comptable_page.dart` | `routesDemoComptable` (`/demo/comptable?ecran=...&montants=affiches`, aucune route en production) et l'assemblage des surcharges de chaque voie. | gelé |
| `lib/features/demo/comptable/socle_comptable_demo.dart` | Personnes et identifiants communs (15 enseignants, 5 contractuels, le Comptable lui-même, prestataires neutres), pour que les fichiers de démonstration des voies parlent des mêmes personnes. | gelé |
| `test/router/navigation_test.dart` | `:139` : le Comptable a quatre destinations. | gelé |
| Tests du socle | `test/core/widgets/montant_sensible_test.dart`, `test/core/comptable/visibilite_montants_test.dart` (R-FIN-01 à 03), `test/core/widgets/pastilles_comptable_test.dart`, `test/features/comptable/socle/routes_comptable_test.dart` (chaque route ouvre sa page dans la bonne coquille). | gelé |

### B. Fichiers de départ posés par CPT-F, puis propriété d'une voie

Chaque page est posée « en préparation » (un `PageShell` honnête, aucun chiffre) avec son constructeur définitif ; chaque port avec son interface complète (`CPT-BR.md`) et son implémentation neutre `CapaciteIndisponible('CPT-BR-nn')` ; chaque fichier de démonstration avec une implémentation vide du port et sa fonction de surcharges.

| Voie (étapes) | Pages | Ports (`lib/core/capacites/`) | Démonstration (`lib/features/demo/comptable/`) |
|---|---|---|---|
| CPT (CPT-JOUR) | `lib/features/comptable/aujourdhui/aujourdhui_page.dart` (`AujourdhuiComptablePage({String? vue})`) | `port_aujourdhui_comptable.dart` (CPT-BR-03) | `aujourdhui_demo.dart` |
| CPT-PAY (1, 2) | `lib/features/comptable/paiements/paiements_page.dart` (`PaiementsAEffectuerPage({String? filtre, String? type, String? classe})`), `lib/features/comptable/paiements/detail_paiement_page.dart` (`DetailPaiementPage({required String obligationId})`) | `port_obligations_payables.dart` (01), `port_payout.dart` (02), `port_capacite_payout.dart` (10) | `paiements_demo.dart` |
| CPT-TRES (1, 2) | `lib/features/comptable/tresorerie/tresorerie_page.dart` (`TresoreriePage({String? action})`) | `port_tresorerie.dart` (04, 05), `port_politique_reserve.dart` (12, **lecture** ; l'écriture `enregistrer` est posée par CPT-F et utilisée par CPT-DIR-1 sans modifier le fichier) | `tresorerie_demo.dart` |
| CPT-ENC (1, 2) | `lib/features/comptable/encaissements/encaissements_page.dart` (`EncaissementsPage({String? filtre})`), `.../detail_encaissement_page.dart` (`DetailEncaissementPage({required String encaissementId})`), `.../rapprochement_page.dart` (`RapprochementPage()`) | `port_encaissements.dart` (07, 15), `port_rapprochement.dart` (14) | `encaissements_demo.dart` |
| CPT-BEN (1, 2) | `lib/features/comptable/beneficiaires/beneficiaires_page.dart` (`BeneficiairesPage({String? filtre})`), `.../profil_paiement_page.dart` (`ProfilPaiementPage({required String beneficiaireId})`), `lib/features/paiements_recus/recevoir_paiements_page.dart` (`RecevoirPaiementsPage()`) | `port_beneficiaires_paiement.dart` (06), `port_relance_paiement.dart` (11), `port_mes_moyens_paiement.dart` (16) | `beneficiaires_demo.dart` |
| CPT-CTR (1) | `lib/features/comptable/contractuels/contractuels_page.dart` (`ContractuelsPage({String? onglet})`), `.../obligation_contractuel_page.dart` (`ObligationContractuelPage({required String obligationId})`), `.../nouvelle_obligation_page.dart` (`NouvelleObligationPage()`) | `port_obligations_contractuels.dart` (08) | `contractuels_demo.dart` |
| CPT-DIR (1) | `lib/features/admin_finance/reserve_delegation_page.dart` (`ReserveDelegationPage()`) | `port_delegation_finance.dart` (13), `port_validations_finance.dart` (09, interface seulement ; son écran Direction attend CPT-Q1) | `direction_demo.dart` |

`port_politique_reserve.dart` est le seul port lu par deux voies (TRES lit les indicateurs, DIR écrit la politique) : CPT-F le pose **complet** (CPT-BR-12) et il est **gelé** ; un champ manquant = ligne pour CPT-FUS.

### C. Dossiers et fichiers que chaque voie crée et modifie seule

| Étape | Branche / worktree | Crée et modifie (en plus de sa liste B) | Tests | i18n | Ne touche jamais |
|---|---|---|---|---|---|
| CPT-JOUR | `ui/comptable-v1` / `cpt` | `lib/features/comptable/aujourdhui/**` (file d'attention `FinanceAttentionQueue` sur `SignalRow`, alertes, échéances, colonne prestataires, accès rapides) | `test/features/comptable/aujourdhui/**` | `comptable.aujourdhui.*` | les dossiers des autres voies ; `resume_tresorerie.dart` et `carte_reserve_strategique.dart` (import seulement) |
| CPT-PAY-1 | `ui/cpt-pay` / `cpt-pay` | `lib/features/comptable/paiements/**` (liste W02, `PayableObligationRow`, filtres, barre de sélection, détail W03, lignes de calcul, « Signaler un écart », mobile) | `test/features/comptable/paiements/**` (R-FIN-16, 17, 18) | `comptable.paiements.*` | `lib/features/comptable/contractuels/**` |
| CPT-PAY-2 | `ui/cpt-pay` / `cpt-pay` | `lib/features/comptable/paiements/confirmation/**` (`PayoutConfirmationSheet`, préflight du lot, suivi), mêmes fichiers que PAY-1 | idem (R-FIN-04, 14, 15, 22, 23) | idem | idem |
| CPT-TRES-1 | `ui/cpt-tres` / `cpt-tres` | `lib/features/comptable/tresorerie/**` (W04, `TreasuryVaultCard`, sept coffres, prévision, mobile) ; propriétaire de `resume_tresorerie.dart` et `carte_reserve_strategique.dart` | `test/features/comptable/tresorerie/**` (R-FIN-05 à 09) | `comptable.tresorerie.*` | `port_politique_reserve.dart` (gelé) |
| CPT-TRES-2 | `ui/cpt-tres` / `cpt-tres` | `lib/features/comptable/tresorerie/transfert/**` (`TreasuryInternalTransfer`, Alimenter, retrait sensible, historique) | idem (R-FIN-10, interdits §10.4) | idem | idem |
| CPT-ENC-1 | `ui/cpt-enc` / `cpt-enc` | `lib/features/comptable/encaissements/**` (W05, filtres, panneau détail, mobile) | `test/features/comptable/encaissements/**` | `comptable.encaissements.*` | les lignes de transaction de la vague FIN (`ligne_transaction.dart`, `ligne_allocation.dart` : import seulement) |
| CPT-ENC-2 | `ui/cpt-enc` / `cpt-enc` | `lib/features/comptable/encaissements/rapprochement/**` (`ReconciliationWorkspace`, doublon, remboursements et avoirs) | idem | idem | idem |
| CPT-BEN-1 | `ui/cpt-ben` / `cpt-ben` | `lib/features/comptable/beneficiaires/**` (W07, `BeneficiaryPaymentProfileCard`, Relancer, Demander une mise à jour, Suspendre) | `test/features/comptable/beneficiaires/**` (R-FIN-11, 19, 21) | `comptable.beneficiaires.*` | `port_messages_metier.dart` de Communications (absent de la base) |
| CPT-BEN-2 | `ui/cpt-ben` / `cpt-ben` | `lib/features/paiements_recus/**` (`BeneficiaryPaymentSetup`, états §38, notice §27.1, externe invité) ; **seules retouches de fichiers existants** : une ligne « Recevoir mes paiements » dans `lib/features/profil_enseignant/profil_enseignant_page.dart` et une rubrique dans `lib/features/compte/compte_page.dart`, chacune affichée selon une capacité rendue par le port, jamais selon le rôle | `test/features/paiements_recus/**` (R-FIN-13, 19) | `comptable.beneficiaires.*` (sous-bloc `recevoir`) | `revenus_enseignant_page.dart` (DR-14) |
| CPT-CTR-1 | `ui/cpt-ctr` / `cpt-ctr` | `lib/features/comptable/contractuels/**` (W06, onglets, formulaire Nouvelle obligation K-57, approbations, mobile) ; « Payer » navigue vers `Routes` de W03, aucun composant de paiement (DR-12) | `test/features/comptable/contractuels/**` | `comptable.contractuels.*` | `lib/features/comptable/paiements/**` |
| CPT-DIR-1 | `ui/cpt-dir` / `cpt-dir` | `lib/features/admin_finance/reserve_delegation/**` (`StrategicReservePolicyPanel`, `FinanceDelegationPolicyPanel`) ; si CPT-Q1 est « oui » : `lib/features/admin_finance/validations/**` (la route et l'onglet « À valider » sont alors posés par CPT-F si la réponse arrive avant lui, sinon par CPT-FUS sur la ligne écrite par CPT-DIR-1) | `test/features/admin_finance/reserve_delegation/**` (R-FIN-08, 09 côté politique ; R-FIN-12 si CPT-Q1 oui) | `comptable.direction.*` | `politiques_commerciales.dart`, `vue_globale_finance.dart`, `finance_page.dart` (gelé après CPT-F) |

**Vérification d'absence de chevauchement** : les six sous-branches écrivent dans des dossiers disjoints (`comptable/paiements`, `comptable/tresorerie`, `comptable/encaissements`, `comptable/beneficiaires` + `paiements_recus` + deux lignes dans `profil_enseignant_page.dart` et `compte_page.dart`, `comptable/contractuels`, `admin_finance/reserve_delegation`) ; CPT-JOUR, sur la branche de base, n'écrit que dans `comptable/aujourdhui`. Les seuls fichiers touchés par plusieurs voies sont les trois de la règle 4, fusionnés par régénération.

### D. Étapes de fin

| Étape | Fichiers |
|---|---|
| CPT-FUS | merges `--no-ff` des six sous-branches dans `ui/comptable-v1` ; union de `fr.i18n.json` et `tool/libelles_sources.json`, `dart run slang` ; lignes « pour CPT-FUS » des voies (routes, onglets, icônes manquantes) dans les fichiers de la liste A ; liens d'Aujourd'hui vérifiés vers les vraies pages ; pilotage `20_comptable/CARTE_FONCTIONS.md`. |
| CPT-COM | `port_relance_paiement.dart` remplacé par `PortMessagesMetier` (puis supprimé : un seul port), page de fil dans la coquille du Comptable (route posée ici, dans la liste A, par cette étape seule), test « Relancer » → fil « Profil de paiement ». |
| CPT-CAPT | `test/features/comptable_recette/**` (captures 390 / 1440, clair / sombre, 320 à 200 %, RTL, montants `_masques` et `_affiches`) ; pilotage `20_comptable/captures/`. |
| CPT-R | pilotage `20_comptable/REVUE_CPT-R.md` seulement. |
| CPT-RC | les fichiers désignés par la revue, dans le respect des propriétaires ci-dessus. |
