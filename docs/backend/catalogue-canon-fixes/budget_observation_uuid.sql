CREATE OR REPLACE FUNCTION public.budget_observation(p_session_id uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare
  v_seance  public.sessions%rowtype;
  v_pol     jsonb;
  v_ttl     int;
  v_visites int;
  v_temps   int;
  v_max_v   int;
  v_max_t   int;
  v_max_pv  int;
  v_ouverte int;
  v_reste_t int;
  v_reste_v int;
  v_restant int;
  v_peut    boolean;
  v_motif   text;
begin
  select * into v_seance from public.sessions s
   where s.id = p_session_id and s.deleted_at is null;
  if not found then
    return jsonb_build_object('peut_entrer', false, 'motif_refus', 'seance_non_active');
  end if;

  v_pol   := public.politique_observation_effective(v_seance.groupe_id);
  v_max_v := (v_pol->>'max_visits_per_session')::int;
  v_max_t := (v_pol->>'max_total_observation_seconds')::int;
  -- NULL quand la politique ne pose aucun plafond par visite : `->>` rend SQL
  -- NULL sur un null JSON, et c'est ce cas-la qu'il faut distinguer de zero.
  -- Zero voudrait dire « aucune seconde », NULL veut dire « pas de plafond ».
  v_max_pv := (v_pol->>'max_seconds_per_visit')::int;

  select vc.token_ttl_seconds into v_ttl from public.video_config vc where vc.id;
  v_ttl := coalesce(v_ttl, 300);

  select count(*) into v_visites
    from public.guardian_session_visit v
   where v.session_id = p_session_id
     and v.observateur_profile_id = auth.uid()
     and v.role = 'guardian_observer';

  -- Intervalle ouvert compte, plafonne au TTL du jeton (arbitrage §1.7).
  select coalesce(sum(
    case
      when v.left_at is not null
        then coalesce(v.duration_seconds, extract(epoch from (v.left_at - v.entered_at))::int)
      when now() - v.entered_at >= make_interval(secs => v_ttl) then v_ttl
      else extract(epoch from (now() - v.entered_at))::int
    end
  ), 0) into v_temps
    from public.guardian_session_visit v
   where v.session_id = p_session_id
     and v.observateur_profile_id = auth.uid()
     and v.role = 'guardian_observer';

  -- Ce que l'intervalle OUVERT a deja consomme, NULL quand il n'y en a pas.
  -- `guardian_visit_ouvert_uidx` (0032_tc_catalogue.sql:478-480) garantit au
  -- plus un intervalle ouvert par (seance, observateur) : le `limit 1` ne
  -- choisit pas entre deux lignes, il lit la seule qui puisse exister. Le meme
  -- plafonnement au TTL que ci-dessus, pour que les deux calculs disent la
  -- meme chose d'un intervalle reste ouvert au-dela de son jeton.
  -- CETTE VALEUR PORTE MAINTENANT DEUX ROLES : elle borne la duree, comme
  -- depuis 0036, et elle DIT LAQUELLE DES DEUX QUESTIONS se pose. `is not
  -- null` s'y lit « une visite est en cours ».
  select case
           when now() - v.entered_at >= make_interval(secs => v_ttl) then v_ttl
           else extract(epoch from (now() - v.entered_at))::int
         end
    into v_ouverte
    from public.guardian_session_visit v
   where v.session_id = p_session_id
     and v.observateur_profile_id = auth.uid()
     and v.role = 'guardian_observer'
     and v.left_at is null
   order by v.entered_at desc
   limit 1;

  v_reste_t := greatest(0, v_max_t - v_temps);
  -- Le reste de la visite : sous le plafond par visite pour l'intervalle
  -- ouvert, le plafond entier pour une visite a venir. Sans plafond par
  -- visite, il n'y a rien a borner et le reste total vaut pour les deux.
  -- Calcul repris mot pour mot de 0036 section C : il n'est pas touche.
  v_reste_v := case
                 when v_max_pv is null then v_reste_t
                 else greatest(0, v_max_pv - coalesce(v_ouverte, 0))
               end;
  v_restant := least(v_reste_t, v_reste_v);

  -- ==========================================================================
  -- LA QUESTION, CHOISIE PAR L'ETAT DE LA VISITE.
  --
  -- Le quota de VISITES ne se demande que lorsqu'il s'agit d'en ouvrir une
  -- nouvelle, c'est-a-dire quand aucun intervalle n'est ouvert. Ce n'est pas un
  -- desserrement : une visite ne nait que dans entrer_observation, qui appelle
  -- cette fonction AVANT son insertion (0033:1152-1161), donc a un moment ou
  -- `v_ouverte` est nul et ou le quota est bel et bien exige. Une fois la
  -- visite ouverte, la compter contre elle-meme ne protegeait rien : elle
  -- avait deja passe la porte.
  --
  -- Le temps, lui, est exige dans les DEUX cas, par `v_restant`, qui vaut le
  -- minimum du reste total et du reste de la visite. Une visite ouverte dont
  -- les deux minutes sont consommees est donc refusee, et refusee AVANT que
  -- autoriser_jeton_video ne tente d'inscrire un jeton de duree nulle.
  --
  -- Les trois conditions sont ecrites en EXIGENCE POSITIVE de ce qui doit etre
  -- vrai pour entrer -- politique allumee, quota non atteint, temps restant --
  -- et non en detection de fautes : un `if` qui ne se declenche pas sur une
  -- valeur absente laisserait passer.
  -- ==========================================================================
  if not (v_pol->>'observation_activee')::boolean then
    v_peut := false; v_motif := 'policy_desactivee';
  elsif v_ouverte is null and v_visites >= v_max_v then
    v_peut := false; v_motif := 'quota_visites_atteint';
  elsif v_restant <= 0 then
    v_peut := false; v_motif := 'temps_epuise';
  else
    v_peut := true; v_motif := null;
  end if;

  return jsonb_build_object(
    'policy_version', v_pol->>'policy_version',
    'visites_utilisees', v_visites,
    'visites_max', v_max_v,
    'temps_consomme_secondes', v_temps,
    'temps_total_max_secondes', v_max_t,
    -- LE MINIMUM DES DEUX RESTES, comme 0036 l'a pose. C'est ce nombre que le
    -- client affiche en compte a rebours (port_politique_observation.dart:
    -- 85-87) ET celui qui borne le jeton signe (0033:1733) : une seule verite,
    -- la meme des deux cotes, decidee ici.
    'restant_secondes', v_restant,
    -- Laquelle des deux questions a ete repondue. Cle neuve et purement
    -- informative : aucun client ne la lit aujourd'hui, et un client qui
    -- l'ignore lit le meme budget qu'avant. Elle existe pour qu'un journal ou
    -- une console d'exploitation puisse distinguer un refus d'entree d'une fin
    -- de visite sans avoir a rededuire l'etat.
    'visite_en_cours', (v_ouverte is not null),
    'peut_entrer', v_peut,
    'motif_refus', v_motif
  );
end;
$function$

