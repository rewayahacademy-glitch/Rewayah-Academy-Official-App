# RECH-BACK-6 — état de recette sécurité et performance

Date : 2026-10-12. Base de branche : `origin/codex/backend-canon-fixes` @ `feba2372`, avec les lots RECH-BACK-1/2/4/5 publiés intégrés. Cette fiche est une cartographie de preuves et de manques, pas une déclaration de conformité globale.

## Résultat de recette

- Les scénarios SQL couvrent BACK-1/2/4/5, mais leurs preuves sont distinctes : BACK-1 deux scénarios ciblés passés sur PG18 partiel; BACK-2 scénario passé sur PG18 partiel après application séparée des grants ciblés (migration D1 déjà présente); BACK-4 non exécuté, car la base partielle n’a pas `private.controle_missions`; BACK-5 confirmé par Claude en PG17. Aucun de ces faits ne remplace le replay complet PG17.
- Deno 2.9.6 est disponible, mais `deno test supabase/functions/recherche-enseignants/index_test.ts` s’arrête avant les tests : la dépendance `npm:@supabase/realtime-js@2.116.0` manque. Aucun résultat Deno n’est revendiqué.
- PG17/Claude reste la preuve d'autorité pour les scénarios SQL. Aucun STAGING/PROD n'a été utilisé.

## SEC-R01..R22

| ID | Menace / invariant | État vérifiable dans les lots | Preuve et manque restant |
|---|---|---|---|
| R01 | Pas de fuite inter-foyer (hit, suggestion, facette, compteur, lien) | Partiel : D1 conserve les filtres RLS et la projection de l’offre; D4 porte sur référence exacte. D2/RA reste bloqué par contrat R3. | Scénario D1 passé sur PG18 partiel avec grants ciblés; replay PG17 complet et recherche élèves/RA entre foyers non prouvés. |
| R02 | Une note financière ne rend pas un élève trouvable par un enseignant | Non prouvé; la recherche D3 actuelle porte sur les enseignants visibles dans les classes de la famille. | Ajouter cas adversarial une fois la recherche élèves/pédagogie D2/D3 disponible. |
| R03 | RA étranger non énumérable, sans annuaire global | Bloqué avec D2 en attente R3; aucune résolution RA ajoutée. | Contrat R3 puis tests RA exact autorisé/non autorisé, homonymes, brute force et absence de différences révélatrices. |
| R04 | EV reste borné à son évaluation, sans mapping identité global | Non implémenté par ces lots. | Cas positif dans l'évaluation et négatif hors évaluation à ajouter au domaine EV. |
| R05 | Une réponse réseau ancienne ne remplace pas la requête la plus récente | Hors périmètre serveur de ce lot; R0 le classe côté front. | Test UI d'ordre des réponses absent de cette branche backend. |
| R06 | Fin de droit/publication/classe/mission invalide les nouvelles lectures et caches | Code corrigé : BACK-1 vérifie authorization_version; BACK-4 vérifie capacité active et échéance. | Ne pas compter la régression de hook maintenant corrigée comme preuve. Scénarios BACK-1 ciblés PASS sur PG18 partiel; BACK-4 non exécuté localement; verdict PG17 requis. |
| R07 | Changement de compte purge toute donnée privée en mémoire | Hors périmètre serveur; la purge client n'est pas prouvée par les RPC. | Test front A→B incluant cache, curseurs et requêtes en vol absent. |
| R08 | Changement d'espace ne réutilise pas les résultats privés | Non prouvé; responsabilité du contrôleur UI. | Test front Tuteur→Personnel absent. |
| R09 | Aucun total/facette de corpus interdit | Partiel pour D1 : réponse bornée et `has_more`, sans total global. | Scénario D1 passe sur PG18 partiel après grants ciblés; replay PG17 et autres domaines non prouvés. |
| R10 | DTO en liste blanche, aucun champ sensible sérialisé | D1 renvoie une projection minimale; D4 ne renvoie que type, UUID et date max. | Le scénario D1 contrôle les champs exposés sur PG18 partiel; D4 confirmé par Claude PG17. Aucun inventaire global des DTO. |
| R11 | Texte HTML/Markdown hostile n'est jamais renvoyé en HTML actif | Non prouvé côté serveur/UI par cette branche. | La normalisation testée côté handler n'est pas une preuve du rendu Flutter échappé; test de rendu requis. |
| R12 | Deep link, document ID et curseur forgés réautorisés; cible whitelistée | Partiel : curseur D1 lié au sujet/domaine/requête et limité dans le temps; ouverture de cible non couverte. | Scénario D1 vérifie pagination, rejeu, autre compte et autre requête sur PG18 partiel. Mutants dédiés du curseur non exécutés; ouverture/destination forgée reste à tester. |
| R13 | Ouverture fichier via URL signée courte et droits frais | Non implémenté par les lots de recherche. | À prouver dans chaque domaine Storage/R2; aucune URL signée n'est produite ici. |
| R14 | KYC, contrôle et banque hors recherche globale | Partiel : D4 n'expose aucun montant, bénéficiaire ni détail bancaire; D3 expose seulement le résumé de mission autorisé. | BACK-5/D4 confirmé par Claude en PG17; BACK-4/D3 scenario présent mais corrigé non rejoué. KYC et rapports dédiés non raccordés. |
| R15 | JWT périmé ne restaure pas un droit révoqué | BACK-1 conserve tranche_age et vérifie authorization_version; BACK-4 rejette l’autorisation périmée. | Scénario BACK-1 ciblé PASS sur PG18 partiel. BACK-4 non exécuté localement. Aucun verdict PG17 correctif encore consigné. |
| R16 | Observateur IA ne se fait pas passer pour enseignant | Non prouvé / non traité par ces lots. | Ajouter scénario identité propre, mission et capacités bornées au module observateur. |
| R17 | Pas d'énumération à haute cadence | D1 applique des limites et quotas de curseur côté SQL; aucune recette gateway ou cadence mesurée. | Les assertions fonctionnelles D1 passent sur PG18 partiel. Mutant quota/curseur non exécuté; messages et latences anti-énumération manquent. |
| R18 | Hors ligne ne présente pas la recherche serveur comme confirmée | Hors périmètre serveur. | Test cache/offline client absent. |
| R19 | Source revérifiée après retard d'index/réplique | Non prouvé; pas de pipeline d'index global livré. | Tester suppression/changement source puis ouverture après délai d'index dans chaque domaine. |
| R20 | Aucun terme sensible/résultat personnel dans les logs | Non prouvé par une recherche statique seule; aucune recette de capture logs n'a été exécutée. | Audit des logs Edge/API/DB et tests de redaction requis. |
| R21 | Entrée énorme/wildcards/opérateurs bornés et requêtes paramétrées | Partiel : D1 borne longueur/limite et paramètre les requêtes; D4 n'accepte qu'un UUID. | Scénarios D1/D4 présents, preuve PG18 partielle pour D1 et PG17 pour D4; timeout et quota réel non mesurés. |
| R22 | Aucun contenu privé envoyé à traduction/autocomplete tiers | Aucun fournisseur externe ajouté par les lots livrés; preuve exhaustive non établie. | Audit dépendances/réseau des adaptateurs front et services reste à faire. |

## Performance — critères et mesure

La spec fixe SQL p95 ≤150 ms et API p95 ≤400 ms, avec plans, buffers, charge synthétique et tailles 10k→100k→1m, utilisateurs synthétiques 25→100→300, plus p50/p95/p99. Aucune mesure p95, plan, buffer ou charge n’a été exécutée pour BACK-1/2/4; le scénario BACK-2 ne prouve pas la performance ni les mutants de curseur. Les index D1 et D4 sont du code présent, pas une preuve de latence. Mesures à réaliser sur une base jetable puis à faire rejouer par Claude en PG17; staging synthétique seulement selon autorisation distincte.

## Conclusion opérationnelle

RECH-BACK-6 livre cette matrice de recette pour empêcher de confondre code présent et risque couvert. L'ensemble SEC-R01..22 n'est **pas validé**. Priorités de levée : R01/R03 après contrat R3; R02/R04/R13/R16/R19 sur les domaines manquants; R05/R07/R08/R11/R18 côté client; R20 audit logs; R17/R21 et performance sous charge. Autocontrôle local PG18 partiel documenté ci-dessus; verdict PG17 de Claude attendu sans bloquer la file.
