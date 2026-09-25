# Lot B : Foyer et fiche eleve (rapport de lot)

Branche `ui/tuteur-v1-b`, dernier commit `be96493` (test C6 ; migration `7ebbd03`, fusion `1d5e383` de `origin/ui/tuteur-v1` @ `1cbc760`, voir §9 ; avant fusion : dernier commit `f258944`, base `cefab7f`, aucune nouvelle base annoncee par A : `origin/ui/tuteur-v1` = `cefab7f`, relu le 24/09 a 22 h 40). Historique : LB-1 `d8f77c9`, LB-2 `2ccb990`, LB-3 `d7b006f`, corrections de la revue (LB-F) `f258944`. Rapports detailles : `LB-2.md`, `LB-3.md` ; revue : `REVUE.md`.

**Verdict : LOT B TERMINE a `be96493`.** Tous les criteres techniques de fin de lot (05 §0) sont remplis. Les deux ecarts de maquette qui dependaient du coordinateur sont leves par la migration de `7ebbd03` (voir §9) : B-1 (avatar ou initiales sur les lignes du Foyer, `LigneRubrique(meneur:)`) et B-3 (ajout de profil sans cloche de coquille, `PageShell(actionsCoquille: false)` et `RangeeEtape`). LB-1, LB-2 et LB-F passent a « fait ». Restent hors lot : B-2 (tri `service_appairage.dart`) et, pour B-4, les liens des lots C et E (la redirection C6 `/tuteur/reglages` -> `/tuteur/foyer` est livree par COORD dans `app_router.dart`, verifiee par `test/features/reglages_enfant_test.dart` a `be96493`).

## 1. Ecrans livres et statut

| Ecran | Route | Fichier | Statut |
|---|---|---|---|
| Foyer | `/tuteur/foyer` | `lib/features/foyer/foyer_page.dart`, `ligne_membre.dart` | UI realisee ; branchee au service existant (`profils_du_foyer_v` via K1 `profilsElevesFoyerProvider`) ; classes : port K6 sans service en production, dependance **DB-TRV-07** (phrase honnete) ; inscription en cours : `v_parcours_onboarding` (0043) non appliquee en production, dependance **DB-ADM-01** (phrase honnete) ; testee (vrai routeur). **Partiel** : avatar ou initiale (B-1). |
| Creer mon profil eleve | `/tuteur/foyer/ajouter?pour=moi` | `creer_mon_profil_indisponible.dart` | Etat indisponible honnete, dependance **DB-FOY-01** ; teste. |
| Ajout de profil | `/tuteur/foyer/ajouter` | `formulaire_profil_eleve.dart` (K3), `lib/features/appareils/ajouter_enfant_page.dart` | Branchee (`CreationProfilEleveAppairage` -> Edge `creer-profil-enfant`) ; testee en simulation ; dependances **DB-FOY-01**, **DB-FOY-02**, **DB-FOY-06**, **DB-ADM-04**, **DB-ADM-05**. **Partiel** : pas plein ecran (B-3). |
| Fiche eleve | `/tuteur/foyer/:eleveId` | `fiche_eleve_page.dart` | Branchee (K1, K6) ; testee. |
| Informations | `.../informations` | `fiche/informations_page.dart`, `photo_eleve.dart` | Branchee (`ServiceAvatar.televerser`, `majReglages(cleAvatar:)`) ; testee en simulation ; **DB-FOY-07** (prenom), **DB-ADM-05** (age). |
| Parcours et inscription | `.../inscription` | `fiche/inscription_page.dart` | Synthese branchee ; **DB-ADM-01**, **DB-TRV-07**. |
| Interface | `.../interface` | `fiche/interface_page.dart` | Branchee (`majReglages(mode:)`) ; **DB-FOY-04** ; testee. |
| Camera en cours | `.../camera` | `fiche/camera_page.dart` | Branchee (`majReglages(camera:)`) ; testee. |
| Acces Rewayah | `.../acces` | `fiche/acces_page.dart` | Branchee (`access_until`, K6 `etatAccesAffiche`) ; **DB-FOY-05** ; testee. |
| Reglages par profil eleve (ancienne TUT-05) | `/tuteur/reglages` | `lib/features/reglages_enfant/reglages_enfant_page.dart` | Contenu deplace vers la fiche (LB-F) : il ne reste qu'un renvoi par eleve vers la fiche, plus les demandes a l'administration. La redirection de la route vers `/tuteur/foyer` revient au coordinateur (C6, demande B-4). |

Aucun STUB « propriete du lot B » ne subsiste (recherche `STUB PHASE 0` dans `lib/` a `f258944` : lots A, C, C-obs, D et E seulement).

## 2. Carte des fonctions (tout le lot)

| Fonction | Ecran unique | Route | Place dans la reference |
|---|---|---|---|
| Ouvrir le Foyer | barre de navigation (Foyer, 2e destination) | `/tuteur/foyer` | onglet Foyer (maquettes Compte, nav : Accueil, Foyer, Historique, Compte) |
| Ajouter un profil eleve (entree) | Foyer, en-tete | `/tuteur/foyer/ajouter` | ancienne capture Foyer Member : action a droite du titre. Sur bureau, elle est a droite du titre. Sur telephone, elle est juste sous le titre, en pleine largeur avec fleche : a 358 de large, le titre, la cloche et le libelle complet ne tiennent pas sur une ligne. Ecart assume. L'Accueil (lot C), le Compte (lot E) et la fin d'admission (lot A) ouvrent la meme route, sans copie. |
| Ouvrir la fiche d'un eleve | Foyer, ligne du membre (groupe « Profils eleves ») | `/tuteur/foyer/:eleveId` | ancienne capture Foyer Member : carte de l'enfant (« Gerer ») ; ici, la ligne entiere avec chevron, dans UN groupe a filets (lignes de Mon compte) |
| Relire les classes | Foyer, sous le groupe (seulement apres un echec) | `/tuteur/foyer` | pas de reference, etat derive |
| Reessayer (lecture du foyer) | Foyer, bloc d'erreur ou hors ligne | `/tuteur/foyer` | etat derive (`EtatSysteme`) |
| Appareils partages | Foyer, groupe « Appareils partages », ligne « Appareils du foyer » | `/tuteur/foyer/appareils` (ecran du lot D) | ancienne capture Foyer Member : section « Appareil familial » sous les enfants |
| Creer mon profil eleve | Foyer, lien discret en bas ; raccourci du Compte (lot E) vers la meme route | `/tuteur/foyer/ajouter?pour=moi` | mandat §4 (raccourci prevu depuis Foyer ET Compte, meme flux) ; ligne de Mon compte cote lot E |
| Choisir pour qui (enfant ou mineur ; proche adulte et moi-meme indisponibles et expliques) | ajout, etape 1 | `/tuteur/foyer/ajouter` | planche V6 E1 (cartes empilees) |
| Prenom, nom, age ; Creer le profil | ajout, etape 2 | idem | planche V6 E3 (champs, pilule en bas) |
| Reponse perdue : voir le foyer ou reessayer | ajout, etape 2 | idem, puis `/tuteur/foyer` | etat derive |
| Enchainement vers la fiche | apres creation | `/tuteur/foyer/:eleveId` | - |
| Identite (photo ou initiales, prenom, classe connue) | fiche, carte d'identite | `/tuteur/foyer/:eleveId` | ancienne capture Profil (en-tete) ; rendu carte identite du Compte (FD) |
| Informations et photo (choisir, apercu, envoyer, reprendre, annuler) | fiche -> Informations | `.../informations` | 1re ligne des parametres ; « Changer la photo » ici seulement |
| Parcours et inscription (questionnaire -> lot A ; classe ou catalogue -> lot C) | fiche -> synthese | `.../inscription`, puis `/tuteur/parcours/:eleveId`, `/tuteur/classes/:id?eleve=` ou `/tuteur/classes/catalogue?eleve=` | 2e ligne |
| Relire la classe | synthese, colonne annexe (seulement apres un echec) | `.../inscription` | etat derive |
| Interface guidee ou standard | fiche -> Interface | `.../interface` | 3e ligne ; cartes a radio (Apparence du Compte) |
| Camera en cours | fiche -> Camera | `.../camera` | 4e ligne ; interrupteur (Confort visuel) |
| Acces Rewayah | fiche -> Acces | `.../acces` | 5e ligne ; carte « Abonnement et acces » de Mon compte : medaillon, titre, echeance, pastille, UN rectangle |
| Appareils de l'eleve | fiche, groupe « Appareils » | `/tuteur/foyer/:eleveId/appareils` (ecran du lot D, aucun import) | colonne droite sur bureau |
| Retour | chaque ecran de niveau 2 et chaque tache focalisee | fiche -> Foyer ; sous-page -> fiche ; ajout -> Foyer | disque retour 48 |
| Solde par eleve | place reservee, rien construit | - | ligne ou groupe sous les appareils (03 §1 ter-9) |
| Demandes a l'administration (reaffectation, duree, minimum payable) | Reglages par profil eleve | `/tuteur/reglages` | hors mandat B (TUT-05 historique), inchange |
| Renvoi photo, camera et interface vers la fiche | Reglages par profil eleve | `/tuteur/reglages` -> `/tuteur/foyer/:eleveId` | un renvoi, pas une copie ; disparait avec la redirection C6 |

Doublons : aucun dans les fichiers du lot B depuis `f258944`. Il reste deux liens actifs vers `/tuteur/reglages`, hors lot B : `accueil_famille_page.dart:458` (lot C) et `compte_page.dart:626` (lot E). Ils ne menent plus qu'aux demandes et au renvoi vers la fiche (voir B-4).

## 3. Etats par ecran

- Foyer : chargement (squelette), contenu, vide (phrase honnete), erreur (Reessayer relit), hors ligne. Classes sans service : une phrase. Classes en echec (service present) : « Classe non lue » sur la ligne, une phrase et « Relire les classes ». Inscription illisible : une phrase. Sans classe mais etape connue : l'etape (« A remplir », « Classe en cours de constitution »...).
- Ajout : session en chargement (squelette), session illisible (erreur et relecture), session hors ligne (hors ligne), compte non actif (raison DB-ADM-04), vierge, erreurs sous les champs, envoi en cours, refus serveur, reponse perdue, hors ligne a l'envoi.
- Fiche et sous-pages : chargement, contenu, erreur, hors ligne, introuvable. Camera et Interface : hors ligne (controle inactif et phrase), echec d'ecriture dit, aucun etat optimiste. Photo : trop lourde, echec du selecteur (nouvel etat, `ficheEleve.informations.selectionEchec`), echec d'envoi, echec d'enregistrement, hors ligne.
- Tri : aucun `.order(...)` n'est ecrit par le lot. Lectures consommees : `profils_du_foyer_v` (tri client K1), `v_parcours_onboarding` (tri sans effet, recherche par id). Les tris sans sens releves (B-2 `service_appairage.dart:212`, `service_offres.dart:115,125`) ne sont pas consommes par les ecrans du lot.

## 4. Tests lances (sous verrou, poste B, 24/09 soir) et resultats exacts

- `flutter test test/features/foyer test/features/reglages_enfant_test.dart` : **+120 ~35 All tests passed!** (les 35 sautes sont les captures sans `CAPTURE_DIR`). Nouveaux tests : `test/features/foyer/accessibilite_foyer_test.dart` (Foyer, Creer mon profil, Ajout, fiche x2, cinq sous-pages : 200 %, RTL, RTL a 200 % a 390x844, sans exception ; `androidTapTargetGuideline` et `textContrastGuideline` sur Foyer et fiche, clair et sombre) ; classes en echec et relecture (Foyer, synthese) ; inscription en cours et inscription illisible ; CTA avec fleche ; camera et interface hors ligne (aucun `majReglages`) ; selecteur de photo qui leve ; carte Acces a medaillon ; porte en chargement, illisible et hors ligne ; renvoi des reglages touche sur le vrai routeur jusqu'a `FicheElevePage`.
- Non-regression `flutter test test/router test/accessibilite test/features/accueil_famille_test.dart test/features/observation_groupe_admin_test.dart test/features/appareils_test.dart test/i18n test/config test/foyer test/features/compte_test.dart` : **+401 All tests passed!**
- `dart analyze --fatal-infos lib/features/foyer lib/features/reglages_enfant lib/features/appareils/ajouter_enfant_page.dart test/features/foyer test/features/reglages_enfant_test.dart` : **No issues found!**
- `dart run tool/verifier_jetons.dart` : **Jetons verifies : 421 fichiers, aucune violation.**
- `dart run slang` : regenere, genere committe dans `f258944`.
- `graphe_imports.ps1 -Repo C:\RA\lot-b -Ref f258944` : `foyer_page`, `ligne_membre`, `creer_mon_profil_indisponible`, `formulaire_profil_eleve`, `fiche_eleve_page`, `photo_eleve`, `fiche/{acces,camera,informations,inscription,interface}_page`, `reglages_enfant_page`, `ajouter_enfant_page`, `service_avatar` sont **atteignables** depuis `lib/main.dart`. Aucun fichier du lot B parmi les non-atteignables.
- Frontiere `git diff --stat origin/ui/tuteur-v1...HEAD -- supabase .github vercel.json pubspec.yaml lib/core/theme lib/core/router lib/core/widgets` : **vide**.

## 5. Captures et planches

`captures/` (390x844@3 et 1440x900@1, clair et sombre), regenerees a `f258944` pour le Foyer et la fiche : `foyer_*` (contenu, vide, chargement, erreur, hors ligne, classes indisponibles, **desormais aussi en 1440x900**, creer mon profil, rail 1024x768), `fiche_*` (fiche, informations, apercu, inscription, inscription avec classes indisponibles, interface, camera, acces a medaillon, chargement, erreur, hors ligne, introuvable), `ajout_*` (LB-2, inchanges : la mise en page de l'ajout n'a pas change). Planches : `foyer_mobile_contre_ancienne_capture`, `foyer_mobile_contre_compte_mobile`, `foyer_bureau_contre_compte_bureau`, `fiche_mobile_contre_profil`, `fiche_mobile_contre_compte_mobile`, `fiche_bureau_contre_compte_bureau`, `ajout_pour_qui_contre_E1`, `ajout_identite_contre_E3`. Il n'existe aucune maquette haute fidelite du Foyer ni de la fiche (C04 §0, manifeste §2). Les planches comparent au contenu des anciennes captures et au rendu de Mon compte.

Ecarts restants (a `7ebbd03`) : action d'ajout sous le titre sur telephone (justifiee au §2). Leves a `7ebbd03` : avatar (B-1) et cloche de l'ajout (B-3), voir §9. Les planches `*_contre_*` datent du 24/09 (avant migration) : les tests de planche sont sautes faute de maquette de reference chargee ; la preuve a jour est dans les captures simples regenerees le 25/09.

## 6. Demandes au coordinateur (`demandes/B.md`)

- **B-1** (levee a `7ebbd03`, meneur livre par COORD et utilise) : `LigneRubrique` avec un `Widget? meneur` dans `lib/core/widgets/groupe_reglages.dart`, pour l'avatar ou l'initiale. Un seul appel a changer ensuite, dans `ligne_membre.dart`.
- **B-2** (ouverte) : `service_appairage.dart:212` `.order('paired_at')` sans `ascending`.
- **B-3** (levee a `7ebbd03`, `actionsCoquille: false`, `RangeeEtape`, `OptionChoix` utilises ; `CarteChoixFoyer` supprimee) : gabarit d'etape plein ecran (`page_shell.dart`) et `ChoiceCardGroup` avec description et option indisponible. Correction faite : `CarteChoixFoyer` est publique et a deux usages, le formulaire K3 et `fiche/interface_page.dart`.
- **B-4** (ouverte, partie lot B faite) : redirection C6 de `/tuteur/reglages`, a faire par COORD, et retrait des liens des lots C et E.

## 7. Defauts hors perimetre consignes

Dans `etat/B.md` : `service_offres.dart:115,125` `.order('ordre')` sans sens (lot A) ; libelles `parcours.etatGroupe*` qui affichent « Groupe » (lot A) ; BOM en tete du sujet du commit `d7b006f` ; cles `tuteur.reglages.photo*`, `camera*`, `mode*` (espace du lot du Compte) devenues inutilisees apres LB-F, a retirer par leur proprietaire.

## 8. Suite donnee a chaque constat de `REVUE.md`

| # | Gravite | Constat | Suite |
|---|---|---|---|
| 1 | majeur | Pas de RAPPORT.md ni de carte des fonctions du Foyer | **Corrige** : ce rapport, carte unique §2 (Appareils partages, Creer mon profil eleve, Ajouter un profil eleve, Ouvrir la fiche, Relire, Reessayer compris). |
| 2 | majeur | Pas d'avatar ni d'initiale sur les lignes du Foyer | **Corrige a `7ebbd03`** : `ligne_membre.dart` pose `LigneRubrique(meneur: PhotoEleve(...))`, photo signee ou initiales. Capture `foyer_contenu_390x844@3_light.png` (25/09 04:54) : disque d'initiales devant chaque profil. LB-1 fait. |
| 3 | majeur | Ajout de profil pas plein ecran (cloche au-dessus de la rangee d'etape) | **Corrige a `7ebbd03`** : `PageShell(actionsCoquille: false)` et `RangeeEtape` partagee en tete. Capture `ajout_pourQuiVierge_390x844@3_light.png` (25/09 04:54) : la rangee d'etape (retour, progression, « 1 sur 2 ») ouvre l'ecran, plus de cloche. LB-2 fait. |
| 4 | mineur | CTA « Ajouter un profil eleve » sans fleche, sous le titre sur telephone | **Corrige** : `fleche: true` (`foyer_page.dart`), teste. Place sur telephone justifiee au §2. |
| 5 | mineur | Acces sans medaillon | **Corrige** : carte a medaillon, titre, echeance et pastille, en UN rectangle (`fiche/acces_page.dart`), teste, capture `fiche_acces_*`. |
| 6 | mineur | Photo, camera et interface en double (`/tuteur/reglages`) | **Corrige pour le lot B**, voir constat 15 ; redirection COORD et liens C et E : B-4 ouverte. |
| 7 | mineur | Formulaire sans etat de chargement ; raison « dossier » fausse | **Corrige** : `porteAjoutProfilProvider` rend `null` pour une session illisible. Chargement : squelette ; illisible : erreur et relecture ; hors ligne : etat hors ligne. `enfantAttente` n'est plus montre que pour une porte ou le serveur refuse (attente ou suspendu). Un test par porte. |
| 8 | mineur | Echec de lecture des classes confondu avec chargement ou indisponible | **Corrige** : `ClasseMembre.echec`, « Classe non lue », phrase et « Relire les classes » (Foyer), « La classe n'a pas pu etre lue. » et « Relire la classe » (synthese). Tests Foyer et fiche. |
| 9 | mineur | Camera et Interface actives hors ligne | **Corrige** : `horsLigneProvider` lu, controles inactifs et phrase hors ligne. Tests par geste. |
| 10 | mineur | Erreurs du selecteur de photo non attrapees | **Corrige** : try/catch et `ficheEleve.informations.selectionEchec`, affiche au repos comme a l'apercu. Test avec un selecteur qui leve. |
| 11 | mineur | `enfant.aucun` et `enfant.aucunDetail` non revus | **Corrige** : « Aucun profil eleve dans le foyer », « Ajoutez d'abord un profil eleve depuis le Foyer. ». Slang regenere. Ligne « hors perimetre » de `etat/B.md` levee. |
| 12 | mineur | Preuves LB-1 manquantes ; classes indisponibles sans 1440x900 | **Corrige** : ce rapport, et captures `foyer_classes_indisponibles_1440x900@1_{light,dark}.png`. |
| 13 | mineur | Pas d'inscription en cours sur la ligne du membre | **Corrige** : sans classe connue, l'etape lue dans `parcoursFoyerProvider` (`libelleEtapeFiche`, deplacee dans `ligne_membre.dart` pour etre partagee) ; phrase si la lecture echoue. Tests unitaires et widget. |
| 14 | mineur | B-3 dit la carte de choix privee | **Corrige** dans `demandes/B.md`. |
| 15 | majeur | Doublon dans `reglages_enfant_page.dart` (fichier du lot B) | **Corrige** : photo, camera, interface et identifiant interne retires. Un renvoi par eleve vers la fiche, touche par un test sur le vrai routeur. `test/features/reglages_enfant_test.dart` est adapte. LB-3 reste « fait », avec preuve `f258944`. |
| 16 | mineur | Aucune preuve 200 % ou RTL, cibles et contraste | **Corrige** : `test/features/foyer/accessibilite_foyer_test.dart` (voir §4). |
| 17 | mineur | Hors ligne des pages d'ecriture non teste | **Corrige** avec le constat 9 : aucun `majReglages` hors ligne, verifie par geste. |
| 18 | mineur | LB-1 sans rapport ni carte | **Corrige** avec le constat 1. |

## 9. Fusion 1cbc760 et migration

Fusion `origin/ui/tuteur-v1` (`1cbc760`) dans `ui/tuteur-v1-b` : `1d5e383` (conflits uniquement dans `strings*.g.dart`, JSON fusionne sans conflit, regenere par `dart run slang` sous verrou). Migration API COORD (`7ebbd03`) : `ligne_membre.dart` utilise `LigneRubrique(meneur: PhotoEleve(...))` (repli initiales) a la place de `AppIcons.profil` ; `formulaire_profil_eleve.dart` passe par `PageShell(actionsCoquille: false)` avec la `RangeeEtape` partagee en en-tete (PageEtape non retenue, elle borne l'en-tete) et `ChoiceCardGroup(autoriserSaisieLibre: false)` avec `OptionChoix` description/disponible/raisonIndisponible pour le choix « pour qui » ; `interface_page.dart` utilise `ChoiceCardGroup` avec cle (mode, generation) pour que la carte retenue soit toujours celle relue du serveur.

Verifications a `7ebbd03` :
- Captures regenerees dans `05_recette/B/captures/` (390x844@3 et 1440x900@1, clair et sombre) : Foyer, fiche eleve, ajout de profil. Planches existantes (`foyer_*_contre_*`, `fiche_*_contre_*`, `ajout_*_contre_*`) relues : les planches `*_contre_*` n'ont pas ete regenerees (tests sautes, pas de maquette de reference chargee) et montrent encore l'etat du 24/09. Rectification (tache 3/3) : les captures simples du 25/09 montrent B-1 et B-3 leves (initiales sur les lignes du Foyer, plus de cloche sur l'ajout) ; la phrase precedente de ce paragraphe, qui les disait identiques, reposait sur les planches perimees.
- `flutter test test/features/foyer/foyer_capture_test.dart test/features/foyer/fiche_eleve_capture_test.dart test/features/foyer/formulaire_profil_eleve_capture_test.dart` : **+29 ~8, All tests passed!** (les 8 sautes sont les planches sans maquette de reference disponible).
- `dart run tool/verifier_jetons.dart` : **Jetons verifies : 427 fichiers, aucune violation.**
- Frontiere `git diff --stat origin/ui/tuteur-v1...HEAD -- supabase .github vercel.json pubspec.yaml lib/core/theme lib/core/router lib/core/widgets` : **vide**.
- `graphe_imports.ps1 -Repo C:\RA\lot-b -Ref 7ebbd03` : 369 fichiers `lib/` atteignables depuis `lib/main.dart`, 62 non atteignables. Aucun fichier de l'espace Foyer/fiche du lot B parmi les non atteignables. `lib/features/reglages_enfant/reglages_enfant_page.dart` reste non atteignable (aucune route ne le cite, seuls des tests) : deja connu, lie a B-4 (redirection COORD encore ouverte, cf §6 et §8 constat 15), pas une regression de cette fusion.

### Tache 3/3 (`be96493`)

Constats de `REVUE.md` : aucun bloquant ; les majeurs R-02 et R-03 (constats 2 et 3 du §8) sont leves a `7ebbd03`, prouves par les captures du 25/09. La fusion apporte la redirection C6 : le test du vrai routeur de `reglages_enfant_test.dart` (tap du renvoi vers la fiche) echouait, la page n'etant plus atteinte ; il verifie desormais que `/tuteur/reglages` mene au Foyer (`be96493`). `dart analyze` cible : No issues found. `flutter test test/features/foyer test/features/reglages_enfant_test.dart` : **+120 ~37, All tests passed!**
