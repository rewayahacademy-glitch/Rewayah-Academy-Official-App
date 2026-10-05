# CPT-R : revue croisée Comptable V1

Revue faite le 05/10/2026 par une session qui n'a écrit aucune ligne de la vague. Code revu : `origin/ui/comptable-v1` @ `8fb00a71`, base de comparaison `728c34c5` (fusion avec `ui/finance-v1`). Sources lues : spec `V/REWAYAH_FINANCE_OPERATIONNELLE_COMPTABLE_V1.md` (§1, §7, §10, §20, §21, §40, §41, §47, §49, §50 à §57, §59, §61), `00_REPRISE.md`, `QUESTIONS.md`, `DEVOIR_DE_REGARD_FINANCE.md` (DR-01 à DR-25), `CPT-BR.md`, `docs/current/CPT-CAPT_RECETTE.md`.

**Verdict : refusé.** Trois défauts majeurs, tous corrigeables en une étape courte (CPT-RC). La sécurité §47 tient : argent en entiers, aucun rôle lu dans un widget, masque remis à zéro à chaque session, idempotence du payout, auto-paiement bloqué, démonstration absente en production. Ce qui fait refuser, c'est la démonstration et la recette visuelle. La route `/demo/comptable` que voit l'opérateur affiche **8 écrans sur 16 vides**. Les captures CPT-CAPT ne le montrent pas, parce qu'elles posent les surcharges à la racine. En plus, la suite `test/widgets` est rouge, et l'en-tête des pages de détail est inutilisable à 320 px avec un texte agrandi deux fois (texte x2).

## 0. Chiffres rejoués

Tout a tourné sous `flock /tmp/flutter.lock`, `PATH=/opt/flutter/bin`, dans un worktree détaché à `8fb00a71`.

| Commande | Résultat |
|:--|:--|
| `flutter pub get`, `dart run slang` | OK, aucun fichier régénéré (`git status` vide) |
| `dart analyze --fatal-infos` (dépôt entier) | **No issues found**, sortie 0 |
| `dart run tool/verifier_jetons.dart` | **39 violations**, toutes hors des fichiers de la vague (mouvement, admin_shell, démos plus anciennes) ; 39 → 39 |
| `flutter test test/features/comptable` | **+273, ~48 sautés, 0 échec** |
| `flutter test test/features/admin_finance` | **+133, ~10, 0 échec** |
| `flutter test test/features/finance` | **+47, 0 échec** |
| `flutter test test/router` | **+279, 0 échec** |
| `flutter test test/widgets` | **+233, −1 : ROUGE** (`catalogue_galerie_test.dart` : « chaque fichier de lib/core/widgets a son entrée ») |
| `flutter test test/core/comptable test/core/widgets/montant_sensible_test.dart test/features/paiements_recus test/capture/cpt_capt_recette_test.dart test/capture/cpt_pay_capture_test.dart` | **+21, ~139 sautés** (captures sans `CAPTURE_DIR`), 0 échec |

**Contre-épreuves** : j'ai muté le code, rejoué le test, puis restauré avec `git checkout --`.
- J'ai retiré `ref.watch(sessionProvider.select(_identiteDe))` de `lib/core/comptable/visibilite_montants.dart:33`. `visibilite_montants_test` échoue alors sur « R-FIN-03 : une nouvelle session (autre compte) remasque ». Le test prouve donc bien R-FIN-03.
- J'ai remplacé l'exclusion `autoPaiement` de `estSelectionnable` (`lib/features/comptable/paiements/paiements_donnees.dart:141-143`) par `true`. `paiements_page_test` échoue alors sur « W02 au bureau (1440) le Comptable bénéficiaire : ni case ni Payer, la raison rendue (R-FIN-15) ». Le test prouve donc bien R-FIN-15.

**Vérification de la route de démonstration réelle** : test jetable, supprimé depuis. Il monte `routesDemoComptable('staging')` dans un `ProviderScope` nu, c'est-à-dire exactement ce que fait l'app en préproduction, puis relève les textes rendus sur les 16 écrans. Résultat : voir majeur M1.

## 1. Ordre de regard §59 (16 questions)

1. **Est-ce la bonne fonction ?** Oui. W01 à W07, M01 et M02, le delta Direction §37 et « Recevoir mes paiements » §20 existent tous, chacun avec une route (`routes_comptable_test.dart:150-200`, 16 routes ouvertes dans la vraie coquille). Rien ne sort du périmètre §60 : ni grand livre, ni FX réel, ni fournisseur maison.
2. **Est-elle au bon endroit ?** Oui. Le shell a quatre destinations et des onglets de second niveau (DR-01) : `nav_shell.dart:219`, `ongletsPaiementsComptable` et `ongletsTresorerieComptable` (`routes_comptable_test.dart:118-135`). Contractuels et Bénéficiaires sont sous Paiements ; Encaissements et Rapprochement sous Trésorerie. Le delta Direction est dans la coquille admin, troisième onglet de Finance (`routes_comptable_test.dart:353-371`).
3. **Existe-t-elle déjà ailleurs ?** Pas de doublon fonctionnel. La Réserve est **lue** par le Comptable (`CarteReserveStrategique`) et **réglée** par la Direction (`strategic_reserve_policy_panel.dart`), un seul composant d'affichage pour les deux. La relance passe par un port vers Messages métier, aucune messagerie Finance (R-FIN-21). Seul reste : « Trésorerie libre » apparaît sur Aujourd'hui et sur Trésorerie, avec le même composant, et DR-07 l'assume.
4. **Le Comptable peut-il travailler sans appeler le Directeur ?** **Pas encore.** Une demande de validation (paiement sensible, retrait de Réserve, sa propre paie) aboutit à « Validation demandée », puis n'arrive nulle part : CPT-Q1 n'a pas de réponse (`QUESTIONS.md`). Le statut affiché est honnête, mais la boucle reste ouverte. Question au directeur Q-D1.
5. **La sécurité reste-t-elle suffisante ?** Oui, côté frontend : voir §2. Les plafonds cumulés et l'anti-fractionnement sont confiés au serveur (`port_payout.dart:7-10`, `MotifRefusPayout.horsDelegation`, CPT-BR-02).
6. **Le montant est-il explicable ?** Oui. W03 détaille ligne par ligne, avec la source, et un écart se signale sans aucun champ de saisie (R-FIN-16 et 17, `detail_paiement_test.dart:26`, `:61` : `find.byType(TextField) findsNothing`). Après un recalcul, la confirmation relit la nouvelle version (R-FIN-18, `confirmation_payout.dart:283-297`, test `confirmation_payout_test.dart:205`).
7. **L'action peut-elle créer une fraude ?** Les chemins frontend sont fermés :
   - le montant n'est pas modifiable dans le payout (aucun champ dans `confirmation_payout.dart`) ;
   - les coordonnées ne sont modifiables que par le bénéficiaire (R-FIN-11, 13) ;
   - l'auto-paiement est sans case ni bouton ;
   - une ligne bloquée est exclue du lot (R-FIN-23) ;
   - la clé d'idempotence est rejouée quand l'issue est inconnue (`confirmation_payout.dart:210`, `:250`, `:488-493`).

   Reste un point faible, mineur m9 : `controler()` retire une clé neuve à chaque préflight (`:235`). Si le Comptable ferme la feuille pendant « issue inconnue » puis rouvre, un second envoi n'est arrêté que par le refus serveur `dejaSoumis` sur (obligation, version). C'est prévu dans CPT-BR, mais à écrire en clair dans CPT-BR-02.
8. **Le statut est-il honnête ?** Oui pour le payout : jamais « réussi » sur un simple appui, il passe par « soumis » puis le suivi du prestataire (`port_payout.dart:5-8`, `SuiviPayout`). Un écart cependant : sous le même titre « À traiter aujourd'hui », le bureau affiche **6** sur Aujourd'hui (`aujourdhui_page.dart:137`, `jour.aTraiterHorsPaiements`) et **8** sur la file complète (`:318-319`), parce que les paiements y sont comptés (captures `aujourdhui_1440x900@1_dark_masques`, `attention_1440x900@1_dark_masques`). Mineur m3.
9. **La métrique aide-t-elle vraiment ?** Oui. Pas de graphique décoratif (DR-09). La Trésorerie libre est en tête, avec sa définition écrite sous le chiffre. La Réserve montre un pourcentage atteint, le manque à compléter et la prochaine allocation. Point à trancher : les pourcentages (« 82 % atteint », « 29,2 % de la trésorerie détenue ») restent visibles quand les montants sont masqués. Question au directeur Q-D2.
10. **Le design ressemble-t-il à Rewayah ?** Oui, sur les captures que j'ai ouvertes : palette violette, rail et barre basse du thème, pastilles et cartes partagées, aucune identité « banque », aucun rail noir sur un contenu blanc. Aucune violation de jeton dans les fichiers de la vague.
11. **Le mobile est-il réellement utilisable ?** **Non à 320 px avec texte x2 sur les pages de détail.** Avec un bouton retour et la bascule des montants, l'en-tête occupe tout le premier écran, un mot par ligne (majeur M3). La barre collante de W06 à 320 x2 mange la moitié de l'écran (E3).
12. **Le desktop est-il réellement un bureau ?** Plutôt oui : tables, rail déplié, deux colonnes sur les détails, trois colonnes sur Aujourd'hui. Deux réserves, mineur m4 :
    - Nouvelle obligation à 1440 empile des cartes de choix de bénéficiaire sur 1 120 px de large, 110 px de haut chacune, avec un bouton pleine largeur (`nouvelleObligation_1440x900@1_dark_masques`) ;
    - la synthèse de Trésorerie occupe la moitié gauche et laisse le reste vide (`tresorerie_1440x900@1_dark_masques`).
13. **Le bénéficiaire garde-t-il la propriété de ses coordonnées ?** Oui. Le Comptable n'a pas de bouton « Modifier les coordonnées » (R-FIN-11, `beneficiaires_test.dart:173`, `:362`). Le libellé n'existe nulle part dans `assets/i18n/fr.i18n.json`, et l'admin n'ouvre pas `/comptable`. Le bénéficiaire saisit les siennes par un jeton opaque, et l'app ne voit jamais de numéro ni d'IBAN (`port_mes_moyens_paiement.dart:104-108`, R-FIN-13).
14. **Le Comptable peut-il se payer lui-même ?** Non :
    - la source rend `RaisonBlocage.autoPaiement`, l'écran affiche « Traitement par un autre responsable requis », sans bouton ni case (`detail_paiement_page.dart:245`, `paiements_donnees.dart:141-143`) ;
    - mes contre-épreuves montrent que les tests le gardent.

    Le choix « la source décide, l'écran ne compare jamais l'identifiant à la session » est écrit et justifié (DR-19). La garantie est donc serveur (CPT-BR-09).
15. **Une réserve protégée peut-elle être détournée ?** Non côté frontend. Un retrait sans capacité est bloqué, la raison est écrite et le bouton n'est jamais pressable (R-FIN-10, `transfert_interne_test.dart:183`, `tresorerie_page_test.dart:229`). Une sortie d'un coffre protégé exige une validation supplémentaire, et les interdits §10.4 ne sont jamais proposés.
16. **L'UI suppose-t-elle un backend inexistant ?** Non. Chaque port a une implémentation `...Indisponible` par défaut (par exemple `PayoutIndisponible`, `CapacitePayoutIndisponible`), qui affiche un état « en préparation » ou « pas encore disponible ». Aucun appel réseau dans `lib/features/comptable`, `lib/features/demo/comptable` ni `lib/features/paiements_recus` (grep sur `http`, `supabase`, `rpc`, `from(` : 0). Aucun fichier interdit K-19 touché : `supabase/`, `pubspec`, `.github`, `vercel.json` et le Coran sont absents du diff. Mais le défaut M1 vient justement de là : la démonstration, censée remplacer le backend, n'atteint pas la moitié des écrans.

## 2. Sécurité §47

| Point | Résultat | Preuve |
|:--|:--|:--|
| Argent en entiers mineurs | **Tenu.** Aucun `double`, `num` ni `toDouble` sur un montant dans les 99 fichiers `lib/` de la vague. Seul `toDouble` : la fraction d'une barre de progression (`carte_reserve_strategique.dart:51`, à partir de `atteintPourMille`, un entier). Les saisies passent par des expressions régulières puis `int.parse`, 12 chiffres au plus (`transfert_interne.dart:166-171`, `saisie_politique.dart:27-45`, `contractuels_commun.dart:102`), ce qui reste sûr en JavaScript (moins de 2^53). | grep |
| Aucune lecture de rôle dans les widgets | **Tenu pour la vague.** 0 `AppRole`/`.role` dans `lib/features/comptable`, `admin_finance/reserve_delegation` et `paiements_recus`. Les seules occurrences sont `nav_shell.dart` (table des destinations, attendue) et `compte_page.dart`, qui en a 23, comme à la base. Les boutons viennent de `actionsPermises` (`statuts_comptable.dart:158-161`). | grep, `git diff` |
| Masqué par défaut, remasqué à chaque session | **Tenu.** Un seul `Notifier` en mémoire, `build()` rejoué quand l'identité de session change (`visibilite_montants.dart:24-37`), jamais persisté. Masque de longueur fixe par devise (`montant_sensible.dart:17`). | R-FIN-01 à 03, contre-épreuve |
| Démonstration jamais en production (K-09) | **Tenu.** `routesDemoComptable` rend `[]` hors `environnementAutoriseDemo` (`demo_comptable_page.dart:126-127`). La porte de redirection utilise le même garde (`redirection.dart:50-66`). Test : `routes_comptable_test.dart:137-148` (`'production'` et `''` donnent une liste vide). | test rejoué |
| Aucun appel serveur réel | **Tenu.** Les ports pointent par défaut sur `...Indisponible`, et la démo les surcharge. | grep |
| Aucun IBAN ni coordonnée réelle | **Tenu.** Suffixes fictifs à 4 chiffres (`beneficiaires_demo.dart:108-109`), destination toujours masquée « Type •••• 1234 », aucun motif IBAN ni numéro de téléphone dans les données de démo. | grep |
| Idempotence et préflight | **Tenu.** Préflight obligatoire sur (id, version). Clé UUID tirée une fois par préflight et rejouée en cas d'issue inconnue (`confirmation_payout.dart:210-276`). Refus typés : `versionChangee`, `dejaSoumis`, `horsDelegation`, `preflightPerime`. Réserve m9 (clé neuve après fermeture). | `confirmation_payout_test` |
| Interdiction de se payer soi-même | **Tenu**, par la raison rendue par la source (DR-19). | R-FIN-15, contre-épreuve |
| L'admin n'ouvre pas `/comptable` | **Tenu.** Il est renvoyé vers `/admin` (`routes_comptable_test.dart:331-339`). | test rejoué |
| Le Comptable n'ouvre pas le delta Direction | **Tenu.** Il est renvoyé vers `/comptable` (`routes_comptable_test.dart:373-381`). | test rejoué |
| Montant exact à la confirmation | **Tenu.** `MontantArgent`, jamais `MontantSensible`, dans la feuille de confirmation (`confirmation_payout.dart:3-4`, `:602`). | R-FIN-04 |

## 3. Recettes R-FIN-01 à 29

Les tests cités ont tous été rejoués et sont verts dans les dossiers ci-dessus. Pour les captures, le tableau dit si je les ai ouvertes moi-même.

| R-FIN | État | Preuve |
|:--|:--|:--|
| 01 Masqués à l'entrée | Tenu | `visibilite_montants_test.dart:38`, `montant_sensible_test.dart:49`, `aujourdhui_page_test.dart:245`, `encaissements_test.dart:111` ; captures ouvertes : Aujourd'hui, Trésorerie, Attention (320 et 1440) |
| 02 « Afficher » les révèle | Tenu | `visibilite_montants_test.dart:44`, `montant_sensible_test.dart:72`, `encaissements_test.dart:119` |
| 03 Remasqués à la nouvelle session | Tenu | `visibilite_montants_test.dart:59`, `:70` ; contre-épreuve rouge |
| 04 Montant exact avant confirmation | Tenu | `confirmation_payout_test.dart:89` |
| 05 Titre fixe « Réserve stratégique » | Tenu | `tresorerie_page_test.dart:138`, `:160` (1, 6 et 12 mois) |
| 06 « Objectif : 3 mois de charges essentielles » | Tenu | `tresorerie_page_test.dart:138-157` (`c.objectifMois(n: 3)`) |
| 07 Objectif fixe : le montant cible | Tenu | `tresorerie_page_test.dart:183` |
| 08 Allocation fixe de 10 USD affichée | Tenu | `tresorerie_page_test.dart:205`, `strategic_reserve_policy_panel_test.dart:128`, `saisie_politique_test` |
| 09 1 000 000 USD sans valeur codée en dur | Tenu | `finance_delegation_policy_panel_test.dart:141`, `strategic_reserve_policy_panel_test` |
| 10 Retrait de Réserve sans capacité bloqué | Tenu | `transfert_interne_test.dart:183`, `tresorerie_page_test.dart:229` |
| 11 Le Comptable : pas de « Modifier les coordonnées » | Tenu | `beneficiaires_test.dart:173`, `:362` |
| 12 L'admin : pas de « Modifier les coordonnées » | Tenu **par absence**, sans test dédié | le libellé n'existe pas dans `fr.i18n.json` ; admin bloqué hors de `/comptable` (`routes_comptable_test.dart:331`). Ajouter un test (m6). L'onglet « À valider » attend CPT-Q1 |
| 13 L'enseignant ajoute ou modifie les siennes | Tenu | `recevoir_paiements_test.dart:136`, `:162` |
| 14 Coordonnées récentes : paiement sensible | Tenu | `detail_paiement_test.dart:136`, `confirmation_payout_test.dart:228` |
| 15 Sa propre paie : pas de Payer, libellé exact | Tenu | `detail_paiement_test.dart:121`, `paiements_page_test.dart:69`, `confirmation_payout_test.dart:241` ; contre-épreuve rouge |
| 16 Montant enseignant en lecture seule | Tenu | `detail_paiement_test.dart:26`, `paiements_page_test.dart:39` |
| 17 Écart sans champ de correction | Tenu | `detail_paiement_test.dart:61` |
| 18 Après recalcul, nouvelle version | Tenu | `confirmation_payout_test.dart:205` |
| 19 Infos manquantes : avis visible du bénéficiaire | Tenu | `recevoir_paiements_test.dart:116`, `:166` |
| 20 « Relancer » ouvre Messages métier en contexte | **Partiel**, différé à CPT-COM | aujourd'hui, une relance préparée par le port, avec modèle et objet ; « Voir le fil » seulement si la source rend une route (`beneficiaires_test.dart:380-430`). Le branchement au vrai fil est prévu par CPT-COM après COM-FUS (`00_REPRISE.md` §5) |
| 21 Aucune messagerie Finance | Tenu | `beneficiaires_test.dart:380`, `paiements_page_test.dart:154` |
| 22 Lot de 12 prêts et 2 bloqués : exclusion claire | Tenu | `confirmation_payout_test.dart:269` (11 prêts / 2 exclus, clé `payout-exclus`) |
| 23 Aucun bloqué envoyé | Tenu | `confirmation_payout_test.dart:332-341` (« un exclu ne part jamais avec le lot ») ; `:349` (un paiement sensible est exclu du lot) |
| 24 Design system Rewayah | Tenu sur ce que j'ai vu | 39 → 39 jetons, aucun dans les fichiers de la vague ; 8 captures ouvertes, voir §4 |
| 25 Pas de thème hybride | Tenu | en sombre, rail et contenu sont sombres sur les 4 écrans à 1440 que j'ai ouverts |
| 26 High-fi harmonisées | Tenu sur la composition | mêmes cartes, pastilles et `MontantSensible` partout ; défauts de gabarit en m4 |
| 27 DM Sans pour les titres | Tenu par le code | `app_typography.dart:29`, `entete_page.dart:64` (`headlineSmall` et `headlineMedium` en DM Sans). E7 n'est pas un défaut |
| 28 Plus Jakarta Sans reste | Tenu | `app_typography.dart`, corps en Jakarta |
| 29 Desktop réel 1440 | Tenu, avec les réserves m4 | `*_1440x900@1_*` ; j'ai ouvert Aujourd'hui, Attention, Trésorerie et Nouvelle obligation en sombre |

**Bilan : 27 tenues, 1 partielle et différée par le plan (R-FIN-20), 1 tenue sans test dédié (R-FIN-12).**

## 4. Captures que j'ai ouvertes moi-même

Lecture d'image accordée. Ouvertes : `aujourdhui`, `attention`, `tresorerie` et `nouvelleObligation` à 320x640@2 texte x2 clair et à 1440x900@1 sombre, plus `detailPaiement_320x640@2_texte2_light_masques` et `ecart_route_demo_tresorerie_390x844@3_light_masques`. Les 390 clair n'ont pas été ouverts, par économie.

- **Aujourd'hui 320 x2** : titre plein, bascule à droite du sous-titre, Trésorerie libre masquée « ●●●●●,●● $ », barre basse lisible. Rien de coupé hors défilement.
- **Aujourd'hui 1440 sombre** : trois colonnes, Réserve « Sous objectif ». Le titre « Alertes 3 » est plus haut d'environ 12 px que les deux autres titres de colonne et n'a pas de « Voir tout » ; vide sous la carte de trésorerie (m5). Compteur 6 contre 8 (m3).
- **Attention 320 x2** : **défaut**. Le bouton retour et la bascule encadrent une colonne de titre d'environ 50 % de la largeur ; « À / traiter / et / alertes » s'écrit un mot par ligne, et le premier écran ne montre **aucun contenu** (M3).
- **Attention 1440 sombre** : liste propre, tons attention et alerte lisibles.
- **Détail du paiement 320 x2** : même défaut M3. Le premier écran n'est que le titre et une phrase de 8 lignes.
- **Trésorerie 320 x2** : correct (sélecteur « Coffres », bascule).
- **Trésorerie 1440 sombre** : la bascule n'a pas de libellé « Montants masqués », alors qu'Aujourd'hui en a un ; la synthèse occupe la moitié gauche et laisse le reste vide ; les pourcentages restent visibles sous le masque (m4, m5, Q-D2).
- **Nouvelle obligation 320 x2** : titre à côté du retour, encore acceptable ; le bouton « Créer l'obligation » occupe deux lignes en bas.
- **Nouvelle obligation 1440 sombre** : formulaire étiré sur toute la largeur, cartes de choix de 110 px de haut (m4).
- **ecart_route_demo_tresorerie** : « Cet écran est en préparation. Aucun chiffre n'est affiché ici pour l'instant. » C'est ce que voit l'opérateur sur la vraie route (M1).

## 5. Écarts E1 à E9 de CPT-CAPT, et ceux que j'ajoute

| # | Jugement | Raison |
|:--|:--|:--|
| E1 arabe absent (`comptable.*`) | **Directeur** (Q-D3), pas une régression | `ar.i18n.json` ne couvre que 8 espaces de clés sur 48 (classe, commun, compte, eleve, enseignant, etat, salle, tc) : ni Finance ni admin ne sont traduits. Le gabarit RTL se retourne bien. Faut-il traduire un rôle du personnel ? |
| E2 route de démo sans surcharges | **MAJEUR, plus large que relevé** : voir M1 | pas 2 écrans, 8 sur 16 |
| E3 barre collante W06 à 320 x2 | Mineur (m7) | le contenu défile, mais il reste moins de 300 px utiles |
| E4 pastilles sur 2 ou 3 lignes | Mineur (m8) | forme pleine qui touche le texte à 320 x2 ; « À approuver » sur deux lignes à 1440 |
| E5 pastille de version sur 3 lignes (Direction) | Mineur (m8) | même cause que E4 |
| E6 interrupteur de délégation, vide et bordure imbriquée | Mineur (m8) | gabarit |
| E7 police des titres à 320 | **Clos, pas un défaut** | `entete_page.dart:64` utilise `headlineSmall`/`headlineMedium`, en DM Sans par le thème (`app_typography.dart:29`, `:140-141`) |
| E8 environ 250 px de vide dans `admin_shell` à 390 | Mineur (m8) | coquille admin partagée |
| E9 colonne État des encaissements à 1440 | Mineur (m8) | alignement d'une pastille longue |
| **E10** (nouveau) en-tête des détails à 320 x2 | **MAJEUR** : voir M3 | |
| **E11** (nouveau) compteur « À traiter » 6 contre 8 | Mineur (m3) | |

## 6. Défauts majeurs

**M1. La démonstration réelle laisse 8 écrans sur 16 vides.** `DemoComptablePage` pose les surcharges dans un `ProviderScope` imbriqué (`demo_comptable_page.dart:~323`, `overrides: surchargesCoquilleComptableDemo(...)`). Or les fournisseurs dérivés qui lisent les ports ne déclarent pas `dependencies:`. Ils sont donc résolus dans le conteneur racine, lisent le port `...Indisponible` et affichent l'état « en préparation ». Ce que j'ai relevé sur la route `routesDemoComptable('staging')`, sans surcharge à la racine :
- **en préparation** (« Cet écran est en préparation. ») : `beneficiaires`, `profilPaiement`, `tresorerie`, `alimenter` ;
- **pas encore disponible** (« Pas encore disponible ») : `contractuels`, `obligationContractuel`, `nouvelleObligation`, `recevoirPaiements` ;
- **rendus normalement** : aujourdhui, attention, paiements, detailPaiement, encaissements, detailEncaissement, rapprochement, compte, ainsi que le delta Direction sur `/demo/finance?ecran=reserveDelegation`.

Fichiers fautifs (nombre de fournisseurs, `dependencies:` déclarés) :
- `lib/features/comptable/tresorerie/tresorerie_donnees.dart` : 7, 0 ;
- `lib/features/comptable/beneficiaires/etat_beneficiaires.dart` : 4, 0 ;
- `lib/features/comptable/contractuels/contractuels_commun.dart` : 4, 0 ;
- `lib/features/paiements_recus/etat_mes_moyens.dart` : 4, 0.

À comparer avec ceux qui marchent : `aujourdhui_page.dart:66` et `paiements_donnees.dart:23-43` déclarent bien leurs `dependencies`.

Les 119 captures CPT-CAPT posent les mêmes surcharges à la racine (`cpt_capt_recette_test.dart:93-98`, et le commentaire le reconnaît). Elles montrent donc un état que l'opérateur ne voit pas en PWA. C'est contraire à la règle transverse « tout doit fonctionner en PWA » et à l'objet de K-09.

**M2. Suite `test/widgets` rouge.** `catalogue_galerie_test.dart:257-279` : quatre fichiers ajoutés par la vague dans `lib/core/widgets/` n'ont d'entrée ni au catalogue ni dans la galerie : `bascule_montants`, `ligne_destination`, `montant_sensible`, `pastilles_comptable`. C'est le premier contrôle de « Vérifier avant de dire que c'est fait » (`flutter test`) : la CI est rouge.

**M3. En-tête des pages de détail inutilisable à 320 x2.** `lib/core/widgets/entete_page.dart:99-140`, modifié par la vague. Le titre ne passe sous le retour et les actions que si **le mot le plus long** ne tient pas à côté. Quand chaque mot tient, le titre et le sous-titre sont composés dans environ 50 % de la largeur, un mot par ligne, et le premier écran ne montre rien d'autre. Captures : `attention_320x640@2_texte2_light_masques`, `detailPaiement_320x640@2_texte2_light_masques`. Cela touche W03, l'écran central du paiement, et la file complète de W01.

## 7. Mineurs

- **m1.** `lib/core/widgets/comptable/` (3 composants : `carte_reserve_strategique`, `ligne_activite`, `resume_tresorerie`) échappe au contrôle du catalogue, qui ne lit pas les sous-dossiers (`catalogue_galerie_test.dart:261-263`). Il faut les inscrire, ou les déplacer dans `lib/features/comptable/commun/`.
- **m2.** Le registre des écrans `docs/archive/2026-09-pre-remise-a-plat/design/08-catalogue-ecrans.md:89` porte encore `CPT-01 … hors MVP-0`. Les écrans FIN-CPT-W01 à W07, M01 et M02 n'y sont pas inscrits : le registre de fait est `UX_REVIEW_FINANCE_COMPTABLE_L0.md` (voir Q-D4).
- **m3.** Même titre « À traiter aujourd'hui », compteurs 6 et 8 (`aujourdhui_page.dart:137` contre `:318`).
- **m4.** Bureau : Nouvelle obligation étirée sur 1 120 px ; synthèse de Trésorerie sur une demi-largeur.
- **m5.** Bascule sans libellé sur Trésorerie à 1440 (avec libellé sur Aujourd'hui) ; titre « Alertes » désaligné ; vide sous la carte de trésorerie d'Aujourd'hui.
- **m6.** R-FIN-12 sans test dédié.
- **m7.** E3.
- **m8.** E4, E5, E6, E8, E9.
- **m9.** Clé d'idempotence neuve si la feuille est fermée puis rouverte après « issue inconnue » : écrire dans CPT-BR-02 que le serveur refuse `dejaSoumis` sur (obligation, version), quelle que soit la clé.

## Suivi proposé / CPT-RC

Les corrections, majeurs d'abord :

1. **(M1) Démonstration réelle complète.** Ajouter `dependencies: <ProviderOrFamily>[port...Provider]` à chaque fournisseur dérivé de `tresorerie_donnees.dart`, `etat_beneficiaires.dart`, `contractuels_commun.dart`, `etat_mes_moyens.dart`, et vérifier `donnees_encaissements.dart` et `donnees_rapprochement.dart`, qui rendent aujourd'hui mais sans `dependencies`. À défaut, donner aux pages un point d'entrée qui lit les ports dans la portée. **Fait quand** : un nouveau test `test/features/comptable/socle/route_demo_reelle_test.dart` monte `routesDemoComptable('staging')` dans un `ProviderScope` **sans surcharge**, pour chacune des 16 valeurs de `EcranDemoComptable`, et vérifie qu'aucun texte `enPreparationTitre` ni « Pas encore disponible » n'apparaît. Ce test échoue sur `8fb00a71`. Ensuite, `cpt_capt_recette_test.dart` passe `racine: false` par défaut, et les captures W04, M02, W06 (trois écrans) et W07 (deux écrans) sont régénérées depuis la vraie route.
2. **(M2) Catalogue et galerie.** Voici ce qu'il faut inscrire, sur le modèle de `MontantArgent` (FI-3a) : une ligne commentée dans `composantsDuCatalogue` (`test/widgets/catalogue_galerie_test.dart`, à la suite de `// FI-3b`) et une `EntreeGalerie` d'au moins 2 états dans `lib/features/_dev/galerie/catalogue_galerie.dart`. Ces composants ne sont pas inscrits dans un document markdown : la liste de test, avec son commentaire de lot, tient lieu de catalogue.
   - `// CPT-F (spec §7, DR-06) : le masque des montants du Comptable.` puis `'BasculeMontants'` (états : masqués, affichés, étroit sans libellé) et `'MontantSensible'` (états : masqué, révélé, grand).
   - `ligne_destination.dart` contient `LigneDestinationMasquee` : **renommer le fichier** en `ligne_destination_masquee.dart`, inscrire `'LigneDestinationMasquee'` (états : mobile money vérifiée, banque à vérifier, sans destination).
   - `pastilles_comptable.dart` contient 9 classes et aucune `PastillesComptable`. Recommandé : inscrire `'PastillesComptable'` comme une famille, sur le modèle de l'exception `GrilleSemaine` mais dans l'autre sens, avec un commentaire qui le dit, et une `EntreeGalerie(nom: 'PastillesComptable', famille: FamilleComposant.composantEtat)` dont les états sont les 9 pastilles, chacune dans un état représentatif. Variante plus stricte : un fichier par pastille.
   - **Fait quand** : `flutter test test/widgets` est à 0 échec (aujourd'hui −1), y compris « un composant livré avec son seul état nominal n'est pas fini ».
3. **(M3) En-tête à 320 x2.** `lib/core/widgets/entete_page.dart` : empiler retour et actions au-dessus du titre aussi quand la largeur laissée au titre est sous un seuil (par exemple moins de 60 % de `maxWidth`), ou dès que `textScaler` atteint `AppGabarit.seuilTexteColonne`. **Fait quand** : un test à 320x640, texte x2, avec `onRetour` et une action, vérifie que le titre prend la largeur de la colonne et que le premier élément de contenu est visible dans le premier écran. Captures `attention`, `detailPaiement` et `obligationContractuel` en 320 x2 régénérées et ouvertes.
4. (m3) Compteur Aujourd'hui : renommer la zone du bureau « À traiter (hors paiements) », ou afficher le total de la file. **Fait quand** : un même titre porte un même nombre sur les deux écrans (test dans `aujourdhui_page_test.dart`).
5. (m6) Test R-FIN-12 : l'admin sur une fiche personne enseignant, `find.textContaining('coordonnées')` sans action de modification.
6. (m1) Inscrire ou déplacer les trois composants de `lib/core/widgets/comptable/`, et étendre le contrôle aux sous-dossiers.
7. (m4, m5) Nouvelle obligation à 1440 : colonne de formulaire bornée et liste des bénéficiaires plus dense ; synthèse de Trésorerie sur toute la largeur ou en deux colonnes ; libellé de la bascule homogène sur toutes les pages.
8. (m7, m8 : E3 à E6, E8, E9) Pastilles longues : rayon non plein ou texte sur une seule ligne avec retour à la ligne propre. Barre collante W06 plus compacte à texte x2. Vide de `admin_shell` à 390.
9. (m9) Une phrase dans `20_comptable/CPT-BR.md` (CPT-BR-02) : refus `dejaSoumis` par (obligation, version), indépendamment de la clé.
10. (m2) Inscrire FIN-CPT-W01 à W07, M01 et M02 au registre des écrans en vigueur, selon la réponse à Q-D4.

**Questions au directeur**

- **Q-D1** (CPT-Q1, toujours ouverte) : où la Direction valide-t-elle les demandes du Comptable ? Onglet « À valider » dans Finance, ou rien dans cette vague ? Sans réponse, la question 4 du §59 reste à « non ».
- **Q-D2** : quand les montants sont masqués, faut-il aussi masquer les pourcentages (« 82 % atteint », « 29,2 % de la trésorerie détenue ») ? Ils ne donnent pas de montant, mais ils révèlent la répartition, et un seul montant révélé suffit à tout recalculer.
- **Q-D3** (E1) : faut-il traduire l'espace Comptable en arabe ? Aujourd'hui, ni Finance ni admin ne le sont (8 espaces de clés sur 48).
- **Q-D4** : le registre des écrans (`08-catalogue-ecrans.md`) est archivé et porte encore « CPT-01 hors MVP-0 ». Peut-on confirmer que `20_comptable/UX_REVIEW_FINANCE_COMPTABLE_L0.md` tient lieu de registre pour cette vague, ou faut-il réinscrire les écrans ?
