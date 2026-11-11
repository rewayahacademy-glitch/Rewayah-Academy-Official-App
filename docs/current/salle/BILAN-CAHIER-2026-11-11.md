# Bilan du cahier de la salle, point par point (11/11/2026, mis à jour en fin de journée)

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

Depuis les fusions de l'après-midi (fermeture de la salle, situations graves, téléphone de
l'enseignant, récitation au micro seul, Coran grand, grille des commandes, vignette, transitions,
partage de tout support), **aucun banc n'a été rejoué sur l'ensemble fusionné** : les lignes
« prouvé sur le banc » datent d'avant ces fusions.

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
| Indicateur réel chez l'enseignant (ses propres barres) | codé, testé | les barres suivent la mesure |
| La qualité de chaque élève vue par l'enseignant | codé, testé | D-017 ; pas vu sur un vrai réseau dégradé |
| Dire à quelqu'un « on vous entend mal » | codé, testé | D-017 |
| Relevé conservé comme preuve, 180 jours (décision du directeur du 11/11) | **codé sur une branche, non fusionné** | D-024, branche `worktree-agent-a068e9993ee530f3d` : table, écriture bornée, lecture par la direction seule, purge à 180 jours, 47 contrôles SQL. **Bloqué** : la phrase d'information aux familles et aux enseignants n'est pas validée ; la migration contient un effacement (la purge), donc une page à coller par le directeur ; pas d'écran pour la direction |

## §7. Le support est générique

| Demande | État | Preuve ou manque |
| :--- | :--- | :--- |
| Étagère avec une couverture par support | codé, testé | D-016 ; couvertures à la couleur de la marque, couverture arabe du Coran en violet profond |
| « Afficher » et « Partager » | codé, testé | fiche du support |
| Tiroir à languette | **en partie** | le panneau porte la couleur de la marque ; pas de languette au bord de l'écran (écarté : un seul endroit par chose) |
| Partage commun à tout support | codé, testé | D-026 : identifiant de support dans le message, un lecteur par type, pointeur et page sans rien du Coran ; un support de démonstration « à valider » se partage de bout en bout dans les tests. **Restes** : l'écriture n'est pas prouvée sur un autre support ; pas de lecteur de PDF (un support entre en images, une par page) ; une application d'élève pas à jour ne voit pas un autre support que le Coran |
| Supports de démonstration « à valider » | **en partie** | un support factice pour les tests ; une liste proposée, sans contenu (`salle/SUPPORTS-A-VALIDER.md`) ; aucun support réel |
| Réutilisable dans « Ma classe » | **en partie** | composants du core réutilisables ; pas branchés ailleurs |

## §8. Défauts constatés par le directeur

| Défaut | État | Preuve ou manque |
| :--- | :--- | :--- |
| Vidéo de l'enseignant en double | codé, testé | D-014 |
| Boutons posés n'importe où, aucun système | codé, testé | D-027, la grille des commandes : une tuile, des cases égales, le même ordre partout, un seul endroit par chose ; téléphone, tablette et ordinateur de l'enseignant. **Restes** : la capsule du haut au téléphone, les en-têtes des deux panneaux de l'ordinateur |
| Outils moches et qui ne marchent pas | **en partie** | le pointeur est refait (D-014) ; le tracé n'a pas été revérifié chez l'élève |
| Messages tantôt en haut, tantôt en bas | **en partie** | l'île et les annonces sont en haut ; « votre micro s'ouvrira… » et « Caméra désactivée pour ce profil » sont encore en bas (la seconde se lit mal sur le texte du Coran) |
| Changer de page, glisser au doigt | codé, testé | |
| Table des sourates dans le désordre | **non trouvé** | un seul écran sort de l'ordre : le cahier de l'enseignant, « Où reprendre ». Au directeur de dire si c'est celui-là |
| « Reprendre la lecture » qui ne disparaît jamais | codé, testé | une petite languette qu'on ferme, élève et enseignant |
| Pointeur discret et en retard | codé, testé | **le retard réel entre deux appareils n'est pas mesuré** |
| Chronomètre caché | prouvé sur le banc | île avec le temps restant, chez tous |
| « En ligne » et « En salle » en double, chrono bavard | prouvé sur le banc | |
| « Faire réciter » | prouvé sur le banc pour le serveur | micro seul fermé chez les camarades (D-022) ; pas essayé dans la vraie application à deux navigateurs |
| « Faire sonner » | codé, testé | renommé « Appeler » ; son non essayé dans un vrai navigateur |

## §9. Le téléphone réduit

| Demande | État | Preuve ou manque |
| :--- | :--- | :--- |
| Téléphone de l'enseignant réduit | codé, testé | D-020 puis D-027 : une barre de six cases (Micro, Caméra, Élèves, Pointeur, Plus, Quitter) ; l'écriture et le tableau restent sur tablette et ordinateur. Le §9 du cahier retirait aussi les élèves et les supports : gardés pour l'enseignant, à confirmer par le directeur |
| Élève au téléphone : page à pleine taille | codé, testé | les commandes s'effacent après 3 s ; la vignette se range au bord et revient par une languette (D-023) |

## Demandes du 11/11 (ajoutées au cahier)

| Demande | État | Preuve ou manque |
| :--- | :--- | :--- |
| L'écran ne coupe plus la séance | prouvé sur le banc pour la reprise | D-009 ; l'écran tenu allumé reste à prouver sur un vrai téléphone |
| Micro des élèves fermé avant l'enseignant | prouvé sur le banc | D-008 ; fonctions du serveur à déployer |
| Après le départ de l'enseignant | prouvé sur le banc pour le serveur | D-018 : micros fermés, puis salle fermée après 120 s ; pas rejoué sur l'ensemble fusionné |
| Sortir sans couper | codé, testé | D-010 |
| Île à la façon de la Dynamic Island | prouvé sur le banc dans la salle | D-011 ; jamais elle ne pousse ni ne réduit la page |
| Écran d'attente | prouvé sur le banc | D-012 |
| Carré de l'enseignant dans le panneau des élèves | codé, testé | |
| Coran grand sur ordinateur | codé, testé | D-021 : + 21 % à 1440 x 900 panneaux ouverts ; seulement + 7 % à 1280 x 720 panneaux ouverts |
| Situations graves de la salle | codé, testé | D-019 : micro refusé, rechargement, refus d'entrée expliqués, pause vue par tous |
| Transitions de la salle | codé, testé | D-025 : l'arche pendant l'attente réelle, sortie immédiate, panneaux et tiroir sur un ressort sans rebond. **Restes** : la fermeture du tiroir au téléphone n'est pas animée ; « réduire vers l'île » est une version sobre |
| Vignettes vidéo qu'on déplace et qu'on cache au téléphone | codé, testé | D-023, chez l'élève |

## §12. Rust

Répondu : non (journal D-001).

## Ce que le directeur doit trancher (une ligne chacune, avec la recommandation)

1. Relevé de qualité : validez-vous la phrase d'information aux familles (`DROIT-RELEVE-QUALITE.md` §11.6, sur la branche du lot) ? Recommandé : oui, puis relecture par un juriste avant d'installer.
2. Relevé de qualité : faut-il l'accord du parent à l'inscription pour les moins de 14 ans au Québec ? Recommandé : demander au juriste, ne rien garder avant.
3. Cours qui déborde avec l'enseignant présent : couper à l'heure ? Recommandé : non, ne pas couper.
4. Le micro d'un élève se rouvre-t-il seul au retour de l'enseignant ? Recommandé : non, jamais sans son geste.
5. La pause repousse-t-elle la fin, et ferme-t-elle les micros ? Recommandé : elle ne repousse pas la fin ; les micros restent au choix de chacun.
6. Téléphone de l'enseignant : garder Élèves et Bibliothèque (contre le §9 du cahier) ? Recommandé : oui.
7. Au téléphone, au repos, plus aucun bouton en bas (il faut toucher la page) : d'accord ? Recommandé : oui, comme chez l'élève.
8. Un support réel entre en images, une par page (pas de lecteur de PDF) : d'accord ? Recommandé : oui pour commencer.
9. Le cahier « Où reprendre » est-il l'écran où la table des sourates semblait dans le désordre ?
