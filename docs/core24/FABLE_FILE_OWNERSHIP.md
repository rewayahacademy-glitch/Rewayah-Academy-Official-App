# FABLE_FILE_OWNERSHIP

Matrice de propriété des fichiers touchés par Fable pendant le sprint noyau 24 h
(`REWAYAH_SPRINT24H_CORE_CONTRACT_V2.md`, `REWAYAH_PROMPT_FABLE_CORE24H_CODE_V2.md`).

Produit par **Fable** le 21 septembre 2026.

> **La règle est immuable : Fable ne touche que les zones frontend directement
> nécessaires aux features UI P0.** Tout besoin hors de ces zones est écrit dans
> `CONTRACT_REQUEST_FABLE.md`, jamais contourné par un faux branché en production.

---

## 0. Baseline et branche

| Élément | Valeur |
| :--- | :--- |
| `CORE24_BASELINE_SHA` fourni par Agent Z | **absent** de tous les documents de `D:\RA _APP\Maestro Vague\` et du dépôt |
| Baseline adoptée | `ae61eb6c22834514b40143562c851293c5d7d388` = `origin/main` au 21/09/2026 |
| Pourquoi celle-là | c'est la seule référence **poussée et partagée**. La branche d'Agent Z `observation/lot-2026-09-21` (`0bfc9e4`) n'est pas fusionnée et porte `0042`, une migration non appliquée qui relève d'Astra. `main` en est l'ancêtre direct : le fast-forward reste possible, et cette branche Fable se rebase ou se fusionne sans conflit prévisible (aucun fichier de `0bfc9e4` n'est dans la liste ci-dessous, hors `fr.i18n.json`, 3 lignes). |
| Branche | `core24/fable-frontend` |
| Worktree | `D:\RA_CORE24\fable` |
| Fusion dans `main` | **jamais par Fable.** Astra intègre. |

Si Astra a démarré d'un autre SHA, `git diff ae61eb6..<CORE24_BASELINE_SHA>` sur
les chemins de la section 1 dit exactement ce qu'il faut rejouer : aucun fichier
de cette liste n'est modifié par `observation/lot-2026-09-21`, sauf
`assets/i18n/fr.i18n.json` (3 lignes d'observation, orthogonales aux miennes).

---

## 1. Fichiers de Fable

### 1.1 Nouveaux

| Chemin | Rôle |
| :--- | :--- |
| `lib/features/classes/domaine/classe_vm.dart` | `ClasseVM`, `CreneauClasse`, `BrouillonClasse`, `ReglesClasse`, `ProgrammeChoix`, `EnseignantEligible`, `MembreClasse` : la forme unique de la Classe pour les quatre rôles |
| `lib/features/classes/domaine/conformite.dart` | KYC V2 séparé en ses composantes : `ExigenceKyc`, `EtatKyc`, `DispenseKyc`, `ConformiteCompte`, `PreconditionSalle` |
| `lib/features/classes/domaine/erreur_domaine.dart` | `EchecDomaine`, `MotifEchec`, `messageHumain()` : aucune erreur Postgres à l'écran |
| `lib/features/classes/domaine/ports.dart` | `PortClassesAdmin`, `PortMarketplaceClasses`, `PortConformite`, `PortPreconditionSalle` |
| `lib/features/classes/domaine/adaptateurs_existants.dart` | adaptateurs **réels** sur `groupes_admin`, `creer_groupe`, `app_config`, `programme_*_admin`, `comptes_admin`, `etat_dossier`, `mes_groupes_v`, `profils_du_foyer_v` ; `capaciteAbsente` là où le serveur manque |
| `lib/features/classes/domaine/providers.dart` | providers Riverpod des ports (défaut = adaptateur réel, jamais un faux) |
| `lib/features/classes/libelles_classes.dart` | mise en forme : créneau en mots, durée, public, états, titre Sayyid/Sayyida |
| `lib/features/classes/carte_classe.dart` | `CarteClasse`, `ActionCarte` : la carte compacte, un bouton, divulgation progressive |
| `lib/features/classes/grille_classes.dart` | 1 / 2 / 3 colonnes par `LayoutBuilder` + `AppGabarit` |
| `lib/features/classes/porte_salle.dart` | `PorteSalle` : Rejoindre, ou la précondition photo expliquée avant le clic |
| `lib/features/classes/surface_presence.dart` | `SurfacePresence` : états de présence rendus par le serveur, jamais calculés |
| `lib/features/classes/rappel_kyc.dart` | `RappelKyc` : rappel calme, « Faire plus tard » |
| `lib/features/classes/selecteur_membre.dart` | « Pour qui ? » : membres du foyer |
| `lib/features/classes/feuille_dispense_kyc.dart` | feuille Admin : confirmation courte, motif obligatoire, retour humain |
| `lib/features/classes/routes_core24.dart` | `CheminsCore24`, `routesCore24()` : retourne des routes, ne construit aucun `GoRouter` |
| `lib/features/admin_groupes/creation_classe_page.dart` | `CreationClassePage` : programme/public, grille de créneaux, aperçu, publication (unitaire ou en lot) |
| `lib/features/enseignant_classes/classes_enseignant_page.dart` | `ClassesEnseignantPage` : onboarding tant que non cléaré, puis Mes classes / Classes disponibles / Candidater ; `EtapeConformite` |
| `lib/features/tuteur_classes/classes_foyer_page.dart` | `ClassesFoyerPage` : rappel KYC calme, membre du foyer, Classes du foyer, disponibles, Inscrire, Proposer un créneau, planning avec présence serveur |
| `test/features/classes/**` | 13 fichiers : doubles de ports (`faux/`), largeurs (`support/`), 11 suites |
| `docs/core24/FABLE_FILE_OWNERSHIP.md`, `CONTRACT_REQUEST_FABLE.md`, `FABLE_IMPLEMENTATION_REPORT.md` | ce lot |

### 1.2 Modifiés

| Chemin | Ce qui change, et rien d'autre |
| :--- | :--- |
| `lib/features/admin_groupes/groupes_page.dart` | réécrit : « Classes », deux entrées (créer / générer en lot) vers `CreationClassePage`, colonnes humaines, **inscription d'un élève par choix dans une liste** (plus de champ d'identifiant), erreurs humaines. Les feuilles observation / capacité / retrait / clôture sont conservées |
| `lib/features/admin_comptes/comptes_page.dart` | deux colonnes KYC V2 (exigence, état) + action « Dispenser du KYC » / « Rétablir » sur les enseignants, retour local |
| `lib/features/bienvenue_enseignant/bienvenue_page.dart` | bloc « Accès ouvert / en attente » (contrat, identité, dispense visible) + troisième sortie « Voir les classes » |
| `lib/features/dossier/depot_piece_page.dart` | « Faire plus tard » pour tuteur et élève (jamais pour l'enseignant) |
| `lib/features/dossier/attente_page.dart` | « Continuer sans la pièce pour l'instant » quand seule la pièce manque, tuteur/élève |
| `lib/features/accueil_famille/accueil_famille_page.dart` | ligne « Classes disponibles » dans « Gérer le foyer » |
| `lib/features/accueil_eleve/accueil_eleve_page.dart` | le bouton Rejoindre passe par `PorteSalle` (précondition photo) ; structure ELV-02 inchangée (2 blocs) |
| `lib/features/profil_enseignant/profil_enseignant_page.dart` | `SettingRow` « Mes classes » |
| `lib/features/tc_mes_groupes/carte_groupe.dart` | paramètre `porte` (widget rendu à la place du bouton Rejoindre) |
| `lib/features/tc_mes_groupes/mes_groupes_page.dart` | `onAjouterPhoto`, `PorteSalle` sur chaque carte |
| `lib/features/tc_mes_groupes/routes_tc_a.dart` | passe `onAjouterPhoto` au tuteur (vers `Routes.tuteurReglages`) |
| `assets/i18n/fr.i18n.json` | renommages visibles « Groupe » → « Classe », « enfants » → « membres du foyer » (valeurs seules, **aucune clé renommée**) ; nouveau sous-arbre racine `classes` |
| `lib/core/i18n/strings*.g.dart` | **générés** par `dart run slang`, versionnés comme le veut `lib/CLAUDE.md`. À l'intégration : relancer `dart run slang` plutôt que résoudre un conflit à la main |

### 1.3 Lecture seule, consommés sans une ligne modifiée

```
lib/core/**                    (services, widgets, thème, routeur, session, vidéo, présence, Teaching Core)
lib/features/disponibilites/grille_semaine.dart   (la grille de semaine, réutilisée telle quelle)
lib/features/admin_groupes/feuille_observation_groupe.dart
lib/features/tc_espace_groupe/**, lib/features/tc_classe_live/**, lib/features/salle/**
supabase/**                    (aucune migration, aucune fonction Edge)
pubspec.yaml                   (aucune dépendance)
test/support/harnais.dart      (réutilisé, non modifié)
```

### 1.4 Ce que Fable n'a pas touché, conformément au prompt

`supabase/`, migrations, RLS, Edge Functions, `lib/core/video/**` (LiveKit),
`lib/core/coran/**` et `lib/core/tc_coran/**` (Quran Engine), `lib/core/auth/**`
et `lib/core/session/**` (auth core), `lib/core/domain/enums.dart`,
`lib/core/*/service_*.dart` (repositories partagés), `lib/core/router/**`,
`lib/core/widgets/**` (design system), `lib/core/theme/**`, `lib/core/icons/**`.

Aucun composant n'a été ajouté à `lib/core/widgets/` : `catalogue_galerie_test`
(défaut baseline #2, déjà rouge avant ce lot) n'a pas une entrée de plus à
réclamer.

---

## 2. Vérification

Depuis `D:\RA_CORE24\fable` :

```
dart run slang                       # régénère strings*.g.dart (aucun diff attendu)
dart analyze lib test/features/classes
dart run tool/verifier_jetons.dart   # 355 fichiers, aucune violation
flutter test test/features/classes   # 80 tests
flutter test                         # suite complète : 1808 verts le 21/09, voir FABLE_IMPLEMENTATION_REPORT.md
```
