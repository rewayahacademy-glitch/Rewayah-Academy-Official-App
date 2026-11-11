# UX_REVIEW : NAV-REFONTE étape 4, panneau de la direction (part sans décision ouverte)

Date : 11/11/2026. Feu vert du pilote le 11/11/2026, sur `main` 6fe6b35c.
Maquettes : « Panneau de la direction sur ordinateur » et Revue du 09/11.
Captures : `docs/current/captures/E2E/nav-direction/`, faites sur la pile locale sans personne connectée.

**Ce qui n'est pas prouvé.** Le directeur n'a rien vu en production. Le nom et la photo réels d'un compte de la direction au pied de la colonne n'ont pas été capturés : sans personne connectée, le pied montre « Mon compte » et l'initiale.

## Ce lot

| # | Règle | Source | Conclusion | Modification |
| :- | :- | :- | :- | :- |
| 1 | Une commande garde la même place d'un état à l'autre | Nielsen n° 4 ; Apple HIG « Sidebars » | La direction n'avait pas de bouton : à partir de 1200, la colonne était toujours ouverte. | Le même `BoutonPanneau` que les rôles, à partir de 1200, à 16 du bord de début, ouvert comme replié (test en ltr et en rtl). Le choix est gardé par appareil (`navigation.repliee`, partagé avec les rôles). |
| 2 | Le compte en pied, une seule porte vers lui | Material 3 « Navigation drawer » ; maquette de la direction | Il y avait deux entrées vers le compte : le pied (« Administrateur ») et le menu en haut à droite (P1). | Le même `PiedComptePanneau` que les rôles : photo ou initiale, prénom lu sur le profil, menu Mon compte · Thème · Se déconnecter. Le bouton Compte quitte l'en-tête à partir de 600. Au téléphone, la barre et le tiroir ne changent pas. |
| 3 | Rail replié : icônes avec infobulles | Material 3 « Navigation rail » | Déjà en place. | Le pied s'y ajoute : la photo seule, son nom en infobulle. |
| 4 | Un filet visible entre la colonne et la page | Gestalt (séparation des régions) | Le rail Material peignait son fond par-dessus la bordure, et le filet ne se voyait pas, déjà sur `main`. | Le filet est maintenant peint au premier plan. |
| 5 | Texte agrandi, arabe, sombre | WCAG 1.4.4 et 1.4.10 | Vérifié à 800 et 1440, ×1 et ×2, clair et sombre, en ltr et en rtl : le pied reste dans la colonne et aucun mot n'est coupé. | Aucune. |

Les huit domaines ne changent pas : mêmes noms, même ordre, mêmes routes, mêmes droits.

## Ce qui attend le directeur (rien n'est codé)

1. Les noms des sections (« Chaque jour », « École », « Réglages et contrôle »).
2. Le retrait des 11 cartes outils de l'Accueil.
3. « Demandes d'admission » pour Personnes.
4. Les e-mails rangés dans Communications.
5. Les 4 adresses Comptes, en sous-liens, ou le sélecteur gardé dans la page.
6. À 800, le panneau ouvert pousse-t-il la page, ou passe-t-il par-dessus avec un voile ? **En attendant la réponse, sous 1200, le rail reste figé et n'a pas de bouton.**
7. En Mode Accessibilité, le panneau est-il ouvert par défaut ?

Les sous-liens, le volet et les sections viendront après ses réponses.
