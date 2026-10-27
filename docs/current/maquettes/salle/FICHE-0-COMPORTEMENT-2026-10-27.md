# Fiche 0 : le comportement de la salle (27 octobre 2026)

**Autorité.** Cette fiche dit ce qui doit être vrai dans `/salle` à chaque événement, pour chaque
rôle, avant tout écran. Les fiches d'écran (fiche 1 téléphone, fiche 2 iPad et ordinateur) lui
obéissent ; quand une ligne d'une fiche d'écran la contredit, cette fiche prévaut. Elle est écrite
par le pilote le 27/10/2026 à partir : des constats du directeur en production les 26 et 27/10
(au départ de l'enseignante, la page du Coran, les mentions et les écritures du tableau restaient
chez l'élève ; rien ne s'effaçait non plus quand l'élève sortait et revenait) ; de
`docs/current/01_PRODUIT_ET_PARCOURS.md` et `06_SPEC_FONCTIONNELLE_MVP.md` ; des usages de Meet
et de Zoom ; de l'inventaire du code du 27/10 (ce qui est codé, ce qui manque). Les arbitrages du
pilote sont marqués **[arbitrage]** ; le directeur peut les renverser par numéro.

**Contrat.** Une ligne = un fait = un test à deux appareils (l'enseignante et un élève, parfois un
tuteur), ×1 et ×2, français et arabe ; la preuve finale est le directeur avec deux appareils sur
l'aperçu de la PR, puis en production.

**Mots.** « L'enseignante » désigne la personne qui tient la séance, quel que soit son genre
dans les textes i18n (le vocabulaire de `mots-rewayah` s'applique aux libellés).

## A. L'enseignante quitte

| N° | Ce qui doit être vrai | Source |
| :-- | :-- | :-- |
| 1 | **« Quitter » chez l'enseignante** ouvre un choix à trois boutons : « Terminer la séance » (pour tout le monde), « Sortir, la séance continue », « Annuler ». | Zoom (End meeting for all / Leave) **[arbitrage]** |
| 2 | **Terminer** : dans les 2 s, chaque élève, tuteur et contrôleur voit « La séance est terminée. » plein écran, sans page, sans tableau, sans encre ; après 5 s, ou au toucher de « Fermer », chacun revient à sa page de départ (Classe, accueil, compte rendu). L'enseignante va à son écran « Terminée » (cahier). | Meet, 01 § Après séance |
| 3 | **Sortir** : dans les 2 s, chez chaque élève, la page présentée se retire, le tableau se ferme, les encres et le pointeur disparaissent de l'écran ; la scène d'attente « En attente de {Nom} » s'affiche avec le bandeau « L'enseignante est sortie. La séance continue. ». | Meet (le partage s'arrête avec celui qui partage) |
| 4 | **Retour de l'enseignante** dans la même séance : la page et le tableau ne reviennent chez les élèves que si elle les présente de nouveau ; les traits qu'elle avait faits reviennent avec le tableau (ils restent gardés sur son appareil pendant la séance). | 01 § Classe et supports (continuité) **[arbitrage]** |
| 5 | **Limite connue** : tant que le serveur n'enregistre pas la fin (migration à coller par le directeur), une personne qui entre après « Terminer » voit la scène d'attente, pas « terminée ». Dite dans la PR qui applique la ligne 2. | inventaire 27/10 |

## B. Coupures de réseau

| N° | Ce qui doit être vrai | Source |
| :-- | :-- | :-- |
| 6 | **L'enseignante perd le réseau** sans Quitter : pendant 120 s (fenêtre de reconnexion de la présence), chez l'élève la page reste, figée, avec le bandeau « Connexion de l'enseignante interrompue. » ; la vignette montre son avatar, jamais la vidéo d'un autre participant. | présence J3 (120 s), Meet |
| 7 | **Elle revient** dans les 120 s : le bandeau disparaît, la page, le tableau et les traits sont rejoués chez chaque élève. **Passé 120 s** : même effet que « Sortir » (ligne 3). | 06 § LiveKit (« retrouvent support après coupure ») |
| 8 | **L'élève perd le réseau** : sa propre pastille dit « Lien coupé », la page reste figée ; à son retour, page, tableau et traits lui sont rejoués en moins de 3 s si l'enseignante est là, sinon il voit la scène d'attente (ligne 3). | 06 § Outils enseignant |
| 9 | **L'élève quitte et revient** (« Retourner dans la salle ») : même rejeu que la ligne 8. | existant |

## C. La vignette et la scène

| N° | Ce qui doit être vrai | Source |
| :-- | :-- | :-- |
| 10 | **La vignette de l'élève** ne montre jamais qu'une personne : l'enseignante (sa vidéo, ou son avatar si sa caméra est éteinte ou si elle est absente). Aucun repli vers un autre participant. | constat 27/10 (le code bascule vers un autre participant sous le nom de l'enseignante) |
| 11 | **L'élève ne voit jamais la vidéo des autres élèves**, ni leur liste ; sa ligne d'état dit « {n} élèves en salle ». Quand rien n'est présenté, sa scène montre l'enseignante en grand. | décision Q7 (décidée, jamais appliquée) ; protection des mineurs **[arbitrage : Meet montre tout le monde, nous non]** |
| 12 | **L'enseignante voit** les vidéos de ses élèves sur la scène, et sa feuille Élèves avec présence, micro et caméra de chacun. | fiche 1 l. 10, fiche 2 |
| 13 | **Le pointeur** de l'enseignante disparaît chez l'élève 2 s après son dernier mouvement. | Meet, Zoom **[arbitrage]** |

## D. Tuteurs et visites

| N° | Ce qui doit être vrai | Source |
| :-- | :-- | :-- |
| 14 | **Un tuteur en visite est invisible et muet** : aucune vidéo, aucune tuile, aucune vignette, pour personne, à aucun moment. | migration 0040, 01 § Rôles |
| 15 | **Son enfant seul** voit la ligne « Ton parent observe la séance. » (« Votre parent observe la séance. » pour un adulte), avec un point rouge fixe, sans clignotement ; les autres élèves ne voient rien. | existant (sans le clignotement) **[arbitrage]** |
| 16 | **L'enseignante** voit « Un parent observe. » ; avec plusieurs tuteurs en même temps : « {n} parents observent. », sans prénoms. La ligne disparaît dans les 10 s après la fin de la dernière visite. | constat 27/10 (aujourd'hui singulier seulement) **[arbitrage]** |
| 17 | **Le tuteur voit** ce que voit son enfant, sans pouvoir y toucher : l'enseignante en grand, la page et le tableau quand ils sont présentés ; le rappel « Vous assistez au cours. Vous n'êtes pas entendu. » ; le temps de visite restant. À l'épuisement du temps : « Fin de la visite. » puis retour à sa page de départ. | 01 § Rôles (observation bornée) **[arbitrage : aujourd'hui il ne voit aucune page]** |
| 18 | **Le contrôleur et l'administration incognito** sont invisibles ; aucun signal en direct à personne ; la mention permanente « Visite de contrôle possible. » reste l'information générale voulue par 01. | 01 § Classe et supports, ADR-011 |

## E. Enregistrement et états

| N° | Ce qui doit être vrai | Source |
| :-- | :-- | :-- |
| 19 | **Aucun enregistrement n'existe** : « Cours enregistré » et un point rouge d'enregistrement n'apparaissent nulle part. La fiche 1, ligne 2, est amendée : le point de la capsule est vert quand l'enseignante est connectée, gris quand sa connexion est interrompue. | 06 § Enregistrement (amendement du 11/10), DECISION-ENTREE l. 33 |
| 20 | **« En ligne »** dans la ligne d'état de l'élève dit l'état de sa propre connexion ; l'état de l'enseignante se lit dans le bandeau des lignes 3 et 6, jamais ailleurs. | existant, clarifié |

## F. Durées

| N° | Ce qui doit être vrai | Source |
| :-- | :-- | :-- |
| 21 | **Les commandes qui se masquent** le font après 3 s partout (téléphone, iPad, ordinateur) ; le délai de 4 s disparaît. | Meet **[arbitrage]** |
| 22 | **Les bandeaux d'événement** (sortie, connexion interrompue, parent qui observe) restent tant que l'état dure ; **les avis ponctuels** (« Connexion rétablie. », « De retour ») disparaissent après 4 s. | Material 3 (snackbar 4 s) |
| 23 | **L'heure de fin dépassée** : « La séance se poursuit. » reste ; rien ne coupe la séance tout seul, seule l'enseignante termine (ligne 1). Le serveur cesse de laisser entrer 20 min après l'heure de fin (existant). | existant |

## G. Preuve

| N° | Ce qui doit être vrai | Source |
| :-- | :-- | :-- |
| 24 | **Chaque ligne** est un test à deux appareils simulés (l'enseignante et un élève ; un tuteur pour 14 à 17) et le directeur la vérifie avec deux appareils sur l'aperçu de la PR, avant fusion. | contrat de l'écran §2 |

## État

| Lignes | Spécifié | Codé | Prouvé par le directeur |
| :-- | :-- | :-- | :-- |
| 1 à 24 | 27/10 | aucune (l'inventaire du 27/10 dit ce qui existe en partie : 8, 9, 14, 15, 18, 20, 23) | |

## Journal

- 27/10 : écrite par le pilote après le constat du directeur (départ de l'enseignante sans effet chez
  l'élève) et l'inventaire du code. Trous relevés par l'inventaire et couverts ici : départ de
  l'enseignante (1 à 5), vignette sans enseignante (10), fin de séance (2, 5), retour de
  l'enseignante (4), élève qui revient sans enseignante (8), vidéos des autres élèves (11),
  plusieurs tuteurs (16), ce que voit le tuteur (17), budget du tuteur épuisé (17), clignotement
  (15), délai des avis (22).
