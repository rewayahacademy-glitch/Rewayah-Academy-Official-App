# Classe et visio : rapport pour le directeur

Mis à jour le 26/09/2026 (nuit), par un agent d'exécution du poste B pendant que vous dormiez. Langage simple, sans jargon technique.

## En une phrase

Tous les écrans prévus pour la salle de classe (élève, interface guidée pour les enfants, enseignant) sont codés, testés et comparés à vos images retouchées. Le contrôle final (vérification complète du code) est passé sans aucune erreur. Rien n'est branché à un vrai serveur : c'est voulu (décision K-28), le branchement se fera en une fois à l'étape BR-1.

## Ce qui est fait

- **La salle vue par un élève** (CLV-04) : le support de cours occupe l'écran, la petite vidéo de l'enseignante est en coin, jamais déformée ; les boutons (micro, caméra, agrandir, quitter) sont ronds, tous de la même taille.
- **L'interface guidée** (CLV-05, pour les enfants) : mêmes principes, en plus simple, avec des couleurs pleines pour les deux boutons principaux (Parler en vert, Caméra en violet).
- **La salle vue par l'enseignante** (CLV-06) : en plus des mêmes éléments, elle a une barre d'outils (Pointeur, Marquer, Masquer, Annoter) et deux boutons « Élèves » et « Supports ».
- **Le panneau Élèves** (CLV-07) : liste des élèves connectés, avec la fiche dépliée de l'élève sélectionné (niveau, chapitre en cours, dernière séance) et 4 actions (rappeler, choisir pour réciter, noter, signaler un besoin).
- **Le panneau Supports** (CLV-08) : reprendre le dernier support, supports récents, ressources de la classe.
- **La fin de séance** : côté élève et guidée, un écran simple « Séance terminée » ; côté enseignante (CLV-10), un petit récapitulatif (qui était là, durée, cahier à compléter).
- **Le point rouge d'enregistrement** : toujours un petit point rouge et un texte discret, sans encadré. Quand un parent observe la séance, le point clignote doucement (sauf en interface guidée, où il reste fixe avec un œil).
- Tout est en français (textes gérés par le système de traduction du projet), et fonctionne aussi bien en thème clair qu'en thème sombre, sur téléphone, tablette et ordinateur.

## Où voir chaque écran (mode démonstration, sans serveur)

Dans la version d'essai, ajoutez `/demo/salle` à l'adresse. Une page liste chaque rôle (élève, interface guidée, enseignante) et chaque situation (au repos, pendant qu'un parent observe, rien de partagé, panneau Élèves, panneau Supports, fin de séance). Un clic ouvre la salle en plein écran, avec des boutons qui répondent vraiment (micro, caméra, zoom, panneaux). Les noms et les chiffres affichés sont fictifs.

## Les captures (images) à regarder

Dossier : `C:\RA\pilotage\10_classe\captures\T9\`. Mode d'emploi détaillé (quel fichier regarder pour quel écran) : `C:\RA\pilotage\05_recette\CL\OU_TROUVER.md`. En résumé : ouvrez d'abord les fichiers `planche_….png`, qui montrent votre image retouchée en haut et l'écran réellement codé en dessous, pour comparer d'un coup d'œil. Il y en a 10, en clair et en sombre (les fichiers `_dark.png`). Les photos (visage de l'enseignante, illustrations) sont remplacées par des couleurs unies : c'est volontaire, aucune vraie photo n'est utilisée dans les essais.

## Les 8 petits choix laissés en attente (Q1 à Q8)

Vous n'aviez pas encore répondu à 8 petites questions de détail. Pour ne pas arrêter le travail, l'option la plus proche de vos images a été appliquée à chaque fois. Si vous préférez l'autre option un jour, c'est un changement d'une ligne de code, pas une reprise :

1. **Boutons de l'interface guidée** : disques pleins verts (Parler) et violets (Caméra), même taille que les autres boutons. *(appliqué : oui)*
2. **Rangement des outils enseignant** : rangée au-dessus du support sur grand écran ; en colonne à droite quand le panneau Élèves ou Supports est ouvert.
3. **Le compte de l'enseignante** : affiché en haut à droite.
4. **La phrase d'observation** : reste complète (« Tuteur de Mariam observe. »), pas raccourcie.
5. **Le texte de la mention d'enregistrement** : affiché en entier, pas résumé.
6. **Zoom local pour l'élève** : oui, avec la phrase « Zoom local, sans effet sur les autres. ».
7. **Vidéo des autres élèves** : jamais montrée à un élève.
8. **Interface guidée sur ordinateur** : la vidéo est à côté du support, jamais par-dessus.

## Contrôle final effectué cette nuit (26/09)

- Mise à jour du code : déjà à jour (rien de nouveau à récupérer).
- Vérification complète du code (`flutter analyze`) : **aucun problème**.
- Ensemble complet des tests automatiques (`flutter test`, 468 secondes) : **2942 tests réussis, 731 mis de côté (des captures d'écran qui ne se déclenchent que sur demande), aucun test en échec.**
- Aucun test n'a cassé à cause de ce lot : rien à corriger, rien à commettre côté code.

## Ce qui n'est pas encore fait

- **CL-4 (les écrans d'entrée)** : « Espace Classe » élève, « Espace Classe » enseignant, préparation technique avant d'entrer. Ces 3 écrans n'ont pas de maquette du directeur : quelqu'un doit d'abord les dessiner (ou vous les valider directement en code) avant de les coder.
- ~~CL-7 (les écrans de secours)~~ : **fait le 26/09** avec votre feu vert sans maquette, voir la section « Écrans de secours (CL-7) » plus bas.
- Ces deux points étaient prévus pour le poste A ; comme il est éteint depuis le 25/09, ils attendent soit une reprise par le poste B, soit votre feu vert pour les dessiner sans maquette (méthode habituelle : gabarits déjà utilisés ailleurs).
- **BR-1 (branchement du serveur, tout en une fois, plus tard)** : le vrai support de cours partagé, les outils d'enseignement qui agissent réellement, la vraie bibliothèque de supports, les permissions micro/caméra du téléphone, la fusion technique des deux salles existantes en une seule en coulisses. Rien de tout cela n'est visible pour l'instant : les écrans sont prêts à les recevoir dès que vous donnez le feu vert pour BR-1.
- Une question mineure laissée à votre avis : quand un enfant en interface guidée quitte la séance avant la fin, il voit aujourd'hui « La séance est terminée. » alors qu'elle continue pour les autres. Une phrase plus juste serait « Tu as quitté la séance. ». Rien n'a été changé sans votre accord.

## Tableau de suivi (nettoyage)

Le tableau partagé (page « Chantier Tuteur V1 ») a été relu et remis à jour ce soir pour qu'il reflète l'état réel du lot Classe et visio (les lignes CL-3 et CL-6, marquées comme en cours, sont en réalité terminées) et pour que l'autre poste ne s'y perde plus : voir le récapitulatif court en tête des lignes `CL-*`.

## Écrans de secours (CL-7)

Fait le 26/09/2026, sans maquette (votre feu vert), en réutilisant les éléments déjà présents dans l'application. Rien n'est branché au serveur : ce sont les écrans, prêts à recevoir les vrais signaux à l'étape BR-1.

**Ce qui est fait**, pour l'élève, l'enfant en interface guidée et l'enseignant :

- **Réseau faible** : une bande d'avertissement en haut (« Réseau faible. L'audio est prioritaire. ») ; la séance continue normalement.
- **Reconnexion** : la bande dit « Connexion interrompue. Reconnexion en cours… » ; le cours reste affiché ; Micro et Caméra sont mis en pause le temps de la reconnexion.
- **Connexion rétablie** : un court message « Connexion rétablie. » qui disparaît seul.
- **Reconnexion impossible / hors ligne** : un encadré avec « Réessayer » et « Quitter la séance » (Quitter demande toujours confirmation).
- **Micro bloqué** par le téléphone : une petite fenêtre explique que le micro est bloqué, avec « Continuer sans micro ». Le bouton « Ouvrir les réglages » viendra avec le serveur (BR-1).
- **Caméra interdite** (élève) : pas de bouton Caméra, et une ligne discrète au-dessus des boutons du bas : « Caméra désactivée pour ce profil. » L'enfant en interface guidée ne voit ni bouton ni explication.
- **Séance prolongée** : « La séance se poursuit. » à la place du minuteur ; aucun bouton « Prolonger ».
- **Accès retiré** : un écran « Votre accès à cette séance a pris fin. » avec « Retour à la Classe ». Au clavier, ce bouton est déjà sélectionné à l'ouverture.

**Où le voir** : ouvrez `/demo/salle`. Pour chaque rôle (Élève standard, Interface guidée, Enseignant), il y a deux groupes de boutons : « Déroulé de la séance » (l'ordinaire) puis **« Situations de secours »** (9 situations ; 8 pour l'enseignant, car il a toujours la caméra). Un clic ouvre la salle dans cette situation. Dans « Reconnexion impossible », « Réessayer » fait revenir la connexion pour que vous voyiez la suite.

**Captures à regarder** (dossier `10_classe/captures/`) :

- `TS6/cl7_demo_liste_390x844_light.png` : la page de démonstration rangée par rôle.
- `TS5/cl7_04_camera_interdite_768x1024@1_light.png` : la ligne « Caméra désactivée pour ce profil. » tient maintenant sur une seule ligne (avant, elle se coupait en deux sur tablette).
- `TS2/` : réseau faible, reconnexion, connexion rétablie (élève `cl7_04`, guidée `cl7_05`, enseignant `cl7_06`).
- `TS3/`, `TS4/`, `TS5/` : reconnexion impossible, micro bloqué, séance prolongée, accès retiré.

**Vérifié** : téléphone, tablette, ordinateur, clair et sombre ; écran très étroit (320) ; texte agrandi à 200 % ; navigation au clavier (on voit toujours où l'on est). 619 tests réussis, aucun échec. Les recommandations de Google (Material) et d'Apple ont été relues : rien à changer.

**À trancher par vous** (une option par défaut est appliquée, rien n'est bloqué) :

1. **Q-S1** : « Caméra désactivée pour ce profil. » reste **visible** au-dessus des boutons (choix actuel), ou bien seulement **lu à voix haute** par le lecteur d'écran, sans texte visible ?
2. **Q-S2** : ces textes n'étaient pas dans la spec, ils ont été proposés : « Connexion rétablie. » pour l'enfant ; « Continuer sans micro » pour l'enfant ; « Impossible de rétablir la connexion. » pour l'enseignant ; et, pour le lecteur d'écran, « Indisponible pendant la reconnexion. » sur un bouton en pause. Les gardez-vous ?
3. **Boutons de l'enfant pendant la reconnexion** : en interface guidée, les grosses pastilles de couleur « Parler » et « Caméra » deviennent **grises (sans couleur)** tant que la reconnexion dure, pour montrer qu'elles sont en pause. Cela vous convient-il, ou préférez-vous qu'elles gardent leur couleur (en restant inactives) ?
