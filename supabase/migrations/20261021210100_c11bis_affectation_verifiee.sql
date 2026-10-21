-- C11BIS-AFFECTATION (21/10/2026, CAND-Q15, lot c11bis) : rendre possible
-- l'affectation d'un enseignant a une classe nee d'un regroupement.
-- Proposition : docs/current/CANDIDATURES/CORRECTIFS_HORS_MODULE_PROPOSES.md,
-- section 4, avec les ajustements de la section 0 bis.
--
-- Constat sur la pointe :
-- * affecter_enseignant_classe_c11bis (0079:90-131, garde reecrite par F86
--   20261012110500) levait sans condition, apres ses sorties deja_affecte et
--   classe indisponible : 'compatibilite enseignant non verifiable : source
--   titre public absente'. Les deux motifs ecrits (titre public C-05,
--   collisions C-07) sont leves depuis 0082, qui derive le titre de
--   profiles.gender et cree tc_verifier_affectation_enseignant ;
-- * L3-06 (20261017120600:19-20) a ferme affecter_enseignant_classe, seule
--   voie qui affectait. Ses commentaires (:8, :29 et le COMMENT ON FUNCTION de
--   la fonction retiree) disent _c11bis porteuse du verrou par enseignant : ce
--   n'etait vrai qu'en intention. Cette migration ne touche pas a L3-06 (deja
--   appliquee) ; elle rend ces phrases vraies. La fonction retiree reste fermee
--   et le controle final le prouve ;
-- * regroupements_c11bis_admin (20261011121958) code
--   'peut_affecter_enseignant', false en dur dans ses deux branches : :299
--   (regroupement ouvert dont la cle correspond a une classe existante) et
--   :403 (classes en attente d'enseignant).
--
-- Correction :
-- A. affecter_enseignant_classe_c11bis garde la garde F86 au mot pres (deux IF
--    successifs, meme message, SQLSTATE 42501), ses sorties deja_affecte et
--    classe indisponible, rend affecte sans rien reecrire quand le meme
--    enseignant est deja en place (rejeu apres une reponse perdue, relecture
--    du lot), puis delegue a
--    public.tc_verifier_affectation_enseignant(uuid,uuid) (piece d'identite,
--    statut, langue, genre, plafond, disponibilites, collisions par instant,
--    seances ponctuelles, verrou par enseignant R8) et affecte. Les
--    declencheurs existants font le reste : seances (0055), demandes passees a
--    enseignant_affecte (0085), eleve adulte prevenu (0078). La notification
--    du tuteur principal reprend le correctif M-b de 0075 (fuseau du foyer,
--    premiere seance future) que 0082 avait perdu.
-- B. regroupements_c11bis_admin rend la capacite calculee par le serveur, par
--    pg_get_functiondef puis replace, chaque fragment controle avant :
--    * branche :299 : la sous-requete existing ne retient plus qu'une classe
--      qui attend encore son enseignant (teacher_id nul, etat
--      en_attente_enseignant) et lit ces deux colonnes ; capacite =
--      existing.teacher_id IS NULL AND existing.etat =
--      'en_attente_enseignant'. Relecture du lot : sans ce filtre, une fois
--      l'enseignant confirme, la classe active restait rattachee aux demandes
--      encore ouvertes sur sa cle, et l'ecran la rangeait sous "Enseignant a
--      confirmer" avec deux phrases fausses (enseignant "reste a
--      confirmer", confirmation "pas ouverte"). Le client ne connait cet
--      objet que comme une classe sans enseignant (ClasseSansEnseignant).
--      Ces demandes redeviennent un regroupement ordinaire (Prete ou
--      Incomplete) : creer_classe_depuis_regroupement cree toujours une
--      nouvelle classe, parallele a l'active (R1, R16), et une classe nee
--      d'un regroupement est pleine a sa creation ;
--    * branche :403 : a.peut_affecter_enseignant de classes_a_confirmer_admin
--      (0071), vrai seulement pour une classe en attente sans enseignant.
-- Droits, empreintes F86 recalculees, controle final par to_regprocedure.
-- Aucune instruction d'effacement (ni objet retire, ni ligne effacee, ni
-- table videe) : le comptage de LECONS-MIGRATIONS-STAGING.md vaut 0. Aucune
-- donnee reprise : les classes en attente sont dans un etat valide et
-- s'affectent par l'ecran.
--
-- Ordre (section 2 de la proposition) : apres le lot langue, sinon toute
-- affectation reelle est refusee par la comparaison langue_code =
-- ANY(teacher_profiles.languages) de tc_verifier_affectation_enseignant
-- (0082:64) ; avant le lot creer_groupe.
BEGIN;

-- ------------------------------------------------------------------
-- Preflight : le predicat existe sous sa signature a deux arguments.
-- ------------------------------------------------------------------
DO $preflight$
BEGIN
  IF pg_catalog.to_regprocedure('public.tc_verifier_affectation_enseignant(uuid,uuid)') IS NULL THEN
    RAISE EXCEPTION 'C11BIS-AFFECTATION preflight : public.tc_verifier_affectation_enseignant(uuid,uuid) absente';
  END IF;
  IF pg_catalog.to_regprocedure('public.affecter_enseignant_classe_c11bis(uuid,uuid)') IS NULL
     OR pg_catalog.to_regprocedure('public.regroupements_c11bis_admin()') IS NULL
     OR pg_catalog.to_regprocedure('public.classes_a_confirmer_admin()') IS NULL THEN
    RAISE EXCEPTION 'C11BIS-AFFECTATION preflight : fonction C-11 bis absente';
  END IF;
END
$preflight$;

-- ------------------------------------------------------------------
-- A. L'affectation verifiee
-- ------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.affecter_enseignant_classe_c11bis(
  p_groupe_id uuid,
  p_teacher_profile_id uuid
)
RETURNS text
LANGUAGE plpgsql
VOLATILE
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  v_groupe public.groupes%ROWTYPE;
BEGIN
  IF NOT coalesce(
       public.app_account_valid() AND public.app_role() = 'admin',
       false
     ) THEN
    RAISE EXCEPTION 'affectation reservee a l''administration'
      USING ERRCODE = '42501';
  END IF;
  IF p_groupe_id IS NULL OR p_teacher_profile_id IS NULL THEN
    RAISE EXCEPTION 'affectation reservee a l''administration'
      USING ERRCODE = '42501';
  END IF;

  SELECT * INTO v_groupe FROM public.groupes
   WHERE id = p_groupe_id
   FOR UPDATE;
  IF NOT FOUND OR v_groupe.ended_at IS NOT NULL THEN
    RAISE EXCEPTION 'classe indisponible';
  END IF;
  IF v_groupe.teacher_id IS NOT NULL THEN
    -- Rejeu du meme choix (reponse perdue, puis nouvel appui comme l'ecran le
    -- demande) : l'enseignant demande est deja en place et les familles ont
    -- ete prevenues par le premier appel. Rien n'est reecrit, ni seance, ni
    -- audit, ni notification : 'affecte', comme la premiere fois. Un autre
    -- enseignant deja confirme : 'deja_affecte', rien ne change.
    IF v_groupe.teacher_id = p_teacher_profile_id
       AND v_groupe.etat = 'active' THEN
      RETURN 'affecte';
    END IF;
    RETURN 'deja_affecte';
  END IF;
  IF v_groupe.etat <> 'en_attente_enseignant' THEN
    RAISE EXCEPTION 'classe indisponible';
  END IF;

  -- C-04, C-05, C-07 et verrou par enseignant (R8) : leve sur refus, avant
  -- toute ecriture.
  PERFORM public.tc_verifier_affectation_enseignant(
    p_groupe_id, p_teacher_profile_id
  );

  -- Declencheurs : seances (0055), demandes classe_validee vers
  -- enseignant_affecte (0085), eleve adulte prevenu (0078).
  UPDATE public.groupes
     SET teacher_id = p_teacher_profile_id, etat = 'active'
   WHERE id = p_groupe_id;

  PERFORM public.log_sensitive_access(
    'enseignant_affecte_classe', 'groupes', p_groupe_id::text,
    pg_catalog.jsonb_build_object('teacher_id', p_teacher_profile_id)
  );

  -- Tuteur principal de chaque foyer de la classe : heure locale du foyer,
  -- premiere seance future (correctif M-b de 0075).
  INSERT INTO public.notifications
    (destinataire, foyer_id, evenement, params, destination)
  SELECT DISTINCT h.primary_guardian_id, h.id, 'enseignant_affecte',
         pg_catalog.jsonb_build_object(
           'groupe_id', p_groupe_id,
           'debut_local', pg_catalog.to_char(s.started_at AT TIME ZONE h.timezone,
                                             'YYYY-MM-DD"T"HH24:MI:SS')
         ),
         '/tuteur/demandes'
    FROM public.groupe_membres gm
    JOIN public.profiles p ON p.id = gm.student_id
    JOIN public.households h ON h.id = p.household_id
    JOIN public.sessions s ON s.groupe_id = gm.groupe_id AND s.deleted_at IS NULL
   WHERE gm.groupe_id = p_groupe_id
     AND gm.left_at IS NULL
     AND h.primary_guardian_id IS NOT NULL
     AND s.started_at = (
       SELECT pg_catalog.min(s2.started_at) FROM public.sessions s2
        WHERE s2.groupe_id = p_groupe_id AND s2.deleted_at IS NULL
          AND s2.started_at > pg_catalog.now()
     );

  RETURN 'affecte';
END;
$function$;

-- ------------------------------------------------------------------
-- B. La capacite des deux branches de regroupements_c11bis_admin
-- ------------------------------------------------------------------
DO $capacite$
DECLARE
  v_oid pg_catalog.regprocedure := 'public.regroupements_c11bis_admin()'::pg_catalog.regprocedure;
  v_definition text;
  v_avant text[];
  v_apres text[];
  v_i integer;
  v_n integer;
BEGIN
  v_definition := pg_catalog.pg_get_functiondef(v_oid);
  v_avant := ARRAY[
    -- :331-333, sous-requete existing de la branche :299
    $avant1$      SELECT g.id AS groupe_id, g.libelle, g.genre_public
        FROM public.groupes g
       WHERE g.ended_at IS NULL$avant1$,
    -- :298-299, classe d'un regroupement ouvert
    $avant2$          'genre_classe', existing.genre_public,
          'peut_affecter_enseignant', false$avant2$,
    -- :402-403, classe en attente rendue par classes_a_confirmer_admin
    $avant3$      'genre_classe', g.genre_public,
      'peut_affecter_enseignant', false$avant3$
  ];
  v_apres := ARRAY[
    $apres1$      SELECT g.id AS groupe_id, g.libelle, g.genre_public,
             g.teacher_id, g.etat
        FROM public.groupes g
       WHERE g.ended_at IS NULL
         AND g.teacher_id IS NULL
         AND g.etat = 'en_attente_enseignant'$apres1$,
    $apres2$          'genre_classe', existing.genre_public,
          'peut_affecter_enseignant',
            existing.teacher_id IS NULL
            AND existing.etat = 'en_attente_enseignant'$apres2$,
    $apres3$      'genre_classe', g.genre_public,
      'peut_affecter_enseignant', a.peut_affecter_enseignant$apres3$
  ];

  -- Chaque fragment attendu figure une fois et une seule, sinon rien n'est
  -- remplace.
  FOR v_i IN 1 .. pg_catalog.array_length(v_avant, 1) LOOP
    v_n := (pg_catalog.length(v_definition)
            - pg_catalog.length(pg_catalog.replace(v_definition, v_avant[v_i], '')))
           / pg_catalog.length(v_avant[v_i]);
    IF v_n <> 1 THEN
      RAISE EXCEPTION 'C11BIS-AFFECTATION preflight : fragment % de regroupements_c11bis_admin trouve % fois, 1 attendu', v_i, v_n;
    END IF;
  END LOOP;

  FOR v_i IN 1 .. pg_catalog.array_length(v_avant, 1) LOOP
    v_definition := pg_catalog.replace(v_definition, v_avant[v_i], v_apres[v_i]);
  END LOOP;

  IF pg_catalog.strpos(v_definition, '''peut_affecter_enseignant'', false') > 0 THEN
    RAISE EXCEPTION 'C11BIS-AFFECTATION : une capacite en dur reste dans regroupements_c11bis_admin';
  END IF;
  FOR v_i IN 1 .. pg_catalog.array_length(v_apres, 1) LOOP
    IF pg_catalog.strpos(v_definition, v_apres[v_i]) = 0 THEN
      RAISE EXCEPTION 'C11BIS-AFFECTATION : fragment % non installe dans regroupements_c11bis_admin', v_i;
    END IF;
  END LOOP;

  EXECUTE v_definition;
END
$capacite$;

-- ------------------------------------------------------------------
-- Droits, liste blanche F86
-- ------------------------------------------------------------------
ALTER FUNCTION public.affecter_enseignant_classe_c11bis(uuid, uuid) OWNER TO postgres;
REVOKE ALL ON FUNCTION public.affecter_enseignant_classe_c11bis(uuid, uuid)
  FROM PUBLIC, anon, authenticated, service_role, agent_ro;
GRANT EXECUTE ON FUNCTION public.affecter_enseignant_classe_c11bis(uuid, uuid)
  TO authenticated;

ALTER FUNCTION public.regroupements_c11bis_admin() OWNER TO postgres;
REVOKE ALL ON FUNCTION public.regroupements_c11bis_admin()
  FROM PUBLIC, anon, authenticated, service_role, agent_ro;
GRANT EXECUTE ON FUNCTION public.regroupements_c11bis_admin()
  TO authenticated;

DO $droits$
DECLARE
  v_affecter pg_catalog.regprocedure := 'public.affecter_enseignant_classe_c11bis(uuid,uuid)'::pg_catalog.regprocedure;
  v_regroupements pg_catalog.regprocedure := 'public.regroupements_c11bis_admin()'::pg_catalog.regprocedure;
BEGIN
  EXECUTE pg_catalog.format('COMMENT ON FUNCTION %s IS %L', v_affecter, pg_catalog.format(
    'F86 candidate allowlist: signature=%s; md5_functiondef=%s; guard_type=ROLE_POSITIVE_TEMPLATE; owner=postgres; search_path=""; reviewer=Claude a relire; date=2026-10-21. C11BIS-AFFECTATION. Must-pass: active admin assigns only a teacher accepted by public.tc_verifier_affectation_enseignant(uuid,uuid) (identity, status, language, gender, cap, availability, collisions, per-teacher lock) to a class waiting for its teacher, then sessions, requests and the household guardian notification follow; affecte with no new write, audit row or notification when the same teacher is already set on the active class (replay after a lost answer); deja_affecte when another teacher is already set; non-admin, inactive admin, missing-profile JWT and NULL arguments are denied by the first guards (42501).',
    'public.affecter_enseignant_classe_c11bis(uuid,uuid)',
    pg_catalog.md5(pg_catalog.pg_get_functiondef(v_affecter))));
  EXECUTE pg_catalog.format('COMMENT ON FUNCTION %s IS %L', v_regroupements, pg_catalog.format(
    'F86 candidate allowlist: signature=%s; md5_functiondef=%s; guard_type=ROLE_POSITIVE_TEMPLATE; owner=postgres; search_path=""; reviewer=Claude a relire; date=2026-10-21. C11BIS-AFFECTATION. Must-pass: requests are partitioned by UTC schedule, public, language, server-derived gender and request-level declared level; unknown attributes are returned individually as a_completer; the open-request branch attaches only a class still waiting for its teacher (no teacher, state en_attente_enseignant), so an active class is never listed as waiting; peut_affecter_enseignant is true only for a class with no teacher in state en_attente_enseignant, in both class branches.',
    'public.regroupements_c11bis_admin()',
    pg_catalog.md5(pg_catalog.pg_get_functiondef(v_regroupements))));
END
$droits$;

-- ------------------------------------------------------------------
-- Controle final
-- ------------------------------------------------------------------
DO $postflight$
DECLARE
  v_signature text;
  v_oid pg_catalog.regprocedure;
  v_p pg_catalog.pg_proc%ROWTYPE;
  v_definition text;
  v_role text;
BEGIN
  -- Les deux fonctions clientes : DEFINER, proprietaire, search_path vide,
  -- authenticated seul, empreinte exacte.
  FOREACH v_signature IN ARRAY ARRAY[
    'public.affecter_enseignant_classe_c11bis(uuid,uuid)',
    'public.regroupements_c11bis_admin()'
  ] LOOP
    v_oid := pg_catalog.to_regprocedure(v_signature);
    IF v_oid IS NULL THEN
      RAISE EXCEPTION 'C11BIS-AFFECTATION postflight : % absente', v_signature;
    END IF;
    SELECT * INTO v_p FROM pg_catalog.pg_proc WHERE oid = v_oid::oid;
    v_definition := pg_catalog.pg_get_functiondef(v_oid);
    IF NOT v_p.prosecdef
       OR pg_catalog.pg_get_userbyid(v_p.proowner) <> 'postgres'
       OR NOT coalesce(v_p.proconfig @> ARRAY['search_path=""'], false)
       OR pg_catalog.has_function_privilege('public', v_oid, 'EXECUTE')
       OR pg_catalog.has_function_privilege('anon', v_oid, 'EXECUTE')
       OR pg_catalog.has_function_privilege('service_role', v_oid, 'EXECUTE')
       OR pg_catalog.has_function_privilege('agent_ro', v_oid, 'EXECUTE')
       OR NOT pg_catalog.has_function_privilege('authenticated', v_oid, 'EXECUTE')
       OR pg_catalog.strpos(
            coalesce(pg_catalog.obj_description(v_oid::oid, 'pg_proc'), ''),
            'md5_functiondef=' || pg_catalog.md5(v_definition) || ';') = 0 THEN
      RAISE EXCEPTION 'C11BIS-AFFECTATION postflight : DEFINER, droits ou empreinte invalides pour %', v_signature;
    END IF;
  END LOOP;

  -- A : le refus inconditionnel a disparu, le predicat est appele, la garde
  -- F86 est intacte, le rejeu du meme enseignant est idempotent.
  v_definition := pg_catalog.pg_get_functiondef(
    pg_catalog.to_regprocedure('public.affecter_enseignant_classe_c11bis(uuid,uuid)'));
  IF pg_catalog.strpos(v_definition, 'compatibilite enseignant non verifiable') > 0
     OR pg_catalog.strpos(v_definition, 'public.tc_verifier_affectation_enseignant(') = 0
     OR pg_catalog.strpos(v_definition, 'public.app_account_valid() AND public.app_role() = ''admin''') = 0
     OR pg_catalog.strpos(v_definition, 'IF p_groupe_id IS NULL OR p_teacher_profile_id IS NULL THEN') = 0
     OR pg_catalog.strpos(v_definition, 'USING ERRCODE = ''42501''') = 0
     OR pg_catalog.strpos(v_definition, 'IF v_groupe.teacher_id = p_teacher_profile_id') = 0
     OR pg_catalog.strpos(v_definition, 's2.started_at > pg_catalog.now()') = 0
     OR pg_catalog.strpos(v_definition, 'AT TIME ZONE h.timezone') = 0 THEN
    RAISE EXCEPTION 'C11BIS-AFFECTATION postflight : corps de affecter_enseignant_classe_c11bis inattendu';
  END IF;

  -- B : plus aucune capacite en dur, et la branche :299 ne rattache qu'une
  -- classe qui attend son enseignant.
  v_definition := pg_catalog.pg_get_functiondef(
    pg_catalog.to_regprocedure('public.regroupements_c11bis_admin()'));
  IF pg_catalog.strpos(v_definition, '''peut_affecter_enseignant'', false') > 0
     OR pg_catalog.strpos(v_definition, 'existing.etat = ''en_attente_enseignant''') = 0
     OR pg_catalog.strpos(v_definition, E'WHERE g.ended_at IS NULL\n         AND g.teacher_id IS NULL\n         AND g.etat = ''en_attente_enseignant''') = 0
     OR pg_catalog.strpos(v_definition, 'a.peut_affecter_enseignant') = 0 THEN
    RAISE EXCEPTION 'C11BIS-AFFECTATION postflight : capacite de regroupements_c11bis_admin non calculee';
  END IF;

  -- Le predicat reste interne : aucun client ne l'appelle directement.
  v_oid := pg_catalog.to_regprocedure('public.tc_verifier_affectation_enseignant(uuid,uuid)');
  IF v_oid IS NULL
     OR pg_catalog.has_function_privilege('anon', v_oid, 'EXECUTE')
     OR pg_catalog.has_function_privilege('authenticated', v_oid, 'EXECUTE')
     OR pg_catalog.has_function_privilege('agent_ro', v_oid, 'EXECUTE') THEN
    RAISE EXCEPTION 'C11BIS-AFFECTATION postflight : predicat absent ou ouvert a un client';
  END IF;

  -- L3-06 tient : la fonction retiree n'est executable par personne.
  v_oid := pg_catalog.to_regprocedure('public.affecter_enseignant_classe(uuid,uuid)');
  IF v_oid IS NOT NULL THEN
    FOREACH v_role IN ARRAY ARRAY['public', 'anon', 'authenticated', 'service_role', 'agent_ro'] LOOP
      IF pg_catalog.has_function_privilege(v_role, v_oid, 'EXECUTE') THEN
        RAISE EXCEPTION 'C11BIS-AFFECTATION postflight : affecter_enseignant_classe(uuid,uuid) executable par %', v_role;
      END IF;
    END LOOP;
  END IF;
END
$postflight$;

COMMIT;
