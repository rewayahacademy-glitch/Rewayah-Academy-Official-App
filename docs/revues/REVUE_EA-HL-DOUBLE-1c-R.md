# Revue adverse EA-HL-DOUBLE-1c : branche `corrections/c2-hl-double-c` (8d251c35)

**Verdict : ACCEPTÉE AVEC RÉSERVES.**

- **Ce qui est fait et prouvé :**
  - le refus R0 et les réserves de EA-HL-DOUBLE-1 sont traités ;
  - chaque correction est tenue par des tests qui échouent si on l'annule.
- **Défaut majeur :** aucun n'est prouvé.
- **Réserve moyenne :** sur l'Accueil élève, quand on est hors ligne et que la lecture des cours échoue, un « wifi barré » reste dans le bloc d'erreur, à côté de celui du bandeau.

J'ai relu dans deux worktrees jetables détachés sur `origin/corrections/c2-hl-double-c` : un pour les tests complets, un pour les mutations. Les deux ont été retirés à la fin. Rien n'a été poussé ni modifié sur la branche.

## Périmètre et origine
- **Base de départ :** la branche part de `29a4fc83` (branche commune), et `ec7b7aeb` en est bien un ancêtre.
- **Reprise :** 5a3ef55a et 98d3eef7 ont été repris en 1c18419d et aa411036.
  - Les patch-id diffèrent seulement dans le code généré par slang (`strings*.g.dart`), régénéré après la fusion.
  - Le contenu source est le même.
- **Ajouts :** trois commits, 7f3a5946, 3894aa4b et 8d251c35.
- **Fichiers interdits :** aucun n'est touché (`supabase/`, `.github/`, `vercel.json`, `pubspec`, thème, `page_shell`, rendu du Coran, `dart_define`).
- **Commits :**
  - les 5 commits se terminent exactement par les deux lignes imposées ;
  - aucun identifiant de modèle n'apparaît dans les lignes ajoutées.

## Les défauts de la revue précédente, un par un
| Défaut | Statut | Preuve |
| :--- | :--- | :--- |
| Notes des enseignants « Sans réseau… » (créneaux grille, prise, demande ; Bienvenue ; Journée) | **Levé** | Textes réécrits (« … quand la connexion reviendra ») et sourcés dans `libelles_sources.json`, « à faire valider par le directeur ». `horsLignePrise`, `horsLigneDemande` et `lancerHorsLigne` ne sont utilisés nulle part dans `lib/` : seule la garde du catalogue les vérifie. |
| Carte « Connexion interrompue » de l'appairage | **Levé** | Nouveaux titres « Code masqué pour l'instant » et « Le code n'a pas pu être préparé », avec l'icône sablier. Capture sombre ouverte. |
| La garde du catalogue laissait passer « Sans réseau » et « Connexion interrompue » | **Levé** | Motif partagé `motifHorsLigne` (sans réseau, connexion interrompue, perdue ou coupée, demande ou nécessite une connexion…). Les deux textes du cahier « LIB-CAHIER-1 » restent une exception nommée, remontée au directeur. |
| Phrase par défaut d'`EtatSansDonnees` non détectée | **Levé** | `phraseHorsLigneParDefaut()` est vérifiée dans `expectHorsLigneUneFois`. |
| `lectureHorsLigne` prouvée seulement par un test unitaire | **Levé** | Sept tests de page « déjà lu puis relu en échec ». |
| Icône wifi barré sous le bandeau | **Levé en partie** | `EtatSansDonnees`, le routeur, les dossiers, l'observation, la carte de session et la note d'entrée de l'Accueil élève passent au sablier. Le bloc d'erreur de l'Accueil élève est oublié (réserve 1). |
| Note des appareils d'un élève (relevée par le rédacteur) | **Levé** | « Vous pourrez retirer ou connecter un appareil quand la connexion reviendra. » Le test de page appelle maintenant `expectAvecDonnees()`. |

## Mutations faites par moi
- **M1 : retour aux anciens textes** (appareils.eleve.horsLigne ; titres de l'appairage = « Connexion interrompue » ; bienvenue.horsLigne ; creneaux.horsLigneGrille), puis slang. **6 échecs** :
  - la garde du catalogue ;
  - les 2 tests de l'émetteur hors ligne ;
  - les appareils d'un élève hors ligne ;
  - Bienvenue « offline » ;
  - la grille des créneaux « offline ».
- **M2 : `phrase: ''` retiré** d'`EtatSansDonnees`. **12 échecs**, comme annoncé.
- **M3 : `lectureHorsLigne` neutralisée** (`false && …`). **7 échecs de page** : Accueil, Historique, carte du titulaire, soldes, recharge, Ma classe, Mon espace.
- **M4 : retour au « wifi barré »** dans `EtatSansDonnees`, le routeur, les dossiers, l'Accueil élève, la carte de session et l'appairage. **18 échecs** : Accueil, Ma classe, Mon espace adultes, Accueil élève, émetteur, appareils, fiche élève, soldes, recharge, Journée et routeur.
  - Les dossiers admin n'ont aucun test qui échoue sur ce point (sans gravité).

## Sondes
**Sonde sur l'Accueil élève**, ajoutée puis retirée dans « hors ligne, l echec porte la nature hors ligne ».
- Le bandeau est trouvé une fois.
- `iconesHorsLigne()` en trouve **2** : le second signal est prouvé, voir la réserve 1.

**Autres écrans sous `PageShell` qui lisent `horsLigneProvider`.** J'ai parcouru leurs textes : saisie du code, caméra, présentation, photo de l'élève, profil et photo de l'enseignant, bibliothèque. Tous disent ce qui ne peut pas se faire et quand ce sera possible, sans redire le réseau.

**Exceptions documentées et acceptables :**
- la visionneuse de pièce ;
- la salle et la classe en direct (`PageImmersive`) ;
- le scanner.

## Contrôles
| Contrôle | Résultat |
| :--- | :--- |
| `dart run slang` | aucune différence |
| `dart analyze --fatal-infos` | 0 problème |
| `verifier_jetons` | 39 violations, aucune sur une ligne modifiée (carte_session:400 et file_dossiers:363 existaient avant) |
| `verifier_revue` | 1568 (annoncé : 1568) |
| `flutter test --concurrency=2 test/core test/router test/widgets test/teaching_core test/features` | **+5389 ~2211, All tests passed** |

## Captures
- **Volume :** 118 PNG.
- **Ouvertes :**
  - soldes 320 x2 RTL ;
  - recharge 320 x2 RTL et guidée ;
  - appareils d'un élève en guidée (nouvelle note) ;
  - créneaux 320 x2 ;
  - Bienvenue 390 ;
  - observation guidée sombre ;
  - alertes de la Journée 320 x2 RTL ;
  - soldes 1440 ;
  - fiche élève sombre ;
  - appairage sombre ;
  - Ma classe avec données.
- **Rendu :** chaque fois, le bandeau est le seul signal, sous lui il n'y a qu'un sablier, et aucun mot n'est coupé.
- **Artefact attendu :** la ponctuation inversée et « sur 2 1 » en RTL viennent du français affiché en sens RTL.
- **Couverture :** les écrans exigés par l'étape sont couverts en sombre, Interface guidée et 1440. D'autres variantes manquent (réserve 2).

## Réserves, à traiter dans un lot suivant
1. **Moyen.** Bloc d'erreur hors ligne de l'Accueil élève (`accueil_eleve_page.dart:240-252`).
   - Il garde le « wifi barré » du bandeau, ce que contredit la règle 03 écrite par cette branche.
   - Correction : passer `icone: AppIcons.attente` au bloc, et ajouter `expectHorsLigneUneFois()` au test.
2. **Mineur.** Captures absentes ou partielles :
   - Accueil élève, carte de session, file des dossiers : aucune capture ;
   - appairage : pas d'Interface guidée ;
   - Bienvenue et démarrage : ni sombre, ni guidée, ni RTL ;
   - 320 en RTL : absent pour le Foyer, la fiche élève, l'observation et les appareils.
3. **Mineur.** Échec d'entrée en observation après une coupure : « Connexion impossible » et « Vérifiez votre connexion » sous le bandeau. Ces formes ne sont pas couvertes par `motifHorsLigne`.

## Points remontés au directeur (non imputés au rédacteur)
- `enseignant.cahier.exceptionHorsLigne` et `enFileDetailHorsLigne` commencent encore par « Sans réseau ». Ils sont sourcés « commentaire du directeur, LIB-CAHIER-1 » : c'est à lui de trancher.
- `parcours.horsLigneDetail` est affiché selon le classement de la panne, pas selon le bandeau : à arbitrer.
- Tous les libellés réécrits sont marqués « rédigé par l'agent, à faire valider par le directeur ».

## Statut
- **Présent dans le code et testé localement :** ma revue le confirme.
- **Pas fait :** rien n'est testé sur staging ni déployé. Aucune PR n'est ouverte, rien n'est sur `main`.
