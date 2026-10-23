# L1-08-reprise - Compte suspendu : la RPC de gel de conservation et quatre vues gardent les droits de l'administration

Vague 1, reprise ouverte par L1-V (vérification croisée, nuit du 16 au 17/10/2026). Défaut résiduel de la classe P1-6, hors du périmètre écrit de L1-08 (policies seulement), pas une régression : la vague ne l'a ni créé ni aggravé.

## 1. But et pourquoi (P1-6 résiduel, rapport section 4.2)

L1-08 a enveloppé 41 policies par rôle dans `app_account_valid()` ; le scénario L1-V prouve qu'un administrateur suspendu ne lit plus rien par REST (D1 à D3). Mais trois chemins hors policies portent encore un rôle nu :

- la RPC `public.geler_archive_seance(uuid, text, boolean)` (SECURITY DEFINER, exécutable par `authenticated`, inscrite dans la liste blanche L1-09) n'exige que `app_role() = 'admin'`. Un administrateur suspendu, pendant la vie de son jeton (une heure), lève le gel de conservation d'un enregistrement retenu pour un litige : `legal_hold_since` repasse à NULL et l'archive redevient purgeable à `expires_at`. Preuve : `scenarios_af_l1_v_contournements.sql`, bloc D5, « L1-V DEFAUT D5 : admin suspendu leve le gel de conservation d'un enregistrement (retour t) » puis « legal_hold_since est NULL apres l'appel ». Classement : P1 (pouvoir destructeur d'un compte retiré, journalisé mais effectif).
- les vues `presence_seance_v`, `session_peers_v`, `tendance_feedback_v` (propriétaire `postgres`, donc sans RLS sous-jacente) ouvrent une branche `app_role() in ('admin','controller')` ou `app_role() = 'admin'` sans `app_account_valid()`. Preuve : blocs D4 et D6, « admin suspendu lit presence_seance_v (4 lignes) », « controleur suspendu lit presence_seance_v (4 lignes) ». Classement : P2 (lecture de prénoms et d'états de présence de toute l'académie par un compte retiré).
- `eleves_en_attente_v` exige le rôle `teacher` sans compte valide : un enseignant suspendu voit les élèves sans affectation. P3.

Deux points d'hygiène relevés dans la migration de L1-08 :

- `20261017100800_af_l1_08_policies_compte_valide.sql` n'a ni `begin;` ni `commit;` (les sept autres migrations de la vague en ont) : sous `psql -f`, comme en CI et en rejeu local, un échec du postflight laisse les `alter policy` déjà passés. P3.
- La garde « ni disabled ni supprimé » des trois policies de dépôt (`kyc_staff_self_insert`, `kyc_guardian_insert`, `contract_acceptances_self_insert`) est écrite en négatif (`account_status <> 'disabled'`) et ignore `access_until`. Exacte aujourd'hui (l'énumération a quatre valeurs), fausse le jour où une valeur s'ajoute. P3.

Enfin, l'en-tête de `scenarios_af_liste_blanche_volatiles.sql` affirme que chaque fonction listée a « garde positive sur le role ET app_account_valid() » ; c'est faux pour `geler_archive_seance` (seule fonction volatile DEFINER exécutable par `authenticated` dont le corps cite `app_role()` sans `app_account_valid`, requête du point 5).

## 2. Critère de réussite

C'est fini quand :

1. une migration horodatée redéfinit `geler_archive_seance` avec `if not coalesce(public.app_role() = 'admin' and public.app_account_valid(), false)`, corps sinon identique ;
2. la même migration recrée `presence_seance_v`, `session_peers_v`, `tendance_feedback_v` et `eleves_en_attente_v` avec `public.app_account_valid()` en tête de la clause d'accès, mêmes colonnes dans le même ordre, `security_barrier` conservé ;
3. elle est entre `begin;` et `commit;` ;
4. dans `scenarios_af_l1_v_contournements.sql`, les NOTICE « L1-V DEFAUT D4 », « D5 », « D6 » deviennent des exceptions, et le scénario passe ;
5. la requête du point 5 rend zéro ligne ;
6. 15 scénarios CI PASS, chaque scénario PASS sur base neuve, liste blanche PASS.

Facultatif, même lot : garde positive `account_status in ('pending_kyc','provisional_active','active') and (access_until is null or access_until > now())` dans les trois policies de dépôt ; `begin;`/`commit;` ne peut pas être ajouté à la migration 20261017100800 si elle est déjà appliquée quelque part (vérifier d'abord).

## 3. Ce qu'il faut lire

- `docs/audit-final/verifications/L1-V-2026-10.md` (défauts D-1 et D-2).
- `supabase/tests/scenarios_af_l1_v_contournements.sql`, blocs D.
- La définition actuelle de chaque objet, lue dans la base rejouée (`pg_get_functiondef`, `pg_get_viewdef(..., true)`), jamais réécrite de mémoire.
- `lib/core/suivi/service_suivi.dart:75`, `lib/core/tc_classe/roster_enseignant.dart:200`, `lib/core/presence/service_presence.dart:232` (lecteurs de `presence_seance_v`, pour vérifier que les colonnes ne bougent pas).

## 4. Fichiers autorisés et interdits

Autorisés : `supabase/migrations/2026101712xxxx_af_l1_08_reprise_*.sql` (nouveau), `supabase/tests/scenarios_af_l1_v_contournements.sql` (NOTICE vers exception), `supabase/tests/scenarios_af_liste_blanche_volatiles.sql` (en-tête seulement).

Interdits : toute migration existante, `lib/`, `.github/`.

## 5. Étapes

1. Base neuve, stub puis toutes les migrations ; exporter les quatre `pg_get_viewdef` et `pg_get_functiondef('public.geler_archive_seance(uuid,text,boolean)'::regprocedure)`.
2. Écrire la migration par copie exacte, une seule condition ajoutée par objet ; `create or replace view` exige les mêmes colonnes dans le même ordre.
3. Rejouer ; jouer `scenarios_af_l1_v_contournements.sql` : D4, D5 et D6 doivent sortir en « OK ».
4. Changer les trois NOTICE en `raise exception` ; rejouer ; vérifier qu'il ÉCHOUE sur une base sans la nouvelle migration.
5. Requête de contrôle :
   `select p.oid::regprocedure from pg_proc p join pg_namespace n on n.oid = p.pronamespace where n.nspname = 'public' and p.provolatile = 'v' and p.prosecdef and has_function_privilege('authenticated', p.oid, 'execute') and p.prosrc like '%app_role()%' and p.prosrc not like '%app_account_valid%';`

## 6. Vérifications

- `\d+` des quatre vues identique avant et après (colonnes, types).
- 15 scénarios CI dans l'ordre de `ci.yml`, puis chaque scénario sur base neuve.
- `git diff --stat` limité aux fichiers autorisés.

## 7. Pièges connus

- Une vue propriété de `postgres` ne passe pas par la RLS des tables lues : la garde de compte doit être dans la vue elle-même.
- `presence_seance_v` appelle `etat_presence` par ligne : ajouter `app_account_valid()` en tête de clause, pas dans une sous-requête corrélée.
- Le scénario L1-V est à base neuve : ne pas l'enchaîner après un autre scénario qui laisse des fixtures.

## 8. Quand s'arrêter et demander

- Si un écran ou une fonction Edge lit l'une des quatre vues avec un compte `pending_kyc` (que `app_account_valid()` refuse) : s'arrêter, lister l'appelant.
- Si la migration 20261017100800 est déjà appliquée sur STAGING : ne pas la modifier, tout mettre dans la nouvelle.

## 9. Commit

- Branche : `lots/L1-08-reprise-rpc-vues`, partie de `claude/backend-reprise` après fusion de la vague 1.
- Message : `fix(securite): gel de conservation et vues de presence exigent un compte valide (L1-08-reprise, P1-6)`.
- Jamais de push sur `main`. PR brouillon vers `claude/backend-reprise`.

## 10. Modèle conseillé

Zone backend. Difficulté : Haiku suffit (copie exacte, une condition par objet), relecture par l'agent de vérification de la vague suivante.

Esprit : une garde de compte ne vaut que si elle est sur tous les chemins, policies, vues et RPC.
