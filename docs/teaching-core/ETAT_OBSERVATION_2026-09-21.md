# Observation du tuteur -- etat au 21/09/2026

Document d'etat de la branche `observation/lot-2026-09-21`. Il dit ce qui marche, ce qui attend, et
ce qui a ete mesure plutot que suppose. A lire avant de fusionner ou d'appliquer quoi que ce soit.

## La regle produit

Dictee par l'operateur le 21/09, mot pour mot :

> Le tuteur peut venir plusieurs fois selon les reglages de l'admin. Mais par defaut, il vient deux
> fois max, chaque visite 2 minutes max. Pourquoi ? Parce qu'il vient pour voir si son enfant est
> actif. Mais avec un groupe de 5 personnes il peut venir et trouver que ce n'est pas le tour de son
> enfant, donc il attend, et peut revenir apres, c'est pour augmenter les chances qu'il tombe sur le
> tour de son enfant en train de participer / lire / repondre.

L'administration peut changer ces valeurs **ou les annuler** (`SourcePolitique` : heriter de
l'Academie, personnaliser pour le groupe, desactiver).

Deux consequences que le code doit respecter, et qui ne se deduisent pas des chiffres seuls :

1. **Deux minutes PAR VISITE**, pas deux minutes partagees. D'ou un budget total de 240 s.
2. **Un ecran d'observation qui ne montre pas l'enfant ne rend pas le service.** Le parent ne vient pas
   verifier que le cours a lieu, il vient verifier que SON enfant participe.

## La regle de visibilite, tranchee par l'operateur le 21/09

Elle n'est plus une ambiguite. Mot pour mot :

> Le tuteur est visible par son enfant et l'enseignant, les autres enfants ne voient rien. Chacun voit
> son parent a lui quand il est en ligne. Sur mobile c'est un oeil plus le nombre « X tuteur en
> observation », et l'enfant voit l'oeil + mention discrete « ton tuteur observe ».

Trois destinataires, trois traitements differents :

| Qui | Ce qu'il voit |
|---|---|
| L'enseignant | Un oeil + le **compteur agrege** des tuteurs en observation |
| L'enfant observe | Un oeil + une mention discrete, sans action ni bouton |
| Les autres enfants du groupe | **Rien.** Ni dans la galerie video, ni en annonce |

C'est exactement la specification 11.3 deja citee dans `indicateur_observation.dart` (« les autres
eleves n'ont pas besoin d'etre interrompus »). Le cote client la respecte :
`capacites_observateur.dart` pose `visibleDesParticipants: false` pour le tuteur. **Le serveur, lui,
ne la fait pas appliquer** -- voir le defaut mesure ci-dessous.

## Ce qui est livre sur cette branche

| Lot | Etat |
|---|---|
| Salle video reelle sur l'ecran d'observation | Fait -- meme chemin que `salle_page.dart`, un seul `moteurSalleProvider`, jeton `guardian_observer` verifie cote client avant d'ouvrir la salle |
| Sortie de salle si la visite expire pendant la connexion | Fait -- `_sortieDemandee` + relecture de la phase au retour de `rejoindre` |
| Annonce au professeur | Fait, mais **pas encore a la forme demandee** : `IndicateurObservation` pose une ligne PAR tuteur, libellee « Tuteur de {prenomEnfant} observe ». La regle demande un oeil + le compteur agrege, et le doc du composant affirme deja que l'enseignant n'apprend jamais quel tuteur observe -- ce que ce libelle contredit |
| Reglages d'observation par l'administration | Fait -- **feuille** ouverte depuis la ligne du groupe, pas une route (la RPC ecrit par groupe) |
| Bascule du bouton « Assister » | **NON FAIT, volontairement** -- voir plus bas |
| Annonce a l'enfant | **NON FAIT** -- capacite serveur absente, pas un cablage manquant. Le composant `IndicateurObservationEnfant` existe, le libelle « Ton tuteur regarde le cours » aussi ; ce qui manque est la lecture serveur de `0040`. Le monter avant reviendrait a poser un temoin qui ne s'allume jamais |

## Les quatre migrations, aucune appliquee

A appliquer **dans cet ordre**. Chacune porte un bloc de controle de sortie en exigence positive :
elle echoue bruyamment si elle ne prend pas.

| Fichier | Ce qu'elle fait | Consequence si on ne l'applique pas |
|---|---|---|
| `0035_ressources_du_groupe_rejoue_visibilite.sql` | `ressources_du_groupe` rejoue la politique de visibilite de `library_resource` | Un eleve membre recoit les ressources `enseignant_seul` et `admin` de son groupe ; un compte suspendu passe |
| `0036_observation_defauts_academie_et_plafond_visite_groupe.sql` | Defauts 2 visites / 120 s par visite / 240 s total / version `a2` ; 5e parametre a `definir_politique_observation_groupe` ; `budget_observation` borne la duree par visite | La regle produit n'existe pas ; l'ecran de reglages admin ne peut rien enregistrer (`PGRST202` -> `capaciteAbsente`) ; personnaliser un groupe annule le plafond par visite |
| `0037_entrer_observation_rend_l_enfant_concerne.sql` | `entrer_observation` rend enfin `enfant_profile_id` | Le parent lit en permanence « votre enfant n'a pas d'image ouverte », meme si son enfant recite camera ouverte. **C'est ce qui bloque la bascule d'« Assister ».** |
| `0039_budget_observation_repond_sur_la_visite_en_cours.sql` | `budget_observation` repond sur la visite en cours ; `sortir_observation` reparee | L'observation video ne fonctionne pour personne, et aucune visite ne peut se fermer |
| `0040` -- **a ecrire** | Deux choses que la regle de visibilite exige : `guardian_observer` rejoint les roles masques dans `autoriser_jeton_video` ; une lecture d'annonce reservee a l'enfant concerne, qui ne rende QUE sa propre ligne | Les quatre autres enfants voient le tuteur dans la galerie, et l'enfant observe n'apprend jamais que son parent regarde |

`0034` et `0038` appartiennent au chantier R2, conduit par un autre agent. Ne pas y toucher.
**Elles sont deja appliquees en production, et dans l'ordre inverse de leurs numeros** : `0038`
(`20260921043316`) puis `0034` (`20260921043922`), verifie par `list_migrations` le 21/09. L'ordre en
base diverge donc de l'ordre des fichiers ; un environnement reconstruit depuis `supabase/migrations/`
les rejouera dans l'autre sens. Sans consequence tant que les deux chantiers restent independants,
mais a savoir avant de reconstruire une base.

**Plus grave, et mesure le 21/09 : leurs deux fichiers ne sont sur AUCUNE branche poussee.**
`git ls-tree -r origin/main -- supabase/migrations` ne rend ni `0034_r2_stockage.sql` ni
`0038_hook_jeton_foyer_absent.sql`. Elles tournent en production sans exister dans l'historique
partage : une base reconstruite depuis `origin/main` n'aurait ni le stockage R2, ni le correctif du
hook de jeton -- lequel avait immobilise quatre enseignants pendant neuf jours. Le travail vit dans le
worktree principal de l'agent R2. **A faire remonter a lui, pas a corriger d'ici.**

## Ce qui a ete mesure sur un Postgres reel, pas relu

Postgres 17 nu en conteneur, `supabase/tests/stub_auth.sql` plus un stub `storage`, les migrations du
worktree appliquees dans l'ordre sur base vierge, fixtures posees, **vraies RPC appelees**.

Trois defauts qui rendaient l'observation inoperante pour tout le monde, tous anterieurs a ce lot :

1. **La premiere visite se refusait son propre jeton video.** `budget_observation` comptait
   l'intervalle **deja ouvert** dans le quota, et `autoriser_jeton_video` refuse le jeton quand
   `peut_entrer` est faux -- or l'ecran ouvre l'intervalle PUIS demande le jeton. Avec le quota de 1
   en production, refus systematique, motif `quota_visites_atteint`.
   Le serveur posait la mauvaise question : « une NOUVELLE visite serait-elle acceptee ? » au lieu de
   « CETTE visite a-t-elle encore du temps ? ».
2. **`sortir_observation` etait inexecutable.** Elle ecrivait `duration_seconds`, colonne
   `GENERATED ALWAYS` depuis `0032` (erreur `428C9`), et posait `fin_de_visite = 'utilisateur'`, valeur
   absente du `check` comme de l'enum Dart `FinDeVisite`. Comme `guardian_visit_ouvert_uidx` n'admet
   qu'un intervalle ouvert par seance et par observateur, **la deuxieme visite ne pouvait pas naitre**.
3. **Un jeton de duree nulle levait une erreur brute** (`video_token_grants_duree_ok`, `23514`) au lieu
   d'un refus avec motif, quand le temps de la visite etait epuise mais le total non.
4. **Le tuteur est visible de TOUS les enfants du groupe.** Lu dans le corps de la fonction en
   production le 21/09, ligne 74 : `v_invisible := (v_role in ('masked_controller', 'admin_masked'))`.
   `guardian_observer` n'y figure pas, donc le jeton part avec `hidden = false` et LiveKit place le
   tuteur dans la galerie de chaque participant. Les quatre autres enfants le voient. C'est l'inverse
   exact de la regle de visibilite, et `capacites_observateur.dart` annonce pourtant
   `visibleDesParticipants: false` : **le client dit vrai, le serveur ne suit pas.** Correction
   minimale : ajouter `'guardian_observer'` a cette seule liste. Reste a ecrire (`0040`).

`autoriser_jeton_video` n'a PAS ete rouverte : c'est un point chaud traverse par quatre roles, et elle
consomme `budget_observation`. Rendre cette derniere juste a suffi. Les quatre autres roles ont ete
mesures inchanges (`ttl = 900`).

## Decisions qui attendent l'operateur

1. **Appliquer les quatre migrations** sur la base de production. La base est vide (0 groupe,
   0 seance, 0 visite journalisee), le rayon d'explosion est nul.
2. **Etape 8 (E2E)** : rien n'a ete lance. Attention, la production Vercel sert un bundle du **19/09
   03:56 UTC, anterieur a Teaching Core** : un essai contre `rewayah-academy.vercel.app` testerait le
   mauvais code. Un preview du commit `d5eb74c` existe deja, construit le 20/09.

## Deux defauts pre-existants signales, non corriges

- `ci.yml`, job `migrate-check` : echoue des `0030_tc_socle.sql:209`, `insert into storage.buckets`
  sans garde alors que `0004:992` en a une.
- `test/teaching_core/q/q03_quota_observation_tuteur_test.dart` encode les ANCIENS defauts d'Academie
  (1 visite / 120 s) comme etant « la specification ». Il reste vert parce qu'il lit une fixture
  locale et jamais la base.
