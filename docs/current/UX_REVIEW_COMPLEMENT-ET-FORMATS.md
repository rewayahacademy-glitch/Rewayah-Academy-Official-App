# UX_REVIEW COMPLEMENT-ET-FORMATS (14/11/2026)

Lot COMPLEMENT-ET-FORMATS. Demandes du directeur (14/11) : « cette page [Demander un complément]
manque d'éléments qu'on peut demander à compléter » ; « Pourquoi permettre à l'user de l'envoyer si
c'est pour le refuser des jours après ? […] je veux savoir les formats admis et comment empêcher les
gens de déposer sauf au format demandé ». Le pilote a fixé l'ordre du parcours, deux groupes, une
seule colonne, pas d'onglets (consigne 19 : le directeur ne tranche pas l'UX).

Cette note justifie les choix de disposition (DESIGN-GOV §4). Elle ne change ni permission, ni règle
KYC, ni état serveur (§4.3) : la liste des éléments vient du serveur, et la décision sur la pièce
reste celle de `decider_dossier`.

| # | Règle | Source | Conclusion | Modification |
| :-: | :-- | :-- | :-- | :-- |
| 1 | Grouper ce qui va ensemble, titre de groupe court | Gestalt (proximité) ; Material 3, *Lists* (sous-titres de section) | Treize éléments en une seule liste se lisent mal. Deux groupes séparent ce que la personne a répondu de ce qu'elle a signé ou déposé | `FeuilleGeste` : « Réponses » puis « Documents et accords », chacun un `ChoiceCardGroup` à choix multiple |
| 2 | L'ordre suit la tâche de la personne | Nielsen n° 2 « Correspondance avec le monde réel » | Les documents sont rangés dans l'ordre où le candidat les fournit : cadre, contrat, avis, code de conduite, pièce, photo, accord de publication | `codesDocumentsEtAccords` (`libelles_candidature.dart`) ; ordre identique côté serveur (`20261126800000`) |
| 3 | Pas d'onglets sur ordinateur, une seule barre de défilement | Consigne 19 ; DECISION-DEFILEMENT-2026-11-01 | Une seule colonne dans la feuille, qui défile avec la page | Aucun `SelecteurSection` |
| 4 | Prévenir l'erreur plutôt que la signaler tard | Nielsen n° 5 « Prévention des erreurs » ; Baymard (formats de fichiers annoncés avant le choix) | Les formats admis sont dits sous « Choisir la photo » ; la boîte du système ne propose que JPEG et PNG ; un autre format est refusé au choix, avant l'envoi | `depot_piece_page.dart` (`fichiers.formatsPiece`) ; `preparerFichier` |
| 5 | Un message d'échec dit quoi faire | K-59 ; Nielsen n° 9 | Chaque refus (format, HEIC non convertible, taille) a sa phrase avec l'action suivante | `phraseRefusFichier` |
| 6 | Ne pas faire sortir d'un dossier pour un geste simple | Consigne 19 ; L3 de RETOURS-TERRAIN | Une pièce ou une photo illisible le dit dans le dossier ; « Demander une nouvelle pièce d'identité » ouvre la feuille du complément, l'élément déjà coché | `PieceSurPlace`, `BlocPhotoDossier`, `ouvrirFeuilleGeste(elementsInitiaux:)` |
| 7 | Une action secondaire est un lien, pas un bouton plein | K-56 | Le geste « Demander une nouvelle pièce » est un `LienFleche` ; le seul bouton plein reste celui de la feuille | aucun nouveau bouton plein |

## Ce qui n'est pas prouvé

- Rien n'a été vu par le directeur en production ; la migration `20261126800000` n'est pas installée.
- La conversion HEIC dans le navigateur (Safari sur iPhone) n'est pas testée sur un vrai iPhone :
  les tests remplacent le convertisseur. Sur iPhone, la boîte de choix sans HEIC fait aussi convertir
  la photo par le système.
