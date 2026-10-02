# UX_REVIEW_08_FINANCE : revue UX 2026 du domaine Finance (étape FI-1a)

Rédigée le 02/10/2026, avant tout écran de la vague Finance, en application de `DESIGN-GOV-2026-09-26` §4.1 à §4.3 et §4 bis. Corrigée le même jour après relecture (maquettes 08 à 10, Compte > Paiements, données par rôle, teintes). Document seulement : aucun code, aucun commit. Les worktrees `D:\RA_TUTEUR\adultes` (`ui/eleves-adultes-v1` @ 5629693), `D:\RA_TUTEUR\admin` (`ui/admin-v1` @ a8dfcb3) et `D:\RA_TUTEUR\corrections` (`corrections/revue-directeur-2026-10` @ 0796f75) ont été lus, rien n'y a été écrit.

**Lectures.**
- Guide du directeur `V/REWAYAH_FINANCE_FRONTEND_GUIDE_V4_2026-10-02.md` : §0, §1 (1.1 à 1.8), §2, §3, §4, §5, §6, §7, §8 (F2 à F8), §11, §12, §13, §14, §15, §16.
- Les 10 maquettes de `V/`, ouvertes une à une (01 à 07, puis 08 à 10 reçues le 02/10 à 23 h).
- `ECARTS_MAQUETTES_08_10.md` (écarts A1 à A9, B1 à B8, C1 à C8, D1 à D12).
- `00_REPRISE.md`, `02_DECOUPAGE.md` (ligne FI-1a), `QUESTIONS.md`, `FI-BR.md`.
- `DESIGN-GOV-2026-09-26.md` §4 et §4 bis (contrats A à E).
- `LECONS_DES_ROLES.md` leçons 3, 4, 11, 12, 13, 15.
- `DECISIONS_DELEGUEES_2026-10-02.md` (voir « Corrections à `00_REPRISE.md` », point C-3).
- Modèle de forme : `16_eleves_adultes/UX_REVIEW_07_ELEVES_ADULTES.md`.

**Règle de priorité.** Pour la finance, le guide prime sur toute règle antérieure incompatible (guide §0, point 1). Les maquettes priment pour la composition, l'ordre et la place des actions, pas pour les valeurs (§0 point 2 et 5, §2 « Règle de fidélité »), ni pour la coque, les couleurs et le lexique (`ECARTS_MAQUETTES_08_10.md`, « Comment s'en servir »). Les règles non financières (classe, navigation, sécurité, vocabulaire) restent celles du projet (§0, 2e paragraphe).

**Limite §4.3.** Les standards cités ne changent ni une permission, ni un état serveur, ni une règle métier FIN4, ni une valeur commerciale. Quand un standard pousse ailleurs que le guide, le guide est gardé.

**GOV.UK exclu** (DESIGN-GOV §4.1). **Thème** : aucune couleur ni jeton proposé (K-37). **RISQUE, envoyé en TH-2.** `00_REPRISE.md` l. 57 propose de prendre l'accent de profil dans les 32 teintes `teintesIdentite` par `teinteGroupe(index)` (`adultes/lib/core/theme/app_palette.dart:306`, `:309`). Ces teintes sont déjà l'identité des classes (`lib/core/tc_groupe/palette_groupe.dart:21`) et des couvertures (`lib/features/tc_catalogue/vignette_ressource.dart:126`, via `teinteCouverture`, `app_palette.dart:314`). Or le bandeau de profil « n'est PAS une couleur de classe » (guide §3.2), et ces teintes ne sont pas des « accents de profils déjà présents » (§3.8 point 2). Sur une même carte, un enfant et sa classe pourraient avoir la même teinte. Décision : **ne pas réutiliser `teinteGroupe` tel quel**. TH-2 tranche entre (a) des jetons d'accent de profil distincts, ajoutés au design system et figés par test (§3.8 points 3 et 5, seule exception de couleur approuvée), ou (b) une règle écrite qui interdit qu'un profil et une classe affichés ensemble partagent une teinte. Jusque-là, FI-2 ne pose aucune teinte de profil. Si le directeur veut les teintes exactes des maquettes : même ligne TH-2. **Coran, serveur** : non touchés ; chaque besoin serveur est déjà une ligne de `FI-BR.md`.

**Décisions.** « Garder » : la maquette ou le guide est suivi tel quel. « Adapter » : gardé avec une modification concrète. « Refuser » : un élément est écarté, la ligne dit lequel et pourquoi.

## Sources consultées

| Code | Source | URL | Date et vérification |
|---|---|---|---|
| W-334 | WCAG 2.2, 3.3.4 Error Prevention (Legal, Financial, Data), AA : « at least one of the following is true: Reversible, Checked, or Confirmed » | https://www.w3.org/WAI/WCAG22/Understanding/error-prevention-legal-financial-data.html | 02/10/2026, lue en ligne |
| W-413 | WCAG 2.2, 4.1.3 Status Messages, AA : un message d'état est exposé par rôle ou propriété, annoncé sans prendre le focus | https://www.w3.org/WAI/WCAG22/Understanding/status-messages.html | 02/10/2026, lue en ligne |
| W-141 | WCAG 2.2, 1.4.1 Use of Color, A : la couleur n'est jamais le seul moyen visuel de transmettre une information ou de distinguer un élément | https://www.w3.org/WAI/WCAG22/Understanding/use-of-color.html | 02/10/2026, lue en ligne |
| W-323, W-2411, W-258, W-1410, W-144, W-243 | WCAG 2.2 : navigation cohérente, focus non masqué, taille de cible, reflow 320, texte 200 %, ordre du focus | voir `UX_REVIEW_07_ELEVES_ADULTES.md` | lues le 26/09/2026, non relues ce jour |
| BAY-REV | Baymard, « Order Review » et « Payment UX » : modifier sur place à l'étape de relecture (ne pas renvoyer en arrière), action principale visible sans défiler, relecture facile à parcourir, ne jamais confondre relecture et confirmation de commande, le bouton dit ce qui suit | https://baymard.com/checkout-usability/benchmark/step-type/order-review ; https://baymard.com/blog/payment-ux | 02/10/2026, vérifiée par recherche en ligne ; pages non relues en entier |
| HIG-ST | Apple HIG, Steppers : « Make the value that a stepper affects obvious » ; le stepper ne montre pas de valeur, il se pose à côté du champ qui la montre | https://developer.apple.com/design/human-interface-guidelines/steppers | 02/10/2026, page rendue en JavaScript ; règle vérifiée par recherche en ligne |
| HIG | Apple HIG, Accessibility : cible 44 x 44 pt | https://developer.apple.com/design/human-interface-guidelines/accessibility | relue par recherche le 26/09/2026 |
| M3-SEG | Material Design 3, Segmented buttons : choisir une option, changer de vue ou trier, de 2 à 5 options, sélection unique par défaut | https://m3.material.io/components/segmented-buttons/guidelines ; https://api.flutter.dev/flutter/material/SegmentedButton-class.html | 02/10/2026, vérifiée par recherche en ligne |
| M3-WSC / F-AR | Material 3, classes de fenêtre ; Flutter adaptive et responsive (ne pas étirer, décider sur la fenêtre) | voir `UX_REVIEW_07` | lues le 26/09/2026, non relues ce jour |
| NN-10 / NN-CD | NN/g, 10 heuristiques ; dialogues de confirmation (seulement pour une conséquence sérieuse) | voir `UX_REVIEW_07` | lues le 26/09/2026 |
| HICK / NN-GP | Loi de Hick ; proximité Gestalt | voir `UX_REVIEW_07` | lues le 26/09/2026 |

## Inventaire vérifié de l'existant utile à cette revue

Chaque ligne a été ouverte ce jour. « adultes » = `D:\RA_TUTEUR\adultes`, « admin » = `D:\RA_TUTEUR\admin`, « corrections » = `D:\RA_TUTEUR\corrections`.

| Existant | Où | Ce qu'il fait aujourd'hui |
|---|---|---|
| Foyer du tuteur et Ma famille du titulaire | adultes `lib/features/foyer/foyer_page.dart:76` | Une seule page. Bouton dominant « Ajouter un profil élève » (`:192-198`), sous le titre sur téléphone, dans l'en-tête sur bureau (`:331-334`). Profils en lignes groupées « Profils élèves » (`:454`). Section des soldes seulement pour le titulaire adulte et seulement sur bureau (`:260-266`) ; sur téléphone, une ligne « Paiements du foyer » vers la page des paiements (`:267-271`). |
| Section des soldes | adultes `lib/features/compte/soldes_foyer.dart:33` | Une ligne par bénéficiaire, solde « tel que rendu » (`:162-163`), pastilles d'exception « Bientôt épuisé », « Inactif » (`:124-133`), un bouton « Recharger » au bord de fin (`:177-189`), récapitulatif discret (`:194-203`). Posée à deux endroits : `foyer_page.dart:261` et `paiements_page.dart:116`. |
| Compte > Paiements | adultes `lib/features/compte/paiements_page.dart:38` `PaiementsComptePage` ; route `/tuteur/compte/paiements` (`lib/core/router/app_router.dart:662-666`) | Historique des paiements (date, justificatif). Avec `soldes: true` (titulaire adulte, « Paiements du foyer », `demo_adulte_page.dart:1239-1244`), pose d'abord `SoldesFoyerSection` et son « Recharger » (`paiements_page.dart:110-116`). Le second adulte n'a que l'historique, jamais les soldes (`:36-37`, E3 ; `demo_adulte_page.dart:1114-1117`). L'élève adulte y arrive depuis Mon espace (`demo_adulte_page.dart:1022-1024`). |
| Recharge | adultes `lib/features/foyer/recharge_foyer.dart:39` | Deux étapes : bénéficiaires (case, offre, « Tout sélectionner »), puis « Vérifier la recharge » avec « Modifier » par bénéficiaire et « Payer {montant} » (`:5-13`, `:455-456`, `:617`, `:666`). |
| Contrat de recharge | adultes `lib/core/capacites/port_recharge_foyer.dart` | Solde rédigé (`:59-60`), une offre par bénéficiaire, jamais un montant (`:66-67`), total jamais additionné (`:147`), paiement idempotent qui rend un état rédigé (`:159-163`). |
| Fiche élève | adultes `lib/features/foyer/fiche_eleve_page.dart:241` | Identité, groupe « Paramètres de l'élève » : Informations, Parcours et inscription, Interface, Caméra en cours, Accès Rewayah (`:304-335`) ; Appareils (`:340-362`). Âge non affiché, non enregistré (`:235-236`). Place réservée pour le solde (`:238-240`). |
| Page Accès | adultes `lib/features/foyer/fiche/acces_page.dart:15-27` | Lecture seule de l'accès daté (`access_until`), jamais « abonnement ». |
| Mon espace (élève adulte) | adultes `lib/features/mon_espace_adulte/mon_espace_adulte_page.dart:105-106`, `:281-290`, `:338-344` | Rubrique « Paiements » (hors forfait famille) ; rubrique « Paiements du foyer » pour le second adulte. Les deux n'existent qu'une fois la donnée lue (permission par l'absence, `:278-280`). |
| Contrôle segmenté | adultes `lib/core/widgets/controle_segmente.dart:35` | 2 à 4 vues ; peut changer de route (Historique, `:32-34`) ; sélection jamais par la couleur seule (`:25-27`). |
| Sous-navigation de domaine admin | adultes et admin `lib/core/widgets/sous_navigation_domaine.dart:21` | Onglets = routes distinctes. |
| Domaine Finance admin | admin `lib/core/admin/admin_domaine.dart:31-33`, `:99`, `:124` | Réservé, visible, inerte. Configuration = « règles globales du système, distinctes de Finance par nature » (`:35-37`). |
| Enseignant | corrections `lib/core/widgets/nav_shell.dart:150-152`, `:155-175` ; `lib/core/router/routes.dart:289-290` | Quatre destinations : Aujourd'hui, Classes, Disponibilités, Profil. **Pas de « Compte »** : Profil (`/enseignant/profil`) porte les réglages. |
| Profil de l'enseignant | corrections `lib/features/profil_enseignant/profil_enseignant_page.dart:61` | Groupes Statut, Identité, Contrat (`:592-628`), Personnel (`:660-683`), déconnexion. |
| StatusPill | adultes `lib/core/widgets/status_pill.dart:60` | Pastille + mot, jamais la couleur seule (`:50-54`) ; libellé « deux mots au plus » (`:64`). |
| PermanentNotice | adultes `lib/core/widgets/permanent_notice.dart:8-35` | **Mention de la salle (ADR-011), sans aucun paramètre.** Inutilisable pour un bandeau financier (voir C-1). |
| EcranResultat | adultes `lib/core/widgets/ecran_resultat.dart:31` | Cercle, titre, phrase, une action ; action jamais rendue sans geste (`:25-26`). |
| Textes existants | adultes `assets/i18n/fr.i18n.json` | Recharge `:3886-3915`, paiements `:3916-3927`, Foyer `:787-817`, fiche `:866-887`, montants de démonstration en euros `:4158-4169`. |

## Revue, une ligne par écran du guide §5

Colonnes : n°, écran (guide, maquette), sources, règle utile, décision, modification concrète, règle Rewayah.

| N° | Écran | Sources | Règle utile | Décision | Modification concrète | Règle Rewayah |
|---|---|---|---|---|---|---|
| 1 | **Foyer, Soldes et paiements, mobile** (guide §5.1 « Mobile », maquette 03) | guide §5.1, §11.7, §13 ; W-141 ; HICK ; NN-GP | Une décision principale par écran. Une action à un seul endroit. Statut jamais par la couleur seule. | Adapter | a) Ordre de la maquette gardé : titre « Foyer » et sous-titre « Soldes et paiements » ; trois compteurs (enfants, profils financés, paiements du mois) ; carte « Total des soldes (lecture) » et « À payer ce mois » ; « Recharger plusieurs profils » 16 sous la carte ; section « Enfants du foyer ». b) **Refuser** le « + Recharger » de l'en-tête : il double « Recharger plusieurs profils » (guide §13, 1er point ; `00_REPRISE.md` §5). Voir Q-FI-9. c) Une seule action pleine : « Recharger plusieurs profils ». « Ajouter un profil élève » (`foyer_page.dart:192-198`) passe au niveau secondaire, à sa place actuelle (voir Q-FI-2). d) Carte d'enfant : `ProfileIdentityAvatar`, prénom, âge **seulement s'il est rendu** (`fiche_eleve_page.dart:235-236`), classe, pastille de période, « Accès jusqu'au {date} », Solde actuel, Prochain débit, **une** action. e) **Refuser** le chevron à droite de « Prochain débit » : il ouvre la même fiche que « Voir le détail » (§13) ; la maquette 05 n'en a pas. Voir Q-FI-9. f) Le bouton de carte est secondaire, jamais plein (contrat B règle 4 ; `02_DECOUPAGE` FI-4). Son libellé visible est celui de la maquette, son nom lu porte le prénom (« Recharger Ibrahim »). g) « Recharger » d'un enfant ouvre la recharge avec lui seul coché (guide §4, FI7). h) **Refuser** « Gérer tous les enfants » : la liste des enfants EST cette section ; le lien n'a pas de cible distincte (leçon 11). Voir Q-FI-9. i) Les cartes remplacent la liste « Profils élèves » (`foyer_page.dart:454`) et la section des soldes (`foyer_page.dart:260-266`) : jamais deux listes des mêmes enfants (§13). La ligne « Paiements du foyer » (`:267-271`) suit la ligne 14. | FI1, FI7, FI15 à FI18, K-56, contrat B. |
| 2 | **Foyer, bureau 1440** (§5.1 « Desktop », maquette 05) | guide §5.1, §6, §11.1, §11.6, §13 ; M3-WSC ; F-AR | Vraie composition bureau : rangée de synthèse, cartes en colonnes, panneaux. Jamais le mobile étiré. Ne pas interpréter la maquette. | Adapter | a) Rangée de synthèse en 4 blocs comme la maquette : Total des soldes (lecture), À payer ce mois, Profils financés, puis « Recharger plusieurs profils » avec la note « Chaque enfant a un solde… » dessous. b) Cartes d'enfants en colonnes (3 par rangée à 1440 ; au-delà, nouvelle rangée, jamais une colonne étirée). c) Le « Recharger » d'Ibrahim, plein dans la maquette, devient **secondaire** : un seul bouton plein par écran (contrat B règle 1). Chevrons des boutons de carte refusés comme en 1 e. d) « Vue financière du foyer » : **gardée telle que la maquette 05**, à sa place, avec son sélecteur de mois et ses deux valeurs, total des soldes (« Sur {n} enfants ») et à payer ce mois (« Pour {n} profils financés »), rendues par les données (FI-BR-04). Libellé du total unifié avec la rangée de synthèse (« Total des soldes (lecture) », un seul libellé). Ces deux valeurs répètent la rangée de synthèse (§6, duplication) : rien n'est retiré ni remplacé sans réponse (Q-FI-8). e) « Dernières transactions » gardées, « Voir tout » ouvre l'historique du foyer (ligne 14). f) **Refuser** le panneau « Actions rapides » : « Recharger plusieurs profils » y est une 2e fois (§13) ; « Gérer les accès, Définir les périodes financées » contredit le modèle (la période est financée par un paiement et arrêtée par le serveur, FIN4-06, FIN4-08 ; la page Accès est en lecture seule, `acces_page.dart:15-27`). « Dernières transactions » prend la place libérée. Voir Q-FI-3. g) 768 et 1200 : composition intermédiaire (cartes sur 2 colonnes, synthèse sur 2 rangées), jamais la maquette compressée (§13). | FI1, FI19, K-42 point 6, contrat D. |
| 3 | **Fiche élève, Finances, mobile** (§5.2, maquette 02) | guide §5.2, §11.7 ; M3-SEG ; W-323 ; W-141 | Détail data-driven, aucune remise inventée. Segmenté = 2 à 5 vues exclusives. | Adapter | a) Onglets : `ControleSegmente` existant (`controle_segmente.dart:35`), chaque segment est une route, comme l'Historique (`:32-34`) : « Général » = la fiche existante (`/tuteur/foyer/:eleveId`), « Finances » = `/tuteur/foyer/:eleveId/finances` (guide §4). b) **« Apprentissage » non affiché** : ni le guide, ni la fiche existante, ni une décision ne disent ce qu'il contient ; un segment sans contenu est un bouton qui ne mène nulle part (leçon 11). Voir Q-FI-1. c) En-tête : grand `ProfileIdentityAvatar`, prénom, âge si rendu, classe, pastille d'**accès** « Accès actif » (maquette 02 ; identité, guide §5.2) ; la date « Jusqu'au… » n'y est pas répétée : elle est dans la carte de période (une seule fois par écran). d) « Vue financière » : Solde actuel ; pastille de **période** (« Décembre financé ») et « Accès jusqu'au {date} » ; Prochain débit ; Mensualité. e) « Détail de la mensualité » : une ligne par élément rendu (tarif, remise de rang, réduction calendrier, avoir, taxe), puis « Total à financer » (guide §5.2). **Refuser** les valeurs de la maquette (30 $, « Remise famille −5 $ » sur Mariam, 2024 : guide §2). Aucune ligne de remise si le rang rendu n'y donne pas droit (rang 1 ou 2, guide §1.3 ; guide §2 « si son rang familial n'y donne pas droit »). f) Note sur les absences gardée (FIN4-04). g) « Recharger Mariam » plein, 16 sous la note ; « Voir les mouvements » secondaire, 8 dessous (contrat A, B). | FI2 à FI6, FI13, FI14, contrat B. |
| 4 | **Fiche élève, Finances, bureau 1440** (§5.2, maquette 06) | guide §5.2, §6, §11.6 ; W-323 | Colonnes, panneaux ; ne pas dupliquer. | Adapter | a) Trois colonnes de la maquette : identité, Vue financière, Historique des transactions. Fil d'Ariane « Foyer › Mariam », titre « Mariam · Finances ». b) Pas de contrôle segmenté à 1200 et plus (absent de la maquette 06) : la colonne d'identité porte **le groupe existant** « Paramètres de l'élève » (`fiche_eleve_page.dart:299-338`), réutilisé, jamais recopié ; la maquette en montre une version (Classe, Interface, Caméra, Accès Rewayah) qu'on ne redessine pas (K-51, `02_DECOUPAGE` FI-6a). c) La période apparaît une fois : dans la Vue financière. La pastille « Décembre financé » sous l'identité est **refusée** (elle répète la carte voisine et la ligne « Accès Rewayah »). d) « Télécharger le reçu » secondaire sous « Recharger Mariam » ; affiché seulement si un reçu est rendu (FI-BR-05, leçon 11). e) Bandeau du bas : gardé avec ses trois faits (« Pas de consommation par séance », « Accès lié à la période financée », historique de présence). **Refuser** « Un seul paiement sera effectué… réparti… entre les profils sélectionnés » : c'est le texte de la recharge, faux sur la fiche d'un seul enfant. | FI3, FI5, FI18, FI19, K-51. |
| 5 | **Mouvements d'un profil et reçu** (§4 `…/:studentId/mouvements`, §5.2 ; sans maquette dédiée, panneaux de 05 et 06) | guide §4, §5.2, §7 `TransactionRow` ; W-141 | Historique en ajout seul. Signe et texte, jamais la couleur seule. | Adapter | a) Liste à 390, tableau compact à 1440 (`DataCollection`, `data_collection.dart:96`). b) Une ligne : icône de type, libellé (« Recharge », « Mensualité {mois} », « Avoir »), date et heure au format de la langue, montant signé (+ / −). La couleur du montant n'est qu'un renfort. c) **Refuser** « Recharge manuelle » : aucune recharge automatique n'existe dans le guide ; « Recharge » suffit. d) Filtre par personne avec avatar (§3.4). e) Aucune action « supprimer » (append-only, §5.7 invariants). | FI14, FI17, FI-BR-05. |
| 6 | **Recharge multi-profils, mobile** (§5.3, maquette 04) | guide §1.6, §5.3 ; W-334 ; BAY-REV ; HIG-ST ; W-258 ; HICK | Relecture et confirmation avant engagement. Modifier sur place. La valeur du stepper est évidente. | Adapter | a) Une seule page, comme la maquette : « Profils à recharger » (case, avatar, prénom, classe, stepper de montant), « Total à payer » avec l'explication, « Moyen de paiement », « Payer {total} ». b) Le montant au centre du stepper est un champ lisible et saisissable ; − et + changent d'un pas lu dans la politique (`00_REPRISE.md` §5 INCONNU) ; profil non coché = montant désactivé (§5.3). Cibles de 48 (W-258). c) « Minimum suggéré : {montant} » sous la ligne quand les données le rendent (§5.3). d) Le total additionne les seuls montants choisis (FI8) ; il est arrêté par le serveur à l'appui sur « Payer » (état `preparing`). Si le serveur ajoute une ligne (taxe, §1.8) ou change le total, la page l'affiche dans le bloc du total avec « Vérifiez la répartition avant de payer. » (§5.4) et le bouton devient « Payer {nouveau total} » : aucun frais nouveau sans relecture (BAY-REV, W-334 « Confirmed »). e) Cette page remplace les deux étapes d'EA-10 : la relecture est sur place, rien ne renvoie en arrière (BAY-REV). f) Moyen de paiement : `ChoiceCardGroup` (`choice_card_group.dart:78`), carte entière cliquable. **Refuser** les chevrons des cartes de choix (un bouton radio ne mène pas ailleurs). Voir Q-FI-9. g) **Refuser** « Paiement sécurisé et chiffré » : l'application ne peut pas l'affirmer sans le rail branché (leçon 10). Voir Q-FI-4. h) Rail `WEB_STRIPE` seul ; aucun bouton App Store ni Play (§1.6). | FI7, FI8, FI10, FI13, FI14, F4. |
| 7 | **Recharge, bureau 1440** (§5.3, maquette 07 « Paiement du foyer ») | guide §5.3, §6, §13 ; W-334 ; BAY-REV | Une action à un seul endroit. Le bouton principal visible sans défiler. | Adapter | a) Trois colonnes de la maquette : Profils à recharger, explication, Récapitulatif du paiement. Le récapitulatif **garde la liste par profil** de la maquette (avatar, prénom, montant choisi), puis le total, le moyen de paiement et « Payer {total} ». Le moyen de paiement reprend le `ChoiceCardGroup` de la ligne 6 f (cartes entières, sans chevron) : le moyen affiché par défaut est le premier rendu, les autres se choisissent sur place, sans page ni dialogue en plus. b) **Refuser** « Recharger plusieurs profils » en tête : la page EST la recharge (`00_REPRISE.md` §5). Le 4e bloc de la rangée de synthèse (bouton + note) disparaît : la note est déjà dans la colonne du milieu. Les trois blocs de lecture restent. c) Titre : « Recharge » sur toutes les largeurs (W-323, une même page garde un même nom), sous-titre de la maquette 07. Voir Q-FI-5. d) Bandeau « Accès à régulariser » gardé, en bas comme la maquette ; son bouton, sur cette page, coche l'enfant et met le minimum suggéré : il s'appelle donc « Ajouter Ibrahim à la recharge » (contrat B règle 6). **Refuser** la croix de fermeture : l'état dure tant qu'il n'est pas réglé (§1.7). Voir Q-FI-6. | FI7, FI8, FI11, FI19. |
| 8 | **États du paiement et résultat** (§5.4, maquette 01) | guide §1.6, §5.4 ; W-413 ; BAY-REV ; NN-10 n° 1 et 9 | Jamais « confirmé » au retour d'un écran externe. Message d'état annoncé sans voler le focus. | Adapter | a) Huit états (§1.6), chacun avec son texte : `preparing` « Vérifiez la répartition avant de payer. » ; `awaiting_confirmation` « Paiement en cours de confirmation », « Ne payez pas une seconde fois. » ; `confirmed` et `allocation_in_progress` « Paiement confirmé », « Mise à jour des soldes… » ; `completed` = la maquette 01 ; `failed`, `cancelled`, `stale` : voir lexique. b) Succès : montant total, référence, moyen, date, répartition, nouveau solde par profil (§5.4), sur `EcranResultat` (`ecran_resultat.dart:31`). c) **Refuser** l'éclat et les confettis autour de la coche (contrat E : aucune animation de réussite ; `02_DECOUPAGE` FI-8). d) **Refuser** le « ! » du titre (§5.4 dit « Paiement confirmé »). e) Coche par profil gardée avec un nom lu (« Crédité ») ; « Soldes mis à jour » reste une annonce d'état (W-413). f) Échec : la sélection est conservée ; « Réessayer », « Changer de moyen de paiement », « Retour » (§5.4). g) « Retour aux soldes » au bord de fin, 16 sous le dernier bloc. | FI9, D5, K-59, contrat E. |
| 9 | **Accès, essai, impayé** (§1.2, §1.7, §8 F5 ; sans maquette dédiée, bandeau de 07) | guide §1.7, §4 « Élève enfant » ; W-141 ; W-413 ; leçon 15 | L'enfant ne lit jamais une cause financière. Le compte reste navigable. | Garder | a) Textes du guide mot pour mot (lexique). b) `EmplacementEntree` non modifié : Rejoindre indisponible avec la raison existante (`00_REPRISE.md` §4, règles R1 à R21). c) « Essai : n/2 » jamais compté comme payant. d) Aucun compte désactivé. e) Côté enfant, le montant manquant, la cause et le solde ne sont **jamais chargés**, pas seulement non affichés (voir « Données financières par rôle »). | FI2, FI4, FI11, FI12. |
| 10 | **Élève adulte, mes finances** (§4 « Élève adulte ») | guide §4 ; W-323 ; §13 | Ne pas dupliquer le Foyer. Une seule surface. | Adapter | a) Correspondance : **`/eleve/finances` (guide §4) = la fiche Finances (n° 3, n° 4) pour son seul profil**, avec son historique ; la route exacte s'aligne sur la coque adulte existante en FI-9b (guide §4 « adapter à l'existant »), sans créer une seconde route. b) La rubrique « Paiements » de Mon espace (`mon_espace_adulte_page.dart:105-106`, `:281-290`) y mène. La page qu'elle ouvre aujourd'hui (`PaiementsComptePage`, historique seul, `demo_adulte_page.dart:1022-1024`) n'est plus une destination à part : son historique devient la section historique de cette fiche ; il ne reste qu'une surface. c) Sa recharge = la même page (n° 6) avec son profil seul. d) Pas de segmenté Général / Finances (il n'a pas de fiche « Général »). | FI7, FI-BR-17. |
| 11 | **Enseignant, Revenus** (§5.5, maquette 08) | guide §1.4, §4, §5.5 ; `ECARTS_MAQUETTES_08_10` A1 à A9, B1 à B8 | Une estimation, jamais une paie. Hors coque de la direction. | Adapter | a) **Coque** : écran de l'espace Enseignant, `/enseignant/revenus`, ouvert depuis le **Profil** (point 3 ci-dessous ; B1 dit « Compte », mais l'enseignant n'a pas de Compte, C-2). **Refuser** la barre latérale de la direction, ses 11 entrées, le fil « Finance > Revenus de l'enseignant », la recherche, la cloche, la puce « Tuteur » et le pied « Admin » (A1 à A4, B1). b) Titre et sous-titre : **Adapter**, le titre dit que c'est une estimation (« Revenus estimés », B5, §5.5). c) Sélecteur de mois avec flèches : **Garder** (structure de la maquette), dates réalistes (A7). d) Rangée de 4 tuiles : **Adapter** en une rangée de synthèse sobre (A8) : revenu estimé du mois, heures assurées, classes actives (« 3 », objectif 3 et maximum 4 seulement si utile, B7), taux horaire effectif moyen ; **Refuser** les flèches « vs mois précédent » tant que la donnée n'est pas rendue (A8), et les pastilles d'icônes multicolores (A5). e) « Détail par groupe » : **Adapter** en « Détail par classe » (A6) ; colonnes du guide §5.5 : classe, type, capacité, sièges éligibles, heures assurées, taux horaire effectif, montant estimé, ligne de total gardée ; capacités et taux de démonstration recalculés par la formule, jamais au-dessus de 7 (B2, B3, §1.4) ; tableau compact à 1440, lignes groupées sur téléphone (§6). Aucune formule dans le widget (FI6) : le taux vient du port. f) Carte « Nouvelle règle de rémunération » : **Garder** à sa place (B8) : base garantie, composante occupation, plafond horaire (§5.5). g) « Historique des paiements » et « Voir tout » : **Adapter** : structure gardée, statut jamais « Payé » présenté comme définitif sans le serveur (B5). h) « Allocation Internet » : **Garder** à part de la rémunération, une seule fois, montant de démonstration (B6). i) « À propos des anciennes primes » : **Refuser** (B4, §13 : un ancien montant 20/26 ou 10/20 ne réapparaît pas). j) Interdits : solde de famille, montant payé par un élève, bonus « classe pleine » (§1.4, §5.5). | FI20. |
| 12 | **Finance, Vue globale** (§5.6, maquette 09) | guide §1.5, §5.6, §6, §8 F7 ; `ECARTS_MAQUETTES_08_10` A1 à A9, C1 à C8 ; W-141 | Encaissement, revenu, solde, charge, marge séparés. Chaque graphique porte son nombre exact. | Adapter | a) **Coque** : AdminShell réel, domaine Finance, onglet « Vue globale » (`admin_domaine.dart`) ; **Refuser** les entrées inventées, la recherche large, la puce « Tuteur / Administration » (A1 à A4). b) Sélecteur de mois : **Garder** (A7 pour les dates). c) 7 indicateurs : **Adapter** : les 7 du guide gardés (C6) en grille lisible à 1440, propre à 1200 et 768 ; « Marge projetée », jamais « observée » (C2) ; « Essais en cours » = un **nombre** d'élèves, jamais un montant (C1) ; flèches « vs mois précédent » seulement si la donnée est rendue (A8) ; pas de pastilles multicolores (A5). d) « Évolution des encaissements, coûts et marge » : **Adapter** : encaissement, charge et marge jamais mêlés dans un même histogramme (C5) ; un graphique par notion, chacun avec son nombre exact (§8 F7). e) « Répartition des revenus » : **Adapter** : catégories du modèle seulement, par type d'élève (enfant, adulte) ou par classe (C3) ; **Refuser** frais de scolarité, inscriptions, cours additionnels, dons. f) « Évolution de la marge » : **Garder**, la référence ~30 % est un repère de pilotage, jamais une sanction (§1.5). g) « État des paiements » (Financés, À régulariser, En essai, En confirmation) : **Garder** (C7), couleurs d'état des jetons seulement. h) « Top classes (par encaissements) » : **Garder** (C8), aucune classe dite « mauvaise » par la marge. i) « Alertes et actions » : **Garder** (C7) ; chaque ligne ouvre sa cible, une seule fois. j) « Dernières opérations » : **Adapter** aux mouvements du modèle seulement : recharges, allocations par profil, paie enseignant, remboursements (C4). | FI21. |
| 13 | **Politiques commerciales** (§5.7, maquette 10) | guide §1.3, §1.5, §5.7, §8 F8 ; `ECARTS_MAQUETTES_08_10` A1 à A9, D1 à D12 ; K-56 | Versionnée ; les invariants ne sont pas des champs. Un seul bouton plein. | Adapter | a) **Coque** : AdminShell réel, domaine Finance, onglet « Politiques commerciales » (`/admin/finance/politiques`, voir plus bas) ; **Refuser** la barre bleu nuit et les entrées inventées (A1, A2). b) Bandeau de version (brouillon v2.1.0 → active v2.0.0, date d'effet) : **Garder** (D11) ; date d'effet obligatoire avant publication. c) Actions : **Adapter** (A9, D9) : brouillon enregistré, puis « Aperçu avant publication » secondaire, puis « Publier la version », seul bouton plein, sous ce qu'il confirme ; **Refuser** « Enregistrer les modifications » plein en haut. « Publier » arrive sur un état honnête (aucune écriture, §8 F8, FI-BR-02). d) Menu « … » : **Refuser** : il mêle paramètres et invariants (D10) ; aucun invariant n'est un champ. e) Sélecteur de mois « Octobre 2024 » : **Refuser** : une politique se lit par version et date d'effet, pas par mois (§5.7). Voir Q-FI-9. f) Sept cartes de familles, chacune avec un « Modifier » secondaire : **Garder** la grille et l'ordre ; contenus corrigés : Tarifs « par mois », jamais « par cours » (D1), seuil d'âge non affiché (D4) ; Essai « 2 séances d'essai maximum » + activation (D8) ; Remises par « membre payant », « par mois » (D2, D3) ; Rémunération enseignants + aide Internet (D6) ; **« Classes »** au lieu de « Groupes » (A6, CLASSE-FORM-1) ; Paiement + règles de relance visibles (D7) ; Pilotage ~30 % de référence, budgets marqués « non contraignants » (D5). g) Aperçus « exemple de foyer » et « exemple d'enseignant » : **Garder** (D12), formule enseignant complète, total « par mois » (D2). | FI22. |
| 14 | **Compte > Paiements** (§4 « Si `Compte > Paiements` existe déjà » ; sans maquette) | guide §4, §13 ; W-323 ; leçon 15 | Raccourci vers la surface canonique, jamais un deuxième centre de paiement. Une action à un seul endroit. | Adapter | a) Tuteur : la ligne « Paiements » du Compte devient un **raccourci vers `/tuteur/foyer`** ; `/tuteur/compte/paiements` (`app_router.dart:662-666`) redirige vers le Foyer. b) L'historique des paiements du foyer (`PaiementsComptePage` sans soldes, date et justificatif) est **gardé** : il devient la cible de « Voir tout » des Dernières transactions (ligne 2 e), sous le Foyer. c) **`SoldesFoyerSection` est retirée** de ses deux poses (`foyer_page.dart:260-266`, `paiements_page.dart:116`) : les cartes d'enfants la remplacent (lignes 1 i, 2). Avec elle disparaissent le second « Recharger » et la pastille « Bientôt épuisé » (E-5). d) Titulaire adulte : sa ligne « Paiements du foyer » (`foyer_page.dart:267-271`, `demo_adulte_page.dart:1239-1244`) mène au même historique, sans soldes ni « Recharger ». e) Second adulte : il garde sa page « Paiements du foyer » en lecture seule (historique seul, `paiements_page.dart:36-37`), sans changement. | FI1, FI7, FI-BR-18, E-19. |

## Les trois points à trancher

1. **Un seul « Recharger plusieurs profils ».** Sur le Foyer mobile, il reste dans la carte des soldes ; le « + Recharger » de l'en-tête est retiré. Sur le Foyer bureau, il reste dans la rangée de synthèse ; celui d'« Actions rapides » est retiré avec le panneau. Sur la page de recharge (maquette 07), il est retiré. Le « Recharger » de `SoldesFoyerSection` disparaît avec elle (ligne 14). Source : guide §13 (« une action existe à deux endroits »), §11.7, contrat B règle 1, `00_REPRISE.md` §5.
2. **Onglets de la fiche élève.** Deux segments, « Général » et « Finances », par le `ControleSegmente` existant, chaque segment étant une route (`controle_segmente.dart:32-34`). « Apprentissage » n'est pas affiché tant qu'aucun contenu n'est défini (Q-FI-1). Les sous-pages existantes (Informations, Parcours et inscription, Interface, Caméra, Accès) restent sous « Général » ; sur bureau, elles sont reprises dans la colonne d'identité de la page Finances (maquette 06). Source : guide §2 (fidélité), §4 (route Finances), M3-SEG, K-51, leçon 11.
3. **Entrée Revenus de l'enseignant.** L'enseignant n'a pas d'onglet « Compte » : sa 4e destination est « Profil » (`nav_shell.dart:171-175`, corrections). Revenus est donc **une ligne du Profil** (« Revenus estimés »), dans un groupe à elle placé après « Contrat », qui ouvre `/enseignant/revenus` (guide §4) comme une page posée, avec retour vers le Profil. Jamais une 5e destination (E10 ; M3-NAV 3 à 5 destinations, la barre en a déjà 4). `ECARTS_MAQUETTES_08_10` B1 dit « depuis son Compte » : même correction que C-2 (Q-FI-10). À revérifier sur `ui/enseignant-v1` en FI-10 : le Profil y a peut-être changé (non lu ici).

Autres points demandés par `02_DECOUPAGE` FI-1a :
- **Politiques sous le domaine Finance** : `/admin/finance/politiques`, onglet de Finance (`ongletsFinance()` : « Vue globale », « Politiques commerciales »). Le guide §4 propose `/admin/parametres/politiques-commerciales`, mais dit « si le dépôt utilise une autre structure, conserver l'existant et mapper ». Dans le dépôt, Configuration porte les règles du système, « distinctes de Finance par nature » (`admin_domaine.dart:35-37`) ; une politique commerciale est financière par nature. La maquette 10 la place aussi sous Finance (fil « Finance > Politiques commerciales »).
- **« Gérer les accès »** (maquette 05) : refusé (ligne 2 f).

## Données financières par rôle (leçon 15)

Ce que le port rend à chaque rôle. « Jamais chargé » veut dire : le champ n'existe pas dans la réponse du port pour ce rôle, **même pendant le chargement ou en erreur** ; l'écran ne le masque pas, il ne l'a jamais (leçon 15 : « la permission vient de l'absence de donnée, jamais d'un bouton masqué »). Les rubriques suivent le même principe (`mon_espace_adulte_page.dart:278-280`).

| Rôle | Solde | Mensualité, prochain débit | Montant manquant, cause | Mouvements | Recharge | Source |
|---|---|---|---|---|---|---|
| Tuteur titulaire | Oui, par enfant de son foyer | Oui, par enfant | Oui (bandeau « Accès à régulariser ») | Oui, par profil et historique du foyer | Oui, un ou plusieurs profils | guide §4 Tuteur, §5.1 à §5.3 |
| Titulaire adulte (Ma famille) | Oui, par bénéficiaire de son foyer, dont lui | Oui | Oui | Oui | Oui | guide §4 ; E-11 ; FI-BR-17 |
| Second adulte rattaché | **Jamais chargé** | **Jamais chargé** | **Jamais chargé** | Historique des paiements du foyer seulement, en lecture (date, justificatif) | **Aucune** (aucun bouton, aucune route) | `paiements_page.dart:36-37` (E3, EA-BR-16) ; K-53.8 ; FI-BR-18 |
| Élève adulte autonome | Oui, son seul profil | Oui, son seul profil | Oui, son seul profil | Oui, les siens | Oui, son seul profil (ligne 10) | guide §4 Élève adulte ; FI-BR-17 |
| Élève enfant | **Jamais chargé** | **Jamais chargé** | **Jamais chargé** : seul l'état d'accès (essai, accès actif, accès temporairement indisponible) | **Jamais chargé** | **Aucune** | guide §4 Élève enfant, §1.7 |

Conséquence pour le second adulte : il ne voit jamais les cartes d'enfants du Foyer (« Solde actuel », « Prochain débit », « Recharger ») ; sa seule surface reste « Paiements du foyer » (ligne 14 e). Pour l'enfant : la ligne 9 ne règle pas que le texte, le port de l'enfant ne porte ni montant ni cause.

## Écarts entre le guide et les écrans Élèves adultes déjà validés

Le guide prime pour la finance (§0). Ces écarts ne rouvrent pas EA : ils s'appliquent dans la vague Finance. Ce qui n'est pas financier va en « Harmonisation : <écran> » (K-51, HU-1).

| N° | Écran EA validé, preuve | Guide | Ce qui s'applique |
|---|---|---|---|
| E-1 | Une offre par bénéficiaire, jamais un montant (`port_recharge_foyer.dart:66-67` ; `fr.i18n.json:3888`, `:3891`, `:3894` ; règle F11) | §5.3 montant par profil | Montant par profil, stepper. |
| E-2 | Solde « déjà rédigé », sans unité ajoutée (`port_recharge_foyer.dart:59-60` ; `soldes_foyer.dart:162-163` ; règle E2) | §7, §11.3 | Unités mineures + code ISO, formatées par la langue (K-41.5). |
| E-3 | Total jamais additionné dans Flutter (`port_recharge_foyer.dart:147` ; règle F12) | §5.3 « le total se recalcule » | Seule addition permise : les montants choisis ; le serveur arrête le total. |
| E-4 | Deux étapes : bénéficiaires puis « Vérifier la recharge » avec « Modifier » (`recharge_foyer.dart:5-13` ; `fr.i18n.json:3892`, `:3900-3906` ; UX_REVIEW_07 n° 15 c, n° 16 c) | maquettes 04 et 07 : une page, « Payer » direct | Une page ; relecture sur place (ligne 6 d, e). |
| E-5 | Pastilles d'exception seulement, « Bientôt épuisé », « Inactif » (`soldes_foyer.dart:124-133` ; `fr.i18n.json:3920-3921`) ; « Actif » refusé (UX_REVIEW_07 n° 14 f ; règle E12) | §5.1 états : financé, essai, manque, confirmation, expiré, pause | Pastille de période toujours visible. « Bientôt épuisé » disparaît partout, Foyer et Compte > Paiements compris (ligne 14 c) : l'accès ne dépend pas du solde (FIN4-08). |
| E-6 | « Récapitulatif du foyer : {valeur} » (`fr.i18n.json:3919` ; UX_REVIEW_07 n° 14 c) | maquettes 05, 07 « Total des soldes (lecture) » | « Total des soldes (lecture) » + phrase « Ce n'est pas un porte-monnaie partagé ». |
| E-7 | Titre « Bénéficiaires » (`fr.i18n.json:3917`) | maquettes 04, 07 « Profils à recharger » ; 05 « Enfants du foyer » | Termes des maquettes. |
| E-8 | Bouton « Recharger » unique (`fr.i18n.json:3918`) | §5.1 « Recharger plusieurs profils » ; §4 « Recharger Mariam » | Libellés du guide. |
| E-9 | Montants de démonstration en euros (`fr.i18n.json:4158-4169`) | §1.1 USD | USD, toujours marqués « (démonstration) ». |
| E-10 | Démonstration du paiement arrêtée sur « Paiement pas encore disponible » (`fr.i18n.json:3912-3913` ; UX_REVIEW_07 n° 16 e) | §1.6 « simuler ces états avec fixtures et ports » | La démonstration parcourt les huit états ; la production reste sur l'état honnête. |
| E-11 | Ma famille bureau : soldes en colonne droite (`foyer_page.dart:255-266` ; UX_REVIEW_07 n° 7) | maquette 05 | Composition de la maquette 05 pour le tuteur et le titulaire adulte (même page). |
| E-12 | Compteurs et tuiles refusés (UX_REVIEW_07 n° 6 c, n° 7 c ; K-42 point 4) | §5.1 nombre d'enfants, profils financés, paiements du mois | Compteurs gardés (Q-FI-7). |
| E-13 | Âge non affiché, non enregistré (`fiche_eleve_page.dart:235-236` ; `fr.i18n.json:893`) | maquettes « 10 ans » ; §5.1 « âge si présent dans le design » | Âge seulement s'il est rendu ; ordre prénom, âge, classe constant (§11.5). |
| E-14 | « Tout sélectionner » (`fr.i18n.json:3889-3890` ; UX_REVIEW_07 n° 15 b) | absent des maquettes 04 et 07 | Retiré (fidélité §2). |
| E-15 | « Revenir aux paiements du foyer » (`fr.i18n.json:3914`) | maquette 01 « Retour aux soldes » | « Retour aux soldes ». |
| E-16 | Liste « Profils élèves » en lignes (`foyer_page.dart:454` ; `fr.i18n.json:791`) | maquettes 03, 05 : cartes « Enfants du foyer » | Cartes ; une seule liste. |
| E-17 | Bouton dominant « Ajouter un profil élève » (`foyer_page.dart:184-198`) | §5.1 CTA « Recharger plusieurs profils » | « Ajouter… » secondaire (Q-FI-2). Ligne « Harmonisation : Foyer ». |
| E-18 | Sous-titre « Les profils élèves de votre foyer » (`fr.i18n.json:790`) | maquettes « Soldes et paiements » | Sous-titre des maquettes. |
| E-19 | « Paiements du foyer » du titulaire : `SoldesFoyerSection` et son « Recharger » avant l'historique (`paiements_page.dart:32-37`, `:110-116` ; `soldes_foyer.dart:177-189` ; EA-9), en plus de la section du Foyer bureau (`foyer_page.dart:260-266`) | §4 « Compte > Paiements » = raccourci, jamais un deuxième centre de paiement ; §13 | `SoldesFoyerSection` retirée des deux poses ; Compte > Paiements = raccourci vers le Foyer ; historique gardé (ligne 14). |
| — | Conformes, sans changement : remise seulement si rendue (UX_REVIEW_07 n° 16 a ; FI5) ; second adulte qui voit les paiements sans recharger (K-53.8, FI-BR-18), avec les champs précisés dans « Données financières par rôle » ; place réservée au solde dans la fiche (`fiche_eleve_page.dart:238-240`). | | |

## Écrans 08 à 10 : ce que le guide impose en plus des maquettes

Les maquettes 08 à 10 sont reçues (`ECARTS_MAQUETTES_08_10.md` §E) : FI-10, FI-11a et FI-11b n'attendent plus. Les décisions par élément sont aux lignes 11 à 13. Ce qui suit est le contenu que le guide impose, quelle que soit la maquette.

**Enseignant, Revenus (FI-10).** §5.5 et §1.4 : la mention que c'est une estimation, pas une paie définitive ; par classe : heures assurées, capacité, sièges éligibles (moyenne ou détail par séance), taux horaire effectif, montant estimé ; l'explication en trois points (base garantie, composante occupation, plafond horaire) ; l'allocation Internet séparée, une seule fois ; le relevé (§4). Interdits : solde de famille, montant payé par un élève, bonus « classe pleine » (§1.4, §5.5).

**Finance, Vue globale (FI-11a).** §5.6 : chiffre encaissé, revenu académique, paie enseignants, marge projetée, impayés, essais en cours, soldes créditeurs ; toujours séparés (encaissement, revenu, solde client, charge, marge). Chaque graphique porte son nombre exact (§8 F7). La marge de référence n'est ni une sanction ni un blocage (§1.5).

**Politiques commerciales (FI-11b).** §5.7 : statut brouillon ou publiée, date d'effet, comparaison avec la version active, aperçu avant publication ; sept familles de paramètres (Tarifs, Essai, Remises, Enseignants, Classes, Paiement, Pilotage). Les invariants ne sont jamais des champs. « Publier » arrive sur un état honnête (aucune écriture, §8 F8, FI-BR-02).

## Corrections à `00_REPRISE.md` (constatées en lisant le code)

- **C-1.** `AttentionBanner` ne peut pas reposer sur `PermanentNotice` (`00_REPRISE.md:60`) : ce composant est la mention de la salle, sans aucun paramètre, protégé par `tool/verifier_jetons.dart` (`permanent_notice.dart:8-35`). Aucun bandeau partagé n'existe (`lib/core/widgets` : `BandeauObservation`, `OfflineBanner`, `LocalFeedback` ne conviennent pas). Proposition pour FI-3b : assembler `AppCard` + `StatusPill` + `ProfileIdentityAvatar` + `ActionPrincipale` (contrat C : assembler, ne pas redessiner).
- **C-2.** L'enseignant n'a pas de « Compte » mais un « Profil » (`nav_shell.dart:150-152`, corrections) : la ligne FI-10 de `02_DECOUPAGE.md` (« depuis le Compte ») et `ECARTS_MAQUETTES_08_10` B1 (« ouvert depuis son Compte ») se lisent « depuis le Profil ».
- **C-3.** La décision K-53 n'est pas dans `DECISIONS_DELEGUEES_2026-10-02.md` : ce fichier ne traite que du Contrôleur, du Mode Accessibilité, de l'Enseignant et des corrections de la revue (`:7-43`), sans point Finance. Les points de K-53 utilisés ici sont relevés là où ils sont cités : K-53 (questions) et K-53.6 (jamais « admin ») dans `outils/yaaden/YAADEN_RULES.md:52`, `:55` ; K-53.8 (paiements visibles des deux adultes) dans `05_recette/EA/REVUE_EA-R.md:9`.
- **C-4.** `StatusPill` limite son libellé à deux mots (`status_pill.dart:64`) : « Essai : 1/2 séance utilisée » (maquettes 03, 05) devient « Essai : 1/2 » ; la phrase longue passe sur la ligne de la carte.
- **C-5.** Pastille d'essai : la maquette la montre violette, proche de l'accent d'Aïcha. Le choix du ton (parmi les tons existants de `TonEtat`) est laissé à FI-3b, avec une contrainte : aucun ton qui ressemble à un accent de profil (§11.4). Si aucun ton existant ne convient : ligne TH-2.
- **C-6.** `00_REPRISE.md` l. 57 (accent de profil = `teinteGroupe`) : à ne pas suivre tel quel, voir « Thème » en tête (RISQUE, TH-2). `00_REPRISE.md` l. 51 (Compte > Paiements devient un raccourci) : précisé par la ligne 14.

## Contrats A à E appliqués

| Contrat | Application |
|---|---|
| **A, espacement** | Objet vers son bouton : 16 (carte des soldes → « Recharger plusieurs profils » ; note → « Recharger Mariam » ; total → « Payer » ; dernier bloc → « Retour aux soldes »). Sections : 24 sur téléphone, 32 sur bureau. Cartes d'enfants : 16 entre elles. |
| **B, boutons** | Un plein par écran : Foyer « Recharger plusieurs profils » ; fiche « Recharger {prénom} » ; recharge « Payer {total} » ; résultat « Retour aux soldes » ; politiques « Publier la version ». Boutons de cartes secondaires. Libellés qui disent l'action. Pas de pied collant. |
| **C, composants** | `PageShell`, `GroupeReglages`, `LigneCleValeur`, `StatusPill`, `ChoiceCardGroup`, `ControleSegmente`, `DataCollection`, `EcranResultat`, `EtatSysteme`, `BlocAsynchrone`, `Skeleton`, `ActionPrincipale`, `PhotoEleve` (dans `ProfileIdentityAvatar`). Nouveaux composants seulement ceux du guide §7 qui n'ont pas d'équivalent (FI-2, FI-3a, FI-3b). |
| **D, bureau** | Compact sous 600, rail à 600, barre latérale à 1200 ; à 1440, colonnes des maquettes 05 à 10 ; jamais une colonne de téléphone centrée (§6). |
| **E, mouvement** | Jetons gelés ; aucune animation de réussite, aucun confetti ; réduction de mouvement = 0. |

## Lexique du rôle (K-53.4)

Source : « guide §x » ; « maquette 0n » (texte d'une maquette validée, guide §2) ; « existant » (déjà dans `fr.i18n.json`, ligne citée) ; « proposé par un agent » (à valider). Les valeurs entre accolades viennent des données. Aucun montant ni date fixe.

### Foyer (lignes 1, 2)

| Texte | Où | Source |
|---|---|---|
| « Foyer » | titre | existant `fr.i18n.json:788` ; maquettes 03, 05 |
| « Soldes et paiements » | sous-titre | maquettes 03, 05 ; guide §5.1 (titre de l'écran) |
| « {n} enfants » / « Dans le foyer » | compteur | maquette 03 ; guide §5.1 « nombre d'enfants » |
| « {n} profils financés » / « Sur {n} enfants » | compteur | maquettes 03, 05 ; guide §5.1 |
| « {n} paiement(s) » / « Ce mois-ci » | compteur | maquette 03 ; guide §5.1 « paiements du mois » |
| « Total des soldes (lecture) » | carte ; panneau « Vue financière du foyer » | maquettes 05, 07 ; guide §5.1 « total des soldes en lecture ». « Total des soldes (foyer) » (maquette 03) et « Solde total actuel » (panneau de la maquette 05) ne sont pas gardés : un seul libellé. |
| « Somme des soldes individuels de vos enfants. Ce n'est pas un porte-monnaie partagé. » | sous le total | maquette 05 ; guide FIN4-07 |
| « À payer ce mois » | carte ; panneau « Vue financière du foyer » | maquettes 03, 05 ; guide §5.1 |
| « Montant des mensualités à venir pour les profils financés. » | sous « À payer » | maquette 05 (le « 1 paiement programmé ce mois-ci » de la maquette 03 répète le compteur : non gardé) |
| « Sur {n} enfants », « Pour {n} profils financés » | sous les deux valeurs du panneau, bureau | maquette 05 |
| « Recharger plusieurs profils » | bouton | guide §5.1 |
| « Chaque enfant a un solde et une période financée individuels. Les accès sont liés à la période financée, pas simplement au solde. » | note, bureau | maquette 05 ; guide FIN4-06, FIN4-08 |
| « Tous les accès sont actifs » | bloc profils financés | maquette 05 |
| « {n} accès à régulariser » | même place, quand ce n'est pas le cas | proposé par un agent |
| « Enfants du foyer » | titre de section | maquette 05 (« Enfants » de la maquette 03 non gardé : un seul libellé) |
| « {âge} ans » | carte, si rendu | maquettes 03, 05 ; existant `fr.i18n.json:843` (« ans ») |
| « {Mois} financé » | pastille | maquettes 02, 03, 05 ; guide §5.1 « financé » |
| « Essai : {n}/{max} » | pastille | guide §8 F5 (« trial 0/2 ») ; `00_REPRISE.md` FI4 ; maquette raccourcie (C-4) |
| « Il manque {montant} » | pastille | maquettes 03, 05 ; guide §1.7 |
| « En confirmation » | pastille | guide §5.1 « paiement en confirmation » ; libellé proposé par un agent |
| « Accès expiré » | pastille | guide §5.1 « accès expiré » ; existant `fr.i18n.json:801` (« Accès expiré depuis le {date} »), raccourci à deux mots (C-4) : proposé par un agent |
| « En pause » | pastille | guide §5.1 « pause » ; libellé proposé par un agent |
| « À régulariser » | pastille | guide §1.7 |
| « Accès jusqu'au {date} » | carte | existant `fr.i18n.json:800` ; maquettes |
| « Solde actuel » | carte | maquettes 02, 03, 05 |
| « Prochain débit » | carte | maquettes ; guide §5.1 |
| « Voir le détail » | bouton de carte | maquettes 03, 05 |
| « Recharger » (nom lu « Recharger {prénom} ») | bouton de carte | maquettes 03, 05 ; guide §4 |
| « Vue financière du foyer » | panneau, bureau | maquette 05 |
| « Dernières transactions » / « Voir tout » | panneau, bureau | maquette 05 |
| « Recharge », « Mensualité {mois} », « Avoir » | lignes de transaction | guide §4 et FI-BR-05 (recharge, mensualité, avoir) ; « Mensualité {mois} » maquettes 05, 06 ; « Avoir académique » de la maquette non gardé tant que les données ne le rendent pas |
| « Ajouter un profil élève » | bouton secondaire | existant `fr.i18n.json:789` |

### Fiche élève, Finances (lignes 3, 4)

| Texte | Où | Source |
|---|---|---|
| « Général », « Finances » | segments | maquette 02 |
| « Foyer › {prénom} », « {prénom} · Finances » | fil d'Ariane, titre bureau | maquette 06 |
| « Accès actif » | pastille d'en-tête | maquette 02 |
| « Vue financière » | titre de carte | maquette 06 (« Vue d'ensemble financière » de la maquette 02 non gardé : un seul libellé) |
| « Période financée » | carte | maquette 06 ; guide §5.2 |
| « Mensualité » / « {montant} / mois » | carte | maquettes 02, 06 ; guide §5.2 |
| « Détail de la mensualité » | groupe | maquettes 02, 06 |
| « Tarif enfant », « Tarif adulte » | ligne | guide §5.2 (« Tarif standard » de la maquette non gardé) |
| « Remise familiale {rang}e membre » | ligne, si rendue | guide §5.2 (« Remise famille » de la maquette non gardé) |
| « Réduction calendrier », « Avoir », « Taxe applicable » | lignes, si rendues | guide §5.2 |
| « Total à financer » | ligne de total | guide §5.2 (« Total dû » de la maquette non gardé) |
| « Les absences ordinaires n'entraînent pas de réduction sur le mois une fois celui-ci financé. Vous pouvez consulter l'historique de présence dans l'onglet Historique. » | note | maquette 02 ; guide FIN4-04 |
| « Recharger {prénom} » | bouton | maquettes 02, 06 ; guide §4 |
| « Voir les mouvements » | bouton secondaire | maquette 02 |
| « Télécharger le reçu » | bouton secondaire, bureau | maquette 06 |
| « Historique des transactions » | panneau, bureau | maquette 06 |
| « Pas de consommation par séance », « Accès lié à la période financée », « Vous pouvez consulter l'historique de présence dans l'onglet Historique » | bandeau, bureau | maquette 06 |
| « Mouvements de {prénom} » | titre de la page des mouvements | proposé par un agent |

### Recharge (lignes 6, 7)

| Texte | Où | Source |
|---|---|---|
| « Recharge » | titre | maquette 04 (Q-FI-5) |
| « Choisissez les profils et les montants à recharger » | sous-titre | maquette 07 |
| « Profils à recharger » | groupe | maquettes 04, 07 |
| « Montant pour {prénom} », « Diminuer le montant pour {prénom} », « Augmenter le montant pour {prénom} » | noms lus du stepper | proposé par un agent (HIG-ST) |
| « Minimum suggéré : {montant} » | aide sous la ligne | guide §5.3 ; texte proposé par un agent |
| « Sélectionnez au moins un profil pour continuer. » | raison du bouton inactif | existant `fr.i18n.json:3893`, « bénéficiaire » remplacé par « profil » : proposé par un agent |
| « Total à payer » | bloc | maquettes 04, 07 ; existant `fr.i18n.json:3907` |
| « Un seul paiement sera effectué » | titre de l'explication, bureau | maquette 07 |
| « Le montant sera réparti entre les profils selon les montants choisis. Chaque enfant conserve un solde et une période financée individuels. » | explication | maquettes 04, 07, avec « automatiquement » remplacé par « selon les montants choisis » (c'est le tuteur qui répartit, leçon 10) : proposé par un agent |
| « Moyen de paiement » | groupe | guide §1.6, §5.3 (« Méthode de paiement » des maquettes non gardé) |
| « Carte enregistrée », « •••• {4 chiffres} », « Payer avec une autre carte » | choix | maquette 04 |
| « Payer avec un portefeuille numérique » | choix | maquette 04, « digital » remplacé par « numérique » : proposé par un agent ; FI-BR-07 |
| « Payer {total} » | bouton | maquettes 04, 07 ; existant `fr.i18n.json:3908` |
| « Vérifiez la répartition avant de payer. » | état `preparing` | guide §5.4 |
| « Récapitulatif du paiement » | colonne, bureau | maquette 07 |
| « Accès à régulariser » | bandeau | guide §1.7 ; maquette 07 |
| « Il manque {montant} pour financer {mois}. » | bandeau | guide §1.7 ; maquette 07 |
| « Son accès se terminera le {date}. » | bandeau | maquette 07 |
| « Recharger maintenant » | bandeau, hors de la page de recharge | maquette 07 |
| « Ajouter {prénom} à la recharge » | bandeau, sur la page de recharge | proposé par un agent |

### États du paiement et résultat (ligne 8)

| Texte | Où | Source |
|---|---|---|
| « Paiement en cours de confirmation » / « Ne payez pas une seconde fois. » | `awaiting_confirmation` | guide §5.4 |
| « Paiement confirmé » / « Mise à jour des soldes… » | `confirmed`, `allocation_in_progress` | guide §5.4 |
| « Paiement confirmé » | titre de `completed` | guide §5.4 ; maquette 01 sans « ! » |
| « Votre paiement de {montant} a bien été effectué et réparti entre les profils sélectionnés. » | phrase | maquette 01 |
| « Détails du paiement », « Référence », « Date », « Montant total » | carte | maquette 01 |
| « Moyen de paiement » | ligne | guide §5.4 (« Méthode de paiement » de la maquette non gardé) |
| « Répartition par profil », « Nouveau solde : {montant} » | carte | maquette 01 ; guide §5.4 |
| « Crédité » | nom lu de la coche | proposé par un agent |
| « Soldes mis à jour » / « Les nouveaux soldes sont désormais disponibles pour tous les profils concernés. » | annonce | maquette 01 |
| « Retour aux soldes » | bouton | maquette 01 |
| « Le paiement n'a pas été confirmé. » | titre de `failed` | existant `fr.i18n.json:3910` |
| « Réessayer », « Changer de moyen de paiement », « Retour » | actions de `failed` | guide §5.4 (« Changer de moyen » complété : proposé par un agent) |
| « Paiement annulé » / « Votre sélection est conservée. » | `cancelled` | proposé par un agent |
| « Cette demande de paiement a expiré » / « Vérifiez les soldes avant de recommencer. » | `stale` | proposé par un agent |
| « (démonstration) » | après tout montant de démonstration | `02_DECOUPAGE` FI-1c (REVUE_EA-R m4) |

### Accès, essai, impayé (ligne 9)

| Texte | Où | Source |
|---|---|---|
| « Accès à cette classe temporairement indisponible » / « Votre tuteur peut gérer l'accès. » | enfant | guide §1.7 |
| « Accès à régulariser » / « Il manque {montant} pour financer {mois}. » | tuteur, adulte | guide §1.7 |
| « Place conservée jusqu'au {date} » | tuteur, adulte | guide §1.7 (conservation de place) ; texte proposé par un agent |

### Enseignant, Vue globale, Politiques (lignes 11 à 13)

Vocabulaire du projet (guide §0, 2e paragraphe) : « classe », jamais « groupe » (CLASSE-FORM-1, rappelée par `ECARTS_MAQUETTES_08_10` A6) ; « séance », jamais « cours ».

| Texte | Où | Source |
|---|---|---|
| « Revenus estimés » | ligne du Profil et titre de l'écran | guide §5.5 (« estimation ») ; B5 ; libellé proposé par un agent (la maquette 08 dit « Mes revenus ») |
| « Estimation, pas une paie définitive » | mention | guide §5.5 |
| « Revenu estimé du mois », « Heures assurées », « Classes actives », « Taux horaire effectif moyen » | rangée de synthèse | maquette 08, avec « Groupes actifs » → « Classes actives » (A6, B7) et « moyen » → « effectif moyen » (guide §5.5) : proposé par un agent |
| « Détail par classe » | titre du tableau | maquette 08 « Détail par groupe », A6 |
| « Classe », « Type », « Capacité », « Sièges éligibles », « Heures assurées », « Taux horaire effectif », « Montant estimé », « Total » | colonnes | guide §5.5 ; maquette 08 (« Places éligibles occupées » → « Sièges éligibles », guide §5.5) |
| « Nouvelle règle de rémunération » | carte | maquette 08 (B8) |
| « Base garantie », « Composante occupation », « Plafond horaire » | explication | guide §5.5 |
| « Historique des paiements » / « Voir tout » | panneau | maquette 08 (B5 : statut jamais présenté comme définitif) |
| « Allocation Internet » | carte à part | guide §4 Enseignant (« allocation Internet ») ; maquette 08 (B6) |
| « Relevé » | lien | guide §4 |
| « Vue globale », « Politiques commerciales » | onglets de Finance | guide §2 ; maquettes 09, 10 |
| « Chiffre encaissé », « Revenu académique », « Paie enseignants », « Marge projetée », « Impayés », « Essais en cours », « Soldes créditeurs » | indicateurs | guide §5.6 (C1, C2) |
| « État des paiements » : « Financés », « À régulariser », « En essai », « En confirmation » | panneau | maquette 09 (C7) |
| « Top classes (par encaissements) », « Alertes et actions », « Dernières opérations » | panneaux | maquette 09 (C4, C7, C8) |
| « Version brouillon », « Version active », « Date d'effet » | bandeau de version | maquette 10 (D11) ; guide §5.7 |
| « Comparer avec la version active », « Aperçu avant publication » | politique | guide §5.7 ; maquette 10 (« comparaison » mis en verbe : proposé par un agent) |
| « Publier la version » | bouton plein | `ECARTS_MAQUETTES_08_10` D9 |
| « Tarifs », « Essai », « Remises », « Enseignants », « Classes », « Paiement », « Pilotage » | familles | guide §5.7, avec « Groupes » → « Classes » (CLASSE-FORM-1, A6) |
| « Capacité des classes », « par classe » | champs, aide | CLASSE-FORM-1 (A6) |
| « {montant} / mois » | tarifs, remises, aperçu foyer | D1, D2 ; guide §1.3 |
| « {rang}e membre payant » | remises | D3 ; guide §1.3 |
| « 2 séances d'essai maximum » | essai | D8 ; guide §5.7 |
| « Non contraignant » | budgets de pilotage | D5 ; guide §5.7 |
| « Publication indisponible avant le branchement » | état de « Publier » | `02_DECOUPAGE` FI-11b ; texte proposé par un agent |

## Synthèse

- 14 lignes : 1 gardée, 13 adaptées (dont les écrans 08 à 10 et Compte > Paiements). Aucun écran refusé, aucun écran en attente.
- Éléments de maquette refusés : « + Recharger » en tête (03), chevron des cartes (03, 05), « Gérer tous les enfants » (03, 05), panneau « Actions rapides » (05), « Recharger plusieurs profils » sur la page de recharge (07), pastille de période répétée sous l'identité (06), phrase de recharge sur la fiche (06), chevrons des moyens de paiement (04, 07), « Paiement sécurisé et chiffré » (04), croix du bandeau (07), éclat de réussite et « ! » (01), « Apprentissage » (02), coque de la direction et entrées inventées (08 à 10), flèches « vs mois précédent » sans donnée (08, 09), « À propos des anciennes primes » (08), catégories de revenus et d'opérations inventées (09), histogramme mêlé (09), « Enregistrer les modifications » plein, menu « … » et sélecteur de mois (10), toutes les valeurs (30 $, −5 $, 2024, « par cours »).
- Retiré du code existant : `SoldesFoyerSection` (deux poses) ; Compte > Paiements devient un raccourci.
- 19 écarts avec les écrans Élèves adultes, tous tranchés par le guide §0.
- Un tableau rôle × donnée : second adulte et enfant sans solde, mensualité, manque ni recharge, jamais chargés (leçon 15).
- Six corrections à `00_REPRISE.md` (C-1 à C-6), dont deux qui changent la suite : pas de `PermanentNotice` pour le bandeau (FI-3b) ; pas de `teinteGroupe` comme accent de profil (RISQUE, TH-2).
- Aucune permission, aucun état serveur, aucune valeur commerciale, aucune couleur. Aucun texte n'est inventé en silence : les textes « proposé par un agent » sont listés ci-dessus.

## Questions au directeur

Aucune ne bloque : la recommandation est appliquée et peut être reprise à tout moment.

1. `NON_BLOQUANT | Q-FI-1. Que doit contenir l'onglet « Apprentissage » de la fiche élève (maquette 02) ? | Non affiché ; deux onglets, Général et Finances.`
2. `NON_BLOQUANT | Q-FI-2. Sur le Foyer, « Recharger plusieurs profils » devient le seul bouton plein, et « Ajouter un profil élève » passe en secondaire : d'accord ? | Oui, comme le guide §5.1.`
3. `NON_BLOQUANT | Q-FI-3. Sur ordinateur, on retire le panneau « Actions rapides » (« Recharger » y est en double, « Gérer les accès » laisse croire que le tuteur fixe lui-même les périodes) : d'accord ? | Retiré ; la place va aux dernières transactions.`
4. `NON_BLOQUANT | Q-FI-4. « Paiement sécurisé et chiffré » n'apparaît qu'une fois le vrai paiement branché : d'accord ? | Retiré pour cette vague.`
5. `NON_BLOQUANT | Q-FI-5. La page de recharge s'appelle « Recharge » partout (la maquette ordinateur dit « Paiement du foyer ») : d'accord ? | « Recharge ».`
6. `NON_BLOQUANT | Q-FI-6. Le bandeau « Accès à régulariser » reste affiché tant que l'accès n'est pas réglé, sans croix : d'accord ? | Sans croix.`
7. `NON_BLOQUANT | Q-FI-7. On garde les compteurs du Foyer (enfants, profils financés, paiements du mois), que la vague Élèves adultes avait retirés : d'accord ? | Gardés, comme le guide §5.1.`
8. `NON_BLOQUANT | Q-FI-8. Sur ordinateur, le panneau « Vue financière du foyer » répète le total des soldes et le montant à payer déjà en tête de page. Faut-il le garder tel quel, ou lui faire montrer autre chose pour le mois choisi (par exemple les paiements du mois) ? | Gardé tel que la maquette 05, avec le même libellé qu'en tête ; rien n'est remplacé sans votre réponse.`
9. `NON_BLOQUANT | Q-FI-9. Plusieurs petits éléments des maquettes sont retirés parce qu'ils doublent une action ou ne mènent nulle part : le « + Recharger » en haut du Foyer sur téléphone, les flèches des cartes d'enfants, le lien « Gérer tous les enfants », les flèches des moyens de paiement, le sélecteur de mois de la page des politiques. D'accord ? | Retirés ; chaque action reste à un seul endroit.`
10. `NON_BLOQUANT | Q-FI-10. Les revenus de l'enseignant s'ouvrent depuis son Profil (il n'a pas d'onglet Compte), par une ligne « Revenus estimés » : d'accord ? | Depuis le Profil.`
11. Q2 (« business plan ») de `QUESTIONS.md` reste ouverte. Q1 (trois maquettes absentes) est réglée par la réception des maquettes 08 à 10.

## Reste

- `QUESTIONS.md` Q1 est encore marquée ouverte : à clore dans ce fichier (non modifié ici, consigne « aucun autre fichier »).
- La route exacte de `/eleve/finances` dans la coque adulte (ligne 10 a) est fixée en FI-9b, après lecture des routes de l'élève adulte.
- Le Profil de l'enseignant sur `ui/enseignant-v1` n'a pas été lu (point 3).
