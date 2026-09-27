# Rapport de la répétition de fusion — 27/09/2026

Étape B du plan directeur du 27/09 (dépôt `C-plan-directeur-2026-09-27` du tableau).
Étape C (garde-fous) à la fin. Session cloud du 27/09 au soir.

Branche d'essai `integration/essai-fusion`, poussée avec l'accord écrit du directeur
(question 1 du §5 du plan, réponse « oui » le 27/09). **Elle n'est jamais fusionnée
dans `main` sans lui.** Aucune branche de poste (`ui/*`, `pilotage/*`) n'a été touchée,
ni `main`, `supabase/`, `.github/`, `pubspec.yaml`, le thème ou le Coran.

## 0. Où

- `integration/essai-fusion` @ 55a5235 : les 8 fusions, rien d'autre.
- `claude/confident-mayer-m2fqsl` : la même chose, plus l'outil de l'étape C
  (`tool/verifier_revue.dart`, `tool/revue_socle.txt`) et ce rapport. PR brouillon vers
  `integration/essai-fusion` : elle ne vise ni `main` ni une branche de poste, et ne
  déclenche aucun déploiement.
- Feuille de décisions du directeur (étape A) : https://claude.ai/artifact/5hqpCULEK4Hwchu7D4BVtg

## 1. En une phrase

Les 8 branches s'assemblent : **20 fichiers en conflit (dont 7 fichiers générés
régénérés par slang), tous résolus sans perdre de comportement**. Chaque étape de fusion compile (`dart analyze --fatal-infos` : 0) et
la suite complète passe à chaque étape (tableau §3). Ce qui reste à faire pour une
vraie fusion, ce n'est pas l'assemblage, c'est la dette que les vagues ont accumulée
sans que rien ne la mesure : 36 violations de jetons, 1377 libellés sans source dans le
dépôt, 23 boutons grisés, 10 messages réseau qui affirment ce que l'app ne sait pas.

## 2. Méthode

- Worktree depuis `origin/main` (4a7aa2b), `git merge --no-ff`, jamais de rebase, dans
  l'ordre du plan.
- Après chaque fusion : marqueurs de conflit, `flutter pub get`, `dart run slang`,
  `dart run build_runner build --delete-conflicting-outputs`, `dart analyze --fatal-infos`,
  `flutter test --no-pub -r failures-only`, `dart run tool/verifier_jetons.dart`.
  Flutter 3.47.5, `CAPTURE_DIR` jamais défini.
- Les fichiers générés en conflit (`strings*.g.dart`) : un côté pris, puis régénérés par
  slang. Jamais corrigés à la main.
- `dart format` lancé seulement sur les fichiers résolus à la main (règle 6 du plan).

## 3. État mesuré après chaque fusion

| # | Branche fusionnée | Pointe | Fichiers en conflit | analyze | Suite (réussis / ignorés / échecs) | Jetons |
| :- | :- | :- | :-: | :-: | :- | :-: |
| 0 | `main` (base) | 4a7aa2b | — | 0 | (non relancée) | 0 |
| 1 | `ui/tuteur-v1` | 73f12c8 | 0 | 0 | 2725 / 572 / 0 | 10 |
| 2 | `ui/classe-v1` | d44710a | 0 | 0 | 3283 / 978 / 0 | 16 |
| 3 | `ui/enseignant-v1` | 1108a4a | 0 | 0 | 3366 / 1391 / 0 | 21 |
| 4 | `ui/admin-v1` | a8dfcb3 | 3 | 0 | 3620 / 1711 / 0 | 34 |
| 5 | `ui/controleur-v1` | 674bdad | 1 | 0 | 3624 / 1831 / 0 | 46 |
| 6 | `claude/great-curie-50duvi` (PR n°4) | fe4bdd0 | 2 | 0 | 3738 / 1851 / 0 | 34 |
| 7 | `ui/accessibilite-v1` | e8d0dfc | 6 | 0 | 3790 / 1919 / 0 | 35 |
| 8 | `ui/eleves-adultes-v1` | f02444f | 8 | 0 | 3861 / 2135 / 0 | 36 |

Les jetons baissent de 46 à 34 à la fusion 6 : la PR n°4 apporte le correctif
`verifier_jetons` de 1480a91 (`FractionallySizedBox` n'est plus pris pour un
`SizedBox`) et les boutons CT-6 passés par `ActionPrincipale`.

Pour comparaison, chaque branche seule (outil de sa propre branche) : main 0,
tuteur 10, classe 16, enseignant 21, admin 29, contrôleur 33, PR n°4 27,
accessibilité 22, élèves adultes 22.

## 4. Conflits et résolutions

**Le plan `13_fusion/PLAN_FUSION_ADMIN_ENSEIGNANT.md` annonçait 7 conflits et 2 erreurs
cachées pour Admin + Enseignant.** Il datait des pointes 2fac423 et 0b01297. Sur les
pointes du 27/09, il en reste 3 : AD-RC avait déjà unifié `pressable`,
`action_principale`, `lien_fleche` et `etat_systeme`, et l'icône `reduire` en double est
devenue `ajusterEcran` côté admin. La seconde erreur cachée (les arguments nommés en
double dans `Pressable.selon` de `groupe_reglages`) est bien apparue dans le bloc en
conflit ; elle est corrigée par la résolution.

| Fusion | Fichier | Nature | Résolution et pourquoi |
| :- | :- | :- | :- |
| 4 admin | `lib/core/widgets/groupe_reglages.dart` | Les deux côtés ajoutent des options à `LigneRubrique` : `marque`, `focusNode`, `libelleSemantique` (enseignant EN-3/EN-12) ; `pastille`, `selectionnee`, `cochee`, `autofocus`, `focusNode`, `libelleSemantique`, placement mesuré `_RangeeMesuree` (admin AD-5/AD-6/HL-A-3) | Union, un seul `focusNode` et un seul `libelleSemantique`. `_RangeeMesuree` (admin) pour les lignes à contrôle, `_rangee` (enseignant, marque en fin ou dessous) pour les autres ; le chevron reste masqué sur une case (`cochee`). L'assert « icône ou meneur » tombe (les tests admin l'exigent). Choix provisoire du plan §5 points 3 et 4 |
| 4 admin | `lib/features/demo/repere_demonstration.dart` | Typographie du ruban Démonstration : 10/w700 (enseignant) contre 9/w600, interlettrage 0 (admin) | Version admin, choix provisoire du plan §5 point 6 (le mot tient en entier). Captures enseignant et Classe légèrement changées |
| 4, 5, 6, 7, 8 | `lib/core/i18n/strings.g.dart`, `strings_fr.g.dart` | Fichiers générés | Un côté pris, régénérés par `dart run slang`. `fr.i18n.json` et `ar.i18n.json` : aucun doublon de clé (vérifié) |
| 7 accessibilité | `routes.dart`, `app_router.dart`, `redirection.dart` | Chaque vague ajoute sa route `/demo/...` au même endroit | Union : `/demo/controleur` et `/demo/accessibilite` |
| 7 accessibilité | `lib/core/widgets/nav_shell.dart` | Doc de `destinationsPour` réécrite des deux côtés (C13 contrôleur à 4 destinations ; MA-2 élève à 4 destinations dans les deux présentations) | Doc MA-2 gardée ; la phrase « le contrôleur n'a pas de coquille », périmée depuis C13, est corrigée. Le code n'était pas en conflit |
| 7 accessibilité | `lib/features/salle/salle_page.dart` | `_Commande.encreDuRegistre` ajouté **des deux côtés** (CT-3 pour le contrôleur, MA-5 pour l'élève en Mode Accessibilité) | Un seul paramètre, une seule doc (CT-3 + MA-5), style par `_encreSalle` (MA-5), qui fait la même chose |
| 8 adultes | `routes.dart`, `app_router.dart`, `redirection.dart` | Même point chaud | Union : contrôleur, accessibilité, adulte |
| 8 adultes | `lib/features/demo/mode_demonstration.dart` | `surchargesDemoTuteur` : `dossiers` et `titulaire` (AD-10) contre `eleves` (EA-1b) | Les trois paramètres ; un titulaire de dossier garde un foyer vide, sinon `eleves ?? DonneesDemo.eleves` |
| 8 adultes | `lib/features/tc_espace_groupe/espace_groupe_page.dart` | EA-2 (K-51) a refait la page en `LecteurGroupe` / `LectureGroupe` / `ColonnesParRangees` pour la partager avec l'accueil adulte ; MA-4 a ajouté `titre`, `tutoiement`, `pied`, `enPile` sur l'ancienne structure | Structure EA-2 gardée, options MA-4 reportées dessus (`carte(tutoiement:)`, `identiteEtCarte(tutoiement:, enPile:)`, `IdentiteGroupe(enPile:)`). Les deux comportements restent |
| 8 adultes | `lib/features/tc_espace_groupe/emplacements_groupe.dart` | En-tête Bibliothèque à grand texte corrigé deux fois : MA-4 (pile dès 200 %, `FittedBox`) et EA-2 (pile dès `seuilTexteColonne` = 1,5) | Seuil EA-2 (plus tôt), avec le `FittedBox` MA-4 pour qu'un mot plus large que l'écran se resserre au lieu d'être coupé, et l'écart de 8 de MA-4 avant le lien |

**Aucune résolution n'a fait perdre un comportement** : il n'y a donc pas de nouvelle
question au directeur issue de l'assemblage. Les 8 choix d'apparence déjà écrits dans
`13_fusion` §5 sont repris dans la feuille de décisions (question F1).

## 5. Doublons de composants entre vagues

Aucune classe publique n'est déclarée deux fois. Les doublons sont de fonction :

1. **Le point chaud des démonstrations.** Chaque vague ajoute sa page (`DemoEnseignantPage`,
   `DemoControleurPage`, `DemoAccessibilitePage`, `DemoAdultePage`, plus `DemoClassePage`
   et `DemoSallePage`), sa coquille de démo, et la même ligne dans `routes.dart`,
   `app_router.dart` et `redirection.dart`. Ce sont 6 des 20 fichiers en conflit. Un registre unique
   des démonstrations (une liste de routes lue par le routeur et par la redirection)
   supprimerait ce conflit pour chaque rôle à venir.
2. **Encre du registre de la salle** : ajoutée deux fois dans `salle_page.dart` (CT-3 et
   MA-5), unifiée par la fusion. La même cause reste ouverte pour l'élève et
   l'enseignant (ligne PT-B-20260927-1ab2a969, HU-1).
3. **En-tête Bibliothèque à grand texte** : corrigé deux fois (MA-4 et EA-2), unifié par
   la fusion (ligne PT-B-20260927-ba1364f5).
4. **Mise en colonnes « deux tiers / un tiers »** : `ColonnesParRangees` et `Rangee`
   (EA-2, partagés), `ColonnesFiche`, `ColonnesSousPage` et `ColonneSousPage` (lot
   tuteur). Trois implémentations du même gabarit.
5. **Trois accueils d'élève** : `accueil_eleve_page`, `AccueilAccessibilite` (MA-3),
   `AccueilAdultePage` (EA-2). L'accueil adulte réutilise `LectureGroupe` ; l'accueil
   accessibilité reçoit un `GroupHomeVM` déjà résolu, d'où ses états manquants (revue MA-3).
6. **Deux écrans de fin de séance** : `ApresSeanceAccessibilite` (MA-6) et
   `resultat_seance.dart` (question A7 de la feuille de décisions).
7. **Pastille et marque de `LigneRubrique`** : deux notions voisines pour la même
   `StatusPill`, deux règles de placement (question F1, point 3).
8. **Carte d'identité du compte** : `CarteIdentiteCompte` (adulte) et la carte du Compte
   tuteur, qui diverge sur « Compte validé » (ligne PT-A-20260927-fe71b248).

## 6. Écrans qui ne compilent pas ou ne passent pas

Aucun. `dart analyze --fatal-infos` rend 0 diagnostic après chacune des 8 fusions, et la
suite complète passe à chaque étape (§3). Les écrans ont été vérifiés par les tests
seulement : **aucune capture n'a été relue dans cette répétition**.

## 7. Ce qu'il reste pour une vraie fusion

1. **Les décisions du directeur** (feuille https://claude.ai/artifact/5hqpCULEK4Hwchu7D4BVtg),
   surtout D1 (BR-1) et F1 (les 8 choix d'apparence, à voir sur captures).
2. **Les captures des deux rôles touchés par la fusion 4** (plan 13_fusion §2 point 7 :
   `test/capture/ad5` à `ad11`, `coque_admin`, captures EN-4 à EN-11, CL-4/7, salle,
   préparation à 200 %), comparées aux validées. Estimation : une demi-journée.
3. **La dette mesurée, à répartir par vague** (étape C, §8) : 36 violations de jetons,
   23 boutons grisés, 10 messages réseau affirmatifs, et les libellés sans source.
4. **Les majeurs des revues du 27/09**, qui ne sont pas des problèmes de fusion mais
   partent avec elle : EA-4 (confidentialité F6/F7), CT-4 (compte rendu rattaché à la
   mission courante), CT-3 (« Son reçu » ne coupe rien, « Agrandir » agrandit
   l'enseignant, pré-vol micro du contrôleur), MA-5, MA-7, MA-3/MA-4, EA-6.
5. **Le registre des démonstrations** (§5 point 1) avant la prochaine vague, pour ne pas
   refaire les mêmes 6 conflits.

Estimation : l'assemblage lui-même tient en une journée (refaire ces 8 fusions sur les
pointes du jour, avec ce rapport). Le reste dépend des décisions et de la dette.

## 8. Étape C — garde-fous

### 8.1 Ce qui existe déjà

- Le correctif `verifier_jetons` de 1480a91 est **déjà sur la branche d'essai** : il y
  arrive avec la PR n°4 (fusion 6). Rien à reporter.
- **`Duration(` littérale en démonstration** : déjà détectée par `verifier_jetons`
  (règle `duree-litterale`, 14 des 36 violations de l'arbre fusionné). Le défaut n'est
  pas de détection mais d'application : l'outil n'est lancé par aucune CI sur les PR
  vers `ui/*`. D'où la question D2 au directeur.

### 8.2 Nouveau : `tool/verifier_revue.dart`

Un outil à part, pour ne rien changer à `verifier_jetons` :
`dart run tool/verifier_revue.dart [--regle=...] [--detail] [--corpus=dossier]`.

| Règle | Ce qu'elle voit | Pourquoi |
| :- | :- | :- |
| `libelle-sans-source` | Une clé de `fr.i18n.json` dont le texte (hors paramètres) ne se lit mot pour mot dans aucun document de `docs/` (ou d'un `--corpus`), et qui n'est pas déclarée dans `tool/libelles_sources.json` avec sa référence | « Libellés sans source » relevés sur CT-2 à CT-6, MA-3 à MA-7, EA-4 à EA-6 |
| `bouton-grise` | Un `onPress`, `onPressed` ou `onTap` de `lib/features` qui peut valoir `null` (littéral ou branche de ternaire). Un bouton coupé le temps d'un envoi déjà parti n'est pas visé | lib/CLAUDE.md : « un bouton qui ne peut pas aboutir n'est pas rendu » ; revues CT-5, EA-6, MA-7 |
| `affirmation-reseau` | Un texte d'échec qui affirme un non-envoi (« n'a pas été envoyé », « n'est pas partie ») | Revues CT-4 et EA-6 ; question D5 |

`tool/revue_socle.txt` fige l'existant de `main` (4a7aa2b) : 1082 lignes, jamais
rouvertes (décision du 26/09). **Sur `main` : aucune violation.**

### 8.3 Chiffres, avec et sans chaque contrôle

Sans les nouveaux contrôles, la seule mesure est `verifier_jetons`. Avec :

| Arbre | Jetons | Libellés sans source (docs du dépôt) | … avec documents du directeur et pilotage | Boutons grisés | Affirmations réseau |
| :- | :-: | :-: | :-: | :-: | :-: |
| `main` | 0 | 0 | 0 | 0 | 0 |
| `ui/tuteur-v1` | 10 | 749 | 466 | 4 | 4 |
| `ui/classe-v1` | 16 | 904 | 498 | 7 | 4 |
| `ui/enseignant-v1` | 21 | 1042 | 551 | 13 | 5 |
| `ui/admin-v1` | 29 | 1002 | 501 | 11 | 4 |
| `ui/controleur-v1` | 33 | 1126 | 592 | 13 | 8 |
| PR n°4 | 27 | 1139 | 602 | 14 | 8 |
| `ui/accessibilite-v1` | 22 | 1074 | 576 | 13 | 5 |
| `ui/eleves-adultes-v1` | 22 | 1150 | 625 | 18 | 7 |
| **Fusion des 8** | **36** | **1377** | **704** | **23** | **10** |

Les branches se contiennent les unes les autres (§3) : le chiffre d'une branche inclut
celui de sa base. Les vagues ont ajouté 1680 clés de texte depuis `main` (1868 → 3548).
Le « corpus » de la 4e colonne est `projet/ressources` (documents du directeur) et
`pilotage/tuteur-v1` (découpages des agents) : même avec eux, **704 libellés (42 %) ne
se lisent mot pour mot dans aucun document**. La correspondance mot pour mot est
stricte : une paraphrase compte comme sans source. C'est voulu : un libellé repris d'une
planche (image) ou d'une décision orale se déclare dans `tool/libelles_sources.json`.

Les 23 boutons grisés et les 10 affirmations de l'arbre fusionné sont listés par
`dart run tool/verifier_revue.dart --regle=bouton-grise,affirmation-reseau --detail`.

### 8.4 Proposition au directeur

Question D2 de la feuille de décisions : une CI Flutter sur les PR vers `ui/*` (analyze,
suite, `verifier_jetons`, et `verifier_revue` en avertissement d'abord), en PR brouillon
qu'il valide, puisque `.github/` lui est réservé.
