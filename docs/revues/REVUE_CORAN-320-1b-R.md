<!-- verdict : ACCEPTEE_AVEC_RESERVES -->
# Relecture adverse de CORAN-320-1b (branche corrections/c2-coran-320-b, c6f707aa)

J'ai travaillé dans un worktree jetable, détaché sur `origin/corrections/c2-coran-320-b` et retiré à la fin. Je n'ai rien poussé ni modifié. La base de comparaison est 5a52ff30.

## Verdict : ACCEPTÉE AVEC RÉSERVES

Les cinq réserves de REVUE_CORAN-320-1-R sont traitées, et c'est prouvé par mutations, par une sonde indépendante et par les captures. Le rendu des versets est inchangé. Je ne trouve aucun défaut majeur. Il reste trois réserves : la rupture de seuil s'est déplacée à 1,29 ; la part des versets annoncée en focus est surévaluée ; les replis décidés par délégation doivent encore être validés.

## Ce que le diff modifie dans `lib/` (vérifié)

Trois fichiers seulement :
- `lib/features/tc_mushaf/mushaf_page.dart` : en-tête compact, juz, réglage de taille replié, commandes, seuil `>=`.
- `lib/features/tc_mushaf/vue_focus_classe.dart` : état vide `_SansPlage`.
- `lib/core/widgets/barre_precedent_suivant.dart` : sens propre de la position.

Fichiers non touchés :
- `vue_page_mushaf.dart`, `vue_verset_agrandi.dart` ;
- `ColonneVersetsReflow`, `BlocVerset` ;
- `core/coran`, `core/tc_coran` ;
- thème, i18n, `pubspec.yaml`, `supabase/`, `.github/`.

Aucun libellé n'est ajouté. Dans `VueFocusClasse`, le seul changement est un `LayoutBuilder` et la bande de l'état vide. L'appel `ColonneVersetsReflow(versets, zoom, sections)` est identique.

## Preuves rejouées

| Contrôle | Résultat |
|---|---|
| `dart analyze --fatal-infos` | 0 problème |
| `test/features/tc_mushaf` et `barre_precedent_suivant_test` | +48, 0 échec |
| tc_mushaf, teaching_core, accueil_adulte, core, widgets, salle_seance, bienvenue, router | +3361 ~571. Le seul « -1 » vient d'un dossier inexistant que j'ai passé par erreur ; aucun test n'échoue. |
| Suites salle et enseignant (`salle_enseignant_test`, `revue_cl_r_tests_test`, `etats_agrandir_test`) avec tc_mushaf | +67, 0 échec |
| `verifier_revue` | 1533 avant comme après, aucune violation dans les fichiers touchés |
| `verifier_jetons` | 37 avant comme après |

## Mutations (toutes tuées)

1. Seuil remis à `>` : 3 échecs.
2. Barre : sens de l'interface au lieu du sens propre de la position : 2 échecs. Avec un sens gauche à droite forcé, le test « lettres arabes » échoue (1 échec).
3. `vue_focus_classe.dart` ramené à 5a52ff30 : 3 échecs.
4. Juz retiré de l'en-tête compact : 8 échecs.
5. Réglage de taille remis au-dessus de la pagination compacte : 13 échecs.
6. Isolement de « 100 % » retiré : 1 échec.

## Contre-épreuve indépendante (rendu des versets)

J'ai écrit ma propre sonde sur la route réelle `/eleve/coran`, puis je l'ai exécutée sur `lib/` à 5a52ff30 et sur la tête de branche :
- 3 rendus ;
- 320x568 à x1, x1,29, x1,3, x1,31 et x2 (LTR et RTL), 390x844 x2, 1440x900 x1.

Les signatures des paramètres reçus par `ColonneVersetsReflow` et `BlocVerset` sont identiques dans les 24 cas : versets, zoom, échelle, sens, largeur, taille, interligne, rosace. Les constantes du test du rédacteur sont donc authentiques. En page du mushaf, la seule différence est la taille du cadre `VuePageMushaf` à x1,3 (51 puis 305 px). C'est l'effet attendu du compactage de l'habillage, et le rendu lui-même ne change pas.

## Chiffres mesurés (part de la hauteur, 320x568)

| Cas | Avant | Après |
|---|---|---|
| Lecture agrandie x2 (LTR et RTL) | 32 % | 53 % |
| Focus x2 | débordement de 29 px, versets 0 % | 0 débordement, zone 53 % dont versets 35 % |
| Focus x1 | débordement de 29 px | 0 |
| Focus x1,3 | débordement de 98 px | 0 |
| Lecture agrandie à x1,3 exactement | 0 % | 54 % |
| Page du mushaf à x1,3 exactement | 9 % | 54 % |
| Lecture agrandie à 390x844 x2 | 53 % | 67 % |
| Focus à 390x844 x2 (versets réels) | 32 % | 58 % |

Dans tous les cas, la pagination tient sur une rangée de 48 px, au lieu de 168 px avant. Le juz est présent dans l'en-tête compact de la lecture agrandie et du focus. Le message du focus n'est plus recouvert : le bas de la zone touche le haut de l'attribution.

## Captures ouvertes

- **320x568 x2, lecture agrandie** : avant ; après en clair, avec le panneau déplié, en RTL et en sombre. La pagination tient sur une ligne et l'en-tête affiche « Al-Faatiha . Juz 1 ». Le panneau déplié montre le choix du rendu, puis « Réduire le texte 100 % » et « Agrandir le texte ». Aucun mot coupé.
- **320x568, focus** : x2 avant (texte agrandi recouvert par l'attribution, bande de débordement) ; après en clair, en RTL et à x1,3. Le message est lisible et il n'y a plus de débordement.
- **Page du mushaf, 320x568** : x1,3 après.
- **390x844 x2 sombre RTL** : avant, « 604 / 1 » et « % 100 » ; après, « 1 / 604 ». Lecture agrandie et focus vérifiés. Les flèches gardent leur miroir.
- **1440, clair et sombre, dans les deux rendus** : la différence de pixels est bornée à la rangée « 100 % » (680-1017 x 736-752). Les versets sont identiques au pixel près.
- **Interface guidée** : sans objet, ces écrans ne l'emploient pas.

## Autres appelants de BarrePrecedentSuivant

- **Salle** (`barre_support.dart`) et **enseignant** (`panneau_enseignant.dart`) : la position vient de `t.salle.seance.page`, soit « {page} / {pages} », sans traduction arabe. Elle passe désormais de gauche à droite, ce qui corrige le même défaut. Je n'ai pas modifié leurs fichiers, et leurs suites passent.
- **Bienvenue** : la position était déjà isolée, le rendu est inchangé.
- **Galerie** : couverte par `catalogue_galerie_test`, qui fait partie de la suite `test/widgets`.

## Réserves

1. **Le seuil n'est pas continu (gravité moyenne).** À x1,29, les versets ont 0 % de la hauteur en lecture agrandie et en focus, et 9 % en mushaf. La rupture a seulement reculé d'un centième. Le `>=` était explicitement admis par la demande, mais les échelles intermédiaires de iOS et Android (1,15 ; 1,24) restent touchées. La fiche ne le mentionne pas. Prochaine étape suggérée : un compactage progressif, ou un seuil plus bas.
2. **La part des versets en focus est surévaluée (gravité mineure).** Le test et la fiche mesurent toute `VueFocusClasse`, bande du message vide comprise. Les versets réels occupent 35 % à 320 x2. La demande (2), qui portait sur le débordement et le recouvrement, est remplie ; c'est le chiffre annoncé qui est inexact.
3. **Choix décidés par délégation le 09/10, à valider par le directeur.** Ils sont inscrits dans la fiche : le réglage de taille est replié derrière « Mode de lecture » (il devient moins visible à texte agrandi) ; le message du focus est plafonné à 130 % et borné au tiers de la zone ; le seuil passe par `>=` ; le juz est placé sur la ligne de la sourate.

Le rédacteur a déclaré lui-même deux défauts antérieurs, hors périmètre : à x1 sur 320x568, les versets n'ont que 6 % de la hauteur, et la barre resserrée déborde de 24 px quand on la monte seule.

Statut : présent dans le code, testé localement (le rédacteur et le relecteur). Ni testé sur staging, ni déployé.
