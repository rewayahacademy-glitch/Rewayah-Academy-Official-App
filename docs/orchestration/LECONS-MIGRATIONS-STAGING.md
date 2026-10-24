# Leçons : installer une migration sur staging (19/10/2026)

## Le symptôme

`apply_migration` (outil Supabase) renvoie `{"status":"cancelled"}` ou
« timed out after 60s », alors que le directeur a bien accepté la demande.
Rien n'est écrit sur la base.

## La cause

Le serveur Supabase demande sa propre confirmation dès qu'une migration contient
une instruction d'effacement (`DELETE`, `DROP`, `TRUNCATE`), même dans le corps
d'une fonction. Cette deuxième confirmation n'apparaît pas dans l'app Claude :
elle expire, puis l'appel est annulé.

Preuve du 19/10 : `fac_e_01` (60 Ko, sans effacement), `ses_cloture_auto` et
`imm_import_ecran` passent du premier coup. `cpt_suppression_export` (5 `DELETE`)
échoue à chaque essai.

## Ce qu'il faut faire

1. Avant d'installer, compter les effacements :
   `grep -ciE '\b(delete from|drop |truncate)\b' fichier.sql`.
2. À 0 : `apply_migration` marche (retirer `BEGIN;` et `COMMIT;`).
3. Au-dessus de 0 : ne pas relancer en boucle, et ne pas réécrire le SQL pour
   tromper la détection. Le directeur colle le fichier dans l'éditeur SQL de
   Supabase, projet staging `xldmmlrnxyabdtvxqbyy` uniquement. Claude vérifie
   ensuite les objets créés.

## Deuxième leçon : les fins de ligne de Windows (23/10/2026)

### Le symptôme

Le directeur colle depuis Windows. Le fichier 4 de la liste du 23/10 s'arrête à
son contrôle préalable : `fragment 1 de regroupements_c11bis_admin trouve 0 fois,
1 attendu`. Les fichiers 1 à 3 étaient passés.

### La cause

Le copier-coller depuis Windows ajoute un retour chariot (`\r`) à chaque fin de
ligne, et l'éditeur SQL l'envoie tel quel. Les corps de fonctions créés par
collage gardent ces caractères : 34 fonctions sur staging en avaient, dont celles
des collages du 18/10. Une migration qui cherche un passage de plusieurs lignes
dans une fonction existante (`pg_get_functiondef` puis `replace`) échoue donc
dans les deux sens : un passage collé (avec `\r`) contre une fonction posée par
`apply_migration` (sans), ou l'inverse. Reproduit à l'identique sur une base
locale.

### Ce qu'il faut faire

1. Avant un collage, vérifier qu'aucune fonction ne garde de retour chariot :
   `select count(*) from pg_proc where strpos(prosrc, chr(13)) > 0` doit valoir 0.
   Sinon, Claude applique `docs/orchestration/staging/normalisation_fins_de_ligne_editeur_sql.sql`
   (sans effacement, `apply_migration` passe) : chaque fonction est recréée à
   l'identique sans ces caractères, et son empreinte F86 est reportée.
2. Ne jamais faire coller un fichier brut. Le donner enveloppé :
   `python3 tool/envelopper_pour_editeur_sql.py <fichier.sql> <n> <total>`.
   L'enveloppe retire `BEGIN;`/`COMMIT;`, puis exécute le texte après avoir retiré
   les `\r`, en une seule transaction. Les mots d'effacement restent visibles :
   l'éditeur demande toujours sa confirmation, rien n'est caché.
3. Après le collage, comparer les empreintes des fonctions touchées avec une base
   locale construite depuis le dépôt (md5 de `pg_get_functiondef`, du commentaire
   et des droits), puis inscrire les versions à l'historique comme
   `historique_15_migrations_editeur_sql`.

Preuve du 23/10 : normalisation, puis fichiers 4 à 15 enveloppés ; 143 fonctions
identiques au dépôt, 25 tables nouvelles avec RLS, plus aucun `\r`.

## La page de collage : règle du directeur (23/10/2026)

> « J'aime bien la façon dont tu as préparé les migrations à coller sur l'artefact, il faut
> rendre cela une règle pour les prochaines fois. » (directeur, 23/10/2026)
>
> Et avant : « tu me les donnes ici par ordre avec les instructions (je ne suis pas une IA,
> ni dev). »

Chaque fois que le directeur doit coller des migrations dans l'éditeur SQL de la base de test :

1. **Une page, pas des fichiers ni du SQL dans la conversation.** Claude la fabrique avec
   `python3 -I tool/page_migrations/generer.py --sortie <page.html> <fichier.sql>::"<ce que fait
   le fichier, en mots de tous les jours>" …` (dans l'ordre d'application), puis la publie avec
   l'outil Artifact (page privée) et donne le lien. Chaque fichier y est déjà enveloppé contre les
   fins de ligne de Windows ; la page dit le nom du projet à vérifier (« Rewayah STAGING (test) »,
   jamais « Rewayah PROD (Real Users) »), la sauvegarde à regarder, les gestes un par un (Copier,
   Ctrl+A puis Ctrl+V, Run, « Run this query » si l'avertissement apparaît, attendre « Success »,
   cocher « Fait »), quoi faire sur un message rouge (s'arrêter, capture d'écran), et la phrase à
   écrire à la fin (« migrations faites »).
2. **Dans la conversation**, en plus du lien : l'ordre des fichiers avec une phrase simple chacun,
   et les mêmes consignes en cinq lignes. Aucun jargon (pas de « transaction », « RLS », « RPC »)
   sans l'expliquer.
3. **Avant de donner la page** : Claude vérifie, en lecture, qu'aucune fonction de la base de test ne
   garde de retour chariot (sinon normalisation, section précédente) et rejoue localement la même
   suite de fichiers enveloppés.
4. **Pendant** : si une étape échoue, Claude reproduit l'erreur en local avant de proposer une
   correction, republie la page au même lien avec ce qui reste à faire, et dit clairement où on en
   est (« Où on en est » : fait, à faire par Claude, à faire par le directeur).
5. **Après** « migrations faites » : vérification des empreintes contre une base locale du dépôt,
   inscription à l'historique, mise à jour de la liste et du journal `08`.

Les fichiers sans mot d'effacement peuvent toujours être appliqués par Claude avec
`apply_migration` quand le texte exact peut lui être transmis sans recopie à la main ; sinon, ils
vont sur la page avec les autres (une recopie de 100 Ko par Claude est un risque d'erreur).

## Troisième leçon : tout va en production, et jamais un fichier brut (24/10/2026)

> « je t'ai dit pas de base test, tout doit aller sur prod » (directeur, 24/10/2026)

- **Décision du directeur** : plus de passage par la base de test. Une migration prouvée en local
  (base neuve montée avec les migrations de `main`, rejeu complet des scénarios) va directement en
  production. La base de test n'est plus mise à niveau.
- **Qui colle** : le garde-fou du projet et les permissions de la session refusent à Claude toute
  écriture en production et toute page qui la vise. Le directeur colle donc lui-même, dans le SQL
  Editor du projet « Rewayah PROD (Real Users) ». Claude vérifie ensuite en lecture.
- **Ce qui s'est passé le 24/10** : le fichier 18 a été donné brut. Ses cinq fonctions ont gardé les
  retours chariot de Windows, et sa version manquait à l'historique. Il a fallu un second collage :
  la normalisation de `docs/orchestration/staging/normalisation_fins_de_ligne_editeur_sql.sql`
  (16 fonctions de la production corrigées) suivie de l'inscription à l'historique, le tout enveloppé.
- **Donc** : ce que le directeur colle en production est toujours enveloppé
  (`tool/envelopper_pour_editeur_sql.py`) et finit par l'inscription de la version dans
  `supabase_migrations.schema_migrations`. Avant : vérifier en lecture
  `select count(*) from pg_proc where strpos(prosrc, chr(13)) > 0` (0 attendu). Après : comparer les
  empreintes à la base locale et vérifier la version dans `list_migrations`.
