# STYLE-REFERENCE-CL4-2026-09-26 : le style de l'entrée en classe devient la référence

**Décision du directeur, 26/09/2026.**

> « C'est tellement bien fait. C'est la première fois pour moi d'avoir cet effet wow. J'aime bien ta manière de présenter, beaucoup d'espace vide comme je l'aime. Il faut généraliser le style, jusque-là c'est le meilleur. »

Il rappelle aussi une consigne : plus on avance, plus on doit être performant, et moins il doit y avoir de problèmes.

## Ce qui fait référence

**Les écrans.** Lot CL-4, branche `ui/classe-v1` @ `eb97496`. Captures dans `pilotage 10_classe/captures/CL-4.7/`.

**La planche de présentation.** https://claude.ai/artifact/Dhzuqd4ywgL5weasWbEHgL

## Le style des écrans, à appliquer à tout nouveau lot

Ces règles s'ajoutent aux contrats A à E de DESIGN-GOV sans les modifier. Le thème reste figé (K-37) : il s'agit de mise en page et de densité, pas de couleurs.

1. **Beaucoup d'espace vide.**
   - Une page comporte peu de blocs.
   - Une section mène à la suivante avec de l'air : 24 sur mobile, 32 sur bureau.
   - On ne remplit jamais un vide pour le remplir.
2. **Un seul bouton dominant par écran.**
   - Il est collé à ce qu'il confirme (16), au bord de fin, à largeur naturelle sur bureau.
   - Tout le reste est un lien ou une action secondaire.
3. **Un emplacement qui dit l'état plutôt que trois éléments qui répètent la même chose.** C'est la règle R4, étendue à tous les rôles : une ligne d'état calme, qui devient le bouton quand l'action est possible.
4. **Des cartes groupées** (`GroupeReglages`), une ligne par élément.
   - Titre, puis une seule ligne secondaire en texte doux.
   - Jamais une grande carte par élément.
   - Jamais de tuile de chiffre pleine largeur pour une donnée secondaire : on met une petite pastille.
5. **Un en-tête d'identité sobre** :
   - retour au bord de début, en haut ;
   - puis le nom humain comme titre ;
   - puis une ligne de contexte et une pastille discrète.
   - Pas de titre générique (« Fiche du groupe »).
6. **Sur bureau, une composition en rangées**, dans l'ordre de lecture.
   - Deux colonnes seulement à partir de 840 de largeur utile, divisée par le facteur de texte.
   - Sinon une seule colonne bornée.
   - Jamais un mobile étiré.
7. **Des états calmes** :
   - des phrases humaines ;
   - une seule annonce au lecteur d'écran par changement ;
   - aucune erreur brute ;
   - un skeleton fidèle.

## La présentation au directeur, à appliquer à toute planche de validation

1. **Une page web par lot**, avec les écrans en grand. Des commandes simples en haut : Téléphone, Tablette, Ordinateur ; Clair, Sombre.
2. **Pour chaque écran**, à gauche : son nom et trois points au plus, en français simple (ce qui a été décidé, pas du jargon). À droite : la capture.
3. **Beaucoup d'espace, peu de texte.** En bas, les cas particuliers, puis « Ce qui viendra plus tard ».
4. **Données de démonstration réalistes**, jamais une vraie identité. L'enseignant est un homme par défaut, puisque 90 % des enseignants en sont.

## Portée

- S'applique à tout nouveau lot, dès maintenant, pour tous les rôles : Admin (étapes AD restantes), Classe, et les suivants.
- Ne rouvre aucune étape terminée. Les écrans déjà faits s'harmonisent sur cette référence en HU-1.
- Chaque lot doit faire au moins aussi bien que le précédent : moins de retours du directeur, pas plus.
