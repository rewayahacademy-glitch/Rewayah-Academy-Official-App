# Rewayah - contrat documentaire canonique
Version : 23 septembre 2026. Portée : spécification cible pour achever l'application existante. Ces documents ne prouvent pas que les fonctionnalités sont déjà livrées.

## Lecture en moins de cinq minutes
1. Lire ce fichier, puis `08_DECISIONS_ET_FEUILLE_DE_ROUTE_2026-09-23.md` version 2 pour la gate C0. Tant que C0 reste ouverte, seul `09_PROMPT_REPRISE_VERTICALE.md` version de configuration peut être exécuté ; les tranches produit sont gelées.
2. Lire uniquement le document du domaine touché : `01_PRODUIT_ET_PARCOURS.md`, `02_ARCHITECTURE_ET_SECURITE.md`, `03_DESIGN_SYSTEM_ET_UX.md` ou `06_SPEC_FONCTIONNELLE_MVP.md`. Pour un lot académique ou financier futur, lire aussi `07_MEMOIRE_PEDAGOGIE_FINANCE.md`.
3. Lire `04_EXECUTION_GIT_CI_ET_MIGRATION.md` seulement pour intégration, ménage documentaire, branches ou déploiement.
4. Inspecter le code, les migrations, les tests et le journal Git du périmètre. Le code atteste l'état réel, pas la validité d'une décision métier.
5. Avant de coder, produire : fichiers prévus, dépendances, critères de succès, points incertains. Travailler par un lot limité.

## Autorité et désaccords
La demande explicite la plus récente du directeur prévaut sur ces documents. Ensuite : les décisions datées de `08_DECISIONS_ET_FEUILLE_DE_ROUTE_2026-09-23.md`, puis décisions canoniques ici, contrats effectivement migrés et vérifiés, documents historiques conservés en archive, suppositions d'agent. Une migration en production impose un plan compatible et réversible, même si ces specs décrivent un modèle différent. En cas de conflit réel, noter le conflit et proposer la modification minimale ; ne pas choisir silencieusement.

## Invariants
- Conserver Flutter Android, iOS, Web ; Supabase ; LiveKit ; stockage R2 distinct et privé selon les quatre groupes réellement configurés. Claude Code est l'agent de développement. Vercel concerne le déploiement web effectivement configuré ; confirmer le projet dans le dépôt.
- Préserver l'existant utile. Pas de recréation de l'app, de schéma, de thème, d'auth ou de routeur pour chaque lot.
- Une classe est un groupe stable, avec horaire récurrent et enseignant attitré. Le tuteur choisit parmi les classes proposées ; l'admin affecte et gère les exceptions.
- L'interface présente une tâche et une action principales ; noms simples. Les codes internes restent internes.
- Autorisation contrôlée côté serveur : RLS, rôles, capacités et accès LiveKit. Aucun secret ou calcul financier de référence côté Flutter.
- Aucun déploiement, migration distante, publication, suppression de branche ou de mémoire avant inventaire, sauvegarde et feu vert explicite de l'opérateur sur la liste précise. Ne jamais effacer une branche contenant un travail non intégré.

## Statuts de preuve
Chaque tâche et bilan distingue `spécifié`, `présent dans le code`, `testé localement`, `testé sur staging`, `déployé`. Ne jamais qualifier d'achevé un parcours UI dont le backend, le branchement, la sécurité ou le test réel manque.

## Contradictions résolues
- L'ancien « matching » individuel par disponibilités est remplacé pour l'inscription courante par le choix d'une classe précréée avec un même enseignant et ses séances récurrentes. Les disponibilités servent à proposer des options, gérer exceptions et liste d'attente.
- Les anciens plafonds génériques de 6 personnes et capacités supposées de 5 cèdent aux capacités et durées de la version de classe validée ; le référentiel académique plus récent propose 5 enfants/60 min et 6 adultes/90 min, alors que le Control System antérieur propose 4/45 et 5/90. Ne pas présumer d’une valeur par défaut avant arbitrage ; afficher la capacité réelle.
- « Mode enfant » devient `Interface guidée`, activable selon les besoins, y compris par un adulte. Dans l'espace cours : `Sayyid` / `Sayyida`.
- Le document économique du 13 septembre développe la finance et l'IA ; il n'annule pas les parcours indispensables à une première cohorte réelle. Les moteurs financiers avancés restent des lots séparés. Les chiffres de scénario ne deviennent jamais des vérités de production.
- Les quotas et prix anciens de fournisseurs ne sont pas des paramètres fiables de 2026 : vérifier contrats et consoles avant arbitrage de coût.
- Ne pas interpréter la documentation académique comme un mandat de réécrire l'enseignement ou le Coran. Les validations pédagogiques restent humaines.

## Questions à résoudre sur le dépôt, sans blocage du travail indépendant
État exact de CORE24 Classes V2 et de son audit ; quatre noms/contrats R2 en production ; état des migrations ; statut LiveKit Cloud ou hébergé ; branche principale et configuration Vercel ; référentiel académique actuel et version approuvée. Documenter la preuve et la personne qui tranche une divergence. L'audit CORE24 communiqué par le directeur indique explicitement « non prêt pour intégration » : aucun merge sur ce seul fondement.
