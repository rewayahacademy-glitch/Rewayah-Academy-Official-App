# UX_REVIEW_TELEPHONE-REDUIT : le téléphone de l'enseignant (11/11/2026)

Lot TELEPHONE-REDUIT. Demandes : cahier de la salle §9 (« Le téléphone réduit », décision du
10/11, « discutable avec preuves ») ; demande du 11/11 (sortir de l'écran de la salle sans couper
la séance, Q1 de `salle/SORTIES-DE-LA-SALLE.md`) ; cahier §8 (« le chronomètre est caché dans une
carte dépliable au téléphone »).

**Ce qui n'est pas prouvé.** Tout est vérifié par des tests locaux et des captures **de test**
(390 x 844, le vrai écran `/salle` monté avec un faux serveur de visio). Rien n'a été essayé en
production ni sur le banc : le banc `salle-banc/classe-6/` n'a **aucune** capture de l'enseignant
au téléphone. Le pointeur au doigt, au téléphone, n'a jamais été rejoué chez un élève réel.

## 0. Ma conclusion sur le §9, en une ligne

**Le §9 est juste pour l'élève, faux pour l'enseignant sur trois points** : un enseignant qui n'a
qu'un téléphone doit pouvoir **ouvrir et partager un support** (sinon personne ne le partage et
« suivre le support partagé » ne veut rien dire), **voir ses élèves et faire réciter** (c'est le
cœur d'une séance de Coran), et **réduire la salle**. Le reste du §9 est juste : écrire et le
tableau n'ont pas leur place au téléphone.

Preuves :
- L'académie dit elle-même aux familles que le téléphone suffit : « Tablette ou ordinateur
  conseillé pour le cours. Le téléphone reste pris en charge. » (`tc.groupe.session.conseilAppareil`,
  `assets/i18n/fr.i18n.json`). Aucune règle de `docs/current/` n'exige un ordinateur de
  l'enseignant (`PLAN-TROIS-SALLES-2026-11-07.md` : la salle 3 est « l'application de
  l'enseignant », sans appareil imposé ; `VISION-ECOLE-2026-11-05.md` : « l'enseignant ne fait pas
  de corvée »).
- Le journal de la salle l'avait déjà écrit (D-006, réserve) : « l'enseignant au téléphone doit quand
  même pouvoir tourner la page et ouvrir un support déjà choisi pour la classe, sinon un enseignant
  dont l'ordinateur tombe en panne ne peut plus faire cours ».
- Seul l'enseignant partage un support (`peut_piloter`, serveur) : sans « Partager » au téléphone,
  sa classe n'a plus de page à suivre.
- « Faire réciter » est tenu par le serveur depuis D-014 (les micros des autres se ferment) : c'est
  le geste qui permet d'entendre chaque lettre d'un élève (cahier §5, « absolu et non négociable »).

## 1. Inventaire : ce que l'enseignant pouvait faire au téléphone avant ce lot

Relevé dans le code au commit `156c31032` (`telephone_plein_ecran.dart`, `telephone_enseignant.dart`,
`barre_outils_salle.dart`, `dock_seance.dart`) et sur les captures `avant-*` de
`captures/E2E/telephone-reduit/`. Un « geste » = un appui ; le premier toucher de la page (qui fait
apparaître les commandes) compte pour un.

| Commande | Où | Gestes |
| :-- | :-- | :-- |
| Tourner la page | glisser au doigt sur la page (`GlisserPage`) | 1 |
| Zoomer | pincer, double toucher (D-013 : plus de bouton) | 1 |
| Micro, Caméra | pilule du bas, au toucher | 2 |
| Élèves (feuille : présence, cartes) | pilule du bas, au toucher | 2 |
| Faire réciter, Appeler, autoriser à écrire | carte d'un élève dépliée dans la feuille | 4 |
| Quitter (question : Réduire la salle, Quitter et ouvrir le cahier, Rester) | pilule du bas | 2 (+1) |
| **Réduire la salle** | seulement dans la question de Quitter, ou par le retour du téléphone | **3** |
| Voir la vidéo en grand | œil de la capsule, au toucher | 2 |
| **Chrono, état, mention de contrôle** | **ligne d'état du profil**, capsule dépliée | **2** |
| Pause | ligne d'état du profil (si le serveur la permet) | 3 |
| Ouvrir un support (étagère, fiche, Partager ou Afficher) | tiroir « Commandes », onglet Bibliothèque | 4 |
| Ranger le support | tiroir, onglet Bibliothèque | 3 |
| Ouvrir ou fermer le tableau | tiroir, onglet Bibliothèque | 3 |
| Stylo, Surligner, Gomme, Annuler, couleurs | tiroir, onglet Outils | 4 |
| **Pointeur** | **absent** (« Pointeur n'est pas au téléphone », réponse L8 du 26/10, `barre_outils_salle.dart`) | impossible |

Deux écarts entre les documents et le code, relevés ici :
- D-014 écrit « au téléphone, l'enseignant arme le pointeur dans l'onglet Outils » : **faux**,
  l'onglet Outils n'avait que Stylo, Surligner, Gomme, Annuler.
- `lib/CLAUDE.md` décrit un tiroir à **trois** onglets (Support, Outils, Séance) : le code n'en a
  que deux (Support, Outils) ; l'onglet Séance a été retiré avant ce lot.

## 2. Ce que le §9 garde, ce qu'il retire, et mon avis commande par commande

| Commande | §9 | Mon avis | Fait dans ce lot |
| :-- | :-- | :-- | :-- |
| Rejoindre, voir et entendre | garde | garder | inchangé |
| Micro, Caméra | garde | garder | inchangé |
| Quitter | garde | garder | inchangé |
| Pointeur | garde | garder, **et le créer** : il n'existait pas | **ajouté**, à côté de « Commandes » (2 gestes) ; tenu, il reste visible au repos et se repose d'un appui |
| Tourner la page | (suivre le support) | garder | inchangé (glisser au doigt) |
| Ouvrir, partager, ranger un support | retire (implicite) | **garder** (sans lui, rien à suivre) | gardé : le tiroir n'est plus que la Bibliothèque |
| Élèves, Faire réciter, Appeler | retire (implicite) | **garder** | gardé, inchangé |
| Réduire la salle | (non cité) | **garder, visible** | **ajouté** au début de la capsule (2 gestes au lieu de 3) |
| Chrono et état | (non cité) | garder, **visible au repos** | **l'île** posée en haut au repos, à la place de la capsule (0 geste) |
| Voir la vidéo en grand | (voir et entendre) | garder | inchangé |
| Pause | (non cité) | garder | par l'île (même composant que l'ancienne ligne d'état) |
| Écrire (Stylo, Surligner, Gomme, Annuler, couleurs) | retire | **retirer** : le doigt cache ce qu'il écrit, un trait au doigt sur une ligne de 4 mm est illisible, et le même doigt glisse déjà la page et pointe (conflit de gestes) | **retiré sous 600 points** ; une phrase le dit dans le tiroir |
| Tableau (ouvrir) | retire | **retirer** : sans écriture, un tableau blanc ne sert à rien au téléphone | **retiré sous 600 points** ; ouvert ailleurs, sa ligne reste pour le **fermer** |
| Retirer un élève, régler la classe | retire | retirer (n'existe pas dans la salle) | rien |

Sur tablette (600 points et plus, iPad en portrait compris) et sur ordinateur, **rien ne change** :
le tiroir garde ses deux onglets, l'écriture et le tableau. Ce qui est retiré du téléphone reste
atteignable sur tablette et ordinateur, et le tiroir le dit : « Pour écrire sur la page ou ouvrir le
tableau, utilisez une tablette ou un ordinateur. » (jamais un bouton grisé, `lib/CLAUDE.md`).

## 3. « Réduire la salle » : pourquoi au début de la capsule, et pas dans la pilule

| Place essayée | Résultat | Décision |
| :-- | :-- | :-- |
| Dans la pilule, juste avant Quitter (comme l'ordinateur) | Mesuré sur la capture `avant-390-fr-light-toucher` : les quatre disques nommés prennent environ 330 des 358 points utiles à 390. Un cinquième (« Réduire ») fait passer la pilule sur **deux rangées** à 390 en texte normal : elle grossit, ce que la fiche 1 (ligne 4) et SORTIE-SALLE excluent | écarté |
| À la place d'un disque moins utile | Micro, Caméra, Élèves, Quitter servent tous à chaque cours | écarté |
| Première ligne du tiroir | 3 gestes (toucher, Commandes, Réduire) : pas plus visible que la question de Quitter | écarté |
| **Au début de la capsule du haut** | La place du retour sur un téléphone (WhatsApp, Google Meet et Teams mettent « réduire l'appel » en haut au début ; Apple HIG et Material 3 : le retour en haut au début) ; **le même geste que le retour du téléphone**, qui réduit déjà la salle depuis SORTIE-SALLE ; la même icône que la tuile « Réduire » de l'ordinateur (`AppIcons.retour`) ; la capsule passe d'environ 216 à 272 points et tient à 320 ; la pilule ne change pas | **retenu** |

Le bouton est une icône (cible de 48) ; son infobulle dit « Réduire la salle » et le lecteur d'écran
lit « Réduire la salle : la séance continue et vous entendez toujours la classe ». Il n'apparaît que
si l'appel peut continuer hors de l'écran (`ActionsSeance.onRetour` non nul, sens posé par
SORTIE-SALLE). L'Interface guidée garde le choix de SORTIE-SALLE : pas de « Réduire » (garde dans le
code, même si l'enseignant n'y est jamais). Il est aussi rendu sur iPad en portrait (sous 840
points, même capsule) : c'était le même trou.

## 4. Le chrono au repos

Avant : chez l'enseignant au téléphone, l'île n'était **pas** posée (la composition ne rendait que la
capsule, masquée au repos) ; le chrono ne se lisait qu'en dépliant le profil, en deux gestes. C'est
exactement le défaut du cahier §8. Après : **au repos**, l'île (`PiluleEtatSalle`, repliée, D-011)
est posée en haut au début, **à la place de la capsule** ; au toucher, la capsule (vidéo, « Réduire
la salle », œil) prend la même place pendant trois secondes, et son profil redit la ligne d'état.
Une première version posait l'île au-dessus de la capsule, toujours : à 360 en texte x2, la pilule
de l'appel débordait de 25 à 61 points (mesuré par le test) ; écartée. Même règle sur iPad en
portrait (même composition, sous 840). Sur la scène vidéo en grand (sans page), la capsule reste
seule, l'île n'y est pas posée (limite dite, le profil garde le chrono).

Limite des captures : le faux serveur des tests ne donne pas d'heure de séance ; l'île y montre
« En ligne · Visite de contrôle possible. » (la mention reste dépliée 10 s à l'entrée, D-011) et
pas le temps restant. Le chrono lui-même n'est pas montré par ces captures.

## 5. Règles et sources

| Règle | Source | Conséquence ici |
| :-- | :-- | :-- |
| Rien ne recouvre ni ne pousse la page du Coran | directeur, 11/11 (règles des agents) | l'île est petite et repliée, posée comme chez l'élève (lot CORAN-ELEVE) ; la pilule ne grossit pas |
| Un bouton qui ne peut pas aboutir n'est pas rendu, une phrase dit la limite | `lib/CLAUDE.md`, pièges payés | phrase « Pour écrire sur la page… » ; pas de bouton grisé |
| ONGLETS-1 | `lib/CLAUDE.md` | un onglet vidé disparaît : le tiroir n'a plus de sélecteur sous 600 |
| Fiche 1, lignes 4 et 14 | `maquettes/salle/FICHE-1-TELEPHONE-2026-10-26.md` | pilule inchangée ; rien ne se recouvre à 390 et à 360 en texte x2 (testé) |
| SORTIE-SALLE : `onRetour` seulement si l'appel est tenu ; pas de « Réduire » en guidée | `salle/SORTIES-DE-LA-SALLE.md` | repris tel quel |
| Fitts, Jakob (conventions des plateformes) ; Apple HIG (navigation) ; Material 3 (top app bar) ; WCAG 2.5.8 (cible) | références de DESIGN-GOV §4 | « Réduire » au début du haut ; cibles de 48 |
| Le public : les enseignants les moins à l'aise ; moins de clics, un seul endroit par chose | directeur, 11/11 | Réduire 3 → 2 gestes, chrono 2 → 0, pointeur impossible → 2 |

## 6. Limites dites

- Toucher la page pour pointer fait aussi revenir les commandes (comportement de
  `CommandesMasquables`, inchangé) : la pilule réapparaît trois secondes en bas pendant qu'on pointe.
  À essayer sur le banc avant d'en décider.
- À 360 en texte x2, la case du Pointeur passe au disque seul (nom dans l'infobulle et la voix),
  pour que la rangée tienne au-dessus de la pilule.
- Au téléphone, un enseignant sans droit de présenter qui touche « Commandes » trouve la seule
  Bibliothèque (avant : la ligne Tableau). Cas relevé par le test C11 de la fiche 1, non changé.
- Le Pointeur est montré à côté de « Commandes » quand le serveur le permet (`voitOutils`) ; sans
  support présenté, il n'apparaît pas.
- Le mot « Commandes » ouvre désormais la seule Bibliothèque au téléphone : le mot est resté (moins
  de changements de textes) ; « Supports » serait plus juste (Q3).

## 7. Questions au directeur

| # | Question | Ma recommandation |
| :-- | :-- | :-- |
| T1 | Le §9 est-il amendé pour l'enseignant : garder au téléphone ouvrir et partager un support, voir ses élèves et « Faire réciter », réduire la salle ? | Oui (appliqué ainsi, rien de cela n'est retiré) |
| T2 | Écrire et le tableau sont-ils bien retirés du téléphone de l'enseignant (sous 600 points), avec la phrase qui renvoie à la tablette ou l'ordinateur ? | Oui (appliqué) |
| T3 | Renommer « Commandes » en « Supports » au téléphone, puisqu'il n'ouvre plus que la Bibliothèque ? | Oui, petit lot de textes |
| T4 | « Réduire la salle » au début de la capsule du haut (et non dans la pilule, qui passerait sur deux rangées) vous convient-il ? | Oui |
| T5 | Pendant qu'il pointe, la pilule doit-elle rester cachée ? | Oui, à décider après un essai sur le banc |
