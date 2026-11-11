# UX_REVIEW : NAV-REFONTE étape 3, panneau de la tablette et de l'ordinateur

Date : 11/11/2026. Brief du garde-cap du 09/11/2026. Feu vert du pilote le 11/11/2026 (sur `main` af4fd984).
Maquette : canevas « Panneau » (NAV-REFONTE, 09/11).
Captures : `docs/current/captures/E2E/nav-panneau/` (pile locale, sans personne connectée, données de test).

**Ce qui n'est pas prouvé.** Rien n'est vu par le directeur en production. La photo et le prénom au pied du panneau viennent de `prenomDuCompteProvider` et `photoPersonneProvider`. Les captures tournent sans personne connectée : elles montrent donc l'initiale et le nom de la destination. Le pied avec une vraie photo n'a pas été capturé.

| # | Règle | Source | Conclusion | Modification |
| :- | :- | :- | :- | :- |
| 1 | Une commande garde la même place d'un état à l'autre (cohérence, mémoire spatiale) | Nielsen n° 4 « Consistency and standards » ; Apple HIG « Sidebars » (bouton de barre latérale fixe en tête) | L'ancien disque à deux flèches changeait de place : sous le symbole quand le panneau était replié, au bout du logo quand il était ouvert. | Un seul bouton carré à icône de panneau (Phosphor `sidebar-simple`), toujours à 16 du bord de début, en haut (test `un seul bouton, a la meme place`, ltr et rtl). |
| 2 | Cible de 24 au minimum, état lu | WCAG 2.2, 2.5.8 et 4.1.2 | Il faut une cible de 48 et que le lecteur d'écran lise si le panneau est ouvert ou replié. | Carré de 40 dans une cible de 48, avec `Semantics(expanded:)`. Le lecteur dit « Replier la navigation » ou « Déplier la navigation ». |
| 3 | Le compte en pied, séparé des rubriques | Material 3 « Navigation drawer » ; Apple HIG « Sidebars » ; maquette Panneau | Le Compte, le Profil ou Mon espace était une rubrique comme les autres. | Il quitte la liste et vient au pied : photo (ou initiale), prénom quand le panneau est ouvert, menu avec Compte, Thème, Se déconnecter (`MenuActions`, nouveau paramètre `declencheur`). Le menu du compte en haut à droite (P1, 06/11) est retiré, pour ne pas en avoir deux. |
| 4 | Panneau replié : rail d'icônes avec infobulles | Material 3 « Navigation rail » | Le rail existait déjà. Le pied replié montre la photo seule, avec le nom en infobulle. | Le Mode Accessibilité garde le nom écrit sous la photo (MA-NAV-1), avec une cible de 72. |
| 5 | Texte agrandi : rien de coupé ni de rogné | WCAG 1.4.4 ; COUPE-MOTS-1 | Le nom au pied du panneau se coupait à ×2 avec la police de test. | Le nom passe par `TexteSansCoupure` : il va à la ligne entre les mots, sans jamais descendre sous ×1. Vérifié à 800 et 1440, ×1 et ×2, clair et sombre, ltr et rtl, ouvert et replié (32 cas). |
| 6 | Miroir arabe | `06-accessibilite` §5 ; LOGO-APP | Le panneau passe à droite. Le bouton ouvre la ligne, puis le logo suit, sans être retourné. L'icône de panneau est miroitée et le double chevron du menu ne l'est pas. | Le test du logo en arabe est mis à jour : le logo suit maintenant le bouton, il n'est plus au tout début de la ligne. |
| 7 | Pastilles seulement avec un compte du serveur | Brief du 09/11 | C'est déjà le cas (badge « Nouveau » de NOUVEAUTES). | Aucune. |

## Écarts à la maquette, à arbitrer

- **Symbole du logo dans le rail replié.** La maquette ne montre que le bouton. Le symbole est gardé sous le bouton (LOGO-APP : le seul logo de l'écran, qui ramène à l'accueil). À retirer seulement sur décision.
- **Halo au pied du panneau.** La lumière entoure la photo comme sur le téléphone. Le geste n'est pas le même : sur le téléphone, toucher le cercle ouvre « En ce moment » ; ici, toucher le pied ouvre le menu, et « En ce moment » en est la première entrée. C'est une **proposition**.
- **Volet de sous-liens.** Aucune rubrique NavShell n'a de sous-liens aujourd'hui, donc rien n'est codé. Le volet viendra avec la direction (étape 4).
- **Fil d'Ariane.** Le fil existe déjà dans `main` (FIL-ARIANE, 06/11) : un composant unique, `FilAriane`, que `PageShell` pose sur tablette et ordinateur pour toute page de niveau 2 ou plus. Il est réutilisé tel quel, rien n'est dupliqué. Il est posé au-dessus du titre de la page, pas sous un en-tête d'application : NavShell n'a pas d'en-tête.
