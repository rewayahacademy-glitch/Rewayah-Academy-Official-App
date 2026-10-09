# REWAYAH - BR-0B - Blueprint backend consolidé V0.2

Date de consolidation : 7 octobre 2026. Remplace la V0.1 du 6 octobre.

**Verdict : architecture à consolider avant branchement. Le frontend existant est une source de contrats, pas une preuve de backend opérationnel.**

Ce document rassemble la contre-revue, la cible technique, les contrats métier retrouvés et le plan de réalisation. Il ne constitue ni une autorisation de migration, ni une validation de production. Aucun code GitHub, aucune configuration distante, aucune donnée métier n'a été modifié pendant cet audit.

## 0. Résultat de la contre-revue

La V0.1 pose de bons principes : séparation des environnements, autorisation serveur, idempotence, journal financier, cache cloisonné et releases compatibles. Elle reste insuffisante seule pour Claude : elle omet une grande partie des contrats déjà préparés, laisse ouverts des choix déjà tranchés et ne décrit pas les mécanismes nécessaires pour prouver la sécurité, la restauration et la capacité.

Corrections structurantes de cette version :

1. Rétablissement des décisions KYC et Contrôleur déjà documentées.
2. Inventaire distant daté, branches GitHub identifiées par SHA, séparation du constat et de la cible.
3. Couverture Tuteur, Élève adulte/enfant, Enseignant, Direction, Contrôleur, Finance, Comptable, Communications, Supports et accessibilité.
4. Corrections de sécurité prioritaires fondées sur les permissions et les fonctions réellement présentes.
5. Raccordement par contrats existants, avec états, versions, erreurs, concurrence et tests négatifs.
6. Plan de montée en charge mesurable. Aucune promesse de « centaines de milliers de personnes » sans distinction entre comptes, connexions et participants vidéo.
7. Restauration de données réelles dans un environnement RECOVERY protégé, jamais dans STAGING.
8. Plan de livraison par lots, prérequis communs et critères de passage vérifiables.

### Nature des preuves

- **OBSERVÉ** : résultat distant ou contenu GitHub lu sur une référence figée.
- **DÉCISION SOURCE** : règle produit écrite dans le cockpit ou un contrat daté ; cela ne prouve pas son implémentation.
- **CONSTAT STATIQUE** : déduit du code, des grants, des policies ou d'une définition SQL ; aucune exploitation en production n'a été tentée.
- **CIBLE** : exigence proposée pour le futur backend ; pas une fonctionnalité actuellement disponible.
- **NON VÉRIFIÉ** : ne doit être ni annoncé prêt, ni transformé en défaut avéré.

La collecte principale date du **6 octobre 2026 vers 19:45-20:00 UTC**. Une vérification ciblée des fonctions d'autorisation/groupes a été effectuée le 7 octobre. Les sources continuent d'évoluer : Claude doit rafraîchir les références de sa verticale avant son lot, sans réinterpréter cet audit comme une photographie permanente.

## 1. Autorité et périmètre

Ordre de décision : instruction explicite datée la plus récente du directeur ; décisions et cockpit courants ; spécifications validées et contrats BR du domaine ; constat d'implémentation ; hypothèse technique. **Une base live ne remplace pas une décision produit.** Un défaut déployé reste un défaut. Un écran ne crée pas un droit.

Pour chaque conflit : consigner les deux sources, leurs dates, la portée et la résolution. Ne pas réouvrir une décision simplement parce que la V0.1 l'avait oubliée. Ne pas prendre une valeur de démonstration pour un tarif approuvé.

La mission actuelle autorise la revue et la correction documentaire. Elle ne lève pas automatiquement le gel de BR-1, ne fusionne aucune branche et ne lance aucun paiement. Le transfert PISI décrit dans `mapping BD sup.md` concerne un autre produit : ses projets ne sont pas des environnements de Rewayah.

## 2. État distant observé

### 2.1 Environnements Supabase

| Élément | PROD | STAGING |
|---|---|---|
| Nom observé | Rewayah PROD (Real Users) | Rewayah STAGING (test) |
| project_ref | `gggmtelinlpseweouyav` | `xldmmlrnxyabdtvxqbyy` |
| Région | `eu-west-1`, Irlande | `eu-west-2`, Londres |
| État du projet | ACTIVE_HEALTHY | ACTIVE_HEALTHY |
| PostgreSQL observé | 17.6.1.166 | 17.11.0.003 |
| Tables applicatives public | 67, dont partition ; RLS activée | 0 |
| Vues public | 15 | 0 |
| Historique migrations | 50 entrées, jusqu'à 0042 | 0 |
| Edge Functions | 10 actives | 0 |
| Publication de tables Realtime | Aucune table retournée par le catalogue interrogé | Aucune |
| Données réelles | À protéger | Interdites |

Les deux projets appartiennent à `kiiqmnrsttqrolaofflu`, organisation observée sur le plan Free. `max_connections` observé : 60 pour chaque base. Ce nombre ne représente pas la capacité d'utilisateurs de l'application.

L'entrée de branche Supabase `main` de PROD porte `MIGRATIONS_FAILED` depuis septembre. Le projet répond aux lectures : **ce statut d'intégration n'est pas une panne de la base**. Sa cause et son rattachement Git doivent être diagnostiqués avant toute remise en route.

Les dix fonctions déployées : `creer-profil-enfant`, `session-enfant`, `create-room-token`, `livekit-webhook`, `agent-session`, `r2-selftest`, `piece-identite-depot`, `archive-seance-acces`, `piece-identite-confirme`, `piece-identite-acces`. Leur présence n'atteste pas que chaque parcours est utilisable.

### 2.2 GitHub réellement accessible

Dépôt : `rewayahacademy-glitch/Rewayah-Academy-Official-App`.

| Référence observée | SHA figé | Rôle dans la revue |
|---|---|---|
| main | `4a7aa2befe354ace408d3c75c8ea177fb70544e1` | Historique, dernier commit du 22 septembre ; pas le frontend courant |
| corrections/revue-directeur-2026-10 | `6e2c91c4475837bfc5b555dd3a31a2af1e35b479` | Base commune des corrections frontend |
| pilotage/tuteur-v1 | `708ef8f59bfefae89db071764d3f90a7d6b13322` | Contrats et décisions des verticales |
| ui/finance-v1 | `728c34c5a9ef94b325ff52c032ae3cc2aafdee87` | Frontend Finance |
| ui/comptable-v1 | `c07aead7dddf4282cb55a49fb3c7973fe548e45c` | Frontend Comptable |
| ui/communications-v1 | `7356160bc52ed11a29ab49c3f5a2b55535892434` | Référence de branche Communications |
| ui/tuteur-v1 | `73f12c885d330828f71672da241632dff0fe3d81` | Référence portée par la PR 3 |

L'ancien rapport « GitHub REMOTE INACCESSIBLE » est dépassé pour cette session. Les branches ne sont pas interchangeables. Finance/Comptable/Communications ne doivent pas être supposés intégrés à la branche commune.

PR observées : 2 C0 en brouillon ; 3 Tuteur en brouillon ; 5 répétition de fusion en brouillon ; 7 CI D2 en brouillon. La dernière CI observée sur la PR 7 est en échec. Cela ne signifie pas que tous les tests frontend échouent : les tests locaux du cockpit et la CI distante sont des preuves différentes.

`main` est renvoyée avec `protected:false`. La lecture des rulesets a répondu 403 avec une restriction de formule GitHub. Les protections d'environnement et droits de contournement n'ont pas été attestés. Prévoir une protection effectivement disponible sur le compte, sans considérer un fichier d'instructions comme un verrou technique.

### 2.3 Divergence migrations

`main` et la branche commune contiennent 0001-0038 avec plusieurs fichiers complémentaires portant les mêmes préfixes 0030/0032/0033, puis `0043_offres_horaires_et_intentions.sql`. Les fichiers 0039-0042 ne sont pas dans ces deux arbres inspectés, alors que leurs entrées existent en PROD.

0043 n'est pas dans l'historique live observé. Elle prévoit notamment `langues_cours`, `cohortes_age`, `offres_horaires`, `intentions_horaire`, `groupe_creneaux` : ces noms ne sont pas présents dans le catalogue public observé. Ne pas raccorder un écran en présumant ces objets disponibles.

L'historique distant contient aussi des marqueurs 0006-0008 et des versions horodatées. **50 entrées ne signifient pas 50 fichiers SQL distincts.** Le rapport source mentionne une autre 0043 locale liée au jeton vidéo : cette copie locale n'a pas été inspectée ici. Ne pas la confondre avec 0043 de main.

## 3. Décisions produit rétablies

| Sujet | Règle à préserver | Source retrouvée |
|---|---|---|
| KYC | KYC/validation de l'enseignant ; le tuteur n'attend pas un KYC pour exister | Cockpit p.34, K-47, 27/09 |
| Lecture des pièces | Direction seule pour la revue sensible ; Contrôleur exclu | Cockpit p.25, KYC-LECTURE-1, 02/10 |
| MFA Contrôleur | Obligatoire ; ne plus présenter le principe comme ouvert | Cockpit p.25, PAQ-CT-BR1 B2 |
| Rapports de contrôle | Rapport brut 12 mois après envoi, prolongé si dossier/mesure ouvert ; une contestation sous 7 jours après publication de la synthèse mensuelle | Cockpit p.25, B4/B7 |
| Confidentialité contrôle | Identité du contrôleur non révélée ; rapport brut auteur + administration ; export administration | Cockpit p.25/p.36 ; CT-BR |
| Élève adulte | Compatibilité avec `guardian` historique + profil `autonomous` propre ; capacité serveur explicite | EA-ROLE-BR et EA-BR |
| Finance foyer | Solde par profil ; synthèse foyer non dépensable | FI-BR-03/04/14 |
| Second adulte | Lecture paiements ; recharge réservée au titulaire | FI-BR-18 ; K-53.8 |
| Entrée en cours | Droit d'accès serveur par période/essai ; pas comparaison client solde/prix | FI-BR-08 |
| Essai | 2 séances au plus ; absence à une séance ouverte consomme ; annulation Rewayah ne consomme pas | FI-BR-08 |
| Conservation de place | 7 jours au lancement, pilotés par politique | FI-BR-08 |
| Cahier et paye | Cahier validé requis pour rendre la séance payable ; corrections historisées | Cockpit K-45, p.34 |
| Comptable | Bureau opérationnel et délégation ; FI-BR-13 est remplacé par CPT-BR | CPT-BR §4 |
| Communications | Studio frontend admin seul ; capacités serveur ; fil de contrôle unique partagé entre les adaptateurs | COM-BR-13/14/16 |
| Accessibilité | Préférence fonctionnelle et capacités, sans divulguer sa raison médicale ; libellé visible courant « Mode Accessibilité » | Cockpit p.95 et MA-BR |

Précisions : la photo de l'élève, les consentements et le KYC professionnel sont distincts. La consultation par l'enseignant de son propre dossier doit être définie séparément de la capacité de revue Direction. Ne pas étendre une permission de revue à tous les documents du foyer.

La mémoire ancienne « 4 USD/h » ou « 20 USD/élève/mois » ne sert pas de valeur par défaut. La politique commerciale versionnée et son texte de lancement font foi. Les bourses « 3 maximum pour 100 payants » et les remises orphelins/convertis proviennent d'une décision antérieure du directeur : formaliser précisément dénominateur, arrondi, période, retrait et concurrence depuis le document économique courant avant calcul. Ne pas inventer cette formule.

Le contrat FI contient une contradiction interne : FI-BR-18 accorde la lecture au second adulte alors qu'une ancienne ligne de sa section de relecture la refuse. La règle explicite FI-BR-18/K-53.8 prévaut. Les extraits sources annexés sont conservés comme preuves, pas comme permission de réintroduire cette contradiction.

## 4. Blocages sécurité prioritaires

Priorité P0 = bloque l'ouverture du parcours concerné à de vrais usagers ; ne signifie pas qu'une fuite a été observée.

| ID | Constat et niveau de preuve | Correction cible et preuve attendue |
|---|---|---|
| SEC-01 P0 | `agent-session` signe `role=agent_ro`, mais `sub` prend l'identifiant du profil observé et le rôle applicatif son parcours. Les surcharges longues de `creer_groupe` et `modifier_groupe` sont EXECUTE par agent_ro, DEFINER, sans refus agent explicite. Chaîne statique préoccupante, aucune mutation tentée | Révoquer toutes les écritures effectives par fonctions, pas seulement par tables. Identité propre + sujet observé séparé ; garde agent et plafond de délégation. Test négatif de chaque surcharge sur STAGING |
| SEC-02 P0 | `app_role()` et `app_household_id()` lisent le JWT. Les droits peuvent survivre à une modification serveur | Autorité courante des droits révocables ; vérifier rôle/capacité/relation/statut/session pour chaque opération sensible ; invalidation de caches et canaux. Test JWT ancien après retrait |
| SEC-03 P0 | `guard_profile_privileged_columns` emploie `app_role() <> 'admin'` ; NULL ne fait pas entrer dans le IF | Garde positive et refus par défaut. Tester rôle absent/invalide, ancien JWT et modification de chaque colonne privilégiée ; contrôler aussi policy et grants avant de conclure à l'exploitabilité |
| SEC-04 P0 | Fonction `autoriser_lecture_piece_identite` accepte admin ou controller ; Storage `kyc_lecture_admin` également | Appliquer Direction seule aux chemins table/vue/RPC/Edge/Storage ; fermer l'accès direct qui contournerait audit et filtrage. Test Contrôleur refusé par toutes voies |
| SEC-05 P0 | Les 15 vues public n'ont pas `security_invoker=true` ; advisor les signale DEFINER | Classer chaque vue selon son audience ; INVOKER ou retrait d'exposition avec voie serveur contrôlée. Les filtres existants empêchent de conclure automatiquement à une fuite |
| SEC-06 P0 | `wallets`/`wallet_entries` conservent policies ALL admin/comptable ; modèle legacy de foyer différent du solde par profil demandé | Ledger inviolable par acteurs métier ; écritures par commandes contrôlées ; migration explicite des portefeuilles, pas changement silencieux de propriétaire |
| SEC-07 P0 | Policy UPDATE `student_profiles_family_update` repose sur le foyer, pas une capacité de titulaire | Séparer propriété/consultation/mutation, interdire à un enfant d'éditer les réglages protégés de lui-même ou d'un autre ; whitelist colonnes/commandes et tests |
| SEC-08 P0 | `session-enfant` déployée indique et implémente l'absence de limitation de débit locale sur le code d'appairage | Limitation serveur multi-dimension, code usage unique, consommation atomique, erreurs non révélatrices. Protections externes éventuelles non auditées |
| SEC-09 P1 | Advisors : protection mots de passe compromis et options MFA insuffisantes signalées | Vérifier la configuration Auth effective, le mode d'auth utilisé et la disponibilité de la formule ; activer méthodes requises et récupération testée, sans prétendre qu'une option seule impose MFA |
| SEC-10 P0 | Le frontend sait afficher les états mais plusieurs ports renvoient volontairement `CapaciteIndisponible` | Remplacer seulement l'adaptateur validé ; jamais transformer indisponibilité en succès, liste vide ou permission implicite |

Inventaire advisors du 6/10 : 15 vues signalées, 27 fonctions DEFINER exécutables par anon, 118 par authenticated ; 7 tables RLS sans policy directe ; une extension public. Ce sont des surfaces à qualifier : des fonctions publiques peuvent être intentionnelles et des tables privées sans policy peuvent être correctement fermées. Ne pas révoquer aveuglément les hooks Auth, les fonctions système ou les fonctions métier nécessaires.

Le catalogue de fonctions inspecté comporte 141 routines DEFINER ; les fonctions d’extensions présentes dans le catalogue doivent être distinguées des routines métier. Une refonte uniforme INVOKER casserait certaines opérations. Pour chaque routine : propriétaire, signature complète, EXECUTE effectif, dépendances, validation identité, capability, relation, état, audit et tests doivent être documentés.

### 4.1 Autorité d'accès cible

Évaluation : identité vérifiée -> capacité actuelle -> relation actuelle -> état courant -> contexte (MFA/temps/affectation) -> autoriser/refuser/exiger validation.

- RBAC pour les ensembles de capacités ; ReBAC pour foyer/classe/mission ; ABAC pour contexte. Commencer par des règles typées, testables et versionnées dans le backend existant, sans imposer d'emblée un moteur distribué.
- Ne jamais utiliser `user_metadata` modifiable pour accorder un droit.
- Ne pas faire reposer une révocation immédiate sur l'expiration JWT. JWT valide prouve l'émission, pas l'actualité d'une affectation.
- Éviter la récursion RLS : helper privé minimal ou table d'autorisation dédiée, owner limité, noms qualifiés, plan de requête vérifié. Ne pas ajouter une sous-requête récursive sur profiles partout.
- Corriger à terme l'instruction de `supabase/CLAUDE.md` qui impose exclusivement les claims JWT : elle contredit les droits courants requis par ce blueprint.
- RLS ne masque pas des colonnes : DTO/vues restreintes pour notes d'autres élèves, causes financières, coordonnées et pièces.
- `WITH CHECK`/`USING`, grants et triggers se vérifient ensemble. Une absence explicite de `WITH CHECK` n'est pas toujours une absence de contrôle : PostgreSQL peut réutiliser USING selon la policy.
- DEFINER : `search_path=''`, noms qualifiés, propriétaire le moins privilégié possible, contrôle d'accès dans le corps, grants minimaux par signature. L'owner postgres contourne généralement RLS ; activer FORCE RLS seul ne neutralise pas un rôle BYPASSRLS.
- API exposée explicitement inventoriée ; schémas internes séparés. Configuration effective Data API/GraphQL à confirmer, pas simplement déduite du nom public.

### 4.2 Agents et délégations

Conserver HUMAN/AI_AGENT/SERVICE/DEVICE comme types conceptuels. Ne pas créer arbitrairement quatre copies de la table profiles. Une délégation associe identité propre, mandant, sujet éventuellement observé, finalité, ressources, capabilities maximales, environnement, expiration et quotas.

A0 lecture ; A1 brouillons réversibles ; A2 commandes bornées ; A3 approbation explicite pour privilèges, migration PROD, paiement final, remboursement et KYC sensible ; A4 jamais auto-octroi, désactivation audit ou accès racine. Ces niveaux sont une politique cible à implémenter, pas un mécanisme déjà présent.

Gateway -> contrôle déterministe -> commande métier. Le texte d'un LLM, une page lue et un prompt ne constituent pas une autorisation. L'approbation porte sur commande normalisée, empreinte du payload, version, environnement, montant, destinataire et expiration ; tout changement invalide l'approbation. L'exécuteur est distinct de l'approbateur selon la séparation des tâches.

Aucune clé service_role permanente ni accès SQL PROD général pour les agents applicatifs. Les comptes techniques de déploiement sont séparés des agents du produit, avec secrets courts ou rotation, traçabilité et permissions minimales.

## 5. Architecture cible et frontières

Conserver Flutter + Supabase Auth/PostgreSQL + Edge Functions + LiveKit + R2. **Monolithe métier modulaire au départ** : transactions locales pour l'argent, les places et les droits ; adaptateurs externes derrière contrats. Pas de microservices, sharding ou cellules régionales imposés avant mesures.

| Domaine | Base existante constatée | Complément cible à concevoir/raccorder |
|---|---|---|
| Identité/foyer | profiles, households, student_profiles, teacher_profiles | Appartenance active, capacités, invitations, consentements, autonomisation |
| Classes/planning | groupes, groupe_membres, recurrence_rules, sessions | Offre publique vs classe, patterns, intentions, publication, places, occurrences/exceptions |
| Salle/présence | session_participants, session_events, livekit_webhook_deliveries, guardian_session_visit | Prévol cohérent, révocation active, réconciliation, budgets observation |
| Pédagogie | lesson_reports, learning_assignment, progression/evaluations | Projection par audience, validation/version et événement de payabilité |
| Supports | library_resource, resource_version, annotations, session_shared_content | Version de présentation autoritaire, droit d'annotation, snapshot et reprise |
| Finance | wallets, wallet_entries, payouts, payout_methods, webhook_events | Ledger par profil, obligations, encaissements/payouts, rapprochement, politiques, coffres et délégations |
| Communications | Pas de domaine complet retrouvé dans le catalogue public inspecté | Fils métier, messages, vocaux, annonces, communauté, Studio et notifications |
| Audit/exploitation | audit_logs, app_config/history | Corrélation, outbox/inbox, tâches durables, rétention exécutable, supervision |

Cette table ne prescrit pas des noms SQL nouveaux. Pour chaque besoin, réutiliser/étendre un objet existant ou justifier la création. Préserver les identifiants de personnes et les relations en production. Un grand groupe d'utilisateurs ne justifie pas à lui seul un multi-tenant commercial : Rewayah reste l'organisation actuelle ; préparer des scopes clairs sans inventer d'autres académies.

## 6. Contrat obligatoire frontend-backend

Pour chaque identifiant BR de l'annexe, Claude doit tenir une ligne versionnée :

`BR_ID | source+SHA | route+port+méthode | lecture/commande | DTO/version | identité/capacité/relation | table/vue/RPC/Edge | migration | erreurs | idempotence/concurrence | cache/realtime | tests | état de preuve`.

Les interfaces Dart réellement présentes priment pour le câblage technique ; si elles contredisent le produit, corriger le contrat par changement explicite. Ne pas deviner les noms RPC à partir d'un écran. Ne pas exposer directement une table simplement parce qu'elle ressemble au DTO.

Convention cible :

- IDs stables ; dates UTC ISO 8601 et fuseau IANA métier séparé ; heure de référence serveur.
- Montants entiers en unités mineures + devise ; validation des bornes de sérialisation Flutter Web/JS. Aucun float monétaire.
- Commande : `command_id`, version attendue, sujet cible validé, payload métier. Le serveur dérive acteur, organisation et droits.
- Réponse : identifiant, version, état réel, actions permises, raisons filtrées selon audience, correlation_id ; temps serveur si nécessaire.
- Erreurs typées : non authentifié, interdit, périmé/conflit de version, quota/capacité, ncurrence et exploitation/performance. Une même personne/agent ne s'auto-certifie pas comme revue indépendante.
7. Produire un bilan par contrat : SPÉCIFIÉ / CODE / TEST LOCAL / STAGING / DÉPLOYÉ / BLOQUÉ. Citer les preuves, les limites et les décisions réellement manquantes.

**Première tâche recommandée : lot A, sans déploiement.** Sortie attendue : manifeste de migration canonique + registre des ports/BR de la première verticale + plan de corrections SEC priorisées. Le présent audit n'a exécuté aucun de ces lots d'implémentation.

## 15. Points encore à compléter, sans réouvrir les décisions acquises

- Texte courant de politique commerciale/lancement et document économique pour valeurs exactes, bourses et formules ; ne pas recopier les démos comme barème.
- Autorité et détails du workflow d'émancipation ; documents enfant manquants identifiés par cockpit.
- Durées/finalités légales KYC, communications, objets temporaires et backups ; politique d'enregistrement si activation envisagée.
- Mise en œuvre MFA privilégiés, récupération et break-glass ; principe MFA Contrôleur déjà acquis.
- Contrats précis autorisant la Direction sur les nouveaux écrans/validations Comptable lorsque CPT-Q1 reste cité comme condition dans une source ; chercher une décision plus récente avant demande.
- Choix/opérationnalité PSP par corridor, secrets et webhooks test/PROD, plan de charge média, quotas et budget ; aucune transaction réelle autorisée par la seule mention d'un prestataire.
- RPO/RTO et paliers opérationnels financés ; secrets effectifs, backups et compte Cloudflare/LiveKit/Vercel non inspectés dans cette mission.

Ces lacunes bloquent leur fonctionnalité, pas automatiquement toute conception du backend. Faire les travaux indépendants déjà autorisés avant de solliciter une décision.

## 16. Sources et références

Sources utilisateur : blueprint V0.1 ; `Suivi Rewayah - Claude.pdf` (96 pages, export 06/10 01:24) ; `mapping backend(1).md` ; `mapping BD sup.md`. Le rapport historique de transfert est antérieur à la création STAGING : ne pas reprendre son « aucun staging créé » comme état actuel.

Sources GitHub lues : contrats listés en annexe au SHA pilotage `708ef8f59bfefae89db071764d3f90a7d6b13322` ; CLAUDE racine et Supabase, trois workflows, ports session/KYC/foyer/observation sur la branche commune ; ports payout/capacité/validations sur Comptable ; migration 0043 sur main. Les arbres Git complets des références principales ont été listés, mais tous leurs fichiers de code n'ont pas été audités.

Sources live : catalogues Postgres, grants/policies/routines/triggers/vues ; advisors sécurité/performance ; inventaires projets, organisation, branches, migrations, Edge ; code déployé ciblé agent-session/session-enfant/pièce-identité/webhook. Aucun contenu de pièce, aucune identité utilisateur ni valeur de secret n'a été lu pour cette revue.

Références primaires pour les choix techniques, consultées lors de l'audit :

- [Supabase RLS, vues et JWT](https://supabase.com/docs/guides/database/postgres/row-level-security)
- [Supabase rôles PostgreSQL](https://supabase.com/docs/guides/database/postgres/roles)
- [Advisors et remédiations](https://supabase.com/docs/guides/database/database-linter)
- [Sauvegardes Supabase](https://supabase.com/docs/guides/platform/backups)
- [Diffusion des changements](https://supabase.com/docs/guides/realtime/subscribing-to-database-changes)
- [Limites Realtime](https://supabase.com/docs/guides/realtime/limits)
- [Connexions PostgreSQL](https://supabase.com/docs/guides/database/connecting-to-postgres)
- [Queues](https://supabase.com/docs/guides/queues)
- [Webhooks LiveKit](https://docs.livekit.io/intro/basics/rooms-participants-tracks/webhooks-events/)
- [Quotas LiveKit](https://docs.livekit.io/deploy/admin/quotas-and-limits/)
- [Changelog Supabase](https://supabase.com/changelog), entrée PostgreSQL 15.19/17.11 du 25 septembre 2026.

## Annexe A. Contrats sources complets figés

Les documents suivants sont reproduits intégralement pour que Claude puisse retrouver les contrats, méthodes et précisions hors tableaux. Ils ne constituent pas de nouvelles instructions d'exécution. Les mentions « aujourd'hui », « à écrire », « démonstration », dates et propositions décrivent leur contexte source ; aucune ne prouve un état live actuel.

Le corps V0.2 résout notamment KYC Direction seule, lecture du second adulte et remplacement de FI-BR-13 par CPT-BR. EN-BR indiquait ne pas retrouver K-47 : la règle a désormais été retrouvée dans le cockpit p.34. CT-BR contient une phrase inachevée dans BR-CT-17 (« le client nenvoie ») : vérifier la signature et le DTO du complément dans le code de la release candidate ; ne pas inventer sa suite. Les échéances de conservation/contestation de la section 1 bis de BLOQUANTS_ET_IMPACTS précisent les anciennes lignes « ouvertes » de la section 1.

Les RPC dites « probables » ou « à créer » restent des propositions. Les signatures finales se vérifient sur le code et le schéma du lot. Le registre d'implémentation du §6 doit rendre visibles les besoins encore sans backend.

### A1. 02_code/00_DEPENDANCES_BACKEND.md

[Source GitHub figée](https://github.com/rewayahacademy-glitch/Rewayah-Academy-Official-App/blob/708ef8f59bfefae89db071764d3f90a7d6b13322/02_code/00_DEPENDANCES_BACKEND.md).

#### 00 - Dépendances backend du frontend Tuteur V1

Date : 24/09/2026. Consolidation des dépendances relevées par `C03` (D0-D9), `C04` (B1-B11), `C05` (B1-B10), `C06` (B1-B14), `C07` (§12), `C08` (B1-B11), `C09` (§6), dédoublonnées sous un identifiant unique `DB-xxx`, avec vérification ciblée des migrations (lecture seule).

**Rien ici n'est à réaliser dans ce lot** (mandat §3 : aucune migration, RLS, RPC, Edge Function, émission de token, politique serveur, finance, R2, webhook, LiveKit central). Chaque ligne donne le contrat attendu et le comportement frontend honnête en attendant, pour que l'écran existe sans faux succès.

Légende gravité : **B** bloque une recette réelle du parcours ; **M** dégrade le parcours (écran partiel) ; **F** confort ou exactitude. Colonne « Écran » : numéros de ligne de `00_MAPPING_ROUTES.md`.

Statut de preuve : **CODE** (lu dans les migrations ou le Dart), **MESURÉ** (lecture en production par `C07` le 24/09), **REVENDIQUÉ** (écrit par un document ou une archive, non remesuré), **DÉDUIT**.

---

##### 0. Ce que le serveur garantit déjà (à consommer, à ne pas re-simuler)

| Domaine | Garantie existante | Preuve | Statut |
|---|---|---|---|
| Appairage | Code 6 caractères, TTL `pairing_code_ttl_minutes` (10), empreinte SHA-256 seule stockée, usage unique sous verrou, un seul code vivant par élève, lien au foyer à la création, plafond d'appareils à la création et à la consommation, journal | `0004_inscription_kyc_appairage.sql:580-647, 659-716` | CODE, scénarios SQL écrits (`scenarios_etape3.sql:354-525`) mais rejeu CI `BLOCKED_INFRA` |
| Appairage | Révocation efface le jeton (`token_hash = null`), bornée au foyer | `0004:731-769` | CODE |
| Observation | Politique 2 visites, 120 s par visite, 240 s au total, `policy_version a2`, surcharge par groupe réglée par l'admin | `0036:190-198`, `app_config` | MESURÉ |
| Observation | Contrôle à l'entrée (`entrer_observation`) : rôle, compte valide, fenêtre, lien foyer par appartenance au groupe, politique, quota, un seul intervalle ouvert par (séance, observateur) | `0037:79-149`, `0032:478-480` | CODE |
| Observation | Jeton tuteur sans publication (micro, caméra, data), tuteur masqué des autres élèves | `0040`, `0041` (branche observation, appliquées) | CODE + MESURÉ (migrations présentes) |
| Observation | Journal `guardian_session_visit` lisible par l'observateur (RLS self) et l'admin | `0032:449-492` | CODE + MESURÉ (SELECT accordé) |
| Consentement | Acceptation immuable (ni update ni delete), unicité (profil, sorte, version), insert par soi (`profile_id = auth.uid()`) | `0004:221-264` | CODE (vérifié) |
| Temps | Fenêtre d'ouverture serveur `join_opens_at` / `join_window_minutes = 20`, grâce 15 min, horloge serveur `maintenant_serveur()`, heures rendues par `horloge_seance()` dans le fuseau du foyer et du groupe | `0030_tc_socle.sql:33-41, 67-76`, `0033_tc_vues_rpc.sql:427-488` | CODE |
| Bibliothèque | `ressources_du_groupe` rejoue la visibilité par ressource | `0035_ressources_du_groupe_rejoue_visibilite.sql:101-112` (appliquée, `CONFIGURATION_BASELINE:124`) | CODE (le commentaire `routes_tc_b.dart:54-62` est périmé) |
| [critique] Observation | Support partagé lisible par l'observateur pendant sa visite : `entrer_observation` l'inscrit dans `session_participants`, la policy de lecture de `session_shared_content` vise tout participant | `0037:134`, `0032:425-436` | CODE ; seul le rendu manque (frontend, C07 §9) |
| [critique] Réserve sur §0 | `supabase/migrations/LISEZ-MOI-0035-0037-non-appliquees.md` (21/09) affirme `0035`-`0037` **non** appliquées ; `CONFIGURATION_BASELINE_2026-09-23.md:124` les mesure identiques en production le 23/09. La base (plus récente) prévaut, le LISEZ-MOI est périmé (nettoyage : chantier C0, pas la branche UI) | fichiers cités | REVENDIQUÉ par la base, non remesuré ici |

##### 1. Admission et consentements

| Id | Capacité manquante | Service attendu | Entrée | Sortie | Impact UI | Écran | Comportement frontend honnête en attendant | Sources | Grav. |
|---|---|---|---|---|---|---|---|---|---|
| DB-ADM-01 | Questionnaire pédagogique et offres | Appliquer `0043_offres_horaires_et_intentions.sql` ou la remplacer selon l'arbitrage X1 | - | `regles_academie`, `cohortes_age`, `langues_cours`, `v_parcours_onboarding`, `enregistrer_profil_apprentissage`, `offres_compatibles`, `choisir_offre_horaire` | Questionnaire et bloc parcours inertes en production (`bloc_parcours.dart:46-48` se tait) | 6, 14, C7 | Écran « Le questionnaire n'est pas encore disponible » explicite au lieu du silence ; aucune tranche ni langue codée côté client | C03 D0, C06 B13, C09 §6-2 | B |
| DB-ADM-02 | Consentement d'observation parentale enregistrable comme tel | Sorte dédiée (élargir le `CHECK` de `contract_acceptances.contract_kind`) **ou** décision d'intégrer le texte dans une nouvelle version de `guardian_terms` | (profil, sorte, version, variante responsable légal / élève adulte) | ligne d'acceptation | Sans elle, l'accord ne se distingue pas des autres conditions | C1, C2 | Afficher le texte exact du mandat paramétré par la politique effective, case non précochée. Enregistrement possible **aujourd'hui** par insert d'une nouvelle version d'une sorte existante (policy `contract_acceptances_self_insert`, vérifiée), mais seulement après décision P2 : sinon ne rien enregistrer et ne pas prétendre l'avoir fait | C03 D3, C07 §11, C09 K12 | M |
| DB-ADM-03 | Re-consentement des comptes existants | RPC `consentements_a_renouveler()` (sortes et versions requises manquantes) + règle serveur sur l'effet d'un refus ; `etat_dossier()` filtrant la version | appelant | liste (sorte, version, obligatoire) | `etat_dossier()` ignore la version (`0004:459-470`, vérifié) : bumper `VersionsContrat.courante` ne redemande rien à personne, contrairement au commentaire `versions_contrat.dart:3-6` ; un compte actif n'atteint plus `/attente` | C2 | Écran `/tuteur/compte/consentements` construit et testé en simulation, non activé avant P2 ; la liste des acceptations signées reste lisible (Compte > Informations légales) | C03 D4, C08 B9, C09 §6-6 | M |
| DB-ADM-04 | Décrire ses élèves avant validation du dossier | Ouvrir `creer_profil_enfant` et le questionnaire à `pending_kyc` (fonction `compte_en_parcours()` prévue par `0043:190-192`) | appelant `pending_kyc` | profil élève créé | Aujourd'hui l'ajout est refusé tant que le dossier n'est pas validé (`0004:856-858`) et le routeur ferme `/tuteur/*` | 6, 11 | Parcours séquencé par porte : récapitulatif du dossier puis, une fois validé, enchaînement direct ajout de profil → questionnaire. Aucune liste d'élèves stockée localement pendant l'attente | C03 §9, C09 | M (point P5) |
| DB-ADM-05 | Cohortes 6-9 / 10-13 / 14-17 / 18+ et date de naissance canonique des mineurs | `definir_date_naissance_apprenant(membre, date)`, colonne protégée par RLS, cohortes dérivées | (élève, date) | âge, cohorte | Âge demandé deux fois (entier 3-18 puis tra-172) : « politique désactivée » n'existe qu'en démonstration. `kyc_admin_all` (FOR ALL admin, sans genre) laisse lire `kyc_documents` hors filtre. | RevueDossiersDepuisValidation | 01_RELEVE l.94, l.131-132 |
| AD-BR-16 (actualisation) | Notifier ou versionner la politique pour que les files ouvertes chez d'autres relecteurs se relisent (§15.2). Le client ne relit qu'au prochain rafraîchissement ; seule la session qui bascule relit. | dossiersEnAttenteProvider | spec l.1204, §15.4 |

##### Ajouts AD-10 (26/09/2026)

- **AD-BR-28 (complément AD-10)** : `etat_dossier()` doit rendre `correction_autorisee` et la liste des éléments à corriger. Sans eux, le client suppose la correction permise (clé absente = autorisée) ; « Ce dossier ne peut pas être modifié pour le moment. » ne s'affiche qu'en démonstration, par le point d'entrée `?demo=tuteur&dossier=refuse-fige` (AD-10 corrections ; plus aucun double de test). Emplacements : `EtatDossier.correctionAutorisee` (lib/core/dossier/etat_dossier.dart), `AttentePage`. Source : P-ADM-09.2 et 09.6.
- **AD-BR-26 (complément AD-10)** : aucun signal serveur de changement d'état. Relecture au retour (`AppLifecycleListener.onResume`) et bouton « Actualiser l'état du dossier » sont un palliatif client ; un compte validé pendant que l'application reste au premier plan ne bouge pas avant l'un des deux. Besoin : Realtime ou équivalent. Emplacement : `_AttentePageState._relire`. Source : P-ADM-11.1. **À arbitrer (K-09)** : ce palliatif AJOUTE des appels existants à de nouveaux déclencheurs : à chaque retour dans l'application et à chaque « Actualiser », un appel `etat_dossier()` et un `auth.refreshSession()` (`SourceSessionSupabase.rafraichir`). Variante possible sans serveur : ne rafraîchir la session que si `etat_dossier()` rend un statut de compte différent ; non appliquée faute d'arbitrage.
- **AD-BR-29 (rappel AD-10)** : aucune politique de dispense ; l'adaptateur de production rend toujours `ExigencePiece.requise` (revue_dossiers_depuis_validation.dart:185). « Aucune pièce requise pour ce dossier. » et AC-12 ne sont atteignables qu'en démonstration. Le portail lit une clé `piece_requise` (absente = vraie, comportement actuel) pour ne jamais demander de pièce à une famille dispensée refusée ; besoin : `etat_dossier()` doit la rendre. Emplacement : `EtatDossier.pieceRequise`.
- **AD-BR-06 (complément AD-10)** : `decider_dossier(p_document_id)` décide par pièce ; un dossier sans pièce (dispensé ou incomplet) ne peut être ni validé ni refusé en production, alors que P-ADM-08.4 autorise le refus.
- **AD-BR-02 (complément AD-10)** : pas de révision de dossier en production ; une resoumission crée une nouvelle ligne `kyc_documents` pending, vue comme un nouveau document. AC-13 garanti seulement en démonstration (l'interface ne reprend pas les cases grâce à la clé `id#revision`).
- **AD-BR (nouveau, AD-10)** : `etat_dossier()` ne sait pas dire « pièce validée, autre condition restante » ; le portail affiche alors « en cours de vérification ». En production `decider_dossier` active toujours un compte `pending_kyc`, donc le cas n'existe qu'en démonstration (conséquence documentaireSeule, test T9). Besoin : état d'accès réel et condition restante. Source : P-ADM-11.3.
- **AD-BR-27 (clos côté client)** : la promesse de notification du portail est retirée (`attente.enVerification` = « Nous vérifions votre dossier. »). La réintroduire exige un service réel qui garantit l'envoi.
- **AD-BR-03 (rappel AD-10)** : la clé `dossiers.journalisation` (« Chaque consultation de pièce est inscrite au journal d'audit… ») est supprimée ; elle ne revient qu'une fois la lecture branchée sur l'audit `kyc_document_open` par pièce.

##### HL-A-6 : KYC enseignant seulement (27/09/2026, K-47, deviennent BR-1)

Décision du directeur (K-47, prime sur la spec 03 et l'ADR-014 sur ce point) : pièce d'identité et validation par l'administration pour l'ENSEIGNANT seulement. Le tuteur ne dépose aucune pièce et n'attend aucune validation ; ses accords (accusé ADR-011, conditions tuteur) restent. Côté client (ui/admin-v1, HL-A-6) : `EtatDossier.pieceExigee` est faux pour `guardian` même sans `piece_requise`, un tuteur n'a plus d'état « refusé » ni « en vérification » mais `accesEnPreparation` (« Votre compte est créé. L'ouverture de votre compte n'est pas encore automatique. Vous n'avez aucun document à envoyer. L'académie peut l'ouvrir pour vous : joignez-la. », corrigé en HL-A-6 fin, plus aucune promesse « en cours »), et `deciderRedirection` renvoie un guardian qui demande `/attente/piece` sur `/attente`. Tant que BR-1 n'est pas fait, un tuteur réel reste enfermé sur `/attente` par le serveur.

- **BR-1.a statut initial du tuteur** : `creer_profil_inscription` (0004:393-407) écrit `pending_kyc` en dur pour tous les rôles (I2, :403-405) ; `profiles.account_status` vaut `pending_kyc` par défaut (0003:23-24, ADR-014). Besoin : pour `p_role = 'guardian'`, naître dans un statut qui ouvre l'accès sans validation humaine (`active`, ce qui révise ADR-014 et I2, ou un statut « client » avec sa porte). `teacher` inchangé. `guard_profile_privileged_columns` (0001:539-550) reste seul maître des changements de statut ultérieurs.
- **BR-1.b porte d'accès** : `app_account_valid()` (0001:412-423) ferme toute lecture à un `pending_kyc`. Le tuteur fraîchement inscrit doit la passer (par BR-1.a ou une règle guardian). Précédent : `compte_en_parcours()` (0043:174-188) accepte déjà `pending_kyc` pour l'onboarding. Côté client, rien à changer : la garde lit le statut (`session_state.dart:184`) et mène un compte actif à `/tuteur`.
- **BR-1.c file ADM-02 réservée aux enseignants** : `dossiers_en_attente` (0029:109-119 et :141-145) doit ajouter `and p.role = 'teacher'` dans ses deux branches ; le compteur de l'Accueil admin (`dossiersEnAttenteProvider`) en dépend. Filtre client posé (HL-A-6, côté admin) dans l'adaptateur `RevueDossiersDepuisValidation` (liste, détail, pièce, décision, relecture : `role == teacher`, un rôle illisible est écarté), sans nouvel appel ; le compteur de l'Accueil admin et la page Comptes (colonne Pièce, filtre « attendent une décision ») comptent ENCORE les tuteurs `pending_kyc` jusqu'à BR-1.c.
- **BR-1.d `etat_dossier()`** (0004:431-484) : rendre `piece_requise = (role = 'teacher')`, ne rendre aucun état de pièce pour un guardian (`piece_statut` nul), et ajouter `correction_autorisee` (AD-BR-28, enseignant). AD-BR-29 devient sans objet pour la famille.
- **BR-1.e dépôt fermé au tuteur** : `peut_deposer_piece_identite` (0034:274-303) et la policy `kyc_guardian_insert` (0004) laissent un guardian déposer une pièce pour son foyer ; à retirer (ou à limiter si une pièce d'élève reste voulue : question au directeur).
- **BR-1.f activation enseignant** : `decider_dossier` (0004:523-571) garde l'exigence de pièce ; ajouter la garde `p.role = 'teacher'` pour ne plus décider une pièce de guardian.
- **BR-1.g accès par paiement** : aucune table de paiement client, aucun webhook ni RPC qui écrirait `account_status` ou `access_until` après un paiement, aucune information bancaire du tuteur (`payout_methods` sert au versement du personnel). `access_until` (0001:79) n'est écrit que par l'administration. Besoin à arbitrer : quel événement ouvre l'accès (paiement encaissé, moyen de paiement enregistré, ou ouverture immédiate avec accès limité) et par quelle écriture serveur.
- **BR-1.h comptes existants** : migration des tuteurs déjà en `pending_kyc` vers le statut client, et sort de leurs lignes `kyc_documents` (conserver, purger selon `purge_at`, ou marquer hors objet).
- **Démonstration (client, HL-A-6)** : les dossiers démo D02 (Amina Benali), D07 et D10 passent en `AppRole.teacher` ; D03 « famille dispensée » (guardian) est RETIRÉ (HL-A-6 côté admin), ainsi que `ExigencePiece.dispensee`, `EtatPieceRevue.nonRequise`, la ligne « Aucune pièce requise » et le type « Tuteur » de la file ; `documentaireSeule` reste (texte neutre, porté par D02 enseignant). Clé i18n `dossiers.revue.pieceNonRequise` purgée (HL-A-6 fin). Le point d'entrée `?demo=tuteur&dossier=refuse|refuse-fige|verification` montre donc une enseignante ; son renommage en `?demo=enseignant&dossier=…` reste à faire.

###### HL-A-6 fin : corrections d'audit (27/09)

- **BR-1.c (choix)** : AUCUNE porte admin pour ouvrir un tuteur avant BR-1. Raison : `decider_dossier` exige `p_document_id`, donc un tuteur sans pièce n'a jamais pu être ouvert depuis ADM-02 ; garder les tuteurs dans la file aurait remis le KYC tuteur. Conséquence assumée : avant BR-1, un tuteur réel `pending_kyc` ne s'ouvre que par une écriture serveur (hors application). L'écran `/attente` le dit (« pas encore automatique », « l'académie peut l'ouvrir pour vous : joignez-la ») au lieu de promettre une ouverture en cours. BR-1.a/b supprime l'impasse.
- **BR-1.c (Accueil admin)** : les lignes « À traiter / Dossier d'identité de … » sont filtrées côté client (enseignants seulement, même cache) ; la tuile compteur `indicateurs.dossiersEnAttente` compte ENCORE les tuteurs jusqu'à BR-1.c, et peut donc différer de la longueur de la liste.
- **BR-1.d (rôle illisible)** : côté client, un profil sans rôle lisible s'affiche « illisible » avec Réessayer et n'exige aucune pièce (pièce exigée seulement si `role = teacher`). `etat_dossier()` doit toujours rendre le rôle.
- **BR-1.g (textes)** : les textes tuteur « validé / dossier validé » (appairage `comptePhrase`, foyer `enfantAttente`, `compteNonValide`) disent désormais « compte / accès ouvert » ; à reformuler encore (« après le paiement » ?) selon l'arbitrage BR-1.g.
- **Question directeur (K-47, genre)** : l'étape Genre reste posée au tuteur mais n'a plus d'explication (la raison KYC est réservée à l'enseignant). Faut-il encore demander le genre au tuteur, et pour quelle raison réelle (appariement enseignant/enseignante ?), ou la rendre facultative ? Non tranché ici (on ne refait pas les étapes).
- **Démonstration** : `?demo=tuteur&dossier=…` est documentée comme démonstration ENSEIGNANT (code) ; le parcours tuteur voulu est `?demo=tuteur` sans `dossier` (arrivée directe sur `/tuteur`). Pas de variante `dossier=acces` en démo (elle exigerait un dossier tuteur dans l'état partagé de la file admin) : l'état « attente d'ouverture » est prouvé par la planche (écran 16) et les tests `/attente`.

##### AD-BR, étape 890 : synthèse des besoins serveur de la spec 03 (§16, §17, §28), 02/10/2026

Cette section regroupe en une ligne par besoin ce que le serveur doit faire pour la spec 03 (`projet/ressources:specs/03_admin_validation_dossiers/03_ADMIN_VALIDATION_DOSSIERS_V1_2.md`, §15 à §17 et §28). Elle ne remplace pas les sections ci-dessus : chaque ligne renvoie aux anciens identifiants AD-BR-nn et BR-1.x. Rien n'est codé avant BR-1 (K-28). Les noms de RPC sont des propositions de la spec (§17, l.1295) : à BR-1, on préfère une RPC existante si elle couvre le besoin.

Ports relevés sur `origin/ui/admin-v1` (a8dfcb34). Abréviations : **PRD** = `lib/core/capacites/port_revue_dossiers.dart` ; **PPK** = `lib/core/capacites/port_politique_revue_kyc.dart` ; **RDV** = `lib/core/capacites/revue_dossiers_depuis_validation.dart` (adaptateur de production provisoire) ; **DEMO** = `lib/features/demo/dossiers_demo.dart`. Providers : `portRevueDossiersProvider` (PRD:403, indisponible par défaut), `portPolitiqueRevueKycProvider` (PPK:58), `politiqueRevueKycProvider` (PPK:65), `peutReglerPolitiqueKycProvider` (PPK:74), `dossierPourRevueProvider` (`lib/features/admin_dossiers/etat_file_dossiers.dart:128`), `decisionsDossiersProvider` (`lib/features/admin_dossiers/decision_dossier.dart:241`), `dossiersEnAttenteProvider` (`lib/core/dossier/service_validation.dart:258`).

| N° | Opération serveur | RLS : qui lit, qui écrit | Audit | Atomicité | Concurrence | Politique de genre (serveur) | Port Dart | Démonstration simule | Anciens n°, source |
|---|---|---|---|---|---|---|---|---|---|
| BR-AD-01 | RPC `list_reviewable_dossiers(curseur, limite, rôle?)` : une ligne par personne, éléments minimaux, curseur suivant, total fiable, tri date de soumission croissante puis id ; enseignants seulement (K-47). | Lecture : relecteur avec capacité de revue prouvée et périmètre ; aucune écriture. Aucun `object_key` rendu. | Pas d'audit par lecture de file (la spec ne l'exige pas). | Sans objet (lecture). | Autorisation et filtres AVANT pagination et compteur ; curseur stable. | Si `genre_reviewer_enforced = true`, filtre appliqué par le serveur avant pagination ; si `false`, aucun filtre ni refus fondé sur le genre. | `PortRevueDossiers.listerDossiers` (PRD:330) | `RevueDossiersDemo` (DEMO:357) ; production : RDV:133 lit `dossiers_en_attente` et dédoublonne | AD-BR-01, BR-1.c ; §17.1, §17.6, §16.2 |
| BR-AD-02 | RPC `get_dossier_for_review(dossier_id)` : détail minimal, état, révision du dossier et version du document, vérifications (id stable, origine, obligatoire, état, modifiable), accords applicables, `can_validate`, `can_reject`, `can_view_document`, blocages distincts, conséquence de la décision. | Lecture : relecteur autorisé du périmètre. Erreurs `not_found`, `forbidden`, `stale`, `temporarily_unavailable`. | Pas exigé pour la lecture du détail. | Sans objet. | La révision rendue sert d'`expected_revision` à la décision. | Même règle que BR-AD-01 : le serveur refuse le dossier hors politique, jamais l'écran seul. | `PortRevueDossiers.dossierPourRevue` (PRD:337) | DEMO:357 ; production : RDV:169 reconstruit depuis la file, révision 0 | AD-BR-02 ; §17.2 |
| BR-AD-03 | RPC ou Edge `request_kyc_documenme-Uni vers EEE couvert par l'adéquation britannique ; vérifier les sous-traitants Cloudflare hors EEE (DPA, UK Addendum). |
| B10 | Capture bloquée : **oui**. Le filigrane **n'apparaît que lorsqu'une capture est tentée**, jamais en permanence. | Blocage de capture (Android) et détection (iOS) ; filigrane affiché à la tentative. |
| B11 | Le brouillon **ne sort jamais de l'application**. | Stockage local chiffré, hors sauvegarde et hors partage, effacé après l'envoi. |
| B12 | Élèves, parents et enseignants, pour les choix du titulaire (une offre par beneficiaire, un, plusieurs ou tous, F11), un recapitulatif arrete par le serveur avec son identifiant : une ligne par beneficiaire (qui recoit, montant paye, quantite de solde attribuee, remise seulement si elle s'applique avec son libelle, statut de l'attribution) et le total, tous deja rediges, jamais additionnes dans Flutter ; rien d'autre sur le second adulte (ni Classe, ni niveau, F6, F10), rien au second adulte rattache (E3, F7) ; aucun texte rendu ne contient le mot admin (K-53.6) ; tests d'acces horizontal (un titulaire ne lit et ne verifie que pour les beneficiaires de son foyer), revue securite separee (doc section 17). | `portRechargeFoyerProvider` rend `CapaciteIndisponible('EA-BR-24')` (etat « Recharge pas encore disponible ») ; la demonstration le surcharge (`_RechargeDemo`) : les beneficiaires des soldes d'EA-9 et deux offres de demonstration (« 5,00 € » et « 10,00 € », prix de la planche 4.3) qui attribuent « Solde de démonstration A » et « Solde de démonstration B », sans quantite d'unites ni taux deductible (revue EA-10, 00_MAQUETTES 4.1 C3 et 4.2 C2, E2), aucune remise rendue, statut « En attente du paiement », total fixe d'avance pour chaque combinaison par le serveur de demonstration, jamais additionne (`DonneesAdulteDemo.recapitulatifRecharge`) ; rien n'est envoye. |
| EA-BR-25 | EA-10 | Paiement d'une recharge (`payer_recharge`) : paiement du seul recapitulatif arrete par EA-BR-24, idempotent par la cle fournie par le client (une nouvelle tentative apres coupure ne paie pas deux fois), aucun moyen de paiement ni numero de carte rendu au client, meme masque (F13), etat du paiement deja redige et rendu tel quel (jamais un succes deduit par le client), attribution du solde a chaque beneficiaire seulement apres confirmation du prestataire, prestataire a choisir (doc section 20.8) ; soldes (EA-BR-23) et historique (DB-CPT-03, EA-BR-16) relus ensuite ; audit, tests d'acces horizontal (un titulaire ne paie que son propre recapitulatif), revue securite separee (doc section 17). | `PortRechargeFoyer.payer` rend `CapaciteIndisponible('EA-BR-25')` : etat honnete « Paiement pas encore disponible. Aucun paiement n'a ete effectue. », jamais « Paiement reussi » ; la demonstration rend le meme etat, la coupure pour « Erreur reseau » (D5 : « Le paiement n'a pas ete confirme. Verifiez avant de reessayer. ») et la latence simulee pour « Double soumission » ; rien n'est paye. |
| EA-BR-26 | EA-10 | Paiement de recharge non confirme (D5) : quand la reponse d'un `payer_recharge` (EA-BR-25) est perdue, le serveur doit rendre l'etat de ce paiement (en cours, confirme, refuse) a toute relecture des paiements du foyer (EA-BR-23, historique) et a toute nouvelle verification (EA-BR-24) du meme titulaire, et refuser ou signaler un nouveau paiement des memes beneficiaires sous une autre cle tant que le premier n'est pas tranche, pour qu'une recharge rouverte ne paie jamais deux fois ; audit, tests d'acces horizontal (un titulaire ne lit que ses propres paiements), revue securite separee (doc section 17). | Apres une coupure au paiement, `RechargeFoyerPage` garde la meme cle, retire « Modifier » et le retour aux choix, garde l'avertissement D5 ; le retour mene aux paiements du foyer, ou l'on verifie. Une recharge rouverte ensuite tire une nouvelle cle : seul le serveur peut le voir. La demonstration ne paie rien. |
| EA-BR-27 | EA-11 | Demande de reprise du foyer, cote second adulte (`reprise_foyer`, `deposer_reprise_foyer`) : pour le compte connecte seulement, s'il est le second adulte rattache, l'etat de sa demande rendu par le serveur (aucune, deposee, refusee par le titulaire, en attente de l'administration, validee, refusee ; doc section 18, cas 16 a 20) avec la date du depot et, tant que le titulaire n'a pas repondu, la date a partir de laquelle l'administration pourra l'examiner, rendue telle quelle (doc section 12.3, F17, jamais 30 jours calcules dans Flutter) ; depot idempotent par la cle fournie par le client (une nouvelle tentative apres coupure ne cree pas de seconde demande), une seule demande active par foyer, motif « Deces declare du titulaire » (section 12.1), aucune piece demandee tant que la procedure n'est pas definie (section 20 point 10) ; notification du titulaire dans son centre de notifications (DB-CPT-04, texte du doc section 12.2, sans le nom du demandeur, Q11) et de l'administration (section 12.4, dossier de la vague Admin) ; aucune titularite transferee sans decision auditee de l'administration, jamais au jour 30 ni sur la seule inactivite, suspension, verrouillage ou echec de paiement (sections 12.3, 12.8, 13) ; apres validation, seule la gouvernance du foyer est transferee, jamais les identifiants, messages, conversations, historique personnel, moyens de paiement, pieces ni donnees privees du titulaire (sections 12.6, 12.7) ; dire si une nouvelle demande est possible apres un refus (non tranche par le doc) ; suites de la demande notifiees au second adulte ; demande traitee comme sensible (F23) ; aucun texte rendu ne contient le mot admin (K-53.6) ; audit, tests d'acces horizontal (seul le second adulte rattache d'un foyer depose ou lit la demande de ce foyer), revue securite separee (doc section 17). | `repriseFoyerProvider` et `PortRepriseFoyer.deposer` rendent `CapaciteIndisponible('EA-BR-27')` (etat « indisponible ») ; la demonstration les surcharge (`DonneesAdulteDemo.reprise` : aucune demande hors des cas 16 a 20, depot le 29 septembre 2026, examen possible le 29 octobre 2026, deux donnees fixes ; `_RepriseDemo` : depot enregistre puis la page relue en « Deposee », coupure pour « Erreur reseau » (D5), latence simulee pour « Double soumission ») ; la cloche du second adulte porte une notification par suite (refusee par le titulaire, attente de l'administration, validee, refusee, libelles provisoires D4) ; rien n'est envoye. |
| EA-BR-28 | EA-11 | Demande de reprise du foyer, cote titulaire (`demande_reprise_recue`, `refuser_reprise_foyer`) : pour le compte connecte seulement, s'il est titulaire du foyer vise, la demande qui le concerne (a refuser, ou deja refusee par lui), sans rien dire du demandeur au-dela du doc section 12.2 (Q11) ; refus idempotent par la cle fournie par le client, sans confirmation exigee, qui ne transfere rien et que l'administration voit (section 12.5) ; dire si le refus reste possible apres 30 jours sans reponse (la demonstration le permet, CHOIX DE DEMONSTRATION) ; `foyer_titulaire` (EA-BR-14) rend sur la place occupee qu'une demande attend la reponse du titulaire (ligne de Ma famille, UX_REVIEW_07 ligne 18 d) ; aucun texte rendu ne contient le mot admin (K-53.6) ; audit, tests d'acces horizontal (un titulaire ne lit ni ne refuse que la demande visant son foyer), revue securite separee (doc section 17). | `demandeRepriseRecueProvider` et `PortRepriseFoyer.refuser` rendent `CapaciteIndisponible('EA-BR-28')` ; la demonstration les surcharge (`DonneesAdulteDemo.repriseTitulaire` : a refuser pour les cas 16 et 18, refusee pour le cas 17 ; `PlaceOccupee.repriseARepondre` sur la ligne de la place ; notification du doc section 12.2 datee du 29 septembre 2026 dans la cloche de l'Accueil) ; rien n'est envoye. |



### A9. 17_finance/FI-BR.md

[Source GitHub figée](https://github.com/rewayahacademy-glitch/Rewayah-Academy-Official-App/blob/708ef8f59bfefae89db071764d3f90a7d6b13322/17_finance/FI-BR.md).

#### Vague Finance : besoins serveur (pour BR-1)

Rien n'est branché dans cette vague (guide §15, K-28). Chaque ligne dit ce qu'il faudra au serveur, et ce que la démonstration montre en attendant. Exigences communes à toutes les lignes (guide §5.7 « invariants » et §15) : idempotence de toute écriture, historique en ajout seul, audit, tests d'accès horizontal (un tuteur ne lit jamais un autre foyer, un enseignant jamais une donnée de famille), revue de sécurité séparée, aucun mot « admin » dans un texte rendu à un client (K-53.6).

Écrit le 02/10/2026 (FI-0). Les lignes seront complétées étape par étape, puis relues en FI-12.

| Réf. | Étape | Besoin | Aujourd'hui en démonstration |
|---|---|---|---|
| FI-BR-01 | FI-1c, FI-11a | **Politique commerciale effective**, versionnée et datée : tarifs enfant et adulte, essai (nombre, activation), remises par rang familial, base et plafond horaires, cibles et maximum de groupes, aide Internet, capacités enfant, adulte, débutant, minimum d'ouverture, conservation de place, rails activés, règles de relance, marge de référence, budgets non contraignants (guide §5.7). Lecture par tous les écrans qui en dépendent. | `finance_demo.dart` porte la politique de lancement du guide §1 ; ports neutres en production. |
| FI-BR-02 | FI-11b, FI-11c | **Brouillon, publication, historique** d'une politique : date d'effet, comparaison avec la version active, aperçu ; jamais rétroactif sur une facture payée (§1.3) ; écriture réservée à la direction, auditée. | « Publier » arrive sur un état « non disponible avant le branchement ». |
| FI-BR-03 | FI-4, FI-6a | **Finance d'un profil élève** : solde individuel (unités mineures + code ISO), période financée (mois, « jusqu'au »), prochain débit (date, montant), mensualité et ses lignes déjà arrêtées (tarif, remise de rang, réduction calendrier, avoir, taxe, total), état (financé, essai n/2, manque X, en confirmation, expiré, pause, à régulariser avec fin de conservation). Remplace EA-BR-23. | Foyer Mariam, Ibrahim, Aïcha + 6 jeux du guide F2, montants marqués « (démonstration) ». |
| FI-BR-04 | FI-4, FI-5 | **Synthèse du foyer en lecture** : total des soldes, à payer ce mois, profils financés, paiements du mois. Jamais un solde dépensable ni une autorisation (FIN4-07). | Valeurs du foyer de démonstration. |
| FI-BR-05 | FI-6b | **Mouvements d'un profil** (recharge, mensualité, avoir), en ajout seul, filtrables par personne ; **reçu** téléchargeable quand il existe. | Liste de démonstration ; « Télécharger le reçu » sur un état honnête. |
| FI-BR-06 | FI-7, FI-8 | **Commande de recharge multi-profils** : un paiement externe, une allocation nominative par profil (§1.6), total et taxe arrêtés par le serveur avant paiement, clé d'idempotence, huit états, confirmation par le webhook du prestataire avant tout crédit, double confirmation = un seul crédit, reprise d'une commande en `awaiting_confirmation`. Remplace EA-BR-24, EA-BR-25, EA-BR-26. | Double de port qui parcourt les états ; aucun paiement. |
| FI-BR-07 | FI-7 | **Moyens de paiement enregistrés** (carte masquée, autre carte, portefeuille numérique) par le prestataire web ; aucune donnée de carte chez Rewayah. | Trois choix de démonstration ; rail `WEB_STRIPE` seul. |
| FI-BR-08 | FI-9a | **Droit d'accès par période financée** : bouton Rejoindre ouvert ou non par le serveur, compteur d'essai (2 au plus, consommé si l'élève est absent d'une séance ouverte, pas si Rewayah annule, §1.2), conservation de place (7 jours au lancement) puis libération selon la règle opérationnelle ; pour l'enfant, un état neutre sans cause. | États d'accès de démonstration ; Rejoindre jamais lié au solde. |
| FI-BR-09 | FI-6a, FI-9a | **Débit mensuel** : mois civil, prorata du premier mois payant après l'essai, aucun débit partiel, aucune dette empilée après la fin réelle de l'inscription (§1.1, §1.7). | Prochain débit et manque à financer rendus par la démonstration. |
| FI-BR-10 | FI-1c, FI-7 | **Taxes** : calcul et taux côté serveur, ligne séparée du tarif académique, total réel avant confirmation, taxe collectée jamais comptée en revenu (§1.8). | Une ligne « Taxe applicable » de démonstration dans un seul jeu. |
| FI-BR-11 | FI-10 | **Revenus estimés de l'enseignant** : par séance assurée, sièges éligibles (financé présent ou absent, essai présent, jamais au-delà de la capacité), taux effectif plafonné, aide Internet séparée, relevé ; aucune donnée de famille rendue (§1.4, §5.5). Paie réelle et prestataire de versement hors lot (ADR-007). | Jeux du guide F6. |
| FI-BR-12 | FI-11a | **Vue globale** : encaissé, revenu académique, paie enseignants, marge projetée, impayés, essais en cours, soldes créditeurs, alertes ; encaissement, revenu, solde client, charge et marge séparés (§5.6). | Jeux du guide F7 (vide, mois sans activité, impayés, soldes créditeurs, longue liste). |
| FI-BR-13 | FI-11a | **Rôle comptable** (`accountant`) : lecture de la même Finance, permissions adaptées, aucune politique éditable sauf décision contraire (§4). | Hors lot ; `/comptable` inchangé. |
| FI-BR-14 | FI-1c | **Tables existantes `wallets` et `wallet_entries`** (`ADMIN_FINANCE_CONFIGURATION.md:72`) : vérifier qu'elles portent un solde **par profil** ; un portefeuille de foyer est interdit (FIN4-07). À remodéliser avant tout branchement si besoin. | Sans objet. |
| FI-BR-15 | FI-1c | **Rails futurs** `IOS_STOREKIT` et `ANDROID_PLAY` : interfaces prévues, non activées, jamais affichées au lancement (§1.6). | Rail web seul. |
| FI-BR-16 | FI-4, FI-9a | **Notifications et relances** d'impayé, visibles dans le centre de l'application, selon la règle de relance de la politique ; jamais envoyées à l'enfant avec une cause financière (§1.7). | Aucune notification envoyée. |
| FI-BR-17 | FI-9b | **Finances de l'élève adulte autonome** : les mêmes données que FI-BR-03, FI-BR-05 et FI-BR-06 pour son seul profil. | Vue personnelle de démonstration. |
| FI-BR-18 | FI-4, FI-7 | **Second adulte du foyer** : il lit les paiements (K-53.8) ; la recharge reste au titulaire tant que le directeur ne dit pas autre chose. | Vue du conjoint sans bouton de recharge. |
| FI-BR-19 | FI-2 | **Couleur d'accent du profil choisie par le tuteur** (décision du directeur 04/10) : une clé de jeton par profil élève, écrite par le titulaire seulement, lue par tous les écrans du foyer ; jamais une couleur libre (hex), seulement une clé de la liste des jetons d'accent de profil. | Choix gardé en mémoire de la démonstration ; port neutre en production. |

##### Relu par FI-12 (04/10)

Relecture faite le 04/10/2026 sur le worktree `rc-2` (commit de base `930cf21f`), par `grep -rn "CapaciteIndisponible('" lib/core/capacites` : chaque port neutre de production dit la référence qu'il attend. Le détail par fichier et par ligne est dans `05_recette/FI/FI_RAPPORT.md` §8.

###### FI-BR utilisés par les ports, et ce qui manque côté serveur

| Réf. | Port (méthodes) | Écrans qui l'attendent | Ce qui manque côté serveur |
|---|---|---|---|
| FI-BR-01 | `port_politiques_commerciales.dart` : `active()`, `apercuFamille()`, `apercuEnseignant()` | Foyer, Recharge, Politiques | La politique effective versionnée, lisible par tous les écrans qui en dépendent ; le calcul des aperçus (famille 1 à 5 enfants, taux enseignant) fait par le serveur. |
| FI-BR-02 | `port_politiques_commerciales.dart` : `versions()`, `publier()` | Politiques (brouillon, comparaison, historique, Publier) | Brouillon, publication datée non rétroactive, historique en ajout seul, écriture réservée à la direction et auditée, réponse de publication confirmée. |
| FI-BR-03 | `port_paiements_foyer.dart` : `finances()` | Foyer, Fiche > Finances, Fiche > Accès, Compte > Accès | La finance de chaque profil (solde, période, prochain débit, mensualité détaillée, état, manque, fin de conservation) et la synthèse du foyer. FI-BR-04 n'a pas de méthode propre : la synthèse arrive par `finances()`. Jamais rendue au second adulte ni à l'enfant (lecture par rôle, `UX_REVIEW_08_FINANCE.md:96-106`). |
| FI-BR-05 | `port_paiements_foyer.dart` : `mouvements()`, `derniersMouvements()` | Fiche > Mouvements, reçu, Foyer à 1440 | Mouvements par profil en ajout seul, reçu avec sa répartition, les trois derniers mouvements du foyer. |
| FI-BR-06 | `port_recharge_foyer.dart` : `verifierMontants()`, `suivre()` | Recharge, Résultat (8 états) | Commande multi-profils, total et taxe arrêtés avant paiement, idempotence, huit états, crédit seulement après le webhook, reprise d'une commande en attente. |
| FI-BR-11 | `port_revenus_enseignant.dart` : `moisEnCours()` | Revenus | Revenus estimés par séance assurée, sièges éligibles, taux plafonné, aide Internet à part, aucune donnée de famille. |
| FI-BR-12 | `port_finance_direction.dart` : `vueGlobale()` | Vue globale | Les sept indicateurs du mois et les alertes, chacun séparé. |
| FI-BR-17 | `port_mes_finances.dart` : `finances()`, `mouvements()` | Mes finances de l'adulte autonome | Les données de FI-BR-03, 05 et 06 limitées au seul profil de la session. |
| FI-BR-19 | `port_accents_profils.dart` (lecture et écriture) | Foyer, fiche, recharge, résultat, reçu, toute carte de profil | La clé d'accent par profil, écrite par le titulaire seul, une clé de la liste des jetons, jamais une couleur libre. |

FI-BR sans port aujourd'hui (aucune référence dans `lib/core/capacites`) : 04 (passe par 03), 07, 08, 09, 10, 13, 14, 15, 16, 18. FI-BR-18 (second adulte) est une règle de lecture du serveur, sans port propre : la recette FI-12 la constate à l'écran (`fi12_compte_paiements_second_adulte_*`, aucun solde ni recharge).

###### Corrections proposées, reportées ici (non faites dans le code)

| Où | Aujourd'hui | Proposé | Pourquoi |
|---|---|---|---|
| `port_acces_foyer.dart`, `AccesFoyerIndisponible.acces()` | `CapaciteIndisponible('LOT-E')` | `CapaciteIndisponible('FI-BR-08')` | L'accès par période financée (Rejoindre, essais, conservation de place, copie neutre de l'enfant) est le besoin FI-BR-08 ; LOT-E n'est que le lot qui devait écrire l'adaptateur. |
| `port_recharge_foyer.dart`, `beneficiaires()`, `verifier()`, `payer()` | `CapaciteIndisponible('EA-BR-24')` et `('EA-BR-25')` | `CapaciteIndisponible('FI-BR-06')` | FI-BR-06 remplace EA-BR-24, 25 et 26 (ligne FI-BR-06 ci-dessus) : la table doit dire la même chose que les ports. |
| `port_paiements_foyer.dart`, `soldes()` | `CapaciteIndisponible('EA-BR-23')` | `CapaciteIndisponible('FI-BR-03')` | FI-BR-03 remplace EA-BR-23 (ligne FI-BR-03 ci-dessus). |

Ces trois changements sont une petite étape de code (une ligne par méthode, plus les tests qui lisent la référence) : à ranger dans FI-RC ou BR-1, pas dans FI-12, qui ne touche que la recette.



### A10. 18_supports_tableau/TB-BR.md

[Source GitHub figée](https://github.com/rewayahacademy-glitch/Rewayah-Academy-Official-App/blob/708ef8f59bfefae89db071764d3f90a7d6b13322/18_supports_tableau/TB-BR.md).

#### Supports et tableau : besoins serveur et temps réel (branchement BR-1)

Une ligne par besoin. Démonstration seulement jusqu'à BR-1 (K-28) : rien de ceci n'autorise un travail serveur dans le chantier TB (plan §14, §21). Relevé à TB-0 (02/10/2026) sur `corrections/revue-directeur-2026-10` @ `0796f75`, `supabase/` lu sans écrire. À compléter par chaque étape TB et par TB-12.

##### Temps réel (LiveKit Data Channels, plan §10)

- **TB-BR-01 Présentation** (support, version, page, affichage) : message fiable, état complet à une révision, appliqué d'un bloc. Réutiliser `typeRevisionEtatPartage`, `ServiceEtatPartage`, `ReducteurEtatPartage` et `sujetProtocolePedagogique` ; aucun second sujet ni second client.
- **TB-BR-02 Aperçu de trait et pointeur** : canal non fiable (lossy), lots au plus toutes les 40 ms pendant le geste, environ 1 200 octets (sous 1 300), numéros de lot. Vérifier que `TraitEnCours.pointsParPaquetParDefaut` (3 points) respecte la cadence.
- **TB-BR-03 Trait terminé** : message fiable, tracé compact (`simplifierTrait`), au plus 15 Kio de charge, découpage et assemblage bornés ; remplace l'aperçu.
- **TB-BR-04 Retirer, annuler, effacer** : messages fiables ciblés par identifiant, révision et déduplication ; jamais un remplacement global (annuler ne touche pas le trait d'autrui).
- **TB-BR-05 Enveloppe minimale** : version de protocole, séance, contexte de présentation, support/version/page ou tableau libre, identifiant d'opération, **auteur lu de l'identité de connexion** (jamais du message), révision, données. Le contexte empêche un vieux paquet de repeindre une autre page ou une page revisitée après effacement.
- **TB-BR-06 Demande d'état et snapshot** : réponse ciblée au participant (arrivée tardive, reconnexion), snapshot avec sa révision puis opérations postérieures ; écriture suspendue jusqu'à récupération ; trou détecté = demande d'état.
- **TB-BR-07 Arbitrage** : l'enseignant attribue la révision commune ; s'il est absent, aucun nouveau maître choisi en silence (contrat de remplacement existant ou indisponibilité).
- **TB-BR-08 Bornes** : taille de trait, nombre de traits, fréquence, données entrantes validées (un client autorisé peut envoyer un message malformé) ; files bornées, priorité aux changements pédagogiques sur aperçus et snapshots.
- **TB-BR-09 Adaptateur** : `AdaptateurTransportLiveKit` mappé sur `publishData` de la version du dépôt (`livekit_client ^2.12.0`), vérifié dans la documentation de cette version ; parler fiable / non fiable, jamais TCP / UDP.

##### Droits et identité

- **TB-BR-10 Autorisation d'écrire** : droit effectif côté serveur (capacité signée du jeton ou RPC), annoncé par message mais jamais créé par lui ; retrait immédiat ; aucun commit non autorisé appliqué (UX-20).
- **TB-BR-11 Rôles** : présenter, changer de page, ranger, effacer pour tous = enseignant seulement ; tuteur observateur et contrôleur en lecture seule de l'état partagé.
- **TB-BR-12 Quitter / Terminer** : distinguer sortie personnelle et fin pour tous si la capacité existe ; aucune confirmation ajoutée à une simple sortie.

##### État partagé et conservation

- **TB-BR-13 Affichage Support / Avec notes / Tableau** : `session_shared_content.display_mode` n'accepte que `page`, `verse`, `focus` (`0032_tc_catalogue.sql:404`, `ModeAffichagePartage`). L'affichage du plan est un **autre axe** (fond visible, calque visible) : champ ou valeur à ajouter au contrat par une migration autorisée à BR-1, jamais dans TB.
- **TB-BR-14 Tableau libre** : `annotation_layer` est rattachée à une ressource (`resource_id`) ; il faut un contexte « tableau libre de la séance » sans ressource, ou une ressource technique, à décider à BR-1.
- **TB-BR-15 Couches** : `annotation_layer` est par auteur (`auteur_profile_id`, index uniques) et `annotation_trait` une ligne par trait (gomme ciblée) : conforme au plan. Vérifier la politique de partage des couches des élèves autorisés (une couche par élève ou couche de séance de l'enseignant).
- **TB-BR-16 Snapshot durable** : instantané compact après opérations stabilisées, au changement de support ou au rangement, et en fin de séance ; écritures regroupées ; jamais un point par écriture ; jamais seulement à la fermeture d'onglet. Portée `temporaire` jamais écrite (règle de la base).
- **TB-BR-17 Point de reprise par support** : page et couches retrouvées en séance ; entre séances seulement si le contrat durable est branché. Sans lui, l'écran dit « Les notes sont conservées dans cette séance uniquement. ».
- **TB-BR-18 Statut de sauvegarde réel** : « Les notes de cette séance ne sont pas sauvegardées. » et « Réessayer » branchés sur le vrai résultat d'écriture durable, jamais sur `publishData`.

##### Fichiers, catalogue, cache

- **TB-BR-19 Fournisseur des pages** : relever le fournisseur réellement branché (R2 selon les sources canoniques, « Supabase Storage » dans un prompt ; `catalogue_local.dart:15` : aucun bucket de supports aujourd'hui). Un seul adaptateur de fichiers, aucun second stockage.
- **TB-BR-20 Pages immuables et versionnées** : dimensions canoniques et ratio fournis par le serveur ; source et licence vérifiées ; édition Hafs conforme pour toute page coranique ; aucune image générée.
- **TB-BR-21 Cache** : page courante et voisines, borné en mémoire et sur disque ; résolution selon l'écran et le zoom, même cadrage ; cache Web configuré, CORS, URL signées (`cached_network_image` seul ne suffit pas sur le Web) ; purge au retrait d'accès.
- **TB-BR-22 Catalogue de la classe** : ressources autorisées, couvertures, recherche, versions, rubrique Récents avec point de reprise (port catalogue réel).

##### Contexte de la salle

- **TB-BR-23 Enregistrement** : état effectif pour le témoin rouge ; inconnu = pas de témoin.
- **TB-BR-24 Contrôle** : « Contrôle possible » et « Contrôle actif » lus du contrat d'observation (`VisiteSeance`) ; un seul contrôle à la fois (BR-CT-18).
- **TB-BR-25 Profil** : titre Sayyid/Sayyida et âge (tutoiement A4) lus du profil réel.

##### Dépendances et mesures

- **TB-BR-26 perfect_freehand** (plan §9.5) : demande un ajout à `pubspec.yaml` (accord écrit, K-19). En démonstration, rendu par `_PeintreAnnotations` existant. Si le paquet est accepté, la même version sur tous les clients ; sinon, documenter l'algorithme commun.
- **TB-BR-27 Mesures sur appareils** : fluidité du trait, délai de page, délai du trait final, mémoire et trafic, sur smartphone modeste, iPad et Web, avec coupure et réordre de paquets (§15) ; jamais « zéro latence ».
- **TB-BR-28 Recette réseau réelle** : iPad vers smartphone et Web (cercle sur le même mot), deux élèves autorisés, reconnexion, coupure de l'enseignant, fermeture totale puis reprise (§15).



### A11. 19_communications/COM-BR.md

[Source GitHub figée](https://github.com/rewayahacademy-glitch/Rewayah-Academy-Official-App/blob/708ef8f59bfefae89db071764d3f90a7d6b13322/19_communications/COM-BR.md).

#### Communications V1 : contrats serveur pour BR-1 (K-28)

Complété par COM-0b (revue REVUE_COM-0.md, 04/10).

Le chantier est frontend seulement. Chaque besoin serveur s'ajoute ici (une ligne par besoin) et se branche à BR-1, jamais avant. Points de départ repris de la spec §34 (« risques volontairement non résolus ») ; COM-0 a nommé les ports et précisé les contrats (référence `origin/corrections/revue-directeur-2026-10` @ `f6ac3658`).

**Règle des ports** (seul modèle : `PortNotifications` / `NotificationsIndisponibles`, `lib/core/capacites/port_notifications.dart:34`, `:45`, `:50-59`) :
- interface `abstract interface class Port…`, implémentation de production **neutre** `…Indisponible(s)` dont chaque méthode rend `CapaciteIndisponible('COM-BR-nn')` (le code de la ligne ci-dessous), jamais un `StateError`, jamais une liste vide inventée ; l'écran rend alors `EtatSysteme(NatureEtat.indisponible)`, sans « Réessayer » (`lib/core/widgets/bloc_asynchrone.dart:27-28`, `:236`) (COM-BR-A09) ;
- écart connu, non modifié par COM : `EchangesIndisponibles` lève `StateError` (`lib/features/controleur/echanges_controleur.dart:109-123`), ce qui donne un échec avec « Réessayer » ; ce n'est pas un modèle. **Pour COM-F** : ajouter la famille `COM-BR-nn` (une ligne de ce fichier) au commentaire de `lib/core/capacites/capacite_indisponible.dart` (familles listées `:14-21`, rappel `:26`) ;
- un `Provider<Port…>` à côté du port ; la démonstration le remplace par `overrideWithValue` dans son fichier de voie, sous `environnementAutoriseDemo` ; `lib/main.dart` ne branche rien avant BR-1 ;
- toute action porte l'identifiant de son objet (fil, publication, canal, annonce), jamais « l'objet courant » (leçon 15) ; aucune URL de stockage, chemin ou jeton n'arrive à l'écran (§12) ;
- un widget ne lit jamais le rôle pour publier, programmer, modérer, ouvrir les paramètres d'un canal ou écrire dans un fil : il lit une capacité Communications (COM-BR-16), fermée par défaut.

| Code | Besoin | Écran ou composant | Port côté app (fichier) | Contrat attendu | État |
|---|---|---|---|---|---|
| COM-BR-01 | Schéma des fils métier, liés à un objet (Classe, élève, dossier, mission, remplacement ; et, si le contrat actuel l'autorise, séance, paiement ou objet financier, support ou signalement : spec §3.1 l.135-144) et paires autorisées §3.2 ; le serveur refuse toute paire marquée Non (§3.2 l.165-168 : enfant en Interface guidée, enseignant vers enseignant, famille vers famille, élève vers élève) ; un fil n'est rendu que si le serveur l'a autorisé pour cet utilisateur (COM-BR-A06) | Messages métier | `PortMessagesMetier` (`lib/features/com_messages/port_messages_metier.dart`) | `fils()` (résumé : objet lié nettoyé, interlocuteur autorisé, non-lus, action requise), `fil(filId)`, `filPourObjet(typeObjet, objetId)` (fil canonique, créé par le serveur s'il manque, comme `PortEchanges.filDeMission`) ; refus = fil absent, jamais un fil vide ; `marquerLu(filId)` (fait baisser les non-lus du résumé, spec l.413, l.669) (COM-BR-A03) ; `rechercher(texte)` (ThreadSearch, spec §18 l.1022-1036), résultats limités aux fils que la personne a le droit de lire, jamais plus que `fils()` ; réserve : un filtre local sur `fils()` peut suffire en V1, le besoin d'une recherche serveur est à confirmer à BR-1 (COM-BR-A05) | à écrire |
| COM-BR-02 | Envoi idempotent, accusé de réception (« envoyé » seulement après confirmation) | composers (`FilDiscussion`, `EtatEnvoiMessage`) | `PortMessagesMetier.envoyer(filId, texte, cleIdempotence)` ; `PortStudio.envoyer(...)` | le futur se termine sur l'accusé du serveur ; un échec dit « non confirmé » (leçon 10) ; la clé d'idempotence est générée par l'app et rejouée telle quelle | à écrire |
| COM-BR-03 | Stockage des vocaux (3:00 max) | VoiceMessageComposer | `PortEnregistreurVocal` (`lib/features/com_vocal/port_enregistreur_vocal.dart`) pour l'enregistrement local ; envoi par `PortMessagesMetier` / `PortStudio` | durée maximale vérifiée par le serveur, format, lecture par lien signé de courte durée jamais affiché ; enregistrement et permission micro exigent un paquet absent de `pubspec.yaml` (`record` ou équivalent) : décision à BR-1 ; stockage : réutiliser le domaine R2 `pieceJointeMessage` déjà déclaré et inutilisé (seau `rewayah-message-attachments`, `supabase/functions/_shared/r2/domaines.ts:36`, `:43`, `:58`) et sa forme de clé `messages/<conversation>/<pièce>` (`cles.ts:34`, `:80`), aucun nouveau seau (COM-BR-A11) | à écrire |
| COM-BR-04 | Politique pièces jointes (taille, types) et stockage, URL signée jamais affichée | AttachmentPolicyPort | `PortPolitiquePiecesJointes` (`lib/core/communications/port_pieces_jointes.dart`) | `politique()` (types et taille autorisés, venus du serveur, jamais codés en dur) ; états autorisé, trop volumineux, type interdit, en cours, envoyé, échec, indisponible ; ouverture par jeton éphémère ; stockage : même domaine R2 `pieceJointeMessage` et même forme de clé que COM-BR-03 (`domaines.ts:36`, `cles.ts:80`) ; la migration R2 ne crée rien pour la messagerie (`supabase/migrations/0034_r2_stockage.sql:36-39`) (COM-BR-A11) | à écrire |
| COM-BR-05 | Publications, réponses, catégories de la Communauté | Communauté | `PortCommunaute` (`lib/features/com_communaute/port_communaute.dart`) | `categories()`, `publications(categorie, recherche)`, `publication(id)`, `reponses(publicationId)`, `publier(...)`, `repondre(...)` ; aucun profil exposé au-delà du nom et de la Classe autorisés ; aucun compteur de popularité (§32) | à écrire |
| COM-BR-06 | Modération réelle : signalements, file, masquer/restaurer, journal | ModerationQueue, ModerationActions | `PortModeration` (`lib/core/communications/moderation.dart`, socle) | `signaler(objet, MotifSignalement)` (8 motifs §5.5) ; `file()`, `masquer`, `restaurer`, `rejeter`, `approuver` selon la capacité « modérer » de COM-BR-16 ; chaque action journalisée côté serveur ; « Le contenu a été signalé… » seulement après accusé | à écrire |
| COM-BR-07 | Détection serveur des liens affiliés et de la vente (aucune garantie côté client) | CommunityPromotionGuard | `PortGardePromotion` (`lib/features/com_communaute/port_garde_promotion.dart`) | `verifier(brouillon)` → normal, avertissement, affilié, vente ; `etatLien(url)` → interne, ressource externe, commercial interdit, non vérifié ; « Vérifié » jamais sans ce contrat | à écrire |
| COM-BR-08 | Canaux Studio, membres, visibilité (visible, restreint, privé autorisé, absent) | Le Studio | `PortStudio` (`lib/features/com_studio/port_studio.dart`) | `canaux()` ne rend **que** les canaux autorisés (absent = non rendu, R-COM-08) ; `canal(id)`, `messages`, `partages` (épinglés, fichiers, liens), `membres`, `rechercher` ; non-lus par canal dans `canaux()` et `marquerLu(canalId)` (StudioChannelList, spec l.1086) (COM-BR-A03) ; réactions secondaires (§10.4 l.542-545, COM-M03 l.912) : `reagir(messageId, reaction)`, `retirerReaction(messageId, reaction)`, total par message rendu avec `messages`, discret, sans score ni classement (§32 l.1763, l.1765) ; étape COM-STU-1, COM-STU-3 ne fait que garder la règle d'affichage en mode Focus (COM-BR-A04) | à écrire |
| COM-BR-09 | Notifications : catalogue par rôle, lu/non lu, push | NotificationCenter, cloches | `PortNotifications` existant (`lib/core/capacites/port_notifications.dart:34`), étendu | champs ajoutés : niveau (information, à lire, action requise, urgent), lu, type, destination validée ; `marquerLue(id)` ; compteur de non-lus pour le point de la cloche ; push hors V1 ; source actuelle absente (DB-CPT-04) | à écrire |
| COM-BR-10 | Annonces : audience, programmation, publication confirmée, état lu, lecture admin des annonces publiées et planifiées | AnnouncementPublisher, ClassAnnouncementCard | `PortAnnonces` (`lib/features/com_annonces/port_annonces.dart`) | `annoncesDeClasse(classeId)`, `annonce(id)`, `publier(contenu, audience, date?)` ; « Publiée » seulement sur confirmation ; l'enseignant ne peut viser que sa Classe (refus serveur) ; `marquerLue(annonceId)` (COM-BR-A03) ; lecture admin des annonces publiées sur une période et des annonces planifiées, ou leur comptage, pour deux des quatre indicateurs de COM-W04 (spec l.1004-1010 ; les deux autres viennent de `file()` de COM-BR-06 et de COM-BR-11, `PortModeration` du socle n'est pas touché) ; étape COM-ANN-1 ; à défaut, COM-ANN-2 écrit que ces deux tuiles restent en démo marquée (COM-BR-A08) ; programmation : aucun ordonnanceur n'existe (`pg_cron` installé nulle part, `0034_r2_stockage.sql:40-42`, `0033_tc_vues_rpc.sql:305`), la programmation exige une décision BR-1 (COM-BR-A11) ; « programmer » suit la capacité de COM-BR-16 | à écrire |
| COM-BR-11 | Matrice de permissions définitive (AudienceRulesMatrix) | Administration des communications | `PortReglesAudience` (`lib/features/com_annonces/port_regles_audience.dart`) | lignes de la matrice venues du serveur (rôle, peut publier, audiences, validation) ; tuteur, élève, contrôleur : aucune publication (§13.4) | à écrire |
| COM-BR-12 | Rétention, audit, synchronisation des brouillons entre appareils | tous | `PortBrouillons`, `PortElementsEnregistres` (`lib/core/communications/`) | V1 : mémoire de session ; BR-1 : durée de rétention, audit, synchronisation éventuelle ; Drift n'est pas approuvé pour des messages | à écrire |
| COM-BR-13 | Qui entre dans Le Studio : rôle ou capability « équipe interne » (aujourd'hui aucun, `lib/core/domain/enums.dart:9`, `peutVoirDirection` toujours faux) | Le Studio | lu par la session (`SessionState`) | claim du jeton ou capability serveur ; en V1 frontend, admin seul (Q1) | à écrire |
| COM-BR-14 | Côté administration, lecture et réponse aux fils des contrôleurs (le port actuel ne sert que le contrôleur) | Messages admin | `PortMessagesMetier` (vue admin) | les fils `mission` de tous les contrôleurs, sans prénom d'élève (C8), réponse avec accusé ; complète BR-CT-13 (`14_controleur/CT-BR.md:20`), même fil serveur, à ne pas compter deux fois ; `PortEchanges` et `PortMessagesMetier` lisent la même source à BR-1 (un adaptateur, pas deux schémas ; spec §14 l.776 : un seul endroit pour la liste des fils) (COM-BR-A10) | à écrire |
| COM-BR-15 | Activité et « Aujourd'hui » du Studio : agrégat d'attention depuis les modules canoniques, chaque ligne avec sa destination | StudioTodayBoard, ActivityInbox | `PortActiviteStudio` (`lib/features/com_studio/port_activite_studio.dart`) | lignes typées (§8.1) avec destination canonique validée et état lu (spec l.413) ; `marquerLu(ligneId)`, dans ce port, aucun port séparé (COM-BR-A03) ; aucune action métier exécutée dans le Studio (R-COM-11) | à écrire |
| COM-BR-16 | Capacités Communications de la personne connectée, projetées par le serveur : publier une annonce, programmer, modérer, ouvrir les paramètres d'un canal, écrire dans un fil ; fermées par défaut, ouvertes seulement en démonstration (spec §5.5 l.298-305, §9.3 l.473, §13.4 l.758-759 ; COM-BR-11 est la matrice affichée à l'admin, pas le droit de la personne) | COM-COMU-1, COM-ANN-1, COM-ANN-2, COM-STU-1 (actions publier, programmer, modérer, paramètres) | **Pour COM-F**, une des deux formes, choisie et écrite dans sa liste de fichiers : (a) un port `PortCapacitesCommunications` dans `lib/core/communications/` (production neutre : tout fermé) ; (b) la règle « capacités portées par les objets rendus » (un `Set` de capacités sur l'annonce, le canal, la publication, avec `peut(...)`), sur le modèle de `lib/core/tc_bibliotheque/library_resource.dart:264-267`. Choix écrit dans `02_DECOUPAGE.md` (COM-F, « Capacités Communications ») : (a), fichier `lib/core/communications/capacites_communication.dart` (`CapaciteCommunication`, `PortCapacitesCommunications`), plus (b) pour les capacités liées à un objet (écrire dans un fil, paramètres d'un canal) | dans les deux cas, jamais de lecture du rôle dans un widget (CLAUDE.md ; seules capacités de session aujourd'hui : `peutEcrire` et `peutVoirDirection`, `lib/core/session/session_state.dart:129`, `:140`) ; capacité absente = action non rendue ; le serveur refuse quand même (COM-BR-A01). **Ajout du 05/10 (décisions prises par délégation du directeur, artefact « Décisions du directeur, 4 octobre », https://claude.ai/artifact/V6mniNAePTUXfpxKbnkEhW)** : (1) D-FUS-6 : `CapaciteCommunication.envoyerVocal` (ajoutée à COM-FUS, six capacités au lieu de cinq) est validée ; le composer vocal n'est rendu que si elle est ouverte, l'envoi passe par `PortEnvoiVocal` (neutre en production, COM-BR-03) ; le serveur projette donc aussi « envoyer un vocal » ; (2) D-FUS-7 : la **forme b** est retenue pour la Communauté et le Studio : `CapacitesCommunaute` (`peutPublier`, `peutRepondre`, servies par `PortCommunaute`) et `CapaciteCanal` (par canal) restent portées par les objets rendus, à côté du port global `capacitesCommunicationProvider` ; pas de `publierCommunaute` au socle | à écrire |



### A12. 19_communications/DECISIONS_COM_FUS.md

[Source GitHub figée](https://github.com/rewayahacademy-glitch/Rewayah-Academy-Official-App/blob/708ef8f59bfefae89db071764d3f90a7d6b13322/19_communications/DECISIONS_COM_FUS.md).

#### Communications V1, décisions du directeur en attente après COM-FUS (5 octobre 2026)

COM-FUS ne tranche aucune de ces questions. Le code fusionné sur `ui/communications-v1`
garde l'état décrit dans « État actuel ». Chaque décision liste ses options, et
l'option sans changement de code est toujours indiquée.

##### D-FUS-1. Clés arabes `com.*` contre les règles 4 et 5 de `02_DECOUPAGE`

- **Décision du 05/10, prise par délégation du directeur** (source : artefact « Décisions du directeur, 4 octobre », https://claude.ai/artifact/V6mniNAePTUXfpxKbnkEhW) : option 1 (garder l'arabe ; les dates suivent la langue choisie). `02_DECOUPAGE.md` règles 4 et 5, l.53, l.78, l.161 amendés le 05/10. Question R-08 (dates) : réponse a, même décision.

- **Conflit** : les règles 4 et 5 (et les lignes 53, 78, 161 de `02_DECOUPAGE.md`) disent
  que `ar.i18n.json` ne reçoit aucune clé `com` et qu'il est gelé après COM-F. Les
  consignes de chaque étape demandaient pourtant l'i18n fr ET ar. COM-F, COM-F-b et les
  cinq voies (msg, voc, commu, stu, ann) ont toutes ajouté leurs clés arabes.
- **État actuel** : toutes les clés `com.*` existent en fr et en ar, à parité (slang).
- **Options** :
  1. garder l'arabe : amender les règles 4 et 5 et les lignes 53, 78, 161 de
     `02_DECOUPAGE.md` (aucun changement de code) ;
  2. retirer toutes les clés `com.*` de `ar.i18n.json` d'un bloc, avec repli sur le
     français (un commit, slang régénéré ; l'interface arabe affichera du français dans
     les Communications).

##### D-FUS-2. Texte d'échec du signalement (§5.2) contre K-59 et D5

- **Décision du 05/10, prise par délégation du directeur** (source : artefact « Décisions du directeur, 4 octobre », https://claude.ai/artifact/V6mniNAePTUXfpxKbnkEhW) : option 1 (garder les textes actuels, corriger la spec §5.2). Amendement écrit dans `V/REWAYAH_COMMUNICATIONS_FRONTEND_V1.md` §5.2 (note datée) et ci-dessous, « Amendement de la spec §5.2 ».

- **Conflit** : la spec §5.2 impose « Le signalement n'a pas pu être envoyé. Réessayez. »
  et « Le contenu a été signalé à l'équipe de modération. ». K-59 et D5 interdisent
  d'affirmer un échec réseau que l'app ne peut pas prouver (« non confirmé, jamais non
  envoyé »), et `verifier_revue` (règle `affirmation-reseau`) le refuse.
- **État actuel** : le socle dit « Le signalement n'a pas encore été confirmé. Réessayez
  dans un instant. » et « Le contenu a été signalé. Il sera examiné. » ; la page
  Communauté dit « Vous avez signalé cette publication. L'équipe de modération va
  l'examiner. ».
- **Options** :
  1. amender la spec §5.2 pour suivre K-59 (aucun changement de code) ;
  2. admettre une exception datée à `verifier_revue` et reprendre le texte exact de la
     spec (`com.socle.signalement.erreur` et `.confirme`) ;
  3. seulement aligner le texte de confirmation sur « … à l'équipe de modération. »
     (sans toucher au texte d'échec).

##### D-FUS-3. Bandeau hors ligne générique sur les pages Communications

- **Décision du 05/10, prise par délégation du directeur** (source : artefact « Décisions du directeur, 4 octobre », https://claude.ai/artifact/V6mniNAePTUXfpxKbnkEhW) : option 1 (masquer le bandeau générique sur les pages Communications ; les autres écrans ne changent pas). Question R-03 : réponse a, même décision.

- **Conflit** : sur Messages (et les autres pages COM), le bandeau générique de
  `PageShell` (`OfflineBanner`, clé partagée `reseau.horsLigne`, « … l'envoi attendra »)
  s'affiche en plus du bandeau des Communications. Le texte générique promet une file
  d'envoi qui n'existe pas pour les messages.
- **État actuel** : les deux bandeaux s'affichent ; un commentaire le signale dans
  `messages_page.dart`.
- **Options** :
  1. masquer le bandeau générique sur les pages COM (paramètre de `PageShell`, socle) ;
  2. changer le texte de `reseau.horsLigne` pour tous les écrans (ne plus promettre la
     file d'envoi) ;
  3. garder les deux (aucun changement).

##### D-FUS-4. Domaine actif de `/admin/notifications`

- **Décision du 05/10, prise par délégation du directeur** (source : artefact « Décisions du directeur, 4 octobre », https://claude.ai/artifact/V6mniNAePTUXfpxKbnkEhW) : option 1 (acter `domaine: null` ; `02_DECOUPAGE.md` l.86 corrigé le 05/10).

- **Conflit** : `02_DECOUPAGE` §COM-F (compléments COM-0b, l.86) demande
  `AdminDomaine.accueil` ; COM-F-Q5 (8043c6ae, captures 6916b0ea) a choisi
  `domaine: null`, la cloche étant la seule entrée active.
- **État actuel** : `domaine: null` (`app_router.dart`), testé.
- **Options** :
  1. acter `domaine: null` en corrigeant `02_DECOUPAGE` l.86 (aucun changement de code) ;
  2. passer `AdminDomaine.accueil` (une ligne du routeur et le test associé).

##### D-FUS-5. Historique : fusion anticipée de `ui/com-commu` dans `ui/com-ann` (6c69e0cb)

- **Décision du 05/10, prise par délégation du directeur** (source : artefact « Décisions du directeur, 4 octobre », https://claude.ai/artifact/V6mniNAePTUXfpxKbnkEhW) : option 1 (fusion anticipée admise, aucune réécriture d'historique).

- **Constat** : COM-ANN-2 a fusionné `ui/com-commu` avant la fusion COM-FUS. COM-FUS a
  ensuite fusionné les deux branches dans `ui/communications-v1` ; la fusion anticipée
  est donc dans l'historique de la branche cible.
- **Options** :
  1. admettre explicitement cette fusion anticipée (aucun changement) ;
  2. reconstruire `ui/com-ann` (push forcé, feu vert explicite requis). Après COM-FUS,
     cela ne changerait plus `ui/communications-v1` sans réécrire aussi son historique.

##### D-FUS-6. Capacité vocale `envoyerVocal` (ajoutée à COM-FUS)

- **Décision du 05/10, prise par délégation du directeur** (source : artefact « Décisions du directeur, 4 octobre », https://claude.ai/artifact/V6mniNAePTUXfpxKbnkEhW) : option 1 (`envoyerVocal` validée ; inscrite dans la ligne COM-BR-16 de `COM-BR.md` le 05/10).

- **Constat** : pour que le composer vocal ne soit rendu qu'avec une capacité, COM-FUS a
  ajouté `CapaciteCommunication.envoyerVocal` (six capacités au lieu de cinq) et
  `PortEnvoiVocal` (neutre, COM-BR-03).
- **Options** :
  1. valider et inscrire `envoyerVocal` dans la ligne COM-BR-16 de `COM-BR.md` ;
  2. porter le vocal par la capacité `ecrireDansFil` seule (le composer apparaîtrait dès
     que l'écriture est ouverte et que l'enregistreur répond).

##### D-FUS-7. Capacités de la Communauté et du Studio

- **Décision du 05/10, prise par délégation du directeur** (source : artefact « Décisions du directeur, 4 octobre », https://claude.ai/artifact/V6mniNAePTUXfpxKbnkEhW) : option 1 (forme b : capacités portées par les objets ; inscrite dans la ligne COM-BR-16 de `COM-BR.md` le 05/10).

- **Constat** : la Communauté garde `CapacitesCommunaute` (`peutPublier`, `peutRepondre`,
  servies par `PortCommunaute`) et le Studio `CapaciteCanal` (par canal), à côté du port
  global `capacitesCommunicationProvider` (COM-BR-16).
- **Options** :
  1. garder les capacités portées par les objets (forme b de COM-BR-16, aucun changement) ;
  2. ajouter `publierCommunaute` au socle et rattacher `peutRepondre` à `ecrireDansFil`.

##### D-FUS-8. Choix produit et libellés proposés par les agents

- **Décision du 05/10, prise par délégation du directeur** (source : artefact « Décisions du directeur, 4 octobre », https://claude.ai/artifact/V6mniNAePTUXfpxKbnkEhW) : avertissement « potentiellement commercial » : **bloquer**, comme aujourd'hui (pas de « Publier quand même ») ; programmation : **garder les trois créneaux** ; libellés `com.*` : **pas de page de validation** : les sessions les valident par relecture croisée (vocabulaire de `docs/current`, K-59, pas de jargon) et marquent « validé par délégation le 05/10 » (relecture : `LIBELLES_COM_RELECTURE.md`). Correction déjà décidée : `com.communaute.garde.reponse.avertissement` devient « Cette réponse semble contenir une promotion commerciale. Retirez le lien, le code ou l'offre avant de l'envoyer. » ; `com.communaute.garde.reponse.consigneBlocage` et `com.communaute.reponses.refusee` sont bons. Colonne « Validation requise » : non tranchée, reste à COM-BR-11.

- Avertissement « potentiellement commercial » : il retient la publication comme un
  blocage (pas de « Publier quand même ») ; à confirmer ou à remplacer par un
  « Publier quand même ».
- Programmation d'une annonce : trois créneaux proposés (demain 8:00, demain 18:00,
  lundi suivant 8:00) au lieu d'un sélecteur de date ; aucun ordonnanceur serveur
  (BR-1, COM-BR-10).
- Colonne « Validation requise » de la matrice : « Non » partout en démonstration ; la
  valeur réelle relève de COM-BR-11.
- Libellés `com.*` marqués « proposé par un agent » dans `tool/libelles_sources.json`
  (toutes les voies) : à valider.

##### D-FUS-9. Fichiers gelés que la suite demande d'ouvrir

- **Décision du 05/10, prise par délégation du directeur** (source : artefact « Décisions du directeur, 4 octobre », https://claude.ai/artifact/V6mniNAePTUXfpxKbnkEhW) : icônes : **autoriser l'ajout** de « signet », « épingle », « lien » dans `app_icons.dart` ; UX_REVIEW : **les écrire avant la recette humaine** (écrits le 05/10 : `UX_REVIEW_COM-STU-1.md`, `UX_REVIEW_COM-STU-2.md`, `UX_REVIEW_COM-STU-3.md`).

- Icônes dédiées « signet », « épingle », « lien » absentes de `lib/core/icons/app_icons.dart`
  (gelé) : les voies utilisent des icônes de repli. Options : autoriser l'ajout des trois
  icônes, ou garder les replis.
- `UX_REVIEW_<lot>.md` (DESIGN-GOV §4) non écrits pour COM-STU-1, COM-STU-2 et COM-STU-3,
  dont les dispositions sont des PROPOSITIONS : à écrire avant HU-1, ou à dispenser.

##### Réponses du 05/10 aux questions de la revue COM-R (par délégation du directeur)

Source : artefact « Décisions du directeur, 4 octobre », https://claude.ai/artifact/V6mniNAePTUXfpxKbnkEhW. Décisions prises par délégation le 05/10/2026 ; l'artefact reste ouvert au directeur pour les corriger.

| Question | Sujet | Réponse | Effet |
|---|---|---|---|
| R-03 (D-FUS-3) | Double bandeau hors ligne | a : masquer le bandeau générique sur les pages Communications | correction de code à faire (paramètre de `PageShell`) |
| R-08 (D-FUS-1) | Arabe et dates | a : garder l'arabe, traduire les dates | correction de code à faire (dates selon la langue, bidi) |
| R-12 | Actions compactes centrées | a : corriger le composant commun (`ActionPrincipale`), captures de tous les écrans concernés vérifiées | correction de code à faire |
| R-16 | Annonce ou séance en tête (Classe du tuteur) | a : la séance en tête quand elle est ouverte ou proche ; l'annonce en haut le reste du temps | correction de code à faire |
| R-19 | Cinquième règle de la Communauté | a : la garder (« Aucune donnée personnelle d'un élève ou d'une famille ») | aucun changement |
| R-27 | Raccourci « Communauté enseignants » sans service | a : le cacher tant que la Communauté n'est pas ouverte | correction de code à faire |
| COM-R-3, constat 5 | Focus à 320, texte ×2 | a : zone d'écriture réduite à une ligne en Focus, qui s'agrandit quand on écrit | correction de code à faire |
| R-28 (vocal) | Ouverture du message vocal | a : un bouton micro à côté d'« Envoyer » | correction de code à faire |
| COM-RC (tour 5) | Huit défauts mineurs restants | a : un tour court de correction | étape à ouvrir |

##### Amendement de la spec §5.2 (signalement), 05/10

La spec du directeur (`V/REWAYAH_COMMUNICATIONS_FRONTEND_V1.md` §5.2) est dans ce dossier de pilotage ; elle est amendée sur place (note datée sous le tableau). Aucune copie de cette spec n'existe dans `docs/current` (recherche `git grep` du 05/10 sur `origin/ui/communications-v1` et `origin/main` : aucun résultat). Textes retenus (K-59, D5 : « non confirmé », jamais « non envoyé ») :

- « Publication signalée » : « Le contenu a été signalé. Il sera examiné. » (`com.socle.signalement.confirme`), seulement après l'accusé du serveur ; la page Communauté garde « Vous avez signalé cette publication. L'équipe de modération va l'examiner. » ;
- « Modération indisponible » / envoi non confirmé : « Le signalement n'a pas encore été confirmé. Réessayez dans un instant. » (`com.socle.signalement.erreur`) ; service absent : « Le signalement n'est pas encore disponible ici. » (`com.socle.signalement.indisponible`).




### A13. 20_comptable/CPT-BR.md

[Source GitHub figée](https://github.com/rewayahacademy-glitch/Rewayah-Academy-Official-App/blob/708ef8f59bfefae89db071764d3f90a7d6b13322/20_comptable/CPT-BR.md).

#### Comptable V1 : besoins serveur (pour BR-1)

Rien n'est branché dans cette vague (spec §1.1, K-28) : aucune migration, RLS, RPC, webhook, secret, intégration Stripe / Verto / pawaPay / Wise, aucun vrai paiement, aucune vraie coordonnée. Chaque ligne dit ce qu'il faudra au serveur, le port neutre qui l'attend (posé par CPT-F, `CapaciteIndisponible('CPT-BR-nn')` en production, K-09), et ce que la démonstration montre en attendant.

Écrit le 04/10/2026 par CPT-0. Les voies complètent la colonne « méthodes » si elles en ont besoin, **dans leur ligne seulement** ; CPT-RC relit la table contre les ports (`grep -rn "CapaciteIndisponible('CPT-BR" lib/core/capacites`), comme FI-12 l'a fait pour FI-BR.

##### 1. Exigences communes à toutes les lignes

- **Argent** : entier en unités mineures + code ISO 4217 (`Montant`, `lib/core/finance/montant.dart:14`), jamais de flottant ; Flutter formate, il n'additionne ni ne convertit (FI6). Tout agrégat (total d'un lot, fonds protégés, trésorerie libre, part d'un coffre en pour mille) est **rendu par le serveur**.
- **Capacités, pas rôles** : chaque objet arrive avec `actionsPermises` (ensemble fermé : `payer`, `demanderValidation`, `relancer`, `demanderMiseAJour`, `suspendre`, `signalerEcart`, `alimenter`, `transferer`, `creerObligation`, `approuver`, `rapprocher`, `rembourser`) et, pour chaque action absente qui serait attendue, une `raisonBlocage` (`autoPaiement`, `validationRequise`, `infosManquantes`, `verificationRequise`, `horsDelegation`, `fournisseurIndisponible`, `fondsInsuffisants`, `doublonPotentiel`, `nonApprouvee`, `capaciteAbsente`). L'écran affiche la raison, il ne la déduit jamais (DR-19).
- **Pas de faux succès** : une écriture rend l'état réel du prestataire ou du serveur (`soumis`, `enTransit`, ...), jamais « réussi » à la réception de la demande (spec §5.3).
- **Idempotence** : toute écriture porte une clé générée par l'app et rejouée telle quelle ; une double réception n'agit qu'une fois.
- **Coordonnées** : le serveur ne rend jamais une coordonnée complète au personnel ; la forme masquée (`•••• 4423`) est **calculée par le serveur**. Aucune coordonnée n'est conservée par l'app.
- **Journal** (§48) : chaque opération visible rend initiateur, date, source, ancien état, nouvel état, montant, objet, preuve, prestataire, référence. Le frontend n'invente aucun audit.
- **Accès horizontal** : un Comptable ne lit que l'organisation Rewayah ; un bénéficiaire ne lit que ses propres obligations et son propre profil ; l'admin lit selon CPT-Q1. Tests d'accès horizontal et revue de sécurité séparée avant tout branchement.
- **Délégation** : toute action du Comptable est vérifiée côté serveur contre `FinanceDelegationPolicy` (CPT-BR-13) ; l'écran n'est qu'un reflet.
- **Mots** : jamais « admin » dans un texte rendu à un bénéficiaire (K-53.6) : « la direction ».

##### 2. Table des besoins

| Réf. | Étape | Besoin serveur | Port (fichier posé par CPT-F) et méthodes attendues | Démonstration en attendant |
|---|---|---|---|---|
| CPT-BR-01 | CPT-PAY-1, CPT-BEN-2 (lecture « moi »), DR-14 | **Obligation payable** (`TeacherPayableObligation` étendu aux contractuels) : id, **version**, période, bénéficiaire (id, nom, type enseignant / contractuel, lien éventuel à l'opérateur), lignes de calcul (Classe, remplacement, bonus approuvé, ajustement approuvé ; chacune avec montant, source, auteur, validation, date, §13.3, §23), devise, montant final, statut (15 états §15), échéance, méthode de payout prévue (masquée), preuve, `actionsPermises`, `raisonBlocage`. Consolidation **par bénéficiaire** (§14.4), la Classe reste un filtre. Recalcul à la source = nouvelle version (R-FIN-18). « Signaler un écart » crée un signalement lié à la ligne, sans montant saisi (R-FIN-17). | `lib/core/capacites/port_obligations_payables.dart` : `liste(filtre)`, `detail(obligationId)`, `signalerEcart(obligationId, ligneId, motif)` | `lib/features/demo/comptable/paiements_demo.dart` : 15 enseignants, 5 contractuels, 12 prêts, 2 infos manquantes, 1 méthode modifiée récemment, 1 auto-payout interdit, 1 validation supplémentaire, 1 payout échoué (spec §44). |
| CPT-BR-02 | CPT-PAY-2 | **Payout** : préflight d'une sélection (nombre de bénéficiaires, total par devise, prestataires, prêts, exclus avec raison, erreurs, plafonds de délégation restants, frais et change **si le prestataire les donne**, §41, §43) ; soumission des seuls prêts, chacun par (id, version) avec clé d'idempotence ; suivi par payout (`soumis`, `enTransit`, `reussi`, `echoue`, `annule`, `retourne`) depuis le webhook du prestataire. Plafonds cumulés par Comptable, par bénéficiaire et par période (anti-fractionnement, §47). Version changée = refus « recalculée » (DR-13). Le serveur refuse `dejaSoumis` pour toute seconde soumission d'une même obligation dans une même version (obligation, version), quelle que soit la clé d'idempotence : une feuille de confirmation fermée puis rouverte après « issue inconnue » tire une clé neuve, et seul ce refus empêche alors un double paiement (CPT-R m9, 05/10). Demande de validation pour un payout sensible (§21.4). | `lib/core/capacites/port_payout.dart` : `preflight(selection)`, `soumettre(preflightId, cleIdempotence)`, `suivre(payoutId)`, `demanderValidation(obligationId, motif)` | Double qui parcourt les états avec délai ; « 18 prêts / 3 exclus » ; un échec ; aucun paiement. |
| CPT-BR-03 | CPT-JOUR | **Aujourd'hui** : file d'éléments (type parmi les douze alertes §28, liste `aTraiter` ou `alerte` DR-10, compteur, cible : écran + filtre), échéances datées (obligations, remboursements ; pas de fournisseurs non spécifiés, DR-25), encaissements récents, activité récente (§48), résumé trésorerie (CPT-BR-04), Réserve (CPT-BR-12, lecture), état des prestataires (CPT-BR-10). | `lib/core/capacites/port_aujourdhui_comptable.dart` : `aujourdhui()` | `aujourdhui_demo.dart`, cohérente avec les autres fichiers de démonstration (mêmes identifiants). |
| CPT-BR-04 | CPT-TRES-1, CPT-JOUR | **Trésorerie et coffres** : trésorerie détenue, fonds protégés, en transit, **trésorerie libre** (centrale, §11), et les sept coffres §8.1 (montant, part en pour mille, nature protégée ou non, règle d'usage) ; historique des allocations ; prévision datée (lignes, pas de série graphique, DR-09). Une somme protégée n'est jamais comptée libre. | `lib/core/capacites/port_tresorerie.dart` : `resume()`, `coffres()`, `historique(filtre)`, `prevision()` | `tresorerie_demo.dart`. |
| CPT-BR-05 | CPT-TRES-2 | **Mouvement interne entre coffres** : couples permis rendus par la politique ; vers une protection = délégable ; sortie d'un coffre protégé = sensible (« Validation supplémentaire requise ») ; refus serveur des quatre interdits §10.4 (vider Fonds clients, Taxes pour une dépense ordinaire, retrait de Réserve sans workflow, modification d'allocation pour masquer un déficit) ; journal ; aucune modification d'une allocation passée. | `port_tresorerie.dart` : `mouvementsPermis()`, `transferer(origine, destination, montant, cleIdempotence)` | Transfert simulé ; retrait de Réserve sans capacité bloqué (R-FIN-10). |
| CPT-BR-06 | CPT-BEN-1, CPT-Q1 | **Profil de paiement vu par le personnel** : identité, méthode masquée (type, opérateur, `•••• 4423`, pays, devise, titulaire masqué si utile), statut (aucun moyen, incomplet, en vérification, vérifié, suspendu, action requise, invitation envoyée), dernière modification, vérification, capacité de payout (CPT-BR-10), historique des paiements ; actions `relancer`, `demanderMiseAJour`, `suspendre` (selon capacité), `marquerVerificationRequise` ; **aucune écriture de coordonnées** par le personnel (R-FIN-11, 12). Lecture par la Direction selon CPT-Q1. | `lib/core/capacites/port_beneficiaires_paiement.dart` : `liste(filtre)`, `profil(beneficiaireId)`, `demanderMiseAJour(id)`, `suspendre(id, motif)`, `reprendre(id)` | `beneficiaires_demo.dart`. |
| CPT-BR-07 | CPT-ENC-1 | **Encaissements** : date, famille, profils concernés, brut, devise, frais, net, moyen, prestataire, référence, état (9 états §24.1), rapprochement, affectation par profil ; « Confirmé » seulement après le prestataire (§24.3). **Même source que les recharges du foyer** (FI-BR-06) et que l'« encaissé » de la Vue globale (FI-BR-12) : un adaptateur, pas deux. | `lib/core/capacites/port_encaissements.dart` : `liste(filtre)`, `detail(id)` | `encaissements_demo.dart` : 3 encaissements, 1 remboursement. |
| CPT-BR-08 | CPT-CTR-1, CPT-BEN-2 | **Obligations de contractuels** : récurrent (calculé si contrat connu) et ponctuel (bénéficiaire, objet, montant, devise, échéance, justificatif, centre de coût, auteur, approbateur si requis, statut) ; création réservée aux capacités (`creerObligation`) ; **montant figé après approbation** ; obligation approuvée = obligation payable (CPT-BR-01). **Bénéficiaire externe sans compte** : invitation sécurisée, accès limité à sa saisie de méthode, état « Invitation envoyée », renvoi (§18, DR-16). | `lib/core/capacites/port_obligations_contractuels.dart` : `liste(filtre)`, `detail(id)`, `creer(brouillon, cleIdempotence)`, `approuver(id)` (si capacité), `inviterBeneficiaire(id)` | `contractuels_demo.dart` : « Karim Studio - Facture #024 - 350 USD » (exemple de la spec). |
| CPT-BR-09 | CPT-PAY-2, CPT-TRES-2, CPT-CTR-1, CPT-DIR-1 (si CPT-Q1 oui) | **Validations** : file des demandes (payout sensible, retrait de Réserve, obligation à approuver, payout du Comptable lui-même), raison de la sensibilité, demandeur, montant exact ; décision (valider / refuser avec motif) par une autre personne que le demandeur ; journal. | `lib/core/capacites/port_validations_finance.dart` : `demandes(filtre)`, `decider(demandeId, decision, motif)` | Côté Comptable : état « Validation demandée ». Côté Direction : selon CPT-Q1. |
| CPT-BR-10 | CPT-PAY-2, CPT-JOUR | **`FinanceProvider` et `PayoutCapabilityPort`** : liste des prestataires réellement activés (nom, état, solde si disponible) ; pour un corridor (pays, devise, opérateur, méthode) : `supported`, `unsupported`, `temporarilyUnavailable`, `needsVerification`, `insufficientProviderBalance` (§42). Aucun prestataire codé comme obligatoire ; un prestataire non activé n'apparaît jamais opérationnel (§1.2). | `lib/core/capacites/port_capacite_payout.dart` : `prestataires()`, `capacite(corridor)` | Noms neutres « (démonstration) », un indisponible (§44). |
| CPT-BR-11 | CPT-BEN-1, CPT-COM | **Relancer** par Messages métier : objet `profilPaiement` ajouté aux objets de COM-BR-01 et à la paire Administration → Enseignant (spec Finance §27.3, décision du directeur ; DR-20) ; `filPourObjet('profilPaiement', beneficiaireId)` ; message modèle §27.3 prérempli ; notifications automatiques §27.4. Le contractuel externe n'a pas de fil : « Renvoyer l'invitation » (CPT-BR-08). | `lib/core/capacites/port_relance_paiement.dart` (mince, au dessin de `PortMessagesMetier`) : `relancer(beneficiaireId)` → identifiant de fil ; remplacé par `PortMessagesMetier` à CPT-COM | « Relance préparée (démonstration) », jamais « envoyée ». |
| CPT-BR-12 | CPT-TRES-1, CPT-DIR-1 | **Politique de Réserve stratégique** : mode d'objectif (montant fixe, ou couverture en N mois de charges essentielles), montant cible ou nombre de mois, règle d'alimentation (désactivée, fixe, pourcentage, jusqu'à l'objectif, proposée), montant ou pourcentage auto, cadence (clôture de cycle, hebdomadaire, mensuelle, après encaissement consolidé, manuelle), seuil d'alerte, retrait soumis à validation ; indicateurs §9.7 (objectif, actuel, manque, pourcentage atteint en pour mille, mode, dernière et prochaine allocation, statut parmi : atteint, sous objectif, dépassement, règle inactive, alimentation prévue). **Aucune plage commerciale codée** : 10 USD comme 1 000 000 USD (R-FIN-08, 09). Écriture réservée à la Direction, versionnée, auditée. | `lib/core/capacites/port_politique_reserve.dart` : `politique()`, `indicateurs()`, `enregistrer(brouillon, cleIdempotence)` (Direction) | `direction_demo.dart` : politique cible fixe, politique en mois, allocation auto fixe ; `tresorerie_demo.dart` lit la même. |
| CPT-BR-13 | CPT-DIR-1, toutes les voies | **`FinanceDelegationPolicy`** : paiements standards autorisés, plafond par transaction, plafond par lot et par période, remboursement standard, alimentation de Réserve autorisée, retrait interdit, premier paiement d'un bénéficiaire et coordonnées récemment modifiées → seconde validation, auto-payout interdit, montant manuel interdit, politique tarifaire interdite (§21.2) ; paiement standard §21.3, sensible §21.4. Écriture Direction, auditée. | `lib/core/capacites/port_delegation_finance.dart` : `politique()`, `enregistrer(brouillon, cleIdempotence)` (Direction) | `direction_demo.dart`. |
| CPT-BR-14 | CPT-ENC-2 | **Rapprochement** : relier paiement attendu, transaction prestataire, mensualité, frais, remboursement, payout, preuve ; états automatique, à vérifier, rapproché, conflit, sans correspondance, doublon potentiel ; action `rapprocher(a, b)` et `marquerDoublon` journalisées. | `lib/core/capacites/port_rapprochement.dart` : `aRapprocher(filtre)`, `proposer(transactionId)`, `rapprocher(transactionId, cibleId, cleIdempotence)` | `encaissements_demo.dart` : 2 rapprochements, 1 doublon potentiel. |
| CPT-BR-15 | CPT-ENC-2 | **Remboursements et avoirs** : demande, bénéficiaire, motif, montant, source, état, approbation requise ou non ; exécution selon la politique Finance, jamais réécrite par le Comptable (§26). | `port_encaissements.dart` : `remboursements(filtre)`, `executerRemboursement(id, cleIdempotence)` | Un remboursement en attente. |
| CPT-BR-16 | CPT-BEN-2 | **Mes moyens de paiement (bénéficiaire lui-même)** : ajouter, remplacer, supprimer, méthode préférée (§17) ; changement sensible : modification demandée, nouvelle méthode en vérification, ancienne inactive ou conservée selon règle, payout suspendu temporairement, méthode vérifiée (§19) ; ré-authentification, MFA, KYC, temporisation anti-fraude **prévues, non implémentées** ; saisie des coordonnées chez le prestataire ou dans un champ chiffré jamais conservé par l'app. Le Comptable bénéficiaire modifie les siennes ici (§20). | `lib/core/capacites/port_mes_moyens_paiement.dart` : `etat()`, `ajouter(...)`, `remplacer(...)`, `supprimer(id)`, `choisirPreferee(id)` | États de démonstration, aucune coordonnée réelle (numéros fictifs non conformes). |
| CPT-BR-17 | toutes | **Journal par opération** (§48) servi avec chaque objet ou par `journal(objetId)`. | méthode `journal(id)` dans le port de chaque voie | Entrées de démonstration. |

##### 3. Ce qui n'a pas de besoin serveur

- **Visibilité des montants** (`FinanceAmountVisibilityToggle`) : purement locale, en mémoire, remise à « masqué » à chaque session (spec §7.3) ; jamais écrite ni lue sur le serveur.
- **Filtres, onglets, tri** : locaux.

##### 4. Correspondances avec la vague Finance

| CPT-BR | Lien avec FI-BR | Règle |
|---|---|---|
| 07 | FI-BR-06 (recharges), FI-BR-12 (encaissé du mois) | Même source, un adaptateur. |
| 01 (lecture « moi ») | FI-BR-11 (revenus estimés) | Deux objets distincts ; DR-14. |
| 06 | FI-BR-13 (rôle comptable) | FI-BR-13 est remplacé par les lignes 01 à 16. |
| 12, 13 | FI-BR-01, 02 (politique commerciale) | Politiques séparées ; même exigence de version, d'audit et d'écriture réservée à la Direction. |




