-- B-06 / SEC-04 — reserver la revue et l'ouverture des pieces KYC a la Direction.
-- Additif uniquement : les migrations deja appliquees ne sont jamais reecrites.
begin;

create or replace function public.read_kyc_documents()
returns setof public.kyc_documents
language plpgsql
security definer
set search_path = ''
as $function$
declare
  reader_gender public.gender;
begin
  if not coalesce(
    public.app_role() = 'admin' and public.app_account_valid(),
    false
  ) then
    raise exception 'acces KYC refuse';
  end if;

  select p.gender into reader_gender
  from public.profiles p
  where p.id = auth.uid() and p.deleted_at is null;

  if reader_gender is null then
    raise exception 'genre du lecteur inconnu : renseignez-le avant de consulter un dossier';
  end if;

  perform public.log_sensitive_access(
    'kyc_read',
    'kyc_documents',
    null::text,
    jsonb_build_object('reader_gender', reader_gender)
  );

  return query
    select k.*
    from public.kyc_documents k
    where k.deleted_at is null and k.gender = reader_gender;
end;
$function$;

create or replace function public.autoriser_lecture_piece_identite(p_document_id uuid)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $function$
declare
  v_piece public.kyc_documents;
begin
  if not coalesce(
    public.app_role() = 'admin' and public.app_account_valid(),
    false
  ) then
    raise exception 'lecture des pieces d''identite reservee a la Direction'
      using errcode = '42501';
  end if;

  if p_document_id is null then
    raise exception 'document non precise' using errcode = '22023';
  end if;

  select k.* into v_piece
  from public.read_kyc_documents() k
  where k.id = p_document_id;

  if not found then
    raise exception 'piece introuvable ou hors de votre perimetre'
      using errcode = '42501';
  end if;

  perform public.log_sensitive_access(
    'kyc_document_open',
    'kyc_documents',
    v_piece.id::text,
    jsonb_build_object(
      'profile_id', v_piece.profile_id,
      'storage_backend', v_piece.storage_backend,
      'status', v_piece.status
    )
  );

  return jsonb_build_object(
    'document_id', v_piece.id,
    'profile_id', v_piece.profile_id,
    'object_key', v_piece.object_key,
    'storage_backend', v_piece.storage_backend,
    'doc_type', v_piece.doc_type
  );
end;
$function$;

comment on function public.read_kyc_documents() is
  'B-06: Direction seulement; filtre de genre et audit de liste avant retour.';
comment on function public.autoriser_lecture_piece_identite(uuid) is
  'B-06/SEC-04: Direction active seulement; audite une piece avant que le serveur emette une URL courte.';

revoke all on function public.read_kyc_documents() from public, anon, agent_ro;
grant execute on function public.read_kyc_documents() to authenticated;
revoke all on function public.autoriser_lecture_piece_identite(uuid) from public, anon, agent_ro;
grant execute on function public.autoriser_lecture_piece_identite(uuid) to authenticated;

-- Les lectures et décisions passent par les RPC auditées. La policy historique
-- ALL permettait à un admin de lire/modifier directement la table, sans filtre
-- par genre ni événement par pièce.
drop policy if exists kyc_admin_all on public.kyc_documents;

-- Aucun client ne lit directement la table, même si une policy est ajoutée
-- par erreur plus tard. Les accès légitimes passent par les RPC auditées.
revoke select on table public.kyc_documents from public, anon, authenticated, agent_ro;

-- Le navigateur ne signe plus d'URL Storage directement. L'Edge Function
-- piece-identite-acces signe avec le client serveur après l'autorisation SQL.
do $storage$
begin
  if to_regclass('storage.objects') is not null then
    execute 'drop policy if exists kyc_lecture_admin on storage.objects';
  end if;
end
$storage$;

do $verify$
begin
  if not (
    select relrowsecurity
    from pg_catalog.pg_class
    where oid = 'public.kyc_documents'::regclass
  ) then
    raise exception 'B-06: RLS must remain enabled on kyc_documents';
  end if;

  if exists (
    select 1 from pg_catalog.pg_policies
    where schemaname = 'public'
      and tablename = 'kyc_documents'
      and cmd in ('ALL', 'SELECT')
  ) then
    raise exception 'B-06: direct KYC table read policy remains';
  end if;

  if pg_catalog.has_function_privilege('anon', 'public.read_kyc_documents()', 'execute')
     or pg_catalog.has_function_privilege('agent_ro', 'public.read_kyc_documents()', 'execute')
     or pg_catalog.has_function_privilege('anon', 'public.autoriser_lecture_piece_identite(uuid)', 'execute')
     or pg_catalog.has_function_privilege('agent_ro', 'public.autoriser_lecture_piece_identite(uuid)', 'execute') then
    raise exception 'B-06: anon or agent_ro retains a KYC RPC';
  end if;

  if not pg_catalog.has_function_privilege('authenticated', 'public.read_kyc_documents()', 'execute')
     or not pg_catalog.has_function_privilege('authenticated', 'public.autoriser_lecture_piece_identite(uuid)', 'execute') then
    raise exception 'B-06: authenticated lacks the guarded KYC RPC';
  end if;
end
$verify$;

commit;
