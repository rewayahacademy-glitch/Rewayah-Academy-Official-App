# Tri des PR ouvertes créées avant le 25/10/2026 (lecture seule)

Agent E, 08/11/2026, à la demande du pilote. **Rien n'a été fermé, poussé ni fusionné** : ce
document propose, le pilote décide (ou le directeur quand c'est marqué DÉCISION).

## Ce qui est faux, bloqué ou non prouvé (d'abord)

1. **Les aperçus de PR parlent probablement à la base de production.** `.github/workflows/flutter-deploy.yml`
   (main `e5d1ee18c`) construit l'aperçu d'une PR avec `secrets.SUPABASE_URL` et
   `secrets.SUPABASE_ANON_KEY`, les mêmes que la production (lignes 111-112 et 151-152), sans clé
   `environment:`. « staging » n'y règle que l'étiquette Sentry (`ENVIRONNEMENT=staging`). Le
   commentaire du robot « staging, aucun effet sur la production » n'est donc vrai que pour le site
   (Vercel), pas pour la base. Je ne peux pas lire la valeur des secrets : c'est **probable, non
   prouvé**. La PR 26 (Codex) corrigeait exactement ce point ; voir sa ligne. `.github/` relève du
   directeur.
2. **Un travail client n'est jamais arrivé dans `main`** (PR 45 et 50) : le traitement groupé des
   candidatures, la synthèse de la file et la confirmation du nom en lettres latines. Le serveur
   correspondant est dans `main` (et en production) ; les écrans, non. Voir leur ligne.
3. **Méthode.** La copie locale était superficielle (« shallow ») : les bases communes étaient
   introuvables, d'où un premier relevé faux, jeté. L'historique complet a été rapatrié
   (`git fetch --unshallow`), puis chaque PR comparée à `main` `e5d1ee18c` : commits absents de
   `main` (`git rev-list`, `git cherry`), fichiers touchés depuis la base commune, présence et
   contenu de chacun dans `main`, migrations absentes de `main`. Le relevé brut est reproductible
   par ces mêmes commandes.
4. **INVENTAIRE-NON-BRANCHE-2026-10-31** recense du code **présent dans `main`** et non branché ;
   aucune de ces PR n'y figure. Les seuls modules de l'inventaire qu'on retrouve ici (`tc_dock`,
   `tc_flux_academique`, `tc_parcours/port_post_cours`) sont des copies anciennes, dans la branche
   de la PR 45, de modules que `main` a **supprimés** depuis, sur décision (PR 204, `fccd2f6b8`,
   M1-SUPPR, 03/11). Fermer la PR 45 ne les ferait donc pas perdre.

## Synthèse

| Proposition | PR |
| --- | --- |
| FERMER, déjà dans `main` (tête de la branche ancêtre de `main`) | 35, 37, 38, 39, 41, 43, 44 |
| FERMER, remplacée ou rendue caduque par `main` | 1, 5, 7, 8, 10, 13, 17, 20, 21, 23, 24, 25, 27, 28, 29, 30, 31, 32, 34 ; 50 (doublon de 45) |
| FERMER après une vérification nommée | 22 |
| REPRENDRE | 45 (écrans client des candidatures) |
| DÉCISION | 26 (directeur, `.github`), 40 (pilote), 42 (directeur) |

## Une ligne par PR

Légende : « absent » = fichier de la PR qui n'existe pas dans `main` ; « migrations » = fichiers
`supabase/migrations/*.sql` de la PR absents de `main` sous ce nom.

| PR | Titre | Ce qu'elle fait | `main` contient ou rend caduc ? (preuve) | Proposition | Migrations |
| --- | --- | --- | --- | --- | --- |
| 1 | Refonte UI Lavender & Pastel (Google/Apple Design) | Refonte visuelle par Jules (09/09) d'une base antérieure | Caduc : branche sans base commune avec `main` ; le système visuel actuel est `docs/current/03_DESIGN_SYSTEM_ET_UX.md` et DESIGN-GOV-2026-09-26 | FERMER | aucune absente |
| 5 | Étapes B et C du plan directeur : rapport de la répétition de fusion et verifier_revue | Rapport d'essai de fusion du 27/09 et premier `verifier_revue` | `tool/verifier_revue.dart` est dans `main` ; seul `RAPPORT_ESSAI_FUSION.md` (rapport historique) est absent | FERMER (rapport à archiver si le pilote veut la trace) | aucune |
| 7 | ci(D2) : contrôler aussi les PR vers ui/** | Lance la CI sur les PR vers `ui/**` | Fait : `.github/workflows/ci.yml` de `main` contient déjà `ui/**` (2 occurrences) | FERMER | aucune |
| 8 | feat(site): preview site public français Rewayah | Premier aperçu du site public `/fr/` | Remplacé : `site-public/` est dans `main` (PR 44 fusionnée, tête `231d69ffe` ancêtre de `main`) | FERMER | aucune |
| 10 | Lot C — séparer l'identité agent du profil observé | Scénario TDD SEC-01 (identité de l'agent) | Remplacé : `0057_agent_identity_subject.sql` dans `main` depuis `adb1c857f` (11/10) ; `supabase/functions/agent-session` signe `sub` = identifiant opaque du jeton | FERMER | `20261009180731_agent_identity_subject.sql` (remplacée par 0057) |
| 13 | Lot F1 — vertical backend foyer, classes et séances | Intégration F1 vers `ccr` | Remplacé : 0050 à 0056 dans `main` (`adb1c857f`) ; adaptateurs sous d'autres chemins (`lib/core/capacites/profil_eleve_titulaire_supabase.dart`, `lib/core/offres/demandes_suivi_supabase.dart`) | FERMER | aucune absente |
| 17 | Backend — F2, support et raccordements complémentaires | F2 : notifications, support, signalement, état partagé, assignations | Remplacé : 0059 à 0063 dans `main` (`adb1c857f`), mêmes objets renumérotés | FERMER | 0055 à 0061 sous leurs anciens numéros (remplacées par 0058 à 0063) |
| 20 | Lot C — garder l'identité agent distincte du profil observé | SEC-01 avec 0057 | Remplacé : 0057 dans `main` (`adb1c857f`) | FERMER | aucune absente |
| 21 | F2 — corrections et raccordements backend | F2 après le lot C, vers `ccr` | Remplacé : migrations F2 dans `main` ; écrans d'invitations, regroupements et historique d'observation présents sous d'autres chemins (`features/connexion/invitation_foyer_ouverte.dart`, `core/offres/regroupements_c11bis_supabase.dart`, `features/admin_observations/observations_admin_page.dart`) | FERMER | aucune absente |
| 22 | SEC-PROD — snapshot exact et candidat non validé | Relevé de sécurité de la production au 10/10 et SQL de correction **jamais validé ni appliqué** | Non prouvé point par point : les corrections de sécurité sont arrivées par d'autres chemins (vagues L1 de l'audit, PR 39, ancêtre de `main`) | FERMER, après que le garde-cap a vérifié qu'aucun point de `docs/backend/SEC_PROD_REMEDIATION.sql` ne reste ouvert | aucune |
| 23 | B-13 — refuser l'historique aux admins suspendus | Policy `guardian_visit_admin` sur compte valide | Fait : `0058_guardian_visit_admin_account_valid.sql` dans `main` (`adb1c857f`) | FERMER | `0049_guardian_visit_admin_active_account.sql` (remplacée par 0058) |
| 24 | docs: publier les sources BR-0B et leur état courant | Documents de passation Codex (plans BR-0B) | Caduc : documents historiques, absents de `main` | FERMER (à archiver si besoin) | aucune |
| 25 | docs: réconcilier le ledger migrations lot A au 2026-10-10 | Rapport de réconciliation des migrations au 10/10 | Caduc : état daté, dépassé par le registre du garde-cap | FERMER | aucune |
| 26 | fix(ci): isoler les aperçus Flutter sur Supabase STAGING | Aperçus construits avec les secrets `STAGING_SUPABASE_*` | **Pas dans `main`** : voir le point 1 ci-dessus. La branche vise l'ancien `flutter-deploy.yml` (vers `ccr`) et n'est pas applicable telle quelle | DÉCISION (directeur, `.github`) : les aperçus de PR doivent-ils utiliser une base de STAGING plutôt que la production ? | aucune |
| 27 | fix(security): intégrer B-13 après F1 et l'identité agent | Portage de B-13 | Fait : 0058 dans `main` | FERMER | aucune absente |
| 28 | fix(security): B-20 identity agent opaque et validation du compte | SEC-01 avec validation du compte observé | Fait : 0057 et `agent_pre_request` exigent un compte actif (`0014_acces_agent.sql`) et un accès non expiré (`20261121800000_hygiene_agent_acces_expire.sql`, en production depuis le 08/11) | FERMER | `0074_agent_identity_account_validity.sql` (0074 dans `main` est un autre fichier : `0074_positive_guards_all_definers.sql`) |
| 29 | feat(backend): F1 foyer, profils titulaires et offres sur ccr actuel | F1 réancré | Remplacé, comme 13 | FERMER | aucune absente |
| 30 | fix(security): B-20 identity agent opaque et validation du compte | Doublon de 28 réancré | Comme 28 | FERMER | `0074_agent_identity_account_validity.sql` |
| 31 | B-13 — compte admin actif uniquement (réancré sur ccr courant) | Doublon de 27 réancré | Comme 23 | FERMER | aucune absente |
| 32 | docs(backend): prove one PROD 0011 migration body match | Preuve de correspondance d'une migration de production | Caduc : preuve datée du 10/10 | FERMER | aucune |
| 34 | docs(orchestration): passation de fin de Codex (13/10) | Passation après la fin de Codex | Caduc : remplacée par `docs/orchestration/PASSATION-2026-10-17.md` (dans `main`) | FERMER | aucune |
| 35 | docs(pedagogie): compétence programme-rewayah… | Compétence programme et sources du directeur | Fait : tête `f6e3973fb` ancêtre de `main` | FERMER | aucune |
| 37 | Reprise du back-end après Codex… | Intégration back-end du 16/10 | Fait : tête `0df3e9fab` ancêtre de `main` | FERMER | aucune |
| 38 | docs(audit): analyse ultime du 16/10/2026… | Audit final | Fait : tête `4fd273946` ancêtre de `main` | FERMER | aucune |
| 39 | Corrections de l'audit final, nuit du 16 au 17/10 | Vagues de correction de l'audit | Fait : tête `9a1d50a9c` ancêtre de `main` | FERMER | aucune |
| 40 | Simulation économique : 216 scénarios… | Outil de simulation des prix, hors application (38 fichiers sous `tool/simulation/`) | Absent de `main` ; les tarifs sont fixés par DECISION-TARIFS-2026-10-18 | DÉCISION (pilote, question d'outillage, aucune règle d'argent) : garder l'outil dans le dépôt ou le fermer ? | aucune |
| 41 | Passation du 17/10… | Passation et lots du 17/10 | Fait : tête `dbe6b4441` ancêtre de `main` | FERMER | aucune |
| 42 | Skills motion design (Emil Kowalski, LottieFiles) et taste-skill | 18 compétences tierces sous `.claude/skills/` (104 fichiers, licences MIT) | Absent de `main` : `main` n'a que `marque-rewayah`, `mots-rewayah`, `programme-rewayah` | DÉCISION (directeur) : ces 18 compétences tierces entrent-elles dans le dépôt, donc dans toutes les sessions ? | aucune |
| 43 | Marque (manifeste, cahier visuel, registre) et paie des enseignants à 47 % | Marque et décision de paie du 19/10 | Fait : tête `dc26cccd9` ancêtre de `main` | FERMER | aucune |
| 44 | Site public : direction en arche… | Refonte du site public | Fait : tête `231d69ffe` ancêtre de `main` | FERMER | aucune |
| 45 | CANDIDATURES : décisions du directeur, spécification, socle serveur… | Module des candidatures, serveur et écrans | **En partie seulement** : le serveur est dans `main` (`20261022000100_cand_l2a2_gestes_direction.sql` avec `apercu_lot_candidats` et `executer_lot_candidats`, `20261024000000_cand_nom_latin.sql`, `20261024010000_cand_prevenir_par_courriel.sql`), l'écran « Prévenir par e-mail » aussi (`prevenir_candidats.dart`), et CAND-04 est passé par `7392ef60f` (06/11). **Jamais entrés dans `main`** : `features/admin_candidatures/lot_candidatures.dart` (913 lignes, traitement groupé), `synthese_candidatures.dart` (synthèse de la file), `features/candidature/nom_latin_etape.dart` (confirmation du nom latin) et `core/candidature/modeles_lot_candidatures.dart`, avec leurs tests. Aucun écran de `main` n'appelle `apercu_lot_candidats` ni `executer_lot_candidats` | REPRENDRE : un lot par écran, sur `main`, en réutilisant ces fichiers (serveur déjà en production, sans écran). Ensuite seulement, fermer la PR | aucune absente |
| 50 | Claude/lucid mccarthy qpk6yq | Même branche et même tête que la 45 (`0acc35bd0`), sans description | Doublon de 45 | FERMER (doublon ; la 45 garde le suivi) | aucune |
</content>
</invoke>
