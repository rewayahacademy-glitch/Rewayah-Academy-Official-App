# Décisions déléguées à l'orchestrateur (02/10/2026)

Le 02/10, le directeur a répondu aux points qu'il pouvait trancher sur la planche du Contrôleur. Pour le reste, il a écrit : « le reste tu te débrouilles pour le bien de l'académie et de ses élèves ».

Les choix ci-dessous sont donc **définitifs pour le travail en cours**. Le directeur peut les reprendre à tout moment, par une décision datée. Le critère est toujours le même : ce qui protège le mieux les élèves, puis ce qui coûte le moins de travail refait.

## Contrôleur (CT)

| Question | Choix | Raison |
|---|---|---|
| Les 137 textes du lexique (P1 à P137) | **Gardés**, avec deux corrections demandées par le directeur : « mission » devient « Classe à observer » ou « visite » ; « faits automatiques » devient « relevé automatique de la séance (heures, élèves présents, reconnexions) ». Commit `ui/controleur-v1` 91f31eb6. | Le directeur a relu la liste et n'a commenté que ces textes. |
| Le complément redemande-t-il nature, domaine et personne ? | **Non** : motif facultatif et texte seulement. | Minimisation : le rapport d'origine porte déjà ces informations, et un complément court est plus vite écrit. |
| Le complément en plein écran ? | **Non** : il s'ouvre dans l'Historique, avec la barre du bas. | Tâche courte. Le retour au rapport reste visible. À revoir à HU-1 si le parcours l'exige. |
| Bloquants B1 à B15 | Voir `14_controleur/BLOQUANTS_ET_IMPACTS.md` §1 bis. Choix de l'orchestrateur pour B4 (12 mois), B5 (intérêt légitime) et B7 (une contestation par rapport, 7 jours, motif écrit). | Réponses du directeur sur la planche. |

## Mode Accessibilité (MA)

| Question | Choix | Raison |
|---|---|---|
| Regrouper le lecteur du Coran dans un composant commun ? | **Oui, à HU-1** : extraction de l'enrobage `MushafPage` dans un composant partagé. Le rendu du Coran n'est pas touché. | Un seul lecteur, une seule façon de rétablir le grossissement pour tous les rôles. |
| MA9 contre EN-12 pour la salle de l'élève | **MA9 prime** en Mode Accessibilité. Ailleurs, EN-12 s'applique. | Le Mode Accessibilité existe pour l'élève qui en a besoin. |
| « Mode standard » devient « Présentation standard » | **Oui**, partout où l'élève ou le tuteur le lit. À appliquer à HU-1 et dans les 5 langues (LG-1). | Ce n'est pas un « mode » réduit, c'est une présentation. Cela évite de stigmatiser l'autre présentation. |
| Essai TalkBack réel (débogage USB du téléphone) | **Reporté à la recette finale avant production** (ligne « À faire plus tard »). Le directeur n'a pas à activer le débogage USB pour avancer. | Les tests prouvent déjà les noms et les rôles. L'essai réel se fera une seule fois, sur l'application complète. |

## Enseignant (EN)

| Question | Choix | Raison |
|---|---|---|
| Définitions des faiblesses (EN-7c) | **Gardées** telles qu'écrites en EN-7c. | Aucun commentaire du directeur. Elles restent modifiables par le lexique. |

## Corrections de la revue du directeur (fiche `docs/current/REPRISE-CORRECTIONS-REVUE.md`, branche corrections/revue-directeur-2026-10)

| Question | Choix | Raison |
|---|---|---|
| MA-NAV-1 : retirer le Coran de la barre élève en Mode Accessibilité ? | **Non, le Coran reste** : Accueil, Ma classe, Coran, Mon espace (comme `ui/accessibilite-v1`, MA-2). | Dans une académie de Coran, c'est une destination essentielle. Quatre destinations restent dans la limite de la demande (« les essentielles seulement »). |
| Au-delà de 130 % de texte, le mot d'état des bascules de la salle disparaît : accepter ? | **Non** : le mot d'état reste (il peut passer sous le libellé). | Un état ne doit jamais être dit seulement par la couleur ou la forme (WCAG 1.4.1). |
| Galerie vidéo de la salle : écart de 8 entre les tuiles ? | **Oui, 8**. | Ce sont des tuiles vidéo d'une même grille, pas des cartes de contenu. K-55 vise les cartes. |
| Configuration : menu ou 4 segments ? | **4 segments** quand ils tiennent sur la largeur, menu en dessous. | Les choix visibles d'un coup d'œil valent mieux qu'un menu caché (ONGLETS-1). |
| REMPL-1 : offre de remplacement visible aux seuls enseignants du bon genre ? | **Oui**. | Recommandation de la fiche ; cohérent avec la politique de genre déjà appliquée côté serveur (AD-BR). |
| Lot 3 : libellés proposés (LIB-ABS-1, LIB-CAHIER-1, LIB-OBJ-1, LIB-ERR-1, FOYER-ADMIN-1, KYC-PHOTO-1) | **Adoptés tels que proposés** dans les fiches du tableau. | Ils répondent mot pour mot aux remarques du directeur. |
| Pièce d'identité (KYC) : le contrôleur peut-il la lire (règle serveur actuelle) ? | **Non** : seule la direction la lit. Migration au branchement (KYC-LECTURE-1). | Minimisation : le contrôleur n'en a pas besoin, et le texte validé dit « seule la direction la consulte ». |
| Salle : contraste du support partagé sur fond sombre | **Reporté à TH-2 / HU-1** (CONTRASTE-SUPPORT-1). | Les couleurs sont figées (K-37). |
