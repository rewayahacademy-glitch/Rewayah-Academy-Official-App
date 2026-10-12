# RECH-BACK-6 — état de recette sécurité et performance

Date : 2026-10-12. Base de branche : `origin/codex/backend-canon-fixes` @ `feba2372`, avec les lots RECH-BACK-1/2/4/5 publiés intégrés. Cette fiche est une cartographie de preuves et de manques, pas une déclaration de conformité globale.

## Résultat de recette

- Les scénarios SQL disponibles sont `scenarios_rech_back_1_security.sql`, `scenarios_rech_back_2_d1_search.sql`, `scenarios_rech_back_4_missions.sql` et `scenarios_rech_back_5_finance_reference.sql`. Ils couvrent des cas ciblés (session invalidée, recherches D1/cursor et projections, mission expirée, référence finance exacte/isolation). Ils n'ont pas été exécutés sur PG18 ici : `psql` explicite (`C:\Program Files\PostgreSQL\18\bin\psql.exe -U postgres -h 127.0.0.1 -w -d postgres`) répond `fe_sendauth: no password supplied`. Aucune base n'a été créée.
- Les tests Deno précédemment exécutés de `supabase/functions/recherche-enseignants/index_test.ts` et `_shared/recherche/curseur_test.ts` passaient, mais ne prouvent pas les invariants SQL, RLS ou PG17.
- PG17/Claude reste la preuve d'autorité pour les scénarios SQL. Aucun STAGING/PROD n'a été utilisé.

## SEC-R01..R22

| ID | Menace / invariant | État vérifiable dans les lots | Preuve et manque restant |
|---|---|---|---|
| R01 | Pas de fuite inter-foyer (hit, suggestion, facette, compteur, lien) | Partiel : D1 classes est limité au foyer par la requête/RLS; D4 porte sur référence exacte. D2/RA est bloqué par contrat R3. | Scénarios D1/D4 présents, non exécutés PG18; couvrir recherche élève/RA entre deux foyers et tous les canaux de réponse. |
| R02 | Une note financière ne rend pas un élève trouvable par un enseignant | Non prouvé; la recherche D3 actuelle porte sur les enseignants visibles dans les classes de la famille. | Ajouter cas adversarial une fois la recherche élèves/pédagogie D2/D3 disponible. |
| R03 | RA étranger non énumérable, sans annuaire global | Bloqué avec D2 en attente R3; aucune résolution RA ajoutée. | Contrat R3 puis tests RA exact autorisé/non autorisé, homonymes, brute force et absence de différences révélatrices. |
| R04 | EV reste borné à son évaluation, sans mapping identité global | Non implémenté par ces lots. | Cas positif dans l'évaluation et négatif hors évaluation à ajouter au domaine EV. |
| R05 | Une réponse réseau ancienne ne remplace pas la requête la plus récente | Hors périmètre serveur de ce lot; R0 le classe côté front. | Test UI d'ordre des réponses absent de cette branche backend. |
| R06 | Fin de droit/publication/classe/mission invalide les nouvelles lectures et caches | Partiel : nouvelle session invalide et mission de contrôle expirée refusée. Publication/cache et remplacement de classe non couverts. | Scénarios BACK-1/4 présents, non exécutés PG18; ajouter révocation de publication/affectation et vérification à l'ouverture. |
| R07 | Changement de compte purge toute donnée privée en mémoire | Hors périmètre serveur; la purge client n'est pas prouvée par les RPC. | Test front A→B incluant cache, curseurs et requêtes en vol absent. |
| R08 | Changement d'espace ne réutilise pas les résultats privés | Non prouvé; responsabilité du contrôleur UI. | Test front Tuteur→Personnel absent. |
| R09 | Aucun total/facette de corpus interdit | Partiel pour D1 : réponse bornée et `has_more`, pas de total global dans le SQL livré. | Scenario D1 présent, non exécuté; vérifier tous les futurs adaptateurs/domaines. |
| R10 | DTO en liste blanche, aucun champ sensible sérialisé | Partiel : D1 renvoie projection minimale; D4 ne renvoie que type, UUID et date max. | Scénarios D1/D4 présents; tests JSON bruts non exécutés PG18 et aucun inventaire global des DTO. |
| R11 | Texte HTML/Markdown hostile n'est jamais renvoyé en HTML actif | Non prouvé côté serveur/UI par cette branche. | La normalisation testée côté handler n'est pas une preuve du rendu Flutter échappé; test de rendu requis. |
| R12 | Deep link, document ID et curseur forgés réautorisés; cible whitelistée | Partiel : curseur D1 lié au sujet/domaine/requête et limité dans le temps; ouverture de cible non couverte. | Scénario D1 présent; ajouter tests d'ouverture et de destination forgée dans l'adaptateur/UI. |
| R13 | Ouverture fichier via URL signée courte et droits frais | Non implémenté par les lots de recherche. | À prouver dans chaque domaine Storage/R2; aucune URL signée n'est produite ici. |
| R14 | KYC, contrôle et banque hors recherche globale | Partiel : D4 n'expose aucun montant, bénéficiaire ni détail bancaire; D3 expose seulement le résumé de mission autorisé. | Scénarios D3/D4 présents mais non exécutés; KYC et rapports dédiés non raccordés. |
| R15 | JWT périmé ne restaure pas un droit révoqué | Partiel : version d'autorisation fraîche dans BACK-1, vérifiée aux entrées D1/D3/D4. | Scenario BACK-1 et cas stale D3/D4 présents, non exécutés PG18; replay PG17 requis. |
| R16 | Observateur IA ne se fait pas passer pour enseignant | Non prouvé / non traité par ces lots. | Ajouter scénario identité propre, mission et capacités bornées au module observateur. |
| R17 | Pas d'énumération à haute cadence | Partiel : quotas/limites présents pour les recherches D1 et curseur; pas de recette gateway ni de test de cadence mesurée. | Scénario de limites D1 présent; test anti-énumération multi-termes/IP et vérification des messages/latences manquent. |
| R18 | Hors ligne ne présente pas la recherche serveur comme confirmée | Hors périmètre serveur. | Test cache/offline client absent. |
| R19 | Source revérifiée après retard d'index/réplique | Non prouvé; pas de pipeline d'index global livré. | Tester suppression/changement source puis ouverture après délai d'index dans chaque domaine. |
| R20 | Aucun terme sensible/résultat personnel dans les logs | Non prouvé par une recherche statique seule; aucune recette de capture logs n'a été exécutée. | Audit des logs Edge/API/DB et tests de redaction requis. |
| R21 | Entrée énorme/wildcards/opérateurs bornés et requêtes paramétrées | Partiel : D1 valide longueur/termes/limite, utilise des paramètres; D4 n'accepte qu'un UUID. | Scénarios D1/D4 présents, non exécutés; timeout et quota réel non mesurés. |
| R22 | Aucun contenu privé envoyé à traduction/autocomplete tiers | Aucun fournisseur externe ajouté par les lots livrés; preuve exhaustive non établie. | Audit dépendances/réseau des adaptateurs front et services reste à faire. |

## Performance — critères et mesure

La spec fixe SQL p95 ≤150 ms et API p95 ≤400 ms, avec plans, buffers, charge synthétique et tailles 10k→100k→1m, utilisateurs synthétiques 25→100→300, plus p50/p95/p99. Aucun chiffre de latence, plan, buffer ou charge n'est disponible dans le dépôt ni dans cette session. Le verrou local PG18 empêche même le rejeu des scénarios; aucun résultat de performance n'est revendiqué. Les index D1 (GIN) et D4 (B-tree sur référence) sont du code présent, pas une preuve de p95. Mesures à réaliser sur une base jetable puis à faire rejouer par Claude en PG17; staging synthétique seulement selon autorisation distincte.

## Conclusion opérationnelle

RECH-BACK-6 livre cette matrice de recette pour empêcher de confondre code présent et risque couvert. L'ensemble SEC-R01..22 n'est **pas validé**. Priorités de levée : R01/R03 après contrat R3; R02/R04/R13/R16/R19 sur les domaines manquants; R05/R07/R08/R11/R18 côté client; R20 audit logs; R17/R21 et performance sous charge. Limitation d'autocontrôle local notée ci-dessus; verdict PG17 de Claude attendu sans bloquer la file.
