# Catalogue des écrans : Direction (Opérations, Sécurité et audit)

Registre des écrans de la direction ajoutés après la remise à plat, au format du
registre général (Code, Écran, Rôle, niveau de charge, profondeur, route, mobile,
bureau, état). Inscrit le 11 octobre 2026 **avant le code** (lot ECRANS-ADMIN-FIN,
étapes DASH-ADM-PLANNING et DASH-ADM-INC, `DASH_STRATEGIE.md` §5, décidé par
délégation le 05/10, DIR-REP-1 et D9).

**État** : présent dans le code et testé localement (`flutter test`, 320 px, texte ×2,
LTR et RTL), frontend seulement. Ni staging ni déploiement. En production chaque port
vaut `null` : la page dit « Disponible au branchement serveur », sans rien inventer ;
la démonstration (hors production) porte les données.

| Code | Écran | Rôle | Niv. | Prof. | Route | Mobile | Desktop | État |
| :--- | :--- | :--- | :-: | :-: | :--- | :--- | :--- | :--- |
| `ADM-PLAN` | Planning de la semaine | Direction | E | 1 | `/admin/operations/planning` | Barre semaine précédente / suivante, un jour par section, lignes fines | Idem, colonne bornée | **construit (11/10)**, port `PortPlanningDirection` (`lib/core/admin/port_planning_direction.dart`), démo `planning_incidents_demo.dart` |
| `ADM-INC` | Incidents des 24 dernières heures | Direction | E | 1 | `/admin/securite-audit/incidents` | Une carte à lignes fines | Idem, colonne bornée | **construit (11/10)**, port `PortIncidentsSeances`, lecture serveur au BR-1 |

## ADM-PLAN : Planning

- **Tâche** : voir d'un coup d'œil les séances de la semaine, toutes classes confondues.
- **Contenu** : barre `BarrePrecedentSuivant` (« Semaine du lundi 12 octobre 2026 ») et
  lien « Revenir à cette semaine » hors de la semaine en cours ; par jour qui a des
  séances, un `SectionHeader` (date, nombre de séances) et une `CarteLignes` ; chaque
  ligne dit la classe (nom distinct, R16), l'horaire, l'enseignant ou « Sans
  enseignant », et l'état en pastille (jamais la couleur seule ; « En direct » et
  « Annulée » par `PastilleEtatSeance`).
- **Aucune action** : un rapport, aucun bouton grisé, aucun bouton plein.
- **Entrée** : ligne « Planning de la semaine » des raccourcis de l'Accueil (domaine
  Opérations conservé).
- **États** : chargement (`Skeleton.liste`), contenu, vide (« Aucune séance cette
  semaine »), erreur (`EtatSysteme`, « Réessayer »), hors ligne (bandeau de `PageShell` ;
  `EtatSansDonnees` si rien n'a pu être lu), port absent (`CapaciteIndisponible`).
- **Contrat serveur à demander** : lecture des séances dont le début tombe dans une
  semaine (lundi 00 h au lundi suivant), avec nom de la classe, enseignant éventuel,
  début, durée, statut.

## ADM-INC : Incidents des 24 dernières heures

- **Pourquoi pas le Journal** : la tuile « Incidents (24 h) » compte des **séances** au
  statut incident technique, enseignant absent ou élève absent mises à jour depuis 24 h
  (migration 0015), pas des entrées du journal d'audit. Un lien vers le Journal ne
  montrerait pas le chiffre de la tuile (D9). La page liste donc ces séances.
- **Contenu** : une `CarteLignes`, plus récent d'abord ; chaque ligne dit la classe, quand
  l'incident est survenu, l'enseignant ou « Sans enseignant », et sa nature en pastille.
- **Entrée** : le chiffre « Incidents (24 h) » de la tuile double devient un lien ; « Accès
  échus » reste un lien vers Comptes (DASH-ADM-ECHUS).
- **États** : les mêmes cinq que ADM-PLAN.
- **Contrat serveur à demander (BR-1)** : lecture de ces séances sur 24 h, même critère
  que le compteur.
