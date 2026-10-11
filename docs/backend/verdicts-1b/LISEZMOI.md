# Preuves des verdicts 1b

Rejouables sans écrire dans une zone interdite : aucun fichier de ce dossier n'est compilé ni exécuté par la CI.

- `sql/replay.sh <ref git> <nom>` : Postgres 16 en loopback (PGPORT 5544), `stub_auth` sans création de rôles, publication `supabase_realtime` créée, toutes les migrations dans l'ordre, puis `sql/run_all.sh` joue chaque scénario sur une base clonée. Sortie : `/tmp/scn/<nom>_results.txt`.
- `sql/ma_capacite_eleve.sql`, `sql/suivi_sortie.sql`, `sql/b08_sortie_reelle.sql` : captures des sorties réelles des RPC sur canon-fixes ea1a0da9. `sql/c21_fixed.sql` : scénario C-21 avec des enseignants `provisional_active`.
- `dart/*.dart` : tests de contrat (serveur HTTP local) à copier sous `test/` dans le worktree d'une branche d'adaptateur pour les lancer (`flutter test --no-pub`).
