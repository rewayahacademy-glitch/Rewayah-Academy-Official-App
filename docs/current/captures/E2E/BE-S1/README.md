# BE-S1 (16/11/2026)

**Aucun changement visuel.** Le lot ajoute des lectures du serveur (détails de l'historique, nom du
responsable, filtres sur les réponses et la file, voisins d'un dossier) et leurs ports, modèles et
adaptateur Dart (`lib/core/candidature/`). Aucun écran ne les affiche encore.

**La vraie preuve de ce lot est `journal.txt`** : la sortie texte de
`supabase/tests/scenarios_be_s1.sql` (70 contrôles), jouée sur un Postgres 16 local jetable (stub
`stub_auth.sql`, les 501 migrations, puis la migration `20261128100000_be_s1_lectures.sql`).

Captures : `dossier_historique_390x844.png` et `dossier_historique_1440x900.png`. Elles montrent que
le dossier d'une candidature côté direction, avec son bloc Historique, s'affiche toujours après le
changement de modèle (événements, responsable).

Comment : `CAPTURE_DIR=<dossier> flutter test --no-pub test/capture/adm21_capture_test.dart` (la vraie
application, le vrai routeur, les vraies polices, thème clair), puis les images `historique_390_light`
et `historique_1440_light` retenues.

Limites, dites en premier : les données sont **fictives** (double du port, aucune donnée de production,
aucune écriture, aucun serveur joint). Ces captures ne prouvent ni les nouvelles lectures, ni les
filtres, ni les voisins : elles ne prouvent que le rendu. Les nouveaux champs (`details`,
`responsableNom`) ne sont pas affichés : le double du port ne les rend pas, et aucun écran ne les lit
encore. Rien n'est prouvé sur staging ni en production ; la preuve de l'étape reste celle du directeur.
