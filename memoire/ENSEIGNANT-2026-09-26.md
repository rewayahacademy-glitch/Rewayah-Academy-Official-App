# ENSEIGNANT-2026-09-26 : règles réutilisables du rôle enseignant (E1 à E20)

**Sources.**
- Document du directeur : `specs/04_enseignant/04_ENSEIGNANT.md` (V1, 26/09/2026, 2 680 lignes). **Ne pas le relire en entier** : ce fichier en garde l'essentiel.
- Cinq planches : pilotage `12_enseignant/V/PLANCHE-1..5.png`.
- Rectifications : pilotage `12_enseignant/V/00_MAQUETTES_ENSEIGNANT.md`.

**Ordre d'autorité.**
1. La demande la plus récente du directeur.
2. DESIGN-GOV (gelé).
3. K-42, le style CL-4.
4. CLASSE-ENTREE (R1 à R21).
5. Le présent fichier.
6. Le document 04.
7. Les planches, qui sont des exemples de composition et jamais une règle métier.

## Métier

- **E1. Classe entière, référent permanent.** L'enseignant se positionne sur une Classe entière, avec tout son rythme récurrent. Il ne prend jamais un élève isolé ni une seule séance normale.
  - L'ancien matching disparaît de l'écran : « Élèves en attente », « Prendre {jour} à {heure} ».
  - Un remplacement modifie une séance, jamais le titulaire.
- **E2. Normal, c'est automatique et calme. Une exception, c'est visible et actionnable.**
  - Aucune présence manuelle, aucun rapport narratif, aucune donnée saisie deux fois.
  - Préparer une séance prend moins d'une minute, et le cahier moins de 45 secondes.
  - Pas de message « Succès ! » quand le résultat se voit déjà.
- **E3. Une fonction a un seul emplacement.** La carte anti-doublon du doc §8 fait foi.
  - Bibliothèque, Coran, cahier, revue, fiche élève, signalement, absence et photo s'ouvrent depuis leur objet.
  - Aucune de ces fonctions n'entre dans la barre de navigation.
- **E4. La salle est unique.** `/salle` et la préparation de CL-4 sont réutilisées telles quelles.
  - Les ajouts propres à l'enseignant : roster, fiche élève, file de récitation, barre d'outils compacte, sélecteur de ressources, notice discrète du parent.
  - Aucune seconde salle, aucun second préflight.
- **E5. Aucune donnée privée des familles côté enseignant.** Ni téléphone, ni e-mail, ni adresse, ni pièce d'identité, ni paiement, ni solde.
  - La fiche élève est pédagogique seulement : prénom, identifiant Académie, niveau, objectif, dernière séance, reprise, assiduité récente, travail, notes autorisées.
  - **Photo de l'élève : elle s'affiche** (décision du directeur, 26/09/2026), partout où l'enseignant et l'administration identifient l'élève : roster, fiche élève, salle, cahier.
    - Si le tuteur a déposé une photo, c'est que l'enseignant et l'administration en ont besoin. La vidéo est déjà permise en classe, donc la photo aussi.
    - Composant `PhotoEleve` (photo signée, initiales seulement en repli).
    - Cette visibilité est couverte par le consentement de l'inscription de l'enfant (texte A5 de pilotage `09_consentements`).
    - Une règle « initiales seulement, jamais la photo de l'élève » est une erreur : elle ne venait pas du directeur.
- **E6. Rien de ce que le serveur décide n'est calculé dans Flutter.** Cela vaut pour :
  - la fenêtre d'entrée, la capacité, la durée et les seuils (pas de 4, 5, 6, 60, 90 ni 40 % en dur) ;
  - la compatibilité des Classes et la limite de charge ;
  - le quota d'observation des parents ;
  - l'état d'un remplacement.
  - D'ici BR-1, ces valeurs viennent des données de démonstration (K-35), jamais de constantes dans un widget.
- **E7. Pas de faux succès.** Cette règle vise « Cahier enregistré », « Cette Classe vous est attribuée » et « Remplaçant confirmé ».
  - Ces messages ne s'affichent que sur une réponse du serveur (en démonstration, sur l'état de démonstration correspondant).
  - Une demande envoyée à l'administration dit « Votre demande a été transmise. Elle apparaîtra dans vos Classes après confirmation. »
- **E8. Pas d'IA qui juge.**
  - Aucune évaluation automatique de la récitation (« Très bien », « Prononciation correcte »).
  - Aucune note, aucun classement, aucun badge présenté comme une garantie.
  - Aucun bouton « Suggérer avec l'IA ». Un préremplissage n'est qu'une proposition que l'enseignant vérifie.
- **E9. Ce n'est pas une course.** Aucun compte à rebours par élève dans la file de récitation.
  - Le chrono de séance reste discret et reporté (LIVE-CHRONO-01).

## Écran et style (en plus de K-42 et R1 à R21)

- **E10. Navigation à 4 destinations, dans le même ordre partout** : Aujourd'hui, Classes, Disponibilités, Profil.
  - Barre en bas sur mobile, rail sur tablette, barre latérale sur ordinateur.
  - Pas de Messages, de Statistiques, de Planning ni de Mes élèves dans la navigation.
- **E11. Un emplacement unique pour la prochaine séance** (R4 étendu). Il affiche d'abord une ligne de contexte calme (« Dans 1 h 24 »), puis un seul bouton qui évolue :
  - avant la fenêtre d'entrée : « Préparer la séance », qui ouvre la Classe à son bloc de préparation ;
  - fenêtre ouverte : « Préparer l'entrée » (CL-4), puis « Entrer dans la classe » ;
  - après la séance : « Finaliser le cahier » ;
  - sinon : « Voir la Classe ».
  - Jamais de bouton grisé. Le modèle `EmplacementEntree` est réutilisé, sans fork.
- **E12. Une carte de séance montre peu de choses** : nom de la Classe, heure, durée, nombre d'élèves.
  - L'heure de la Classe n'apparaît que si elle diffère de l'heure locale.
  - Une pastille n'apparaît que pour une exception : Remplacement, Reportée, Annulée. « Confirmée » est l'état normal : pas de pastille.
- **E13. Des lignes groupées plutôt que des onglets.**
  - Sur mobile, pas d'onglets internes dans une Classe ou une fiche élève : des sections en une seule colonne.
  - Sur bureau, des rangées, et deux colonnes au-delà de 840 de largeur utile.
- **E14. Les actions de séance n'apparaissent qu'en direct.** Hors séance, la fiche élève ne propose que « Signaler un besoin ». En séance, elle propose :
  - « Faire réciter » ;
  - « Appeler discrètement » ;
  - « Noter » ;
  - « Signaler un besoin ».
- **E15. Les disponibilités sont hebdomadaires.** Les jours sont écrits sans date (« Lundi »), sans navigation de semaine, sans « 16 sept. ».
- **E16. Le texte montré à l'élève nomme l'enseignant par son titre** : « Sayyid Ibrahim vous appelle », jamais « Le professeur » (leçon M2 de CL-4, et K-41 sur le genre).
  - L'enseignant de démonstration est Sayyid Ibrahim (un homme). La variante « Sayyida » est une option de démonstration.
- **E17. Lexique** :
  - Classe, Séance, Séance en direct, Cahier de séance, Vérifier la présence, Élève à renforcer.
  - Jamais : groupe, Session, Cours en cours, matching, Rapport obligatoire, Élève problématique, Erreur inconnue.
- **E18. L'enseignant ne crée rien d'administratif.** Pas de bouton « Nouvelle classe », « Nouvelle séance » ou « Ajouter un élève ».
  - Pas non plus de « Générer une évaluation », « Imprimer le roster » ni « Ajouter un document ». Pas de messagerie avec les familles.
- **E19. Les raccourcis clavier en salle sur ordinateur sont une proposition en attente** (voir `00_MAQUETTES_ENSEIGNANT.md` §4). Ils ne sont pas codés avant la décision du directeur.
- **E20. Les dates et noms de démonstration sont réalistes et datés de 2026.** Les données des planches (2024, Youssouf, Amina…) ne sont jamais recopiées telles quelles.
