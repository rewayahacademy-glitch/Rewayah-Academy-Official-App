# Revue croisée C1-CTRL-R : messages, données par séance, délais et retour système du contrôleur

- **Objet revu** : `origin/corrections/c1-ctrl` @ `90bd9eea` (base `af20f6c2`, branche commune). 4 commits : CTRL-MSG-1 `02a36bdf`, CTRL-SEANCE-1 `04acce70`, CTRL-DELAI-1 `887e12ab`, CTRL-RETOUR-1 `90bd9eea`. 52 fichiers (+1265 −57), dont 30 captures.
- **Relecteur** : session cloud `01KyPAZg`. Elle n'a pas écrit ces étapes (auteur : `268bd1ef`).
- **Date** : 4 octobre 2026.
- **Références** : `14_controleur/CT-BR.md` (BR-CT-10, BR-CT-14 mis à jour au pilotage `c52817da`), `05_recette/CT/REVUE_CT-R.md` (K-59), `verifications/2026-10-03/VERIF-CT-1/RAPPORT.md`, `lib/CLAUDE.md`, Bible V2.
- **Méthode** :
  - lecture du diff complet (code, i18n, tests, captures) ;
  - contrôles relancés dans le worktree détaché `/home/user/rv-c1-ctrl` (aucune suite complète) ;
  - trois mutations ciblées, remises en place par `git checkout --` ; `git status` propre à la fin ;
  - six captures ouvertes ;
  - fusion à blanc avec `origin/corrections/revue-directeur-2026-10`.

## Verdict

**Refusée**, pour deux défauts majeurs : M1 (premier relecteur, confirmé) et M2 (trouvé à la contre-vérification, débordement à 320 px et texte ×2). Voir la section « Contre-vérification » en fin de rapport.

Le cœur du lot est bon. Le relevé et le roster sont lus par séance, et la mutation le prouve. Le retour système recule d'une étape et garde le texte, et la mutation le prouve aussi. Un serveur muet donne un échec honnête au lieu d'un indicateur qui tourne sans fin. Les tests sur horloge factice le montrent pour le compte rendu et l'observation.

Mais l'écran « séance inconnue », que CTRL-MSG-1 réécrit, reste une impasse. Il n'a aucun bouton, aucune coquille, aucune barre. Et le nouveau texte dit « écrivez à l'administration » sans donner le moyen de le faire. La capture de l'auteur le montre.

## Contrôles relancés (chiffres mesurés)

| Contrôle | Résultat |
| :--- | :--- |
| `dart run slang`, `build_runner build` | OK (code 0) |
| `dart analyze --fatal-infos` | **0 problème** |
| `dart run tool/verifier_jetons.dart \| grep -c "\["` | **39**, le chiffre attendu |
| `flutter test test/features/controleur` | **189 réussis, 0 échec** (le chiffre de l'auteur) |
| `demo_controleur_page_test`, `rtl_echelle_texte_ecrans_test`, `clavier_test`, `test/i18n`, `test/tool`, `q04_capacites_admin_controleur_test`, les 3 tests de capture CTRL | **105 réussis, 0 échec, 30 sautés** (captures sautées sans le drapeau) |
| Mutation 1 : le retour système ferme le Complément (`widget.onRetour()` au lieu de `_retourSysteme()`) | **2 échecs** : « retour systeme aux etapes 2 et 3 : une etape, texte garde » et « retour systeme apres l envoi : le detail a jour » |
| Mutation 2 : l'observation lit le roster de `'seance-B'` au lieu de sa séance | **1 échec** : « l observation de A propose les prenoms de A, jamais ceux de B » |
| Mutation 3 : retrait du délai sur le Complément et sur les Échanges | **189 réussis, 0 échec** : ces deux délais ne sont pas testés (voir m2) |
| Fusion à blanc `git merge-tree --write-tree origin/corrections/revue-directeur-2026-10 HEAD` | **1 conflit** : `tool/libelles_sources.json` (ajouts en fin de fichier des deux côtés : 5 clés DASH contre 3 clés CTRL). `fr.i18n.json` et `strings_fr.g.dart` fusionnent seuls ; régénérer `strings*.g.dart` après fusion |
| Fichiers interdits (`supabase/`, `.github/`, `vercel.json`, `pubspec.yaml`) | Aucun |
| `git status` après mutations | Propre |

## Points de la fiche, un par un

| Point demandé | Constat |
| :--- | :--- |
| **K-59, « non confirmé »** (cause, suite, ce qui reste fiable) | ✅ pour les échecs d'envoi. `observation.echecSansTexte` (`fr.i18n.json:3540`) ne parle plus d'un texte gardé, choisi par `_Souscription(sansTexte:)` (`observation_controle_page.dart:381, 625`). Test « Sans serveur ni texte » vert. Les envois qui dépassent le délai disent « n'est pas confirmé » (capture `ctrl_delai1_*`). ❌ pour l'écran « séance inconnue » : voir M1. Le texte d'aide se contredit aussi un peu : « La visite reste transmise… ; ce point n'est pas confirmé » (m1) |
| **Données par séance, aucun prénom d'une autre Classe** | ✅ `faitsVisiteProvider` et `rosterControleProvider` deviennent `FutureProvider.family(seanceId)` (`compte_rendu_controle.dart:71`, `observation_controle.dart:117`). La page lit `faitsVisiteProvider(widget.seanceId)` et `rosterControleProvider(_visite!.seanceId)`, y compris pour « Réessayer » (`invalidate(_roster)`). Les ports neutres rendent `null` et une liste vide. La démo ne répond que pour sa séance (`demo_controleur_page.dart:113-118, 155-158`). 3 tests dans `seance_controleur_test.dart`, mutation 2 prise. Capture `ctrl_seance1_roster_a_320x2_sombre` : « Amina », « Youssef » seulement |
| **Retour système qui recule d'une étape** | ✅ `PopScope(canPop: false)` dans `complement_rapport_page.dart:183` : il recule d'une étape et garde le texte, ferme le Complément à l'étape 1, rend le détail à jour après l'envoi, et ne fait rien pendant l'envoi. L'Historique ne ferme plus que le détail (`historique_controleur_page.dart:177-183`). Les deux PopScope ne se marchent pas dessus : l'externe sort si `_enComplement`. Tests par `handlePopRoute` (étapes 3, 2, 1, et après l'envoi). Mutation 1 prise |
| **Délais avec horloge factice** | ✅ en partie. `.timeout(AppDelais.requeteMax)` (20 s) est posé sur les 5 appels : envoi du compte rendu, transmission de la visite, observation, complément, message des Échanges. Les 2 tests de `delai_controleur_test.dart` utilisent un port qui ne répond jamais et `tester.pump(AppDelais.requeteMax)`. Ils couvrent le compte rendu, la transmission (« visiteEchec » et Réessayer) et l'observation. Le Complément et les Échanges ne sont pas couverts : mutation 3 non prise (m2) |
| **CT-BR.md BR-CT-14 mis à jour** (pilotage `c52817da`) | ✅ La ligne CTRL-SEANCE-1 (`CT-BR.md:30`) dit : séance dans l'adresse, lecture par séance, auteur du complément fixé par le serveur, aucun serveur avant BR-1. Il manque l'idempotence des envois que le délai rend possibles en double (m3) |

## Règles du projet

| Règle | Constat |
| :--- | :--- |
| 5 états | Inchangés par le lot. L'état « séance inconnue » existe mais sans sortie (M1) |
| 320 px, texte ×2 | `rtl_echelle_texte_ecrans_test` vert. Les captures « 320x2 » sont à densité 2, pas à texte ×2 (m4) |
| Un seul bouton plein | ✅ « Envoyer le compte rendu » seul plein, « Plus tard » en contour (capture `ctrl_delai1_1440_sombre`) |
| Aucun texte en dur | ✅ 3 clés ajoutées à `fr.i18n.json`, chacune sourcée dans `tool/libelles_sources.json` |
| Rôle lu par un widget | ✅ Aucun |
| Port neutre en production, démo par surcharge | ✅ Ports neutres par séance ; démo par `overrideWith` sur la seule séance de démo |
| Composants partagés | Aucun composant partagé modifié. `EmptyState` et `FilDiscussion` sont seulement utilisés |

## Captures ouvertes

| Fichier | Ce qu'on voit |
| :--- | :--- |
| `CTRL-MSG-1/ctrl_msg1_inconnue_320x2_clair` | Titre « Compte rendu », icône de main, « Ce compte rendu ne peut plus être repris ici. » et l'aide sur 8 lignes. Aucun mot coupé. **Aucun bouton, aucune barre, aucun retour** : la moitié basse est vide |
| `CTRL-MSG-1/ctrl_msg1_inconnue_390_sombre` | Même écran, bien sombre. Même absence de sortie |
| `CTRL-SEANCE-1/ctrl_seance1_roster_a_320x2_sombre` | Étape 3 sur 5, « Choisissez l'élève dans la liste de la Classe. », deux cartes « Amina » et « Youssef ». « Continuer » en contour tant que rien n'est choisi |
| `CTRL-DELAI-1/ctrl_delai1_320x2_clair` | Après le délai : « Envoyer le compte rendu » et « Plus tard » de nouveau actifs, puis « L'envoi n'est pas confirmé… Votre choix reste sélectionné… ». Ce paragraphe est **aligné à droite** sur 5 lignes, difficile à lire à 320 (`compte_rendu_controle_page.dart:359`, `TextAlign.end`, antérieur au lot, m5) |
| `CTRL-DELAI-1/ctrl_delai1_1440_sombre` | En haut, « La transmission de la visite n'est pas confirmée… » et « Réessayer ». « Rien à signaler » choisi. En bas, « Plus tard », « Envoyer le compte rendu » et l'échec. Mise en page sombre correcte, colonne à gauche (déjà suivi en HU-1) |

## Défauts retenus

### MAJEUR

**M1. L'écran « séance inconnue » est une impasse, et son texte promet une action impossible.**

- Où : `compte_rendu_controle_page.dart:179-187` et `observation_controle_page.dart:283-293`. Les deux passent `libelleAction` et `onAction` à `EmptyState`, mais avec `registre: RegistreVide.subi`. Or `EmptyState` jette le bouton dans ce registre (`empty_state.dart:84-87`).
- Les routes `/controleur/compte-rendu` et `/controleur/observation` sont sans coquille (`app_router.dart:1126-1147`). Il n'y a donc ni barre, ni rail, ni retour à l'écran.
- Le nouveau texte dit « Pour ajouter une remarque, écrivez à l'administration. » sans lien vers les Échanges. K-59 demande la suite à donner : ici, elle n'est pas faisable depuis l'écran.
- Preuve : captures `ctrl_msg1_inconnue_*` (6 images, aucun bouton). Le registre `subi` date d'avant le lot, mais CTRL-MSG-1 réécrit précisément cet état.
- Étape proposée, **CTRL-MSG-2** : passer ces deux états en `RegistreVide.actionnable`, avec « Écrire à l'administration » (`Routes.controleurEcrireAdmin(null)` ou le fil général) en bouton, et « Revenir au contrôle » (`Routes.controleur`) en action secondaire. Ajouter un test qui touche le bouton et vérifie la route. Refaire les 6 captures.

### mineurs

- **m1. Aide qui se contredit.** « La visite reste transmise à l'administration avec son relevé automatique ; ce point n'est pas confirmé depuis cet écran » (`fr.i18n.json:3487`). On affirme puis on retire. Proposition : « Le serveur transmet la visite et son relevé automatique dès la sortie de la salle ; cet écran ne peut pas le confirmer. » À faire avec M1.
- **m2. Deux délais sans test.** Retirer le `.timeout` du Complément (`complement_rapport_page.dart:164-166`) et des Échanges (`echanges_controleur_page.dart:179-180`) laisse les 189 tests verts. Ajouter un test « serveur muet » pour chacun, sur le même modèle que `delai_controleur_test.dart`.
- **m3. Doublons possibles après un délai.** Un serveur lent qui répond après 20 s a quand même enregistré. Le « Réessayer » qui suit envoie alors une seconde observation, un second complément ou un second message. Seule `transmettreVisite` est dite idempotente (BR-CT-10). Ajouter dans `CT-BR.md` une ligne BR : une clé d'envoi produite par le client pour `envoyer`, `envoyerObservation`, `ajouterComplement` et le message des Échanges, que le serveur dédoublonne.
- **m4. « 320x2 » n'est pas « texte ×2 ».** Les captures de ces dossiers sont à densité 2 (`fixerVueCapture(tester, Size(320, 700), 2)`), donc à texte ×1. Le texte ×2 n'est vérifié que par `rtl_echelle_texte_ecrans_test`. Renommer en `320_dpr2`, ou ajouter une variante `textScaler: 2`.
- **m5 (antérieur au lot). Échec aligné à droite.** Le paragraphe d'échec du compte rendu est en `TextAlign.end` (`compte_rendu_controle_page.dart:359`) : 5 lignes à bord gauche irrégulier à 320. `TextAlign.start` suffit.
- **m6 (hors périmètre). Pas de retour système par étape dans l'Observation.** L'Observation (5 étapes, avec du texte) n'a pas de `PopScope` : le retour système sort de la page et la saisie est perdue. Même traitement que CTRL-RETOUR-1, à prévoir en CTRL-RETOUR-2.

## Pour accepter

1. Corriger M1 (avec m1) dans une étape CTRL-MSG-2, sur `corrections/c1-ctrl` : bouton visible et fonctionnel sur les deux écrans « séance inconnue », test de navigation, 6 captures refaites.
2. Recommandé dans la même passe : m2 (deux tests de délai) et m5 (une ligne).
3. Au pilotage : ligne BR pour m3.
4. À la fusion (CORR-2) : régler `tool/libelles_sources.json` en gardant les deux blocs (virgule entre eux), puis `dart run slang`.

## Contre-vérification (second relecteur, session 01KyPAZg, 4 octobre 2026)

Méthode : relecture sceptique du rapport ci-dessus, dans le même worktree `/home/user/rv-c1-ctrl` (HEAD `90bd9eea`). Deux mutations nouvelles, des captures temporaires à 320 px avec un vrai texte ×2 (`echelleTexte: 2`, densité 1) et en RTL, écrites dans le bloc-notes de la session. Les fichiers de test temporaires sont supprimés. Aucune suite complète. `git status` propre à la fin.

### M1 : confirmé, non réfuté

- `compte_rendu_controle_page.dart:179-187` et `observation_controle_page.dart:283-293` passent bien `libelleAction` et `onAction` avec `registre: RegistreVide.subi`.
- `EmptyState` (`lib/core/widgets/empty_state.dart:84-87`) n'affiche le bouton que si `registre == RegistreVide.actionnable`. Le bouton est donc jeté.
- `PageShell` est appelé sans `onRetour` : aucun disque de retour. Les routes sont sans coquille (`app_router.dart:1126-1147`). `GardeControle` rend l'enfant tel quel en accès actif.
- Après un rechargement ou un lien direct, il n'y a pas d'historique : le retour système ne mène nulle part. L'écran est une impasse.
- J'ai ouvert `ctrl_msg1_inconnue_320x2_sombre` : titre, icône, constat, aide sur 8 lignes, puis la moitié basse vide. Aucun bouton.
- Le test « Seance inconnue » (`compte_rendu_controleur_test.dart:585-607`) vérifie le texte, pas la sortie. Il vérifie même que l'aide contient « n'est pas confirmé », c'est-à-dire la phrase qui se contredit (m1).
- Le registre `subi` date d'avant le lot. Mais CTRL-MSG-1 réécrit précisément cet état et son texte promet une suite (« écrivez à l'administration ») que l'écran ne permet pas. K-59 (la suite à donner) n'est pas tenu. **Majeur maintenu.**

### Mineurs du premier relecteur

- **m1** confirmé. J'ajoute un point : « La visite reste transmise » affirme un fait que l'app ne peut pas savoir. La transmission part de `initState` de la page (`compte_rendu_controle_page.dart:113-118`), et un rechargement peut avoir coupé cet appel. La seule garantie est la création du rapport par le serveur à la sortie (CT-BR), qui n'existe pas avant BR-1. La reformulation proposée est la bonne.
- **m2** non rejoué (mutation du premier relecteur, crédible : aucun test de délai ne vise le Complément ni les Échanges).
- **m3** confirmé par lecture : seul `transmettreVisite` est protégé par l'état `enCours`/`transmise`.
- **m4** confirmé, et il pèse plus lourd que prévu. `hoteCapture` a déjà un paramètre `echelleTexte` (`test/capture/outil_capture.dart:134`), que les trois tests de capture du lot n'utilisent pas. `rtl_echelle_texte_ecrans_test` ne monte ni le compte rendu, ni l'Observation, ni le Complément : aucun test ne mesure ces écrans à texte ×2. C'est ce qui cache M2.
- **m5** confirmé sur ma capture `ctrl_delai1_320x2_sombre` à texte ×2 : 11 lignes alignées à droite, bord gauche irrégulier.
- **m6** confirmé : aucun `PopScope` dans `observation_controle_page.dart`.

### Ce que le premier relecteur a raté

**M2 (nouveau, MAJEUR). L'échec d'envoi de l'Observation déborde à 320 px et texte ×2 : le bouton est coupé.**

- Mesure : capture `ctrl_msg1_echec_sans_texte` rejouée avec `Size(320, 700)`, densité 1, `echelleTexte: 2`. Les 4 variantes (clair, sombre, LTR, RTL) lèvent « A RenderFlex overflowed by 60 pixels on the bottom ». Widget en cause : la `Column` de `lib/core/widgets/page_shell.dart:208`.
- Ce qu'on voit : la zone d'actions fixe occupe tout l'écran. Plus de titre, plus de récapitulatif. L'aide « Ce compte rendu est transmis… », puis l'échec `echecSansTexte` sur 11 lignes, puis « Envoyer le compte rendu » coupé sous les bandes jaunes et noires du débordement. Le contrôleur ne peut ni relire ni réessayer.
- Cause : `PageParcours` met la `souscription` (aide et échec) dans `actions:` (`page_parcours.dart:113-117`), zone fixe qui ne défile pas. Un paragraphe d'échec long ne tient pas.
- Antériorité : la souscription date de CT-5 (`13353249f`, 27/09). Mais CTRL-MSG-1 crée la clé `echecSansTexte` et livre six captures de cet état dites « 320x2 », prises à densité 2 et texte ×1, qui ne montrent pas le défaut. La règle « 320 px et texte ×2 sans débordement » est cassée sur l'état que le lot réécrit.
- Risque voisin : le Complément (`complement_rapport_page.dart`) utilise aussi `souscription:` ; son échec est à mesurer de la même façon.
- Contrôle : à texte ×2, `ctrl_delai1` (compte rendu), `ctrl_seance1_faits_a` et `ctrl_seance1_roster_a` ne débordent pas (16 captures sans erreur).
- Étape proposée, **CTRL-X2-1** : sortir l'échec de la zone fixe (le placer en tête du corps défilant, ou rendre la zone d'actions défilante au-delà d'une hauteur maximale) ; un test widget à `Size(320, 700)` et `TextScaler.linear(2)` sur l'échec de l'Observation et du Complément, qui échoue sur le code actuel ; captures refaites avec `echelleTexte: 2`.

### Autres vérifications, sans défaut

- **RTL à 320 px, texte ×2** (captures temporaires `*_320rtl_*`) : le roster se retourne bien (radio à droite, nom à gauche), la page « séance inconnue » est centrée. Le point qui passe en tête (« .ici », « .Classe ») vient du texte français rendu en RTL, pas d'un défaut de l'écran.
- **Mutation 4** : `sansTexte: false` forcé (`observation_controle_page.dart:381`). **1 échec** : « Sans serveur ni texte : l echec ne parle pas d un texte garde ».
- **Mutation 5** : `sansTexte: true` forcé. **2 échecs** sur `test/features/controleur` (187 réussis) : « Observation, serveur muet : non confirme et Retour de nouveau disponible » et « Sans serveur, l envoi echoue et la saisie reste ». Le choix du message est donc tenu dans les deux sens.
- **Capture `ctrl_seance1_faits_a_320x2_clair`** : seulement les faits de la Classe Al-Fajr. La valeur de « Reconnexions » passe sous son libellé (repli de `LigneCleValeur`, antérieur). Pas de nouveau défaut.
- **Bouton dans un bouton, couleur ou texte en dur** : rien de nouveau dans le diff. Les 3 clés i18n sont sourcées.
- **Fusion à blanc** rejouée : même conflit unique, `tool/libelles_sources.json`.

### Verdict corrigé

**Refusée.** Deux majeurs : M1 (confirmé) et M2 (nouveau). Pour accepter : CTRL-MSG-2 (M1 avec m1), puis CTRL-X2-1 (M2, avec m4 : captures à vrai texte ×2). m2, m5 recommandés dans la même passe ; m3 au pilotage ; m6 en CTRL-RETOUR-2.

## Suite complète (session principale 01KyPAZg)

Suite dossier par dossier (`flutter test` par dossier de `test/`, captures ignorées) : c1-ctrl : 5371 réussis, 0 échec.
