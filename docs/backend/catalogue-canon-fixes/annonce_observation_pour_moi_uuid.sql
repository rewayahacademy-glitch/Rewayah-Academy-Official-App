CREATE OR REPLACE FUNCTION public.annonce_observation_pour_moi(p_session_id uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare
  v_depuis timestamptz;
begin
  -- Porte d'entree, en EXIGENCE POSITIVE. Avec auth.uid() nul, `not exists`
  -- est vrai et la porte se FERME.
  if not exists (
    select 1
      from public.sessions s
      join public.groupe_membres m
        on m.groupe_id = s.groupe_id
       and m.left_at is null
     where s.id = p_session_id
       and s.deleted_at is null
       and m.student_id = auth.uid()
       and public.app_account_valid()
  ) then
    raise exception 'reserve a l''eleve du groupe de cette seance'
      using errcode = 'insufficient_privilege';
  end if;

  -- LE VERROU DE VIE PRIVEE, en deux clauses qui disent la meme chose de deux
  -- facons : la visite me designe, OU son observateur est de mon foyer. La
  -- seconde couvre le cas de deux freres dans le meme groupe, que la premiere
  -- manquait. Aucune des deux n'atteint un autre foyer.
  select v.entered_at into v_depuis
    from public.guardian_session_visit v
   where v.session_id = p_session_id
     and v.role = 'guardian_observer'
     and v.left_at is null
     and (
       v.enfant_profile_id = auth.uid()
       or public.est_du_foyer(v.observateur_profile_id)
     )
   order by v.entered_at desc
   limit 1;

  -- Deux faits, pas un de plus. Ni identite de l'observateur, ni numero de
  -- visite, ni compteur : un compteur renseignerait sur les autres foyers.
  return jsonb_build_object(
    'observe', v_depuis is not null,
    'depuis',  v_depuis
  );
end;
$function$

