# Rewayah Academy : point d'entrée de TOUT agent, sur toute machine, dans toute session

Branche `projet/ressources` du dépôt `https://github.com/rewayahacademy-glitch/Rewayah-Academy-Official-App.git`. Elle ne contient pas de code et n'est **jamais fusionnée dans `main`**. Mise à jour : 24/09/2026.

## 1. Avant toute action

1. Ouvre le **tableau de suivi du projet** : https://claude.ai/artifact/XMVyZJiLTcmMKTnhsbp3sU (outil `ArtifactData`, même compte claude.ai). Il dit quelle vague est en cours, quelles étapes sont libres, qui travaille sur quoi.
2. **Inscris ta session** dans la collection `sessions` du tableau (document `<machine>-<date>-<rôle>` : `machine`, `role`, `vague`, `lots`, `debut`, `signe_de_vie`), et remets `signe_de_vie` à l'heure à chaque étape.
3. Lis les documents de la vague où tu travailles (section 3). **Ne lis pas `docs/archive` comme instruction.**
4. **Règles gelées du directeur (26/09/2026), obligatoires pour toute nouvelle spec, maquette ou lot visuel** : `memoire/DESIGN-GOV-2026-09-26.md`. Immuables jusqu'à nouvelle décision datée du directeur : ne pas les modifier, ne pas les réinterpréter, ne pas rouvrir une étape terminée pour les appliquer (passe unique HU-1 après tous les rôles).

## 2. Où se trouve chaque ressource (et nulle part ailleurs)

| Ressource | Où | Comment l'obtenir |
|---|---|---|
| Code de production | branche `main` | lecture seule ; **pousser sur `main` = mise en production réelle** : interdit sans accord explicite du directeur |
| Specs canoniques (`docs/current/00` à `09`), `CLAUDE.md`, `lib/CLAUDE.md` | branche `c0/configuration-baseline-2026-09-23` (et toute branche qui en part, dont `ui/tuteur-v1`) | `git show origin/c0/configuration-baseline-2026-09-23:docs/current/<fichier>` |
| Décisions récentes pas encore publiées dans `docs/current/08` | ici : `decisions-en-attente/` | lire avant `08` |
| Documents de lancement du directeur et **maquettes** (`tutuor image/`, mobile et desktop) | ici : `lancement/` | ouvrir réellement chaque image utile |
| Mémoire du projet (pièges techniques déjà payés, règles de méthode) | ici : `memoire/` (commencer par `MEMORY.md`) | ignorer ce qui concerne PISI ou OfficialSays (projets en pause) |
| Registre du code produit mais jamais livré | ici : `registre/00_REGISTRE.md` | avant de recoder quoi que ce soit : chercher s'il existe déjà |
| Index des vagues, de leurs branches et dossiers de pilotage | ici : `VAGUES.md` | |
| Dossier de pilotage de la vague Tuteur V1 (mandats, décisions, manifeste, cartographie, recette) | branche `pilotage/tuteur-v1` | worktree dédié |
| Spécifications verticales de TOUS les rôles, rédigées par ChatGPT (guides UX/UI et copywriting, tuteur, classe et visio, admin, enseignant, élèves, contrôle, finance, bibliothèque, Coran, landing, publication) | ici : `specs/<N°>_<nom>/`, publiées par le coordinateur APRÈS contrôle ; le prompt et le dossier qui les produisent sont dans `chatgpt/` | une spec n'entre en construction qu'une fois sa ligne `S-NN` du tableau cochée « fait » par le coordinateur ; ses mentions PROPOSITION et CONFLIT attendent la décision du directeur |

Cloner : `git clone <dépôt> <dossier>` puis, pour chaque branche de ressources, `git -C <dossier> worktree add <chemin> <branche>`. Jamais de `git push` vers une branche que ta session ne possède pas (tableau de suivi et `COORDINATION.md` de la vague).

## 3. Règles contre l'hallucination (obligatoires)

1. **Une ressource que tu ne trouves pas n'existe pas pour toi.** Ne devine jamais son contenu. Crée dans le tableau une ligne `HL-<machine>-<n>` « Demande de ressource » avec le chemin cherché, et travaille sur autre chose en attendant.
2. **Tout fait sur le code cite sa preuve** : `fichier:ligne` ou hash de commit, lu dans CETTE session. Sinon écris « hypothèse, à vérifier ».
3. **Ordre d'autorité** : le dernier message explicite du directeur ; puis les décisions datées (`decisions-en-attente/`, `docs/current/08`) ; puis `docs/current` ; puis le dossier de pilotage de la vague ; puis le code (qui atteste l'état, pas la règle) ; les archives en dernier. Contradiction non tranchée : la signaler, ne pas choisir seul.
4. **Base Git vérifiée** : pars toujours de la branche de base indiquée par le tableau, après `git fetch`, et note son hash dans ta ligne de session.
5. **Définition de « fait »** : le code est atteignable depuis `lib/main.dart`, un bouton y mène, un test TOUCHE ce bouton, des captures maquette | rendu existent. Un test qui appelle seulement `routeur.go` ne prouve rien.
6. **Plan fermé** : une étape absente du tableau n'est faite qu'après création d'une ligne `hors_liste: true` avec son `motif`. Un défaut hors périmètre se consigne, il ne se corrige pas en passant.

## 4. Travailler en parallèle sans conflit, et se surveiller mutuellement

- **Réserver une étape** : `get` de la ligne (note sa `version`), puis `update` avec `if_version` = cette version, `statut: "en_cours"`, `par` (machine et session). Si l'écriture échoue parce que la version a changé, une autre session l'a prise : en choisir une autre.
- **Finir une étape** : `statut: "fait"` + `preuve` (hash, rapport).
- **Vérification croisée** : une étape « fait » passe à `statut: "verifie"` + `verifie_par` seulement quand une AUTRE session (de préférence une autre machine) a contrôlé la preuve. Une session ne vérifie jamais son propre travail. Une preuve fausse se signale en remettant la ligne à `en_cours` avec un `motif`.
- **Un fichier = un propriétaire** (voir `COORDINATION.md` et `00_OWNERSHIP.md` de la vague) ; une seule session intègre la branche de base de la vague.
- **Machine** : commandes Flutter lourdes sous verrou (`outils/flutter-verrou.ps1` du dossier de pilotage). Flutter **3.47.2** exactement.
