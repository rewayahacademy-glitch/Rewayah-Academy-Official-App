<!-- verdict : REFUSEE -->
**Verdict : REFUSÉE.** Le point (1), qui était la réserve MOYENNE, n'est pas rempli sur le Journal, une page du périmètre de l'étape. Les points (2) à (6) sont faits et prouvés.

Statut du lot : testé localement seulement. Rien n'est testé sur staging ni déployé.

# Revue adverse PAGESHELL-200-1e

- Branche : `corrections/c2-pageshell-e`, tête `6f9a9616`, base `5a52ff30`.
- La branche contient bien `origin/corrections/revue-directeur-2026-10`.
- Les trois commits se terminent exactement par les deux lignes d'attribution demandées.
- Zones interdites : aucune n'est touchée (supabase, .github, pubspec, thème, Coran, dart_define).
- Je n'ai rien poussé. Les deux worktrees de revue (`rv-PAGESHELL-200-1e-17` et `rv17-mut`) sont retirés.

## Contrôles

| Contrôle | Résultat |
|---|---|
| `dart analyze --fatal-infos` | aucun problème |
| `verifier_jetons` | 37, égal à la base `5a52ff30` (mesuré par moi) |
| `verifier_revue` | 1533, égal à la base (mesuré par moi) |
| `page_shell_200_1e_test.dart` | 38 réussis |
| test/core | +736, tout passe |
| test/router | +300 (~7 sautés), tout passe |
| test/accessibilite | +362, tout passe |
| test/widgets | +337, tout passe |
| test/features | +3037 (~2166 sautés), tout passe |

Toutes les suites ont tourné avec `--concurrency=2`.

## Mutations (correction annulée, les tests doivent échouer)

| Mutation | Résultat |
|---|---|
| M1 : `sousBandeau` remis dans `teteDefilante` (la tête défile sous le bandeau) | échecs dans le groupe (1) |
| M2 : respiration de 64 rétablie sous le bandeau | échecs dans le groupe (2) |
| M3 : report de `_revenirTeteFixe` non borné | le cas (3) échoue |
| M4 : échelle compacte du titre simple retirée | échecs dans le groupe (4) |
| M5 : bandeau de la chaîne toujours en `Row` | les cas (5) à 320 x2 échouent |
| M6 : `_teteHaute` toujours faux | le cas Journal 390x684 guidée échoue |
| M7 : `sousBandeau: false` dans AdminShell | les cas (2) échouent |

Chaque correctif est donc bien protégé, mais seulement sur les géométries que les tests mesurent.

## Défaut majeur : la tête du Journal défile encore sous l'alerte

J'ai écrit une sonde sur la vraie coque admin (démonstration, alerte ouverte). Elle compare le rectangle d'`EntetePage` et celui de `BasculeTheme` avant et après avoir défilé jusqu'au bout.

Sur le **Journal**, la tête défile avec la page et les actions Recherche, thème, cloche et compte sortent de la vue dans tous ces cas :
- 800x600, standard et Interface guidée, LTR et RTL ;
- 1024x768, LTR et RTL ;
- 1440x700 et 1440x500 ;
- 1440x900 en Interface guidée.

C'est exactement le comportement de la base : rien n'a changé pour ces cas.

Je l'ai vérifié sur deux captures que j'ai produites et ouvertes : Journal 1440x700 clair et 1024x768 sombre RTL, défilées. Il ne reste à l'écran que le bandeau, puis l'état d'erreur.
- Le corps est court. Pourtant le défilement global fait sortir toute la tête.
- C'est précisément la réserve d'ALERTE-1b (« à 1440, après défilement, Recherche, thème, cloche et compte sortent de la vue »).

**Cause.** Le rédacteur a ajouté une règle : la tête ne reste fixe que si elle laisse au corps au moins la moitié de la place restante (`_teteHaute`, `page_shell.dart:442-464`).
- Le directeur n'avait délégué qu'une exception : 200 % sur téléphone.
- La tête du Journal (onglets, carte de la chaîne, filtres) dépasse cette moitié dès 1440x700.
- La fiche ne le dit pas : elle cite seulement « une fenêtre de bureau de 600 px de haut ».

**Pourquoi les tests ne le voient pas.** Le test livré mesure une page synthétique avec des onglets de 48 px. Les captures ne montrent pas le Journal sur rail ou large une fois défilé.

**Même constat ailleurs.** Règles et Dossiers à 800x600 en Interface guidée : la tête défile et les actions sortent de la vue.

**Ce qui progresse.**
- Règles : la tête est fixe à 800x600, 320x640 et 390x684 en taille normale.
- Règles et Dossiers : la tête est fixe à 390x844 en Interface guidée.

**Piste de correction.** Garder fixe au minimum la ligne titre + actions (et les onglets), quitte à faire défiler la carte de la chaîne et les filtres du Journal. Le Journal doit être testé sur ses vraies données, en rail et en large, avec l'alerte ouverte.

## Points vérifiés et conformes

**(2) Écart en Interface guidée.** L'écart entre le bandeau et le titre passe de 72 à 32 px (8 + 24) sur tous les cas sondés. Sans bandeau, la respiration de 64 reste.

**(3) Report borné.** Le report est limité à `AppMouvement.plafond`. Le test avec un `CircularProgressIndicator` sans fin échoue bien sans la borne.

**(4) Titre simple.** Il suit `EnteteCompact.echelleTitre` à texte agrandi, et le test contrôle qu'aucun mot n'est coupé.

**(5) Journal.**
- La rangée de la chaîne passe en pile à 320 x2 et ne déborde plus de 17 px. La sonde le confirme sur la base comme sur la branche, en LTR et en RTL.
- J'ai sondé `BandeauChaineJournal` seul à 320, 358, 390 et 1024 px, texte x1, x1,5 et x2, standard et guidée : aucun débordement.
- Journal en Interface guidée à 390x684, avec et sans alerte : aucun débordement, et « Réessayer » reste touchable.

**(6) Régression large.** Elle est relancée et tout passe (tableau ci-dessus).

**Décisions.** Elles sont écrites « décidé par délégation le 09/10 » dans `03_DESIGN_SYSTEM_ET_UX.md` et dans la fiche.

## Autres défauts

- **MOYEN, déjà présent sur la base.** La barre mobile admin (`admin_shell.dart:904`) déborde de 24 px à 320x640, texte x2, en Interface guidée, quand l'alerte est ouverte (cloche présente). Ce fichier est dans le périmètre, et la réserve (1) exige « sans débordement » en Interface guidée.
- **MINEUR, déjà présent sur la base.** Dans la phrase de la chaîne du Journal, « ci-dessous » est coupé au trait d'union à 390 et 320 px en taille normale, et à 390 en texte x2 (`verifierEcranSansMotCoupe`). Le widget vient d'être repris : il faudrait `nomsComposesEntiers`.
- **MINEUR.** `_largeurPastille` recopie la géométrie interne de `StatusPill` sans le style `fond.applyTo` : le seuil entre rangée et pile est fragile.
- **Hors périmètre, déjà présents.** Les libellés du rail sont tronqués (« Accueil ») à 800 et 1024 px. Le point final passe en tête de ligne en RTL (« .Les règles… »), déjà signalé par le rédacteur.

## Captures ouvertes

**Celles du rédacteur :**
- Règles 800x600 sombre RTL, rail, défilée : la tête est fixe ;
- Règles 1440x900 en Interface guidée, défilée : la tête est fixe, la page ne défilait pas ;
- Journal 320x640 x2 clair : la pastille passe au-dessus de la phrase, aucun mot coupé ;
- Journal 390x844 en Interface guidée, en haut de page.

**Les miennes :**
- Journal 1440x700 clair, défilée : la tête et les actions sont hors de la vue ;
- Journal 1024x768 sombre RTL, défilée : même chose ;
- Journal 390x684 en Interface guidée sans alerte : correct.

Les captures que j'ai produites sont dans le scratchpad : `rv17_cap/`.

## Ce qu'il faut pour accepter

1. La tête fixe sous le bandeau sur le Journal, en rail et en large, au moins la ligne titre + actions et les onglets.
2. Des tests de géométrie sur le vrai Journal (800x600, 1024x768, 1440x700, 1440x900 guidée), en LTR et en RTL.
3. Une fiche qui décrit exactement quand la tête défile.
4. De préférence, la correction du débordement de 24 px de la barre mobile à 320 x2 en Interface guidée.
