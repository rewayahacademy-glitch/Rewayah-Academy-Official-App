<!-- verdict : ACCEPTEE_AVEC_RESERVES -->
# Revue adverse de COUPE-MOTS-3b (branche `corrections/c2-coupe-mots-3b`, commit b3a26bf7)

**Verdict : ACCEPTÉE AVEC RÉSERVES.** Les quatre points demandés sont faits et prouvés. Aucun défaut majeur. Il reste trois réserves mineures, détaillées plus bas.

- **Statut :** testé localement seulement. Rien sur staging, rien de déployé.
- **Méthode :** relecture indépendante, en lecture seule. Worktree jetable détaché sur `origin/corrections/c2-coupe-mots-3b`, retiré à la fin. Rien n'a été poussé.
- **Base :** un seul commit au-dessus de `origin/corrections/revue-directeur-2026-10` (6e2c91c4). Le merge-base est bien égal à cette tête.

## Contrôle de la demande, point par point

### (1) Captures en sombre, à 390 et à 1440 — FAIT

- **Contenu du dossier :** `docs/current/captures/COUPE-MOTS-3b/` contient 52 fichiers, dont le script archivé `coupe_mots_3b_capture_test.dart.txt`.
- **Écrans couverts :** les trois écrans corrigés par COUPE-MOTS-3 (Espace Classe enseignant, Espace Classe élève, récapitulatif de l'observation).
- **Variantes, en fr et en ar :**
  - 320 x2 en clair ;
  - 320 x2 en sombre ;
  - 320 x2 en sombre avec l'Interface guidée ;
  - 390 en clair et en sombre (largeur réelle 390) ;
  - 1440 en clair et en sombre (1440 x 900).
- **Captures arabes « avant » :** 9.

Captures ouvertes :

| Capture | Ce que j'ai vu |
| :--- | :--- |
| ens ar 320 x2 clair, avant et après | « % 1 · 60 » devient « 1 · 60 % » |
| ens ar 1440 sombre | Conseil d'appareil dans le bon ordre, progression correcte |
| ens ar 390 clair | Correct |
| élève ar 320 x2 sombre | Correct |
| élève fr 320 x2 clair | Correct |
| élève ar 390 clair | Pastille « 3 élèves sur 6 places » correcte |
| observation ar 390 clair, avant | « .avant l'envoi », « Mariam S. · Élève précis », « .à l'administration » |
| observation ar 320 x2 sombre guidée, après | Ordre correct, aucun mot coupé |
| observation fr 1440 clair | Correct |

### (2) Test d'écran de `lierTaillesFichier` — FAIT, mutation vérifiée

- **Ce que fait le test :** `test/features/coupe_mots_3b_test.dart` monte `FicheGroupePage`. Il lui fournit des ressources dont le titre court est écrit avec une espace ordinaire.
- **Garde sur la donnée :** le test vérifie d'abord qu'aucune espace insécable n'est présente. Les octets `C2 A0` sont bien dans le motif, je l'ai contrôlé avec `grep -P`.
- **Exigence à l'écran :** il exige ensuite l'espace insécable pour les trois tailles rendues.
- **Mutation faite par moi :** j'ai remplacé `lierTaillesFichier(ressource.shortTitle)` par `(ressource.shortTitle)` dans `emplacements_groupe.dart`. Le test échoue alors en fr et en ar.

### (3) Fiche `tool/libelles_sources.json` — FAIT

- Les quatre clés (`kyc.tropVolumineux`, `ficheEleve.informations.tropLourde`, `tuteur.reglages.photoTropLourde`, `classe.entree.progressionValeur`) portent « validé par délégation le 05/10 (règle DIR-REP-1, étape COUPE-MOTS-3b) ».
- Le JSON reste valide.

### (4) Texte français réordonné en RTL — FAIT, mutations vérifiées

- **Nouvelle fonction :** `isolerSiAutreSens`, dans `lib/core/i18n/isolat_bidi.dart`. Elle isole le texte (U+2068 / U+2069) seulement quand sa première lettre s'écrit dans l'autre sens que l'interface. Elle s'appuie sur `isolerSens`, la fonction déjà employée ailleurs dans le code.
- **Écrans touchés :** `fiche_groupe_page`, `emplacements_groupe`, `espace_groupe_page`, `carte_session`, `observation_controle_page`.
- **Mutation globale :** avec les cinq écrans de la base remis en place, les trois tests d'ordre visuel en arabe échouent.
- **Mutations fichier par fichier :** j'ai remis un seul fichier à son état de base à la fois. Chaque fois, au moins un test arabe échoue :

| Fichier remis à l'état de base | Tests qui échouent |
| :--- | :--- |
| `observation_controle_page` | observation (1 échec) |
| `fiche_groupe_page` | enseignant (1 échec) |
| `carte_session` | élève (1 échec) |
| `emplacements_groupe` | élève (1 échec) |
| `espace_groupe_page` | enseignant et élève (2 échecs) |

- **Périmètre de `emplacements_groupe.dart` :** seulement l'import et la ligne d'affichage (7 lignes). C'est le strict nécessaire, ce qui ménage CARTES-PERSO-1b.

## Contrôles transverses

- `dart analyze --fatal-infos` : aucun problème.
- `verifier_revue` : 1550, contre 1550 sur la base 6e2c91c4. Égal à la base.
- `verifier_jetons` : 39 signalements. Le seul qui touche un fichier modifié (`carte_session.dart:401`, `ontap-nu`) est antérieur au lot (blame eb97496c4 du 26/09).
- `dart format` : 0 fichier modifié.
- **Régressions sur les autres appelants :** j'ai lancé avec `--concurrency=2` les 34 fichiers de test qui citent les composants ou libellés touchés. Ils viennent de `test/features`, `test/accessibilite`, `test/core/accessibilite`, `test/router` et `test/teaching_core`, entre autres. Résultat : 573 réussis, 512 ignorés, 0 échec.
- **Suite complète :** non rejouée par moi. Mon lancement a dépassé la limite de 10 minutes et a été arrêté. Je n'ai pas non plus pu confirmer les compteurs annoncés par le rédacteur.
- **Ajustement de `coupe_mots_3_test.dart`** (`find.textContaining`) : justifié, puisque la question est maintenant isolée en arabe.
- **Zones interdites :** aucun fichier sous `supabase/`, `.github/`, `vercel.json`, `pubspec.yaml`, thème ou rendu du Coran.
- **Commit :** les deux lignes de fin sont exactes, et aucun identifiant de modèle n'apparaît dans le diff.

## Réserves (mineures, sans effet sur la fusion)

1. **Captures 320 x2 de l'Espace Classe incomplètes.** Elles ne montrent que le bas de la page, donc ni la pastille de capacité ni le conseil d'appareil. Les deux sont visibles et corrects à 390 et à 1440, et testés à 320 x2 par la position des glyphes.
2. **Valeurs encore mêlées en RTL, déjà déclarées par le rédacteur :**
   - la durée « الدرس بعد 3 h 28 » s'affiche « h 28 3 » ; elle est renvoyée au lot DUREE ;
   - la ligne des élèves à 320 x2 (« RA-DEMO-001 · Niveau 1 الاستئناف: Page 24 ») reste mêlée ; elle est hors des exemples nommés.

   Toutes deux restent à traiter.
3. **Isolation non testée sur une partie de l'observation :** les valeurs Nature et Domaine, l'explication et le message d'échec. Le risque est faible, et les mutations par fichier échouent déjà grâce aux autres valeurs.
