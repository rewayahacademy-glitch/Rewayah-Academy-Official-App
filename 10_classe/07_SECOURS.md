# Classe et visio : écrans de secours (lot CL-7)

Date : 26/09/2026. Rédigé par un agent de cadrage du poste B. Aucune maquette du directeur : feu vert pour composer avec les gabarits et composants existants. Preuve UX : `UX_REVIEW_CL-7.md`.
Sources : spec `02_CLASSE_ET_VISIO.md` (S, lignes) P05 l.220, P06 l.231, P09 l.259, P10 l.268, P11 l.275, P12 l.283, CLV-04 états l.637-675, CLV-05 l.739-785, CLV-06 l.846-895, CLV-09 l.1087-1101, §6.4 l.1215 ; matrice `V/01_MATRICE_ROLES.md` ; plan `03_PLAN_CODE.md` ; code `C:\RA\classe` @ `262b4b2` (`ui/classe-v1`).
Règles gelées : `DESIGN-GOV-2026-09-26` (contrats A à E appliqués à ce **nouveau** lot seulement ; rien de fait n'est rouvert). Thème chrome / violet (K-37). K-28 : aucun branchement serveur.

Rôles : **ES** élève standard (CLV-04), **IG** Interface guidée (CLV-05), **EN** enseignant (CLV-06/10).
Marque **PROPOSITION** = texte absent de la spec, proposé ici, à valider par le directeur.

## 1. Ce qui existe déjà (point de départ, aucun fork)

| Besoin | Existant dans le code | Constat |
|---|---|---|
| État de connexion | `ConnexionSeance { enLigne, reconnexion }` (`vue_seance.dart` l.60), pastille `_Connexion` de `ChromeSeance` (« En ligne » / « Reconnexion ») ; adaptateurs `depuis_salle.dart` l.79 et `depuis_classe_live.dart` l.67 | Pas de réseau faible, rétablie, échec, hors ligne. **Aucun `BandeauConnexion`** : prévu par DV D9, jamais créé. |
| Bandeau réseau | `OfflineBanner` (`lib/core/widgets/offline_banner.dart`) | Texte figé `reseau.horsLigne` et lié à `horsLigneProvider` : inutilisable tel quel en salle. → extension additive (T-S2), pas de copie. |
| Retour bref | `LocalFeedback` | Couvre « Connexion rétablie. ». |
| Erreur récupérable dans la page | `EtatSysteme(portee: bloc)` avec `NatureEtat.reconnexion`, `horsLigne`, `permissionRefusee` ; action + lien secondaire | Couvre « Reconnexion impossible » et « hors ligne confirmé ». |
| Feuille / dialogue | `AppBottomSheet.ouvrir` (feuille < 600, dialogue au-delà) | Couvre la feuille « micro bloqué ». |
| Caméra interdite | `cameraAutorisee` → `commandesDock` sans Caméra (ES, IG) | Fait ; manque le statut non interactif ES (P10.3). |
| Prolongation | `HorlogeDepassee` → « La séance se poursuit. » dans `ligneEtat` (ES, EN) ; rien en IG | Fait. |
| Fin | `ResultatSeance` (`IssueSeance.terminee/quittee`), `FinSeanceEnseignant` | Fait ; manque l'issue « accès retiré ». |
| Impasse d'entrée micro | `/salle` : `CauseImpasse.materiel` (avant l'entrée) | Hors CL-7 (P09 = en salle) ; non rouvert. |
| Statut | `StatusPill` | Couvre le statut caméra. |

Clés i18n existantes réutilisables : `salle.seance.reconnexion`, `salle.seance.sePoursuit`, `salle.seance.quitterQuestion` + `rester`, `salle.seance.sortir` (« Quitter la séance »), `salle.fin.*`, `commun.etats.*` (textes par défaut d'`EtatSysteme`, remplacés ici par ceux de la spec).

## 2. États par rôle

Colonnes communes : déclencheur (tout vient du moteur ou du serveur ; l'UI ne détecte rien elle-même) → forme → textes → actions → focus → composant → 390 / 768 / 1440.
Formes : **B** = bandeau non bloquant (`OfflineBanner` étendu, `liveRegion`) ; **F** = retour bref (`LocalFeedback`) ; **E** = bloc d'erreur dans la salle (`EtatSysteme` bloc) ; **S** = feuille/dialogue (`AppBottomSheet`) ; **R** = écran de résultat ; **T** = texte d'état ; **P** = `StatusPill` statique.

### 2.1 P05 Reconnexion

| État | Rôle | Déclencheur | Forme | Texte exact | Actions | Focus |
|---|---|---|---|---|---|---|
| Reconnexion en cours | ES | `ConnexionSeance.reconnexion` | B avertissement + pastille « Reconnexion » (existante) ; support conservé ; Micro/Caméra désactivés | `Connexion interrompue. Reconnexion en cours…` (S l.620) | aucune | inchangé ; annonce par région vivante |
| | IG | idem | B | `Reconnexion de la séance…` (S l.773) | aucune | idem |
| | EN | idem | B ; support à la dernière révision ; outils temps réel, pagination active et Supports désactivés | `Connexion interrompue. Reconnexion en cours…` (S l.858) | aucune | idem |
| Libellé d'accessibilité d'un bouton désactivé | ES, IG, EN | idem | — | `{Micro}. Indisponible pendant la reconnexion.` **PROPOSITION** | — | — |
| Rétablie | ES, EN | `retablie` (transitoire) | F sous l'en-tête, puis disparition seule | `Connexion rétablie.` (S l.621, 859) | aucune | inchangé |
| | IG | idem | F | `Connexion rétablie.` **PROPOSITION** (texte adulte repris, 2 mots, CLV-05 n'en donne pas) | aucune | inchangé |
| Reconnexion impossible | ES | `echec` | E à la place du bandeau ; salle conservée | titre `Impossible de rétablir la connexion.` (S l.653) | leading `Quitter la séance` → confirmation existante `Quitter la séance ?` ; trailing `Réessayer` | focus conservé ; bloc annoncé (région vivante) |
| | IG | idem | E, cibles 72 dp | `La connexion ne revient pas.` (S l.775) | `Quitter` (leading), `Réessayer` (trailing) (S l.775) | idem |
| | EN | idem | E | `Impossible de rétablir la connexion.` **PROPOSITION** (texte ES repris, CLV-06 n'en donne pas) | `Quitter la séance` → confirmation cahier existante (`Quitter et ouvrir le cahier`) ; `Réessayer` | idem |
| Hors ligne confirmé | ES, EN | `horsLigne` (appareil sans réseau confirmé par le moteur) | E | `Vous êtes hors ligne. La séance nécessite une connexion.` (S l.655) | `Réessayer` seul (S l.655) | idem |
| | IG | idem | E | `La connexion ne revient pas.` (même état que l'échec : CLV-05 n'a pas d'autre texte) | `Quitter`, `Réessayer` | idem |

Règles : aucune nouvelle absence ni présence affichée (P05.7) ; pas de reconnexion en boucle visible ; la durée avant « impossible » est décidée par le moteur (BR-1), aucune minuterie locale. `Réessayer` affiche `actionEnCours` (indicateur local dans le bouton, §4 bis.6 point 5).

### 2.2 P06 Réseau faible

| Rôle | Déclencheur | Forme | Texte exact | Actions |
|---|---|---|---|---|
| ES | `reseauFaible` (room connectée) | B avertissement ; pastille « En ligne » inchangée ; commandes actives | `Réseau faible. L'audio est prioritaire.` (S l.619) | aucune |
| IG | idem | B : titre + sous-texte | `Le réseau est faible.` / `Le son reste prioritaire.` (S l.771) | aucune |
| EN | idem | B ; le bouton `Réseau` du dock reste tel quel (son contenu = BR-1) | `Réseau faible. L'audio est prioritaire.` (S l.857) | aucune |

Jamais « hors ligne » tant que la room est connectée (P06.5). Si la vidéo de l'enseignant est suspendue par le SDK, la vignette prend son rendu « sans vidéo » existant, sans texte ajouté (aucune phrase de la spec ne couvre ce cas).

### 2.3 P09 Micro bloqué

| Rôle | Déclencheur | Forme | Textes exacts | Actions | Focus |
|---|---|---|---|---|---|
| ES | geste `Micro` + permission OS refusée (signal du moteur) | S « feuille média » (S l.659) | corps `Le micro est bloqué dans les réglages de cet appareil.` (S l.633) ; titre de feuille `Micro` (libellé existant) | leading secondaire `Continuer sans micro` (S l.265) ; trailing principal `Ouvrir les réglages` (S l.264) **seulement si `onOuvrirReglages` ≠ null** | titre de la feuille à l'ouverture ; à la fermeture, retour au bouton Micro |
| IG | idem | S, cibles 72 dp | `Le micro est bloqué sur cet appareil.` (S l.758) | `Continuer sans micro` **PROPOSITION** pour IG (3 mots, P09.5 ne distingue pas les rôles) ; `Ouvrir les réglages` (S l.759) si possible | idem |
| EN | idem | S | `Le micro est bloqué dans les réglages de cet appareil.` | idem ES | idem |

Le micro reste affiché « coupé » ; aucun état « actif » n'est envoyé ni montré (P09.6). Ouvrir les réglages système : **BR-1** (aucun paquet de permission, pubspec interdit) → rappel `null`, bouton non rendu.

### 2.4 P10 Caméra interdite

| Rôle | Déclencheur | Forme | Texte | Actions |
|---|---|---|---|---|
| ES | `cameraAutorisee == false` (claim `can_publish_video`) | pas de bouton Caméra (fait) ; P statique ton neutre | `Caméra désactivée pour ce profil.` (S l.634) | aucune (non interactive, pas de hover/focus ; lue dans l'ordre du dock) |
| IG | idem | aucun bouton, **aucune explication** (S l.779, matrice) | — | — |
| EN | sans objet : la matrice donne toujours la caméra à l'enseignant | — | — | — |

**Q-S1 (directeur)** : la spec place ce statut « dans les détails média », que les maquettes ne montrent pas. Option retenue par défaut : P dans la barre basse, à la place du bouton (768, 1440) ou juste au-dessus du dock, alignée start, écart 8 (390). Autre option : aucun texte visible, seulement le libellé d'accessibilité. Constante nommée `optionQS1` dans `vue_seance.dart`, comme Q1-Q8.

### 2.5 P11 Séance prolongée

| Rôle | Forme | Texte |
|---|---|---|
| ES | T dans la ligne d'état (fait) | `La séance se poursuit.` |
| IG | rien (matrice l.15, l.71) | — |
| EN | T à la place de `{n} min restantes` (fait) | `La séance se poursuit.` |

Minuteur jamais négatif : `HorlogeRestante(minutes)` n'accepte pas de négatif (assertion + test). Aucun bouton « Prolonger » (matrice l.51).

### 2.6 P12 Salle terminée ou accès retiré

| État | Rôle | Forme | Textes exacts | Action | Focus |
|---|---|---|---|---|---|
| Terminée | ES | R `ResultatSeance(terminee)` (fait) | `Séance terminée` / `Vous pouvez retrouver votre travail dans votre Classe.` | `Retour à la Classe` | titre |
| | IG | R (fait) | `La séance est terminée.` | `Retour à l'accueil` | titre |
| | EN | R `FinSeanceEnseignant` (fait) | CLV-10 | `Ouvrir le cahier` | titre |
| Accès retiré | ES | R `ResultatSeance(accesRetire)` **nouvelle issue** | titre `Votre accès à cette séance a pris fin.` (S l.673, §6.3) ; aucune phrase | `Retour à la Classe` | titre |
| | IG | R guidée existante (un seul écran de fin en IG) | `La séance est terminée.` | `Retour à l'accueil` | titre |
| | EN | R `FinSeanceEnseignant` (P12.4 : CLV-10 avec le cahier) | CLV-10 | `Ouvrir le cahier` | titre |

Contrôles média arrêtés avant l'affichage ; aucune tentative de reconnexion (P12.5) ; aucune mention d'enregistrement ; jamais « Présent » ni « Absent ».

### 2.7 Disposition 390 / 768 / 1440 (commune)

| Élément | 390 x 844 | 768 | 1440 |
|---|---|---|---|
| Bandeau B | sous `ChromeSeance`, pleine largeur de la colonne salle, gouttière 16 ; plusieurs lignes permises | idem, gouttière du gabarit | sous l'en-tête, au-dessus du support seulement (pas sous le rail enseignant), gouttière 32 |
| Retour F | sous le bandeau / l'en-tête, 3 s (`LocalFeedback`) | idem | idem |
| Bloc E | entre en-tête et support ; le support rétrécit, ne disparaît pas ; actions 16 dp sous le texte, trailing | idem | largeur bornée par `EtatSysteme`, aligné start du support |
| Feuille S | feuille du bas | dialogue centré (`AppBottomSheet`, ≥ 600) | dialogue centré |
| Pastille P | au-dessus du dock, start, 8 | dans la barre basse à la place de Caméra | idem |
| Résultat R | existant | existant | existant |

Mouvement : `AppMouvement.apparition` (180 ms) pour B et E, `easeOutCubic` / `easeInCubic`, 0 en réduction de mouvement. Mode agrandi (focus) : B et E restent visibles (état critique), F aussi.

### 2.8 Ce qui relève du serveur ou du SDK (BR-1, non codé)

| Élément | Ligne |
|---|---|
| Détection réelle : perte, qualité, échec durable, hors ligne (LiveKit + `connectivity`) → `ConnexionSeance` | BR-1 |
| Nouveau jeton, rejeu de `SharedContentState`, reconstruction de la présence | BR-1 |
| Suspension/réduction vidéo en réseau faible | BR-1 (SDK) |
| Permission OS micro : détection du refus, ouverture des réglages (`onOuvrirReglages`) | BR-1 |
| `can_publish_video` et refus serveur d'une publication externe | BR-1 |
| Clôture, révocation, prolongation : états serveur → `fin`, `IssueSeance.accesRetire`, `HorlogeDepassee` | BR-1 |
| Contenu du bouton `Réseau` enseignant | BR-1 |

Les adaptateurs `depuis_salle.dart` et `depuis_classe_live.dart` reçoivent seulement la correspondance des états **déjà connus** (`PhaseSalle.instable` → `reseauFaible`, `retabli` → `retablie`, `reconnexion` → `reconnexion`) ; rien de neuf n'est inventé côté moteur.

## 3. Plan de code (tâches < 35 min, séquentielles)

Consignes communes : `03_PLAN_CODE.md` §6 (verrou flutter, interdits, slang fr + ar, `verifier_jetons`, clair + sombre, commit en français avec attribution, push `origin ui/classe-v1` ; rapport `05_recette/CL/T-Sn.md` et captures `10_classe/captures/T-Sn/` dans `C:\RA\pilotage`). Lire ce fichier §1-§2 et `UX_REVIEW_CL-7.md`. Aucun fichier de `lib/core/theme/` modifié.

| Tâche | État |
|---|---|
| T-S1 à T-S6 | à faire |

### T-S1 - Modèle, textes, démo (≈ 30 min)

Fichiers : `vue_seance.dart`, `actions_seance.dart`, `resultat_seance.dart` (énumération seulement), `seance_demo.dart`, `assets/i18n/fr.i18n.json` + `ar.i18n.json`, `test/features/salle_seance/vue_seance_test.dart`.
1. `ConnexionSeance { enLigne, reseauFaible, reconnexion, retablie, echec, horsLigne }` ; getters purs : `texteBandeau` (par rôle, textes §2.1-2.2 ; `null` si aucun), `sousTexteBandeau` (IG réseau faible), `voitBlocEchec`, `titreEchec`, `commandesPublicationActives` (faux en `reconnexion`, `echec`, `horsLigne`), `texteCameraInterdite` (ES seulement, si `!cameraAutorisee` et `optionQS1`), constante `optionQS1 = true`. `texteConnexion` : `reseauFaible` et `retablie` → « En ligne ».
2. `HorlogeRestante` : `assert(minutes >= 0)` et adaptateurs bornés à 0.
3. `IssueSeance.accesRetire` + textes.
4. `ActionsSeance` : `onReessayerConnexion`, `onContinuerSansMicro`, `onOuvrirReglages` (null = non rendu).
5. Clés slang `salle.secours.*` (textes §2) ; `dart run slang`.
6. `EtatDemoSalle` + : `reseauFaible`, `reconnexion`, `retablie`, `echec`, `horsLigne`, `microBloque`, `cameraInterdite`, `prolongee`, `accesRetire`.
Tests : un test pur par ligne des tableaux §2 (texte par rôle, IG sans caméra ni explication, EN sans statut caméra, minutes jamais négatives, aucun texte « hors ligne » en `reseauFaible`). Captures : aucune.

### T-S2 - Bandeau et retour bref (≈ 30 min)

Fichiers : `lib/core/widgets/offline_banner.dart` (ajout **additif** d'un constructeur `OfflineBanner.message({required String message, String? sousTexte})` qui ne lit pas le fournisseur ; `const OfflineBanner()` inchangé), `salle_seance.dart`, `dock_seance.dart` (état désactivé de `BoutonAppel` : même composant, paramètre `actif`), tests `salle_seance_widget_test.dart`, `test/core/widgets/offline_banner_test.dart`.
Insertion sous `ChromeSeance` (et en mode agrandi) ; `LocalFeedback` pour `retablie` ; `Semantics(liveRegion: true)`.
Tests : bandeau présent/absent par rôle et par état, texte exact ; en `reconnexion`, **taper Micro et Caméra n'appelle pas** `onMicro`/`onCamera`, taper Quitter l'appelle ; `const OfflineBanner()` garde son texte ; pas de débordement à 390, 768, 1440 (zoom 2,0 à 390).
Captures : `cl7_{04,05,06}_{reseau_faible,reconnexion,retablie}_{390x844@3,768x1024@1,1440x900@1}_{light,dark}`.

### T-S3 - Reconnexion impossible et hors ligne (≈ 30 min)

Fichiers : `salle_seance.dart`, tests `salle_secours_test.dart` (nouveau).
`EtatSysteme(portee: bloc, nature: reconnexion | horsLigne, titre: …, phrase: '', libelleAction: Réessayer, onAction: onReessayerConnexion, libelleSecondaire: Quitter la séance / Quitter, onSecondaire: onQuitter)` ; vérifier l'ordre leading/trailing et l'écart 16 du composant (sinon consigner l'écart pour HU-1, ne pas forker).
Tests : taper `Réessayer` appelle `onReessayerConnexion` ; taper `Quitter la séance` ouvre la confirmation existante (ES : `Quitter la séance ?` / `Rester` ; EN : `Quitter et ouvrir le cahier`) ; hors ligne ES/EN sans lien Quitter ; le support reste monté (clé `zone-support` trouvée).
Captures : `cl7_{04,05,06}_{echec,hors_ligne}_{390x844@3,768x1024@1,1440x900@1}_{light,dark}`.

### T-S4 - Micro bloqué (≈ 25 min)

Fichiers : `salle_seance.dart` (ouverture de la feuille par un rappel `onMicroBloque` de la démo / du moteur), `feuille_micro_bloque.dart` (contenu seulement, dans `AppBottomSheet.ouvrir`), tests.
Tests : ouverture → texte exact par rôle ; `Ouvrir les réglages` absent si `onOuvrirReglages == null`, présent et appelé sinon ; taper `Continuer sans micro` ferme la feuille, appelle `onContinuerSansMicro` et **rend le focus au bouton Micro** ; le bouton Micro reste « Micro coupé ».
Captures : `cl7_{04,05,06}_micro_bloque_{390x844@3,768x1024@1,1440x900@1}_{light,dark}` (avec et sans « Ouvrir les réglages » à 390).

### T-S5 - Caméra interdite, prolongée, accès retiré (≈ 25 min)

Fichiers : `salle_seance.dart` / `dock_seance.dart` (`StatusPill` statique selon `texteCameraInterdite`), `resultat_seance.dart` (issue `accesRetire`), `demo_salle_page.dart`, tests.
Tests : ES caméra interdite → pas de `bouton-camera`, pastille présente et **non tappable** (aucun `Pressable`) ; IG → ni bouton ni texte ; prolongée ES/EN texte, IG rien ; accès retiré ES → titre exact, taper `Retour à la Classe` appelle `onRetour`, focus initial sur le titre ; EN → `FinSeanceEnseignant`, taper `Ouvrir le cahier`.
Captures : `cl7_04_camera_interdite_*`, `cl7_{04,06}_prolongee_*`, `cl7_{09,05,10}_acces_retire_*` aux trois tailles, deux thèmes.

### T-S6 - Page démo et recette (≈ 30 min)

Fichiers : `demo_salle_page.dart` (les 9 nouvelles situations dans la liste rôle × état, libellés `salle.seance.demo.etats.*`, paramètre `?etat=` ; situations sans objet pour un rôle non listées : `cameraInterdite` pour EN), `test/features/demo/demo_salle_page_test.dart` (taper chaque lien ouvre la bonne salle), `05_recette/CL/CL-7_RAPPORT.md`.
Recette : relire toutes les captures avec Read, cocher chaque ligne de `UX_REVIEW_CL-7.md`, relire en ligne M3 (bannière, snackbar) et Apple HIG Privacy puis mettre à jour la colonne « Consultation », consigner les écarts pour HU-1, mettre à jour `03_PLAN_CODE.md` §7 et `00_REPRISE.md` (CL-7 fait).

## 4. Questions pour le directeur (non bloquantes, option par défaut appliquée)

- **Q-S1** : statut « Caméra désactivée pour ce profil. » visible dans la barre basse (défaut) ou seulement pour le lecteur d'écran ?
- **Q-S2** : textes PROPOSITION : « Connexion rétablie. » en IG, « Continuer sans micro » en IG, « Impossible de rétablir la connexion. » côté enseignant, libellé d'accessibilité « Indisponible pendant la reconnexion. ».
