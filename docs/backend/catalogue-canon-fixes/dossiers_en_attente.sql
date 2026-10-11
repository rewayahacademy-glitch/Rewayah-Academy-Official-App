CREATE OR REPLACE FUNCTION public.dossiers_en_attente()
 RETURNS TABLE(profile_id uuid, immutable_id text, first_name text, last_name text, role app_role, account_status account_status, inscrit_le timestamp with time zone, document_id uuid, doc_type text, document_gender gender, object_key text, depose_le timestamp with time zone, etat_piece text)
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare
  v_en_attente int;
  v_masque boolean := public.agent_identite_masquee();
begin
  -- Exigence POSITIVE, jamais un refus : `app_role()` rend NULL pour un
  -- appelant anonyme, et un refus ecrit `<> 'admin'` ne se declenche pas sur
  -- NULL. Le `coalesce` fait que toute inconnue ferme la porte.
  if not coalesce(public.app_role() = 'admin', false) then
    raise exception 'validation des dossiers reservee a l''administration'
      using errcode = '42501';
  end if;

  select count(*) into v_en_attente
  from public.kyc_documents k
  where k.status = 'pending' and k.deleted_at is null;

  if v_en_attente = 0 then
    return query
      select p.id, p.immutable_id,
        case when v_masque then null else p.first_name end,
        case when v_masque then null else p.last_name end,
        p.role, p.account_status, p.created_at,
        null::uuid, null::text, null::public.gender, null::text,
        null::timestamptz, 'aucune'::text
      from public.profiles p
      where p.deleted_at is null and p.account_status = 'pending_kyc'
      order by p.created_at asc;
    return;
  end if;

  return query
    with visibles as (
      select k.* from public.read_kyc_documents() k where k.status = 'pending'
    )
    select p.id, p.immutable_id,
      case when v_masque then null else p.first_name end,
      case when v_masque then null else p.last_name end,
      p.role, p.account_status, p.created_at,
      v.id, v.doc_type, v.gender, v.object_key, v.created_at,
      case
        when v.id is not null then 'a_verifier'
        when exists (
          select 1 from public.kyc_documents k2
          where k2.profile_id = p.id and k2.status = 'pending'
            and k2.deleted_at is null
        ) then 'non_visible'
        else 'aucune'
      end::text
    from public.profiles p
    left join visibles v on v.profile_id = p.id
    where p.deleted_at is null
      and (p.account_status = 'pending_kyc' or v.id is not null)
    order by coalesce(v.created_at, p.created_at) asc;
end;
$function$

