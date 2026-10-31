# État de la ligne d'arrivée

Toute session, pilote ou agent, commence par ce fichier (`METHODE-2026-11-01.md`, règle 3).
Une ligne par parcours de `PARCOURS-OUVERTURE-2026-11-01.md`, mise à jour à chaque passage du
test de bout en bout.

Vert en local : le test de bout en bout passe sur la pile locale, captures datées à l'appui.
Rouge : il échoue, cause écrite. Non écrit : aucun test encore. **Vert en local n'est pas une
recette en production** : la dernière colonne ne se remplit que quand le directeur l'a faite.

| # | Parcours | Vert en local | Cause si rouge | Dernier passage | Captures | Recette prod (directeur) |
|---|---|---|---|---|---|---|
| 1 | La direction valide un enseignant | vert en local | Compte en attente préparé par l'interface : invitation de la direction, inscription avec le code (lien Mailpit), accords, pièce factice. La pièce d'un enseignant n'est relue que par un membre du même genre (direction de test et candidate : femmes). Écarts : la page Invitations est sous Personnes, Candidatures, « Invitations » ; après le lien d'e-mail, « Pour qui créez-vous ce compte ? » revient et « J'ai un code d'invitation » est à toucher de nouveau. Pile : l'URL signée de la pièce pointait l'adresse interne locale (kong:8000), redirigée dans le navigateur de test | 2026-10-31 21:10 UTC | [parcours-1](captures/E2E/parcours-1/) | |
| 2 | La direction crée une classe à plusieurs séances | vert en local | Écarts relevés : le formulaire ouvre déjà 3 créneaux (le carnet dit « Ajouter un créneau ») ; la barre de navigation de l'enseignant n'est pas dans l'arbre d'accessibilité (onglet Classes ouvert par son adresse) | 2026-10-31 20:08 UTC | [parcours-2](captures/E2E/parcours-2/) | |
| 3 | Une famille et un adulte s'inscrivent, la direction les accepte | vert en local | Lien de confirmation reçu et ouvert depuis Mailpit (local, pas l'envoi réel de production). Écarts : étape « Lire et accepter nos conditions » absente du carnet ; le récapitulatif affiche « Langue du cours francais » (code, sans cédille) ; après « Accepter la demande », la boîte garde « État À traiter » ; la recherche des Demandes perd le focus après la 1re lettre (vu sous Playwright) | 2026-10-31 20:35 UTC | [parcours-3](captures/E2E/parcours-3/) | |
| 4 | La direction place un élève | vert en local | Classe d'adultes créée au passage pour placer l'élève adulte (sert au parcours 8). Écart : l'Accueil de la famille montre « Rejoindre la salle avec … » et en même temps « Ouverture de la salle non confirmée pour l'instant » pendant une séance en cours | 2026-10-31 20:40 UTC | [parcours-4](captures/E2E/parcours-4/) | |
| 5 | Tenir la séance (Rejoindre, vidéo, page du Coran) | vert en local | Vidéo et micro réels via LiveKit local (caméra/micro factices de Chromium) ; son vérifié par la présence des pistes audio et l'état « Micro ouvert », pas à l'oreille. Élève rejoint par le tuteur (« Rejoindre la salle avec … »), pas par l'appareil de l'enfant. Écarts : sur ordinateur 1200 x 760, « Page suivante » n'est pas à côté de la page mais dans « Plus » ; côté tuteur en salle, bandeau « Séance toujours en direct · Retourner dans la salle » et « État inconnu » | 2026-10-31 20:49 UTC | [parcours-5](captures/E2E/parcours-5/) | |
| 6 | Présence et cahier | non écrit |  |  |  | |
| 7 | La famille voit la classe, la présence, et paie | non écrit | paiement : clé Stripe absente en production |  |  | |
| 8 | L'élève adulte suit sa classe | partiel : étapes 1-2 vertes (local), étape 3 non jouée | Étape 3 (« Dernières séances », « Voir tout ») PAS ENCORE JOUÉE : la séance d'adultes finit à 22:45 UTC et se clôt 30 min après ; rejouer « node tool/e2e/parcours_8.mjs --apres ». Écart : quand deux séances s'enchaînent, « Aujourd'hui » de l'enseignant garde la précédente « en direct · temps prévu écoulé » jusqu'à sa clôture automatique (fin + 30 min) et ne propose pas la salle suivante : l'enseignant passe par l'onglet Classes | 2026-10-31 21:23 UTC | [parcours-8](captures/E2E/parcours-8/) | |

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

- **CI** : 30 scénarios sur 154 rejoués par `ci.yml` (présence aux minutes, cahier hebdomadaire et remplacements n'y sont pas) ; la pile locale rejoue tout, c'est elle la preuve. Élargir la CI : décision du directeur (`.github/`).
- **Cahier du remplaçant** : le remplaçant ne peut déposer aucun cahier (prouvé en local le 31/10) ; PR 106 fusionnée, lot lancé, règle par défaut « le remplaçant seul dépose, le titulaire lit ».
- **Minutes connectées sans sortie (lot PRESENCE, 20261102900000)** : si l'enseignant entre sans jamais sortir, `private.pai_minutes_enseignant` ferme l'intervalle à `finance_ended_at`, posé par la clôture automatique. Une séance d'1 h peut ainsi compter 1799 minutes (relevé local du 31/10, scénario ses_cloture_auto cas 4). La paie reste juste, car elle est plafonnée à la durée prévue, mais les minutes affichées à la famille et à la direction sont fausses. Correction proposée : borner à la fin prévue plus la grâce. Elle sera faite par une nouvelle migration, jamais en modifiant la migration appliquée.
- **`scenarios_fac_e_paie_par_eleve`** échoue sur `main` (« pending trigger events »), hors des 30 scénarios rejoués par la CI.
- **Séances qui s'enchaînent (relevé E2E local, 31/10 21:24)** : pour un même enseignant, Aujourd'hui garde la séance précédente « Séance en direct · Temps prévu écoulé » jusqu'à la clôture automatique (fin plus 30 min). L'écran ne propose pas la suivante ; seul l'onglet Classes le fait. « Quitter et ouvrir le cahier » laisse la séance en in_progress. Bloquant pour l'ouverture. Lot à lancer après la PR 100.

- **F1** : les aperçus Vercel écrivent dans la base de production (même `SUPABASE_URL`).
- **F2** : la base staging est en retard depuis le 23/10.
