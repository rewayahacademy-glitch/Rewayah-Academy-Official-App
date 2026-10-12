begin;

create schema if not exists private;

create table private.preinscription_households (
  id uuid primary key default gen_random_uuid(),
  email_normalise text not null unique,
  status text not null default 'pre_registered'
    check (status in ('pre_registered', 'confirmed', 'rejected')),
  welcomed_at timestamptz,
  waited_at timestamptz,
  created_at timestamptz not null default now()
);

create table private.preinscription_persons (
  id uuid primary key default gen_random_uuid(),
  household_id uuid not null references private.preinscription_households(id) on delete cascade,
  person_kind text not null check (person_kind in ('adult', 'guardian', 'student', 'teacher')),
  first_name text,
  last_name text,
  birth_date date,
  source_row integer not null check (source_row > 1),
  created_at timestamptz not null default now()
);

comment on table private.preinscription_households is
  'Destinataires préenregistrés; seule la future phase de confirmation écrit dans cette table.';
comment on table private.preinscription_persons is
  'Personnes préenregistrées; la RPC de prévisualisation ne persiste aucune ligne.';

alter table private.preinscription_households enable row level security;
alter table private.preinscription_persons enable row level security;
revoke all on private.preinscription_households, private.preinscription_persons
  from public, anon, authenticated, service_role;

-- Decode RFC 4180 CSV without depending on column positions; the caller maps
-- duplicate header names by occurrence after this parser returns each row.
create function private.parse_import_csv(p_csv text)
returns jsonb
language plpgsql immutable security definer set search_path = ''
as $$
declare
  result jsonb := '[]'::jsonb;
  row_values jsonb := '[]'::jsonb;
  cell text := '';
  quoted boolean := false;
  just_closed_quote boolean := false;
  i integer := 1;
  ch text;
  next_ch text;
begin
  if p_csv is null or length(p_csv) > 5000000 then
    raise exception using errcode = '22023', message = 'CSV absent ou supérieur à 5 Mo';
  end if;
  if left(p_csv, 1) = chr(65279) then p_csv := substring(p_csv from 2); end if;
  while i <= length(p_csv) loop
    ch := substring(p_csv from i for 1);
    next_ch := substring(p_csv from i + 1 for 1);
    if quoted then
      if ch = '"' and next_ch = '"' then
        cell := cell || '"'; i := i + 1;
      elsif ch = '"' then
        quoted := false;
        just_closed_quote := true;
      else
        cell := cell || ch;
      end if;
    elsif just_closed_quote and ch not in (',', E'\n', E'\r') then
      raise exception using errcode = '22023', message = 'CSV mal formé après un guillemet fermant';
    elsif ch = '"' then
      if cell <> '' then raise exception using errcode = '22023', message = 'CSV mal formé'; end if;
      quoted := true;
    elsif ch = ',' then
      row_values := row_values || jsonb_build_array(cell); cell := ''; just_closed_quote := false;
    elsif ch = E'\n' or ch = E'\r' then
      row_values := row_values || jsonb_build_array(cell);
      if row_values <> jsonb_build_array('') then result := result || jsonb_build_array(row_values); end if;
      row_values := '[]'::jsonb; cell := ''; just_closed_quote := false;
      if ch = E'\r' and next_ch = E'\n' then i := i + 1; end if;
    else
      cell := cell || ch;
    end if;
    i := i + 1;
  end loop;
  if quoted then raise exception using errcode = '22023', message = 'CSV mal formé: guillemet non fermé'; end if;
  if cell <> '' or jsonb_array_length(row_values) > 0 then
    row_values := row_values || jsonb_build_array(cell);
    result := result || jsonb_build_array(row_values);
  end if;
  return result;
end;
$$;
alter function private.parse_import_csv(text) owner to postgres;
revoke all on function private.parse_import_csv(text) from public, anon, authenticated, service_role;

create function public.previsualiser_import_inscriptions(p_eleves_csv text, p_enseignants_csv text)
returns jsonb
language plpgsql security definer set search_path = ''
as $$
declare
  students jsonb;
  teachers jsonb;
  student_headers jsonb;
  teacher_headers jsonb;
  row_data jsonb;
  v_cell_text text;
  email_value text;
  unique_emails text[] := array[]::text[];
  seen_emails text[] := array[]::text[];
  row_index integer;
  field_index integer;
  header_name text;
  paired_first_name text;
  occurrence_no integer;
  paired_header_index integer;
  test_row boolean;
  has_person_name boolean;
  invalid_date boolean;
  empty_rows integer := 0;
  invalid_rows integer := 0;
  people_count integer := 0;
  row_people_count integer := 0;
  duplicate_rows integer := 0;
  rejected jsonb := '[]'::jsonb;
begin
  if auth.uid() is null
     or public.app_role() is distinct from 'admin'::public.app_role
     or public.app_account_valid() is not true then
    raise exception using errcode = '42501', message = 'Accès refusé';
  end if;
  students := private.parse_import_csv(p_eleves_csv);
  teachers := private.parse_import_csv(p_enseignants_csv);
  if jsonb_array_length(students) = 0 or jsonb_array_length(teachers) = 0 then
    raise exception using errcode = '22023', message = 'Les deux CSV doivent contenir une ligne d’en-tête';
  end if;
  student_headers := students->0;
  teacher_headers := teachers->0;
  if not exists (select 1 from jsonb_array_elements_text(student_headers) as h(value) where lower(btrim(value)) = 'email')
     or not exists (select 1 from jsonb_array_elements_text(teacher_headers) as h(value) where lower(btrim(value)) = 'email') then
    raise exception using errcode = '22023', message = 'En-tête Email requis dans les deux CSV';
  end if;
  for row_index in 1..jsonb_array_length(students)-1 loop
    row_data := students->row_index;
    if not exists (select 1 from jsonb_array_elements_text(row_data) as cells(value) where btrim(value) <> '') then
      empty_rows := empty_rows + 1;
      rejected := rejected || jsonb_build_array(jsonb_build_object('source','eleves','row',row_index+1,'reason','empty_row'));
      continue;
    end if;
    test_row := false;
    has_person_name := false;
    row_people_count := 0;
    email_value := null;
    invalid_date := false;
    if jsonb_array_length(row_data) <> jsonb_array_length(student_headers) then
      invalid_rows := invalid_rows + 1;
      rejected := rejected || jsonb_build_array(jsonb_build_object('source','eleves','row',row_index+1,'reason','column_count_mismatch'));
      continue;
    end if;
    email_value := null;
    for field_index in 0..jsonb_array_length(student_headers)-1 loop
      header_name := lower(btrim(student_headers->>field_index));
      v_cell_text := btrim(row_data->>field_index);
      if lower(v_cell_text) in ('test','testing','demo','dummy','test row','ligne test','dummy row','demo row','sample row')
         or lower(v_cell_text) ~ '^(test|demo|dummy)@' then test_row := true; end if;
      if header_name like '%date de naissance%' and v_cell_text <> '' then
        begin
          if v_cell_text !~ '^(0[1-9]|[12][0-9]|3[01])/(0[1-9]|1[0-2])/[0-9]{4}$'
             or pg_catalog.to_char(pg_catalog.to_date(v_cell_text, 'DD/MM/YYYY'), 'DD/MM/YYYY') <> v_cell_text then
            invalid_date := true;
          end if;
        exception when others then
          invalid_date := true;
        end;
        if invalid_date then
          invalid_rows := invalid_rows + 1;
          rejected := rejected || jsonb_build_array(jsonb_build_object('source','eleves','row',row_index+1,'reason','invalid_birth_date'));
          exit;
        end if;
      end if;
      if v_cell_text <> '' and header_name like 'nom%' then
        paired_first_name := regexp_replace(header_name, '^nom', 'prénom');
        select count(*)::integer into occurrence_no
        from jsonb_array_elements_text(student_headers) with ordinality as h(value, ord)
        where lower(btrim(h.value)) = header_name and h.ord <= field_index + 1;
        select h.ord::integer into paired_header_index
        from jsonb_array_elements_text(student_headers) with ordinality as h(value, ord)
        where lower(btrim(h.value)) = paired_first_name
          and (select count(*) from jsonb_array_elements_text(student_headers) with ordinality as prior(value, ord)
               where lower(btrim(prior.value)) = paired_first_name and prior.ord <= h.ord) = occurrence_no
        order by h.ord
        limit 1;
        if paired_header_index is not null
           and btrim(coalesce(row_data->>(paired_header_index - 1), '')) <> '' then
          has_person_name := true;
          row_people_count := row_people_count + 1;
        end if;
      end if;
      if header_name in ('email','email du tuteur') and v_cell_text <> '' then
        if header_name = 'email du tuteur' or email_value is null then email_value := lower(v_cell_text); end if;
        if not lower(v_cell_text) ~ '^[^[:space:]@]+@[^[:space:]@]+\.[^[:space:]@]+$' then
          invalid_rows := invalid_rows + 1;
          rejected := rejected || jsonb_build_array(jsonb_build_object('source','eleves','row',row_index+1,'reason','invalid_email'));
          email_value := null;
          exit;
        end if;
      end if;
    end loop;
    if invalid_date then continue; end if;
    if email_value is null and rejected @> jsonb_build_array(jsonb_build_object('source','eleves','row',row_index+1,'reason','invalid_email')) then
      continue;
    end if;
    if test_row then
      invalid_rows := invalid_rows + 1;
      rejected := rejected || jsonb_build_array(jsonb_build_object('source','eleves','row',row_index+1,'reason','test_row'));
      continue;
    end if;
    if not has_person_name then
      invalid_rows := invalid_rows + 1;
      rejected := rejected || jsonb_build_array(jsonb_build_object('source','eleves','row',row_index+1,'reason','missing_person_name'));
      continue;
    end if;
    if email_value is null then
      invalid_rows := invalid_rows + 1;
      rejected := rejected || jsonb_build_array(jsonb_build_object('source','eleves','row',row_index+1,'reason','missing_email'));
      continue;
    end if;
    people_count := people_count + row_people_count;
    if email_value = any(seen_emails) then duplicate_rows := duplicate_rows + 1;
    else seen_emails := array_append(seen_emails,email_value); end if;
    if not email_value = any(unique_emails) then unique_emails := array_append(unique_emails,email_value); end if;
  end loop;
  for row_index in 1..jsonb_array_length(teachers)-1 loop
    row_data := teachers->row_index;
    if not exists (select 1 from jsonb_array_elements_text(row_data) as cells(value) where btrim(value) <> '') then
      empty_rows := empty_rows + 1;
      rejected := rejected || jsonb_build_array(jsonb_build_object('source','enseignants','row',row_index+1,'reason','empty_row'));
      continue;
    end if;
    test_row := false;
    has_person_name := false;
    email_value := null;
    if jsonb_array_length(row_data) <> jsonb_array_length(teacher_headers) then
      invalid_rows := invalid_rows + 1;
      rejected := rejected || jsonb_build_array(jsonb_build_object('source','enseignants','row',row_index+1,'reason','column_count_mismatch'));
      continue;
    end if;
    for field_index in 0..jsonb_array_length(teacher_headers)-1 loop
      header_name := lower(btrim(teacher_headers->>field_index));
      v_cell_text := btrim(row_data->>field_index);
      if lower(v_cell_text) in ('test','testing','demo','dummy','test row','ligne test','dummy row','demo row','sample row')
         or lower(v_cell_text) ~ '^(test|demo|dummy)@' then test_row := true; end if;
      if header_name = 'prénom' and v_cell_text <> '' then has_person_name := true; end if;
      if header_name = 'email' and v_cell_text <> '' then
        email_value := lower(v_cell_text);
        if not email_value ~ '^[^[:space:]@]+@[^[:space:]@]+\.[^[:space:]@]+$' then
          invalid_rows := invalid_rows + 1;
          rejected := rejected || jsonb_build_array(jsonb_build_object('source','enseignants','row',row_index+1,'reason','invalid_email'));
          has_person_name := false;
          exit;
        end if;
        email_value := lower(v_cell_text);
      end if;
    end loop;
    if rejected @> jsonb_build_array(jsonb_build_object('source','enseignants','row',row_index+1,'reason','invalid_email')) then continue; end if;
    if test_row then
      invalid_rows := invalid_rows + 1;
      rejected := rejected || jsonb_build_array(jsonb_build_object('source','enseignants','row',row_index+1,'reason','test_row'));
      continue;
    end if;
    if not has_person_name then
      invalid_rows := invalid_rows + 1;
      rejected := rejected || jsonb_build_array(jsonb_build_object('source','enseignants','row',row_index+1,'reason','missing_person_name'));
      continue;
    end if;
    if email_value is null then
      invalid_rows := invalid_rows + 1;
      rejected := rejected || jsonb_build_array(jsonb_build_object('source','enseignants','row',row_index+1,'reason','missing_email'));
      continue;
    end if;
    people_count := people_count + 1;
    if email_value = any(seen_emails) then duplicate_rows := duplicate_rows + 1;
    else seen_emails := array_append(seen_emails,email_value); end if;
  end loop;
  return jsonb_build_object(
    'foyers',coalesce(cardinality(unique_emails),0),
    'personnes',people_count,
    'doublons',duplicate_rows,
    'lignes_rejetees',invalid_rows+empty_rows,
    'motifs_rejet',rejected,
    'ecriture_effectuee',false
  );
end;
$$;
alter function public.previsualiser_import_inscriptions(text,text) owner to postgres;
revoke all on function public.previsualiser_import_inscriptions(text,text) from public, anon, service_role;
grant execute on function public.previsualiser_import_inscriptions(text,text) to authenticated;
comment on function public.previsualiser_import_inscriptions(text,text) is
  'Prévisualisation sans écriture des CSV Élèves et Enseignants; admin actif requis, aucune valeur CSV ni donnée personnelle renvoyée.';

commit;
