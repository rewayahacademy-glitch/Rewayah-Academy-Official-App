# Couleurs de la messagerie (MESSAGERIE-COULEURS, 16/11/2026)

Le directeur : « moche, trop moche, je préfère la couleur d'avant » (capture : la liste des conversations, au téléphone, en arabe,
côté administration : lignes nues sur fond gris, seule la ligne choisie en lavande).

- `avant/` : `main` au 16/11 (après #512, #540, #546). `apres/` : ce lot.
- 390 et 1440, français et arabe, clair et sombre : liste (`bulles-liste-390-*`) et conversation (`bulles-fil-*`).
- Mesure : la couleur n'a pas bougé avec #540 (32 écrans comparés entre `59c6e3e` et `main`, seule la bande du champ change) ; elle
  est venue avec #512 (BULLES-MESSAGERIE) : fond de conversation `#E9E5F0` / `#1B1B24` au lieu de la page `#F1EFF4` / `#16161E`,
  lignes de liste nues.
- Décision du directeur (via le pilote, 16/11) : liste en une carte blanche sur la page ; conversation sur le fond de la page ;
  champ sans rectangle ; la bulle reçue garde son ombre légère. Bord de la bulle reçue sur le fond : 1,14:1 en clair, 1,22:1 en
  sombre (le dessin, pas la couleur, la détache).
- Garde de rendu : `test/features/com_messages/messagerie_couleurs_test.dart`.

## Captures ajoutées le 16/11 (ordinateur, 1440 x 900)

- `apres/volet-1440-{fr,ar}-{clair,sombre}.png` : volet de conversation du dossier d'un candidat, fil remonté, croix « Fermer »
  au bord de fin de la barre (visible dans les quatre). Code : groupe « captures volet » de
  `test/features/admin_candidature/conversation_mise_en_page_test.dart`.
- `apres/bulles-liste-1440-{fr,ar}-{clair,sombre}.png` : liste des conversations (carte blanche à lignes fines sur le fond de
  page). Code : `test/features/com_messages/messagerie_couleurs_capture_test.dart`.
- Pas de capture « avant » à 1440 pour ces deux écrans (non refaite, pour économiser).
- Mesuré : bulle reçue `#FEFEFE` sur le fond du fil `#F1EFF4` = 1,13:1 en clair (elle ne se détache que par l'ombre légère) ;
  `#262633` sur `#16161E` = 1,21:1 en sombre.
- Défaut de capture, hors lot : le drapeau du Sénégal manque sur la capture `volet-1440-fr-clair` (présent sur les trois autres) ;
  cause non vérifiée (probablement le chargement de la police d'emoji dans le rendu de test).
