-- CAND-Q15, lot creer_groupe (21/10/2026) : un seul predicat pour poser un
-- enseignant sur une classe.
--
-- Defaut (CANDIDATURES/CORRECTIFS_HORS_MODULE_PROPOSES.md, section 5) :
-- creer_groupe a 8 arguments (0045:9-68, garde reecrite par 0067) inserait une
-- classe ACTIVE avec son enseignant sans passer par le predicat C-04/C-07 de
-- 0082 (tc_verifier_affectation_enseignant). Ni piece d'identite validee, ni
-- date d'acces, ni profil enseignant, ni genre, ni plafond hebdomadaire, ni
-- collisions, ni verrou par enseignant ; le declencheur de 0055 materialisait
-- aussitot les seances au nom de cet enseignant. C'etait le seul chemin vivant
-- qui ecrit groupes.teacher_id (CF1-B6 de UX_REVIEW_CLASSE-FORM-1.md jamais
-- ecrit cote serveur ; la garde par declencheur de affa5756 a ete annulee par
-- 4bb32056, etat que porte 0082:240-241).
--
-- Decision du directeur (recommandation CAND-Q15 validee le 21/10) : controle
-- strict sauf les disponibilites. Bloquent : compte, piece validee, date
-- d'acces, profil enseignant present, genre connu et compatible, plafond,
-- collisions (classes, affectations, seances ponctuelles). La couverture par
-- les disponibilites declarees reste un avertissement a l'ecran (D4).
--
-- Variante retenue par la recherche dans les branches (section 0 bis) :
-- * le corps du predicat passe dans app_private.verifier_affectation_enseignant
--   (uuid, uuid, boolean), recopie de 0082:23-234 a une difference pres : la
--   boucle de couverture des disponibilites (0082:126-163) ne tourne que si le
--   drapeau vaut true (NULL vaut true). Commentaires remis en ASCII, fonctions
--   du catalogue qualifiees ; messages leves inchanges, au caractere pres.
--   INVOKER et aucun EXECUTE client, comme app_private.deplacer_membre_classe :
--   seuls des DEFINER de proprietaire postgres l'appellent, apres leur garde ;
-- * public.tc_verifier_affectation_enseignant(uuid, uuid) garde sa signature,
--   ses attributs et ses droits, et devient un appel d'une ligne avec true :
--   affecter_enseignant_classe (0082:282), enseignants_pour_classe (0083:117)
--   et le lot c11bis gardent le comportement strict, disponibilites comprises ;
-- * creer_groupe garde signature, defauts, garde, controles d'entree, journal
--   et valeur rendue. La classe nait 'en_attente_enseignant' sans enseignant
--   (groupes_enseignant_etat_coherent), le predicat tourne avec false, puis la
--   meme mise a jour que 0082:286-288 la passe 'active' : aucune seance n'existe
--   avant le controle (0055:1-2), et un refus annule tout.
--
-- Droits (F86) : creer_groupe reste executable par authenticated seulement
-- (service_role retire : la garde positive le refusait deja, app_role() nul) ;
-- empreinte md5 posee en commentaire et verifiee au controle final. Le
-- predicat public n'est executable par aucun client ; l'interne par personne.
-- Aucune signature publique ajoutee ni retiree : la liste blanche des
-- fonctions volatiles ne change pas.
--
-- Hors lot : modifier_groupe peut encore deplacer une classe active vers une
-- collision (seconde moitie de CF1-B6, lot a part, meme appel apres sa mise a
-- jour) ; CF1-B1 (p_genre_public) n'existe pas, une classe creee ici est donc
-- 'indetermine' et la regle de genre se reduit a "genre de l'enseignant
-- connu". Application a distance seulement apres toute la chaine 0043 a
-- 20261019130000 (etat, genre_public, 0082, app_private).
BEGIN;

-- ------------------------------------------------------------------
-- 1. Le predicat, avec son drapeau de disponibilites
-- ------------------------------------------------------------------
CREATE FUNCTION app_private.verifier_affectation_enseignant(
  p_groupe_id uuid,
  p_teacher_id uuid,
  p_exiger_disponibilites boolean
)
RETURNS void
LANGUAGE plpgsql
VOLATILE
SECURITY INVOKER
SET search_path = ''
AS $function$
DECLARE
  v_g public.groupes%ROWTYPE;
  v_gender public.gender;
  v_cap int;
  v_duree int;
  v_charge numeric;
  v_c record;
  v_busy record;
  v_w int;
  v_aw int;
  v_debut timestamptz;
  v_busy_debut timestamptz;
  v_trouve boolean;
BEGIN
  IF p_groupe_id IS NULL OR p_teacher_id IS NULL THEN
    RAISE EXCEPTION 'classe ou enseignant absent';
  END IF;

  SELECT * INTO v_g
  FROM public.groupes
  WHERE id = p_groupe_id AND ended_at IS NULL
  FOR UPDATE;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'classe indisponible';
  END IF;

  -- Serialise deux tentatives concurrentes d'affecter le meme enseignant.
  PERFORM pg_catalog.pg_advisory_xact_lock(
    pg_catalog.hashtextextended('teacher-schedule:' || p_teacher_id::text, 0)
  );

  SELECT p.gender INTO v_gender
  FROM public.profiles p
  JOIN public.teacher_profiles tp ON tp.profile_id = p.id
  WHERE p.id = p_teacher_id
    AND p.role = 'teacher'
    AND p.deleted_at IS NULL
    AND p.account_status IN ('active', 'provisional_active')
    AND (p.access_until IS NULL OR p.access_until > pg_catalog.now())
    AND tp.deleted_at IS NULL
    AND tp.kyc_status = 'approved'
    AND (v_g.langue_code IS NULL OR v_g.langue_code = ANY(tp.languages));
  IF NOT FOUND OR v_gender IS NULL THEN
    RAISE EXCEPTION 'enseignant indisponible ou genre inconnu';
  END IF;

  IF v_g.genre_public IS NULL
     OR v_g.genre_public NOT IN ('hommes', 'femmes', 'indetermine')
     OR (v_g.genre_public = 'hommes' AND v_gender <> 'male')
     OR (v_g.genre_public = 'femmes' AND v_gender <> 'female') THEN
    RAISE EXCEPTION 'enseignant incompatible avec le public de la classe';
  END IF;

  v_duree := public.app_config_int('session_duration_minutes', 60);
  SELECT tp.weekly_hours_cap INTO v_cap
  FROM public.teacher_profiles tp
  WHERE tp.profile_id = p_teacher_id;

  SELECT
    (
      SELECT pg_catalog.count(*) FROM (
        SELECT DISTINCT g.id, gs.weekday, gs.hour_local
        FROM public.groupes g
        CROSS JOIN LATERAL (
          SELECT g.weekday, g.hour_local
          UNION
          SELECT gc.weekday, gc.hour_local
          FROM public.groupe_creneaux gc
          WHERE gc.groupe_id = g.id
        ) gs
        WHERE g.teacher_id = p_teacher_id
          AND g.ended_at IS NULL AND g.etat = 'active'
          AND g.id <> p_groupe_id
      ) active_groups
    )
    +
    (
      SELECT pg_catalog.count(*)
      FROM public.teacher_student_assignments tsa
      JOIN public.weekly_availability wa ON wa.profile_id = tsa.student_id
      WHERE tsa.teacher_id = p_teacher_id AND tsa.ended_at IS NULL
    )
    +
    (
      SELECT pg_catalog.count(*) FROM (
        SELECT DISTINCT gs.weekday, gs.hour_local
        FROM public.groupes target
        CROSS JOIN LATERAL (
          SELECT target.weekday, target.hour_local
          UNION
          SELECT gc.weekday, gc.hour_local
          FROM public.groupe_creneaux gc
          WHERE gc.groupe_id = target.id
        ) gs
        WHERE target.id = p_groupe_id
      ) target_slots
    )
  INTO v_charge;

  IF v_cap IS NULL OR v_charge * v_duree / 60.0 > v_cap THEN
    RAISE EXCEPTION 'plafond horaire enseignant dépassé';
  END IF;

  -- Couverture par les disponibilites declarees : chaque occurrence de la
  -- classe, y compris avant et apres les changements saisonniers. Exigee
  -- sauf quand l'appelant passe false (creer_groupe : D4 et CAND-Q15, la
  -- couverture n'est qu'un avertissement a l'ecran). NULL vaut true.
  IF coalesce(p_exiger_disponibilites, true) THEN
    FOR v_c IN
      SELECT DISTINCT slots.weekday, slots.hour_local, v_g.timezone_iana
      FROM (
        SELECT v_g.weekday AS weekday, v_g.hour_local AS hour_local
        UNION
        SELECT gc.weekday, gc.hour_local
        FROM public.groupe_creneaux gc
        WHERE gc.groupe_id = p_groupe_id
      ) slots
    LOOP
      FOR v_w IN 0..51 LOOP
        v_debut := public.instant_creneau(v_c.weekday, v_c.hour_local, v_c.timezone_iana, v_w);
        v_trouve := false;
        FOR v_busy IN
          SELECT wa.weekday, wa.hour_local, wa.timezone_iana
          FROM public.weekly_availability wa
          WHERE wa.profile_id = p_teacher_id
        LOOP
          FOR v_aw IN greatest(0, v_w - 1)..least(52, v_w + 1) LOOP
            v_busy_debut := public.instant_creneau(
              v_busy.weekday, v_busy.hour_local, v_busy.timezone_iana, v_aw
            );
            IF v_busy_debut <= v_debut
               AND v_busy_debut + interval '1 hour' >= v_debut + pg_catalog.make_interval(mins => v_duree) THEN
              v_trouve := true;
              EXIT;
            END IF;
          END LOOP;
          EXIT WHEN v_trouve;
        END LOOP;
        IF NOT v_trouve THEN
          RAISE EXCEPTION 'enseignant non disponible: jour %, heure %, fuseau %, semaine %, instant %',
            v_c.weekday, v_c.hour_local, v_c.timezone_iana, v_w, v_debut;
        END IF;
      END LOOP;
    END LOOP;
  END IF;

  -- C-07 : les creneaux principaux et secondaires des classes actives,
  -- les affectations individuelles recurrentes et les seances ponctuelles
  -- sont comparees comme des instants, pas comme des heures locales.
  FOR v_c IN
    SELECT DISTINCT slots.weekday, slots.hour_local, v_g.timezone_iana
    FROM (
      SELECT v_g.weekday AS weekday, v_g.hour_local AS hour_local
      UNION
      SELECT gc.weekday, gc.hour_local
      FROM public.groupe_creneaux gc
      WHERE gc.groupe_id = p_groupe_id
    ) slots
  LOOP
    FOR v_busy IN
      SELECT DISTINCT busy.weekday, busy.hour_local, busy.timezone_iana
      FROM (
        SELECT slots.weekday, slots.hour_local, g.timezone_iana
        FROM public.groupes g
        CROSS JOIN LATERAL (
          SELECT g.weekday, g.hour_local
          UNION
          SELECT gc.weekday, gc.hour_local
          FROM public.groupe_creneaux gc
          WHERE gc.groupe_id = g.id
        ) slots
        WHERE g.teacher_id = p_teacher_id
          AND g.ended_at IS NULL AND g.etat = 'active'
          AND g.id <> p_groupe_id
        UNION
        SELECT wa.weekday, wa.hour_local, wa.timezone_iana
        FROM public.teacher_student_assignments tsa
        JOIN public.weekly_availability wa ON wa.profile_id = tsa.student_id
        WHERE tsa.teacher_id = p_teacher_id AND tsa.ended_at IS NULL
      ) busy
    LOOP
      FOR v_w IN 0..51 LOOP
        v_debut := public.instant_creneau(v_c.weekday, v_c.hour_local, v_c.timezone_iana, v_w);
        FOR v_aw IN greatest(0, v_w - 1)..least(52, v_w + 1) LOOP
          v_busy_debut := public.instant_creneau(
            v_busy.weekday, v_busy.hour_local, v_busy.timezone_iana, v_aw
          );
          IF v_debut < v_busy_debut + pg_catalog.make_interval(mins => v_duree)
             AND v_busy_debut < v_debut + pg_catalog.make_interval(mins => v_duree) THEN
            RAISE EXCEPTION 'chevauchement avec une classe ou affectation active';
          END IF;
        END LOOP;
      END LOOP;
    END LOOP;
  END LOOP;

  IF EXISTS (
    SELECT 1
    FROM public.sessions s
    CROSS JOIN LATERAL pg_catalog.generate_series(0, 51) AS w(n)
    CROSS JOIN LATERAL (
      SELECT public.instant_creneau(v_g.weekday, v_g.hour_local, v_g.timezone_iana, w.n) AS starts_at
      UNION
      SELECT public.instant_creneau(gc.weekday, gc.hour_local, v_g.timezone_iana, w.n)
      FROM public.groupe_creneaux gc WHERE gc.groupe_id = p_groupe_id
    ) target
    WHERE s.teacher_id = p_teacher_id
      AND s.groupe_id IS NULL
      AND s.deleted_at IS NULL
      AND s.status NOT IN ('canceled')
      AND target.starts_at < s.ended_at
      AND s.started_at < target.starts_at + pg_catalog.make_interval(mins => v_duree)
  ) THEN
    RAISE EXCEPTION 'chevauchement avec une séance existante';
  END IF;
END;
$function$;

ALTER FUNCTION app_private.verifier_affectation_enseignant(uuid, uuid, boolean)
  OWNER TO postgres;
REVOKE ALL ON FUNCTION app_private.verifier_affectation_enseignant(uuid, uuid, boolean)
  FROM PUBLIC, anon, authenticated, service_role, agent_ro;
COMMENT ON FUNCTION app_private.verifier_affectation_enseignant(uuid, uuid, boolean) IS
  'CAND-Q15 : predicat C-04/C-07 de 0082 (compte, piece validee, acces, langue, genre, plafond, collisions, verrou par enseignant). p_exiger_disponibilites : couverture par weekly_availability exigee si true ou NULL ; false pour creer_groupe (D4). INVOKER, aucun EXECUTE client.';

-- ------------------------------------------------------------------
-- 2. Le predicat public : meme signature, memes attributs, memes droits
-- ------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.tc_verifier_affectation_enseignant(
  p_groupe_id uuid,
  p_teacher_id uuid
)
RETURNS void
LANGUAGE plpgsql
VOLATILE
SECURITY DEFINER
SET search_path = ''
AS $function$
BEGIN
  -- Affectation d'une classe en attente : les disponibilites sont exigees.
  PERFORM app_private.verifier_affectation_enseignant(p_groupe_id, p_teacher_id, true);
END;
$function$;

ALTER FUNCTION public.tc_verifier_affectation_enseignant(uuid, uuid) OWNER TO postgres;
REVOKE ALL ON FUNCTION public.tc_verifier_affectation_enseignant(uuid, uuid)
  FROM PUBLIC, anon, authenticated, agent_ro;

-- ------------------------------------------------------------------
-- 3. creer_groupe : meme signature, memes defauts (0045:10)
-- ------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.creer_groupe(p_teacher_profile_id uuid, p_type_public text, p_libelle text, p_weekday smallint, p_hour_local smallint, p_seuil_max smallint, p_timezone_iana text, p_couleur_jeton smallint DEFAULT NULL::smallint)
 RETURNS uuid
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare
  v_id uuid;
  v_seuil smallint;
begin
  if not coalesce(public.app_role() = 'admin' and public.app_account_valid(), false) then
    raise exception 'creation de groupe reservee a l''administration';
  end if;

  if not exists (
    select 1 from public.profiles p
    where p.id = p_teacher_profile_id
      and p.role = 'teacher'
      and p.deleted_at is null
      and p.account_status in ('active', 'provisional_active')
  ) then
    raise exception 'cet enseignant n''existe pas ou son compte n''est pas valide';
  end if;

  if p_timezone_iana is not null then
    perform 1 from pg_catalog.pg_timezone_names where name = p_timezone_iana;
    if not found then
      raise exception 'fuseau IANA inconnu : %', p_timezone_iana;
    end if;
  end if;

  v_seuil := coalesce(
    p_seuil_max,
    case p_type_public
      when 'enfant' then 5
      when 'adulte' then 6
      else null
    end
  );

  if v_seuil is null then
    raise exception 'type de public inconnu : %', p_type_public;
  end if;

  -- CAND-Q15 : la classe nait en attente, sans enseignant ; aucune seance
  -- n'est materialisee avant le predicat (0055:1-2).
  insert into public.groupes
    (teacher_id, etat, type_public, seuil_max, libelle, weekday, hour_local, timezone_iana, couleur_jeton)
  values
    (null, 'en_attente_enseignant', p_type_public, v_seuil, p_libelle, p_weekday, p_hour_local,
     coalesce(p_timezone_iana, 'Europe/Paris'), p_couleur_jeton)
  returning id into v_id;

  -- Controle strict sauf les disponibilites (decision CAND-Q15, D4) : leve sur
  -- refus, et la transaction de l'appel annule la classe.
  perform app_private.verifier_affectation_enseignant(v_id, p_teacher_profile_id, false);

  -- Meme transition que 0082:286-288 ; le declencheur de 0055 materialise.
  update public.groupes
     set teacher_id = p_teacher_profile_id, etat = 'active'
   where id = v_id;

  perform public.log_sensitive_access(
    'groupe_cree', 'groupes', v_id::text,
    pg_catalog.jsonb_build_object('teacher_id', p_teacher_profile_id, 'type_public', p_type_public, 'seuil_max', v_seuil)
  );

  return v_id;
end;
$function$;

ALTER FUNCTION public.creer_groupe(uuid, text, text, smallint, smallint, smallint, text, smallint)
  OWNER TO postgres;
REVOKE ALL ON FUNCTION public.creer_groupe(uuid, text, text, smallint, smallint, smallint, text, smallint)
  FROM PUBLIC, anon, authenticated, service_role, agent_ro;
GRANT EXECUTE ON FUNCTION public.creer_groupe(uuid, text, text, smallint, smallint, smallint, text, smallint)
  TO authenticated;

DO $droits$
DECLARE
  v_oid regprocedure := 'public.creer_groupe(uuid,text,text,smallint,smallint,smallint,text,smallint)'::regprocedure;
BEGIN
  EXECUTE pg_catalog.format('COMMENT ON FUNCTION %s IS %L', v_oid, pg_catalog.format(
    'F86 candidate allowlist: signature=%s; md5_functiondef=%s; guard_type=ROLE_POSITIVE_ADMIN; owner=postgres; search_path=""; reviewer=Claude a relire; date=2026-10-21. CAND-Q15 lot creer_groupe : PortCreationClasse.creer par ServiceGroupes.creer. Garde: direction active. La classe nait en attente, app_private.verifier_affectation_enseignant(..., false) controle l''enseignant (strict sauf disponibilites), puis la classe passe active.',
    v_oid::text, pg_catalog.md5(pg_catalog.pg_get_functiondef(v_oid))));
END;
$droits$;

-- ------------------------------------------------------------------
-- 4. Controle final
-- ------------------------------------------------------------------
DO $postflight$
DECLARE
  v_interne regprocedure := pg_catalog.to_regprocedure(
    'app_private.verifier_affectation_enseignant(uuid,uuid,boolean)');
  v_public regprocedure := pg_catalog.to_regprocedure(
    'public.tc_verifier_affectation_enseignant(uuid,uuid)');
  v_creer regprocedure := pg_catalog.to_regprocedure(
    'public.creer_groupe(uuid,text,text,smallint,smallint,smallint,text,smallint)');
  v_p pg_catalog.pg_proc%ROWTYPE;
  v_role text;
BEGIN
  IF v_interne IS NULL OR v_public IS NULL OR v_creer IS NULL THEN
    RAISE EXCEPTION 'CAND-Q15 creer_groupe : signature absente (interne %, public %, creer %)',
      v_interne, v_public, v_creer;
  END IF;
  -- Aucune surcharge du predicat public : un appel a deux arguments reste sans ambiguite.
  IF (SELECT pg_catalog.count(*) FROM pg_catalog.pg_proc p
       JOIN pg_catalog.pg_namespace n ON n.oid = p.pronamespace
      WHERE n.nspname = 'public' AND p.proname = 'tc_verifier_affectation_enseignant') <> 1 THEN
    RAISE EXCEPTION 'CAND-Q15 creer_groupe : surcharge inattendue de tc_verifier_affectation_enseignant';
  END IF;

  -- Le predicat interne : INVOKER, postgres, search_path vide, aucun EXECUTE.
  SELECT * INTO v_p FROM pg_catalog.pg_proc WHERE oid = v_interne::oid;
  IF v_p.prosecdef OR v_p.provolatile <> 'v'
     OR pg_catalog.pg_get_userbyid(v_p.proowner) <> 'postgres'
     OR NOT coalesce(v_p.proconfig @> ARRAY['search_path=""'], false)
     OR pg_catalog.strpos(v_p.prosrc, 'IF coalesce(p_exiger_disponibilites, true) THEN') = 0
     OR pg_catalog.strpos(v_p.prosrc, 'enseignant non disponible: jour') = 0
     OR pg_catalog.strpos(v_p.prosrc, 'chevauchement avec une classe ou affectation active') = 0 THEN
    RAISE EXCEPTION 'CAND-Q15 creer_groupe : predicat interne invalide';
  END IF;
  FOREACH v_role IN ARRAY ARRAY['anon', 'authenticated', 'service_role', 'agent_ro'] LOOP
    IF pg_catalog.has_function_privilege(v_role, v_interne, 'EXECUTE') THEN
      RAISE EXCEPTION 'CAND-Q15 creer_groupe : % peut executer le predicat interne', v_role;
    END IF;
  END LOOP;

  -- Le predicat public : DEFINER, delegue avec true, ferme aux clients.
  SELECT * INTO v_p FROM pg_catalog.pg_proc WHERE oid = v_public::oid;
  IF NOT v_p.prosecdef OR v_p.provolatile <> 'v'
     OR pg_catalog.pg_get_userbyid(v_p.proowner) <> 'postgres'
     OR NOT coalesce(v_p.proconfig @> ARRAY['search_path=""'], false)
     OR pg_catalog.strpos(v_p.prosrc,
          'app_private.verifier_affectation_enseignant(p_groupe_id, p_teacher_id, true)') = 0 THEN
    RAISE EXCEPTION 'CAND-Q15 creer_groupe : predicat public invalide';
  END IF;
  FOREACH v_role IN ARRAY ARRAY['anon', 'authenticated', 'agent_ro'] LOOP
    IF pg_catalog.has_function_privilege(v_role, v_public, 'EXECUTE') THEN
      RAISE EXCEPTION 'CAND-Q15 creer_groupe : % peut executer tc_verifier_affectation_enseignant', v_role;
    END IF;
  END LOOP;

  -- creer_groupe : DEFINER, garde positive, naissance en attente, predicat
  -- sans disponibilites, droits et empreinte F86.
  SELECT * INTO v_p FROM pg_catalog.pg_proc WHERE oid = v_creer::oid;
  IF NOT v_p.prosecdef
     OR pg_catalog.pg_get_userbyid(v_p.proowner) <> 'postgres'
     OR NOT coalesce(v_p.proconfig @> ARRAY['search_path=""'], false)
     OR pg_catalog.strpos(v_p.prosrc,
          'if not coalesce(public.app_role() = ''admin'' and public.app_account_valid(), false) then') = 0
     OR pg_catalog.strpos(v_p.prosrc, '(null, ''en_attente_enseignant'',') = 0
     OR pg_catalog.strpos(v_p.prosrc,
          'app_private.verifier_affectation_enseignant(v_id, p_teacher_profile_id, false)') = 0
     OR pg_catalog.strpos(v_p.prosrc, 'set teacher_id = p_teacher_profile_id, etat = ''active''') = 0 THEN
    RAISE EXCEPTION 'CAND-Q15 creer_groupe : corps de creer_groupe invalide';
  END IF;
  IF NOT pg_catalog.has_function_privilege('authenticated', v_creer, 'EXECUTE')
     OR pg_catalog.has_function_privilege('anon', v_creer, 'EXECUTE')
     OR pg_catalog.has_function_privilege('service_role', v_creer, 'EXECUTE')
     OR pg_catalog.has_function_privilege('agent_ro', v_creer, 'EXECUTE') THEN
    RAISE EXCEPTION 'CAND-Q15 creer_groupe : droits EXECUTE de creer_groupe invalides';
  END IF;
  IF coalesce(pg_catalog.obj_description(v_creer::oid, 'pg_proc'), '') NOT LIKE
       '%md5_functiondef=' || pg_catalog.md5(pg_catalog.pg_get_functiondef(v_creer)) || '%' THEN
    RAISE EXCEPTION 'CAND-Q15 creer_groupe : empreinte F86 de creer_groupe absente ou perimee';
  END IF;
END;
$postflight$;

COMMIT;
