# CL-4, entrée en classe : découpage

Les étapes sont inscrites au tableau de suivi sous `CL-4.*`. Chaque tâche d'agent dure moins de 35 minutes :
- Opus pour le design et les écrans ;
- Sonnet pour le mécanique.

## Lectures, et rien d'autre

- `00_MAQUETTES_ENTREE.md` (rectifications) et `01_HARMONISATION.md`.
- `projet/ressources:memoire/CLASSE-ENTREE-2026-09-26.md` : règles R1 à R21.
- Document du directeur : `specs/02_classe_et_visio/REWAYAH_CLASSE_ENTREE_PREFLIGHT_CHRONO_V1.md` (§3 à §12, §15, §16).
- Spec 02, CLV-01 à CLV-03 : états et textes que le document du directeur ne tranche pas.
- Règles gelées (contrats A à E).

## Base

- Branche `ui/classe-v1`, worktree `C:\RA\classe`.
- Démonstration seulement (K-28) : tout besoin serveur tient en une ligne dans `10_classe/CL-4-BR.md`.
- Zones interdites habituelles.
- Commandes lourdes : `flutter-verrou.ps1`.

## Maquettes du document du directeur (§14) couvertes

| Code | Écran | Étape |
|---|---|---|
| CLS-ELV-01 et 02 | Espace Classe élève : séance à venir, puis fenêtre T-20 ouverte | CL-4.3 |
| CLS-ENS-01 et 02 | Espace Classe enseignant : préparation, puis fenêtre ouverte | CL-4.4 |
| PRE-ENS-01 | Préparation enseignant, tout est prêt | CL-4.5 |
| PRE-ELV-01, PRE-ERR-01 | Préparation élève minimale, puis problème à résoudre | CL-4.6 |
| LIVE-TIMER-01 | Chrono | **Reporté** : LIVE-CHRONO-01 |

## Étapes

| Étape | Contenu | Sortie |
|---|---|---|
| CL-4.0 | Relevé, classement par rôle, rectifications, harmonisation, règles R1 à R21 | **Fait** (ce dossier) |
| CL-4.1 | **Revue UX 2026** (DESIGN-GOV §4). Pour chaque disposition : règle, source, date, conclusion. Sans GOV.UK (exclu par le directeur). | `10_classe/UX_REVIEW_CL-4.md` |
| CL-4.2 | **Socle de démonstration.** Horloge de séance dérivée d'horodatages (R5) et états de la carte : à venir, fenêtre ouverte, préparation, attente, en direct, terminée, annulée, hors ligne, avis de changement d'heure (DST). Route `/demo/classe`, hors production, rôle × état. Ports de démonstration sur le patron de `CatalogueClassesDemo`. Réutiliser `SessionClockVM` et `GroupHomeVM` s'ils existent (relevé d'abord). | Code et tests |
| CL-4.3 | **Espace Classe élève** : évolution d'`EspaceGroupePage`. Bouton seulement à l'ouverture (R4), heures, durée, décompte, ≤ 3 actions, bibliothèque, progression compacte. Tailles 390 / 768 / 1440 (bureau en vraie composition). Skeleton. | Code, tests qui touchent les boutons, captures |
| CL-4.4 | **Espace Classe enseignant** : évolution de `FicheGroupePage`. Carte de séance et « Préparer l'entrée », préparation (support, reprise, objectif), élèves (projection pédagogique, R15), supports récents, anomalies seulement s'il y en a. | Idem |
| CL-4.5 | **Préparation enseignant** : rendu de `PreCours` en mode complet, selon le patron du document §12 (aperçu coupé, équipement, contexte, bouton près du contexte). Médias coupés (R8), pas de faux sélecteur (R10), vérifications indépendantes (R19). | Idem |
| CL-4.6 | **Préparation élève** : mode silencieux de `PreCours`, avec « Tout est prêt » minimal ; le blocage réutilise la feuille micro de CL-7 ; Interface guidée : une seule question. Aucune erreur brute (R11). | Idem |
| CL-4.7 | **Recette.** Reflow 320, texte à 200 %, clavier, focus jamais masqué, clair et sombre. Planche web pour le directeur (une interface par planche sur web). | `05_recette/CL/CL-4_RAPPORT.md` et la planche |
| CL-4.R | **Revue croisée** par une autre session. | L'étape passe à « vérifié » |

## Reporté, noté au tableau

- **LIVE-CHRONO-01** : le chrono discret de la salle (règles R5 à R7). À appliquer lors de la passe Classe Live correspondante, ou en HU-1.
- **LIVE-PAUSE-01** : la pause configurable de l'enseignant, plus tard, sur décision du directeur.
- **Écarts de coque** (entrées de navigation et pied de compte vus dans les images) : HU-1.
