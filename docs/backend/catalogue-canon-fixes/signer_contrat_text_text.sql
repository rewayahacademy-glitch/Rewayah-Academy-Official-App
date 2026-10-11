CREATE OR REPLACE FUNCTION public.signer_contrat(p_version text, p_nom_saisi text)
 RETURNS contract_acceptances
 LANGUAGE plpgsql
 SET search_path TO ''
AS $function$
declare
  v_courant public.contract_texts%rowtype;
  v_signature public.contract_acceptances%rowtype;
  v_uid uuid := auth.uid();
begin
  if not coalesce(
    v_uid is not null
    and public.app_role() = 'teacher'::public.app_role,
    false
  ) then
    raise exception using errcode = '42501', message = 'acces_signature_refusee';
  end if;
  if not exists (
    select 1 from public.profiles p
    where p.id = v_uid and p.role = 'teacher'::public.app_role
      and p.deleted_at is null
      and p.account_status in (
        'pending_kyc'::public.account_status,
        'provisional_active'::public.account_status,
        'active'::public.account_status
      )
  ) then
    raise exception using errcode = '42501', message = 'acces_signature_refusee';
  end if;

  if p_nom_saisi is null or length(btrim(p_nom_saisi)) = 0 then
    raise exception using errcode = 'P0001', message = 'nom_vide';
  end if;
  if char_length(btrim(p_nom_saisi)) > 120 then
    raise exception using errcode = 'P0001', message = 'nom_trop_long';
  end if;

  select t.* into v_courant
  from public.contract_texts t
  where t.contract_kind = 'teacher_nda'
    and t.locale = 'fr'
    and t.is_current;

  if not found then
    raise exception using errcode = 'P0002', message = 'contrat_introuvable';
  end if;
  if p_version is distinct from v_courant.version then
    raise exception using
      errcode = 'P0001',
      message = 'version_perimee:' || v_courant.version;
  end if;

  insert into public.contract_acceptances (
    profile_id, contract_kind, version, signer_name
  ) values (
    v_uid, 'teacher_nda', v_courant.version, btrim(p_nom_saisi)
  )
  on conflict (profile_id, contract_kind, version) do nothing
  returning * into v_signature;

  if not found then
    select c.* into v_signature
    from public.contract_acceptances c
    where c.profile_id = v_uid
      and c.contract_kind = 'teacher_nda'
      and c.version = v_courant.version;
  end if;

  if v_signature.id is null or v_signature.signed_sha256 is null
     or v_signature.signer_name is null then
    raise exception 'signature enseignant incomplete';
  end if;
  return v_signature;
end;
$function$

