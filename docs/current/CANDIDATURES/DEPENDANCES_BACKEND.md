# CANDIDATURES · Dépendances backend (non traitées, non livrées)

Statut : `spécifié` seulement, **proposition non décidée**. Rien ci-dessous n'existe
côté serveur. Tant qu'un besoin manque, le port correspondant rend
`CapaciteIndisponible('CAND-BR-nn')` en production et l'écran le dit. Aucun besoin
ne se construit avant la question du directeur qu'il cite
(`REVUE_CRITIQUE_CANDIDATURES_2026-10-21.md`, section 9), et aucun sans le feu vert
de `CAND-Q02` (lot backend sur la base de test).

| # | Besoin | Écran qui l'attend | Méthode (`CONTRAT_PORTS_CANDIDATURES.md`) | Question |
| :--- | :--- | :--- | :--- | :--- |
| `CAND-BR-01` | Tables candidature, type de candidature, réponses versionnées par questionnaire, décisions, entretiens ; RLS : le candidat ne lit que sa candidature, la direction selon son genre | tous | tous | `CAND-Q02`, `CAND-Q07` |
| `CAND-BR-02` | Liste paginée au serveur, filtres, tri, compteurs d'étapes et des quatre alertes, recherche (nom partiel, référence exacte, contact exact réservé) | `ADM-20` | `lister` | `CAND-Q04`, `CAND-Q20` |
| `CAND-BR-03` | Détail, contrôles nommés calculés en base, lecture du contact journalisée | `ADM-21` | `lire`, `lireContact` | `CAND-Q07` |
| `CAND-BR-04` | Une RPC par geste, motivée quand il le faut, journalisée ; `confirmer` sous les huit contrôles | `ADM-21`, `ADM-22` | `geste` | `CAND-Q01`, `CAND-Q03` |
| `CAND-BR-05` | Modification de `decider_dossier()` pour le rôle enseignant et garde d'activation étendue aux huit contrôles | ADM-02, `ADM-21` | `geste(confirmer)` | `CAND-Q01`, `CAND-Q18` |
| `CAND-BR-06` | Lot : aperçu avec éligibles et exclus motivés, exécution ligne par ligne, idempotence, issue inconnue honnête | `ADM-22` | `preparerLot`, `executerLot` | - |
| `CAND-BR-07` | Historique d'une candidature (modèle `historique_classe`), sans nom dans le journal | `ADM-21` | `historique` | - |
| `CAND-BR-08` | Entretiens : planification, issue, compte rendu, constat de niveau ; et, si voie 2, type de séance `entretien`, rôles de participants, jeton pour un candidat convoqué, exclusions (paie, clôture, vues, mention de contrôle) | `ADM-20` (vue Entretiens), `CAND-02` | `planifierEntretien`, `consignerEntretien` | `CAND-Q06`, `CAND-Q08`, `CAND-Q19` |
| `CAND-BR-09` | Import « candidatures » : analyse serveur, essai à blanc, confirmation idempotente par référence source, aal2 exigée en base, formulaire B rendu « déjà connu » | `ADM-23` | `analyser`, `essaiABlanc`, `confirmer` | `CAND-Q03`, `CAND-Q16`, `CAND-Q17` |
| `CAND-BR-10` | `etat_dossier()` étendu (à compléter, en examen, entretien, pause, refusée par modèle, retirée), questionnaire versionné, envoi des réponses, retrait | `/attente`, `CAND-01` à `CAND-03` | `PortMaCandidature` | `CAND-Q01`, `CAND-Q03`, `CAND-Q18` |
| `CAND-BR-11` | Sorte d'accord pour l'engagement, version requise, insertion autorisée à un compte `pending_kyc` invité | page d'accords | (mécanisme existant) | `CAND-Q11` |
| `CAND-BR-12` | Conditions de rémunération lues dans la politique de paie, pour un compte en attente | `CAND-01` | `conditionsRemuneration` | - |
| `CAND-BR-13` | Référentiel de compatibilité de paiement, ses droits (direction et comptabilité), l'alerte sur les confirmées concernées, et la source de `CPT-BR-10` | `ADM-24`, `CAND-01` | `PortReferentielPaiement` | `CAND-Q05` |
| `CAND-BR-14` | Conservation, anonymisation, copie des données et suppression pour les candidatures | - | - | `CAND-Q21` |
| `CAND-BR-15` | Scénarios `T/scenarios_candidatures.sql`, et leur ajout à `.github/workflows/ci.yml` par la direction (zone interdite aux agents) | - | - | - |

Aucune migration, RPC, RLS ni adaptateur `*_supabase.dart` n'a été écrit dans ce lot.
