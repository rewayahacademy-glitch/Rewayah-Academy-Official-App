<!-- verdict : ACCEPTEE_AVEC_RESERVES -->
## Revue adverse : CARTES-PERSO-1 (branche corrections/c2-cartes-perso, 733f121d)

**Verdict : ACCEPTEE_AVEC_RESERVES.** La demande est remplie. Aucun défaut majeur n'est prouvé. Les réserves portent sur des trous de couverture de test et sur un arbitrage déjà consigné.

**Statut.** La partie client est écrite et testée localement. Elle n'est pas branchée au serveur, pas testée sur staging, pas déployée.

### Périmètre relu
- **Commits relus** : 940d435b, 07c8df32, 9c56ef3d, 733f121d. Ils changent 38 fichiers.
- **Zones interdites** (supabase/, .github/, pubspec, vercel.json, thème, Coran, dart_define) : non touchées.
- **Commits** : rédigés en français. Les deux lignes de fin sont exactes. Aucun identifiant de modèle ailleurs.

### Demande contre livré
- **Fiche CLS-CARTES** dans `docs/current/DASH_STRATEGIE.md` :
  - la décision du 05/10, déléguée par le directeur, est au §3.9 ;
  - la fiche elle-même est en annexe A, au format des autres fiches : rôles, écrans, cinq états, champs K-57 (déduit, choisi, saisi), invariants ;
  - une ligne a été ajoutée au §5 ;
  - CARTES-BR-01 à 03 sont au §5 bis : table class_cards, RLS (écriture par l'enseignant, lecture par les membres et les tuteurs), RPC de lecture ordonnée et d'écriture avec bornes, masquage a posteriori, journal d'audit ;
  - REPRISE-CORRECTIONS-REVUE.md est mis à jour. **Conforme.**
- **Port neutre** `lib/core/tc_groupe/cartes_classe.dart` : en production, il rend `CapaciteIndisponible('CARTES-BR-01')`. L'écran affiche alors l'EtatSysteme « pas encore ouvertes », sans Réessayer et sans fausse carte. **Conforme.**
- **Démo** `cartes_classe_demo.dart` : branchée via `surchargesEleveDemo`. La capacité est vraie seulement dans `surchargesEnseignantDemo`. **Conforme.**
- **Capacité** : le droit de modifier vient de `peutModifier` (lu par le port), jamais d'un rôle. **Conforme.**
- **Écrans** : EspaceGroupePage, FicheGroupePage, MaClasseAdultePage et ClasseTuteurPage portent le bloc. Le tuteur, l'enfant et l'adulte lisent ; l'enseignant touche une carte pour ouvrir la feuille.
- **Feuille de l'enseignant** :
  - 4 modèles préremplis (titre proposé ; échéance tirée de la prochaine séance pour un devoir ou un rappel) ;
  - les bornes sont vérifiées avant l'envoi ;
  - les défauts s'affichent sous les champs ;
  - le bouton n'est jamais grisé ;
  - le retrait demande une confirmation ;
  - un envoi perdu affiche « non confirmée ».
- **Cinq états** : chargement, contenu, vide (subi pour la famille ; « Ajouter une carte » pour l'enseignant), erreur avec Réessayer, hors ligne.
  - Hors ligne suit K-42 : le bandeau de PageShell est le seul signal. Les cartes déjà lues restent affichées. Sans elles, EtatSansDonnees s'affiche.
  - Un enseignant hors ligne n'a ni carte pressable ni bouton d'ajout. Rien n'est grisé.
- **Interface guidée** : le modèle n'est pas affiché ; le lien est un bouton secondaire pleine largeur ; le lecteur d'écran lit le libellé complet.

### Preuves exécutées (worktrees jetables, retirés à la fin)
- `dart analyze --fatal-infos` : aucun problème.
- `verifier_jetons` : 39 violations, identique à la base 4207c357.
- `verifier_revue` : 1568 violations, identique à la base, et le diff des sorties triées est vide.
- `cartes_classe_test.dart` : 39 sur 39.
- `test/features`, `test/router`, `test/widgets`, `test/accessibilite` : +3807, tous passent. Les 2129 sautés le sont faute de CAPTURE_DIR.
- `test/core` et `test/tool` : +702, tous passent.
- **Captures** : régénérées avec CAPTURE_DIR, les 19 fichiers sont reproduits. J'ai ouvert les captures suivantes :
  - bloc_guidee_320x2_rtl_sombre ;
  - bloc_enseignant_320x2_ltr_clair ;
  - etats_390_clair ;
  - feuille_320x2_rtl_sombre ;
  - page_enseignant_feuille_1440_sombre ;
  - page_guidee_320x2_clair ;
  - page_adulte_390_sombre.

  Aucun mot n'est coupé et aucun débordement n'apparaît. Les cartes sont séparées, et le thème clair, le thème sombre et le RTL sont couverts.

### Mutations (contre-épreuves)
**Tuées (15)** : chaque mutation fait échouer au moins un test.

| Mutation | Comportement cassé |
| :--- | :--- |
| M2 | Hors ligne, l'enseignant peut quand même modifier |
| M3 | Le type de carte s'affiche en Interface guidée |
| M4 | Le port de production rend une liste vide au lieu de « indisponible » |
| M5 | Le vide ne tient plus compte de la capacité |
| M6 | Le bloc « rien à afficher » hors ligne disparaît |
| M7 | Les traits d'union ne sont plus insécables |
| M8 | Le tri par position est remplacé par un tri par identifiant |
| M9 | La capacité est ignorée (toute carte devient modifiable) |
| M10 | Le bouton d'ajout s'affiche sans capacité |
| M11 | « Indisponible » devient une erreur ordinaire |
| M12 | Le message d'envoi perdu devient « non enregistrée » |
| M13 | L'échéance n'est plus tirée de la prochaine séance |
| M14 | Un lien en http est accepté |
| M15 | Plus de bouton de lien en Interface guidée |
| M16 | Plus de plafond de 6 cartes |
| M17 | Le retrait ne demande plus de confirmation |
| M18 | L'enseignant de la démo ne peut plus modifier |

**Survivantes (3)** : aucun test ne détecte ces changements.
- **M1** : le tri à l'affichage est supprimé. Le compte rendu annonçait pourtant cette contre-épreuve.
- **M19** : la garde contre le double envoi est supprimée.
- Le bloc est retiré des pages tuteur et adulte.

### Réserves (non bloquantes, à traiter dans un lot de suite)
1. La présence des cartes sur ClasseTuteurPage et MaClasseAdultePage n'est couverte par aucun test, et le tuteur n'a pas de capture d'écran réel.
2. Le tri à l'affichage et la garde contre le double envoi ne sont pas testés.
3. Le lien se copie au lieu de s'ouvrir. L'arbitrage url_launcher est consigné pour le directeur.
4. Devoir et Lien utile ont la même icône de livre ouvert.
5. En RTL, la ponctuation des libellés français de la feuille est mal placée. C'est un artefact général de l'app, pas de ce lot.
6. Le test de la fiche élève a été ajusté avec ensureVisible, parce que la page s'est allongée.