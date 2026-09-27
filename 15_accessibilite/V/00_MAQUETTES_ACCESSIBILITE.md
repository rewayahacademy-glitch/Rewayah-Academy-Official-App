# Mode Accessibilité : planches du directeur, comparaison avec l'existant, rectifications

**Date.** 27/09/2026, étape MA-0 (documents seulement).

**Sources.**
- `PLANCHE-1..4.png` (dans ce dossier, dans l'ordre des noms reçus : 01_21_26, 01_21_28, 01_21_32, 01_21_35).
- Document `projet/ressources:specs/06_accessibilite/REWAYAH_06_RECHERCHE_MODE_ACCESSIBILITE_V1.md`.
- Règles réutilisables `memoire/ACCESSIBILITE-2026-09-27.md` (MA1 à MA24).
- Existant lu en lecture seule : `C:\RA\enseignant`, branche `ui/enseignant-v1` @ 1108a4a.

**Règle de la vague** (même méthode qu'EN-0) : ne rien jeter sans comparer. On garde le meilleur de l'existant, on prend ce que les planches apportent de mieux, on rectifie leurs erreurs sans redessiner. Style K-42 (CL-4). Thème figé (K-37) : toute remarque de couleur devient une ligne TH-2.

## 1. Ce que montrent les planches

| Planche | Format | Écrans |
|---|---|---|
| 1 | 3 téléphones | Accueil (« Comprendre quoi faire maintenant »), Ma classe (« Se préparer avant le cours »), Coran (« Lire avec plus de confort »). |
| 2 | 3 téléphones | Pendant le cours (« Suivre le support sans se perdre »), Après le cours (« Savoir quoi faire ensuite »), Mon espace (« Garder une interface simple »). |
| 3 | Ordinateur | Accueil – Mode Accessibilité : barre latérale 4 destinations, salutation, carte « Prochaine séance » large, puis deux colonnes « Avant le prochain cours » et « Lire le Coran » / « Besoin d'aide ? ». |
| 4 | Ordinateur | Classe live – Mode Accessibilité : barre latérale 6 entrées, fil d'Ariane, support Coran dominant, vidéos enseignante et « Vous » à droite, « Travail demandé », « À préparer ensuite », barre Micro, Caméra, Lever la main, Discussion, Participants, « Quitter la classe ». |

## 2. Classement par rôle

Les 4 planches sont du rôle **élève**, sans distinction d'âge (MA1). Elles montrent une enfant (« Mariam, 10 ans ») mais le mode vaut aussi pour l'élève adulte, la personne âgée ou en situation de handicap.

| Rôle | Ce qui le touche | Règle |
|---|---|---|
| Élève mineur | Tous les écrans ; indication d'observation ; pas d'âge affiché. | MA17 à MA23. |
| Élève adulte | Tous les écrans ; peut activer ou désactiver lui-même (démonstration). | MA24, vouvoiement (MA4). |
| Tuteur (parent) | Page existante « interface » du profil de l'enfant, à renommer ; il observe (l'enfant le voit). | MA3, MA23, MA24. |
| Enseignant | Voit « Interface guidée » sur la fiche de séance (`fiche_seance.dart`) : libellé à renommer, et question de confidentialité (§5, question Q6). | E5, MA3. |
| Administration | Aucun écran dans cette vague. | — |

## 3. Comparaison écran par écran

Légende : **G** = garder de l'existant ; **P** = prendre de la planche ; **C** = corriger (erreur de la planche, ou contradiction avec une règle).

### Planche 1

**Accueil (téléphone).** Existant : `accueil_eleve_page.dart` (« Deux blocs, rien d'autre » en mode enfant, sans navigation, pictogrammes et audio).
- G : la sobriété des deux blocs ; l'`EmplacementEntree` partagé (R4) ; le texte « Avant le prochain cours » déjà présent dans les traductions ; la clé audio existante comme aide (MA13).
- P : l'ordre du doc §5 (salutation courte, Prochaine séance, un bouton, Avant le prochain cours, Lire le Coran, Besoin d'aide ?) ; la photo de l'enseignant dans la carte ; icône + texte sur chaque ligne ; la barre à 4 destinations.
- C :
  1. Le bouton « Voir ma classe » n'est pas fixe : c'est l'état de l'emplacement unique (E11, R4). Fenêtre ouverte, il devient l'entrée ; avant, « Voir ma classe ».
  2. La pastille « Aujourd'hui » double la date déjà écrite : retirée (une pastille = une exception, E12).
  3. « Qu'Allah facilite ton apprentissage » : phrase de décor, à garder seulement si le directeur la veut (Q4) ; la salutation reste une ligne.
  4. « Une question ? On est là pour t'aider. » est une promesse de support sans canal (DB-CPT-07) : retirée (MA14).
  5. L'illustration de mosquée en filigrane est retirée (K-42, pas de décor).
  6. La barre d'état « 9:41 » et les noms des planches ne sont pas repris (E20) ; enseignant de démonstration Sayyid Ibrahim par défaut, variante Sayyida.

**Ma classe avant la séance (téléphone).** Existant : fiche de Classe élève et préparation CL-4 (`preparation_eleve.dart`, variante « une question, une action » pour `InterfaceMode.enfant`).
- G : l'en-tête d'identité CL-4 (retour, nom humain, ligne de contexte) ; l'`EmplacementEntree` ; la préparation guidée ; « À préparer » (3 au plus).
- P : la photo de l'enseignante près du nom ; heure locale et durée en deux petites données ; la mention « Tablette ou ordinateur conseillé. Le téléphone reste pris en charge. » (doc §6) ; la ligne « Support de la classe ».
- C :
  1. **« Salle ouverte », « Disponible dans 20 min » et un bouton « Rejoindre le cours » actif** se contredisent : une seule ligne d'état qui devient le bouton quand l'entrée est permise (R4, MA19). Jamais de bouton actif avant.
  2. « Paris (GMT+2) » : l'heure de la Classe n'est affichée que si elle diffère de l'heure locale (E12).
  3. Pas d'icône caméra sur le bouton : « Rejoindre » n'allume rien (R8).
  4. La ligne « Support de la classe » en vert : la couleur n'est pas un sens (MA11) ; teinte = ligne TH-2 si besoin.

**Coran (téléphone).** Existant : `tc_mushaf` (`mushaf_page`, `vue_page_mushaf`, `vue_verset_agrandi`, `navigation_coran_feuille`). Rendu intouchable.
- G : le rendu du Mushaf tel quel ; le mode verset ; la feuille de navigation (sourate, page) ; la reprise de position.
- P : gros contrôles « Précédent » et « Suivant » avec texte ; un réglage de taille simple (moins / plus) **hors du rendu** ; la ligne « À lire aujourd'hui » quand un travail existe.
- C :
  1. La traduction française sous chaque verset n'est pas ajoutée : on ne touche pas au rendu (MA22). Une traduction est une décision séparée (Q7).
  2. Signet et roue de réglages en haut : seulement s'ils existent déjà ; sinon retirés (pas de fonction nouvelle par la planche).
  3. Le cartouche décoratif du titre de sourate appartient au rendu existant ou n'est pas ajouté.

### Planche 2

**Pendant le cours (téléphone).** Existant : salle unique `/salle` (`vue_seance.dart` avec la variante `InterfaceMode.enfant` CLV-05, `vignette_video.dart`, `zone_support.dart`, « deux commandes seulement » dans `vue_salle.dart`).
- G : la salle unique ; le support dominant ; les deux commandes du mode ; le réseau calme (R11, R12) ; les textes d'observation existants.
- P : l'état « Vous suivez le support automatiquement » en une ligne calme ; la vignette de l'enseignant avec son nom ; « Micro coupé », « Caméra coupée » avec texte ; l'aide en bas.
- C :
  1. « Un tuteur vous observe » est remplacé par le texte existant « Ton parent observe la séance. » / « Votre parent observe la séance. » (MA9, MA23).
  2. Le bouton rouge « Quitter le cours » utilise le niveau destructif existant d'`ActionPrincipale` ; aucune couleur nouvelle (K-37). Espacé des commandes (MA10).
  3. « Problème de son ou d'image » : l'aide mène à l'aide de la salle existante (préparation, réseau), pas à un contact humain non décidé.
  4. La traduction sous les versets n'est pas ajoutée (rendu intouchable).

**Après le cours (téléphone).** Existant : `resultat_seance.dart`, et le travail issu du cahier (K-45).
- G : l'écran de résultat existant ; le travail du cahier.
- P : l'ordre prochaine action, travail pour la prochaine fois (3 au plus), « Revoir le support du cours », prochaine séance.
- C :
  1. « Très bien ! Vous avez suivi toute la séance. » est retiré : jugement automatique (E8) et affirmation de présence (R7). Il reste « Cours terminé ».
  2. L'icône de confettis est retirée (pas de célébration, pas de gamification, MA7).
  3. « Message de votre enseignante » : seulement si le contrat donne un message à l'élève (Q8) ; sinon retiré.
  4. Les dates 2024 ne sont pas reprises (E20).

**Mon espace (téléphone).** Existant : `/compte` (`compte_page.dart`) avec les sections Apparence et Accessibilité (« Réduire les animations »), `lectureGrande` (« Lecture en grand texte »), la page d'aide honnête, les appareils ; côté tuteur, `/tuteur/foyer/:eleveId/interface` (« Interface guidée » / « Interface standard »).
- G : la page Compte existante et ses réglages ; les libellés existants « Réduire les animations », « Taille du texte » ; la page d'aide ; les appareils.
- P : la carte d'identité en tête ; une ligne « Mode Accessibilité » avec son état ; le groupe « Préférences d'affichage » en `GroupeReglages`.
- C :
  1. « 10 ans » est retiré : l'âge n'est pas affiché (MA23, minimisation).
  2. « Mode Accessibilité actif » + pastille « Actif » disent deux fois la même chose : titre et état, sans pastille.
  3. « Animations réduites » devient le libellé existant « Réduire les animations » (MA9 : même fonction, même libellé).
  4. « Aide audio » : seulement si le réglage existe réellement (clé audio existante) ; sinon retiré (Q5).
  5. « Présentation standard – Demander une interface classique » : un mineur ne voit une demande que si la politique et son contrat existent (DB-FOY-04, MA24). L'adulte voit une bascule (démonstration).
  6. « Une question ? On est là pour m'aider. » retiré (MA14).
  7. Chevrons à côté des interrupteurs : un interrupteur n'ouvre pas une page ; pas de chevron.

### Planche 3

**Accueil (ordinateur).**
- G : la coquille existante (barre latérale au-delà de 1200, contrat D) ; l'emplacement unique.
- P : la barre latérale à 4 destinations avec texte ; la carte « Prochaine séance » en rangée (identité à gauche, heure et durée, bouton au bord de fin) ; deux colonnes dessous (tâches ; Coran et aide).
- C :
  1. La cloche avec point de notification est retirée (notifications non garanties, doc §5 « éviter »).
  2. Le cœur après le prénom et l'illustration de mosquée sont retirés (MA4, K-42).
  3. « Salle ouverte » avec un bouton « Voir ma classe » : l'état et le bouton sont un seul emplacement (R4).
  4. Le bouton n'est pas étiré (contrat B : largeur naturelle sur bureau) et reste à 16 de son objet.

### Planche 4

**Classe live (ordinateur).**
- G : la salle unique `/salle`, sa variante guidée (vignette ≈ 300 × 273 sur bureau), le rendu du Coran, le réseau calme.
- P : le support dominant à gauche ; l'enseignant et « Vous » à droite ; l'état « En direct » ; la barre de commandes en bas avec texte sous chaque icône ; « Quitter la classe » isolé au bord de fin.
- C :
  1. **Pas de navigation de l'app dans la salle** : la barre latérale (Accueil, Ma classe, Coran, Historique, Foyer, Compte) est retirée (MA17). « Foyer » est de toute façon une destination du tuteur.
  2. « Lever la main », « Discussion » et « Participants » sont retirés : absents du contrat de salle (E3, MA20).
  3. « Travail demandé » et « À préparer ensuite » quittent la salle : ils vont après la séance (chrome réduit, doc §6).
  4. « Paramètres » en haut : seulement les réglages de salle existants.
  5. « Connexion bonne » n'est pas affichée en continu : le réseau ne s'affiche que s'il pose problème, en phrase calme (R12).
  6. L'indicateur vert de signal près de « Vous » : couleur seule (MA11), retiré ou doublé d'un mot.
  7. Flèches à côté de Micro et Caméra (choix de périphérique) : seulement là où la plateforme le permet (R10).

## 4. Données de démonstration (E20, K-35)

- Élève de démonstration : Mariam (identifiant existant `demo-eleve-mariam`), Classe An-Nour, niveau 1. Variante adulte : un élève adulte fictif en Mode Accessibilité (prénom au choix de MA-1b, jamais une vraie identité).
- Enseignant : Sayyid Ibrahim par défaut, variante `&titre=sayyida`.
- Dates en septembre et octobre 2026 ; aucun âge affiché.
- Photos non réelles, initiales en repli.

## 5. Mon avis sur le document 06 (droit de regard du directeur)

1. **Navigation.** Le doc (§3) fixe Accueil, Ma classe, Coran, Mon espace ; l'élève standard a aujourd'hui Accueil, Coran, Suivi, Compte. Comme le mode ne doit pas créer une seconde application, les deux présentations prennent les mêmes 4 destinations. Choix provisoire : celles du doc, pour les deux (Q1).
2. **Fin du « zéro lecture ».** L'ancien mode enfant (6-8 ans, sans lecture, sans navigation, cibles 72) est remplacé par un mode sans âge, avec texte et icône. C'est ce que dit le doc ; je le note parce que c'est un changement fort de l'existant.
3. **Cibles.** Le doc dit 52 à 56 ; l'existant du mode enfant dit 72. DESIGN-GOV fait primer la valeur prouvée : on garde les jetons de `app_metriques.dart` s'ils sont au moins de 52 (Q3).
4. **GOV.UK** (§1.7) : exclu comme référence de design par DESIGN-GOV ; retenu seulement pour l'idée de tester avec de vrais utilisateurs.
5. **Donnée sensible.** Savoir qu'un élève adulte utilise le Mode Accessibilité peut révéler un handicap (catégorie particulière, UK GDPR art. 9). L'enseignant ne devrait voir que ce qui l'aide à enseigner, sans raison ni diagnostic (Q6).
6. **Référence au document 06_ELEVE_ENFANT.md.** Le doc dit « à intégrer dans `06_ELEVE_ENFANT.md` », qui n'est pas fourni. On avance sur le doc 06 recherche seul (Q9).
