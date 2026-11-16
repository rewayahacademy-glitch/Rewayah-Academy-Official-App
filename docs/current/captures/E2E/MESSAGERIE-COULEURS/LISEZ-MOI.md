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
