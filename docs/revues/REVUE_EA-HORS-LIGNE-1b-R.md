J'accepte le lot avec réserves. Les deux défauts majeurs de la revue sont levés et je l'ai prouvé moi-même. Il ne reste que des mineurs, dont deux antérieurs au lot.

# Contre-revue EA-HORS-LIGNE-1b : ACCEPTÉE AVEC RÉSERVES

## Contexte
- **Branche relue :** `origin/corrections/c2-hors-ligne-b`, tête `9a75765c`.
- **Base :** `origin/corrections/c2-hors-ligne` (`a6b0ef22`).
- **Commits :** 2, `ec1c2508` et `9a75765c`.
- **Défauts à lever :** ceux de `docs/revues/REVUE_EA-HORS-LIGNE-1-R.md`, sur `origin/revues/2026-10-04-b061fd81`.
  - Deux majeurs : l'état d'erreur des demandes admin réemployait `reseau.horsLigne`, et le bandeau promettait « Tout reste consultable ».
  - Deux mineurs : les captures manquantes et le bouton grisé de l'invitation du conjoint.
- **Méthode :** lecture seule.
  - Un worktree jetable `rv-HORS-LIGNE`, détaché sur la tête.
  - Un worktree jetable `rv-HL-base`, détaché sur la base, pour comparer.
  - Les deux sont retirés. Rien n'a été poussé et aucune branche n'a été modifiée.

## Périmètre du diff
20 fichiers :
- `fr.i18n.json` et `strings_fr.g.dart` ;
- `offline_banner.dart` (commentaire seulement) ;
- `demandes_page.dart` (1 ligne) ;
- 2 tests ;
- `libelles_sources.json` ;
- un script de capture et sa copie `.dart.txt` (contenus identiques, vérifié avec `diff`) ;
- 11 PNG.

Aucun fichier interdit n'est touché : ni `supabase/`, ni `.github/`, ni `pubspec`, ni le thème, ni le rendu du Coran, ni `dart_define`.

Les deux commits sont en français et finissent par les deux lignes exigées. Je n'ai trouvé aucun autre identifiant de modèle et aucun secret.

## Commandes et résultats

| Contrôle | Résultat |
|---|---|
| `dart run slang` | OK, aucun diff généré (les fichiers générés sont à jour) |
| `dart analyze --fatal-infos` | No issues found |
| `verifier_revue` | 1627 sur la tête, 1627 sur la base, même répartition par règle (libelle-sans-source 1566, affirmation-reseau 5, bouton-grise 32…) |
| `verifier_jetons` | 39 sur la tête, 39 sur la base |
| `flutter test --concurrency=2` sur `test/core`, `test/i18n`, `test/tool`, `test/accessibilite`, `test/widgets` | +1273, tous verts |
| `flutter test --concurrency=2 test/features` | +2541 (~2062 sautés), tous verts |
| Tests ciblés `offline_banner_test` et `demandes_admin_test` | +21, tous verts |

## Majeur 1 : le bandeau promettait trop (`fr.i18n.json:133`). Levé.
- **Nouveau texte :** « Pas de réseau. Ce qui est déjà affiché reste consultable. », la formulation recommandée par la revue.
- **Usages de `t.reseau.horsLigne` dans `lib` :**
  - `offline_banner.dart:93` ;
  - les galeries de développement (`compte_galerie`, `catalogue_galerie`).
- **Le réemploi dans `demandes_page` a disparu.**
- **Contre-épreuve refaite :**
  - J'ai remis « Pas de réseau. Tout reste consultable. » dans `fr.i18n.json` et relancé slang.
  - Le test « le bandeau ne promet que ce qui est deja affiche » échoue : `Expected: not contains 'tout'`, `Actual: 'pas de réseau. tout reste consultable.'`.
  - Il est vert sur la tête. Le test est donc discriminant.

## Majeur 2 : l'erreur des demandes admin (`demandes_page.dart:132`). Levé.
- **Nouvel état `hasError` :** il affiche `t.admin.demandes.erreurFile`, soit « La file des demandes n'a pas pu se charger. Réessayez dans un instant. ».
- **Dans le même état :** l'icône d'alerte et le bouton Réessayer.
- **Ancienne clé :** `admin.demandes.erreur` a été retirée, sans reste d'usage puisque l'analyse est propre.
- **Contre-épreuve refaite :**
  - J'ai remis dans la page `'L\'opération n\'a pas abouti : ${t.reseau.horsLigne}'`.
  - Le test « une panne dit que la file n a pas charge, pas « Pas de reseau » » échoue (`Found 0 widgets with text "La file des demandes n'a pas pu se charger...`).
  - Le test est donc discriminant.
- **Ce que le test vérifie en plus :** l'absence de `reseau.horsLigne` et de « consultable ».
- **Autres messages de la page :** les erreurs de décision passent par `_message(erreur)`. Aucun autre usage de `horsLigne` n'existe dans `admin_demandes`.

## Mineur 3 : captures. Levé.
- **Script rejoué** avec `CAPTURE_DIR`, augmenté pour ma vérification par des cas supplémentaires :
  - bandeau en RTL sombre à 390, en RTL sombre à 320 et 200 %, à 1440 en sombre, à 1440 en RTL clair et 200 % ;
  - erreur des demandes à 1440 et 200 % ;
  - cahier à 1440 en sombre et à 320 en sombre et 200 %.
- **Mesure des mots coupés :** sur l'écran entier (`motsCoupes` sur `Scaffold`), pas seulement sur le bandeau. Les 18 cas passent.
- **Bandeau, erreur des demandes et cahier en file :** aucun mot coupé dans toutes les configurations.
- **Captures livrées ouvertes** (`bandeau_320x2`, `bandeau_390_rtl`, `erreur_demandes_320x2`, `cahier_en_file_320x2`), ainsi que mes captures 320x2 RTL sombre, 1440x2 RTL et cahier 1440 sombre :
  - le bandeau tient sur 1 à 3 lignes sans coupure ;
  - le RTL est en miroir ;
  - le contraste est correct en sombre ;
  - le cahier montre le bandeau et « En attente d'envoi / sera envoyé lorsque la connexion reviendra » sans contradiction ;
  - l'erreur des demandes n'a ni bandeau ni « Pas de réseau ».

## Défauts restants (tous mineurs)
1. **Mot coupé à 320 px et 200 % sur la file des demandes, antérieur au lot.**
   - « Plateforme » est coupé dans « Plateforme : 45 min ». Le rédacteur ne l'a pas signalé, il n'a signalé que « STUDENT-AD-000001 », qui passe à la ligne au trait d'union.
   - J'ai mesuré la même chose sur la base `a6b0ef22`.
   - Le script livré ne le voit pas : il ne mesure que le bandeau et l'EmptyState, et la capture de 900 de haut coupe la carte de règle.
   - À traiter dans l'étape propriétaire de l'écran ADM-06.
2. **Boutons grisés hors ligne, antérieurs (EA-6).** Il s'agit de `invitation_conjoint.dart:569` et `:726`. C'était « pour suivi » dans la revue d'origine, et le rédacteur le reconnaît.
3. **Ancienne promesse dans un test.** `test/features/demo/repere_demonstration_test.dart:17` garde en dur « Tout reste consultable, l envoi attendra ». C'est sans effet en production, mais l'ancienne promesse reste dans le dépôt.
4. **Libellés à valider.** `reseau.horsLigne` et `admin.demandes.erreurFile` ont été rédigés par l'agent et restent à faire valider par le directeur, comme déclaré dans `libelles_sources.json`.

## Vérification du compte rendu du rédacteur
- Les affirmations sur les tests, les contre-épreuves, les compteurs (1627 et 39), l'analyse et les captures sont exactes.
- Une omission : le mot coupé « Plateforme » (point 1).

## Verdict
**ACCEPTÉE AVEC RÉSERVES.** La fusion reste soumise aux contrôles habituels (CI, sécurité) et à la validation des deux libellés par le directeur.