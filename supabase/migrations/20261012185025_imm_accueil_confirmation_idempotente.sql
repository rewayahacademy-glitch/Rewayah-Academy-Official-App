begin;

alter table private.preinscription_households
  add column a_patiente boolean not null default false,
  add column mot_accueil text,
  add column mot_patience text,
  add column confirmed_at timestamptz,
  add column confirmed_by uuid references public.profiles(id);

alter table private.preinscription_persons
  add column person_key text;
create unique index preinscription_persons_person_key_uq
  on private.preinscription_persons(person_key)
  where person_key is not null;

create or replace function private.preparer_plan_import_inscriptions(
  p_eleves_csv text,
  p_enseignants_csv text
) returns jsonb
language plpgsql
security definer
set search_path = ''
as $function$
declare
  v_report jsonb;
  v_students jsonb;
  v_teachers jsonb;
  v_student_headers jsonb;
  v_teacher_headers jsonb;
  v_row jsonb;
  v_header text;
  v_first_header text;
  v_form_answer text;
  v_email text;
  v_first_name text;
  v_last_name text;
  v_kind text;
  v_key text;
  v_occurrence integer;
  v_field integer;
  v_first_field integer;
  v_birth_field integer;
  v_next_name_field integer;
  v_email_field integer;
  v_guardian_email_field integer;
  v_form_field integer;
  v_birth_date date;
  v_people jsonb := '[]'::jsonb;
  v_emails text[] := array[]::text[];
  v_person_keys text[] := array[]::text[];
  v_row_index integer;
begin
  -- The preview owns validation and the authenticated admin guard. Its report
  -- identifies accepted rows without placing raw CSV values in API responses.
  v_report := public.previsualiser_import_inscriptions(p_eleves_csv, p_enseignants_csv);
  v_students := private.parse_import_csv(p_eleves_csv);
  v_teachers := private.parse_import_csv(p_enseignants_csv);
  v_student_headers := v_students->0;
  v_teacher_headers := v_teachers->0;

  select h.ord::integer into v_email_field
    from jsonb_array_elements_text(v_student_headers) with ordinality as h(value, ord)
   where lower(btrim(h.value)) = 'email'
   order by h.ord limit 1;
  select h.ord::integer into v_guardian_email_field
    from jsonb_array_elements_text(v_student_headers) with ordinality as h(value, ord)
   where lower(btrim(h.value)) = 'email du tuteur'
   order by h.ord limit 1;
  select h.ord::integer into v_form_field
    from jsonb_array_elements_text(v_student_headers) with ordinality as h(value, ord)
   where lower(btrim(h.value)) like 'pour qui faites-vous cette inscription%'
   order by h.ord limit 1;

  for v_row_index in 1..jsonb_array_length(v_students)-1 loop
    if exists (
      select 1 from jsonb_array_elements(v_report->'motifs_rejet') as r(value)
       where r.value->>'source' = 'eleves'
         and (r.value->>'row')::integer = v_row_index + 1
    ) then
      continue;
    end if;
    v_row := v_students->v_row_index;
    v_email := lower(btrim(coalesce(
      nullif(v_row->>(v_guardian_email_field - 1), ''),
      v_row->>(v_email_field - 1)
    )));
    if v_email = '' then continue; end if;
    if not v_email = any(v_emails) then
      v_emails := array_append(v_emails, v_email);
    end if;
    v_form_answer := case when v_form_field is null then ''
      else lower(btrim(coalesce(v_row->>(v_form_field - 1), ''))) end;

    for v_field in 0..jsonb_array_length(v_student_headers)-1 loop
      v_header := lower(btrim(v_student_headers->>v_field));
      if v_header not like 'nom%' then continue; end if;
      v_last_name := btrim(coalesce(v_row->>v_field, ''));
      if v_last_name = '' then continue; end if;
      v_first_header := regexp_replace(v_header, '^nom', 'prénom');

      select count(*)::integer into v_occurrence
        from jsonb_array_elements_text(v_student_headers) with ordinality as h(value, ord)
       where lower(btrim(h.value)) = v_header and h.ord <= v_field + 1;
      select h.ord::integer into v_first_field
        from jsonb_array_elements_text(v_student_headers) with ordinality as h(value, ord)
       where lower(btrim(h.value)) = v_first_header
         and (select count(*) from jsonb_array_elements_text(v_student_headers)
                with ordinality as prior(value, ord)
               where lower(btrim(prior.value)) = v_first_header and prior.ord <= h.ord) = v_occurrence
       order by h.ord limit 1;
      v_first_name := btrim(coalesce(v_row->>(v_first_field - 1), ''));
      if v_first_field is null or v_first_name = '' then continue; end if;

      v_birth_date := null;
      select h.ord::integer into v_birth_field
        from jsonb_array_elements_text(v_student_headers) with ordinality as h(value, ord)
       where lower(btrim(h.value)) like '%date de naissance%'
         and h.ord > v_field + 1
         and not exists (
           select 1 from jsonb_array_elements_text(v_student_headers)
             with ordinality as n(value, ord)
            where lower(btrim(n.value)) like 'nom%'
              and n.ord > v_field + 1 and n.ord < h.ord
         )
       order by h.ord limit 1;
      if v_birth_field is not null
         and nullif(btrim(coalesce(v_row->>(v_birth_field - 1), '')), '') is not null then
        v_birth_date := pg_catalog.to_date(btrim(v_row->>(v_birth_field - 1)), 'DD/MM/YYYY');
      end if;

      if v_header like 'nom de l''élève%' or v_header like 'nom de l''eleve%' then
        v_kind := 'student';
      elsif v_header like 'nom du tuteur%' then
        v_kind := 'guardian';
      elsif v_header = 'nom' and v_form_answer like '%moi%'
            and v_form_answer not like '%enfant%' then
        v_kind := 'adult';
      elsif v_header = 'nom' then
        v_kind := 'guardian';
      else
        v_kind := 'student';
      end if;

      v_key := pg_catalog.md5(
        v_email || pg_catalog.chr(31)
        || lower(pg_catalog.regexp_replace(btrim(v_last_name), '[[:space:]]+', ' ', 'g')) || pg_catalog.chr(31)
        || lower(pg_catalog.regexp_replace(btrim(v_first_name), '[[:space:]]+', ' ', 'g')) || pg_catalog.chr(31)
        || coalesce(v_birth_date::text, '')
      );
      if not v_key = any(v_person_keys) then
        v_person_keys := array_append(v_person_keys, v_key);
        v_people := v_people || pg_catalog.jsonb_build_array(pg_catalog.jsonb_build_object(
          'email', v_email, 'person_key', v_key, 'person_kind', v_kind,
          'first_name', v_first_name, 'last_name', v_last_name,
          'birth_date', v_birth_date, 'source_row', v_row_index + 1
        ));
      end if;
    end loop;
  end loop;

  -- Teacher rows are validated by the same preview. They form a household
  -- keyed by their own normalized email and have no assumed birth date.
  for v_row_index in 1..jsonb_array_length(v_teachers)-1 loop
    if exists (
      select 1 from jsonb_array_elements(v_report->'motifs_rejet') as r(value)
       where r.value->>'source' = 'enseignants'
         and (r.value->>'row')::integer = v_row_index + 1
    ) then
      continue;
    end if;
    v_row := v_teachers->v_row_index;
    select lower(btrim(coalesce(v_row->>((h.ord - 1)::integer), '')))
      into v_email
      from jsonb_array_elements_text(v_teacher_headers) with ordinality as h(value, ord)
     where lower(btrim(h.value)) = 'email'
     order by h.ord limit 1;
    select btrim(coalesce(v_row->>((h.ord - 1)::integer), ''))
      into v_first_name
      from jsonb_array_elements_text(v_teacher_headers) with ordinality as h(value, ord)
     where lower(btrim(h.value)) = 'prénom'
     order by h.ord limit 1;
    select btrim(coalesce(v_row->>((h.ord - 1)::integer), ''))
      into v_last_name
      from jsonb_array_elements_text(v_teacher_headers) with ordinality as h(value, ord)
     where lower(btrim(h.value)) = 'nom'
     order by h.ord limit 1;
    if v_email is null or v_email = '' or v_first_name is null or v_first_name = '' then continue; end if;
    if not v_email = any(v_emails) then v_emails := array_append(v_emails, v_email); end if;
    v_key := pg_catalog.md5(
      v_email || pg_catalog.chr(31)
      || lower(pg_catalog.regexp_replace(btrim(coalesce(v_last_name, '')), '[[:space:]]+', ' ', 'g')) || pg_catalog.chr(31)
      || lower(pg_catalog.regexp_replace(btrim(v_first_name), '[[:space:]]+', ' ', 'g')) || pg_catalog.chr(31)
    );
    if not v_key = any(v_person_keys) then
      v_person_keys := array_append(v_person_keys, v_key);
      v_people := v_people || pg_catalog.jsonb_build_array(pg_catalog.jsonb_build_object(
        'email', v_email, 'person_key', v_key, 'person_kind', 'teacher',
        'first_name', v_first_name, 'last_name', nullif(v_last_name, ''),
        'birth_date', null, 'source_row', v_row_index + 1
      ));
    end if;
  end loop;

  return pg_catalog.jsonb_build_object(
    'report', v_report,
    'emails', to_jsonb(v_emails),
    'persons', v_people
  );
end;
$function$;
alter function private.preparer_plan_import_inscriptions(text, text) owner to postgres;
revoke all on function private.preparer_plan_import_inscriptions(text, text)
  from public, anon, authenticated, service_role;

create or replace function public.confirmer_import_inscriptions(
  p_eleves_csv text,
  p_enseignants_csv text,
  p_options_foyers jsonb default '[]'::jsonb
) returns jsonb
language plpgsql
security definer
set search_path = ''
as $function$
declare
  v_plan jsonb;
  v_emails text[];
  v_person jsonb;
  v_option jsonb;
  v_email text;
  v_id uuid;
  v_guardian text;
  v_students text;
  v_welcome text;
  v_patience text;
  v_waited boolean;
  v_household_created boolean;
  v_households_created integer := 0;
  v_people_created integer := 0;
  v_people_existing integer := 0;
  v_rows integer;
  v_person_index integer;
begin
  if auth.uid() is null
     or public.app_role() is distinct from 'admin'::public.app_role
     or public.app_account_valid() is not true then
    raise exception using errcode = '42501', message = 'Accès refusé';
  end if;
  if p_options_foyers is null then p_options_foyers := '[]'::jsonb; end if;
  if jsonb_typeof(p_options_foyers) <> 'array'
     or exists (select 1 from jsonb_array_elements(p_options_foyers) as o(value)
                 where jsonb_typeof(o.value) <> 'object'
                    or nullif(lower(btrim(o.value->>'email')), '') is null
                    or (o.value ? 'a_patiente' and jsonb_typeof(o.value->'a_patiente') <> 'boolean')
                    or (o.value ? 'mot_accueil' and jsonb_typeof(o.value->'mot_accueil') not in ('string', 'null'))
                    or (o.value ? 'mot_patience' and jsonb_typeof(o.value->'mot_patience') not in ('string', 'null'))
                    or length(coalesce(o.value->>'mot_accueil', '')) > 3000
                    or length(coalesce(o.value->>'mot_patience', '')) > 3000)
     or exists (select lower(btrim(o.value->>'email'))
                  from jsonb_array_elements(p_options_foyers) as o(value)
                 group by lower(btrim(o.value->>'email')) having count(*) > 1) then
    raise exception using errcode = '22023', message = 'Options de foyer invalides';
  end if;

  v_plan := private.preparer_plan_import_inscriptions(p_eleves_csv, p_enseignants_csv);
  v_emails := array(select jsonb_array_elements_text(v_plan->'emails'));
  if exists (
    select 1 from jsonb_array_elements(p_options_foyers) as o(value)
     where not lower(btrim(o.value->>'email')) = any(v_emails)
  ) then
    raise exception using errcode = '22023', message = 'Option fournie pour un foyer absent de l’import';
  end if;

  foreach v_email in array v_emails loop
    select o.value into v_option
      from jsonb_array_elements(p_options_foyers) as o(value)
     where lower(btrim(o.value->>'email')) = v_email
     limit 1;
    v_waited := coalesce((v_option->>'a_patiente')::boolean, false);
    select p.value->>'first_name' into v_guardian
      from jsonb_array_elements(v_plan->'persons') as p(value)
     where p.value->>'email' = v_email
       and p.value->>'person_kind' in ('guardian', 'adult', 'teacher')
     order by (p.value->>'source_row')::integer,
              (p.value->>'person_kind' = 'guardian') desc,
              (p.value->>'person_kind' = 'adult') desc
     limit 1;
    select string_agg(p.value->>'first_name', ', ' order by (p.value->>'source_row')::integer)
      into v_students
      from jsonb_array_elements(v_plan->'persons') as p(value)
     where p.value->>'email' = v_email and p.value->>'person_kind' = 'student';
    v_guardian := coalesce(nullif(v_guardian, ''), v_students, 'votre famille');
    v_welcome := coalesce(nullif(btrim(v_option->>'mot_accueil'), ''),
      'Bonjour ' || v_guardian
      || case when nullif(v_students, '') is not null then ', les personnes inscrites avec vous sont ' || v_students else '' end
      || '. Les informations déjà fournies ont été enregistrées dans Rewayah Academy. Bienvenue.');
    v_patience := null;
    if v_waited then
      v_patience := coalesce(nullif(btrim(v_option->>'mot_patience'), ''),
        v_guardian || ', vous nous aviez demandé, il y a longtemps déjà, de vous inscrire, vous et '
        || coalesce(nullif(v_students, ''), 'votre famille')
        || '. Nous vous avions demandé d''attendre, et vous avez attendu, avec une patience et une confiance qui nous ont profondément touchés. '
        || 'Vous faites partie des toutes premières familles de la nouvelle Rewayah Academy. Bienvenue chez vous.'
        || E'\n[Signature du directeur]');
    end if;

    insert into private.preinscription_households
      (email_normalise, status, welcomed_at, a_patiente, waited_at, mot_accueil, mot_patience, confirmed_at, confirmed_by)
    values
      (v_email, 'confirmed', pg_catalog.statement_timestamp(), v_waited,
       case when v_waited then pg_catalog.statement_timestamp() else null end,
       v_welcome, v_patience,
       pg_catalog.statement_timestamp(), auth.uid())
    on conflict (email_normalise) do update set
      status = 'confirmed', welcomed_at = excluded.welcomed_at,
      a_patiente = excluded.a_patiente,
      waited_at = excluded.waited_at,
      mot_accueil = excluded.mot_accueil, mot_patience = excluded.mot_patience,
      confirmed_at = excluded.confirmed_at, confirmed_by = excluded.confirmed_by
    returning id, (xmax = 0) into v_id, v_household_created;
    if v_household_created then v_households_created := v_households_created + 1; end if;

    for v_person_index in 0..jsonb_array_length(v_plan->'persons')-1 loop
      v_person := v_plan->'persons'->v_person_index;
      if v_person->>'email' <> v_email then continue; end if;
      insert into private.preinscription_persons
        (household_id, person_kind, first_name, last_name, birth_date, source_row, person_key)
      values
        (v_id, v_person->>'person_kind', v_person->>'first_name', v_person->>'last_name',
         nullif(v_person->>'birth_date', '')::date, (v_person->>'source_row')::integer,
         v_person->>'person_key')
      on conflict (person_key) where person_key is not null do nothing;
      get diagnostics v_rows = row_count;
      if v_rows = 1 then v_people_created := v_people_created + 1;
      else v_people_existing := v_people_existing + 1; end if;
    end loop;
  end loop;

  perform public.log_sensitive_access(
    'preinscription_import_confirmed', 'preinscription_households', null,
    pg_catalog.jsonb_build_object(
      'households_created', v_households_created,
      'persons_created', v_people_created,
      'persons_existing', v_people_existing,
      'households_processed', cardinality(v_emails)
    )
  );
  return pg_catalog.jsonb_build_object(
    'foyers_traites', cardinality(v_emails),
    'foyers_crees', v_households_created,
    'personnes_creees', v_people_created,
    'personnes_deja_importees', v_people_existing,
    'journal_audit', true
  );
end;
$function$;
alter function public.confirmer_import_inscriptions(text, text, jsonb) owner to postgres;
revoke all on function public.confirmer_import_inscriptions(text, text, jsonb)
  from public, anon, service_role;
grant execute on function public.confirmer_import_inscriptions(text, text, jsonb) to authenticated;
comment on function public.confirmer_import_inscriptions(text, text, jsonb) is
  'Confirme un import CSV prévisualisé; idempotent par personne, réservé à un admin actif, journalise les compteurs sans données CSV ni PII.';

do $verification$
begin
  if has_function_privilege('anon', 'private.preparer_plan_import_inscriptions(text,text)', 'execute')
     or has_function_privilege('authenticated', 'private.preparer_plan_import_inscriptions(text,text)', 'execute')
     or has_function_privilege('service_role', 'private.preparer_plan_import_inscriptions(text,text)', 'execute')
     or has_function_privilege('anon', 'public.confirmer_import_inscriptions(text,text,jsonb)', 'execute')
     or has_function_privilege('service_role', 'public.confirmer_import_inscriptions(text,text,jsonb)', 'execute')
     or not has_function_privilege('authenticated', 'public.confirmer_import_inscriptions(text,text,jsonb)', 'execute') then
    raise exception 'IMM-ACCUEIL phase 2: confirmation ACL incorrecte';
  end if;
  if exists (
    select 1 from pg_catalog.pg_proc p
     where p.oid in (
       'private.preparer_plan_import_inscriptions(text,text)'::regprocedure,
       'public.confirmer_import_inscriptions(text,text,jsonb)'::regprocedure
     )
       and (not p.prosecdef or p.proowner <> 'postgres'::regrole
         or not (p.proconfig @> array['search_path=""']))
  ) then
    raise exception 'IMM-ACCUEIL phase 2: definer configuration incorrecte';
  end if;
end;
$verification$;

commit;
