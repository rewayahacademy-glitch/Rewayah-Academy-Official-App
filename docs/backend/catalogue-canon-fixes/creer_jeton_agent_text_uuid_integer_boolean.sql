CREATE OR REPLACE FUNCTION public.creer_jeton_agent(p_libelle text, p_profil_observe uuid, p_duree_heures integer DEFAULT 8, p_identite_masquee boolean DEFAULT true)
 RETURNS TABLE(jeton text, jeton_id uuid, expire_le timestamp with time zone)
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare
  v_secret text;
  v_role public.app_role;
  v_id uuid;
  v_expire timestamptz;
  v_immuable text;
begin
  if not coalesce(public.app_role() = 'admin' and public.app_account_valid(), false) then
    raise exception 'emission reservee a l administration'
      using errcode = '42501';
  end if;

  if coalesce(btrim(p_libelle), '') = '' then
    raise exception 'un jeton sans libelle ne se revoque jamais : libelle obligatoire'
      using errcode = '22023';
  end if;

  if p_duree_heures is null or p_duree_heures < 1 or p_duree_heures > 24 then
    raise exception 'duree hors bornes : de 1 a 24 heures'
      using errcode = '22023';
  end if;

  select p.role, p.immutable_id into v_role, v_immuable
  from public.profiles p
  where p.id = p_profil_observe
    and p.deleted_at is null
    and p.account_status in ('active', 'provisional_active');

  if v_role is null then
    raise exception 'profil observe introuvable, supprime ou inactif'
      using errcode = '23503';
  end if;

  -- 32 octets d'alea. `gen_random_bytes` vient de pgcrypto, installe en schema
  -- `extensions` par 0001 ; l'appel est qualifie parce que `search_path` est
  -- vide.
  v_secret := 'rag_' || encode(extensions.gen_random_bytes(32), 'hex');
  v_expire := now() + make_interval(hours => p_duree_heures);

  insert into public.jetons_agent (
    libelle, prefixe, empreinte, profil_observe, parcours,
    identite_masquee, expire_le, cree_par
  )
  values (
    btrim(p_libelle),
    left(v_secret, 12),
    encode(extensions.digest(convert_to(v_secret, 'UTF8'), 'sha256'), 'hex'),
    p_profil_observe,
    v_role,
    coalesce(p_identite_masquee, true),
    v_expire,
    auth.uid()
  )
  returning public.jetons_agent.id into v_id;

  perform public.log_sensitive_access(
    'agent_token_issued', 'jetons_agent', v_id::text,
    jsonb_build_object(
      'libelle', btrim(p_libelle),
      'parcours', v_role::text,
      'profil_observe', v_immuable,
      'identite_masquee', coalesce(p_identite_masquee, true),
      'expire_le', v_expire
    )
  );

  -- Le secret ne repassera jamais par ici.
  return query select v_secret, v_id, v_expire;
end;
$function$

