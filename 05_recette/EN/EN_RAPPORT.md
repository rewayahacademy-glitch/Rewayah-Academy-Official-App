# Vague Enseignant : rapport de recette (EN-12)

27/09/2026. Branche `ui/enseignant-v1`, worktree `C:\RA\enseignant`. Démonstration : `/demo/enseignant` (et `/demo/salle`, `/demo/classe` pour les deux écrans qui en dépendent).

Ce rapport couvre la deuxième partie d'EN-12 : les captures finales et le contrôle de recette. La première partie (les tests qui appuient sur les vrais boutons de la vraie coquille) a été faite juste avant, dans les commits « EN-12 (lot 1) » à « EN-12 (tests) ».

## Écrans couverts par les captures

Le fichier `test/features/enseignant_recette/captures_en_test.dart` a été complété pour photographier, à travers la vraie coquille enseignant, les 11 écrans de la vague :

1. **Coquille** : les 4 destinations (Aujourd'hui, Classes, Disponibilités, Profil).
2. **Aujourd'hui** : la situation normale, sans rien à faire, et hors connexion.
3. **Mes Classes et Espace Classe.**
4. **Fiche élève** et **Signaler un besoin.**
5. **Disponibilités** : la grille, le détail d'une Classe disponible, la confirmation, le succès.
6. **Premiers pas.**
7. **Profil et photo publique** : profil, choix de la photo, aperçu, succès de l'envoi.
8. **Cahier de séance** : à remplir, validé, corrigé, en attente d'envoi (hors ligne).
9. **Absence et remplacement** : l'alerte, la feuille d'absence, l'état déclaré, la confirmation puis la carte « Remplacement ».
10. **Salle** : la salle au repos, le panneau Élèves, l'appel côté élève, la notice au parent, le sélecteur de ressources.
11. **Revue de Classe** : avec anomalies et à vide.

Pour chacun, les tailles 390, 768 et 1440, en clair et en sombre. En plus, pour un cas représentatif de chaque écran, à 390 : le texte à 200 % et l'arabe simulé (le sens de lecture inversé).

**233 images PNG** ont été produites, une par test, rangées dans `C:\RA\enseignant\build\captures\en12\`, un sous-dossier par écran (`aujourdhui`, `classes`, `fiche_eleve`, `disponibilites`, `premiers_pas`, `profil`, `cahier`, `absence_remplacement`, `salle`, `revue_classe`, `coquille`).

## Commits d'EN-12

- `EN-12 (lot 1)` à `EN-12 (lot 6)` : corrections de recette enseignant.
- `EN-12 (micro)` : annonce « Micro ouvert » en salle (l'ouverture du micro n'était pas annoncée, corrigé).
- `EN-12 (tests)` : branchement des tests depuis la vraie coquille enseignant.
- `EN-12 (captures)` : ce lot, les 233 captures de recette (ce rapport).

## Résultat de la suite complète

`flutter test --reporter failures-only` : **3 353 tests exécutés, 3 352 réussis, 1 échoué, 1 379 mis de côté** (ce sont les captures d'écran, qui ne tournent que si `CAPTURE_DIR` est donné).

Le seul échec n'est pas dans les tests de cette étape : il est dans `test/features/profil_enseignant/photo_publique_test.dart` (« ENS-01 en démonstration : la photo manque, puis est faite »), un fichier d'une étape antérieure (EN-6) que je n'ai pas touché. Le test cherche le texte « 4 sur 4 » après l'ajout de la photo et ne le trouve plus. À reprendre par la personne qui suit EN-6 ou dans la revue croisée EN-R ; je ne l'ai pas corrigé, la consigne étant de ne réparer que mes propres tests.

## Défauts visibles, notés en regardant les captures

J'ai regardé au moins une capture par écran à 390 et à 1440 en sombre. Les captures confirment, sans en ajouter de nouveaux, les points déjà relevés par l'audit (liste ci-dessous) : par exemple « Cours avec la Classe An-Nour » et « Cours dans 1 h 30 » sur Aujourd'hui, le titre générique « Revue de la Classe », le texte « Palier à venir », et la phrase de contrat en lecture seule sur le Profil. Le texte à 200 % et l'arabe simulé s'affichent sans coupure ni débordement sur les cas regardés (Aujourd'hui, Cahier, la carte Remplacement, la Revue de Classe) ; les libellés à droite et les valeurs à gauche s'inversent correctement en arabe simulé.

## Points en attente du directeur

Ce sont des désaccords ou des choix qui restent à trancher par vous ; rien n'a été corrigé sans votre décision. Repris de l'audit de recette :

1. **Remplacement contradictoire.** La liste Classes affiche déjà Al-Fatiha avec la pastille « Remplacement » et sa séance du mardi 18:00, alors qu'Aujourd'hui propose en même temps d'accepter ce même remplacement. Une capture de l'étape précédente (en8) ne montrait pas de doublon, seulement la carte ; mais la contradiction entre l'offre et la liste Classes, elle, est réelle.
2. **Deux Classes « An-Nour » différentes dans la démonstration.** Aujourd'hui et Classes montrent An-Nour le lundi à 17h30 avec 4 élèves (Yusuf, Maryam, Adam, Safiya). L'Espace Classe et la salle montrent une autre An-Nour, le lundi à 18h00, « 3 élèves sur 6 places » (Mariam, Yusuf, Aïcha). Toute Classe de la liste (Al-Fatiha, Al-Badr, Al-Ikhlas) ouvre en réalité cette même An-Nour de démonstration.
3. **Mots de développeur dans des messages d'erreur** : « Le serveur n'a pas répondu. », « Le corpus n'a pas été importé dans cet environnement. », « Il n'est pas supposé pour autant. » (formule obscure), « Le portail d'attente vous dit ce qu'il reste à fournir. ».
4. **« Cours » et « rapports » à la place de « Séance » et « cahiers ».** Sur Aujourd'hui : « Cours avec la Classe An-Nour », « {nombre} cours donnés aujourd'hui », « Le cours de {heure} est annulé », « Votre prochain cours est... » et « prières, pauses ou rapports peuvent manquer ». La carte affiche « Cours dans 1 h 30 » alors que E11 attend « Dans 1 h 24 ». Seuls « rapports » et cette ligne de contexte sont de vrais écarts avec les règles ; « cours » seul n'est pas interdit par E17.
5. **Quatre libellés visibles sans source retrouvée** : « Palier à venir » (la spec dit « gate proche »), « Rien ne demande votre attention. » (la spec dit « aucun sujet à revoir », sans texte imposé), « Deux choses à ne pas découvrir en cours de route », « Ces pièces sont en lecture seule : un contrat qui s'édite depuis l'écran de la personne qu'il engage n'est plus un contrat. » (ton de leçon).
6. **Ton de surveillance dans le Cahier**, à « Signaler une exception » : « Le motif est obligatoire : il reste au dossier de la séance. » et « Votre décision et son motif sont consignés dans le cahier, avec votre nom. ». La spec justifie le motif et la trace, mais le ton reste à adoucir.
7. **Revue de Classe : pas de retour, titre générique.** « Revue de la Classe » ne dit pas laquelle. Chaque anomalie est déjà une carte séparée, conforme à la règle « une anomalie par ligne ».
8. **« Appeler discrètement » coupé en syllabes** dans le panneau Élèves sur bureau (1440) : « Appeler di / scrètemen / t ». Le mot dépasse la largeur de la tuile ; à texte agrandi, d'autres libellés subiront le même sort.
9. **GrilleSemaine (Disponibilités) : case proposée et case libre presque identiques en sombre**, le filet ne change rien (même couleur dans les deux états) : l'information n'est portée que par une teinte à peine visible.
10. **GrilleSemaine inerte** (hors ligne ou envoi) : les cases ne disent rien à un lecteur d'écran, alors que le texte affiché dit que la grille reste consultable.
11. **Raccourci clavier M : l'ouverture du micro n'est pas annoncée**, seule la coupure l'est.
12. **GrilleSemaine : l'heure « 17h » est écrite en dur**, non traduite, alors que la liste juste à côté écrit « 17 h ».
13. **GrilleSemaine sur téléphone (390) : zone tactile d'environ 40 px**, sous le repère de 48 px habituel du projet (le minimum d'accessibilité de 24 px reste respecté).
14. **Notice au parent en salle : texte de la vague Classe, pas de la vague Enseignant** (« Tuteur de Mariam observe. »). Les deux sources écrites de la vague Enseignant se contredisent d'ailleurs entre elles (« Le parent de {prénom} observe la séance. » contre « Un parent observe cette séance »).
15. **Indicateur par élève : l'indicateur lui-même est exigé par les règles écrites** (ce n'est donc pas à retirer sans votre décision), mais les trois mots affichés (« Présence régulière », « À renforcer », « Absence récente ») n'ont aucune source écrite, et parlent de présence là où la spec demande un indicateur de préparation.
16. **Dock enseignant sur téléphone (390) : 7 boutons, libellés tronqués** (« Suppo... », « Partag... », « Outils ... »).
17. **Démonstration : Al-Fatiha à la fois Classe en remplacement et offre à accepter** (même séance, doublon volontaire de la donnée de démonstration, à corriger si elle prête à confusion).

Aucun de ces points n'a été tranché ni modifié : ils attendent votre choix.
