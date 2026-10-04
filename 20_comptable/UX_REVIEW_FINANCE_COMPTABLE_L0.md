# Comptable V1 : revue UX avant code (FIN-L0, étape CPT-0)

Écrit le 04/10/2026 par la session cloud 01B8we8b (étape CPT-0), **en lecture seule** : aucune ligne de code, aucun fichier hors de `20_comptable/`.

- **Code inventorié** : `origin/ui/finance-v1` @ `5198107f` (dernier commit : FI-COUPE-2). FI-VAGUE-CORR est encore en cours : CPT-F revérifie les numéros de ligne cités ici sur le commit d'où il part (les noms de classes et de fichiers, eux, ne bougent pas).
- **Sources** : spec `V/REWAYAH_FINANCE_OPERATIONNELLE_COMPTABLE_V1.md` (ci-dessous « spec §n ») ; planches `V/CPT-H00` à `CPT-H08` (toutes ouvertes et regardées) ; `17_finance/00_REPRISE.md` ; `19_communications/02_DECOUPAGE.md` et `COM-BR.md` (pour Relancer).
- **Règle de style** (K-63, spec §3) : une planche vaut pour la composition (ordre des zones, proportions, densité, place des actions, relation liste / détail / contexte), jamais pour une couleur, une police, un rayon, une ombre, une pastille colorée, un fond ou un shell. Ces écarts ne font **pas** de ligne TH-2 (K-63). Le shell est celui que CPT-F pose pour le rôle (§3 ci-dessous).

Fichiers livrés avec celui-ci : `DEVOIR_DE_REGARD_FINANCE.md` (constats DR-01 à DR-24), `CPT-BR.md` (contrats serveur), `QUESTIONS.md` (CPT-Q1, seul point qui attend le directeur), `02_DECOUPAGE.md` complété (fichiers par étape).

---

## 1. Inventaire de l'existant (spec §58 FIN-L0)

### 1.1 Le Comptable aujourd'hui

| Élément | Où | Constat |
|---|---|---|
| Rôle | `lib/core/domain/enums.dart:14` `AppRole.accountant` ; session `lib/core/session/session_controleur.dart:28` | Existe, lu depuis le JWT, mode `standard`. |
| Route | `lib/core/router/routes.dart:599` `Routes.comptable = '/comptable'` ; racine `:724`, préfixe réservé `:735` | La fiche CPT-0 citait `routes.dart:450` : la ligne a bougé avec la vague Finance. |
| Écran | `lib/core/router/app_router.dart:1256-1260` : `/comptable` rend `ComptePage` **sans aucun chrome** | La fiche citait `app_router.dart:1020`. Le Comptable n'a ni coquille, ni destination : il atterrit sur la page Compte nue. |
| Navigation | `lib/core/widgets/nav_shell.dart:217` : `AppRole.accountant \|\| AppRole.admin => const <Destination>[]` ; `secondairesPour` vide (`:265`) | Aucune destination. `_CoquilleSecondaire` (`app_router.dart:1471-1525`) rend un `NavShell` vide pour lui sur `/compte`. |
| Compte | `lib/features/compte/compte_page.dart:789-795` (espace « comptable »), libellés `t.compte.roles.accountant`, `t.compte.roleDetail.accountant` (« Gère les paiements et les factures ») ; `lib/features/compte/espaces_compte.dart:83` | Rien d'autre. |
| Préfixe | `lib/core/router/redirection.dart:226` (`Routes.prefixePour(role)`) | Toute route Comptable vit sous `/comptable/...` ; l'admin ne peut pas l'ouvrir (et inversement). Conséquence en DR-03. |
| Tests | `test/router/navigation_test.dart:139` (`AppRole.accountant: <String>[]`), `test/features/compte_test.dart:188`, `test/features/connexion_test.dart:34`, `test/features/controleur/espaces_controleur_test.dart:191` | `navigation_test.dart:139` **devra changer** dans CPT-F (le rôle reçoit des destinations). |
| Contrats antérieurs | `17_finance/FI-BR.md` FI-BR-13 ; règle FI23 (`17_finance/00_REPRISE.md:254`) « le comptable lit la même Finance, jamais un second système » | La spec §0 remplace cette définition « trop étroite » : le Comptable a son bureau opérationnel, mais les données canoniques restent partagées (DR-02). |

### 1.2 Finance déjà livrée (vague 17_finance, à ne pas doubler)

| Domaine | Fichiers (classe:ligne) | Ce qu'on en garde pour le Comptable |
|---|---|---|
| Finance foyer (tuteur) | `lib/features/foyer/finances_foyer.dart:37` `financesFoyerProvider`, `:70` `SyntheseSoldesFoyer` ; `lib/features/foyer/fiche/finances_page.dart:50` `FinancesElevePage` ; `recharge_foyer.dart:47` `RechargeFoyerPage` ; `resultat_recharge.dart:47` `ResultatRechargePage` ; `lib/features/compte/paiements_page.dart:47` `PaiementsComptePage` | Rien n'est touché. Les **encaissements** du Comptable sont la face « reçue » des recharges du foyer : même source serveur à BR-1 (CPT-BR-07), écrans différents. |
| Finance élève adulte | `lib/features/mon_espace_adulte/mes_finances_page.dart:35` | Rien. |
| Accès / période financée | `lib/features/acces_finance/acces_finance.dart:101`, `:196`, `:216` | Rien. |
| Finance enseignant | `lib/features/revenus_enseignant/revenus_enseignant_page.dart:56` `RevenusEnseignantPage` (route `Routes.enseignantRevenus`, `routes.dart:394`, ouverte depuis le Profil `profil_enseignant_page.dart:71`) ; port `lib/core/capacites/port_revenus_enseignant.dart:94` | Reste « Revenus **estimés** ». La rémunération **calculée et due** (`TeacherPayableObligation`) est un autre objet : risque de deux chiffres pour la même paie (DR-14). « Recevoir mes paiements » est une surface distincte (CPT-BEN-2). |
| Finance Direction | `lib/features/admin_finance/finance_page.dart:30` `FinancePage` (onglets `OngletFinance`, `:10`) ; `vue_globale_finance.dart:54` `VueGlobaleFinanceBloc`, `:84` `VueGlobaleFinanceContenu` ; `politiques_commerciales.dart:102` `PolitiquesCommercialesBloc`, `:222` contenu ; onglets `lib/core/admin/admin_domaine.dart:181` `ongletsFinance()` ; routes `app_router.dart:1137-1148` (`/admin/finance`, `/admin/finance/politiques`) ; port `lib/core/capacites/port_finance_direction.dart:109` | **Seul endroit** où CPT-DIR-1 ajoute ses deux panneaux (dans un **troisième onglet** posé par CPT-F, §5.9). La Vue globale répond à « où en est le mois » (stratégique) ; Aujourd'hui du Comptable répond à « que dois-je faire maintenant » (opérationnel) : pas de doublon si Aujourd'hui ne reprend ni revenu, ni marge (DR-08). |
| Démonstration | `lib/features/demo/finance_demo.dart:94` `DonneesFinanceDemo` (1 304 lignes), `:1297` `FinanceDirectionDemo` ; `demo_finance_page.dart:31` `routesDemoFinance` (`/demo/finance`) ; garde `mode_demonstration.dart:71` `environnementAutoriseDemo` ; `?demo=admin` `lib/main.dart:100` | Même mécanisme pour le Comptable : `/demo/comptable` posé par CPT-F, aucune route en production (K-09). |

### 1.3 Composants d'argent et de structure existants

| Composant | Fichier:ligne | Note |
|---|---|---|
| `Montant` (entier en unités mineures + ISO 4217) | `lib/core/finance/montant.dart:14` | La base de tout montant Comptable. Jamais de `double`. |
| Formateur unique | `lib/core/finance/format_montant.dart:76` `formaterMontant`, `:36` `decimalesDe`, `:67` `symboleDe` | `SensitiveAmount` masque **par-dessus**, sans second formateur. |
| `MontantArgent` (`MoneyAmount`) | `lib/core/widgets/montant_argent.dart:31`, tailles `:10` | Chiffres tabulaires (`AppTypography.tabulaire`), signe explicite. Base de `SensitiveAmount`. |
| `StatusPill` + `TonEtat` | `lib/core/widgets/status_pill.dart:60`, `:13` | Point + mot, jamais la couleur seule. Base de toutes les pastilles §15, §24.1, §25. |
| `PastilleFinanciere` | `lib/core/widgets/pastille_financiere.dart:17` | Typée `EtatFinancier` (profil élève) : **non réutilisable** pour un paiement sortant ; on fait un habit de `StatusPill`, pas une recopie. |
| `LigneFinance` (`FinanceLineItem`) | `lib/core/widgets/ligne_finance.dart:21` | Idéale pour les lignes de calcul de W03 (« Classe Al-Fajr 100 USD ») si elle accepte un montant masqué : voir §4, « à étendre par CPT-F ». |
| `LigneTransaction` (`TransactionRow`) | `lib/core/widgets/ligne_transaction.dart:13` | Montant toujours signé, non masquable. `FinanceActivityRow` s'en inspire sans la modifier (fichier de la vague FIN). |
| `LigneAllocation` | `lib/core/widgets/ligne_allocation.dart:13` | Répartition par profil d'une recharge : utile dans le panneau détail d'un encaissement (W05). |
| `LigneMoyenPaiement` (`PaymentMethodRow`) | `lib/core/widgets/ligne_moyen_paiement.dart:19` | Choix d'un rail **pour payer** (tuteur), pas une destination masquée : non réutilisable pour `Orange Money •••• 4423`. |
| `ResumeSoldes` (`BalanceSummary`) | `lib/core/widgets/resume_soldes.dart:19` | Typé `SyntheseFoyer` : non réutilisable pour la trésorerie. |
| `LigneCleValeur` | `lib/core/widgets/ligne_cle_valeur.dart:20` | Socle de toute ligne « clé / valeur ». |
| `CarteLignes`, `CarteGroupee`, `GroupeReglages` | `carte_lignes.dart:16`, `carte_groupee.dart:34`, `groupe_reglages.dart:108` | Une carte, des filets (K-55). |
| `SignalRow` | `lib/core/widgets/signal_row.dart:21` | « Une ligne à traiter : icône, phrase, ancienneté, chevron » : c'est exactement `FinanceAttentionQueue` / `FinanceAlertRow`. |
| `DataCollection` | `lib/core/widgets/data_collection.dart:96` (`ColonneDonnees` `:37`, `rendu` riche) | Tableau à 1440, cartes sous le bureau : tables W02, W05, W06. **Pas de colonne de sélection** native : la case se pose par `rendu` dans la voie qui en a besoin (CPT-PAY-1). |
| `FilterPill`, `MenuFiltre` | `filter_pill.dart:25`, `menu_filtre.dart:54` | Filtres §30, §33. |
| `SousNavigationDomaine` | `lib/core/widgets/sous_navigation_domaine.dart:25` | Onglets d'un domaine (patron de `FinancePage`). Base de la navigation de second niveau du Comptable (§3). |
| `PageShell` | `lib/core/widgets/page_shell.dart:45` | Toute page Comptable est une `PageShell` dans la coquille du rôle. |
| `AppBottomSheet` | `lib/core/widgets/app_bottom_sheet.dart:48` (`FormeModale` `:21`) | Feuille mobile / dialogue bureau : `PayoutConfirmationSheet`, `TreasuryInternalTransfer`. |
| `ChoiceCardGroup` | `lib/core/widgets/choice_card_group.dart:78` | Choix de coffre, de méthode préférée (K-57). |
| `ActionPrincipale`, `RangeeActions` | `action_principale.dart:52`, `:415` | Un seul bouton plein par zone (K-56). |
| `ConfirmDestructive` | `confirm_destructive.dart:27` | « Suspendre le paiement ». |
| `BandeauAttention` | `bandeau_attention.dart:24` | Notice « Informations de paiement à compléter » (§27.1). |
| `AvatarNom`, `IdentiteProfil` | `avatar_nom.dart:45`, `identite_profil.dart:146` | Identité d'un bénéficiaire (W03, W07). `IdentiteProfil` porte l'accent **de profil élève** : ne pas l'utiliser pour un enseignant (FI-ACCENT-1). |
| États | `etat_systeme.dart:79`, `bloc_asynchrone.dart:41`, `skeleton.dart:27`, `empty_state.dart:46`, `offline_banner.dart:35`, `ecran_resultat.dart:31` | Les onze états de §49 se font avec eux. |
| `StatTile` | `stat_tile.dart:22` | « Un chiffre qui mène à son écran d'action » : KPI d'Aujourd'hui seulement s'ils ouvrent un écran (K-42, DR-08). |
| `LienFleche`, `SectionHeader`, `MenuActions` | `lien_fleche.dart:20`, `section_header.dart:20`, `menu_actions.dart:37` | « Voir tout -> », titres de zone, actions rares « … ». |
| Icônes | `lib/core/icons/app_icons.dart` : `oeil`, `masquer`, `finance`, `verrou`, `info`, `avertissement`, `succes`, `historique`, `discussion`, `invitationEnvoyee`, `chevron` existent | Manquent au moins : coffre, transit, entrée, sortie, lien (rapprochement), contractuel, export. CPT-F les ajoute **toutes** d'un coup (§6.1). |
| Typographie | `lib/core/theme/app_typography.dart:7-28` : **DM Sans titres, Plus Jakarta Sans le reste** | R-FIN-27 et R-FIN-28 sont déjà tenus par le thème : aucune ligne TH-2. |
| Graphiques | aucune bibliothèque dans `pubspec.yaml` ; `vue_globale_finance.dart:7-8` « Aucun graphique » | Les histogrammes et anneaux des planches ne se font pas (DR-09). `pubspec.yaml` est interdit (K-19). |

### 1.4 Ports, démonstration, tests, jetons

- **Ports** : convention `lib/core/capacites/port_*.dart`, neutre par défaut (`CapaciteIndisponible`, `capacite_indisponible.dart:22`, avec la référence BR attendue), réel seulement dans `main.dart` (K-09). Aucun port Comptable n'existe. Les ports à créer sont listés dans `CPT-BR.md` §2.
- **Relancer** : la vague Communications pose `PortMessagesMetier` (`lib/features/com_messages/port_messages_metier.dart`, méthode `filPourObjet(typeObjet, objetId)`, COM-BR-01) sur `ui/communications-v1`, absente de `ui/finance-v1`. CPT-F pose un port mince de relance au même dessin ; CPT-COM le remplace (CPT-BR-11).
- **Démonstration** : modèle `demo_finance_page.dart` + `finance_demo.dart`. Données Comptable §44 à créer (15 enseignants, 5 contractuels, etc.).
- **Tests** : 471 fichiers de test sur la branche ; dernière suite complète citée 5 815 / 0 (FI-12, `57dbdcc0`). Finance : `test/features/finance_recette/`, `test/features/admin_finance/`, `test/core/widgets/composants_argent_test.dart`, `lignes_finance_test.dart`, `test/core/finance/format_montant_test.dart`. Captures : `test/capture/outil_capture.dart`.
- **Jetons** : `tool/verifier_jetons.dart` ; aucune valeur nouvelle permise (K-37). Les libellés : `assets/i18n/fr.i18n.json` (un seul fichier, `flat_map`, `slang.yaml`), plus `tool/libelles_sources.json`. `ar.i18n.json` n'est pas touché avant LG-1.

---

## 2. Les planches, une par une (composition seulement)

Toutes les planches montrent : « Réserve 3 mois » comme titre (interdit, spec §9.1, R-FIN-05) ; des icônes dans des pastilles de couleur (vert, orange, rose, bleu) ; des barres et anneaux colorés ; des montants masqués de **longueur variable** (`$•••••`, `$•• •••,••`, `$••••••••`) ; des logos de prestataires. Rien de cela n'est repris : tons du thème Rewayah (`TonEtat`), longueur de masque fixe (DR-06), aucun logo (DR-21).

| Planche | Ce qu'on prend | Ce qu'on refuse (en plus de la liste commune) |
|---|---|---|
| **H00** (sombre intégral, désignée référence prioritaire par la spec §3.3) | **Confirmée comme référence de composition de W01.** En-tête : fil d'Ariane, titre, sous-titre, « Montants masqués » + action à droite ; rangée « Trésorerie » pleine largeur ; trois colonnes « À traiter aujourd'hui » (liste compteur + phrase + chevron), « Échéances proches » (frise datée), colonne droite « prestataires » + « Activité récente » + « Accès rapides ». | Barre de recherche globale et ⌘K (DR-18) ; « Exporter le rapport » (DR-17) ; graphique « Flux de trésorerie » (DR-09) ; entrée « Administration » et « Rapports » dans la barre ; sous-menu Finance à 8 entrées (DR-01) ; « +12 % vs mois dernier » (DR-08) ; deux « Disponible » / « Réservée » à côté des coffres (DR-07). |
| **H01** (clair, sidebar 10 entrées) | **Le patron de navigation** : barre du rôle + **onglets de domaine dans la page** (Aujourd'hui, Paiements, Trésorerie, Encaissements, Contractuels) ; carte Réserve à droite de la trésorerie ; trois colonnes Paiements / Encaissements / Alertes ; tableau « Activité récente » en bas. | Classes, Calendrier, Apprenants, Bibliothèque, Devoirs dans la barre du Comptable (pas ses fonctions) ; sélecteur de date « Aujourd'hui » (DR-08) ; œil par tuile en plus du contrôle global (DR-06) ; statut « Payé » (vocabulaire §15 seulement). |
| **H02** (clair) | Liste « À payer aujourd'hui » avec bénéficiaire, rôle, montant, état ; « Alertes et actions » en phrases. | Bouton « Payer » sur la ligne d'Aujourd'hui (DR-11) ; « Alimenter la réserve » plein dans Aujourd'hui (l'action vit en W04, Aujourd'hui y mène) ; « Bonjour Amadou 👋 » (aucun emoji de salutation dans les en-têtes existants) ; « Retour à l'app ». |
| **H03** (clair) | Grille des **sept coffres** (3 × 3) : bon ordre pour W04 ; « Paiements à venir » datés. | « Tâches du jour » avec cases à cocher (une case ne coche pas une tâche ; seule W02 sélectionne, DR-11) ; « Vue d'ensemble » en barres empilées (DR-09) ; « Disponible » **et** « Trésorerie libre » sur la même grille (DR-07). |
| **H03b** (sidebar sombre / contenu clair) | Rangée de 5 KPI en tête ; « À faire aujourd'hui » à compteurs. | Le shell hybride (R-FIN-25) ; anneau « Répartition par coffre » en pourcentages sans montant (DR-09) ; « Centre de messages » (aucune messagerie Finance, R-FIN-21). |
| **H04** (sidebar sombre / contenu clair) | **Tableau « Paiements à effectuer »** : case, bénéficiaire, type, période/objet, montant, destination masquée, statut, action (ordre exact de spec §30) ; onglets Tous / Enseignants / Contractuels avec compteurs ; « Échéances proches » à pastille de date ; carte Réserve avec phrase d'objectif. | Le shell hybride ; panneau sombre « À traiter aujourd'hui » collé au contenu clair ; destination affichée avec le logo de l'opérateur. |
| **H05** (clair) | Variante de W01 : 4 + 4 tuiles de coffres, Réserve avec « À compléter » mis en évidence et un seul bouton. | Tuiles de 8 couleurs ; date 2025. |
| **H05b** (clair) | Tableau Paiements avec Classe sous le nom (la Classe reste un détail, spec §14.5) ; « Méthode » nommée (Orange Money, Wave, Banque). | « Solde total » en tuile pleine violette ; anneau des coffres ; type « Remplaçant » (un remplacement est une **ligne** d'obligation, pas un type de bénéficiaire, spec §13.1). |
| **H06** (clair) | Coffres en rangée de 7 avec la part de chacun ; « Échéances importantes » datées avec délai (« Dans 3 jours ») ; alertes avec une action secondaire chacune. | Sparklines Entrées / Sorties ; « Répartition des sorties » ; « Rappels / ajustements » comme famille de paiement (un ajustement est une ligne, §23) ; identité « Programme Afrique ». |
| **H07** (sidebar sombre / contenu clair) | Une action par ligne d'« À faire » (Voir, Relancer, Rapprocher). | « Payer maintenant » sur « 14 enseignants » depuis Aujourd'hui : paiement en lot sans préflight (DR-11) ; « Contacter » (le mot est « Relancer », §27.2) ; dates 2025. |
| **H08** (multicanal : W01 à W06, M01 à M03) | **La référence des écrans autres que W01** : W02 onglets « À effectuer / En cours / Historique », filtres, barre de sélection bas « 3 éléments sélectionnés · Total · Payer la sélection » ; W03 deux colonnes (total + lignes de calcul à gauche, méthode masquée + informations à droite), onglets « Vue d'ensemble / Détail du dû / Méthode / Historique » ; W04 trois colonnes (coffres, transfert, évolution) ; W05 table + panneau détail à droite ; W06 table d'obligations + « Nouvelle obligation » + encart « montants définis à la création » ; mobiles : listes, détail, confirmation en feuille. | **M03 « Confirmer le paiement » affiche un montant masqué** : contraire à spec §7.5 et R-FIN-04 (DR-05) ; W02 a « Encaissements » allumé dans la barre alors qu'on est sur Paiements ; W04 graphique « Évolution » (DR-09) ; W04 montant de transfert vide (`$ 0,00`) au lieu d'un montant proposé (K-57, DR-15) ; **W07 absent** (composé d'après W03, §5.7) ; M02 « Alertes » à part (gardé seulement « si lisible », spec §36). |

**H00 est confirmée** comme référence prioritaire (demande de `00_REPRISE.md` §2) pour **W01 seulement** ; H08 fait référence pour W02 à W06 et les mobiles ; H04 et H05b départagent le tableau W02. Aucune planche n'est reprise pour le shell (§3).

---

## 3. Shell et navigation du rôle Comptable (décision de CPT-0, confirmable)

Les planches montrent toutes une barre latérale de 7 à 10 entrées, avec un sous-menu Finance déplié. Le dépôt interdit plus de **quatre destinations** par rôle (`nav_shell.dart`, assertion `maxDestinations`, « c'est la seule chose qui empêche la barre basse de devenir un menu ») et la spec §45 demande une **barre basse réelle** sur mobile. H01 montre d'ailleurs le bon patron : barre du rôle + onglets dans la page.

**Choix retenu** (DR-01, sans décision requise, le directeur peut le reprendre) : le Comptable reçoit un `NavShell` à quatre destinations, posé par CPT-F dans `destinationsPour` (`nav_shell.dart:217`) et une `StatefulShellRoute.indexedStack` sur le modèle de la coquille contrôleur (`app_router.dart:962`) :

| # | Destination (libellé) | Route | Onglets dans la page (`SousNavigationDomaine`) | Écrans |
|---|---|---|---|---|
| 1 | **Aujourd'hui** | `/comptable` | aucun | W01, M01 écran 1 |
| 2 | **Paiements** | `/comptable/paiements` | À effectuer · Contractuels · Bénéficiaires | W02, W03, W06, W07, M01 écrans 2-3 |
| 3 | **Trésorerie** | `/comptable/tresorerie` | Coffres · Encaissements · Rapprochement | W04, W05, rapprochement, M02 |
| 4 | **Compte** | `/compte` (partagé) | — | Compte, dont « Recevoir mes paiements » (§20 : le Comptable peut être payé) |

À 1440 la colonne latérale dépliée (256, mot-symbole) donne la composition des planches, avec quatre entrées au lieu de dix ; sous 600, la barre basse. Le mode enfant ne concerne pas ce rôle. « Rapports » n'a aucune fiche d'écran dans la spec (§29-35) : pas d'entrée (DR-17).

---

## 4. Composants §39 : réutiliser ou créer

« Créer » veut toujours dire : un habit des composants existants, dans les jetons, jamais une recopie. Colonne « Qui » = l'étape qui écrit le fichier ; un composant partagé par deux voies est posé **une fois** par CPT-F.

| Composant (spec §39) | Existant à réutiliser | Décision | Qui |
|---|---|---|---|
| `SensitiveAmount` | `MontantArgent` `montant_argent.dart:31` + `formaterMontant` `format_montant.dart:76` | **À créer** `lib/core/widgets/montant_sensible.dart` : masque de longueur fixe par devise (DR-06), sémantique « Montant masqué », chiffres tabulaires. | CPT-F |
| `FinanceAmountVisibilityToggle` | `BoutonIcone` / icônes `oeil`, `masquer` | **À créer** `lib/core/widgets/bascule_montants.dart` + état de session `lib/core/comptable/visibilite_montants.dart` (Riverpod, jamais `PortPreferencesPersistantes`, remis à « masqué » à chaque changement de session). | CPT-F |
| `MoneyAmount` | `MontantArgent` `montant_argent.dart:31` | **Réutiliser** tel quel (montant exact de la confirmation, R-FIN-04). | — |
| `FinancialStatusChip` | `StatusPill` `status_pill.dart:60`, `TonEtat` `:13` | **À créer** comme habits : `PastillePaiementSortant` (15 états §15), `PastilleEncaissement` (9 états §24.1), `PastilleRapprochement` (6 états §25), `PastilleProfilPaiement` (6 états §38), `PastilleCapacitePayout` (5 retours §42) dans `lib/core/widgets/pastilles_comptable.dart`. `PastilleFinanciere` n'est pas étendue (typée profil élève). | CPT-F |
| `PaymentMethodRow` | `LigneCleValeur` `ligne_cle_valeur.dart:20` (pas `LigneMoyenPaiement`, qui sert à payer) | **À créer** `LigneDestinationMasquee` dans `lib/core/widgets/ligne_destination.dart` : type, opérateur, `•••• 4423` rendu **par la source**, pays, devise, état de vérification. | CPT-F |
| `BalanceSummary` (`AvailableTreasurySummary`) | `ResumeSoldes` `resume_soldes.dart:19` (non réutilisable : foyer) ; `StatTile` `stat_tile.dart:22` | **À créer** `ResumeTresorerie` `lib/core/widgets/comptable/resume_tresorerie.dart` : Trésorerie libre au centre, puis protégés, transit, détenu. Utilisé par W01 (zone 1) et W04. | CPT-F (puis CPT-TRES-1 seul à le modifier) |
| `TreasuryVaultCard` | `AppCard` `app_card.dart:28`, `LigneCleValeur` | **À créer** dans `lib/features/comptable/tresorerie/`. | CPT-TRES-1 |
| `StrategicReserveCard` | `AppCard`, `LinearProgressIndicator` du thème (déjà employé `fiche_groupe_page.dart:831`) | **À créer** `lib/core/widgets/comptable/carte_reserve_strategique.dart` : lue par W01 (zone 2, lecture) et W04 ; titre fixe « Réserve stratégique », objectif rédigé selon le mode (R-FIN-05 à 07). | CPT-F (puis CPT-TRES-1 seul à le modifier) |
| `StrategicReservePolicyPanel` | `politiques_commerciales.dart:1104` `_ChampPolitique` (privé : patron seulement), `ChoiceCardGroup` | **À créer** dans `lib/features/admin_finance/reserve_delegation/`. | CPT-DIR-1 |
| `FinanceDelegationPolicyPanel` | idem | **À créer** au même endroit. | CPT-DIR-1 |
| `TreasuryInternalTransfer` | `AppBottomSheet` `app_bottom_sheet.dart:48`, `ChoiceCardGroup` `:78` | **À créer** dans `lib/features/comptable/tresorerie/`. | CPT-TRES-2 |
| `PayableObligationRow` | `ColonneDonnees` + `DataCollection` `data_collection.dart:37`, `:96` | **À créer** dans `lib/features/comptable/paiements/` (W02). W06 a sa propre ligne d'obligation de contractuel (états d'approbation) et **ouvre W03 pour payer** (DR-12) : aucun partage de fichier. | CPT-PAY-1 |
| `PayoutBatchBar` | `RangeeActions` `action_principale.dart:415` | **À créer** (barre de sélection + préflight). | CPT-PAY-1 (barre), CPT-PAY-2 (préflight) |
| `PayoutConfirmationSheet` | `AppBottomSheet`, `MontantArgent`, `LigneDestinationMasquee` | **À créer** ; montant **toujours exact** (R-FIN-04). | CPT-PAY-2 |
| `BeneficiaryPaymentProfileCard` | `AvatarNom` `avatar_nom.dart:45`, `LigneDestinationMasquee` | **À créer** (W07). | CPT-BEN-1 |
| `BeneficiaryPaymentSetup` | `PageEtape` `page_etape.dart:23`, `ChoiceCardGroup`, `BandeauAttention` `bandeau_attention.dart:24` | **À créer** (« Recevoir mes paiements »). | CPT-BEN-2 |
| `ReconciliationWorkspace` | `DataCollection`, `LigneAllocation` `ligne_allocation.dart:13` | **À créer**. | CPT-ENC-2 |
| `FinanceAttentionQueue` | `SignalRow` `signal_row.dart:21` + `CarteLignes` `carte_lignes.dart:16` | **Habit** dans `lib/features/comptable/aujourdhui/`. | CPT-JOUR |
| `FinanceAlertRow` | `SignalRow` `signal_row.dart:21` | **Réutiliser** (ton = famille de l'alerte). | CPT-JOUR |
| `FinanceProviderStatus` | `StatusPill` | **À créer** comme `PastilleCapacitePayout` (ci-dessus) ; ligne prestataire dans W01 et la feuille de confirmation. | CPT-F |
| `FinanceActivityRow` | `LigneTransaction` `ligne_transaction.dart:13` (non masquable, fichier FIN non modifié) | **À créer** `lib/core/widgets/comptable/ligne_activite.dart` sur `LigneCleValeur` + `SensitiveAmount` : initiateur, date, ancien → nouvel état, référence (§48). Utilisée par W01, W03, W04, W05. | CPT-F |

Extension d'un fichier existant : **aucune**. `LigneFinance` ne prend pas de montant masqué ; W03 compose ses lignes de calcul avec `LigneCleValeur` + `SensitiveAmount` (dans la voie PAY), ce qui évite de rouvrir un fichier de la vague FIN.

---

## 5. Écrans : entrée réelle, shell réel, matrice

Légende matrice : **G** garder (existe et convient), **A** améliorer (existe, à retoucher), **+** ajouter (n'existe pas), **S** supprimer / refuser (vient d'une planche, contraire à la spec ou au dépôt).

### 5.1 FIN-CPT-W01 Aujourd'hui (+ M01 écran 1) : CPT-JOUR

- **Entrée** : destination 1 « Aujourd'hui », `/comptable` (remplace `ComptePage` nue, `app_router.dart:1258`). **Shell** : `NavShell` comptable, index 0.
- **Composition** (H00) : en-tête (titre, sous-titre, `FinanceAmountVisibilityToggle` à droite) ; `ResumeTresorerie` pleine largeur (Trésorerie libre au centre) ; à droite ou dessous la `StrategicReserveCard` en lecture ; trois colonnes : À traiter aujourd'hui (`FinanceAttentionQueue`), Échéances, colonne droite Prestataires + Activité récente ; bas : Paiements à effectuer (résumé par famille, pas de bouton Payer), Encaissements récents, Accès rapides (liens vers W02, W06, W05, W04). Neuf zones, spec §29.
- **Mobile (M01-1)** : une colonne : Trésorerie libre, À traiter, Échéances ; le reste derrière « Voir tout ».
- **Matrice** : + toutes les zones ; S graphique de flux (DR-09), recherche globale (DR-18), export (DR-17), Payer sur ligne (DR-11), KPI de variation (DR-08), Revenu acquis (DR-08).

### 5.2 FIN-CPT-W02 Paiements à effectuer (+ M01 écran 2) : CPT-PAY-1, CPT-PAY-2

- **Entrée** : destination 2 « Paiements », onglet « À effectuer », `/comptable/paiements` ; filtres en paramètres de requête (`?filtre=prets|infos|verification|validation|retard&type=enseignant|contractuel&classe=`) pour que les liens d'Aujourd'hui ouvrent la liste déjà filtrée (§5.1, règle « un raccourci ouvre l'écran canonique »). **Shell** : `NavShell`, index 1.
- **Composition** (H08 W02, H04) : onglets internes « À effectuer / En cours / Historique » ; filtres ; table (case, bénéficiaire, type, période/objet, montant, destination masquée, échéance, statut, action) ; barre de sélection en bas (`PayoutBatchBar`). Mobile : liste de cartes (spec §45), case à gauche, CTA bas.
- **Matrice** : + tout ; S « Exporter la sélection » (DR-17) ; A « Payer » visible seulement si l'obligation le permet (capacité rendue par la source, jamais `role ==`).

### 5.3 FIN-CPT-W03 Détail bénéficiaire / paiement (+ M01 écran 3) : CPT-PAY-1, CPT-PAY-2

- **Entrée** : ligne de W02, `/comptable/paiements/obligation/:obligationId` (segment fixe `obligation` pour ne pas entrer en collision avec `contractuels` et `beneficiaires`) ; aussi depuis W01 (ligne « Enseignants à payer » → W02 filtré, puis ligne), W06 (« Payer » d'un contractuel, DR-12), W07 (historique). **Shell** : `NavShell`, index 1, retour vers W02.
- **Composition** (H08 W03) : identité + statut ; colonne gauche total + lignes de calcul avec source (chaque ligne ouvre sa source quand elle a une route) ; colonne droite destination masquée, vérification, encart permanent §31 ; onglets Historique / Preuve ; un seul bouton plein « Payer maintenant » ; « Signaler un écart » en secondaire, sans champ de montant (R-FIN-17).
- **Matrice** : + tout ; S « Payer maintenant » quand le bénéficiaire est la personne connectée (R-FIN-15, libellé « Traitement par un autre responsable requis »).

### 5.4 FIN-CPT-W04 Trésorerie & coffres (+ M02 écran 1) : CPT-TRES-1, CPT-TRES-2

- **Entrée** : destination 3 « Trésorerie », onglet « Coffres », `/comptable/tresorerie` ; depuis W01 (Réserve, Accès rapides « Alimenter la Réserve stratégique » → `/comptable/tresorerie?action=alimenter`). **Shell** : `NavShell`, index 2.
- **Composition** (H08 W04, H03) : rangée détenu / libre / protégé / transit (`ResumeTresorerie`) ; colonne coffres (sept `TreasuryVaultCard`, ordre spec §8.1) ; colonne Réserve stratégique (indicateurs §9.7) ; transfert interne (`TreasuryInternalTransfer`, en feuille sur mobile) ; historique des allocations (`FinanceActivityRow`) ; prévision **en lignes datées**, pas en courbe (DR-09).
- **Matrice** : + tout ; S « Réserve 3 mois » partout (R-FIN-05) ; S graphique « Évolution » ; A champ montant du transfert : proposé (manque à compléter, allocation de la politique), modifiable (K-57).

### 5.5 FIN-CPT-W05 Encaissements & rapprochement (+ M02 écran 2) : CPT-ENC-1, CPT-ENC-2

- **Entrée** : destination 3, onglet « Encaissements », `/comptable/tresorerie/encaissements` (filtres en requête) ; détail `/comptable/tresorerie/encaissements/:id` (panneau à 1440, page sous 1200) ; rapprochement onglet « Rapprochement », `/comptable/tresorerie/rapprochement`. **Shell** : `NavShell`, index 2.
- **Composition** (H08 W05) : onglets d'état avec compteurs ; recherche famille / référence ; table date, référence, famille, profils, brut, frais, net, moyen, prestataire, état, rapprochement (§24.2) ; panneau détail à droite (brut, frais, net, référence, prestataire, foyer, affectation par profil avec `LigneAllocation`, rapprochement). Mobile : liste + page détail.
- **Matrice** : + tout ; G vocabulaire §24.1 ; S « Voir le reçu » tant que la source ne rend pas de reçu (même règle que FI, « Télécharger le reçu seulement si rendu »).

### 5.6 FIN-CPT-W06 Contractuels & obligations : CPT-CTR-1

- **Entrée** : destination 2, onglet « Contractuels », `/comptable/paiements/contractuels` ; création `/comptable/paiements/contractuels/nouvelle` (seulement si la capacité « créer une obligation » est rendue) ; détail `/comptable/paiements/contractuels/obligation/:obligationId`. **Shell** : `NavShell`, index 1.
- **Composition** (H08 W06, M03) : onglets Obligations / À approuver / À payer / Historique ; table bénéficiaire, objet, montant, échéance, statut, action ; « Nouvelle obligation » en haut à droite, seul bouton plein ; encart « Les montants sont définis lors de la création de l'obligation… ». « Payer » ouvre W03 (DR-12).
- **Matrice** : + tout ; S montant modifiable après approbation ; A formulaire préremplir / proposer / saisir (K-57 ; seul le montant et l'objet sont saisis, et le CPT-0 dit pourquoi : une facture externe n'est connue que de celui qui la reçoit).

### 5.7 FIN-CPT-W07 État du profil de paiement : CPT-BEN-1

- **Entrée** : destination 2, onglet « Bénéficiaires », liste `/comptable/paiements/beneficiaires`, fiche `/comptable/paiements/beneficiaires/:beneficiaireId` ; depuis W03 (destination masquée → « Voir le profil de paiement ») et W01 (« Informations manquantes »). **Shell** : `NavShell`, index 1.
- **Composition** : **aucune planche** ; composée d'après W03 (H08) : identité en tête, `BeneficiaryPaymentProfileCard` à gauche (méthode masquée, statut, pays, devise, dernière modification, vérification, capacité de payout), historique de paiements à droite ; actions Relancer (plein), Demander une mise à jour, Voir le fil, Suspendre le paiement (selon capacité, `ConfirmDestructive`). Aucun « Modifier coordonnées » (R-FIN-11).

### 5.8 FIN-CPT-M01 et M02 (mobile)

M01 = W01 mobile, W02 mobile, W03 mobile (dans leurs voies respectives). M02 = W04 mobile, W05 mobile ; « Alertes / relances » (écran 3 facultatif, spec §36) n'est **pas** un écran à part : c'est « Voir tout » de la file d'Aujourd'hui, même route (`/comptable?vue=attention`), pour ne pas créer une seconde liste d'alertes (DR-10). M03 de H08 (contractuels mobile) est pris comme composition du mobile de W06.

### 5.9 Delta Direction (§37) : CPT-DIR-1

- **Entrée** : coquille admin, domaine Finance, **troisième onglet** « Réserve et délégation », `/admin/finance/reserve-delegation`, posé par CPT-F dans `ongletsFinance()` (`admin_domaine.dart:181`) et `app_router.dart` (à côté de `:1144`). **Shell** : `AdminShell`, `AdminDomaine.finance`.
- **Pourquoi pas dans « Politiques commerciales »** : `politiques_commerciales.dart` (1 754 lignes) est un fichier de la vague FIN en cours de correction (FI-VAGUE-CORR) et porte la politique **tarifaire** versionnée ; la Réserve et la délégation sont de la gouvernance de trésorerie. Un onglet de plus dans le même domaine n'est pas un second système (spec §37).
- **Validation des opérations sensibles** : aucune surface Direction n'est prévue par la spec pour valider ce que le Comptable « demande » : voir `QUESTIONS.md` CPT-Q1.

### 5.10 « Recevoir mes paiements » (§17, §38) : CPT-BEN-2

- **Entrée** : route partagée **`/compte/paiements-recus`** (posée par CPT-F, `_CoquilleSecondaire` comme `/compte/profil`, `app_router.dart:291-295`). L'enseignant y arrive par une ligne de son Profil (`profil_enseignant_page.dart`, qui pousse déjà `Routes.compteProfil` `:705` et `Routes.compteReglages` `:711`) ; le Comptable par une rubrique de `ComptePage`. Une seule surface pour tout bénéficiaire avec compte (spec §17 « Compte > Paiements > Recevoir mes paiements »).
- **Shell** : celui du rôle connecté (`_CoquilleSecondaire`).
- Le contractuel n'a pas de rôle (`AppRole` en a six) : il est bénéficiaire externe, état « Invitation envoyée » côté Comptable (DR-16).

---

## 6. Ce que CPT-F doit poser une fois pour toutes

Détail fichier par fichier : `02_DECOUPAGE.md`, section « Fichiers par étape ». En résumé : routes et coquille (`routes.dart`, `app_router.dart`, `nav_shell.dart`, `admin_domaine.dart`), toutes les icônes (`app_icons.dart`), les pages « en préparation » de chaque surface avec leur **constructeur définitif**, les ports neutres et leurs modèles (un fichier par voie), les composants partagés du §4, le socle de démonstration et un fichier de données par voie, un bloc i18n `comptable.<module>` par voie, la mise à jour de `test/router/navigation_test.dart:139`.

### 6.1 Icônes à ajouter par CPT-F

Coffre, Réserve (bouclier), en transit, entrée d'argent, sortie d'argent, lien (rapprochement), contractuel, bénéficiaire, échéance (calendrier), écart signalé, suspendre. Le choix du glyphe suit `docs/produit/design-tokens.md` (icônes) ; aucune icône de marque de prestataire.

---

## 7. Contradictions relevées (dépôt, spec, planches)

| N° | Entre | Ce qui prime | Où c'est traité |
|---|---|---|---|
| X-1 | Planches (barre à 8-10 entrées) / dépôt (4 destinations, assertion) | Dépôt + spec §45 (barre basse réelle) | §3, DR-01 |
| X-2 | FI23 « le comptable lit la même Finance » / spec §0 « véritable bureau » | Spec §0 (plus récente, directeur) ; données canoniques partagées | DR-02 |
| X-3 | Préfixe `/comptable` réservé / R-FIN-12 « Admin consulte enseignant » | À décider : CPT-Q1 | DR-03 |
| X-4 | H08 M03 confirmation masquée / spec §7.5, R-FIN-04 | Spec | DR-05 |
| X-5 | Masques de longueur variable (toutes planches) / spec §7.1 | Spec | DR-06 |
| X-6 | « Réserve 3 mois » (toutes planches) / spec §9.1 | Spec | R-FIN-05 |
| X-7 | Graphiques (H00, H03, H03b, H05b, H06, H07, H08 W04) / spec §29 « pas de graphiques en surnombre », FI21, absence de bibliothèque | Spec + dépôt | DR-09 |
| X-8 | COM spec §3.2 (objets Enseignant ↔ Administration : affectation, Classe, planning, support, dossier professionnel ; « toute extension exige une décision ») / spec Finance §27.3 objet « Profil de paiement » | Spec Finance (décision du directeur du même jour, autorité 1) : l'objet s'ajoute à COM-BR-01 | DR-20, CPT-BR-11 |
| X-9 | Spec §38 « contractuel avec compte » / `AppRole` sans contractuel | Dépôt (aucun rôle, aucun serveur dans cette vague) | DR-16 |
| X-10 | Revenus **estimés** (FI-10) / obligation **calculée** (spec §13) pour la même paie | À écrire ; aucune modification de FI-10 dans cette vague | DR-14 |
| X-11 | CLAUDE.md « aucun écran hors `docs/design/08-catalogue-ecrans.md` » / sur `ui/finance-v1` le catalogue est archivé (`docs/archive/2026-09-pre-remise-a-plat/design/08-catalogue-ecrans.md`) | Même pratique que la vague FIN : la fiche de chaque écran est le §5 de ce fichier | §5 |
