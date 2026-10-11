# PED-PROGRESSION : lire d'abord

Reçu le 11/10/2026 (soir). Complément de cahier livré par le directeur (spec verticale V1, deux planches high-fi).

## Préalable obligatoire, demandé par le directeur le 11/10/2026

Aucun écran PED-PROGRESSION ne se code avant l'étude **PED-PROG-ETUDE** et la décision du directeur sur ses conclusions.

Selon le directeur, le suivi de la progression est « le nerf de l'app ». C'est la raison n° 1 de sa création : savoir si un élève avance et, sinon, à qui l'imputer (l'élève, l'enseignant ou le tuteur). Le cahier, la présence automatique, la vérification du réseau, l'endroit où l'élève s'est arrêté, la reprise et le fuseau horaire existent pour répondre à cette question.

L'étude doit déterminer, simplement mais complètement :

1. **La logique de progression.** Ce qui mesure l'avancée (unités du parcours, jalons, sourates, pages, compétences) et à quel rythme.
2. **Les objectifs.**
   - Un système **par défaut et obligatoire**, où chaque tranche ou niveau avance automatiquement selon un rythme attendu.
   - Des **exceptions explicites** : faire avancer ou reculer un élève, ou lui donner un programme spécifique, toujours avec un motif.
   - La portée : par élève et/ou par groupe (Classe).
3. **Les écarts et alertes.** Quand l'écart entre le réel et l'objectif déclenche un message au tuteur, une alerte à l'administration ou une optimisation du parcours.
4. **L'imputation (KPI).** À partir des preuves existantes (présence, réseau, cahier K-45, travail, reprise), dire si le retard vient de l'élève, de l'enseignant, du tuteur ou de la plateforme, sans accusation automatique non prouvée.

Livrable de l'étude : un artefact pour le directeur, avec des scénarios et des exemples chiffrés, puis une décision datée versée dans `docs/current/`.

## Ordre de lecture

1. Ce fichier.
2. `PED_PROGRESSION_SPEC_VERTICALE_V1.md` (source d'acceptation R01-R39 pour les écrans, sous réserve de l'étude).
3. `README_HI_FI_PED_PROGRESSION.md`.
4. `references/` : deux planches high-fi, avec des données fictives.

Règles inchangées : le cahier K-45 est gelé ; aucun pourcentage, score ou classement calculé par Flutter ; le serveur seul calcule les écarts.
