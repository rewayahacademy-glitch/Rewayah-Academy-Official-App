<!-- verdict : ACCEPTEE_AVEC_RESERVES -->
# Revue adverse de PAGESHELL-200-1e (reprise)

Branche `corrections/c2-pageshell-e`, tête 2cba5256, base 5a52ff30.

## Verdict : ACCEPTÉE AVEC RÉSERVES

Les six points demandés sont remplis, et chacun est prouvé par une mutation. Les deux autres objections de la relecture précédente (barre mobile, « ci-dessous ») sont aussi levées et prouvées. Je n'ai trouvé aucun défaut majeur. Les réserves sont mineures : documentation, défauts déjà présents sur la base, couverture de test.

Statut : **testé localement** seulement. Rien n'est testé sur staging ni déployé.

## Méthode
- Trois worktrees jetables, tous retirés à la fin : revue sur 2cba5256, mutations sur 2cba5256, base sur 5a52ff30.
- Rien n'a été poussé.
- Le diff ne touche que les fichiers autorisés : `page_shell.dart`, `admin_shell.dart`, `admin_journal/journal_page.dart`, plus tests, captures et documentation.
- Aucune zone interdite n'est touchée (supabase, .github, pubspec, thème, Coran, dart_define).
- Les 6 commits se terminent exactement par les deux lignes d'attribution demandées. Aucun autre identifiant de modèle n'apparaît.

## Contrôles outillés
- `dart analyze --fatal-infos` : aucun problème.
- `verifier_jetons` : 37 violations, autant que la base. Celles des fichiers touchés existaient déjà (graisse w600 dans admin_shell, dont seules les lignes ont bougé).
- `verifier_revue` : 1533, comme le déclare le rédacteur.
- Régression large relancée par moi (`--concurrency=2`), **0 échec** :

| Dossier | Réussis | Ignorés |
| :--- | :--- | :--- |
| test/widgets | 435 | 0 |
| test/core | 736 | 0 |
| test/router | 300 | 7 |
| test/accessibilite | 362 | 0 |
| test/features | 3037 | 2166 |

- Fichier du lot plus `test/features/alertes` : 181 réussis.

## Mutations (correction annulée, les tests doivent échouer)

| # | Mutation | Résultat |
|---|---|---|
| M1 | La tête défile dès qu'un bandeau est posé (`teteDefile \|\| sousBandeau`) | 78 échecs |
| M2 | Respiration de l'Interface guidée rétablie sous bandeau | 8 échecs |
| M3 | Report du retour à la tête fixe non borné | 1 échec (animation infinie) |
| M4 | Échelle compacte HIER-1 retirée du titre simple | 8 échecs |
| M5 | Pastille et phrase toujours côte à côte (ancienne `Row`) | 8 échecs |
| M6 | `nomsComposesEntiers: false` sur la phrase de la chaîne | 8 échecs |
| M7 | Écarts de la barre mobile jamais retirés | 6 échecs |
| M8 | Mode « noyau fixe » supprimé (repli en défilement global) | 14 échecs |
| M9 | Mesure du noyau neutralisée | 3 échecs |

Les tests de géométrie (1 bis) ne sont pas creux. Une sonde montre une vraie course de défilement (`maxScrollExtent` de 18 à 1262 px) dans 34 cas RTL sur 41. Les autres cas tiennent dans la vue, et il n'y a rien à faire défiler.

## Sonde indépendante : Journal à contenu sous l'alerte
Montage :
- vraie `AdminShell` avec un bandeau de 96 px, puis la même chose sans bandeau ;
- `JournalPage` avec 40 entrées ;
- tailles 320x640, 390x684, 390x844, 800x600, 1024x768, 1440x500 et 1440x900 ;
- texte x1 et x2, standard et Interface guidée, LTR et RTL : 224 cas.

Chaque cas défile jusqu'au bout, puis contrôle la position du titre et des onglets.

| Mesure | Après | Base |
| :--- | :--- | :--- |
| Débordements (`overflowed`) | **0** | 6 |
| Cas où la tête bouge | téléphone à 200 % seulement (exception déléguée) | aussi 800x600, 1024x768, 1440x500, 1440x900 |
| Mots coupés relevés par `verifierEcranSansMotCoupe` | 60 | 68 |

- La phrase de la chaîne (« 40 entrées relues… »), tronquée sur la base, ne l'est plus.
- Les mots coupés qui restent existaient tous déjà sur la base : voir réserve 3.

## Captures ouvertes
J'ai ouvert, en vue avant et après :
- Journal 1440x700 clair : avant, la tête a disparu au défilement ; après, titre, onglets et actions sont fixes sous l'alerte ;
- Journal 1440x900 guidée, 390x684 guidée et 800x600 sombre RTL guidée ;
- Journal 320x640 x2 en clair guidé et en sombre RTL : barre mobile entière, pastille au-dessus de la phrase ;
- Règles 1440x500 sombre et 390x844 sombre RTL ;
- Dossiers 800x600 guidée ;
- Accueil 320x640 x2 sombre RTL : titre compact, sans mot coupé.

Résultats :
- Le bandeau pousse la tête sans la recouvrir.
- Aucun débordement visible et aucun bouton grisé.
- La ponctuation RTL (« .instant ») est un artefact de capture déjà déclaré par le rédacteur.

## Points de la demande
1. **Tête fixe sous l'alerte : rempli.** Trois modes : tête fixe, noyau fixe, défilement global. Titre, onglets et actions dès 600 px restent fixes sur les gabarits compact, rail et large, en LTR et RTL, en Interface guidée. La règle « 200 % sur téléphone » est écrite « décidé par délégation le 09/10 ». Seule exception physique : Dossiers en Interface guidée à 320x640, documentée.
2. **Écart en Interface guidée : rempli.** Il fait 8 + 24 sous le bandeau ; M2 le prouve.
3. **Report borné : rempli.** Il est borné à `AppMouvement.plafond` et testé avec une animation infinie ; M3 le prouve.
4. **Titre simple : rempli.** Il passe par `EnteteCompact.echelleTitre` ; M4 le prouve.
5. **Journal : rempli.** La ligne de la chaîne ne déborde plus à 320 x2, et la vue 390x684 guidée ne déborde plus ; M5, M6, M9 et la sonde le prouvent.
6. **Régression large : rempli.** Relancée par moi : 0 échec.

## Réserves (mineures, non bloquantes)
1. `test/features/alertes/alerte1b_test.dart` (vers la ligne 269) : le commentaire invoque encore la règle « plus de la moitié », qui a été retirée. À corriger.
2. Au-delà de 130 % de texte, MA-RC B1 fait encore défiler la tête sous l'alerte sur tablette et bureau. La décision est écrite par délégation, mais 03 parle de « seule exception » puis cite MA-RC B1 : à clarifier.
3. Des troncatures existaient déjà sur la base et restent hors des 6 points. Elles sont dans le rail et le pied de la barre latérale admin (« Accueil », « Administration »), et dans le Journal à contenu à 1440x500 x2 (« kyc_documents », « À quel titre »). À inscrire dans un lot ultérieur.
4. Le Journal de démonstration est toujours en état d'erreur : les tests (1 bis) et les captures ne montrent jamais la liste à contenu. Ma sonde le compense, mais un test du lot devrait couvrir ce cas.
5. Une tête fixe ne garantit qu'une cible tactile au corps. En Interface guidée, à 800x600 sur Dossiers ou à 320x640 sur le Journal, le corps visible ne fait qu'environ 100 px. C'est conforme à la règle écrite par délégation, mais c'est peu confortable.
