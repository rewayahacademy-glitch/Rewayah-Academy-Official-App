# Passation du pilote, 25/10/2026, 15:30 UTC

Écrite par la session pilote `session_018zqR7D4uVdaYUvrgoEHNPG` pour celle qui la remplace, à la
demande du directeur (contexte saturé, jetons à économiser jusqu'à la réinitialisation de jeudi
29/10). Tout ce qui n'est pas ici se retrouve dans `docs/current/BOUCLE-1_PLAN_2026-10-24.md`
(journal §6), `docs/orchestration/PILOTAGE-BOUCLES-2026-10-24.md`,
`docs/orchestration/ETUDE-ACCUEIL-ET-CLASSES-2026-10-25.md` et
`docs/orchestration/PASSATION-SALLE-2026-10-25.md`.

## 1. Les rôles

- **Le directeur** : non technicien, épuisé, attentif aux coûts, francophone et arabophone. Il a
  délégué le projet à 100 % le 24/10 : « tu es le patron ». Il ne fait que ce que le garde-fou
  interdit aux agents : ouvrir une PR depuis le lien compare exact, cliquer Merge, coller du SQL dans
  l'éditeur SQL de **production** depuis une page privée (Artifact), valider les textes, tester en
  production. Une seule chose à la fois, dite en mots simples, vérité d'abord (CLAUDE.md). Il ne lit
  pas le code ; il ne doit jamais devoir deviner quoi faire.
- **Le pilote** (toi) : seul à parler au directeur. Lit, décide, consigne, commande le worker,
  relit son travail, écrit les corps de PR, s'abonne aux PR, surveille les CI, prépare les pages à
  coller. Ne code pas lui-même sauf documentation. Ne recrée jamais sans chercher ce qui existe.
- **Le worker salle** : `session_011CALX9teGtqrquq7vN8ZpH` (créée à 14:35 UTC, en attente, ne
  consomme rien tant qu'on ne lui écrit pas). Il rend compte au pilote par `send_message` ; **lui
  donner ton identifiant de session dès ton premier message**, sinon ses rapports partent vers
  l'ancienne session. Ordres qui tiennent : aucun appel MCP Supabase, rien vers `main`, aucun test
  sauté, aucun push sans ton « pousse », push simple jamais forcé, pas de push vers une branche dont
  une PR a sa CI en cours (la concurrence l'annule et on repaie 1 h 30). L'ancien worker
  `session_01GVwRsTBkJjivjBMnaQzCVH` est archivé ; sa branche distante de relais
  `claude/admiring-brown-r6ai72-relais` (25060b8) ne sert plus, seul le directeur peut la supprimer.

## 2. Règles qui ne se discutent pas

- Production seulement, pas de staging. Lecture seule sur la base par le MCP Supabase (`SELECT`),
  l'identifiant du projet n'apparaît que dans les arguments MCP, jamais dans une commande shell.
- Le garde-fou `.claude/hooks/garde.py` refuse : PR vers `main` par un agent, push vers `main`,
  push forcé, suppression de branche distante, fusion, relance ou annulation de CI, écriture
  Supabase, zones interdites (`.github/`, `vercel.json`, `pubspec.yaml`, `site-public/`, settings et
  hooks), `git checkout main` dans l'arbre principal. On ne le contourne jamais.
- Ce que le directeur colle vient toujours d'une page privée : `python3 -I
  tool/page_migrations/generer.py --sortie "$S/x.html" --titre "…" "<fichier>::<phrase>"`, puis
  remplacer les liens staging par https://supabase.com/dashboard/projects et « base de test » par
  « production », publier avec l'outil Artifact, supprimer `tool/__pycache__`. Le SQL avec des
  adresses personnelles ne se versionne jamais.
- Aucun nom de modèle dans les titres et corps de commit, PR, code ; la ligne `Co-Authored-By`
  imposée par l'outil reste telle quelle. Aucun secret dans le dépôt. Les fichiers de jeton
  Cloudflare dans les téléversements du directeur ne se lisent ni ne se citent.
- Les migrations ne s'appliquent pas à la fusion ; les fonctions Edge se déploient au push sur
  `main` (`deploy.yml`, 1 min) ; l'application se déploie par `flutter-deploy.yml` (8 min). La CI
  Flutter d'une PR dure 1 h 30 : on ne pousse jamais sur une branche pendant qu'elle tourne.
- Plein écran sans bordure sur tous les écrans de la salle, téléphone et ordinateur ; tout le
  reste flotte et se masque. Pas de design deviné : standards publics (Meet, Material 3).
- Pulaar : pas de traduction automatique ; on prend la seconde langue déclarée.
- **Jetons jusqu'à jeudi** : une tâche à la fois au worker, en un message ; pas de grandes suites
  relancées pour de la documentation ; pas d'agents d'exploration superflus ; points de contrôle
  automatiques toutes les deux heures au plus.
- **Crédits GitHub Actions** : presque épuisés, renouvelés à la réinitialisation mensuelle. Le
  dépôt reste **privé** (le directeur l'a refusé public). Quand le compteur bloque : préparer une
  page pour que le directeur rende la CI manuelle (`ci.yml`, zone interdite), et écrire dans chaque
  PR les tests passés en local chez le worker.

## 3. État exact

- `main` = 1ce0c76 (fusion de la PR 56, 14:43 UTC). En production depuis : courriel d'attente en
  « lettre personnelle » (sans image ni en-tête de liste), arabe écrit à la main, nom
  « أكاديمية الرواية ». **Prouvé** : deux copies vers samtransldocs@gmail.com arrivées dans
  l'onglet « Principale ».
- **Campagne** : 524 candidats en file (`courriels_sortants`, catégorie recrutement), départ
  lundi 26/10 09:00 UTC, 180 par jour jusqu'au 28/10 ; ar 403, en 59, fr 59, pt 3. À surveiller en
  lecture seule (statuts, `derniere_erreur`). Transport réel : SMTP Gmail. Rien à faire si tout
  part ; si des erreurs apparaissent, le worker lit `courriels-envoi` et `traduction.ts`.
- **PR 57** ouverte (https://github.com/rewayahacademy-glitch/Rewayah-Academy-Official-App/pull/57),
  tête 5ce23d7, 14 commits de la salle (lots 1 et 2), corps écrit, CI lancée vers 15:22 UTC, verte
  attendue vers 17:00 UTC. **S'y abonner** (`subscribe_pr_activity`), puis : verte → dire au
  directeur « Merge » ; fusionnée → il teste K4 en production sur téléphone et ordinateur ; ses
  retours font le lot salle 3. Déjà connus : liseré de quelques pixels autour du tableau sur
  ordinateur ; sur téléphone le tableau est une bande 16:9 (alternative : couvrir et glisser, comme
  Zoom mobile), il décide après test.
- Branche de travail : `claude/admiring-brown-r6ai72`. Le pilote ne pousse qu'après la fusion de
  la PR en cours ; il rebase sur `origin/main` avant.
- Base de production (lecture du 25/10) : 8 classes, 1 offre, 1 élève. Les fonctions de
  regroupement (`regroupements_c11bis_admin`, `creer_classe_depuis_regroupement`) y existent.

## 4. Ce qui vient, dans l'ordre

1. PR 57 verte → fusion → test K4 du directeur → lot salle 3 (ses retours, liseré, décision bande
   16:9). Boucle 1 close quand il dit que la salle tient.
2. **Fiche d'écran de la page de connexion** (décision 6 de l'étude du 25/10) : modèle = page
   « Ne plus recevoir ces e-mails » (fond de marque plein, logo, arche, boutons à même la page,
   aucun rectangle emboîté) ; ordinateur en deux volets, illustration des pages 404 du site public à
   gauche, formulaire à droite sur caramel clair, clair et sombre à décider. Une demi-page écrite
   par le pilote, validée par le directeur, puis une PR du worker. **Avant** B2.1 et B2.2.
3. B2.1 : essai à blanc de l'import des élèves actuels (écran « Importer les inscriptions », vrais
   CSV du classeur Google) ; lire les résultats avec le directeur. Il doit décider le prix d'une
   classe d'un seul élève et son annonce (cours individuels actuels = classes d'un élève en vague 1).
4. B2.2 : enseignants validés par K1 et affectés ; bibliothèque de noms de classes à proposer pour
   validation (plan §5, décision du 25/10) ; B2.2 bis (cloche, concierge, créneaux multiples ; deux
   lignes de `ci.yml` à coller par le directeur, journal du plan).
5. Lot « accueil des familles » avant la Boucle 3 et ajout « demandes compatibles » dans « Créer
   une classe » (étude du 25/10, décisions 2 à 4). Le directeur enverra des captures de Rewire ; les
   ranger dans `docs/current/maquettes/…/references/`.
6. Reliquats connus : D14 webhook et jeton 60 s ; `EtatPartageSupabase` (lot futur) ; écran
   Classes à plusieurs créneaux ; DKIM/DMARC et Search Console (tâches du directeur) ; secret
   `APP_ORIGINES` ; révoquer le jeton Cloudflare après DKIM/DMARC ; D5 (adulte apprenant pour
   lui-même, jamais proposé par « Ajouter un élève »).

## 5. Pages privées encore utiles

- Test tiers (déjà collé) : https://claude.ai/artifact/3L3rqyAtSJKmpg55LKaePi
- Report de 24 h de la campagne (ne sert plus, sauf incident) : https://claude.ai/artifact/XDBikF8YnzbutZZCJcFKnQ
- Pulaar vers arabe (collé, vérifié) : https://claude.ai/artifact/6N8VNZMcPHRDnv6SxXGbSV

## 6. Pièges vus ces deux jours

- Le directeur colle parfois avant l'ordre « colle » : prévoir des SQL idempotents (clés
  `cle_idempotence`).
- Un test vert en local et rouge en CI (ordre de `Directory.listSync`) : exiger un parcours
  déterministe, ne jamais « réessayer » une CI.
- Le crochet d'arrêt réclame de pousser les commits locaux : on ne pousse pas pendant la CI d'une PR
  sur la même branche ; dire pourquoi, pousser après la fusion.
- Le worker d'avant a coûté environ 200 $ en 36 h : un message d'ordre cadré vaut mieux que dix
  allers-retours.
