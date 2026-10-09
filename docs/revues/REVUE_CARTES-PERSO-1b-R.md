<!-- verdict : ACCEPTEE_AVEC_RESERVES -->
# Relecture adverse : CARTES-PERSO-1b (branche `corrections/c2-cartes-perso-b` @ f09b653a)

**Verdict : ACCEPTÉE AVEC RÉSERVES.** Les quatre points de la deuxième relecture refusée sont levés. Chaque correction est prouvée par un test qui échoue quand on l'annule. Il reste deux réserves mineures, sans aucun défaut majeur.

Statut de preuve : testé localement dans un worktree jetable détaché sur `origin/corrections/c2-cartes-perso-b`, puis retiré. Pas testé sur staging, rien de déployé. Je n'ai rien poussé.

## Vérifications générales
- `dart analyze --fatal-infos` : aucun problème.
- `tool/verifier_jetons.dart` : 39 violations, aucune dans les fichiers touchés.
- `tool/verifier_revue.dart` : 1567 violations (la base en compte 1568 selon le rédacteur), aucune dans les fichiers touchés.
- Tests lancés avec `--concurrency=2` :
  - `test/features/tc_espace_groupe`, `test/features/demo`, `test/features/classe_tuteur` : 281 réussis, 0 échec ;
  - `test/features`, `test/router`, `test/accessibilite` : **+3533, 0 échec**, ce qui couvre les autres appelants de `BlocCartesClasse` : `EspaceGroupePage`, `FicheGroupePage`, `MaClasseAdultePage`, `ClasseTuteurPage`.
- Périmètre : aucun fichier touché sous `supabase/`, `.github/`, `pubspec.yaml`, `vercel.json`, thème ou Coran. Aucune clé i18n ajoutée.
- Commits : en français, avec les deux lignes de fin exactes, et aucun identifiant de modèle ailleurs.

## Point 1 (MAJEUR) : vraie démonstration tuteur
- **Correction :** `surchargesDemoTuteur` surcharge `portCartesClasseProvider` avec `PortCartesClasseDemo(peutModifier: false, cartes: cartesClasseDemo(...))`. Le tuteur lit donc les mêmes cartes que la démonstration enseignant, en lecture seule.
- **Le test monte la vraie démonstration :** `test/features/demo/demo_tuteur_cartes_test.dart` monte la vraie `RacineDemonstrable`. Il passe par l'entrée, la carte de l'Accueil, puis `ClasseTuteurPage`. Il n'injecte aucune surcharge de cartes : seuls le stockage et l'horloge sont surchargés.
- **Ce que le test vérifie :**
  - les titres et leur ordre sont identiques à ceux de `cartesClasseDemo` ;
  - `onModifier` est nul et le bouton « Ajouter » est absent ;
  - toucher une carte n'ouvre aucune feuille.
- **Mutation :** j'ai supprimé la surcharge. Le test échoue et trouve « Les cartes de la classe ne sont pas encore… ».
- **Élève et adulte :** ces démonstrations passent déjà par `surchargesEleveDemo` puis `surchargesCartesClasseDemo` (`demo_classe_page.dart:287`, `demo_adulte_page.dart:850/865`).
- **Capture :** `demo_tuteur_classe_390_clair.png`, ouverte. On y voit les 3 cartes, Devoir avec l'icône livre et Lien utile avec l'icône fichier, ainsi que « Copier le lien de « Récitation modèle » ».

## Point 2 : sens de lecture en RTL
- **Ce qui est isolé :**
  - `helperText` : les deux `aideLongueur` et `aideLien` ;
  - `errorText` : `_erreur` renvoie maintenant `isolerSens(messageDefaut)`, donc l'isolement de l'échéance a été retiré pour ne pas l'appliquer deux fois ;
  - les descriptions du `ChoiceCardGroup` ;
  - le titre de la feuille, avec le titre de la carte isolé dedans ;
  - la question et la conséquence du retrait.
- **Sens des champs :** les champs titre et texte suivent leur première lettre (`sensDeLaSaisie`). Le champ lien est forcé de gauche à droite.
- **Mutations :** j'ai retiré l'isolement, l'un après l'autre :
  - descriptions : un test échoue (« feuille, rtl : aides, erreurs et descriptions des modèles isolées ») ;
  - `aideLien` : le même test échoue ;
  - erreurs : 3 tests échouent ;
  - phrase de contexte de la feuille : 2 tests échouent.
- **Captures ouvertes :**
  - `feuille_320x2_ar_rtl_clair` : le point reste à la fin de la phrase de contexte, des descriptions et des erreurs, et aucun mot n'est coupé ;
  - `feuille_320x2_fr_ltr_clair` ;
  - `bloc_enseignant_320x2_ar_rtl_sombre` : « …familles la voient aussitôt. », avec le point à la fin ;
  - `bloc_famille_320x2_ar_rtl_clair` ;
  - `page_enseignant_feuille_390_ar_rtl_clair`.

## Point 3 : lectureHorsLigne
- **Test :** un port réussit sa première lecture, puis échoue après invalidation, hors ligne.
- **Mutation :** j'ai remplacé `lectureHorsLigne(...)` par la lecture directe du provider. Le test échoue.

## Point 4 : pictogrammes
- **Correction :** le lien utile prend `AppIcons.supports`, le devoir garde `AppIcons.lecon`. Aucune icône n'est ajoutée au jeu gelé.
- **Mutation :** j'ai remis `AppIcons.livreOuvert` sur le lien. Le test « chaque modèle a son pictogramme » échoue.

## Décision CARTES
Le paragraphe de reprise de la fiche CLS-CARTES (`DASH_STRATEGIE.md` §3.9) contient bien « choix a, décidé par délégation le 05/10 ». CARTES-BR-02 est consigné.

## Réserves (mineures)
1. Les lignes « Échéance : {date} » et « Aucune échéance » ne sont pas isolées. Je n'y vois aucun effet aujourd'hui, car elles n'ont pas de ponctuation finale. À isoler à la prochaine occasion.
2. La démonstration de la direction ne surcharge pas le port des cartes. Ce n'était pas demandé ; le retrait par la direction relève du serveur (CARTES-BR-02).

## Hors périmètre, déjà consigné
- Sur la page de démonstration de l'enseignant en arabe, des composants antérieurs se lisent dans le désordre : « élèves sur 6 places 3 », « .téléphone », « % Chapitre 1 · 60 ».
- Le lien se copie au lieu de s'ouvrir, faute de `url_launcher`, que `pubspec.yaml` interdit à cette étape.
- Le bouton « Enregistrer la carte » apparaît pâle sur les captures, en fr comme en ar. Il reste actif (`onPress` toujours défini) : c'est le style de `ActionPrincipale`, que cette étape ne modifie pas.
