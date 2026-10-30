-- B2.1 (30/10/2026, voie A choisie par le pilote) : les inscrits actuels
-- importes deviennent un foyer et des matricules RA, puis des profils.
--
-- Decision : docs/current/DECISION-IMMATRICULATION-2026-10-12.md (§1 format
-- RA-AA-NNNN tire au hasard, §5 accueil des inscrits actuels). Constat du
-- pilote (30/10) : apres « Confirmer », les eleves restaient dans
-- private.preinscription_* sans foyer ni matricule.
--
-- Contrainte du schema : public.profiles.id reference auth.users(id). Le
-- serveur ne cree aucun compte de connexion a la place d'une personne
-- (decision du pilote), donc aucun profil ne nait a la confirmation. Ce lot :
--
-- 1. A la confirmation (confirmer_import_inscriptions, inchangee sinon) :
--    chaque pre-inscription qui compte un tuteur, un adulte ou un eleve recoit
--    un foyer public.households (sans tuteur principal) et chacune de ces
--    personnes un matricule RA RESERVE dans private.person_registrations,
--    sous l'identifiant de sa ligne de pre-inscription (le registre n'a pas de
--    cle etrangere vers profiles). L'annee est celle de la confirmation, date
--    du serveur. Si un tuteur porte deja l'adresse (compte confirme), son foyer
--    est repris et ses enfants deja presents sont reconnus par leur nom :
--    rien n'est double. Les enseignants ne sont pas touches (candidatures).
-- 2. A la reclamation apres preuve de l'e-mail
--    (reclamer_preinscription_apres_preuve, inchangee sinon) : la personne qui
--    reclame recoit son profil de tuteur actif (D4) dans ce foyer, avec SON
--    matricule reserve, et devient tuteur principal ; un « adulte » recoit
--    aussi sa fiche d'eleve autonome. Si elle a deja un profil de tuteur, la
--    pre-inscription rejoint son foyer (le foyer reserve, vide, est ferme,
--    jamais supprime).
-- 3. Quand le tuteur cree ensuite un enfant (fonction Edge existante
--    creer-profil-enfant), un declencheur BEFORE INSERT sur profiles reprend
--    le matricule reserve de l'eleve importe du meme foyer et du meme prenom
--    (et du meme nom s'il y a plusieurs prenoms identiques).
--
-- La ligne de pre-inscription reclamable tient lieu d'invitation nominative
-- (pilote, 30/10) : invitations_foyer (invitation d'un conjoint) n'est pas
-- utilisee. Idempotent : rejouer la confirmation ou la reclamation ne cree ni
-- foyer, ni matricule, ni profil de plus. L'essai a blanc n'est pas touche.
-- Aucune suppression : les deux RPC sont recompilees par remplacement d'un
-- point d'ancrage dans leur propre definition, et leurs empreintes F86 sont
-- recalculees.

BEGIN;

-- 1. Liens ----------------------------------------------------------------

ALTER TABLE private.preinscription_households
  ADD COLUMN household_id uuid REFERENCES public.households(id);
CREATE UNIQUE INDEX preinscription_households_household_uq
  ON private.preinscription_households(household_id)
  WHERE household_id IS NOT NULL;

-- profile_id : le profil reel de la personne, une fois cree ou reconnu. Sans
-- cle etrangere : le declencheur l'ecrit avant que la ligne profiles existe.
ALTER TABLE private.preinscription_persons
  ADD COLUMN profile_id uuid,
  ADD COLUMN realise_le timestamptz;
CREATE INDEX preinscription_persons_profile_idx
  ON private.preinscription_persons(profile_id)
  WHERE profile_id IS NOT NULL;

COMMENT ON COLUMN private.preinscription_households.household_id IS
  'B2.1 : foyer public de la pre-inscription (cree a la confirmation, ou foyer du tuteur deja present).';
COMMENT ON COLUMN private.preinscription_persons.profile_id IS
  'B2.1 : profil reel de la personne. Tant qu''il est nul, son matricule reserve est dans private.person_registrations sous l''id de cette ligne.';

-- 2. Aides privees ----------------------------------------------------------

CREATE FUNCTION private.b21_nom(p_valeur text)
RETURNS text
LANGUAGE sql IMMUTABLE SECURITY INVOKER SET search_path = ''
AS $function$
  SELECT pg_catalog.lower(pg_catalog.regexp_replace(
    pg_catalog.btrim(coalesce(p_valeur, '')), '[[:space:]]+', ' ', 'g'));
$function$;
ALTER FUNCTION private.b21_nom(text) OWNER TO postgres;
REVOKE ALL ON FUNCTION private.b21_nom(text) FROM PUBLIC, anon, authenticated, service_role;

-- Realise une pre-inscription confirmee : foyer, rapprochement, matricules
-- reserves ; avec p_uid (reclamation apres preuve), profil du tuteur.
CREATE FUNCTION private.b21_realiser_preinscription(p_pre uuid, p_uid uuid)
RETURNS jsonb
LANGUAGE plpgsql VOLATILE SECURITY DEFINER SET search_path = ''
AS $function$
DECLARE
  v_pre private.preinscription_households%ROWTYPE;
  v_owner public.profiles%ROWTYPE;
  v_person private.preinscription_persons%ROWTYPE;
  v_titulaire private.preinscription_persons%ROWTYPE;
  v_household uuid;
  v_match uuid;
  v_cohorte text;
  v_foyer_cree boolean := false;
  v_reserves integer := 0;
  v_reconnus integer := 0;
  v_profil text := 'aucun';
BEGIN
  SELECT * INTO v_pre FROM private.preinscription_households h
   WHERE h.id = p_pre FOR UPDATE;
  IF NOT FOUND OR v_pre.status <> 'confirmed'
     OR NOT EXISTS (SELECT 1 FROM private.preinscription_persons p
                     WHERE p.household_id = p_pre AND p.person_kind <> 'teacher') THEN
    RETURN pg_catalog.jsonb_build_object('realisee', false);
  END IF;

  -- Le tuteur deja present : celui qui reclame, sinon le compte confirme qui
  -- porte la meme adresse (l'adresse d'auth.users est unique).
  IF p_uid IS NOT NULL THEN
    SELECT * INTO v_owner FROM public.profiles p
     WHERE p.id = p_uid AND p.role = 'guardian' AND p.deleted_at IS NULL;
  ELSE
    SELECT p.* INTO v_owner
      FROM auth.users u JOIN public.profiles p ON p.id = u.id
     WHERE pg_catalog.lower(pg_catalog.btrim(u.email)) = v_pre.email_normalise
       AND u.email_confirmed_at IS NOT NULL
       AND p.role = 'guardian' AND p.deleted_at IS NULL
     LIMIT 1;
  END IF;

  IF v_owner.id IS NOT NULL THEN
    v_household := v_owner.household_id;
    IF v_pre.household_id IS NOT NULL AND v_pre.household_id <> v_household THEN
      -- Le foyer reserve, reste vide, est ferme ; jamais supprime.
      UPDATE public.households h SET status = 'closed'
       WHERE h.id = v_pre.household_id AND h.primary_guardian_id IS NULL
         AND NOT EXISTS (SELECT 1 FROM public.profiles p WHERE p.household_id = h.id);
    END IF;
  ELSIF v_pre.household_id IS NOT NULL THEN
    v_household := v_pre.household_id;
  ELSE
    INSERT INTO public.households DEFAULT VALUES RETURNING id INTO v_household;
    v_foyer_cree := true;
  END IF;
  IF v_pre.household_id IS DISTINCT FROM v_household THEN
    UPDATE private.preinscription_households SET household_id = v_household WHERE id = p_pre;
  END IF;

  FOR v_person IN
    SELECT * FROM private.preinscription_persons p
     WHERE p.household_id = p_pre AND p.person_kind <> 'teacher' AND p.profile_id IS NULL
     ORDER BY p.source_row, p.id
     FOR UPDATE
  LOOP
    v_match := NULL;
    IF v_person.person_kind IN ('guardian', 'adult') THEN
      v_match := v_owner.id;
    ELSE
      -- Rapprochement : un eleve deja present dans le foyer, meme prenom et
      -- meme nom, que rien d'autre ne revendique.
      SELECT pr.id INTO v_match FROM public.profiles pr
       WHERE pr.household_id = v_household AND pr.role = 'student' AND pr.deleted_at IS NULL
         AND private.b21_nom(pr.first_name) = private.b21_nom(v_person.first_name)
         AND private.b21_nom(pr.last_name) = private.b21_nom(v_person.last_name)
         AND NOT EXISTS (SELECT 1 FROM private.preinscription_persons o WHERE o.profile_id = pr.id)
       ORDER BY pr.created_at, pr.id
       LIMIT 1;
    END IF;
    IF v_match IS NOT NULL THEN
      UPDATE private.preinscription_persons
         SET profile_id = v_match, realise_le = pg_catalog.statement_timestamp()
       WHERE id = v_person.id;
      v_reconnus := v_reconnus + 1;
    ELSIF NOT EXISTS (SELECT 1 FROM private.person_registrations r WHERE r.profile_id = v_person.id) THEN
      PERFORM private.attribuer_matricule(v_person.id,
        coalesce(v_pre.confirmed_at, pg_catalog.statement_timestamp()));
      v_reserves := v_reserves + 1;
    END IF;
  END LOOP;

  IF p_uid IS NOT NULL THEN
    IF v_owner.id IS NOT NULL THEN
      v_profil := 'existant';
    ELSIF EXISTS (SELECT 1 FROM public.profiles p WHERE p.id = p_uid) THEN
      -- Un autre role (enseignant, direction) : rien n'est cree ni change.
      v_profil := 'autre_role';
    ELSE
      SELECT * INTO v_titulaire FROM private.preinscription_persons p
       WHERE p.household_id = p_pre AND p.person_kind IN ('guardian', 'adult')
         AND p.profile_id IS NULL
         AND pg_catalog.btrim(coalesce(p.first_name, '')) <> ''
         AND pg_catalog.btrim(coalesce(p.last_name, '')) <> ''
       ORDER BY p.source_row, (p.person_kind = 'guardian') DESC, p.id
       LIMIT 1
       FOR UPDATE;
      IF FOUND THEN
        -- Le matricule reserve passe au profil reel : le declencheur
        -- profiles_attribuer_matricule le retrouve sous p_uid.
        UPDATE private.person_registrations SET profile_id = p_uid
         WHERE profile_id = v_titulaire.id;
        INSERT INTO public.profiles
          (id, immutable_id, role, household_id, first_name, last_name, account_status)
        VALUES (p_uid, NULL, 'guardian', v_household,
          pg_catalog.btrim(v_titulaire.first_name), pg_catalog.btrim(v_titulaire.last_name), 'active');
        UPDATE public.households SET primary_guardian_id = p_uid
         WHERE id = v_household AND primary_guardian_id IS NULL;
        UPDATE private.preinscription_persons
           SET profile_id = p_uid, realise_le = pg_catalog.statement_timestamp()
         WHERE id = v_titulaire.id;
        IF v_titulaire.person_kind = 'adult' THEN
          -- La tranche adulte vient des tranches d'age du serveur.
          SELECT c.code INTO v_cohorte FROM public.cohortes_age c
           WHERE c.actif AND c.type_public = 'adulte'
           ORDER BY c.ordre LIMIT 1;
          INSERT INTO public.student_profiles
            (profile_id, titulaire_profile_id, student_type, interface_mode, camera_policy, cohorte)
          VALUES (p_uid, p_uid, 'autonomous', 'standard', 'forbidden', v_cohorte);
        END IF;
        PERFORM public.log_sensitive_access('profil_cree', 'profiles', p_uid::text,
          pg_catalog.jsonb_build_object('role', 'guardian', 'source', 'import_inscriptions',
            'eleve_autonome', v_titulaire.person_kind = 'adult'));
        v_profil := 'cree';
      END IF;
    END IF;
  END IF;

  RETURN pg_catalog.jsonb_build_object(
    'realisee', true, 'foyer_cree', v_foyer_cree,
    'matricules_reserves', v_reserves, 'personnes_reconnues', v_reconnus,
    'profil', v_profil);
END;
$function$;
ALTER FUNCTION private.b21_realiser_preinscription(uuid, uuid) OWNER TO postgres;
REVOKE ALL ON FUNCTION private.b21_realiser_preinscription(uuid, uuid)
  FROM PUBLIC, anon, authenticated, service_role;

-- Appelee par confirmer_import_inscriptions pour les adresses du fichier.
CREATE FUNCTION private.b21_realiser_import(p_emails text[])
RETURNS void
LANGUAGE plpgsql VOLATILE SECURITY DEFINER SET search_path = ''
AS $function$
DECLARE
  v_id uuid;
  v_r jsonb;
  v_foyers integer := 0;
  v_reserves integer := 0;
  v_reconnus integer := 0;
BEGIN
  FOR v_id IN
    SELECT h.id FROM private.preinscription_households h
     WHERE h.email_normalise = ANY(coalesce(p_emails, ARRAY[]::text[]))
     ORDER BY h.id
  LOOP
    v_r := private.b21_realiser_preinscription(v_id, NULL);
    IF (v_r->>'foyer_cree')::boolean THEN v_foyers := v_foyers + 1; END IF;
    v_reserves := v_reserves + coalesce((v_r->>'matricules_reserves')::integer, 0);
    v_reconnus := v_reconnus + coalesce((v_r->>'personnes_reconnues')::integer, 0);
  END LOOP;
  PERFORM public.log_sensitive_access(
    'preinscription_foyers_realises', 'preinscription_households', NULL,
    pg_catalog.jsonb_build_object('foyers_crees', v_foyers,
      'matricules_reserves', v_reserves, 'personnes_reconnues', v_reconnus));
END;
$function$;
ALTER FUNCTION private.b21_realiser_import(text[]) OWNER TO postgres;
REVOKE ALL ON FUNCTION private.b21_realiser_import(text[])
  FROM PUBLIC, anon, authenticated, service_role;

-- 3. Le profil d'un enfant reprend son matricule reserve --------------------

CREATE FUNCTION private.b21_profil_reprend_matricule()
RETURNS trigger
LANGUAGE plpgsql SECURITY DEFINER SET search_path = ''
AS $function$
DECLARE
  v_person uuid;
  v_meme_prenom integer;
BEGIN
  IF NEW.role IS DISTINCT FROM 'student'::public.app_role OR NEW.household_id IS NULL
     OR EXISTS (SELECT 1 FROM private.person_registrations r WHERE r.profile_id = NEW.id)
     OR NOT EXISTS (SELECT 1 FROM private.preinscription_households h
                     WHERE h.household_id = NEW.household_id) THEN
    RETURN NEW;
  END IF;

  -- Meme prenom ; le nom departage. Un prenom seul ne suffit que s'il est unique.
  SELECT count(*)::integer INTO v_meme_prenom
    FROM private.preinscription_persons p
    JOIN private.preinscription_households h ON h.id = p.household_id
   WHERE h.household_id = NEW.household_id AND p.person_kind = 'student'
     AND p.profile_id IS NULL
     AND private.b21_nom(p.first_name) = private.b21_nom(NEW.first_name)
     AND EXISTS (SELECT 1 FROM private.person_registrations r WHERE r.profile_id = p.id);
  SELECT p.id INTO v_person
    FROM private.preinscription_persons p
    JOIN private.preinscription_households h ON h.id = p.household_id
   WHERE h.household_id = NEW.household_id AND p.person_kind = 'student'
     AND p.profile_id IS NULL
     AND private.b21_nom(p.first_name) = private.b21_nom(NEW.first_name)
     AND (private.b21_nom(p.last_name) = private.b21_nom(NEW.last_name) OR v_meme_prenom = 1)
     AND EXISTS (SELECT 1 FROM private.person_registrations r WHERE r.profile_id = p.id)
   ORDER BY (private.b21_nom(p.last_name) = private.b21_nom(NEW.last_name)) DESC, p.source_row, p.id
   LIMIT 1
   FOR UPDATE OF p;
  IF v_person IS NULL THEN
    RETURN NEW;
  END IF;

  UPDATE private.person_registrations SET profile_id = NEW.id WHERE profile_id = v_person;
  UPDATE private.preinscription_persons
     SET profile_id = NEW.id, realise_le = pg_catalog.statement_timestamp()
   WHERE id = v_person;
  RETURN NEW;
END;
$function$;
ALTER FUNCTION private.b21_profil_reprend_matricule() OWNER TO postgres;
REVOKE ALL ON FUNCTION private.b21_profil_reprend_matricule()
  FROM PUBLIC, anon, authenticated, service_role;

-- Le nom trie avant profiles_assign_person_registration : les declencheurs
-- BEFORE d'une table s'executent dans l'ordre alphabetique de leur nom.
CREATE TRIGGER profiles_a_reprendre_matricule_importe
BEFORE INSERT ON public.profiles
FOR EACH ROW EXECUTE FUNCTION private.b21_profil_reprend_matricule();

-- 4. Les deux RPC appellent la realisation -----------------------------------

DO $ancrages$
DECLARE
  v_f pg_catalog.regprocedure;
  v_def text;
  v_avant text;
  v_apres text;
BEGIN
  v_f := 'public.confirmer_import_inscriptions(text,text,jsonb)'::pg_catalog.regprocedure;
  v_def := pg_catalog.pg_get_functiondef(v_f);
  v_avant := E'  perform public.log_sensitive_access(\n    ''preinscription_import_confirmed''';
  v_apres := E'  -- B2.1 : foyers et matricules reserves des personnes importees.\n'
          || E'  perform private.b21_realiser_import(v_emails);\n' || v_avant;
  IF pg_catalog.strpos(v_def, v_avant) = 0 OR pg_catalog.strpos(v_def, 'b21_realiser') > 0 THEN
    RAISE EXCEPTION 'B2.1 : confirmer_import_inscriptions a change, migration a revoir';
  END IF;
  EXECUTE pg_catalog.replace(v_def, v_avant, v_apres);

  v_f := 'public.reclamer_preinscription_apres_preuve()'::pg_catalog.regprocedure;
  v_def := pg_catalog.pg_get_functiondef(v_f);
  v_avant := E'  select coalesce(\n    pg_catalog.jsonb_agg(';
  v_apres := E'  -- B2.1 : foyer, matricules et profil du tuteur qui a prouve son adresse.\n'
          || E'  perform private.b21_realiser_preinscription(v_household_id, v_uid);\n\n' || v_avant;
  IF pg_catalog.strpos(v_def, v_avant) = 0 OR pg_catalog.strpos(v_def, 'b21_realiser') > 0 THEN
    RAISE EXCEPTION 'B2.1 : reclamer_preinscription_apres_preuve a change, migration a revoir';
  END IF;
  EXECUTE pg_catalog.replace(v_def, v_avant, v_apres);
END;
$ancrages$;

-- CREATE OR REPLACE garde proprietaire et droits ; reaffirmes par prudence.
ALTER FUNCTION public.confirmer_import_inscriptions(text, text, jsonb) OWNER TO postgres;
REVOKE ALL ON FUNCTION public.confirmer_import_inscriptions(text, text, jsonb)
  FROM PUBLIC, anon, service_role;
GRANT EXECUTE ON FUNCTION public.confirmer_import_inscriptions(text, text, jsonb) TO authenticated;
ALTER FUNCTION public.reclamer_preinscription_apres_preuve() OWNER TO postgres;
REVOKE ALL ON FUNCTION public.reclamer_preinscription_apres_preuve()
  FROM PUBLIC, anon, service_role;
GRANT EXECUTE ON FUNCTION public.reclamer_preinscription_apres_preuve() TO authenticated;

DO $empreintes$
DECLARE
  v_oid pg_catalog.regprocedure;
BEGIN
  FOREACH v_oid IN ARRAY ARRAY[
    'public.confirmer_import_inscriptions(text,text,jsonb)'::pg_catalog.regprocedure,
    'public.reclamer_preinscription_apres_preuve()'::pg_catalog.regprocedure]
  LOOP
    EXECUTE pg_catalog.format('COMMENT ON FUNCTION %s IS %L', v_oid, pg_catalog.format(
      'F86 candidate allowlist: signature=%s; md5_functiondef=%s; guard_type=ROLE_POSITIVE_TEMPLATE; owner=postgres; search_path=""; reviewer=Claude a relire; date=2026-11-01. B2.1 : appelle la realisation des foyers importes (private.b21_*), garde inchangee.',
      v_oid::text, pg_catalog.md5(pg_catalog.pg_get_functiondef(v_oid))));
  END LOOP;
END;
$empreintes$;

-- 5. Controles ----------------------------------------------------------------

DO $postflight$
DECLARE
  v_oid pg_catalog.regprocedure;
  v_p pg_catalog.pg_proc%ROWTYPE;
  v_role text;
BEGIN
  FOREACH v_oid IN ARRAY ARRAY[
    'private.b21_realiser_preinscription(uuid,uuid)'::pg_catalog.regprocedure,
    'private.b21_realiser_import(text[])'::pg_catalog.regprocedure,
    'private.b21_profil_reprend_matricule()'::pg_catalog.regprocedure,
    'public.confirmer_import_inscriptions(text,text,jsonb)'::pg_catalog.regprocedure,
    'public.reclamer_preinscription_apres_preuve()'::pg_catalog.regprocedure]
  LOOP
    SELECT * INTO v_p FROM pg_catalog.pg_proc WHERE oid = v_oid::oid;
    IF NOT v_p.prosecdef OR pg_catalog.pg_get_userbyid(v_p.proowner) <> 'postgres'
       OR NOT coalesce(v_p.proconfig @> ARRAY['search_path=""'], false) THEN
      RAISE EXCEPTION 'B2.1 : % doit etre SECURITY DEFINER, a postgres, search_path vide', v_oid;
    END IF;
    IF pg_catalog.has_function_privilege('anon', v_oid, 'EXECUTE')
       OR pg_catalog.has_function_privilege('service_role', v_oid, 'EXECUTE') THEN
      RAISE EXCEPTION 'B2.1 : % ouverte a anon ou service_role', v_oid;
    END IF;
  END LOOP;
  FOREACH v_oid IN ARRAY ARRAY[
    'private.b21_nom(text)'::pg_catalog.regprocedure,
    'private.b21_realiser_preinscription(uuid,uuid)'::pg_catalog.regprocedure,
    'private.b21_realiser_import(text[])'::pg_catalog.regprocedure,
    'private.b21_profil_reprend_matricule()'::pg_catalog.regprocedure]
  LOOP
    IF pg_catalog.has_function_privilege('authenticated', v_oid, 'EXECUTE') THEN
      RAISE EXCEPTION 'B2.1 : % ouverte a authenticated', v_oid;
    END IF;
  END LOOP;
  IF NOT pg_catalog.has_function_privilege('authenticated',
         'public.confirmer_import_inscriptions(text,text,jsonb)', 'EXECUTE')
     OR NOT pg_catalog.has_function_privilege('authenticated',
         'public.reclamer_preinscription_apres_preuve()', 'EXECUTE') THEN
    RAISE EXCEPTION 'B2.1 : les deux RPC doivent rester ouvertes a authenticated';
  END IF;
  IF pg_catalog.strpos(pg_catalog.pg_get_functiondef(
       'public.confirmer_import_inscriptions(text,text,jsonb)'::pg_catalog.regprocedure),
       'private.b21_realiser_import(v_emails)') = 0
     OR pg_catalog.strpos(pg_catalog.pg_get_functiondef(
       'public.reclamer_preinscription_apres_preuve()'::pg_catalog.regprocedure),
       'private.b21_realiser_preinscription(v_household_id, v_uid)') = 0 THEN
    RAISE EXCEPTION 'B2.1 : point d''ancrage absent apres recompilation';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_catalog.pg_trigger t
                  WHERE t.tgrelid = 'public.profiles'::pg_catalog.regclass
                    AND t.tgname = 'profiles_a_reprendre_matricule_importe' AND NOT t.tgisinternal)
     OR 'profiles_a_reprendre_matricule_importe' >= 'profiles_assign_person_registration' COLLATE "C" THEN
    RAISE EXCEPTION 'B2.1 : declencheur absent ou mal ordonne';
  END IF;
  FOREACH v_role IN ARRAY ARRAY['anon', 'authenticated', 'service_role'] LOOP
    IF pg_catalog.has_table_privilege(v_role, 'private.preinscription_households', 'SELECT')
       OR pg_catalog.has_table_privilege(v_role, 'private.preinscription_persons', 'SELECT')
       OR pg_catalog.has_table_privilege(v_role, 'private.person_registrations', 'SELECT') THEN
      RAISE EXCEPTION 'B2.1 : % lit une table privee', v_role;
    END IF;
  END LOOP;
  IF NOT (SELECT c.relrowsecurity FROM pg_catalog.pg_class c
           WHERE c.oid = 'private.preinscription_households'::pg_catalog.regclass)
     OR NOT (SELECT c.relrowsecurity FROM pg_catalog.pg_class c
           WHERE c.oid = 'private.preinscription_persons'::pg_catalog.regclass) THEN
    RAISE EXCEPTION 'B2.1 : RLS desactivee sur une table de pre-inscription';
  END IF;
END;
$postflight$;

COMMIT;
