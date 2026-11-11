# Bilan du cahier de la salle, point par point (11/11/2026)

Demande du directeur du 11/11 : « N'oublie pas de jeter un coup d'œil sur le prompt initial, il y a
beaucoup de demandes qui ne sont pas encore traitées. »

**À lire d'abord.** Rien dans ce tableau n'est « fait » au sens du directeur : aucune ligne n'est
prouvée par lui en production. Les mots employés :

- **prouvé sur le banc** : vérifié dans la vraie application ou par les vraies fonctions du serveur,
  sur la pile locale de ce dépôt (`tool/salle/`) ;
- **codé, testé** : présent dans le code, tests automatiques verts, captures de test ; pas vu dans
  la vraie application ;
- **en partie** : une moitié manque, elle est dite ;
- **pas commencé**.

## §4. Essais par l'usage réel

| Demande | État | Preuve ou manque |
| :--- | :--- | :--- |
| Classe pleine | prouvé sur le banc | à 6 élèves, le maximum confirmé par le directeur (`captures/E2E/salle-banc/classe-6/`, puis `classe-apres-11-11/`) |
| Téléphone, tablette, ordinateur | prouvé sur le banc | les trois, élève et enseignant ; **jamais sur un vrai téléphone** |
| Clair et sombre | prouvé sur le banc | un élève en sombre dans chaque essai |
| Plusieurs salles en même temps | **pas commencé** | aucun essai à deux classes simultanées |
| Arabe en séance réelle | **pas commencé** | l'arabe n'est vérifié que par des tests et des captures de test |
| Mode Accessibilité en séance réelle | **pas commencé** | idem |
| Réseaux bons et mauvais | prouvé sur le banc pour la voix | `salle/MESURES-VOIX.md` ; pas pour le pointeur ni la page |

## §5. L'élève comprend chaque mot de l'enseignant, et l'inverse

| Demande | État | Preuve ou manque |
| :--- | :--- | :--- |
| Voix protégée, mesurée avant et après, dans les deux sens | prouvé sur le banc | pertes isolées de 10 et 20 %, 300 ms, 3G : zéro mot perdu après correction |
| Pertes en rafales (réseau mobile en mauvais état) | **non tenu** | à partir de 10 % en rafales, des mots sont encore perdus (défaut V-3) |
| Enregistrement de ce que l'élève entend | prouvé sur le banc | c'est l'outil de mesure ; l'enregistrement des séances pour l'académie est « prévu plus tard » (directeur, 11/11) |
| Règle écrite par seuil | fait | `salle/MESURES-VOIX.md` |
| Répéter chaque mesure trois fois | **pas commencé** | un seul passage par case |

## §6. Indicateur de réseau et relevé conservé

| Demande | État | Preuve ou manque |
| :--- | :--- | :--- |
| Indicateur réel chez l'enseignant (ses propres barres) | codé, testé | les barres étaient factices ; elles suivent la mesure |
| La qualité de chaque élève vue par l'enseignant | **pas commencé** | |
| Dire à quelqu'un « on vous entend mal » | **pas commencé** | |
| Relevé conservé comme preuve | **pas commencé** | la base légale est écrite (`salle/DROIT-RELEVE-QUALITE.md`) ; il manque la décision du directeur sur la durée (proposé : 180 jours) et une migration |

## §7. Le support est générique

| Demande | État | Preuve ou manque |
| :--- | :--- | :--- |
| Étagère avec une couverture par support | codé, testé | D-016 ; collection aux couleurs de la marque, couverture arabe du Coran (couleurs nouvelles à valider) |
| « Afficher » et « Partager » | codé, testé | fiche du support |
| Tiroir à languette | **en partie** | le panneau existant porte la couleur de la marque ; pas de languette au bord de l'écran (question ouverte) |
| Partage commun à tout support | **pas commencé** | le partage en direct reste codé pour le Coran : l'alphabet ne peut pas se partager |
| Supports de démonstration « à valider » | **en partie** | une liste proposée, sans contenu (`salle/SUPPORTS-A-VALIDER.md`) ; aucun support réel créé |
| Réutilisable dans « Ma classe » | **en partie** | composants du core réutilisables ; pas branchés ailleurs |

## §8. Défauts constatés par le directeur

| Défaut | État | Preuve ou manque |
| :--- | :--- | :--- |
| Vidéo de l'enseignant en double | codé, testé chez l'enseignant | D-014 ; chez l'élève au téléphone, à revérifier après le lot du Coran de l'élève |
| Bouton Coran au milieu, boutons posés n'importe où | codé, testé | barre du bas en cinq groupes (D-015), haut réparti, étagère |
| Outils moches et qui ne marchent pas | **en partie** | le pointeur est refait (D-014) ; le tracé n'a pas été revérifié chez l'élève |
| Messages tantôt en haut, tantôt en bas | **en partie** | l'île et les annonces de gestes sont en haut ; « votre micro s'ouvrira… » et les phrases de caméra sont encore en bas |
| Changer de page, glisser au doigt | codé, testé | enseignant au téléphone ; l'élève qui glisse reçoit « la page suit celle de l'enseignant » |
| Table des sourates dans le désordre | **non trouvé** | aucun écran de l'élève ne liste les sourates ; un seul écran sort de l'ordre : le cahier de l'enseignant, « Où reprendre » (la sourate retenue en tête). Au directeur de dire si c'est celui-là |
| « Reprendre la lecture » qui ne disparaît jamais | codé, testé | s'efface après 6 s, se retrouve d'un appui |
| Pointeur discret et en retard | codé, testé | point visible, sillage, envoi à 30 positions par seconde ; **le retard réel entre deux appareils n'est pas mesuré** |
| Chronomètre caché | prouvé sur le banc | île avec le temps restant, chez tous |
| « En ligne » et « En salle » en double, chrono bavard | prouvé sur le banc | |
| « Faire réciter » | prouvé sur le banc pour le serveur | 28 contrôles ; pas essayé dans la vraie application à deux navigateurs |
| « Faire sonner » | codé, testé | renommé « Appeler », avec retour chez l'enseignant ; son non essayé dans un vrai navigateur |

## §9. Le téléphone réduit

| Demande | État | Preuve ou manque |
| :--- | :--- | :--- |
| Ne garder au téléphone que : rejoindre, voir et entendre, micro et caméra, suivre le support, pointeur, quitter | **pas commencé** | le téléphone de l'enseignant garde son tiroir complet |
| Élève au téléphone : page à pleine taille | codé, testé | les commandes s'effacent après 3 s |

## Demandes du 11/11 (ajoutées au cahier)

| Demande | État | Preuve ou manque |
| :--- | :--- | :--- |
| L'écran ne coupe plus la séance | prouvé sur le banc pour la reprise | D-009 ; l'écran tenu allumé reste à prouver sur un vrai téléphone |
| Micro des élèves fermé avant l'enseignant | prouvé sur le banc | D-008 ; fonctions du serveur à déployer |
| Après le départ de l'enseignant | **pas commencé** | la salle ne se ferme pas, les micros restent |
| Sortir sans couper | codé, testé | D-010 ; pas de bouton « Réduire » visible au téléphone de l'enseignant |
| Île à la façon de la Dynamic Island | prouvé sur le banc dans la salle | D-011 ; hors de la salle : codé, testé |
| Écran d'attente | prouvé sur le banc | D-012 |
| Carré de l'enseignant dans le panneau des élèves | codé, testé | |
| Coran grand sur ordinateur | **en partie** | élève : pleine hauteur ; enseignant : + 8 % seulement |
| Toutes les situations autour de la salle | relevé fait, corrections **pas commencées** | 78 situations lues (`salle/SITUATIONS-DE-LA-SALLE.md`) ; les plus graves non corrigées : micro refusé muet, rechargement qui perd l'appel, refus d'entrée mal expliqués, pause |

## §12. Rust

Répondu : non (journal D-001).

## Ce que le directeur doit trancher (une ligne chacune, avec la recommandation)

1. Les élèves adultes attendent-ils aussi l'enseignant pour ouvrir leur micro ? Recommandé : oui.
2. Pendant une récitation, fermer aussi la caméra des camarades ? Recommandé : non, le micro seul.
3. Le bleu nuit et l'or de la couverture du Coran (couleurs nouvelles). Recommandé : oui, pour cette couverture seulement.
4. Une languette au bord de l'écran pour les supports, à la place du bouton de la barre ? Recommandé : non, un seul endroit par chose.
5. Le Coran plus grand chez l'enseignant sur ordinateur : barre sur un côté, ou double page ? Recommandé : la barre sur un côté d'abord.
6. Durée de conservation du relevé de qualité. Recommandé : 180 jours.
7. Paiement du temps de dépassement. Recommandé : non payé.
8. Le cahier « Où reprendre » est-il l'écran où la table des sourates semblait dans le désordre ?
