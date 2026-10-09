-- SEC-01 : conserver l'identite opaque du jeton dans le JWT, tout en gardant
-- les policies existantes bornees au profil observe par auth.uid().
--
-- PostgREST execute db_pre_request sous le role de requete dans une transaction.
-- La substitution transaction-locale n'arrive qu'apres validation de la ligne
-- du jeton ET du profil observe ; un jeton mort ou devenu incoherent ne peut
-- donc pas choisir un sujet.
create or replace function public.agent_pre_request()
returns void
language plpgsql stable security definer
set search_path = ''
as $agent_pre_request$
declare
  v_id uuid;
  v_profil_observe uuid;
begin
  v_id := public.agent_jeton_id();
  if v_id is null then
    return;
  end if;

  select t.profil_observe
    into v_profil_observe
  from public.jetons_agent t
  join public.profiles p on p.id = t.profil_observe
  where t.id = v_id
    and t.revoque_le is null
    and t.expire_le > now()
    and p.deleted_at is null
    and p.account_status in ('active', 'provisional_active')
    and p.role = t.parcours;

  if v_profil_observe is null then
    raise exception 'jeton agent revoque, expire ou incoherent'
      using errcode = '42501';
  end if;

  perform set_config('request.jwt.claim.sub', v_profil_observe::text, true);
end;
$agent_pre_request$;

comment on function public.agent_pre_request() is
  'Valide la session agent a chaque requete et substitue auth.uid() par le profil observe apres validation. Le JWT conserve sub = agent_token_id.';
