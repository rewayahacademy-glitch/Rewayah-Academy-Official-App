CREATE OR REPLACE FUNCTION public.remettre_session_agent(p_jeton text)
 RETURNS TABLE(jeton_id uuid, profil_observe uuid, parcours app_role, foyer uuid, identite_masquee boolean, expire_le timestamp with time zone)
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare
  v_empreinte text;
  v_ligne public.jetons_agent;
  v_profil public.profiles;
begin
  if coalesce(btrim(p_jeton), '') = '' then
    raise exception 'jeton absent' using errcode = '28000';
  end if;

  v_empreinte := encode(
    extensions.digest(convert_to(p_jeton, 'UTF8'), 'sha256'), 'hex');

  select * into v_ligne
  from public.jetons_agent t
  where t.empreinte = v_empreinte;

  -- Un message unique pour les trois cas. « Jeton inconnu » et « jeton expire »
  -- se distinguent pour le porteur legitime, pas pour celui qui essaie.
  if v_ligne.id is null
     or v_ligne.revoque_le is not null
     or v_ligne.expire_le <= now()
  then
    raise exception 'jeton refuse' using errcode = '28000';
  end if;

  select * into v_profil
  from public.profiles p
  where p.id = v_ligne.profil_observe
    and p.deleted_at is null
    and p.account_status in ('active', 'provisional_active');

  if v_profil.id is null then
    raise exception 'jeton refuse' using errcode = '28000';
  end if;

  -- Le parcours a ete FIGE a l'emission. Si le role du profil a change depuis,
  -- le jeton ne decrit plus la realite : il ne se rattrape pas en silence.
  if v_profil.role <> v_ligne.parcours then
    raise exception 'jeton refuse' using errcode = '28000';
  end if;

  update public.jetons_agent
     set derniere_remise_le = now(), remises = remises + 1
   where id = v_ligne.id;

  perform public.log_sensitive_access(
    'agent_session_opened', 'jetons_agent', v_ligne.id::text,
    jsonb_build_object(
      'libelle', v_ligne.libelle,
      'parcours', v_ligne.parcours::text,
      'profil_observe', v_profil.immutable_id
    )
  );

  return query
    select v_ligne.id, v_profil.id, v_ligne.parcours, v_profil.household_id,
           v_ligne.identite_masquee, v_ligne.expire_le;
end;
$function$

