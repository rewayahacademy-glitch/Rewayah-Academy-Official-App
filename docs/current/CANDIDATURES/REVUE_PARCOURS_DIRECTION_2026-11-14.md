# Revue du parcours recrutement côté direction — 14/11/2026

Origine : plainte du directeur (14/11/2026) : dans le dossier d'un candidat
(« Personnes › Candidatures › {nom} »), « Écrire à {nom} » le faisait sortir
vers les Messages, et il fallait une dizaine d'actions pour revenir. Règle
retenue : **tout se fait depuis le dossier, retour compris** ; le bouton retour
ramène à la liste filtrée d'où l'on vient, à la même position.

Statuts : `présent dans le code` et `testé localement` seulement. Rien n'est
prouvé en production tant que le directeur ne l'a pas fait lui-même.

## Gestes du dossier, un par un

| Geste | Constat avant | Règle | Correction |
| :--- | :--- | :--- | :--- |
| Écrire à {nom} | Quittait le dossier (`go` vers Messages) ; retour = panneau, Personnes, Candidatures, recherche | Le dossier ne se quitte pas ; Material 3 « side sheet » sur ordinateur, feuille au téléphone (Apple HIG, Nielsen n° 3 « contrôle et liberté ») | La conversation se déplie dans le dossier : volet à droite à 840 points et plus, surface plein écran en dessous ; « Replier la conversation » ramène au dossier, même adresse, même position. Même fil que Messages (`FilContextuel` : temps réel, coches « lu », envoi honnête), rien de recréé (`FilEnPlace`, `VoletConversation`) |
| Ouvrir dans Messages | N'existait pas en lien secondaire | Lien secondaire, jamais une sortie sans retour | « Ouvrir dans Messages » dans le volet ; la page s'**empile** (`push`) : son retour ramène au dossier |
| Accepter / Refuser / Demander une précision ; Concluant / Non concluant / À refaire ; Accueillir / Ne pas accueillir ; confirmer ou écarter un moyen de versement ; pause ; retrait | Déjà dans le dossier : une feuille de confirmation par geste (`feuille_geste.dart`), le geste principal en un clic, les autres dans le menu de la prochaine action | Un geste, une confirmation, sur place | Aucune ; conforme |
| Pièce d'identité : voir et valider | Déjà sur place (`PieceSurPlace` réutilise `RevueDossier`) ; seul le cas « pièce hors de la file » proposait « Dossiers à valider » par `go`, donc sans retour | Le chemin de secours garde le retour | `push` : le retour de « Dossiers à valider » ramène au dossier |
| Entretien : planifier, ajouter ou retirer une personne, compte rendu, issue | Déjà dans le dossier, en feuilles | Sur place | Aucune ; conforme |
| Rejoindre l'entretien | Ouvre la salle vidéo (`go`) | Sortie justifiée : c'est la salle | **Reste** : la sortie de la salle mène à l'accueil de l'administration, pas au dossier (voir « Ce qui reste ») |
| Photo, contact, historique, réponses | Lecture sur place ; le contact dans une feuille | Sur place | Aucune ; conforme |
| Copier le lien d'inscription | Feuille sur place | Sur place | Aucune ; conforme |
| Retour du dossier | Ouvert depuis la liste par `push` : le retour la retrouve avec ses filtres et sa position. Ouvert depuis « Entretiens du jour » ou depuis un message par `go` : le retour tombait sur la liste **sans filtre** | Le retour ramène d'où l'on vient | « Voir la fiche » (entretiens du jour) et « Voir le dossier » (aperçu dans Messages) empilent le dossier (`push`) |

## Ce qui reste (non corrigé ici)

- **Sortie de la salle d'entretien** : corrigée le 14/11 au soir
  (`VISION_RECRUTEMENT_2026-11-14.md`) : la salle ramène au dossier du candidat.
- **Profil du candidat** : aucun lien « profil » dans le dossier aujourd'hui ;
  rien à corriger, mais rien à prouver non plus.
- **Décision de pièce hors genre** : la phrase écrite ici plus tôt était
  **inexacte**. `valider_piece_candidat` passe par le moteur des gestes, qui
  laisse agir le super-admin des deux côtés depuis V1-a-bis (03/11), avec
  trace ; aucun refus hors côté n'est enregistré en production. Seuls les
  gestes **en lot** restaient bornés : ouverts au super-admin par la migration
  20261126400000 (décision A15 du 14/11).
