# Plan de la salle : composition, 26/10/2026

Demande du directeur (26/10, 08:10) : « un plan d'abord, chaque choix justifié par la simplicité et
la rapidité pour l'enseignant le moins technique ; ne pas jeter ce qu'on a construit ; le Coran et
le tableau marchent ». Source : ses trois maquettes (ordinateur à trois panneaux, téléphone
commandes, téléphone visio au toucher), rangées dans `docs/current/maquettes/salle/references/`.
Inventaire du code fait le 26/10 (lecture seule). État : **validé par le directeur le 26/10 à 08:40 (Q1 oui, Q2 non, Q3 bande gardée), « la dernière refonte de la salle »**.

## 0. Le principe, en une phrase

Rien ne vient au milieu : la page du Coran ou le tableau occupe le centre ; à gauche la vidéo de
l'enseignant et ses élèves, à droite la bibliothèque, en bas les commandes, toujours au même
endroit ; un seul clic fait tout disparaître (focus) et tout revenir ; micro, caméra et quitter ne
disparaissent jamais.

## 1. Ce qui ne change pas (déjà construit, déjà en production)

- La page du Coran, son zoom, ses flèches, le pointeur, les traits synchronisés, la reprise de page.
- Le tableau blanc 16:9 et sa synchronisation (ouverture, traits).
- La pilule d'appel au standard du 24/10 (micro, caméra, tableau, quitter), les teintes du lot 3
  (désactivé en violet, rouge réservé à Quitter), la caméra fermée par défaut, « Réessayer ».
- Les raccourcis clavier M, V, R, B sur ordinateur.
- La vue de l'élève en Interface guidée, la visite du tuteur en lecture seule.

## 2. Ordinateur (840 points et plus) : trois panneaux, comme la maquette

**Pourquoi** : un enseignant qui ne manipule pas l'ordinateur ne cherche rien ; tout est visible,
à la même place, du premier au dernier cours.

| Zone | Contenu | Ce qui existe et qui est réemployé |
|---|---|---|
| Haut | Nom de la Classe, « Sayyida/Sayyid Prénom » ; à droite la pastille « Visite de contrôle possible. » | `PiluleEtatSalle` |
| Gauche, 300 de large | 1. La vidéo de l'enseignant (sa propre image, nom, rôle, qualité du lien). 2. « Élèves (n) » : une carte par élève, prénom, pastille présent / en retard / lien coupé, micro. **Toucher un élève déplie sa carte sur place** : fiche courte et ses actions (faire réciter, rappel discret, noter, signaler, autoriser l'écriture). Jamais une nouvelle page, jamais au milieu. | `VignetteAimantee` (fixée dans le panneau), `PanneauEleves` et `_CarteEleve` (cartes qui se déplient, actions déjà codées, non branchées depuis le plein cadre), `PileCartes` (16 entre cartes, K-55) |
| Centre | La page ou le tableau, titre « Coran · Page 24 », pilule de zoom, bouton focus. Inchangé. | tout l'existant |
| Droite, 320 de large | **Bibliothèque** : champ « Rechercher un support », filtres Récents / Cette classe / Tous, puis les supports **avec leur couverture** (vignette), titre, sous-titre (« Page 24 · Dernière séance »). **Toucher un support déplie la carte** : grande couverture, un seul bouton plein « Présenter », lien « Reprendre page 24 ». Une croix « Fermer » en haut. | `BibliothequeSeance` et `SurfaceBibliotheque` (existent, non branchées), `CouvertureRessource` et `VignetteRessource` (couvertures calculées, teinte réservée au Coran), `RangeeFiltres` + `FilterPill`, `PresentateurCoran` |
| Bas, toute la largeur | Barre des commandes, deux groupes : à gauche Bibliothèque, Pointeur, Écrire, Plus ; à droite Micro, Caméra, Élèves, Quitter (rouge). **Chaque icône porte son nom dessous** sur ordinateur. | `DockSeance`, `CommandeSalle` ; le nom sous l'icône est un écart au standard du 24/10 (« icônes seules ») : décision datée demandée (§8, Q1) |

**Focus** (bouton agrandir du centre, ou touche F) : les panneaux gauche et droit et le haut
disparaissent, la page prend toute la largeur ; la barre du bas reste. Un second clic ramène tout.
**Pourquoi** : un seul geste, réversible, sans menu ; les commandes de sécurité restent visibles.
Existant : « Focus » (`agrandi`) du dock, qui aujourd'hui ne change presque rien ; il prend ce sens.

**Vérité à dire** : la bibliothèque ne peut présenter que le Coran aujourd'hui. La fonction qui sert
les autres supports (PDF, texte, audio, vidéo, image) n'a jamais été essayée en production et le
lien de lecture n'est pas branché dans l'application. Le panneau listera donc ce qui existe
vraiment ; les autres supports viendront par un lot « bibliothèque servie » (serveur + app), sans
fausse promesse à l'écran.

## 3. Les outils de dessin : le standard de la tablette

**Pourquoi** : « petites flèches pour annuler et refaire, des couleurs, tout accessible » ; rien
dans un menu.

- Quand on écrit (Écrire ou tableau ouvert), une **barre d'outils horizontale** apparaît juste
  au-dessus des commandes, sur ordinateur, et reste tant qu'on écrit : Stylo · Surligneur · Gomme ·
  Annuler ← · Rétablir → · dix pastilles de couleur · trois épaisseurs. Tout visible d'un coup.
- Existant : stylo, surligneur, gomme, Annuler, trois épaisseurs, quatre tons « d'intention »
  (à revoir, à apprendre, à renforcer, à entretenir), tous dans l'onglet Outils des Commandes.
- Nouveau : **Rétablir** (n'existe pas dans le code), un **nuancier de dix couleurs** posé dans le
  thème (`app_palette.dart`, jamais dans un écran), les quatre tons d'intention gardés comme les
  quatre premières couleurs avec leur nom lu par le lecteur d'écran. Les traits synchronisés
  portent déjà la couleur : rien ne change pour l'élève.

## 4. Téléphone (moins de 600 points) : la maquette « visio au toucher »

**Pourquoi** : l'écran est petit, la page ou le tableau doit tout prendre ; ce dont on a besoin
revient d'un toucher.

- Au repos : la page ou le tableau seul, et en bas un petit bouton « Commandes ».
- Au toucher : en haut une **capsule** avec la vidéo de l'enseignant (petite, « voir » pour
  l'agrandir), en bas la pilule micro · caméra · quitter. Tout se masque de nouveau après 3 s,
  sauf la pilule quand un panneau est ouvert (existant : `CommandesMasquables`).
- « Commandes » déplie un tiroir en bas, trois onglets : Support (la bibliothèque, couvertures),
  Outils (stylo, surligneur, gomme, annuler, rétablir, couleurs, épaisseurs), Séance (micro, caméra,
  élèves, quitter). « Réduire » le referme. Existant : le panneau Commandes et ses onglets.
- Les élèves, sur téléphone : la liste reste une feuille qui monte du bas (comme aujourd'hui),
  cartes qui se déplient sur place. **Pourquoi** : pas de place pour un panneau à gauche.
- Le tableau sur téléphone : bande 16:9 aujourd'hui ; décision du directeur après test (§8, Q3).

## 5. Ce que voit l'élève

- Au centre la page présentée ; en haut la capsule vidéo de l'enseignant ; en bas micro, caméra
  (si autorisée), quitter. Pas de bibliothèque, pas d'outils.
- **Proposé** : l'élève ne voit pas la liste des autres élèves (simplicité, discrétion ; la
  présence est l'affaire de l'enseignant). À confirmer (§8, Q2).
- Interface guidée (enfant) : mêmes écrans, cibles de 72, aucune commande de plus. Inchangé.
- Tuteur observateur, contrôleur : inchangés (lecture seule).

## 6. Les mots

- « Élève », jamais « Apprenant / Apprenante » (maquette). « Visite de contrôle possible. » sans
  « Cours enregistré » (aucun enregistrement réel : décision du 11/10, ADR-011). « Sayyida /
  Sayyid » en salle. « Bibliothèque », plus jamais « Support » ni « Choisir un support ».
- Aucune clé nouvelle sans décision ; les clés manquantes seront listées dans la PR.

## 7. Livraison : deux PR, prouvées en production par le directeur

| # | PR | Contenu | Preuve |
|---|---|---|---|
| A | Salle ordinateur | trois panneaux, élèves qui se déplient, bibliothèque avec couvertures et « Présenter », barre des commandes nommées, focus, barre d'outils avec rétablir et dix couleurs, mots corrigés | enseignant sur ordinateur, élève sur téléphone : un cours entier sans chercher une commande |
| B | Salle téléphone | capsule vidéo au toucher, tiroir Commandes à trois onglets, pilule de base au toucher, élèves en feuille | enseignant sur téléphone |

Après : lot « bibliothèque servie » (PDF, texte, audio, vidéo, image : fonction serveur, lien de
lecture, couvertures téléversées par la direction), hors de ce plan.

## 8. Trois réponses attendues du directeur

| # | Question | Proposition du pilote |
|---|---|---|
| Q1 | Sur ordinateur, le nom sous chaque icône de la barre des commandes (écart au standard « icônes seules » du 24/10) ? | oui : l'enseignant le moins à l'aise lit le mot |
| Q2 | L'élève voit-il la liste des autres élèves ? | non |
| Q3 | Tableau sur téléphone : bande 16:9 (actuel) ou plein écran qui se fait glisser ? | garder la bande pour la PR B, décider après test |
