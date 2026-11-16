# PX-1 : relevé avant le code (A-11, A-9, messagerie), 16/11/2026

Lu en production, **lecture seule, schéma, déclencheurs et fonctions seulement**, aucune ligne de personne. Ce relevé
précède toute ligne de code (consigne du pilote). Il dit d'abord ce qui est faux ou mal pensé.

## 0. Ce qui est faux ou mal pensé (à arbitrer par le pilote avant le code)

1. **R13 (absent de toute liste de personnes) ne se prouve que liste par liste.** `profiles` n'a ni colonne « compte
   officiel » ni valeur de rôle non humaine (`app_role` : admin, accountant, controller, teacher, guardian,
   student). Les listes de personnes sont des lectures directes de `profiles` (annuaire d'observation) ou des
   fonctions `SECURITY DEFINER` qui ne passent pas par la RLS. Une politique RLS ne suffit donc pas. Le scénario ne
   peut prouver l'absence que pour les lectures **nommées** dans le scénario (§3).
2. **`com_envoyer_message` n'a pas de fonction interne réutilisable** : l'auteur vient de `auth.uid()` via
   `private.com_appelant_msg()`, et le droit d'écrire de `private.com_fil_json(...)`. Praxis ne se connecte jamais
   (R3) : il ne peut pas l'appeler. Consigne : ne pas modifier les fonctions de la messagerie. `praxis_ecrire` écrit donc
   lui-même dans `public.com_messages` (+ `com_fils.dernier_message_le`, + `com_lectures`, + audit), et laisse jouer
   le déclencheur existant `com_signaler_message` (signaux temps réel). Logique dupliquée sur ces trois écritures ;
   à factoriser plus tard par la messagerie.
3. **Les fils d'une famille concernent presque toujours un mineur.** `private.com_paires` n'admet jamais un mineur
   comme partie directe (`NOT com_est_mineur`), mais un fil de type `classe` ou `eleve` a pour partie un **foyer** dont les
   élèves mineurs sont l'objet. Lecture littérale la plus prudente de §3.2, retenue : sont refusés (cause `mineur`)
   les fils dont une partie est un profil mineur ou inconnu, dont un auteur est mineur, **et** les fils `classe`/`eleve`
   dont la partie est un foyer. Praxis ne voit alors que les fils `dossier`, `candidature`, `remplacement`,
   `profilPaiement` (adultes). **Cela retire à Praxis la plupart des messages de parents.** À assouplir seulement par le
   directeur, par décision datée.
4. **A-9 : table à côté, pas de colonne `usage`.** `jetons_agent` a `profil_observe uuid NOT NULL` et `parcours`
   (enum) `NOT NULL` : un jeton d'observation désigne une personne observée et passe par `agent-session` qui signe un
   JWT `agent_ro`. Une clé Praxis n'a ni personne observée ni JWT : elle est un secret présenté à une fonction Edge qui
   appelle `service_role`. L'étendre mettrait des clés Praxis dans `jetons_agent_actifs()` et `agent_pre_request()`,
   donc sur le chemin de la règle 1 de `0014`. On crée `private.praxis_cles` à côté (même modèle : empreinte sha256,
   montrée une fois, expiration, révocation). L'écran partagera la page, pas la table.
5. **A-11 : aucun déclencheur sur `auth.users` ni `auth.identities`** (aucun profil créé par déclencheur : c'est
   l'application qui le fait). Sur `public.profiles`, en INSERT : `profiles_attribuer_matricule` (écrit une ligne dans
   `private.person_registrations`, donc un matricule `RA-26-…` consultable par `rechercher_personne_par_matricule`)
   **sauf** si `immutable_id` est fourni **et** `session_user = 'postgres'` (vérifié : la connexion d'`execute_sql` est
   `postgres`) ; `b21_profil_reprend_matricule` (sans effet hors rôle `student`) ; `profiles_nom_propre` ;
   `profiles_garde_photo`. Aucun déclencheur d'INSERT n'envoie de courriel ni de notification (les courriels et
   notifications d'activation sont des déclencheurs d'UPDATE de `account_status` pending_kyc vers active, rôle teacher).
   La migration pose un `immutable_id` explicite et **échoue** si `session_user <> 'postgres'` (fail closed).
6. 266 comptes d'authentification existants ont un mot de passe vide (liens magiques ou OTP) : « sans mot de passe »
   ne distingue donc pas Praxis. Ce qui l'empêche de se connecter : aucune ligne dans `auth.identities`, aucun courriel
   ni téléphone, `banned_until` posé très loin, profil `disabled`.

## 1. Ce que la migration fait du compte (proposition, à confirmer)

- `auth.users` : une ligne, `email`, `phone`, `encrypted_password` NULL, `banned_until` lointain, aucune identité.
- `public.profiles` : rôle **`accountant`** (24 fonctions le citent, contre 404 pour `admin`, 147 `teacher`, 32
  `controller`), `account_status = 'disabled'` (défense en profondeur : `app_account_valid()` vaut faux si une session
  existait), `immutable_id` explicite `RA-OFFICIEL-PRAXIS`, prénom `Praxis`. Pas de foyer (rôle de personnel).
- L'indicateur « compte officiel » : table `private.comptes_officiels (profile_id pk, code unique)` plutôt qu'une
  colonne de `profiles` (table chaude, garde `guard_profile_privileged_columns`). La messagerie le lira par une
  fonction de lecture (son domaine).
- **Risque du statut `disabled`** : il apparaît dans les lectures « comptes désactivés ». À nommer au scénario R13.

## 2. Ce que la messagerie fait de l'écriture (lu)

Un fil (`com_fils`) a deux parties : `partie_a` (profil ou foyer) et `partie_b` (`equipe` ou un profil). « L'académie
participe » = `partie_b_nature = 'equipe'`. `peut_ecrire` = la paire existe dans `private.com_paires`. Un message :
`com_messages(fil_id, auteur_id, cle_idempotence, texte)`, unique `(fil_id, auteur_id, cle_idempotence)`. Les non-lus
se calculent par `com_lectures`. Plafond existant : 5 000 signes, 30 messages par jour (candidatures, hors admin).

## 3. Lectures de personnes nommées pour le scénario R13

`lister_enseignants`, `rechercher_personne_par_matricule`, `lister_planning_direction`, `groupe_roster_enseignant`,
`controleur_roster_visite`, la table `private.person_registrations`, les lectures directes de `public.profiles` par
l'annuaire d'observation. Les autres ne sont pas prouvées.
