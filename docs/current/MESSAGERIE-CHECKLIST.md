# Messagerie : checklist du pilote

**Mise à jour : mardi 17/11/2026, 10 h 55 UTC.** Cette page est mise à jour à chaque étape.

## Où on en est, en clair

**#551 (couleurs, croix, champ) est fusionnée à 21 h 22 UTC (`906ba099`)**, **déployée en production à 21 h 28 UTC**
(déploiement 1302 vert) ; **pas encore vue par vous** : fermer puis rouvrir l'application.

**Ce que je fais (le pilote)** : je ne code pas. Je donne le travail à un seul agent, je le contrôle
toutes les 30 minutes, je relis ses captures et la CI, puis je fusionne et j'installe en base.

**Ce que j'ai demandé à l'agent (un lot à la fois)** :

1. **Finir la correction des couleurs, #551** : **fusionnée à 21 h 22 UTC**
   - [x] reprendre la branche de l'agent précédent (archivé, il avait fini son contexte)
   - [x] régénérer les textes et le code : aucun changement
   - [x] contrôle du code (`analyze`) : zéro erreur
   - [x] écrire, et cette fois enregistrer, le code qui fait les captures (il avait été perdu)
   - [x] tous les tests de l'application : 22 375 passés, 0 échoué ; vérificateurs verts
   - [x] faire les captures (`07fa7688`) : volet avec la croix, liste, fr et ar, clair et sombre
   - [x] **moi** : relu 3 captures. Croix visible ; fil sur le fond de page ; bulles reçues lisibles
         (aucun contour à ajouter, décision du pilote) ; liste en carte blanche
   - [x] heure du dernier message coupée sous le champ : défaut de la capture seulement, prouvé par
         deux tests (fr, ar)
   - [x] reprendre les dernières fusions de l'équipe (`73651b66`) ; #563 fusionnée depuis, sans conflit
   - [x] CI lue par le pilote : 11 contrôles verts, 2 ignorés (aperçus)
   - [x] **moi** : captures relues, fusion
   - [ ] **vous** : voir en production (fermer puis rouvrir l'application)
2. **NOUVEAU-FILS** : **fusionné (#566) et déployé à 22 h 39, migration installée à 22 h 35 UTC**
   - [x] badge « Nouveau » sur une conversation de moins de 7 jours que personne de l'équipe n'a lue
   - [x] une conversation vide affiche « Nouveau » et « Aucun message »
   - [x] filtre « Nouveaux » dans la liste
   - [x] migration installée par le pilote et vérifiée ; appels réels en 200
3. **NOUVELLE-VERSION** (ensuite) : bandeau « Nouvelle version disponible », jamais de rechargement
   pendant que vous écrivez.

**Ce qui attend votre décision** : voir « Pour le directeur au réveil », en bas.

## Point du matin (dix lignes au plus)

1. **Fusionné et déployé** : #551 couleurs, croix du volet, champ (21 h 28 UTC) ; #566 NOUVEAU-FILS,
   badge « Nouveau », « Aucun message », filtre « Nouveaux » (22 h 39 UTC). Déploiements verts.
2. **Installé en base** : `nouveau_fils` (22 h 35 UTC), vérifié ; depuis, les appels réels à la liste et
   au fil répondent 200, aucune erreur Postgres.
3. **Pas prouvé** : rien n'est vu par vous. Fermez puis rouvrez l'application, puis regardez Messages.
4. **Le badge « Nouveau » ne se voit que côté équipe** (décision du pilote : une famille ne doit pas
   savoir si l'équipe a lu).
5. **À décider par vous** : ajouter `scenarios_image_candidat.sql` et `scenarios_nouveau_fils.sql` à
   `ci.yml` (zone interdite aux agents) ; bulles reçues pâles (sans contour, décision du pilote).
6. **Praxis (Pilote Équipe, #567) a retouché l'envoi des messages et des annonces à 23 h 14-16 UTC**,
   relu par le pilote avant. **Envoi d'un message prouvé en production** : 3 messages réels (00 h 27,
   02 h 52, 03 h 19 UTC), réponse 200, un seul message en base chaque fois. L'envoi d'une annonce n'a pas
   encore servi depuis : non prouvé.
7. **Aucun agent messagerie actif.** Suite en liste : NOUVELLE-VERSION, comptes Praxis, CHECK des
   notifications (écart dépôt / production, aucune personne touchée).

## Faux, bloqué ou non prouvé (à lire d'abord)

- La messagerie est grise depuis #512, la croix du volet a disparu (#540), le champ de saisie
  s'arrondit en cercle : corrections dans la PR #551, **pas fusionnée**, CI pas encore lancée.
- L'agent précédent de #551 (`session_0163KjrvV6fGAftwzWig2qU9`) a poussé `571f558a` (fusion de
  `main` 1ae0202e, sans conflit, vérifié par le pilote) et a été **archivé à 19 h 47**. Sur ce commit,
  **rien n'est vérifié** : ni slang, ni build_runner, ni analyze, ni tests, ni CI ; #551 est encore en
  brouillon, donc sans CI.
- Le conteneur de l'agent de #551 a été recréé : il a **perdu, non poussées**, les captures du volet
  (croix) et de la liste 1440. La tête poussée `667a9543` est intacte. **La croix du volet n'a aucune
  capture** ; elle n'est prouvée que par un test. L'agent attendait une réponse de l'utilisateur de sa
  session ; le pilote lui a relayé la consigne de reprise du directeur (« il repart de sa branche
  poussée »).
- Vérifié par le pilote : entre la base de #551 (`af1cfbb9`) et `main`, aucun changement dans `lib/`
  ni `assets/i18n` ; fusion sans conflit.
- Plafond de quatre agents : un seul agent messagerie à la fois ; NOUVEAU-FILS part après #551.
- #538, #540, #546 sont en production mais **pas vus** par le directeur.
- Le plantage à l'ouverture d'une conversation depuis un profil n'est **pas reproduit**.
- Erreurs de l'ordre de prise de poste, constatées : le fichier `PASSATION-MESSAGERIE-2026-11-16.md`
  n'existe pas (la passation s'appelle `MESSAGERIE-HANDOFF-2026-11-16.md`) ; l'adresse du Pilote Équipe
  donnée par la passation (`session_0163KjrudJVgfH6zMjadp2bb`) diffère de celle reçue ce soir
  (`session_0163KjrvqR38dL9HhgktqAdg`, retenue).

## En cours

| Lot | Qui | Statut | Prochaine étape |
| :--- | :--- | :--- | :--- |
| MESSAGERIE-COULEURS #551 | agent neuf `session_0163KjrwKsohCvdhrjhrWP5N` (Sonnet, lancé 19 h 48) | PR brouillon ; `7e7fae52` poussé (19 h 54) : slang ×2 et build_runner sans changement, analyze à zéro, code des captures commité ; `flutter test` complet en cours, captures non générées, CI non lue | l'agent relance slang deux fois, build_runner, analyze, `flutter test` complet, les trois vérificateurs ; refait et **commite** les captures du volet (1440, fr et ar, clair et sombre, fil remonté, croix) et de la liste 1440 ; passe la PR en « prête », lit la CI ; le pilote relit les captures avant/après (téléphone et ordinateur, clair et sombre, ce qui change ailleurs), lit la CI, prévient le Pilote Équipe (`lib/core`, `assets/i18n`), fusionne |
| Cette checklist #560 | pilote | PR | fusion quand la CI est verte |

## À lancer

| # | Lot | Condition | Détail |
| :--- | :--- | :--- | :--- |
| 1 | NOUVEAU-FILS | après #551 et une place d'agent libre | badge « Nouveau » (`lib/core/widgets/badge_nouveau.dart`), « Nouveau · aucun message » pour une conversation vide, filtre « Nouveaux » ; règle serveur : moins de 7 jours et aucune ligne `com_lectures` d'un membre de l'équipe ; migration `202611295xxxxx` au-delà de `20261129500000` (déjà pris), vérifiée sur `origin/main` ; session neuve |
| 2 | NOUVELLE-VERSION | après NOUVEAU-FILS | bandeau « Nouvelle version disponible » qui lit `version.json` ; jamais de rechargement pendant un brouillon ou un envoi |
| 3 | Canal du Studio dans la nouvelle présentation | décision du directeur | d'abord un emplacement d'en-tête au fil plein écran ; risque sur le mode focus |
| 4 | Bouton « i » emporté par la barre repliée (Messages, ordinateur) | lot à part | relevé par l'agent de #551, hors de #551 |
| 5 | `scenarios_fac_f_relances_suspension.sql` indépendant de l'heure | sans urgence | échoue le lundi 7-8 h UTC |
| 7 | Comptes officiels dans les conversations (Praxis) : *#RA_PRAXIS*, *#RA_STAFF*, « Assistant de l'académie · IA », « Parler à l'équipe » (`BUREAU-EQUIPE/SECRETAIRE-IA.md` §9, §11) | après NOUVEAU-FILS, pas cette nuit | signalé par le Pilote Équipe le 16/11 à 21 h 15 ; plage `202611296…` réservée à Praxis, pas à la messagerie |
| 8 | Écart dépôt / production : `notifications_evenement_check` accepte `annonce_direction` en production, mais aucune migration du dépôt ne l'ajoute (`20261126900000` l'annonce seulement). Une base rejouée depuis le dépôt (CI) ne notifie aucune annonce | petit lot de rattrapage, après NOUVEAU-FILS | relevé par BE-PIECE (PX-1), vérifié en production par le pilote le 16/11 à 22 h 12 ; aucune personne touchée en production ; PX-1 prévenu de garder les 61 valeurs de la production s'il réécrit ce CHECK |
| 9 | L'application appelle `com_envoyer_message` deux fois par envoi (30 à 150 ms d'écart) ; la clé d'idempotence évite le doublon en base (vérifié : 1 message par paire) | petit lot, sans urgence | relevé par le pilote le 17/11 à 04 h 15 dans les journaux de production |
| 6 | Recette du directeur en production : #538, #540, #546, puis #551 | après fusion de #551 | liste d'essais, une par une, page humaine |

## Corrections non bloquantes demandées par le directeur

| Date | Demande | Statut |
| :--- | :--- | :--- |
| 16/11 | Le lecteur vocal dans sa propre bulle : contraste à revoir | à faire, à l'ouverture des vocaux |
| 16/11 | « Enregistrer l'image » exige la règle CORS sur le `GET` | à vérifier dans Cloudflare |
| 16/11 | Test local `images_messagerie_test` (glisser vers le bas) qui échoue en local, passe en CI | cause inconnue |

## Pour le directeur au réveil

- **Bulles reçues en clair** : l'agent mesure 1,13:1 entre la bulle et le fond ; seule l'ombre la
  détache. Le pilote a jugé sur capture qu'elles restent lisibles et n'a pas ajouté de contour. Si vous
  les trouvez trop pâles en production, un contour fin est une petite correction.
- **Drapeau du Sénégal absent** sur une capture du dossier (volet, fr clair), cause non vérifiée, hors
  messagerie : signalé, non traité.

1. Un fin contour sur les bulles reçues si, après #551, elles se fondent dans le fond clair
   (contraste 1,14:1) ?
2. Le canal du Studio dans la nouvelle présentation, au risque du mode focus ?
3. Ajouter `scenarios_image_candidat.sql` à `.github/workflows/ci.yml` (zone interdite aux agents) ?
4. Le plantage depuis un profil : au prochain essai, noter l'heure exacte et faire une capture.

## Journal du pilote

- 16/11, 19 h 18 : prise de poste de `session_0163KjrvfAPWhND7VanbMLHL` ; checklist ouverte (#560) ;
  session archivée à 19 h 23.
- 16/11, 19 h 40 : prise de poste de `session_0163Kjrx8uX1pRbk4RhE7Yuz` ; lectures faites ; agent de
  #551 contacté ; Pilote Équipe contacté (plafond d'agents, fichiers partagés) ; checklist renommée
  `MESSAGERIE-CHECKLIST.md`.
- 16/11, 19 h 40 : le Pilote Équipe (#557 redéploie courriels-envoi et push-envoi) : rien de la
  messagerie ne les touche, il peut fusionner. Aucune migration messagerie annoncée cette nuit hors
  NOUVEAU-FILS.
- 16/11, 19 h 40 : l'agent de #551 signale la perte des captures du volet ; consigne de reprise relayée.
- 16/11, 19 h 47 : prise de poste de `session_0163KjrvqyXGcbF9eGGztS24`. Agent de #551 archivé après
  « poussé » (`571f558a`). Agent neuf `session_0163KjrwKsohCvdhrjhrWP5N` lancé sur #551 seul. Pilote
  Équipe (`session_0163KjrwwgbbL52RHBDSnDVm`) prévenu des fichiers partagés de #551, dont
  `admin_candidature/volet_conversation.dart`.
- 16/11, 19 h 54 : agent de #551 : `7e7fae52` (slang ×2 et build_runner sans changement, analyze à zéro,
  code des captures commité ; tests et captures en cours). Pilote Équipe : 3 agents de son côté, plafond
  de 4 atteint ; il fusionnera #547 (i18n générés, router, main.dart) ; #551 devra ensuite fusionner
  `main` et relancer slang deux fois. Ses migrations de ce soir : `20261129440000`, `480000`, `490000`.
- 16/11, 20 h 10 : contrôle. `main` a reçu #553, #555, #557 ; #547 pas encore. Agent inactif depuis
  19 h 54 (« en attente des tests ») : relancé par message.
- 16/11, 20 h 10 : agent : `flutter test` complet en cours, 4 172 passés, 1 663 sautés, pas fini.
- 16/11, 20 h 15 : le directeur ne voyait pas la checklist (elle était sur une branche) ; réécrite
  en clair en tête de page et envoyée directement.
- 16/11, 20 h 45 : `07fa7688` (main fusionnée, captures). Pilote : 3 captures relues ; décision :
  pas de contour sur les bulles reçues ; défaut signalé (heure du dernier message sous le champ).
- 16/11, 21 h 20 : #551 prête, CI verte relue par le pilote (11 succès, 2 ignorés), aucun changement
  d'i18n ni de widgets partagés dans main depuis sa dernière fusion ; Pilote Équipe prévenu.
- 16/11, 21 h 22 : **#551 fusionnée** (`906ba099`). Erreur du pilote : un premier essai de fusion avec
  un identifiant de commit recopié de mémoire, refusé par GitHub, sans effet ; refait avec l'identifiant lu.
- 16/11, 21 h 25 : NOUVEAU-FILS confié au même agent ; migration `20261129510000` vérifiée libre sur main.
- 16/11, 21 h 28 : déploiement de production de `906ba099` vert (« Flutter Web → Vercel », run 1302).
- 16/11, 22 h 12 : signalement « annonces non notifiées » : faux en production (vérifié) ; vrai écart dépôt / production, mis en liste (n° 8).
- 16/11, 22 h 34 : **#566 fusionnée** (`8f320a9b`) en premier, accord du Pilote Équipe ; CI relue (11 verts).
- 16/11, 22 h 35 : **`nouveau_fils` installée** (enregistrée `20261116223511`). Avant : fonction plpgsql,
  ancre unique, contexte (`f`, `p_moi`, `p_role`, `p_foyer`) et colonnes vérifiés en production. Après :
  clé présente, attributs et droits inchangés. Appel direct de la fonction refusé par le garde-fou ;
  remplacé par la lecture des journaux : appels réels `com_lister_fils` / `com_lire_fil` en 200 de 22 h 47
  à 22 h 51, aucune erreur Postgres.
- 16/11, 22 h 35 : agent `session_0163KjrwKsohCvdhrjhrWP5N` archivé (place libérée).
- 16/11, 22 h 39 : déploiement de `8f320a9b` vert (run 1309).
- 16/11, 23 h 14-16 : PX-1 (#567, Pilote Équipe) installé : extraction des internes de `com_envoyer_message` et `com_annonce_envoyer`, contrôle md5 passé, `com_fil_json` non touchée, CHECK des notifications non réécrit (relu par le pilote avant). Journaux depuis 23 h 13 : 42 appels de messagerie, 39 en 200, 3 en 204, 0 erreur ; aucun envoi réel, donc envoi non prouvé.
- 17/11, 04 h 15 : envoi prouvé (3 messages réels en 200, 1 ligne en base chacun) ; double appel du client relevé, absorbé par l'idempotence (liste n° 9) ; envoi d'annonce pas encore exercé.

### Matin du 17/11 : affichage de Praxis (ordre du directeur, « Praxis opérationnel ce soir »)

- [x] **#612 PRAXIS-AFFICHAGE fusionnée** (`6f2e1c58`, 09 h 53 UTC) : nom **#Ra_Praxis sans italique** (directeur,
  confirmé à 9 h 05 : « je confirme le nouveau nom et l'image est déposée »), indicateur de compte officiel, fiche du
  profil « Assistant de l'académie · IA ». **Déployée** à 10 h 00 UTC (run 1400 vert). **Pas vue par vous.**
- [x] **Migration `com_compte_officiel` installée** (09 h 54 UTC, enregistrée `20261117095418`) : chaque participant
  porte `officiel` et `compte_officiel` (code du compte, `praxis` aujourd'hui). Vérifiée : attributs et droits
  inchangés. Journaux depuis : 41 appels de messagerie, tous 200 ou 204, aucune erreur Postgres.
- [x] **#618 image de Praxis fusionnée** (`d70c99a3`) et **déployée** (run 1409 vert, 10 h 38 UTC) : l'image fournie
  par le directeur, réduite à 256 px sans retouche (14 Ko), affichée seulement pour le compte `praxis` ; captures
  relues par le pilote (lisible à 24 pt, la toque se lit, les yeux sont petits). **Pas vue par vous.**
- [x] **#616 fusionnée** : le PNG plein format est conservé dans `assets/brand/praxis/` (non embarqué dans l'appli).
- [x] Agent `session_0163Kjry6zThXGyFJhJk9NHn` **archivé** à 10 h 28 : la messagerie n'a plus d'agent actif.
- [ ] **Non fait** : bouton « Parler à l'équipe » (aucune action existante pour ouvrir une conversation avec l'équipe ;
  rien inventé).
- Arrêté sur ordre direct du directeur : l'icône dessinée par l'agent (« je vais le faire moi-même »).
- Pour le directeur : `scenarios_com_compte_officiel.sql` à ajouter à `ci.yml` (zone interdite aux agents).

## POUR JEUDI SOIR (20/11) — PX-BULLE ne s'affiche pas en production (constat du directeur, 17/11 ~16 h UTC)

- **Faux** : #622 est déployée (13 h 51 UTC), mais le directeur voit encore « le compte de l'académie » sur un message de Praxis.
- **Vérifié en base** : le message « Bonjour, oui, c'est bien moi… » (13 h 25 UTC) a bien pour auteur le compte Praxis
  (`comptes_officiels.code = 'praxis'`), dont le rôle est `accountant`.
- **Cause probable, NON prouvée** : dans un fil avec l'académie, `private.com_participant` rend l'auteur de l'équipe
  sous la nature « équipe » (l'académie), pas « profil » ; la migration `20261129520000` n'a ajouté `officiel` et
  `compte_officiel` que dans la branche « profil ». Le client ne reçoit donc pas `praxis` et n'affiche ni image ni nom.
- **À faire** : 1) lire `pg_get_functiondef('private.com_participant(...)')` et le JSON d'un message de Praxis pour
  confirmer ; 2) nouvelle migration (plage 202611295…) qui rend `compte_officiel` aussi quand l'auteur réel d'un message
  est un compte officiel, quelle que soit la nature affichée ; 3) test sur ce cas exact (fil avec l'académie, auteur
  Praxis de rôle `accountant`) ; 4) fermer puis rouvrir l'application pour vérifier.
- **Règle précisée par le directeur (17/11, soir)** : Praxis n'a PAS de conversation à lui. Il écrit dans la conversation
  entre l'académie et la personne, par le compte de l'académie. La personne voit en haut l'académie (#RA_STAFF), mais
  chaque message écrit par Praxis porte son image et « #Ra_Praxis ». L'administration voit ces messages de son côté
  (les siens), et ceux de Praxis sont marqués de son image.
- **Second défaut à corriger (client)** : #622 n'affiche le marqueur que si `!m.deSoi` (`lecture_fil_communication.dart`,
  `messageFilDe`). Côté administration, un message de Praxis est « de soi » : le marqueur doit aussi s'y afficher
  (image et nom sur la bulle de soi), sans changer les messages écrits par un humain de l'équipe.

### État de la correction PX-BULLE-2 (PR #634), 17/11 16 h 10 UTC

- CI de #634 (commit 975421857) : migrations applicables sur Postgres 17 vertes, build web vert, tests Flutter lots 0 et 1 verts.
- **Bloqué** : « Captures R3 » rouge, il manque les captures d'écran du changement (`docs/current/captures/E2E/PX-BULLE-2/`). Règle R3 : pas de capture, pas de fusion. Rien n'est fusionné, la migration 20261129530000 n'est **pas** installée.
- Demande faite à l'agent (session_0163Kjrxownsxaf7Mi26sad3) : produire de vraies captures, ou dire qu'il ne peut pas. Interdiction de fabriquer une image.
- Jeudi : si les captures sont là et la CI toute verte, fusionner #634, installer 20261129530000 (ancre `END || pg_catalog.jsonb_build_object('est_soi', m.auteur_id = p_moi))` à vérifier une fois en prod avant), puis le directeur ferme et rouvre l'appli.
- 16 h 06 UTC : l'agent répond « captures impossibles » (Flutter absent de son conteneur ; rien fabriqué). Agent archivé, place libérée. Jeudi : lancer un agent dont le conteneur a Flutter (comme celui de PX-BULLE) pour les seules captures `PX-BULLE-2`, puis fusion et installation.
