# Passation du pilote, 05/11/2026

Écrite par la session pilote `session_0163Kjrv38i3CYWs5z3wtmWi`, sur ordre du directeur du 05/11
vers 20:40 UTC : « Relance le travail, il faut que ça finisse. […] je veux que tu te prépares à te
retirer, toi et l'autre pilote, parce que vous commencez à engranger beaucoup de contexte. »
Le successeur n'est lancé que sur ordre du directeur. Le garde-cap écrit de son côté
`PASSATION-GARDE-CAP-2026-11-05.md`.

## 0. Ce qui est faux, bloqué ou non prouvé, d'abord

- **Plafond hebdomadaire du compte.** Il a été atteint le 04/11 vers 16:30 UTC, avec quatre agents,
  le pilote et le garde-cap. Tout s'est arrêté jusqu'à la remise à zéro du 05/11 à 20:00 UTC.
  Rythme à surveiller.
- **Non prouvé en production par le directeur** (aucun agent n'a de compte de production) :
  - le bandeau « personne occupée » ;
  - les photos ;
  - le Compte de l'enfant ;
  - le changement de compte ;
  - le Compte du tuteur. Sur « Méthode de connexion », « non précisée » serait un défaut : les 12
    comptes actifs ont `email` ou `google`.
- **« Paiements et reçus : Non disponible »** au Compte du tuteur. La valeur est écrite en dur
  (`compte_tuteur_page.dart:144`). C'est conforme au plan, qui met le paiement en Boucle 2, en
  dernier (décision du 24/10). Annoncé au directeur le 04/11.
- **Deploy Supabase rouge sur main** (run 278, 0a6ee422). `supabase/setup-cli@v1` demande
  `latest`, et l'API GitHub a refusé pour limite d'appels. C'est sans effet, puisque le train ne
  touchait pas `supabase/`. L'épinglage de la version (`deploy.yml` l. 50 et 102) est sur la liste
  du directeur. Un second rouge de ce type serait un signal d'arrêt.
- **Le pilote n'a ni dart ni flutter dans son conteneur.** Une fusion de train résolue à la main
  sur du code généré a échoué au contrôle slang (train b, 04/11). Règle : quand un train a un
  conflit sur un fichier généré, un agent avec dart lance `dart run slang` puis `build_runner` sur
  la branche du train, en un commit, avant la CI.

## 1. Rôles et sessions

| Rôle | Session | Tâche en cours au 05/11 20:40 |
| :--- | :--- | :--- |
| Pilote (moi) | `session_0163Kjrv38i3CYWs5z3wtmWi` | trains, fusions, migrations, rapport au directeur |
| Garde-cap | `session_018zqR7D4uVdaYUvrgoEHNPG` | compare captures et diffs avant chaque train, vérifie en production sans compte |
| N1 | `session_0163KjrxdNHzGwurffK4qWjt` | FOYER-ÉLÈVE, `claude/foyer-eleve` |
| I1 | `session_0163KjrvZfk2JT1EXKk17hdH` | PHOTOS-A, `claude/photos-a` ; garde la PR 210 (exception P6) |
| Fin de séance | `session_0163KjrwZrC2S3DjyQZCYQJB` | PHOTOS-B, `claude/photos-b` |
| C1 | `session_0163KjrwZ15mab73PMw441R3` | DEMO-SUPPR D2, `test/` seul |

Un successeur donne son identifiant de session dès son premier message à chaque agent, sinon les
rapports partent vers l'ancienne session.

## 2. Règles de fusion (DECISION-QUATRE-AGENTS-2026-11-02, P5 à P7)

- **P5, la méthode du train.**
  - Une branche `train/AAAA-MM-JJ[-x]` part de `main`. On y fusionne chaque lot par commit de
    fusion, sans écrasement.
  - Une seule PR `train → main`, ouverte en brouillon, puis passée en prête (`draft=false`) et
    fusionnée par **commit de fusion** (`merge_method: merge`, SHA complet attendu).
  - Le garde-cap a comparé chaque écran avant l'ouverture.
  - Au plus deux mises en production par jour.
- **P7, pousser peu.**
  - Branche sans PR, un seul push par tour.
  - Aucun push sur une branche déjà dans un train.
  - Les PR `test/`, docs ou `supabase/` seules restent libres et se fusionnent hors train.
- **Vercel Hobby.** Le plafond est de 100 déploiements par fenêtre glissante de 24 h, partagés par
  l'équipe ; les aperçus de la PR 187 (site public) comptent aussi. Pas de Vercel Pro (directeur).
  Un aperçu refusé pour quota ne compte pas comme un échec du train.
- **Après chaque fusion :**
  - le run « Flutter Web → Vercel » est vert, et l'étape « Controle du bundle SERVI » aussi ;
  - `https://app.rewayahacademy.com/version.json` rend `build_number` = numéro du run ;
  - on prévient le garde-cap, puis le directeur, avec ce qu'il doit tester lui-même.
- **Migrations.**
  - Préflight en lecture seule (`execute_sql`), puis `apply_migration` sans BEGIN/COMMIT, puis
    vérification de `md5(prosrc)` contre le fichier.
  - Tout `DROP`, `DELETE` ou `TRUNCATE` passe par une page Artifact à coller par le directeur
    (`tool/page_migrations/generer.py`).
- **Le bot de revue Codex** a atteint sa limite d'usage : on l'ignore.

## 3. État de la production

- `main` = 7ee028f7 (train c, PR 241, fusionné le 05/11 à 20:58 UTC) : FOYER-ÉLÈVE. Run 574 vert,
  `version.json` = 574. Juste avant lui, le site public (PR 187, 123236ce, 20:56 UTC) a été fusionné
  hors du pilote, sur demande du directeur selon le commit (run 573 vert). Le 05/11 compte donc trois
  mises en production (238, 187, 241), une de plus que la règle.
- Avant : 1eee5c3b (train b, PR 238, fusionné le 05/11 à 20:29 UTC) : FUSEAUX client et
  TEXTES-NEUTRES. Run 570 vert à 20:35, `version.json` rend `build_number` 570. Non prouvé par le
  directeur en production.
- Avant lui : le train a (PR 237, 0a6ee422, build 567). Il a mis en ligne les PR 224, 223, 225 et
  230 (matin du 04/11), plus 227 (questionnaire), 231 (renvoi du lien) et 234 (photo de l'adulte).
- Migrations installées le 04/11 :
  - GARDE-PROFIL `20261110000000` (PR 236, md5 ac83ecc4…) ;
  - FUSEAUX-bis `20261109900000` ;
  - B4 factures `20261102600000` (cron fac-* actifs) ;
  - V1-c et M1-A8 (collées par le directeur) ;
  - PHOTOS-2a, FUSEAUX serveur, DRAPEAUX.

## 4. Ce qui reste, dans l'ordre (ordre du directeur : chacun finit, puis on fait le point)

1. **FOYER-ÉLÈVE (N1).**
   - Fait : la ligne « Foyer » du Compte et des Réglages ne s'affiche qu'avec `aUnFoyer`
     (dff9739b, conforme selon le garde-cap).
   - Fini le 05/11 : l'interrupteur « Foyer · Activité des profils de votre foyer » ne s'affiche
     aussi qu'avec `aUnFoyer`. Branche `claude/foyer-eleve`, d0018d7b (contient main 1eee5c3b).
     Suite complète : 18 297 réussis, 0 échec, 7 136 sautés (comme main).
   - Conforme selon le garde-cap (capture 390/02). En production par le train c (PR 241, build 574).
     Non prouvé par le directeur.
2. **PHOTOS-A (I1)**, demande du directeur du 04/11 : « leur photo […] ne s'affiche pas partout,
   elle ne synchronise pas ».
   - Tout portrait lit `photoPersonneProvider(id)`.
   - `personneId` devient facultatif sur `AvatarNom`, `TuileSansImage` et `AvatarSansImage`.
   - `PhotoEnseignant` lit l'id.
   - Un test de garde, avec un socle qui ne peut que diminuer.
   - Écrans : `tc_*`, salle, profil de l'enseignant, catalogue, contrôleur, Studio. Fiche complète
     chez le garde-cap.
3. **PHOTOS-B (Fin de séance).**
   - Écrans : accueil de la famille, `carte_classe_seance`, finances, recharge, comptable,
     Communauté, Mon espace guidé, Comptes de la direction au téléphone, le Foyer et
     `compte_page.dart` (libérés le 05/11 à 20:58, après la fusion de FOYER-ÉLÈVE).
   - Ne touche ni `avatar_nom.dart` ni `lib/core/photos/`.
4. **DEMO-SUPPR D2 (C1)** : le harnais par rôle à la place de `demo_*_page.dart` pour 348 tests,
   en `test/` seul. R (le retrait dans `lib/`) n'est pas lancé sans ordre.
5. **Un train final** avec ce qui est conforme.
6. **PR 210 (SUPPRIMER, I1)** : en attente de l'enrôlement du téléphone par le directeur.

## 5. Ce qui attend le directeur (une chose à la fois, par page privée)

- **Page `ci.yml` groupée.** Elle ajoute les scénarios suivants :
  - anti_robot, v1b_creneaux, supprimer_bis, n3_compte_rendu_controleur, v1_entretiens ;
  - photos_2a_ecriture, fuseaux_interlocuteurs, drapeaux, cand_l3, v2e_fondateurs ;
  - b4_factures_cron, v1c_chevauchement, fuseaux_decalage_apres, garde_profil.

  Y joindre l'aperçu sur étiquette, pour économiser le quota Vercel, et l'épinglage de
  `supabase/setup-cli`.
- Les réglages MFA (la vraie cause reste un lot à faire), les clés Turnstile (jamais par la
  conversation) et les en-têtes de cache de `vercel.json`.
- **Ménage**, après accord sur la liste :
  - branches `train/2026-11-04`, `train/2026-11-04-a` et `train/2026-11-04-b` ;
  - worktree `/home/user/wt-train` dans le conteneur du pilote.
- **Rappel du 20/11** (`trig_01NkvMcFF7RECikj1YTjXzAa`) : saisir les prix spéciaux et les accès
  offerts avant les factures du 24/11.

## 6. Décisions prises sans le directeur (ne plus jamais les lui reposer)

- « Fondateur » reste au masculin générique (mots-rewayah §1). « Fondatrice » selon la personne
  seulement si le serveur rend un jour le genre (`personnel_pour_entretien`).
- La démo est supprimée, dans l'ordre D1, D2, puis R. Un enfant ne voit pas le prénom de ses
  camarades en salle (défaut protecteur).
- Les libellés V2-e (« Marquer comme fondateur » / « Retirer des fondateurs ») et les trois notions
  V2-a : décidés.

## 7. Finitions notées, hors lot (un lot de finition plus tard)

- À 1280, « Connecter l'appareil d'un élève » passe sur deux lignes (le texte ne change pas, A.7).
- À 1440 en français, « Échanger sur cette Classe » porte une majuscule au milieu de la phrase.
- À 1440 en arabe, la note « الأيام المعتادة… » flotte en haut à gauche, au lieu d'être sous la
  carte.
- En arabe, le pays reste « Côte d'Ivoire » en lettres latines (DRAPEAUX-bis).
- Question ouverte de N1 : l'enfant choisit-il la langue de ses courriels ? Rien n'est codé.
  `updated_at` reste modifiable par l'enfant.
