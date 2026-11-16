# MAJEUR (16/11/2026)

Ce que change le lot : une question d'âge, « J'ai 18 ans ou plus. », en tête du parcours de la
salle 1 (avant les questions), et la même case en tête de la page des candidats déjà avancés, là où
ils sont. Sans la case, « Continuer » n'est pas rendu et une phrase dit pourquoi. « J'ai moins de
18 ans » demande confirmation (l'effet est dit avant : candidature en pause, rien n'est supprimé),
puis une phrase bienveillante dit que le recrutement est réservé aux personnes de 18 ans et plus.
Fichiers : `lib/features/candidature/majorite_etape.dart` (écran et carte), `candidature_page.dart`
et `portail_candidature.dart` (branchements), `lib/core/candidature/` (modèle, port, adaptateur).

Captures (390 et 1440, français et arabe de droite à gauche) :
- `salle1-question-*` : la question avant les questions ; `salle1-case-cochee-*` : « Continuer »
  apparaît ; `salle1-confirmation-*` : « Vous avez moins de 18 ans ? » avec l'effet dit avant ;
  `salle1-moins-18-*` : la page bienveillante.
- `avances-carte-*` : la carte d'âge en tête de la page d'un candidat dont la candidature est
  déjà envoyée (ici en examen).

Comment : `CAPTURE_DIR=<dossier> flutter test --no-pub test/features/candidature/majeur_test.dart`
(la vraie application dans le harnais des tests, les vraies polices du dépôt, thème clair), groupe
« captures ».

Limites, dites en premier : les données sont **fictives** (double du port, aucune donnée de
production, aucun serveur joint). Ces captures prouvent le rendu, pas le serveur ni le parcours réel.
La carte des candidats avancés n'est capturée que pour l'état « en examen » ; elle se pose par
`EnteteSalle`, donc aussi en salle 2 et en salle 3, mais ces deux états n'ont pas leur capture.
**Ce que les captures ne montrent pas, parce que ce n'est pas fait :** les gestes suivants d'un
candidat avancé (le bouton de « prochaine action » de la page d'attente) n'attendent pas encore la
case : ce bouton est posé par `lib/features/dossier/attente_page.dart`, hors de la zone de ce lot.
La rubrique « Accords » du dossier de la direction n'est pas touchée (PR 508 pas fusionnée).
La preuve de l'étape reste celle du directeur en production.

`journal.txt` : la sortie texte de `supabase/tests/scenarios_majeur.sql` (32 contrôles), jouée sur un
Postgres 16 local jetable (stub, toutes les migrations de `main`, puis `20261128400000`). C'est la
preuve du serveur ; les captures ne prouvent que l'écran.
