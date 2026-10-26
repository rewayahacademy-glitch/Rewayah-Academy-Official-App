# Revue UX du parcours d'entrée (règle gelée DESIGN-GOV §4.2)

Spécification : `docs/current/PARCOURS-ENTREE-2026-10-25.md`. Une section par PR.

**Limite à dire d'abord** : les standards ci-dessous sont cités de mémoire, dans leur version
publique connue (Material 3, WCAG 2.2, Flutter adaptive, Baymard), sans lecture en ligne le
25/10/2026 : la date indiquée est celle de la revue, pas celle d'une consultation des pages.
Rien n'est prouvé en production ; « fait » attend la vérification du directeur.

## PR 1 : connexion, lien envoyé, récupération d'accès (25/10/2026)

| Proposition contrôlée | Standard | Règle utile | Conclusion | Conséquence dans le code |
|---|---|---|---|---|
| Deux volets dès 840 points de largeur utile | Material 3, classes de fenêtre (« expanded » à partir de 840) ; Flutter adaptive | Au-delà de 840, une seconde colonne remplace l'empilement ; la largeur se lit divisée par le facteur de texte (reflow WCAG 1.4.10) | ajustée | `CoquilleEntree` : `largeur / facteur >= AppGabarit.seuilEtendu`. À 1440 en texte ×2 (720 utiles), la page reprend la composition du téléphone ; testé |
| Image au début de ligne, formulaire à la fin | Material 3, mise en page bidirectionnelle ; contrat B (start/end) | Une mise en page se miroite en arabe par `start`/`end`, jamais `left`/`right` | conforme à la règle, vérifiée | `Row` sans direction forcée : volet de marque à droite en arabe ; test `entree_rendu_test` (centre de l'image de part et d'autre du milieu selon le sens) |
| L'illustration ne se retourne pas en arabe | README du logo (« jamais retourné ») | Un logo et son dessin gardent leur orientation | conforme | `PorteLumiere` pose sa scène sous `Directionality` de gauche à droite ; test « jamais retournée en arabe » |
| Un seul bouton plein, à la place du bas du formulaire | Material 3, hiérarchie des boutons (un « filled » par vue) ; K-56 ; contrat B | Une seule action dominante ; Google en bouton à contour ; sorties en liens | conforme, vérifiée au rendu | `verifierUnSeulBoutonPlein` à 320 et 1440, ×1 et ×2, clair et sombre, fr et ar ; « Connecter l'appareil d'un élève », « Lien expiré ou jamais reçu ? », « Informations légales » passent de bouton texte à `LienFleche` |
| Bouton pleine largeur sur téléphone, largeur du contenu sur ordinateur, au bord de fin | Contrat B (« sur desktop, un bouton n'est pas étiré pleine largeur sans justification », action qui poursuit au bord *trailing*) ; Fitts | Sur téléphone, la cible pleine largeur est la plus proche du pouce ; sur ordinateur, le bouton suit son libellé | conforme | `BoutonEntree` : `Align(centerEnd)` sur ordinateur ; test : largeur du bouton < largeur du champ à 1440, égale à 320 |
| Sur ordinateur, « Continuer avec Google » puis « Recevoir le lien » sur une rangée au bord de fin, 8 points entre eux (correctif du directeur du 25/10/2026, capture 1440 refusée : boutons éparpillés) | Contrat B (action group au bord *trailing*, secondaire avant principale) ; Gestalt, proximité | Les actions d'un même formulaire forment un groupe aligné sur la ligne de fin du champ | ajustée | `RangeeActions` (composant partagé, option `pileePleineLargeur`) ; largeur de lecture portée de 400 à 560 (`AppPage.largeurDialogue`) : la rangée mesure 408 en connexion et 508 en création avec les polices du dépôt ; à texte ×1,5 et ×2 elle s'empile pleine largeur ; tests `entree_rendu_test` et tests du composant |
| Champ unique, étiquette au-dessus, erreur sous le champ | Baymard, formulaires (étiquette hors du champ, message d'erreur adjacent au champ fautif) ; WCAG 3.3.1 | L'erreur se lit à côté de ce qu'elle concerne, en texte | conforme | `ChampEntree` : étiquette au-dessus, `errorText` sous le champ, encre de la surface (blanche sur le violet, `inkAlert` sur le parchemin) |
| Champ blanc à encre sombre sur le violet | WCAG 1.4.11 (composants 3:1) ; 1.4.3 (texte 4,5:1) | Le champ se détache de son fond, la saisie se lit | conforme, mesurée | Champ sur le thème clair, fond de carte `#FFFFFF` ; filet de focus `inkAccent` de 2 points sur le champ blanc |
| Texte blanc sur `#6538E4` | WCAG 2.2, 1.4.3 | 4,5:1 au moins | conforme, mesurée : 6,5:1 | Test `surface_marque_test` et `entree_rendu_test` (contraste mesuré) |
| Encre, encre secondaire, accent et alerte sur le parchemin `surfaceQuran` | WCAG 2.2, 1.4.3 | 4,5:1 au moins | conforme, mesurée | Test « encre, encre secondaire, accent et alerte sur le parchemin » |
| Bouton plein violet à texte blanc sur le parchemin | WCAG 1.4.3 et 1.4.11 | Texte 4,5:1, contour du bouton 3:1 contre son fond | conforme, mesurée | `ActionPrincipale(affirmee: true)`, `#8652E6` sur blanc ; test du bouton contre le parchemin |
| L'illustration joue une fois, 1,5 s, puis reste immobile | WCAG 2.2.2 (Pause, Stop, Hide : tout mouvement automatique de plus de 5 s doit pouvoir s'arrêter) ; Material 3, mouvement | Un mouvement court qui s'arrête de lui-même n'a pas à être mis en pause | conforme | `AppMouvement.entreeIllustration` (1,5 s, décision du directeur du 25/10/2026) ; aucune boucle ; test « l'illustration joue une fois puis s'arrête » (`hasRunningAnimations` faux) |
| Durée de 1,5 s, au-dessus du plafond de 400 ms ; mouvement réduit en fondus de même durée | Contrat E (durées gelées, plafond 400 ms, réduction = durée 0) | Le contrat E n'autorise pas de lui-même cette durée | dérogation datée | Décision du directeur du 25/10/2026 (`PARCOURS-ENTREE` §2 et §5) : la durée entre dans `AppMouvement` sous un nom explicite, hors du budget de transition comme `pulsation` ; en mouvement réduit, fondus seuls sur la même durée, sans tracé ni étirement, image finale identique |
| Logo par un fondu net, sans déplacement | Material 3, mouvement (apparition) ; contrat E | Un fondu court, aux jetons existants | conforme | `LogoEntree` : fondu `AppMouvement.apparition` (180 ms) |
| Thème unique en clair et en sombre | Charte 03 (« mode clair et sombre complets ») | La charte demande les deux thèmes | **dérogation : décision du directeur du 25/10, contredit 03** | `CoquilleEntree` force le thème clair sur la page, comme la salle le fait déjà (`zone_support.dart`) ; test « identique en clair et en sombre » |
| Défilement sur téléphone, l'image toujours au-dessus du titre | WCAG 1.4.10 (reflow) ; Nielsen, visibilité de l'état | Le contenu entier reste atteignable sans défilement horizontal | conforme | Page qui défile ; à 390 × 844 en mode courant, le bouton plein reste au premier écran ; en mode démonstration (deux champs) ou texte ×2, il demande un défilement |
| Focus clavier visible | WCAG 2.4.7 et 2.4.11 | Le focus se voit sur chaque contrôle | conforme pour les composants partagés, non mesuré au rendu dans ce lot | `ActionPrincipale`, `LienFleche`, `ControleSegmente` et `DisqueRetour` gardent leur focus ; sur le violet, leur encre de focus est blanche (`AppPalette.surMarque`) |
| Hors ligne | Charte 03, « hors ligne se dit une seule fois » | Le bandeau de `PageShell` est le signal | conforme, existant gardé | Bandeau de `PageShell` et phrase `connexion.horsLigne` sous le champ après la tentative ; aucun comportement nouveau |

Ce que cette PR ne change pas : les textes (aucune clé nouvelle), les routes, les redirections, les
règles d'accès, le comportement des envois de lien et de Google.

## PR 2 : démarrage animé, raccord avec la connexion (26/10/2026)

Codée et testée localement, non poussée, **non prouvée** par le directeur. Décisions du pilote du
26/10 : l'animation joue à chaque lancement ; version courte quand une session est déjà active ;
mouvement réduit en fondus seuls.

| Proposition contrôlée | Standard | Règle utile | Conclusion | Conséquence dans le code |
|---|---|---|---|---|
| Démarrage sur la surface de marque : logo horizontal blanc en haut, la porte au centre, aucune roue, ni mot-marque ni ornement | Material 3, écran de lancement (une marque, pas de contenu) ; `PARCOURS-ENTREE` §3 A | Un écran de lancement montre la marque et rien d'autre | conforme | `EcranDemarrage` : `PageShell(fond: surfaceMarque, bordABord)`, `LogoEntree`, `PorteLumiere.surMarque` ; `MarquePage`, `OrnementMarque` et l'indicateur circulaire retirés de cet écran |
| La porte joue une fois, 1,5 s, puis reste immobile | WCAG 2.2.2 ; contrat E (dérogation datée de la PR 1) | Un mouvement court qui s'arrête de lui-même | conforme, dérogation déjà datée | Même `AppMouvement.entreeIllustration` que la connexion ; test « joue une fois, puis s'arrête » |
| Raccord sans coupure avec la connexion | Material 3, transitions (continuité d'un élément partagé) | Un élément qui reste à l'écran ne recommence pas | ajustée | `RaccordEntree` : le démarrage inscrit l'avancement à chaque image ; la première coquille d'entrée le **prend** et reprend la porte à ce point (image finale si l'entrée avait fini). Écart avec la consigne (« vrai quand l'animation est finie ») : un avancement plutôt qu'un booléen, sinon une redirection à 1 s faisait rejouer la porte du début. Un retour ou un lien direct plus tard la rejoue, comme avant |
| Session déjà active : version courte | Nielsen, efficacité pour l'utilisateur fréquent | Ne pas faire attendre qui revient | conforme | Fondus seuls sur `AppMouvement.plafond` (400 ms) ; session lue active pendant l'entrée : fin accélérée sur 400 ms. Limite : la redirection remplace l'écran aussitôt ; cette fin accélérée ne se voit que si la transition de page la laisse affichée |
| Mouvement réduit : fondus seuls, même image finale | WCAG 2.3.3 ; contrat E | Réduire sans retirer le sens | conforme | Même chemin que la PR 1 (`MediaQuery.disableAnimations`) ; test : aucun symbole qui se dessine, animation finie |
| Message « plus long que prévu » à 8 s, sous la porte, qui reste | Nielsen, visibilité de l'état ; charte 03 (états) | L'état long se dit sans retirer le repère | conforme | `EtatSysteme(chargementProlonge)` sous la porte ; tests « sous la porte » |
| Thème unique sur cet écran | Dérogation de la PR 1 (décision du directeur du 25/10) | Comme la connexion qui suit | dérogation déjà datée | Thème clair forcé, contenu sous `SurMarque` |

Ce que cette PR ne change pas : les textes (aucune clé nouvelle ; la marque est lue par le
libellé du logo, `commun.marque`, et l'ouverture par `commun.demarrage.ouverture`), les routes, les
redirections.
