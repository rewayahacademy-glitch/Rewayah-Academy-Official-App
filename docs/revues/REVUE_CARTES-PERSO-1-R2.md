<!-- verdict : REFUSEE -->
## CARTES-PERSO-1, revue adverse de `corrections/c2-cartes-perso` (bcb25e20) : refusée

**Verdict : REFUSÉE.** Dans la vraie démonstration tuteur (« Essayer la démonstration »), le tuteur ne voit aucune carte. Il reste aussi trois défauts mineurs. La correction est courte et décrite plus bas.

J'ai travaillé dans le worktree jetable `rv-CARTES-PERSO-1-88`, détaché sur origin/corrections/c2-cartes-perso, puis je l'ai retiré. Rien n'a été poussé.

### Ce qui est conforme

- **Fiche** : la fiche CLS-CARTES existe dans `docs/current/DASH_STRATEGIE.md`, au §3.9 et à l'annexe A. Elle suit le format du catalogue et porte la décision datée du 05/10, déléguée par le directeur. Les besoins serveur sont consignés sous CARTES-BR-01 à 03 :
  - la table `class_cards` avec toutes les colonnes demandées ;
  - la RLS : écriture par l'enseignant de la classe, lecture par les membres et les tuteurs de leurs foyers ;
  - une RPC de lecture ordonnée et une RPC d'écriture qui contrôle les longueurs ;
  - le masquage a posteriori par la direction ;
  - le journal d'audit.
- **Port neutre** : `lib/core/tc_groupe/cartes_classe.dart`. En production, il rend `CapaciteIndisponible('CARTES-BR-01')`, sans aucune fausse carte. Aucun branchement serveur.
- **Capacité, pas rôle** : le droit de modifier vient de `CartesClasseVM.peutModifier`. Si je remplace `vue.peutModifier && !horsLigne` par `!horsLigne`, 9 tests échouent.
- **Cinq états** : chargement, contenu, vide (famille ou enseignant), erreur avec Réessayer, et « pas encore ouvertes » (production) sont présents et capturés.
  - Hors ligne suit K-42 : seul le bandeau de PageShell signale le réseau.
  - Le bloc EtatSansDonnees dit ce qui manque, avec l'icône sablier.
  - La phrase « Les cartes pourront être modifiées quand la connexion reviendra » suit la formulation prévue par `03` §États.
- **Aucun bouton grisé** : hors ligne, l'ajout n'est pas affiché et les cartes ne se pressent pas.
- **Les trois corrections annoncées** tiennent à la mutation :
  - feuille dans le conteneur de l'emplacement (sans `UncontrolledProviderScope`) : 4 échecs ;
  - « Copier le lien de » isolé en RTL (isolement retiré) : 4 échecs ;
  - lecture par le tuteur (bloc retiré de ClasseTuteurPage à 390) : 1 échec.
- **Interface guidée** : sans le pictogramme `estEnfant`, 5 échecs.
- **Contrôles** :
  - `dart analyze --fatal-infos` : 0 problème.
  - `verifier_revue` : 1568, identique au socle 4207c357.
  - `verifier_jetons` : 39, identique au socle, aucun écart dans les fichiers nouveaux.
  - Aucun fichier interdit touché : pubspec, supabase/, .github/, thème, Coran.
- **Tests** (tous avec `--concurrency=2`) :
  - Dossiers touchés (tc_espace_groupe, classe_tuteur, ma_classe_adulte, demo, fiche_eleve, captures CARTES-PERSO-1) : 296 passent, 97 sautés (captures sans CAPTURE_DIR), 1 erreur de chargement due à un chemin inexistant que j'avais mal écrit (`test/features/fiche_groupe`). Le vrai fichier `fiche_groupe_test.dart` passe, tout comme la sonde jetable du défaut 1 (20 tests en tout).
  - Régressions sur les autres appelants des quatre pages : accessibilite, core/accessibilite, accueil_adulte, classe_eleve, classe_enseignant, enseignant_recette, foyer, mon_espace_adulte, router, teaching_core/a et les tests de `test/features` qui montent ces pages. Résultat : 1382 passent, 0 échec.
- **Captures ouvertes** : bloc enseignant, famille et guidée à 320 px texte ×2 (LTR clair, RTL sombre) ; page guidée à 320 ×2 et 390 ; tuteur à 320 ×2 en RTL ; enseignant après enregistrement à 390 ; planche des états à 390.
  - Aucun mot n'est coupé dans les cartes.
  - En Interface guidée, l'enfant voit le titre et le texte, et le lien est un bouton pleine largeur.

### Défauts

1. **MAJEUR : le tuteur ne voit aucune carte dans la vraie démonstration.**
   - `surchargesDemoTuteur` (`mode_demonstration.dart`) ne surcharge pas le port des cartes.
   - Une sonde passe par RacineDemonstrable en staging, touche l'entrée de démonstration, puis ouvre la Classe d'Aïcha. Résultat : la page affiche le bloc, mais 0 carte et l'état « Les cartes de la classe ne sont pas encore ouvertes ».
   - La lecture par le tuteur n'est prouvée que dans un test qui injecte lui-même les surcharges. Le directeur ne peut la voir nulle part dans l'application.
   - **Correction** : ajouter `surchargesCartesClasseDemo(groupe, peutModifier: false)` pour `DonneesDemo.groupeAicha` et `DonneesDemo.groupeYusuf` dans `surchargesDemoTuteur`. Ajouter un test qui passe par l'entrée de démonstration, puis une capture.

2. **MINEUR : le RTL n'est corrigé qu'en partie dans la feuille.** Le compte rendu le dit corrigé. Dans `feuille_320x2_rtl_sombre.png`, on lit pourtant :
   - « caractères au plus 60 » et « caractères au 280 plus » ;
   - « .classe » et « .d'horaire » ;
   - « Collez une adresse qui commence par .//:https ».

   **Correction** : passer par `isolerSens` les textes d'aide et d'erreur des champs ainsi que les descriptions des modèles.

3. **MINEUR : la règle « cartes déjà lues gardées hors ligne » n'est pas prouvée.** Si je retire `lectureHorsLigne`, la mutation survit : les 50 tests passent. Il manque un test où une relecture échoue hors ligne après une première lecture réussie.

4. **MINEUR : deux modèles ont le même pictogramme.** Devoir et Lien utile s'affichent avec le même livre ouvert.

### Hors périmètre (déjà consigné par le rédacteur, je le confirme)

- À 320 px et texte ×2, la carte de séance de ClasseTuteurPage coupe des mots (`carte_seance_classe.dart`, antérieure à cette étape). Il faut une étape dédiée.
- Le lien se copie au lieu de s'ouvrir, faute de `url_launcher` : c'est à arbitrer par le directeur.

### Statut de preuve

Tout est **testé localement** seulement. Rien n'est testé sur staging, rien n'est déployé, aucun branchement serveur (BR-1 à faire).