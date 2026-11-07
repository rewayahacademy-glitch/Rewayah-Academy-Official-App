# Liste WEB-BUREAU : 66 / 309 lignes vertes

Rapport : `docs/current/captures/E2E/WEB-BUREAU/liste-avant/rapport.json` (2026-11-06T17:08:49.222Z).
B1 barre laterale, B3 fil, B5 boutons etires : definition `docs/current/DEFINITION-PAGE-ORDINATEUR-2026-11-06.md`.
B4, B6, B7 (lecture, tete, pied) : mesures par le garde-fou Flutter, pas encore ici.

| Role | Lignes | Vertes |
|---|---|---|
| comptabilite | 31 | 9 |
| controle | 23 | 7 |
| direction | 85 | 0 |
| eleve | 29 | 8 |
| enseignant | 35 | 8 |
| famille | 76 | 6 |
| visiteur | 30 | 28 |

## comptabilite

| Route | Obtenue a 1440 | Sortie 1440 | Sortie 390 | B1 | B3 | B5 | Verdict |
|---|---|---|---|---|---|---|---|
| `/comptable` | `/comptable` | colonne-dessinee | barre | oui | non | 0 | vert |
| `/comptable/paiements` | `/comptable/paiements` | colonne-dessinee | barre | oui | non | 0 | vert |
| `/comptable/paiements/beneficiaires` | `/comptable/paiements/beneficiaires` | colonne-dessinee | barre | oui | non | 0 | **rouge** : B3 pas de fil |
| `/comptable/paiements/beneficiaires/:beneficiaireId` | `/comptable/paiements/beneficiaires/:id` | retour | retour | oui | non | 0 | **rouge** : B3 pas de fil |
| `/comptable/paiements/beneficiaires/:beneficiaireId/fil` | `/comptable/paiements/beneficiaires/:id/fil` | retour | retour | oui | non | 0 | **rouge** : B3 pas de fil |
| `/comptable/paiements/contractuels` | `/comptable/paiements/contractuels` | colonne-dessinee | barre | oui | non | 0 | **rouge** : B3 pas de fil |
| `/comptable/paiements/contractuels/nouvelle` | `/comptable/paiements/contractuels/nouvelle` | retour | retour | oui | non | 0 | **rouge** : B3 pas de fil |
| `/comptable/paiements/contractuels/obligation/:obligationId` | `/comptable/paiements/contractuels/obligation/:id` | retour | retour | oui | non | 0 | **rouge** : B3 pas de fil |
| `/comptable/paiements/obligation/:obligationId` | `/comptable/paiements/obligation/:id` | retour | retour | oui | non | 1 | **rouge** : B3 pas de fil, B5 1 bouton(s) etire(s) |
| `/comptable/tresorerie` | `/comptable/tresorerie` | colonne | barre | oui | non | 0 | vert |
| `/comptable/tresorerie/encaissements` | `/comptable/tresorerie/encaissements` | colonne-dessinee | barre | oui | non | 0 | **rouge** : B3 pas de fil |
| `/comptable/tresorerie/encaissements/:encaissementId` | `/comptable/tresorerie/encaissements/:id` | retour | retour | oui | non | 0 | **rouge** : B3 pas de fil |
| `/comptable/tresorerie/paiements-familles` | `/comptable/tresorerie/paiements-familles` | retour | retour | oui | non | 3 | **rouge** : B3 pas de fil, B5 3 bouton(s) etire(s) |
| `/comptable/tresorerie/rapports` | `/comptable/tresorerie/rapports` | colonne-dessinee | barre | oui | non | 2 | **rouge** : B3 pas de fil, B5 2 bouton(s) etire(s) |
| `/comptable/tresorerie/rapprochement` | `/comptable/tresorerie/rapprochement` | colonne-dessinee | barre | oui | non | 0 | **rouge** : B3 pas de fil |
| `/compte` | `/compte` | colonne | barre | oui | non | 6 | **rouge** : B5 6 bouton(s) etire(s) |
| `/compte/langue-courriels` | `/compte/langue-courriels` | retour | retour | oui | non | 0 | **rouge** : B3 pas de fil |
| `/compte/mes-donnees` | `/compte/mes-donnees` | retour | retour | oui | non | 0 | **rouge** : B3 pas de fil |
| `/compte/paiements-recus` | `/compte/paiements-recus` | retour | retour | oui | non | 0 | **rouge** : B3 pas de fil |
| `/compte/profil` | `/compte/profil` | colonne | barre | oui | non | 7 | **rouge** : B3 pas de fil, B5 7 bouton(s) etire(s) |
| `/compte/profils` | `/compte/profils` | colonne | barre | oui | non | 0 | **rouge** : B3 pas de fil |
| `/compte/profils/:profilId` | `/compte/profils/:id` | colonne | barre | oui | non | 0 | **rouge** : B3 pas de fil |
| `/compte/reglages` | `/compte/reglages` | colonne | barre | oui | non | 5 | **rouge** : B3 pas de fil, B5 5 bouton(s) etire(s) |
| `/compte/securite` | `/compte/securite` | retour | retour | oui | non | 1 | **rouge** : B3 pas de fil, B5 1 bouton(s) etire(s) |
| `/recherche` | `/recherche` | retour | retour | oui | non | 0 | **rouge** : B3 pas de fil |
| `/tc/bibliotheque` | `/comptable` | colonne-dessinee | barre | oui | non | 0 | vert |
| `/tc/bibliotheque/:resourceId` | `/comptable` | colonne-dessinee | barre | oui | non | 0 | vert |
| `/tc/groupes` | `/comptable` | colonne-dessinee | barre | oui | non | 0 | vert |
| `/tc/groupes/:groupeId` | `/comptable` | colonne-dessinee | barre | oui | non | 0 | vert |
| `/tc/mushaf` | `/comptable` | colonne-dessinee | barre | oui | non | 0 | vert |
| `/tc/observation/:seanceId` | `/comptable` | colonne-dessinee | barre | oui | non | 0 | vert |

## controle

| Route | Obtenue a 1440 | Sortie 1440 | Sortie 390 | B1 | B3 | B5 | Verdict |
|---|---|---|---|---|---|---|---|
| `/compte` | `/compte` | colonne | barre | oui | non | 6 | **rouge** : B5 6 bouton(s) etire(s) |
| `/compte/langue-courriels` | `/compte/langue-courriels` | retour | retour | oui | non | 0 | **rouge** : B3 pas de fil |
| `/compte/mes-donnees` | `/compte/mes-donnees` | retour | retour | oui | non | 0 | **rouge** : B3 pas de fil |
| `/compte/paiements-recus` | `/compte/paiements-recus` | retour | retour | oui | non | 0 | **rouge** : B3 pas de fil |
| `/compte/profil` | `/compte/profil` | colonne | barre | oui | non | 7 | **rouge** : B3 pas de fil, B5 7 bouton(s) etire(s) |
| `/compte/profils` | `/compte/profils` | colonne | barre | oui | non | 0 | **rouge** : B3 pas de fil |
| `/compte/profils/:profilId` | `/compte/profils/:id` | colonne | barre | oui | non | 0 | **rouge** : B3 pas de fil |
| `/compte/reglages` | `/compte/reglages` | colonne | barre | oui | non | 5 | **rouge** : B3 pas de fil, B5 5 bouton(s) etire(s) |
| `/compte/securite` | `/compte/securite` | retour | retour | oui | non | 0 | **rouge** : B3 pas de fil |
| `/controleur` | `/controleur` | colonne-dessinee | barre | oui | non | 0 | vert |
| `/controleur/compte-rendu` | `/controleur/compte-rendu` | AUCUNE | AUCUNE | non | non | 0 | **rouge** : sans sortie a 1440, sans sortie a 390, B1 pas de barre laterale, B3 pas de fil |
| `/controleur/compte-rendu/observation` | `/controleur/compte-rendu/observation` | AUCUNE | AUCUNE | non | non | 0 | **rouge** : sans sortie a 1440, sans sortie a 390, B1 pas de barre laterale, B3 pas de fil |
| `/controleur/echanges` | `/controleur/echanges` | colonne-dessinee | barre | oui | non | 1 | **rouge** : B5 1 bouton(s) etire(s) |
| `/controleur/historique` | `/controleur/historique` | colonne-dessinee | barre | oui | non | 1 | **rouge** : B5 1 bouton(s) etire(s) |
| `/controleur/mfa` | `/controleur` | colonne-dessinee | barre | oui | non | 0 | vert |
| `/controleur/notifications` | `/controleur/notifications` | retour | retour | oui | non | 0 | **rouge** : B3 pas de fil |
| `/recherche` | `/recherche` | retour | retour | oui | non | 0 | **rouge** : B3 pas de fil |
| `/tc/bibliotheque` | `/controleur` | colonne-dessinee | barre | oui | non | 0 | vert |
| `/tc/bibliotheque/:resourceId` | `/controleur` | colonne-dessinee | barre | oui | non | 0 | vert |
| `/tc/groupes` | `/controleur` | colonne-dessinee | barre | oui | non | 0 | vert |
| `/tc/groupes/:groupeId` | `/controleur` | colonne-dessinee | barre | oui | non | 0 | vert |
| `/tc/mushaf` | `/controleur` | colonne-dessinee | barre | oui | non | 0 | vert |
| `/tc/observation/:seanceId` | `/tc/observation/:id` | AUCUNE | AUCUNE | non | non | 1 | **rouge** : sans sortie a 1440, sans sortie a 390, B1 pas de barre laterale, B3 pas de fil, B5 1 bouton(s) etire(s) |

## direction

| Route | Obtenue a 1440 | Sortie 1440 | Sortie 390 | B1 | B3 | B5 | Verdict |
|---|---|---|---|---|---|---|---|
| `/admin` | `/admin` | colonne | barre | oui | non | 11 | **rouge** : B5 11 bouton(s) etire(s) |
| `/admin/acces-agents` | `/admin/securite-audit/acces-agents` | retour | retour | oui | non | 0 | **rouge** : B3 pas de fil |
| `/admin/alertes` | `/admin/alertes` | retour | retour | oui | non | 0 | **rouge** : B3 pas de fil |
| `/admin/attribution` | `/admin/operations/regroupements` | colonne | barre | oui | non | 0 | **rouge** : B3 pas de fil |
| `/admin/comptes` | `/admin/personnes/comptes` | colonne | barre | oui | non | 2 | **rouge** : B3 pas de fil, B5 2 bouton(s) etire(s) |
| `/admin/configuration` | `/admin/configuration/regles` | retour | retour | oui | non | 18 | **rouge** : B3 pas de fil, B5 18 bouton(s) etire(s) |
| `/admin/configuration/conservation-donnees` | `/admin/configuration/conservation-donnees` | retour | retour | oui | non | 3 | **rouge** : B3 pas de fil, B5 3 bouton(s) etire(s) |
| `/admin/configuration/fonctionnalites` | `/admin/configuration/fonctionnalites` | retour | retour | oui | non | 1 | **rouge** : B3 pas de fil, B5 1 bouton(s) etire(s) |
| `/admin/configuration/politique-revue-kyc` | `/admin/configuration/politique-revue-kyc` | retour | retour | oui | non | 0 | **rouge** : B3 pas de fil |
| `/admin/configuration/protection-enfants` | `/admin/configuration/protection-enfants` | retour | retour | oui | non | 3 | **rouge** : B3 pas de fil, B5 3 bouton(s) etire(s) |
| `/admin/configuration/regles` | `/admin/configuration/regles` | retour | retour | oui | non | 18 | **rouge** : B3 pas de fil, B5 18 bouton(s) etire(s) |
| `/admin/demandes` | `/admin/operations/demandes` | retour | retour | oui | non | 0 | **rouge** : B3 pas de fil |
| `/admin/dossiers` | `/admin/personnes/dossiers` | colonne | barre | oui | non | 1 | **rouge** : B3 pas de fil, B5 1 bouton(s) etire(s) |
| `/admin/finance` | `/admin/finance` | retour | retour | oui | non | 1 | **rouge** : B5 1 bouton(s) etire(s) |
| `/admin/finance/a-valider` | `/admin/finance/a-valider` | retour | retour | oui | non | 1 | **rouge** : B3 pas de fil, B5 1 bouton(s) etire(s) |
| `/admin/finance/paie` | `/admin/finance/paie` | retour | retour | oui | non | 1 | **rouge** : B3 pas de fil, B5 1 bouton(s) etire(s) |
| `/admin/finance/paie/obligation/:obligationId` | `/admin/finance/paie/obligation/:id` | retour | retour | oui | non | 1 | **rouge** : B3 pas de fil, B5 1 bouton(s) etire(s) |
| `/admin/finance/paiements` | `/admin/finance/paiements` | retour | retour | oui | non | 3 | **rouge** : B3 pas de fil, B5 3 bouton(s) etire(s) |
| `/admin/finance/politiques` | `/admin/finance/politiques` | retour | retour | oui | non | 1 | **rouge** : B3 pas de fil, B5 1 bouton(s) etire(s) |
| `/admin/finance/reserve-delegation` | `/admin/finance/reserve-delegation` | retour | retour | oui | non | 1 | **rouge** : B3 pas de fil, B5 1 bouton(s) etire(s) |
| `/admin/journal` | `/admin/securite-audit/journal` | retour | retour | oui | non | 0 | **rouge** : B3 pas de fil |
| `/admin/notifications` | `/admin/notifications` | retour | retour | oui | non | 0 | **rouge** : B3 pas de fil |
| `/admin/operations` | `/admin/operations/traitement` | colonne | barre | oui | non | 0 | **rouge** : B3 pas de fil |
| `/admin/operations/avis` | `/admin/operations/avis` | retour | retour | oui | non | 0 | **rouge** : B3 pas de fil |
| `/admin/operations/communications` | `/admin/operations/communications/annonces` | retour | retour | oui | non | 0 | **rouge** : B3 pas de fil |
| `/admin/operations/communications/annonces` | `/admin/operations/communications/annonces` | retour | retour | oui | non | 0 | **rouge** : B3 pas de fil |
| `/admin/operations/communications/messages` | `/admin/operations/communications/messages` | retour | retour | oui | non | 0 | **rouge** : B3 pas de fil |
| `/admin/operations/communications/messages/:filId` | `/admin/operations/communications/messages/:id` | retour | retour | oui | non | 0 | **rouge** : B3 pas de fil |
| `/admin/operations/communications/moderation` | `/admin/operations/communications/moderation` | retour | retour | oui | non | 0 | **rouge** : B3 pas de fil |
| `/admin/operations/courriels` | `/admin/operations/courriels` | retour | retour | oui | non | 1 | **rouge** : B3 pas de fil, B5 1 bouton(s) etire(s) |
| `/admin/operations/demandes` | `/admin/operations/demandes` | retour | retour | oui | non | 0 | **rouge** : B3 pas de fil |
| `/admin/operations/groupes` | `/admin/operations/groupes` | colonne | barre | oui | non | 1 | **rouge** : B3 pas de fil, B5 1 bouton(s) etire(s) |
| `/admin/operations/groupes/:groupeId` | `/admin/operations/groupes/:id` | retour | retour | oui | non | 2 | **rouge** : B3 pas de fil, B5 2 bouton(s) etire(s) |
| `/admin/operations/offres` | `/admin/operations/offres` | retour | retour | oui | non | 1 | **rouge** : B3 pas de fil, B5 1 bouton(s) etire(s) |
| `/admin/operations/pilotage` | `/admin/operations/pilotage` | retour | retour | oui | non | 0 | **rouge** : B3 pas de fil |
| `/admin/operations/planning` | `/admin/operations/planning` | retour | retour | oui | non | 0 | **rouge** : B3 pas de fil |
| `/admin/operations/regroupements` | `/admin/operations/regroupements` | colonne | barre | oui | non | 0 | **rouge** : B3 pas de fil |
| `/admin/operations/traitement` | `/admin/operations/traitement` | colonne | barre | oui | non | 0 | **rouge** : B3 pas de fil |
| `/admin/pedagogie` | `/admin/pedagogie/diagnostics` | retour | retour | oui | non | 0 | **rouge** : B3 pas de fil |
| `/admin/pedagogie/bibliotheque` | `/admin/pedagogie/bibliotheque` | retour | retour | oui | non | 0 | **rouge** : B3 pas de fil |
| `/admin/pedagogie/bibliotheque/:supportId` | `/admin/pedagogie/bibliotheque/:id` | retour | retour | oui | non | 1 | **rouge** : B3 pas de fil, B5 1 bouton(s) etire(s) |
| `/admin/pedagogie/bibliotheque/:supportId/attribution` | `/admin/pedagogie/bibliotheque/:id/attribution` | retour | retour | oui | non | 1 | **rouge** : B3 pas de fil, B5 1 bouton(s) etire(s) |
| `/admin/pedagogie/bibliotheque/:supportId/publication` | `/admin/pedagogie/bibliotheque/:id/publication` | retour | retour | oui | non | 1 | **rouge** : B3 pas de fil, B5 1 bouton(s) etire(s) |
| `/admin/pedagogie/bibliotheque/nouveau` | `/admin/pedagogie/bibliotheque/nouveau` | retour | retour | oui | non | 2 | **rouge** : B3 pas de fil, B5 2 bouton(s) etire(s) |
| `/admin/pedagogie/diagnostics` | `/admin/pedagogie/diagnostics` | retour | retour | oui | non | 0 | **rouge** : B3 pas de fil |
| `/admin/pedagogie/evaluations` | `/admin/pedagogie/evaluations` | retour | retour | oui | non | 1 | **rouge** : B3 pas de fil, B5 1 bouton(s) etire(s) |
| `/admin/pedagogie/programmes` | `/admin/pedagogie/programmes` | retour | retour | oui | non | 1 | **rouge** : B3 pas de fil, B5 1 bouton(s) etire(s) |
| `/admin/pedagogie/progression` | `/admin/pedagogie/progression` | retour | retour | oui | non | 1 | **rouge** : B3 pas de fil, B5 1 bouton(s) etire(s) |
| `/admin/pedagogie/qualite` | `/admin/pedagogie/qualite` | retour | retour | oui | non | 0 | **rouge** : B3 pas de fil |
| `/admin/personnes` | `/admin/personnes/dossiers` | colonne | barre | oui | non | 1 | **rouge** : B3 pas de fil, B5 1 bouton(s) etire(s) |
| `/admin/personnes/candidatures` | `/admin/personnes/candidatures` | retour | retour | oui | non | 1 | **rouge** : B3 pas de fil, B5 1 bouton(s) etire(s) |
| `/admin/personnes/candidatures/:reference` | `/admin/personnes/candidatures/:id` | retour | retour | oui | non | 0 | **rouge** : B3 pas de fil |
| `/admin/personnes/comptes` | `/admin/personnes/comptes` | colonne | barre | oui | non | 2 | **rouge** : B3 pas de fil, B5 2 bouton(s) etire(s) |
| `/admin/personnes/demandes` | `/admin/personnes/demandes` | retour | retour | oui | non | 1 | **rouge** : B3 pas de fil, B5 1 bouton(s) etire(s) |
| `/admin/personnes/dossiers` | `/admin/personnes/dossiers` | colonne | barre | oui | non | 1 | **rouge** : B3 pas de fil, B5 1 bouton(s) etire(s) |
| `/admin/personnes/import` | `/admin/personnes/import` | retour | retour | oui | non | 2 | **rouge** : B3 pas de fil, B5 2 bouton(s) etire(s) |
| `/admin/personnes/invitations` | `/admin/personnes/invitations` | retour | retour | oui | non | 2 | **rouge** : B3 pas de fil, B5 2 bouton(s) etire(s) |
| `/admin/personnes/reprises` | `/admin/personnes/reprises` | retour | retour | oui | non | 1 | **rouge** : B3 pas de fil, B5 1 bouton(s) etire(s) |
| `/admin/personnes/suppressions` | `/admin/personnes/suppressions` | retour | retour | oui | non | 1 | **rouge** : B3 pas de fil, B5 1 bouton(s) etire(s) |
| `/admin/securite-audit` | `/admin/securite-audit/journal` | retour | retour | oui | non | 0 | **rouge** : B3 pas de fil |
| `/admin/securite-audit/acces-agents` | `/admin/securite-audit/acces-agents` | retour | retour | oui | non | 0 | **rouge** : B3 pas de fil |
| `/admin/securite-audit/incidents` | `/admin/securite-audit/incidents` | retour | retour | oui | non | 0 | **rouge** : B3 pas de fil |
| `/admin/securite-audit/journal` | `/admin/securite-audit/journal` | retour | retour | oui | non | 0 | **rouge** : B3 pas de fil |
| `/admin/securite-audit/observations` | `/admin/securite-audit/observations` | retour | retour | oui | non | 0 | **rouge** : B3 pas de fil |
| `/admin/securite-audit/tirages` | `/admin/securite-audit/tirages` | retour | retour | oui | non | 0 | **rouge** : B3 pas de fil |
| `/admin/studio` | `/admin/studio` | retour | retour | oui | non | 0 | **rouge** : B3 pas de fil |
| `/admin/studio/canaux` | `/admin/studio` | retour | retour | oui | non | 0 | **rouge** : B3 pas de fil |
| `/admin/studio/canaux/:canalId` | `/admin/studio/canaux/:id` | retour | retour | oui | non | 0 | **rouge** : B3 pas de fil |
| `/admin/tableau-de-bord` | `/admin` | colonne | barre | oui | non | 11 | **rouge** : B5 11 bouton(s) etire(s) |
| `/compte` | `/compte` | retour | retour | oui | non | 7 | **rouge** : B5 7 bouton(s) etire(s) |
| `/compte/langue-courriels` | `/compte/langue-courriels` | retour | retour | oui | non | 0 | **rouge** : B3 pas de fil |
| `/compte/mes-donnees` | `/compte/mes-donnees` | retour | retour | oui | non | 0 | **rouge** : B3 pas de fil |
| `/compte/paiements-recus` | `/compte/paiements-recus` | retour | retour | oui | non | 0 | **rouge** : B3 pas de fil |
| `/compte/profil` | `/compte/profil` | retour | retour | oui | non | 7 | **rouge** : B3 pas de fil, B5 7 bouton(s) etire(s) |
| `/compte/profils` | `/compte/profils` | retour | retour | oui | non | 0 | **rouge** : B3 pas de fil |
| `/compte/profils/:profilId` | `/compte/profils/:id` | retour | retour | oui | non | 0 | **rouge** : B3 pas de fil |
| `/compte/reglages` | `/compte/reglages` | retour | retour | oui | non | 5 | **rouge** : B3 pas de fil, B5 5 bouton(s) etire(s) |
| `/compte/securite` | `/compte/securite` | retour | retour | oui | non | 1 | **rouge** : B3 pas de fil, B5 1 bouton(s) etire(s) |
| `/recherche` | `/recherche` | retour | retour | oui | non | 0 | **rouge** : B3 pas de fil |
| `/tc/bibliotheque` | `/admin` | colonne | barre | oui | non | 11 | **rouge** : B5 11 bouton(s) etire(s) |
| `/tc/bibliotheque/:resourceId` | `/admin` | colonne | barre | oui | non | 11 | **rouge** : B5 11 bouton(s) etire(s) |
| `/tc/groupes` | `/admin` | colonne | barre | oui | non | 11 | **rouge** : B5 11 bouton(s) etire(s) |
| `/tc/groupes/:groupeId` | `/admin` | colonne | barre | oui | non | 11 | **rouge** : B5 11 bouton(s) etire(s) |
| `/tc/mushaf` | `/admin` | colonne | barre | oui | non | 11 | **rouge** : B5 11 bouton(s) etire(s) |
| `/tc/observation/:seanceId` | `/tc/observation/:id` | AUCUNE | AUCUNE | non | non | 1 | **rouge** : sans sortie a 1440, sans sortie a 390, B1 pas de barre laterale, B3 pas de fil, B5 1 bouton(s) etire(s) |

## eleve

| Route | Obtenue a 1440 | Sortie 1440 | Sortie 390 | B1 | B3 | B5 | Verdict |
|---|---|---|---|---|---|---|---|
| `/compte` | `/compte` | colonne | barre | oui | non | 6 | **rouge** : B5 6 bouton(s) etire(s) |
| `/compte/langue-courriels` | `/compte/langue-courriels` | retour | retour | oui | non | 0 | **rouge** : B3 pas de fil |
| `/compte/mes-donnees` | `/compte/mes-donnees` | retour | retour | oui | non | 0 | **rouge** : B3 pas de fil |
| `/compte/paiements-recus` | `/compte/paiements-recus` | retour | retour | oui | non | 0 | **rouge** : B3 pas de fil |
| `/compte/profil` | `/compte/profil` | colonne | barre | oui | non | 6 | **rouge** : B3 pas de fil, B5 6 bouton(s) etire(s) |
| `/compte/profils` | `/compte/profils` | colonne | barre | oui | non | 1 | **rouge** : B3 pas de fil, B5 1 bouton(s) etire(s) |
| `/compte/profils/:profilId` | `/compte/profils/:id` | colonne | barre | oui | non | 5 | **rouge** : B3 pas de fil, B5 5 bouton(s) etire(s) |
| `/compte/reglages` | `/compte/reglages` | colonne | barre | oui | non | 5 | **rouge** : B3 pas de fil, B5 5 bouton(s) etire(s) |
| `/compte/securite` | `/compte/securite` | retour | retour | oui | non | 1 | **rouge** : B3 pas de fil, B5 1 bouton(s) etire(s) |
| `/eleve` | `/eleve` | colonne-dessinee | barre | oui | non | 0 | vert |
| `/eleve/adulte` | `/eleve/adulte` | colonne-dessinee | barre | oui | non | 0 | **rouge** : B3 pas de fil |
| `/eleve/adulte/classe` | `/eleve/adulte/classe` | colonne-dessinee | barre | oui | non | 0 | **rouge** : B3 pas de fil |
| `/eleve/adulte/demandes` | `/eleve/adulte/demandes` | retour | retour | oui | non | 0 | **rouge** : B3 pas de fil |
| `/eleve/adulte/demandes/:demandeId` | `/eleve/adulte/demandes/:id` | retour | retour | oui | non | 0 | **rouge** : B3 pas de fil |
| `/eleve/adulte/seances` | `/eleve/adulte/seances` | retour | retour | oui | non | 0 | **rouge** : B3 pas de fil |
| `/eleve/aide` | `/eleve/aide` | retour | retour | oui | non | 0 | **rouge** : B3 pas de fil |
| `/eleve/coran` | `/eleve/coran` | colonne-dessinee | barre | oui | non | 0 | vert |
| `/eleve/finances` | `/eleve` | colonne-dessinee | barre | oui | non | 0 | vert |
| `/eleve/finances/mouvements` | `/eleve` | colonne-dessinee | barre | oui | non | 0 | vert |
| `/eleve/finances/prix` | `/eleve` | colonne-dessinee | barre | oui | non | 0 | vert |
| `/eleve/notifications` | `/eleve` | colonne-dessinee | barre | oui | non | 0 | vert |
| `/eleve/suivi` | `/eleve/suivi` | colonne-dessinee | barre | oui | non | 0 | vert |
| `/recherche` | `/recherche` | retour | retour | oui | non | 0 | **rouge** : B3 pas de fil |
| `/tc/bibliotheque` | `/tc/bibliotheque` | AUCUNE | AUCUNE | non | non | 0 | **rouge** : sans sortie a 1440, sans sortie a 390, B1 pas de barre laterale, B3 pas de fil |
| `/tc/bibliotheque/:resourceId` | `/tc/bibliotheque/:id` | retour | retour | non | non | 0 | **rouge** : B1 pas de barre laterale, B3 pas de fil |
| `/tc/groupes` | `/tc/groupes` | AUCUNE | AUCUNE | non | non | 0 | **rouge** : sans sortie a 1440, sans sortie a 390, B1 pas de barre laterale, B3 pas de fil |
| `/tc/groupes/:groupeId` | `/tc/groupes/:id` | AUCUNE | AUCUNE | non | non | 0 | **rouge** : sans sortie a 1440, sans sortie a 390, B1 pas de barre laterale, B3 pas de fil |
| `/tc/mushaf` | `/tc/mushaf` | AUCUNE | AUCUNE | non | non | 0 | **rouge** : sans sortie a 1440, sans sortie a 390, B1 pas de barre laterale, B3 pas de fil |
| `/tc/observation/:seanceId` | `/eleve` | colonne-dessinee | barre | oui | non | 0 | vert |

## enseignant

| Route | Obtenue a 1440 | Sortie 1440 | Sortie 390 | B1 | B3 | B5 | Verdict |
|---|---|---|---|---|---|---|---|
| `/compte` | `/compte` | colonne | barre | oui | non | 7 | **rouge** : B5 7 bouton(s) etire(s) |
| `/compte/langue-courriels` | `/compte/langue-courriels` | retour | retour | oui | non | 0 | **rouge** : B3 pas de fil |
| `/compte/mes-donnees` | `/compte/mes-donnees` | retour | retour | oui | non | 1 | **rouge** : B3 pas de fil, B5 1 bouton(s) etire(s) |
| `/compte/paiements-recus` | `/compte/paiements-recus` | retour | retour | oui | non | 0 | **rouge** : B3 pas de fil |
| `/compte/profil` | `/compte/profil` | colonne | barre | oui | non | 7 | **rouge** : B3 pas de fil, B5 7 bouton(s) etire(s) |
| `/compte/profils` | `/compte/profils` | colonne | barre | oui | non | 0 | **rouge** : B3 pas de fil |
| `/compte/profils/:profilId` | `/compte/profils/:id` | colonne | barre | oui | non | 0 | **rouge** : B3 pas de fil |
| `/compte/reglages` | `/compte/reglages` | colonne | barre | oui | non | 5 | **rouge** : B3 pas de fil, B5 5 bouton(s) etire(s) |
| `/compte/securite` | `/compte/securite` | retour | retour | oui | non | 1 | **rouge** : B3 pas de fil, B5 1 bouton(s) etire(s) |
| `/enseignant/bienvenue` | `/enseignant/bienvenue` | AUCUNE | barre-dessinee | non | non | 2 | **rouge** : sans sortie a 1440, B1 pas de barre laterale, B3 pas de fil, B5 2 bouton(s) etire(s) |
| `/enseignant/classes` | `/enseignant/classes` | colonne-dessinee | barre | oui | non | 1 | **rouge** : B5 1 bouton(s) etire(s) |
| `/enseignant/communaute` | `/enseignant/communaute` | retour | retour | oui | non | 0 | **rouge** : B3 pas de fil |
| `/enseignant/communaute/:publicationId` | `/enseignant/communaute/:id` | retour | barre | oui | non | 0 | **rouge** : B3 pas de fil |
| `/enseignant/contrat` | `/enseignant/journee` | colonne-dessinee | barre | oui | non | 0 | vert |
| `/enseignant/creneaux` | `/enseignant/creneaux` | colonne-dessinee | barre | oui | non | 0 | vert |
| `/enseignant/groupe/:groupeId` | `/enseignant/groupe/:id` | retour | retour | non | non | 0 | **rouge** : B1 pas de barre laterale, B3 pas de fil |
| `/enseignant/groupe/:groupeId/annonce` | `/enseignant/groupe/:id/annonce` | retour | retour | non | non | 0 | **rouge** : B1 pas de barre laterale, B3 pas de fil |
| `/enseignant/groupe/:groupeId/revue` | `/enseignant/groupe/:id/revue` | retour | retour | non | non | 0 | **rouge** : B1 pas de barre laterale, B3 pas de fil |
| `/enseignant/journee` | `/enseignant/journee` | colonne-dessinee | barre | oui | non | 0 | vert |
| `/enseignant/journee/a-terminer` | `/enseignant/journee/a-terminer` | retour | retour | oui | non | 0 | **rouge** : B3 pas de fil |
| `/enseignant/journee/alertes` | `/enseignant/journee/alertes` | retour | retour | oui | non | 0 | **rouge** : B3 pas de fil |
| `/enseignant/journee/remplacements` | `/enseignant/journee/remplacements` | retour | retour | oui | non | 0 | **rouge** : B3 pas de fil |
| `/enseignant/messages` | `/enseignant/messages` | retour | retour | oui | non | 0 | **rouge** : B3 pas de fil |
| `/enseignant/messages/:filId` | `/enseignant/messages/:id` | retour | retour | oui | non | 0 | **rouge** : B3 pas de fil |
| `/enseignant/notifications` | `/enseignant/notifications` | retour | retour | oui | non | 1 | **rouge** : B3 pas de fil, B5 1 bouton(s) etire(s) |
| `/enseignant/profil` | `/enseignant/profil` | colonne-dessinee | barre | oui | non | 0 | vert |
| `/enseignant/revenus` | `/enseignant/revenus` | retour | retour | oui | non | 0 | **rouge** : B3 pas de fil |
| `/enseignant/seance/:seanceId/cahier` | `/enseignant/seance/:id/cahier` | retour | retour | non | non | 0 | **rouge** : B1 pas de barre laterale, B3 pas de fil |
| `/recherche` | `/recherche` | retour | retour | oui | non | 0 | **rouge** : B3 pas de fil |
| `/tc/bibliotheque` | `/tc/bibliotheque` | AUCUNE | AUCUNE | non | non | 0 | **rouge** : sans sortie a 1440, sans sortie a 390, B1 pas de barre laterale, B3 pas de fil |
| `/tc/bibliotheque/:resourceId` | `/tc/bibliotheque/:id` | retour | retour | non | non | 0 | **rouge** : B1 pas de barre laterale, B3 pas de fil |
| `/tc/groupes` | `/enseignant/journee` | colonne-dessinee | barre | oui | non | 0 | vert |
| `/tc/groupes/:groupeId` | `/enseignant/journee` | colonne-dessinee | barre | oui | non | 0 | vert |
| `/tc/mushaf` | `/enseignant/journee` | colonne-dessinee | barre | oui | non | 0 | vert |
| `/tc/observation/:seanceId` | `/enseignant/journee` | colonne-dessinee | barre | oui | non | 0 | vert |

## famille

| Route | Obtenue a 1440 | Sortie 1440 | Sortie 390 | B1 | B3 | B5 | Verdict |
|---|---|---|---|---|---|---|---|
| `/compte` | `/tuteur/compte` | colonne-dessinee | barre | oui | non | 2 | **rouge** : B5 2 bouton(s) etire(s) |
| `/compte/langue-courriels` | `/compte/langue-courriels` | retour | retour | non | non | 0 | **rouge** : B1 pas de barre laterale, B3 pas de fil |
| `/compte/mes-donnees` | `/tuteur/compte/mes-donnees` | retour | retour | oui | non | 1 | **rouge** : B3 pas de fil, B5 1 bouton(s) etire(s) |
| `/compte/paiements-recus` | `/compte/paiements-recus` | retour | retour | non | non | 0 | **rouge** : B1 pas de barre laterale, B3 pas de fil |
| `/compte/profil` | `/tuteur/compte/informations` | retour | retour | oui | non | 0 | **rouge** : B3 pas de fil |
| `/compte/profils` | `/tuteur/foyer` | colonne-dessinee | barre | oui | non | 0 | vert |
| `/compte/profils/:profilId` | `/tuteur/foyer/:id` | retour | retour | oui | non | 6 | **rouge** : B3 pas de fil, B5 6 bouton(s) etire(s) |
| `/compte/reglages` | `/tuteur/compte/preferences` | retour | retour | oui | non | 2 | **rouge** : B3 pas de fil, B5 2 bouton(s) etire(s) |
| `/compte/securite` | `/tuteur/compte/securite` | retour | retour | oui | non | 0 | **rouge** : B3 pas de fil |
| `/recherche` | `/recherche` | retour | retour | oui | non | 0 | **rouge** : B3 pas de fil |
| `/tc/bibliotheque` | `/tc/bibliotheque` | AUCUNE | AUCUNE | non | non | 0 | **rouge** : sans sortie a 1440, sans sortie a 390, B1 pas de barre laterale, B3 pas de fil |
| `/tc/bibliotheque/:resourceId` | `/tc/bibliotheque/:id` | retour | retour | non | non | 0 | **rouge** : B1 pas de barre laterale, B3 pas de fil |
| `/tc/groupes` | `/tuteur` | colonne-dessinee | barre | oui | non | 2 | **rouge** : B5 2 bouton(s) etire(s) |
| `/tc/groupes/:groupeId` | `/tuteur/classes/:id` | retour | retour | oui | non | 0 | **rouge** : B3 pas de fil |
| `/tc/mushaf` | `/acces-refuse` | retour | retour | exception | non | 0 | vert |
| `/tc/observation/:seanceId` | `/tc/observation/:id` | retour | retour | non | non | 0 | **rouge** : B1 pas de barre laterale, B3 pas de fil |
| `/tuteur` | `/tuteur` | colonne-dessinee | barre | oui | non | 2 | **rouge** : B5 2 bouton(s) etire(s) |
| `/tuteur/accueil` | `/tuteur` | colonne-dessinee | barre | oui | non | 2 | **rouge** : B5 2 bouton(s) etire(s) |
| `/tuteur/classes/:classeId` | `/tuteur/classes/:id` | retour | retour | oui | non | 0 | **rouge** : B3 pas de fil |
| `/tuteur/classes/:classeId/observer` | `/tuteur/classes/:id` | retour | retour | oui | non | 0 | **rouge** : B3 pas de fil |
| `/tuteur/classes/:classeId/planning` | `/tuteur/classes/:id/planning` | retour | retour | oui | non | 0 | **rouge** : B3 pas de fil |
| `/tuteur/classes/:classeId/progression` | `/tuteur/classes/:id/progression` | retour | retour | oui | non | 0 | **rouge** : B3 pas de fil |
| `/tuteur/classes/:classeId/ressources` | `/tuteur/classes/:id/ressources` | retour | retour | oui | non | 0 | **rouge** : B3 pas de fil |
| `/tuteur/classes/:classeId/travail` | `/tuteur/classes/:id/travail` | retour | retour | oui | non | 0 | **rouge** : B3 pas de fil |
| `/tuteur/classes/catalogue` | `/tuteur/classes/catalogue` | retour | retour | oui | non | 1 | **rouge** : B3 pas de fil, B5 1 bouton(s) etire(s) |
| `/tuteur/compte` | `/tuteur/compte` | colonne-dessinee | barre | oui | non | 2 | **rouge** : B5 2 bouton(s) etire(s) |
| `/tuteur/compte/acces` | `/tuteur/compte/acces` | retour | retour | oui | non | 0 | **rouge** : B3 pas de fil |
| `/tuteur/compte/aide` | `/tuteur/compte/aide` | retour | retour | oui | non | 0 | **rouge** : B3 pas de fil |
| `/tuteur/compte/consentements` | `/tuteur/compte/consentements` | retour | retour | oui | non | 2 | **rouge** : B3 pas de fil, B5 2 bouton(s) etire(s) |
| `/tuteur/compte/informations` | `/tuteur/compte/informations` | retour | retour | oui | non | 0 | **rouge** : B3 pas de fil |
| `/tuteur/compte/informations-legales` | `/tuteur/compte/informations-legales` | retour | retour | oui | non | 6 | **rouge** : B3 pas de fil, B5 6 bouton(s) etire(s) |
| `/tuteur/compte/mes-donnees` | `/tuteur/compte/mes-donnees` | retour | retour | oui | non | 1 | **rouge** : B3 pas de fil, B5 1 bouton(s) etire(s) |
| `/tuteur/compte/paiements` | `/tuteur/compte/paiements` | retour | retour | oui | non | 0 | **rouge** : B3 pas de fil |
| `/tuteur/compte/preferences` | `/tuteur/compte/preferences` | retour | retour | oui | non | 2 | **rouge** : B3 pas de fil, B5 2 bouton(s) etire(s) |
| `/tuteur/compte/preferences/apparence` | `/tuteur/compte/preferences/apparence` | retour | retour | oui | non | 0 | **rouge** : B3 pas de fil |
| `/tuteur/compte/preferences/langue-courriels` | `/tuteur/compte/preferences/langue-courriels` | retour | retour | oui | non | 0 | **rouge** : B3 pas de fil |
| `/tuteur/compte/securite` | `/tuteur/compte/securite` | retour | retour | oui | non | 0 | **rouge** : B3 pas de fil |
| `/tuteur/demandes` | `/tuteur/demandes` | retour | retour | oui | non | 0 | **rouge** : B3 pas de fil |
| `/tuteur/demandes/:demandeId` | `/tuteur/demandes/:id` | retour | retour | oui | non | 0 | **rouge** : B3 pas de fil |
| `/tuteur/demandes/:demandeId/changement` | `/tuteur/demandes/:id/changement` | retour | retour | oui | non | 1 | **rouge** : B3 pas de fil, B5 1 bouton(s) etire(s) |
| `/tuteur/foyer` | `/tuteur/foyer` | colonne-dessinee | barre | oui | non | 0 | vert |
| `/tuteur/foyer/:eleveId` | `/tuteur/foyer/:id` | retour | retour | oui | non | 6 | **rouge** : B3 pas de fil, B5 6 bouton(s) etire(s) |
| `/tuteur/foyer/:eleveId/acces` | `/tuteur/foyer/:id/acces` | retour | retour | oui | non | 0 | **rouge** : B3 pas de fil |
| `/tuteur/foyer/:eleveId/appareils` | `/tuteur/foyer/:id/appareils` | retour | retour | oui | non | 1 | **rouge** : B3 pas de fil, B5 1 bouton(s) etire(s) |
| `/tuteur/foyer/:eleveId/appareils/connexion` | `/tuteur/foyer/appairer/:id` | retour | retour | oui | non | 0 | **rouge** : B3 pas de fil |
| `/tuteur/foyer/:eleveId/camera` | `/tuteur/foyer/:id/camera` | retour | retour | oui | non | 0 | **rouge** : B3 pas de fil |
| `/tuteur/foyer/:eleveId/couleur` | `/tuteur/foyer/:id/couleur` | retour | retour | oui | non | 0 | **rouge** : B3 pas de fil |
| `/tuteur/foyer/:eleveId/finances` | `/tuteur/foyer/:id/finances` | retour | retour | oui | non | 0 | **rouge** : B3 pas de fil |
| `/tuteur/foyer/:eleveId/informations` | `/tuteur/foyer/:id/informations` | retour | retour | oui | non | 0 | **rouge** : B3 pas de fil |
| `/tuteur/foyer/:eleveId/inscription` | `/tuteur/foyer/:id/inscription` | retour | retour | oui | non | 2 | **rouge** : B3 pas de fil, B5 2 bouton(s) etire(s) |
| `/tuteur/foyer/:eleveId/interface` | `/tuteur/foyer/:id/interface` | retour | retour | oui | non | 0 | **rouge** : B3 pas de fil |
| `/tuteur/foyer/:eleveId/mouvements` | `/tuteur/foyer/:id/mouvements` | retour | retour | oui | non | 0 | **rouge** : B3 pas de fil |
| `/tuteur/foyer/ajouter` | `/tuteur/foyer/ajouter` | retour | retour | oui | non | 0 | **rouge** : B3 pas de fil |
| `/tuteur/foyer/ajouter-enfant` | `/tuteur/foyer/ajouter` | retour | retour | oui | non | 0 | **rouge** : B3 pas de fil |
| `/tuteur/foyer/appairer/:eleveId` | `/tuteur/foyer/appairer/:id` | retour | retour | oui | non | 0 | **rouge** : B3 pas de fil |
| `/tuteur/foyer/appareils` | `/tuteur/foyer/appareils` | retour | retour | oui | non | 1 | **rouge** : B3 pas de fil, B5 1 bouton(s) etire(s) |
| `/tuteur/foyer/invitation` | `/tuteur/foyer/invitation` | retour | retour | oui | non | 0 | **rouge** : B3 pas de fil |
| `/tuteur/foyer/inviter` | `/tuteur/foyer/inviter` | retour | retour | oui | non | 0 | **rouge** : B3 pas de fil |
| `/tuteur/foyer/prix` | `/tuteur/foyer/prix` | retour | retour | oui | non | 0 | **rouge** : B3 pas de fil |
| `/tuteur/foyer/recharge` | `/tuteur/foyer/recharge` | retour | retour | oui | non | 0 | **rouge** : B3 pas de fil |
| `/tuteur/foyer/recharge/result` | `/tuteur/foyer/recharge/result` | colonne-dessinee | barre | oui | non | 0 | **rouge** : B3 pas de fil |
| `/tuteur/foyer/reprise` | `/tuteur/foyer/reprise` | retour | retour | oui | non | 0 | **rouge** : B3 pas de fil |
| `/tuteur/foyer/reprise/titulaire` | `/tuteur/foyer/reprise/titulaire` | retour | retour | oui | non | 0 | **rouge** : B3 pas de fil |
| `/tuteur/historique` | `/tuteur/suivi` | colonne-dessinee | barre | oui | non | 0 | vert |
| `/tuteur/historique/observations` | `/tuteur/suivi/observations` | colonne-dessinee | barre | oui | non | 0 | **rouge** : B3 pas de fil |
| `/tuteur/inscription-reprise` | `/tuteur` | colonne-dessinee | barre | oui | non | 2 | **rouge** : B5 2 bouton(s) etire(s) |
| `/tuteur/messages` | `/tuteur/messages` | retour | retour | oui | non | 0 | **rouge** : B3 pas de fil |
| `/tuteur/messages/:filId` | `/tuteur/messages/:id` | retour | retour | oui | non | 0 | **rouge** : B3 pas de fil |
| `/tuteur/notifications` | `/tuteur/notifications` | retour | retour | oui | non | 1 | **rouge** : B3 pas de fil, B5 1 bouton(s) etire(s) |
| `/tuteur/parcours/:eleveId` | `/tuteur/parcours/:id` | retour | retour | oui | non | 0 | **rouge** : B3 pas de fil |
| `/tuteur/presentation` | `/tuteur/presentation` | retour | retour | oui | non | 0 | **rouge** : B3 pas de fil |
| `/tuteur/reglages` | `/tuteur/foyer` | colonne-dessinee | barre | oui | non | 0 | vert |
| `/tuteur/seances/:seanceId` | `/tuteur/seances/:id` | retour | retour | oui | non | 1 | **rouge** : B3 pas de fil, B5 1 bouton(s) etire(s) |
| `/tuteur/seances/:seanceId/observations` | `/tuteur/seances/:id/observations` | retour | retour | oui | non | 1 | **rouge** : B3 pas de fil, B5 1 bouton(s) etire(s) |
| `/tuteur/suivi` | `/tuteur/suivi` | colonne-dessinee | barre | oui | non | 0 | vert |
| `/tuteur/suivi/observations` | `/tuteur/suivi/observations` | colonne-dessinee | barre | oui | non | 0 | **rouge** : B3 pas de fil |

## visiteur

| Route | Obtenue a 1440 | Sortie 1440 | Sortie 390 | B1 | B3 | B5 | Verdict |
|---|---|---|---|---|---|---|---|
| `/` | `/commencer` | racine | racine | exception | non | 0 | vert |
| `/acces-refuse` | `/connexion` | racine | racine | exception | non | 0 | vert |
| `/agent` | `/agent` | exempte | exempte | exception | non | 0 | vert |
| `/attente` | `/connexion` | racine | racine | exception | non | 0 | vert |
| `/attente/accords` | `/connexion` | racine | racine | exception | non | 0 | vert |
| `/attente/accuse` | `/connexion` | racine | racine | exception | non | 0 | vert |
| `/attente/candidature` | `/connexion` | racine | racine | exception | non | 0 | vert |
| `/attente/contrat` | `/connexion` | racine | racine | exception | non | 0 | vert |
| `/attente/partage` | `/connexion` | racine | racine | exception | non | 0 | vert |
| `/attente/piece` | `/connexion` | racine | racine | exception | non | 0 | vert |
| `/attente/talents` | `/connexion` | racine | racine | exception | non | 0 | vert |
| `/avis/:jeton` | `/avis/:id` | AUCUNE | AUCUNE | exception | non | 0 | **rouge** : sans sortie a 1440, sans sortie a 390 |
| `/bienvenue` | `/commencer` | racine | racine | exception | non | 0 | vert |
| `/commencer` | `/commencer` | racine | racine | exception | non | 0 | vert |
| `/connexion` | `/commencer` | racine | racine | exception | non | 0 | vert |
| `/connexion/eleve` | `/connexion/eleve/code` | retour | retour | exception | non | 0 | vert |
| `/connexion/eleve/code` | `/connexion/eleve/code` | retour | retour | exception | non | 0 | vert |
| `/connexion/eleve/scanner` | `/connexion/eleve/scanner` | retour | retour | exception | non | 0 | vert |
| `/connexion/recuperation` | `/connexion/recuperation` | retour | retour | exception | non | 0 | vert |
| `/hors-ligne` | `/connexion` | racine | racine | exception | non | 0 | vert |
| `/inscription` | `/connexion` | racine | racine | exception | non | 0 | vert |
| `/inscription/genre` | `/connexion` | racine | racine | exception | non | 0 | vert |
| `/inscription/identite` | `/connexion` | racine | racine | exception | non | 0 | vert |
| `/inscription/invitation` | `/connexion` | racine | racine | exception | non | 0 | vert |
| `/inscription/invitation-comptable` | `/connexion` | racine | racine | exception | non | 0 | vert |
| `/inscription/recapitulatif` | `/connexion` | racine | racine | exception | non | 0 | vert |
| `/inscription/usage` | `/connexion` | racine | racine | exception | non | 0 | vert |
| `/juridique` | `/juridique` | retour | retour | exception | non | 6 | **rouge** : B5 6 bouton(s) etire(s) |
| `/juridique/:texte` | `/juridique/conditions` | retour | retour | exception | non | 0 | vert |
| `/salle` | `/commencer` | racine | racine | exception | non | 0 | vert |
