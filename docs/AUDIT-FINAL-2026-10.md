# Audit final de conformité, de sécurité, de simplicité et de finition - octobre 2026

- Date : 16/10/2026.
- Auditeur : session Claude Code (Fable), lecture seule. Aucun code, aucune migration, aucune configuration n'a été modifié. Rien n'a été écrit sur STAGING ni sur la production.
- Code audité : branche `claude/backend-reprise`, SHA `0df3e9fa` (PR 37 vers `ccr-1b1bfa0b-m1kvkk`).
- Base auditée : STAGING `xldmmlrnxyabdtvxqbyy` (PostgreSQL 17.11), en lecture seule, migrations appliquées jusqu'à `20261016102300`, soit exactement la branche.
- Préversion auditée : `rewayah-academy-jsmnhsct2-rewayahacademy-3863s-projects.vercel.app`, compilée contre STAGING (le bundle contient l'URL de STAGING et `ENVIRONNEMENT=staging`), déployée par CLI le 16/10 vers 14 h 40 UTC, sans SHA Git attaché : on ne peut pas prouver qu'elle correspond à `0df3e9fa`.
- Ce que je n'ai pas pu faire : me connecter avec les comptes de test (mot de passe non fourni). Les écrans connectés ont été vus en mode démonstration (`?demo=tuteur`, `?demo=admin`, `/demo/*`), jamais avec de vraies données. La chaîne LiveKit n'a pas été essayée.
- Annexes : `docs/audit-final/MATRICE-CONFORMITE.md` (133 exigences, une ligne chacune), `docs/audit-final/MESURES-2026-10-16.md` (commandes et chiffres), `docs/audit-final/captures/` (49 captures de la préversion), `docs/audit-final/lots/` (fiches de correction et `INDEX.md`).

Conventions du rapport : « DM » désigne le document maître du 14/10 (version 1.1 avec addenda), avec le numéro de sa section ; « REGISTRE » désigne `REGISTRE-RECONCILIATION-2026-10-14.md` (branche `claude/keen-ritchie-kdmnfc`, PR 35) ; « AUDIT-ETAT » désigne `docs/AUDIT-ETAT-2026-10-16.md`. Les identifiants `AUD-xxx` sont ceux de l'audit d'harmonisation du 14/10.

---

## 1. En une page

### Où en est l'application

L'application est un produit avancé, cohérent dans son code Flutter, raccordé à un serveur réel sur STAGING pour la plus grande partie des parcours décidés en octobre : regroupement des demandes et création de classe, classes parallèles, fusion et transfert, pilotage, tirage des contrôles, remplacements, bibliothèque, état partagé de la salle, messages et annonces, suivi « livraison » des demandes. 49 adaptateurs sont branchés dans `lib/main.dart`. Les 199 migrations se rejouent de zéro sur un PostgreSQL 17 neuf sans erreur. Les 109 tables ont la RLS. Les 313 fonctions SECURITY DEFINER fixent `search_path = ''`. L'analyseur Dart est propre. Les 1 436 tests de `test/core` et les 1 478 tests de `test/teaching_core` sont verts.

Trois choses empêchent d'inviter une vraie famille :

1. **Le serveur laisse passer des choses qu'il ne devrait pas.** Tout compte connecté peut forger des événements de présence (`record_session_event`). Un enfant connecté peut lire le portefeuille, les paiements et les versements de son foyer, voir les séances de sa fratrie, lire le cahier brut de son enseignant et s'autoriser lui-même la caméra. Ces faits sont confirmés sur la base STAGING, pas seulement dans le code.
2. **Des promesses faites au directeur n'ont pas d'écran ou pas de serveur.** Pas d'écran pour publier une offre vitrine, donc la vitrine réelle est vide. Pas d'écran de matricule, pas d'accueil des inscrits actuels, pas de simulateur de tarif, pas de site public sur cette branche, pas de recharge, pas de paie, pas de MFA pour le contrôleur. Les cohortes et plusieurs réglages en base contredisent les décisions du 29/09 au 14/10.
3. **Les garde-fous ne tournent pas sur la branche de travail.** La CI ne rejoue que 15 scénarios SQL sur 74 ; le scénario des remplacements est rouge sur une base neuve. Le job Flutter de la CI est ignoré sur la PR 37 (il ne tourne que vers `main`), ce qui a laissé passer 18 violations de jetons et un dépassement du socle de revue.

### Les chiffres

| Mesure | Résultat |
|---|---|
| Exigences atomiques relevées | 133 |
| Conformes (preuve fichier et test ou essai) | 43 |
| Partielles | 47 |
| Absentes | 19 |
| Contraires à la demande | 20 |
| Non vérifiables (mot de passe des comptes de test, compte LiveKit, secret du workflow) | 3 |
| Failles de sécurité retenues | P0 : 2, P1 : 7, P2 : 6, P3 : 5 |
| Écarts de l'audit du 14/10 (oublis, erreurs, changements de statut) | 9 oublis, 4 jugements à corriger, 14 statuts changés |
| Lots de correction | 32 lots de code et 4 de vérification croisée, en quatre vagues ; 5 conditionnels à un arbitrage ; 23 exécutables par un Haiku (`docs/audit-final/lots/INDEX.md`) |

### Les dix décisions qui attendent le directeur (détail en section 7)

1. A-01 Enregistrement audio : retirer des contrats et des accords la phrase « chaque cours est enregistré en audio », tant qu'aucune captation n'existe.
2. A-02 MFA du contrôleur : activer le TOTP et exiger `aal2` pour observer une séance.
3. A-03 Un seul nom : « Interface guidée » (document maître) ou « Mode Accessibilité » (code et tableau).
4. A-04 Navigation enseignant : trois destinations (document maître) ou quatre (K-43 et code).
5. A-05 Seconde salle `/tc/classe` : la débrancher maintenant.
6. A-06 Matching individuel (prendre un élève, attribution 1-à-1) : retirer les derniers chemins vivants.
7. A-07 Inscription enseignant : fermer l'inscription sans code d'invitation.
8. A-08 Site public et tarifs : intégrer la PR 8 dans la branche de référence et créer la politique tarifaire côté serveur.
9. A-09 Observation du tuteur : ouvrir le drapeau de compilation en staging, après la vague de sécurité.
10. A-10 CI : liste blanche des deux empreintes de test, scénarios SQL tous rejoués, job Flutter sur les PR vers la branche de référence (fichiers `.github/`, hors de portée des agents).

---

## 2. Matrice de conformité

Le détail, ligne par ligne, avec écran, backend, raccordement, états, preuve et statut, est dans `docs/audit-final/MATRICE-CONFORMITE.md`. Cette section en donne la lecture par rôle puis par domaine, et nomme ce qui compte.

### 2.1 Par rôle

| Rôle | Exigences | Conformes | Partielles | Absentes | Contraires | Non vérifiables |
|---|---:|---:|---:|---:|---:|---:|
| Tuteur et foyer (T) | 25 | 7 | 11 | 5 | 1 | 0 |
| Élève enfant (E) | 10 | 4 | 2 | 0 | 4 | 0 |
| Élève adulte (A) | 6 | 2 | 2 | 1 | 0 | 1 |
| Enseignant (N) | 12 | 4 | 5 | 1 | 2 | 0 |
| Contrôleur (C) | 7 | 4 | 1 | 2 | 0 | 0 |
| Comptable et finance (F) | 10 | 1 | 5 | 3 | 1 | 0 |
| Administration et direction (D) | 22 | 8 | 5 | 3 | 6 | 0 |

**Tuteur.** Ce qui marche : la coquille à quatre destinations, le suivi « livraison » des demandes, les notifications d'étape, l'invitation du second adulte, l'appairage des appareils, la demande de créneau refusée sans jour ni heure. Ce qui manque : l'écran de matricule (T-21), l'accueil des inscrits actuels (T-22), la recharge (T-07), la pause d'un mois (T-24), « Rattraper le cours » (T-25). Ce qui est contraire : la photo de l'élève n'est lisible que par son foyer, alors que K-44 la destine à l'enseignant et aux camarades (T-17, policy Storage `avatar_lecture_foyer`). Ce qui est fermé à tort : l'observation d'une séance, prête côté serveur (2 visites de 120 s, quota et jeton bornés sur STAGING), mais verrouillée dans l'écran par un drapeau de compilation vrai seulement en développement (T-05).

**Élève enfant.** L'accueil, l'entrée en classe, le Coran et la connexion par code sont conformes dans le code. Mais quatre exigences de protection de l'enfant sont contredites par le serveur, et c'est là que l'application n'est pas prête : finances du foyer lisibles (E-02), séances de la fratrie visibles (E-03), caméra et interface modifiables par l'enfant (E-04), cahier brut de l'enseignant lisible (E-09).

**Élève adulte.** Le profil autonome sans faux enfant est conforme et testé (A-02). La capacité « élève autonome » est servie par le serveur et lue par le routeur (A-03) ; le tableau de suivi garde encore `EA-ROLE-BR` à faire, à tort. Le solde personnel n'existe pas (A-05).

**Enseignant.** Journée, bouton d'entrée qui change de sens, profil, contrat versionné, photo publique : conformes. Le cahier est présent mais sa file hors ligne n'est jamais rejouée (N-04). Un remplaçant qui a pris une séance n'obtient pas de jeton vidéo (N-06) et le scénario SQL des remplacements est rouge sur base neuve. L'ancien chemin « prendre un élève » (1-à-1) est encore exécutable (N-02). Rien n'existe côté enseignant pour les évaluations (N-08).

**Contrôleur.** Tirage au sort des missions, observation incognito, rapports et échanges : conformes et testés. Absents : la MFA (C-03) et les délais de conservation et de contestation (C-07). Partiel : le contrôleur lit tout le journal d'audit et les cahiers bruts sans mission (C-05).

**Comptable et finance.** L'argent est en entiers (F-01). Tout le reste est écran sans serveur ou serveur sans écran : ledger modifiable (F-02), espace Comptable sur ports « indisponible » sauf les séries de trésorerie (F-03), aucune politique tarifaire (F-04), aucun simulateur (F-05), aucun paiement (F-06).

**Administration.** Le cœur d'octobre est là et testé : regroupements et « Créer la classe » (D-05), proposition d'enseignant (D-06), classes parallèles (D-07), fusion et transfert (D-08), pilotage (D-09), tirage (D-12), bibliothèque (D-13). Contraires : la décision de dossier KYC sans garde d'état (D-02), l'aperçu de pièce qui contourne la porte serveur et échoue (D-03), le retrait d'élève qui ne coupe pas ses séances (D-10), les cohortes 5-7 / 8-10 / 11-14 / 15-17 au lieu de 6-9 / 10-13 / 14-17 (D-16), l'âge minimum 3 au lieu de 6 (D-17), le minimum d'ouverture 3 au lieu de 4 (D-18). Absents : l'écran des offres vitrines (D-04), l'import des inscriptions (D-15), le calendrier des fermetures (D-20).

### 2.2 Par domaine transverse

| Domaine | Exigences | Conformes | Partielles | Absentes | Contraires | Non vérifiables |
|---|---:|---:|---:|---:|---:|---:|
| Salle, bibliothèque, Teaching Core (S) | 12 | 4 | 5 | 0 | 2 | 1 |
| Communications, recherche, notifications (R) | 4 | 1 | 3 | 0 | 0 | 0 |
| Site public (W) | 4 | 1 | 1 | 2 | 0 | 0 |
| Identité, sessions, habilitations (I) | 8 | 4 | 3 | 0 | 1 | 0 |
| Intégration, CI, exploitation (X) | 13 | 3 | 4 | 2 | 3 | 1 |

**Salle.** Deux salles restent montées dans le routeur : `/salle` et `/tc/classe`, cette dernière atteinte depuis `/tc/groupes` par tout rôle autre qu'élève (S-01). La fenêtre T-20 et les 15 minutes de grâce sont des réglages serveur lus par les fonctions (S-03). La présence est forgeable par tout compte (S-04). La salle ne dit plus « Cours enregistré », mais le contrat et les accords annoncent encore un enregistrement audio (S-05).

**Communications et recherche.** Messages et annonces sont raccordés (R-02), avec un test Dart rouge et une annonce en double. La recherche a son serveur complet (cinq lots `rech_back`, quota, version d'autorisation) mais aucun adaptateur branché : l'écran tourne sur sa démonstration (R-01).

**Site public.** Rien sur cette branche ; la PR 8 vers `main` n'est pas intégrée (W-01). Les pages légales de suppression de compte et d'export n'existent pas (W-03).

**Identité.** Les colonnes privilégiées de `profiles` sont gardées en exigence positive (I-01). Le genre, qui commande le cloisonnement KYC, reste modifiable par chacun (I-02). 50 policies par rôle ne vérifient pas que le compte est valide (D-21).

**Intégration.** Migrations rejouables (X-01). 15 scénarios sur 74 en CI, 73 verts sur 74 en local, un rouge (X-02). Le stub CI ne reproduit pas les privilèges par défaut de Supabase (X-03). `deploy.yml` déploie en production sans dépendance de tests (X-05). Le job Flutter de la CI n'a pas tourné sur la PR 37 (X-06), et deux régressions des garde-fous sont passées : 18 violations de jetons (X-08) et un socle de revue dépassé sur deux règles (X-09).

### 2.3 Exigences conformes à préserver (ne pas réécrire)

Socle Flutter (routeur unique, gardes par préfixe, composants partagés, analyseur propre) ; RLS et `search_path` partout ; gardes positives des RPC ; jeton d'agent opaque ; appairage et connexion enfant ; classes parallèles, fusion, transfert, pilotage ; regroupements et création de classe ; tirage des contrôles ; bibliothèque CAP29 ; état partagé de la salle ; pause de séance ; messages et annonces ; suivi « livraison » ; contrat enseignant versionné ; présentation publique avant connexion.

---

## 3. Écarts entre l'audit du 14/10 et la réalité

L'audit du 14/10 a travaillé sur `main` (SHA `4a7aa2b`), pas sur la branche de travail ; l'AUDIT-ETAT du 16/10 a relu 31 lignes sur la branche. J'ai contrôlé les deux sur STAGING et sur le code.

### 3.1 Exigences oubliées par l'audit du 14/10

| Oubli | Source de l'exigence | Constat du 16/10 |
|---|---|---|
| Photo de l'élève lisible par l'enseignant et les camarades | K-44 (26/09) | Contraire : policy Storage `avatar_lecture_foyer` limitée au foyer (T-17) |
| Observation du tuteur fermée par un drapeau de compilation | G03 6.4 | L'audit a jugé la porte serveur ; il n'a pas vu `Env.observationTuteurReelleSelon` qui ferme l'écran hors développement (T-05) |
| Matricule RA affiché et accueil des inscrits actuels | DECISION-IMMATRICULATION (12/10) | Absents côté écran, serveur présent (T-21, T-22, D-15) |
| Cohortes, âge minimum, minimum d'ouverture, pause | REGISTRE sections 2 et 3 | Contraires sur STAGING (D-16 à D-18) |
| Le contrôleur lit tout le journal d'audit | DM 15.2 (aucun accès indu) | `audit_logs_read` : admin et contrôleur, sans mission (C-05) |
| Lecture directe des fichiers de supports | DM 1.4 (contrôle à chaque délivrance) | Policy Storage `supports_lecture` ouverte à tout compte connecté (S-09) |
| `materialiser_seances` et `log_sensitive_access` exécutables par tout compte | DM 3.3, 14.4 | Confirmé sur STAGING (P1-2, P1-3) |
| Stratégie d'URL par fragment | DM 17.5 (liens entre routes sans boucle) | Toute adresse devient `#/...` (X-13) |
| Scénario `scenarios_b09_remplacements.sql` rouge sur base neuve | CLAUDE.md « un contrôle qui n'a jamais tourné » | Échec ligne 106, contrainte `sessions_no_teacher_overlap` (X-02) |

### 3.2 Jugements de l'audit du 14/10 à corriger

| Référence | Ce que l'audit disait | Ce qui est vrai le 16/10 |
|---|---|---|
| AUD-IDS-040 / SRC-036 / TAB-051 | Le contrôleur lit les pièces KYC (P0) | Fermé sur STAGING : `read_kyc_documents` admin seul, Storage `kyc_client_read_block`. L'AUDIT-ETAT l'avait déjà passé en CORRIGÉ ; je le confirme sur la base |
| AUD-IDS-019 | Jeton sans rôle écrit `role` et `account_status` (critique) | Fermé : trigger `guard_profile_privileged_columns` en garde positive, vu sur STAGING. Reste `gender` (nouvelle faille P1-5) |
| AUD-SAL-084 | Le tuteur entre par `assister_seance` sans quota | Faux sur la branche : le tuteur passe par `entrer_observation` avec quota ; mais l'écran est fermé par le drapeau (T-05). L'audit a manqué l'autre moitié du problème |
| AUD-OFR-030 | Pas de regroupement ni de « Créer la classe » | Branché et testé (D-05) |

### 3.3 Statuts qui ont changé depuis le 14/10

| Référence | 14/10 | 16/10 (ce rapport) | Preuve |
|---|---|---|---|
| AUD-IDS-016 (`record_session_event`) | CONTRADICTOIRE | toujours ouvert, confirmé sur STAGING | `has_function_privilege('authenticated', ...) = true`, corps sans garde |
| AUD-TAB-050 (`decider_dossier`) | ABSENT | toujours ouvert, confirmé sur STAGING | définition relue : `WHERE id = p_document_id` sans état |
| ALR-ELV-01/02, AUD-ELV-075 | CONTRADICTOIRE | toujours ouvert, confirmé sur STAGING | policies relues |
| AUD-FIN-004 (`wallet_entries`) | ABSENT | toujours ouvert | triggers relus : aucun d'immuabilité |
| AUD-COM-008 (MFA) | ABSENT | toujours absent | `config.toml:310-312` |
| AUD-FIN-072 (gardes négatives) | CONTRADICTOIRE | CORRIGÉ | 0067, 0074, 0084 ; `b18` en CI |
| AUD-OFR-066 / ELV-077 (groupes fictifs servis aux familles) | PRÉSENT NON RACCORDÉ | CORRIGÉ | `port_groupes.dart:39-49` : double seulement si `PLAYGROUND` |
| AUD-SAL-090 (« Cours enregistré ») | CONTRADICTOIRE | PARTIEL | salle corrigée ; contrat et accords non |
| AUD-ENS-023 (`rejouer`) | ABSENT | toujours absent | 0 appelant dans `lib/` |
| AUD-SYS-004 (enseignant effectif) | CONTRADICTOIRE | toujours ouvert | `autoriser_jeton_video` ignore `remplacements_seance` |
| AUD-SYS-005 (retrait d'élève) | ABSENT | PARTIEL | transfert coupe, retrait simple non |
| AUD-GTE-002 (migrations divergentes) | CONTRADICTOIRE | CORRIGÉ en local, non vérifiable en PROD | 199 migrations rejouées ; STAGING au même niveau |
| MES E2 (scénarios etape3, ctr01, agt01 rouges) | rouges | verts | 15 PASS en suite CI locale |
| CI stub `storage` | manquant | CORRIGÉ | `stub_auth.sql:30-44` |

---

## 4. Sécurité, du P0 au P3

Méthode : droits lus sur STAGING (`pg_policies`, `pg_proc`, `has_function_privilege`, `information_schema.column_privileges`, `storage.objects`), fonctions relues par `pg_get_functiondef`, jamais le code seul. Pour chaque P0, j'ai cherché à réfuter la faille avant de la retenir.

Rôles considérés : direction, administrateur, enseignant, tuteur, élève mineur, élève adulte, contrôleur, comptable, jeton sans rôle, compte suspendu, agent IA (`agent_ro`).

### 4.1 P0

**P0-1. Tout compte connecté forge la présence.**

- Exposition : n'importe quel compte (élève compris) appelle `select record_session_event('<séance>', '<profil>', 'joined', 'livekit_webhook')` par PostgREST et écrit une présence, un départ, un enregistrement. La présence commande l'absence, la paie de l'enseignant (K-45) et les corrections de la direction.
- Preuve STAGING : `has_function_privilege('authenticated', 'public.record_session_event(uuid,uuid,session_event_type,text)', 'EXECUTE') = true` ; corps de la fonction : `insert into public.session_events ...` sans aucune garde, SECURITY DEFINER.
- Réfutation tentée : la RLS de `session_events` n'arrête rien (la fonction est DEFINER, propriété de `postgres`) ; aucune policy d'INSERT n'est nécessaire ; aucune version d'autorisation n'est lue ; la migration `0048_revoke_public_volatile_function_execute.sql` rend EXECUTE à `authenticated` pour toute fonction qu'il exécutait avant. La faille tient.
- Correctif : `revoke execute on function public.record_session_event(uuid,uuid,session_event_type,text) from authenticated, anon, public;` et garder `service_role`. Même traitement pour `log_sensitive_access` et `materialiser_seances` (P1-2, P1-3). Test de refus : un scénario SQL qui, sous `authenticated`, attend `42501`, et un contrôle de liste blanche des fonctions volatiles exécutables. Lot L1-01.

**P0-2. Un jeton élève lit les finances du foyer, les séances de sa fratrie, le cahier brut, et change sa caméra.**

- Exposition : un enfant connecté (jeton `role = student`, `household_id` posé par `custom_access_token_hook`) lit par PostgREST `wallets`, `wallet_entries`, `payout_methods`, `payouts` de son foyer ; lit `mes_seances_v` pour toute sa fratrie ; lit `lesson_reports` et `makharij_findings` (notes internes de l'enseignant) de toute séance de son foyer ; écrit `student_profiles.camera_policy = 'allowed'` et `interface_mode` pour lui-même ou un frère.
- Preuve STAGING : `wallets_family_read` : `(household_id = app_household_id()) AND app_account_valid()` ; `wallet_entries_family_read`, `payout_methods_family_read`, `payouts_family_read` : même forme ; `student_profiles_family_update` : foyer sans rôle, grant UPDATE sur `interface_mode`, `camera_policy`, `avatar_storage_key`, `cohorte`, `langue_cours`, `niveau_declare`, `objectif`, `onboarding_fait_le` ; `mes_seances_v` : `eleve.household_id = app_household_id()` sans rôle ; `lesson_reports_reader` : `session_in_household(session_id, app_household_id()) OR session_has_participant(session_id, auth.uid())`.
- Réfutation tentée : le hook de jeton pourrait ne pas poser `household_id` pour un élève ; relu : il le pose pour tout profil. L'écran de l'enfant n'affiche pas ces données ; mais le doc maître (28.1, 02 règle 3) exige la policy, pas l'interface. La faille tient.
- Correctif : ajouter `app_role() = 'guardian'` (ou la capacité titulaire) dans `using` et `with check` des cinq policies de foyer ; retirer `interface_mode` et `camera_policy` du grant par colonnes pour les laisser à une RPC tuteur ; réécrire `mes_seances_v` avec une clause par rôle ; réduire `lesson_reports_reader` et `makharij_findings_read` à l'auteur, à l'administration et au contrôleur en mission, la famille lisant `seance_resumes`. Tests de refus : un scénario par table avec un jeton élève. Lots L1-02, L1-03, L1-04.

### 4.2 P1

| Réf. | Faille | Exposition | Preuve STAGING | Correctif et test | Lot |
|---|---|---|---|---|---|
| P1-1 | `decider_dossier` accepte une seconde décision et un rejet ne retire pas l'accès | Administration seulement ; un dossier approuvé puis rejeté garde un compte actif ; deux administrateurs peuvent se contredire sans le voir | définition : `UPDATE public.kyc_documents SET status = ... WHERE id = p_document_id` ; `UPDATE profiles SET account_status='active' ... WHERE account_status='pending_kyc'` seulement si approuvé | garde `status = 'pending'` (sinon `already_decided`), version attendue, `account_status = 'disabled'` au rejet d'un compte actif ; scénario de double décision | L1-05 |
| P1-2 | `log_sensitive_access` exécutable par tout compte | Insertion d'une ligne signée dans la chaîne d'audit (hash valide), donc un faux « kyc_decision » ou « video_token_issued » | `auth_exec = true`, SECURITY DEFINER ; seuls deux appelants INVOKER légitimes (`auditer_regle_remuneration_enseignant`, `x217_valider_politique_coffres`) | revoke à `authenticated` ; les deux appelants INVOKER deviennent DEFINER ou appellent une fonction privée | L1-01 |
| P1-3 | `materialiser_seances` exécutable par tout compte | Création de séances et de participants pour toute affectation 1-à-1 ouverte (horizon 4 semaines) | `auth_exec = true`, corps sans garde ; appelée en interne par `attribuer_eleve` et `prendre_eleve` (DEFINER, donc le revoke ne les casse pas) | revoke à `authenticated` | L1-01 |
| P1-4 | Ledger `wallet_entries` modifiable et supprimable par administrateur et comptable | Un montant encaissé peut être réécrit ou effacé par REST sans trace | `wallet_entries_admin_accountant_all` FOR ALL ; grant UPDATE, DELETE ; triggers : seul `x217_guard_confirmation_source` | trigger `guard_wallet_entries_immutable` sur UPDATE et DELETE (modèle `guard_audit_logs_immutable`), revoke UPDATE et DELETE ; corrections par écriture inverse | L1-06 |
| P1-5 | `profiles.gender` modifiable par son titulaire | Le genre du lecteur commande quelles pièces KYC un administrateur voit (0088) ; un administrateur ou un enseignant change son genre par REST | `profiles_self_update` : `id = auth.uid()` ; la garde ne cite pas `gender` | ajouter `old.gender is distinct from new.gender` à `guard_profile_privileged_columns` ; scénario de refus | L1-07 |
| P1-6 | 50 policies par rôle sans `app_account_valid()` | Un administrateur, comptable ou contrôleur suspendu garde ses droits REST pendant la vie de son jeton (une heure) : `profiles_admin_all`, `sessions_admin_all`, `wallet_entries_admin_accountant_all`, `audit_logs_read`, `verset_admin`, etc. | liste des 50 relevée (annexe MESURES) | réécrire chaque `using`/`with check` en `coalesce(app_role() = '...' and app_account_valid(), false)` ; scénario « admin suspendu » sur les tables | L1-08 |
| P1-7 | Le stub CI ne reproduit pas les privilèges par défaut de Supabase ; `deploy.yml` déploie en production sans dépendance de tests ; le job Flutter ne tourne pas sur la PR de référence | Une faille comme P0-1 est invisible en CI ; un push sur `main` déploie sans test | `stub_auth.sql` ; `deploy.yml:31-33, :74, :107` ; `ci.yml` job `flutter` : `if: github.base_ref == 'main'` ; check runs PR 37 | stub avec `ALTER DEFAULT PRIVILEGES ... GRANT EXECUTE ON FUNCTIONS TO authenticated, anon` et test de liste blanche ; `needs` dans `deploy.yml` ; `base_ref` élargi | L1-09 (stub et liste blanche) ; `.github` : arbitrage A-10 |

### 4.3 P2

| Réf. | Faille | Preuve | Correctif | Lot |
|---|---|---|---|---|
| P2-1 | Le contrôleur lit tout le journal d'audit (payloads des décisions KYC, jetons vidéo, profils créés) et les cahiers bruts de toutes les séances, sans mission | `audit_logs_read` : `app_role() in ('admin','controller')` ; `lesson_reports_reader` : `app_role() = 'controller'` | limiter le contrôleur à ses propres actions et aux séances de ses missions | L1-03 (cahier), L1-08 (journal) |
| P2-2 | Un remplaçant n'obtient pas de jeton vidéo ; le retrait simple d'un élève ne coupe pas ses séances | `autoriser_jeton_video` ne lit que `session_participants` et `sessions.teacher_id` ; `retirer_eleve_groupe` ne touche que `groupe_membres` | lire `private.c29_enseignant_effectif_session` dans le jeton ; supprimer logiquement les `session_participants` à venir au retrait | L2-01 |
| P2-3 | Tout compte connecté lit tout fichier du seau `supports` dont le dossier est une ressource existante, en contournant les droits par version | Storage `supports_lecture` : `exists (select 1 from library_resource r where r.id::text = foldername[1])` | restreindre à `autoriser_lecture_version` ou passer par la fonction Edge `bibliotheque-lecture` seule | L2-09 |
| P2-4 | Aperçu KYC côté client par `createSignedUrl` : la porte tracée n'est pas utilisée et l'aperçu échoue pour l'administration | `service_validation.dart:221-223` ; `kyc_client_read_block` | appeler `piece-identite-acces` | L2-02 |
| P2-5 | Les RPC de l'ancien matching (`prendre_eleve` pour tout enseignant, `attribuer_eleve`) restent vivantes et contredisent la décision « classes précréées » | définitions STAGING, `service_matching.dart:212` | après A-06 : revoke et retrait des appelants | arbitrage A-06 |
| P2-6 | Aperçu de PR et production compilés avec le même nom de secret `SUPABASE_URL` | `flutter-deploy.yml:128` ; valeur non lisible | un secret d'environnement `staging` distinct ; preuve par `grep` du bundle, comme la préversion du jour | arbitrage A-10 |

### 4.4 P3

| Réf. | Faille ou hygiène | Preuve | Correctif |
|---|---|---|---|
| P3-1 | Grants de table à `anon` sans policy `anon` (`jetons_agent`, `verset`, `mushaf`, `video_token_grants`, `session_video_route`, `livekit_webhook_deliveries`, `session_presence_override`, 4 vues) ; extension `btree_gist` installée dans `public` (177 fonctions exécutables par `anon`) | grants STAGING | revoke all de `anon` sur ces tables ; déplacer l'extension dans `extensions` (migration à part, hors urgence) |
| P3-2 | `kyc_guardian_insert` subsiste alors que le tuteur ne dépose plus de pièce (K-47) ; le compte tuteur naît encore `pending_kyc` | policy et `creer_profil_inscription` STAGING | retirer la policy ; créer le tuteur `provisional_active` (décision K-47 déjà prise) |
| P3-3 | `photos_enseignants_ecriture` : tout compte connecté écrit dans son propre dossier du seau des photos d'enseignants | policy STAGING | exiger `app_role() = 'teacher'` |
| P3-4 | `lesson_reports_teacher_write` déclarée pour le rôle `{public}` (inoffensif : `anon` n'a aucun grant sur la table) | policy STAGING | redéclarer `to authenticated` |
| P3-5 | TTL des jetons vidéo à 900 s ; le doc maître dit « expiration courte » sans chiffre | `video_config.token_ttl_seconds = 900` | réglage, décision d'exploitation |

### 4.5 Ce qui est sain et vérifié sur STAGING

Pièces KYC : lecture administration seule, cloisonnement de genre, journalisation ; Storage `kyc` fermé au client. Jeton d'agent opaque et en lecture seule. Observation : quotas et jeton borné (`guardian_observer` sans publication, masqué, TTL au reste). Contrôleur masqué sans publication. Notifications au seul destinataire. Signatures de contrat immuables. Journal d'audit immuable (triggers), sauf la forge décrite en P1-2. Colonnes privilégiées de `profiles` gardées. Gardes positives dans les RPC. Aucune fonction DEFINER sans `search_path`.

---

## 5. Doublons, code mort et sur-ingénierie

### 5.1 Doublons

| Doublon | Fichiers | Qui l'utilise | Lequel garder et pourquoi |
|---|---|---|---|
| Deux salles | `/salle` : `lib/features/salle/salle_page.dart` (4 146 lignes avec `salle_seance`, 16 434 lignes) ; `/tc/classe` : `lib/features/tc_classe_live/` (3 012 lignes), monté par `routesTcE()` (`app_router.dart:1923`) | `/salle` : Journée, accueil élève, contrôleur, fiche de groupe (6 appelants) ; `/tc/classe` : `tc_mes_groupes/routes_tc_a.dart:43,58` pour tout rôle autre qu'élève sur `/tc/groupes` | Garder `/salle` (décision 08 du 23/09 : chemin vivant). Débrancher la route `/tc/classe` et faire pointer `_rejoindre` sur `preparerSalleEleve`, sans supprimer les fichiers D/F/H tant que leurs capacités utiles ne sont pas reprises (arbitrage A-05) |
| Deux fichiers de jetons de mouvement | `lib/core/theme/app_mouvement.dart` (17 importateurs) et `lib/core/mouvement/mouvement.dart` (15 importateurs, 5 durées et 3 courbes littérales, signalées par `verifier_jetons`) | les deux | Garder `app_mouvement.dart` (source des jetons gelés, DESIGN-GOV contrat E) ; `mouvement.dart` ne doit plus porter de valeur, seulement réexporter |
| Trois sources pour « qui enseigne cette séance » | `sessions.teacher_id`, `session_participants(role='teacher')` (écrit par `materialiser_seances` 1-à-1 seulement), `remplacements_seance` lu par `private.c29_enseignant_effectif_session` | le jeton vidéo lit les deux premières, la mission de contrôle lit la troisième | Une seule fonction d'enseignant effectif (celle de C-29), lue par le jeton, la présence et la paie |
| Matching individuel contre classes précréées | `lib/core/matching/` (539 lignes), `features/creneaux` (1 587), `features/disponibilites` (410), `features/admin_attribution` (901) ; RPC `prendre_eleve`, `attribuer_eleve`, `materialiser_seances`, `eleves_sans_enseignant`, `teacher_student_assignments` | `admin_traitement`, `admin_demandes`, `/admin/operations/attributions` | Garder les disponibilités (utiles aux exceptions) ; retirer le chemin 1-à-1 du parcours courant (00, contradictions résolues). Arbitrage A-06 car des écrans demandés sont concernés |
| RPC qui font la même chose | `creer_groupe` (2 surcharges), `modifier_groupe` (2 surcharges), `affecter_enseignant_classe` et `affecter_enseignant_classe_c11bis`, `publier_groupe_depuis_offre` et `creer_classe_depuis_regroupement` | `service_groupes.dart` (surcharges), `regroupements_c11bis_supabase.dart` (c11bis) | Garder la signature longue de `creer_groupe` et `modifier_groupe` (fuseau et couleur), `affecter_enseignant_classe_c11bis` (verrou par enseignant), `creer_classe_depuis_regroupement` (idempotent). Lot L3-06 |
| Migrations qui redéfinissent la même fonction | `read_kyc_documents` et `modifier_groupe` : 6 fois ; `etat_presence`, `creer_groupe` : 6 ; `dossiers_en_attente`, `creer_profil_enfant`, `autoriser_jeton_video` : 5 ; 23 autres fonctions 3 fois ou plus (liste en annexe MESURES) | historique | Ne rien réécrire : c'est l'histoire. Règle pour la suite : toute correction d'une fonction crée une migration qui la redéfinit entièrement, et le scénario qui la couvre entre en CI |
| Libellés en double | 454 textes français identiques portés par 1 113 clés (`notifications` 8 fois, `bibliothèque` 7, `{date} à {heure}` 7, « il est possible que la demande ne soit pas parvenue » 7, `non renseigné` 6, `{minutes} min` 6, `page {page} sur {total}` 5, « un motif est requis » 5, « disponible au branchement serveur » 5) | tous les écrans | Garder une clé `commun.*` pour les formats et les états génériques seulement (K-41 : une clé = un sens, donc pas de fusion aveugle). Lot L3-05 |
| Deux espaces de démonstration | `features/demo` (27 932 lignes, compilées dans le bundle, gardées à l'exécution par `environnementAutoriseDemo`) et `features/_dev` (7 185 lignes, derrière `GALERIE` et `PLAYGROUND` constants, donc élaguées) | développement et préversion | Garder ; mesurer le poids de `features/demo` dans `main.dart.js` (13,8 Mo non compressé pour la préversion) avant de décider une importation différée |

### 5.2 Code mort

| Élément | Preuve | Action |
|---|---|---|
| `ServiceVideo.assisterEnTuteur` et la RPC `assister_seance` | `service_video.dart:131` : aucun appelant hors démonstration ; `0041:226` retire EXECUTE | supprimer la méthode et l'implémentation de démonstration (L3-04) |
| `lib/core/offres/demandes_horaires_supabase.dart` | adaptateur jamais importé (recherche sur les 48 adaptateurs : le seul orphelin) | supprimer (L3-04) |
| `DepotCahiers.rejouer()` | défini, appelé seulement par deux tests | le brancher (L2-03), ce n'est pas du code mort mais une promesse non tenue |
| `estCertificationReussie` | `lib/core/admin/service_evaluations.dart:180`, décision du 12/10 : un résultat n'est pas un certificat | retirer ou renommer (L3-04) |
| `Env.observationTuteurReelle` forcé à faux hors développement | `env.dart`, `observationTuteurReelleSelon` | lever après la vague 1 (A-09, L2-06) |
| `recording_retention_days = 30` en `app_config` ; `session_recordings`, `autoriser_ecoute_archive`, `geler_archive_seance`, Edge `archive-seance-acces` | aucun Egress ne démarre | laisser dormir jusqu'à l'arbitrage A-01 ; ne pas montrer |
| Routes déclarées sans page : `/tuteur/parcours` sans identifiant d'élève donne « Cette page est introuvable » en démonstration | capture `tuteur_tuteur_parcours_390_light.png` ; `app_router.dart:921` n'accepte que `/tuteur/parcours/:eleveId` | la constante `Routes.tuteurParcours` seule ne doit pas servir de destination (L4-05) |

### 5.3 Complexité sans valeur pour l'utilisateur

- 110 ports pour 48 adaptateurs : 62 ports vivent avec un double de démonstration ou un état « indisponible ». Le modèle est bon (K-09), mais les ports de la finance (`port_mes_finances`, `port_validations_finance`, `port_delegation_finance`), de la recherche et des vocaux portent des écrans complets sans serveur. C'est de l'écran d'avance, pas de la sur-ingénierie, à condition de ne pas l'étendre avant le raccordement.
- `features/demo` : 27 932 lignes, soit 7,5 % du code, livrées dans tout bundle. Les lanceurs de démonstration (index de scénarios) sont utiles au directeur sur la préversion. Décision : les garder, mais mesurer.
- Trois notions de capacité de classe : `app_config.groupe.capacite_enfant`, `groupes.seuil_max`, `max_participants_per_session = 7`. La valeur effective est bien celle de la classe (R2), mais `max_participants_per_session` ne sert qu'à l'ancien 1-à-1.
- Deux notions de fenêtre d'après-cours : `grace_after_end_minutes = 15` (séance) et `rejoindre_observation` qui code `interval '15 minutes'` en dur. Même valeur, deux endroits.

### 5.4 Friction : nombre de gestes par parcours clé (sur la préversion, démonstration)

| Parcours | Gestes | Observation |
|---|---:|---|
| Se connecter (adulte) | 3 (adresse, mot de passe de démonstration, « Recevoir le lien ») puis ouverture du courriel | Le libellé du bouton (« Recevoir le lien ») et celui du champ (« Mot de passe de démonstration ») se contredisent : avec un mot de passe, le bouton connecte sans lien (commit `faed9a41`). Un tuteur réel ne sait pas lequel des deux chemins il prend. Lot L4-01 |
| Se connecter (enfant) | 2 (code, « Connecter l'appareil ») ou 1 (scanner) | Bon |
| Rejoindre une séance (élève) | 2 (accueil, « Rejoindre » puis préparation silencieuse) | Bon, un seul emplacement d'entrée (K-40) |
| Remplir le cahier | 1 écran, pastilles préremplies, 5 boutons d'action dans `cahier_page.dart` | Le temps cible de 45 s n'est pas mesuré ; aucun compteur dans les tests |
| Inscrire un enfant | 2 étapes (« Pour qui », puis le formulaire) | Bon ; l'option « Moi-même » inerte en démonstration contredit la règle « jamais grisé » |
| Lire le Coran | 1 (destination `Coran` de la barre) | Bon |
| Publier une offre (administration) | impossible | Aucun écran |
| Décider d'un dossier KYC | 3 (sélection, « Voir la pièce », décision) | « Voir la pièce » échoue avec la policy actuelle (D-03) |

---

## 6. Design et friction, écran par écran

Règles appliquées : DESIGN-GOV-2026-09-26 (contrats A à E), `lib/CLAUDE.md`, K-54 à K-59, K-42 (air, un seul bouton plein), K-55 (cartes). Le style, les couleurs, le logo, les polices et les bento grids ne sont pas en cause : ils sont tenus partout où je les ai vus. Captures dans `docs/audit-final/captures/`, nommées `<écran>_<largeur>_<thème>.png`. Mode sombre, arabe de droite à gauche et texte agrandi : vus sur la préversion pour le sombre et l'arabe ; le texte agrandi n'a pas été produit sur la préversion (il l'est par les tests de capture du dépôt à 320 px et texte ×2, verts dans `test/core`).

### 6.1 Entrée (bienvenue, connexion)

- `bienvenue_390_light.png`, `bienvenue_1440_dark.png` : présentation en cinq écrans, hiérarchie claire, un seul bouton (flèche), lien « Essayer la démonstration ». Conforme.
- `connexion_390_light.png`, `connexion_390_dark.png`, `connexion_1440_light.png` : carte unique, un seul bouton plein. Défauts : (1) la phrase « Nous vous envoyons un lien par courriel. Aucun mot de passe à retenir » est suivie d'un champ « Mot de passe de démonstration » ; (2) le bouton dit « Recevoir le lien » alors qu'il connecte quand le mot de passe est rempli ; (3) en arabe (`connexion_390ar_light.png`), « Essayer la démonstration » reste en français. Lot L4-01.
- `connexion_eleve_390_light.png` : titre sur deux lignes à 390 (« Connecter cet appareil »), aide « Chiffres de 2 à 9 et lettres, sans I ni O », lien « Scanner le QR code », bouton collé en bas. Conforme à K-56.

### 6.2 Tuteur (démonstration)

- Accueil (`tuteur_tuteur_390_light.png`, `tuteur_tuteur_1440_light.png`) : avatars des enfants en tête, carte « Vos demandes de créneau », alerte d'appareil, carte de Classe. Défauts : (1) la liste des demandes nomme Inès et Bilal, qui ne sont pas dans le foyer de démonstration (Aïcha, Yusuf) ; données de démonstration incohérentes (K-28 demande des données réalistes) ; (2) à 390 l'alerte d'appareil est une carte jaune avec un bouton plein, à 1440 c'est un texte nu avec un bouton plein : deux rendus pour le même bloc ; (3) deux boutons pleins visibles sur le même écran à 390 (« Connecter un appareil » et, plus bas, l'entrée de Classe) ; (4) « Avant le prochain cours : le travail à préparer n'est pas encore relié à cet espace » alors que `portTravailAVenirProvider` est branché dans `main.dart` : phrase de démonstration à retirer quand le réel est vu. Lot L4-05.
- Foyer (`tuteur_tuteur_foyer_390_light.png`, `tuteur_tuteur_foyer_1440_dark.png`) : bandeau de couleur de profil derrière l'avatar (K-62) présent, cartes espacées (K-55), un seul bouton plein « Ajouter un profil élève ». Défaut : « Accès jusqu'au 31 décembre 2099 » (donnée de démonstration non réaliste). Conforme sinon.
- Historique (`tuteur_tuteur_suivi_390_light.png`) : état vide propre (« Aucune séance passée »), sélecteur de section à deux segments. Conforme.
- Compte (`tuteur_tuteur_compte_390_light.png`) : première carte « Pas encore disponible. Cette fonction n'est pas encore ouverte » sans dire laquelle : contraire à K-59 (ce qui manque, la cause, l'action). Lot L4-02. Le reste (cartes groupées à lignes fines) est conforme.
- Suivi des demandes (`tuteur_tuteur_demandes_390_light.png`) : une carte par demande, « Étape en cours », lien « Voir le suivi ». Conforme ; le titre « Suivi des demandes » passe sur deux lignes à 390 avec la flèche de retour à gauche, ce qui est le gabarit `PageParcours` déjà noté en dette HU-1.
- Ajouter un profil (`tuteur_tuteur_foyer_ajouter_390_light.png`) : deux cartes de choix expliquées (K-58), étape « 1 sur 2 », bouton « Suivant » en bas. Défaut : « Moi-même : Indisponible » affiché inerte. Lot L4-05.
- Recharge, Messages (`tuteur_tuteur_foyer_recharge_390_light.png`, `tuteur_tuteur_messages_1440_light.png`) : états « pas encore disponible » honnêtes.
- Arabe (`tuteur_tuteur_390ar_light.png`) : miroir correct, barre inversée, noms latins isolés. Conforme.

### 6.3 Administration (démonstration)

- Centre de commande (`admin_admin_1440_light.png`, `admin_admin_390_light.png`) : alertes en tête (ALERTE-1), tuiles chiffrées. Défaut mineur : les tuiles « 2 Demandes à trancher » et « 0 Élèves sans enseignant » ont des hauteurs et des compositions différentes dans la même rangée (chiffre en haut, texte en bas pour l'une, chiffre et texte collés pour l'autre). À 390, le bouton « Voir toutes les alertes » est un lien aligné à gauche sous le titre, sans sa flèche. Dette HU-1, pas de lot.
- Classes à ouvrir (`admin_admin_operations_regroupements_1440_light.png`) : bandeau rouge d'alerte persistant sur toutes les pages (voulu par ALERTE-1, mais il occupe 110 px de chaque écran admin), puis une carte par regroupement avec un gros bouton plein « Créer la classe » répété sur chaque carte. Contrat B, règle 4 : « une collection de cartes répétées ne porte pas un gros CTA plein identique sur chaque carte ». `verifier_revue` compte 17 fichiers `plein-multiple` contre 14 au socle. Lot L4-03.
- Dossiers à valider (`admin_admin_personnes_dossiers_1440_light.png`) : composition maître-détail conforme au contrat D (file 336, détail large), pastilles d'état, vérifications en cases. Bon. « Voir la pièce » cassé côté serveur (D-03).
- Classes (`admin_admin_operations_groupes_390_light.png`) : bouton plein « Nouvelle classe », champ de recherche, rangée de filtres qui défile (`RangeeFiltres`). Conforme.
- Finance (`admin_admin_finance_1440_light.png`) : sept tuiles d'indicateurs, légendes honnêtes (« Une charge à venir, pas un paiement fait »). Conforme visuellement ; données de démonstration.
- Pédagogie (`admin_admin_pedagogie_1440_light.png`) : squelette encore affiché après 7 secondes en démonstration, sans explication. DESIGN-GOV 4 bis.6 : à 8 s le chargement prolongé est expliqué, à 20 s il devient récupérable. Non prouvé ici (capture à 7 s) ; à vérifier par un test. Lot L4-06.
- Tirage des contrôles (`admin_admin_securite-audit_tirages_1440_light.png`) : « Fréquence, de 0 à 50 » présenté en cartes radio pleine largeur (« 0 mission par semaine », « 1 mission », « 2 missions » ... et « Autre ») : des cartes de 100 px de haut pour un nombre. Un sélecteur compact (puces 0, 1, 2, 3, 5 et un champ « Autre ») tiendrait sur un écran, en gardant K-58 (une ligne d'explication par option). Lot L4-04.

### 6.4 Démonstrations de rôle (`/demo/*`)

Les pages `/demo/salle`, `/demo/enseignant`, `/demo/adulte`, `/demo/controleur`, `/demo/comptable`, `/demo/communications`, `/demo/accessibilite`, `/demo/classe` sont des lanceurs (listes de scénarios) ; la salle de démonstration à 1440 (`demo_salle_1440_light.png`) aligne 40 états en puces bordées. Elles sont utiles au directeur ; leur présence sur la préversion est voulue (`ENVIRONNEMENT=staging`). En arabe (`demo_salle_390ar_light.png`, `demo_adulte_390ar_light.png`), tout est traduit et miroité.

### 6.5 Proposition de retrait d'écran (toujours rangée en arbitrage)

**`/tc/classe` (Classe Live du Teaching Core).**

1. Demande d'origine : plan d'intégration Teaching Core, étape 7 (lot E), septembre 2026.
2. Ce qui fait doublon : une deuxième salle média montée dans le routeur, atteinte depuis `/tc/groupes` par les rôles autres qu'élève ; `/salle` porte déjà le dock, les supports, l'état partagé et les commandes (TB-1 à TB-12 vérifiées).
3. Ce qui la remplace : `/salle`, avec `preparerSalleEleve` pour tous les rôles.
4. Ce que l'utilisateur perd : rien de visible ; les capacités D/F/H non encore reprises (flux académique) restent dans le code, non routées.
5. Ce que l'utilisateur gagne : une seule salle, un seul jeton, une seule reconnexion à tester ; 3 012 lignes de moins à maintenir en parallèle.

Voir A-05.

---

## 7. Arbitrages du directeur

Chaque question est posée simplement, avec les options, leurs conséquences et ma recommandation. Aucune n'est technique : les détails techniques sont déjà tranchés dans les fiches.

**A-01. Enregistrement audio des cours.** Les contrats et accords (`contrat.pointEnregistrement`, accords `fr.i18n.json:901-926`) promettent « chaque cours est enregistré en audio, trente jours ». Aucune captation n'existe. Option 1 : retirer ces phrases maintenant et ne garder que « une personne de l'académie peut observer un cours en direct » (déjà vrai). Option 2 : garder le texte et construire la captation (Egress LiveKit, R2, consentements, accès tracés). Conséquence de l'option 2 : un chantier complet et une base légale à écrire avant la première famille. Recommandation : option 1, aujourd'hui ; décision du 14/10 (REGISTRE section 8) : la révision passe par l'audio préenregistré du programme, pas par l'enregistrement des cours.

**A-02. MFA du contrôleur.** Le document maître l'exige ; rien n'existe. Option 1 : activer le TOTP de Supabase, enrôlement obligatoire à la première connexion du contrôleur, garde `aal2` dans `rejoindre_observation` et les RPC de mission. Option 2 : différer après la première cohorte. Conséquence de l'option 2 : un mot de passe volé suffit pour observer des enfants. Recommandation : option 1, avant toute mission réelle (lot L1-10 après décision).

**A-03. Un seul nom pour l'interface des enfants.** Le document maître (12/10) dit « Interface guidée » ; le code, le tableau et K-50 (27/09) disent « Mode Accessibilité » (9 libellés). Option 1 : « Interface guidée » partout (9 clés à changer, les routes ne bougent pas). Option 2 : « Mode Accessibilité » partout et amender le document maître. Recommandation : option 1, c'est la décision la plus récente et le mot que les familles comprennent.

**A-04. Navigation de l'enseignant.** Le document maître (10.1) dit trois destinations sans quatrième entrée ; K-43 (26/09) dit quatre (Aujourd'hui, Classes, Disponibilités, Profil) et le code en a quatre. Option 1 : garder quatre et amender le document maître. Option 2 : passer à trois en fondant Classes dans Journée. Conséquence de l'option 2 : refaire la coquille enseignant et ses tests (vague EN vérifiée). Recommandation : option 1.

**A-05. Seconde salle.** Option 1 : débrancher `/tc/classe` maintenant (lot L3-01, une ligne du routeur et une fonction), garder les fichiers. Option 2 : attendre d'avoir repris dans `/salle` les capacités D/F/H. Conséquence de l'option 2 : deux salles à sécuriser et à tester tant que cela dure. Recommandation : option 1.

**A-06. Matching individuel.** Option 1 : retirer du parcours courant « prendre un élève », l'attribution 1-à-1 et les écrans `admin_attribution`, `creneaux` côté marketplace individuel ; révoquer `prendre_eleve` et `attribuer_eleve` ; le 1-à-1 devient une Classe à capacité 1. Option 2 : garder ces écrans comme exception administrative. Conséquence de l'option 2 : deux modèles d'affectation à maintenir (trois sources d'enseignant). Recommandation : option 1 ; c'est la contradiction résolue de `00_LIRE_D_ABORD.md`.

**A-07. Inscription d'un enseignant sans invitation.** Option 1 : fermer `creer_profil_inscription('teacher')` sans code valide. Option 2 : laisser les deux portes. Conséquence de l'option 2 : n'importe qui ouvre un dossier enseignant. Recommandation : option 1 (lot L1-11 après décision).

**A-08. Site public et tarifs.** La PR 8 (site statique français) vise `main` et n'est pas intégrée ; aucune politique tarifaire n'existe côté serveur ; aucun simulateur. Option 1 : faire porter la PR 8 sur la branche de référence par l'agent du site (K-64), et créer d'abord la politique tarifaire versionnée côté serveur, dont le site et le simulateur liront la projection publique. Option 2 : publier le site avec des prix écrits en dur, puis les raccorder. Conséquence de l'option 2 : deux grilles (site et application) à tenir à la main, contraire au document maître 13.3. Recommandation : option 1.

**A-09. Observation du tuteur en staging.** Le serveur est prêt (2 visites de 120 s, jeton borné). L'écran est fermé par un drapeau vrai seulement en développement. Option 1 : après la vague 1 de sécurité, ouvrir le drapeau pour `staging`, garder la production fermée jusqu'à une recette à quatre rôles. Option 2 : attendre la recette LiveKit complète. Recommandation : option 1 (lot L2-06).

**A-10. CI et déploiement (fichiers `.github/`, hors de portée des agents).** Trois lignes à poser par le directeur : liste blanche des deux empreintes de test (`bibliotheque_upload_test.ts:43`, `20261011072525_f70_review_insert_acl_and_hash.sql:36`) ; rejouer tous les `scenarios_*.sql` ; faire tourner le job Flutter sur les PR vers `ccr-1b1bfa0b-m1kvkk` et `claude/backend-reprise` ; ajouter `needs` dans `deploy.yml` ; un secret `SUPABASE_URL` distinct pour l'aperçu. Recommandation : appliquer les cinq ; le lot L1-09 prépare le fichier exact à copier.

Deux décisions de produit déjà prises que le code ne respecte pas encore (pas d'arbitrage, exécution) : le tuteur naît `pending_kyc` alors que K-47 ne lui demande rien (P3-2) ; les cohortes et réglages du 29/09 au 14/10 (D-16 à D-19, lot L2-08, étape `ALIGN-1410-BACK` déjà au tableau).

---

## 8. Plan de correction réparti

Les fiches sont dans `docs/audit-final/lots/`, une par lot, autonomes. `docs/audit-final/lots/INDEX.md` donne la vue d'ensemble : vague, dépendances, modèle, taille, fichiers. Chaque lot tourne dans son propre worktree, sur une branche partie de `claude/backend-reprise`, et ne touche aucun fichier d'un autre lot de la même vague. Chaque vague se termine par un lot de vérification croisée confié à un agent qui n'a pas écrit le code.

| Vague | Lots | Ce qu'elle ferme |
|---|---|---|
| 1. Sécurité P0 et P1 | L1-01 à L1-09, L1-V | P0-1, P0-2, P1-1 à P1-7 |
| 2. Raccordements manquants | L2-01 à L2-10, L2-V | remplaçant et retrait d'élève, aperçu KYC, file des cahiers, fratrie côté client, écran des offres, observation, matricule, réglages du 14/10, photos d'élève, annonce en double |
| 3. Doublons et simplification | L3-01 à L3-07, L3-V | seconde salle, jetons de mouvement, code mort, libellés en double, RPC en double, garde-fous en régression |
| 4. Finition visuelle | L4-01 à L4-06, L4-V | connexion, Mon compte, cartes à bouton répété, tirage, données de démonstration, squelettes |

Exécutants : les fiches disent « Codex » pour `supabase/**` et les adaptateurs (COHABITATION, garde-fou versionné) et « Claude » pour les écrans. La fiche « Maintenant » du tableau (16/10) dit que le directeur a levé les zones ChatGPT ; le garde-fou n'a pas suivi. Le directeur nomme l'exécutant au lancement de chaque lot ; les fiches n'en dépendent pas.

Ordre impératif : la vague 1 avant toute invitation de famille réelle. Les vagues 2, 3 et 4 peuvent se chevaucher entre elles, pas avec la vague 1 sur les mêmes fichiers.

Esprit de travail inscrit dans chaque fiche (Cherny, Karpathy) : critère de réussite écrit avant tout le reste ; un moyen de vérifier soi-même (scénario SQL, test Dart, capture) ; le plus simple qui marche ; changement chirurgical ; petit diff ; chaque erreur payée devient une ligne dans « Pièges connus ».

Ce que ce rapport ne décide pas : le périmètre finance (Comptable, paie, recharge) et le site public restent suspendus aux arbitrages A-08 et au périmètre MVP-0 ; aucun lot ne les construit.
