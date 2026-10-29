# Admission, lot B : une famille et un élève adulte naissent en attente, rapport du 29/10/2026

Décision : `docs/current/DECISION-ADMISSION-2026-10-27.md`, §2 (règles 1, 2, 4, 5) et §7 (lot B).
Branche `claude/admiring-brown-r6ai72-admission-b`, depuis `origin/main` (0278546).

## Ce qui est bloqué, inconnu ou non prouvé (à lire d'abord)

1. **Le cœur du lot est côté serveur, zone interdite aux agents.** La migration et le modèle d'e-mail sont écrits ci-dessous, mot pour mot, mais **ni appliqués, ni rejoués sur un Postgres nu, ni testés sur staging**. Rien de ce lot n'est vrai en production tant qu'ils ne sont pas posés.
2. **Le type `personnel` n'est pas créé.** `candidature_types.role_compte` est obligatoire et ne porte qu'un rôle ; le personnel en a plusieurs (comptable, contrôleur, direction). Il faut une décision : un type par rôle (`personnel_comptable`, `personnel_controleur`, `personnel_direction`), ou une colonne de plus. Sans enjeu pour le lot B : le personnel entre toujours sur invitation.
3. **La confirmation d'e-mail** (`enable_confirmations`) est un réglage du tableau de bord Supabase : c'est au directeur de l'allumer (Authentication, Sign In / Providers, Email, « Confirm email »).
4. **Le plafond d'inscriptions par heure** (`candidatures.inscriptions_par_heure` = 60 en production) n'est lu par aucune des deux fonctions d'inscription des familles. Je ne l'ai pas branché : à décider avec ce lot ou au suivant.
5. **Cinq scénarios serveur de la CI deviennent rouges avec cette migration** (rejoué en local, voir plus bas) ; ils sont dans la zone interdite, à mettre à jour dans la même pull request :
   - `scenarios_tuteur_nait_actif.sql` et `scenarios_af_l1_11_inscription_enseignant_invitation.sql` (l. 112) : ils prouvent D4, que la décision du 27/10 annule. Attendre `pending_kyc` au lieu de `active` ;
   - `scenarios_cand_l1_socle.sql` (l. 276) et `scenarios_cand_l2a2_gestes_direction.sql` (l. 338) : ils figent l'empreinte du corps de `lister_candidatures` ; droits, propriétaire, `SECURITY DEFINER` et `search_path` sont inchangés (vérifié), seule l'empreinte est à remplacer ;
   - `scenarios_l5_usage_inscription.sql` (l. 71) : sa fixture inscrit un tuteur sans genre ; lui donner un genre (l'application l'exige déjà à l'étape « Genre »).
6. Une famille en attente ne peut pas encore créer les profils de ses enfants (`creer_profil_enfant` exige un tuteur actif). C'est cohérent avec « rien d'autre n'est visible avant la décision », mais la direction décidera sans voir les enfants. À trancher pour le lot C.
7. Les compteurs du tableau de bord de la direction qui comptent les candidatures sans filtre de type compteront aussi les familles. Non vérifié un par un.

## Ce que fait ce lot dans l'application (codé, testé localement)

- La page d'attente d'un tuteur (famille ou élève adulte) dit : « Votre demande est en cours », « La direction lit chaque demande avant d'ouvrir un compte. », « Vous n'avez rien à envoyer. Nous vous écrivons à votre adresse e-mail dès que la direction a répondu. » Avant : « L'ouverture de votre compte n'est pas encore automatique », et « joignez l'académie ».
- La page d'attente d'un tuteur ignore la demande d'admission pour son affichage : elle ne montre jamais les salles d'examen, la tuile de partage ni « Vos autres talents », qui ne concernent que les enseignants.

## La migration, à poser dans `supabase/migrations/20261029120000_admission_lot_b_famille_en_attente.sql`

Écrite à partir des définitions **lues en production le 29/10/2026** (`private.creer_profil_inscription_interne`, `public.inscrire_titulaire`, `public.lister_candidatures`, `public.courriel_enfiler`). Aucun `DELETE`, `DROP` ni `TRUNCATE`.

```sql
-- ADMISSION lot B (decision du directeur du 27/10/2026,
-- docs/current/DECISION-ADMISSION-2026-10-27.md §2 et §7) : personne n'entre
-- sans decision de la direction. Annule D4 (20261024160000_tuteur_nait_actif).
--
-- 1. Deux types de demande : famille et eleve_adulte (compte tuteur).
-- 2. private.creer_profil_inscription_interne : le tuteur nait en attente
--    (pending_kyc) avec sa demande (etape recue), et l'e-mail « demande
--    recue » part par la file. Le reste est identique a la version du 24/10.
-- 3. public.inscrire_titulaire : « Moi » fait de la demande une demande
--    d'eleve adulte.
-- 4. public.lister_candidatures : sans type demande, la file reste celle des
--    enseignants (ADM-20 n'envoie aucun type) ; les listes des familles
--    viendront au lot C.
-- Les tuteurs deja actifs ne changent pas.

BEGIN;

INSERT INTO public.candidature_types (code, role_compte)
VALUES ('famille', 'guardian'), ('eleve_adulte', 'guardian')
ON CONFLICT (code) DO NOTHING;

CREATE OR REPLACE FUNCTION private.creer_profil_inscription_interne(
  p_role text,
  p_first_name text,
  p_last_name text,
  p_gender public.gender DEFAULT NULL::public.gender,
  p_timezone text DEFAULT 'Europe/Paris'::text,
  p_parent_suit_des_cours boolean DEFAULT false
)
RETURNS public.profiles
LANGUAGE plpgsql SECURITY DEFINER SET search_path = ''
AS $function$
declare
  v_uid uuid := auth.uid();
  v_role public.app_role;
  v_household uuid;
  v_profile public.profiles;
  v_candidature public.candidatures;
begin
  if v_uid is null then raise exception 'aucune session'; end if;
  if p_role not in ('guardian', 'teacher') then
    raise exception 'role non ouvert a l''inscription publique : %', p_role;
  end if;
  v_role := p_role::public.app_role;
  if v_role <> 'guardian' and coalesce(p_parent_suit_des_cours, false) then
    raise exception 'profil apprenant personnel reserve au titulaire';
  end if;
  if exists (select 1 from public.profiles p where p.id = v_uid) then
    raise exception 'ce compte a deja un profil';
  end if;
  if coalesce(btrim(p_first_name), '') = '' or coalesce(btrim(p_last_name), '') = '' then
    raise exception 'prenom et nom sont requis';
  end if;
  -- La demande recopie le genre du compte (candidatures.genre, NOT NULL).
  if v_role = 'guardian' and p_gender is null then
    raise exception 'genre requis' using errcode = '22023';
  end if;

  if v_role = 'guardian' then
    insert into public.households (timezone)
    values (coalesce(nullif(btrim(p_timezone), ''), 'Europe/Paris'))
    returning id into v_household;
  end if;
  -- Admission (27/10) : tout compte nait en attente de la decision.
  insert into public.profiles
    (id, immutable_id, role, household_id, first_name, last_name, gender, account_status)
  values (v_uid, null, v_role, v_household,
    btrim(p_first_name), btrim(p_last_name), p_gender, 'pending_kyc')
  returning * into v_profile;

  if v_role = 'guardian' then
    update public.households set primary_guardian_id = v_uid where id = v_household;
    if coalesce(p_parent_suit_des_cours, false) then
      insert into public.student_profiles
        (profile_id, titulaire_profile_id, student_type, interface_mode,
         camera_policy, cohorte)
      values (v_uid, v_uid, 'autonomous', 'standard', 'forbidden', 'adulte_18_plus');
      perform public.log_sensitive_access(
        'profil_eleve_titulaire_cree', 'student_profiles', v_uid::text,
        jsonb_build_object('student_type', 'autonomous', 'source', 'inscription')
      );
    end if;
    -- La demande d'admission, une par compte et par type.
    insert into public.candidatures (type_code, profile_id, genre, nom_complet, source)
    values ('famille', v_uid, p_gender,
      btrim(p_first_name) || ' ' || btrim(p_last_name), 'lien_public')
    returning * into v_candidature;
    perform public.courriel_enfiler(
      'inscription', 'admission_recue', public.courriel_adresse_profil(v_uid), v_uid,
      jsonb_build_object('reference', v_candidature.reference),
      'admission_recue:' || v_candidature.id::text);
  else
    insert into public.teacher_profiles (profile_id) values (v_uid);
  end if;
  perform public.log_sensitive_access('profil_cree', 'profiles', v_uid::text,
    jsonb_build_object('role', v_role::text));
  return v_profile;
end;
$function$;

CREATE OR REPLACE FUNCTION public.inscrire_titulaire(
  p_usage text,
  p_first_name text,
  p_last_name text,
  p_gender public.gender DEFAULT NULL,
  p_timezone text DEFAULT 'Europe/Paris',
  p_suit_des_cours boolean DEFAULT false
) RETURNS public.profiles
LANGUAGE plpgsql
VOLATILE
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  v_profile public.profiles;
BEGIN
  IF auth.uid() IS NULL THEN RAISE EXCEPTION 'aucune session'; END IF;
  IF NOT coalesce(p_usage IN ('moi', 'famille'), false) THEN
    RAISE EXCEPTION 'usage inconnu : %', p_usage USING ERRCODE = '22023';
  END IF;
  v_profile := private.creer_profil_inscription_interne(
    'guardian', p_first_name, p_last_name, p_gender, p_timezone,
    p_usage = 'moi' OR coalesce(p_suit_des_cours, false));
  UPDATE public.households h
     SET usage_inscription = p_usage
   WHERE h.id = v_profile.household_id;
  -- « Moi » : la demande est celle d'un eleve adulte (liste separee, lot C).
  IF p_usage = 'moi' THEN
    UPDATE public.candidatures c
       SET type_code = 'eleve_adulte'
     WHERE c.profile_id = v_profile.id AND c.type_code = 'famille';
  END IF;
  RETURN v_profile;
END;
$function$;

-- La file des enseignants reste celle des enseignants : sans type demande,
-- lister_candidatures lit le type « enseignant ». Une seule ligne change ; le
-- bloc refuse de continuer si elle n'est pas trouvee telle quelle.
DO $do$
DECLARE
  v_def text := pg_catalog.pg_get_functiondef(
    'public.lister_candidatures(jsonb,text,integer)'::pg_catalog.regprocedure);
  v_avant text := 'v_type := v_filtre ->> ''type'';';
  v_apres text := 'v_type := coalesce(v_filtre ->> ''type'', ''enseignant'');';
BEGIN
  IF pg_catalog.strpos(v_def, v_avant) = 0
     OR pg_catalog.strpos(pg_catalog.substr(v_def, pg_catalog.strpos(v_def, v_avant) + 1), v_avant) <> 0 THEN
    RAISE EXCEPTION 'lister_candidatures : la ligne du type a change, migration a revoir';
  END IF;
  EXECUTE pg_catalog.replace(v_def, v_avant, v_apres);
END;
$do$;

COMMIT;
```

Points relus : `CREATE OR REPLACE` garde les droits et les commentaires des trois fonctions ; la règle `private.candidature_compte_conforme` accepte un tuteur `pending_kyc` rattaché à une demande `famille` à l'étape `recue` (rôle du type `guardian`, compte ni `active` ni `provisional_active`) ; le déclencheur `candidatures_genre_du_compte` recopie le genre du compte ; `courriel_enfiler` rend `NULL` sans adresse et ne lève jamais, il ne bloque donc pas l'inscription ; la clé d'idempotence empêche un second e-mail.

## Rejoué en local

Postgres 16 local (la CI tourne en 17 ; pas de démon Docker ici) : `supabase/tests/stub_auth.sql`, les 269 migrations du dépôt, puis celle-ci, sans erreur. Le scénario ci-dessous, à poser dans `supabase/tests/scenarios_admission_lot_b.sql` et dans `.github/workflows/ci.yml`, passe :

```
NOTICE:  ADM-B OK : famille et eleve adulte en attente, demandes recues, e-mails en file, activation refusee
NOTICE:  ADM-B OK : sans genre, refus net
NOTICE:  ADM-B OK : la file sans type lit les enseignants
```

```sql
-- ADMISSION lot B (decision du 27/10/2026) : une famille et un eleve adulte
-- naissent en attente avec leur demande ; l'e-mail « demande recue » est en
-- file ; la file des enseignants ne montre pas les familles.
-- Rejoue sur une base neuve, apres stub_auth.sql et toutes les migrations.
-- Fixtures sans donnee personnelle ; tout est annule a la fin. Un echec leve
-- 'ADM-B ROUGE : ...'.
BEGIN;

ALTER TABLE auth.users ADD COLUMN IF NOT EXISTS raw_app_meta_data jsonb NOT NULL DEFAULT '{}'::jsonb;
ALTER TABLE auth.users ADD COLUMN IF NOT EXISTS created_at timestamptz NOT NULL DEFAULT now();

INSERT INTO auth.users (id, email) VALUES
  ('ab000000-0000-4000-8000-000000000001', 'adm-b-famille@example.test'),
  ('ab000000-0000-4000-8000-000000000002', 'adm-b-adulte@example.test'),
  ('ab000000-0000-4000-8000-000000000003', 'adm-b-sansgenre@example.test');

-- Une famille s'inscrit.
SELECT set_config('request.jwt.claim.sub', 'ab000000-0000-4000-8000-000000000001', true);
SELECT set_config('test.uid', 'ab000000-0000-4000-8000-000000000001', true);
SELECT set_config('request.jwt.claims', '{}', true);
SELECT set_config('test.jwt', '{}', true);
SET LOCAL ROLE authenticated;
SELECT public.inscrire_titulaire('famille', 'Fixture', 'Famille', 'female', 'Europe/Paris', false);
RESET ROLE;

-- Un eleve adulte s'inscrit (« Moi »).
SELECT set_config('request.jwt.claim.sub', 'ab000000-0000-4000-8000-000000000002', true);
SELECT set_config('test.uid', 'ab000000-0000-4000-8000-000000000002', true);
SET LOCAL ROLE authenticated;
SELECT public.inscrire_titulaire('moi', 'Fixture', 'Adulte', 'male', 'Europe/Paris', false);
RESET ROLE;

DO $controles$
DECLARE
  v_n integer;
BEGIN
  IF (SELECT p.account_status FROM public.profiles p
       WHERE p.id = 'ab000000-0000-4000-8000-000000000001') <> 'pending_kyc' THEN
    RAISE EXCEPTION 'ADM-B ROUGE : la famille ne nait pas en attente';
  END IF;
  IF (SELECT p.account_status FROM public.profiles p
       WHERE p.id = 'ab000000-0000-4000-8000-000000000002') <> 'pending_kyc' THEN
    RAISE EXCEPTION 'ADM-B ROUGE : l''eleve adulte ne nait pas en attente';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM public.candidatures c
                  WHERE c.profile_id = 'ab000000-0000-4000-8000-000000000001'
                    AND c.type_code = 'famille' AND c.etape = 'recue'
                    AND c.issue = 'en_cours' AND c.source = 'lien_public'
                    AND c.genre = 'female') THEN
    RAISE EXCEPTION 'ADM-B ROUGE : la demande de la famille manque';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM public.candidatures c
                  WHERE c.profile_id = 'ab000000-0000-4000-8000-000000000002'
                    AND c.type_code = 'eleve_adulte' AND c.etape = 'recue') THEN
    RAISE EXCEPTION 'ADM-B ROUGE : la demande de l''eleve adulte manque ou n''a pas son type';
  END IF;
  SELECT count(*) INTO v_n FROM public.courriels_sortants s
   WHERE s.modele = 'admission_recue' AND s.categorie = 'inscription'
     AND s.destinataire_profil IN ('ab000000-0000-4000-8000-000000000001',
                                   'ab000000-0000-4000-8000-000000000002');
  IF v_n <> 2 THEN
    RAISE EXCEPTION 'ADM-B ROUGE : % e-mail(s) « demande recue » en file, 2 attendus', v_n;
  END IF;
  -- Un compte en attente avec sa demande ne s'active pas avant la decision.
  BEGIN
    UPDATE public.profiles SET account_status = 'active'
     WHERE id = 'ab000000-0000-4000-8000-000000000001';
    RAISE EXCEPTION 'ADM-B ROUGE : la famille a pu etre activee sans decision';
  EXCEPTION WHEN check_violation THEN
    NULL;
  END;
  RAISE NOTICE 'ADM-B OK : famille et eleve adulte en attente, demandes recues, e-mails en file, activation refusee';
END
$controles$;

-- Sans genre, l'inscription est refusee (la demande en exige un).
SELECT set_config('request.jwt.claim.sub', 'ab000000-0000-4000-8000-000000000003', true);
SELECT set_config('test.uid', 'ab000000-0000-4000-8000-000000000003', true);
DO $sans_genre$
BEGIN
  PERFORM public.inscrire_titulaire('famille', 'Fixture', 'SansGenre', NULL, 'Europe/Paris', false);
  RAISE EXCEPTION 'ADM-B ROUGE : inscription sans genre acceptee';
EXCEPTION WHEN invalid_parameter_value THEN
  RAISE NOTICE 'ADM-B OK : sans genre, refus net';
END
$sans_genre$;

-- La file des enseignants (sans type demande) ne montre pas les familles.
DO $file$
DECLARE
  v_def text := pg_catalog.pg_get_functiondef(
    'public.lister_candidatures(jsonb,text,integer)'::pg_catalog.regprocedure);
BEGIN
  IF pg_catalog.strpos(v_def, 'coalesce(v_filtre ->> ''type'', ''enseignant'')') = 0 THEN
    RAISE EXCEPTION 'ADM-B ROUGE : lister_candidatures ne borne pas la file aux enseignants';
  END IF;
  RAISE NOTICE 'ADM-B OK : la file sans type lit les enseignants';
END
$file$;

ROLLBACK;
```

## Le modèle d'e-mail, dans `supabase/functions/_shared/courriel/modeles_fr.ts`

Dans `MODELES`, après `demande_recue` :

```ts
  admission_recue: (d) => avis(d, 'Votre demande est bien reçue', 'Votre demande est en cours',
    'Nous avons bien reçu votre demande. La direction lit chaque demande avant d’ouvrir un compte. Vous n’avez rien à envoyer : nous vous écrivons à cette adresse dès que la direction a répondu.',
    'Voir ma demande', '/attente'),
```

et l'ajouter à `TRADUITS_A_L_ENVOI` (`['attente_candidat', 'admission_recue']`) pour qu'il parte traduit dans la langue de la personne. Le test `courriel_test.ts` liste les modèles : l'y ajouter. Sans ce modèle, la ligne reste dans la file en échec, l'inscription n'est pas bloquée.

## Ce que le directeur fait pour prouver le lot B, après fusion et migration

Les inscriptions restent fermées en production (décision, §6) : la preuve se fait avec une famille test.

1. Allumer « Confirm email » dans Supabase.
2. S'inscrire comme famille test, confirmer l'adresse.
3. Après les conditions à accepter, la page dit « Votre demande est en cours » ; aucune autre page n'est atteignable (taper `/tuteur` dans l'adresse ramène à la page d'attente) : vrai. Sinon : faux, capture.
4. L'e-mail « Votre demande est bien reçue » arrive : vrai. Sinon : faux, capture.
