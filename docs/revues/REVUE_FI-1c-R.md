# Revue croisée FI-1c-R — socle Finance de démonstration et ports

- **Objet revu** : `ui/finance-v1` @ `4cc9c472` (base `af9f408b`), 17 fichiers, +2102 lignes, aucune suppression.
- **Relecteur** : session cloud `01KyPAZg` (téléphone du directeur). Elle n'a pas écrit FI-1c (auteur : `b061fd81`, exclue).
- **Date** : 4 octobre 2026.
- **Méthode** : lecture de tout le diff ligne à ligne, comparaison au guide Finance V4 §1 (pilotage `17_finance/V/REWAYAH_FINANCE_FRONTEND_GUIDE_V4_2026-10-02.md`), contrôles relancés sur un worktree propre (Flutter 3.47.6, Dart 3.13.5), mesures faites avec un test jetable, supprimé après usage.

## Verdict

**Acceptée avec réserves.** FI-1c peut passer à « fait ». Les valeurs de la politique sont justes, l'argent est partout un entier en unités mineures avec son code ISO, les ports réels restent neutres et rien ne sort du périmètre. Les deux réserves (M1, M2) viennent des doubles de démonstration. Aucun écran ne les branche encore, donc rien n'est visible aujourd'hui. Elles doivent être corrigées **avant** qu'une étape d'écran branche ces doubles (FI-4, FI-9a, FI-11a). Je propose de les confier à FI-2, qui est en cours sur le foyer.

## Contrôles relancés (chiffres mesurés)

| Contrôle | Résultat |
| :--- | :--- |
| `dart run slang`, `build_runner build` | OK (2060 sorties) |
| `dart analyze --fatal-infos` | **0 problème** |
| `flutter test test/features/finance test/features/foyer` | **302 verts, 0 échec**, 37 ignorés |
| `flutter test test/core` | **639 / 0** |
| `flutter test test/router` | **277 / 0** |
| `flutter test test/widgets` | **230 / 0** |
| `flutter test test/features` | **2464 / 0** (2076 ignorés : captures sans `CAPTURE_DIR`) |
| 23 autres dossiers | **1699 / 0** (`test/capture` : 583 ignorés) |
| **Total, un dossier à la fois** | **5309 verts, 0 échec**, identique au chiffre de l'auteur |
| `dart run tool/verifier_jetons.dart` | 39 relevés à la tête, **39 à la base `af9f408b`, diff vide** : FI-1c n'en ajoute aucun |

## Points de la fiche, un par un

| Point demandé | Constat |
| :--- | :--- |
| Valeurs de la politique = guide §1 | ✅ 50 / 60 USD, 2 essais, rangs 1-2 sans remise, rang 3 −5, rang 4+ −7, base 4 / plafond 7, capacités 5/6/4, minimum 4, groupes 3/4, place 7 jours, marge 300/350/400 ‰, `webStripe` seul. Les exemples du guide sont tenus : 3 profils = 145 USD, 5 profils = 50+50+45+43+43 = 231 USD |
| Mariam rang 1 sans remise, aucune valeur de maquette (30 $, 2024, −5 $ sur Mariam) | ✅ Le test `finance_demo_test.dart:164` le vérifie, et rien de tel n'apparaît dans `lib/` |
| Montants entiers en unités mineures + ISO | ✅ `Montant(int mineur, String devise)`, aucun `double`. Les calculs du double (`tauxEffectif`, `_classe`) sont en entiers (`~/`) |
| Ports neutres par défaut, démonstration seulement par surcharge (K-09) | ✅ Les trois nouveaux ports rendent `CapaciteIndisponible` (FI-BR-01/02/11/12). Aucun fichier de `lib/` hors `finance_demo.dart` n'importe les doubles |
| Aucun montant ni cause dans `AccesBeneficiaire` (FI12) | ✅ Ajouts : `seancesPayantesOuvertes` (bool), `essaisUtilises`, `essaisMax` (int). Mais voir **M1** |
| Contrats non dédoublés | ✅ `PortPaiementsFoyer.finances()` et `PortRechargeFoyer.verifierMontants()/suivre()` font évoluer les contrats existants. Les 4 implémentations existantes sont complétées (démo EA, deux faux de test, `faux_capacites`) |
| Rien hors périmètre (pubspec, thème, supabase) | ✅ Diff limité à `lib/core/capacites`, `lib/core/finance`, `lib/features/demo` et `test/` |

## Réserves

### M1 — Un profil non financé est rendu comme un accès ordinaire et « Actif »

`finance_demo.dart:341-343` : quand `periode == null`, l'accès vaut `EtatAccesAffiche.sansEcheance`. La documentation de cette valeur dit : « Aucune échéance : le cas ordinaire d'un compte valide » (`port_acces_foyer.dart:9`).

Mesuré : `unARegulariser` → Ibrahim `etat=sansEcheance ouvertes=false`. Il en va de même pour `aucunPaiement` (Mariam, Ibrahim) et pour Aïcha dans `unEnEssai`.

Conséquence dès qu'un écran branche `AccesFoyerFinanceDemo` : `compte/acces_page.dart:64-69` affiche tout état autre que `expire` avec la pastille **« Actif »** au ton **succès**, et la légende « Sans date de fin ». Le tuteur verrait donc Ibrahim « Actif » alors que le guide §1.7 demande « Accès à régulariser ». `foyer/ligne_membre.dart:85` dirait « Accès sans échéance ».

Le test `finance_demo_test.dart:274` ne vérifie pas `etatAffiche`, d'où le défaut silencieux.

**Correction proposée** : rendre pour un profil payant non financé la fin de sa dernière période (par exemple 30/09), ce qui donne `expire`. Ou bien ne pas brancher ce double sur les écrans EA tant que `EtatAccesAffiche` ne connaît pas l'état « à régulariser » (question pour FI-BR-08). Ajouter une assertion sur `etatAffiche` dans le test.

### M2 — Vue globale de démonstration : marge projetée de 1,2 %

`DonneesFinanceDemo.vueGlobale()` additionne le revenu d'**un seul foyer** (3 profils, 145 USD) et la paie d'un enseignant pour **trois classes complètes** (13 sièges éligibles, 143,20 USD). Mesuré : `encaisse = revenu = 14500`, `paie = 14320`, **`marge = 12 ‰`**.

Une fois affichée (FI-11a), la démonstration montrerait au directeur une marge de 1,2 % face à une cible de 30 %. C'est un chiffre faux et alarmant, issu de deux populations qui ne se correspondent pas. Le guide §1.5 interdit d'en faire une sanction, mais le chiffre lui-même induit en erreur.

**Correction proposée** : tirer le revenu des mêmes 13 sièges que la paie, et tester que la marge en découle.

> **Rectificatif (FI-1c-CORR, même session).** J'avais d'abord écrit « autour de 30 % » et « dans la fourchette de référence ». C'était faux. Une fois le revenu et la paie tirés des mêmes sièges (9 enfants à 50 USD, 4 adultes à 60 USD, soit 690 USD, pour une paie de 143,20 USD), la marge **sur la seule paie des enseignants** vaut 792 ‰. Le 30 % du guide §1.5 est une marge *nette*, après des charges que la démonstration ne connaît pas. FI-1c-CORR ne force donc aucune fourchette : elle teste que la marge découle des mêmes sièges.

## Mineurs (portés par l'étape d'écran concernée)

- **m1** — `RecapitulatifRecharge`, rendu par la nouvelle `verifierMontants()`, garde ses montants en **chaînes déjà rédigées** (`montantPaye`, `soldeAttribue`, `total`), alors que tout le reste de FI-1c passe à `Montant`. Le commentaire du port parle d'une taxe arrêtée par le serveur, mais le récapitulatif n'a aucun champ taxe (§1.8 : le total débité doit être visible avant confirmation). → FI-7.
- **m2** — Le garde-fou `finance_demo_test.dart:447` ne cherche que des littéraux en unités mineures (`5000`, `4500`…). Un écran qui écrirait `usd(50)`, `50 USD` ou `Montant(50 * 100…)` passerait. → durcir à l'occasion de FI-3a (composant d'argent).
- **m3** — `unARegulariser` : Ibrahim n'est pas financé, mais il compte encore au rang 2, donc Aïcha garde sa remise de rang 3. Le guide ne tranche pas si un membre « à régulariser » reste « membre payant ». À poser au directeur avec FI-2 si l'écran le montre.
- **m4** — `unARegulariser` : Ibrahim, dont octobre n'est pas financé, a quand même un `prochainDebit` le 1er novembre à 50 USD. `paiementsDuMois` vaut 2 paiements de 50 USD pour trois mois financés à 145 USD. Ce sont des incohérences de démonstration sans effet de calcul.
- **m5** — Les revenus de démonstration ne couvrent pas encore les jeux du lot F6 du guide : essai dans la séance, financé absent, remplacement, aide Internet oui/non. L'auteur le signale (`allocationInternet` nulle). → FI-10.

## Suite par dossiers (un dossier à la fois, jamais deux suites en même temps)

```
test/core 639 · test/router 277 · test/widgets 230 · test/features 2464 (~2076)
test/accessibilite 314 · test/teaching_core 912 (~55) · test/theme 70 · test/video 43
test/parcours 44 · test/capacites 37 · test/tool 32 · test/coran 25 · test/seance_famille 25
test/planning 23 · test/presence 20 · test/tc_observation 19 · test/agent 18 · test/foyer 18
test/suivi 16 · test/priere 15 · test/mouvement 13 · test/appairage 12 · test/cache 11
test/config 11 · test/observabilite 10 · test/i18n 7 · test/icons 4 · test/capture 0 (~583)
Total : 5309 verts, 0 échec.
```

## Suite : FI-1c-CORR

La correction de M1 et M2 est livrée en patch, `docs/revues/FI-1c-CORR.patch`, sur cette branche. Elle n'est **pas** poussée sur `ui/finance-v1`, faute d'accord du directeur pour pousser sur la branche d'un rôle. Pour l'appliquer depuis `ui/finance-v1` :

```
git fetch origin claude/collaborative-task-tracking-r47ieu
git show origin/claude/collaborative-task-tracking-r47ieu:docs/revues/FI-1c-CORR.patch | git am
```

Le patch touche deux fichiers : `lib/features/demo/finance_demo.dart` et `test/features/finance/finance_demo_test.dart`. Il a été construit sur `f58645d1`.
