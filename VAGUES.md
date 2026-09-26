# Vagues du projet Rewayah Academy

Ordre décidé par le directeur (24/09/2026). Une vague = une branche de base, un dossier de pilotage, des lots, des lignes dans le tableau de suivi. La vague suivante ne commence qu'après accord du directeur.

| Vague | État | Branche de base | Dossier de pilotage | Objectif |
|---|---|---|---|---|
| Tuteur V1 (frontend) | en cours | `ui/tuteur-v1` | branche `pilotage/tuteur-v1` | Tous les écrans et parcours du rôle Tuteur, fidèles aux maquettes, honnêtes sur ce que le serveur ne fait pas encore |
| Classe et visio | préparée (25/09), démarre par le lot CL-1 | `ui/classe-v1` (worktree `C:\RA\classe`) | branche `pilotage/tuteur-v1`, dossier `10_classe/` (lire `00_REPRISE.md`) ; spec `specs/02_classe_et_visio/` ; images `lancement/classe image/` | **Priorité n° 1 : un élève et un enseignant se rencontrent et se voient** (salle unique, visio, jeton serveur, entrée depuis la classe, présence) ; validation des dossiers enseignants par l'admin ; puis lecteur du Coran fidèle |
| Admin : validation des dossiers (spec 03) | préparée (26/09), démarre par AD-1 | `ui/admin-v1` depuis `origin/ui/tuteur-v1` (worktree `C:\RA\admin`) | branche `pilotage/tuteur-v1`, dossier `11_admin/` (lire `00_REPRISE.md`) ; spec `specs/03_admin_validation_dossiers/` ; règles gelées `memoire/DESIGN-GOV-2026-09-26.md` | ADM-02 : file, revue du dossier, pièce, refus, validation, politique de genre KYC Super Admin, en démonstration (serveur à BR-1) |
| Backend T1 | prévue, après le frontend Tuteur | à créer | à créer | Garanties serveur du tuteur, sécurité, CI verte (prompt prêt dans le document « Rewayah — Audit de méthode ») |
| Rôles suivants | à planifier | - | - | Enseignant, élève adulte, élève enfant (Interface guidée, accessibilité), administration, contrôleur, contrôleur invité, finance et comptable, bibliothèque et ressources, solde par enfant et recharge, landing page web, publication iOS, Play Store, Windows |

Backlog consigné pour la vague Classe et visio : `pilotage/tuteur-v1` : `08_BACKLOG_VAGUE_CLASSE_VISIO.md`.
