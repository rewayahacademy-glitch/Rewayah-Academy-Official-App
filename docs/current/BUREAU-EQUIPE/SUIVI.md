# Suivi du Bureau de l'équipe

Statuts permis : `pas commencé`, `en cours` (agent, branche), `PR ouverte` (numéro),
`dans main` (numéro), `prouvé par le directeur` (date). Aucun autre mot. Mis à jour le 16/11/2026.

## Vague 0 et vague 1 (ordre du directeur du 16/11)

| Lot | Contenu | Cahier | Statut |
| :--- | :--- | :--- | :--- |
| BE-0a | Message en double | aucun : corrigé par le pilote hors de ce chantier. Cause prouvée par lui : la liste des messages présents à l'ouverture était lue trop tard dans une conversation vide (pas le rapprochement par texte, que la stratégie supposait) | dans main (#503) |
| BE-0b serveur | L'historique renvoie le détail et le nom du responsable | `CAHIER-BE-S1.md` | dans main (#505) ; migration installée en production le 16/11 par le coordinateur, sur ordre du directeur ; à prouver par le directeur |
| BE-1a | Ordre des dossiers (précédent, suivant), filtres sur les réponses, « pièce en attente », « mes dossiers » | `CAHIER-BE-S1.md` | dans main (#505) ; migration installée en production le 16/11 par le coordinateur, sur ordre du directeur ; à prouver par le directeur |
| BE-0b écran + BE-1d | Dossier en trois étages, rubriques repliées avec leurs gestes, photo et pièce qui s'ouvrent au toucher, rien de fixe (arbitrage du 16/11), résumé en tableau | `CAHIER-BE-DOSSIER.md` | dans main (#508) |
| BE-0c + BE-1c | Retours qui ramènent d'où l'on vient, filtres dans l'adresse, entrée de « Personnes » sur Candidatures, en-tête de liste réduit, une seule file | `CAHIER-BE-LISTE.md` | dans main (#506) |
| BE-VERSEMENT | Le moyen de versement se valide seul quand le pays est pris en charge ; la direction décide une fois par pays, pas par candidat (directeur, 16/11) | `CAHIER-BE-VERSEMENT.md` | dans main (#509) ; installé en production le 16/11 |
| BE-LISTE-2 | Un seul système de filtres (titre-sélecteur, recherche avec Filtres et Trier, une rangée de files avec leurs nombres), bandeau des deux côtés fermable (directeur, 16/11, captures de production) | `CAHIER-BE-LISTE-2.md` | en cours (agent BE-LISTE, `claude/be-liste-2`) |
| PAYS-RECHERCHE | Le Ghana introuvable : la recherche de pays ne lisait que la langue de l'interface ; liste courte des vrais pays (directeur, 16/11) | `CAHIER-BE-PAYS-MAJEUR.md` | PR ouverte (#513) |
| MAJEUR | Attestation « 18 ans ou plus » avant de continuer ; les candidats déjà avancés cochent à leur prochaine visite (directeur, 16/11) | `CAHIER-BE-PAYS-MAJEUR.md` | PR ouverte (#517) ; migration `20261128400000` à installer juste après la fusion |
| BE-COLONNES | Les critères de la synthèse en colonnes dans la liste, sur ordinateur, triables (directeur, 16/11) | `CAHIER-BE-COLONNES.md` | pas commencé (après BE-LISTE-2, même zone ; la PR 508 est dans main) |
| BE-DOSSIER-2 | Corrections du dossier en production : page vide au bout, moins de rubriques repliées, carte de profil avec la messagerie, heures en plages sans mélange arabe et latin (directeur, 16/11) | `CAHIER-BE-DOSSIER-2.md` | PR ouverte (#518) |
| BE-1b | « Précédent / Suivant », compteur, passage au suivant après une décision | `CAHIER-BE-SUIVANT.md` | PR ouverte (#516), après #518 |
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
- 16/11 : le directeur conteste la confirmation du versement candidat par candidat ; lu en production : 125 candidatures `a_verifier` avec un pays déjà `confirme`. Arbitrage : automatique si le pays est pris en charge, décision une fois par pays sinon (`CAHIER-BE-VERSEMENT.md`).
- 16/11 : directeur, sur les captures du dossier : le résumé doit être un tableau de synthèse (mots-clés, pas les phrases du candidat), « imagine lire ce paragraphe pour plus de 1 000 personnes » ; écrans pliables : penser aux deux états, ni chevauchement, ni débordement, ni page qui saute quand une rubrique s'ouvre. Transmis à BE-DOSSIER (PR 508). Les deux barres du haut de sa capture étaient deux captures mises côte à côte par le coordinateur, pas un doublon de l'application.
- 16/11 : le directeur autorise le coordinateur à installer **toutes les migrations nécessaires** à ce chantier (« je t'autorise de faire toutes les migrations nécessaires »). Chaque installation est vérifiée avant (ancres) et après (lecture en production), et notée ici.
- 16/11 : BE-VERSEMENT fusionné (#509) et installé en production (`be_versement_regle`, puis `be_versement_recalcul`). Lu après : plus aucune candidature en cours `a_verifier` ; 176 en examen avec un versement valide ; `paiement_non_disponible` passe de 53 à 51 (2 ramenés, avec l'avis au candidat).
- 16/11 : le directeur, sur la liste en production : sept blocs et quatre façons de filtrer avant le premier nom ; bandeau jaune à rendre fermable ; rangée « Sélectionner / Trier » cassée. Cahier BE-LISTE-2.
- 16/11 : un candidat ne trouve pas le Ghana. Vérifié : le pays existe ; la recherche ne lit que le nom dans la langue de l'interface (`motsCles` jamais rempli). Et le directeur demande l'attestation « 18 ans ou plus ». Cahier BE-PAYS-MAJEUR.
- 16/11 : le directeur, sur la PR 515 (pas encore en production) : filtres sur cinq lignes et recherche trop haute ; les files doivent tenir dans un menu déroulant. Et sur le dossier en production : page vide au bout (faute du coordinateur, qui avait accepté ce blanc), trop de replis, carte de profil voulue, heures mélangées en arabe. Cahier BE-DOSSIER-2 ; BE-LISTE-2 revu.
- 16/11 : le garde-fou refuse au coordinateur de relancer un job de CI ; un test du lundi matin (`scenarios_fac_f_relances_suspension.sql`) fait échouer « Migrations applicables » entre 06:50 et 08:00 UTC, signalé au pilote.
