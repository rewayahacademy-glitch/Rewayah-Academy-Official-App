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
| 98 | Remplacement automatique de l'enseignant absent | hors ligne (déjà commencé) | fusionnée le 31/10 ; fonction courriels-envoi redéployée par deploy.yml (version 12) |
| 100 | Séance ouverte par le jeton vidéo | 5 | rejouée par-dessus la 98 (a985822cf) ; attend la CI, puis migration et fusion |
| 103 | Cahier hebdomadaire | 6 | fusionnée le 31/10, migration posée et vérifiée en production |
| 104 | Confier une classe à un autre enseignant | 2 | fusionnée le 31/10, migration posée et vérifiée en production |
| 106 | L'exception du cahier corrige la présence | 6 | fusionnée le 31/10 (480a19ca3) ; migration posée en production, corps identique au fichier (md5), déclencheur présent, fonction fermée à authenticated |
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
| `remplacement_auto` (PR 98, pas encore sur `main`) | non (collée par le directeur dans l'éditeur SQL) | oui : table présente, tâche planifiée active, 55 passages réussis (relu par l'ancien pilote le 31/10) | appliquée, non enregistrée |

Aucune migration de rattrapage de l'enregistrement sans décision du directeur.

## Dette en attente (on ne la règle pas maintenant)

Décrite et suivie dans le registre `UX-CONSTATS.md`, table « Constats fonctionnels » : FN-001 (CI
30/154), FN-002 (cahier du remplaçant), FN-003 (1799 minutes, affichage faux, argent juste), FN-004
et FN-005 (scénarios rouges sur `main`), FN-006 (séances qui s'enchaînent, bloquant), FN-007 (F1),
FN-008 (F2), FN-009 et FN-010 (foyers A et B), FN-011 (clés Stripe).
