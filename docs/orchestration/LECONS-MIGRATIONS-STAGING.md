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
