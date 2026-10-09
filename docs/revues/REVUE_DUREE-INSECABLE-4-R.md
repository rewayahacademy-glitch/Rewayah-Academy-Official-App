<!-- verdict : REFUSEE -->
## DUREE-INSECABLE-4 : verdict **REFUSÉE**

J'ai relu `corrections/c2-duree-4`, tête `9735c09d` : trois commits sur `6e2c91c4`. Les commits sont en français et finissent par les deux lignes demandées. `page_shell.dart`, `supabase/`, `.github/`, `pubspec.yaml`, le thème et le rendu du Coran ne sont pas touchés. Rien n'a été poussé. Les deux worktrees jetables (`rv-DUREE-INSECABLE-4-26` et `rv4-mut`) sont retirés.

La branche est refusée pour une seule raison : la réserve (1) n'est pas entièrement remplie, alors que la demande disait « test qui trouve tous ces cas ». Le reste est solide.

### Réserve par réserve

**(1) Ancres U+200E au milieu d'un libellé : incomplète, défaut majeur prouvé**

Les 4 cas trouvés par le rédacteur sont bien corrigés : l'historique du contrôleur (2 cas), la salle côté enseignant et LignePresence. La garde `test/support/garde_ancres.dart` suit les variables, les fonctions, les listes jointes, les interpolations et les concaténations.

Mais la garde pose comme hypothèse qu'un argument nommé est une valeur affichée seule. C'est faux pour `ColonneDonnees.texte`. Sous 1200 px, `DataCollection` passe en cartes et joint les colonnes secondaires par « · » (`data_collection.dart:400-406`).

- **Preuve sur la vraie page Comptes**, vue de 800 px, avec le harnais de `comptes_test` : le texte rendu est « TEACHER-AS-000001 · Enseignant · En attente · Aucune pièce déposée · ‎12 jours · 2 ». L'ancre est au milieu de la ligne, et la garde reste verte.
- **Même défaut sur la page Progression**, à la lecture du code : `_depuis` passe par valeurSeule, et les colonnes Groupe et Niveau viennent avant (« Groupe · Niveau · ‎N jours »).
- **Correction attendue :**
  - insecable seul dans ces `_attente` / `_depuis`, ou ancre posée par `DataCollection` seulement en tête du résumé ;
  - extension de la garde aux fonctions passées en `texte:` d'une colonne secondaire, ou contrôle à l'exécution sur les textes rendus.

**(2) Unités hors durée : conforme**

- Âge hors bornes, zoom de la salle (ancré, car affiché seul) et zoom du Mode Accessibilité passent par `LibellesGroupe.insecable`.
- La garde connaît maintenant ans, o, Ko, Mo, Go et %.
- Les deux « 150 % » de `tc_mushaf` sont exclus de la garde à bon droit : le rendu du Coran est interdit à cette étape. C'est consigné « décidé par délégation le 05/10 ».
- Les six clés i18n concernées sont déclarées « validé par délégation le 05/10 » dans `tool/libelles_sources.json`. Aucun texte i18n n'est modifié.

**(3) Rappel testé par le code réel : conforme**

- `duree_insecable_4` rend la FicheSeance et presse le bouton.
- Un nouveau test passe par `classe_live_page`.
- L'ancien test, qui appelait `insecable` lui-même, est supprimé.

**(4) CarteSession : conforme**

- La ponctuation d'un libellé français reste à sa place en RTL : « dans 8 min. » au lieu de « .dans 8 min ». La capture avant/après le montre.
- La carte est bornée à `AppPage.largeurLecture` (800), au bord de début, y compris le squelette et l'état vide.
- Sur les pages réelles (Ma classe, Mode Accessibilité), la carte est déjà dans une colonne de moins de 800 px : aucune régression d'alignement.
- LocalFeedback est isolé de la même façon.

### Mutations : chaque correction annulée fait échouer un test

| Correction annulée | Test qui échoue |
|---|---|
| `insecable` retiré dans `fiche_seance` | `duree_insecable_4` (3) |
| `insecable` retiré dans `classe_live_page` | « sans couper la durée » |
| SensDuContenu neutralisé | 2 tests RTL |
| Borne de 800 px retirée | test à 1440 px |
| `vue_seance` remis en valeurSeule | garde, test salle, `vue_seance_test` |
| Âge nu dans le formulaire | garde des unités, 2 tests du formulaire |
| `ligne_presence` remis en valeurSeule | garde, test LignePresence, `duree_insecable_2` |
| Zoom de la salle nu | garde, test du zoom |
| Zoom du Mode Accessibilité nu | garde des unités |
| Historique remis en valeurSeule | garde des ancres |

### Contrôles

- `dart analyze --fatal-infos` : 0 problème.
- `verifier_jetons` : 39, identique à la base, aucune nouvelle violation dans les fichiers touchés.
- `verifier_revue` : 1547 contre 1550 sur la base. La seule baisse est `libelle-sans-source` (1490 → 1487).
- `flutter test --concurrency=2` :
  - **Vert :** `test/accessibilite` (+372) ; `duree_insecable_2/3/4`, `classe_live_page_test`, `vue_seance_test`, `formulaire_profil_eleve_test` et `test/features/controleur`, tous verts.
  - **Pas de résultat :** le lancement de la suite large (`core`, `features`, `router`, `teaching_core`, `widgets`) a été interrompu par la limite de temps. Le second n'avait rien rendu quand j'ai dû conclure, et le retrait du worktree l'a arrêté. Le rédacteur la déclare verte, mais je ne l'ai pas revérifiée.

### Captures

J'ai ouvert les 16 captures du rédacteur. Elles montrent la carte seule. J'ai ajouté des captures sur les pages réelles :

- Ma classe adulte : 1440 clair LTR, 1440 sombre RTL, 390 clair, 320 texte x2 sombre RTL ;
- Mode Accessibilité : 1440, 320 texte x2 RTL, 390 sombre.

Aucun mot n'est coupé dans la carte, et la ponctuation y est correcte. Deux défauts préexistants, hors des cartes touchées : en RTL, « .règles de tajwid » et « élèves sur 6 places 3 ».

### Réserves mineures

- SensDuContenu double en partie `isolerSens`, qui existe déjà dans `core/i18n/isolat_bidi.dart`.
- EmptyState n'est pas encore isolé ; c'est signalé par le rédacteur.

### Pour lever le refus

Corriger les ancres glissées des pages Comptes et Progression. Étendre la garde aux colonnes secondaires de `DataCollection`, ou vérifier les textes rendus, avec une contre-épreuve sur l'ancien code.
