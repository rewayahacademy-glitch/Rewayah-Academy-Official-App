# Passation de fin de Codex (13/10/2026)

L'abonnement Codex (ChatGPT) est terminé le 13/10/2026. Codex 1 et Codex 2 ne
reprendront pas. Ce document permet à **n'importe quel agent** (Claude ou autre) de
reprendre le backend sans relire la feuille ni les journaux. Il donne l'état de chaque
lot, son SHA exact et les étapes restantes.

La liste exhaustive des branches `codex/*` et `codex2/*` est dans
`PASSATION-FIN-CODEX-ANNEXE-BRANCHES.md`. Seuls les lots nommés ici sont à reprendre.

## 0. Règles qui restent en vigueur

- **Interdits :**
  - pas de push sur `main`, ni de PR vers `main` ;
  - aucune écriture en production, et STAGING seulement sur ordre du directeur ;
  - jamais de `service_role` ;
  - `.claude/hooks/garde.py` ne se modifie pas.
- **Données réelles :** aucune donnée réelle d'élève ou de famille dans Git, la feuille,
  un test ou un chat. Les CSV de test sont inventés.
- **Intégration :** un lot n'entre dans `codex/backend-canon-fixes` qu'après une ligne
  **CONFIRMÉ** écrite par une session qui n'en est pas l'autrice. Un intégrateur
  unique à la fois. Codex 1 l'était ; c'est désormais la session Claude qui reprend.
- **Horodatage des migrations :** il doit rester strictement croissant et sans doublon.
  Les secondes paires et impaires ne servent plus, car il n'y a plus deux auteurs.
- **F86 :**
  - INVOKER par défaut ;
  - DEFINER seulement avec `search_path` vide et un commentaire qui porte le
    `md5(pg_get_functiondef)` réel, jamais `A_CALCULER` ;
  - `anon` et `service_role` sans EXECUTE ;
  - chaque garde a un scénario de refus et un mutant qui le fait échouer quand on
    retire la garde.
- **Une branche par lot**, versionnée `-r2`, `-r3`. Jamais plusieurs branches
  concurrentes pour un même lot.
- **Fichiers générés :** `strings*.g.dart` se régénère avec `dart run slang`, jamais à
  la main.

### Procédure de rejeu (preuve « CONFIRMÉ »)

1. Démarrer un PostgreSQL 17 nu, en **UTF8**. Sans UTF8, les scénarios `imm_accueil_*`
   échouent sur le BOM.
2. Charger `supabase/tests/stub_auth.sql`.
3. Appliquer toutes les migrations dans l'ordre du glob.
4. Lancer chaque `supabase/tests/scenarios_*.sql` dans une base neuve. Utiliser
   faketime pour les scénarios qui dépendent de l'heure.
5. Rejouer chaque garde par un mutant : il doit rendre le scénario ROUGE.
6. Écrire le verdict (CONFIRMÉ ou CHANGES, avec le SHA) dans le journal de l'onglet
   concerné de la feuille de suivi.

Côté Dart, la vérification se fait sur fusion locale avec `ccr-1b1bfa0b-m1kvkk`, avec
les commandes suivantes :

```
dart run slang
dart run build_runner build --delete-conflicting-outputs
dart analyze --fatal-infos
flutter test
```

## 1. Base de départ

| Branche | SHA | État |
| :--- | :--- | :--- |
| `codex/backend-canon-fixes` (SQL commun) | `481e9921` | **CONFIRMÉ, 65/65** en UTF8. Contient F86-refus, B-12 et ses négatifs, C-29 fixtures, RECH-BACK-2/6, A793/A816, IMM-BACK-1, CAP29-BACK-2, IMM-ACCUEIL phases 1-3 |
| `ccr-1b1bfa0b-m1kvkk` (app Flutter commune) | `d5e45ec8` | base Dart. La fusion locale avec canon-fixes 481e9921 se fait sans conflit (A786) |
| `codex/journal` | `a4812de1` | journal de secours de Codex 1 (`docs/backend/codex1/JOURNAL.md`), en lecture seule |

## 2. CONFIRMÉS, à intégrer dans canon-fixes (travail mécanique)

Il faut fusionner chacun dans `codex/backend-canon-fixes`, puis refaire un rejeu complet
de la base fusionnée avant de la déclarer CONFIRMÉE.

| Lot | Branche @ SHA | Remarque |
| :--- | :--- | :--- |
| IMM-ACCUEIL empreintes F86 | `codex/backend-imm-accueil-f86` @ `94131ce9` | 3 md5 exacts (355d5f55…, 741639b4…, 6e9dee18…) |
| F70 délégations financières (SQL + Dart) | `codex/backend-f70-review-fixes-r2` @ `15baadd4` | SQL CONFIRMÉ sur 235d272b ; Dart CONFIRMÉ sur 15baadd4 |
| B-09 notifications | `codex/backend-b09-notifications-integration-r1` @ `a8c7a6a5` | Ce commit est la fusion de canon-fixes 481e9921 et de r4 `98ae3d2c`, la version relue CONFIRMÉE. Il s'intègre donc en avance rapide : il n'ajoute à canon-fixes que les 11 fichiers B-09 (adaptateur, provider, libellés FR et AR, test, sources). Vérifié par `git log` le 13/10. Contrairement à ce que dit le verdict de la ligne 131, r4 ne contient pas a8c7a6a5 ; c'est l'inverse. 3cea4299 est une branche sœur qui ne diffère que par le libellé des sources : elle est abandonnée, comme toutes les autres branches B-09. Après fusion avec ccr, lancer `dart run slang`. |
| Négatifs (5) | `c29-control-negative-r1` 8cc91ef1, `c29-rules-negative-r1` e63d8111, `c20-timeline-negative-r1` b9165888, `x2-22-anon-negative-r1` f94ed687, `c35-library-read-negative-r1` dad52bc7 | un seul fichier de scénario chacun |
| Négatifs (14) | `agt01` cf9ed5a3, `age-presentation` 7b6fa5e9, `b03` 7b94e77c, `b04` 2894db2b, `b07` 60724ed6, `b08-summary` c381f48c, `b09-notifications` 89d5e772, `b09-replacement` 004c9ff1, `b10` 776033a9, `b11-student-concern-anon` 33c6f60f, `b13-anon` 1a0f9ab0, `b15` a5fcfc0a, `f86-observation-context` 4109340f, `f86-take-student-context` 43621e0b | branches `codex/backend-<lot>-…-r1`, un seul scénario chacune |
| RECH-BACK-3 recherche + quota C-38 | `codex2/rech-back-3-wip` @ `33d02d74` | CONFIRMÉ avec **réserve de temps de réponse** (voir §3) |

Ces négatifs ont des mutants survivants, sans blocage. Ce sont des refus déjà assurés
par un autre contrôle :

- b03 : inviter_conjoint, repondre_invitation_conjoint ;
- age-presentation : refuser et accepter_demande_presentation ;
- b04 : refuser et deposer_reprise_foyer ;
- b07 : profil_eleve_titulaire_existe ;
- b09-replacement : designer_remplacant_admin ;
- b11-student-concern : transmettre et deposer ;
- policy UPDATE des notifications.

Améliorer ces sondes est un bonus, pas un préalable.

## 3. CHANGES ouverts (petites corrections précises)

| Lot | Branche @ SHA | Ce qu'il reste à faire |
| :--- | :--- | :--- |
| **F86 inscription** (sécurité) | `codex/backend-f86-registration-acl-r3` @ `9f0349b3` | L'attaque est fermée : un tuteur ne peut plus rattacher le compte Auth d'un tiers, grâce à `app_metadata.child_of`. Dans `scenarios_imm_back_1_registrations`, il reste quatre points. (1) Ligne 112 : l'enseignant de fixture doit être en `provisional_active` avec un NDA signé, pas en `active` sans contrat. (2) Ligne 309 : faire les UPDATE de `auth.users` et le CREATE de `auth.sessions` après `reset role`, en propriétaire. (3) Ajouter des sondes : un compte créé il y a 16 min est refusé, un `created_at` futur est refusé. (4) Tolérer 1 min d'écart d'horloge (`created_at <= now() + interval '1 minute'`). Ensuite, relever le md5 de `creer_profil_enfant`, qui change à chaque modification, et l'inscrire. |
| C-29 quota versionné | `codex/backend-c29-versioned-quota` @ `118fb75a` | Dans `scenarios_c29_assignment_weights`, libérer le contrôleur (cycle décalé d'une semaine) avant l'étape version 3, pour que le quota 0 soit réellement prouvé. Ajouter un test hors borne : 51 ou -1 doit être refusé. Remplacer A_CALCULER par `222b72c1d4780ae489304148b2b896d7`, à re-mesurer après modification. |
| RECH-BACK-4 négatif | `codex/backend-rech-back-4-negative-r1` @ `47ac9018` | Scénario rouge. Retirer la valeur `'Disabled'` en trop (8 valeurs pour 7 colonnes). Placer la séance 203 hors de la fenêtre de la 202. Mettre la mission 403 sur une autre classe que la 101, ou clore la 401 avant. |
| B-11 négatif | `codex/backend-b11-negative-context-r1` @ `f01610d7` | Le compte désactivé doit appeler sur **sa** session et **son** groupe. Sinon le refus vient d'ailleurs et les 3 mutants survivent. |
| B-14 négatif | `codex/backend-b14-negative-context-r1` @ `d4f7d86c` | Même défaut : le compte désactivé doit publier sur une session qui lui appartient. |
| C-04 négatif | `codex/backend-c04-negative-context-r1` @ `210de186` | Ligne 27 : l'élève de fixture doit avoir un foyer (`profiles_household_required`). |
| C-21 négatif | `codex/backend-c21-negative-context-r1` @ `b5ebb0d3` | Ligne 26 : `gender` et `account_status` sont inversés pour le contrôleur. |
| Gardes de compte désactivé non prouvées | dans c29-control, c29-rules et x2-22 (déjà CONFIRMÉS) | Pour `ma_capacite_controle_active`, `lire_regles_tirage` et `pause_seance_demarrer`, donner au compte désactivé un rôle ou une capacité valide dans la fixture. Ainsi, seul `account_status` le refuse. |
| Empreintes IMM-BACK-1 | à créer sur une nouvelle branche | Une migration de commentaire remplace les 6 `A_CALCULER`. Relevé sur 410d2957 : `private.tirer_nombre_matricule(integer)` 067377ae1388cec594cd8296046088a7, `private.attribuer_matricule(uuid,timestamptz)` 0843a7fef71a947b8ee5a2a00ffdb7a4, `profiles_attribuer_matricule()` 69732d13720f32ac5f78e88bde3a2144, `rechercher_personne_par_matricule(text)` 2fb0b9de8fc7c2d2479907d4b046d326. Les fonctions `creer_profil_inscription` et `creer_profil_enfant` changent avec F86 r3 : les **re-mesurer après son intégration**. Ajouter `REVOKE EXECUTE … FROM service_role` sur ces deux-là. |
| RECH-BACK-3 réserve | `codex2/rech-back-3-wip` @ `33d02d74` | Un existant non autorisé répond en 0,89 ms, contre 0,37 ms pour un inexistant. Appeler toujours le contrôle d'autorisation, avec un uuid nul si rien n'est trouvé, avant de renvoyer vide. |

## 4. Lots inachevés ou bloqués

| Lot | Où en est-il | Suite |
| :--- | :--- | :--- |
| **IMM-BACK-2** (codes d'évaluation EV-NNNN) | `codex2/imm-back-2-wip` @ `8925ee48` ne contient que du IMM-BACK-1 ancien. **Le lot n'est pas commencé.** | Décision rendue le 12/10. Les codes s'attachent à la publication d'une évaluation, avec une ligne par élève et par évaluation publiée. Ils sont tirés au hasard et uniques dans l'évaluation. Utiliser la table d'évaluations du canon si elle existe, sinon créer une table minimale `evaluation_publications` (id, groupe, titre, publiée_le). L'administration choisit l'affichage : code, nom, ou les deux. Références : `docs/current/DECISION-IMMATRICULATION-2026-10-12.md` §4, IMM-06 à 08 et IMM-13. Partir de canon-fixes, pas de la branche WIP. |
| **COM-BACK-1** (messagerie) | `codex/com-back-1-wip` @ `8e0893bb` : la proposition de schéma est dans `docs/orchestration/COM-BACK-1-PROPOSITION.md`. Bloqué. | Il manque des décisions du directeur : fuseau et ordre des annonces, limites et durée de conservation des messages et pièces jointes, édition et suppression, publics, modération. À poser au directeur en questions simples avant tout code. |
| CAP29-BACK-1 | audit statique fait par Codex 1 (journal de la feuille) | Reprendre les écarts relevés, lot par lot. |
| Contrats C-36 à C-40 | onglet Contrats, proposés par Codex 2 | À confirmer par le front au moment des écrans. |

## 5. Avant tout déploiement (rappel)

- Activer « Confirm Email » dans Supabase Auth. Le rattachement IMM-ACCUEIL dépend de
  `email_confirmed_at`.
- Mettre en **UTF8** le Postgres de la CI.
- Les migrations sont appliquées hors CI, sur feu vert explicite du directeur et sur une
  liste précise. GitHub Actions est hors service.

## 6. Où lire le reste

- **Feuille de suivi** `1v3uuQD9jHgezbrmNlrKPOvGsRBCpxYXkN_KIq5N72WA`. Les onglets
  « Codex1 · en cours » et « Codex2 · en cours » contiennent le tableau de bord (lignes
  1-19) et le journal (à partir de la ligne 22), avec chaque livraison et chaque verdict.
  « Contrats » contient les ports partagés. Les deux sessions Codex n'y ont plus accès
  (jeton Google expiré).
- **Tableau des étapes** (artifact) : https://claude.ai/artifact/XMVyZJiLTcmMKTnhsbp3sU
- **Fin de session Codex 2 :** journal Codex 2, ligne 63. Ses 12 dossiers locaux étaient
  propres et tout le travail était poussé.
- **Codex 1 n'a pas écrit de ligne FIN DE SESSION.** Sa dernière déclaration, le 13/10 à
  04:39, dit que `codex/journal` et `codex/backend-canon-fixes` correspondent aux SHA
  distants et qu'il n'y a rien de nouveau à pousser.

## 7. Postes locaux de Codex (disque D:) : nettoyage par le directeur

Les deux Codex travaillaient en local sur des dossiers `D:\rewayah-*` (worktrees Git).
Tout ce qui figure dans ce document est **déjà sur GitHub**.

Avant de supprimer un dossier `D:\rewayah-*`, lancer ces deux commandes à l'intérieur :

```
git status --short
git log --branches --not --remotes --oneline
```

- Si les deux commandes n'affichent rien, le dossier ne contient rien qui ne soit déjà
  sur GitHub. On peut le supprimer.
- Si l'une affiche quelque chose, **ne rien supprimer** et demander à une session Claude
  de pousser ce reste sur une branche `codex/<lot>-wip`.

Exception connue : Codex 1 garde trois fichiers Windows `generated_*`, modifiés
localement et volontairement non poussés. Ce sont des fichiers générés, sans valeur, qui
peuvent être perdus.
