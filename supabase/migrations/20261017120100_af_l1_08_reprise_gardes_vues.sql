-- AF L1-08-reprise : la garde de compte valide couvre aussi la RPC de gel de conservation, quatre vues,
-- les trois policies de depot (garde positive), et toutes les policies sont evaluees une fois par requete.
-- Origine : verification croisee L1-V (defaut D-1, mesure de lecture a l'echelle).
-- Methode : les definitions sont lues dans la base rejouee (pg_get_functiondef, pg_get_viewdef) et
-- recopiees par script, une seule condition ajoutee par objet ; les policies sont reecrites par la
-- boucle du bloc 3, qui compare chaque texte reecrit au texte d'origine et s'arrete au moindre ecart.
--
-- 1. geler_archive_seance : admin ET compte valide (un admin suspendu levait le gel d'un litige).
-- 2. presence_seance_v, session_peers_v, tendance_feedback_v, eleves_en_attente_v : proprietaire postgres,
--    donc sans RLS sous-jacente ; la garde de compte est dans la vue. Memes colonnes, security_barrier conserve.
--    (select public.app_account_valid()) : une seule evaluation par requete (InitPlan).
-- 3. Trois policies de depot : garde positive (pending_kyc, provisional_active, active, access_until)
--    au lieu de `account_status <> 'disabled'`.
-- 4. Toute policy de public et de storage qui appelle app_role() ou app_account_valid() les appelle
--    en (select ...) : evaluation une fois par requete au lieu de une fois par ligne et par policy.
--    app_role() et app_account_valid() sont STABLE : le sens ne change pas ; le bloc le verifie.

begin;

set local search_path = public;

-- 1. RPC de gel de conservation.
create or replace function public.geler_archive_seance(p_recording_id uuid, p_motif text, p_gel boolean DEFAULT true)
 RETURNS boolean
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare
  v_touche int;
begin
  if not coalesce(public.app_role() = 'admin' and public.app_account_valid(), false) then
    raise exception 'gel de conservation reserve a l''administration'
      using errcode = '42501';
  end if;

  if p_recording_id is null then
    raise exception 'archive non precisee' using errcode = '22023';
  end if;

  -- `p_gel` a NULL doit ECHOUER, jamais degeler. Sans ce refus, `if p_gel and
  -- ...` ne se declenche pas (NULL and true vaut NULL, donc aucun motif n'est
  -- exige) et `case when p_gel then ... else null end` tombe dans le ELSE :
  -- une archive retenue pour un litige perdrait sa protection sur un argument
  -- omis, ce qu'un client qui serialise un booleen nullable produit sans le
  -- vouloir. C'est le meme renversement que `0029` a corrige ailleurs --
  -- l'inconnue doit fermer, pas ouvrir.
  if p_gel is null then
    raise exception 'sens du gel non precise' using errcode = '22023';
  end if;

  if p_gel and coalesce(btrim(p_motif), '') = '' then
    raise exception 'un gel de conservation exige un motif' using errcode = '22023';
  end if;

  update public.session_recordings r
  set legal_hold_since = case when p_gel then coalesce(r.legal_hold_since, now()) else null end
  where r.id = p_recording_id and r.deleted_at is null;

  get diagnostics v_touche = row_count;
  if v_touche = 0 then
    raise exception 'archive introuvable' using errcode = '42501';
  end if;

  -- Le motif entre ICI, et nulle part ailleurs : `audit_logs` est reserve a
  -- l'administration, quand la ligne d'archive est lisible par l'enseignant de
  -- la seance et par les familles.
  perform public.log_sensitive_access(
    case when p_gel then 'recording_legal_hold_set' else 'recording_legal_hold_lift' end,
    'session_recordings',
    p_recording_id::text,
    jsonb_build_object('gel', p_gel, 'motif', nullif(btrim(coalesce(p_motif, '')), ''))
  );

  return true;
end;
$function$;

-- 2. Vues.
create or replace view public.presence_seance_v with (security_barrier = true) as
 SELECT sp.session_id,
    sp.profile_id,
    sp.role,
        CASE
            WHEN agent_identite_masquee() THEN p.immutable_id
            ELSE p.first_name
        END AS prenom,
    p.immutable_id AS identifiant_immuable,
    etat_presence(sp.session_id, sp.profile_id) AS etat,
    ( SELECT
                CASE
                    WHEN min(e.server_ts) IS NOT NULL THEN GREATEST(min(e.server_ts), s.started_at)
                    ELSE NULL::timestamp with time zone
                END AS "case"
           FROM session_events e
          WHERE e.session_id = sp.session_id AND e.profile_id = sp.profile_id AND e.event_type = 'joined'::session_event_type) AS entre_le,
    ( SELECT max(e.server_ts) AS max
           FROM session_events e
          WHERE e.session_id = sp.session_id AND e.profile_id = sp.profile_id) AS derniere_trace_le,
    o.etat IS NOT NULL AS consolide,
    o.decide_le AS consolide_le,
    s.started_at,
    s.ended_at,
    s.status AS statut_seance
   FROM session_participants sp
     JOIN sessions s ON s.id = sp.session_id
     JOIN profiles p ON p.id = sp.profile_id
     LEFT JOIN session_presence_override o ON o.session_id = sp.session_id AND o.profile_id = sp.profile_id
  WHERE (select public.app_account_valid()) AND sp.deleted_at IS NULL AND s.deleted_at IS NULL AND p.deleted_at IS NULL AND ((app_role() = ANY (ARRAY['admin'::app_role, 'controller'::app_role])) OR s.teacher_id = auth.uid() OR app_role() = 'guardian'::app_role AND est_du_foyer(p.id) OR sp.profile_id = auth.uid()) AND ((sp.role <> ALL (ARRAY['masked_controller'::participant_role, 'admin_masked'::participant_role])) OR app_role() = 'admin'::app_role);

create or replace view public.session_peers_v with (security_barrier = true) as
 SELECT DISTINCT sp.session_id,
    p2.id AS peer_id,
        CASE
            WHEN agent_identite_masquee() THEN p2.immutable_id
            ELSE p2.first_name
        END AS first_name,
    p2.immutable_id
   FROM session_participants sp
     JOIN session_participants sp2 USING (session_id)
     JOIN profiles p2 ON p2.id = sp2.profile_id
  WHERE (select public.app_account_valid()) AND sp.profile_id = auth.uid() AND sp.deleted_at IS NULL AND sp2.deleted_at IS NULL AND p2.deleted_at IS NULL AND sp2.profile_id <> sp.profile_id AND ((sp2.role <> ALL (ARRAY['masked_controller'::participant_role, 'admin_masked'::participant_role, 'guardian_observer'::participant_role])) OR app_role() = 'admin'::app_role);

create or replace view public.tendance_feedback_v with (security_barrier = true) as
 SELECT f.groupe_id,
    f.question_id,
    count(*) AS nombre_echantillons,
    count(*) FILTER (WHERE f.reponse = 'difficile'::text) AS n_difficile,
    count(*) FILTER (WHERE f.reponse = 'bien'::text) AS n_bien,
    count(*) FILTER (WHERE f.reponse = 'tres_bien'::text) AS n_tres_bien
   FROM session_feedback f
     JOIN groupes g ON g.id = f.groupe_id
  WHERE (select public.app_account_valid()) AND f.question_id = 'comprehension'::text AND (g.teacher_id = auth.uid() OR app_role() = 'admin'::app_role)
  GROUP BY f.groupe_id, f.question_id
 HAVING count(*) >= app_config_int('feedback_seuil_tendance'::text, 5);

create or replace view public.eleves_en_attente_v with (security_barrier = true) as
 SELECT e.id AS student_id,
        CASE
            WHEN agent_identite_masquee() THEN e.immutable_id
            ELSE e.first_name
        END AS first_name,
    e.immutable_id,
    sp.level,
    sp.interface_mode,
    we.weekday,
    we.hour_local,
    we.timezone_iana,
    attente.depuis
   FROM profiles e
     JOIN student_profiles sp ON sp.profile_id = e.id AND sp.deleted_at IS NULL
     JOIN weekly_availability we ON we.profile_id = e.id
     JOIN weekly_availability wt ON wt.profile_id = auth.uid() AND instant_creneau(wt.weekday::integer, wt.hour_local::integer, wt.timezone_iana) = instant_creneau(we.weekday::integer, we.hour_local::integer, we.timezone_iana)
     JOIN LATERAL ( SELECT min(w2.created_at) AS depuis
           FROM weekly_availability w2
          WHERE w2.profile_id = e.id) attente ON true
  WHERE (select public.app_account_valid()) AND e.role = 'student'::app_role AND e.deleted_at IS NULL AND (e.account_status = ANY (ARRAY['active'::account_status, 'provisional_active'::account_status])) AND app_role() = 'teacher'::app_role AND NOT (EXISTS ( SELECT 1
           FROM teacher_student_assignments a
          WHERE a.student_id = e.id AND a.ended_at IS NULL));

-- 3 et 4. Policies.
do $policies$
declare
  r record;
  v_qual text;
  v_chk text;
  v_sql text;
  v_depot text[] := array['kyc_staff_self_insert', 'kyc_guardian_insert', 'contract_acceptances_self_insert'];
  v_ancien text := 'pv.account_status <> ''disabled''::account_status';
  v_nouveau text := '(pv.account_status = ANY (ARRAY[''pending_kyc''::account_status, ''provisional_active''::account_status, ''active''::account_status]) AND (pv.access_until IS NULL OR pv.access_until > now()))';
  v_motif constant text := '(?<!SELECT )(?<!public\.)\m(public\.)?(app_role|app_account_valid)\(\)';
  v_depots int := 0;
  v_reecrites int := 0;
  v_avant jsonb := '{}'::jsonb;
  v_apres jsonb := '{}'::jsonb;
  v_cle text;
  v_a text;
  v_b text;
begin
  -- 3. Depots : garde positive. Le remplacement doit toucher exactement une fois chaque policy.
  for r in
    select schemaname, tablename, policyname, with_check from pg_policies
     where schemaname = 'public' and policyname = any (v_depot)
  loop
    if (length(r.with_check) - length(replace(r.with_check, v_ancien, ''))) / length(v_ancien) <> 1 then
      raise exception 'L1-08-reprise: garde de depot introuvable ou multiple dans %', r.policyname;
    end if;
    execute format('alter policy %I on %I.%I with check (%s)',
      r.policyname, r.schemaname, r.tablename, replace(r.with_check, v_ancien, v_nouveau));
    v_depots := v_depots + 1;
  end loop;
  if v_depots <> 3 then
    raise exception 'L1-08-reprise: % policies de depot trouvees, 3 attendues', v_depots;
  end if;

  -- 4. Evaluation une fois par requete. Etat d'origine memorise, puis reecriture.
  for r in
    select schemaname, tablename, policyname, qual, with_check from pg_policies
     where schemaname in ('public', 'storage')
       and (coalesce(qual, '') || coalesce(with_check, '')) ~ '\m(app_role|app_account_valid)\(\)'
     order by schemaname, tablename, policyname
  loop
    v_cle := r.schemaname || '.' || r.tablename || '.' || r.policyname;
    v_avant := v_avant || jsonb_build_object(v_cle, jsonb_build_array(
      regexp_replace(coalesce(r.qual, ''), '\( SELECT (app_role\(\)|app_account_valid\(\)) AS \w+\)', '\1', 'g'),
      regexp_replace(coalesce(r.with_check, ''), '\( SELECT (app_role\(\)|app_account_valid\(\)) AS \w+\)', '\1', 'g')));
    v_qual := case when r.qual is null then null else regexp_replace(r.qual, v_motif, '(select public.\2())', 'g') end;
    v_chk := case when r.with_check is null then null else regexp_replace(r.with_check, v_motif, '(select public.\2())', 'g') end;
    if v_qual is not distinct from r.qual and v_chk is not distinct from r.with_check then
      continue;
    end if;
    v_sql := format('alter policy %I on %I.%I', r.policyname, r.schemaname, r.tablename);
    if v_qual is not null then v_sql := v_sql || ' using (' || v_qual || ')'; end if;
    if v_chk is not null then v_sql := v_sql || ' with check (' || v_chk || ')'; end if;
    execute v_sql;
    v_reecrites := v_reecrites + 1;
  end loop;

  -- Verification : le texte reecrit, une fois les enveloppes retirees, est le texte d'origine.
  for r in
    select schemaname, tablename, policyname, qual, with_check from pg_policies
     where schemaname in ('public', 'storage')
  loop
    v_cle := r.schemaname || '.' || r.tablename || '.' || r.policyname;
    continue when not v_avant ? v_cle;
    v_a := regexp_replace(coalesce(r.qual, ''), '\( SELECT (app_role\(\)|app_account_valid\(\)) AS \w+\)', '\1', 'g');
    v_b := regexp_replace(coalesce(r.with_check, ''), '\( SELECT (app_role\(\)|app_account_valid\(\)) AS \w+\)', '\1', 'g');
    if v_a is distinct from (v_avant -> v_cle ->> 0)
       or v_b is distinct from (v_avant -> v_cle ->> 1) then
      raise exception 'L1-08-reprise: le sens de la policy % a change', v_cle;
    end if;
  end loop;
  raise notice 'L1-08-reprise: % policies de depot, % policies reecrites', v_depots, v_reecrites;
end $policies$;

-- Postflight.
do $postflight$
declare v text;
begin
  -- Aucun appel nu ne reste dans les policies.
  select string_agg(schemaname || '.' || tablename || '.' || policyname, ', ')
    into v
    from pg_policies
   where schemaname in ('public', 'storage')
     and (coalesce(qual, '') || coalesce(with_check, '')) ~ '(?<!SELECT )(?<!public\.)\m(public\.)?(app_role|app_account_valid)\(\)';
  if v is not null then
    raise exception 'L1-08-reprise postflight: appels non enveloppes : %', v;
  end if;

  -- Les huit policies sans app_account_valid sont toujours exactement celles de L1-08.
  select string_agg(tablename || '.' || policyname, ', ' order by tablename || '.' || policyname)
    into v
    from pg_policies
   where schemaname = 'public'
     and (coalesce(qual,'') || coalesce(with_check,'')) like '%app_role()%'
     and (coalesce(qual,'') || coalesce(with_check,'')) not like '%app_account_valid%';
  if v is distinct from 'contract_acceptances.contract_acceptances_self_insert, households.households_guardian_select, intentions_horaire.intentions_horaire_parties, kyc_documents.kyc_guardian_insert, kyc_documents.kyc_staff_self_insert, offres_horaires.offres_horaires_vitrine, profiles.profiles_family_select, student_reading_position.srp_foyer_lecture' then
    raise exception 'L1-08-reprise postflight: liste des policies sans app_account_valid : %', coalesce(v, '(aucune)');
  end if;

  -- Gardes positives des depots.
  if exists (
    select 1 from pg_policies
     where policyname in ('kyc_staff_self_insert', 'kyc_guardian_insert', 'contract_acceptances_self_insert')
       and (with_check like '%<> ''disabled''%' or with_check not like '%access_until%')
  ) then
    raise exception 'L1-08-reprise postflight: garde de depot non positive';
  end if;

  -- Vues et RPC.
  if exists (
    select 1 from pg_views
     where schemaname = 'public'
       and viewname in ('presence_seance_v', 'session_peers_v', 'tendance_feedback_v', 'eleves_en_attente_v')
       and definition not like '%app_account_valid%'
  ) then
    raise exception 'L1-08-reprise postflight: une vue sans app_account_valid';
  end if;
  if (select count(*) from pg_class c
       where c.oid in ('public.presence_seance_v'::regclass, 'public.session_peers_v'::regclass,
                       'public.tendance_feedback_v'::regclass, 'public.eleves_en_attente_v'::regclass)
         and coalesce(c.reloptions, '{}') @> array['security_barrier=true']) <> 4 then
    raise exception 'L1-08-reprise postflight: security_barrier perdu';
  end if;
  if (select p.prosrc from pg_proc p where p.oid = 'public.geler_archive_seance(uuid,text,boolean)'::regprocedure)
     not like '%app_account_valid%' then
    raise exception 'L1-08-reprise postflight: geler_archive_seance sans app_account_valid';
  end if;
end $postflight$;

commit;
