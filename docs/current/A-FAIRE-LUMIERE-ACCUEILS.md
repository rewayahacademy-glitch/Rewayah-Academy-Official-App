# À faire : lumières des accueils (directeur, 09/11/2026)

**LOT EN ATTENTE — À NE PAS LANCER : seulement après la réinitialisation des tokens et sur ordre du
directeur. Avant tout code : croquis validés par le directeur.**

Demande du directeur du 09/11/2026, transmise par le garde-cap puis par le pilote. Ce fichier garde
ce qui doit entrer dans le lot, pour que rien ne se perde. Il ne décide rien de plus que ce qui est
écrit ici.

## Grammaire commune des lumières

| Lumière | Sens |
| :--- | :--- |
| Rouge qui tourne | urgent |
| Orange qui respire | à préparer |
| Vert qui respire | en direct |
| Bleu, un tour | nouveau |
| Violet fixe | profil sélectionné |

## Règles

- **Une seule lumière en mouvement par écran** : la plus urgente.
- **Pastille et mot obligatoires** : la couleur ne parle jamais seule.
- **Uniquement des états fournis par le serveur** : aucune lumière déduite sur l'appareil.
- **Un seul composant**, dans le core : celui du halo de NAV-REFONTE.
- **Persistance** : la lueur reste tant que la situation dure. La rotation se rejoue à l'ouverture
  de l'écran et au retour sur l'écran, jamais en boucle infinie.

## Ordre du lot

1. **Ronds des profils du foyer**
   - profil sélectionné : violet ;
   - salle ouverte : vert ;
   - enfant en retard (séance en direct, enfant absent) ou accès bloqué : rouge ;
   - séance dans moins d'une heure avec quelque chose à préparer : orange ;
   - cahier de séance déposé ou nouveau résultat : bleu.
2. **Accueil de l'élève et de l'enfant**
   - lumière verte sur « Rejoindre ma classe » ;
   - tour doré à la fin d'une sourate (progression comptée par sourate).
3. **Aujourd'hui de l'enseignant** : élèves absents ou en retard, demandes, cahier à remplir.
4. **Accueil de la direction** : incidents, dossiers en attente.

## Des accueils plus vivants, sans couleur ajoutée ailleurs

- Carte « prochaine séance » en tête, avec compte à rebours.
- Anneau de progression par sourate autour de la photo de l'élève.
- Micro-animations de réussite (`DECISION-FLUIDITE`).
- Illustrations Silhouette de la marque dans les états vides.

## Avant tout code

- Croquis validés par le directeur.
- Vocabulaire : compétence `mots-rewayah` pour tout texte ; on ne change un mot que sur décision
  datée du directeur.

Inscrit dans la table « Lire » de `CLAUDE.md`.
