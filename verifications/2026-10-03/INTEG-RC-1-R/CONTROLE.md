# INTEG-RC-1-R : contrôle adverse du rapport (03/10/2026)

Contrôleur adverse pour la session orchestratrice 00166a22. Le but était de réfuter le rapport de INTEG-RC-1-R
(commits pilotage `a792eda`, `60df6c5`). Aucun code modifié, rien écrit au tableau.
Worktree de contrôle à moi : `D:\RA_TUTEUR\r-integ-ctrl`, détaché sur `4a4fbe7` ; `D:\RA_TUTEUR\r-integ` n'a pas été touché.

## Verdict du contrôle

**Le verdict « accepté, aucun bloquant » tient.** Les affirmations importantes ont été revérifiées et tiennent.
Il y a **une affirmation fausse**, le mineur m4. Elle ne change pas le verdict. S'y ajoutent deux imprécisions
de méthode et une omission partielle de l'énoncé, que j'ai couverte moi-même.

## Revérifié et confirmé

| Affirmation | Preuve du contrôle |
|---|---|
| Commits de preuve poussés | `git log origin/pilotage/tuteur-v1` : `a792edac` et `60df6c56` présents ; les 44 fichiers du dossier sont dans `origin/pilotage/tuteur-v1` (`git ls-tree`). |
| Chaîne et seconds parents | `git log -1 --format=%p` : 0c0b739 = 98e3f9d + 058c525 ; f4c917c = 0c0b739 + 39a702a ; 328a737 = f4c917c + 5629693 ; 760802c = 328a737 + 7885b35 ; 4a4fbe7 = 760802c. `git ls-remote` : les 4 seconds parents sont bien les pointes actuelles des branches gelées. |
| 4a4fbe7 était la pointe de corrections | Aujourd'hui `origin/corrections/revue-directeur-2026-10` = `7c61287`. 4a4fbe7 en est un ancêtre (`merge-base --is-ancestor`). Les 8 commits venus après sont BENTO-1b et GALERIE-BENTO-2, hors du périmètre de la revue. |
| i18n en union stricte | Script indépendant (union des clés aplaties, retrait voulu seulement si la clé est dans la base et absente d'un parent) : **pertes 0, nées 0** dans les 4 fusions, en fr comme en ar. 4a4fbe7 face à 760802c : 0 clé retirée, 0 ajoutée. 0 clé ar sans clé fr. |
| Aucune couleur ajoutée (K-37) | 0 ligne `+` avec `Color(0x`, `Colors.`, `fromARGB`, `fromRGBO`, `withOpacity`, `withValues(alpha`, `Color.lerp` ou `ColorScheme`, dans les 4 remerge-diff et dans `correction_4a4fbe7.diff`. `git diff --stat 98e3f9d 4a4fbe7 -- lib/core/theme pubspec.yaml supabase .github vercel.json` est vide. Aucune branche n'avait touché `lib/core/theme` depuis sa base de fusion. |
| Skips | `git diff 98e3f9d 4a4fbe7 -- test` : 21 lignes `+…skip`, toutes `sautSansCapture` dans des groupes « Capture : … », 0 retirée ; 0 skip dans les remerge-diff. |
| `dart analyze` | Relancé sous verrou (09:05) : **No issues found!** |
| `verifier_revue` | Relancé : **1664 violation(s)**, même ventilation que `03_verifier_revue.log`. |
| Tests | Relancés sous verrou, sans `CAPTURE_DIR` : `flutter test test/accessibilite test/core/accessibilite test/features/salle_seance test/core/widgets/commande_salle_test.dart test/coran test/widgets/nav_shell_accessibilite_test.dart`. Résultat : **+915 ~361, All tests passed!**, 0 `[E]`, et les 361 sautés sont tous « CAPTURE_DIR absent ». NAV-FLECHES-1 (`coran_ma7_test.dart`) est vert. Verrou libéré après 740 s, code 0. |
| Hunks cités | `0c0b739:cahier_page.dart` l. 1084-1098 : `travailMaison(eleve:)`, et la suggestion seulement `if (_suggestionDevoir)` avec la clé `cahier-devoir-suggestion`. `controle_page.dart:51`, `:118` et `demo_controleur_page.dart:757`, `:767` : `ValueChanged<String>`. `_DockEtroit` : 0 occurrence dans `lib`. `recharge_foyer.dart` : `Ecart.vMd` (5629693 l. 565) devient `Ecart.vLg` (328a737 l. 566) ; le fichier est absent de f4c917c. |
| Décisions déléguées | `DECISIONS_DELEGUEES_2026-10-02.md:35` dit « Non, le Coran reste », et `:36` dit « le mot d'état reste ». D1 est donc fondé. `REVUE-DIRECTEUR-2026-10.md` (4a4fbe7) porte bien la « Contradiction ouverte » et les options (a) et (b). |
| Captures | J'ai ouvert moi-même 7 PNG : salle MA Mariam (clair) et Idriss (sombre) ; lecteur mushaf page 1 et page 6, verset agrandi, masque ; entrée « Le Coran ». La description du rapport est exacte : titre entier, dock de 4 disques sans mot d'état, Coran actif dans une barre de 4 onglets, page 1 sans flèche « précédente » avec ☰ et → à la même place. `09_captures.log` : `EXCEPTION … null` partout, `TOOLTIP precedente=0` en page 1. |
| Tests renommés dans 760802c | 4 noms de tests des corrections ont disparu (navigation_ma2 ×2, navigation_test, nav_shell_accessibilite). Ils sont remplacés par leurs équivalents « 4 destinations ». C'est la suite cohérente de la décision « le Coran reste », pas une perte de couverture. |

## Écarts trouvés

1. **m4 est faux (mineur).** Le rapport écrit que, dans `guidee_fin_test.dart`, `find.text('Micro ouvert')` « est devenu » `_bouton('Micro ouvert')`, et que le test « ne prouve plus que le mot d'état est affiché ». Dans 4a4fbe7, la fusion a gardé les **deux** côtés : `test/features/salle_seance/guidee_fin_test.dart:207` `expect(find.text('Micro ouvert'), findsOneWidget);` et `:211` `expect(_bouton('Micro ouvert'), findsOneWidget);`. Dans le remerge-diff, les trois `find.text` sont des lignes de contexte (sans `-`). Le test prouve donc toujours le mot affiché à l'échelle de texte par défaut. Ce défaut mineur proposé n'existe pas.
2. **Comparaison `verifier_revue` : la première violation de chaque journal n'est pas lue (mineur, sans effet sur la conclusion).** `compare_verifier.py.txt` ne lit pas la ligne 1, préfixée par « Running build hooks... ». C'est la source de l'écart 1664 (`03`) contre 1663 (`07`). La ligne perdue, `commun.etats.chargementProlonge.titre`, est aussi la première ligne des 5 journaux `10_*`. « 0 violation née de l'intégration » reste donc vrai.
3. **Énoncé, point 1 : fichiers fusionnés sans conflit non cités (mineur).** `git show --remerge-diff` ne montre que les conflits et les changements écrits dans la fusion. L'énoncé nommait `salle_page`, `salle_seance`, `action_principale` et `etat_systeme`. Le rapport ne les cite pas, alors que des fichiers modifiés des deux côtés ont été fusionnés automatiquement : `salle_page`, `app_router` (f4c917c) ; `action_principale`, `app_icons`, `salle_seance`, `ma_classe_adulte_page` (328a737) ; `salle_seance`, `chrome_seance`, `section_header`, `texte_sans_coupure`, `suivi_eleve_page` (760802c). J'ai contrôlé moi-même trois d'entre eux par sondage. `salle_page` : diff P1→fusion = diff base→P2 (25 lignes), et la correction CT-R B1 `adresseCompteRendu(..., widget.seanceId)` est gardée. `action_principale` : `RangeeActions` vient d'EA, et `etat_systeme.dart:391` l'utilise. L'analyse à 0 et les tests verts couvrent le reste ; je n'ai pas relu les autres un par un.
4. **Usage du verrou non démontrable par les journaux (observation).** Aucune ligne « VERROU » dans les `*.log` du dossier, et `job2.ps1.txt` ne prend pas le mutex lui-même. Il a pu être lancé par le verrou, mais la preuve n'est pas au dossier.
5. **Nom des captures « derniere » (observation).** « derniere » désigne la dernière page du corpus de référence (`reference.pages.last`, page 6 sur 604), pas la borne 604. La disparition de la flèche « suivante » à la dernière page n'est donc prouvée par aucune capture : seul le test NAV-FLECHES-1 la couvre (premier cas) et le rapport ne la revendique pas.

## Non lancé par ce contrôle

- La suite complète (test/core, test/teaching_core, test/features entiers) : non lancée, comme dans le rapport. Les composants partagés `page_shell`, `nav_shell` et `setting_row` ont pourtant été fusionnés (LECONS §13).
- `test/video/vue_salle_test.dart`, `test/features/controleur/*salle*` et `salle_test`/`salle_200_test` : non relancés ici. Ils sont dans le journal `04` de l'auteur.
- Slang : non régénéré ici. Je m'appuie sur `11_slang_recontrole.log` (identique=True pour les 3 fichiers), et l'union i18n a été contrôlée de façon indépendante.

## Étape proposée

- Aucune pour m1 à m3 et D1, déjà portés par le rapport (ETATS-MA-1 après arbitrage).
- Pour l'orchestratrice : ne pas reprendre m4 au tableau ; il n'existe pas.
