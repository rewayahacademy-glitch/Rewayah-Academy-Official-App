# Revue croisée DASH-ENS-LISTES-R : remplacements et alertes de la Journée ont leur adresse

- **Objet revu** : `corrections/c2-ens-listes` @ `cd0f5988` (base `66cf818f`, tête de `c2-ens-route`), 2 commits, 26 fichiers (+918 −59), dont 18 captures et le script de capture.
- **Relecteur** : session cloud `01KyPAZg`. Elle n'a pas écrit DASH-ENS-LISTES (auteur : `b061fd81`).
- **Date** : 4 octobre 2026.
- **Références** : DASH_STRATEGIE §5 (lignes DASH-ENS-REMPL et DASH-ENS-ALERTES), D6, D10 ; `lib/CLAUDE.md`.
- **Méthode** :
  - lecture du diff ;
  - contrôles relancés sur le worktree `/home/user/rv-ens-listes` ;
  - deux mutations ciblées, remises en place (`git status` propre à la fin) ;
  - trois captures ouvertes ;
  - fusion à blanc sur `corrections/revue-directeur-2026-10`.

## Verdict

**Acceptée avec réserves.** Les deux lignes de la fiche sont tenues. La Journée montre trois remplacements au plus, les plus proches d'abord, et « Voir tout » sous le troisième. Les alertes de présence au-delà de deux deviennent un lien « Voir les N autres alertes ». Les deux pages ont leur adresse, leurs états, et le retour vers la Journée. Le reste de la Journée est inchangé. Trois remarques mineures ne bloquent rien.

## Contrôles relancés (chiffres mesurés)

| Contrôle | Résultat |
| :--- | :--- |
| `dart run slang`, `build_runner build` | OK |
| `dart analyze --fatal-infos` | **0 problème** |
| `dart run tool/verifier_jetons.dart \| grep -c "\["` | **39**, le chiffre attendu |
| `test/router/parcours_enseignant_test.dart` | **32 réussis, 0 échec** (dont 15 du groupe DASH-ENS-LISTES) |
| Écrans voisins : `journee_test`, `enseignant_recette`, `demo_enseignant_page_test`, `rtl_echelle_texte_ecrans_test`, `mes_classes_test`, `q01_pii_projection_enseignant_test` (avec le précédent) | **193 réussis, 0 échec**, 233 sautés (tests de capture et de recette gardés par drapeau, déjà sautés avant) |
| Mutation 1 : tri des remplacements neutralisé, et lien des alertes jamais affiché | **3 échecs** : « 3 remplacements sur 5, les plus proches », « Voir tout ouvre l'adresse, tous » (ordre), « 2 alertes et un lien vers les 3 autres » |
| Mutation 2 : présence illisible traitée comme une liste vide sur la page des alertes | **1 échec** : « présence illisible : jamais aucune alerte (J3, D10) » |
| Fusion à blanc sur `revue-directeur-2026-10` | **1 conflit** : `tool/libelles_sources.json`, ajouts en fin d'objet JSON des deux côtés. Le même conflit existe déjà pour `c2-ens-route` seule. Résolution triviale : garder les deux blocs, une virgule entre eux |

## Points de la fiche un par un

1. **Trois remplacements, puis « Voir tout »** ✅. `journee_page.dart` : `maximumRemplacements = 3`, `trierRemplacements` (tri par début), `_cartesRemplacements` ajoute `_AvecVoirTousRemplacements` à la troisième carte seulement si la liste dépasse trois. Tests « 3 sur 5 les plus proches » et « trois ou moins : aucun lien ». Le lien est frère de la carte, pas dedans : pas de bouton dans un bouton. Le libellé sémantique dit « Voir les N remplacements confirmés ».
2. **Lien des alertes (D6 b levée)** ✅. `_AlertesUtiles` reçoit `autres` et affiche un `LienFleche` vers `Routes.enseignantAlertes`. L'ancienne phrase sans lien « et N autres élèves » n'est plus produite. La page des alertes liste les cinq absences du test.
3. **États des deux pages** ✅.
   - Remplacements : contenu et vide ; hors ligne par `PageShell`. Pas de chargement ni d'erreur : la source (`remplacementsConfirmesProvider`) est synchrone, ce que la doc de la classe dit. Choix défendable.
   - Alertes : chargement (`Skeleton.liste`), erreur séances avec « Réessayer » qui relit (test : 2 lectures), erreur présence (jamais « aucune alerte »), vide, contenu ; hors ligne par `PageShell`.
4. **Tests sur le vrai routeur** ✅. Le groupe monte `Routes.enseignantJournee`, `enseignantRemplacements`, `enseignantAlertes` par `monter` (routeur réel), vérifie `matchedLocation`, l'ouverture directe et le retour par `DisqueRetour`. Trois tests 320 px, texte ×2, sans mot coupé ni exception.
5. **Captures K-61** ✅. 18 PNG dans `docs/current/captures/DASH-ENS-LISTES`, script fourni en `.txt`.
6. **Accord au féminin des alertes** ✅. « Voir l'autre alerte » au singulier, « Voir les {nombre} autres alertes » au pluriel.
7. **La journée entière reste affichée** ✅. Séance en direct, remplacements, Ma journée, Alertes utiles : tout est là sur la capture 390 clair. Seules les listes au-delà du seuil sont coupées.

## Règles du projet

- Textes : 7 clés ajoutées dans `fr.i18n.json` et sourcées dans `tool/libelles_sources.json`. Aucun texte en dur.
- Couleurs et valeurs : composants existants seulement (`LienFleche`, `PileCartes`, `EmptyState`, `EtatSysteme`, `Ecart`). Jetons : 39, inchangé.
- Un seul bouton plein : « Rejoindre la salle » sur la Journée ; aucun sur les deux listes.
- RTL : `AlignmentDirectional.centerEnd` et `alignerEnFin` pour les liens.
- Aucun rôle lu dans les widgets. Aucun composant partagé modifié (seule `journee_page.dart` change côté écran).

## Captures ouvertes

- `journee_contenu_390_clair.png` : séance en direct, trois remplacements (29 sept., 30 sept., 1er oct.), « Voir tout » aligné à droite sous le troisième, Ma journée, deux alertes puis « Voir les 3 autres alertes ». Lisible, rien de coupé.
- `alertes_contenu_320x2_sombre.png` : titre « Alertes utiles » sur deux lignes à côté du disque retour, cinq alertes, les mots entiers. Contraste correct en sombre.
- `remplacements_contenu_320x2_clair.png` : titre « Remplacements confirmés », cinq cartes dans l'ordre chronologique, aucun mot coupé, un bouton contour « Voir la Classe » par carte.

## Défauts retenus

Aucun majeur.

Mineurs :

1. **Clé morte** : `enseignant.journee.autresAbsences` (« et {nombre} autres élèves. ») n'est plus utilisée dans `lib/`, mais reste dans `assets/i18n/fr.i18n.json:3073` et le code généré. À supprimer.
2. **Singulier non testé** : aucun test ne monte trois alertes pour vérifier « Voir l'autre alerte ». La branche `autres == 1` n'est couverte par rien.
3. **« Voir tout » emprunté au tuteur** : le lien des remplacements lit `t.tuteur.accueil.voirTout`. Le texte est juste, mais l'espace de noms ne l'est pas ; une clé partagée (ou `enseignant.journee.voirTout`) serait plus propre.

Remarque hors périmètre (préexistante, non imputée à l'étape) : la phrase d'absence « Yasmine n'est pas entré en salle » ne s'accorde pas au féminin. Elle vient de `absenceDetectee`, déjà présente avant la base.

## Pour accepter

- Fusionner `c2-ens-listes` après `c2-ens-route`, en résolvant `tool/libelles_sources.json` par l'union des deux blocs.
- Dans une correction légère (ou au lot DASH-LIB) : retirer `autresAbsences`, ajouter un test « trois alertes : Voir l'autre alerte », et donner au « Voir tout » une clé hors `tuteur`.

## Contre-verification

Sceptique independant, session `01KyPAZg`, non auteur. Meme worktree, meme tete `cd0f5988`.

**Majeurs de la premiere revue** : aucun. Il n'y a rien a refuter.

**Recherche d'un majeur oublie** :

- Bouton dans un bouton : non. La tuile Bento n'est pas appuyable. « Voir tout » est frere de l'`AppCard`, pas dedans (`journee_page.dart:380`). Le lien des alertes est pose sous le `GroupeReglages`, hors des lignes (`journee_page.dart:1344`).
- Mot coupe a 320 x2 : non. Capture `journee_contenu_320x2_clair.png` ouverte : « Voir tout » et « Voir les 3 autres alertes » passent sur deux lignes, mots entiers. Trois tests 320 x2 du groupe le verifient aussi.
- 1440 : capture `journee_contenu_1440_clair.png` ouverte. Trois remplacements, « Voir tout » sous Al-Kawthar, deux alertes, puis le lien. Rien ne deborde.
- Etats : les deux pages ont les leurs (remplacements synchrones, alertes avec chargement, erreur, vide, contenu). Le hors ligne vient de `PageShell`. Rien ne manque.
- Un seul bouton plein : sur la page des alertes, les offres sont des `LigneRubrique`, pas des boutons pleins. Le « Reessayer » partiel n'y est pas passe. Rien a redire.
- Composant partage modifie : aucun. `_AlertesUtiles` est prive a `journee_page.dart`. Son nouveau parametre `entete` vaut vrai par defaut, donc la Journee ne change pas.
- Texte en dur : aucun.

**Mineurs** :

1. Cle morte `autresAbsences` : **confirme**. Seule occurrence hors code genere : `assets/i18n/fr.i18n.json:3073`.
2. Singulier non teste : **confirme par mutation**. J'ai remplace « Voir l'autre alerte » par « Voir les 1 autres alertes ». Resultat de `parcours_enseignant_test.dart` : 32 reussis, 0 echec. Aucun test ne voit la difference. Fichier remis en place.
3. « Voir tout » emprunte au tuteur : **confirme, mais nuance**. Ce n'est pas nouveau. `ListeATerminer` le fait deja (`journee_page.dart:980`, avant cette etape). L'etape suit une habitude existante. A corriger au lot DASH-LIB pour les deux endroits.

**Nouveau** : aucun majeur, aucun mineur nouveau.

**Verdict final** : **Acceptee avec reserves**, inchange. `git status` propre a la fin.

## Fusion d'essai des douze branches CORR-2 (relu par 01KyPAZg)

Branche locale `integ-c2-essai`, jamais poussée, sur `corrections/revue-directeur-2026-10` @ f6ac3658. Ordre : elv-err, bento3b, ea-prod, tuile-tuteur, obs-coupe, coupe2, ens-route, ens-listes, ma-prod, tut-cta, adm-echus, hors-ligne.

- Conflits : chaînes i18n et `libelles_sources.json` (triviaux, régénérés par `dart run slang`) ; routeur `/eleve` entre DASH-EA-PROD et DASH-MA-PROD, composable : la redirection adulte d'EA-PROD (`redirectionAccueilEleve(capaciteAccueilAdulte: …)`) est gardée, le constructeur devient `AccueilEleveSelonPresentation` de MA-PROD, suivi de `...routesAccueilAdulte()`.
- Mesures sur la fusion (df122065) : `dart analyze --fatal-infos` 0 problème ; jetons 39 ; suite dossier par dossier 5573 réussis, 0 échec (27 dossiers ; captures ignorées 657).
