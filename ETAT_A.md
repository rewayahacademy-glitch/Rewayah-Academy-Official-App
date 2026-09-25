# État annoncé par le poste A (coordinateur)

## 25/09/2026 : nouvelle base `origin/ui/tuteur-v1` @ `1cbc760` (réponses aux demandes, lot D intégré)

- **Nouvelle base commune : `origin/ui/tuteur-v1` @ `1cbc760`** (poussée). Contenu depuis `cefab7f` : les réponses aux demandes (5 commits), la fusion du lot D `ae34143` (`origin/ui/tuteur-v1-d` @ `f799ade`), puis la bascule du QR `1cbc760`.
- Vérification complète sous verrou : `dart analyze --fatal-infos` (dépôt entier) sans problème ; `verifier_jetons` 424 fichiers sans violation ; **suite complète 2241 tests verts, 0 échec** (229 captures sautées sans `CAPTURE_DIR`) ; frontière `supabase`, `.github`, `vercel.json`, `pubspec.yaml` vide. Journal : `04_phase0/integration_lotD_tests.log`.

## Réponses aux demandes

| Demande | Réponse | Commit |
|---|---|---|
| B-1 (meneur dans `GroupeReglages`) | **Fait.** `LigneRubrique.meneur` (`Widget?`) rendu à la place de l'icône, filet au même retrait ; `icone` facultative, assertion `icone != null \|\| meneur != null`. | `c950607` |
| B-2 / D-2 (tri `paired_at`) | **Fait.** `.order('paired_at', ascending: false)` (plus récent d'abord). Aucun autre `.order(` dans `lib/core/appairage`. Garde lexicale `test/appairage/tri_explicite_test.dart` (le client Supabase n'est pas simulable sans nouvelle dépendance). | `5445d97` |
| B-3 / A-2 (gabarit d'étape, choix) | **Fait.** `PageShell(actionsCoquille: false)` : ni cloche ni bascule. Nouveau `lib/core/widgets/page_etape.dart` : `PageEtape(numero, total, onRetour, child, action)` (rangée V6 en première ligne : disque retour 48, progression continue, « n sur N » lu « Étape n sur N », clés `commun.etape.*` ; action collée en bas, `ActionPrincipale(pilule: true)` permise) et `RangeeEtape` publique (panneau bureau, dialogue). `OptionChoix(description, disponible = true, raisonIndisponible)` (défaut `commun.choix.indisponible`) ; radio dessiné `RadioChoix` (anneau ≥ 3:1, testé clair et sombre) en sélection unique, coche conservée en sélection multiple ; carte « Autre » et `autoriserSaisieLibre` inchangés. | `6c6aef9` |
| B-4 (`/tuteur/reglages`) | **Fait.** Alias vers `/tuteur/foyer` (mapping C6) ; `ReglagesEnfantPage` n'est plus montée par le routeur. Conséquence : les liens des lots C (`accueil_famille_page.dart`, `destination: Routes.tuteurReglages`) et E (`compte_page.dart`, `context.push(Routes.tuteurReglages)`) aboutissent au Foyer tant qu'ils ne sont pas mis à jour. | `9bed664` |
| D-1 (paire QR) | **Fait.** `AppPalette.contenuQr` (fond `#FFFFFF`, encre `#110E20`), identique en clair et en sombre. Ajout pur, aucun jeton existant ne change. Test de contraste. | `1614d28` |
| D-3 (retour de l'émetteur) | Information notée, aucun changement. La fiche (lot B) appelle `Routes.appairerPour(id)` + `?retour=<chemin de la fiche>`. | — |
| A-1 (visiteur vers `/bienvenue`) | **Non appliqué maintenant** : l'écran `/bienvenue` n'existe que sur `ui/tuteur-v1-a`. Sera appliqué à l'intégration du lot A. | — |
| A-3 (port des consentements) | Hors de cette passe ; traité à l'intégration du lot A (branchement du port) et avec le lot E (entrée dans le Compte). | — |
| R-08 (scanner et gouttière de `PageShell`) | **Accepté, écart justifié, `PageShell` inchangé.** Le scanner n'a pas de maquette propre ; la référence la plus proche (M3 #20) pose elle-même son contenu avec des marges. Si le directeur veut un scanner bord à bord, `PageImmersive` (gabarit partagé sans gouttière) existe déjà : ce serait un changement du lot D, pas de `PageShell`. | — |

Bascule faite par COORD à l'intégration du lot D : `EmetteurQr.paire` retiré, le QR lit `contenuQr` (`1cbc760`).

## Consignes aux postes

- **Poste B** : fusionner `origin/ui/tuteur-v1` @ `1cbc760` dans le lot en cours (et dans `ui/tuteur-v1-b` avant sa fin), puis migrer les contournements vers les composants partagés :
  - `_RangeeEtape` et le haut de page de l'ajout de profil : `PageEtape` / `RangeeEtape` ;
  - `_Radio` et `CarteChoixFoyer` (formulaire K3 et `fiche/interface_page.dart`) : `ChoiceCardGroup` avec `OptionChoix.description`, `disponible`, `raisonIndisponible` (`autoriserSaisieLibre: false` si aucune réponse libre) ;
  - icône profil des lignes du Foyer (`ligne_membre.dart`) : `LigneRubrique(meneur: AvatarTile(...))` ;
  - lot A : ses contournements locaux d'étape et de choix, même migration.
- **Lots C et E (poste A)** : remplacer les liens vers `Routes.tuteurReglages` (`accueil_famille_page.dart`, `compte_page.dart`) par la destination de la fiche ou du Foyer ; la route n'est plus qu'un alias du Foyer.
- Ordre d'intégration suivant : B, puis A (avec A-1 et A-3), C, E, O au fil de leurs fins de lot.
