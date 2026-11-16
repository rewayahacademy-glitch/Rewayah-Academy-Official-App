# PAYS-RECHERCHE (16/11/2026)

Ce que change le lot : la recherche d'un pays lit aussi les trois noms du pays (français, arabe,
anglais) et son code, quelle que soit la langue de l'application ; la liste courte affichée d'abord
suit les vraies candidatures (Arabie saoudite, Nigeria, Yémen, Égypte, Algérie, Bénin, Ghana, Tchad,
puis Sénégal, Mali, Guinée, Maroc, France, Belgique, Royaume-Uni). Fichiers :
`lib/features/candidature/question_etape.dart` et `pays_versement_portail.dart`.

Captures : `recherche-390-ar.png`, `recherche-1440-ar.png` (application en arabe, « Ghana » tapé en
lettres latines : le Ghana, « غانا », est trouvé) ; `recherche-390-fr.png`, `recherche-1440-fr.png`
(application en français, « غانا » tapé : « Ghana » est trouvé).

Comment : `CAPTURE_DIR=<dossier> flutter test --no-pub test/features/candidature/pays_versement_portail_test.dart`
(la vraie application dans le harnais des tests, les vraies polices du dépôt, thème clair), groupe
« captures », écran « Pays du compte de versement » du portail du candidat.

Limites, dites en premier : données **fictives** (double du port, aucune donnée de production, aucun
serveur joint). Ces captures prouvent le rendu et la recherche dans le harnais de test ; elles ne
prouvent ni l'écran de production ni le parcours complet. La capture arabe à 390 est celle de la
feuille du portail ; la question « pays de versement » du parcours (salle 1) utilise le même
composant de recherche et les mêmes mots-clés. La preuve de l'étape reste celle du directeur.
