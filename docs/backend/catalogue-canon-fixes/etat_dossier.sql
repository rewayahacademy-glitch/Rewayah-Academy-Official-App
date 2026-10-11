CREATE OR REPLACE FUNCTION public.etat_dossier()
 RETURNS jsonb
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare
  v_profile public.profiles;
  v_doc public.kyc_documents;
  v_contrat boolean;
  v_accuse boolean;
begin
  if auth.uid() is null then
    raise exception 'aucune session';
  end if;

  select * into v_profile
  from public.profiles p where p.id = auth.uid() and p.deleted_at is null;

  -- Aucun profil : c'est une inscription a terminer, pas un dossier a attendre.
  if v_profile.id is null then
    return jsonb_build_object('profil', false);
  end if;

  select * into v_doc
  from public.kyc_documents k
  where k.profile_id = v_profile.id and k.deleted_at is null
  order by k.created_at desc
  limit 1;

  select exists (
    select 1 from public.contract_acceptances c
    where c.profile_id = v_profile.id
      and c.contract_kind = case when v_profile.role = 'teacher'
                                 then 'teacher_nda' else 'guardian_terms' end
  ) into v_contrat;

  select exists (
    select 1 from public.contract_acceptances c
    where c.profile_id = v_profile.id
      and c.contract_kind = 'recording_and_control_notice'
  ) into v_accuse;

  return jsonb_build_object(
    'profil', true,
    'role', v_profile.role::text,
    'statut', v_profile.account_status::text,
    'piece_deposee', v_doc.id is not null,
    'piece_statut', v_doc.status::text,
    'motif_refus', v_doc.rejection_reason,
    'depose_le', v_doc.created_at,
    'contrat_signe', v_contrat,
    'accuse_signe', v_accuse
  );
end;
$function$

