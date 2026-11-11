# Registre des lots (créé le 11/11/2026)

Ordre urgent du directeur du 11/11, relayé par le garde-cap puis par le pilote : « ne plus perdre un seul lot ».
Ce registre recense tout lot qui existe hors de `main` : une branche distante, une PR ouverte, une dette nommée.
Chaque ligne a **un seul statut et sa preuve** :

- **LIVRÉ (#N)** ;
- **REMPLACÉ par #N** (ou par le commit de `main` qui l'a remplacé) ;
- **ABANDONNÉ** (avec la décision datée) ;
- **À LIVRER** (avec l'agent et l'ordre) ;
- **non vérifié**, quand aucune preuve n'a été trouvée. Une ligne sans preuve n'a jamais de statut deviné.

Relevé fait par E le 11/11/2026 vers 12 h UTC, sur `main` `b86dbc9d9`, avec `tool/registre_lots.sh` lancé sur un vrai clone (historique complet).

## D'abord : ce qui est faux, bloqué ou non prouvé

- **117 lignes sur 241 sont « non vérifié ».** Leur contenu manque à `main` au 11/11, et aucune décision ni aucun ordre écrit ne dit quoi en faire. Ce sont autant de lots peut-être perdus. Pour chacune, le pilote décide, ou le directeur quand il s'agit d'une décision de produit.
- **Trois PR ouvertes attendent une décision du directeur depuis le 08/11, sans réponse écrite trouvée** (`docs/orchestration/TRI-PR-AVANT-25-10.md`) :
  - **#26** : les aperçus de PR construisent encore l'application avec les secrets Supabase de la **production**. `.github/workflows/flutter-deploy.yml`, lignes 150-151, au 11/11. La PR 26 les isolait sur STAGING. Le risque est probable, non prouvé : je ne peux pas lire la valeur des secrets.
  - **#42** : 18 compétences tierces sous `.claude/skills/`.
  - **#22** : SQL de sécurité de la production, jamais validé. Proposée FERMER après une vérification du garde-cap ; je n'ai pas trouvé cette vérification.
- **Les verdicts « remplacé » et « abandonné » viennent pour la plupart d'un relais.** C'est l'annexe de `ALERTE-LOTS-NON-LIVRES-2026-11-08.md`, un relevé de E du 08/11 sur `main` `13fc04c09`. Ce qui est mesuré le 11/11, c'est seulement que le contenu de ces branches est toujours absent de `main`. Un « REMPLACÉ par <commit> » renvoie au commit de `main` qui a réécrit leurs fichiers ; il ne prouve pas, ligne par ligne, que rien d'utile n'a été perdu.
- **Écart avec la mesure du garde-cap.**
  - Le garde-cap comptait 162 branches sans PR ; j'en compte 166.
  - Les branches poussées depuis expliquent au moins une partie de l'écart, dont `claude/profils-p1-travail`, poussée par moi aujourd'hui.
  - Les deux autres chiffres sont retrouvés à l'identique : 206 branches livrées, 75 PR non fusionnées.
- **PR fermées sans fusion.** Parmi toutes les PR fermées sans fusion, 62 l'ont été le 08/11 (date de fermeture lue sur GitHub). Celles d'avant le 25/10 suivent les propositions de `TRI-PR-AVANT-25-10.md`. Pour les autres, je n'ai trouvé aucune raison écrite : leur ligne le dit.

## Comment refaire le relevé

```
tool/registre_lots.sh            # résumé, puis une ligne par branche hors de main
tool/registre_lots.sh --tsv      # lignes seules, pour un tableur
tool/registre_lots.sh --sans-fetch
```

Git seul, lecture seule. `git fetch` met à jour les références du clone ; `git ls-remote origin 'refs/pull/*/head'` donne la PR à la tête de chaque branche. Une PR compte comme fusionnée si `main` porte « (#N) » ou « Merge pull request #N » dans son journal. Aucun appel à l'API GitHub, aucune écriture distante.

Pour chaque ligne, le contenu présent ou absent de `main` au 11/11 est mesuré comme suit. Le diff de la branche depuis sa base commune avec `main` est réappliqué à l'envers sur `main` :

```
git diff --binary $(git merge-base origin/main origin/B) origin/B > b.patch
git apply --check -R b.patch
```

S'il passe sans conflit, le contenu est dans `main`. Un diff nul ne contient rien hors de `main`.

## Règle de méthode (pilote et garde-cap, 11/11/2026)

1. **Tout lot commencé a sa branche `claude/<lot>-travail` et sa ligne dans ce registre, le jour même.** La ligne porte l'agent et l'ordre (À LIVRER).
2. **Toute PR fermée sans fusion porte, en dernier commentaire, la raison et son remplaçant** (PR ou commit de `main`). Sans ce commentaire, la ligne reste « non vérifié ».
3. **Le pilote lance `tool/registre_lots.sh` avant chaque série de fusions.** Il met ce registre à jour : une ligne livrée passe à LIVRÉ (#N), une branche nouvelle reçoit sa ligne.
4. **Le garde-cap contrôle** que le résumé du script et ce registre se correspondent.
5. Une ligne n'est jamais écrite « fait », « livré », « à faire » ou « non branché » sans sa preuve du jour : un commit dans `main`, un fichier:ligne ou une lecture en production. Sans preuve, on écrit « non vérifié ». Un relais d'un autre agent se signale comme tel (consigne du directeur du 11/11, `docs/orchestration/CONSIGNES-DIRECTEUR-EN-VIGUEUR.md`, V9).

## Les PR ouvertes (13, au 11/11)

| PR | Branche | Statut | Preuve |
| :-: | :-- | :-- | :-- |
| 433 | `claude/goutte-huile` | non vérifié | créée le 11/11 ; dans la file du pilote d'après son message du 11/11 ; l'agent n'est pas écrit |
| 432 | `claude/titulaire-sans-appareil` | non vérifié | idem |
| 431 | `claude/fix-clignote-demande` | non vérifié | idem |
| 430 | `claude/sombre-sans-eclair` | non vérifié | idem |
| 429 | `claude/retirer-absence-detectee` | À LIVRER (E, dans la file du pilote) | tête `595604ca7` ; elle ne se pousse que pour corriger un test rouge (pilote, 11/11) |
| 426 | `claude/bande-barre` | non vérifié | créée le 11/11 ; dans la file du pilote d'après son message du 11/11 ; l'agent n'est pas écrit |
| 421 | `claude/proposition-progression-sourates` | non vérifié | documentation seule ; ni agent ni ordre écrit trouvé. La question qu'elle posait (« sourate validée ») est tranchée en option A (pilote, 11/11) |
| 409 | `claude/zealous-tesla-ewstzw` | À LIVRER (Fable, la salle) | pilote, 11/11 : PR en cours, personne d'autre n'y touche |
| 382 | `claude/ma-progression` | À LIVRER (H, après le lot SOURATES de B) | pilote, 11/11 : « sourate validée » est tranchée en option A ; la PR dépend de SOURATES (migration) |
| 380 | `claude/progression-adulte` | À LIVRER (A, après la file actuelle) | pilote, 11/11 : abandonnée le 08/11 sur une panne de CI sqlite3 qui ne venait pas d'elle |
| 42 | `claude/jolly-gauss-7rlt4y` | non vérifié | DÉCISION du directeur demandée le 08/11 (`TRI-PR-AVANT-25-10.md`) : 18 compétences tierces sous `.claude/skills/` (104 fichiers) ; absentes de `main` au 11/11, qui n'a que `marque-rewayah`, `mots-rewayah` et `programme-rewayah` |
| 26 | `codex/backend-staging-preview-secrets` | non vérifié | DÉCISION du directeur demandée le 08/11 ; au 11/11, `flutter-deploy.yml` (l. 150-151) construit encore les aperçus avec les secrets de production. La branche vise un ancien `flutter-deploy.yml` et ne s'applique pas telle quelle |
| 22 | `codex/backend-sec-prod` | non vérifié | proposée FERMER après une vérification du garde-cap (`TRI-PR-AVANT-25-10.md`), vérification non trouvée ; `docs/backend/SEC_PROD_REMEDIATION.sql` absent de `main` au 11/11 ; `PROD_SECURITY_SNAPSHOT_2026-10-10.md` est dans `main` (`adb1c857f`), dans une autre version |

## Dettes nommées, hors branche

| Date | Dette | Statut | Preuve |
| :-- | :-- | :-- | :-- |
| 11/11 | TRANSITIONS (1) : focus sur le titre et annonce du lecteur d'écran au changement de page (WCAG 2.4.3), dans le core, une seule fois | À LIVRER (A, après P1) | garde-cap : TRANSITIONS jugé CONFORME SOUS RÉSERVES ; relayé par le pilote le 11/11 |
| 11/11 | TRANSITIONS (2) : position de défilement au retour, prouvée par un test sur une liste | À LIVRER (A, après P1) | idem |
| 11/11 | TRANSITIONS (3) : sur le web, tout retour est un fondu court (simplification acceptée, à écrire) | À LIVRER (A, après P1) | idem |
| 11/11 | NON-BRANCHÉ-ÉCHUS : suppression de `lib/core/capacites/port_capacite_payout.dart` (ligne échue de `tool/branchement_tolere.txt`) | À LIVRER (E, ordre du pilote du 11/11) | commit local `86840822c` sur `claude/non-branche-echus-travail` ; pousser cette branche attend la fin de la suite complète |
| 08/11 | Recherche, volet finance : `rech_d4_rechercher_reference_finance` (en production d'après la lecture du 08/11) sans adaptateur dans l'application | non vérifié | `ALERTE-LOTS-NON-LIVRES-2026-11-08.md`, état au 11/11 ; aucun agent ni ordre écrit |

## Les branches hors de `main`, une par une (241 non livrées)

Les 206 branches livrées (PR fusionnée) ne figurent que dans la sortie du script, plus bas.

### À LIVRER (5)

| Date | Branche | PR | Commits hors main | Statut | Preuve |
| :-- | :-- | :-: | --: | :-- | :-- |
| 2026-11-11 | `claude/zealous-tesla-ewstzw` | 409 | 77 | À LIVRER (Fable, PR 409 en cours ; personne d'autre n'y touche) | pilote, 11/11 |
| 2026-11-11 | `claude/retirer-absence-detectee` | 429 | 2 | À LIVRER (E, dans la file du pilote du 11/11) | PR 429, tête 595604ca7 |
| 2026-11-11 | `claude/profils-p1-travail` | - | 1 | À LIVRER (A, PROFILS P1 ; reprend la tête ec427b9f3 de E) | pilote, 11/11 ; non vert : conflit R1 du branchement signalé au pilote |
| 2026-11-08 | `claude/progression-adulte` | 380 | 4 | À LIVRER (A, après la file actuelle) | pilote, 11/11 : abandonnée le 08/11 sur une panne de CI sqlite3 qui ne venait pas d'elle |
| 2026-11-08 | `claude/ma-progression` | 382 | 3 | À LIVRER (H, après le lot SOURATES de B) | pilote, 11/11 : « sourate validée » tranchée en option A |

### Non vérifié (117)

| Date | Branche | PR | Commits hors main | Statut | Preuve |
| :-- | :-- | :-: | --: | :-- | :-- |
| 2026-11-11 | `claude/titulaire-sans-appareil` | 432 | 1 | non vérifié | PR 432 ouverte, créée le 11/11 ; dans la file du pilote d'après son message du 11/11 ; agent non écrit dans le registre |
| 2026-11-11 | `claude/sombre-sans-eclair` | 430 | 5 | non vérifié | PR 430 ouverte, créée le 11/11 ; dans la file du pilote d'après son message du 11/11 ; agent non écrit dans le registre |
| 2026-11-11 | `claude/proposition-progression-sourates` | 421 | 1 | non vérifié | PR 421 ouverte (documentation seule) ; ni agent ni ordre écrits trouvés |
| 2026-11-11 | `claude/goutte-huile` | 433 | 3 | non vérifié | PR 433 ouverte, créée le 11/11 ; dans la file du pilote d'après son message du 11/11 ; agent non écrit dans le registre |
| 2026-11-11 | `claude/fix-clignote-demande` | 431 | 1 | non vérifié | PR 431 ouverte, créée le 11/11 ; dans la file du pilote d'après son message du 11/11 ; agent non écrit dans le registre |
| 2026-11-11 | `claude/bande-barre` | 426 | 8 | non vérifié | PR 426 ouverte, créée le 11/11 ; dans la file du pilote d'après son message du 11/11 ; agent non écrit dans le registre |
| 2026-10-19 | `claude/jolly-gauss-7rlt4y` | 42 | 1 | non vérifié | PR 42 ouverte ; DÉCISION du directeur demandée le 08/11 (TRI-PR-AVANT-25-10 l.75), sans réponse écrite trouvée |
| 2026-10-17 | `claude/sharp-goldberg-z10a13` | 40 | 7 | non vérifié | PR 40 fermée sans fusion le 2026-11-08 ; annexe 08/11 l.26, verdict a (livrable tel quel) : simulation économique sur STAGING (seed, outils ; PR 40 ouverte) ; contenu absent de main au 11/11 |
| 2026-10-10 | `codex/backend-staging-preview-secrets` | 26 | 2 | non vérifié | PR 26 ouverte ; DÉCISION du directeur demandée le 08/11 (TRI-PR-AVANT-25-10 l.61) ; au 11/11, flutter-deploy.yml construit encore les aperçus avec secrets.SUPABASE_URL et SUPABASE_ANON_KEY (lignes 150-151), comme la production |
| 2026-10-10 | `codex/backend-sec-prod` | 22 | 29 | non vérifié | PR 22 ouverte ; proposée FERMER après vérification du garde-cap (TRI-PR-AVANT-25-10 l.57), vérification non trouvée ; docs/backend/SEC_PROD_REMEDIATION.sql absent de main au 11/11 |
| 2026-11-11 | `claude/transitions-travail` | - | 1 | non vérifié | absente de l'annexe du 08/11 ; contenu absent de main au 11/11 |
| 2026-11-11 | `claude/sourates-travail` | - | 3 | non vérifié | absente de l'annexe du 08/11 ; contenu absent de main au 11/11 |
| 2026-11-11 | `claude/progression-adulte-travail` | - | 5 | non vérifié | absente de l'annexe du 08/11 ; contenu absent de main au 11/11 |
| 2026-11-11 | `claude/lumiere-accueils-vert` | - | 3 | non vérifié | absente de l'annexe du 08/11 ; contenu absent de main au 11/11 |
| 2026-11-11 | `claude/bande-suite-travail` | - | 11 | non vérifié | absente de l'annexe du 08/11 ; contenu absent de main au 11/11 |
| 2026-11-08 | `claude/harmonisation-a` | 329 | 2 | non vérifié | PR 329 fermée sans fusion le 2026-11-08 ; absente de l'annexe du 08/11 ; contenu absent de main au 11/11 |
| 2026-11-07 | `claude/vigilant-pascal-utfgbs` | 314 | 29 | non vérifié | PR 314 fermée sans fusion le 2026-11-08 ; annexe 08/11 l.323, verdict d (proposé abandonné) : passation du garde-cap du 07/11 au soir, « renvoyé par le directeur » (titre du commit) ; contenu absent de main au 11/11 |
| 2026-11-07 | `claude/revenus` | - | 3 | non vérifié | annexe 08/11 l.40, verdict a (livrable tel quel) : 3 commits absents de main (présence partielle comptée, total à recevoir, migration 20261110220000_revenus_pres ; contenu absent de main au 11/11 |
| 2026-11-07 | `claude/photo-candidature-figee` | - | 2 | non vérifié | annexe 08/11 l.118, verdict b (à reprendre) : migration 20261111200000 (photo du dossier figée à l'envoi, réservée) jamais livrée ; 6 fichiers en conflit ; contenu absent de main au 11/11 |
| 2026-11-07 | `claude/page-salle3` | - | 3 | non vérifié | annexe 08/11 l.39, verdict a (livrable tel quel) : page du directeur pour 20261119000000, déjà installée : utile seulement comme modèle ; contenu absent de main au 11/11 |
| 2026-11-07 | `claude/page-push1` | - | 2 | non vérifié | annexe 08/11 l.38, verdict a (livrable tel quel) : outil des pages de migration : refuse un fichier avec BEGIN; ou COMMIT; seul sur une ligne ; contenu absent de main au 11/11 |
| 2026-11-07 | `claude/methode-pilote-garde` | 322 | 1 | non vérifié | PR 322 fermée sans fusion le 2026-11-07 ; annexe 08/11 l.37, verdict a (livrable tel quel) : document d'orchestration du 07/11 ; contenu absent de main au 11/11 |
| 2026-11-07 | `claude/harmoniser-argent` | - | 1 | non vérifié | annexe 08/11 l.36, verdict a (livrable tel quel) : relevé de la phase 1, cité par REPONSES-HARMONISER-ARGENT (section 6) ; contenu absent de main au 11/11 |
| 2026-11-07 | `claude/ci-propose` | - | 3 | non vérifié | annexe 08/11 l.35, verdict a (livrable tel quel) : liste de 218 scénarios SQL pour la CI (ordre de docs/current/ordre-scenarios-ci.txt) ; ci.yml par le pilote ; contenu absent de main au 11/11 |
| 2026-11-07 | `claude/brouillon-persistant` | 281 | 6 | non vérifié | PR 281 fermée sans fusion le 2026-11-08 ; absente de l'annexe du 08/11 ; contenu absent de main au 11/11 |
| 2026-11-07 | `claude/admiring-brown-r6ai72` | - | 9 | non vérifié | annexe 08/11 l.34, verdict a (livrable tel quel) : RECETTE-FINALE du 07/11 (document) ; contenu absent de main au 11/11 |
| 2026-11-06 | `claude/classe-minuscule` | - | 4 | non vérifié | annexe 08/11 l.33, verdict a (livrable tel quel) : « classe » en minuscule au milieu d'une phrase (garde-cap 06/11) ; conflit sur les textes fr seulement ; contenu absent de main au 11/11 |
| 2026-11-03 | `claude/preuve-rouge-ci` | 159 | 1 | non vérifié | PR 159 fermée sans fusion le 2026-11-03 ; annexe 08/11 l.322, verdict d (proposé abandonné) : test cassé exprès, « ne pas fusionner » (titre du commit, 03/11) ; contenu absent de main au 11/11 |
| 2026-10-28 | `claude/admiring-brown-r6ai72-audit` | - | 3 | non vérifié | annexe 08/11 l.32, verdict a (livrable tel quel) : inventaire du code du 28/10 (document) ; contenu absent de main au 11/11 |
| 2026-10-27 | `claude/admiring-brown-r6ai72-surface` | - | 2 | non vérifié | annexe 08/11 l.31, verdict a (livrable tel quel) : passation vers l'agent local (document) ; contenu absent de main au 11/11 |
| 2026-10-27 | `claude/admiring-brown-r6ai72-fiche-0` | - | 2 | non vérifié | annexe 08/11 l.30, verdict a (livrable tel quel) : fiche 0 section H (document) ; contenu absent de main au 11/11 |
| 2026-10-27 | `claude/admiring-brown-r6ai72-admission` | - | 1 | non vérifié | annexe 08/11 l.29, verdict a (livrable tel quel) : fiche admission lot D (document) ; contenu absent de main au 11/11 |
| 2026-10-26 | `claude/admiring-brown-r6ai72-passation-2` | - | 1 | non vérifié | annexe 08/11 l.28, verdict a (livrable tel quel) : passation du 26/10 (document) ; contenu absent de main au 11/11 |
| 2026-10-13 | `codex/journal` | - | 10 | non vérifié | annexe 08/11 l.115, verdict b (à reprendre) : lot serveur Codex du 09 au 13/10 ; base trop vieille ; contenu absent de main au 11/11 |
| 2026-10-13 | `codex/backend-c29-versioned-quota` | - | 1 | non vérifié | annexe 08/11 l.114, verdict b (à reprendre) : lot serveur Codex du 09 au 13/10 ; base trop vieille ; contenu absent de main au 11/11 |
| 2026-10-13 | `archive/pc-2026-10-13/codex/proof-f70-ccr-merge` | - | 1 | non vérifié | absente de l'annexe du 08/11 ; contenu absent de main au 11/11 |
| 2026-10-12 | `codex2/x2-18` | - | 12 | non vérifié | annexe 08/11 l.113, verdict b (à reprendre) : lot serveur Codex du 09 au 13/10 ; base trop vieille ; contenu absent de main au 11/11 |
| 2026-10-12 | `codex/deleg-fin-1-serveur` | - | 7 | non vérifié | annexe 08/11 l.112, verdict b (à reprendre) : lot serveur Codex du 09 au 13/10 ; base trop vieille ; contenu absent de main au 11/11 |
| 2026-10-12 | `codex/com-back-1-wip` | - | 2 | non vérifié | annexe 08/11 l.111, verdict b (à reprendre) : lot serveur Codex du 09 au 13/10 ; base trop vieille ; contenu absent de main au 11/11 |
| 2026-10-12 | `codex/backend-sec-prod-27-invoker` | - | 2 | non vérifié | annexe 08/11 l.110, verdict b (à reprendre) : lot serveur Codex du 09 au 13/10 ; base trop vieille ; contenu absent de main au 11/11 |
| 2026-10-12 | `codex/backend-f86-titulaire-profile-create-guard` | - | 1 | non vérifié | annexe 08/11 l.109, verdict b (à reprendre) : lot serveur Codex du 09 au 13/10 ; base trop vieille ; contenu absent de main au 11/11 |
| 2026-10-12 | `codex/backend-f86-teacher-profile-guard` | - | 1 | non vérifié | annexe 08/11 l.108, verdict b (à reprendre) : lot serveur Codex du 09 au 13/10 ; base trop vieille ; contenu absent de main au 11/11 |
| 2026-10-12 | `codex/backend-f86-pairing-code-guard` | - | 1 | non vérifié | annexe 08/11 l.107, verdict b (à reprendre) : lot serveur Codex du 09 au 13/10 ; base trop vieille ; contenu absent de main au 11/11 |
| 2026-10-12 | `codex/backend-f86-null-safe-review-fixes` | - | 4 | non vérifié | annexe 08/11 l.106, verdict b (à reprendre) : lot serveur Codex du 09 au 13/10 ; base trop vieille ; contenu absent de main au 11/11 |
| 2026-10-12 | `codex/backend-f86-null-safe` | - | 2 | non vérifié | annexe 08/11 l.105, verdict b (à reprendre) : lot serveur Codex du 09 au 13/10 ; base trop vieille ; contenu absent de main au 11/11 |
| 2026-10-12 | `codex/backend-f86-archive-retention-guard` | - | 1 | non vérifié | annexe 08/11 l.104, verdict b (à reprendre) : lot serveur Codex du 09 au 13/10 ; base trop vieille ; contenu absent de main au 11/11 |
| 2026-10-12 | `codex/backend-f86-archive-listen-guard` | - | 1 | non vérifié | annexe 08/11 l.103, verdict b (à reprendre) : lot serveur Codex du 09 au 13/10 ; base trop vieille ; contenu absent de main au 11/11 |
| 2026-10-12 | `codex/backend-f86-admin-group-mutator-guards` | - | 2 | non vérifié | annexe 08/11 l.102, verdict b (à reprendre) : lot serveur Codex du 09 au 13/10 ; base trop vieille ; contenu absent de main au 11/11 |
| 2026-10-12 | `codex/backend-f70-review-fixes` | - | 34 | non vérifié | annexe 08/11 l.101, verdict b (à reprendre) : lot serveur Codex du 09 au 13/10 ; base trop vieille ; contenu absent de main au 11/11 |
| 2026-10-12 | `codex/backend-ea-role-br` | - | 2 | non vérifié | annexe 08/11 l.100, verdict b (à reprendre) : lot serveur Codex du 09 au 13/10 ; base trop vieille ; contenu absent de main au 11/11 |
| 2026-10-12 | `codex/backend-cap29-review-fixes` | - | 1 | non vérifié | annexe 08/11 l.99, verdict b (à reprendre) : lot serveur Codex du 09 au 13/10 ; base trop vieille ; contenu absent de main au 11/11 |
| 2026-10-12 | `codex/backend-c29-f86-hashes` | - | 1 | non vérifié | annexe 08/11 l.98, verdict b (à reprendre) : lot serveur Codex du 09 au 13/10 ; base trop vieille ; contenu absent de main au 11/11 |
| 2026-10-12 | `codex/backend-b09-notifs` | - | 3 | non vérifié | annexe 08/11 l.97, verdict b (à reprendre) : lot serveur Codex du 09 au 13/10 ; base trop vieille ; contenu absent de main au 11/11 |
| 2026-10-11 | `codex2/x2-19` | - | 5 | non vérifié | annexe 08/11 l.96, verdict b (à reprendre) : lot serveur Codex du 09 au 13/10 ; base trop vieille ; contenu absent de main au 11/11 |
| 2026-10-11 | `codex2/x2-13` | - | 2 | non vérifié | annexe 08/11 l.95, verdict b (à reprendre) : lot serveur Codex du 09 au 13/10 ; base trop vieille ; contenu absent de main au 11/11 |
| 2026-10-11 | `codex2/x2-12` | - | 2 | non vérifié | annexe 08/11 l.94, verdict b (à reprendre) : lot serveur Codex du 09 au 13/10 ; base trop vieille ; contenu absent de main au 11/11 |
| 2026-10-11 | `codex2/x2-11` | - | 1 | non vérifié | annexe 08/11 l.93, verdict b (à reprendre) : lot serveur Codex du 09 au 13/10 ; base trop vieille ; contenu absent de main au 11/11 |
| 2026-10-11 | `codex2/x2-09` | - | 3 | non vérifié | annexe 08/11 l.92, verdict b (à reprendre) : lot serveur Codex du 09 au 13/10 ; base trop vieille ; contenu absent de main au 11/11 |
| 2026-10-11 | `codex2/x2-08` | - | 3 | non vérifié | annexe 08/11 l.91, verdict b (à reprendre) : lot serveur Codex du 09 au 13/10 ; base trop vieille ; contenu absent de main au 11/11 |
| 2026-10-11 | `codex2/x2-07` | - | 5 | non vérifié | annexe 08/11 l.90, verdict b (à reprendre) : lot serveur Codex du 09 au 13/10 ; base trop vieille ; contenu absent de main au 11/11 |
| 2026-10-11 | `codex2/x2-06` | - | 2 | non vérifié | annexe 08/11 l.89, verdict b (à reprendre) : lot serveur Codex du 09 au 13/10 ; base trop vieille ; contenu absent de main au 11/11 |
| 2026-10-11 | `codex2/x2-05` | - | 9 | non vérifié | annexe 08/11 l.88, verdict b (à reprendre) : lot serveur Codex du 09 au 13/10 ; base trop vieille ; contenu absent de main au 11/11 |
| 2026-10-11 | `codex2/x2-04` | - | 5 | non vérifié | annexe 08/11 l.87, verdict b (à reprendre) : lot serveur Codex du 09 au 13/10 ; base trop vieille ; contenu absent de main au 11/11 |
| 2026-10-11 | `codex2/x2-03` | - | 4 | non vérifié | annexe 08/11 l.86, verdict b (à reprendre) : lot serveur Codex du 09 au 13/10 ; base trop vieille ; contenu absent de main au 11/11 |
| 2026-10-11 | `codex2/x2-02` | - | 25 | non vérifié | annexe 08/11 l.85, verdict b (à reprendre) : lot serveur Codex du 09 au 13/10 ; base trop vieille ; contenu absent de main au 11/11 |
| 2026-10-11 | `codex2/x2-01` | - | 2 | non vérifié | annexe 08/11 l.84, verdict b (à reprendre) : lot serveur Codex du 09 au 13/10 ; base trop vieille ; contenu absent de main au 11/11 |
| 2026-10-11 | `codex/backend-sec-prod-m2-fixes` | - | 17 | non vérifié | annexe 08/11 l.83, verdict b (à reprendre) : lot serveur Codex du 09 au 13/10 ; base trop vieille ; contenu absent de main au 11/11 |
| 2026-10-11 | `codex/backend-sec-prod-allowlist` | - | 30 | non vérifié | annexe 08/11 l.82, verdict b (à reprendre) : lot serveur Codex du 09 au 13/10 ; base trop vieille ; contenu absent de main au 11/11 |
| 2026-10-11 | `codex/backend-rls-disabled` | - | 1 | non vérifié | annexe 08/11 l.81, verdict b (à reprendre) : lot serveur Codex du 09 au 13/10 ; base trop vieille ; contenu absent de main au 11/11 |
| 2026-10-11 | `codex/backend-offres-adapters` | - | 15 | non vérifié | annexe 08/11 l.80, verdict b (à reprendre) : lot serveur Codex du 09 au 13/10 ; base trop vieille ; contenu absent de main au 11/11 |
| 2026-10-11 | `codex/backend-foyer-ports` | - | 15 | non vérifié | annexe 08/11 l.79, verdict b (à reprendre) : lot serveur Codex du 09 au 13/10 ; base trop vieille ; contenu absent de main au 11/11 |
| 2026-10-11 | `codex/backend-f79-allowlist` | - | 4 | non vérifié | annexe 08/11 l.78, verdict b (à reprendre) : lot serveur Codex du 09 au 13/10 ; base trop vieille ; contenu absent de main au 11/11 |
| 2026-10-11 | `codex/backend-f70-contract-publication` | - | 25 | non vérifié | annexe 08/11 l.77, verdict b (à reprendre) : lot serveur Codex du 09 au 13/10 ; base trop vieille ; contenu absent de main au 11/11 |
| 2026-10-11 | `codex/backend-f69-super-admin-controls` | - | 2 | non vérifié | annexe 08/11 l.76, verdict b (à reprendre) : lot serveur Codex du 09 au 13/10 ; base trop vieille ; contenu absent de main au 11/11 |
| 2026-10-11 | `codex/backend-f69-k65` | - | 1 | non vérifié | annexe 08/11 l.75, verdict b (à reprendre) : lot serveur Codex du 09 au 13/10 ; base trop vieille ; contenu absent de main au 11/11 |
| 2026-10-11 | `codex/backend-contract-signature-continuation` | - | 21 | non vérifié | annexe 08/11 l.74, verdict b (à reprendre) : lot serveur Codex du 09 au 13/10 ; base trop vieille ; contenu absent de main au 11/11 |
| 2026-10-11 | `codex/backend-contract-signature` | - | 1 | non vérifié | annexe 08/11 l.73, verdict b (à reprendre) : lot serveur Codex du 09 au 13/10 ; base trop vieille ; contenu absent de main au 11/11 |
| 2026-10-11 | `codex/backend-cap29-version-integrity` | - | 27 | non vérifié | annexe 08/11 l.72, verdict b (à reprendre) : lot serveur Codex du 09 au 13/10 ; base trop vieille ; contenu absent de main au 11/11 |
| 2026-10-11 | `codex/backend-cap29-library-visibility` | - | 30 | non vérifié | annexe 08/11 l.71, verdict b (à reprendre) : lot serveur Codex du 09 au 13/10 ; base trop vieille ; contenu absent de main au 11/11 |
| 2026-10-11 | `codex/backend-c25-regroupements` | - | 1 | non vérifié | annexe 08/11 l.70, verdict b (à reprendre) : lot serveur Codex du 09 au 13/10 ; base trop vieille ; contenu absent de main au 11/11 |
| 2026-10-11 | `codex/backend-c23-reprise-adapter` | - | 4 | non vérifié | annexe 08/11 l.69, verdict b (à reprendre) : lot serveur Codex du 09 au 13/10 ; base trop vieille ; contenu absent de main au 11/11 |
| 2026-10-11 | `codex/backend-c22-hardening` | - | 1 | non vérifié | annexe 08/11 l.68, verdict b (à reprendre) : lot serveur Codex du 09 au 13/10 ; base trop vieille ; contenu absent de main au 11/11 |
| 2026-10-11 | `codex/backend-c22-canon-adapter` | - | 3 | non vérifié | annexe 08/11 l.67, verdict b (à reprendre) : lot serveur Codex du 09 au 13/10 ; base trop vieille ; contenu absent de main au 11/11 |
| 2026-10-11 | `codex/backend-c22-age-presentation` | - | 287 | non vérifié | annexe 08/11 l.66, verdict b (à reprendre) : lot serveur Codex du 09 au 13/10 ; base trop vieille ; contenu absent de main au 11/11 |
| 2026-10-11 | `codex/backend-c21-kyc-verdict` | - | 15 | non vérifié | annexe 08/11 l.65, verdict b (à reprendre) : lot serveur Codex du 09 au 13/10 ; base trop vieille ; contenu absent de main au 11/11 |
| 2026-10-11 | `codex/backend-c21-kyc-access-adapter` | - | 19 | non vérifié | annexe 08/11 l.64, verdict b (à reprendre) : lot serveur Codex du 09 au 13/10 ; base trop vieille ; contenu absent de main au 11/11 |
| 2026-10-11 | `codex/backend-c17-signature-status` | - | 27 | non vérifié | annexe 08/11 l.63, verdict b (à reprendre) : lot serveur Codex du 09 au 13/10 ; base trop vieille ; contenu absent de main au 11/11 |
| 2026-10-11 | `codex/backend-b12-f84-ccr` | - | 1 | non vérifié | annexe 08/11 l.62, verdict b (à reprendre) : lot serveur Codex du 09 au 13/10 ; base trop vieille ; contenu absent de main au 11/11 |
| 2026-10-11 | `codex/backend-b09-f1-producers` | - | 25 | non vérifié | annexe 08/11 l.61, verdict b (à reprendre) : lot serveur Codex du 09 au 13/10 ; base trop vieille ; contenu absent de main au 11/11 |
| 2026-10-11 | `codex/backend-b03-b12` | - | 1 | non vérifié | annexe 08/11 l.60, verdict b (à reprendre) : lot serveur Codex du 09 au 13/10 ; base trop vieille ; contenu absent de main au 11/11 |
| 2026-10-11 | `codex/backend-adult-kyc-contract` | - | 15 | non vérifié | annexe 08/11 l.59, verdict b (à reprendre) : lot serveur Codex du 09 au 13/10 ; base trop vieille ; contenu absent de main au 11/11 |
| 2026-10-11 | `codex/backend-a81-f86` | - | 1 | non vérifié | annexe 08/11 l.58, verdict b (à reprendre) : lot serveur Codex du 09 au 13/10 ; base trop vieille ; contenu absent de main au 11/11 |
| 2026-10-11 | `codex/backend-a81-f69-hardening` | - | 17 | non vérifié | annexe 08/11 l.57, verdict b (à reprendre) : lot serveur Codex du 09 au 13/10 ; base trop vieille ; contenu absent de main au 11/11 |
| 2026-10-11 | `claude/revue-backend-codex-1` | - | 2 | non vérifié | annexe 08/11 l.24, verdict a (livrable tel quel) : verdicts des adaptateurs du 11/10 (document) ; contenu absent de main au 11/11 |
| 2026-10-11 | `claude/f86-manifeste` | - | 3 | non vérifié | annexe 08/11 l.23, verdict a (livrable tel quel) : manifeste F86 du 11/10 (document) ; contenu absent de main au 11/11 |
| 2026-10-11 | `claude/compta-recon` | - | 1 | non vérifié | annexe 08/11 l.22, verdict a (livrable tel quel) : rapport d'écart Finance/Comptable du 11/10 (document) ; contenu absent de main au 11/11 |
| 2026-10-11 | `claude/catalogue-canon-fixes` | - | 1 | non vérifié | annexe 08/11 l.21, verdict a (livrable tel quel) : catalogue de 416 fichiers docs/backend du 11/10 (document) ; contenu absent de main au 11/11 |
| 2026-10-11 | `archive/pc-2026-10-13/codex/backend-c23-reprise` | - | 5 | non vérifié | annexe 08/11 l.320, verdict d (proposé abandonné) : archive du poste du 13/10 (archive/pc-2026-10-13) ; contenu absent de main au 11/11 |
| 2026-10-11 | `archive/pc-2026-10-13/codex/backend-c11bis` | - | 45 | non vérifié | annexe 08/11 l.319, verdict d (proposé abandonné) : archive du poste du 13/10 (archive/pc-2026-10-13) ; contenu absent de main au 11/11 |
| 2026-10-10 | `ui/brand-logo-2026` | - | 1 | non vérifié | annexe 08/11 l.318, verdict d (proposé abandonné) : revue, relevé ou maquette d'avant la Boucle 1 (24/10), sans effet sur l'application ; contenu absent de main au 11/11 |
| 2026-10-10 | `docs/specs-entrantes-2026-10-10` | - | 1 | non vérifié | annexe 08/11 l.317, verdict d (proposé abandonné) : revue, relevé ou maquette d'avant la Boucle 1 (24/10), sans effet sur l'application ; contenu absent de main au 11/11 |
| 2026-10-10 | `codex/backend-passation-2026-10-10` | - | 1 | non vérifié | annexe 08/11 l.55, verdict b (à reprendre) : lot serveur Codex du 09 au 13/10 ; base trop vieille ; contenu absent de main au 11/11 |
| 2026-10-10 | `codex/backend-f1-ccr-port` | - | 20 | non vérifié | annexe 08/11 l.48, verdict b (à reprendre) : lot serveur Codex du 09 au 13/10 ; base trop vieille ; contenu absent de main au 11/11 |
| 2026-10-10 | `claude/wizardly-babbage-lmhkog` | - | 2 | non vérifié | annexe 08/11 l.20, verdict a (livrable tel quel) : 665 captures du bilan TB du 10/10 (document lourd, déconseillé) ; contenu absent de main au 11/11 |
| 2026-10-09 | `revues/2026-10-04-b061fd81` | - | 14 | non vérifié | annexe 08/11 l.316, verdict d (proposé abandonné) : revue, relevé ou maquette d'avant la Boucle 1 (24/10), sans effet sur l'application ; contenu absent de main au 11/11 |
| 2026-10-09 | `codex/backend-staging-deploy` | - | 14 | non vérifié | annexe 08/11 l.42, verdict b (à reprendre) : lot serveur Codex du 09 au 13/10 ; base trop vieille ; contenu absent de main au 11/11 |
| 2026-10-05 | `juridique/licence-code` | - | 4 | non vérifié | annexe 08/11 l.314, verdict d (proposé abandonné) : revue, relevé ou maquette d'avant la Boucle 1 (24/10), sans effet sur l'application ; contenu absent de main au 11/11 |
| 2026-10-04 | `revues/2026-10-04-01MrLWqB` | - | 4 | non vérifié | annexe 08/11 l.313, verdict d (proposé abandonné) : revue, relevé ou maquette d'avant la Boucle 1 (24/10), sans effet sur l'application ; contenu absent de main au 11/11 |
| 2026-10-04 | `corrections/c2-ea-coran` | - | 3 | non vérifié | annexe 08/11 l.311, verdict d (proposé abandonné) : revue, relevé ou maquette d'avant la Boucle 1 (24/10), sans effet sur l'application ; contenu absent de main au 11/11 |
| 2026-10-04 | `claude/collaborative-task-tracking-r47ieu` | - | 11 | non vérifié | annexe 08/11 l.19, verdict a (livrable tel quel) : revues croisées du 04/10 (document) ; contenu absent de main au 11/11 |
| 2026-10-04 | `ccr-a2ce253e-vnv87y` | - | 1 | non vérifié | annexe 08/11 l.310, verdict d (proposé abandonné) : revue, relevé ou maquette d'avant la Boucle 1 (24/10), sans effet sur l'application ; contenu absent de main au 11/11 |
| 2026-09-27 | `archive/pc-2026-10-13/adrc/m4` | - | 1 | non vérifié | annexe 08/11 l.307, verdict d (proposé abandonné) : archive du poste du 13/10 (archive/pc-2026-10-13) ; contenu absent de main au 11/11 |
| 2026-09-27 | `archive/pc-2026-10-13/adrc/m3` | - | 1 | non vérifié | annexe 08/11 l.306, verdict d (proposé abandonné) : archive du poste du 13/10 (archive/pc-2026-10-13) ; contenu absent de main au 11/11 |
| 2026-09-27 | `archive/pc-2026-10-13/adrc/m1` | - | 1 | non vérifié | annexe 08/11 l.305, verdict d (proposé abandonné) : archive du poste du 13/10 (archive/pc-2026-10-13) ; contenu absent de main au 11/11 |
| 2026-09-26 | `ui/tuteur-v1-t` | - | 35 | non vérifié | annexe 08/11 l.304, verdict d (proposé abandonné) : revue, relevé ou maquette d'avant la Boucle 1 (24/10), sans effet sur l'application ; contenu absent de main au 11/11 |
| 2026-09-26 | `reserve/theme-monochrome-k36` | - | 34 | non vérifié | annexe 08/11 l.303, verdict d (proposé abandonné) : revue, relevé ou maquette d'avant la Boucle 1 (24/10), sans effet sur l'application ; contenu absent de main au 11/11 |
| 2026-09-23 | `archive/pc-2026-10-13/integration/core24-classes-v2-remediation` | - | 15 | non vérifié | annexe 08/11 l.302, verdict d (proposé abandonné) : archive du poste du 13/10 (archive/pc-2026-10-13) ; contenu absent de main au 11/11 |

### Remplacé (87)

| Date | Branche | PR | Commits hors main | Statut | Preuve |
| :-- | :-- | :-: | --: | :-- | :-- |
| 2026-11-08 | `claude/profil-adulte-place` | 330 | 3 | REMPLACÉ par 13fc04c09 | annexe ALERTE 08/11 l.282 (relevé de E le 08/11, relayé) : chaque fichier qui diffère a été réécrit dans main depuis |
| 2026-11-08 | `claude/photo-foyer` | 326 | 4 | REMPLACÉ par ea0c3c5d0 | annexe ALERTE 08/11 l.281 (relevé de E le 08/11, relayé) : chaque fichier qui diffère a été réécrit dans main depuis |
| 2026-11-08 | `claude/notif-defaut` | 328 | 202 | REMPLACÉ par 13fc04c09 | annexe ALERTE 08/11 l.279 (relevé de E le 08/11, relayé) : chaque fichier qui diffère a été réécrit dans main depuis |
| 2026-11-08 | `claude/garde-cap-nuit-0711` | 323 | 9 | REMPLACÉ par d936adca4 | annexe ALERTE 08/11 l.278 (relevé de E le 08/11, relayé) : chaque fichier qui diffère a été réécrit dans main depuis |
| 2026-11-08 | `claude/fluidite-1-g4` | 327 | 202 | REMPLACÉ par 13fc04c09 | annexe ALERTE 08/11 l.277 (relevé de E le 08/11, relayé) : chaque fichier qui diffère a été réécrit dans main depuis |
| 2026-11-07 | `claude/suivi-eleve` | 287 | 10 | REMPLACÉ par 13fc04c09 | annexe ALERTE 08/11 l.274 (relevé de E le 08/11, relayé) : chaque fichier qui diffère a été réécrit dans main depuis |
| 2026-11-07 | `claude/selection-texte` | 293 | 8 | REMPLACÉ par 225a957da | annexe ALERTE 08/11 l.273 (relevé de E le 08/11, relayé) : chaque fichier qui diffère a été réécrit dans main depuis |
| 2026-11-07 | `claude/sans-barre-fixe` | 305 | 8 | REMPLACÉ par dbacab482 | annexe ALERTE 08/11 l.272 (relevé de E le 08/11, relayé) : chaque fichier qui diffère a été réécrit dans main depuis |
| 2026-11-07 | `claude/salle2-entretien` | 301 | 20 | REMPLACÉ par 13fc04c09 | annexe ALERTE 08/11 l.271 (relevé de E le 08/11, relayé) : chaque fichier qui diffère a été réécrit dans main depuis |
| 2026-11-07 | `claude/salle-3-accueil` | 300 | 9 | REMPLACÉ par 13fc04c09 | annexe ALERTE 08/11 l.270 (relevé de E le 08/11, relayé) : chaque fichier qui diffère a été réécrit dans main depuis |
| 2026-11-07 | `claude/salle-1-tout-ici` | 298 | 6 | REMPLACÉ par 13fc04c09 | annexe ALERTE 08/11 l.269 (relevé de E le 08/11, relayé) : chaque fichier qui diffère a été réécrit dans main depuis |
| 2026-11-07 | `claude/salle-1-suite` | 312 | 118 | REMPLACÉ par 13fc04c09 | annexe ALERTE 08/11 l.268 (relevé de E le 08/11, relayé) : SALLE-1-TOUT-ICI suite nommé dans les trains G4 et G5 |
| 2026-11-07 | `claude/remplacement-temps-reel` | 310 | 7 | REMPLACÉ par 13fc04c09 | annexe ALERTE 08/11 l.267 (relevé de E le 08/11, relayé) : chaque fichier qui diffère a été réécrit dans main depuis |
| 2026-11-07 | `claude/push-textes` | 308 | 1 | REMPLACÉ par 18d5da209 | annexe ALERTE 08/11 l.266 (relevé de E le 08/11, relayé) : chaque fichier qui diffère a été réécrit dans main depuis |
| 2026-11-07 | `claude/piece-avant-envoi` | 292 | 2 | REMPLACÉ par 13fc04c09 | annexe ALERTE 08/11 l.264 (relevé de E le 08/11, relayé) : CAND-L1B nommé dans les trains G4 et G5 |
| 2026-11-07 | `claude/nouveautes` | 285 | 9 | REMPLACÉ par 13fc04c09 | annexe ALERTE 08/11 l.263 (relevé de E le 08/11, relayé) : chaque fichier qui diffère a été réécrit dans main depuis |
| 2026-11-07 | `claude/messages-candidat` | 304 | 6 | REMPLACÉ par 13fc04c09 | annexe ALERTE 08/11 l.262 (relevé de E le 08/11, relayé) : chaque fichier qui diffère a été réécrit dans main depuis |
| 2026-11-07 | `claude/invitations-personnelles` | 311 | 5 | REMPLACÉ par 13fc04c09 | annexe ALERTE 08/11 l.261 (relevé de E le 08/11, relayé) : chaque fichier qui diffère a été réécrit dans main depuis |
| 2026-11-07 | `claude/invitation-second-adulte` | 275 | 6 | REMPLACÉ par 13fc04c09 | annexe ALERTE 08/11 l.260 (relevé de E le 08/11, relayé) : chaque fichier qui diffère a été réécrit dans main depuis |
| 2026-11-07 | `claude/harmonisation-e` | 321 | 121 | REMPLACÉ par 13fc04c09 | annexe ALERTE 08/11 l.259 (relevé de E le 08/11, relayé) : chaque fichier qui diffère a été réécrit dans main depuis |
| 2026-11-07 | `claude/fluidite-2` | - | 9 | REMPLACÉ par 225a957da | annexe ALERTE 08/11 l.117 (relevé de E le 08/11, relayé) : FLUIDITE-2 livré par la PR 349 (84eb99dcb) le 08/11 ; main en avance, ne pas fusionner (corrigé par le garde-cap) ; 2 fi |
| 2026-11-07 | `claude/fluidite-1-bouton` | 320 | 14 | REMPLACÉ par 13fc04c09 | annexe ALERTE 08/11 l.258 (relevé de E le 08/11, relayé) : reste : captures ou documents de preuve ; le lot est livré |
| 2026-11-07 | `claude/fluidite-1` | 295 | 6 | REMPLACÉ par 13fc04c09 | annexe ALERTE 08/11 l.257 (relevé de E le 08/11, relayé) : chaque fichier qui diffère a été réécrit dans main depuis |
| 2026-11-07 | `claude/dettes-ui` | 279 | 4 | REMPLACÉ par 13fc04c09 | annexe ALERTE 08/11 l.256 (relevé de E le 08/11, relayé) : chaque fichier qui diffère a été réécrit dans main depuis |
| 2026-11-07 | `claude/cand-photo` | - | 2 | REMPLACÉ par 13fc04c09 | annexe ALERTE 08/11 l.255 (relevé de E le 08/11, relayé) : reste : captures ou documents de preuve ; le lot est livré |
| 2026-11-07 | `claude/cahiers-par-seance` | 276 | 5 | REMPLACÉ par 13fc04c09 | annexe ALERTE 08/11 l.254 (relevé de E le 08/11, relayé) : chaque fichier qui diffère a été réécrit dans main depuis |
| 2026-11-07 | `claude/cadre-ecran` | 296 | 9 | REMPLACÉ par 13fc04c09 | annexe ALERTE 08/11 l.252 (relevé de E le 08/11, relayé) : chaque fichier qui diffère a été réécrit dans main depuis |
| 2026-11-07 | `claude/bouton-attente` | 286 | 7 | REMPLACÉ par 225a957da | annexe ALERTE 08/11 l.251 (relevé de E le 08/11, relayé) : reste : captures ou documents de preuve ; le lot est livré |
| 2026-11-07 | `claude/accords-lisez-bas` | - | 32 | REMPLACÉ par 13fc04c09 | annexe ALERTE 08/11 l.250 (relevé de E le 08/11, relayé) : SALLE-1 lot 4 nommé dans les trains G4 et G5 ; reste : captures |
| 2026-11-05 | `train/2026-11-06-photos` | 244 | 2 | REMPLACÉ par b02056ec8 | annexe ALERTE 08/11 l.249 (relevé de E le 08/11, relayé) : reste : captures ou documents de preuve ; le lot est livré |
| 2026-11-04 | `train/2026-11-04` | - | 1 | REMPLACÉ par 13fc04c09 | annexe ALERTE 08/11 l.248 (relevé de E le 08/11, relayé) : chaque fichier qui diffère a été réécrit dans main depuis |
| 2026-11-03 | `claude/photos-ecrans` | - | 4 | REMPLACÉ par 13fc04c09 | annexe ALERTE 08/11 l.116 (relevé de E le 08/11, relayé) : PHOTOS-2a livré sous 20261109300000_photos_2a_fermer_ecriture_avatar.sql (e7b9ce49c, PR 212), dans main et en production |
| 2026-11-03 | `claude/onboarding-fin-sauvegarde` | - | 1 | REMPLACÉ par 13fc04c09 | annexe ALERTE 08/11 l.224 (relevé de E le 08/11, relayé) : reste : captures ou documents de preuve ; le lot est livré |
| 2026-11-03 | `claude/ci-scenarios-03-11` | - | 1 | REMPLACÉ par 4b9980cb6 | annexe ALERTE 08/11 l.209 (relevé de E le 08/11, relayé) : chaque fichier qui diffère a été réécrit dans main depuis |
| 2026-10-30 | `rewayahacademy-glitch-patch-5` | - | 1 | REMPLACÉ par 4b9980cb6 | annexe ALERTE 08/11 l.157 (relevé de E le 08/11, relayé) : chaque fichier qui diffère a été réécrit dans main depuis |
| 2026-10-26 | `rewayahacademy-glitch-patch-2` | - | 1 | REMPLACÉ par 48f0bde6d | annexe ALERTE 08/11 l.156 (relevé de E le 08/11, relayé) : chaque fichier qui diffère a été réécrit dans main depuis |
| 2026-10-26 | `rewayahacademy-glitch-patch-1` | - | 1 | REMPLACÉ par 48f0bde6d | annexe ALERTE 08/11 l.155 (relevé de E le 08/11, relayé) : chaque fichier qui diffère a été réécrit dans main depuis |
| 2026-10-25 | `claude/admiring-brown-r6ai72-relais` | - | 12 | REMPLACÉ par 13fc04c09 | annexe ALERTE 08/11 l.154 (relevé de E le 08/11, relayé) : chaque fichier qui diffère a été réécrit dans main depuis |
| 2026-10-25 | `claude/admiring-brown-r6ai72-passation` | - | 1 | REMPLACÉ par cef3a65f3 | annexe ALERTE 08/11 l.153 (relevé de E le 08/11, relayé) : chaque fichier qui diffère a été réécrit dans main depuis |
| 2026-10-24 | `claude/lucid-mccarthy-qpk6yq` | 45,50 | 17 | REMPLACÉ par 0081ee309 | annexe ALERTE 08/11 l.152 (relevé de E le 08/11, relayé) : socle CANDIDATURES du 24/10 (PR 45 et 50 ouvertes), repris par les lots candidats livrés depuis |
| 2026-10-13 | `codex/backend-c21-negative-context-r1` | - | 1 | REMPLACÉ par 5fd08c31d | annexe ALERTE 08/11 l.151 (relevé de E le 08/11, relayé) : chaque fichier qui diffère a été réécrit dans main depuis |
| 2026-10-13 | `codex/backend-c04-negative-context-r1` | - | 1 | REMPLACÉ par b9af42c6c | annexe ALERTE 08/11 l.150 (relevé de E le 08/11, relayé) : chaque fichier qui diffère a été réécrit dans main depuis |
| 2026-10-13 | `codex/backend-b09-notifications-sources` | - | 1 | REMPLACÉ par 18d5da209 | annexe ALERTE 08/11 l.149 (relevé de E le 08/11, relayé) : chaque fichier qui diffère a été réécrit dans main depuis |
| 2026-10-13 | `claude/beautiful-ptolemy-xmhiki` | 34 | 4 | REMPLACÉ par main (voir le tri) | PR 34 fermée le 2026-11-08 sur la proposition « FERMER » de TRI-PR-AVANT-25-10 l.68 |
| 2026-10-12 | `codex2/imm-back-1-wip` | - | 1 | REMPLACÉ par 410d29579 | annexe ALERTE 08/11 l.148 (relevé de E le 08/11, relayé) : chaque fichier qui diffère a été réécrit dans main depuis |
| 2026-10-12 | `codex2/imm-back-1` | - | 1 | REMPLACÉ par 410d29579 | annexe ALERTE 08/11 l.147 (relevé de E le 08/11, relayé) : chaque fichier qui diffère a été réécrit dans main depuis |
| 2026-10-12 | `codex/backend-rech-d3-enseignants` | - | 5 | REMPLACÉ par 81c838165 | annexe ALERTE 08/11 l.146 (relevé de E le 08/11, relayé) : chaque fichier qui diffère a été réécrit dans main depuis |
| 2026-10-12 | `codex/backend-f86-b18-negative-cases` | - | 2 | REMPLACÉ par e3f52ffa1 | annexe ALERTE 08/11 l.145 (relevé de E le 08/11, relayé) : chaque fichier qui diffère a été réécrit dans main depuis |
| 2026-10-12 | `codex/backend-cap29-back-2` | - | 5 | REMPLACÉ par 291249c7f | annexe ALERTE 08/11 l.144 (relevé de E le 08/11, relayé) : chaque fichier qui diffère a été réécrit dans main depuis |
| 2026-10-12 | `codex/backend-c29-port-wiring` | - | 1 | REMPLACÉ par 0081ee309 | annexe ALERTE 08/11 l.143 (relevé de E le 08/11, relayé) : chaque fichier qui diffère a été réécrit dans main depuis |
| 2026-10-12 | `codex/backend-b09-events-destinations-r2` | - | 1 | REMPLACÉ par 355ba7dee | annexe ALERTE 08/11 l.142 (relevé de E le 08/11, relayé) : chaque fichier qui diffère a été réécrit dans main depuis |
| 2026-10-11 | `codex2/x2-10` | - | 2 | REMPLACÉ par bab82154f | annexe ALERTE 08/11 l.141 (relevé de E le 08/11, relayé) : chaque fichier qui diffère a été réécrit dans main depuis |
| 2026-10-11 | `codex/backend-recherche-classes` | - | 1 | REMPLACÉ par ad1e4c28a | annexe ALERTE 08/11 l.140 (relevé de E le 08/11, relayé) : chaque fichier qui diffère a été réécrit dans main depuis |
| 2026-10-11 | `codex/backend-f70-status-tests` | - | 1 | REMPLACÉ par d2f4561eb | annexe ALERTE 08/11 l.139 (relevé de E le 08/11, relayé) : chaque fichier qui diffère a été réécrit dans main depuis |
| 2026-10-11 | `codex/backend-cap29-catalogue` | - | 4 | REMPLACÉ par 291249c7f | annexe ALERTE 08/11 l.138 (relevé de E le 08/11, relayé) : chaque fichier qui diffère a été réécrit dans main depuis |
| 2026-10-11 | `codex/backend-c29-tirage` | - | 4 | REMPLACÉ par 4b9980cb6 | annexe ALERTE 08/11 l.137 (relevé de E le 08/11, relayé) : chaque fichier qui diffère a été réécrit dans main depuis |
| 2026-10-11 | `codex/backend-b18-ci-state` | - | 1 | REMPLACÉ par e3f52ffa1 | annexe ALERTE 08/11 l.136 (relevé de E le 08/11, relayé) : chaque fichier qui diffère a été réécrit dans main depuis |
| 2026-10-11 | `codex/backend-b09-notifications` | - | 8 | REMPLACÉ par 4b9980cb6 | annexe ALERTE 08/11 l.135 (relevé de E le 08/11, relayé) : chaque fichier qui diffère a été réécrit dans main depuis |
| 2026-10-11 | `codex/backend-b09-adaptateur` | - | 1 | REMPLACÉ par 355ba7dee | annexe ALERTE 08/11 l.134 (relevé de E le 08/11, relayé) : chaque fichier qui diffère a été réécrit dans main depuis |
| 2026-10-11 | `codex/backend-b04-reprise` | - | 3 | REMPLACÉ par ea1a0da98 | annexe ALERTE 08/11 l.133 (relevé de E le 08/11, relayé) : chaque fichier qui diffère a été réécrit dans main depuis |
| 2026-10-11 | `codex/backend-al01-05-f86` | - | 3 | REMPLACÉ par b2a59b705 | annexe ALERTE 08/11 l.132 (relevé de E le 08/11, relayé) : chaque fichier qui diffère a été réécrit dans main depuis |
| 2026-10-11 | `codex/backend-a81-c24-adapter` | - | 1 | REMPLACÉ par aa68b38c9 | annexe ALERTE 08/11 l.131 (relevé de E le 08/11, relayé) : chaque fichier qui diffère a été réécrit dans main depuis |
| 2026-10-11 | `claude/mushaf-15l-captures` | - | 1 | REMPLACÉ par c025d5da0 | annexe ALERTE 08/11 l.130 (relevé de E le 08/11, relayé) : reste : captures ou documents de preuve ; le lot est livré |
| 2026-10-11 | `claude/br1-branchement` | - | 2 | REMPLACÉ par 13fc04c09 | annexe ALERTE 08/11 l.129 (relevé de E le 08/11, relayé) : chaque fichier qui diffère a été réécrit dans main depuis |
| 2026-10-10 | `codex/backend-notifications` | - | 6 | REMPLACÉ par 355ba7dee | annexe ALERTE 08/11 l.127 (relevé de E le 08/11, relayé) : chaque fichier qui diffère a été réécrit dans main depuis |
| 2026-10-10 | `codex/backend-lota-ledger-provenance` | 32 | 3 | REMPLACÉ par main (voir le tri) | PR 32 fermée le 2026-11-08 sur la proposition « FERMER » de TRI-PR-AVANT-25-10 l.67 |
| 2026-10-10 | `codex/backend-lot-f1` | 13,19 | 98 | REMPLACÉ par main (voir le tri) | PR 13 fermée le 2026-11-08 sur la proposition « FERMER » de TRI-PR-AVANT-25-10 l.53 |
| 2026-10-10 | `codex/backend-lot-c-staging-api` | 20 | 115 | REMPLACÉ par main (voir le tri) | PR 20 fermée le 2026-11-08 sur la proposition « FERMER » de TRI-PR-AVANT-25-10 l.55 |
| 2026-10-10 | `codex/backend-lot-a-manifest` | 25 | 4 | REMPLACÉ par main (voir le tri) | PR 25 fermée le 2026-11-08 sur la proposition « FERMER » de TRI-PR-AVANT-25-10 l.60 |
| 2026-10-10 | `codex/backend-f2-b13-admin-rls` | 17 | 58 | REMPLACÉ par main (voir le tri) | PR 17 fermée le 2026-11-08 sur la proposition « FERMER » de TRI-PR-AVANT-25-10 l.54 |
| 2026-10-10 | `codex/backend-f2-after-c` | 21 | 282 | REMPLACÉ par main (voir le tri) | PR 21 fermée le 2026-11-08 sur la proposition « FERMER » de TRI-PR-AVANT-25-10 l.56 |
| 2026-10-10 | `codex/backend-f1-ccr-8ea7831` | 29,33 | 2 | REMPLACÉ par main (voir le tri) | PR 29 fermée le 2026-11-08 sur la proposition « FERMER » de TRI-PR-AVANT-25-10 l.64 |
| 2026-10-10 | `codex/backend-blueprint` | 24 | 5 | REMPLACÉ par main (voir le tri) | PR 24 fermée le 2026-11-08 sur la proposition « FERMER (à archiver si besoin) » de TRI-PR-AVANT-25-10 l.59 |
| 2026-10-10 | `codex/backend-b20-ccr-8ea7831` | 30 | 2 | REMPLACÉ par main (voir le tri) | PR 30 fermée le 2026-11-08 sur la proposition « FERMER » de TRI-PR-AVANT-25-10 l.65 |
| 2026-10-10 | `codex/backend-b20-agent-identity` | 28 | 7 | REMPLACÉ par main (voir le tri) | PR 28 fermée le 2026-11-08 sur la proposition « FERMER » de TRI-PR-AVANT-25-10 l.63 |
| 2026-10-10 | `codex/backend-b13-ci-ccr` | 27 | 5 | REMPLACÉ par 4b9980cb6 | annexe ALERTE 08/11 l.126 (relevé de E le 08/11, relayé) : chaque fichier qui diffère a été réécrit dans main depuis |
| 2026-10-10 | `codex/backend-b13-ccr-8ea7831` | 31 | 3 | REMPLACÉ par 4b9980cb6 | annexe ALERTE 08/11 l.125 (relevé de E le 08/11, relayé) : chaque fichier qui diffère a été réécrit dans main depuis |
| 2026-10-10 | `codex/backend-b13-admin-suspended` | 23 | 3 | REMPLACÉ par main (voir le tri) | PR 23 fermée le 2026-11-08 sur la proposition « FERMER » de TRI-PR-AVANT-25-10 l.58 |
| 2026-10-10 | `claude/com-suite` | - | 3 | REMPLACÉ par 13fc04c09 | annexe ALERTE 08/11 l.124 (relevé de E le 08/11, relayé) : décisions en attente du 10/10, remplacées par CONSIGNES-DIRECTEUR-EN-VIGUEUR et 08 §5 bis |
| 2026-10-09 | `codex/backend-lot-c` | 10 | 14 | REMPLACÉ par main (voir le tri) | PR 10 fermée le 2026-11-08 sur la proposition « FERMER » de TRI-PR-AVANT-25-10 l.52 |
| 2026-10-08 | `codex/site-public-preview-main` | 8 | 1 | REMPLACÉ par 48f0bde6d | annexe ALERTE 08/11 l.123 (relevé de E le 08/11, relayé) : chaque fichier qui diffère a été réécrit dans main depuis |
| 2026-09-28 | `ui/essai-ci-d2` | 7 | 1 | REMPLACÉ par main (voir le tri) | PR 7 fermée le 2026-11-08 sur la proposition « FERMER » de TRI-PR-AVANT-25-10 l.50 |
| 2026-09-28 | `claude/modest-hopper-hj96t5` | 7 | 1 | REMPLACÉ par 4b9980cb6 | annexe ALERTE 08/11 l.122 (relevé de E le 08/11, relayé) : chaque fichier qui diffère a été réécrit dans main depuis |
| 2026-09-28 | `claude/essai-ci-d2` | 6 | 2 | REMPLACÉ par 4b9980cb6 | annexe ALERTE 08/11 l.121 (relevé de E le 08/11, relayé) : chaque fichier qui diffère a été réécrit dans main depuis |
| 2026-09-27 | `claude/confident-mayer-m2fqsl` | 5 | 2 | REMPLACÉ par main (voir le tri) | PR 5 fermée le 2026-11-08 sur la proposition « FERMER (rapport à archiver si le pilote veut la trace) » de TRI-PR-AVANT-25-10 l.49 |
| 2026-09-23 | `v0/verite-produit` | - | 1 | REMPLACÉ par f53bfdde0 | annexe ALERTE 08/11 l.120 (relevé de E le 08/11, relayé) : chaque fichier qui diffère a été réécrit dans main depuis |
| 2026-09-23 | `nettoyage/base-2026-09-23` | - | 2 | REMPLACÉ par f53bfdde0 | annexe ALERTE 08/11 l.119 (relevé de E le 08/11, relayé) : chaque fichier qui diffère a été réécrit dans main depuis |

### Abandonné (15)

| Date | Branche | PR | Commits hors main | Statut | Preuve |
| :-- | :-- | :-: | --: | :-- | :-- |
| 2026-09-22 | `lot/onboarding-offres` | - | 1 | ABANDONNÉ (remise à plat du 23/09/2026) | annexe ALERTE 08/11 l.301 : avant la remise à plat du 23/09 |
| 2026-09-22 | `core24/fable-frontend` | - | 2 | ABANDONNÉ (remise à plat du 23/09/2026) | annexe ALERTE 08/11 l.300 : avant la remise à plat du 23/09 |
| 2026-09-22 | `archive/pc-2026-10-13/integration/core24-classes-v2` | - | 10 | ABANDONNÉ (remise à plat du 23/09/2026) | annexe ALERTE 08/11 l.299 : avant la remise à plat du 23/09 |
| 2026-09-22 | `archive/pc-2026-10-13/docs/core24-classes-arbitration` | - | 2 | ABANDONNÉ (remise à plat du 23/09/2026) | annexe ALERTE 08/11 l.298 : avant la remise à plat du 23/09 |
| 2026-09-22 | `archive/pc-2026-10-13/astra/core24-v2` | - | 17 | ABANDONNÉ (remise à plat du 23/09/2026) | annexe ALERTE 08/11 l.297 : avant la remise à plat du 23/09 |
| 2026-09-22 | `archive/pc-2026-10-13/astra/core24-presence-safeguard` | - | 18 | ABANDONNÉ (remise à plat du 23/09/2026) | annexe ALERTE 08/11 l.296 : avant la remise à plat du 23/09 |
| 2026-09-22 | `archive/pc-2026-10-13/astra/core24-classes-legacy-snapshot` | - | 19 | ABANDONNÉ (remise à plat du 23/09/2026) | annexe ALERTE 08/11 l.295 : avant la remise à plat du 23/09 |
| 2026-09-21 | `observation/lot-2026-09-21` | - | 11 | ABANDONNÉ (remise à plat du 23/09/2026) | annexe ALERTE 08/11 l.294 : avant la remise à plat du 23/09 |
| 2026-09-21 | `archive/pc-2026-10-13/sauvegarde/r2-du-tiers` | - | 1 | ABANDONNÉ (remise à plat du 23/09/2026) | annexe ALERTE 08/11 l.293 : avant la remise à plat du 23/09 |
| 2026-09-20 | `teaching-core/0-coordinateur` | - | 2 | ABANDONNÉ (remise à plat du 23/09/2026) | annexe ALERTE 08/11 l.292 : avant la remise à plat du 23/09 |
| 2026-09-15 | `archive/pc-2026-10-13/codex/vague5-integration` | - | 7 | ABANDONNÉ (remise à plat du 23/09/2026) | annexe ALERTE 08/11 l.291 : avant la remise à plat du 23/09 |
| 2026-09-15 | `archive/pc-2026-10-13/codex/presence-correction-ui` | - | 1 | ABANDONNÉ (remise à plat du 23/09/2026) | annexe ALERTE 08/11 l.290 : avant la remise à plat du 23/09 |
| 2026-09-15 | `archive/pc-2026-10-13/codex/login-demo` | - | 1 | ABANDONNÉ (remise à plat du 23/09/2026) | annexe ALERTE 08/11 l.289 : avant la remise à plat du 23/09 |
| 2026-09-14 | `archive/pc-2026-10-13/codex/r2-adaptive-shell` | - | 4 | ABANDONNÉ (remise à plat du 23/09/2026) | annexe ALERTE 08/11 l.288 : avant la remise à plat du 23/09 |
| 2026-09-13 | `codex/r1-adaptive-design-system` | - | 1 | ABANDONNÉ (remise à plat du 23/09/2026) | annexe ALERTE 08/11 l.287 : avant la remise à plat du 23/09 |

### Livré (contenu déjà dans `main`, mesuré le 11/11) (17)

| Date | Branche | PR | Commits hors main | Statut | Preuve |
| :-- | :-- | :-: | --: | :-- | :-- |
| 2026-11-07 | `rewayahacademy-glitch-patch-13` | 265 | 6 | LIVRÉ (contenu dans main) | 11/11 : le diff de la branche se réapplique à l'envers sur main b86dbc9d sans conflit (git apply -R --check) |
| 2026-11-07 | `claude/purge-cron` | 316 | 1 | LIVRÉ (contenu dans main) | 11/11 : le diff de la branche se réapplique à l'envers sur main b86dbc9d sans conflit (git apply -R --check) |
| 2026-11-07 | `claude/perf-index-session-events` | 318 | 1 | LIVRÉ (contenu dans main) | 11/11 : le diff de la branche se réapplique à l'envers sur main b86dbc9d sans conflit (git apply -R --check) |
| 2026-11-07 | `claude/perf-fuseaux` | 325 | 1 | LIVRÉ (contenu dans main) | 11/11 : le diff de la branche se réapplique à l'envers sur main b86dbc9d sans conflit (git apply -R --check) |
| 2026-11-07 | `claude/perf-enseignants-public` | 324 | 1 | LIVRÉ (contenu dans main) | 11/11 : le diff de la branche se réapplique à l'envers sur main b86dbc9d sans conflit (git apply -R --check) |
| 2026-11-07 | `claude/mesure-fluidite-selection` | - | 1 | LIVRÉ (contenu dans main) | 11/11 : le diff de la branche se réapplique à l'envers sur main b86dbc9d sans conflit (git apply -R --check) |
| 2026-11-07 | `claude/etat-dossier-photo` | 317 | 1 | LIVRÉ (contenu dans main) | 11/11 : le diff de la branche se réapplique à l'envers sur main b86dbc9d sans conflit (git apply -R --check) |
| 2026-11-07 | `claude/cadre-langues` | 313 | 2 | LIVRÉ (contenu dans main) | 11/11 : le diff de la branche se réapplique à l'envers sur main b86dbc9d sans conflit (git apply -R --check) |
| 2026-10-13 | `archive/pc-2026-10-13/patchs` | - | 2 | LIVRÉ (rien hors de main) | 11/11 : diff nul entre la branche et sa base commune avec main |
| 2026-10-12 | `codex2/imm-accueil-back-phase2-wip` | - | 1 | LIVRÉ (contenu dans main) | 11/11 : le diff de la branche se réapplique à l'envers sur main b86dbc9d sans conflit (git apply -R --check) |
| 2026-10-12 | `codex/backend-kyc-lecture-1` | - | 2 | LIVRÉ (contenu dans main) | 11/11 : le diff de la branche se réapplique à l'envers sur main b86dbc9d sans conflit (git apply -R --check) |
| 2026-10-12 | `codex/backend-c22-presentation-adapter-safe` | - | 1 | LIVRÉ (rien hors de main) | 11/11 : diff nul entre la branche et sa base commune avec main |
| 2026-10-12 | `codex/backend-c11bis-f74-canon` | - | 1 | LIVRÉ (rien hors de main) | 11/11 : diff nul entre la branche et sa base commune avec main |
| 2026-10-09 | `pilotage/tuteur-v1` | - | 341 | LIVRÉ (rien hors de main) | 11/11 : diff nul entre la branche et sa base commune avec main |
| 2026-10-04 | `projet/ressources` | - | 16 | LIVRÉ (rien hors de main) | 11/11 : diff nul entre la branche et sa base commune avec main |
| 2026-09-09 | `specs` | - | 1 | LIVRÉ (rien hors de main) | 11/11 : diff nul entre la branche et sa base commune avec main |
| 2026-09-09 | `refactor-ui-lavender-3628477128789856989` | 1 | 3 | LIVRÉ (rien hors de main) | 11/11 : diff nul entre la branche et sa base commune avec main |

## Sortie du script (11/11/2026, vrai clone, historique complet)

```
Relevé du 2026-11-11T11:54Z, main = b86dbc9d9
Branches hors de main : 447
  livrées (PR fusionnée)      : 206
  PR non fusionnée            : 75
  commits hors de main sans PR : 166

date	branche	PR	statut	commits hors main
2026-11-11	claude/zealous-tesla-ewstzw	409	PR non fusionnée	77
2026-11-11	claude/transitions-travail	-	sans PR	1
2026-11-11	claude/titulaire-sans-appareil	432	PR non fusionnée	1
2026-11-11	claude/sourates-travail	-	sans PR	3
2026-11-11	claude/sombre-sans-eclair	430	PR non fusionnée	5
2026-11-11	claude/selection-retiree	418	livrée	3
2026-11-11	claude/retirer-absence-detectee	429	PR non fusionnée	2
2026-11-11	claude/proposition-progression-sourates	421	PR non fusionnée	1
2026-11-11	claude/progression-adulte-travail	-	sans PR	5
2026-11-11	claude/profils-p1-travail	-	sans PR	1
2026-11-11	claude/profil-eleve-deja-ouvrir	423	livrée	8
2026-11-11	claude/nav-panneau	413	livrée	7
2026-11-11	claude/nav-liquide	407	livrée	13
2026-11-11	claude/nav-halo-salle	410	livrée	5
2026-11-11	claude/nav-halo-compte	406	livrée	17
2026-11-11	claude/nav-direction	415	livrée	5
2026-11-11	claude/lumiere-vert	428	livrée	7
2026-11-11	claude/lumiere-retard	419	livrée	5
2026-11-11	claude/lumiere-douce	425	livrée	6
2026-11-11	claude/lumiere-accueils-vert	-	sans PR	3
2026-11-11	claude/lumiere-accueils-3-4	414	livrée	6
2026-11-11	claude/lumiere-accueils-1	417	livrée	4
2026-11-11	claude/lumiere-3-absents	424	livrée	7
2026-11-11	claude/liquide-matiere	420	livrée	5
2026-11-11	claude/inventaire-non-branche-1111	427	livrée	2
2026-11-11	claude/halo-lumiere	411	livrée	7
2026-11-11	claude/halo-adulte	412	livrée	2
2026-11-11	claude/goutte-huile	433	PR non fusionnée	3
2026-11-11	claude/fix-clignote-demande	431	PR non fusionnée	1
2026-11-11	claude/entetes-telephone	408	livrée	16
2026-11-11	claude/bande-suite-travail	-	sans PR	11
2026-11-11	claude/bande-barre	426	PR non fusionnée	8
2026-11-11	claude/alertes-bloquees-retard	416	livrée	2
2026-11-11	claude/accueil-chargement	422	livrée	11
2026-11-10	claude/nav-cercle-ressort	405	livrée	10
2026-11-10	claude/nav-cercle-compte	403	livrée	2
2026-11-10	claude/nav-barre-sans-aplat	404	livrée	8
2026-11-10	claude/a-faire-lumiere-accueils	402	livrée	4
2026-11-09	claude/onboarding-tuteur-entree	398	livrée	1
2026-11-09	claude/nav-barre-flottante	401	livrée	5
2026-11-09	claude/mes-classes-details	397	livrée	2
2026-11-09	claude/invitation-accueil	399	livrée	12
2026-11-09	claude/accueil-tuteur-une-porte	400	livrée	1
2026-11-08	claude/tri-pr-avant-25-10	389	livrée	1
2026-11-08	claude/train-g5	332	livrée	237
2026-11-08	claude/train-g4	319	livrée	205
2026-11-08	claude/suppression-toleres	388	livrée	2
2026-11-08	claude/source-commun-reussite	340	livrée	1
2026-11-08	claude/signaler-depuis-salle	364	livrée	8
2026-11-08	claude/scenarios-horloge-sessions	370	livrée	4
2026-11-08	claude/scenarios-cand-com-ma-candidature	360	livrée	1
2026-11-08	claude/rythme-lecture	373	livrée	5
2026-11-08	claude/roster-remplacant	393	livrée	1
2026-11-08	claude/rls-tables-private	338	livrée	1
2026-11-08	claude/revenus-2-main	353	livrée	10
2026-11-08	claude/retour-eclair	354	livrée	4
2026-11-08	claude/reprise-cand-4	396	livrée	5
2026-11-08	claude/reprise-cand-3	392	livrée	3
2026-11-08	claude/reprise-cand-1	390	livrée	7
2026-11-08	claude/recherche-livraison	347	livrée	4
2026-11-08	claude/recherche-fils-comptable	361	livrée	1
2026-11-08	claude/recherche-d2	351	livrée	3
2026-11-08	claude/proposition-harmoniser-argent	337	livrée	3
2026-11-08	claude/projection-eleves	395	livrée	4
2026-11-08	claude/progression-adulte	380	PR non fusionnée	4
2026-11-08	claude/profil-adulte-place	330	PR non fusionnée	3
2026-11-08	claude/prevue-minuscule	384	livrée	3
2026-11-08	claude/preuves-suppression	383	livrée	2
2026-11-08	claude/photo-lecture-courante	358	livrée	1
2026-11-08	claude/photo-foyer	326	PR non fusionnée	4
2026-11-08	claude/photo-figee-main	357	livrée	14
2026-11-08	claude/page-push1-main	355	livrée	1
2026-11-08	claude/notifs-l6-horloge	334	livrée	1
2026-11-08	claude/notif-retenu	339	livrée	5
2026-11-08	claude/notif-defaut	328	PR non fusionnée	202
2026-11-08	claude/noms-classes	350	livrée	13
2026-11-08	claude/nom-latin-candidat	391	livrée	3
2026-11-08	claude/nb-observations-classe	348	livrée	4
2026-11-08	claude/mon-espace-guide	375	livrée	6
2026-11-08	claude/mesure-lecture	371	livrée	6
2026-11-08	claude/ma-progression-fiche	381	livrée	4
2026-11-08	claude/ma-progression	382	PR non fusionnée	3
2026-11-08	claude/inventaire-non-livres	345	livrée	6
2026-11-08	claude/hygiene-gardes	372	livrée	10
2026-11-08	claude/hygiene-2	374	livrée	7
2026-11-08	claude/horloge-2	394	livrée	1
2026-11-08	claude/harmonisation-a	329	PR non fusionnée	2
2026-11-08	claude/garde-versements	368	livrée	6
2026-11-08	claude/garde-compte-desactive	365	livrée	7
2026-11-08	claude/garde-cap-reservations-0811d	362	livrée	1
2026-11-08	claude/garde-cap-reservations-0811c	356	livrée	7
2026-11-08	claude/garde-cap-reservations-0811b	352	livrée	5
2026-11-08	claude/garde-cap-reservations-0811	346	livrée	3
2026-11-08	claude/garde-cap-registre-0811f	386	livrée	1
2026-11-08	claude/garde-cap-registre-0811e	379	livrée	2
2026-11-08	claude/garde-cap-registre-0811	333	livrée	3
2026-11-08	claude/garde-cap-nuit-0711	323	PR non fusionnée	9
2026-11-08	claude/frise-heure-serveur	369	livrée	6
2026-11-08	claude/frise-heure-murale-client	385	livrée	1
2026-11-08	claude/frise-heure-client	363	livrée	4
2026-11-08	claude/formule-vitesse-unique	378	livrée	9
2026-11-08	claude/fn025-horloge	367	livrée	1
2026-11-08	claude/fluidite-reglages-foyer	343	livrée	1
2026-11-08	claude/fluidite-foyer	341	livrée	1
2026-11-08	claude/fluidite-2-main	349	livrée	3
2026-11-08	claude/fluidite-1-g4	327	PR non fusionnée	202
2026-11-08	claude/fix-mdp-enfant	331	livrée	1
2026-11-08	claude/fiche-eleve-salle	376	livrée	4
2026-11-08	claude/d2-retrait-profil	342	livrée	1
2026-11-08	claude/curseur-clic	387	livrée	1
2026-11-08	claude/classe-minuscule-main	359	livrée	1
2026-11-08	claude/champ-obligatoire-2	344	livrée	6
2026-11-08	claude/champ-obligatoire	336	livrée	5
2026-11-08	claude/cahier-c3-sans-tx	335	livrée	1
2026-11-07	rewayahacademy-glitch-patch-13	265	PR non fusionnée	6
2026-11-07	claude/vigilant-pascal-utfgbs	314	PR non fusionnée	29
2026-11-07	claude/train-g3	315	livrée	78
2026-11-07	claude/train-g2	307	livrée	20
2026-11-07	claude/suivi-eleve	287	PR non fusionnée	10
2026-11-07	claude/selection-texte	293	PR non fusionnée	8
2026-11-07	claude/sans-barre-fixe	305	PR non fusionnée	8
2026-11-07	claude/salle2-entretien	301	PR non fusionnée	20
2026-11-07	claude/salle-3-accueil	300	PR non fusionnée	9
2026-11-07	claude/salle-1-tout-ici	298	PR non fusionnée	6
2026-11-07	claude/salle-1-suite	312	PR non fusionnée	118
2026-11-07	claude/revenus	-	sans PR	3
2026-11-07	claude/remplacement-temps-reel	310	PR non fusionnée	7
2026-11-07	claude/push-textes	308	PR non fusionnée	1
2026-11-07	claude/push-1	284	livrée	9
2026-11-07	claude/purge-cron	316	PR non fusionnée	1
2026-11-07	claude/piece-avant-envoi	292	PR non fusionnée	2
2026-11-07	claude/photo-candidature-figee	-	sans PR	2
2026-11-07	claude/perf-index-session-events	318	PR non fusionnée	1
2026-11-07	claude/perf-fuseaux	325	PR non fusionnée	1
2026-11-07	claude/perf-enseignants-public	324	PR non fusionnée	1
2026-11-07	claude/page-salle3	-	sans PR	3
2026-11-07	claude/page-push1	-	sans PR	2
2026-11-07	claude/nouveautes	285	PR non fusionnée	9
2026-11-07	claude/methode-pilote-garde	322	PR non fusionnée	1
2026-11-07	claude/mesure-fluidite-selection	-	sans PR	1
2026-11-07	claude/messages-candidat	304	PR non fusionnée	6
2026-11-07	claude/invitations-personnelles	311	PR non fusionnée	5
2026-11-07	claude/invitation-second-adulte	275	PR non fusionnée	6
2026-11-07	claude/harmoniser-argent	-	sans PR	1
2026-11-07	claude/harmonisation-e	321	PR non fusionnée	121
2026-11-07	claude/fluidite-2	-	sans PR	9
2026-11-07	claude/fluidite-1-bouton	320	PR non fusionnée	14
2026-11-07	claude/fluidite-1	295	PR non fusionnée	6
2026-11-07	claude/etat-dossier-photo	317	PR non fusionnée	1
2026-11-07	claude/dettes-ui	279	PR non fusionnée	4
2026-11-07	claude/ci-propose	-	sans PR	3
2026-11-07	claude/cand-photo	-	sans PR	2
2026-11-07	claude/cahiers-par-seance	276	PR non fusionnée	5
2026-11-07	claude/cadre-migrations	294	livrée	5
2026-11-07	claude/cadre-langues	313	PR non fusionnée	2
2026-11-07	claude/cadre-ecran	296	PR non fusionnée	9
2026-11-07	claude/brouillon-persistant	281	PR non fusionnée	6
2026-11-07	claude/bouton-attente	286	PR non fusionnée	7
2026-11-07	claude/admiring-brown-r6ai72	-	sans PR	9
2026-11-07	claude/accords-lisez-bas	-	sans PR	32
2026-11-06	claude/classe-minuscule	-	sans PR	4
2026-11-05	train/2026-11-06-photos	244	PR non fusionnée	2
2026-11-04	train/2026-11-04	-	sans PR	1
2026-11-04	claude/v2a-bis-personne-occupee	223	livrée	3
2026-11-04	claude/regle-trains-p5	228	livrée	2
2026-11-04	claude/photos-2b	225	livrée	10
2026-11-04	claude/photos-2a	212	livrée	5
2026-11-04	claude/p5-pousser-peu	233	livrée	2
2026-11-04	claude/mfa-direction	211	livrée	6
2026-11-04	claude/garde-profil	236	livrée	1
2026-11-04	claude/fuseaux-serveur	214	livrée	1
2026-11-04	claude/demo-suppr-p	232	livrée	1
2026-11-04	claude/demo-prod	230	livrée	3
2026-11-04	claude/connexion-align	229	livrée	9
2026-11-04	claude/chargement-bis	224	livrée	2
2026-11-03	claude/v1b-creneaux	208	livrée	2
2026-11-03	claude/v1a-bis-super-admin	205	livrée	2
2026-11-03	claude/v1-entretiens	189	livrée	4
2026-11-03	claude/ux-046-questionnaire	151	livrée	2
2026-11-03	claude/txt-1-textes	158	livrée	3
2026-11-03	claude/supprimer-serveur	198	livrée	2
2026-11-03	claude/supprimer-bis	201	livrée	1
2026-11-03	claude/snt-ecrans	171	livrée	3
2026-11-03	claude/snt	170	livrée	2
2026-11-03	claude/scenarios-enchaines	190	livrée	2
2026-11-03	claude/salle3-prets-serveur	197	livrée	1
2026-11-03	claude/remb-14	157	livrée	5
2026-11-03	claude/rejeu-e2e	178	livrée	9
2026-11-03	claude/recharge-carte	181	livrée	5
2026-11-03	claude/recharge-1	161	livrée	2
2026-11-03	claude/rang19-scenarios-a	186	livrée	2
2026-11-03	claude/rang14-trois-salles	191	livrée	1
2026-11-03	claude/preuve-rouge-ci	159	PR non fusionnée	1
2026-11-03	claude/photos-serveur	180	livrée	2
2026-11-03	claude/photos-ecrans	-	sans PR	4
2026-11-03	claude/pay-ux	153	livrée	8
2026-11-03	claude/onboarding-fin-sauvegarde	-	sans PR	1
2026-11-03	claude/o1-ouvrir-observation	169	livrée	1
2026-11-03	claude/o1-observation	152	livrée	7
2026-11-03	claude/niv1-reprise-profils	175	livrée	3
2026-11-03	claude/niv1-niveau-une-fois	172	livrée	8
2026-11-03	claude/n4-serveur	194	livrée	1
2026-11-03	claude/n4-r2-octets	196	livrée	1
2026-11-03	claude/n4-ecrans	207	livrée	5
2026-11-03	claude/n3-s2-pause	202	livrée	6
2026-11-03	claude/n3-d3-mission	199	livrée	4
2026-11-03	claude/n2-foyer-adulte	165	livrée	7
2026-11-03	claude/m1-suppr-doublons	204	livrée	6
2026-11-03	claude/m1-modules-en-double	184	livrée	2
2026-11-03	claude/fn-serveur	183	livrée	1
2026-11-03	claude/fn-divers-serveur	195	livrée	2
2026-11-03	claude/deploy-sans-lib	185	livrée	2
2026-11-03	claude/defil-feuille	177	livrée	2
2026-11-03	claude/d1ter-famille-lit-transmis	174	livrée	11
2026-11-03	claude/d1bis-vue-lecture-seule	173	livrée	3
2026-11-03	claude/d1-bis-signalement	164	livrée	7
2026-11-03	claude/courriels-ux	192	livrée	2
2026-11-03	claude/ci-scenarios-03-11	-	sans PR	1
2026-11-03	claude/anti-robot-ecrans	209	livrée	7
2026-11-03	claude/anti-robot	206	livrée	1
2026-11-03	claude/adm-ux-bis	179	livrée	2
2026-11-03	claude/adm-ux	167	livrée	2
2026-11-03	claude/a3-bis-remplacement	156	livrée	6
2026-11-02	claude/ux-047-accords	148	livrée	3
2026-11-02	claude/regles-remplacement	128	livrée	8
2026-11-02	claude/regles-quatre-agents	140	livrée	4
2026-11-02	claude/notifs-l6-reprise	138	livrée	4
2026-11-02	claude/notifs-l6	137	livrée	5
2026-11-02	claude/n1-communications	147	livrée	7
2026-11-02	claude/l5-listes-dossiers	133	livrée	1
2026-11-02	claude/l4-listes-traitement	132	livrée	3
2026-11-02	claude/l3-listes-regroupements	129	livrée	3
2026-11-02	claude/inscription-3	135	livrée	2
2026-11-02	claude/i1-invitations	145	livrée	10
2026-11-02	claude/fn115b-remboursements-serveur	131	livrée	12
2026-11-02	claude/fn115a-conditions-remboursement	130	livrée	2
2026-11-02	claude/fn-115c-ecran	143	livrée	5
2026-11-02	claude/fn-115c	142	livrée	1
2026-11-02	claude/fn-109	144	livrée	1
2026-11-02	claude/etat-ouverture-0211	134	livrée	4
2026-11-02	claude/c1-classes	150	livrée	8
2026-11-02	claude/b-acces-paye	136	livrée	4
2026-11-02	claude/a-tarifs-particuliers	139	livrée	12
2026-11-01	mots-genre-2026-11-01	112	livrée	1
2026-11-01	claude/salle-acces-perdu	124	livrée	7
2026-11-01	claude/regle-defilement	119	livrée	1
2026-11-01	claude/parcours-ouverture	105	livrée	20
2026-11-01	claude/paiement-dans-app	120	livrée	9
2026-11-01	claude/l2-listes-comptes	126	livrée	4
2026-11-01	claude/fn114a-courriel-defaut	121	livrée	5
2026-11-01	claude/fn113-plafond	122	livrée	11
2026-11-01	claude/fin-seance-motif	117	livrée	4
2026-11-01	claude/fin-seance-chrono	113	livrée	4
2026-11-01	claude/fin-seance-avis	118	livrée	3
2026-11-01	claude/etat-ouverture-lots	115	livrée	2
2026-11-01	claude/e2e-verifier-branchement	114	livrée	3
2026-11-01	claude/e2e-parcours-ouverture	107	livrée	52
2026-11-01	claude/decision-push	111	livrée	2
2026-11-01	claude/decision-courriel	110	livrée	4
2026-11-01	claude/decision-branchement	109	livrée	2
2026-11-01	claude/chargement-differe-bloque	123	livrée	5
2026-11-01	claude/adulte-rechargement	127	livrée	3
2026-11-01	claude/adulte-accueil-apres-acceptation	125	livrée	2
2026-11-01	claude/admiring-brown-r6ai72-paiement-recu	116	livrée	3
2026-10-31	claude/tri-quatre-roles	101	livrée	4
2026-10-31	claude/seance-ouverte-jeton	100	livrée	6
2026-10-31	claude/seance-arriere-plan	94	livrée	3
2026-10-31	claude/remplacement-auto	98	livrée	7
2026-10-31	claude/reaffecter-classe	104	livrée	3
2026-10-31	claude/presence-minutes	102	livrée	3
2026-10-31	claude/paie-remplacant	93	livrée	2
2026-10-31	claude/finir-remplacement	96	livrée	2
2026-10-31	claude/eleve-adulte	99	livrée	3
2026-10-31	claude/decisions-31-10	97	livrée	1
2026-10-31	claude/cahier-remplacant	108	livrée	2
2026-10-31	claude/cahier-hebdomadaire	103	livrée	3
2026-10-31	claude/cahier-exception-presence	106	livrée	1
2026-10-30	rewayahacademy-glitch-patch-5	-	sans PR	1
2026-10-28	claude/admiring-brown-r6ai72-audit	-	sans PR	3
2026-10-27	claude/admiring-brown-r6ai72-surface	-	sans PR	2
2026-10-27	claude/admiring-brown-r6ai72-fiche-0	-	sans PR	2
2026-10-27	claude/admiring-brown-r6ai72-admission	-	sans PR	1
2026-10-26	rewayahacademy-glitch-patch-2	-	sans PR	1
2026-10-26	rewayahacademy-glitch-patch-1	-	sans PR	1
2026-10-26	claude/admiring-brown-r6ai72-passation-2	-	sans PR	1
2026-10-25	claude/admiring-brown-r6ai72-relais	-	sans PR	12
2026-10-25	claude/admiring-brown-r6ai72-passation	-	sans PR	1
2026-10-24	claude/lucid-mccarthy-qpk6yq	45,50	PR non fusionnée	17
2026-10-19	claude/jolly-gauss-7rlt4y	42	PR non fusionnée	1
2026-10-17	claude/sharp-goldberg-z10a13	40	PR non fusionnée	7
2026-10-13	codex/journal	-	sans PR	10
2026-10-13	codex/backend-c29-versioned-quota	-	sans PR	1
2026-10-13	codex/backend-c21-negative-context-r1	-	sans PR	1
2026-10-13	codex/backend-c04-negative-context-r1	-	sans PR	1
2026-10-13	codex/backend-b09-notifications-sources	-	sans PR	1
2026-10-13	claude/beautiful-ptolemy-xmhiki	34	PR non fusionnée	4
2026-10-13	archive/pc-2026-10-13/patchs	-	sans PR	2
2026-10-13	archive/pc-2026-10-13/codex/proof-f70-ccr-merge	-	sans PR	1
2026-10-12	codex2/x2-18	-	sans PR	12
2026-10-12	codex2/imm-back-1-wip	-	sans PR	1
2026-10-12	codex2/imm-back-1	-	sans PR	1
2026-10-12	codex2/imm-accueil-back-phase2-wip	-	sans PR	1
2026-10-12	codex/deleg-fin-1-serveur	-	sans PR	7
2026-10-12	codex/com-back-1-wip	-	sans PR	2
2026-10-12	codex/backend-sec-prod-27-invoker	-	sans PR	2
2026-10-12	codex/backend-rech-d3-enseignants	-	sans PR	5
2026-10-12	codex/backend-kyc-lecture-1	-	sans PR	2
2026-10-12	codex/backend-f86-titulaire-profile-create-guard	-	sans PR	1
2026-10-12	codex/backend-f86-teacher-profile-guard	-	sans PR	1
2026-10-12	codex/backend-f86-pairing-code-guard	-	sans PR	1
2026-10-12	codex/backend-f86-null-safe-review-fixes	-	sans PR	4
2026-10-12	codex/backend-f86-null-safe	-	sans PR	2
2026-10-12	codex/backend-f86-b18-negative-cases	-	sans PR	2
2026-10-12	codex/backend-f86-archive-retention-guard	-	sans PR	1
2026-10-12	codex/backend-f86-archive-listen-guard	-	sans PR	1
2026-10-12	codex/backend-f86-admin-group-mutator-guards	-	sans PR	2
2026-10-12	codex/backend-f70-review-fixes	-	sans PR	34
2026-10-12	codex/backend-ea-role-br	-	sans PR	2
2026-10-12	codex/backend-cap29-review-fixes	-	sans PR	1
2026-10-12	codex/backend-cap29-back-2	-	sans PR	5
2026-10-12	codex/backend-c29-port-wiring	-	sans PR	1
2026-10-12	codex/backend-c29-f86-hashes	-	sans PR	1
2026-10-12	codex/backend-c22-presentation-adapter-safe	-	sans PR	1
2026-10-12	codex/backend-c11bis-f74-canon	-	sans PR	1
2026-10-12	codex/backend-b09-notifs	-	sans PR	3
2026-10-12	codex/backend-b09-events-destinations-r2	-	sans PR	1
2026-10-11	codex2/x2-19	-	sans PR	5
2026-10-11	codex2/x2-13	-	sans PR	2
2026-10-11	codex2/x2-12	-	sans PR	2
2026-10-11	codex2/x2-11	-	sans PR	1
2026-10-11	codex2/x2-10	-	sans PR	2
2026-10-11	codex2/x2-09	-	sans PR	3
2026-10-11	codex2/x2-08	-	sans PR	3
2026-10-11	codex2/x2-07	-	sans PR	5
2026-10-11	codex2/x2-06	-	sans PR	2
2026-10-11	codex2/x2-05	-	sans PR	9
2026-10-11	codex2/x2-04	-	sans PR	5
2026-10-11	codex2/x2-03	-	sans PR	4
2026-10-11	codex2/x2-02	-	sans PR	25
2026-10-11	codex2/x2-01	-	sans PR	2
2026-10-11	codex/backend-sec-prod-m2-fixes	-	sans PR	17
2026-10-11	codex/backend-sec-prod-allowlist	-	sans PR	30
2026-10-11	codex/backend-rls-disabled	-	sans PR	1
2026-10-11	codex/backend-recherche-classes	-	sans PR	1
2026-10-11	codex/backend-offres-adapters	-	sans PR	15
2026-10-11	codex/backend-foyer-ports	-	sans PR	15
2026-10-11	codex/backend-f79-allowlist	-	sans PR	4
2026-10-11	codex/backend-f70-status-tests	-	sans PR	1
2026-10-11	codex/backend-f70-contract-publication	-	sans PR	25
2026-10-11	codex/backend-f69-super-admin-controls	-	sans PR	2
2026-10-11	codex/backend-f69-k65	-	sans PR	1
2026-10-11	codex/backend-contract-signature-continuation	-	sans PR	21
2026-10-11	codex/backend-contract-signature	-	sans PR	1
2026-10-11	codex/backend-cap29-version-integrity	-	sans PR	27
2026-10-11	codex/backend-cap29-library-visibility	-	sans PR	30
2026-10-11	codex/backend-cap29-catalogue	-	sans PR	4
2026-10-11	codex/backend-c29-tirage	-	sans PR	4
2026-10-11	codex/backend-c25-regroupements	-	sans PR	1
2026-10-11	codex/backend-c23-reprise-adapter	-	sans PR	4
2026-10-11	codex/backend-c22-hardening	-	sans PR	1
2026-10-11	codex/backend-c22-canon-adapter	-	sans PR	3
2026-10-11	codex/backend-c22-age-presentation	-	sans PR	287
2026-10-11	codex/backend-c21-kyc-verdict	-	sans PR	15
2026-10-11	codex/backend-c21-kyc-access-adapter	-	sans PR	19
2026-10-11	codex/backend-c17-signature-status	-	sans PR	27
2026-10-11	codex/backend-b18-ci-state	-	sans PR	1
2026-10-11	codex/backend-b12-f84-ccr	-	sans PR	1
2026-10-11	codex/backend-b09-notifications	-	sans PR	8
2026-10-11	codex/backend-b09-f1-producers	-	sans PR	25
2026-10-11	codex/backend-b09-adaptateur	-	sans PR	1
2026-10-11	codex/backend-b04-reprise	-	sans PR	3
2026-10-11	codex/backend-b03-b12	-	sans PR	1
2026-10-11	codex/backend-al01-05-f86	-	sans PR	3
2026-10-11	codex/backend-adult-kyc-contract	-	sans PR	15
2026-10-11	codex/backend-a81-f86	-	sans PR	1
2026-10-11	codex/backend-a81-f69-hardening	-	sans PR	17
2026-10-11	codex/backend-a81-c24-adapter	-	sans PR	1
2026-10-11	claude/revue-backend-codex-1	-	sans PR	2
2026-10-11	claude/mushaf-15l-captures	-	sans PR	1
2026-10-11	claude/f86-manifeste	-	sans PR	3
2026-10-11	claude/compta-recon	-	sans PR	1
2026-10-11	claude/catalogue-canon-fixes	-	sans PR	1
2026-10-11	claude/br1-branchement	-	sans PR	2
2026-10-11	archive/pc-2026-10-13/codex/backend-c23-reprise	-	sans PR	5
2026-10-11	archive/pc-2026-10-13/codex/backend-c11bis	-	sans PR	45
2026-10-10	ui/brand-logo-2026	-	sans PR	1
2026-10-10	docs/specs-entrantes-2026-10-10	-	sans PR	1
2026-10-10	codex/backend-staging-preview-secrets	26	PR non fusionnée	2
2026-10-10	codex/backend-sec-prod	22	PR non fusionnée	29
2026-10-10	codex/backend-passation-2026-10-10	-	sans PR	1
2026-10-10	codex/backend-notifications	-	sans PR	6
2026-10-10	codex/backend-lota-ledger-provenance	32	PR non fusionnée	3
2026-10-10	codex/backend-lot-f1	13,19	PR non fusionnée	98
2026-10-10	codex/backend-lot-c-staging-api	20	PR non fusionnée	115
2026-10-10	codex/backend-lot-a-manifest	25	PR non fusionnée	4
2026-10-10	codex/backend-f2-b13-admin-rls	17	PR non fusionnée	58
2026-10-10	codex/backend-f2-after-c	21	PR non fusionnée	282
2026-10-10	codex/backend-f1-ccr-port	-	sans PR	20
2026-10-10	codex/backend-f1-ccr-8ea7831	29,33	PR non fusionnée	2
2026-10-10	codex/backend-blueprint	24	PR non fusionnée	5
2026-10-10	codex/backend-b20-ccr-8ea7831	30	PR non fusionnée	2
2026-10-10	codex/backend-b20-agent-identity	28	PR non fusionnée	7
2026-10-10	codex/backend-b13-ci-ccr	27	PR non fusionnée	5
2026-10-10	codex/backend-b13-ccr-8ea7831	31	PR non fusionnée	3
2026-10-10	codex/backend-b13-admin-suspended	23	PR non fusionnée	3
2026-10-10	claude/wizardly-babbage-lmhkog	-	sans PR	2
2026-10-10	claude/com-suite	-	sans PR	3
2026-10-09	revues/2026-10-04-b061fd81	-	sans PR	14
2026-10-09	pilotage/tuteur-v1	-	sans PR	341
2026-10-09	codex/backend-staging-deploy	-	sans PR	14
2026-10-09	codex/backend-lot-c	10	PR non fusionnée	14
2026-10-08	codex/site-public-preview-main	8	PR non fusionnée	1
2026-10-05	juridique/licence-code	-	sans PR	4
2026-10-04	revues/2026-10-04-01MrLWqB	-	sans PR	4
2026-10-04	projet/ressources	-	sans PR	16
2026-10-04	corrections/c2-ea-coran	-	sans PR	3
2026-10-04	claude/collaborative-task-tracking-r47ieu	-	sans PR	11
2026-10-04	ccr-a2ce253e-vnv87y	-	sans PR	1
2026-09-28	ui/essai-ci-d2	7	PR non fusionnée	1
2026-09-28	claude/modest-hopper-hj96t5	7	PR non fusionnée	1
2026-09-28	claude/essai-ci-d2	6	PR non fusionnée	2
2026-09-27	claude/confident-mayer-m2fqsl	5	PR non fusionnée	2
2026-09-27	archive/pc-2026-10-13/adrc/m4	-	sans PR	1
2026-09-27	archive/pc-2026-10-13/adrc/m3	-	sans PR	1
2026-09-27	archive/pc-2026-10-13/adrc/m1	-	sans PR	1
2026-09-26	ui/tuteur-v1-t	-	sans PR	35
2026-09-26	reserve/theme-monochrome-k36	-	sans PR	34
2026-09-23	v0/verite-produit	-	sans PR	1
2026-09-23	nettoyage/base-2026-09-23	-	sans PR	2
2026-09-23	archive/pc-2026-10-13/integration/core24-classes-v2-remediation	-	sans PR	15
2026-09-22	lot/onboarding-offres	-	sans PR	1
2026-09-22	core24/fable-frontend	-	sans PR	2
2026-09-22	archive/pc-2026-10-13/integration/core24-classes-v2	-	sans PR	10
2026-09-22	archive/pc-2026-10-13/docs/core24-classes-arbitration	-	sans PR	2
2026-09-22	archive/pc-2026-10-13/astra/core24-v2	-	sans PR	17
2026-09-22	archive/pc-2026-10-13/astra/core24-presence-safeguard	-	sans PR	18
2026-09-22	archive/pc-2026-10-13/astra/core24-classes-legacy-snapshot	-	sans PR	19
2026-09-21	observation/lot-2026-09-21	-	sans PR	11
2026-09-21	archive/pc-2026-10-13/sauvegarde/r2-du-tiers	-	sans PR	1
2026-09-20	teaching-core/0-coordinateur	-	sans PR	2
2026-09-15	archive/pc-2026-10-13/codex/vague5-integration	-	sans PR	7
2026-09-15	archive/pc-2026-10-13/codex/presence-correction-ui	-	sans PR	1
2026-09-15	archive/pc-2026-10-13/codex/login-demo	-	sans PR	1
2026-09-14	archive/pc-2026-10-13/codex/r2-adaptive-shell	-	sans PR	4
2026-09-13	codex/r1-adaptive-design-system	-	sans PR	1
2026-09-09	specs	-	sans PR	1
2026-09-09	refactor-ui-lavender-3628477128789856989	1	PR non fusionnée	3
```
