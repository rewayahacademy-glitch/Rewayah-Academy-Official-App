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
- Erreurs typées : non authentifié, interdit, périmé/conflit de version, quota/capacité, validation requise, indisponible, issue inconnue. Adapter aux enums Dart existants, sans changer silencieusement le contrat.
- Pagination par curseur stable et plafond serveur ; sélection de champs ; tri déterministe ; aucun chargement illimité des listes administration.
- Réseau incertain après commande : lire le résultat par command_id avant de recréer une commande. Un timeout ne signifie ni refus, ni échec fournisseur.
- Tests de contrat JSON/Dart/SQL, y compris nullabilité, enums nouveaux, DTO partiels, droits retirés et données redigées.

### 6.1 Exemples réellement inspectés

`PortPolitiqueRevueKyc.lire()/modifier(genreRelecteurApplique, versionAttendue)` renvoient encore AD-BR-16/17 indisponibles par défaut. Le backend doit préserver cette concurrence optimiste et la capability de modification ; un toggle Flutter ne change pas la politique.

`PortVisiteObservation.entrer(sessionId, role)` a déjà un adaptateur Supabase vers `entrer_observation(p_session_id,p_role)` ; sortie vers la RPC correspondante, historique borné à la séance. L'autorisation et le budget doivent précéder la délivrance du jeton LiveKit. Le paramètre rôle est une demande, jamais une preuve.

`PayoutPort.preflight(selection)` utilise des obligations `(id, version)` ; `soumettre(preflightId, cleIdempotence)` puis `suivre(payoutId)`. Le contrôle final serveur doit refaire la validation : un préflight n'est ni un paiement ni une réservation éternelle de fonds.

## 7. Invariants fonctionnels par verticale

### 7.1 Tuteur, enfant, adulte

Inscription reprenable/idempotente, foyer unique selon modèle approuvé, consentements versionnés, tuteur sans attente KYC. Invitation second adulte à usage unique avec expiration ; compte déjà dans un autre foyer traité explicitement. Un retrait relationnel ferme lectures, commandes, tokens et caches concernés.

L'élève autonome ne se déduit ni d'un âge supposé ni d'un simple rôle guardian : profil autonome appartenant à l'identité connectée + capability serveur. Un passage à la majorité ne transfère pas silencieusement solde, compte et relations ; workflow d'émancipation à sourcer avant activation.

Appairage : code court consommé atomiquement, durée courte, limite d'essais distribuée, un secret révocable par appareil, secret stocké de façon appropriée à la plateforme. PIN local = commodité. Tester token appareil révoqué ET session Auth qu'il a pu ouvrir : révoquer la ligne appareil ne suffit pas si une session dérivée continue d'accéder à la base.

Logout adulte : signOut effectif, fermeture subscriptions/media, invalidation providers, séparation de Drift/IndexedDB et des téléchargements sensibles. Préserver les appairages enfant seulement conformément au modèle familial explicite. Test A -> déconnexion -> B -> hors ligne : aucune donnée de A accessible ; inclure historique navigateur, mémoire et notifications.

### 7.2 Classes et planning

Offre -> intention -> classe DRAFT -> affectation enseignant -> publication -> inscription -> occurrence. Ne pas confondre une intention avec une place réservée ou une inscription payante. Conserver un enseignant principal pour le pattern entier ; remplacement temporaire séparé.

Le modèle doit permettre le DRAFT sans enseignant si cette décision reste portée par la spécification Classes retenue. La RPC legacy inspectée exige actuellement un enseignant valide : conflit à résoudre avant raccordement, pas en injectant un faux enseignant.

Places/chevauchements : contraintes uniques et transaction, verrou sur classe/ressource approprié ; validation du planning complet, durée enfants/adultes selon politique ; fuseau IANA. Date locale récurrente et instant UTC d'occurrence distincts ; changement d'heure, voyage, exceptions, jours fériés et modification d'une seule occurrence testés.

Cohortes, langue, diagnostic, débutant et transitions d'âge viennent de la spécification actuelle. Pas de valeur fixe extraite des démos. Tester anniversaire entre intention et inscription, date de naissance absente et dernière place concurrente.

### 7.3 Salle, présence, observations et remplacements

Token LiveKit pour une seule séance, audience et permissions serveur : accès courant, affectation, prévol, fenêtre d'entrée et statut. Pas de permission de publier reçue du client. Refuser les nouveaux tokens ET retirer les permissions/participants actifs lors d'une révocation critique.

Observation tuteur : règle produit existante de deux présences de deux minutes par séance, configuration administrable par groupe ; écoute sans micro/caméra ; annonce selon audience autorisée et enfant concerné ; historique. Vérifier le budget live/configuration effective avant de le déclarer appliqué. Deux appareils et reconnexion partagent le même budget serveur. La durée du JWT ne coupe pas à elle seule un participant déjà connecté : timer/worker durable et commande média d'expulsion/retrait nécessaires.

Observation Contrôleur distincte : mission bornée, MFA, identité non divulguée, autorisations des rapports et contestation séparées. Révocation pendant direct, expiration mission et synthèse différée couvertes. Pour la conservation et la contestation, la source BLOQUANTS_ET_IMPACTS §1 bis distingue la décision du directeur et sa déclinaison par l’orchestrateur : rapport brut 12 mois après envoi, prolongation pendant un dossier/une mesure ouvert ; une contestation motivée par rapport dans les 7 jours après publication de la synthèse mensuelle. La durée supplémentaire des synthèses anonymisées reste à préciser. Ne pas faire partir le délai de contestation de la visite confidentielle.

Présence : signature webhook sur corps brut, anti-rejeu, event ID unique, heure événement vs réception ; traitement idempotent/hors ordre. Les webhooks LiveKit ne garantissent pas livraison totale : réconciliation, statut incertain et correction auditée. Aucun prélèvement/paye définitif basé uniquement sur une absence d'événement ou le chrono client.

Remplacement : offre et acceptation atomique, une seule affectation gagnante, droits temporaires, contexte de reprise minimal, expiration et effet sur paie. La reconnexion technique ne crée pas une nouvelle séance académique.

### 7.4 Pédagogie, bibliothèque et tableau

Cahier commun de classe + données individuelles projetées séparément. Un parent ne reçoit pas les observations d'autres élèves dans un JSON partagé, même si l'UI les masque. Validation versionnée ; correction append-only ; événement de payabilité idempotent. Révision après clôture financière = ajustement explicite, pas réécriture du paiement.

Corpus Hafs et ressources référencés/versionnés ; position personnelle, repère de classe, annotations et fichiers sont des objets différents. Contrôle intégrité et droits de diffusion ; aucune modification automatique du texte religieux à partir d'une génération.

L'enseignant présente de façon autoritaire ; pas de bouton élève « Suivre l'enseignant » réintroduit. Précharger et vérifier la version avant bascule. Un support qui échoue à charger laisse l'ancien visible avec erreur honnête. LiveKit transporte le média ; ne pas faire transiter les flux vidéo dans Postgres.

État partagé : session_id, version/epoch, ordre monotone, commandes autorisées ; snapshot + rattrapage après reconnexion. Les traits temporaires peuvent être diffusés à faible latence, mais la conservation exige un acquittement serveur. Coordonnées normalisées, auteur, autorisation d'écrire, annuler son propre trait, pas celui d'autrui. Séparer événements éphémères et écritures durables regroupées. Ne pas envoyer un write DB à chaque pixel du stylet.

### 7.5 Finance et Comptable

Ledger en ajout seul, équilibré par devise pour la comptabilité opérationnelle cible ; écritures inverses pour corrections, projections reconstruisibles, rapprochement fournisseur. Ne pas présenter cette architecture comme une certification de comptabilité légale.

Solde par profil. Un total foyer est informatif, non une caisse fongible. Recharge multi-profils : un paiement externe, allocation immuable par profil, somme des allocations et taxes/frais validée serveur. Credit seulement sur preuve fournisseur vérifiée et réconciliée ; retour navigateur insuffisant. Référence fournisseur unique par prestataire/environnement/type pertinent.

Séparer encaissement, revenu académique, fonds client, taxes, dette enseignant, estimation, payout en transit et argent libre. Mensualité au mois civil, prorata approuvé, aucun débit partiel, arrêt des dettes à la fin réelle de l'inscription. Politiques effectives datées ; aucune modification rétroactive d'une facture payée.

Essais, financement, conservation place et entitlement sont distincts du wallet. Enfant reçoit une raison neutre, jamais des détails financiers dans le DTO. Le second adulte lit mais ne recharge pas ; l'adulte autonome ne recharge que son profil.

Paye : règle effective, sièges éligibles, durée, remplacements, plafonds et aide Internet séparée. La condition cahier validé est appliquée avant constitution de l'obligation ; la correction ne détruit pas l'historique.

Comptable : obligations versionnées, délégation cumulée par personne/bénéficiaire/période, préflight, validation indépendante, coordonnées masquées serveur, ré-authentification/MFA selon sensibilité. Interdire auto-approbation, auto-payout non autorisé et contournement par fractionnement.

Contraintes métier au-delà d'une idempotency key : **une obligation/version déjà soumise ne peut être payée à nouveau avec une autre clé**. Recalcul, remplacement de coordonnées, nouvelle politique ou expiration invalident le préflight/approbation concernés. Le personnel ne modifie pas les coordonnées d'un bénéficiaire à sa place.

Coffres : fonds protégés exclus du libre, transferts contrôlés, réserve stratégique versionnée, retrait avec workflow. Fournisseurs rendus selon activation réelle et corridor (pays/devise/opérateur/méthode). Pas de pawaPay/Verto/Wise/Stripe présenté opérationnel sans configuration et preuve. Recharges FI et encaissements CPT ont une source commune ; ne pas créer deux comptes divergents.

### 7.6 Communications, Studio et notifications

Reprendre COM-BR-01 à 16 : fils liés à objets métier et paires d'acteurs autorisées, vocaux, annonces, communauté enseignants, Studio, capacités, lecture et modération. Pas de messagerie générale ajoutée par déduction.

Un fil mission Contrôleur vu depuis ses deux interfaces reste un seul fil. Relance profil de paiement utilise l'objet prévu CPT-BR-11 ; le bénéficiaire externe utilise une invitation bornée, pas un accès large à l'app.

Chaque envoi est idempotent, validé côté serveur, audité selon sensibilité, limité en volume et taille ; contenu échappé, URLs/deep links validés, pièces jointes privées. Filtrage d'audience au moment de lire et d'envoyer. Révocation ferme aussi le Realtime.

Notifications : outbox durable, destination/locale/fuseau, préférences et déduplication ; push/email sans pièce KYC, coordonnées complètes ou motif financier à l'enfant. Distinguer envoi accepté, livraison fournisseur et lecture. Les annonces programmées sont annulables avant exécution.

La mémoire « 60 jours max » n'est pas une justification pour mettre toute la messagerie dans Drift : COM-BR-12 laisse la rétention/synchronisation à spécifier et n'approuve pas Drift pour les messages. Définir une matrice par type, puis purge des objets, dérivés et caches. Brouillons mémoire de session ne sont pas des messages persistés.

## 8. Transactions, événements et concurrence

Pour toute commande critique : clé unique scoped `(acteur, environnement, opération, command_id)`, empreinte de payload, résultat conservé ; même clé/autre contenu = conflit. Retention des clés compatible avec fenêtres de retry métier. Ne pas stocker une clé globale sans périmètre utilisateur.

À l'intérieur d'une transaction : autorisation actuelle, version attendue, invariants, verrou, mutation et outbox. Commit avant appel externe durable. Un worker traite l'outbox avec lease, retries bornés/backoff/jitter, compteur et file d'échecs ; déduplication côté receveur. Pas de transaction DB ouverte pendant appel PSP ou génération de fichier.

Webhook : inbox dédupliquée et durable, signature et environnement vérifiés, réponse HTTP après réception durable, traitement asynchrone reprenable. Les événements reçus plusieurs fois sont normaux ; l'effet métier unique est la garantie recherchée. Pas de promesse « exactly once » sur le réseau.

Jobs : facturation, essais, libération places, expiration observation, annonces, rapprochement, rétention. Horaire serveur, tâche unique par objet/période, verrou d'exécution, reprise après panne, monitoring du retard. Gestion des deadlocks par ordre de verrouillage stable et retries limités. `SKIP LOCKED` convient à une file, pas au calcul d'un solde disponible.

## 9. Stockage, secrets et données sensibles

### 9.1 Séparation par domaine

Les groupes de configuration identifiés dans le rapport source sont **`R2_APP_PRIVATE`, `R2_IDENTITY_VAULT`, `R2_RECORDINGS`, `R2_MESSAGING`**. Ne pas remplacer `R2_RECORDINGS` par un préfixe imaginé. Chaque groupe attend les noms suffixés `ACCOUNT_ID`, `ACCESS_KEY_ID`, `SECRET_ACCESS_KEY`, `BUCKET_NAME`, `ENDPOINT`. Aucune valeur secrète dans ce document.

Les noms exacts et l'état des buckets R2 ne sont pas revérifiés auprès de Cloudflare dans cette revue. Les buckets Supabase historiques `avatars`, `kyc`, `photos_enseignants`, `supports` sont une autre couche. Le code déployé `piece-identite-acces` gère encore R2 et le bucket Supabase kyc : ne pas supprimer l'historique ni prétendre que tout a migré vers R2.

Inventaire requis : domaine -> backend stockage -> bucket -> region -> clé serveur -> politique d'accès -> durée -> sauvegarde -> environnement. Identifiants d'objets opaques, jamais noms/numéros d'identité dans les clés. L'URL signée est un bearer secret temporaire, pas un droit révocable instantanément.

### 9.2 Cycle de fichier

Autoriser dépôt -> URL courte bornée à l'objet/taille/type -> zone non consultable -> contrôle effectif taille, signature de format, contenu/scan adapté -> confirmation serveur -> état disponible. Ne jamais croire MIME/extension et confirmation client seuls. Vérifier checksum, métadonnées et appartenance ; reprise multi-part, orphelins, quotas et purge.

KYC : lecture document par document, capacité actuelle Direction, genre de relecteur selon politique actuelle, audit avant délivrance, URL très courte. Le journal prouve l'autorisation/l'ouverture technique, pas que l'humain a réellement lu et compris la pièce. La décision dossier doit porter la version de pièce examinée. Contrôle de lecture préalable auditable sans prétendre prouver l'attention humaine.

Une URL déjà émise peut rester valide jusqu'à expiration : pour une révocation stricte avant ce délai, utiliser une voie proxy vérifiant chaque requête ou autre mécanisme réellement compatible. Pas de cache CDN public de pièces. Pas de pièces sensibles ni tokens dans logs, analytics, crash reports et captures.

Rétention : durée, finalité, événement de départ, gel légal éventuel, purge, reçu de purge et traitement backups. La conservation illimitée historique du KYC n'est pas certifiée comme obligation légale. Valider juridiquement les durées avant activation ; ne pas inventer une loi. Enregistrements restent désactivés tant que finalité, consentement, audience, durée et budget ne sont pas arrêtés.

## 10. Performance et montée en charge

### 10.1 Capacité exprimée correctement

Cible métier de centaines de milliers de comptes compatible avec une croissance progressive de cette architecture, **mais non prouvée par cette revue**. Le nombre d'inscrits n'est ni le nombre de connexions DB, ni de websockets, ni de participants vidéo.

Dimensionner séparément : comptes/MAU, utilisateurs simultanés, requêtes/s, transactions/s, rooms et participants simultanés, fan-out d'événements, minutes média/enregistrement, egress, volume messages/journaux et jobs en retard. Exemple de calcul, pas prévision : 100 000 comptes x 5 % simultanés = 5 000 sessions ; si 40 % sont en classe, 2 000 participants vidéo. Avec 5 participants moyens par salle, environ 400 salles. Les hypothèses doivent être remplacées par mesures métier.

### 10.2 Paliers de validation proposés

| Palier de test synthétique | Objectif | Preuve demandée |
|---|---|---|
| Pilote | 100 connexions app ; trafic et média correspondant à la première cohorte | Parcours complets, charge modérée, erreurs et restauration maîtrisées |
| Croissance | 1 000 connexions app | Requêtes/transactions représentatives, pics d'entrée, fan-out et jobs bornés |
| Grande population | 5 000 puis 10 000 connexions app | Environnement équivalent capacité PROD, quotas validés, saturation mesurée et marge |

Ces chiffres sont des scénarios d'ingénierie proposés, pas des limites du produit ni des capacités garanties. Un STAGING Free ne représente pas une future PROD dimensionnée : prévoir un environnement de performance isolé et des données synthétiques, avec coût explicite avant provisionnement.

Budgets initiaux proposés, à mesurer et ajuster : lectures API simples p95 < 300 ms côté serveur ; commandes transactionnelles hors fournisseur p95 < 500 ms ; préparation autorisation/jeton p95 < 1 s ; erreurs inattendues < 0,1 %. Mesurer séparément RTT client européen/américain/africain, chargement Flutter, connexion média, TURN et qualité audio. Pas de promesse de latence nulle.

### 10.3 Actions PostgreSQL

Advisors du 6/10 : **76 FK sans index couvrant, 39 évaluations auth RLS répétées, 95 combinaisons de policies permissives multiples, 8 index inutilisés signalés**. Ce sont 218 observations de performance, pas 218 failles ni une preuve que la base est lente.

- Index priorisés sur requêtes réelles et relations : profil/foyer, membres actifs, séances à venir, obligations non réglées, objets datés et événements. Index composite suit filtre + tri ; index partiel pour états actifs lorsque justifié.
- Mesurer EXPLAIN avec données synthétiques représentatives et RLS réelle, pas sous postgres uniquement. Sur PROD, pas d'EXPLAIN ANALYZE coûteux sans lot d'exploitation approprié.
- Fonctions d'auth sans dépendance par ligne peuvent être évaluées une fois par requête ; ne pas mettre aveuglément tout helper dans un initplan.
- Pas de suppression d'index fondée sur « unused » d'une base minuscule ; historique d'observation insuffisant et contraintes à considérer.
- Pagination curseur, agrégats serveurs, projections pour dashboards ; aucune requête N+1 ou count global à chaque carte.
- Budgets connexions par service, pool adapté (notamment workers/Edge), transactions courtes, timeouts, suivi locks/autovacuum/bloat. Les clients Flutter utilisent les API, pas une connexion PostgreSQL individuelle.
- Partitionner seulement les grandes tables à cycle temporel démontré (audit/events/messages), avec création des partitions futures et stratégie de purge testée. Ne pas généraliser le partitionnement à toutes les tables.
- Replica/cache pour lecture tolérant un retard ; jamais autorité du paiement, dernière place, révocation ou privilège. Mesurer lag et règle read-after-write.

### 10.4 Realtime et média

Canaux privés à scope session/classe/fil, contrôle des abonnements et publications. Postgres Changes n'est pas prouvé configuré dans les projets inspectés. Choisir explicitement Broadcast privé, Changes ou transport LiveKit selon le flux ; ne pas activer toutes les tables.

Reconnexion backoff+jitter, snapshot/version, déduplication, arrêt subscriptions à navigation/logout/background. Autorisation d'un abonnement et révocation d'un abonnement déjà actif sont deux problèmes distincts.

Pour LiveKit : budget participants, rooms, souscriptions, qualité audio, dynacast/adaptiveStream, TURN, enregistrements et egress. Conserver priorité audio sur réseau faible ; adapter les flux visibles. Réduire la vidéo envoyée à un observateur au strict besoin produit. Comptes/quotas LiveKit et R2 non inspectés : aucune capacité média chiffrée n'est attestée.

Croissance future : augmenter compute/pool, optimiser projections et diffusion, déporter analytics ; replicas puis éventuellement répartition régionale si mesures et contraintes le justifient. Pas de sharding prématuré. Les identifiants et le journal d'audit ne doivent pas imposer une sérialisation globale évitable ; préserver la possibilité d'évolution sans migrer tous les IDs maintenant.

## 11. Exploitation, release et reprise

### 11.1 Séparation réelle des environnements

STAGING : données synthétiques seulement, fournisseur paiement test, buckets et clés distincts, rooms LiveKit test, domaines webhooks/redirects Auth distincts, email/SMS vers destinations de test. Un simple flag `ENVIRONNEMENT=staging` ne change pas les services appelés.

**Constat GitHub :** le workflow Flutter de la branche commune utilise les mêmes noms `secrets.SUPABASE_URL` et `SUPABASE_ANON_KEY` pour aperçu et production et ne déclare pas d'environnement de job distinct dans le fichier inspecté. Il change le label d'environnement mais cela ne prouve pas l'isolation du backend. Les valeurs secrètes n'ont pas été lues : pas de conclusion que la connexion preview actuelle vise forcément PROD. Mettre un contrôle positif project_ref attendu et un contrôle négatif project_ref PROD interdit dans les builds test.

Les tests destructifs STAGING restent bornés au projet et aux fixtures du lot ; le mot STAGING ne vaut pas permission de détruire des ressources partagées.

### 11.2 Migrations reconstructibles

Lot canonique : inventaire version historique -> source Git -> hash -> objets -> dépendances -> décision conserver/remplacer/retirer. Extraire/rapatrier 0039-0042 depuis source autorisée et comparer au SQL de l'historique ; résoudre les marqueurs et la collision 0043. Ne pas éditer l'historique appliqué pour faire apparaître un faux alignement.

Distinguer **rejeu propre de la cible validée** et **reconstruction fidèle de l'historique PROD**, qui ne sont pas nécessairement le même ordre de fichiers. Préserver les corrections de sécurité en créant des migrations nouvelles après la baseline. La CLI attend des versions uniques : les préfixes complémentaires actuels doivent être réconciliés, pas renommés puis poussés naïvement en PROD.

Tests sur base vierge ET upgrade depuis baseline réaliste ; comparaison tables/colonnes/contraintes/index/functions/grants/RLS/triggers/vues et seeds non sensibles. Tester Auth/Storage/Supabase réels sur STAGING en plus du Postgres avec stub Auth utilisé dans CI. Une CI stub ne prouve pas le hook, le signIn, les canaux ou les fonctions Edge.

Expand -> backfill borné et reprenable -> double compatibilité -> bascule -> contract après disparition des anciens clients. Rapport des lignes en anomalie, contraintes validées et règle de reprise ; pas de verrou long non mesuré.

### 11.3 Déploiements

Le workflow `deploy.yml` inspecté déploie les Edge Functions sur le project_ref PROD à un push main. Il est identique entre main et la branche commune. Le workflow Flutter de la branche commune promeut `--prod` avant ses smoke tests. Aucun verrou `needs` entre ces workflows indépendants n'a été attesté. Le succès d'un build web ne certifie donc pas les migrations ni la sécurité.

Cible : commit immuable + manifeste (frontend, schema, Edge, policies, config, corpus) -> tests -> déploiement candidat isolé -> smoke fonctionnels/contrats -> promotion contrôlée. Verrou global release par environnement ; approbations et compte de déploiement dédiés ; cli/dependencies figées. Éviter `latest` non maîtrisé pour un chemin critique.

Version publique Rewayah 3.x distincte du build technique et de la version de contrat. N/N-1 doit couvrir les clients mobiles déjà distribués, pas seulement la précédente PWA. Version minimale imposée seulement après scénario de migration ; aucune mise à jour forcée qui coupe une séance en cours. Flags serveur par feature/audience, fail closed sur actions sensibles, kill switch réversible.

Rollback frontend/Edge n'annule pas les écritures déjà faites. Préférer correction additive ; down migration destructive exclue comme plan normal. Tester compatibilité ancien client/nouveau schéma, conservation des paiements en transit et reprise des workers.

### 11.4 Sauvegarde et restauration

L'organisation Free et une base accessible ne prouvent ni backup automatique exploitable ni PITR. Objectifs proposés avant pilote : RPO DB <= 15 min pour finance/droits et RTO service <= 4 h, à confronter au budget et à la solution réellement souscrite. Si impossibles, définir un objectif accepté avant ouverture, sans annoncer ces garanties.

Sauvegarder DB/Auth nécessaires, métadonnées fichiers, objets R2/Storage, configuration et corpus avec inventaire de versions. Le backup DB Supabase ne contient pas les octets des objets Storage/R2. Secrets restaurables via coffre séparé ; ne pas les mettre dans un dump de travail.

STAGING sert aux restaurations synthétiques. **RECOVERY** reçoit exceptionnellement une sauvegarde réelle : environnement isolé, accès restreint, mêmes exigences de protection que PROD, aucun envoi email/paiement/webhook sortant, aucune exposition preview, destruction contrôlée après exercice. Ne jamais copier les personnes réelles dans STAGING pour « tester le restore ».

Tester : restitution identité/règles, ledger équilibré, objets disponibles/checksums, logs et suppressions cohérents, absence d'effets PSP répétés, temps mesuré. Rejouer les événements reçus après le point restauré par réconciliation, pas par duplication de débit. Un hash d'audit prouve l'intégrité relative, pas l'authenticité absolue face à un administrateur racine ; prévoir copie externe protégée si assurance d'inaltérabilité requise.

### 11.5 Observabilité et maintenance

Correlation_id de l'app à Edge/RPC/outbox/PSP ; métriques p50/p95/p99, erreurs, saturation connexions, verrous, lag queue, retard webhook, paiements en état inconnu, budgets observation dépassés, purge en retard et échec backup. Logs structurés sans secrets ni contenu sensible ; échantillonnage et coût maîtrisés.

SLO et burn rate, alertes exploitables avec responsable et runbook ; alertes métier sur ledger déséquilibré/double obligation, priorité supérieure à une simple moyenne CPU. Budget coût par élève actif et heure de cours : DB/Auth/Realtime, média/TURN/egress, stockage, enregistrements, logs, email, frais PSP et change.

Maintenance PostgreSQL : PROD 17.6 contre STAGING 17.11 ; le changelog Supabase du 25/09 annonce une mise à jour de sécurité avec actions possibles sur extensions/index. Planifier la mise à jour après inventaire extensions, sauvegarde et essais, sans lancer une upgrade durant cet audit. Ne pas conclure que les 44 CVE annoncées sont toutes exploitables sur Rewayah.

## 12. Plan exécutable par lots

| Lot | Contenu | Livrable de passage |
|---|---|---|
| A - Vérité et baseline | SHA par verticale, migration manifest, 0039-0042/0043, règles contradictoires | Registre réconcilié et diff expliqué ; aucune mutation PROD |
| B - Environnements | Bootstrap STAGING synthétique, séparation de tous les services, config Auth | Rejeu propre, smoke, contrôle anti-PROD et preuves d'absence de données réelles |
| C - Sécurité commune | SEC-01 à 09, autorité capabilities, KYC, API, grant matrix | Matrice négative testée, aucune faille bloquante du parcours sélectionné |
| D - Identité/appareils | Session, foyer, autonome, logout/caches, révocation | Parcours multi-compte/multi-appareil et hors ligne vérifiés |
| E - Exploitation/release | CI gate, candidat avant promotion, rollback, backup/RECOVERY | Restore et compatibilité prouvés, monitoring et runbooks |
| F1 - Première verticale | Tuteur + enfant/adulte + classe + séance, selon priorité cockpit | Contrats BR requis branchés de bout en bout sur STAGING |
| F2 - Enseignement | Planning, remplacements, cahier, ressources/tableau | Parcours enseignant et filtrage élèves prouvés |
| F3 - Finance | FI puis CPT, avec finance commune et rails test | Réconciliation, idempotence, séparation tâches et tests fournisseur |
| F4 - Contrôle/communications | Contrôle, COM, Studio, notifications selon dépendances | Droits croisés, confidentialité, durée et livraison prouvés |
| G - Pilote PROD | Cohorte bornée, flags, canary, suivi et rollback | Autorisation de promotion et bilan réel, pas seulement captures |

A-E forment le socle. La conception et les tests locaux des lots suivants peuvent avancer indépendamment ; leur activation dépend des prérequis réellement utilisés. Ne pas imposer de terminer toutes les fonctionnalités futures pour ouvrir une première verticale sûre. Ne pas contourner les gates communes parce qu'une page paraît terminée.

Chaque lot possède un périmètre, un propriétaire, un reviewer distinct, des fichiers réservés, un budget et une condition d'arrêt. Reprendre les voies libres du cockpit avant tout travail dans le dépôt ; ne pas écraser une branche en cours.

## 13. Recette obligatoire et critères de sortie

| Famille | Scénarios minimum |
|---|---|
| Identité/droits | Deux foyers, titulaire/second adulte/enfant/autonome, enseignant affecté/non affecté, contrôleur, comptable, admin, service, agent ; anon ; rôle absent ; compte suspendu ; JWT ancien |
| Surfaces | Même test sur table, vue, RPC, Edge, fichier signé, canal Realtime et média ; pas seulement route Flutter |
| Concurrence | Dernière place, réservation enseignant, remplacement, invitation, code appareil, publication politique, retrait réserve, deux paiements d'obligation avec clés différentes |
| Finance | Retry/timeouts, doublon/hors ordre, montant/devise/compte fournisseur incorrects, chargeback, remboursement partiel, retour tardif, frais/taxes, coordonnées changées après validation |
| Session | A/logout/B/hors ligne, révocation appareil et session dérivée, navigation/back, cache, reconnexion, ancien client |
| Temps | DST, voyage, faux horaire client, échéance essai, 7 jours, 12 mois, double worker, retard purge |
| Classe | Prévol, T-20 selon politique, tuteur écoute seulement, quota global, expulsion réelle, contrôleur invisible, panne webhook, correction présence, cahier individuel filtré |
| Données/fichiers | MIME mensonger, objet absent/partiel, autre foyer, URL expirée, suppression, scan, upload orphelin, quota, restauration cohérente |
| Pannes | DB/Auth/PSP/LiveKit/R2/email indisponibles ; aucune confirmation inventée ; commandes reprenables ; pas de double effet après retour |
| Charge | Dataset synthétique volumineux, RLS réelle, pointes d'entrée, polling/reconnexion, backlog jobs, saturation et récupération |

Définition de prêt pour une verticale : spécifiée + implémentée + tests locaux + contrat + STAGING + tests adverses + observabilité + rollback + promotion autorisée + vérification post-déploiement. Les cases ne sont pas interchangeables.

Une revue statique ne délivre pas un PASS d'exploitation ; aucun pentest ni test de charge n'a été réalisé ici. Aucun quota média/R2, couverture juridique internationale ou restauration réelle n'est certifié par ce document.

## 14. Devoir de regard pour Claude

Avant de coder, pour le lot autorisé :

1. Lire ce corps normatif, puis les contrats de sa verticale en annexe et leur source GitHub actuelle. Fixer SHA/code/schema visés et déclarer les écarts depuis la photographie.
2. Relever chaque port réellement consommé, y compris routes secondaires, erreurs, offline, deep links et commandes de démonstration. Associer chaque besoin BR à un objet serveur, jamais seulement à un nom de table.
3. Vérifier les décisions citées. Les règles KYC, second adulte, mode adulte, finance par profil et exigences Comptable ne doivent pas être remplacées par le comportement legacy.
4. Rechercher lui-même les omissions : action sans contrat, capability sans contrôle serveur, projection trop large, job non durable, limite de débit absente, concurrence, preuve de sauvegarde et effet d'une ancienne version d'app.
5. Documenter toute nouvelle découverte avec fichier/ligne ou requête de catalogue, risque, correction et test. Ne pas déclarer cette V0.2 parfaite parce qu'elle est plus longue.
6. Faire relire séparément sécurité/permissions, intégrité finance-concurrence et exploitation/performance. Une même personne/agent ne s'auto-certifie pas comme revue indépendante.
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
| DB-ADM-05 | Cohortes 6-9 / 10-13 / 14-17 / 18+ et date de naissance canonique des mineurs | `definir_date_naissance_apprenant(membre, date)`, colonne protégée par RLS, cohortes dérivées | (élève, date) | âge, cohorte | Âge demandé deux fois (entier 3-18 puis tranche 5-7...), aucune date affichable | 6, 13 | Lire la liste de tranches du serveur, n'en coder aucune ; afficher un âge seulement s'il est fourni ; ne jamais dériver une date d'une tranche | C03 D5, C04 B2, C09 K3-K4 | M (point P7) |
| DB-ADM-06 | Branche débutant sans diagnostic, pré-diagnostic court pour les autres | `placement_basis` (`self_declared_beginner`), statut de diagnostic non forcé à `a_planifier` ; 2 à 4 questions adaptatives | réponses | statut de placement | L'accueil annonce à tous « Il reste un échange avec un enseignant » (`offre_horaire.dart:596-599`) | 6 | Carte « Je débute » possible, mais l'écran affiche le statut que le serveur rend, sans le réécrire | C03 D6, C09 K5 | F (point P7) |
| DB-ADM-07 | Retour natif du lien courriel et de Google | Schémas de liens profonds Android/iOS (fichiers plateforme = COORD) + URL de redirection autorisées côté Supabase (configuration serveur) ; état réel du fournisseur Google | - | - | Sur mobile natif, le retour tombe sur le « Site URL » web (`AndroidManifest.xml` sans `intent-filter`, `Info.plist` sans `CFBundleURLSchemes`) | 2, 3 | Web : fonctionnel. Mobile natif : documenter « non testable » ; COORD peut ajouter les schémas plateforme, la liste d'URL autorisées reste côté Supabase | C03 D9 | M |
| DB-ADM-08 | Changer d'horaire | `changer_offre_horaire` atomique **ou** appel client à `renoncer_intention_horaire` avant `choisir_offre_horaire` (voie frontend) | (élève, offre) | intention | « Changer d'horaire » échoue toujours (`unique_violation`, `0043:802-805`) | 6 | Voie frontend retenue si `0043` est appliquée | C03 D8 | F |

##### 2. Foyer et profils élèves

| Id | Capacité manquante | Service attendu | Entrée | Sortie | Impact UI | Écran | Comportement frontend honnête | Sources | Grav. |
|---|---|---|---|---|---|---|---|---|---|
| DB-FOY-01 | Profil élève du titulaire (« Moi uniquement », « Créer mon profil élève », « Ouvrir mon espace élève ») | `creer_mon_profil_eleve()` → `student_profiles(profile_id = auth.uid(), student_type = 'autonomous')` ; projection d'une capacité « a un espace élève » dans le jeton ou une vue ; mécanisme de bascule de session ou de rôle (un seul rôle par session aujourd'hui, G-PRE) ; appairage possible pour ce profil (`creer_code_appairage` exige `role = 'student'`, `0004:602`) | appelant | profil élève du titulaire | Aujourd'hui « Élève adulte, pour moi-même » crée un `guardian` sans fiche élève (`inscription_page.dart:38-41`) : l'adulte seul ne peut ni étudier ni choisir une classe | 5, 10, 11, 34 | Option visible et discrète « Créer mon profil élève » qui ouvre un écran d'indisponibilité expliqué ; jamais de profil fictif ; ne jamais conseiller de s'ajouter comme « enfant » (créerait un second compte `minor`) | C03 D1, C04 B7, C05 B9, C09 K17 | B |
| DB-FOY-02 | Proche adulte distinct d'un mineur | `creer_profil_enfant` paramétré par type (`autonomous`), consentement propre, droits bornés du titulaire | (type, identité) | profil | Tout élève créé est `minor` (`0004:892-893`) : le titulaire pourrait régler caméra et photo d'un adulte | 11 | Choix « Pour un proche adulte » indisponible, expliqué | C03 D2, C04 B8 | M |
| DB-FOY-04 | Interface guidée selon la politique (demande de l'élève ≥ 10 ans, décision du tuteur) | `demander_affichage_standard`, `repondre_demande_affichage_standard`, `activer_affichage_standard_tuteur`, `repasser_interface_guidee`, `interface_guidee_etat` ; statut de demande dans `profils_du_foyer_v` ; retrait de `interface_mode` du grant client ; ne plus écraser le mode depuis la cohorte (`0043:628-636`) | (élève, décision) | état | Pas de demande enfant ; le mode est une écriture directe de colonne | 15 | Garder la bascule tuteur existante sous le libellé « Interface guidée » ; aucune bascule côté élève | C04 B3, C09 K6 (contrat CORE24 réutilisable comme spécification, jamais comme code) | F (point P7) |
| DB-FOY-05 | Accès par élève : statut, début, fin, motif | projection `statut`, `debut`, `fin`, `motif` (offert, payé hors application, suspendu) par élève | foyer | lignes | Seule `access_until` est exposée ; une date passée est affichée comme valide aujourd'hui | 17, 37 | Afficher la date réelle, « expiré » si passée (calcul d'affichage), « Statut détaillé non disponible » sinon | C04 B6, C08 §3 | M |
| DB-FOY-06 | Idempotence de la création de profil | clé d'idempotence client pour `creer-profil-enfant` | (clé, brouillon) | même profil | Une réponse perdue puis un nouvel essai créent un doublon (nouvel utilisateur auth à chaque appel, `index.ts:49-57`) | 11 | Après erreur réseau : relire le foyer avant de proposer « Réessayer », signaler un possible doublon | C03 D7, C04 §5 | M |
| DB-FOY-07 | Modifier l'identité d'un élève | RPC tuteur bornée (prénom, nom) journalisée | (élève, champs) | ok | Aucune policy ne le permet (`profiles_self_update` ne vise que soi) | 13 | Champs en lecture seule, « Contactez l'académie pour corriger » quand le canal existera (DB-CPT-07) | C04 B9 | F |
| DB-FOY-08 | Photo : limites et règle | limites de taille et de type du seau `avatars`, compression, purge de l'ancienne photo ; drapeau `photo_identification_requise` + erreur `photo_requise` de `create-room-token` **si** la règle est décidée | fichier | clé | Aucune limite serveur (`0004:997-999`) ; aucune règle « photo requise » sur `main` | 8, 13 | Limite client 4 Mo conservée, aperçu, reprise ; aucun blocage « photo requise » | C04 B5, C09 K7 | F (point P6) |

##### 3. Appareils et appairage

| Id | Capacité manquante | Service attendu | Entrée | Sortie | Impact UI | Écran | Comportement frontend honnête | Sources | Grav. |
|---|---|---|---|---|---|---|---|---|---|
| DB-APP-01 | Annuler un code vivant | `annuler_code_appairage(p_student_profile_id)` | élève | void | Le code reste valable jusqu'à 10 min après la sortie de l'écran | 20 | À la sortie : retirer QR et code de l'arbre et de l'état ; dire « Ce code reste valable jusqu'à HH:MM » (heure d'expiration rendue par la RPC), sans promettre d'annulation | C05 B1 | M |
| DB-APP-02 | Statut de code fiable (consommé, remplacé) | `creer_code_appairage` rendant aussi l'`id` ; `grant select` explicite sur `mes_codes_appairage_v` | élève | (id, code, expires_at) | La vue existe (`0004:298-316`, sans empreinte) mais **aucun grant explicite** (vérifié) : repose sur les privilèges par défaut de Supabase | 20 | Scrutation courte et bornée de `mes_codes_appairage_v` par `(student_profile_id, expires_at)` **après** vérification en recette que la lecture est accordée ; sinon diff de `mes_appareils_v`. Dès `consumed_at` : retrait immédiat de QR et code, « Appareil connecté ». Sans lecture possible : état « Vérifiez sur l'appareil de l'élève », jamais un succès supposé. [critique] Indice favorable, pas une preuve : `mes_appareils_v` suit le même patron (vue `security_barrier` sans `grant` explicite, `0004:773-790`) et est déjà lue par `appareilsDuFoyerProvider` (`service_appairage.dart:210`) | C05 B2, §4 | M |
| DB-APP-03 | Révocation qui ferme les sessions ouvertes | lier session et appareil ; révoquer les refresh tokens à `revoquer_appareil` | appareil | void | « Retirer » n'éjecte pas un appareil connecté (hook JWT indifférent à `devices`, `0038:50-98`) | 18, 19 | Confirmation qui dit « L'appareil ne pourra plus se reconnecter. Une séance déjà ouverte sur cet appareil continue jusqu'à sa déconnexion. » | C05 B3 | M |
| DB-APP-04 | Politique d'appareils lisible par le tuteur | exposition de `max_devices_per_student`, `pairing_code_ttl_minutes` (vue ou `regles_academie`) | - | valeurs | `app_config` lisible par l'admin seul (`0001:969-970`) ; « 2 » et « dix minutes » figés (`service_appairage.dart:189`, `fr.i18n.json:148, 209`) | 19, 20 | Ne plus afficher de chiffre figé ; « limite atteinte » déclenché par la réponse serveur ; durée affichée = `expires_at` rendu | C05 B4, C09 K18 | F |
| DB-APP-05 | Appareil physique partagé et nom | clé pseudonyme d'appareil par foyer dans `mes_appareils_v` + RPC `nommer_appareil` | appareil, nom | - | « Appareil familial, disponible pour… » irréalisable ; `label` exposé mais jamais écrit | 19 | Une ligne par couple (profil, appareil) ; lire `label` s'il existe | C05 B5, C04 B10 | F |
| DB-APP-06 | Codes d'erreur stables | `code` machine dans la réponse de `session-enfant` et des RPC d'appairage | - | `inconnu`, `expire`, `deja_utilise`, `plafond`, `revoque` | Aujourd'hui texte libre SQL ; le client ne lit même pas la branche `error` (`FunctionsHttpException` levée avant, `service_enfant.dart:96-99`) | 22, 24 | Lire `FunctionsHttpException.details` et faire correspondre le texte connu à des messages simples ; inconnu → message générique avec reprise ; jamais le texte brut | C05 B6 | M |
| DB-APP-07 | Limitation de débit sur `session-enfant` | seau `rate_limits` existant (`0001:342-346`) | - | 429 | Risque de devinette accepté par commentaire (`session-enfant/index.ts:16-20`) | 22 | État « Trop d'essais, réessayez dans un instant » prêt, déclenché seulement par une réponse serveur | C05 B7 | F |
| DB-APP-08 | Un appareil lié à un seul foyer | contrôle à la consommation | - | refus | Deux foyers possibles sur une tablette | 23 | Aucun | C05 B8 | F (décision produit ouverte, non remontée : sans impact sur l'UI tuteur) |
| DB-APP-10 | « Une séance à la fois par profil » | lecture de `max_concurrent_sessions_per_profile` à l'émission du jeton | - | refus | Clé semée (`0001:966`), **lue nulle part dans `supabase/`** (vérifié) | 19 | Retirer la phrase du Foyer | C05 §1.5, C09 (imprécis sur ce point) | F |

##### 4. Cours, classes, séances

| Id | Capacité manquante | Service attendu | Entrée | Sortie | Impact UI | Écran | Comportement frontend honnête | Sources | Grav. |
|---|---|---|---|---|---|---|---|---|---|
| DB-CRS-01 | Classes du foyer par élève, y compris classes quittées | extension de `mes_groupes_famille_v` ou `mes_classes_foyer()` : `student_id`, parcours, niveau humain, langue, enseignant (prénom, titre, clé photo), `seuil_max`, `nb_membres`, fuseau, état | foyer | lignes | Recommandée, **pas bloquante** : la policy `groupe_membres_lecture` ouvre les lignes des élèves du foyer (`0019:322-335`, vérifié) ; jointure client possible pour les classes **courantes** seulement (`mes_groupes_famille_v` filtre `left_at is null`, `ended_at is null`) | 8, 10, 12, 26, 32 | Adaptateur `PortClassesFoyer` (jointure `groupe_membres` × `mes_groupes_famille_v`) ; classe quittée : « Classe non disponible » ; titre enseignant absent = aucun titre (jamais un repli `Sayyid`) | C06 B1, C08 B1 | M |
| DB-CRS-02 | Prochaine occurrence fiable par classe et par élève | occurrence avec `session_id`, `debut_utc`, `fin_prevue_utc`, `join_opens_at_utc`, **statut** (planifiée, annulée, reportée), `seance_ouverte`, enseignant d'occurrence + drapeau de remplacement ; statut ajouté à `horloge_seance()` | (groupe, élève) | occurrence | `horloge_seance` ne rend ni statut ni ouverture réelle (`0033:427-485`, vérifié) ; il n'autorise le tuteur que pour les séances **de groupe** (appartenance) ; `prochaineSeance` jamais renseignée par l'adaptateur v0 | 8, 26 | Croiser `mes_seances_v.status` (annulée prime) avec l'horloge ; fenêtre lue sur `join_opens_at_utc`, jamais la constante client 10 min (`pre_vol.dart:22`) ; sans horloge serveur : heure de l'appareil libellée comme telle et aucun état « Salle ouverte » | C06 B2, B14 | B |
| DB-CRS-03 | Planning daté | occurrences d'une période, heures rendues (fuseau foyer et groupe), statut, motif, remplaçant, notice DST | (groupe, période) | liste | Le client n'a aucune bibliothèque de fuseaux (`pubspec.yaml`) ; aucune conversion IANA possible côté client | 27 | Afficher le créneau hebdomadaire connu dans le fuseau du groupe, libellé explicite ; « Planning daté non disponible » | C06 B3 | M |
| DB-CRS-04 | Récurrence multi-créneaux et horizon entretenu | `groupe_creneaux` (`0043:452-459`) pris en compte par la matérialisation, ordonnanceur | - | séances | Un créneau par groupe ; séances matérialisées sur 4 semaines puis plus rien (`0033:298-306, 341-373`) | 27 | Ne jamais inventer d'occurrence | C06 B4 | M |
| DB-CRS-05 | Report et remplacement tracés | occurrence modifiée liée, motif, remplaçant | action admin | - | « Reportée », « remplacement » impossibles à distinguer d'un cours normal | 8, 27 | Aucun état « reportée » produit tant que le serveur ne le rend pas ; ne pas déduire un remplacement d'un `teacher_id` différent | C06 B5 | F |
| DB-CRS-06 | Notice DST pour la famille | `transitions_fuseau_a_venir` ouverte à la famille ou incluse dans l'horloge | séance | transition | Réservée à l'admin (`0033:513-515`) | 8, 27 | Pas de notice | C06 B6 | F |
| DB-CRS-07 | Catalogue de classes ouvertes | classes compatibles avec enseignant, toutes les séances, durée, fuseau, **places restantes serveur**, état (ouverte, complète, liste d'attente) | (élève, fuseau) | liste | Aucune source (`0043` = offres vitrines sans enseignant ni places, non appliquée) | 14, 25 | Écran « Le choix de classe n'est pas encore disponible » ; aucune réservation locale | C06 B7, C09 K1 | B (point P1) |
| DB-CRS-08 | Inscription atomique | `inscrire(classe, élève, clé d'idempotence)` → `inscrit` / `en_attente_validation` / `liste_attente` / `refuse` + motif (`derniere_place_perdue`...) | - | résultat | Aucune | 25 | Idem DB-CRS-07 | C06 B8 | B (point P1) |
| DB-CRS-09 | Photo publique de l'enseignant | URL signée courte de `teacher_photo_cle` (policy de lecture famille du seau des photos enseignants à vérifier) | clé | URL | Aucun service ne résout la clé (`espace_groupe_page.dart:314-320`) : initiales à la place | 8, 26 | Initiales de l'enseignant (jamais le portrait de l'élève) ; état « photo manquante » existant (`photo_enseignant.dart:50-88`) | C06 B9 | F |
| DB-CRS-10 | Marquer un travail fait | RPC famille `marquer_travail_fait(assignment_id, student_id)` | - | statut | `learning_assignment` lisible par le foyer, sans écriture famille (`0032:354-397`) | 8, 28 | Lecture branchée ; cases sans action, statut du service affiché ; jamais de coche locale | C06 B10 | F |
| DB-CRS-11 | Progression partageable | niveau humain courant, jalons, résumés transmis par élève | élève | vue | `progression_historique` lisible admin seul (`0021:44-46`) | 30 | « Progression non disponible » ; présence et séances réelles affichables | C06 B11 | M |
| DB-CRS-12 | Résumé de séance destiné à la famille | projection par élève sans note interne ni décisions des autres élèves | (séance, élève) | texte | Seule source actuelle : `lesson_reports`, à ne pas lire (DB-TRV-02) | 8, 33 | Section absente du détail, pas d'état vide trompeur | C06 B12, C08 B2 | M |
| DB-CRS-13 | Classe d'une séance | `groupe_id` dans `mes_seances_v` (ou vue d'historique) incluant classes quittées | séance | classe | `sessions.groupe_id` lisible par le foyer (`sessions_family_read`), libellé seulement pour les groupes courants | 8, 32, 33 | Jointure client pour les classes courantes ; sinon « Classe non disponible » | C06 B14, C08 B1 | M |

##### 5. Observation (règles du complément)

| Id | Capacité manquante | Service attendu | Entrée | Sortie | Impact UI | Écran | Comportement frontend honnête | Sources | Grav. |
|---|---|---|---|---|---|---|---|---|---|
| DB-OBS-01 | Jeton vidéo émis du tout | `autoriser_jeton_video` doit valider le compte désigné par `p_profile_id` et non `auth.uid()` (nul sous clé de service) ; correctif archivé hors dépôt (`RA_OBS/0043_autoriser_jeton_video…`), à renuméroter `0044` | (session, profil) | jeton | `0042` place `app_account_valid()` en tête de la fonction appelée par `create-room-token` avec la clé de service : **tout jeton vidéo serait refusé, pour tous les rôles** | 31 (et `/salle` hors tuteur) | Aucune recette réelle d'observation ; états « connexion vidéo impossible » et « visite consommée » affichés tels quels ; étiquette « testée en simulation » | C07 fait 4, C10 §8.4 (REVENDIQUÉ par l'archive, non remesuré) | B |
| DB-OBS-02 | Quota au moment du jeton | `budget_observation` évaluable pour `p_profile_id` depuis `autoriser_jeton_video` | (session, profil) | budget de cet observateur | Sous clé de service le budget est calculé pour un observateur nul : toujours « peut entrer », 120 s (DÉDUIT, `0039:212-249`) | 31 | Le compteur affiché vient du budget relu (`budget_observation` côté client, `auth.uid()` = tuteur) ; ne jamais le présenter comme garantie | C07 fait 5, §12-2 | B |
| DB-OBS-03 | Fin de visite imposée et intervalles orphelins fermés | expulsion LiveKit ou retrait du droit d'abonnement à l'épuisement ; fermeture serveur des intervalles abandonnés (webhook `participant_left` ou tâche planifiée) ; retrait de la ligne `session_participants` observateur | événement | ligne close | Fin décidée par le client seul ; quitter la page sans « Quitter » laisse l'intervalle ouvert (`entree_observation_page.dart:114-126`) et brûle la visite suivante (index unique puis `temps_epuise`) | 31, 32 | Appeler `sortir_observation` sur sortie de page, arrière-plan et `dispose` (frontend, réduit le problème sans le garantir) ; afficher « Durée non confirmée » pour une visite ouverte | C07 faits 6 et 8, C08 B3 | B |
| DB-OBS-04 | Motif de fin réel | `sortir_observation(p_session_id, p_motif)` ; motifs `quota_atteint`, `seance_terminee`, `deconnexion` écrits par le serveur | (séance, motif) | ligne | Le serveur écrit toujours `sortie_volontaire` (`0039:344-346`) | 31, 32, 33, C4 | Historique : « Visite terminée » générique ; jamais « Limite atteinte » déduit du client | C07 §12-4, C08 B3 | M |
| DB-OBS-05 | Enfant présent exigé | contrôle de présence dans `entrer_observation` (et au jeton) avec motifs `enfant_absent`, `presence_incertaine` que le Dart saura lire | séance | refus motivé | `entrer_observation` n'exige que l'appartenance au groupe (`0037:102-113`) | 31 | Présence lue sur `presence_seance_v` à titre **indicatif** : « Présence en vérification » quand incertaine, jamais « absent » inventé ; **l'activation réelle attend cette garantie** (point P3) | C07 fait 7, C09 K14 | B |
| DB-OBS-06 | Reprise d'une visite interrompue | réutiliser l'intervalle ouvert après reconnexion, ou motif `visite_deja_ouverte` | séance | visite | Une nouvelle entrée dans les 120 s lève 23505, traité comme « panne réseau » (`port_politique_observation.dart:301-304`) | 31 | Traduire 23505 en « Une visite est déjà ouverte » (frontend) ; jamais remettre le compteur à zéro | C07 §12-6 | M |
| DB-OBS-07 | Compteur non démarré avant la connexion vidéo | ouvrir l'intervalle après connexion, ou ne pas compter une visite dont la connexion échoue | séance | - | L'intervalle s'ouvre au clic « Entrer », avant la vidéo (`0037:133-149`) : un échec vidéo consomme la visite | 31 | L'explication et la pré-vérification (`budget_observation`, lecture sans effet) ne démarrent rien ; le texte dit que la visite est comptée dès l'entrée | C07 §12-7 | M |
| DB-OBS-08 | Restriction des pistes reçues | permissions de piste : enseignant, enfant concerné, support | jeton | abonnements | `can_subscribe = true` sans filtre : le client reçoit identités et flux de tous (`vue_observation_tuteur.dart:36-70` filtre seulement l'affichage) | 31 | Filtre d'affichage conservé ; ne pas écrire « vous ne recevez que… » | C07 §12-8 | M |
| DB-OBS-09 | Nom affichable des participants | `name` dans le jeton LiveKit | - | nom | Vignettes susceptibles d'afficher un UUID (`livekit_session_provider.dart:447`) | 31 | Libellés génériques « Enseignant », « Votre enfant » au lieu de l'identité brute | C07 §12-9 | F |
| DB-OBS-10 | Lien familial exposé à l'enfant | type de lien de l'observateur dans `annonce_observation_pour_moi` | - | lien | « Votre maman… » impossible | notices | « Votre parent observe la séance » | C07 §12-10 | F |
| DB-OBS-11 | Historique transversal | vue ou RPC de liste : tuteur (ses visites groupées par séance et enfant, classe, enseignant, indépendante de l'appartenance courante) ; admin (recherche tuteur, élève, classe, période, statut, pagination) | filtres | lignes | Seule RPC : `visites_observation(p_session_id)` par séance, 7 colonnes ; lecture directe de la table possible sous RLS | 32, 33, C4 | Lecture directe de `guardian_session_visit` sous RLS (SELECT mesuré accordé) avec jointures limitées ; classe quittée « non disponible » ; échec ou refus → « Historique des observations indisponible », jamais une liste locale | C07 §11, C08 B4 | M |
| DB-OBS-12 | Consentement exigé avant visite | exigence serveur d'une acceptation à jour des familles concernées, si le produit la veut | séance | refus | Aucun lien serveur entre consentement et visite | 31 | Aucun contrôle local présenté comme garantie | C07 §12-12 | F (lié à P2) |
| DB-OBS-13 | Fichiers `0039`-`0042` dans le dépôt | rapatrier dans `main` les migrations déjà appliquées en production | - | - | La production est en avance sur `main` ; le rejeu SQL de CI ne les couvre pas | - | Le frontend vise le comportement de production ; aucun fichier `supabase/` dans la branche UI | C08 B11, C10 §6.2 | F (gouvernance C0) |

##### 6. Historique, compte, notifications, paiements

| Id | Capacité manquante | Service attendu | Entrée | Sortie | Impact UI | Écran | Comportement frontend honnête | Sources | Grav. |
|---|---|---|---|---|---|---|---|---|---|
| DB-HIS-03 | Temps connecté et qualité réseau persistés (si voulus) | durées cumulées par (séance, élève), qualité mesurée | - | durées | Non mesurés après la séance | 33 | Colonnes absentes ; « réseau » jamais affiché | C08 B10 | F |
| DB-HIS-04 | Présence consolidée après la séance | finalisation des états « en direct » (`deconnectee`, `confirmation_en_attente` éternels, `0042:141-143`) | séance | état final | Un présent non corrigé reste « À confirmer » | 32, 33 | Fonction pure d'affichage : séance terminée non consolidée → « En cours de vérification » ; « Absence » seulement si consolidée | C08 §4.3 | M |
| DB-CPT-01 | Identité du titulaire modifiable | RPC bornée ; décision sur téléphone, pays, ville (aucune colonne) | champs | ok | Aucune écriture pour le tuteur | 35 | Lecture seule, « modifiable par l'académie » | C08 B7 | F |
| DB-CPT-02 | Sessions actives du titulaire | liste des sessions (aucune API) ; `signOut` à portée « autres » du SDK à valider sans backend | - | liste | - | 36 | Ne pas rendre la liste ; action « Déconnecter mes autres appareils » seulement si validée en recette | C08 §3 | F |
| DB-CPT-03 | Paiements | paiement transitoire saisi par l'admin, lecture famille (montant, devise, statut, date, justificatif) ; écran admin pour `access_until` | foyer | lignes | Aucune table de paiement famille (`0001:242-297` = rémunération) | 37, 38 | Une page, une phrase, aucun bouton ; jamais « abonnement » | C08 B5, C09 K21 | M |
| DB-CPT-04 | Notifications | table et émission, enregistrement `device_tokens`, push | événement | notification | Aucune source ; cloche admin = faux état vide | 9 | Page « Les notifications ne sont pas encore disponibles », cloche sans pastille ; préférences de notification retirées | C08 B6, C09 K20 | M |
| DB-CPT-05 | Messages famille | RPC de transmission de `student_concern` vers `concern_famille_v` + adaptateur `PortSignalement` | - | messages | Aucun circuit ; `concern_famille_v` jamais alimentée | 9 | Pas de lecteur tant que rien ne l'alimente | C08 B6 | F |
| DB-CPT-06 | Fuseau du foyer modifiable | RPC de `0043:644` | fuseau IANA | ok | Tout foyer naît en `Europe/Paris` (`0004:352, 386-388`) | 35, 39 | Fuseau en lecture seule, avec la mention que la valeur peut être le défaut | C08 B8 | F |
| DB-CPT-07 | Canal d'aide | décision du directeur (courriel, lien) et, si besoin, paquet d'ouverture de lien (COORD) | - | - | Aucun canal | 40 | Page indisponible | C08 §3 | F |
| DB-CPT-09 | Persistance des préférences (dépendance **frontend**, pas serveur) | stockage local choisi par COORD (aucun paquet aujourd'hui) ou préférences serveur | préférences | - | Réglages perdus au redémarrage (`preferences_locales.dart:18-22`) | 39 | Texte honnête « sur cet appareil, jusqu'à la fermeture » tant que rien n'est persisté ; thème réellement appliqué (`app.dart`) | C04 B11, C08 §2.3 | F |
| DB-CPT-10 [critique] | Langue de l'interface (dépendance **frontend** et de contenu, pas serveur) | traduction complète et sélecteur de langue (`LocaleSettings.setLocale`) persistant (DB-CPT-09) | langue | - | L'application suit la langue de l'appareil (`main.dart:33`) ; `ar.i18n.json` compte 32 lignes contre 2 208 pour `fr` | 39 | « Français » affiché en lecture seule ; aucun choix d'arabe proposé ; langue d'enseignement traitée à part (questionnaire, DB-ADM-01) | mandat §4, manifeste #15 | F |
| DB-CPT-08 | Documents légaux complets | textes CGU, confidentialité, mentions légales | - | documents | Aucun document dans le dépôt | 41 | Liste des acceptations signées (version, date) ; « Document non disponible » | C08 §3 | F |

##### 7. Transverses et sécurité (à signaler, jamais à masquer par l'UI)

| Id | Sujet | Constat | Impact frontend | Sources | Grav. |
|---|---|---|---|---|---|
| DB-TRV-01 | Policy `student_profiles_family_update` sans contrôle de rôle | Vérifié : filtre le foyer (`app_household_id()`), pas le rôle (`0005:535-556`), grant de colonnes à tout `authenticated` (`0005:562-564`) ; le hook pose `household_id` pour les élèves (`0038:95-96`). Un compte élève pourrait écrire `interface_mode`, `camera_policy`, `avatar_storage_key` de lui-même et de sa fratrie (non exécuté) | Aucune bascule côté élève ; ne pas présenter la fiche comme « seul le tuteur peut modifier » | C04 §1-9, C09 §4.5 | B (sécurité) |
| DB-TRV-02 | `lesson_reports` lisible par tout foyer d'un participant | `content` porte les décisions de tous les élèves du groupe (`0001:1070-1078`, `modeles_enseignant.dart:631-676`) | Ne jamais lire cette table côté tuteur ; résumé famille = DB-CRS-12 | C06 §9, C08 §4.4 | B (sécurité) |
| DB-TRV-03 | Politique réseau absente | aucun timeout centralisé dans `lib/core` | Jetons `AppDelais` documentés côté frontend (contrat K5) | C02 §14 | F |
| DB-TRV-04 | Retour vers la destination après connexion | `retour` doit survivre au trajet du lien magique et de Google : paramètre de `emailRedirectTo` autorisé côté Supabase (configuration) | À défaut, mémoriser le chemin (non sensible) en mémoire de session du navigateur | C01 §10-4 | F |
| DB-TRV-05 | Règles d'académie lisibles par les familles | `regles_academie()` (0043) | Capacités, fenêtre, plafonds affichés seulement s'ils sont rendus | C09 §6-10 | F |
| DB-TRV-07 [critique] | Adaptateurs réels groupes et horloge (dépendance **frontend** soumise à décision, pas serveur) | La vue et les RPC existent (`mes_groupes_famille_v` `0033:140-173` avec `grant select` à `authenticated` ; `horloge_seance` `0033:427-488` ; `maintenant_serveur` `0030:67-76`) mais aucun code de la base ne les lit : `GroupesSupabase` et `HorlogeSeanceSupabase` n'existent que dans `33503fe` ; `maintenant_serveur` n'est appelé nulle part dans `lib/` ; les providers servent les doubles (`port_groupes.dart:37-39`, `port_horloge_seance.dart:54-55`) | Sans P8, K2 fonctionne en `horaireIncertain` et `PortClassesFoyer` n'a pas de source réelle : Accueil (bloc classe, compte à rebours) et Classe restent en « Classe non disponible », jamais la démo. Réécrire ces adaptateurs sans P8 reviendrait à refaire `33503fe` : même décision requise | C06 §11, C10 §6.1 | B (pour Accueil et Classe) |
| DB-TRV-06 | Déploiement involontaire | `main:.github/workflows/flutter-deploy.yml` déploie en production sur `workflow_dispatch` depuis toute branche sans `ab5f7f7` | Aucun lancement manuel, aucun push, aucun tag dans ce chantier | C10 §8.1 | B (infra) |

##### 8. Lecture rapide : ce qui bloque une recette « vérifiée réellement »

- **Observation réelle** : DB-OBS-01 (jeton), DB-OBS-02, DB-OBS-03, DB-OBS-05. Tant qu'elles manquent, le parcours Observation se livre « UI réalisée, testée en simulation ».
- **Parcours familial complet du mandat §11.2** : DB-ADM-01 (questionnaire), DB-CRS-07/08 (choix de classe), DB-FOY-01 (profil du parent plus tard), DB-CRS-02 (séance réelle dans l'accueil).
- **Appairage** : réel côté serveur (§0) ; la recette « disparition du QR à la confirmation » dépend de la lecture de `mes_codes_appairage_v` (DB-APP-02, à mesurer sur staging), la caméra réelle d'un appareil mobile (aucun émulateur ni appareil sur la machine, `C11` §1).
- **Compte** : paiements, notifications, aide, légal restent des écrans d'indisponibilité ; identité, fuseau, acceptations, accès par élève sont branchables sans backend.
- [critique] **Accueil et Classe réels** : dépendent aussi de DB-TRV-07 (adaptateurs de `33503fe`, point P8), pas seulement de DB-CRS-02 ; sans P8, seule la liste des élèves et `mes_seances_v` sont réellement lues à l'Accueil.
- [critique] Identifiants absents de la numérotation (DB-FOY-03, DB-APP-09, DB-HIS-01, DB-HIS-02) : fusionnés lors du dédoublonnage, rien n'a été perdu à la connaissance de la critique ; ne pas les réattribuer.



### A2. 10_classe/CL-4-BR.md

[Source GitHub figée](https://github.com/rewayahacademy-glitch/Rewayah-Academy-Official-App/blob/708ef8f59bfefae89db071764d3f90a7d6b13322/10_classe/CL-4-BR.md).

#### CL-4 : besoins serveur (branchement BR-1)

Une ligne par besoin. Démonstration seulement jusqu'à BR-1 (K-28).

##### CL-4.2 (socle de démonstration, 26/09/2026)

- Horodatages qui font foi de chaque occurrence : début, fin prévue, ouverture de la fenêtre (`join_opens_at`) et fermeture, pour `FenetreSeance` / `SessionClockVM` (R5).
- Instant serveur de référence (`maintenant_serveur()`) pour recalculer l'état après reconnexion ou saut d'horloge, jamais `DateTime.now()` seul.
- État « séance annulée » de l'occurrence, pour `EmplacementEntree.pour(annulee: true)`.
- État « préparation en cours » (pré-vol ouvert pour cette séance), si l'emplacement doit le montrer depuis un autre appareil ou après rechargement.
- Présence déjà connectée avant T0 (`connecte`) pour distinguer « attente » de « fenêtre ouverte ».
- Notice DST rendue côté serveur (heures avant et après déjà converties, échéance) : le client ne convertit aucun fuseau.
- Projection pédagogique des élèves pour l'enseignant (niveau, page de reprise, dernier point utile, présence récente en texte neutre), sans donnée famille (R15).
- Support prévu de la séance (titre, chapitre, pages), « Avant le prochain cours » (3 au plus) et ressources de la classe (titre, type, taille).
- Photo publique de l'enseignante (repli initiales en attendant).
- CL-4.4 : sources à brancher pour l'Espace Classe enseignant - `preparationSeanceProvider(groupeId)` (support prévu, position de reprise, objectif), `projectionElevesProvider(groupeId)` (page de reprise, dernier point, par studentId), et `PortGroupes.groupe(id)` / horloge de séance lisibles par l'enseignant de la Classe (aujourd'hui, sans lecture, la carte dit « Aucune séance prévue »).
- CL-4.5 (préparation enseignant, `SallePage(preparation: true)`) : à brancher - nom de la classe, temps avant le début et nombre d'élèves attendus dans `ContextePreparation` (aujourd'hui seuls support et reprise sont lus, via `preparationSeanceProvider`) ; qualité réseau LiveKit avant connexion pour « Connexion instable » (R12, aujourd'hui seulement en ligne / hors ligne) ; ouverture des réglages système (« Ouvrir les réglages ») et choix du périphérique (« Modifier les périphériques », sortie audio si la plateforme le permet), absents faute d'action réelle ; test caméra réel (aujourd'hui retour local) ; états serveur « séance terminée » et « non attribuée » à relier à `IssuePreparation` ; erreur d'autorisation après le bouton (reste l'impasse existante de la salle).
- CL-4.6 (préparation élève, `PreparationEleve` via `SallePage(preparation: true)` pour le rôle élève) : à brancher - la ligne « Accès à la classe » ne lit aujourd'hui que la connectivité (l'autorisation serveur de la séance reste demandée après « Entrer dans la classe ») ; « Autoriser le micro » ouvre la feuille CL-7 sans action système réelle (pas de redemande de permission ni « Ouvrir les réglages » avant un paquet de permission) ; « Continuer sans micro » entre en sautant le blocage matériel (`_sansMicro`) : vérifier que le moteur LiveKit ne crée aucune piste audio dans ce cas ; qualité réseau LiveKit avant connexion (R12) pour « Connexion instable ».



### A3. 11_admin/AD-BR.md

[Source GitHub figée](https://github.com/rewayahacademy-glitch/Rewayah-Academy-Official-App/blob/708ef8f59bfefae89db071764d3f90a7d6b13322/11_admin/AD-BR.md).

#### AD-BR - Besoins serveur de la vague Admin (K-28)

Une ligne par besoin, format « quoi | où | pourquoi ». Numérotation alignée sur `01_RELEVE.md` §9.
Chaque identifiant est rendu par l'implémentation « indisponible » d'un port (`CapaciteIndisponible('AD-BR-nn')`).
Aucun adaptateur serveur n'est écrit côté client avant que la ligne soit servie.

##### AD-4 (ports de revue des dossiers et de politique KYC)

- AD-BR-01 : RPC `list_reviewable_dossiers` paginée (curseur, limite, rôle), une ligne par personne, sans `object_key`, tri soumission croissante puis id, total fiable, autorisation et politique appliquées avant pagination | `PortRevueDossiers.listerDossiers` (lib/core/capacites/port_revue_dossiers.dart) | contrat §17.1, 01_RELEVE §9 n°1
- AD-BR-02 : RPC `get_dossier_for_review` avec révision, statut, référence de pièce, vérifications, accords versionnés, `can_validate` / `can_reject` / `can_view_document`, blocages et conséquence de la validation | `PortRevueDossiers.dossierPourRevue` | contrat §17.2, n°2
- AD-BR-03 : lecture de pièce par `autoriser_lecture_piece_identite` / Edge `piece-identite-acces` (couple dossier + document vérifié, audit par pièce) à la place de `createSignedUrl` côté client | `PortRevueDossiers.demanderVuePiece` ; pont démo `ServiceValidationDemo.apercu` | contrat §17.3, n°3
- AD-BR-05 : persistance et recontrôle serveur des trois vérifications transmises avec la décision (`missing_required_check`) | `PortRevueDossiers.decider(verificationsFaites)` | contrat §17.4/§17.6, n°5
- AD-BR-06 : `decide_dossier` au niveau du dossier : `expected_revision`, `stale_dossier`, `already_decided`, `cannot_activate`, retour typé (statut final, état d'accès, `new_revision`, `decided_at`) | `PortRevueDossiers.decider` | contrat §17.4, n°6, 8, 9
- AD-BR-07 : idempotence par `command_id` et lecture `get_decision_result` (pending, succeeded, failed, unknown) | `PortRevueDossiers.resultatDecision` | contrat §17.6, P-ADM-10, n°7
- AD-BR-16 : politique `genre_reviewer_enforced` versionnée (valeur initiale true), lue par `read_kyc_documents`, `dossiers_en_attente` et la décision | `PortPolitiqueRevueKyc.lire` (lib/core/capacites/port_politique_revue_kyc.dart) | contrat §17.5, §15.4, n°16
- AD-BR-17 : RPC `get_kyc_review_policy` / `set_kyc_review_policy` (Super Admin, `expected_version`, audit de l'acteur, ancienne et nouvelle valeur) | `PortPolitiqueRevueKyc.modifier` | contrat §17.5, n°17
- AD-BR-18 : fondation Super Admin (claim ou table de capacités, sans valeur `super_admin` dans `app_role`), miroir client dans `SessionState` ; en attendant, capacité simulée dans le seul double de démonstration | `PolitiqueRevueKyc.peutModifier` ; `PolitiqueRevueKycDemo` | Q40, n°18

##### Ajouts AD-5 (2026-09-26)

- AD-BR-01 (complément) : `dossiers_en_attente` rend UNE LIGNE PAR PIÈCE VISIBLE (left join, 0029:124-145), pas une ligne par personne. L'adaptateur `RevueDossiersDepuisValidation` dédoublonne par profile_id en gardant la plus ancienne ; la 2e pièce n'apparaît qu'après décision sur la 1re. Besoins : une ligne par personne, total fiable (compteur), curseur (« Charger les dossiers suivants »). | lib/core/capacites/revue_dossiers_depuis_validation.dart | spec §9.9, 01_RELEVE §5 l.151
- AD-BR-01 (complément) : liste des valeurs de subject_role supportées par le serveur, pour un filtre « Type de dossier » (spec §9.7 l.673-677). Sans elle, filtre et état « Aucun dossier ne correspond à ce filtre. » absents. | PortRevueDossiers.listerDossiers(role) | UX groupe 2 l.39
- AD-BR-01 (complément) : submitted_at distinct de la date d'inscription pour un dossier sans pièce ; l'adaptateur rend deposeLe (à défaut inscrit_le). | DossierEnFile.soumisLeUtc | spec l.1929
- AD-BR-02 et 06 (rappel) : review_status et revision absents de la file ; l'adaptateur rend aVerifier et revision 0, jamais affichée. | DossierEnFile.revision | spec §9.9
- AD-BR-19 (nouveau) : fuseau IANA du profil admin lisible par le client (spec §26 ter l.1929). Aucun fuseau exposé (01_RELEVE l.181), aucun paquet de fuseaux (pubspec interdit). Défaut appliqué : heures en UTC, notées « (UTC) ». | dateRevue (lib/features/admin_dossiers/textes_dossier.dart) | spec l.1929

##### Ajouts AD-6 (2026-09-26)

- AD-BR-02 (complément) : en production, le détail est reconstruit depuis la file `dossiers_en_attente` déjà chargée (même cache), aucun appel nouveau. Absents, donc non affichés : révision (0, jamais affichée : « Ce dossier a changé depuis son ouverture. » n'apparaît jamais en production), accords versionnés (carte « Accords et éléments soumis » masquée), conséquence de validation (`indeterminee`), review_status (toujours « En cours de vérification »). can_validate / can_reject non fournis : déduits de etat_piece et document_id (écart ouvert avec §10.13 « le serveur décide »). | RevueDossiersDepuisValidation.dossierPourRevue | spec §10.13
- AD-BR-03 (rappel AD-6) : « Voir la pièce » inactif en production ET en démonstration jusqu'à AD-7, légende « La consultation de la pièce est indisponible pour le moment. ». L'aperçu en ligne (createSignedUrl + Image.network) est retiré du détail (modification 13). Besoin : autoriser_lecture_piece_identite ou Edge piece-identite-acces avec le couple dossier + document vérifié. AD-6 ne doit pas être fusionné sans AD-7 (Q-AD6-1). | lib/features/admin_dossiers/revue_dossier.dart | spec l.1974
- AD-BR-05 (rappel) : les trois vérifications sont locales, jamais persistées ni recontrôlées ; decider_dossier ne les reçoit pas (AC-19 l.2043 non garanti serveur). | RevueDossier._faites | spec AC-19
- AD-BR-06 (complément AD-6) : decider_dossier(p_document_id) décide par pièce ; un dossier sans pièce n'est ni validable ni refusable en production (« Ce dossier ne peut pas être refusé dans son état actuel. »), alors que P-ADM-08 l.1886 veut un refus possible s'il est autorisé. Ni stale_dossier ni already_decided : « dossier modifié » et « conflit » inatteignables en production. | ServiceValidation.decider | spec P-ADM-08
- AD-BR-19 (rappel) : « Date de dépôt » en UTC, notée « (UTC) ». | dateRevue | spec l.1929

##### Ajouts AD-6, corrections (2026-09-26)

- AD-BR-03 (décision provisoire, à confirmer par le directeur, Q-AD6-1) : jusqu'à AD-7, l'adaptateur de production FERME la validation. Les trois vérifications sont affichées non modifiables, Valider reste désactivé avec « Ce dossier n'est pas encore prêt à être validé. » (nouveau blocage `BlocageRevue.pieceNonConsultable`). Personne n'atteste « La pièce est lisible » sans l'avoir vue. Le refus reste possible. Variante non retenue sans accord : « Voir la pièce » ouvrirait l'aperçu existant (createSignedUrl) dans AppBottomSheet. La démonstration n'est pas touchée. | lib/core/capacites/revue_dossiers_depuis_validation.dart | spec l.1974
- AD-BR-07 (nouveau, dérogation provisoire) : le motif de refus EN LIGNE (TextField, clés motif/motifRequis, « la famille… » faux pour un enseignant) est maintenu jusqu'à AD-8 (modification 19, ADM-02D §26 ter l.1949) pour garder la production fonctionnelle. Quand le motif est ouvert, le premier « Refuser le dossier » est masqué : un seul bouton destructif est visible. Valider appelle encore decider_dossier sans confirmation 02E (Q-AD6-2). | lib/features/admin_dossiers/revue_dossier.dart | spec §10.11, §26 ter

##### Mise à jour AD-7 (26/09, commit 466fdcc sur ui/admin-v1, non poussé)

- AD-BR-03 (mise à jour) : en production, la pièce se lit désormais par le mécanisme client EXISTANT (`ServiceValidation.apercu`, `createSignedUrl` 60 s, seau kyc), sans audit par pièce (`kyc_document_open`), sans exigence positive de rôle ni filtre de genre côté stockage (`kyc_lecture_admin` couvre tout le seau). Besoin BR-1 : brancher `autoriser_lecture_piece_identite` / Edge `piece-identite-acces` à la place. Tant que ce n'est pas fait, la validation rouverte repose sur une lecture sans journal.
- Nouveau besoin : `dossiers_en_attente` ne fournit pas le type MIME ; il est déduit de l'extension d'`object_key` (jpg, jpeg, png, webp seulement). BR : rendre `content_type` et l'échéance réelle depuis la porte serveur.
- Nouveau besoin : sur le web, l'errorBuilder d'Image ne donne pas le statut HTTP ; l'expiration est déduite de l'horloge (`expireLeUtc`). BR : code d'expiration explicite côté Edge (401/403 typé).
- Rappel : `object_key` est exposé au client par la file (0029). À retirer quand l'Edge sera branché.
- Formats : pdf et heic acceptés au dépôt, non affichables (pas de dépendance possible, pubspec interdit) : validation fermée, refus ouvert. BR ou décision produit (Q-AD7-2).

##### Ajouts AD-8 (26/09, ui/admin-v1, non poussé)

- AD-BR-06 (production, AD-8) : decider_dossier n'a pas de garde d'état. L'UPDATE se fait par l'id seul (0004:550-556) et read_kyc_documents ne filtre pas le statut : une seconde décision sur un document déjà décidé RÉUSSIT et écrase la première, même opposée, par un autre administrateur, et écrit une seconde trace kyc_decision. « Conflit » et « déjà décidé » ne sont atteints que si le document a déjà disparu de la file en cache. | RevueDossiersDepuisValidation.decider | P-ADM-05, AC-14, AC-17
- AD-BR-07 (production, AD-8, remplace la dérogation du motif en ligne, levée) : ni command_id ni get_decision_result. Après un résultat inconnu (délai de 20 s AppDelais.requeteMax ou réponse perdue), le client relit la file en cache puis la recharge par dossiers_en_attente (existant). Absent : « Ce dossier a déjà été traité. », non attribué. Présent : échec, reprise de la MÊME charge permise (Q-AD8-9). Risque résiduel : une requête encore en vol peut aboutir après la reprise et produire deux traces. | RevueDossiersDepuisValidation.resultatDecision | P-ADM-10, §17.6
- AD-BR-02 et 06 (conséquence) : la RPC ne dit pas si la validation active le compte ; en réalité decider_dossier passe account_status à active si pending_kyc (0004:558-562), sans contrôler les accords. Faute de champ de conséquence, 02E est indisponible en production (Q21) : la validation est FERMÉE en production (Q-AD8-1, recul par rapport à AD-7). | DossierPourRevue.consequence | §13.2 l.1113
- AD-BR (nouveau) : les erreurs de decider_dossier sont des raise exception P0001 à texte libre ; la carte client repose sur des sous-chaînes (« un refus exige un motif », « introuvable ou hors du perimetre », « seul un administrateur »), fragile. Besoin : codes typés (forbidden, already_decided, stale_dossier, missing_reason, reason_too_long). | RevueDossiersDepuisValidation.decider | §17.4
- AD-BR (nouveau) : aucune longueur maximale du motif côté serveur (0004:536-541) ; motifTropLong (« Le motif dépasse la longueur autorisée. ») est inatteignable en production. | CodeErreurRevue.motifTropLong | Q30, l.1985
- AD-BR-05 (rappel) : les vérifications cochées ne partent pas avec decider_dossier (AC-19 non garanti par le serveur).
- Rappel sécurité : decider_dossier teste app_role() <> 'admin' (garde négative : NULL <> 'admin' ne lève pas, 01_RELEVE l.134) et n'appelle pas app_account_valid. Hors lot, aucune modification serveur.

##### Corrections de revue AD-8 (26/09, ui/admin-v1, poussé sur origin)

- AD-BR-07 (corrige la ligne « Présent : échec, reprise permise » ci-dessus) : en production, un dossier ENCORE PRÉSENT après relecture rend `EtatCommandeEnAttente` et reste « résultat inconnu » : seuls « Fermer » et « Vérifier le résultat », jamais « Réessayer » (la requête peut être encore en vol, decider_dossier n'est ni idempotent ni gardé). La reprise n'est rouverte qu'avec command_id + get_decision_result côté serveur. Conséquence : un dossier réellement non traité reste bloqué pour la session tant que la relecture le montre présent ; l'administrateur peut le rouvrir après rechargement de l'application. | RevueDossiersDepuisValidation.resultatDecision | P-ADM-10.6, spec l.2010
- Q30 relié : reason_too_long n'existe pas côté decider_dossier (aucune limite, besoin l.53-54) ; « Le motif dépasse la longueur autorisée. » n'est atteignable qu'en démonstration et par port de capture. | CodeErreurRevue.motifTropLong | Q30
- Session : les commandes non résolues survivent au départ de la page (keepAlive tant qu'une commande est non résolue) ; aucune nouvelle décision sans relecture. Côté client seulement, rien ne remplace la garde serveur. | decisionsDossiersProvider | P-ADM-10.6

##### Ajouts AD-9 (26/09, commit admin 15c6cd7, non vérifiés côté serveur)

| Id | Besoin | Port / écran | Source |
|----|--------|--------------|--------|
| AD-BR-16 (complément AD-9) | La politique doit aussi être lue par `comptes_admin()` (ADM-08 calcule l'état de pièce sans genre, 0015:160-174) et par la Storage policy `kyc_lecture_admin` (tout le seau, sans genre, 0004:1013-1017). Sinon, politique activée, le cloisonnement se contourne. | PortPolitiqueRevueKyc.lire | 01_RELEVE l.102, l.133, n°21 |
| AD-BR-17 (complément AD-9) | `set_kyc_review_policy` doit rendre des codes typés (`forbidden`, `stale_policy_version`) et une date serveur, et auditer (acteur, ancienne et nouvelle valeur, date). Mention d'audit masquée tant que ce n'est pas prouvé (Q37). | PortPolitiqueRevueKyc.modifier | spec l.127, l.1203 |
| AD-BR-18 (rappel AD-9) | La capacité Super Admin n'existe pas côté serveur. En production, l'onglet n'apparaît jamais et la route affiche « Pas encore disponible » : fondation requise (claim ou table de capacités, hors `app_role`). | peutReglerPolitiqueKycProvider | Q40 |
| AD-BR-20 (rappel n°20) | `profiles.gender` modifiable par son propriétaire (`profiles_self_update` ; `guard_profile_privileged_columns` ne couvre pas `gender`, 0001:541-560, 713-715) et par tout admin (0001:704-705) : §3 point 6 non tenu côté serveur. RPC administrative auditée requise pour poser le genre du personnel ; le bouton « Compléter mon profil » en dépend. | GenreManquant (revue_dossier.dart) | spec §3.6, §15.3 l.1211, 01_RELEVE l.100-101 |
| AD-BR-16 (production) | Filtre de genre codé en dur et sans condition (`read_kyc_documents` 0004:202-213, partagé par file, décision et lecture 0029:125, 0004:545, 0034:170-172) : « politique désactivée » n'existe qu'en démonstration. `kyc_admin_all` (FOR ALL admin, sans genre) laisse lire `kyc_documents` hors filtre. | RevueDossiersDepuisValidation | 01_RELEVE l.94, l.131-132 |
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
| BR-AD-03 | RPC ou Edge `request_kyc_document_view(dossier_id, document_id)` (existant à réutiliser : `autoriser_lecture_piece_identite` / `piece-identite-acces`) : URL ou handle temporaire, expiration, type MIME autorisé. | Lecture : relecteur autorisé ; le serveur vérifie session, capacité, dossier, appartenance du document et version, à chaque délivrance et renouvellement. Aucun chemin choisi par le client. Seau privé, `kyc_lecture_admin` à restreindre. | Une trace par ouverture (`kyc_document_open`) : acteur, dossier, document, date serveur. Jamais le contenu ni le jeton. | Délivrance et trace dans la même opération. | Version du document vérifiée ; erreur `expired` typée. | Appliquée à la délivrance, y compris dans la policy Storage. | `PortRevueDossiers.demanderVuePiece` (PRD:342) | DEMO:357 (document fictif) ; production : `ServiceValidation.apercu` (`service_validation.dart:221`, `createSignedUrl` sans audit) | AD-BR-03 ; §17.3, §17.6, §16.2, §16.3, §28.3 |
| BR-AD-04 | Persistance des trois vérifications humaines : soit transmises avec la décision, soit `save_review_checks(dossier_id, expected_revision, document_revision, checks, command_id)`. Le serveur rejette une décision sans les vérifications obligatoires (`missing_required_check`). | Écriture : relecteur autorisé ; contrôles calculés par le serveur non modifiables. | Vérifications rattachées à la trace de décision. | Avec la décision, dans la même transaction. | Révision attendue ; un changement de pièce rend les vérifications obsolètes. | Même contrôle que la décision. | `PortRevueDossiers.decider(verificationsFaites)` (PRD:348) ; pas encore de port `save_review_checks` | DEMO:357 ; production : cases locales jamais envoyées | AD-BR-05 ; §17.4, §17.6, §28.4, AC-19 |
| BR-AD-05 | RPC `decide_dossier(dossier_id, expected_revision, decision, command_id, vérifications, motif)` : motif non vide après suppression des espaces si refus, longueur maximale ; rend `final_review_status`, `access_state`, `new_revision`, `decided_at`. | Écriture : relecteur autorisé seulement (garde POSITIVE de rôle et `app_account_valid`), enseignants seulement (K-47). | Trace obligatoire : dossier, décision, acteur, date serveur, version du dossier, motif si refus, résultat. Motif hors télémétrie générale. | Décision, effet d'accès et audit dans UNE transaction : jamais partiels. Le serveur recontrôle session, capacité, périmètre, révisions, état, vérifications et accords à l'exécution. | `expected_revision` et état attendu ; `stale_dossier`, `already_decided` (aujourd'hui une seconde décision écrase la première). | Recontrôlée à l'exécution ; un `can_validate` lu avant ne vaut pas autorisation. | `PortRevueDossiers.decider` (PRD:348) ; état de session `decisionsDossiersProvider` | DEMO:357 ; production : RDV:306 sur `decider_dossier` (validation fermée) | AD-BR-06, BR-1.f ; §17.4, §16.3, §16.4, §28.5 à 28.9 |
| BR-AD-06 | Idempotence par `command_id` stable et lecture `get_decision_result(dossier_id, command_id)` : `pending`, `succeeded` avec résultat, `failed`, `unknown`. | Lecture : l'acteur de la commande et l'administration du périmètre. | Une seule trace par `command_id`, même rejouée. | Rejouer la même commande ne crée ni seconde décision ni seconde trace. | Clé d'unicité sur `command_id` ; aucune décision dans une file hors ligne. | Sans objet. | `PortRevueDossiers.resultatDecision` (PRD:358) | DEMO:357 ; production : RDV:368 relit la file, « Réessayer » bloqué | AD-BR-07 ; §16.4, §17.6, P-ADM-10 |
| BR-AD-07 | Codes d'erreur typés pour toutes les RPC de revue (`unauthorized`, `forbidden`, `not_found`, `stale_dossier`, `already_decided`, `missing_required_check`, `missing_required_acceptance`, `document_unavailable`, `cannot_activate`, `expired`, `unsupported_type`, `temporarily_unavailable`, `missing_reason`, `reason_too_long`), à la place des textes libres P0001. | Sans objet. | Sans objet. | Sans objet. | Sans objet. | Un refus de politique rend `forbidden`, sans révéler le genre du dossier. | Codes `CodeErreurRevue` (PRD:98 et suivants) | DEMO:357 rend chaque code | AD-BR (codes typés, AD-8) ; §17.1 à §17.4 |
| BR-AD-08 | Conséquence réelle de la décision : dire si la validation ouvre l'accès ou s'il reste une condition (accords, paiement) ; `access_state` distinct de la décision. | Lecture : relecteur ; écriture de l'accès par la seule transaction de décision. | Effet d'accès dans la trace de décision. | Accès et décision ensemble (§28.7). | Comme BR-AD-05. | Sans objet. | `DossierPourRevue.consequence` (via PRD:337) | DEMO:357 (conséquences variées) ; production : `indeterminee`, confirmation 02E indisponible | AD-BR-02, AD-BR-06 (AD-8) ; §17.4, §28.7 |
| BR-AD-09 | RPC `get_kyc_review_policy()` → `genre_reviewer_enforced`, `version`, `updated_at`, `can_update`. | Lecture : tout relecteur autorisé ; la lecture n'accorde aucune capacité de revue. | Non exigé. | Sans objet. | Version rendue pour la mutation. | Source de vérité unique : aucun cache Flutter ne décide. | `PortPolitiqueRevueKyc.lire` (PPK:34) ; `politiqueRevueKycProvider` (PPK:65) | `PolitiqueRevueKycDemo` (DEMO:650) ; production : indisponible (AD-BR-16) | AD-BR-16 ; §17.5, §15.1 |
| BR-AD-10 | RPC `set_kyc_review_policy(genre_reviewer_enforced, expected_version)` → valeur, version, `updated_at`. | Écriture : Super Admin seulement ; un relecteur ordinaire reçoit `forbidden`. | Acteur, ancienne valeur, nouvelle valeur, date serveur. | Mutation et trace dans une transaction. | `expected_version` ; `stale_policy_version` si une autre modification est passée. | C'est la politique elle-même ; aucun élargissement au-delà de la capacité et du périmètre KYC. | `PortPolitiqueRevueKyc.modifier` (PPK:36) | DEMO:650 ; production : indisponible (AD-BR-17) | AD-BR-17 ; §17.5, §15.2 |
| BR-AD-11 | Application de la politique dans TOUS les chemins : file, détail, lecture de pièce, décision, `comptes_admin()` et policies `kyc_lecture_admin`, `kyc_admin_all`. Aujourd'hui le filtre est codé en dur dans `read_kyc_documents`, sans condition. | Les RLS et la porte Storage lisent la politique ; aucun chemin de lecture ne la contourne. | Non exigé en plus de BR-AD-03 et BR-AD-05. | Sans objet. | Sans objet. | `true` : règle existante, retrouvée et testée ; `false` : aucun filtre ni refus fondé sur le genre, du relecteur ou du dossier. | Pas de port propre : couvert par PRD:330 à 358 | DEMO:357 et DEMO:650 (bascule simulée) | AD-BR-16 (AD-9) ; §15.1, §17.5, §28.11 |
| BR-AD-12 | Capacité Super Admin réelle (claim ou table de capacités, sans nouvelle valeur `super_admin` dans `app_role`), lue par le client pour afficher le réglage. | Lecture : la personne elle-même ; écriture : procédure administrative auditée. | Attribution et retrait audités. | Sans objet. | Sans objet. | Sans objet. | `PolitiqueRevueKyc.peutModifier` (PPK) ; `peutReglerPolitiqueKycProvider` (PPK:74) | DEMO:650 (capacité simulée) ; production : onglet jamais visible | AD-BR-18 ; §15.2, Q40 |
| BR-AD-13 | Capacité administrative de revue prouvée côté serveur pour chaque lecture et mutation (« admin » seul ne suffit pas), compte valide et périmètre du dossier. Aucun rôle enseignant, tuteur, élève, contrôleur ou comptable ne la reçoit. Le titulaire consulte son propre dépôt par son contrat personnel. | Toutes les RPC de revue : garde positive (pas `app_role() <> 'admin'`, qui laisse passer NULL) et `app_account_valid()`. | Refus d'accès journalisés si le contrat d'audit le prévoit (non dit par la spec). | Sans objet. | Sans objet. | Ne donne jamais plus que la capacité et le périmètre. | Tous les appels de PRD ; aucun port de capacité de revue dédié (pas encore de port) | DEMO : session administrateur fixe | §16.2, §28.10 ; 01_RELEVE l.134 |
| BR-AD-14 | Genre du relecteur non modifiable librement : retirer `gender` des colonnes que le titulaire et tout admin peuvent écrire ; RPC administrative auditée pour le poser. | Écriture : procédure administrative seulement ; le relecteur ne peut pas changer son genre pour obtenir plus de dossiers. | Ancienne et nouvelle valeur, acteur, date. | Sans objet. | Sans objet. | Politique active et genre manquant : refus serveur explicite et récupérable (`profil à compléter`) ; politique désactivée : le genre absent ne bloque rien. | `CodeErreurRevue.profilACompleter` (PRD:98, levé à RDV:116) ; pas encore de port de correction du genre | DEMO:357 (cas profil à compléter) | AD-BR-20 ; §15.3 |
| BR-AD-15 | Relecture des files ouvertes après un changement de politique : signal (Realtime ou version de politique rendue par chaque RPC) pour que la prochaine actualisation relise la règle serveur. | Lecture : relecteurs autorisés. | Sans objet. | Sans objet. | Version de politique comparée à chaque appel ; une ancienne autorisation locale ne vaut rien. | Le serveur, pas le client, tranche à chaque appel. | `dossiersEnAttenteProvider` (`service_validation.dart:258`), `politiqueRevueKycProvider` (PPK:65) | DEMO:650 (seule la session qui bascule relit) | AD-BR-16 (actualisation) ; §15.2, §15.4 |
| BR-AD-16 | Séparation des identités : une pièce KYC ne sert jamais de photo de profil, photo publique, vignette, portrait, pièce jointe ni ressource ; seau KYC privé et distinct, aucune URL publique. | Le seau KYC n'est lisible que par BR-AD-03 ; aucune autre policy ne le référence. | Sans objet. | Sans objet. | Sans objet. | Sans objet. | Pas encore de port (contrainte de stockage) | DEMO : « Document fictif » | §16.1, §16.2 |
| BR-AD-17 | Déconnexion et perte de capacité : les RPC refusent immédiatement ; URL présignée à durée courte, sans promesse de révocation tant qu'aucun mécanisme serveur n'existe. | Toutes les RPC recontrôlent la session. | Sans objet. | Sans objet. | Sans objet. | Sans objet. | Purge client : `decisionsDossiersProvider` (`decision_dossier.dart:241`), invalidations `file_dossiers.dart:33` ; pas de port serveur | DEMO : purge locale seulement | §16.5 |
| BR-AD-18 | Preuves serveur de §15.4 et §28 : tests exécutés politique active et désactivée, relecteur homme et femme, genre manquant, relecteur ordinaire refusé, Super Admin audité, décision concurrente, rejeu de commande. Tant qu'une preuve manque, le lot reste « NON TERMINÉ » (§28.16). | Sans objet. | Les tests vérifient la trace. | Les tests vérifient l'absence d'état partiel. | Les tests couvrent `stale_dossier` et `already_decided`. | Les tests couvrent les deux états de la politique. | Sans objet | Tests client sur DEMO seulement | §15.4, §28.11, §28.16 |

###### Points ouverts (ce que la spec 03 ne dit pas)

1. **Durée de vie de l'URL de pièce** : la spec demande une expiration, sans chiffre. Le client utilise 60 s aujourd'hui.
2. **Longueur maximale du motif de refus** : exigée par l'écran (Q30), sans valeur dans la spec ni côté serveur.
3. **Contenu exact de la « règle de genre existante »** quand la politique est active : la spec renvoie au comportement serveur réel (aujourd'hui filtre codé en dur dans `read_kyc_documents`), sans le décrire ni dire si elle vise le genre du relecteur, du titulaire, ou les deux.
4. **Audit des refus d'accès** (tentatives `forbidden`) et des lectures de file : la spec n'impose l'audit qu'aux décisions et à la politique.
5. **Périmètre du relecteur** : la spec parle de « périmètre du dossier » sans le définir (pays, langue, rôle, établissement ?).
6. **Signal de changement de politique** : Realtime, version rendue par chaque RPC ou simple relecture ? La spec dit « actualisation des files ouvertes » sans mécanisme.
7. **Durée de conservation** des traces de décision et des motifs : la spec garde la politique existante sans la nommer.
8. **Capacité Super Admin** : la spec ne dit ni comment elle s'attribue, ni qui peut la retirer (Q40 toujours ouverte).
9. **Accès réel après validation d'un enseignant** : quelles conditions restent (accords, profil, autre) pour remplir `access_state` ; la spec renvoie au « contrat existant ».
10. **Révocation immédiate d'une URL présignée** : la spec ne l'exige pas et n'interdit pas d'en construire une.
11. **Genre du tuteur** (question K-47 ci-dessus) : depuis HL-A-6, la politique de genre ne vise plus que les dossiers enseignants ; la spec 03 ne dit rien du tuteur.


### A4. 12_enseignant/EN-BR.md

[Source GitHub figée](https://github.com/rewayahacademy-glitch/Rewayah-Academy-Official-App/blob/708ef8f59bfefae89db071764d3f90a7d6b13322/12_enseignant/EN-BR.md).

#### EN-BR : besoins serveur de la vague Enseignant (étape BR-1)

Sources : spec `04_ENSEIGNANT.md` §26 (contrats de lecture/écriture) et §27
(sécurité), `ENSEIGNANT-2026-09-26.md` (E1 à E20), K-45 (cahier de séance),
lecture de `supabase/` (migrations et fonctions, lecture seule). Aucun code
n'a été modifié pour produire ce document.

**Remarque préalable sur « K-47 ».** Le repère « K-47 (KYC enseignant
seulement) » cité dans la commande n'a été retrouvé ni dans la mémoire du
poste, ni dans `12_enseignant/`, ni dans `UX_REVIEW_04_ENSEIGNANT.md`, ni dans
l'historique du dépôt. Faute de source, ce document ne lui attribue aucun
contenu : il traite le KYC uniquement à partir de la spec (§8, §19, §24) et de
l'existant `supabase/`, et signale ce manque au directeur.

##### Rappel du doc §26 et §27

- §26 attend treize contrats de lecture/écriture enseignant :
  `TeacherBootstrapVM`, `TeacherTodayVM`, `TeacherClassSummaryVM`,
  `TeacherClassHomeVM`, `TeacherStudentProjection`, `TeacherAvailabilityVM`,
  `TeacherClassOpportunityVM`, `reserve_teacher_class`,
  `TeacherAbsenceCommand`, `TeacherReplacementOfferVM`, `LessonCloseoutVM`,
  `TeacherConcernCommand`, `TeacherPublicPhoto`.
- §27 attend : des policies RLS testées (Classe A invisible à un autre
  enseignant, accès du remplaçant borné et temporaire, aucune donnée
  familiale privée dans la projection élève), un jeton LiveKit court et
  permissionné par séance, une séparation stricte photo publique / coffre KYC
  sur R2, et un audit des corrections de présence, absences, remplacements et
  modifications pédagogiques sensibles.

##### Besoin par écran de démonstration

| Écran (fournisseur démo) | Donnée | RPC / table probable | État |
|---|---|---|---|
| Aujourd'hui, Classes (`enseignant_demo.dart`, `ClasseEnseignantDemo`, `SeanceEnseignant`) | Séances et groupes de l'enseignant | `mes_seances_enseignant_v`, `mes_groupes_v` | **Existe déjà**, branché dans `ServiceEnseignantSupabase` (non démo) |
| Fiche groupe, roster (`fiche_groupe_page.dart`) | Membres actifs d'une Classe | `teacher_roster_v`, RPC `mon_groupe_detail` | **Existe déjà** |
| Profil enseignant (`profil_enseignant_page.dart`) | Bootstrap : langues, plafond d'heures, statut KYC | table `teacher_profiles` via `profiles(...)` | **Existe déjà**, lu par `ServiceProfilEnseignantSupabase` |
| Photo publique (`photo_publique.dart`) | Photo distincte du KYC, visible dans les Classes | seau Storage `photos_enseignants` (policies déjà posées : écriture par l'enseignant, lecture par lui, l'académie et les membres de ses groupes) | **Existe déjà**, mais aucun service Flutter réel ne l'écrit encore (câblage BR-1, pas de nouvelle table) |
| Cahier de séance (`cahier/`, `enseignant_demo.dart` → `BrouillonCahier`, `CahierDemo`) | Brouillon préparé par le serveur, dépôt du cahier | RPC `brouillon_cahier`, table `lesson_reports` (insert) | **Existe déjà pour le dépôt simple** ; **à créer** pour K-45 (voir plus bas) |
| Cahiers à terminer (bandeau « À terminer ») | Cahiers en retard | RPC `mes_rapports_en_attente` | **Existe déjà** |
| Disponibilités (`disponibilites_page.dart`, `grille_semaine.dart`) | Grille hebdomadaire de l'enseignant | table `weekly_availability` (déjà lue/écrite côté famille par `ServicePlanning`, jamais côté enseignant) | **À créer** : le câblage Flutter enseignant, pas la table |
| Classes disponibles / opportunité (`OffreClasseDemo`, ENS-06) | Classe proposée, compatibilité, réservation | `TeacherClassOpportunityVM` et `reserve_teacher_class` du doc §26.7/26.8 | **À créer entièrement** : `offres_horaires` / `intentions_horaire` (migration 0043) servent la file élève/famille, pas la candidature d'un enseignant à une Classe |
| Absence et remplacement (`absence_remplacement.dart`, `RemplacementDemo`) | Déclarer une absence sur une occurrence, offre de remplacement, acceptation | `TeacherAbsenceCommand`, `TeacherReplacementOfferVM` du doc §26.9/26.10 | **À créer entièrement** : aucune table « absence » ni « remplacement » dans `supabase/migrations/` ; pas de notion d'occurrence versionnée non plus |
| Signalement (`feuille_signalement.dart`, `TeacherConcernCommand`) | Catégorie, détails internes, résumé partageable | table `student_concern` (RLS déjà posée : insert par l'enseignant du groupe et de la séance, lecture academie/enseignant séparée) | **Existe déjà côté base** ; **à créer** le service Flutter réel (le fichier actuel n'a qu'un modèle et un port, pas d'appel Supabase) |
| Revue de Classe (`revue_groupe_page.dart`, `anomalies_revue.dart`) | Palier à venir, hors corridor, transfert proposé, réorientation proposée | Le code documente lui-même l'écart : `0020` à `0024` calculent ces anomalies, mais leurs policies sont `app_role() = 'admin'` seulement | **À créer** : une RPC bornée à l'enseignant sur ses seuls groupes, aucune nouvelle notion à inventer (la correspondance anomalie ↔ table est déjà actée dans le code) |
| Raccourcis clavier de la salle (EN-KB) | M, V, R, B, Échap | Aucun | **Sans besoin serveur** : réglage local uniquement |

##### K-45, le cahier de séance = séance payée

Le dépôt de cahier existe (`ServiceEnseignantSupabase.deposerCahier`, table
`lesson_reports`), mais seulement comme un insert protégé par une clé
d'idempotence : une ligne, jamais modifiée. Or K-45 exige, pour BR-1 :

- qu'une séance ne soit payée que lorsque son cahier est validé (aujourd'hui,
  rien dans `sessions`, `wallet_entries` ni `payouts` ne relie un paiement à
  la présence ou à l'absence d'un `lesson_reports` validé) ;
- que « où la Classe s'est arrêtée » (position de reprise) soit obligatoire à
  la validation, pour qu'un remplaçant la retrouve ;
- que le cahier reste corrigeable après validation, avec un historique des
  corrections visible seulement de l'académie (la table actuelle n'a ni
  statut « validé », ni mécanisme de correction, ni table d'historique) ;
- que l'enseignant ne soit jamais bloqué par un cahier manquant, seulement
  non payé, avec une notice sur l'espace Paye (l'espace Paye lui-même n'a pas
  encore d'écran ni de source de vérité liée au cahier).

**À créer** : un statut de validation sur `lesson_reports` (ou une table
dérivée), une table de correction/historique réservée à l'académie, et le
lien entre validation du cahier et déclenchement du paiement. Rien de tout
cela n'existe dans les migrations lues.

##### Sécurité et confidentialité (§27)

- RLS : les tests attendus (Classe A invisible à l'enseignant B, accès
  temporaire du remplaçant, aucune donnée familiale dans la projection
  élève) sont **à écrire** ; les policies déjà posées sur `student_concern`
  et sur `photos_enseignants` vont dans ce sens, mais aucune table
  d'occurrence ni de remplacement n'existe encore à tester.
- LiveKit : jeton par séance, court, permissionné - déjà couvert par
  `create-room-token` (fonction Edge existante), à revérifier pour le rôle
  enseignant précisément à l'étape BR-1.
- R2 : la séparation photo publique / KYC est déjà réelle (deux emplacements
  Storage distincts, `kyc_documents` côté coffre, `photos_enseignants` côté
  public).
- Audit : `audit_logs` existe déjà (migration `0009`) ; il reste à y verser
  les événements propres à l'enseignant (correction de cahier, déclaration
  d'absence, acceptation de remplacement) une fois ces mécanismes créés.

##### Résumé en 5 lignes

Le document `EN-BR.md` est écrit à `C:\RA\pilotage\12_enseignant\EN-BR.md`,
sans code ni commit. Beaucoup existe déjà côté serveur pour l'enseignant
(séances, groupes, roster, profil, dépôt simple de cahier, signalement,
disponibilités familiales, photo publique). Trois besoins sont entièrement à
créer : la candidature à une Classe disponible, la déclaration d'absence
et le remplacement, et la revue de Classe côté enseignant. Le cahier de
séance a le plus gros écart avec K-45 : validation liée à la paye, position
de reprise obligatoire, correction avec historique réservé à l'académie
restent à concevoir. Le repère « K-47 » cité dans la commande est introuvable
dans les sources connues et n'a donc reçu aucun contenu inventé.



### A5. 14_controleur/CT-BR.md

[Source GitHub figée](https://github.com/rewayahacademy-glitch/Rewayah-Academy-Official-App/blob/708ef8f59bfefae89db071764d3f90a7d6b13322/14_controleur/CT-BR.md).

#### Vague Contrôleur : besoins serveur (BR-1)

Créé en CT-1b (27/09/2026). Chaque ligne est un besoin que la démonstration simule, à brancher en une fois à BR-1 (K-28). CT-10 complète ce fichier (doc 08 §9 à §11).

| N° | Besoin | Simulé en démonstration par | Étape |
|---|---|---|---|
| BR-CT-01 | Capacité Contrôleur datée et bornée par périmètre ; révocation immédiate. | session `AppRole.controller` fixe (`demo_controleur_page.dart`) | CT-1b, CT-9 |
| BR-CT-02 | Projection multi-rôle pour `Compte > Espaces` (Enseignant-Contrôleur, Admin-Contrôleur) ; propre Classe exclue des missions. | `DonneesControleurDemo.profils` (`classeExclue`) | CT-1b, CT-9 |
| BR-CT-03 | Attribution des missions pendant les séances en direct (pseudo-aléatoire) ; états prévue, en direct, indisponible. | `DonneesControleurDemo.mission(etat)` | CT-1b, CT-2 |
| BR-CT-04 | Faits automatiques de séance (débuts prévu et réel, durée, participants, reconnexions). | `faitsEnDirect`, `faitsSeanceFinie` | CT-1b, CT-4 |
| BR-CT-05 | Roster autorisé de la mission (prénom seul, C8). | `DonneesControleurDemo.roster` | CT-1b, CT-5 |
| BR-CT-06 | Rapports : transmission automatique à la sortie, statuts Envoyé, Complément ajouté, À terminer ; compléments sans modifier le parent. | `DonneesControleurDemo.rapports` | CT-1b, CT-4, CT-7, CT-8 |
| BR-CT-07 | Fils avec l'administration (par mission ou sujet), états Réponse reçue, En attente ; contexte épinglé. | `DonneesControleurDemo.fils` | CT-1b, CT-6 |
| BR-CT-08 | Journal d'audit des visites et des lectures. | rien (aucune écriture) | CT-10 |
| BR-CT-09 | Remplacer la lecture `mes_seances_v` du planning global (`service_controle.dart`) par la lecture des missions. | `planningGlobalProvider` surchargé à vide | CT-2 |
| BR-CT-10 | Transmission automatique de la visite et de ses faits à l'administration dès la sortie de la salle (`EnvoiCompteRendu.transmettreVisite(seanceId)`, idempotent) ; le serveur crée aussi le rapport de visite sur la sortie annoncée (`annoncerSortie`) ou la fin de séance, pour le cas où l'app est fermée avant la réponse ; l'observation humaine rejoint ce même rapport à l'envoi. **CT-RC (revue CT-R B1)** : les deux envois identifient la visite, envoyer(seanceId, choix) et envoyerObservation(seanceId, observation) ; le serveur joint la réponse au rapport de CETTE séance, jamais à celui qu'il jugerait courant, et refuse une séance que ce contrôleur n'a pas observée. | `EnvoiCompteRenduDemo.transmettreVisite` (délai 400 ms, rien ne part) ; port neutre : échec affiché, « Réessayer » | CT-4 |

- **CT-4 (CTR-03)** : brancher `faitsVisiteProvider` (faits §1.1 de la visite, durée de présence réelle du contrôleur) et `envoiCompteRenduProvider` (joint le choix au rapport déjà transmis automatiquement ; lève une erreur sans confirmation serveur) dans `main.dart` ; `compteRenduATerminerProvider` est en mémoire seulement, l'état « À terminer » réel viendra du serveur.
- **CT-5 (CTR-03A)** : BR-CT-11 `EnvoiCompteRendu.envoyerObservation(seanceId, ObservationControle)` (identifiant de séance ajouté par CT-RC) joint l'observation (nature, domaine, personne, identifiant pédagogique de l'élève s'il y a lieu, texte, drapeau « point important ») au rapport de la visite déjà transmis ; le serveur refuse un texte vide pour « Intervention Admin souhaitée » et pour un point important, et un élève hors du roster autorisé. BR-CT-12 `rosterControleProvider` : roster autorisé de la séance observée (identifiant pédagogique + prénom seul, C8), neutre à vide par défaut ; démonstration : `rosterDemoControleur()`.
- **CT-6 (CTR-04)** : BR-CT-13 `portEchangesProvider` (`PortEchanges`, `lib/features/controleur/echanges_controleur.dart`) : `fils()` lit les fils du contrôleur (un par mission seulement en V1, Classe, début de mission, état Réponse reçue / En attente, messages sans prénom d'élève) ; `filDeMission(missionId)` rend le fil canonique de la mission et le crée s'il n'existe pas (contexte Classe, date, heure joint par le serveur, P-CTR-06) ; `envoyer(filId, texte)` se termine sur la confirmation serveur et lève une erreur sinon (l'écran montre « en cours », puis « Envoyé. » ou l'échec avec « Réessayer ») ; seul le contrôleur de la mission et l'administration lisent le fil (aucun participant de la Classe) ; notification de réponse de l'administration à prévoir. Port neutre par défaut : échec, aucun fil inventé ; démonstration : `EchangesDemo` (en mémoire, 400 ms). À brancher dans `main.dart`.
- **CT-7 (CTR-05, CTR-06)** : BR-CT-14 `portHistoriqueProvider` (`PortHistorique`, `lib/features/controleur/historique_controleur.dart`) : `rapports()` lit les rapports du contrôleur (mission, Classe, enseignant d'affichage, début, durée de présence, statut Envoyé / Complément ajouté / À terminer décidé par le serveur, faits §1.1 consolidés, réponse, observation avec le seul prénom de l'élève du roster, compléments avec date, contenu, motif facultatif et auteur : nom d'affichage fixé par le serveur, jamais par l'application, absent quand c'est le contrôleur connecté, affiché « Vous » ; CT-RC-m4) ; seul le contrôleur auteur et l'administration les lisent ; lecture journalisée (BR-CT-08). La reprise d'un rapport « À terminer » doit rouvrir le compte rendu de **sa** mission (aujourd'hui la route du compte rendu lit `missionControleProvider`, donc la mission courante) : prévoir l'identifiant de mission dans la route ou le provider. Port neutre par défaut : échec, aucun rapport inventé ; démonstration : `HistoriqueDemo` (en mémoire, 400 ms). À brancher dans `main.dart`.
- **CT-7, suite (décisions du directeur du 27/09)** : `rapports()` rend aussi la liste des **élèves présents seulement** (prénom et initiale du nom, C7 = a), jamais les absents. Le fil d'une mission sans message est créé par `filDeMission` comme pour CT-6.
- **BR-CT-15 Mission non contrôlée** : si une mission attribuée n'est pas contrôlée (aucune entrée du contrôleur avant la fin de la séance), le serveur envoie automatiquement un rapport à l'administration : « groupe prévu le … à … non contrôlé ». Aucun écran contrôleur ne le déclenche.
- **BR-CT-16 Identifiant élève unique** : un identifiant élève unique et immuable est attribué à l'inscription, pour distinguer les homonymes (roster, observations, présents) ; jamais affiché comme nom.
- **CT-8 (CTR-03B)** : BR-CT-17 `PortHistorique.ajouterComplement(rapportId, texte:, motif:)` (`lib/features/controleur/historique_controleur.dart`) ajoute un complément à un rapport envoyé **sans aucune réécriture** du rapport parent (C10, P-CTR-07) : le client nenvoie

- **CTRL-SALLE-1 (revue du directeur, 02/10)** : BR-CT-18 un seul contrôle à la fois par classe. Côté serveur : un index unique partiel sur les visites de contrôle ouvertes, par séance (par exemple `unique (seance_id) where fin is null`). L'entrée en contrôle (attribution de mission ou émission du jeton de salle `masked_controller`) passe par une RPC qui insère la visite en une seule opération (`insert … on conflict do nothing`, ou verrou sur la séance). Elle refuse le second contrôle avec le code `controle_deja_en_cours`. La mission rendue au client porte l'état `dejaControlee`, pour que CTR-01 n'affiche pas « Commencer le contrôle ». Scénario SQL : deux contrôleurs A et B, même séance en direct. A entre (accepté). B tente au même instant (refusé avec `controle_deja_en_cours`, aucune ligne ajoutée). A quitte (visite fermée). B entre (accepté). S'y ajoute un test de concurrence : deux transactions simultanées laissent exactement une visite ouverte. Client prêt sur `corrections/l2-ctrlsalle` (EtatMissionControle.dejaControlee, message K-59). En démonstration, l'entrée directe par `/demo/controleur/salle` n'applique pas la règle : le vrai refus viendra du serveur.

- **CTRL-BR-OBS-1 (relevé de CT-2, retrouvé par VERIF-CT-1, 04/10)** : **BR-CT-19, BLOQUANT BR-1, À NE PAS OUBLIER.** Inscrire la visite AVANT d'entrer en salle. `ServiceVideo.observerEnControle(seanceId)` (RPC `rejoindre_observation`, `lib/core/video/service_video.dart:58` et `:125`) n'est appelé nulle part dans `lib/` : « Commencer le contrôle », par son chemin par défaut (`controle_page.dart`, `_CarteMission._commencer`), va à `/salle` avec le billet seul. Sans cet appel, le jeton de salle `masked_controller` est refusé en réel et le passage n'est pas journalisé (BR-CT-08). À BR-1 : appeler `observerEnControle` puis, seulement s'il réussit, aller à `/salle` ; un refus (séance close, pas commencée, contrôleur déjà partie prenante, `controle_deja_en_cours` de BR-CT-18) reste sur CTR-01 avec un message K-59, sans entrer. Le commentaire de `service_video.dart:120-123` décrit déjà ce comportement. Test qui fixe l'état actuel : `test/features/controleur/controle_page_test.dart`, « chemin par défaut : /salle avec le billet seul, aucune inscription de visite avant BR-1 (BR-CT-19) », sur `corrections/c1-adm3`. Aucun code ni serveur changé ici (K-28).
- **CTRL-SEANCE-1 (04/10, corrections/c1-ctrl 04acce70) : mise à jour de BR-CT-14.** La route du compte rendu et celle de l'observation ne lisent plus `missionControleProvider` : elles portent la séance dans l'adresse (`?seance=`), et le serveur fournit le `seanceId` de chaque rapport « À terminer ». L'auteur d'un complément est fixé par le serveur : jamais « Vous » par défaut pour un autre auteur, « Administration » quand l'administration écrit (K-53). Le relevé automatique (`faitsVisiteProvider`) et le roster autorisé (`rosterControleProvider`) sont lus par séance (`FutureProvider.family(seanceId)`) : la source réelle se branche par séance dans main.dart et ne renvoie que les faits et les prénoms de cette séance. Aucun serveur avant BR-1 (K-28).
- **CTRL-SON-1 (04/10, décision C5 = a, corrections/c1-salle d208e53e) : BR-CT-20 - couper le son reçu du contrôleur.** Le moteur de salle doit savoir couper et rétablir la lecture des pistes audio reçues sur l'appareil du contrôleur, sans rien publier. Ensuite seulement, remettre dans `salle_page.dart` (`_CommandesControle`) la bascule « Son reçu / Son coupé » ; les clés `salle.visiteControle.sonRecu`, `sonCoupe`, `couperSon`, `retablirSon` sont conservées. Réécrire alors `salle_controleur_test.dart` : toucher, puis vérifier que la piste est coupée dans le moteur, pas seulement que le mot change. Même logique pour « Agrandir le support » (CTRL-AGRANDIR-1, 259d296a) : à remettre quand un support partagé sera rendu dans /salle (clés `agrandir`, `reduire` conservées).



### A6. 14_controleur/BLOQUANTS_ET_IMPACTS.md

[Source GitHub figée](https://github.com/rewayahacademy-glitch/Rewayah-Academy-Official-App/blob/708ef8f59bfefae89db071764d3f90a7d6b13322/14_controleur/BLOQUANTS_ET_IMPACTS.md).

#### Contrôleur : bloquants avant la mise en service et impacts sur les autres rôles

Créé en CT-10 (02/10/2026). Sources : document 08 (`08_CONTROLEUR_V1_UX_SECURITE.md`) §3.4, §12, §13, §15 ; décisions du directeur du 27/09 (`00_DECISIONS_DIRECTEUR.md`, qui priment : C1 la visite a lieu pendant le cours, C2 le rapport part automatiquement à l'administration). Couverture serveur : `CT-BR.md` (BR-CT-01 à 19). Revue UX : `UX_REVIEW_08_CONTROLEUR.md`.

Cadre juridique : l'académie est une LTD anglaise, donc le droit du Royaume-Uni passe d'abord (UK GDPR, Data Protection Act 2018, ICO, Children's Code). Le RGPD européen reste un complément. Rien ici ne tranche un point légal : la démonstration ne fait que simuler (C21).

##### 1. Bloquants avant la mise en service (doc §15)

Le document demande de ne pas les résoudre dans l'écran, mais de les marquer au tableau. Tant qu'ils sont ouverts, le Contrôleur reste une démonstration.

| N° | Bloquant | Pourquoi (règle, loi) | Qui décide | Déjà couvert par |
|---|---|---|---|---|
| B1 | Niveau de connexion exigé pour une observation privilégiée (§15.1). | Un contrôleur voit des élèves et un enseignant : accès à protéger plus fort qu'un compte ordinaire (UK GDPR, sécurité du traitement, art. 32). | Directeur, avec avis juriste ; serveur BR-1 pour l'application. | Rien |
| B2 | Double vérification (MFA / step-up) pour le Contrôleur (§15.2). | Même raison que B1 : compte à privilèges, risque de vol d'accès. | Directeur ; serveur BR-1. | Rien |
| B3 | Procédure exacte de retrait immédiat d'un accès Contrôleur (§15.3). | Un accès à privilèges doit pouvoir être coupé tout de suite (UK GDPR, sécurité). | Directeur (qui, comment, en combien de temps) ; serveur BR-1. | BR-CT-01 (révocation immédiate côté serveur) ; la procédure humaine : rien |
| B4 | Durée exacte de conservation des rapports (§15.4, §14.6). | Principe de limitation de la conservation (UK GDPR art. 5). | Directeur et juriste ; serveur BR-1. | Rien |
| B5 | Base légale du suivi des enseignants (§15.5, §14.3). | Tout traitement de données personnelles exige une base légale ; la surveillance de collaborateurs est encadrée par l'ICO. | Juriste, puis directeur. | Rien |
| B6 | Analyse d'impact sur la protection des données, DPIA (§15.6, §14.2). | Obligatoire avant un traitement à risque élevé, surtout avec des enfants (UK GDPR art. 35, ICO, Children's Code). | Juriste, puis directeur. | Rien |
| B7 | Politique de contestation d'un rapport par l'enseignant (§15.7). | Droits des personnes : accès, rectification, contestation (UK GDPR) ; équité envers l'enseignant. | Directeur et juriste. | Rien (BR-CT-17 ajoute des compléments sans réécrire le rapport, mais ne traite pas la contestation) |
| B8 | Traitement des données sensibles captées par hasard dans la vidéo ou l'audio (§15.8). | Minimisation et catégories particulières de données (UK GDPR art. 5 et 9) ; enfants. | Juriste et directeur ; serveur BR-1. | Rien |
| B9 | Transferts de données hors Royaume-Uni (§15.9, §14.8). | Transferts internationaux encadrés (UK GDPR chap. V, accord de transfert ICO). | Juriste ; directeur pour le choix des hébergeurs ; serveur BR-1. | Rien |
| B10 | Politique de capture d'écran et de filigrane (watermark) (§15.10, §8.4). | Limiter les fuites d'images d'élèves ; le filigrane est seulement proposé au doc §8.4. | Directeur (question 10 de la revue UX). | Rien (non construit en CT-3) |
| B11 | Un brouillon de compte rendu peut-il rester sur l'appareil ? (§15.11, §8.3). | Le document veut « pas de cache durable » : une donnée gardée sur le téléphone est un risque (UK GDPR, sécurité). | Directeur ; serveur BR-1. | En démonstration, le brouillon n'est qu'en mémoire (`compteRenduATerminerProvider`, CT-4) ; la vraie règle : rien |
| B12 | Information légale à donner aux élèves, parents et enseignants (§15.12, §14.1). | Transparence : surveillance non annoncée seulement si justifiée et prévenue à l'avance (ICO) ; Children's Code. | Juriste, puis directeur. | Le bandeau permanent « Cours enregistré, visite de contrôle possible » existe (revue UX, ligne 18) mais n'est pas une preuve de conformité ; le texte légal : rien |
| B13 | Qui peut lire un rapport brut (§15.13). | Accès limité au nécessaire (UK GDPR art. 5, 25). | Directeur et juriste ; serveur BR-1. | BR-CT-14 (seuls le contrôleur auteur et l'administration lisent) ; le cas des autres : rien |
| B14 | Qui peut exporter un rapport (§15.14). | Un export sort la donnée du circuit protégé. | Directeur ; serveur BR-1. | Rien |
| B15 | Qui peut connaître l'identité du Contrôleur après la publication mensuelle (§15.15, §3.4). | Équilibre entre protection du contrôleur et droit de réponse de l'enseignant. | Directeur et juriste. | Rien |

Note : BR-CT-08 (journal d'audit) est prévu côté serveur mais ne répond à aucun de ces points seul ; il aidera pour B3, B13 et B14.

###### 1 bis. Décisions du directeur (02/10/2026, commentaires sur la planche CT)

Le directeur a répondu point par point. Il a confié le reste à l'orchestrateur : « le reste tu te débrouilles pour le bien de l'académie et de ses élèves ». Les choix marqués *orchestrateur* peuvent être repris par lui à tout moment. Ces points ne bloquent plus le Contrôleur : ils sont à appliquer au branchement (BR-1). Seule la DPIA (B6) reste à signer.

| N° | Décision | Ce qu'il faudra faire (BR-1, sauf mention) |
|---|---|---|
| B1 | Pour observer, le contrôleur doit être **connecté et approuvé par l'administration**. | Le serveur refuse l'entrée si la capacité Contrôle n'est pas approuvée (BR-CT-01). |
| B2 | Double vérification à la connexion : **oui**. | MFA pour tout compte qui a la capacité Contrôle. |
| B3 | **Un clic** de l'administration pour donner ou retirer l'accès ; le contrôleur reçoit une **notification** dans les deux cas. | Bouton côté admin (CT-IMP-AD-16) ; notification au contrôleur ; écran « accès retiré » déjà fait (CT-9). |
| B4 | Garder assez longtemps pour revoir et prendre les mesures. *Orchestrateur* : rapport brut **12 mois** après l'envoi, prolongé tant qu'un dossier ou une mesure est ouvert, puis supprimé ; synthèse sans nom d'élève gardée plus longtemps. | Effacement programmé côté serveur. |
| B5 | Les enseignants signent à l'inscription un **contrat qui annonce les visites de contrôle**. *Orchestrateur* : base légale = intérêt légitime (protection des enfants), avec test de mise en balance ; pas le consentement. | Clause au contrat enseignant (charte 09_consentements) ; politique de contrôle publiée. |
| B6 | Le directeur confie la DPIA à l'orchestrateur. | `DPIA_CONTROLEUR.md` (projet) ; signature du directeur ; avis d'un juriste conseillé avant la production. |
| B7 | L'enseignant peut contester, **mais pas trop facilement**. *Orchestrateur* : une demande par rapport, dans les 7 jours suivant la publication de la synthèse mensuelle, avec un motif écrit ; traitée par l'administration ; pas de bouton mis en avant. | Écran dans la vague Enseignant (CT-IMP-EN-02) ; file côté admin. |
| B8 | Les participants savent qu'ils ne sont pas en privé : risque faible. | Le contrôleur n'écrit que ce qui concerne le cours (ligne d'aide « Décrivez seulement ce que vous avez observé » déjà en place). |
| B9 | Aucun élève ni enseignant au Royaume-Uni ; données chez **Cloudflare, Europe de l'Ouest**. | Royaume-Uni vers EEE couvert par l'adéquation britannique ; vérifier les sous-traitants Cloudflare hors EEE (DPA, UK Addendum). |
| B10 | Capture bloquée : **oui**. Le filigrane **n'apparaît que lorsqu'une capture est tentée**, jamais en permanence. | Blocage de capture (Android) et détection (iOS) ; filigrane affiché à la tentative. |
| B11 | Le brouillon **ne sort jamais de l'application**. | Stockage local chiffré, hors sauvegarde et hors partage, effacé après l'envoi. |
| B12 | Élèves, parents et enseignants voient **le minimum possible**. | Bandeau permanent actuel, sans nom ni annonce en temps réel ; rien de plus. |
| B13 | Lecture d'un rapport brut : **l'administration** (et le contrôleur auteur, pour son propre rapport). | BR-CT-14 déjà conforme. |
| B14 | Export : **l'administration seulement**. | Export tracé au journal d'audit (BR-CT-08). |
| B15 | Identité du contrôleur après la synthèse mensuelle : **jamais révélée**. | La synthèse enseignant n'affiche aucun nom de contrôleur. |

###### 1 ter. Bloquant technique du branchement (BR-1)

| N° | Bloquant | Pourquoi | Ce qu'il faudra faire (BR-1) |
|---|---|---|---|
| BR-CT-19 | « Commencer le contrôle » n'inscrit pas la visite : `observerEnControle` (RPC `rejoindre_observation`) n'est appelé nulle part ; le chemin par défaut va à `/salle` avec le billet seul (CTRL-BR-OBS-1, 04/10). | Sans inscription, le jeton de salle du contrôleur est refusé en réel et le passage n'est pas journalisé (BR-CT-08, B3, B13). | Appeler `observerEnControle` avant `/salle` ; n'entrer qu'en cas de succès ; un refus reste sur CTR-01 avec un message K-59. Détail : `CT-BR.md`, BR-CT-19. |

##### 2. Ce que le Contrôleur change pour les autres rôles

###### 2.1 Enseignant (doc §12 et §3.4)

Règle du document : ne pas reconstruire le rôle Enseignant maintenant ; l'ajouter plus tard sous le nom « ENS - Qualité et parcours professionnel ». Le rôle Enseignant a déjà sa vague (EN-0 fait ; reprise par `12_enseignant/00_REPRISE.md`) : rien de ceci n'y est construit.

| Impact | Ce qu'il faudra faire | Vague / étape |
|---|---|---|
| Synthèse mensuelle des observations publiables : éléments positifs, points à suivre (§12). | Un écran enseignant de synthèse, publié à la fin du mois seulement (§3.4). | Vague Enseignant (à faire), puis BR-1 pour les données |
| Réponses et échanges autorisés avec le contrôle (§12). | Définir ce que l'enseignant peut répondre, et à qui. | Vague Enseignant (à faire) ; décision du directeur |
| Historique qualité, badges et responsabilités, éligibilité à certaines promotions (§12). | Écran d'historique qualité ; règles de badges et de promotion à fixer. | Vague Enseignant (à faire) ; décision du directeur |
| Aucune vitesse brute d'apprentissage des élèves comme score de l'enseignant (§12) ; la paie reste un domaine séparé. | Règle à respecter dans tout écran de synthèse. | Vague Enseignant (à faire) |
| Pas de notification immédiate « vous venez d'être observé » ; dates et heures exactes internes à l'administration (§3.4). | Ne jamais envoyer d'alerte à l'enseignant ; ne pas afficher l'heure exacte du contrôle. | Vague Enseignant (à faire) ; serveur BR-1 |

###### 2.2 Administration (doc §13)

Rien à construire maintenant ; à enregistrer au registre de l'Administration finale. Le rôle admin est conçu en dernier (décision F2). Côté serveur, BR-CT-01, 07, 08, 10, 14 préparent une partie des points 1, 6, 8, 9, mais aucun écran admin n'existe.

| N° §13 | Impact | Ce qu'il faudra faire | Vague / étape |
|---|---|---|---|
| 1 | Attribuer et retirer la capacité Contrôleur. | Écran de gestion des droits. | AD-X (rôle admin, conçu en dernier, décision F2) ; BR-1 (BR-CT-01) |
| 2 | Définir le périmètre d'un contrôleur. | Choix des classes ou groupes contrôlables. | AD-X ; BR-1 |
| 3 | Contrôleur externe permanent. | Procédure et compte spécifiques. | AD-X ; décision du directeur |
| 4 | Rotation et couverture des classes. | Vue de ce qui a été contrôlé et de ce qui ne l'a pas été. | AD-X ; BR-1 (BR-CT-03, 15) |
| 5 | Voir les missions réalisées en temps réel. | Tableau de suivi en direct. | AD-X ; BR-1 |
| 6 | File de rapports. | Liste des rapports reçus automatiquement (C2). | AD-X ; BR-1 (BR-CT-10, 14) |
| 7 | Signalements urgents. | Alerte pour « Intervention Admin souhaitée » et points importants. | AD-X ; BR-1 |
| 8 | Canal de discussion avec le Contrôleur. | Côté admin des fils (le contrôleur a déjà son écran Échanges). | AD-X ; BR-1 (BR-CT-07, 13) |
| 9 | Historique immuable. | Journal non modifiable des visites et rapports. | AD-X ; BR-1 (BR-CT-08, 17) |
| 10 | Détecter les contrôleurs qui valident mécaniquement tout. | Indicateurs de qualité des contrôles. | AD-X ; décision du directeur |
| 11 | Calibration entre contrôleurs. | Méthode de comparaison. | AD-X ; décision du directeur |
| 12 | Gestion des conflits d'intérêt. | Règles (ex. propre Classe exclue, déjà simulée par BR-CT-02). | AD-X ; BR-1 |
| 13 | Synthèse mensuelle de l'enseignant. | Validation et publication côté admin. | AD-X, avec la vague Enseignant (à faire) |
| 14 | Publier ou non un signal qualité aux familles. | Décision et réglage. | AD-X ; décision du directeur |
| 15 | Contrôleur ou évaluateur invité. | Compte temporaire borné. | AD-X ; BR-1 |
| 16 | Retrait immédiat d'un accès privilégié. | Bouton et procédure (lié à B3). | AD-X ; BR-1 |
| 17 | Revue périodique des privilèges. | Rappel et liste à revoir. | AD-X ; BR-1 |
| 18 | Accès au journal d'audit séparé de la gestion des droits. | Deux rôles distincts. | AD-X ; BR-1 |

###### 2.3 Tuteur (doc §3.4)

| Impact | Ce qu'il faudra faire | Vague / étape |
|---|---|---|
| Pas de rapport RH brut montré à la famille (§3.4, décision). | Aucun écran tuteur n'affiche un rapport de contrôle. À vérifier à l'harmonisation. | HU-1 |
| Proposition : afficher seulement un signal du type « Suivi qualité Rewayah effectué ce mois-ci », si la Direction juge cela utile (§3.4, non décidé ; recoupe §13 point 14). | Attendre la décision ; si oui, une ligne non sensible dans l'espace Tuteur, alimentée par le serveur. | Décision du directeur, puis HU-1 et BR-1 |

##### 3. Lignes à ajouter au tableau

Format : `ID | titre court | vague | attend (directeur / BR-1 / AD-X / rien) | note`

```
CT-BLQ-01 | Niveau de connexion pour observation privilégiée | Contrôleur (production) | directeur | doc 08 §15.1 ; non couvert ; avis juriste
CT-BLQ-02 | MFA / step-up du Contrôleur | Contrôleur (production) | BR-1 | doc 08 §15.2 ; non couvert
CT-BLQ-03 | Procédure de retrait immédiat d'un accès | Contrôleur (production) | directeur | doc 08 §15.3 ; BR-CT-01 couvre la technique, pas la procédure
CT-BLQ-04 | Durée de conservation des rapports | Contrôleur (production) | directeur | doc 08 §15.4 et §14.6 ; UK GDPR art. 5 ; avis juriste
CT-BLQ-05 | Base légale du suivi des enseignants | Contrôleur (production) | directeur | doc 08 §15.5 et §14.3 ; juriste UK ; ICO
CT-BLQ-06 | DPIA du contrôle | Contrôleur (production) | directeur | doc 08 §15.6 et §14.2 ; obligatoire avant production ; enfants (Children's Code)
CT-BLQ-07 | Contestation d'un rapport par l'enseignant | Contrôleur (production) | directeur | doc 08 §15.7 ; BR-CT-17 ne la traite pas
CT-BLQ-08 | Données sensibles captées par hasard (vidéo, audio) | Contrôleur (production) | directeur | doc 08 §15.8 ; juriste ; serveur BR-1
CT-BLQ-09 | Transferts hors Royaume-Uni | Contrôleur (production) | directeur | doc 08 §15.9 et §14.8 ; juriste ; choix des hébergeurs
CT-BLQ-10 | Capture d'écran et filigrane | Contrôleur (production) | directeur | doc 08 §15.10 et §8.4 ; question 10 de la revue UX ; non construit
CT-BLQ-11 | Brouillon de compte rendu sur l'appareil | Contrôleur (production) | directeur | doc 08 §15.11 et §8.3 ; en démonstration en mémoire seulement
CT-BLQ-12 | Information légale élèves, parents, enseignants | Contrôleur (production) | directeur | doc 08 §15.12 et §14.1 ; le bandeau permanent n'est pas une preuve de conformité
CT-BLQ-13 | Qui lit un rapport brut | Contrôleur (production) | directeur | doc 08 §15.13 ; BR-CT-14 couvre auteur et administration seulement
CT-BLQ-14 | Qui peut exporter un rapport | Contrôleur (production) | directeur | doc 08 §15.14 ; non couvert
CT-BLQ-15 | Identité du Contrôleur après publication mensuelle | Contrôleur (production) | directeur | doc 08 §15.15 et §3.4 ; avis juriste
CT-BLQ-19 | Inscrire la visite (observerEnControle) avant /salle | Contrôleur (production) | BR-1 | BR-CT-19 ; CTRL-BR-OBS-1 ; sans elle, jeton refusé en réel et passage non journalisé
CT-IMP-EN-01 | Synthèse mensuelle de l'enseignant | Enseignant (à faire) | BR-1 | doc 08 §12 et §3.4 ; publication différée en fin de mois ; positifs et points à suivre
CT-IMP-EN-02 | Réponses et échanges autorisés de l'enseignant | Enseignant (à faire) | directeur | doc 08 §12 ; périmètre des réponses à décider
CT-IMP-EN-03 | Historique qualité, badges, promotions | Enseignant (à faire) | directeur | doc 08 §12 ; règles de badge et d'éligibilité à fixer
CT-IMP-EN-04 | Aucune vitesse d'élève comme score d'enseignant | Enseignant (à faire) | rien | doc 08 §12 ; règle à respecter ; la paie reste séparée
CT-IMP-EN-05 | Pas d'alerte immédiate à l'enseignant observé | Enseignant (à faire) | BR-1 | doc 08 §3.4 ; dates et heures exactes internes à l'administration
CT-IMP-AD-01 | Attribuer et retirer la capacité Contrôleur | Admin | AD-X | doc 08 §13.1 ; BR-CT-01 côté serveur
CT-IMP-AD-02 | Définir le périmètre du contrôleur | Admin | AD-X | doc 08 §13.2
CT-IMP-AD-03 | Contrôleur externe permanent | Admin | directeur | doc 08 §13.3 ; puis AD-X
CT-IMP-AD-04 | Rotation et couverture des classes | Admin | AD-X | doc 08 §13.4 ; BR-CT-03 et 15
CT-IMP-AD-05 | Missions réalisées en temps réel | Admin | AD-X | doc 08 §13.5
CT-IMP-AD-06 | File de rapports reçus | Admin | AD-X | doc 08 §13.6 ; transmission automatique (C2) ; BR-CT-10 et 14
CT-IMP-AD-07 | Signalements urgents | Admin | AD-X | doc 08 §13.7
CT-IMP-AD-08 | Canal de discussion avec le Contrôleur (côté admin) | Admin | AD-X | doc 08 §13.8 ; BR-CT-07 et 13
CT-IMP-AD-09 | Historique immuable | Admin | AD-X | doc 08 §13.9 ; BR-CT-08 et 17
CT-IMP-AD-10 | Détection des contrôleurs qui valident tout | Admin | directeur | doc 08 §13.10 ; puis AD-X
CT-IMP-AD-11 | Calibration entre contrôleurs | Admin | directeur | doc 08 §13.11 ; puis AD-X
CT-IMP-AD-12 | Conflits d'intérêt | Admin | AD-X | doc 08 §13.12 ; BR-CT-02 simule l'exclusion de sa propre Classe
CT-IMP-AD-13 | Validation de la synthèse mensuelle enseignant | Admin | AD-X | doc 08 §13.13 ; lié à CT-IMP-EN-01
CT-IMP-AD-14 | Publier ou non un signal qualité aux familles | Admin | directeur | doc 08 §13.14 ; lié à CT-IMP-TU-02
CT-IMP-AD-15 | Contrôleur ou évaluateur invité | Admin | AD-X | doc 08 §13.15
CT-IMP-AD-16 | Retrait immédiat d'un accès privilégié | Admin | AD-X | doc 08 §13.16 ; lié à CT-BLQ-03
CT-IMP-AD-17 | Revue périodique des privilèges | Admin | AD-X | doc 08 §13.17
CT-IMP-AD-18 | Journal d'audit séparé de la gestion des droits | Admin | AD-X | doc 08 §13.18 ; BR-CT-08
CT-IMP-TU-01 | Aucun rapport de contrôle brut côté famille | Tuteur | rien | doc 08 §3.4 ; à vérifier à l'harmonisation HU-1
CT-IMP-TU-02 | Signal « Suivi qualité effectué ce mois-ci » | Tuteur | directeur | doc 08 §3.4 (proposition, non décidée) ; si oui, HU-1 et BR-1
```



### A7. 15_accessibilite/MA-BR.md

[Source GitHub figée](https://github.com/rewayahacademy-glitch/Rewayah-Academy-Official-App/blob/708ef8f59bfefae89db071764d3f90a7d6b13322/15_accessibilite/MA-BR.md).

#### MA-BR : besoins serveur du Mode Accessibilité (à brancher à BR-1)

| Ligne | Besoin | Né de | Écran |
|---|---|---|---|
| MA-BR-1 | Demande de présentation standard d'un élève mineur : le serveur reçoit la demande (`PortDemandePresentation.demanderPresentationStandard`), la transmet au tuteur, qui l'accepte ou la refuse ; l'acceptation change `interface_mode` du profil. Côté élève : états « en cours », « envoyée », « envoi non confirmé » (D5). Page d'acceptation du tuteur : MA-9. | MA-8, décision S7 = b (27/09) | Mon espace (Mariam) |
| MA-BR-2 | Bascule de l'adulte entre Mode Accessibilité et présentation standard : écriture relue de `interface_mode` sur son propre profil, jamais optimiste ; aujourd'hui la bascule n'agit que dans la démonstration. | MA-8, MA24 | Mon espace (Idriss) |
| MA-BR-3 | Salle : reconnexion et réseau coupé réels (état « reconnexion » du direct, bandeau hors ligne branché sur la vraie connexion) ; la démonstration ne peut pas les simuler honnêtement ; aucun faux « en direct ». | MA-12 | Salle (Mariam, Idriss) |

| MA-BR-4 | Brancher les écrans MA en production dans main.dart : remplacer EcranAccessibiliteDemo par la coquille réelle choisie selon InterfaceMode du profil, avec les vrais ports (PortDemandePresentation, préférences, session). | Au branchement BR-1. Preuve : test de routage (mineur et adulte, Mode Accessibilité et standard), captures MA 390/768/1440, suite complète verte. Source : MA-RC-MINEURS (02/10). |



### A8. 16_eleves_adultes/EA-BR.md

[Source GitHub figée](https://github.com/rewayahacademy-glitch/Rewayah-Academy-Official-App/blob/708ef8f59bfefae89db071764d3f90a7d6b13322/16_eleves_adultes/EA-BR.md).

#### Élèves adultes : besoins serveur (BR-1)

Chaque ligne est un besoin repéré pendant la vague. Rien n'est branché avant BR-1 (K-28). Chaque ligne suit le doc §17 : idempotence, audit, tests d'accès horizontal, revue sécurité séparée.

| Réf. | Étape | Besoin | Aujourd'hui en démonstration |
|---|---|---|---|
| EA-BR-01 | EA-1b | Coquille de l'élève adulte : savoir, depuis le serveur, si le compte est un élève adulte, titulaire d'un foyer ou second adulte (sans changer de rôle serveur : le rôle reste lu du jeton). | La démonstration `/demo/adulte` choisit la coquille et la vue (`vue=conjoint`, `titulaire=femme`). |
| EA-BR-02 | EA-1b | Situation du foyer rendue par le serveur (les 25 cas du doc §18), dont la date de fin de délai rendue telle quelle (F17). | `adulte_demo.dart` : états nommés, date fixe du 18 décembre 2026. |
| EA-BR-03 | EA-1b | Enfants du foyer d'un titulaire adulte lus par la même source que le Foyer du tuteur. | `surchargesDemoTuteur(eleves: …)` avec Aïcha et Oumar Diallo. |
| EA-BR-04 | EA-2 | Accueil de l'élève adulte (`accueil_eleve_adulte`) : prénom, Classe (identifiant du groupe), non-lus de notifications, rendus en une lecture pour le compte connecté. | `accueilAdulteProvider` rend `CapaciteIndisponible` ; `DonneesAdulteDemo.accueil` le surcharge. |
| EA-BR-05 | EA-2 | Ligne « Mon parcours » rendue par le serveur (cours, niveau, chapitre en cours), déjà formulée. | `DonneesAdulteDemo.ligneParcours`, composée des données de la Classe An-Nour. |
| EA-BR-06 | EA-2 | Trois dernières séances de la Classe de l'élève, date déjà rendue, plage horaire, absence de l'élève seule (aucune donnée de présence d'un autre élève). | `DonneesAdulteDemo.dernieresSeances()` : trois lundis de septembre, une absence. |
| EA-BR-07 | EA-4 | Mon espace de l'élève adulte (`mon_espace_eleve_adulte`) : l'identité de la personne connectée (prénom, nom, adresse et méthode de connexion, statut du compte) par le port existant `identiteTitulaireProvider` (lot E), et, à part, la ligne famille rendue par le serveur selon la situation (adulte seul, titulaire ou second adulte) avec la clé de la photo de l'élève. | `monEspaceAdulteProvider` rend `CapaciteIndisponible` ; `DonneesAdulteDemo.identite` surcharge `identiteTitulaireProvider`, `DonneesAdulteDemo.monEspace` la ligne famille (aucune photo livrée). |
| EA-BR-08 | EA-4 | « Mes accords » de l'élève adulte (charte 09 §3) : lire, accepter, refuser et retirer chacun de ses accords, pour soi seulement. | Page `RubriqueIndisponibleAdultePage` (état « indisponible », dépendance EA-BR-08) ; rien n'est simulé. |
| EA-BR-09 | EA-4 | « Cours et accès » de l'élève adulte : ses cours, ses séances et l'état de son propre accès, rendus par le serveur. | Page `RubriqueIndisponibleAdultePage` (état « indisponible », dépendance EA-BR-09) ; rien n'est simulé. |
| EA-BR-10 | EA-3 | Ma classe de l'élève adulte (`ma_classe_eleve_adulte`) : Classe (identifiant du groupe) et ligne « À propos de cette classe » déjà rédigée, en une lecture pour le compte connecté. | `maClasseAdulteProvider` rend `CapaciteIndisponible` ; `DonneesAdulteDemo.maClasse` le surcharge. |
| EA-BR-11 | EA-3 | Participants de la Classe vus par un élève : prénom et clé de photo de chaque membre actif, rien d'autre (ni nom de famille, ni niveau, ni présence, ni donnée du foyer), photo soumise à l'accord photo ; tests d'accès horizontal (un élève ne lit que sa propre Classe). | `DonneesAdulteDemo.maClasse` : la personne qui regarde, Mariam et Yusuf, sans photo (initiales). |
| EA-BR-12 | EA-3 | Ligne « Ma progression dans cette classe » rendue par le serveur, déjà rédigée, sans pourcentage ni appréciation (E6, E8). | `DonneesAdulteDemo.ligneProgressionClasse`. |
| EA-BR-13 | EA-3 | Classe propre du second adulte (séance, participants, ressources, progression), jamais celle du titulaire. | Vue `conjoint` : Ma classe et l'Accueil en état indisponible (fournisseur réel), jamais la Classe An-Nour du titulaire (corrigé en EA-5). |
| EA-BR-14 | EA-5 | Ma famille du titulaire (`foyer_titulaire`) : pour le compte connecte, s'il est titulaire d'un foyer, le genre de la place adulte (conjointe ou conjoint, lu de l'inscription, F3), l'etat de cette place tel que le serveur le rend (libre, invitation envoyee, occupee avec le seul prenom du second adulte, validation administrative en attente ou refusee, delai avec sa date de fin rendue, F17, F21) et la cle de photo du titulaire ; rien d'autre sur le second adulte (ni Classe, ni niveau, ni seance, ni photo, F6) ; tests d'acces horizontal (un titulaire ne lit que son foyer). | `foyerTitulaireProvider` rend `CapaciteIndisponible` (le Foyer du tuteur reste inchange) ; `DonneesAdulteDemo.foyerTitulaire` le surcharge, place selon les 25 cas, date fixe du 18 decembre 2026. |
| EA-BR-15 | EA-6 | Invitation du second adulte, côté titulaire (`inviter_conjoint`, `annuler_invitation_conjoint`) : envoi par e-mail (prénom et adresse obligatoires, nom facultatif, Q7, Q8), une seule invitation active par foyer, idempotence par la clé fournie par le client (une nouvelle tentative après coupure ne crée pas de seconde invitation), réponse neutre (partie ou refusée, sans jamais dire si l'adresse a déjà un compte ni quel genre il porte, F4), annulation par le titulaire, invitation expirée ou annulée rendant la place libre sans délai (F5) avec sa fin rendue dans `foyer_titulaire` (EA-BR-14 : `precedente` expirée ou annulée ; invitation envoyée avec le prénom et l'adresse saisis), acceptation tardive d'une invitation annulée ou expirée refusée côté serveur sans aucun rattachement, message reçu portant l'information de l'art. 14 (UX_REVIEW_07 T3) ; audit, tests d'accès horizontal (un titulaire n'envoie ni n'annule que pour son foyer), revue sécurité séparée (doc §17). | `portInvitationConjointProvider` rend `CapaciteIndisponible` (état « indisponible », dépendance EA-BR-15) ; la démonstration le surcharge (`_InvitationDemo` : envoi et annulation réussis, coupure pour « Erreur réseau », latence simulée pour « Double soumission ») ; `DonneesAdulteDemo.invitationEnvoyee` rend Mariama (ou Mamadou) et une adresse fictive @example.com. |
| EA-BR-16 | EA-4c | Paiements du foyer vus par le second adulte rattache (decision E3, spec section 7.1) : l'historique des paiements du foyer rendu aussi au second adulte tant qu'il est rattache, en lecture seule (aucune recharge, aucun moyen de paiement du titulaire, aucune donnee des enfants au-dela du beneficiaire, F6, F7), et plus rien des qu'il ne l'est plus ; la ligne famille de `mon_espace_eleve_adulte` (EA-BR-07) rend `forfait_famille` au seul second adulte rattache, `ma_famille` au seul titulaire ; tests d'acces horizontal (un second adulte detache ou d'un autre foyer ne lit rien). | Sous « Forfait famille », la ligne « Paiements du foyer » ouvre `PaiementsComptePage` dans la coquille de l'eleve adulte (fournisseur reel `paiementsFoyerProvider`, indisponible, DB-CPT-03) ; `DonneesAdulteDemo.ligneFamille` et `ecranPermisDemoAdulte` : jamais le Foyer ni les enfants pour le second adulte. |
| EA-BR-17 | EA-4c | Ligne famille de `mon_espace_eleve_adulte` (EA-BR-07) dans les situations ou le second adulte n'est ni rattache ni libre : aucune ligne pendant la validation administrative, en attente ou refusee (il a deja accepte l'invitation, doc section 10.4) ; apres une reprise validee, la ligne du nouveau titulaire (`ma_famille`, doc section 12.6) ; pour l'adulte invite deja membre d'un autre foyer, refus de l'acceptation avec l'etat neutre de la section 11 (« Ce compte ne peut pas rejoindre ce forfait actuellement »), sans double appartenance, tandis que `foyer_titulaire` (EA-BR-14) rend au titulaire l'invitation envoyee, neutre (F4), sans jamais dire que l'invite est ailleurs ; tests d'acces horizontal. | `DonneesAdulteDemo.ligneFamille` : aucune ligne (`null`) pour le second adulte en validation en attente ou refusee, en reprise validee et deja dans un autre foyer (CHOIX PROVISOIRE, la succession n'est pas modelisee) ; `DonneesAdulteDemo.place` : invitation envoyee pour le cas 21, le titulaire garde « Ma famille » et ses enfants. |
| EA-BR-18 | EA-5c | Nouvelle demande apres un refus de validation (decision E5, doc section 10.3) : `foyer_titulaire` (EA-BR-14) rend la place `validation refusee` sans motif detaille ni compte a rebours ; `inviter_conjoint` (EA-BR-15) accepte alors une nouvelle invitation du titulaire, sans remettre le delai anti-abus a zero ni en relancer un (section 10.3), avec une nouvelle validation de la direction a l'acceptation ; aucun texte rendu au client ne contient le mot admin (K-53.6) ; audit, tests d'acces horizontal (un titulaire ne relance que pour son foyer). | Ma famille, place `ValidationRefusee` : ligne « Validation refusee par la direction » et bouton secondaire « Faire une nouvelle demande », qui ouvre `InviterConjointPage` (`ecranPermisDemoAdulte` le permet) ; l'envoi passe par `_InvitationDemo` (rien n'est envoye). |
| EA-BR-19 | EA-5c | Profil eleve du titulaire (DB-FOY-01) : `foyer_titulaire` (EA-BR-14) rend si le titulaire a deja son propre profil eleve ; tant que ce n'est pas rendu, « Creer mon profil eleve » (garde, planche 2.3 G, decision E6) ouvre la page indisponible existante ; la creation elle-meme reste DB-FOY-01, sans second compte ni profil gere (F2). | `FoyerPage` garde « Creer mon profil eleve » pour le titulaire adulte ; la demonstration ouvre `CreerMonProfilIndisponible` (ecran `creerMonProfil`), retour a Ma famille ; Mamadou, deja eleve de la Classe An-Nour, y lit donc une page indisponible, a ses textes d'adulte depuis la revue EA-5c (`titulaireAdulte` : ni « compte de tuteur », retour « Revenir a Ma famille », libelles provisoires D4). |
| EA-BR-20 | EA-7 | Invitation recue par le second adulte, cote invite (`invitation_recue`, `accepter_invitation_conjoint`, `refuser_invitation_conjoint`) : lecture, pour le compte connecte seulement, de l'invitation qui lui est adressee (prenom du titulaire et son genre pour les accords du texte T1, remplacement soumis a validation, duree de conservation de la trace deja redigee, charte 09 section 8 point 8, Q14) ou de son etat (acceptee, en attente de validation administrative, refusee, expiree ou annulee, compte inéligible ou deja membre ou titulaire d'un autre foyer rendu sous une seule forme neutre sans motif, F4, doc section 11) ; acceptation et refus idempotents par la cle fournie par le client ; acceptation d'une invitation annulee ou expiree refusee sans aucun rattachement (reponse tardive, doc section 5.2) ; aucune fusion de comptes (section 5.1) ; recu date du choix et version du texte T1 (charte 09 section 3) ; notification de l'invitation dans le centre de notifications de l'invite (DB-CPT-04), et reprise de l'invitation apres creation du compte par la connexion existante (section 5.1) ; aucun texte rendu ne contient le mot admin (K-53.6) ; audit, tests d'acces horizontal (un compte ne lit ni ne repond qu'a l'invitation adressee a son adresse), revue securite separee (doc section 17). | `invitationRecueProvider` et `portReponseInvitationProvider` rendent `CapaciteIndisponible` (etat « indisponible », dependance EA-BR-20) ; la demonstration les surcharge pour `vue=conjoint` (`DonneesAdulteDemo.invitationRecue`, `acceptationDe` : rattachement, validation pour `nouvelleDemande`, rien pour `invitationAnnulee`, forme neutre pour `dejaDansUnAutreFoyer`), et la cloche de l'Accueil ouvre `NotificationsPage` avec une seule notification datee du 26 septembre 2026 ; `invitationSansCompte` renvoie vers `/connexion` sans rien lire ; aucune duree de conservation rendue, la phrase est omise. |
| EA-BR-21 | EA-8 | Sortie du forfait famille (`retirer_second_adulte` par le titulaire, `quitter_forfait_famille` par le second adulte) : sans l'accord de l'autre adulte (F14), sans rien supprimer ni transferer (compte, profil, cours, historique, solde, F15), idempotente par la cle fournie par le client (une nouvelle tentative apres coupure ne fait pas deux departs) ; reponse qui rend la fin du rattachement et, pour le titulaire, la date a partir de laquelle une nouvelle demande pourra etre deposee, rendue telle quelle (F17, doc section 10, jamais 60 ou 120 jours calcules dans Flutter) ; `foyer_titulaire` (EA-BR-14) rend ensuite `delai` avec cette date ; notification de l'AUTRE adulte dans son centre de notifications (DB-CPT-04), textes du doc section 9.3 accordes au genre (« {prenom} a quitte votre forfait famille. », « Vous avez ete retiree / retire du forfait famille de {prenom}. »), visible sans push a la prochaine ouverture (F16) ; aucun texte rendu ne contient le mot admin (K-53.6) ; audit, tests d'acces horizontal (un titulaire ne retire que le second adulte de son foyer, un second adulte ne quitte que son propre rattachement), revue securite separee (doc section 17). | `portSortieForfaitProvider` rend `CapaciteIndisponible` (etat « indisponible », dependance EA-BR-21) ; la demonstration le surcharge (`_SortieDemo` : fin du rattachement avec la date fixe du 18 decembre 2026, coupure pour « Erreur reseau », latence simulee pour « Double soumission ») ; `DonneesAdulteDemo.notificationDepart` pose la notification de l'autre adulte (situations « Le second adulte a quitte » vue titulaire, « a ete retire » vue conjoint), datee du 28 septembre 2026 ; rien n'est envoye. |
| EA-BR-22 | EA-8 | Page Forfait famille du second adulte rattache (`forfait_famille`) : pour le compte connecte seulement, le prenom du titulaire du foyer auquel il est rattache, rien d'autre du foyer (ni enfants, ni autre membre, ni moyen de paiement, F6, F7), et plus rien des qu'il n'est plus rattache ; tests d'acces horizontal (un second adulte detache ou d'un autre foyer ne lit rien). | `forfaitFamilleProvider` rend `CapaciteIndisponible` (etat « indisponible », dependance EA-BR-22) ; `DonneesAdulteDemo.forfaitFamille` le surcharge avec Mamadou (ou Mariama). |
| EA-BR-23 | EA-9 | Soldes du foyer vus par le titulaire (`soldes_foyer`) : pour le compte connecte seulement, s'il est titulaire d'un foyer, une ligne par beneficiaire autorise (prenom, cle de photo des enfants, jamais celle du second adulte, Q4), son solde deja redige sans taux ni devise ajoutes par le client (decision E2, Q9), l'exception eventuelle rendue par le serveur (bientot epuise, acces inactif ; aucun seuil cote client, F12), et un recapitulatif du foyer deja redige, jamais une somme a depenser (F9) ; rien d'autre sur le second adulte (ni Classe, ni niveau, ni seance, F6, F10, doc section 7.3), rien au second adulte rattache (il n'a que l'historique, EA-BR-16, E3) ; aucun texte rendu ne contient le mot admin (K-53.6) ; audit, tests d'acces horizontal (un titulaire ne lit que les soldes de son foyer), revue securite separee (doc section 17). | `PortPaiementsFoyer.soldes` rend `CapaciteIndisponible('EA-BR-23')` (section « Soldes pas encore consultables ») ; `DonneesAdulteDemo.soldes` surcharge `soldesFoyerProvider` dans l'espace foyer du titulaire : Mamadou (ou Mariama) « 120 unités », le second adulte rattache « 80 unités » sans photo, Aicha « 15 unités » avec « Bientôt épuisé », Oumar « 0 unité », recapitulatif rendu ; « Recharger » ouvre une page provisoire (EA-10) ; rien n'est paye ni envoye. |
| EA-BR-24 | EA-10 | Offres et verification de la recharge (`beneficiaires_recharge`, `verifier_recharge`) : pour le compte connecte seulement, s'il est titulaire d'un foyer, chaque beneficiaire autorise (prenom, cle de photo des enfants, jamais celle du second adulte, Q4, solde deja redige, E2) avec les offres applicables a lui, chacune deja redigee (ce qu'elle coute, ce qu'elle attribue), sans taux, pack, seuil ni remise calcules par le client (F12) ; puis, pour les choix du titulaire (une offre par beneficiaire, un, plusieurs ou tous, F11), un recapitulatif arrete par le serveur avec son identifiant : une ligne par beneficiaire (qui recoit, montant paye, quantite de solde attribuee, remise seulement si elle s'applique avec son libelle, statut de l'attribution) et le total, tous deja rediges, jamais additionnes dans Flutter ; rien d'autre sur le second adulte (ni Classe, ni niveau, F6, F10), rien au second adulte rattache (E3, F7) ; aucun texte rendu ne contient le mot admin (K-53.6) ; tests d'acces horizontal (un titulaire ne lit et ne verifie que pour les beneficiaires de son foyer), revue securite separee (doc section 17). | `portRechargeFoyerProvider` rend `CapaciteIndisponible('EA-BR-24')` (etat « Recharge pas encore disponible ») ; la demonstration le surcharge (`_RechargeDemo`) : les beneficiaires des soldes d'EA-9 et deux offres de demonstration (« 5,00 € » et « 10,00 € », prix de la planche 4.3) qui attribuent « Solde de démonstration A » et « Solde de démonstration B », sans quantite d'unites ni taux deductible (revue EA-10, 00_MAQUETTES 4.1 C3 et 4.2 C2, E2), aucune remise rendue, statut « En attente du paiement », total fixe d'avance pour chaque combinaison par le serveur de demonstration, jamais additionne (`DonneesAdulteDemo.recapitulatifRecharge`) ; rien n'est envoye. |
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





---

## Addendum de suivi — 10 octobre 2026

Cette copie est publiée pour rendre le blueprint BR-0B V0.2 accessible aux agents du dépôt. Le corps ci-dessus conserve sa date et ses observations d'origine (7 octobre) : ce n'est pas un état live. Pour tout travail, rafraîchir les branches, la CI et Supabase avant de conclure.

### Ordre de priorité et mandat backend

Le mandat MANDAT-I10 demande à Codex de réaliser le backend par lots, d'enregistrer les preuves dans l'onglet Backend et de continuer sur les autres lignes lorsqu'une ligne est bloquée. Les règles plus récentes de `docs/orchestration/COHABITATION.md` fixent les zones de fichiers, le merge de `ccr-1b1bfa0b-m1kvkk` vers `codex/backend-<sujet>` (merge seulement), le journal des changements distants et l'interdiction de `main`. Aucune migration PROD sans GO écrit dans Journal distant.

Les décisions directeur plus récentes ont priorité sur le corps historique de ce blueprint, notamment `docs/current/DECISION-OFFRES-GROUPES-2026-10-09.md` et Questions!OFFRES-DIR-I16 : une demande familiale ne publie jamais d'offre; jour et heure sont requis; toutes les demandes entrent dans une file privée regroupée; créer la classe et intégrer les élèves est atomique; l'affectation de l'enseignant est confirmée séparément; les états familiaux et notifications suivent chaque transition. Toute ancienne proposition incompatible (dont ouverture automatique de l'offre au quota) est remplacée.

### État vérifié au moment de publication

- Branche backend : `codex/backend-lot-f1` @ `f4497ff9b7b3f8f598957857ccdd0f3e0c5d84b6`; synchronisée depuis `ccr-1b1bfa0b-m1kvkk` @ `02dbdcd742b503315005630af7f88228ed07db88` par PR #16. Aucun changement vers `main`.
- La feuille `Rewayah · Liaison Claude ChatGPT` est le registre de travail courant. La ligne LOT-F1 donne les fichiers, preuves, blocages et travaux restants; la feuille prévaut pour leur état courant.
- CI #123 : les tests Edge R2 passent; l'initialisation Postgres échoue avant l'exécution SQL à cause du pull du conteneur. CI #119 exécutait les migrations avec succès, puis le scénario F1 échouait à son assertion ACL. Ne pas affaiblir cette assertion; distinguer ces deux échecs.
- La création de classe C-03 à C-07, l'intégration des demandes d'un regroupement, B-03/B-04, B-07, B-08 et notifications restent à prouver par code et tests; le statut ne devient pas « fait » sur la seule base du document.
- Aucune migration de cette branche n'a été appliquée à STAGING ou PROD lors de cette mise à jour documentaire.

