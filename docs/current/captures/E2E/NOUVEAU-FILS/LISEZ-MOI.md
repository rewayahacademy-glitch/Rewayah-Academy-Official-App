# Badge « Nouveau » dans le panneau des conversations (NOUVEAU-FILS, 16/11/2026)

- `apres/nouveau-fils-liste-{390,1440}-{fr,ar}-{clair,sombre}.png` : la liste des conversations avec une conversation nouvelle
  (avec message et deux non lus), une conversation nouvelle vide (« Nouveau » puis « Aucun message »), une lue avec un non lu, une lue.
- Pas de « avant » : la fonction n'existait pas. Fixtures de démonstration (vue de l'équipe) : le vrai `nouveau` vient du serveur
  (migration `20261129510000`, non installée au moment de ces captures).
- Code : `test/features/com_messages/nouveau_fils_capture_test.dart` (sauté sans `CAPTURE_DIR`).
- Non capturé : le filtre « Nouveaux » actif (couvert par `nouveau_fils_test.dart`, pas par une capture).
