# Entrée en classe (CL-4) : maquettes du directeur, classement par rôle et rectifications

Le directeur a fourni ces maquettes le 26/09/2026 (7 planches, `PLANCHE-1.png` à `PLANCHE-7.png`, copiées depuis `Downloads/entrée classe`). Il aime le layout global.

**Ce qu'il demande, dans cet ordre :**
1. classer les écrans par rôle, puisque les écrans sont partagés entre les rôles ;
2. harmoniser le style avec celui déjà en place, pour garder une seule ligne cohérente ;
3. découper le travail, puis implémenter.

On ne redessine rien, selon la méthode tuteur : relever ce que montre l'image, puis corriger ses erreurs par écrit.

**Ordre de priorité** :
1. demande la plus récente du directeur ;
2. règles gelées (DESIGN-GOV, contrats A à E) ;
3. textes exacts de la spec 02 (CLV-01 à CLV-03) ;
4. code et composants déjà en place ;
5. image.

## 1. Les 7 planches : même layout, variantes

Les 7 planches déclinent le même layout :
- barre latérale « Rewayah » sur bureau, avec le compte en pied ;
- en-tête : retour, nom de la Classe, cours et niveau ;
- carte de l'enseignante ;
- carte « Prochaine séance », avec son bouton ;
- tâches avant le cours ;
- supports.

Elles varient sur quatre points : clair ou sombre, onglets ou non, aperçu caméra allumé ou non, libellés.

| Planche | Mode | Contenu |
|---|---|---|
| 1 | sombre | Élève et enseignante sur web ; préparation enseignante sur web ; mobiles M1 à M7 (M7 = salle en direct) |
| 2 | clair | CLV-01, 02, 03 sur web ; mobiles 01A, 01B, 02A ; préflight élève 03A et 03B ; salle 04A et 04B |
| 3 | clair | 01A, 01B et 01C (élève) ; 02A, 02B et 02C (enseignante) ; CLV-03 sur web, caméra désactivée |
| 4 | clair, barre latérale sombre | Élève et enseignante sur bureau ; préparation en 3 étapes ; mobiles ; salle en direct sur bureau |
| 5 | clair | Élève sur bureau ; préparation sur bureau ; salle en direct ; mobiles ADM-CL-01 à 05 et ADM-EN-01, 02 |
| 6 | sombre | CLV-01, 02, 03 sur bureau (préparation en 3 étapes) ; mobiles 01a, 01b, 02a, 03a, 03b, 03c ; salle mobile |
| 7 | clair lavande | Élève sur mobile et sur web ; enseignante sur web ; préparation élève et enseignante sur web ; « Tout est prêt » ; problème de micro |

## 2. Classement par rôle

### Élève standard

| Écran | Référence retenue | Variantes (mêmes idées) |
|---|---|---|
| **CLV-01 Espace Classe**, bureau 1440 | P2 « CLV-01 » (clair) | P1 web, P3 01C, P4 01a, P5, P6 CLV-01, P7 n°4 |
| CLV-01, mobile avant ouverture | P2 CLV-01A | P1 M1, P3 01A, P4, P5 ADM-CL-01, P6 01a, P7 n°1 |
| CLV-01, mobile avec la salle ouverte | P2 CLV-01B | P1 M2, P3 01B, P5 ADM-CL-02, P6 01b, P7 n°2 |
| **Couche d'entrée** (vérification silencieuse avant `/salle`) | P5 ADM-CL-03 « Nous vérifions votre appareil… » | P1 M4, P2 03A, P6 03a, P7 n°3 et n°7 |
| Couche d'entrée, blocage micro | P5 ADM-CL-04 ; web : P7 n°8 | P1 M5, P2 03B, P4 mobile, P6 03b |

### Élève en Interface guidée

Aucune planche ne lui est dédiée. Il reçoit la même couche d'entrée, en mode guidé (spec P02) : une seule question claire et une seule action principale. **L'Espace Classe n'est pas son chemin** : il rejoint depuis son Accueil (spec §2.2).

### Enseignant

| Écran | Référence retenue | Variantes |
|---|---|---|
| **CLV-02 Espace Classe enseignant**, bureau | P3 CLV-02C (sans onglets) | P1, P2, P4 01b, P5, P6 CLV-02, P7 n°5 |
| CLV-02, mobile | P3 CLV-02A (avant) et 02B (salle ouverte) | P1 M3, P2 02A, P5 ADM-EN-01, P6 02a |
| **CLV-03 Préparer la séance**, bureau | P3 CLV-03 (caméra désactivée, liste « Votre équipement ») | P1, P2, P4 et P6 (en 3 étapes), P5, P7 n°6 |
| CLV-03, mobile | P1 M6 (vérifications, « Tester le son », pas d'aperçu vidéo) | P5 ADM-EN-02, P6 03c |

### Commun : la salle en direct

Ce ne sont que des références : **hors de CL-4**.

Planches concernées : P1 M7, P2 04A et 04B, P4 CLV-03 live, P5 « Classe en direct » et ADM-CL-05, P6 CLV-04.

La salle est déjà faite (CL-3, CL-5, CL-6, D1 à D10 validés). La règle gelée §4 bis.8 interdit de rouvrir une étape faite.

L'élément nouveau de ces images est le **chrono interne**, « écoulé / restant ».
- Le directeur juge que la maquette l'a raté : il prend trop de place.
- Il ne se fait pas maintenant. C'est l'étape **LIVE-CHRONO-01**.
- Il sera **discret** : ce n'est pas une course de vitesse. Il sert seulement à savoir où en est la durée de la séance.
- La **pause configurable de l'enseignant** est notée pour plus tard : **LIVE-PAUSE-01**.

La page du Coran affichée comme support (P2 04A) relève du lecteur du Coran, hors de cette vague.

## 3. Rectifications (à appliquer sans redessiner)

### Textes : ceux de la spec, pas ceux de l'image

**Mise à jour du 26/09, après le document du directeur** `REWAYAH_CLASSE_ENTREE_PREFLIGHT_CHRONO_V1.md`. Ce document est plus récent que la spec 02, il prime donc sur elle. Ses libellés rejoignent ceux des maquettes et du code.

1. **Bouton élève** :
   - « Rejoindre » (code existant, et §3.4 du document) ;
   - libellé pour le lecteur d'écran : « Rejoindre la séance de {Classe} ».
2. **Bouton enseignant** : « Préparer l'entrée » (maquettes et document §4.3). Il mène toujours à la préparation, jamais directement dans la salle.
3. **Préparation** :
   - bouton « Entrer dans la classe » (document §6.3) ;
   - secondaire « Retour à la Classe » ;
   - micro et caméra écrits « Micro détecté · Micro coupé à l'entrée », jamais « activé » (§6.2).
4. **Sections** :
   - « Avant le prochain cours » et « Voir tout » sont gardés, car le code et les images les emploient déjà (voir `01_HARMONISATION.md` §4) ;
   - « Supports de la classe » devient le titre de bibliothèque déjà en place dans le code ;
   - côté enseignant : « Élèves », « Préparation pédagogique » et « Ressources ».
5. **Heures**, absentes des images, à ajouter :
   - « Votre heure » ;
   - « Chez Sayyida {prénom} » (élève) ou « Heure de la Classe » (enseignant), seulement si l'heure diffère ;
   - « Durée ».
6. **Conseil d'appareil**, absent des images, à ajouter en texte discret : « Tablette ou ordinateur conseillé pour le cours. Le téléphone reste pris en charge. »
7. **États de la fenêtre** (spec) :
   - avant l'ouverture : « La salle ouvrira à {heure}. » ;
   - salle ouverte : « La salle est ouverte. La séance commence dans {durée}. » ;
   - à T0 : « Séance en direct ».
   - Le décompte « Dans 3 h 28 » est conservé en pastille.

### Actions (contrat B)

8. **Un seul emplacement d'entrée** (proposition du directeur, 26/09, règle R4).
   - Il remplace la pastille « Dans 3 h 28 », la note « Le bouton sera disponible… » et le bouton grisé des images.
   - Avant l'ouverture, c'est une ligne d'état calme, « Cours dans 8 min ». À l'ouverture, il devient le bouton « Rejoindre » ou « Préparer l'entrée », au même endroit.
9. **Place du bouton sur bureau** :
   - dans la carte de séance, 16 sous son contenu ;
   - aligné sur le bord de fin (trailing) ;
   - à sa largeur naturelle, jamais étiré sur toute la carte.
   - Sur mobile, il prend toute la largeur (spec : hauteur 52, largeur disponible).
10. **Un seul bouton principal par écran.**
    - La pastille « Ouverte • Rejoindre » de l'en-tête (P3) est retirée, car elle double le bouton.
    - La cloche, la recherche et le bouton « Message » (P2, P5) sont retirés : aucune fonction n'existe derrière.
11. **« Modifier » le support prévu (enseignant)** : action tertiaire en lien, jamais un second bouton plein.

### Portée : rien d'inventé

12. **Les onglets sont retirés** : « Vue d'ensemble / Élèves / Supports / Notes / Historique », « Supports / Progression / Messages ».
    - La spec n'en prévoit pas, et chaque onglet ouvrirait une page qui n'existe pas.
    - Les sorties de la spec restent des liens : « Voir les élèves » et « Voir les ressources ».
    - La référence P3 02C est déjà sans onglets.
13. **La préparation en 3 étapes (P4 et P6) n'est pas retenue.** CLV-03 est une seule carte « Vérifications » : Réseau, Micro, Caméra.
14. **« Ma progression »** (élève) reste une carte compacte, en colonne secondaire.
    - Elle affiche le chapitre et une barre, puis un lien vers Progression.
    - Pas de statistiques détaillées : c'est la destination Progression, pas un doublon.
15. **Les notes de cours et les « Points à renforcer » (enseignant) ne sont pas repris.**
    - La spec limite la préparation à 3 éléments : support de reprise, travail en cours, alerte pédagogique autorisée.

### Médias et vie privée

16. **Caméra (CLV-03)** :
    - aucune caméra n'est ouverte automatiquement (spec, Règles) ;
    - sur bureau, la zone d'aperçu de la référence P3 est gardée, à l'état « Caméra coupée », avec l'action « Tester la caméra » ;
    - sur mobile, un aperçu compact, lui aussi coupé, puis l'état de préparation (document §12).
    - Le micro est le seul critère bloquant ; la caméra n'est jamais bloquante.
    - Pas de sélecteur de sortie audio si la plateforme ne le permet pas : aucun faux contrôle inerte (§9.2).
17. **Élève : une préparation presque silencieuse** (document §7, PRE-ELV-01).
    - Les vérifications se font seules.
    - L'état normal est minimal : « Tout est prêt », Connexion, Audio, Accès à la classe, « Vous entrerez avec le micro coupé. », puis le bouton « Entrer dans la classe ».
    - Il ne s'arrête autrement que sur un blocage (PRE-ERR-01) : un message humain, « Autoriser le micro », puis « Continuer sans micro » en secondaire.
    - Les écrans de blocage réutilisent ceux de CL-7 (feuille micro T-S4, `EtatSysteme`), sans fork.
    - Aucune erreur brute (ICE, RTP, SDP, TURN) n'apparaît.
18. **Aucune photo de personne réelle.**
    - Enseignante : l'avatar partagé du dépôt (initiales ou illustration). Une photo publique n'arrivera qu'avec les données réelles (BR-1).
    - Élèves : initiales seulement. Pas de photo d'enfant, pas de pastille de présence qui juge (« Irrégulier »).
    - Libellés neutres de la spec : prénom, identifiant de l'académie, dernier point utile.
19. **Les illustrations décoratives ne sont pas reproduites** (mosquée en bandeau, couverture du Coran photographique). On garde les surfaces du thème : aucun nouvel asset.
20. **Données de démonstration** :
    - synthétiques, avec la mention visible « Démonstration » ;
    - noms déjà utilisés en démo : Classe An-Nour, Sayyida Amina, Mariam, Yusuf, Aïcha.

### Style : une seule ligne (voir §4)

21. Les couleurs viennent du thème figé chrome / violet (K-37), en clair et en sombre. On ne recopie aucune couleur des images : le lavande de P7 et les verts ou ambres libres ne sont pas repris.
22. La barre latérale et la navigation mobile sont **celles des coques existantes de chaque rôle**. On n'invente aucune entrée : les « Mes classes / Bibliothèque / Progression » des images servent seulement à vérifier. Tout écart est noté ici.

## 4. Harmonisation avec le style en place

Complété après l'inventaire du code : voir `01_HARMONISATION.md`.

## 5. Découpage

Voir `02_DECOUPAGE.md` et le tableau de suivi, étapes `CL-4.*`.

## 6. Ajustements de la revue UX

Source : `10_classe/UX_REVIEW_CL-4.md` (étape CL-4.1, 26/09/2026, DESIGN-GOV §4). Les ajustements précisent le rendu ; ils ne touchent ni les permissions, ni les états serveur, ni les règles R1 à R21. Les numéros renvoient aux lignes de la revue.

1. **Emplacement d'entrée (n° 1)** : hauteur du bouton (52) réservée dans tous les états. La ligne d'état est un texte, ni focalisable ni annoncée comme désactivée. Chaque état porte une icône et un texte.
2. **Composition bureau par rangées (n° 4 et 6)** : élève [identité + séance | Avant le prochain cours], puis [bibliothèque | progression] ; enseignant [séance | À préparer], puis [Élèves | Supports récents]. L'ordre de lecture et de focus suit alors le document §3.2 et §4.2. Écart entre colonnes : 24. Pas de troisième zone côté enseignant.
3. **Tablette 768 en une colonne (n° 5 et 7)** : une colonne jusqu'à 839, deux à partir de 840 (M3 expanded). Remplace le 60/40 de la spec 02.
4. **Colonnes et texte agrandi (n° 20)** : deux colonnes seulement si la largeur utile divisée par le facteur de texte atteint 840.
5. **Bibliothèque (n° 9)** : vignette décorative pour le lecteur d'écran ; libellé « {titre}, {type}, {taille} » en un seul nœud ; une cible par support.
6. **Progression (n° 10)** : une barre, jamais un anneau, avec la valeur écrite à côté (« Chapitre 1 · 60 % »), en un seul nœud.
7. **Roster (n° 11)** : une ligne = une seule cible ; pas d'icônes d'action à droite des lignes ; dernier point utile en texte neutre, sans point coloré.
8. **Préparation enseignant (n° 12)** : à partir de 840, deux volets dans la largeur de lecture 800 (environ 388, 24, 388) ; sous 840, une colonne de 640. Aperçu « Caméra coupée » avec la seule action « Tester la caméra » (pas de barre d'icônes sur l'aperçu). « Modifier les périphériques » en lien tertiaire. Micro absent : bouton désactivé et raison écrite juste au-dessus.
9. **Préparation élève (n° 13)** : pas d'entrée automatique ; une seule annonce polie en fin de vérification ; la feuille de blocage CL-7 prend puis rend le focus ; aucun lien d'aide sans destination.
10. **Skeletons (n° 14)** : os exclus de la sémantique, un seul nœud « Chargement de la prochaine séance. » ou « Chargement de la Classe. » ; en préparation, un état « Vérification… » par ligne.
11. **Hors ligne et DST (n° 15)** : hors ligne, le texte de la spec 02 et « Réessayer » occupent l'emplacement d'entrée, sans second bandeau ; notice DST sous les heures, au-dessus de l'emplacement, pour l'élève comme pour l'enseignant.
12. **Annonces (n° 16)** : `Semantics(liveRegion: true)` sur l'emplacement et le résumé de préparation, pas de `sendAnnouncement` ; le décompte n'est pas dans la région live, seuls les changements d'état sont annoncés ; rendu web à contrôler en CL-4.7.
13. **Focus (n° 17)** : `FocusTraversalGroup` par rangée ; si l'élément focalisé disparaît, le focus revient au titre de la carte de séance ; le bouton qui apparaît ne vole pas le focus ; bandeaux jamais au-dessus de l'élément focalisé.
14. **Reflow 320 (n° 19)** : heures en paires empilées, libellé du bouton sur plusieurs lignes sans ellipse, couvertures en liste plutôt qu'en défilement horizontal.
15. **À vérifier en recette (n° 18 et 20)** : zone de 48 de `LienFleche` ; hauteur 52 d'`ActionPrincipale` en minimum et non en valeur fixe (sans fork du composant).

Dérogations maintenues, décision du directeur : bouton non étiré sur bureau (n° 2) ; bouton mobile dans la carte, jamais en pied collant (n° 3).
