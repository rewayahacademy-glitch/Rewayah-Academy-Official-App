# Fiche 1 : la salle de l'enseignant au téléphone (26/10/2026)

Règles : `docs/orchestration/CONTRAT-ECRAN-2026-10-26.md`. Maquettes du directeur :
`references/2026-10-26-directeur-telephone-visio-au-toucher.webp` (M1) et
`-telephone-commandes.webp` (M2). Branche `claude/admiring-brown-r6ai72` au-dessus de la tête
6240ed1 ; PR B, ouverte par le directeur quand toutes les lignes sont vertes en local, fusionnée
quand elles sont vertes sur l'aperçu Vercel, sur son téléphone et son iPad en portrait.

**Les deux maquettes se contredisent sur un point**, et c'est tranché ici (règle 2) : M2 met
micro, caméra, élèves et quitter dans un onglet « Séance » du tiroir et supprime la pilule ; M1
garde la pilule sous le tiroir ouvert (« visio indépendante ») et n'a que deux onglets. Juste
milieu retenu : **la pilule porte l'appel, toujours atteignable ; le tiroir n'a que Support et
Outils ; rien n'est en double.** C'est la règle de Meet et de Zoom (quitter ne se cache jamais
derrière un onglet). Ceci prévaut sur `PLAN-SALLE-COMPOSITION-2026-10-26.md` §4 pour ces points.

Composition « téléphone » : toute fenêtre de moins de 840 points de large (téléphone, iPad en
portrait). Tailles contrôlées : 390×844 et 834×1194 ; texte ×1 et ×2 ; français et arabe.

| N° | Ce qui est vrai à l'écran | Source |
| :-- | :-- | :-- |
| 1 | **Au repos** (rien touché depuis 3 s) : sur la page, deux objets seulement : la capsule vidéo en haut au centre et le bouton « Commandes ⌃ » en bas au centre. Aucune pilule d'état, aucun bouton Élèves, aucune croix, aucun texte posé sur la page. | M1 cadre 1 |
| 2 | **La capsule** : une seule, sombre, en haut au centre, de gauche à droite : la vignette vidéo, le point d'état (rouge si la séance est enregistrée, vert sinon), l'œil « Voir la vidéo en grand ». Rien d'autre en haut de l'écran. | M1, M2 |
| 3 | **Au toucher** de la page : la pilule de l'appel apparaît en bas, « Commandes ⌃ » remonte au-dessus d'elle, aligné à droite. Tout se masque de nouveau après 3 s sans toucher, sauf la pilule quand un panneau est ouvert. | M1 cadre 2 |
| 4 | **La pilule** : quatre boutons ronds nommés, Micro, Caméra, Élèves, Quitter ; Quitter rouge (le seul bouton plein de l'écran) ; micro ou caméra coupés se lisent par l'icône barrée et le libellé ; Élèves porte le nombre d'élèves présents en pastille. | M1 ; juste milieu (Élèves dans la pilule, pas dans un onglet) |
| 5 | **Toucher la capsule** déplie le profil : une carte en haut, photo, « Sayyida Amina », « Enseignante », point d'état et signal, « Réduire ⌃ », et dessous la ligne d'état (« En ligne · Visite de contrôle possible » ou « Cours enregistré, visite de contrôle possible »). Ce texte n'apparaît nulle part ailleurs. | M2 cadre 1 |
| 6 | **« Commandes »** ouvre le tiroir en bas ; le tiroir se pose au-dessus de la pilule, qui reste visible et entière ; le bouton « Commandes » disparaît tant que le tiroir est ouvert. | M1 cadre 3 |
| 7 | **Le tiroir est une seule surface** du thème (sombre en thème sombre, claire en thème clair) : les tuiles sont posées directement dessus ; aucun bloc d'une autre couleur emboîté dedans. En-tête : « Commandes » à gauche, « Réduire ⌄ » à droite ; dessous le sélecteur à deux segments Support | Outils. Pas d'onglet Séance. | M1 cadre 3 ; juste milieu |
| 8 | **Onglet Outils** : une rangée de quatre tuiles de même taille, Stylo, Surligner, Gomme, Annuler, l'outil actif seul en couleur ; dessous, seulement quand Stylo ou Surligner est actif, une rangée de couleurs qui défile au doigt. Rétablir et les épaisseurs ne sont pas sur téléphone. | M1 cadre 3 ; juste milieu (couleurs gardées : elles existent sur ordinateur) |
| 9 | **Onglet Support** : la page du Coran, le Tableau, les supports de la Bibliothèque (liste existante), et une ligne nommée « Ranger le support » qui remplace la croix ⊠ du haut. Le tableau du téléphone garde sa bande 16:9 (Q3). | plan §4 ; passation 26/10 §3 (croix non comprise) |
| 10 | **Élèves** (bouton de la pilule) ouvre la feuille des élèves ; elle remplace le tiroir s'il était ouvert ; la pilule reste visible ; les cartes se déplient sur place, mêmes cartes que sur ordinateur. | plan §4 |
| 11 | **Un seul panneau du bas à la fois** (tiroir ou feuille des élèves) ; un panneau ouvert ne couvre jamais la pilule ni la capsule ; « Réduire » ou un toucher sur la page le referme. | M1 ; SUPERPOS-1 |
| 12 | **Aucune commande n'apparaît deux fois à l'écran**, dans aucun état : chaque libellé de commande (Micro, Caméra, Élèves, Quitter, Stylo…) se trouve au plus une fois. | directeur, 26/10 |
| 13 | **La pilule du zoom** suit la règle du toucher (visible au toucher, masquée au repos), au bord droit à mi-hauteur, jamais sur un panneau ouvert. | existant |
| 14 | **Rien ne se recouvre, aucun mot coupé, cibles de 48 au moins**, à 390 et 834, texte ×1 et ×2, français et arabe ; à 320 en texte ×2, les libellés peuvent se réduire à l'icône, jamais disparaître. | K-55, K-56, WCAG 1.4.4 |
| 15 | **Miroir en arabe** : tout suit le sens de lecture ; « Commandes » au toucher est aligné du côté de fin de ligne. | contrat B |
| 16 | **L'élève, le tuteur, le contrôleur au téléphone sont inchangés** : ni capsule, ni tiroir, ni « Commandes ». | plan §5 |

**À valider par le directeur** (ligne 9) : le libellé arabe de « Ranger le support », « إرجاع المادة », proposé par le worker le 26/10.

## Captures à produire (par les tests, `CAPTURE_DIR`)

À 390×844 et 834×1194 : repos, toucher, profil déplié, tiroir Support, tiroir Outils avec stylo
actif, feuille des élèves. Nom : `fiche1-<taille>-<etat>.png`, dans `captures/`.

## État

| Ligne | Local (tests) | Aperçu Vercel (directeur) | Production (directeur) |
| :-- | :-- | :-- | :-- |
| 1 à 16 | à faire | | |
