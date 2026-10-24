# La salle de cours : plan de refonte (pilotage, 24/10/2026)

Décision du directeur, le 24/10 au soir, après l'essai K4 (enseignant et enfant ensemble en
production, audio dans les deux sens, vidéo de l'enseignant vue par l'élève) : « la vidéo marche,
l'audio aussi ; le rendu de la salle est désorganisé ; il faut un plan pour ne pas s'éparpiller ».
Ce plan est la seule feuille de route de la salle. Un lot à la fois, une pull request par lot,
captures avant toute fusion, preuve par le directeur en production après fusion.

## Ce que le directeur a dit, et qui fait loi

- La page du Coran prend tout l'écran ; les commandes apparaissent au toucher ; rien de fixe.
- On doit sentir qu'on est entré : fond sombre, vignettes vidéo avec le prénom, état clair.
- Micro, caméra, sortir : des boutons que tout le monde connaît, avec un signal fort allumé/éteint.
- Rien n'est surdimensionné sur ordinateur ; pas d'écran blanc ; pas de panneaux de consignes.
- La qualité vidéo doit être bonne sur un bon réseau, et se dégrader seule sur un mauvais.
- La caméra de l'élève doit marcher quand le tuteur l'a autorisée.
- **Loi du directeur, 24/10/2026 (soir)** : « Sur téléphone, la page du Coran EST l'écran. Une page A4 = un écran de smartphone. Rien au-dessus, rien en dessous, rien à côté. »

## Standard des commandes d'appel (directeur, 24/10/2026, nuit)

Après la capture du tableau au téléphone (« trop nul » : libellés sur deux lignes, boutons mal
alignés, chevron « ^ » sans libellé à côté de la barre), le directeur interdit de **deviner** la
disposition : on suit un standard public. **Référence : Google Meet sur Android et sur le web
(Material 3).** Il s'applique partout (salle, tableau, tous rôles, toutes largeurs) et remplace,
dans la salle, le mot d'état sous le bouton (ETATS-BTN-1), les deux rangées à texte agrandi
(ETATS-MA-1) et le dock compact du Mode Accessibilité (MA-CMD-1).

1. Barre d'appel : UNE pilule flottante, centrée en bas, marge 16 et zone sûre, fond translucide
   (surface à 85 %), rayon plein. Une seule rangée de boutons ronds identiques : 56 au téléphone,
   48 sur ordinateur ; écart constant 12 au téléphone, 16 ailleurs. **Icônes seules**, jamais de
   texte sous un bouton ; le libellé vit dans l'infobulle (survol, appui long) et la sémantique.
   Ordre fixe : micro, caméra, tableau (enseignant), plus (⋯), puis Quitter.
2. États : actif = cercle rempli sombre, icône claire ; coupé ou éteint = cercle rempli rouge,
   icône barrée ; Quitter = pilule rouge plus large (72 × 56), icône du combiné ; tableau ouvert =
   rempli de la couleur primaire. Aucun gris (K-56).
3. « Plus » (⋯) est dans la pilule, même taille que les autres, et ouvre les Commandes
   (Bibliothèque, Outils, Élèves). Aucun déclencheur hors de la pilule.
4. Ligne d'état : une pilule translucide en haut à gauche, hauteur 36, une seule ligne :
   « ● En ligne · Visite de contrôle possible » (ADR-011 tenu). Élèves : bouton rond icône
   « personnes » avec la pastille du nombre, en haut à droite à côté de la vignette vidéo, jamais
   un lien texte.
5. Tableau : aucune phrase au centre ; une feuille vide est une feuille vide. Sa palette est une
   seconde pilule, verticale au bord droit (ordinateur) ou horizontale juste au-dessus de la
   barre d'appel (téléphone), mêmes tailles, icônes seules, outil actif rempli : stylet,
   surligneur, gomme, annuler, tout effacer, fermer le tableau.
6. Alignement : tous les éléments flottants sur une grille de 8, même marge 16 des bords ; la
   pilule du haut et la vignette alignées sur la même ligne.
7. Tout disparaît à 3 s et revient au toucher.

## Les maquettes

Le directeur a fourni des maquettes de la salle à des sessions précédentes, puis les a
supprimées de son côté. Recherche du 24/10 : aucune image de maquette de la salle dans le dépôt
(toutes les branches, l'historique, la PR 50), ni dans les envois de cette session, ni dans le
Drive par leur nom. Les seules traces sont écrites : dossier maître du 14/10 §4.3 (« support
dominant, deux vignettes secondaires qui ne couvrent jamais le support », « très peu de boutons »)
et `03_DESIGN_SYSTEM_ET_UX.md` §Salle pédagogique. Si le directeur retrouve les images, il les
dépose dans `docs/current/maquettes/salle/` et le lot en cours s'y aligne avant sa pull request.

## Les lots, dans l'ordre

| Lot | Contenu | Preuve |
| :-- | :-- | :-- |
| S0, en cours (D9, D10, D12, D14, D15, D16) | Page Madina 15 lignes plein écran des deux côtés ; surimpression au toucher ; vignettes vidéo au coin ; retour en salle ; caméra de l'élève allumée dès l'autorisation, avec l'erreur exacte affichée si le navigateur refuse ; 720p en trois couches ; journal des pistes caméra et micro côté serveur | Captures 390 portrait, 390 paysage, 1366, des deux côtés, validées par le directeur avant la pull request ; puis essai en production, de préférence l'élève sur un téléphone |
| S1 | « On est dans la salle » : scène sombre à l'entrée avec les vignettes nominatives, message d'entrée d'une ligne, boutons micro, caméra, sortir au vocabulaire universel (icône barrée en rouge quand c'est coupé, « Quitter » rouge), tailles justes sur ordinateur, états loading, error, offline sur la même scène | Captures, puis essai en production |
| S2 | Qualité et mesure : couche 720p demandée quand une vidéo est agrandie, audio seul visible, lecture du tableau de bord LiveKit par le directeur (région, trajet), écouteurs filaires pour l'essai du décalage | Essai en production avec chiffres |
| S3, après la Boucle 1 | Outils de l'enseignant en salle (synchronisation de page, pointage, fiche de séance) | Selon `01_PRODUIT_ET_PARCOURS.md` |

Rien d'autre sur la salle tant que S0 n'est pas prouvé. Les reliquats d'interface hors salle
restent dans la pull request des reliquats (`PILOTAGE-BOUCLES-2026-10-24.md`).
