# Rapport de lot A (Admission) — LA-F, tâche 2/2

Écrit par le poste B (agent LA-F, tâche 2/2), 25/09/2026. Complète `CONTEXTE.md`
(fiche condensée), `LA-1.md`, `LA-2.md`, `LA-3.md`, `LA-4.md` et `REVUE.md` déjà
présents dans ce dossier : détail des preuves dans ces fichiers, ici la synthèse
demandée par la définition de « fait » (05_LOTS_PHASE1.md §0) et par la tâche.

## 1. Écrans du lot et carte des fonctions

| Route | Fichier | Fonction | Statut |
|---|---|---|---|
| `/bienvenue` | `lib/features/bienvenue/bienvenue_page.dart` | Accueil visiteur déconnecté | fait |
| `/connexion` | `lib/features/connexion/connexion_page.dart` | Lien magique, renvoi, erreurs classées | fait |
| `/connexion/recuperation` | `lib/features/connexion/recuperation_page.dart` | Lien expiré/refusé, renvoi | fait |
| `/inscription/usage` | `lib/features/inscription/etapes/usage_etape.dart` | Choix Moi / Moi et ma famille | fait (LA-2), tableau en_cours (A-4) |
| `/inscription/identite` | `.../identite_etape.dart` | Prénom, nom, erreurs sous les champs | idem |
| `/inscription/genre` | `.../genre_etape.dart` | Deux cartes côte à côte | idem |
| `/inscription/recapitulatif` | `.../recapitulatif_etape.dart` | `GroupeReglages` un rectangle, Modifier par ligne | idem |
| `/attente` | `lib/features/dossier/attente_page.dart` | Portail dossier, statut exact + une action | fait (code/tests), tableau « partiel » (A-3, P2) |
| `/attente/accuse` | `.../signature_page.dart` (`AccusePage`) | Carte à accuser une fois (ADR-011) | idem |
| `/attente/contrat` | `.../signature_page.dart` (`ContratPage`) | Contrat + paragraphe observation, variante `?pour=moi` | idem |
| `/attente/piece` | `.../depot_piece_page.dart` | Dépôt pièce, refus corrigible | fait |
| `/tuteur/compte/consentements` | `lib/features/consentements/consentement_observation_page.dart` | Re-consentement comptes existants | code/tests faits ; **inatteignable depuis `lib/main.dart`** tant que A-3 n'est pas levée (aucun bouton, seule la route la connaît) |
| `/tuteur/parcours/:eleveId` | `lib/features/parcours_offres/parcours_offres_page.dart` + `bloc_parcours.dart` | Questionnaire + offres, bloc d'accueil | fait |

Carte des fonctions (une fonction = un seul endroit, §1 ter.1) : la sélection de
fuseau vit uniquement dans `parcours_offres_page.dart` (`fuseauSuggere`,
`libelles_parcours.dart`) ; le calcul d'étape/statut du dossier vit uniquement
dans `service_dossier.dart`/`etat_dossier.dart` (jamais recalculé côté écran,
cf. commentaire `AttentePage`) ; le rendu des points de contrat/consentement
vit uniquement dans `texte_observation.dart`/`explication_observation.dart`,
repris par C-obs via i18n seulement (aucun import Dart direct).

## 2. Constats mineurs traités dans cette tâche (2/2 de LA-F)

1. **Planche maquette du récapitulatif quasi vide** (`la2_recapitulatif_contre_maquette.png`)
   — non corrigé : le format de maquette composite (3 écrans juxtaposés
   04/05/06) est un fichier fourni, pas généré par le lot ; un recadrage
   demanderait de retoucher l'image source (hors périmètre code) ou le test
   de capture existant (risque de casser `la2_inscription_capture_test.dart`
   hors budget de temps de cette tâche). Conformité déjà prouvée séparément
   par `la2_recapitulatif_390x844_light.png` (`GroupeReglages` en un seul
   rectangle, §1 ter.3 respecté). Limitation documentée ici, pas corrigée en
   devinant un recadrage.
2. **Minimum de lancement à 0** — corrigé : `bloc_parcours.dart:73` passe un
   `int? minimum` (`regles.value?.minimumLancement`, sans `?? 0`) ;
   `libelles_parcours.dart:detailEtape` affiche
   `parcours.etatClasseEnFormationDetailSansMinimum` (phrase sans chiffre)
   quand la règle n'est pas encore chargée, `etatClasseEnFormationDetail`
   sinon.
3. **Fuseau figé `Europe/Paris`** — corrigé : `parcours_offres_page.dart`
   (`_fuseauVu`) réutilise `fuseauSuggere(fuseauConnu, decalageAppareil)`
   (même fonction que `_pageLieu`) au lieu d'une constante ; repli sur
   `'Europe/Paris'` seulement si aucune suggestion n'est possible (device et
   foyer tous deux inconnus).
4. **Mot interdit « session » dans `lienRefuse`** — déjà corrigé par une
   session précédente (commit `7b696ee`) ; vérifié dans cette tâche,
   `fr.i18n.json:285` = « Ce lien n'a pas pu vous connecter. Demandez-en un
   nouveau ci-dessous. », aucune occurrence de « session ». Aucun changement
   nécessaire.
5. **Vocabulaire interdit dans les clés i18n** (`etatGroupe*`) — corrigé :
   `etatGroupeEnFormation(Detail)` → `etatClasseEnFormation(Detail)`,
   `etatGroupeConfirme(Detail)` → `etatClasseConfirmee(Detail)` dans
   `fr.i18n.json`, `libelles_parcours.dart`, `test/parcours/parcours_offres_test.dart` ;
   `dart run slang` relancé. Vérifié : ces clés ne sont utilisées que dans
   ces fichiers du lot A (aucun appelant hors lot).
6. **Commentaires citant « demande A-2 »** — corrigé : `A-2` → `A-3` dans
   `consentements_supabase.dart:94` et `consentement_observation_page.dart:241`
   (`demandes/A.md` : A-2 est le rappel de B-3, A-3 porte le branchement du
   port des consentements).
7. **Variante du consentement d'observation dépend d'un brouillon en mémoire**
   (`signature_page.dart:50-51`) — **non corrigé, limitation documentée**.
   `EtatDossier` (`lib/core/dossier/etat_dossier.dart`) n'a aucun champ qui
   distingue élève adulte / responsable légal une fois le dossier créé ; la
   seule source est `brouillonInscriptionProvider`, en mémoire, perdu au
   rechargement. Corriger proprement demande soit un champ serveur persistant
   (hors périmètre code frontend, backend `etat_dossier()`), soit une case
   neutre dans `texte_observation.dart` — fichier repris par C-obs via i18n
   paramétré (§6 bis) : y toucher sans vérifier C-obs est risqué et hors
   budget de cette tâche. Déjà reconnu par l'auteur (LA-3, `etat/B.md:33`,
   « reste (2/3) »). Recommandation pour le coordinateur : ajouter à
   `etat_dossier()` un champ qui distingue le rôle du profil élève créé (self
   vs. enfant), pour que `/attente/contrat` (accès direct, sans brouillon)
   choisisse la bonne variante sans deviner.

## 3. Vérifications de fin de lot (05_LOTS_PHASE1.md §0)

- `dart analyze --fatal-infos` ciblé (fichiers touchés par cette tâche +
  tests) : **No issues found**.
- `dart run tool/verifier_jetons.dart` : **422 fichiers, aucune violation**.
- Tests exacts (tous verts, sous verrou `flutter-verrou.ps1`) :
  - `test/parcours test/features/inscription_test.dart test/features/connexion_test.dart test/features/dossier_test.dart` → **82 tests, All tests passed**.
  - `test/features/dossiers_sans_piece_test.dart test/features/consentements_test.dart test/features/admission test/features/bienvenue_connexion_navigation_test.dart test/i18n test/config test/router/navigation_test.dart` → **118 tests, All tests passed**.
  - (Non relancé dans cette tâche, déjà vert en tâche 1/2 : `test/capture/*` du lot A, `test/features/admission/ordre_requetes_test.dart` inclus ci-dessus.)
- Frontière : `git diff --stat origin/ui/tuteur-v1...HEAD -- supabase .github vercel.json pubspec.yaml lib/core/theme lib/core/router lib/core/widgets` → **vide**.
- Aucun STUB restant dans les fichiers du lot A (vérifié par grep sur les
  écrans listés en §1).
- Captures : celles produites en LA-1/LA-2/LA-3/LA-4/LA-F (tâche 1/2) restent
  valides ; aucune nouvelle capture requise par les constats mineurs de cette
  tâche (aucun changement de disposition visuelle, seulement texte/logique).
- Graphe d'imports : non relancé dans cette tâche précise (aucun nouveau
  fichier créé, seuls des fichiers déjà atteignables modifiés) ; dernière
  vérification positive en LA-F tâche 1/2 (commit `08b1a9d`).

## 4. Statut global du lot

**LOT A INCOMPLET** au commit `30bb035` (`ui/tuteur-v1-a`). Raisons, toutes
externes au périmètre du poste B :

- **LA-2** reste « en_cours » au tableau : bloquée par **A-4**
  (`test/accessibilite/clavier_test.dart:43-51`, fichier du coordinateur,
  rouge depuis le passage de l'inscription en étapes routées). Code, tests et
  captures de LA-2 sont faits ; seul ce test transverse hors périmètre du lot
  A empêche « fait ».
- **LA-3** reste « partiel » au tableau : bloquée par **A-3**
  (`portConsentementsProvider`, fichier du coordinateur, ne pointe pas encore
  sur `consentementsLotAProvider`) — `/tuteur/compte/consentements` n'est
  atteignable par aucun bouton depuis `lib/main.dart`, seule l'URL directe
  l'ouvre, donc la définition de « fait » n'est pas remplie pour cet écran ;
  et par la validation du texte signé par le directeur (**point P2**,
  toujours en attente).
- Constat 7 ci-dessus (variante du consentement d'observation) documenté,
  non corrigé : nécessite une décision du coordinateur sur `etat_dossier()`.

Aucun de ces trois points n'est corrigible par le poste B sans franchir la
frontière des fichiers du coordinateur (`00_OWNERSHIP.md §6 bis`) ; ils sont
consignés dans `demandes/A.md` (A-3, A-4) depuis les tâches précédentes et
rappelés ici.

## 5. Demandes ouvertes (rappel, voir `demandes/A.md`)

- **A-1** : bascule `PorteAcces.deconnecte => Routes.bienvenue` (racine
  seulement). Contournement en place (lien discret), non bloquant.
- **A-2** : rappel de B-3 pour l'inscription (contournement local déjà
  écrit, `CarteChoixInscription`).
- **A-3** : brancher `portConsentementsProvider` + poser l'invite dans le
  Compte tuteur (lot E). Bloque LA-3 → « fait ».
- **A-4** : adapter `clavier_test.dart:43-51` au nouvel `/inscription`
  routé par étapes. Bloque LA-2 → « fait ».

## 6. Hors périmètre constaté dans cette tâche

Aucun nouveau défaut hors périmètre découvert pendant le traitement des 6
constats mineurs (tous dans des fichiers du lot A, cf. `00_OWNERSHIP.md §3`).

## 7. Fusion 1cbc760 et migration (tâche 2/3, poste B)

Régénération des captures des écrans touchés par la fusion de `ui/tuteur-v1`
(1cbc760) et la migration de l'inscription vers `PageEtape` /
`ChoiceCardGroup` (commits `65284f5`, `384211d`) :

- `flutter test --no-pub test/capture/la2_inscription_capture_test.dart` sous
  `CAPTURE_DIR` + les 3 `CAPTURE_MAQUETTE_LA2_*` (`onboarding Mble.png`,
  `onboarding Mble d.png`, `Onboarding mobile 2.png`) : **21 tests, All tests
  passed** (verrou, code 0). Les 20 captures 390x844/1440x900 clair/sombre
  (usage, identité, genre, récapitulatif, identité en erreur, récapitulatif
  en échec d'actualisation) et les 3 planches maquette | rendu sont
  régénérées dans `05_recette/A/captures/`.
- Planche `la2_genre_contre_maquette.png` ouverte et comparée à `onboarding
  Mble d.png` : **écart non levé**. La maquette place les deux cartes
  « Homme » / « Femme » côte à côte ; le rendu actuel (étape genre sur
  `ChoiceCardGroup`) les empile toujours en liste verticale. Conforme au
  constat de la tâche précédente (demande **A-5** au coordinateur : disposition
  côte à côte pour `ChoiceCardGroup`) — non corrigible côté lot A tant que
  A-5 n'est pas traitée (fichier `lib/core/widgets/**` hors périmètre).
  Planches usage et récapitulatif : conformes, rien de nouveau par rapport
  à LA-2/LA-F.
- `dart run tool/verifier_jetons.dart` : **428 fichiers, aucune violation**
  (verrou, code 0).
- Frontière `git diff --stat origin/ui/tuteur-v1...HEAD -- supabase .github
  vercel.json pubspec.yaml lib/core/theme lib/core/router lib/core/widgets` :
  **vide**.
- `graphe_imports.ps1 -Repo C:\RA\lot-a -Ref 384211d` : 366 fichiers `lib/`
  atteignables depuis `lib/main.dart`, 66 non atteignables (hors `.g.dart`) ;
  aucun fichier lié à l'inscription (usage/identité/genre/récapitulatif)
  dans la liste des non-atteignables.
- Aucun changement de code dans cette tâche (seules les captures et ce
  rapport sont modifiés) ; rien à committer côté `lot-a`.
