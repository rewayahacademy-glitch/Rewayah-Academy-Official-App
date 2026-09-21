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

## Ce qui est livre sur cette branche

| Lot | Etat |
|---|---|
| Salle video reelle sur l'ecran d'observation | Fait -- meme chemin que `salle_page.dart`, un seul `moteurSalleProvider`, jeton `guardian_observer` verifie cote client avant d'ouvrir la salle |
| Sortie de salle si la visite expire pendant la connexion | Fait -- `_sortieDemandee` + relecture de la phase au retour de `rejoindre` |
| Annonce au professeur | Fait |
| Reglages d'observation par l'administration | Fait -- **feuille** ouverte depuis la ligne du groupe, pas une route (la RPC ecrit par groupe) |
| Bascule du bouton « Assister » | **NON FAIT, volontairement** -- voir plus bas |
| Annonce a l'enfant | **NON FAIT** -- capacite serveur absente, pas un cablage manquant |

## Les quatre migrations, aucune appliquee

A appliquer **dans cet ordre**. Chacune porte un bloc de controle de sortie en exigence positive :
elle echoue bruyamment si elle ne prend pas.

| Fichier | Ce qu'elle fait | Consequence si on ne l'applique pas |
|---|---|---|
| `0035_ressources_du_groupe_rejoue_visibilite.sql` | `ressources_du_groupe` rejoue la politique de visibilite de `library_resource` | Un eleve membre recoit les ressources `enseignant_seul` et `admin` de son groupe ; un compte suspendu passe |
| `0036_observation_defauts_academie_et_plafond_visite_groupe.sql` | Defauts 2 visites / 120 s par visite / 240 s total / version `a2` ; 5e parametre a `definir_politique_observation_groupe` ; `budget_observation` borne la duree par visite | La regle produit n'existe pas ; l'ecran de reglages admin ne peut rien enregistrer (`PGRST202` -> `capaciteAbsente`) ; personnaliser un groupe annule le plafond par visite |
| `0037_entrer_observation_rend_l_enfant_concerne.sql` | `entrer_observation` rend enfin `enfant_profile_id` | Le parent lit en permanence « votre enfant n'a pas d'image ouverte », meme si son enfant recite camera ouverte. **C'est ce qui bloque la bascule d'« Assister ».** |
| `0039_budget_observation_repond_sur_la_visite_en_cours.sql` | `budget_observation` repond sur la visite en cours ; `sortir_observation` reparee | L'observation video ne fonctionne pour personne, et aucune visite ne peut se fermer |

`0034` et `0038` appartiennent au chantier R2, conduit par un autre agent. Ne pas y toucher.
**Elles sont deja appliquees en production, et dans l'ordre inverse de leurs numeros** : `0038`
(`20260921043316`) puis `0034` (`20260921043922`), verifie par `list_migrations` le 21/09. L'ordre en
base diverge donc de l'ordre des fichiers ; un environnement reconstruit depuis `supabase/migrations/`
les rejouera dans l'autre sens. Sans consequence tant que les deux chantiers restent independants,
mais a savoir avant de reconstruire une base.

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

`autoriser_jeton_video` n'a PAS ete rouverte : c'est un point chaud traverse par quatre roles, et elle
consomme `budget_observation`. Rendre cette derniere juste a suffi. Les quatre autres roles ont ete
mesures inchanges (`ttl = 900`).

## Decisions qui attendent l'operateur

1. **Appliquer les quatre migrations** sur la base de production. La base est vide (0 groupe,
   0 seance, 0 visite journalisee), le rayon d'explosion est nul.
2. **Le parent est-il visible des enfants ?** Le depot se contredit : le serveur emet `hidden = false`
   (visible), la salle et un test existant disent visible (« l'enseignant doit savoir qu'un parent
   regarde »), mais `capacites_observateur.dart` affirme `visibleDesParticipants: false`, compense par
   une annonce livree seulement cote enseignant. Rien n'a ete tranche ; aucun ecran ne promet
   l'invisibilite au parent.
3. **Etape 8 (E2E)** : rien n'a ete lance. Attention, la production Vercel sert un bundle du **19/09
   03:56 UTC, anterieur a Teaching Core** : un essai contre `rewayah-academy.vercel.app` testerait le
   mauvais code. Un preview du commit `d5eb74c` existe deja, construit le 20/09.

## Deux defauts pre-existants signales, non corriges

- `ci.yml`, job `migrate-check` : echoue des `0030_tc_socle.sql:209`, `insert into storage.buckets`
  sans garde alors que `0004:992` en a une.
- `test/teaching_core/q/q03_quota_observation_tuteur_test.dart` encode les ANCIENS defauts d'Academie
  (1 visite / 120 s) comme etant « la specification ». Il reste vert parce qu'il lit une fixture
  locale et jamais la base.
