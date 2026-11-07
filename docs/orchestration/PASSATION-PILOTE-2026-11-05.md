# Passation du pilote, 05/11/2026

Écrite par la session pilote `session_0163Kjrv38i3CYWs5z3wtmWi`, sur ordre du directeur du 05/11
vers 20:40 UTC : « Relance le travail, il faut que ça finisse. […] je veux que tu te prépares à te
retirer, toi et l'autre pilote, parce que vous commencez à engranger beaucoup de contexte. »
Le successeur n'est lancé que sur ordre du directeur. Le garde-cap écrit de son côté
`PASSATION-GARDE-CAP-2026-11-05.md`.

**Reprise du 06/11 vers 09:45 UTC.** Le directeur a remis à zéro le contexte de la session pilote
(même identifiant) et lui a recollé cette page : elle reprend le rôle. Garde-cap successeur :
`session_0163KjrwyawmrhemnpDkEL4X`. Lancement du 06/11 à 09:57 (`PLAN-LOTS` §7, rang 22 l) :
trois sessions neuves, voir le §1.

**État du 06/11 à 13:10 UTC (pilote).**
- **En production :** train 254 (ENTREE-ORDRE), run 591, `version.json` = 591. Deux mises en production le 06/11 (248, 254) : plus aucune avant minuit UTC.
- **Migrations installées en production :** CAHIER-C1 `20261110100000`, md5(prosrc) des 4 fonctions identique au fichier.
- **Validés par le garde-cap, train du 07/11** (rappel `trig_01Eou3fN7zjgcFn3vTnMD3Au` à 00:10 UTC) : `claude/cahier-c1` et `claude/accueil-horaire` (5db849a4).
- **CANDIDATS-FLUX, PR A :** `claude/candidats-flux` (98084a0a), conforme sous deux corrections : `libelles_sources` de `dansReferentiel`, et un UPDATE `recrutement` non essentielle dans `20261110300000`. Sa migration s'installe après le push corrigé, puis le train. La PR B (CAND-04) part après la fusion de A, sur `claude/candidats-flux-cand04`.
- **Double vérification :** le directeur est enrôlé. En production, un facteur TOTP est vérifié le 05/11 à 21:17 UTC. Le §4.7 est périmé : la PR 210 est reprise par un agent neuf, `session_0163KjryVXXeQwUUERVxubme`.
- **Liste du directeur, ajout :** retirer `lib/features/parcours_offres` de `.claude/hooks/zones_apres.sh` et mettre à jour le rappel de `demarrage.sh`. La levée a été décidée le 17/10 (`PASSATION-2026-10-17.md`, l. 15), mais ce script n'a jamais été changé. Geste sur `.claude/hooks`, donc ordre du directeur.

## 0. Ce qui est faux, bloqué ou non prouvé, d'abord

- **Défaut en production depuis FUSEAUX : `monHorlogeProvider` appelle `mon_horloge` en boucle.**
  Le flux d'authentification rejoue « signedIn » à chaque abonné. Mesure d'I1 à 390 : 5 578 appels
  en une vingtaine de secondes sur main, 1 avec le correctif (97332736, `compteAChange`). C'est la
  cause probable des photos absentes et de l'envoi en échec à 390. Le correctif part avec le train
  photos, en priorité le 06/11. La preuve « rouge sur main, vert avec ce seul correctif » est
  demandée à I1 par le garde-cap.

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

Au 06/11, 10:05 UTC :

| Rôle | Session | Lot |
| :--- | :--- | :--- |
| Garde-cap (successeur) | `session_0163KjrwyawmrhemnpDkEL4X` | contrôle toutes les 3 h (`trig_01KBfRAkutLKaDFdpYYfTPcn`), quotidien 04:43 |
| Agent | `session_0163KjrxiFV4Ln6SnmoNoXFD` | ENTREE-ORDRE (`claude/entree-ordre`), puis ACCUEIL-HORAIRE (`claude/accueil-horaire`) |
| Agent | `session_0163Kjrxcd9ihnVWoszfWzSt` | CAHIER-C1 (`claude/cahier-c1`), migrations 20261110100000 à 20261110199999 |
| Agent | `session_0163KjrvEw7XeBUYofyTFjoV` | CANDIDATS-FLUX (`claude/candidats-flux`), migrations 20261110300000 à 20261110399999 ; routeur et inscription seulement après la fusion d'ENTREE-ORDRE |

Archivées : N1, Fin de séance, C1 (leur travail est dans `main`, train 248). I1 : archivée après
l'écriture de l'état de la 210 (§4, point 7). ETUDE-CAHIER (`session_0163KjrwMz3ndownaQNWTJkS`,
lancée par l'ancien garde-cap, PR 243 fusionnée) : archivage refusé au pilote par le contrôle
des permissions, laissée à l'arrêt. REVENUS-VERITE points 2 à 6 : au premier agent libéré, plage
20261110200000 à 20261110299999.

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

- `main` = a4934c7f (train du 06/11, PR 248, fusionné le 06/11 à 02:10 UTC). Run 582 vert, étape
  SERVI comprise, `version.json` = 582 (vérifié à 02:22). Contenu : photos partout (PHOTOS-A et B,
  `claude/photos-a` ab7c3a4a), Comptes au téléphone avec un portrait, correctif de la boucle
  `mon_horloge`, revenus de l'enseignant point 1 (`claude/revenus-verite` 9e9e9e27). CI de la PR
  entièrement verte, 6 lots de tests compris. Seule mise en production du 06/11 à cette heure.
  **Non prouvé par le directeur** : la photo dans Comptes au téléphone, l'envoi de la photo d'un
  enfant au téléphone, la photo vue par l'enseignant, et l'écran des revenus d'un enseignant.
- Avant : `main` = 7ee028f7 (train c, PR 241, fusionné le 05/11 à 20:58 UTC) : FOYER-ÉLÈVE. Run 574 vert,
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
   - Rendu le 05/11 à 23:41 : `claude/photos-a` 17cabc8d (base 1eee5c3b, sans conflit avec main
     5cbe8bec). 18 324 tests verts, analyze propre, jetons et branchement corrects, revue à 1058
     (comme main). Robots `photos_a` (390/1440, FR/AR, salle dans les deux sens) et
     `photos_comptes` (session ouverte à 390, sans redimensionner) verts.
   - Restent en initiales, faute d'id renvoyé par le serveur : `catalogue_classes` (démonstration)
     et `controle_page`. La salle n'est prouvée qu'en français.
3. **PHOTOS-B (Fin de séance).**
   - Écrans : accueil de la famille, `carte_classe_seance`, finances, recharge, comptable,
     Communauté, Mon espace guidé, Comptes de la direction au téléphone, le Foyer et
     `compte_page.dart` (libérés le 05/11 à 20:58, après la fusion de FOYER-ÉLÈVE).
   - Ne touche ni `avatar_nom.dart` ni `lib/core/photos/`.
   - Partie hors Foyer rendue le 05/11 à 22:08 : `claude/photos-b` f290540b (sur main 1eee5c3b). 8
     passages du robot verts, 828 + 778 tests verts. Le Foyer et `compte_page.dart` restent à faire
     (signal donné à 22:10).
   - Complet, Foyer compris, le 05/11 à 23:00 : `claude/photos-b` 94102524 (contient main
     5cbe8bec). 721 tests verts. Robot rouge à 390 sur Comptes seul. À comparer par le garde-cap.
   - Constats transmis à I1, précisés à 23:00 (le relevé de 21:50 était en partie faux, l'écoute
     réseau manquait des requêtes) :
     - une session **ouverte** à 390 n'appelle jamais `photos_personnes`, même élargie ensuite ;
       ouverte à 1440, la photo s'affiche. La cause tient à la largeur au démarrage ;
     - l'envoi de la photo au téléphone échoue dans `ServiceAvatarSupabase.televerser`
       (`uploadBinary`, `lib/core/appairage/service_avatar.dart:158`), même motif probable.
   - Non couverts par le robot : « Vous » (Communauté) et le profil de paiement.
   - Conforme selon le garde-cap (05/11, 23:01).
4. **DEMO-SUPPR D2 (C1)** : fusionné hors train le 05/11 (PR 242, 5cbe8bec, `test/` seul, pas de
   mise en production).
   - Ce n'est pas un harnais réécrit : les 24 fichiers de démo restants sont copiés tels quels dans
     `test/support/demo` (59 copies avec D1).
   - 5 tests lisent encore `lib/` jusqu'à R : flash_changement_ecran, entree_demonstration,
     remise_a_zero, demo_tuteur_cartes, racine_reelle.
   - Suite : 18 315 réussis, 7 140 sautés, 0 échec, avant comme après. R n'est pas lancé sans ordre.
5. **Envoi de la photo au téléphone et Comptes sans photo (I1, après PHOTOS-A).** Arbitré le 05/11 :
   c'est la demande du directeur du 04/11, pas un lot nouveau. Preuve du robot exigée à 390, dans
   le même document : écran du tuteur ouvert, envoi réussi, photo visible dans Comptes.
   - Bilan d'I1 (05/11, 23:41) :
     - Comptes au téléphone : les cartes n'avaient aucune place pour une photo, d'où zéro appel
       `photos_personnes` à 390. Corrigé, robot vert ;
     - envoi de la photo d'un enfant : échec **non reproduit**, ni sur main construit en local, ni
       sur la branche. Cause probable, la boucle `mon_horloge` (§0). Non prouvé : à vérifier par
       le directeur en production.
   - Conflit A + B sur `comptes_page.dart` : les deux lots ont fait la photo de Comptes au
     téléphone de deux façons. Le garde-cap a tranché pour la version de Fin de séance (`rendu` au
     téléphone), sans `ColonneDonnees.portrait` dans le composant partagé `DataCollection`. I1
     fusionne B dans A, relance ses robots à 390 et pousse un seul SHA sur `claude/photos-a`.
     Risque noté : I1 avait vu un « nom dans AvatarNom » au téléphone casser 8 gardes ; s'il se
     reproduit, le garde-cap tranche. Le train de 23:42 (PR 244, version d'I1) a été fermé sans
     fusion.
6. **Fait le 06/11 : train PR 248 en production (build 582), voir §3.** Pour mémoire, **un seul train photos** : PHOTOS-A, PHOTOS-B complet (Foyer compris) et le point 5, tous prouvés.
   Pas de train pour un lot partiel (garde-cap, 05/11).
   - Preuve ajoutée par le directeur (06/11) : un enfant avec photo est vu avec sa photo par
     l'enseignant, la direction et son foyer, au robot à 390 et 1440.
   - Le SHA unique d'I1, une fois jugé conforme par le garde-cap, fait le train : PR de
     `claude/photos-a` vers `main`, fusion après minuit UTC (06/11) sur CI verte, une seule mise en
     production. Puis vérifier `version.json` et dire au directeur ce qu'il doit essayer au
     téléphone : la photo dans Comptes, et l'envoi de la photo d'un enfant.
7. **PR 210 (SUPPRIMER, I1)** : en attente de l'enrôlement du téléphone par le directeur.
   - Au 05/11, 23:41 : brouillon, tête 6d89dda7, 163 commits de retard. En conflit avec main sur
     les fichiers slang générés et `comptes_page.dart`. I1 la remettra à jour par un merge, après
     le train photos, pour ne résoudre `comptes_page` qu'une fois. Fichiers générés : `dart run
     slang`, pas à la main (§0).
   - **État au 06/11, 10:05 UTC (I1 archivée, la 210 n'a plus d'agent)** : brouillon, tête
     `6db86b89f096d5404d538259071814a98a2ed98c`, 24 commits de retard sur `main` 8a5a5a08. Restent :
     (1) la mettre à jour avec `main` par un merge (jamais de rebase), puis `dart run slang` et
     `build_runner` en un commit pour les fichiers générés ; (2) relancer le robot
     `supprimer_ecrans.mjs` ; (3) obtenir une suite complète propre. Le jour où le directeur aura
     enrôlé son téléphone, un agent **neuf** la reprend sur cette base.
8. **Nouveaux lots, après le train photos**, écrits dans `PLAN-LOTS` §7 (PR 239 du garde-cap, fusionnée le 05/11 à 23:41, a9b8e43a), dans
   cet ordre :
   - 22 0, ENTREE-ORDRE : pour un nouveau profil, le questionnaire passe avant l'e-mail. Régression
     de la refonte de l'entrée du 04/11. Plusieurs enfants pendant le questionnaire : on garde
     « Ajouter un autre profil élève » au récapitulatif (6 élèves au plus), avec preuve exigée dans
     ce lot ;
   - 22 a, PREFERENCES-WEB : thème mémorisé sur le web (`preferences_locales.dart:267-272`), choix
     de la langue FR / AR mémorisé ;
   - 22 b, FINITION (§7 ci-dessous), plus le compteur « 1 sur 6 / 2 sur 10 » du questionnaire ;
   - 22 c, site public en arabe : noté, sans travail tant que le directeur ne le demande pas ;
   - 22 d, ETUDE-CAHIER : **rendue le 05/11 à 23:27**, PR 243 fusionnée à 23:55, d1f68a47 (`docs/current/ETUDE-CAHIER-2026-11.md`,
     docs seules) ; synthèse pour le directeur : https://claude.ai/artifact/8MUULsR4g7qrjsJ9KottWK.
     Constats : le cahier n'est relu par personne (`preparation_seance.dart:71` rend null) ; en
     production, 95 séances, 6 cahiers, aucun avec un jugement ou un devoir ; programme non publié ;
     préremplissage cassé (clés absentes de `brouillon_cahier`). Le rang 9 (CAHIER-UX) est remplacé ;
   - 22 e, CAHIER-C1 : la salle enregistre au serveur la dernière page présentée, la préparation
     la lit, le remplaçant voit « On reprend page X ». Le gel K-45 est levé pour la refonte
     (décision du directeur, registre 08) ;
   - 22 f, CAHIER-C2 à C8 : conditions remplies (réponses du directeur au registre 08, PR 245 du
     garde-cap, fusionnée le 06/11 à 00:22, d2420d93) : la paie est libérée par la confirmation de position ; un agent rédige les
     objectifs, le directeur les valide ; le livre de lecture n'est pas encore numéroté ; la
     confirmation se fait après chaque séance et remplace l'hebdomadaire ;
   - 22 g, ACCUEIL-HORAIRE : une seule carte « Horaire à choisir », qui passe à « Demande
     enregistrée » une fois la demande faite (aujourd'hui elle ne disparaît jamais et double une
     autre carte) ;
   - 22 h, FINANCE-ENSEIGNANT : les coordonnées de versement de l'enseignant ne sont pas branchées
     (`portMesMoyensPaiementProvider` n'a que `MesMoyensPaiementIndisponibles` en production).
     Inventaire, puis prestataire de versement tout prêt (une seule question au directeur, avec la
     recommandation chiffrée), puis branchement de bout en bout ;
   - 22 i, COULEUR-PROFIL : l'écran existe, sans source serveur (`portAccentsProfilsProvider`
     « Indisponible » en production, colonne jamais créée). Petite migration (une clé d'accent par
     profil, jamais une couleur libre, K-62), puis l'adaptateur ;
   - 22 j, REVENUS-VERITE, **prioritaire** : le Profil enseignant, « Revenus estimés », promet en
     production une « base garantie 4,71 $ par heure » et dit qu'un absent compte (textes
     `revenus.*` du modèle du 17/10, abandonné). Règle en vigueur, redite par le directeur le
     06/11 : par séance, par élève présent et par heure, l'absent n'est jamais payé, aucun minimum.
     Le serveur calcule juste (`pai_due_seance`). Point 1 (textes faux) fait par C1
     (`claude/revenus-verite` 9e9e9e27, conforme) et **en production le 06/11 (build 582)**.
     Restes notés par le garde-cap : retirer `base`, `plafond` et `siegesEligibles` du serveur
     (`mes_revenus_enseignant`) et du modèle Flutter ; traduire en arabe les 39 clés encore en
     français de l'écran des revenus. Points 2 à 5
     (heures assurées, détail par élève, jour de paie `paie.fenetre_versement` du 1er au 10,
     autres revenus) après le train ;
   - 23, harmonisation de l'interface, en dernier.

   Ordre arrêté par le garde-cap (05/11, 23:47) : CAHIER-C1 et ENTREE-ORDRE d'abord, en
   parallèle ; puis ACCUEIL-HORAIRE, PREFERENCES-WEB et FINANCE-ENSEIGNANT ; puis CAHIER-C2 et la
   suite. Au plus 4 agents, 2 si le plafond hebdomadaire approche.

   La vision du directeur (une école dans une application, le suivi pédagogique d'abord, aucune
   corvée pour l'enseignant) est dans `docs/current/VISION-ECOLE-2026-11-05.md`.

**Retrait.** Le pilote et le garde-cap se retirent quand les quatre conditions du §10 de la
passation du garde-cap sont vraies :
- le train photos est en production, ou bloqué avec sa cause écrite ;
- la 210 et D2 sont fusionnées, ou arrêtées avec leur état ;
- les bilans des agents sont ici ;
- les deux passations sont sur `main`.

Les nouveaux pilotes partent avec les nouveaux lots.

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
- **Site public (PR 187), constat du garde-cap du 05/11 à 21:15 :** `/en/`, `/ar/`, `/es/` et `/pt/`
  renvoient vers `app.rewayahacademy.com/<langue>/`, puis vers « Se connecter » en français. Voulu
  (site en français seul) ou oubli : question posée au directeur, zone `site-public/` et `vercel.json`.
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

## 8. Message de lancement du nouveau pilote (à coller tel quel par le directeur)

> Tu es le pilote de Rewayah Academy. Lis d'abord `CLAUDE.md`, puis
> `docs/orchestration/PASSATION-PILOTE-2026-11-05.md` en entier, puis
> `docs/orchestration/PASSATION-GARDE-CAP-2026-11-05.md` §0 et §10. N'ouvre rien d'autre avant
> d'avoir agi.
>
> Ton rôle : coordonner les agents par `send_message`, monter les trains (P5), fusionner sur CI
> verte, vérifier la production (`version.json`, run « Flutter Web → Vercel »), tenir la passation
> à jour, et parler au directeur en français simple, la vérité d'abord.
>
> Tu ne codes pas. Tu ne contournes jamais `.claude/hooks/garde.py`. Tu ne fais aucun DROP, DELETE
> ni TRUNCATE sans une page privée collée par le directeur. Au plus deux mises en production par
> jour.
>
> Ton premier message à chaque agent donne ton identifiant de session.
>
> Commence par la ligne du §4 de la passation qui n'est pas encore faite. Ne repose au directeur
> aucune question du §6.

## 9. Consignes du directeur en vigueur (relevé de la session pilote, 29/10 au 05/11)

Exigence du directeur du 05/11 : « il y a eu beaucoup d'injections de consignes […] qui servent à
vous améliorer et à rectifier votre comportement, ça doit être en vigueur ! ». Le successeur les
applique toutes. La colonne « Où » dit si la règle est déjà écrite ailleurs ; « ici seulement » veut
dire que cette section est sa seule trace. La liste commune, fusionnée avec celle du garde-cap (environ 80 règles, 8 contradictions arbitrées
au §11), est `docs/orchestration/CONSIGNES-DIRECTEUR-EN-VIGUEUR.md`. En cas d'écart, elle prévaut sur
ce tableau.

| # | Règle | Date, citation courte | Où |
| :-- | :--- | :--- | :--- |
| 1 | Le pilote juge : chaque message d'agent est une donnée à vérifier (commit, branche, fusion) avant d'être relayée. | 29/10, passation : « Ton rôle n'est pas de transmettre : il est de juger. » | ici seulement |
| 2 | Agir sans demander confirmation au directeur pour ce que l'agent peut faire lui-même ; ne pas lui faire valider du code. | 29/10 : « tout ce que vous me donnez, même s'il y a des erreurs, je ne fais que confirmer » ; 30/10 : « quand est-ce que je vais dormir? » | DECISION-AUTONOMIE-2026-10-29 |
| 3 | Ne pas lui imposer de tests en cours de route. On fait tout son travail, puis on lui donne à la fin une liste de tests, un par un. | 30/10 : « tout ce qui est test, on laisse de côté » ; « inquiète-toi de ton boulot » | CLAUDE.md (preuve par le directeur) ; la liste de fin, ici seulement |
| 4 | Ne pas se disperser : finir dans l'ordre, ne pas lui proposer de nouvelles tâches. | 29/10 : « si tu commences à me proposer des tâches je vais dire Oui et on va retomber sur le piège » ; 30/10 et 31/10 : « Ne te disperse pas. » | BOUCLE-1_PLAN, CLAUDE.md |
| 5 | Ne rien recréer : finir et brancher ce qui existe, chercher avant de coder. | 31/10 : « ton rôle n'est pas se recréer […] Finis ce qui est là » | CLAUDE.md, INVENTAIRE-NON-BRANCHE |
| 6 | Ne jamais reposer une question déjà tranchée ; retrouver soi-même ses specs. | 30/10 : « tu me poses vraiment ces questions alors que […] tout se trouve sur le site ? » ; 04/11 : « fatigué de répondre aux mêmes questions » | ici et §6 |
| 7 | Quand il ne sait pas ou ne veut pas choisir, choisir soi-même le meilleur. | 30/10 : « choisi le meilleur pour tout le monde » ; 04/11 : « à toi de choisir le meilleur » | ici seulement |
| 8 | Priorité : l'interaction enseignant, élève (tout type), tuteur, administration. | 29/10 22:44 | BOUCLE-1_PLAN |
| 9 | Économiser : pas d'allers-retours inutiles, petits modèles pour les petites tâches. | 29/10 : « Essaye d'être économe » | CLAUDE.md (petits modèles) |
| 10 | Chaque nouveau lot part chez un agent au contexte neuf. | 30/10 : « donner les nouveaux lots à des agents avec un nouveau contexte » | ici seulement |
| 11 | Aucune donnée vivante codée en dur (nombres de candidats, d'élèves). | 30/10 : « j'espère que tu n'as pas codé cela en dur » | ici seulement |
| 12 | Penser d'abord aux utilisateurs, comme Google Meet : ne pas enfermer l'enseignant dans la salle. | 31/10 : « Il faut toujours penser aux USERS » | ici seulement |
| 13 | « Cours en cours » est interdit partout, et tout le monde doit le savoir. | 31/10 | mots-rewayah |
| 14 | Le pilote est aussi comptable et juriste tant que l'académie n'en paie pas. | 30/10 : « tu es le comptable et l'avocat » | ici seulement |
| 15 | Continuer les implémentations coûte que coûte, puis déployer dans l'ordre pour ne rien casser. | 03/11 : « continuer les Implémentations coûte que coûte » | ici, §2 |
| 16 | Ce qu'il colle : dire exactement où ; il est souvent sur téléphone, loin de son ordinateur, sans recherche dans la page, donc donner le fichier entier à remplacer. | 31/10 : « Je la colle où » ; 03/11 : « y'a pas la fonction recherche » | CLAUDE.md (page Artifact) ; le téléphone, ici seulement |
| 17 | N'afficher en permanence que l'essentiel : pas de filtres ni de titres qui mangent la page, détails au clic. | 30/10 20:00 ; 02/11 (notifications) | DECISION-LISTES, DECISION-DEFILEMENT |
| 18 | Le pilote est surveillé ; il ne réannonce pas ce qu'il a déjà annoncé sans l'avoir fait. | 30/10 : « tu es le chef mais tu es surveillé » ; 31/10 : « tu l'avais annoncé il y a 3h » | ici seulement |

Règles de produit qu'il a dû redire, parce qu'elles avaient été perdues (31/10). Le garde-cap a
vérifié le 05/11 qu'elles sont toutes écrites (08 §5 bis, DECISION-CLASSES-SIMULTANEES,
DECISION-TARIFS, REGISTRE) :
- remplacement de l'enseignant : alerte à 3 minutes, dernier délai à 8, remplaçant à la 11e minute.
  Pas d'annulation à 10 minutes : on prévient les familles et on cherche. La paie va au remplaçant
  (astreinte) ;
- cahier de séance hebdomadaire, pas quotidien ;
- le tuteur observe deux fois, deux minutes au plus chaque fois : règle fixe, ne plus la poser.
