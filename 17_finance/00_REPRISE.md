# Vague Finance : reprise (lire ceci d'abord)

> **Décision de l'orchestrateur (02/10, ménage du tableau) — prime sur la branche proposée plus bas.**
> `ui/finance-v1` part de `origin/corrections/revue-directeur-2026-10` **après INTEG-RC-1** (étape qui y réunit admin, élèves adultes, enseignant, contrôleur et accessibilité). Plus aucune fusion séparée admin + adultes : FI-1b dépend d'INTEG-RC-1. FI-1a (revue UX, document) peut démarrer tout de suite. Voie du tableau : **FIN** (une session à la fois). Questions au directeur : dépôts `A-q-FI-*` du tableau.

Préparée le 02/10/2026 (étape FI-0), en lecture seule sur le code : aucun fichier des worktrees `D:\RA_TUTEUR\admin` et `D:\RA_TUTEUR\adultes` n'a été modifié.

## 1. Le rôle en deux phrases

« Finance » n'est pas un nouvel utilisateur : c'est un **domaine** qui traverse cinq rôles existants. Le tuteur voit les soldes et la période financée de chaque enfant, et il recharge un ou plusieurs profils en un seul paiement. L'élève adulte voit ses propres finances, l'enfant ne voit que son état d'accès, l'enseignant voit une estimation de ses revenus, et la direction (rôle `admin`, et plus tard `accountant`) voit la vue globale et règle les politiques commerciales versionnées.

**Pour qui, par ordre de volume** : tuteur (6 maquettes sur 7), direction (2 écrans, pas de maquette fournie), enseignant (1 écran, pas de maquette), élève adulte, enfant (états d'accès seulement).

## 2. Sources

Toutes copiées dans `17_finance/V/` :

| Fichier | Contenu |
|---|---|
| `REWAYAH_FINANCE_FRONTEND_GUIDE_V4_2026-10-02.md` | Guide du directeur, 1 611 lignes. Il **prime** sur toute règle antérieure incompatible pour le périmètre Finance (guide §0). Le lire par section, à la demande de l'étape. |
| `01_mobile_sombre_paiement_confirme.png` | Résultat du paiement, répartition par profil (guide §5.4). |
| `02_mobile_sombre_mariam_finances.png` | Fiche élève, onglet Finances (§5.2). |
| `03_mobile_sombre_foyer_soldes.png` | Foyer, soldes et paiements (§5.1). |
| `04_mobile_sombre_recharge.png` | Recharge multi-profils (§5.3). |
| `05_bureau_clair_foyer_soldes.png` | Foyer à 1440 (§5.1, bureau). |
| `06_bureau_clair_mariam_finances.png` | Fiche Finances à 1440 (§5.2). |
| `07_bureau_clair_paiement_du_foyer.png` | Recharge à 1440, avec le bandeau « Accès à régulariser » (§5.3, §1.7). |

**Maquettes annoncées mais absentes du dossier** (guide §2) : « Enseignant - Revenus », « Finance - Vue globale », « Admin - Politiques commerciales ». Voir `QUESTIONS.md` Q1.

**Valeurs des maquettes à ne pas recopier** (guide §2, §5.2) : `30 $ / mois`, « Remise famille -5 $ » sur Mariam, toute année 2024, toute ancienne remise 5/10 ou paie 20/26. Les valeurs de lancement viennent du guide §1 et vivent dans la politique de démonstration (FI-1c), jamais dans un widget.

## 3. Branche et worktree proposés

- **Branche** `ui/finance-v1`, créée depuis `origin/ui/admin-v1` @ a8dfcb3, **puis** fusion de `origin/ui/eleves-adultes-v1` @ 5629693 en premier geste de FI-1b. Ce n'est pas encore fait : c'est l'étape FI-1b.
- **Worktree** `D:\RA_TUTEUR\finance`. Ne jamais travailler dans `D:\RA_TUTEUR\admin` ni `D:\RA_TUTEUR\adultes`.

**Pourquoi ces deux bases.**
1. L'espace Finance de la direction **vit dans la coquille admin**. Le domaine Finance y est déjà réservé, visible et inerte : `lib/core/admin/admin_domaine.dart:33` (enum), `:99` (chemin `null`), `:124` (5e entrée de la barre). Le contrat d'architecture fixe ses routes `/admin/finance/...` (`docs/archive/2026-09-pre-remise-a-plat/architecture/ADMIN_FINANCE_CONFIGURATION.md:16-18`, `:68-75`) et son gabarit `SousNavigationDomaine` avec un `ongletsFinance()` (`:103-106`). `AdminShell` à jour est sur `ui/admin-v1` (`lib/core/widgets/admin_shell.dart:50`, 47 commits dont la correction PageShell AD-RC M4).
2. Mais 6 maquettes sur 7 sont des écrans **tuteur** qui existent déjà sur `ui/eleves-adultes-v1` (EA-9 soldes, EA-10 recharge, `PortPaiementsFoyer`, `PortRechargeFoyer`, foyer de démonstration). Les recréer violerait K-10 et K-51 ; le guide interdit « deux moteurs de recharge » (§4).
3. Aucune branche ne contient les deux : `ui/admin-v1` et `ui/eleves-adultes-v1` divergent depuis `ui/classe-v1` @ d44710a (47 et 79 commits). `corrections/revue-directeur-2026-10` contient `ui/admin-v1` mais une version d'EA arrêtée à EA-6 (f02444f), sans EA-9 ni EA-10, et c'est un chantier en cours (lots 2 à 5) : on ne s'y lie pas.
4. La fusion est petite : **12 fichiers communs** (`assets/i18n/fr.i18n.json`, `lib/core/i18n/strings*.g.dart` à régénérer par slang, `app_icons.dart`, `app_router.dart`, `redirection.dart`, `routes.dart`, `action_principale.dart`, `groupe_reglages.dart`, `mode_demonstration.dart`, `repere_demonstration.dart`, `test/router/navigation_test.dart`). Leçon 13 de `LECONS_DES_ROLES.md` : partir de la branche la plus avancée pour éviter deux API concurrentes.

## 4. Ce qu'on réutilise (sans fork, K-10, K-51)

Références sur `ui/eleves-adultes-v1` @ 5629693 sauf mention « admin » (`ui/admin-v1` @ a8dfcb3).

| Besoin du guide (§7) | Existant à réutiliser | Note |
|---|---|---|
| Foyer, synthèse Soldes et paiements | `lib/features/foyer/foyer_page.dart:76` `FoyerPage` ; `lib/features/compte/soldes_foyer.dart:33` `SoldesFoyerSection` (appelée `foyer_page.dart:261`) | Retouche demandée par le guide (§5.1), pas une réouverture : même logique qu'EA §22.4. |
| Historique des paiements, Compte > Paiements | `lib/features/compte/paiements_page.dart:38` `PaiementsComptePage` (route `app_router.dart:663`) | Devient un raccourci vers la surface canonique (§4). |
| Recharge | `lib/features/foyer/recharge_foyer.dart:39` `RechargeFoyerPage` ; `lib/core/capacites/port_recharge_foyer.dart:152` `PortRechargeFoyer` | Un seul moteur (§4). Aujourd'hui atteinte seulement par la démonstration (`demo_adulte_page.dart:1248`) : FI-7 lui donne sa vraie route. |
| Soldes, historique | `lib/core/capacites/port_paiements_foyer.dart:103` `PortPaiementsFoyer`, `:61` `SoldeBeneficiaire`, `:90` `SoldesFoyer` | Contrat à faire évoluer (FI-1c), pas à doubler. |
| Accès par profil | `lib/core/capacites/port_acces_foyer.dart:7` `EtatAccesAffiche`, `:39` `AccesBeneficiaire` | Base de FI-9a. |
| Fiche élève et sous-pages | `lib/features/foyer/fiche_eleve_page.dart:241` `FicheElevePage`, `:35` `PageFiche` ; `Routes.ficheEleveSousPage` ; sous-pages `lib/features/foyer/fiche/` (`informations_page.dart:19`, `inscription_page.dart:33`, `interface_page.dart:31`, `camera_page.dart:29`, `acces_page.dart:27`) ; routes `app_router.dart:527-575` | Les lignes Classe, Interface, Caméra, Accès de la maquette 06 existent déjà. |
| `ProfileIdentityAvatar` (photo ou initiale) | `lib/features/foyer/photo_eleve.dart:20` `PhotoEleve` | Le bandeau s'ajoute autour, sans recopier la photo. `AvatarNom` existe sur `corrections/revue-directeur-2026-10` (`lib/core/widgets/avatar_nom.dart`, AVATAR-1) mais pas dans notre base : ligne « Harmonisation » à HU-1. |
| Accent d'identité stable | `lib/core/theme/app_palette.dart:306` `teintesIdentite` (32 paires vérifiées AA, décision D-18), `:309` `teinteGroupe(index)` | Aucune couleur nouvelle (K-37) : la clé `profileAccentKey` est un index stable rendu par les données, jamais la position dans la liste. Le guide §3.8 point 2 demande justement de réutiliser l'existant. |
| `GroupedCard` | `lib/core/widgets/groupe_reglages.dart:81` `GroupeReglages`, `:13` `LigneRubrique` | Un rectangle, lignes à filets (K-55 b). |
| `FinancialStatusChip`, `FinancedPeriodBadge` | `lib/core/widgets/status_pill.dart:60` `StatusPill` | Point + texte, jamais la couleur seule. |
| `AttentionBanner` | `lib/core/widgets/permanent_notice.dart:28` `PermanentNotice` | Bandeau « Accès à régulariser » (maquette 07). |
| `FinanceLineItem`, détail de mensualité, reçu | `lib/core/widgets/ligne_cle_valeur.dart:19` `LigneCleValeur` | Montant à droite, chiffres tabulaires à ajouter par paramètre si absent (demande d'évolution, pas de copie). |
| `MoneySummaryCard` | `lib/core/widgets/stat_tile.dart:22` `StatTile`, `app_card.dart:28` `AppCard` | K-42 : pas de tuile de chiffre pour une donnée secondaire. |
| Action principale, rangée d'actions | `lib/core/widgets/action_principale.dart:52` `ActionPrincipale`, `:371` `RangeeActions` | K-54, K-56. |
| Sélection d'un moyen de paiement | `lib/core/widgets/choice_card_group.dart:78` `ChoiceCardGroup` | Carte entière cliquable, ligne « quand / conséquence » (K-58). |
| Étapes, résultat, états | `page_etape.dart:23` `PageEtape`, `ecran_resultat.dart:31` `EcranResultat`, `etat_systeme.dart:79` `EtatSysteme`, `bloc_asynchrone.dart:41` `BlocAsynchrone`, `skeleton.dart:27` `Skeleton`, `confirm_destructive.dart:27` | Cinq états par écran (leçon 9). |
| Mouvements, tableaux bureau | `lib/core/widgets/data_collection.dart:96` `DataCollection` | Tableau compact à 1440 (§6). |
| `ResponsiveFinanceScaffold` | `lib/core/widgets/page_shell.dart:41` `PageShell` ; coquille tuteur `nav_shell.dart:210` `NavShell` ; admin `admin_shell.dart:50` `AdminShell` | Aucun nouvel échafaudage : une page Finance est une `PageShell` dans la coquille du rôle. |
| Onglets du domaine Finance | admin `lib/core/widgets/sous_navigation_domaine.dart:21` ; modèle `admin_domaine.dart:153` `ongletsPedagogie()` | Créer `ongletsFinance()` à côté (contrat d'architecture règle 5). |
| Entrée en classe (bouton Rejoindre) | `lib/core/tc_horloge/emplacement_entree.dart:65` `EmplacementEntree` | État « indisponible » par sa raison existante ; règles R1-R21, ne pas modifier le composant (sinon ligne HU-1). |
| Démonstration | `lib/features/demo/mode_demonstration.dart:52` `environnementAutoriseDemo` ; modèle `lib/features/demo/demo_adulte_page.dart:349` (routes) et `:96` (écrans) ; données `lib/features/demo/adulte_demo.dart` ; admin `lib/main.dart:100` (`?demo=admin`) | Une seule source de données de démonstration (leçon 14). |
| Captures | `test/capture/outil_capture.dart` ; modèle `test/features/adulte_recette/` | 390, 768, 1440, clair et sombre, 200 %, RTL. |
| Rôle comptable | admin `lib/core/domain/enums.dart:14` `AppRole.accountant` ; `routes.dart:450` `/comptable` ; `app_router.dart:1020-1024` (affiche `ComptePage`) | Même source Finance, permissions adaptées (§4). Hors lot : ligne « À faire plus tard ». |

**Ce qui n'existe nulle part** : surface « Revenus » de l'enseignant ; vue globale Finance ; politiques commerciales ; mouvements par profil ; moyens de paiement ; les huit états de paiement ; période financée, essai n/2, manque à financer dans les données.

## 5. Devoir de regard (guide §12)

```text
DEVOIR DE REGARD - FINANCE FRONTEND (FI-0, 02/10/2026)

CONFORME
- Aucun StoreKit, Play Billing, in_app_purchase, Stripe, « taxe incluse », J+14, « balance > 0 »,
  « 20/26 $ » dans lib/ ni fr.i18n.json (ui/admin-v1, ui/eleves-adultes-v1, ui/enseignant-v1).
- Aucune remise 5/10 ni bonus 10/20 codés.
- Le paiement n'affiche jamais de succès local (PortRechargeFoyer.payer rend CapaciteIndisponible).
- Le domaine Finance admin est réservé, inerte, sans écran vide (admin_domaine.dart:99).

ÉCART (résolus par le guide §0, appliqués dans la vague, pas des questions)
- EA F11 « une offre par bénéficiaire, jamais un montant saisi » (port_recharge_foyer.dart:66-78)
  contre guide §5.3 « montant par profil » : le guide prime.
- EA E2 « solde rédigé par le serveur, sans devise ajoutée par Flutter » (port_paiements_foyer.dart:57)
  contre guide §7 et §11.3 « montant formaté selon la locale, devise identifiable » : montants en unités
  mineures + code ISO, formatés par intl (K-41.5).
- EA F12 « total jamais additionné dans Flutter » (port_recharge_foyer.dart:147) contre §5.3
  « le total se recalcule » : seule addition permise, celle des montants choisis par le tuteur, affichée
  comme total à payer et arrêtée par le serveur avant paiement. Aucun prix, remise ni taxe calculé.
- EA E12 « aucune pastille Actif » contre maquettes 02, 03, 05 (« Décembre financé ») : la pastille
  de période financée est l'information principale du domaine (§5.1 états visuels).
- Démonstration EA en euros (fr.i18n.json:4162-4169, « 5,00 € (démonstration) ») contre USD (§1.1).
- Foyer mobile (maquette 03) : « Recharger » en tête ET « Recharger plusieurs profils » dans la carte,
  même intensité : contraire à K-56 et au guide §13 (« une action existe à deux endroits »). On garde
  « Recharger plusieurs profils » seul, décision consignée en FI-1a.
- Page « Paiement du foyer » (maquette 07) : elle reprend le bouton « Recharger plusieurs profils »
  alors qu'elle EST la recharge : retiré (même raison).

RISQUE
- Tables serveur `wallets`, `wallet_entries` existantes (ADMIN_FINANCE_CONFIGURATION.md:72) : si elles
  portent un portefeuille de foyer, contraire à FIN4-07. À trancher en BR-1 (FI-BR-14).
- Le guide §3 approuve des couleurs nouvelles, K-37 gèle le thème : on prend les 32 teintes
  d'identité existantes ; si le directeur veut les teintes exactes des maquettes, ligne TH-2.
- Fusion admin + adultes dans la branche : à refaire proprement au plan 13_fusion.
- Enseignant : `ui/enseignant-v1` @ 058c525 n'est pas dans la base ; la page Revenus doit rester
  autonome (un fichier, une entrée) pour ne pas entrer en conflit.
- `EmplacementEntree` (classe) : tout changement touche R1-R21 et tous les rôles.

BLOCAGE
- Trois maquettes absentes (Q1) : FI-10, FI-11a, FI-11b attendent.

INCONNU
- Ce que recouvre « business plan » dans le nom du dossier (Q2).
- Montant de l'allocation Internet et pas du sélecteur de montant : paramètres de politique,
  valeurs de démonstration marquées « (démonstration) ».

PROPOSITION MINIMALE
- Construire dans l'existant : Foyer, fiche, Paiements, recharge EA ; domaine Finance de l'AdminShell.
- Ajouter seulement : ProfileIdentityAvatar (autour de PhotoEleve), composants d'argent minces sur
  LigneCleValeur et StatusPill, la politique de démonstration, 4 pages nouvelles (fiche Finances,
  mouvements, Revenus, Vue globale + Politiques).
```

## 6. Interdits

- `main`, PR, `supabase/` (lecture seule), `.github/`, `vercel.json`, `pubspec.yaml`, `dart_define`, secrets (K-19).
- Tout serveur : migrations, RLS, RPC, webhooks Stripe, stockage de carte, ledger, StoreKit, Play Billing, fiscalité, paie réelle (guide §15, K-28). Chaque besoin devient une ligne de `FI-BR.md`.
- Thème et couleurs : aucune couleur, aucun jeton nouveau (K-37) ; idée de couleur = ligne TH-2.
- Tout prix, taux, remise, capacité, délai, pourcentage ou montant dans un widget (guide §13, §14). Ils vivent dans la politique de démonstration.
- Recopier les valeurs des maquettes (§2) ; inventer une remise pour ressembler à une image (§5.2).
- Le mot « admin » dans un texte vu par un client (K-53 point 6) : « la direction » ou « l'administration ».
- Tout texte visible hors `assets/i18n/fr.i18n.json` ; toute phrase en morceaux ; tout format de date ou de montant fixe (K-41).
- Toute traduction avant LG-1 (K-41).
- `dart format` sur un dossier (K-23) ; deux commandes Flutter lourdes à la fois (K-05).
- Recopier un composant partagé ; modifier `PageShell`, `EmplacementEntree`, `NavShell` sans tester un écran de chaque autre rôle (leçon 13).
- Un bouton App Store ou Play (§1.6) ; afficher « paiement confirmé » au retour d'un écran externe (§1.6).
- PISI, « Rewayah Foundations » ou tout produit parallèle (§1.9).
- Le questionnaire d'accueil (réservé à sa vague).
- Rouvrir une étape terminée d'une autre vague : un écart d'un écran non financier va en « Harmonisation : <écran> » (K-51, HU-1).

## 7. Règles du rôle (FI1 à FI24)

Elles s'ajoutent à DESIGN-GOV (K-38), au style CL-4 (K-42), à K-36, K-54 à K-59, et aux règles F1 à F24 de la vague Élèves adultes **sauf** F11, E2, E12 et la partie « total » de F12, remplacées pour la finance par FI5, FI6, FI8 et FI14 (guide §0).

| N° | Règle | Guide |
|---|---|---|
| FI1 | Un élève = un solde + une période financée, individuels. Le total du foyer est une lecture : jamais un portefeuille, jamais une source d'autorisation, jamais « solde commun ». | §1.1 FIN4-06, 07 ; §16 |
| FI2 | L'accès dépend de la période financée, jamais de `solde > 0`. Un élève à 0 $ garde l'accès si le mois est financé ; un solde positif ne donne pas l'accès si le mois ne l'est pas. | FIN4-08 ; §13 |
| FI3 | On vend un accès mensuel à une classe, jamais des séances. Débit par mois civil, jamais par séance ; une absence ne réduit rien ; aucun débit partiel : l'écran dit le manque. | FIN4-02 à 05, 09 |
| FI4 | Essai : 2 séances au plus, gratuites, sans toucher au solde, affiché « Essai : n/2 ». Un essai ne compte jamais comme payant dans un indicateur. | FIN4-10 à 17 |
| FI5 | Toute ligne de prix (tarif, remise de rang, réduction calendrier, avoir, taxe) vient des données. Jamais une remise affichée qui n'existe pas. | §1.3 ; §5.2 |
| FI6 | Aucune valeur commerciale dans un widget : tarifs, remises, taux, capacités, délais, marge sont dans la politique versionnée (démonstration en FI-1c). Flutter formate ; il ne calcule ni prix, ni remise, ni taxe, ni paie. | §1.3 ; §7 ; §13 ; §14 |
| FI7 | Une seule recharge pour 1 ou n profils. « Recharger Mariam » ouvre ce flux avec Mariam cochée. Compte > Paiements devient un raccourci vers la surface canonique. | §4 ; §5.3 |
| FI8 | Recharge : case par profil, montant par profil (désactivé si non coché), total unique, moyen, explication de la répartition, un seul bouton. Le total additionne les montants choisis ; le serveur l'arrête avant le paiement. | §1.6 ; §5.3 |
| FI9 | Paiement : huit états (`preparing`, `awaiting_confirmation`, `confirmed`, `allocation_in_progress`, `completed`, `failed`, `cancelled`, `stale`). Jamais « confirmé » au retour d'un écran externe. Une même confirmation reçue deux fois ne crédite qu'une fois. Un échec garde la sélection. | §1.6 ; §5.4 ; F4 |
| FI10 | Seul le rail `WEB_STRIPE` est montré. Aucun bouton App Store ni Play. | §1.6 |
| FI11 | Impayé : aucun compte désactivé. Le tuteur garde Foyer, historique, paiements, informations ; la nouvelle période dit « À régulariser » ; la place est conservée la durée de la politique. | §1.7 |
| FI12 | Un enfant ne lit jamais une cause financière : « Accès à cette classe temporairement indisponible. Votre tuteur peut gérer l'accès. » Le tuteur et l'adulte lisent le manque exact. | §1.7 ; F5 |
| FI13 | Taxes séparées du tarif académique ; le total réellement débité est visible avant confirmation ; aucun taux dans Flutter ; une taxe n'est jamais présentée comme revenu. | §1.8 |
| FI14 | Montants : chiffres tabulaires, signe explicite, devise toujours identifiable, format de la langue active (intl). Unités mineures + code ISO dans les données. | §7 ; §11.3 ; K-41.5 |
| FI15 | Chaque profil porte `ProfileIdentityAvatar` : photo ou initiale, bandeau d'accent derrière, nom lu (« Mariam, profil enfant, Classe An-Nour »). L'accent vient d'une clé stable, jamais de l'index de la liste ; il n'est ni un statut, ni une classe, ni une alerte ; pas de filtre sur la photo. | §3 ; §11.5 |
| FI16 | L'accent reste local à l'avatar : jamais sur la carte, le fond, un montant, un statut, un bouton. | §3.5 |
| FI17 | Un statut se dit par pastille + point ou icône + texte, jamais par la couleur seule ; l'accent de profil ne ressemble jamais à un statut. | §11.4 ; WCAG 1.4.1 |
| FI18 | Contenus liés = une carte, lignes à filets (GroupeReglages) ; contenus indépendants = cartes séparées par l'écart des jetons. | §7 ; K-55 |
| FI19 | Bureau pensé pour 1440 : colonnes, panneaux, tableaux compacts. Jamais une colonne de téléphone étirée ou centrée. Mobile : une décision principale, bouton principal atteignable, retour clair. | §6 ; §11.6 ; §11.7 |
| FI20 | Enseignant : une estimation marquée comme telle, base garantie + occupation, plafonnée ; Internet à part ; jamais un solde de famille ni un montant payé par un élève ; aucun bonus « classe pleine ». | §1.4 ; §5.5 |
| FI21 | Vue globale : encaissement, revenu, solde client, charge et marge toujours séparés ; aucun graphique sans le nombre exact ; la marge de référence n'est jamais une sanction ni un blocage. | §1.5 ; §5.6 |
| FI22 | Politiques : brouillon ou publiée, date d'effet, comparaison avec la version active, aperçu avant publication ; les invariants (idempotence, séparation des soldes, historique en ajout seul, confirmation avant crédit, pas de double débit, accès par période) ne sont jamais des champs. Aucune écriture réelle. | §5.7 ; §8 F8 |
| FI23 | Le comptable lit la même Finance, avec des permissions adaptées ; jamais un second système. PISI est hors périmètre. | §4 ; §1.9 |
| FI24 | La maquette fait foi pour l'ordre, la densité, les colonnes et la place des actions ; pas pour les valeurs. Comparer capture et maquette côte à côte avant « fait ». | §2 ; §11.1 ; §11.2 ; K-61.4 |

## 8. À lire avant chaque étape

`LECONS_DES_ROLES.md` (15 erreurs), `YAADEN_RULES.md`, K-07, K-10, K-36, K-41, K-42, K-51, K-54 à K-61, puis la section du guide citée par l'étape (`02_DECOUPAGE.md`).
