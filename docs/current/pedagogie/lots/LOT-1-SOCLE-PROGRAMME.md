# Lot 1 · SOCLE-PROGRAMME

> Branche `claude/socle-programme`, ouverte le 12/11/2026 sur la branche de la charte (`179ab28f4`).
> Plan : `PLAN-DE-CONSTRUCTION.md`, section « Lot 1 ». Valeurs : `REGLAGES.md` (tableau 1 et 1 bis).
> Statut : **en cours d'écriture** (ce fichier est réécrit à la fin du lot avec ce qui est réellement fait et testé).

## Ce que le lot réutilise

| Existant | Comment |
|---|---|
| `programme_versions`, `programme_niveaux` (0020, C2) | Une ligne de `programme_niveaux` est une **étape** ; `code_technique` devient son identité stable (`BASES-1` à `BASES-4`). La version en brouillon de production est complétée puis publiée. |
| `programme_niveaux.objectifs`, `plage_support`, `durees` (C2) | `durees[tranche].prevue` = durée prévue de l'étape ; `durees[tranche].limite` = **repère** de l'étape (tableau 1 bis), plus jamais une date ferme. |
| Contrôle de publication de C2 | Gardé tel quel ; un second contrôle s'ajoute (sommes des repères). |
| `private.etape_eleve` (SUIVI-ELEVE) | Même signature ; lit d'abord le fait « étape en cours ». Toutes ses lectures (`etapes_eleves_classe`, `rythme_classe`, `suivi_pedagogique_eleve`, `lire_resultats_evaluations`) rendent donc la même étape. |
| `private.sourates_des_bases`, `sourates_validees` (SOURATES) | Les 17 sourates de la lecture unique viennent d'ici, sans copie. |
| `private.cahier_c1_peut_lire_classe` | Garde de l'enseignant titulaire, du remplaçant (fenêtre de la séance) et de la direction. |
| `private.vitesse_eleve` | Le rythme rendu par la lecture unique (le calcul « À surveiller » est le lot 7). |
| `decider_placement`, `progression_promouvoir` (0021, 0022) | Les gestes existants de la direction : chaque décision publiée corrige le fait « étape en cours » par un déclencheur. |
| Branche `claude/parcours-inscrits-main` | **Reprise telle quelle** en tête du lot (deux commits, migration `20261123810000`). |
| Branche `claude/ma-progression-main` | **Adaptée** : l'idée d'une lecture serveur unique et ses tests de refus sont repris ; sa table `programme_etape_reglages` est écartée (arbitrage n° 1 : une seule clé d'étape ; les heures de révision sont un réglage par âge). |
| Écrans `features/suivi_eleve`, `features/suivi_foyer` (`CarteSuiviPedagogique`) | Branchés sur la lecture unique ; aucun nouvel écran. |

## Ce que le lot crée

- `public.programme_cycles` : le **niveau** d'une version (code stable `bases`, nom, durée prévue et date limite par tranche d'âge).
- `programme_niveaux.cycle_code` et `programme_niveaux.matieres` (matière principale et matière secondaire par tranche d'âge).
- `public.eleve_etape_en_cours` : le fait unique par élève (étape, date d'entrée dans l'étape, date d'entrée dans le niveau, tranche d'âge figée, date limite du niveau, `recul_jours` = point d'accroche du lot 2).
- L'archivage automatique de la version publiée précédente à chaque publication, et un index qui interdit deux versions publiées.
- Le niveau de chaque classe posé seul (classes existantes et classes nouvelles) ; l'étape de chaque élève posée seule à l'entrée en classe (et pour les élèves déjà présents).
- `public.etape_eleve_lecture(p_eleve_id)` : la lecture unique, pour l'élève, le tuteur, l'enseignant, le remplaçant et la direction.
- Le réglage `programme.age_voit_date_limite` (10 ans) dans `app_config`.

## Ce qui reste pour le lot 10

Les anciens calculs restent en base, plus lus par les écrans touchés : la branche « sans fait » de `private.etape_eleve` (ancienne règle), `suivi_pedagogique_eleve` (plus appelée par le suivi de l'élève et du tuteur), l'étape de `groupe_roster_enseignant` (lit encore `progression_historique`, n'est affichée nulle part), `progression_admin`, `unite_curriculum`, `progression_famille.level`.

## Choix techniques

À compléter à la fin du lot.

## Écarts entre le plan et le code trouvé

À compléter à la fin du lot.
