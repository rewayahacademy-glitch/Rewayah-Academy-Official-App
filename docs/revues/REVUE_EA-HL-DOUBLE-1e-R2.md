<!-- verdict : ACCEPTEE_AVEC_RESERVES -->
## Relecture adverse de EA-HL-DOUBLE-1e (branche `corrections/c2-hl-double-e`, commit 88ae5cf6)

**Verdict : ACCEPTEE_AVEC_RESERVES.** Les trois points de la demande sont remplis. Il ne reste aucun défaut majeur prouvé. Les réserves portent sur un défaut antérieur, déjà déclaré par le rédacteur, et sur un détail cosmétique.

### Méthode
- J'ai travaillé dans trois worktrees jetables, tous retirés à la fin :
  - la tête de la branche ;
  - la base `corrections/revue-directeur-2026-10`, dont la branche descend ;
  - une copie de la tête réservée aux mutations.
- Rien n'a été poussé.
- Le diff contient 37 fichiers. `page_shell.dart` n'est pas modifié, et rien n'est touché dans `supabase/`, `.github/`, le thème, le rendu du Coran ou `pubspec.yaml`.

### (1) Journée enseignant : rempli
- Le code distingue les deux échecs : `echecPrieres` (réglages ou pause) et `echecCahiers` (retards). Le message correspond à ce qui a échoué :
  - prières et pauses seules → `erreurPartielle` ;
  - cahiers seuls → `erreurPartielleCahiers` ;
  - les deux → `erreurPartielleTout`.
- Les trois textes ne parlent plus du réseau. Ils disent « il est possible que la demande ne soit pas parvenue jusqu'à Rewayah. Vos séances affichées sont à jour… Réessayez dans un instant. »
- La garde est étendue de deux façons :
  - `motifHorsLigne` attrape désormais « connexion ou service », « connexion instable », « faible », « lente »…, « problème de connexion », etc. ;
  - un test dédié interdit toute occurrence de « connexion » ou « réseau » dans les trois clés de la Journée, sans exception.
- Mutation 1 (j'ai remis l'ancien `journee_page.dart`) : 4 tests de `journee_test.dart` échouent (cahiers seuls et tout, en ligne et hors ligne).
- Mutation 2 (j'ai mis « Connexion instable. » dans `erreurPartielleCahiers`) : la garde du catalogue échoue, ainsi que 2 tests de la Journée.

### (2) docs/current/03 : rempli
- La visionneuse de pièce ne figure plus parmi les exceptions. Le texte dit maintenant que le bandeau reste visible au-dessus et que la pièce affiche « La pièce n'a pas pu être chargée. » avec le sablier.
- Le code confirme ce texte : `visionneuse_piece.dart` prend `icone: AppIcons.attente` en état hors ligne, et la clé `visionneuse.horsLigne` contient cette phrase.

### (3) Les 7 textes « Rewayah n'a pas répondu » : rempli
- La base en comptait exactement 7 : `ficheEleve.interface.echec`, `controleur.complement.echec`, `compteRendu.echec`, `echecRien`, `visiteEchec`, `observation.echec`, `echanges.echec`. Ils sont tous réécrits.
- Une seule formulation cohérente s'applique aux 12 textes : « il est possible qu'il / qu'elle / que la demande ne soit pas parvenu(e) jusqu'à Rewayah ». Elle s'étend aussi aux deux textes adulte qui disaient « le serveur n'a pas répondu ».
- Un test vérifie l'absence de « Rewayah / le serveur n'a pas répondu / ne répond pas » et impose la formulation clé par clé.
- Mutation 3 : j'ai remis « Rewayah n'a pas répondu » dans `echecRien` et « le réseau semble faible » dans `historique.echec`. La garde échoue, et le test de l'historique adulte aussi.
- Dans `tool/libelles_sources.json`, chaque clé porte son ancien texte, K-59 et le libellé « validé par délégation le 05/10 (DIR-REP-1) ».
- La clé morte `salle.reconnexion` est retirée. `analyze` passe, donc elle n'avait aucun appelant.

### Contrôles relancés par moi
| Contrôle | Résultat |
| :--- | :--- |
| `dart run slang` | aucun écart avec les fichiers générés commités |
| `dart analyze --fatal-infos` | 0 problème |
| `verifier_jetons` | 39 violations, inchangé |
| `verifier_revue` | 1550 → 1548 : `libelle-sans-source` −1, `affirmation-reseau` −1, aucune nouvelle catégorie |
| `dart format` sur les 7 fichiers Dart touchés | 0 changement |
| journee, core/reseau, accueil_adulte, controleur, foyer | +658 ~91, tous passés |
| les 26 fichiers qui utilisent le motif partagé `hors_ligne_une_fois` | +647 ~183, tous passés |
| régressions salle, classe live, observation, vidéo, widgets | +1591 ~537, tous passés |

- Tous les tests ont tourné avec `--concurrency=2`.
- Le pourquoi des régressions : le motif élargi aurait pu toucher les textes de salle, d'où ces dossiers.
- Les commits se terminent par les deux lignes exactes demandées, et aucun identifiant de modèle n'apparaît ailleurs.

### Captures ouvertes
- **Journée « tout », 320 x2 RTL** : aucun mot coupé dans l'alerte, et le bandeau seul porte le wifi barré.
- **Journée « cahiers », 390** : le texte exact correspond au cas, le sablier est sous le bandeau, et le bouton Réessayer est actif.
- **Journée, 390 sombre** : correcte.
- **Historique adulte en échec, 320 x2** : aucun mot coupé.
- **Contrôleur, visite en échec, 320 x2** : le texte d'échec est correct.
- L'Interface guidée n'est pas pertinente pour ces écrans.

### Réserves
1. **Antérieure, hors étape.** À 320 px texte x2, ChoiceCardGroup coupe « nor malement », « obser vation » et « administ ration ». La capture de preuve du contrôleur le montre. Le script ne vérifie que le texte d'échec, ce qui explique « sans erreur ». Ce défaut est déclaré en non_fait par le rédacteur. Il doit faire l'objet d'une étape dédiée avant la production.
2. **Cosmétique.** Une ligne de commentaire de doc dépasse 80 colonnes dans `test/support/hors_ligne_une_fois.dart`.
3. **Information.** Neuf clés de la salle et de la classe en direct gardent « Connexion instable » / « Réseau faible » comme permises. C'est conforme à l'exception des écrans `PageImmersive` sans bandeau inscrite dans 03.
