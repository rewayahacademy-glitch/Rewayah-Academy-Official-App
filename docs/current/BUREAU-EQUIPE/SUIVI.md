# Suivi du Bureau de l'équipe

Statuts permis : `pas commencé`, `en cours` (agent, branche), `PR ouverte` (numéro),
`dans main` (numéro), `prouvé par le directeur` (date). Aucun autre mot. Mis à jour le 16/11/2026.

## Vague 0 et vague 1 (ordre du directeur du 16/11)

| Lot | Contenu | Cahier | Statut |
| :--- | :--- | :--- | :--- |
| BE-0a | Message en double | aucun : corrigé par le pilote hors de ce chantier. Cause prouvée par lui : la liste des messages présents à l'ouverture était lue trop tard dans une conversation vide (pas le rapprochement par texte, que la stratégie supposait) | dans main (#503) |
| BE-0b serveur | L'historique renvoie le détail et le nom du responsable | `CAHIER-BE-S1.md` | dans main (#505) ; migration installée en production le 16/11 par le coordinateur, sur ordre du directeur ; à prouver par le directeur |
| BE-1a | Ordre des dossiers (précédent, suivant), filtres sur les réponses, « pièce en attente », « mes dossiers » | `CAHIER-BE-S1.md` | dans main (#505) ; migration installée en production le 16/11 par le coordinateur, sur ordre du directeur ; à prouver par le directeur |
| BE-0b écran + BE-1d | Dossier en trois étages, rubriques repliées avec leurs gestes, photo qui s'ouvre au toucher, pièce sur place, barre de décision fixe | `CAHIER-BE-DOSSIER.md` | PR ouverte (#508, brouillon, `claude/be-dossier-trois-etages`) |
| BE-0c + BE-1c | Retours qui ramènent d'où l'on vient, filtres dans l'adresse, entrée de « Personnes » sur Candidatures, en-tête de liste réduit, une seule file | `CAHIER-BE-LISTE.md` | PR ouverte (#506, agent BE-LISTE, `claude/be-liste-retours`) |
| BE-DOSSIER-2 | Corrections du dossier vu en production : page qui s'arrête au dernier contenu, moins de replis, carte de profil avec la messagerie, heures en plages | `CAHIER-BE-DOSSIER-2.md` | en cours (branche `claude/be-dossier-2`) ; testé localement, pas prouvé en production |
| BE-1b | « Précédent / Suivant », compteur, passage au suivant après une décision | `CAHIER-BE-SUIVANT.md` | PR brouillon #516 (`claude/be-suivant`), attend BE-DOSSIER-2 et les captures arabes |
| BE-1e | Panier de demandes (serveur, écran, côté candidat) | à écrire ; touche la machine à états : cahier par le grand modèle | pas commencé |
| BE-1f | Grille des disponibilités, deux fuseaux, sens arabe | à écrire après BE-1d | pas commencé |
| BE-1g | Impression ; dispense d'entretien ; accueil d'un fondateur | à écrire ; touche la machine à états | pas commencé |

## Vagues 2 à 5 (aucun ordre du directeur)

| Vague | Statut |
| :--- | :--- |
| 2. La mission (droits à la carte, associés invités, suspendre et rétablir) | pas commencé |
| 3. La liste (filtres enregistrés, écrire à une liste) | pas commencé |
| 4. Le Studio (après la messagerie refaite et après la vague 2) | pas commencé |
| 5. L'agent IA qui propose (après les vagues 2 et 3) | pas commencé |

## Le secrétaire IA (vision du directeur du 16/11, `SECRETAIRE-IA.md`)

| Lot | Contenu | Statut |
| :--- | :--- | :--- |
| SEC-0 | Les cinq compétences du secrétaire (`voix-directeur`, `repondre-rewayah`, `annoncer-rewayah`, `savoir-rewayah`, `agir-rewayah`) ; annonces WhatsApp reçues le 16/11 et analysées dans `SOURCE-ANNONCES-2026.md` | pas commencé |
| SEC-1 | Connecteur : messages et annonces en envoi direct (boîte, fil, écrire, annoncer, calendrier, alerter) | pas commencé |
| SEC-2 | Connecteur : dossiers (file, impression, listes, propositions) | pas commencé |
| SEC-3 | Connecteur : objectifs, check-listes, assignation, alertes, point du jour | pas commencé |
| SEC-4 | Connecteur : matching (besoins et ressources, classes proposées) | pas commencé |
| SEC-5 | Connecteur : état de l'application, chiffres, rapports | pas commencé |

## Journal

- 16/11 : trois agents lancés (BE-S1, BE-DOSSIER, BE-LISTE). Un quatrième agent du projet
  travaille déjà sur la messagerie (BULLES-MESSAGERIE) : le plafond de quatre est atteint.
- 16/11 : le directeur donne au coordinateur de ce chantier le droit de fusionner les PR de ses agents, « tant que ça ne met pas en conflit avec l'autre ».
- 16/11 : vision du secrétaire IA écrite (`SECRETAIRE-IA.md`) ; elle amende R3 de la stratégie.
- 16/11 : le directeur tranche : messages et annonces en envoi direct, sans aperçus ; le secrétaire propose aussi les fonctions et corrections à venir ; calendrier des annonces ; jouer le secrétaire sans code : pas maintenant.
- 16/11 : PR 505 (BE-S1) fusionnée par le coordinateur, CI verte. Le pilote signale que la migration porte BEGIN; et COMMIT; seuls sur une ligne (refusés par la page à coller) : retirés dans la PR 504.
- 16/11 : sur ordre du directeur (« installe la migration 505 »), `20261128100000_be_s1_lectures.sql` installée en production par `apply_migration` (version sans BEGIN ni COMMIT). Avant : les six ancres trouvées une fois chacune. Après, lu en production : `voisins_candidature` présente, cinq aides `private.be_*`, les trois fonctions retouchées, `anon` sans droit d'exécution. Non prouvé : l'écran (aucun n'appelle encore ces lectures).
- 16/11 : identité du secrétaire : Praxis, `#RA_PRAXIS` en italique ; le compte de l'administration prend la même marque (`SECRETAIRE-IA.md` §9 et §10).
