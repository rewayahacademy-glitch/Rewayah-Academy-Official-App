# État de la ligne d'arrivée

Toute session, pilote ou agent, commence par ce fichier (`METHODE-2026-11-01.md`, règle 3).
Une ligne par parcours de `PARCOURS-OUVERTURE-2026-11-01.md`, mise à jour à chaque passage du
test de bout en bout.

Vert : le test de bout en bout passe. Rouge : il échoue, cause écrite. Non écrit : aucun test encore.

| # | Parcours | Test bout en bout | Cause si rouge | Dernier passage | Captures |
|---|---|---|---|---|---|
| 1 | La direction valide un enseignant | non écrit | | | |
| 2 | La direction crée une classe à plusieurs séances | non écrit | | | |
| 3 | Une famille et un adulte s'inscrivent, la direction les accepte | non écrit | | | |
| 4 | La direction place un élève | non écrit | | | |
| 5 | Tenir la séance (Rejoindre, vidéo, page du Coran) | non écrit | | | |
| 6 | Présence et cahier | non écrit | | | |
| 7 | La famille voit la classe, la présence, et paie | non écrit | paiement : clé Stripe absente en production | | |
| 8 | L'élève adulte suit sa classe | non écrit | | | |

## Lots en cours (se finissent, puis plus rien hors ligne d'arrivée)

| PR | Objet | Parcours servi | État |
|---|---|---|---|
| 98 | Remplacement automatique de l'enseignant absent | hors ligne (déjà commencé) | migration posée en production, CI en cours |
| 100 | Séance ouverte par le jeton vidéo | 5 | après 98 |
| 103 | Cahier hebdomadaire | 6 | CI en cours |
| 104 | Confier une classe à un autre enseignant | 2 | après 103 |
| 95 | Factures le 1er, relances | 7 | retenue jusqu'au 04/11 |
