# État de la ligne d'arrivée

Toute session, pilote ou agent, commence par ce fichier (`METHODE-2026-11-01.md`, règle 3).
Une ligne par parcours de `PARCOURS-OUVERTURE-2026-11-01.md`, mise à jour à chaque passage du
test de bout en bout.

Vert en local : le test de bout en bout passe sur la pile locale, captures datées à l'appui.
Rouge : il échoue, cause écrite. Non écrit : aucun test encore. **Vert en local n'est pas une
recette en production** : la dernière colonne ne se remplit que quand le directeur l'a faite.

| # | Parcours | Vert en local | Cause si rouge | Dernier passage | Captures | Recette prod (directeur) |
|---|---|---|---|---|---|---|
| 1 | La direction valide un enseignant | non écrit | | | | |
| 2 | La direction crée une classe à plusieurs séances | non écrit | | | | |
| 3 | Une famille et un adulte s'inscrivent, la direction les accepte | non écrit | | | | |
| 4 | La direction place un élève | non écrit | | | | |
| 5 | Tenir la séance (Rejoindre, vidéo, page du Coran) | non écrit | | | | |
| 6 | Présence et cahier | non écrit | | | | |
| 7 | La famille voit la classe, la présence, et paie | non écrit | paiement : clé Stripe absente en production | | | |
| 8 | L'élève adulte suit sa classe | non écrit | | | | |

## Lots en cours (se finissent, puis plus rien hors ligne d'arrivée)

| PR | Objet | Parcours servi | État |
|---|---|---|---|
| 98 | Remplacement automatique de l'enseignant absent | hors ligne (déjà commencé) | migration posée en production, CI en cours |
| 100 | Séance ouverte par le jeton vidéo | 5 | après 98 |
| 103 | Cahier hebdomadaire | 6 | CI en cours |
| 104 | Confier une classe à un autre enseignant | 2 | après 103 |
| 95 | Factures le 1er, relances | 7 | retenue jusqu'au 04/11 |

## Écart entre les migrations du dépôt et la production

Contrôle en lecture seule du 31/10 à 19 h 30 (UTC) : 288 fichiers de `supabase/migrations` sur
`main` comparés à la liste enregistrée en production. Tout écart compte comme un rouge tant qu'il
n'est pas expliqué.

| Migration du dépôt | Enregistrée en production | Objets présents en production | État |
|---|---|---|---|
| 0006, 0007, 0008 | sous les noms `0006_init`, `0007_init`, `0008_init` | oui | expliqué |
| `20261012113000_f86_observation_policy_guard` | non | oui (garde présente) | appliquée, non enregistrée |
| `20261012114000_f86_observation_entry_guard` | non | oui (garde présente) | appliquée, non enregistrée |
| `20261012140000_kyc_controller_storage_policy_retired` | non | oui (politique `kyc_lecture_admin` absente) | appliquée, non enregistrée |
| `20261027120000_notifications_classes_seances` | non | oui (7 fonctions, 6 déclencheurs, contrainte à jour) | appliquée, non enregistrée |
| `remplacement_auto` (PR 98, pas encore sur `main`) | non (collée par le directeur dans l'éditeur SQL) | oui (vérifié le 31/10 après collage) | appliquée, non enregistrée |

Aucune migration de rattrapage de l'enregistrement sans décision du directeur.

## Dette en attente (on ne la règle pas maintenant)

- **F1** : les aperçus Vercel écrivent dans la base de production (même `SUPABASE_URL`).
- **F2** : la base staging est en retard depuis le 23/10.
