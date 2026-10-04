# Revue croisée FI-3-R : composants d'argent FI-3a et FI-3b, plus FI-1c-MINEURS

- **Branche** : `ui/finance-v1`, plage **`bdac0bb7..aebd21a5`** (bornes exclusives à gauche). On a donc trois commits : `4acc1293` FI-3a, `fbe219e7` FI-1c-MINEURS et `aebd21a5` FI-3b. `bdac0bb7` (FI-2-CORR) est exclu, car il appartient au lot précédent, déjà revu.
- **Comment j'ai obtenu le code** : `git fetch origin ui/finance-v1` (f58645d1..aebd21a5). Les deux commits sont **sur `origin/ui/finance-v1`**, et `git branch -r --contains aebd21a5` ne renvoie que cette branche. Je n'ai utilisé aucun patch de `claude/collaborative-task-tracking-r47ieu` : cette branche ne contient aucun patch FI-3, seulement FI-1c-CORR et FI-2-CORR. Travail fait dans un worktree détaché à `aebd21a5`, et dans un second worktree à `bdac0bb7` pour la base. Les deux sont retirés.
- **Guide Finance V4** : il **n'est pas dans le dépôt applicatif**. Je l'ai lu dans le dépôt de pilotage (`pilotage/tuteur-v1`, `17_finance/V/REWAYAH_FINANCE_FRONTEND_GUIDE_V4_2026-10-02.md`), aux §1.6, §1.7, §7, §11.3 et §11.4. J'ai aussi lu la fiche dans `17_finance/02_DECOUPAGE.md` (lignes 33-34 et 60-61, dont C-4, C-5, X-2 et Q-FI-9) et la maquette 02.
- **Revue FI-1c-CORR-R** : introuvable, ni dans le dépôt, ni sur la branche de suivi, ni dans le pilotage. J'ai contrôlé les mineurs à partir de la liste de la fiche de revue.
- **Méthode** : lecture de tout le diff, outils comparés à la base, tests ciblés, contre-épreuves par mutation, et une sonde jetable (mesures avec la police de test **et** avec les vraies polices du dépôt chargées par `FontLoader`), supprimée après usage.

## Verdict

**REFUSÉE.** Le formateur est juste et la plupart des invariants sont tenus : aucun calcul côté widget, jetons seulement, point **et** mot, aucun bouton App Store ou Play, LigneCleValeur sans régression. En revanche, trois critères **écrits dans la fiche** ne sont pas tenus et ne sont pas testés :

- le montant n'est pas au bord de fin et les décimales ne s'alignent pas (M1) ;
- la pastille d'essai ne porte pas « Essai : n/2 » (M2) ;
- le ton de l'essai est violet, voisin de l'accent de profil lavande, et aucune ligne TH-2 n'a été ouverte (M3).

Ces composants sont la fondation de FI-4, FI-6a et FI-7. M1 change le contrat de `LigneCleValeur`, et cela doit être fixé avant le premier écran. Les corrections sont courtes (voir « Pour accepter »).

## Périmètre et commandes (chiffres)

| Contrôle | Base `bdac0bb7` | Lot `aebd21a5` |
|---|---|---|
| `dart run slang` | — | OK, aucun fichier modifié |
| `dart analyze --fatal-infos` | — | **0 problème** (exit 0) |
| `tool/verifier_jetons.dart` | 39 violations | **39**, liste identique, aucune dans les fichiers du lot |
| `tool/verifier_revue.dart` | 1627 (libelle-sans-source 1566…) | **1627**, identique : les 17 clés `argent.*` ont leur source |
| `flutter test --concurrency=2 test/core/finance test/core/widgets test/widgets test/features/finance` | 424 OK, 1 échec de chargement (`test/core/finance` n'existe pas encore) | **459 / 0** (+35 tests) |
| Appelants de `LigneCleValeur` : `test/features/{classe_tuteur,controleur,creneaux,foyer,journee}`, `creneaux_test`, `journee_test`, `suivi_eleve_test` | — | **660 / 0** (140 ignorés, déjà existants) |

**Contre-épreuves** (mutations remises à l'ancien comportement, puis restaurées) :

- Ancien rattachement As-Salam, ancien impayé tiré du foyer, `manques: []` : **2 échecs**. Ce sont les 2 nouveaux tests FI-1c-MINEURS (« encaisse et impayes sur les memes sieges… », « aucun profil mineur dans une classe d adultes »).
- Espace insécable remplacée par une espace ordinaire et `U+2212` remplacé par `-` : **6 / 6 tests de format échouent**.
- `LigneTransaction` non signée, `estMontre` toujours vrai, `valeurForte` ignorée : **3 échecs**, un par test visé.

**Mots coupés à 320 px, texte ×2** (sonde avec `motsCoupes`, copiée de `corrections/c2-coupe2:test/support/aucun_mot_coupe.dart` parce qu'elle n'est pas sur `ui/finance-v1`) :

- Avec la police de test (glyphes de 1 em), 15 faux positifs.
- Avec les **vraies polices**, LTR et RTL : **un seul mot coupé**, `−1 234,56 $` en `TailleMontant.grand`, coupé dans « 234,56 » (m1). Rien à 390 ×2.

## Défauts

### Majeurs

**M1. Le montant n'est ni au bord de fin ni aligné en colonne** (fiche FI-3a : « RTL (montant au bord de fin), alignement des décimales dans une colonne » ; guide §7, §11.3 « colonnes calmes et stables » ; maquette 02, « Détail de la mensualité » aligné à droite).

- **Où** : `lib/core/widgets/ligne_cle_valeur.dart:93-104` (`Wrap` sans `alignment`) et `:120` (`Expanded(flex: 3)`). `ligne_finance.dart:124`, `ligne_transaction.dart:169`, `ligne_allocation.dart:212` et `resume_soldes.dart:256-273` en héritent.
- **Mesure** (vraies polices, 390 px, bord de fin de la ligne à x = 374) :

  | Cas | Gauche | Droite |
  |---|---|---|
  | « 50 $ » (LTR) | 168,8 | 201,1 |
  | « −5 $ » (LTR) | 168,8 | 201,2 |
  | « 143,20 $ » (LTR) | 168,8 | 242,1 |
  | « 50 $ » (RTL, bord de fin à x = 16) | 188,9 | 221,2 |

- **Conséquence** : les montants commencent au milieu de la ligne, alignés à gauche, avec des fins qui varient. Ce n'est ni le bord de fin ni une colonne de décimales.
- Aucun test ne le vérifie : `lignes_finance_test.dart:156-186` ne contrôle que l'absence de débordement et l'empilement à ×2.

**M2. La pastille d'essai ne dit pas où en est l'essai** (fiche FI-3b : « financé, essai n/2, il manque X… » ; ligne 61, C-4 : « StatusPill à deux mots : « Essai : 1/2 » »).

- **Où** : `pastille_financiere.dart:16-30` n'a aucun paramètre de compteur, et `assets/i18n/fr.i18n.json:4678` donne `"essai": "Essai"`.
- Les données existent déjà (`essaisUtilises`, `essaisMax`). FI-4 et FI-9a devront donc rouvrir le composant.

**M3. Le ton de l'essai est voisin d'un accent de profil, et aucune ligne TH-2 n'a été ouverte** (fiche ligne 61, C-5).

- **Où** : `pastille_financiere.dart:35-36`. `essai` et `enConfirmation` sont en `TonEtat.accent`, avec un point `surfacePrimary` `#8652E6` sur `washAccent` `#EEE6FA`.
- L'accent de profil `lavande` vaut `#B7A3F3` en clair et `#CDBDF9` en sombre (`app_palette.dart:627` et `:639`). C'est la même famille violette.
- Le doc du widget affirme « jamais l'accent du profil », mais la proximité demandée par C-5 n'est ni mesurée ni arbitrée.

### Mineurs

- **m1. Un grand montant se coupe dans le nombre à 320 ×2.** `montant_argent.dart:64-69` : `−1 234,56 $` en `grand` (displaySmall 36 ×2) se casse dans « 234,56 » (sonde, vraies polices, LTR et RTL). Les insécables n'y peuvent rien quand le mot seul dépasse la ligne. Il faut une réduction (`FittedBox` borné ou repli sur `titre`) et un test.
- **m2. `BandeauAttention` ne suit pas l'assemblage X-2.** La fiche demande `AppCard` + `StatusPill` + `ProfileIdentityAvatar` + `ActionPrincipale` ; ici c'est une `DecoratedBox` à paire douce, sans avatar ni pastille, avec une action réduite à un lien (`bandeau_attention.dart:24-45, 59-60`). L'écart n'est justifié nulle part. De plus, `liveRegion: true` (`:58`) sur un bandeau permanent est annoncé à chaque apparition. Un Foyer à plusieurs bandeaux (un par enfant) les annoncera tous.
- **m3. `LigneMoyenPaiement` est sur `AppCard`, pas sur `ChoiceCardGroup` (Q-FI-9).** Sans `onPress` (hors ligne), la sémantique n'a ni `hasEnabledState` ni `isEnabled=false` (sonde : `flags: [isInMutuallyExclusiveGroup, hasSelectedState]`). Le lecteur d'écran n'annonce donc pas que le choix est indisponible, et aucun état visuel désactivé n'est montré (`ligne_moyen_paiement.dart:152-157`).
- **m4. Critères de test de la fiche absents :**
  - aucun test en thème **sombre** (les deux fichiers de test n'emploient que `hote`, en clair) ;
  - aucun test « qui retire la couleur et lit l'état » (seuls les mots distincts sont testés, `composants_argent_test.dart:63-70`) ;
  - aucun test d'alignement en colonne ;
  - « format fr et en » : sans objet, car l'application n'a que fr et ar. En revanche, `formaterMontant` ignore la locale (`format_montant.dart:18-21`), alors que le guide §11.3 dit « selon la locale affichée ». La question de l'arabe est signalée par l'auteur, mais elle n'apparaît dans aucune liste de questions.
- **m5. Garde-fou m2 de FI-1c-R non durci.** Il devait l'être « à l'occasion de FI-3a ». `finance_demo_test.dart:600-602` ne cherche toujours que des littéraux en unités mineures, et `usd(50)`, `Montant(50 * 100…)` ou `50 USD` passent encore.
- **m6. Le manque de 8 est écrit deux fois** (`finance_demo.dart:274` pour le foyer et `:513` pour la classe Al-Huda). Le test les relie, mais la source n'est pas unique.
- **m7. Vue globale : populations encore mêlées.** Encaissé et impayés sont bien sur les 13 sièges. En revanche, `soldesCrediteurs` vient du foyer `tousFinances` et `essaisEnCours` du jeu `unEnEssai` (`finance_demo.dart:603-606`), deux populations qui ne correspondent pas aux classes.
- **m8. `BadgePeriodeFinancee` :**
  - il emprunte la clé d'un écran, `t.foyer.membre.date`, depuis `lib/core` ;
  - il passe par `toLocal()` (`badge_periode_financee.dart:26-34`). Une fin rendue à minuit UTC peut afficher la veille sur le continent américain.
- **m9. Galerie** (outil de développement) : textes sans accents (« Acces a regulariser ») et « Il manque 8 USD » en contradiction avec le formateur, qui écrit « 8 $ » (`catalogue_galerie.dart:1185-1186`).

### FI-1c-MINEURS (jeux de démonstration)

| Point | Constat |
|---|---|
| Impayés | ✅ `impayesDemo()` = manques des sièges des classes. 8 $, égal au manque d'Ibrahim et au montant de l'alerte, testé et contre-éprouvé. |
| As-Salam | ✅ Youssef (12 ans) et Khadija (13 ans) sont passés à Al-Huda. Le test vérifie qu'aucun profil de moins de 18 ans n'est dans une classe d'adultes, pour tous les jeux. Contre-éprouvé. |
| Marge « de la paie » dans le contrat | ✅ Documentée sur `VueGlobaleFinance.margeProjeteePourMille` (`port_finance_direction.dart:85-92`) : la marge porte sur la paie seule et ne se compare jamais aux 30 % nets. |
| État « À régulariser » | ⚠️ Non ajouté à `EtatAccesAffiche`. Le report est justifié (il faut un état rendu par le serveur) et posé en question FI-BR-08 (`finance_demo.dart:373-384`). À inscrire dans les questions au directeur. |
| Date de fin du jeu sans paiement | ✅ Déclarée valeur de démonstration, pas une règle (`:355-360`). |
| Essai avec date de fin | ✅ Gardé sans échéance, avec justification (un essai se compte en séances, pas en jours). |
| Encaissé et impayés sur la même population | ✅ Pour ces deux chiffres. Voir m7 pour les soldes créditeurs et les essais. |

### Ce qui est conforme

- **`formaterMontant`** (§7, §11.3) :
  - « 50 $ » avec U+00A0 ;
  - centimes seulement s'il y en a (« 143,20 $ », « 145 $ ») ;
  - milliers en U+202F ;
  - vrai moins U+2212 toujours, plus seulement sur demande, zéro sans signe ;
  - devise identifiable (symbole pour USD, EUR et GBP, code ISO sinon) ;
  - XOF sans décimales.
- **Aucun calcul dans les widgets** : `ResumeSoldes` n'additionne rien, tout vient de `SyntheseFoyer`.
- **Jetons seulement**, aucun rôle lu.
- **Pastille** : point et mot sur `StatusPill`, sept mots distincts.
- **Moyen de paiement** : sélection dite par un fond, une icône et `isSelected` ; carte entière pressable ; StoreKit et Play ne rendent rien (testé).
- **`LigneCleValeur`** : les trois paramètres ajoutés ont des défauts qui reproduisent l'arbre d'avant. 660 tests des appelants verts.

## Captures vues

**Aucune capture du lot.** Je n'en ai trouvé ni dans `docs/` d'`aebd21a5`, ni sur `claude/collaborative-task-tracking-r47ieu` (FI-2-CORR seulement), ni dans le pilotage (`17_finance/captures/` ne contient que FI-2). Pour comparer, j'ai ouvert la maquette `17_finance/V/02_mobile_sombre_mariam_finances.png` : montants alignés au bord de fin, ce qui fonde M1. La fiche ne réclame pas de captures pour FI-3, mais le guide F1 demande des « golden composants ».

## Pour accepter

1. **M1** : ajouter à `LigneCleValeur` un paramètre (par exemple `valeurEnFin`, défaut `false` pour les autres rôles) qui pose la valeur au bord de fin (`WrapAlignment.end` ou `AlignmentDirectional.centerEnd`). Les lignes d'argent l'activent. Ajouter un test : à 390 et 1440, en LTR et RTL, le bord de fin de chaque montant égale le bord de fin de la ligne à 0,5 px près, et les montants d'une colonne ont le même bord de fin.
2. **M2** : la pastille d'essai reçoit le compteur (`essaisUtilises` et `essaisMax`, mis en mots par une clé `argent.etat.essaiCompte`, « Essai : {n}/{max} »), avec un test.
3. **M3** : mesurer l'écart entre le ton de l'essai et `lavande`, en clair et en sombre. S'il est trop proche, ouvrir la ligne TH-2 et le dire dans le bilan.
4. **Tests manquants** : thème sombre pour les 9 composants, et un test qui neutralise la couleur (`StatusPill` sans fond) et lit l'état.
5. **Recommandé avant FI-4** : m1 (grand montant à 320 ×2), m3 (sémantique désactivée), m5 (durcir le garde-fou).
