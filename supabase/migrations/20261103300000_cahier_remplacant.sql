-- CAHIER-REMPLACANT (31/10/2026) : quand une seance est confiee a un
-- remplacant, c'est lui qui depose le cahier de cette seance.
--
-- DELETE / DROP / TRUNCATE : 0. Une fonction creee (CREATE OR REPLACE), trois
-- fonctions remplacees a signature egale (CREATE OR REPLACE), deux politiques
-- modifiees (ALTER POLICY), droits, commentaires, verifications.
--
-- Le defaut (prouve en local le 31/10) : trois portes ne lisaient que
-- `sessions.teacher_id`, le titulaire, et refusaient donc le remplacant :
--   * la politique `lesson_reports_teacher_write` (WITH CHECK) ;
--   * `public.brouillon_cahier` (l'ecran du cahier s'ouvre sur ce brouillon) ;
--   * `public.mes_rapports_en_attente` (la liste « A terminer » de la Journee) ;
--   * et, trouve en ecrivant le scenario : `public.etat_presence`, appelee
--     par `brouillon_cahier` pour chaque eleve, refusait le remplacant.
-- Le declencheur `private.cahier_appliquer_exceptions` (20261103200000)
-- acceptait deja l'enseignant effectif ; il n'est pas touche.
--
-- Regle par defaut, en attendant la confirmation du directeur :
--   * le remplacant SEUL depose le cahier d'une seance remplacee ;
--   * le titulaire ecarte lit ce cahier, il ne le depose pas ;
--   * la direction garde son chemin (`lesson_reports_admin_all`, inchange).
--
-- Une seule source : `private.c29_enseignant_effectif_session(seance)`
-- (dernier evenement de `remplacements_seance` : `remplacement_pris` ou
-- `remplacement_designe_admin` donne le remplacant, sinon `teacher_id`). Sa
-- logique n'est pas recopiee. Elle est privee et fermee a `authenticated`
-- (schema `private` sans USAGE) ; une politique ne peut donc pas l'appeler
-- directement. `public.cahier_seance_confiee(seance)` l'enveloppe pour la RLS :
-- definer, ne repond que pour l'appelant (auth.uid()), jamais pour un tiers.
-- Une seance non remplacee rend `teacher_id` : rien ne change pour elle.
--
-- Le cahier est hebdomadaire (20261103000000) ; ce que cela donne pour une
-- semaine qui mele des seances du titulaire et des seances du remplacant :
--   * la regle de couverture (`private.cahier_semaine_couvert`) n'est pas
--     touchee : chaque eleve de la seance doit figurer dans UN cahier de la
--     meme Classe et de la meme semaine, QUEL QU'EN SOIT L'AUTEUR. Le cahier du
--     titulaire couvre donc aussi la seance du remplacant, et inversement ;
--   * `mes_rapports_en_attente` donne a chacun la derniere seance non couverte
--     de la semaine PARMI CELLES DONT IL EST L'ENSEIGNANT EFFECTIF. Dans une
--     semaine mixte, le titulaire et le remplacant voient chacun une ligne ;
--     le premier qui depose un cahier couvrant tous les eleves fait
--     disparaitre les deux. Le titulaire ne voit plus la seance remplacee ;
--   * la paie (`private.pai_releve_seances`) n'est pas touchee : elle paie
--     deja l'enseignant effectif et met en attente toute seance dont la
--     semaine n'est pas couverte, quel que soit l'auteur du cahier. Un cahier
--     du titulaire libere donc aussi la paie du remplacant pour cette semaine.
--     Aucune regle de paie ne change.
--
-- Non touche, signale au pilote : `public.mes_seances_enseignant_v` et
-- `public.cahier_semaine_depose` lisent encore `teacher_id` (le bouton de fin
-- de seance du remplacant ne connait pas l'etat du cahier de la semaine).
BEGIN;

-- ---------------------------------------------------------------------------
-- 1. L'enveloppe de l'enseignant effectif, pour la RLS
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.cahier_seance_confiee(p_session_id uuid)
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $function$
  SELECT coalesce(auth.uid() IS NOT NULL
                  AND private.c29_enseignant_effectif_session(p_session_id) = auth.uid(),
                  false);
$function$;

-- ---------------------------------------------------------------------------
-- 2. Le depot : le remplacant ecrit, le titulaire ecarte non
-- ---------------------------------------------------------------------------
-- USING inchange (l'auteur retrouve ses propres lignes). WITH CHECK : la
-- seance doit etre confiee a l'appelant, a la place de
-- `session_belongs_to_teacher` (titulaire). Les autres gardes restent :
-- role enseignant, auteur = appelant, compte valide, coalesce sur NULL.
ALTER POLICY lesson_reports_teacher_write ON public.lesson_reports
  USING (coalesce(author_profile_id = auth.uid() AND deleted_at IS NULL
                  AND (SELECT public.app_account_valid()), false))
  WITH CHECK (coalesce((SELECT public.app_role()) = 'teacher'::public.app_role
                       AND author_profile_id = auth.uid()
                       AND public.cahier_seance_confiee(session_id)
                       AND (SELECT public.app_account_valid()), false));

-- ---------------------------------------------------------------------------
-- 3. La lecture : le titulaire lit le cahier de sa seance remplacee
-- ---------------------------------------------------------------------------
-- Ajout d'un seul terme, pour l'enseignant : titulaire de la seance
-- (`session_belongs_to_teacher`). Direction et controleur en mission
-- inchanges ; la famille ne lit toujours pas le cahier brut (L1-03).
ALTER POLICY lesson_reports_reader ON public.lesson_reports
  USING ((SELECT public.app_account_valid()) AND deleted_at IS NULL
         AND (((SELECT public.app_role()) = 'teacher'::public.app_role
               AND (author_profile_id = auth.uid()
                    OR public.session_belongs_to_teacher(session_id, auth.uid())))
              OR (SELECT public.app_role()) = 'admin'::public.app_role
              OR ((SELECT public.app_role()) = 'controller'::public.app_role
                  AND app_private.af_controleur_en_mission(session_id))));

-- ---------------------------------------------------------------------------
-- 4. Le brouillon du cahier : corps de main (md5 6abe6bbc..., identique en
--    production le 31/10), seule la porte change : enseignant effectif.
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.brouillon_cahier(p_session_id uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare
  v_seance      public.sessions%rowtype;
  v_participants jsonb;
  v_evenements  jsonb;
begin
  select * into v_seance
    from public.sessions s
   where s.id = p_session_id and s.deleted_at is null;

  if not found then
    return null;
  end if;

  -- La porte : seul l'enseignant de la seance prepare son cahier. L'admin et
  -- le controleur lisent le cahier depose, ils n'en redigent pas.
  -- CAHIER-REMPLACANT (31/10/2026) : l'enseignant de la seance est
  -- l'enseignant effectif (C-29) ; le titulaire ecarte par un remplacement
  -- ne prepare plus ce cahier.
  --
  -- Exigence POSITIVE enveloppee de coalesce : chacun des quatre termes peut
  -- valoir NULL pour un appelant anonyme ou sans role, et une conjonction
  -- indeterminee doit refuser, jamais laisser passer. Ecrite en refus
  -- (« si l'une est fausse alors refuse »), la porte restait ouverte sur NULL.
  if not coalesce(
       auth.uid() is not null
       and private.c29_enseignant_effectif_session(v_seance.id) = auth.uid()
       and public.app_role() = 'teacher'
       and public.app_account_valid(),
       false
     ) then
    raise exception 'cahier refuse' using errcode = '42501';
  end if;

  select coalesce(jsonb_agg(ligne order by ligne ->> 'prenom'), '[]'::jsonb)
    into v_participants
    from (
      select jsonb_build_object(
               'student_id',           p.id,
               'prenom',               p.first_name,
               'identifiant_immuable', p.immutable_id,
               'niveau',               sp.level,
               'riwaya',               sp.riwaya,
               'presence',             public.etat_presence(p_session_id, p.id),
               'entre_le',             (
                 select min(e.server_ts) from public.session_events e
                  where e.session_id = p_session_id
                    and e.profile_id = p.id
                    and e.event_type = 'joined'
               ),
               'derniere_trace_le',    (
                 select max(e.server_ts) from public.session_events e
                  where e.session_id = p_session_id and e.profile_id = p.id
               ),
               -- Memes cles que `student_reading_position`, volontairement :
               -- `PositionLecture.depuisJson` (core/coran/service_coran.dart)
               -- les lit deja, et un second jeu de noms imposerait un second
               -- modele Dart pour le meme fait.
               --
               -- La position d'un eleve LUI APPARTIENT (invariant J2) : aucune
               -- policy ne laisse un enseignant l'ecrire, et ce n'est pas ce
               -- qui se passe ici. Cette fonction la LIT, pour le seul
               -- enseignant de la seance, afin de preremplir « ce qui a ete
               -- travaille » -- ce que le protocole exige de deduire plutot que
               -- de redemander. Une page tournee par l'enseignant n'ecrase
               -- jamais l'endroit ou l'eleve en etait.
               'position',             (
                 select jsonb_build_object(
                          'page_mushaf', r.page_mushaf,
                          'sourate',     r.sourate,
                          'verset',      r.verset,
                          'zoom_level',  r.zoom_level,
                          'updated_at',  r.updated_at
                        )
                   from public.student_reading_position r
                  where r.student_profile_id = p.id
               ),
               'unite_curriculum',     public.unite_curriculum(p.id)
             ) as ligne
        from public.session_participants spart
        join public.profiles p on p.id = spart.profile_id
        left join public.student_profiles sp on sp.profile_id = p.id
       where spart.session_id = p_session_id
         and spart.role = 'student'
         and spart.deleted_at is null
         and p.deleted_at is null
    ) lignes;

  select coalesce(
           jsonb_agg(
             jsonb_build_object(
               'type',       e.event_type,
               'instant',    e.server_ts,
               'profile_id', e.profile_id
             ) order by e.server_ts
           ),
           '[]'::jsonb
         )
    into v_evenements
    from public.session_events e
   where e.session_id = p_session_id;

  return jsonb_build_object(
    'session_id',           v_seance.id,
    'groupe_id',            v_seance.groupe_id,
    'debut',                v_seance.started_at,
    'fin',                  v_seance.ended_at,
    'statut',               v_seance.status,
    'duree_minutes',
      greatest(
        0,
        (extract(epoch from (v_seance.ended_at - v_seance.started_at)) / 60)::int
      ),
    'minutes_interruption', v_seance.prayer_pause_minutes,
    'deja_depose',          exists (
      select 1 from public.lesson_reports lr
       where lr.session_id = p_session_id and lr.deleted_at is null
    ),
    'participants',         v_participants,
    'evenements',           v_evenements
  );
end;
$function$;

-- ---------------------------------------------------------------------------
-- 4 bis. L'etat de presence lu par le brouillon : corps de main (md5
--    e46b4c59..., identique en production le 31/10). `brouillon_cahier`
--    l'appelle pour chaque eleve ; sa porte ne connaissait que le titulaire et
--    refusait donc le remplacant (42501 « acces refuse »). Un chemin ajoute,
--    l'enseignant effectif ; les quatre chemins existants restent tels quels
--    (le titulaire garde sa lecture de la presence de sa seance).
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.etat_presence(p_session_id uuid, p_profile_id uuid)
 RETURNS presence_state
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO ''
AS $function$
DECLARE
  v_seance         public.sessions%ROWTYPE;
  v_seance_trouvee boolean;
  v_override       public.presence_state;
  v_premier_joined timestamptz;
  v_dernier_type   public.session_event_type;
  v_dernier_ts     timestamptz;
  v_dernier_source text;
  v_left_subi      boolean;
  v_jeton_le       timestamptz;
  v_seuil_retard   int := public.app_config_int('presence.seuil_retard_secondes', 300);
  v_fenetre_reco   int := public.app_config_int('presence.fenetre_reconnexion_secondes', 120);
  v_fenetre_conn   int := public.app_config_int('presence.fenetre_connexion_secondes', 90);
  v_fenetre_join   int := public.app_config_int('join_window_minutes', 20);
BEGIN
  IF NOT public.app_account_valid() THEN
    RAISE EXCEPTION 'compte non valide' USING ERRCODE = 'insufficient_privilege';
  END IF;

  SELECT * INTO v_seance FROM public.sessions s
   WHERE s.id = p_session_id AND s.deleted_at IS NULL;
  v_seance_trouvee := FOUND;

  -- Keep the exact four authorized paths; NULL in any branch now denies access.
  -- CAHIER-REMPLACANT (31/10/2026) : un cinquieme, l'enseignant effectif
  -- (C-29), pour que le brouillon du cahier serve le remplacant.
  IF NOT coalesce(
    public.app_role() = ANY (ARRAY['admin', 'controller']::public.app_role[])
    OR (v_seance_trouvee AND v_seance.teacher_id = auth.uid())
    OR (v_seance_trouvee AND private.c29_enseignant_effectif_session(p_session_id) = auth.uid())
    OR (public.app_role() = 'guardian' AND public.est_du_foyer(p_profile_id))
    OR p_profile_id = auth.uid(),
    false
  ) THEN
    RAISE EXCEPTION 'acces refuse' USING ERRCODE = 'insufficient_privilege';
  END IF;

  IF NOT v_seance_trouvee THEN
    RETURN NULL;
  END IF;

  SELECT o.etat INTO v_override FROM public.session_presence_override o
   WHERE o.session_id = p_session_id AND o.profile_id = p_profile_id;
  IF v_override IS NOT NULL THEN
    RETURN v_override;
  END IF;

  SELECT min(e.server_ts) INTO v_premier_joined
    FROM public.session_events e
   WHERE e.session_id = p_session_id
     AND e.profile_id = p_profile_id
     AND e.event_type = 'joined';

  SELECT e.event_type, e.server_ts, e.source
    INTO v_dernier_type, v_dernier_ts, v_dernier_source
    FROM public.session_events e
   WHERE e.session_id = p_session_id
     AND e.profile_id = p_profile_id
     AND e.event_type IN ('joined', 'left', 'track_subscribed')
   ORDER BY e.server_ts DESC, e.id DESC
   LIMIT 1;

  IF v_premier_joined IS NULL THEN
    IF v_seance.status IN ('ended', 'teacher_absent', 'student_absent') THEN
      RETURN 'absente';
    END IF;

    SELECT max(g.emis_le) INTO v_jeton_le
      FROM public.video_token_grants g
     WHERE g.session_id = p_session_id
       AND g.profile_id = p_profile_id;

    IF v_jeton_le IS NOT NULL
       AND now() - v_jeton_le <= make_interval(secs => v_fenetre_conn) THEN
      RETURN 'en_connexion';
    END IF;

    IF now() < v_seance.started_at - make_interval(mins => v_fenetre_join) THEN
      RETURN 'planifiee';
    END IF;
    RETURN 'en_attente';
  END IF;

  IF v_dernier_type = 'left' THEN
    IF v_dernier_source = 'user_action' THEN
      RETURN 'sortie';
    END IF;
    IF now() - v_dernier_ts <= make_interval(secs => v_fenetre_reco) THEN
      RETURN 'en_reconnexion';
    END IF;
    RETURN 'deconnectee';
  END IF;

  SELECT EXISTS (
    SELECT 1 FROM public.session_events e
     WHERE e.session_id = p_session_id
       AND e.profile_id = p_profile_id
       AND e.event_type = 'left'
       AND e.source <> 'user_action'
       AND e.server_ts < v_dernier_ts
  ) INTO v_left_subi;

  IF v_left_subi THEN
    RETURN 'reconnectee';
  END IF;

  IF v_premier_joined > v_seance.started_at + make_interval(secs => v_seuil_retard) THEN
    RETURN 'en_retard';
  END IF;

  IF v_seance.status IN ('ended', 'teacher_absent', 'student_absent') THEN
    RETURN 'confirmation_en_attente';
  END IF;

  RETURN 'presente';
END;
$function$;

-- ---------------------------------------------------------------------------
-- 5. Les cahiers a remplir : corps de main (20261103000000, md5 1a9ed1e5...,
--    identique en production le 31/10). Seul le filtre sur l'enseignant
--    change, dans la requete et dans la sous-requete « une ligne par
--    semaine » : enseignant effectif. Le pre-filtre (titulaire, ou nomme
--    remplacant de la seance) borne les seances lues avant l'appel par ligne ;
--    la decision reste a `private.c29_enseignant_effectif_session`.
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.mes_rapports_en_attente()
 RETURNS TABLE(session_id uuid, started_at timestamp with time zone, ended_at timestamp with time zone, groupe_id uuid, groupe_libelle text, nb_participants integer, heures_de_retard integer)
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO ''
AS $function$
  select
    s.id,
    s.started_at,
    s.ended_at,
    s.groupe_id,
    g.libelle,
    count(distinct sp.profile_id) filter (
      where sp.role = 'student' and sp.deleted_at is null
    )::int,
    greatest(0, (extract(epoch from (now() - s.ended_at)) / 3600)::int)
  from public.sessions s
    left join public.groupes g on g.id = s.groupe_id
    left join public.session_participants sp on sp.session_id = s.id
  where s.deleted_at is null
    -- CAHIER-REMPLACANT : l'enseignant effectif de la seance (C-29).
    and (s.teacher_id = auth.uid()
         or exists (select 1 from public.remplacements_seance x
                     where x.session_id = s.id and x.enseignant_remplacant_id = auth.uid()))
    and private.c29_enseignant_effectif_session(s.id) = auth.uid()
    and public.app_role() = 'teacher'
    and public.app_account_valid()
    -- Une seance annulee, ou l'enseignant ne s'est pas presente, ne doit aucun
    -- cahier : il n'y a rien a transmettre.
    and s.status in ('ended', 'student_absent', 'tech_failure')
    and s.ended_at < now()
    -- CAHIER-HEBDOMADAIRE : chaque eleve de la seance figure dans un cahier
    -- de la Classe cette semaine-la (fuseau de la Classe).
    and not private.cahier_semaine_couvert(s.id)
    -- Une ligne par Classe et par semaine : la derniere seance non couverte
    -- parmi celles dont l'appelant est l'enseignant effectif.
    and not exists (
      select 1 from public.sessions s2
       where s.groupe_id is not null
         and s2.groupe_id = s.groupe_id
         and s2.id <> s.id
         and s2.deleted_at is null
         and private.c29_enseignant_effectif_session(s2.id) = auth.uid()
         and s2.status in ('ended', 'student_absent', 'tech_failure')
         and s2.ended_at < now()
         and s2.ended_at > s.ended_at
         and pg_catalog.date_trunc('week', s2.started_at at time zone g.timezone_iana)
             = pg_catalog.date_trunc('week', s.started_at at time zone g.timezone_iana)
         and not private.cahier_semaine_couvert(s2.id)
    )
  group by s.id, s.started_at, s.ended_at, s.groupe_id, g.libelle
  order by s.ended_at asc;
$function$;

-- ---------------------------------------------------------------------------
-- 6. Droits
-- ---------------------------------------------------------------------------
-- `cahier_seance_confiee` : memes lecteurs que les politiques qui l'appellent
-- (authenticated, agent_ro ; service_role contourne la RLS mais garde le
-- droit comme `session_belongs_to_teacher`). Jamais anon.
DO $droits$
DECLARE
  v_oid pg_catalog.regprocedure;
  v_role text;
BEGIN
  FOREACH v_oid IN ARRAY ARRAY[
    'public.cahier_seance_confiee(uuid)'::pg_catalog.regprocedure,
    'public.brouillon_cahier(uuid)'::pg_catalog.regprocedure,
    'public.etat_presence(uuid,uuid)'::pg_catalog.regprocedure,
    'public.mes_rapports_en_attente()'::pg_catalog.regprocedure] LOOP
    EXECUTE pg_catalog.format('ALTER FUNCTION %s OWNER TO postgres', v_oid);
    EXECUTE pg_catalog.format('REVOKE ALL ON FUNCTION %s FROM PUBLIC', v_oid);
    IF EXISTS (SELECT 1 FROM pg_catalog.pg_roles WHERE rolname = 'anon') THEN
      EXECUTE pg_catalog.format('REVOKE ALL ON FUNCTION %s FROM anon', v_oid);
    END IF;
    FOREACH v_role IN ARRAY ARRAY['authenticated', 'service_role', 'agent_ro'] LOOP
      IF EXISTS (SELECT 1 FROM pg_catalog.pg_roles WHERE rolname = v_role) THEN
        EXECUTE pg_catalog.format('GRANT EXECUTE ON FUNCTION %s TO %I', v_oid, v_role);
      END IF;
    END LOOP;
  END LOOP;
END;
$droits$;

COMMENT ON FUNCTION public.cahier_seance_confiee(uuid) IS
  'CAHIER-REMPLACANT (31/10/2026) : vrai quand l''appelant est l''enseignant effectif de la seance (private.c29_enseignant_effectif_session : le remplacant si la seance est remplacee, sinon le titulaire). Utilisee par la politique lesson_reports_teacher_write. Ne repond que pour auth.uid(). Lecture seule.';
COMMENT ON FUNCTION public.brouillon_cahier(uuid) IS
  'ENS-02, CAHIER-REMPLACANT (31/10/2026) : brouillon du cahier pour l''enseignant effectif de la seance (le remplacant quand elle est remplacee ; le titulaire ecarte est refuse, 42501). La direction et le controleur lisent le cahier depose, ils n''en redigent pas.';
COMMENT ON FUNCTION public.mes_rapports_en_attente() IS
  'ENS-02, CAHIER-HEBDOMADAIRE, CAHIER-REMPLACANT (31/10/2026) : les cahiers a remplir de l''enseignant connecte, parmi les seances dont il est l''enseignant effectif (C-29), une ligne par Classe et par semaine dont un eleve ne figure dans aucun cahier (private.cahier_semaine_couvert, quel qu''en soit l''auteur), la plus ancienne d''abord.';

-- ---------------------------------------------------------------------------
-- 7. Verifications
-- ---------------------------------------------------------------------------
DO $postflight$
DECLARE
  v_oid pg_catalog.regprocedure;
  v_check text;
  v_qual text;
BEGIN
  FOREACH v_oid IN ARRAY ARRAY[
    'public.cahier_seance_confiee(uuid)'::pg_catalog.regprocedure,
    'public.brouillon_cahier(uuid)'::pg_catalog.regprocedure,
    'public.etat_presence(uuid,uuid)'::pg_catalog.regprocedure,
    'public.mes_rapports_en_attente()'::pg_catalog.regprocedure] LOOP
    IF NOT EXISTS (SELECT 1 FROM pg_catalog.pg_proc p WHERE p.oid = v_oid AND p.prosecdef
                     AND p.provolatile = 's'
                     AND (p.proconfig @> ARRAY['search_path=""'] OR p.proconfig @> ARRAY['search_path=']))
       OR pg_catalog.has_function_privilege('anon', v_oid, 'EXECUTE')
       OR NOT pg_catalog.has_function_privilege('authenticated', v_oid, 'EXECUTE') THEN
      RAISE EXCEPTION 'CAHIER-REMPLACANT : % mal declaree ou droits invalides', v_oid;
    END IF;
  END LOOP;
  IF pg_catalog.has_function_privilege('authenticated',
       'private.c29_enseignant_effectif_session(uuid)'::pg_catalog.regprocedure, 'EXECUTE') THEN
    RAISE EXCEPTION 'CAHIER-REMPLACANT : l''aide privee C-29 est exposee';
  END IF;
  SELECT p.with_check INTO v_check FROM pg_catalog.pg_policies p
   WHERE p.schemaname = 'public' AND p.tablename = 'lesson_reports'
     AND p.policyname = 'lesson_reports_teacher_write';
  IF v_check IS NULL OR v_check NOT LIKE '%cahier_seance_confiee%'
     OR v_check LIKE '%session_belongs_to_teacher%' OR v_check NOT LIKE '%app_account_valid%' THEN
    RAISE EXCEPTION 'CAHIER-REMPLACANT : politique de depot inattendue';
  END IF;
  SELECT p.qual INTO v_qual FROM pg_catalog.pg_policies p
   WHERE p.schemaname = 'public' AND p.tablename = 'lesson_reports'
     AND p.policyname = 'lesson_reports_reader';
  IF v_qual IS NULL OR v_qual LIKE '%session_in_household%' OR v_qual LIKE '%session_has_participant%'
     OR v_qual NOT LIKE '%af_controleur_en_mission%' THEN
    RAISE EXCEPTION 'CAHIER-REMPLACANT : politique de lecture inattendue';
  END IF;
END;
$postflight$;

COMMIT;
