<!-- verdict : REFUSEE -->
## Relecture adverse de CARTES-PERSO-1 (branche corrections/c2-cartes-perso, commit 733f121d)

### Verdict : REFUSEE

Il reste un défaut majeur prouvé : en démonstration, l'enseignant ne peut pas enregistrer la modification d'une carte. La demande principale n'est donc pas remplie.

### Ce qui a été vérifié

Statut de la branche : présente dans le code et testée localement. Elle n'est ni testée sur staging ni déployée.

**Fiche CLS-CARTES (`docs/current/DASH_STRATEGIE.md`)**
- §3.9 porte la décision du 05/10, déléguée par le directeur.
- L'annexe A contient la fiche au format des autres.
- La ligne CARTES-PERSO-1 est ajoutée au §5.
- Le registre §5 bis contient CARTES-BR-01 à 03 :
  - table `class_cards` ;
  - RLS (écriture par l'enseignant, lecture par les membres et les tuteurs) ;
  - RPC de lecture et d'écriture avec contrôle des longueurs ;
  - masquage a posteriori ;
  - journal d'audit.
- `REPRISE-CORRECTIONS-REVUE.md` est mis à jour.
- Conforme.

**Port neutre (`lib/core/tc_groupe/cartes_classe.dart`)**
- En production, le port rend `CapaciteIndisponible('CARTES-BR-01')`, sans fausse carte. L'état indisponible n'a pas de bouton Réessayer (capture `etats_390_clair.png`).
- La capacité `peutModifier` est rendue par la lecture et n'est jamais déduite d'un rôle.
- Conforme.

**Cinq états**
- Chargement, contenu, vide (famille et enseignant), erreur et indisponible sont vérifiés sur la capture à 390.
- Hors ligne suit K-42 :
  - les cartes déjà lues restent affichées ;
  - EtatSansDonnees n'apparaît que lorsque rien n'a été lu ;
  - l'enseignant hors ligne ne peut ni presser une carte ni en ajouter, et aucun bouton n'est grisé.

**Interface guidée**
- Le type de carte n'est pas affiché.
- Le lien est un bouton « Copier le lien », et le lecteur d'écran lit le libellé entier.
- Aucun mot n'est coupé à 320 px avec le texte ×2 en RTL (capture `bloc_guidee_320x2_rtl_sombre.png`).

**Contrôles**
- `dart analyze --fatal-infos` : aucun problème.
- `verifier_revue` : 1568 violations, comme la référence.
- `verifier_jetons` : 39.
- Tests des dossiers touchés (tc_espace_groupe, fiche_groupe_test, classe_tuteur, ma_classe_adulte, fiche_eleve, demo) : 304 passent, 77 captures sont sautées.

**Mutations rejouées** (chacune fait échouer des tests)
- Capacité ignorée (`modifiable = !horsLigne`).
- Tri neutralisé (`sort` qui rend 0) : le test « trierCartes » échoue.

**Captures ouvertes**
- Bloc enseignant 320×2 RTL sombre.
- Bloc Interface guidée 320×2 RTL sombre.
- États à 390.
- Page enseignant avec la feuille à 390.

### Défaut majeur : l'enregistrement échoue dans la vraie démo

**Où :**
- `bloc_cartes_classe.dart`, méthode `_editer` ;
- `feuille_carte_classe.dart`, lignes 201 et 231.

**Cause :**
- La feuille est ouverte par `AppBottomSheet.ouvrir` sur le Navigator du routeur.
- Ce Navigator se trouve au-dessus du `ProviderScope` imbriqué de `EcranEnseignantDemo`.
- `ref.read(portCartesClasseProvider)` se résout donc dans le conteneur racine, qui rend `PortCartesClasseIndisponible`.

**Preuve :** un test jetable sur `routesDemoClasse('dev')` a été lancé en vue enseignant, à 390 et à 1440 :
- étapes : toucher une carte, changer le titre, appuyer sur « Enregistrer la carte » ;
- résultat : « Envoi non confirmé » s'affiche (`NON_CONFIRME=true`) et la feuille reste ouverte ;
- les deux tests échouent.

Les 39 tests du rédacteur ne voient pas ce défaut :
- ils montent le bloc sous un seul `ProviderScope` racine ;
- le groupe « demonstration » ne fait jamais d'enregistrement.

L'ajout et le retrait passent par le même chemin et sont donc touchés aussi.

**Correctif attendu :**
- Transmettre le port à la feuille, ou envelopper la feuille dans `UncontrolledProviderScope(container: ProviderScope.containerOf(context))`. C'est le motif déjà employé dans `demo_accessibilite_page.dart:503`.
- Ajouter un test d'enregistrement et de retrait depuis la vraie page de démo enseignant, à 390 et à 1440. Ce test doit échouer sur 733f121d.

### Défauts mineurs

1. **Point final mal placé en RTL.** Les phrases i18n de l'enseignant (`contexteEnseignant` et les autres) affichent leur point en tête : « .aussitôt ». L'isolat bidi n'est appliqué qu'au texte saisi par l'enseignant.
2. **Lecture par le tuteur non prouvée.** ClasseTuteurPage n'a ni démo, ni capture, ni test de lecture des cartes.

### Remarques non bloquantes

- Le lien est copié au lieu d'être ouvert, parce qu'aucun paquet d'ouverture de lien n'est dans `pubspec.yaml`. C'est consigné comme arbitrage pour le directeur ; acceptable.

### Ménage

Le worktree de relecture `rv-CARTES-PERSO-1-14` est retiré. Rien n'a été poussé.