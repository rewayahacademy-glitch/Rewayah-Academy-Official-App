# État de la ligne d'arrivée

Toute session, pilote ou agent, commence par ce fichier (`METHODE-2026-11-01.md`, règle 3).
Une ligne par parcours de `PARCOURS-OUVERTURE-2026-11-01.md`, mise à jour à chaque passage du
test de bout en bout.

Vert : le test de bout en bout passe. Rouge : il échoue, cause écrite. Non écrit : aucun test encore.

| # | Parcours | Test bout en bout | Cause si rouge | Dernier passage | Captures |
|---|---|---|---|---|---|
| 1 | La direction valide un enseignant | non écrit | | | |
| 2 | La direction crée une classe à plusieurs séances | vert (local) | Écarts relevés : le formulaire ouvre déjà 3 créneaux (le carnet dit « Ajouter un créneau ») ; la barre de navigation de l'enseignant n'est pas dans l'arbre d'accessibilité (onglet Classes ouvert par son adresse) | 2026-10-31 20:08 UTC | [parcours-2](captures/E2E/parcours-2/) |
| 3 | Une famille et un adulte s'inscrivent, la direction les accepte | vert (local) | Lien de confirmation reçu et ouvert depuis Mailpit (local, pas l'envoi réel de production). Écarts : étape « Lire et accepter nos conditions » absente du carnet ; le récapitulatif affiche « Langue du cours francais » (code, sans cédille) ; après « Accepter la demande », la boîte garde « État À traiter » ; la recherche des Demandes perd le focus après la 1re lettre (vu sous Playwright) | 2026-10-31 20:35 UTC | [parcours-3](captures/E2E/parcours-3/) |
| 4 | La direction place un élève | vert (local) | Classe d'adultes créée au passage pour placer l'élève adulte (sert au parcours 8). Écart : l'Accueil de la famille montre « Rejoindre la salle avec … » et en même temps « Ouverture de la salle non confirmée pour l'instant » pendant une séance en cours | 2026-10-31 20:40 UTC | [parcours-4](captures/E2E/parcours-4/) |
| 5 | Tenir la séance (Rejoindre, vidéo, page du Coran) | vert (local) | Vidéo et micro réels via LiveKit local (caméra/micro factices de Chromium) ; son vérifié par la présence des pistes audio et l'état « Micro ouvert », pas à l'oreille. Élève rejoint par le tuteur (« Rejoindre la salle avec … »), pas par l'appareil de l'enfant. Écarts : sur ordinateur 1200 x 760, « Page suivante » n'est pas à côté de la page mais dans « Plus » ; côté tuteur en salle, bandeau « Séance toujours en direct · Retourner dans la salle » et « État inconnu » | 2026-10-31 20:49 UTC | [parcours-5](captures/E2E/parcours-5/) |
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
