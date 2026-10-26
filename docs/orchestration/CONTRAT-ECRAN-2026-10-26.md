# Contrat de l'écran, 26/10/2026

Décision du directeur du 26/10/2026, après une journée où trois PR fusionnées (59, 60, 61) n'ont
rien donné « qui marche vraiment » : le pilote d'origine reprend, avec un modèle suivi à la lettre.
Ce fichier prévaut sur tout plan, revue UX ou passation antérieurs pour la manière de produire un
écran. Il ne change aucune décision de produit.

## 1. Pourquoi le travail était bancal (constat, pas excuse)

- **Le même agent écrivait la règle, le code, le test et le verdict.** Ses tests vérifiaient sa
  propre lecture de la maquette ; « conforme » voulait dire « conforme à ce que j'ai compris ».
  La capture du 26/10 dite conforme avait six écarts visibles à la maquette.
- **La maquette passait par une prose intermédiaire** (plan, tâches numérotées à six points, cotes
  de largeur). Le worker satisfaisait les mots du plan, pas l'écran ; quand le plan contredisait la
  maquette (« la pilule reste »), c'est la maquette qui perdait.
- **Un test de cas limite décidait du cas principal.** Un contrôle à 320 points en texte ×2
  a fait disparaître la puce « Commandes » de la maquette pour tout le monde, puis l'écart a été
  « assumé » dans une revue que le directeur ne lit pas.
- **Les lots grossissaient en cours de route** (six points ajoutés à une PR en cours) ; chaque gros
  lot refaisait la composition et cassait ce que le lot précédent avait réglé.
- **Aucune liste de « ce qui doit être vrai à l'écran » par appareil.** Les iPad du directeur
  n'étaient dans aucun test ; la preuve arrivait en production, après fusion.
- **Un contexte de 470 000 jetons** dégradait le jugement du worker et coûtait 2,4 $ par tour.

## 2. Les huit règles

1. **La fiche d'abord.** Avant tout code, une fiche de l'écran : un tableau, une ligne par fait
   visible, vérifiable en cinq secondes sur l'appareil, une colonne par taille d'appareil du
   directeur (téléphone 390×844, iPad portrait 834×1194, iPad paysage 1194×834, ordinateur
   1366×768). Trente lignes au plus. Le pilote l'écrit depuis la maquette ; le directeur valide
   par numéros de ligne. La maquette et la fiche sont la spécification ; aucune prose entre elles
   et le code.
2. **Aucun écart assumé.** Quand la maquette est imparfaite ou se contredit, le pilote tranche au
   juste milieu (standards publics : Material 3, Meet et Zoom pour les commandes d'appel, WCAG) et
   l'écrit dans la fiche comme ligne « juste milieu », que le directeur peut refuser. Un worker
   qui ne peut pas tenir une ligne s'arrête et le dit avec deux options ; il ne contourne jamais.
   Le cas principal (taille et texte ×1) se conforme à la maquette ; les cas limites s'adaptent.
3. **Une ligne, un test.** Chaque ligne devient un test qui tourne à chaque taille, texte ×1 et
   ×2, français et arabe, avant tout push. Le rapport du worker est ce tableau (ligne × taille,
   vert ou rouge) et les hachés ; rien d'autre. Le mot « conforme » est interdit.
4. **Le pilote regarde.** Avant d'écrire au directeur, le pilote pose la capture à côté de la
   maquette et compare tuile par tuile. Il écrit les différences, jamais un verdict.
5. **Une PR, une fiche, fermée à l'ouverture.** Huit lignes au plus par PR. Toute demande nouvelle
   pendant la PR, même du directeur, va à la fiche suivante, et le pilote le dit.
6. **La preuve, c'est le directeur sur l'aperçu Vercel de la PR**, ligne par ligne, sur ses
   appareils, avant la fusion. Il répond par les numéros de lignes rouges. Aucune fusion avec une
   ligne rouge. Captures et tests verts ne prouvent rien.
7. **L'acquis est protégé.** Les tests des fiches précédentes restent ; une PR qui en casse un est
   refusée avant le push. Une ligne verte qui redevient rouge est un défaut, pas une négociation.
8. **Sobriété.** Messages du pilote : les limites d'abord, cinq lignes. Un worker par fiche, neuf,
   qui ne lit que la fiche, la maquette, les fichiers de l'écran et la section « pièges » de la
   passation ; il est archivé après la fusion. Jamais de nouveau périmètre à l'initiative d'un
   agent.

## 3. Journal

| Date | Fait | Source |
| :-- | :-- | :-- |
| 2026-10-26 | Contrat écrit ; première fiche : `docs/current/maquettes/salle/FICHE-1-TELEPHONE-2026-10-26.md` | pilote |
