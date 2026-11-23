-- AUDIT-FAMILLE-8 (directeur, 22/11/2026) : deux enfants d'un meme foyer ne sont jamais dans la meme classe.
-- L'ecran final de l'inscription le promet (« chacun aura sa classe et son enseignant », ONBOARDING-PRAXIS D7) ;
-- rien dans le serveur ne le tenait.
--
-- private.fratrie_verifier(classe, eleve) : si un membre ACTIF de la classe est du meme foyer que l'eleve et que les
-- deux sont des enfants (student_profiles.student_type = minor), l'operation est refusee avec un message nomme :
-- « deux enfants du meme foyer : jamais dans la meme classe ». Un adulte qui suit des cours (le titulaire) peut
-- partager la classe d'un enfant de son foyer : la regle vise les enfants. Les classes DEJA formees ne sont pas
-- touchees.
-- Appelee par les deux seuls chemins qui inscrivent un eleve dans une classe (remplacement par ancres, chacune
-- trouvee une fois, sinon la migration s'arrete) :
--   * ajouter_eleve_groupe (la direction ajoute un eleve) : refus nomme a l'ajout ;
--   * creer_classe_depuis_regroupement (« Creer la classe ») : si deux freres font partie des premiers eleves du
--     regroupement, la creation est refusee tout entiere, rien n'est cree ; la direction doit alors les separer.
-- Un declencheur sur la table aurait aussi attrape les fixtures de seize scenarios de CI et tout futur import : la
-- regle est donc posee aux deux portes de la direction, pas sur la table.
--
-- MOTS D'EFFACEMENT : ZERO. Une fonction privee neuve ; deux fonctions publiques retouchees (signature, proprietaire,
-- droits et search_path gardes, verifies). Sans BEGIN ni COMMIT de premier niveau. Rejouable.

DO $preflight$
BEGIN
  IF pg_catalog.to_regprocedure('public.ajouter_eleve_groupe(uuid,uuid,text)') IS NULL
     OR pg_catalog.to_regprocedure('public.creer_classe_depuis_regroupement(uuid,uuid,text)') IS NULL THEN
    RAISE EXCEPTION 'AUDIT-FAMILLE-8 : ajouter_eleve_groupe ou creer_classe_depuis_regroupement manque';
  END IF;
END
$preflight$;

CREATE OR REPLACE FUNCTION private.fratrie_verifier(p_groupe uuid, p_eleve uuid)
RETURNS void
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $function$
BEGIN
  IF EXISTS (
       SELECT 1
         FROM public.profiles moi
         JOIN public.student_profiles spm ON spm.profile_id = moi.id AND spm.deleted_at IS NULL
         JOIN public.groupe_membres gm ON gm.groupe_id = p_groupe AND gm.left_at IS NULL
                                      AND gm.student_id <> p_eleve
         JOIN public.profiles autre ON autre.id = gm.student_id AND autre.deleted_at IS NULL
         JOIN public.student_profiles spa ON spa.profile_id = autre.id AND spa.deleted_at IS NULL
        WHERE moi.id = p_eleve
          AND moi.household_id IS NOT NULL
          AND autre.household_id = moi.household_id
          AND spm.student_type = 'minor'
          AND spa.student_type = 'minor') THEN
    RAISE EXCEPTION 'deux enfants du meme foyer : jamais dans la meme classe'
      USING ERRCODE = 'P0001',
            HINT = 'Choisissez une autre classe pour cet enfant, ou separez les enfants du foyer.';
  END IF;
END;
$function$;

REVOKE ALL ON FUNCTION private.fratrie_verifier(uuid, uuid) FROM PUBLIC, anon, authenticated, service_role;
DO $agent_ro$
BEGIN
  IF EXISTS (SELECT 1 FROM pg_catalog.pg_roles WHERE rolname = 'agent_ro') THEN
    EXECUTE 'REVOKE ALL ON FUNCTION private.fratrie_verifier(uuid, uuid) FROM agent_ro';
  END IF;
END
$agent_ro$;
COMMENT ON FUNCTION private.fratrie_verifier(uuid, uuid) IS
  'AUDIT-FAMILLE-8 (22/11/2026) : refuse l''entree dans une classe d''un enfant dont un frere ou une soeur (meme foyer, enfant) en est deja membre actif. Appelee par ajouter_eleve_groupe et creer_classe_depuis_regroupement.';

CREATE FUNCTION pg_temp.remplacer(p_f regprocedure, p_ancres text[], p_nouvelles text[])
RETURNS void LANGUAGE plpgsql AS $r$
DECLARE
  v_def text := pg_catalog.pg_get_functiondef(p_f);
  v_apres text;
  v_n integer;
  v_com text;
  v_avant record;
  i integer;
BEGIN
  SELECT p.prosecdef, p.proowner, p.proconfig, p.proacl INTO v_avant
    FROM pg_catalog.pg_proc p WHERE p.oid = p_f;
  v_apres := v_def;
  FOR i IN 1 .. pg_catalog.cardinality(p_ancres) LOOP
    v_n := (pg_catalog.length(v_apres) - pg_catalog.length(pg_catalog.replace(v_apres, p_ancres[i], '')))
           / pg_catalog.length(p_ancres[i]);
    IF v_n <> 1 THEN
      RAISE EXCEPTION 'AUDIT-FAMILLE-8 : ancre trouvee % fois (attendu 1) dans % : %', v_n, p_f, p_ancres[i];
    END IF;
    v_apres := pg_catalog.replace(v_apres, p_ancres[i], p_nouvelles[i]);
  END LOOP;
  EXECUTE v_apres;
  v_com := pg_catalog.obj_description(p_f, 'pg_proc');
  IF v_com LIKE '%md5_functiondef=%' THEN
    v_com := pg_catalog.regexp_replace(v_com, 'md5_functiondef=[0-9A-Za-z_]+',
      'md5_functiondef=' || pg_catalog.md5(pg_catalog.pg_get_functiondef(p_f)));
    EXECUTE pg_catalog.format('COMMENT ON FUNCTION %s IS %L', p_f, v_com);
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_catalog.pg_proc p
                  WHERE p.oid = p_f AND p.prosecdef = v_avant.prosecdef
                    AND p.proowner = v_avant.proowner
                    AND p.proconfig IS NOT DISTINCT FROM v_avant.proconfig
                    AND p.proacl IS NOT DISTINCT FROM v_avant.proacl) THEN
    RAISE EXCEPTION 'AUDIT-FAMILLE-8 : proprietaire, SECURITY DEFINER, search_path ou droits modifies pour %', p_f;
  END IF;
END
$r$;

DO $migration$
BEGIN
  IF pg_catalog.strpos(pg_catalog.pg_get_functiondef('public.ajouter_eleve_groupe(uuid,uuid,text)'::regprocedure),
                       'fratrie_verifier') > 0 THEN
    RAISE NOTICE 'AUDIT-FAMILLE-8 : deja installee, rien a faire';
    RETURN;
  END IF;

  PERFORM pg_temp.remplacer('public.ajouter_eleve_groupe(uuid,uuid,text)'::regprocedure,
    ARRAY['  insert into public.groupe_membres (groupe_id, student_id)
  values (p_groupe_id, p_student_profile_id);'],
    ARRAY['  perform private.fratrie_verifier(p_groupe_id, p_student_profile_id);

  insert into public.groupe_membres (groupe_id, student_id)
  values (p_groupe_id, p_student_profile_id);']);

  PERFORM pg_temp.remplacer('public.creer_classe_depuis_regroupement(uuid,uuid,text)'::regprocedure,
    ARRAY['    INSERT INTO public.groupe_membres (groupe_id, student_id)
    VALUES (v_groupe, v_student);'],
    ARRAY['    PERFORM private.fratrie_verifier(v_groupe, v_student);
    INSERT INTO public.groupe_membres (groupe_id, student_id)
    VALUES (v_groupe, v_student);']);

  RAISE NOTICE 'AUDIT-FAMILLE-8 : installee';
END
$migration$;

DO $postflight$
BEGIN
  IF pg_catalog.has_function_privilege('authenticated', 'private.fratrie_verifier(uuid,uuid)', 'EXECUTE')
     OR pg_catalog.has_function_privilege('anon', 'private.fratrie_verifier(uuid,uuid)', 'EXECUTE') THEN
    RAISE EXCEPTION 'AUDIT-FAMILLE-8 : fratrie_verifier est executable par un client';
  END IF;
  IF pg_catalog.strpos(pg_catalog.pg_get_functiondef('public.ajouter_eleve_groupe(uuid,uuid,text)'::regprocedure), 'fratrie_verifier') = 0
     OR pg_catalog.strpos(pg_catalog.pg_get_functiondef('public.creer_classe_depuis_regroupement(uuid,uuid,text)'::regprocedure), 'fratrie_verifier') = 0 THEN
    RAISE EXCEPTION 'AUDIT-FAMILLE-8 : une des deux portes n''appelle pas la verification';
  END IF;
  IF NOT pg_catalog.has_function_privilege('authenticated', 'public.ajouter_eleve_groupe(uuid,uuid,text)', 'EXECUTE')
     OR pg_catalog.has_function_privilege('anon', 'public.ajouter_eleve_groupe(uuid,uuid,text)', 'EXECUTE')
     OR pg_catalog.has_function_privilege('anon', 'public.creer_classe_depuis_regroupement(uuid,uuid,text)', 'EXECUTE') THEN
    RAISE EXCEPTION 'AUDIT-FAMILLE-8 : droits inattendus';
  END IF;
END
$postflight$;
