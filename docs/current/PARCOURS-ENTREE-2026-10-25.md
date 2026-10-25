# Parcours d'entrée : spécification unique, 25/10/2026

Écrite par le pilote à la demande du directeur (25/10, 16:30) : « ratisser tout le domaine de la
connexion, avant, pendant, après, pour tout refaire d'un coup ». Remplace la fiche de la seule page
de connexion (son contenu est repris au §3 C). État : **validée par le directeur pour la PR 1
(25/10, 17:35)** ; deux réponses encore attendues pour la suite (§6).

## 1. Ce qui existe aujourd'hui (lu dans le code le 25/10)

| Moment | Aujourd'hui | Défaut vu |
|---|---|---|
| Lancement | Pas d'écran de démarrage dessiné : le nom en texte, un ornement, une roue, le temps de lire la session (8 s avant un message « c'est long ») | « Trop moche » (directeur) ; décision du 10/10 « animation propre » jamais faite |
| Visiteur sans session | Arrive sur `/connexion` : carte blanche sur page claire, logo vertical, adresse e-mail, lien par courriel, Google, appareil de l'élève | Ne ressemble pas à la marque ; carte dans une page |
| Lien envoyé, récupération | Même carte, textes existants | Idem |
| Après le lien, compte sans profil | `/inscription` : usage (moi, famille, code enseignant ou comptable), identité (prénom, nom), genre, récapitulatif, puis création du profil au serveur | Les réponses ne survivent pas à un rechargement ; rien n'est demandé avant le compte |
| Compte en attente | `/attente` : accords (cases, un bouton Suivant), pièce d'identité (enseignant), candidature, partage, talents | Hors périmètre visuel de ce lot, sauf l'habillage (§3 F) |
| Compte actif | Racine de son rôle (tuteur, élève, enseignant, direction, contrôleur, comptable) ; redirections dans `redirection.dart` | Rien à changer |
| Animation | Aucune dans tout le domaine | |

Ce qui ne bouge pas : les redirections, les routes, les règles d'accès, la RLS, les textes existants.

## 2. Décisions qui s'appliquent

- 17/10 : les pages qui défilent avant la connexion sont supprimées ; une même information n'est
  demandée qu'une fois ; tout ce qui se choisit se choisit dans une liste ; accords sur une page.
- 10/10 : une animation propre au démarrage, sans logo figé.
- 25/10, 16:20 : la connexion prend la page « Ne plus recevoir ces e-mails » telle quelle, plus le
  formulaire ; sur ordinateur, l'image au début de ligne (droite en arabe).
- 25/10, 16:40 : logo horizontal blanc centré en haut.
- 25/10, 16:50 et 17:10 : **l'illustration s'anime** (le symbole du logo au milieu, sa porte, la
  lumière qui part comme une route), pour une page moderne ; **le logo horizontal apparaît
  seulement**, avec un style net, il ne voyage pas. Rien d'autre n'est animé.
- 25/10, étude « accueil des familles » (`ETUDE-ACCUEIL-ET-CLASSES-2026-10-25.md` §2 et §3,
  décision 2, après les vidéos de Riwayah) : **compte en dernier et aucune attente de validation
  pour une famille** ; pays et fuseau repris de la candidature des enseignants ; puces pour les
  choix courts, cartes avec exemple pour le niveau et l'objectif ; compteur d'étapes ; deux volets
  sur ordinateur (réponses à gauche, question à droite, lettres A/B/C au clavier) ; demande de
  créneau personnalisé branchée sur le serveur existant, roulette jour et heures ; **moins de dix
  étapes**. Confirmée oralement par le directeur le 25/10 à 17:00 : « d'abord le questionnaire,
  après il enregistre ses infos, sinon les gens fuient ».

## 3. Le parcours cible, écran par écran

Un seul habillage pour tout le domaine, celui de la capture : fond violet de marque uni, logo
horizontal blanc centré en haut, la porte et sa lumière, titre blanc, texte blanc, champs et
boutons posés sur la page, un seul bouton plein par écran, aucune carte. Ordinateur : deux volets
dès 840 points, image au début de ligne, formulaire sur parchemin (`surfaceQuran`).

**A. Démarrage (une fois par lancement, 1,5 s au plus).** Fond violet. L'illustration s'anime :
le symbole se dessine au centre, sa porte s'ouvre, la lumière sort et s'étire au sol comme une
route, les pas et la lanterne apparaissent. Le logo horizontal apparaît en haut, centré, par un
fondu net, sans déplacement. Puis le contenu de l'écran qui suit apparaît sous l'illustration, qui
reste en place. Qui a déjà une session voit une version courte et arrive chez lui. Mouvement
réduit : fondus seuls, même durée, image finale identique. Si la session met plus de 1,5 s à se
lire, l'image finale reste, sans roue ; le message « c'est long » existant arrive à 8 s.

**B. Première visite : le questionnaire d'accueil de la famille, avant tout compte.** Les
questions du parcours d'aujourd'hui (`/tuteur/parcours`), remontées avant la connexion et réduites
à moins de dix étapes, une par écran, « étape x sur n » : pour qui (moi, mon enfant), âge, langue,
pays et fuseau (sélecteur avec recherche et détection de l'appareil, déjà faits pour les
enseignants), niveau, objectif, moments de la journée, puis les offres publiées en cartes ou la
demande de créneau personnalisé (roulette jour et heures). Puces pour les choix courts, cartes avec
exemple pour le niveau et l'objectif. Les réponses sont gardées sur l'appareil (stockage local de
préférences existant) et rattachées au compte à l'étape E. Qui revient sur l'appareil ne répond pas
deux fois. Les codes d'invitation (enseignant, comptable) et « J'ai déjà un compte » sautent le
questionnaire et vont droit à C.

**C. Connexion.** Logo centré, la porte, « Se connecter » ou « Créer votre compte », l'intro, le
choix « J'ai déjà un compte / Créer un compte », le champ adresse, le bouton plein blanc « Recevoir
le lien », « Continuer avec Google » à contour, puis les liens : appareil d'un élève, lien expiré,
mentions. À l'arrivée, l'illustration joue une fois (ou vient de l'écran A sans coupure), puis reste
immobile ; le logo ne bouge pas. Textes et comportements inchangés.

**D. Lien envoyé, récupération d'accès, appareil de l'élève (choix du profil, code, scanner).**
Même habillage, mêmes textes, mêmes gestes qu'aujourd'hui. L'écran de l'élève garde sa grande cible
tactile et son clavier de code.

**E. Après le lien : récapitulatif, puis l'accueil, sans attente.** Un seul écran : « Voici ce que
nous avons compris », prénom et nom du tuteur, genre, l'enfant et ses réponses, « Créer mon
compte ». La demande part à l'académie, la famille arrive sur son Accueil et voit sa demande en
suivi : **aucune attente de validation pour une famille** (décision 2). Si l'appareil n'a pas de
réponses (lien ouvert ailleurs), le questionnaire se pose ici. Vérité à dire : l'absence d'attente
pour une famille est une règle du serveur (statut du compte à la création) : ce lot comprend donc
une migration, collée par le directeur depuis une page privée, et ses tests SQL.

**F. Accords et portail d'attente.** Même habillage ; une page qui défile, chaque texte sa case, un
bouton « Suivant » inactif tant que tout n'est pas coché (décision du 17/10). Aucun autre
changement dans le portail.

## 4. Livraison : une branche, des PR dans l'ordre, chacune prouvée par le directeur

| # | PR | Contenu | Preuve du directeur |
|---|---|---|---|
| 1 | Fondations et connexion | surface de marque, fond de page, porte complète, connexion C, lien envoyé et récupération D, guide du logo | téléphone et ordinateur, français et arabe : la page ressemble à la capture ; le lien arrive |
| 2 | Démarrage animé | écran A, raccord avec C | ouvrir l'app froide : l'illustration joue, le logo apparaît, pas de coupure |
| 3 | Questionnaire d'accueil avant le compte | B et E, stockage local, rattachement, règle serveur « famille sans attente », créneau personnalisé | parcours complet d'une nouvelle famille, sur téléphone puis ordinateur : moins de dix étapes, compte en dernier, demande visible dans son Accueil |
| 4 | Habillage de l'appareil de l'élève et des accords | D (élève), F | un élève entre par son code ; un enseignant signe ses accords |

Les PR 1 et 2 passent avant l'invitation des enseignants et des élèves actuels (B2.1, B2.2) : ce
sont les premiers écrans qu'ils verront. Les PR 3 et 4 ne les concernent pas et viennent après.

## 5. Règles de preuve, pour chaque PR

Textes : aucune clé nouvelle sans décision (vocabulaire `mots-rewayah`). Marque : logo par
`BrandLogo` seul, blanc sur violet, jamais sur dégradé ; porte par `PorteLumiere` complétée.
Mouvement : durées nouvelles ajoutées à `AppMouvement` par cette décision datée du directeur ;
jamais de boucle sans fin ; mouvement réduit respecté ; les tests montent les écrans sans attendre
une animation infinie. Rendu testé à 320 et 1440, texte ×1 et ×2, français et arabe ; un seul
bouton plein ; aucun chevauchement ; contraste mesuré. `UX_REVIEW_ENTREE.md` par PR.

## 6. Deux réponses attendues du directeur

| # | Question | Proposition du pilote |
|---|---|---|
| Q1 | L'ordre des quatre PR du §4 vous convient ? | oui : connexion d'abord, puis démarrage, puis questionnaire et compte en dernier, puis élève et accords |
| Q2 | L'animation de démarrage joue à chaque lancement (1,5 s), ou seulement quand il n'y a pas de session ? | à chaque lancement, raccourcie en fondu quand on est déjà connecté |
