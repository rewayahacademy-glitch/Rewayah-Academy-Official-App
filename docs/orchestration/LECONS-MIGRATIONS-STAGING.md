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
