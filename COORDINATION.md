# COORDINATION entre les deux postes (chantier frontend Tuteur V1)

Mis à jour : 24/09/2026, 18 h. Canal unique : **GitHub** (`origin` = `https://github.com/rewayahacademy-glitch/Rewayah-Academy-Official-App.git`). Les deux postes ne se parlent QUE par des commits poussés. Le directeur relaie seulement si un poste le lui demande.

## Tableau de suivi OBLIGATOIRE (décision du directeur, 24/09)

Page : **https://claude.ai/artifact/XMVyZJiLTcmMKTnhsbp3sU** (« Chantier Tuteur V1 »). Une ligne par étape du plan, collection `etapes` de sa base, écrite avec l'outil **ArtifactData** (même compte claude.ai sur les deux postes).
- **En commençant** une étape : `update` du document (ex. `LB-1`) avec `statut: "en_cours"`, `par` (poste et agent), `date`.
- **En la finissant** : `update` avec `statut: "fait"` et `preuve` (hash de commit, fichier de rapport). Rien n'est « fait » sans preuve (définition de « fait » : `03_DECISIONS_COORDINATEUR.md` §1 ter bis).
- **Étape absente de la liste** : AVANT de la faire, créer `etapes/HL-<poste>-<n>` avec `phase`, `titre`, `poste`, `hors_liste: true`, `motif` (pourquoi on dérive du plan). Si le motif n'est pas lié à l'objectif du lot, ne pas la faire : la consigner dans `08_BACKLOG_VAGUE_CLASSE_VISIO.md` (A) ou `etat/B.md` (B).
- Jamais supprimer une ligne, jamais cocher l'étape d'un autre poste, jamais modifier `titre` ni `ordre` d'une étape du plan.
- Un agent qui n'a pas l'outil ArtifactData écrit la même information dans `etat/B.md` (poste B) ou dans son rapport (poste A) ; la session principale du poste reporte dans le tableau.
- Le plan est **fermé** : les lots s'arrêtent quand leurs étapes sont cochées. Aucune amélioration sans ligne dans le tableau.

## Qui fait quoi

| Poste | Rôle | Lots | Branches qu'il écrit |
|---|---|---|---|
| **A** (poste d'origine, 8 Go) | Coordinateur et intégrateur | C Cours, E Compte/Historique, O Observation | `ui/tuteur-v1` (SEUL à l'écrire), `ui/tuteur-v1-c`, `-e`, `-o` |
| **B** (second poste, 16 Go) | Exécutant | A Admission, B Foyer, D Appareils | `ui/tuteur-v1-a`, `ui/tuteur-v1-b`, `ui/tuteur-v1-d` |

Mandats détaillés des six lots : `05_LOTS_PHASE1.md`. Règles : `03_DECISIONS_COORDINATEUR.md` (les §1 bis, 1 ter, 1 ter bis priment).

## Les trois branches Git à connaître

1. `ui/tuteur-v1` : la base commune (fondations de la phase 0). **Seul le poste A la modifie.** B part d'elle et la relit quand A annonce une nouvelle version.
2. `ui/tuteur-v1-<lot>` : une branche par lot, créée depuis `origin/ui/tuteur-v1`. Chaque poste pousse SES branches de lot ; jamais celles de l'autre.
3. `pilotage/tuteur-v1` : ce dossier de pilotage (documents, maquettes, mandats, états, demandes). Branche orpheline, **jamais fusionnée dans `main`**. Les deux postes y écrivent, **chacun dans ses fichiers seulement** (tableau ci-dessous), avec `git pull --rebase` avant chaque `git push`.

| Fichiers de `pilotage/tuteur-v1` | Écrits par |
|---|---|
| tout sauf ce qui suit | A seulement |
| `etat/B.md` (avancement de B, une ligne par lot et par sous-paquet, avec hash de commit) | B |
| `demandes/A.md`, `demandes/B.md`, `demandes/D.md` (besoins sur des fichiers du coordinateur) | B |
| `05_recette/A/`, `05_recette/B/`, `05_recette/D/` (rapports, captures, carte des fonctions) | B |
| `08_BACKLOG_VAGUE_CLASSE_VISIO.md` | A (B ajoute ses constats dans `etat/B.md`, A les recopie) |

## Chemins sur le poste B

Les documents citent les chemins du poste A. Sur le poste B, remplacer :

| Chemin cité (poste A) | Chemin réel (poste B) |
|---|---|
| `D:\RA _APP\pilotage-tuteur-v1\` | `C:\RA\pilotage\` (worktree de la branche `pilotage/tuteur-v1`) |
| `D:\RA _APP\docs de lancement\` (mandat, maquettes `tutuor image\`) | `C:\RA\pilotage\lancement\` |
| `D:\RA _APP\RA -OFFICIAL-APP\` et `D:\RA_TUTEUR\integration\` | `C:\RA\depot\` (clone, branche `ui/tuteur-v1`, lecture) |
| worktree d'un lot | `C:\RA\lot-<a|b|d>\` |
| `outils\flutter-verrou.ps1` | `C:\RA\pilotage\outils\flutter-verrou.ps1` (même usage, avec `-Dossier` du poste B) |

## Cycle de travail du poste B

1. `git -C C:\RA\pilotage pull --rebase` puis `git -C C:\RA\depot fetch origin` : lire `ETAT_A.md` (annonces du coordinateur, nouvelle base, réponses aux demandes).
2. Lot suivant : `git -C C:\RA\depot worktree add -b ui/tuteur-v1-<lot> C:\RA\lot-<lot> origin/ui/tuteur-v1`, puis `flutter pub get` dans ce worktree.
3. Exécuter les sous-paquets du lot (mandat `05_LOTS_PHASE1.md`), un commit par sous-paquet.
4. Après CHAQUE sous-paquet : `git -C C:\RA\lot-<lot> push -u origin ui/tuteur-v1-<lot>` ; ligne ajoutée dans `etat/B.md` ; push de `pilotage/tuteur-v1`.
5. Fin de lot : rapport et captures dans `05_recette/<lot>/`, dernière ligne « LOT <x> TERMINÉ <hash> » dans `etat/B.md`, push. Passer au lot suivant.
6. Si A annonce une nouvelle base dans `ETAT_A.md` : dans le worktree du lot en cours, `git merge origin/ui/tuteur-v1` (conflits : garder la version de la base pour les fichiers du coordinateur, la sienne pour les fichiers du lot ; `fr.i18n.json` = union des espaces de noms ; régénérer `dart run slang`).

## Interdits absolus (les deux postes)

Push vers `main` ; merge dans `main` ; ouverture de PR (seul A ouvre la PR brouillon `ui/tuteur-v1 -> main`) ; `workflow_dispatch` ; migration ; modification de `supabase/`, `.github/`, `vercel.json` ; push d'une branche d'un autre poste ; suppression d'une branche distante ; affichage ou commit de `dart_define.json` ou d'un secret ; toute modification du Coran (`lib/core/coran`, `lib/core/tc_coran`, `lib/features/tc_mushaf`).

## Intégration (poste A)

A récupère (`git fetch origin`) les branches de lot annoncées terminées, les fusionne dans `ui/tuteur-v1` (union i18n, régénération), lance l'analyse complète et les tests, pousse `ui/tuteur-v1`, met à jour la PR brouillon (URL d'aperçu) et écrit dans `ETAT_A.md` : base mise à jour, lots intégrés, défauts renvoyés au lot.
