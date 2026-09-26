# Classe et visio : plan de code (CL-2 écrans, CL-3, CL-5, CL-6)

Date : 26/09/2026. Rédigé par un agent d'exécution du poste B, sans question au directeur (il dort).
Worktree `C:\RA\classe`, branche `ui/classe-v1` @ `3b41b12`. Consigne K-28 : **aucun branchement serveur**, mode démonstration et ports existants seulement ; le serveur et la configuration viennent à BR-1.

Références, dans cet ordre : `V/01_MATRICE_ROLES.md` (qui voit quoi) ; images `V/retouchees/*_r.jpg` (à reproduire) ; `V/03_RECTIFICATIONS_FINAL.json` (I-1 à I-10, Q1-Q8) ; spec `C:\RA\ressources\specs\02_classe_et_visio\02_CLASSE_ET_VISIO.md` ; `00_REPRISE.md`, `01_INVENTAIRE_CODE.md`, `02_DIRECTION_VISUELLE.md` (D1-D10 seulement s'ils vont dans le sens des images).

## 1. Décision CL-2 : où vit la salle unique

| Question | Décision | Raison |
|---|---|---|
| Route canonique | **`/salle`** (`lib/features/salle/salle_page.dart`) reste l'hôte : billet d'entrée, jeton, rôle **du jeton**, présence, observation, impasses, sortie vers le cahier. | Spec §0 et §3 ; c'est le chemin réellement emprunté (Journée enseignant « Lancer », accueil élève, contrôleur). |
| Rendu | Pour les rôles jeton `eleve` et `enseignant`, `SallePage` rend le **nouveau gabarit `SalleSeance`** (dossier neuf `lib/features/salle_seance/`). Les rôles tuteur observateur, contrôleur, administration gardent le rendu actuel (hors vague). | Un seul gabarit paramétré par le rôle effectif (DV D9, matrice « règle mère »). |
| `/tc/classe` | La route et `ControleurSessionPersistante` restent. `ClasseLivePage` rend **le même `SalleSeance`** via un adaptateur. Aucune route supprimée. | « Sans casser les routes existantes ». La fusion du moteur (session persistante dans `/salle`) est du câblage : BR-1. |
| Ce qu'on reprend de `/tc/classe` | `RosterClasseVM` (source unique du compteur, de la liste et du récapitulatif, I-6), le contenu de `FicheSeance` (six champs, quatre actions), `SessionClockVM` (« 32 min restantes »), `EmplacementBibliothequeEnClasse` / `ClassLibraryPicker` (Supports, câblage à BR-1). | Le meilleur de l'autre salle, sans le réécrire. |
| Rôle effectif | `RoleSeance { eleve, guidee, enseignant }` = rôle du jeton (`RoleSalle.eleve` / `RoleSalle.enseignant`) + mode d'interface **lu dans le thème** (`AppMetriques.of(context)`, `InterfaceMode.enfant` = guidée). Jamais passé d'écran en écran (lib/CLAUDE.md). | Matrice colonnes ES / IG / EN. |
| Mention d'enregistrement | `PermanentNotice` reste l'unique composant de la mention (sans paramètre, ADR-011). Son **rendu interne** devient : point rouge 8 px + texte 12-13 px couleur secondaire, sans fond ni bordure ni icône (I-1). Le point devient un widget public `PointEnregistrement` du même fichier. | lib/CLAUDE.md : on améliore le composant, on n'en recrée pas un. |
| Démonstration | Données fictives cohérentes `lib/features/demo/seance_demo.dart` et une page hors production `/demo/salle` (liste rôle × état, puis la salle en plein écran). | « Un moyen de voir chaque état » sans serveur. |

## 2. Architecture

```
lib/features/salle_seance/
  vue_seance.dart          RoleSeance, VueSeance (immuable, pure) et TOUTES les règles de la matrice en getters
  actions_seance.dart      ActionsSeance : rappels nullables (null = bouton non rendu)
  salle_seance.dart        SalleSeance : gabarit unique, dispositions compacte (<600) / moyenne (600-1199) / large (>=1200) via Gabarit
  chrome_seance.dart       ChromeSeance : retour, titre, ligne d'état, pastille « En ligne », MentionSeance, coin droit (thème, cloche, réglages, compte)
  mention_seance.dart      MentionSeance : PermanentNotice au repos ; pendant une visite, PointEnregistrement + notice
  zone_support.dart        ZoneSupport (support dominant, défilement au pouce, état « rien partagé »)
  vignette_video.dart      VignetteVideo (ratio 1,1:1 fixe, jamais étirée, étiquette nom, signal enseignant seulement)
  dock_seance.dart         DockSeance (standard / guidée / enseignant) + BoutonAppel (cercles de même diamètre)
  barre_support.dart       IndicateurPage (lecture seule), PaginationSupport (enseignant), ZoomLocal
  outils_enseignement.dart OutilsEnseignement : rangée (desktop CLV-06, mobile), colonne (web étroit), carte (desktop CLV-07/08)
  rail_seance.dart         RailSeance : barre latérale enseignant desktop (Journée, Classes, Ressources, Profil)
  panneau_seance.dart      PanneauSeance : tiroir gauche desktop / volet gauche web étroit / feuille du bas mobile
  panneau_eleves.dart      CLV-07 : liste + fiche dépliée + 4 actions
  panneau_supports.dart    CLV-08 : Reprendre, Récents, Ressources de la Classe, Voir toute la bibliothèque
  resultat_seance.dart     ResultatSeance : CLV-09 (élève, guidée) et CLV-10 (enseignant, récapitulatif)
  depuis_salle.dart        adaptateur VueSalle + présence + annonces -> VueSeance (pour /salle)
  depuis_classe_live.dart  adaptateur ContexteClasseLive + RosterClasseVM -> VueSeance (pour /tc/classe)
lib/features/demo/
  seance_demo.dart         DonneesSeanceDemo + EtatDemoSalle { repos, visite, rienPartage, eleves, supports, fin }
  demo_salle_page.dart     page /demo/salle (hors production seulement)
test/features/salle_seance/
  vue_seance_test.dart     la matrice en tests purs (un test par ligne « jamais »)
  salle_seance_widget_test.dart   présence / absence d'éléments par rôle, sans débordement aux 3 largeurs
  salle_seance_capture_test.dart  captures (sautées sans CAPTURE_DIR)
```

Principes : `VueSeance` ne connaît ni LiveKit ni Supabase ; les widgets ne décident rien, ils lisent les getters (`voitCompteurEleves`, `voitPaginationActive`, `voitIndicateurPage`, `voitZoomLocal`, `commandesDock`, `ligneEtat`, `texteNotice`, `pointClignote`, `titre`…). Un rappel `null` dans `ActionsSeance` = bouton non rendu (lib/CLAUDE.md). Les outils d'enseignement ne sont rendus que si un rappel existe (vrai en démo, faux dans `/salle` tant que BR-1 n'a pas câblé le Teaching Dock).

Jetons : couleurs `AppPalette` (paires, encres), espacements `AppSpacing`, rayons `AppRadius`, ombres `AppElevation`, durées `AppMouvement` (le clignotement utilise `AppMouvement.pulsation` en aller-retour, ≈ 2,4 s, et devient un point fixe si `AppMouvement.mouvementReduit`), icônes `AppIcons` (Phosphor), tout geste par `Pressable`. **Aucun fichier de `lib/core/theme/` modifié.** Contrôle : `dart run tool/verifier_jetons.dart`.

Textes : clés slang `salle.seance.*` (écran) et `salle.fin.*` dans `assets/i18n/fr.i18n.json` (+ `ar.i18n.json`, repli `fr` admis), puis `dart run slang`. Les contenus fictifs (noms, support) vivent dans `seance_demo.dart` comme `DonneesDemo`.

## 3. Données de démonstration (I-6, une seule source)

Classe An-Nour ; enseignante Sayyida Amina (compte « SA ») ; élève devant l'écran Mariam (vue élève et guidée) ; 3 inscrits.

| Élève | Statut pendant la séance | Couleur |
|---|---|---|
| Mariam | Connecté | succès (vert) |
| Yusuf | Pas encore connecté | avertissement (jaune) |
| Aïcha | Connexion interrompue | alerte (rouge) |

Compteur = connectés maintenant : **« Élèves 1/3 »** partout (les images CLV-06/08 affichent « 3/4 » : écart de données corrigé par I-6). Fin : « 2 élèves connectés sur 3 inscrits » (connectés au moins une fois : Mariam, Aïcha), fin 15:16, « Cahier à compléter ». Fiche Mariam : Niveau 1 ; Objectif actuel Chapitre 1 (les bonnes manières) ; Dernière séance 24 sept. 2026 ; À reprendre Pages 24 à 26 ; Présence récente 3 séances cette semaine ; Travail actuel Écoute de la récitation. Jamais « présent » ni « absent ».
Support : « Chapitre 1 », « Les bonnes manières en classe », encadré « Être attentif aux explications du professeur. », liste 1 Écouter avec calme. 2 Poser des questions poliment. 3 Respecter les camarades., page 1 / 12. Illustration et vidéo : aplats aux jetons (jamais de photo réelle en capture).
Supports : Reprendre « Chapitre 1 · Les bonnes manières · Support de cours · v2.0 » (Ouvrir) ; Récents « Fiche de mémorisation · PDF · 12 pages · v1.1 », « Exercices – Chapitre 1 · PDF · 8 pages · v1.0 » ; Ressources de la Classe « Bibliothèque An-Nour · 24 ressources » ; « Voir toute la bibliothèque ».
Horloge : « 32 min restantes » ou « La séance se poursuit. » (état `depassee`). Visite : « le tuteur de Mariam observe » (vrai/faux).

## 4. Réponses retenues aux questions Q1-Q8 (option des images, sans réponse du directeur)

Q1 oui (guidée : disques pleins vert Parler et violet Caméra, même diamètre que Agrandir et Quitter). Q2 : desktop CLV-06 = rangée d'outils au-dessus du support ; desktop CLV-07/08 = carte « Outils d'enseignement » en colonne droite ≈ 340 px, avec Élèves et Supports au-dessus (comme les images). Q3 non (compte en haut à droite). Q4 non (« Tuteur de Mariam observe. »). Q5 non (texte complet). Q6 oui (zoom local élève avec « Zoom local, sans effet sur les autres »). Q7 oui (jamais la vidéo des autres élèves). Q8 oui (guidée desktop : vidéo à côté du support). Barre latérale enseignant desktop : gardée (images), entrées de la matrice Journée, Classes (active), Ressources, Profil ; les entrées « Séance en direct » vues sur CLV-08/10 ne sont pas reprises (matrice prime). Chaque réponse est une constante nommée dans `vue_seance.dart` (`optionQ1`…), pour qu'un « non » du directeur se change en une ligne.

## 5. Correspondance image -> écran -> rôle -> capture

| Image retouchée | Écran | Rôle effectif | États | Capture (dans `10_classe/captures/T<n>/`) |
|---|---|---|---|---|
| `CLV-04_eleve_desktop_r.jpg` | CLV-04 | élève | visite (Mariam) | `cl_04_eleve_visite_1440x900@1_{dark,light}` |
| `CLV-05_guidee_desktop_r.jpg` | CLV-05 | guidée | visite, point fixe + œil | `cl_05_guidee_visite_1440x900@1_*` |
| `CLV-06_enseignant_desktop_r.jpg` | CLV-06 | enseignant | visite, « se poursuit » | `cl_06_enseignant_visite_1440x900@1_*` |
| `CLV-07_eleves_desktop_r.jpg` | CLV-07 | enseignant | panneau Élèves, fiche Mariam dépliée | `cl_07_eleves_1440x900@1_*` |
| `CLV-08_supports_desktop_r.jpg` | CLV-08 | enseignant | panneau Supports | `cl_08_supports_1440x900@1_*` |
| `CLV-10_fin_desktop_r.jpg` | CLV-10 | enseignant | fin | `cl_10_fin_1440x900@1_*` |
| `CLV-04-05-06_mobile_r.jpg` | CLV-04/05/06 | élève, guidée, enseignant | visite | `cl_0{4,5,6}_*_visite_390x844@3_*` |
| `CLV-07-08-10_mobile_r.jpg` | CLV-07/08/10 | enseignant | sans visite, « 32 min restantes », feuilles | `cl_{07,08,10}_*_390x844@3_*` |
| `CLV-04-05-06_web_etroit_r.jpg` | CLV-04/05/06 | trois rôles | visite | `cl_0{4,5,6}_*_visite_640x1000@1_*` |
| `CLV-07-08-10_web_etroit_r.jpg` | CLV-07/08/10 | enseignant | visite, « 32 min restantes », volets | `cl_{07,08,10}_*_640x1000@1_*` |
| (aucune, spec) | CLV-09 | élève, guidée | fin | `cl_09_{eleve,guidee}_fin_{390x844@3,1440x900@1}_*` |

Tailles : mobile 390x844 @3 (zone sûre 47/34), web étroit 640x1000 @1 (gabarit tablette), desktop 1440x900 @1. Les deux thèmes. Écart accepté et à dire dans chaque rapport : photos remplacées par des aplats.

## 6. Consignes communes à toutes les tâches

- Réponds en français. Ne pose pas de question. Ne parle jamais du questionnaire d'accueil.
- Lis d'abord ce plan (§1 à §5), puis la matrice `V/01_MATRICE_ROLES.md`, puis ouvre avec Read les images de ta tâche.
- Pars du dernier commit de `origin/ui/classe-v1` (`git -C C:\RA\classe pull --rebase`). Chaque tâche part de la précédente.
- Commandes lourdes **toujours** : `& C:\RA\pilotage\outils\flutter-verrou.ps1 -Dossier C:\RA\classe -Commande "flutter <cmd>"` (analyze, test, slang via `flutter pub run slang` ou `dart run slang` si le verrou l'accepte).
- Interdits : `main`, PR, `supabase/`, `.github/`, `vercel.json`, `pubspec.yaml`, `lib/core/theme/*`, tout ce qui touche au Coran, secrets, tout appel serveur. Ne jamais committer `windows/flutter/generated_*` : `git add` fichier par fichier.
- Règles visuelles : un seul style de bouton d'appel (cercles de même diamètre), aucun chevauchement (sauf la vignette vidéo, posée en coin du support avec retrait de 12 px, et les feuilles/volets), support dominant, vignette jamais déformée (`AspectRatio` fixe + `BoxFit.cover`), mention = point rouge + petit texte sans fond ; pendant une visite, point qui clignote doucement (guidée : point fixe + icône œil) et la notice remplace le texte. Rien de réservé à l'enseignant (Élèves, Supports, Pointeur/Marquer/Masquer/Annoter, Réseau, pagination active, durée restante) sur les vues élève et guidée. Pas de « Foyer ». Textes par slang. Clair + sombre.
- Fin de tâche : `flutter analyze` sans erreur ni avertissement nouveau, `dart run tool/verifier_jetons.dart` vert, tests de la tâche verts, captures produites avec `$env:CAPTURE_DIR = "C:\RA\pilotage\05_recette\CL\captures\<Tn>"`, puis relis toi-même chaque capture avec Read à côté de l'image retouchée et corrige les écarts visibles. Commit (message en français, attribution `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`) et push sur `origin ui/classe-v1`. Captures et un court `05_recette/CL/<Tn>.md` (fait, écarts restants) committés dans `C:\RA\pilotage` (branche `pilotage/tuteur-v1`, `git pull --rebase` avant push).
- Plus de 35 min : committe et pousse ce qui est propre, écris ce qui reste dans `05_recette/CL/<Tn>.md`.

## 7. Tâches (séquentielles, chacune < 30 min)

**Où en est-on (seule source ; une ligne par fiche du §8) :**

| Fiche §8 | État | Où lire le résultat |
|---|---|---|
| T1 à T7 | faites | `05_recette/CL/T1.md` à `T7.md` |
| **T8** (rendu en séance de `/salle`) | **à faire : c'est la prochaine et la dernière** | - |
| T9 (`/tc/classe`) | faite | `05_recette/CL/T8.md` |
| T10 (recette, 10 planches) | faite, retours de relecture corrigés (`262b4b2`) | `05_recette/CL/RAPPORT.md`, captures `captures/T9/` |
| CL-7 écrans de secours, T-S1 à T-S6 (plan `07_SECOURS.md`) | faites (T-S6 `56541ce`) | `05_recette/CL/T-S1.md` à `T-S6.md`, `RAPPORT.md` section « Écrans de secours (CL-7) », captures `captures/TS2/` à `TS6/` |

Pour les rapports, se fier à la colonne « Fiche §8 » (les noms de fichiers de rapport ont un cran de décalage). Une fiche est « faite » quand son retour de relecture est corrigé et poussé. Captures d'une nouvelle tâche : `10_classe/captures/T<fiche>/`, seulement ses écrans.

Le détail de chaque tâche suit (§8). Chaque agent lit §1 à §6 puis sa fiche.

## 8. Fiches des tâches

### T1 - Socle : règles, données démo, i18n, mention et en-tête

Fichiers : créer `lib/features/salle_seance/vue_seance.dart`, `actions_seance.dart`, `mention_seance.dart`, `chrome_seance.dart` ; `lib/features/demo/seance_demo.dart` ; modifier `lib/core/widgets/permanent_notice.dart` (rendu seulement) ; `assets/i18n/fr.i18n.json` (+ `ar`) puis `dart run slang` ; `test/capture/outil_capture.dart` (paramètre `interfaceMode` de `hoteCapture`, défaut `standard`) ; tests `test/features/salle_seance/vue_seance_test.dart`, `chrome_seance_test.dart`, `salle_seance_capture_test.dart`.
1. `RoleSeance { eleve, guidee, enseignant }` et `RoleSeance.resoudre(RoleSalle, InterfaceMode)` (autre rôle du jeton = `null` : la salle garde l'ancien rendu).
2. `VueSeance` immuable (§3 : classe, enseignant, compte, élève courant, horloge `restantes(min) | depassee | null`, connexion, `enregistrementConfirme`, `visite` {prénom de l'enfant observé, concerneMoi}, support, caméra enseignant, signal, liste d'élèves, supports, fin, panneau ouvert) et les getters de la matrice : `titre`, `ligneEtat` (I-9), `texteMention`, `texteNotice` (I-2 : « Votre parent observe la séance. » / « Ton parent observe la séance. » seulement si `concerneMoi` ; « Tuteur de {prénom} observe. » toujours pour l'enseignant), `pointClignote` (jamais en guidée), `voitCompteurEleves`, `compteurEleves` (dérivé de la liste, I-6), `voitPaginationActive`, `voitIndicateurPage`, `voitZoomLocal`, `commandesDock` (I-4), `voitOutils`, `voitBoutonsPanneaux`, `voitDureeRestante`, constantes `optionQ1` à `optionQ8` (§4).
3. `seance_demo.dart` : `DonneesSeanceDemo.vue(role, etat)` pour `EtatDemoSalle { repos, visite, rienPartage, eleves, supports, fin }`, avec les données exactes du §3.
4. `PermanentNotice` : même constructeur sans paramètre, même texte `t.salle.bandeauPermanent`, nouveau rendu : `PointEnregistrement` (cercle 8 px, encre d'alerte de la palette) + texte `bodySmall` en encre secondaire, sans fond, aligné à gauche. `PointEnregistrement({bool clignote})` public dans le même fichier (aller-retour 100 % vers 40 % sur `AppMouvement.pulsation`, fixe si `AppMouvement.mouvementReduit`).
5. `MentionSeance` : enregistrement non confirmé ou fin = rien ; repos = `PermanentNotice()` ; visite visible pour ce rôle = point (clignotant sauf guidée) + [icône œil en guidée] + notice ; libellé d'accessibilité = mention + notice. Aucun rôle ne voit un contrôleur.
6. `ChromeSeance` : retour ‹, titre (« Séance en direct » / « Ma séance »), ligne d'état, pastille « En ligne » (`StatusPill` existant), mention. Desktop : mention sur la même ligne après « En ligne ». Mobile et web étroit : « En ligne » à droite du titre, mention en ligne seule dessous (images). Coin droit desktop : élève et enseignant = bascule de thème (`BasculeTheme`), cloche, réglages, compte (avatar + nom + chevron) ; guidée = icône de sortie + avatar « M » + « Mariam » sans menu ; mobile et web étroit : rien à droite hormis « En ligne ».
Critères : un test par ligne « jamais » de la matrice §6 (élève et guidée : aucun compteur, Réseau, outil, pagination active, durée restante, « Tuteur de » ; enseignant : jamais « Votre parent », jamais « Mariam » comme compte) ; la notice n'apparaît pas pour un élève non concerné ; « Élèves x/y » = nombre de « Connecté » de la liste ; aucun « Foyer », « présent », « absent ». Captures : en-tête seul (`ChromeSeance` dans un `Scaffold`) pour les 3 rôles, repos et visite, 390 / 640 / 1440, clair et sombre, dans `05_recette/CL/captures/T1`.

### T2 - Salle élève standard CLV-04 et page de démonstration

Fichiers : `salle_seance.dart`, `zone_support.dart`, `vignette_video.dart`, `dock_seance.dart`, `barre_support.dart` ; `lib/features/demo/demo_salle_page.dart` ; route `/demo/salle` dans `lib/core/router/routes.dart` et `app_router.dart` (+ `redirection.dart` pour la laisser passer sans session), enregistrée **seulement** si `environnementAutoriseDemo(Env.environnement)` ; tests widget et captures.
1. `SalleSeance(vue, actions)` : plein écran, sans barre de l'app ; dispositions par `Gabarit` (compacte < 600, moyenne 600-1199, large >= 1200). Élève : en-tête (T1), support dominant, vignette de l'enseignante en coin haut droit du support (retrait 12 px, ≈ 136x124 en mobile et web étroit, ≈ 208x190 en desktop, ratio fixe), dock Micro, Caméra (si autorisée), Agrandir, Quitter.
2. Desktop (image CLV-04) : barre basse à 16-24 px sous le support : à gauche indicateur « 1 / 12 » en lecture seule (aucune flèche), au centre le dock, à droite « Zoom local, sans effet sur les autres » + (−, 100 %, +) + icône Agrandir (même action que le dock). Mobile et web étroit : ni pagination ni indicateur (I-7), le support défile au pouce.
3. `BoutonAppel` : cercle unique (diamètre `AppMetriques.cibleTactile`), icône + libellé dessous ; Quitter = disque plein d'alerte ; les autres = surface surélevée. Quitter ouvre `ConfirmDestructive` avec « Vous pourrez revenir si la séance est encore ouverte. ».
4. `ZoneSupport` : carte claire aux jetons, contenu démo (§3) ; état `rienPartage` : vidéo de l'enseignante au centre + « {Titre} {Prénom} n'a rien partagé pour l'instant. ».
5. `DemoSallePage` : liste de liens rôle × état (3 x 6) ; chaque lien ouvre la salle démo en plein écran avec état local (micro, caméra, zoom, panneaux qui s'ouvrent vraiment) ; guidée = sous-arbre `Theme(AppTheme.pour(InterfaceMode.enfant, luminosité))`.
Critères : aucun débordement (`tester.takeException()` nul) à 390x844, 640x1000, 1440x900 ; vue élève sans Élèves, Supports, Réseau, outil, flèche de page ; vignette de ratio constant quand la largeur change ; notice « Votre parent observe la séance. » seulement en état visite. Captures CLV-04 repos et visite aux 3 tailles, clair et sombre, comparées à `CLV-04_eleve_desktop_r.jpg` et aux colonnes gauches de `CLV-04-05-06_mobile_r.jpg` et `CLV-04-05-06_web_etroit_r.jpg`.

### T3 - Interface guidée CLV-05 et fin élève CLV-09

Fichiers : `salle_seance.dart`, `dock_seance.dart`, `vignette_video.dart`, `resultat_seance.dart` (nouveau), i18n `salle.fin.*`, tests, captures.
1. Guidée (thème `InterfaceMode.enfant`) : titre « Ma séance », pas de sous-titre, « En ligne » + mention (visite : point **fixe** + œil + « Ton parent observe la séance. »). Coin droit desktop : icône de sortie (même confirmation que Quitter) + avatar Mariam sans menu.
2. Dock guidé : Parler (disque plein vert, paire succès), Caméra (disque plein violet, paire primaire) seulement si autorisée, sinon aucun bouton ; Agrandir ; Quitter ; tous de même diamètre (`cibleTactile` du mode enfant) (Q1).
3. Vidéo : desktop = colonne à droite du support ≈ 300x275, jamais par-dessus (Q8) ; mobile ≈ 160x150 et web étroit ≈ 180x164 en coin du support. Étiquette sans barres de signal. Ni pagination, ni indicateur, ni zoom.
4. `ResultatSeance` (réutiliser `EcranResultat` de `lib/core/widgets/ecran_resultat.dart` si sa grammaire suffit) : CLV-09 standard « Séance terminée » / « Vous pouvez retrouver votre travail dans votre Classe. » / « Retour à la Classe » ; sortie avant fin « Vous avez quitté la séance. » / « Vous pourrez revenir tant qu'elle reste ouverte. » ; guidée « La séance est terminée. » / « Retour à l'accueil ». Aucun récapitulatif, aucune présence, aucune mention d'enregistrement.
Critères : guidée sans zoom, indicateur de page, signal, sous-titre, « La séance se poursuit. » ; boutons du dock de taille égale (test sur les `Size`) ; point non animé en guidée ; textes CLV-09 exacts. Captures CLV-05 visite aux 3 tailles et CLV-09 (élève, guidée) en 390 et 1440, clair et sombre, comparées à `CLV-05_guidee_desktop_r.jpg` et aux colonnes centrales des planches mobile et web étroit CLV-04-05-06.

### T4 - Salle enseignant CLV-06

Fichiers : `salle_seance.dart`, `rail_seance.dart`, `outils_enseignement.dart`, `barre_support.dart`, `dock_seance.dart`, `vignette_video.dart`, tests, captures.
1. Ligne d'état « Classe An-Nour · 32 min restantes » ou « Classe An-Nour · La séance se poursuit. » (texte simple), « En ligne », mention ; visite : point clignotant + « Tuteur de Mariam observe. ». Compte « SA Sayyida Amina ».
2. Desktop : `RailSeance` à gauche (logo Rewayah Academy ; Journée -> `Routes.enseignantJournee` ; Classes, active -> `Routes.groupePour(groupeId)` ; Ressources -> `RoutesTcB.bibliotheque` ; Profil -> `Routes.enseignantProfil` ; toute sortie passe par la confirmation de Quitter). Rangée d'outils Pointeur, Marquer, Masquer, Annoter (tuiles avec libellé) au-dessus du support ; à droite, boutons « Élèves 1/3 › » et « Supports › ».
3. Mobile : Élèves et Supports en deux boutons au-dessus du support, rangée de 4 tuiles d'outils entre support et dock. Web étroit : mêmes boutons au-dessus, outils en colonne à droite du support.
4. Vignette de l'enseignante seulement si sa caméra est active, avec indicateur de signal. Dock Micro, Caméra, Réseau, Quitter (séparateur avant Quitter), jamais Agrandir. Desktop : pagination active ‹ 1/12 › alignée sous le support à gauche, zoom (−, 100 %, +) à droite, sans Agrandir. Mobile : pas de pagination.
5. Quitter : confirmation « Quitter et ouvrir le cahier » (spec l.861-863) ; aucun « Terminer pour tous », aucun « Prolonger ».
Critères : enseignant sans « Votre parent », « Ton parent », « Mariam » en compte, « Foyer », Agrandir ; outils rendus seulement si `actions.onOutil` n'est pas nul ; compteur = T1. Captures CLV-06 visite aux 3 tailles, clair et sombre, contre `CLV-06_enseignant_desktop_r.jpg` et les colonnes droites des planches CLV-04-05-06.

### T5 - PanneauSeance et CLV-07 Élèves

Fichiers : `panneau_seance.dart`, `panneau_eleves.dart`, `salle_seance.dart`, tests, captures. Relire `lib/features/tc_classe_live/fiche_seance.dart`, `roster_classe.dart` et `lib/core/tc_classe/roster_classe_vm.dart` : reprendre champs, statuts et actions, sans dupliquer de logique (le VM reste la source ; en démo, `DonneesSeanceDemo` fournit une liste au même format).
1. `PanneauSeance(titre, onFermer, enfant)` : desktop = colonne gauche ≈ 340 px entre rail et support, jamais par-dessus le support ; web étroit = volet gauche par-dessus le support (I-8) avec ✕ ; mobile = feuille du bas (`AppBottomSheet`) avec poignée et ✕, le support visible au-dessus.
2. `PanneauEleves` : ligne Mariam dépliée (avatar M, « Connecté » vert, chevron), grille 2 colonnes des six champs, quatre actions Rappeler, Choisir pour réciter, Noter, Signaler un besoin (tuiles icône + libellé) ; puis Yusuf « Pas encore connecté » (jaune), Aïcha « Connexion interrompue » (rouge), repliés avec chevron ›.
3. Desktop avec panneau ouvert (image CLV-07) : support au centre avec vignette ; colonne droite : boutons Élèves 1/3 et Supports puis carte « Outils d'enseignement » (Q2) ; pagination et zoom sous le support seulement.
Critères : panneau jamais rendu pour élève ou guidée (test) ; aucun « Absent » ni « Présent » ; compteur du bouton = nombre de « Connecté » de la liste ; aucune coordonnée familiale. Captures CLV-07 aux 3 tailles, clair et sombre (desktop : visite + « se poursuit » ; mobile : sans visite, « 32 min restantes » ; web étroit : visite, « 32 min restantes »), contre `CLV-07_eleves_desktop_r.jpg` et les colonnes gauches des planches CLV-07-08-10.

### T6 - CLV-08 Supports

Fichiers : `panneau_supports.dart`, `salle_seance.dart`, tests, captures. Relire `lib/features/tc_catalogue/` (`ClassLibraryPicker`, `EmplacementBibliothequeEnClasse`) : reprendre modèles et libellés, sans câbler de serveur.
1. `PanneauSupports` dans `PanneauSeance` : « Reprendre » (vignette, « Chapitre 1 », « Les bonnes manières », « Support de cours · v2.0 », bouton « Ouvrir ») ; « Récents » + « Voir tout → » (deux lignes PDF) ; « Ressources de la Classe » (+ « Voir tout → » en mobile et web étroit) ; bouton plein « Voir toute la bibliothèque → » (seule zone pleine du panneau).
2. Desktop (image CLV-08) : panneau Supports à gauche, support au centre, colonne droite = carte Outils puis boutons Élèves 1/3 et Supports en liste ; dock, puis pagination et zoom à droite du dock (image).
3. En démo, « Ouvrir » change le support affiché et ferme le panneau ; dans `/salle`, rappel nul = bouton non rendu (BR-1).
Critères : panneau enseignant seulement ; une seule action pleine ; aucun chevauchement à 640 de large. Captures CLV-08 aux 3 tailles, clair et sombre, contre `CLV-08_supports_desktop_r.jpg` et les colonnes centrales des planches CLV-07-08-10.

### T7 - CLV-10 fin enseignant et branchement de /salle

Fichiers : `resultat_seance.dart`, `depuis_salle.dart`, `lib/features/salle/salle_page.dart`, tests `test/features/salle_test.dart`, `salle_enseignant_test.dart` et nouveaux, captures.
1. CLV-10 : en-tête « Séance terminée » + « Classe An-Nour » + pastille « Terminée », rail enseignant en desktop ; icône validée, « Séance terminée », « Le cahier est prêt avec les informations de la séance. », carte récapitulative (Classe An-Nour · Sayyida Amina ; Fin 15:16 ; 2 élèves connectés sur 3 inscrits ; Cahier de séance + badge doux « Cahier à compléter »), bouton plein « Ouvrir le cahier → » (`Routes.cahierPour`), secondaire « Revenir à ma journée ». État « Le cahier ne peut pas être ouvert pour le moment. » + « Réessayer ». Aucune mention d'enregistrement.
2. `depuis_salle.dart` : construit `VueSeance` depuis `VueSalle`, la présence déjà lue (`presenceSeanceProvider`), `monTuteurObserveProvider`, `annoncesObservationProvider`, les capacités (caméra autorisée) ; outils et Supports sans rappel (non rendus) tant que BR-1 n'a pas câblé.
3. Sorties de `/salle` : enseignant -> CLV-10 puis cahier ; élève -> CLV-09 (« Retour à la Classe » -> `/tc/groupes`, guidée -> accueil). Le rendu EN séance est passé en T8.
Critères : `test/features/salle_test.dart`, `salle_enseignant_test.dart`, `test/video`, `test/router` verts ; route `/salle` inchangée. Captures `10_classe/captures/T7/cl_10_fin_*` aux 3 tailles, clair et sombre, contre `CLV-10_fin_desktop_r.jpg` et les colonnes droites des planches CLV-07-08-10.

### T8 - Rendu en séance de /salle sur SalleSeance

Pourquoi à part : brancher tel quel casserait la vraie vidéo, le Coran et la présence (voir `05_recette/CL/T7.md`, « Reste à faire »). Ne pas toucher `PanneauEnseignant` (il porte le Coran : interdit).
Fichiers : `vignette_video.dart`, `zone_support.dart` (ou équivalents de `salle_seance/`), `salle_seance.dart`, `lib/features/salle/salle_page.dart`, tests `salle_test.dart`, `salle_enseignant_test.dart`.
1. Un emplacement `video` (Widget optionnel) dans `VignetteVideo` et `ZoneSupport`, rempli par `renduVideo` du moteur ; sans lui, le rendu démo actuel. Vidéo jamais déformée (cover dans la vignette).
2. Un emplacement pour la ligne de présence de l'élève (« Ma présence », « en retard »), le mot du lien (qualité en mots) et « Vous attendez votre professeur », sans chevauchement et sans rien de réservé à l'enseignant chez l'élève et la guidée.
3. `PanneauEnseignant` gardé tel quel, posé par-dessus la salle enseignant (aucune modification de son contenu).
4. Enfin `SallePage.build` : si `RoleSeance.resoudre(vue.role, mode)` n'est pas nul et hors impasse, rendre `SalleSeance` via `DepuisSalle` (déjà prêt et testé) ; sinon rendu actuel (observateur, contrôleur, administration, impasses).
Critères : `salle_test.dart`, `salle_enseignant_test.dart`, `test/video`, `test/router` verts sans affaiblir une règle (invisibilité du contrôleur, annonce d'observation à l'enseignant, jamais « absent », présence et lien toujours dits). Captures `10_classe/captures/T8/` : CLV-04, CLV-05, CLV-06 rendues par `SallePage` avec le faux moteur, 3 tailles, clair et sombre.

### T9 - Branchement de /tc/classe et remise au vert

Fichiers : `depuis_classe_live.dart`, `lib/features/tc_classe_live/classe_live_page.dart`, tests `test/teaching_core/e/*`, `test/teaching_core/q/q12_navigation_session_persistante_test.dart`.
1. `ClasseLivePage` garde `ControleurSessionPersistante`, `PreCours` et sa route ; son corps en séance devient `SalleSeance` via `depuis_classe_live.dart` (`RosterClasseVM` -> liste d'élèves, `SessionClockVM` -> horloge, `ContexteClasseLive.support/dock/bibliotheque` -> rappels non nuls seulement s'ils sont fournis).
2. Supprimer seulement le code de rendu devenu mort dans `classe_live_page.dart` (`_Corps`, `_Commandes`…) s'il n'a plus d'appelant ; garder `FicheSeance`, `PanneauRoster`, `BarreCoursEnCours` s'ils ont encore un importeur.
Critères : `flutter test test/teaching_core test/features/salle_test.dart test/features/salle_enseignant_test.dart test/router` vert ; `/tc/classe` et `/salle` rendent la même salle pour un même rôle (test widget qui compare les textes visibles des deux hôtes) ; `flutter analyze` propre. Captures CLV-06 et CLV-07 desktop et mobile rendues via `ClasseLivePage` avec le faux moteur (`test/teaching_core/e/faux/faux_classe.dart`), comparées aux captures T4 et T5.

### T10 - Recette complète

Fichiers : `test/features/salle_seance/salle_seance_capture_test.dart` (complété), `test/capture/outil_capture.dart` (fonction `plancheRangee` : image retouchée en haut, rangée de N captures dessous, tout en `dart:ui`), `C:\RA\pilotage\05_recette\CL\RAPPORT.md`, `OU_TROUVER.md`.
1. Produire toutes les captures du §5 dans `10_classe/captures/T10/` (clair et sombre), plus les états repos, rien partagé, panneaux, fin, pour chaque rôle, aux 3 tailles.
2. Dix planches `planche_<nom_image>.png` : image retouchée contre rendu (une capture pour les desktop, rangée de trois pour les planches mobile et web étroit).
3. Relire chaque planche avec Read ; corriger dans le code les écarts de mise en page (pas les photos) ; relancer.
4. `flutter analyze`, `dart run tool/verifier_jetons.dart`, **suite complète** `flutter test` (sous verrou).
5. `RAPPORT.md` : tableau image -> capture -> écarts restants -> invariant I-x vérifié par quel test ; options Q1-Q8 appliquées ; ce qui attend BR-1 (support partagé réel, outils câblés, Supports réels, session persistante dans `/salle`, micro et caméra des plateformes). `OU_TROUVER.md` en langage simple pour le directeur (dossier des images, adresse `/demo/salle`).
Critères : 10 planches présentes, aucune capture en carrés (garde-fou des polices), suite complète verte ou échecs listés avec la preuve qu'ils existaient déjà au commit `3b41b12`.
