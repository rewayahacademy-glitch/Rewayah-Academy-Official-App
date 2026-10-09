<!-- verdict : ACCEPTEE_AVEC_RESERVES -->
# Relecture adverse : COUPE-MOTS-4 (branche `corrections/c2-coupe-mots-4`, tête `ad04a226`)

## Verdict : **ACCEPTÉE AVEC RÉSERVES**

Les quatre points de la demande sont remplis, et les preuves sont rejouées ci-dessous. Je n'ai trouvé aucun défaut majeur. Restent trois réserves mineures (couverture de captures, garde de la barre limitée à la barre, identifiant réduit dans la carte de Comptes) et trois constats hors étape, consignés.

Statut : présent dans le code, testé localement (par moi). Ni testé sur staging, ni déployé.

## Méthode
- Worktree jetable détaché sur `origin/corrections/c2-coupe-mots-4`, plus un second worktree jetable pour les mutations. Les deux sont retirés à la fin, rien n'a été poussé.
- Base du lot : `5a52ff30`. Le premier commit du lot est `b26852b3`, ChoiceCardGroup. Le lot compte 9 commits, chacun terminé par les deux lignes d'attribution exactes, sans autre identifiant de modèle.

## Contrôles automatiques
| Contrôle | Résultat |
|---|---|
| `dart analyze --fatal-infos` | No issues found |
| `dart run slang` sur la tête | aucun fichier modifié (le fichier généré est cohérent avec `fr.i18n.json`) |
| `verifier_revue` | 1413 violations, pas de hausse (le rédacteur annonçait 1414) |
| `verifier_jetons` | inchangé, mêmes violations qu'avant (`admin_shell`, `groupe_reglages`), aucune nouvelle dans les fichiers du lot |
| `flutter test --concurrency=2 test/widgets test/core test/features test/teaching_core test/router` | **+5902 ~2365, All tests passed** |
| Fichiers interdits (`page_shell`, `admin_shell`, `rangee_filtres`, `supabase/`, `.github/`, `vercel.json`, `pubspec.yaml`, thème, Coran) | aucun touché |
| Secrets | aucun |

## Mutations (on annule la correction, les tests doivent échouer)
1. **ChoiceCardGroup** remis à `5a52ff30` : `test/features/coupe_mots_4` donne **+32 −52**. Les échecs nomment le mot (« Royaume-Uni, », « uniquement »…).
2. **nav_shell.dart** remis à `5a52ff30` : `coupe_mots4_barre_guidee_test` donne **+8 −8**. Les échecs nomment « Contrôle », « Historique », « Échanges », « Aujourd'hui », « Disponibilités ».
3. **Identifiant de Comptes** :
   - Avec `identifiantInsecable` neutralisé, le test échoue sur l'assertion U+2011.
   - Avec `data_collection.dart` et `comptes_page.dart` remis à la base et l'assertion U+2011 retirée, le test donne −6 : « TEACHER-AS-000002 » est coupé.
   - Conclusion : la mesure géométrique mord. Le U+2011 double la protection de `TexteSansCoupure`.
4. **Typographie** : avec `fr.i18n.json` remis à la base puis slang, la garde `typographie_fr_test` échoue, ainsi que `reglages_enfant_coupe_mots_4_test` (« Pourquoi ce changement ? : ? »).
5. **Feuille des règles** : avec `demandes_page.dart` remis à la base, on obtient −4. `demandes_admin_test`, à 1200 px, passe avec la correction.

## Vérification de la typographie (point 4)
- Comparaison programmatique : l'ancien et le nouveau `fr.i18n.json` sont identiques une fois les espaces normalisées. **Seules des espaces ont changé.**
- Sur les 4041 valeurs, il reste 0 espace sécable avant « ? ! : ; » ou à l'intérieur de « ». Aucune espace fine U+202F n'est utilisée : U+00A0 est la règle du dépôt, inscrite dans `03_DESIGN_SYSTEM_ET_UX.md`.
- 275 entrées de `tool/libelles_sources.json` portent « validé par délégation le 09/10 (DIR-REP-1) ».
- La garde porte sur tout le fichier.

## Appelants de ChoiceCardGroup (point 1)
Les 21 appelants de `lib/` sont couverts par les tests d'écran de `test/features/coupe_mots_4/`. La galerie de développement est exclue :
- `emplacement_evaluation` est couvert par le test du cahier ;
- `feuille_carte_classe` est couvert par le test « feuille d'une carte de classe ».

Ces tests mesurent l'écran entier, c'est-à-dire chaque `Scaffold` et chaque `BottomSheet`, en fr (LTR) et en ar (RTL), à 320 px texte x2, en interface standard et guidée.

## Captures ouvertes
J'ai ouvert :
- compte rendu à 320x2 en fr ;
- barre guidée du Contrôleur en fr et de l'enseignant en ar (deux rangées de deux onglets, tous visibles, aucun mot coupé) ;
- feuille des règles en fr, avant et après, en sombre (« Plateforme / : 60 min » corrigé) ;
- Comptes à 320x2 ;
- feuille du motif dans les réglages de l'enfant, en guidée (« Pourquoi ce changement ? » entier) ;
- fiche Interface en ar ;
- dépôt de pièce en guidée.

Dans ces captures, aucun mot n'est coupé dans le périmètre corrigé.

## Réserves (mineures)
- **Garde de la barre** : `coupe_mots4_barre_guidee_test` ne mesure que la barre, pas le corps des pages. C'est justifié par l'interdiction de toucher `page_shell.dart`.
- **Carte de Comptes** : à 320x2, le titre identifiant est fortement réduit par `TexteSansCoupure`. Il reste lisible, mais la hiérarchie diffère de la carte voisine.
- **Captures incomplètes** : il manque la barre guidée à 390 et Comptes à 390 et 1440. Le sombre n'est capturé que pour deux écrans. Les tests couvrent ces cas.

## Hors étape (consigné, non bloquant pour ce lot)
- `ar.i18n.json` est en grande partie non traduit, d'où le point placé en tête de ligne par le bidi.
- « En attent » est rogné par `rangee_filtres.dart`, fichier interdit.
- « Envoyer ma pièce » est un bouton grisé préexistant (`depot_piece_page.dart:147`), contraire à la règle « aucun bouton grisé ». À traiter dans une étape dédiée.

## Serveur
Aucun besoin serveur.
