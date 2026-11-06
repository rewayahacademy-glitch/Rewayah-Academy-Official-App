# Passation du garde-cap, 05/11/2026

**Successeur en poste le 06/11/2026 vers 09:40 UTC : `session_0163KjrwyawmrhemnpDkEL4X`.** Les rapports des agents et du pilote destinés au garde-cap vont à cette session. Contrôle quotidien recréé (`trig_01SFMEq8Si8axxotmjn3atzA`, 04:43 UTC). Contrôle horaire **non recréé** : aucun agent ne construit (relevé de 09:40, toutes les sessions d'agents à l'arrêt) ; il est recréé quand le nouveau pilote lance un agent, et arrêté quand plus aucun ne construit (§12, point 7). Nouveau pilote : pas encore nommé par le directeur.

**Retrait effectif le 06/11/2026 vers 02:45 UTC.** `main` 6943a873, build 582 en production (train du 06/11 : photos partout, Comptes au téléphone, boucle `mon_horloge`, textes des revenus). Les deux contrôles planifiés du garde-cap sont supprimés. Aucune question n'est laissée ouverte au directeur : tout ce qui reste est un lot de `PLAN-LOTS.md` §7, rangs 22 0 à 23.

Ordre du directeur du 05/11 vers 20:35 UTC : chacun finit les tâches qui lui ont été confiées, on fait le point, puis le pilote et le garde-cap se retirent, car leur contexte devient trop lourd. Cette page permet à un successeur de reprendre le rôle de garde-cap sans relire l'historique.

Session sortante : `session_018zqR7D4uVdaYUvrgoEHNPG`. Un successeur n'est lancé que sur ordre du directeur.

## 1. Ce qui est faux, bloqué ou non prouvé (à lire en premier)

- **Plafond hebdomadaire.** Du 04/11 16:30 au 05/11 20:00 UTC, toutes les sessions ont été bloquées : 4 agents, le pilote et le garde-cap consommaient ensemble le plafond de la semaine en 4 ou 5 jours. Le directeur a choisi de finir avec les 4 agents, puis de faire le point. Il faut ralentir après ce point : la décision du 29/10 prévoit 2 agents au plus.
- **Non prouvé en production, faute de compte :**
  - bandeau « personne occupée » ;
  - photos ;
  - Compte de l'enfant ;
  - changement de compte ;
  - Compte du tuteur.
- **Train b (PR 238)** : fusionné le 05/11 vers 20:30 UTC (1eee5c3b), CI verte sur c9c56ed1. Contrôles à faire après le déploiement : heure du tuteur « Paris » et textes de refus en arabe.
- **Mon oubli à la revue de la PR 231** : à 1280 px, « Connecter l'appareil d'un élève » tient sur 2 lignes. C'est noté pour le lot de finition.

## 2. Le rôle

Le garde-cap ne construit rien, ne fusionne rien et n'installe aucune migration.

**Il est l'arbitre.** Quand une question n'est ni d'argent, ni de sécurité, ni de données personnelles, ni de droit, il tranche lui-même, l'écrit dans `PLAN-LOTS.md` §7 et l'annonce au pilote. Il ne renvoie jamais la décision au pilote (« à toi de juger ») ni au directeur (« dites-moi si c'est voulu »). Le 05/11 au soir, le directeur a reproché au garde-cap sortant d'avoir délaissé ce rôle.

Il fait aussi sept choses :

1. Il relève les demandes du directeur et en écrit la fiche : cause, exige, écrans avec lignes de code, hors lot, preuve exigée. Exemple : `garde-cap/FICHE-PHOTOS-PARTOUT-2026-11-04.md`.
2. Il relit les PR serveur : RLS, `SECURITY DEFINER`, `search_path` vide, mots DROP, DELETE et TRUNCATE comptés.
3. Il compare chaque lot d'écran, capture contre demande, avant le feu vert du pilote. Les couleurs se mesurent sur les captures `brut/`, jamais sur les captures allégées.
4. Il tient la table des numéros de migration : `garde-cap/RESERVATIONS-MIGRATIONS.md`. Toute nouvelle migration prend un numéro au-dessus de la dernière installée en production.
5. Il vérifie en production, en lecture seule, après chaque installation (md5 de la fonction, propriétaire, droits).
6. Il fait le contrôle horaire et le contrôle quotidien (§5).
7. Il tient la documentation dans sa propre PR de docs.

Règles de parole avec le directeur :
- en français, avec des mots simples, la vérité d'abord, sans tiret long ;
- jamais de tests à lui faire faire ;
- ne jamais reposer une question déjà tranchée ;
- argent, sécurité, données personnelles et droit lui arrivent en une seule question groupée ;
- pas de message la nuit.

## 3. Les sessions

| Rôle | Session |
|---|---|
| Pilote (fusionne, installe, fabrique les pages à coller) | `session_0163Kjrv38i3CYWs5z3wtmWi` |
| C1 | `session_0163KjrwZ15mab73PMw441R3` |
| I1 | `session_0163KjrvZfk2JT1EXKk17hdH` |
| N1 | `session_0163KjrxdNHzGwurffK4qWjt` |
| Fin de séance (FdS) | `session_0163KjrwZrC2S3DjyQZCYQJB` |
| ETUDE-CAHIER (étude seule, lancée le 05/11 par le garde-cap ; ses conclusions sont à arbitrer) | `session_0163KjrwMz3ndownaQNWTJkS` |
| Site public (session du directeur, ne pas piloter) | `session_0163KjrxSa9pANwwSgjNENEv` |
| Metricool (session du directeur, ne pas piloter) | `session_0163KjryMowJDcpyHg3gVWYT` |

## 4. Tâches en cours au 05/11 20:40 UTC

Toutes les sessions ont été relancées avec la consigne de finir leur tâche, sans en prendre une nouvelle, puis d'envoyer leur bilan au pilote.

| Agent | Tâche | État | Ce que le garde-cap doit faire |
|---|---|---|---|
| N1 | FOYER-ÉLÈVE : masquer l'interrupteur « Foyer · Activité des profils » des Réglages de l'élève (capacité `aUnFoyer`) | corrigé en local, suite complète à relancer, pas poussé | recomparer la capture 390/02 au SHA |
| I1 | PHOTOS-A (enseignant, salle, Mes groupes, catalogue, contrôleur, Studio, test de garde), puis **l'envoi de la photo au téléphone** | plan conforme le 05/11 ; envoi au téléphone confié par l'arbitrage du 05/11 22:40 | comparer contre la fiche ; exiger la preuve robot de l'envoi à 390, dans le même document |
| FdS | PHOTOS-B (suivi du foyer, accueil, Foyer, recharge, Mes finances, comptable, « Vous », Mon espace guidé, Comptes au téléphone) | partie hors Foyer conforme (f290540b, 05/11 22:20) ; reste le Foyer, et la cause de l'absence de photo dans Comptes de la direction | recomparer le Foyer et Comptes ; un seul train photos quand A, B et l'envoi au téléphone sont prouvés |
| I1 | PR 210 SUPPRIMER (exception à P6) | brouillon ouvert | relecture serveur, règle du collage pour DELETE |
| C1 | D2 : une PR qui ne touche que test/ | relancé par le pilote le 05/11 | vérifier qu'aucun fichier hors test/ n'est touché |

## 5. Contrôles planifiés

- **Contrôle horaire** `trig_014BKxvPVSUN15LdVG7RdZrL`. Il relève :
  - les fusions dans `main` ;
  - les branches poussées ;
  - les zones du directeur touchées ;
  - les migrations ;
  - le nombre d'agents et de PR ouvertes ;
  - les déploiements en échec.
- **Contrôle quotidien** `trig_01LLgorsxNhDxiVNfimcv98q`. Il produit un résumé de 3 lignes au plus pour le directeur : en production depuis hier, pas prêt, son action seulement si elle est nécessaire.

Ces deux contrôles visent la session sortante. Au retrait, le directeur décide : les supprimer, ou les recréer pour le successeur. Ils consomment du plafond : une fois par heure, c'est cher.

## 6. Règles techniques à connaître

- **Trains (P5).**
  - Une branche `train/AAAA-MM-JJ[-a|-b]`. Les PR y entrent par commit de fusion, et le train entre dans `main` de la même façon.
  - Au plus 2 mises en production par jour.
- **Agents (P6 et P7).**
  - Une PR en travail et une en attente au plus par agent.
  - Une branche sans PR, un push par tour de correction. Le SHA va au pilote et au garde-cap.
- **Vercel Hobby.**
  - 100 déploiements par jour.
  - Ouvrir une PR qui touche `lib/` crée un aperçu.
  - Ne jamais jouer d'E2E sur un aperçu (G5).
- **Code généré.**
  - La CI (ci.yml l. 506-512) relance slang et build_runner, puis échoue si `git status --porcelain` n'est pas vide.
  - Après une fusion, il faut régénérer, jamais résoudre à la main : les coupures `switch (path)` de `strings_*.g.dart` bougent.
- **URL de l'application.** Le routage passe par le dièse : `https://app.rewayahacademy.com/#/commencer`.
- **Photos.**
  - Seule source fraîche : `photoPersonneProvider(profileId)` (`lib/core/photos/photo_personne.dart`).
  - `cleAvatar`, `avatar_storage_key`, `teacher_photo_cle`, `photo_storage_key`, `avatarUrlProvider` et `photoEnseignantUrlProvider` sont périmés pour l'affichage.
- **Méthode de connexion.** `methodeConnexionDepuis` (`lib/core/capacites/identite_titulaire_supabase.dart:91-98`) : Google, ou lien. Le mot de passe est éteint dans toutes les constructions (flutter-deploy.yml l. 157).
- **Deploy Supabase.** `supabase/setup-cli@v1` avec `version: latest` (deploy.yml l. 50 et 102) rougit quand GitHub limite les appels. La correction est dans la zone du directeur.

Le garde-fou `.claude/hooks/garde.py` n'est jamais contourné :
- l'identifiant du projet de production ne va jamais dans une commande shell ;
- la production est en lecture seule ;
- aucune écriture SQL par execute_sql.

`.github/`, `vercel.json`, `pubspec.yaml` et `site-public/` appartiennent au directeur.

## 7. Liste du directeur (ses gestes, rien à faire par les agents)

1. Fixer la version du CLI Supabase dans deploy.yml.
2. Supprimer la branche abandonnée `train/2026-11-04`.
3. Activer TOTP pour la direction.
4. Régler Turnstile (clé secrète jamais dans le dépôt ni dans la conversation).
5. Décider de la PR 187 du site public.
6. Fixer les prix spéciaux avant le 24/11.
7. Répondre aux questions de la session Metricool.

Points encore ouverts dans ma liste de tâches d'avant le 03/11. Je ne les ai pas revérifiés ce soir ; le successeur confirme leur état avant d'en parler :
- DKIM et DMARC du domaine. Le jeton Cloudflare est à révoquer par le directeur une fois ces deux réglages posés.
- Envoi du plan du site à Search Console et à Bing.
- Secret `APP_ORIGINES` après la bascule du domaine.
- Allègement de la CI (Windows, APK).
- FN-115 : remboursements et litiges.

## 8. Lots suivants, déjà arbitrés

L'ordre est écrit dans `docs/current/RELEVES-2026-11-02/PLAN-LOTS.md` §7 :
1. **22 0, ENTREE-ORDRE.** Pour un nouveau profil, le questionnaire vient avant l'e-mail et la connexion. C'est une règle du directeur, cassée par la refonte de l'entrée du 04/11 ; le garde-cap sortant ne l'a pas vue à la revue.
2. **22 a, PREFERENCES-WEB.** Le thème choisi est mémorisé, et la langue de l'application se choisit (français ou arabe) et se mémorise aussi.
3. **22 b, la finition** (liste ci-dessous).
4. **22 c, le site public en arabe.** Il est noté, mais aucun travail sans une demande du directeur.
5. **Les rangs restants : 9, 13, 15, 16 et 21.**
6. **23, l'harmonisation de l'interface,** en une seule passe.

Le nouveau pilote part avec ces lots.

Lot de finition (22 b) :

- À 1280 px, le libellé de la page de connexion tient sur 2 lignes.
- « cette Classe » : la majuscule est en trop (1440, FR).
- Note du planning mal placée (1440, AR).
- DRAPEAUX-bis : le nom du pays dans la langue de l'écran.

## 9. Fichiers repris de l'espace de travail

- `garde-cap/FICHE-PHOTOS-PARTOUT-2026-11-04.md` : la fiche en cours.
- `garde-cap/RESERVATIONS-MIGRATIONS.md` : la table des numéros, état au 04/11. La dernière migration en production est GARDE-PROFIL 20261110000000.
- `garde-cap/JOURNAL-GARDE-CAP.md` : le journal du 03/11 au 05/11 (contrôles, comparaisons, écarts).
- `garde-cap/outils/*.cjs` : scripts Playwright pour les vues de production sans compte.
  - `chargement.cjs` et `lent.cjs` : chargement, et réseau lent à 4 Mbit/s.
  - `ecrans.cjs` et `parcours.cjs` : actions click, type, key, wheel, wait, shot.
  - Format CommonJS (`require('playwright')`), à lancer depuis un dossier de travail. Les chemins de sortie sont relatifs.

## 10. Le retrait (décision du garde-cap, 05/11, sur l'offre du directeur)

Le pilote et le garde-cap restent jusqu'à la fin des lots en cours, puis se retirent. Les nouveaux partent avec les lots du §8. Raison : PHOTOS-A, PHOTOS-B et l'envoi au téléphone dépendent du contexte déjà accumulé (la fiche, les comparaisons, les constats). Les passer à mi-chemin coûterait une relecture complète.

Le retrait a lieu quand ces quatre conditions sont vraies, et pas avant :
1. Le train photos (PHOTOS-A, PHOTOS-B complet, envoi au téléphone) est en production, ou bloqué avec sa cause écrite.
2. La PR 210 (SUPPRIMER) et D2 (C1) sont fusionnées, ou arrêtées avec leur état écrit.
3. Chaque agent a envoyé son bilan au pilote, et le pilote l'a recopié dans `PASSATION-PILOTE-2026-11-05.md`.
4. Cette page et celle du pilote sont sur `main`.

Au retrait, le garde-cap sortant :
- supprime ses deux contrôles planifiés, `trig_014BKxvPVSUN15LdVG7RdZrL` et `trig_01LLgorsxNhDxiVNfimcv98q`, qui visent sa session ;
- ajoute en tête de cette page la ligne « Retrait effectif le … », avec l'état de `main` et le dernier build en production ;
- ne laisse aucune question ouverte au directeur : tout ce qui reste est un lot du §8.

## 11. Message de lancement du successeur (à coller tel quel par le directeur)

> Tu es le garde-cap de Rewayah Academy. Lis, dans cet ordre, et rien d'autre avant d'agir :
> 1. `CLAUDE.md`, puis `docs/orchestration/CONSIGNES-DIRECTEUR-EN-VIGUEUR.md` (toutes les consignes du directeur, en vigueur) ;
> 2. `docs/orchestration/PASSATION-GARDE-CAP-2026-11-05.md` ;
> 3. `docs/orchestration/PASSATION-PILOTE-2026-11-05.md` ;
> 4. `docs/current/RELEVES-2026-11-02/PLAN-LOTS.md`, §7 et §8.
>
> Tu es l'arbitre : tu tranches toi-même tout ce qui n'est ni argent, ni sécurité, ni données personnelles, ni droit. Tu parles au directeur en français, en mots simples, la vérité d'abord. Recrée tes deux contrôles, l'horaire et le quotidien, d'après le §5 de ta passation, sur ta propre session. Le nouveau pilote est la session que le directeur te nomme.

## 12. Les deux contrôles, à recréer par le successeur sur sa propre session

**Contrôle horaire** (cron `23 * * * *`, à garder seulement tant que des agents construisent ; il coûte du plafond) :

> Contrôle horaire. Les règles sont dans `docs/current/RELEVES-2026-11-02/PLAN-LOTS.md` §7 et §8, sur main. 1. Compte les agents de construction enfants du pilote : 4 au plus. 2. git fetch ; pour chaque branche claude/* poussée depuis le dernier contrôle, cherche : fichiers hors de la zone du lot ; .github, vercel.json, pubspec.yaml ou site-public touchés par un agent ; numéro de migration absent de la table ou en double ; vague de formatage ; nouveau module vidéo (livekit hors de salle et tc_realtime) ; suppression sans le « oui » du directeur ; règle inventée présentée comme décision du directeur ; deux lots sur les mêmes fichiers ; push vers main ; lot hors de l'ordre du §7 ou hors liste. 3. Une PR ouverte non fusionnée par agent au plus. 4. Signaux d'arrêt : deux CI rouges de suite sur main ; moins de lots fusionnés que lancés sur 24 h ; code non branché ou module en double ; fusion sans capture ni verdict du robot. 5. Une question au directeur dont la réponse est écrite est un écart. 6. En cas d'écart : le pilote d'abord, avec le fait et le fichier, puis le directeur en une ou deux phrases ; sans écart, personne. 7. Arrête ce contrôle quand plus aucun agent ne construit.

**Contrôle quotidien** (cron `43 4 * * *`) :

> Contrôle quotidien du garde-cap, 15 minutes au plus, sans piloter. 1. Lis ETAT-OUVERTURE, METHODE et PLAN-LOTS §7-§8 sur main, puis les PR fusionnées depuis hier. 2. Vérifie : chaque fusion sert un parcours, branche de l'existant ou suit le §7 ; les parcours verts ont un passage Playwright daté avec captures ; ETAT-OUVERTURE est à jour ; rien n'est construit hors liste. 3. Écart : recadrage court au pilote. 4. Au directeur, trois lignes au plus : ce qui est en ligne depuis hier, ce qui n'est pas prêt, son action seulement s'il le faut. **Ne lui parle jamais des tests qu'il doit faire** (directeur, 02/11).

**Leçon de la dernière nuit, à ne pas répéter :** le garde-cap sortant a plusieurs fois écrit au directeur « deux vérifications vous reviendront » (photo posée au téléphone, écran des revenus). C'est contraire à P14 de `CONSIGNES-DIRECTEUR-EN-VIGUEUR.md`. Ce qui n'est pas prouvé se dit « non prouvé en production », sans lui assigner de test.
