-- D6 (24/10/2026, decision du pilote deleguee par le directeur) : l'enfant
-- entre en salle depuis l'appareil de son tuteur, sans appairage. L'appairage
-- reste une option pour une tablette de l'enfant.
--
-- 1. public.autoriser_jeton_video_eleve(p_session_id, p_tuteur_id, p_eleve_id,
--    p_ws_url_cloud, p_ws_url_self_hosted), reservee au serveur
--    (create-room-token, sous service_role ; p_tuteur_id est l'identifiant lu
--    dans le jeton Supabase verifie, jamais une valeur du corps).
--    * le tuteur : profil guardian, non supprime, actif ou provisoire, acces
--      non echu, avec un foyer ;
--    * l'eleve : profil student du MEME foyer, participant eleve non supprime
--      de la seance ;
--    * le jeton est celui de l'ELEVE : autoriser_jeton_video est appelee pour
--      l'eleve, inchangee (compte, seance close, fenetre, suspension pour
--      paiement, capacites, camera, video_token_grants, journal) ;
--    * aucune elevation : tout autre role que 'student' rendu par
--      autoriser_jeton_video est refuse (l'exception annule tout, y compris la
--      ligne de video_token_grants) ;
--    * le journal note `demande_par` (le tuteur) dans audit_logs.
--    autoriser_jeton_video elle-meme n'est pas modifiee.
-- 2. D8 : quitter_salle accepte aussi l'enseignant de la seance
--    (sessions.teacher_id) et l'enseignant effectif (remplacant designe) :
--    materialiser_seances_groupe n'inscrit que les eleves dans
--    session_participants, et l'enseignant recevait 42501 en sortant.
--
-- Aucune suppression.

BEGIN;

CREATE FUNCTION public.autoriser_jeton_video_eleve(
  p_session_id uuid,
  p_tuteur_id uuid,
  p_eleve_id uuid,
  p_ws_url_cloud text,
  p_ws_url_self_hosted text
)
RETURNS jsonb
LANGUAGE plpgsql SECURITY DEFINER SET search_path = ''
AS $function$
declare
  v_foyer uuid;
  v_acces jsonb;
begin
  select p.household_id into v_foyer
    from public.profiles p
   where p.id = p_tuteur_id
     and p.role = 'guardian'
     and p.deleted_at is null
     and p.account_status in ('active', 'provisional_active')
     and (p.access_until is null or p.access_until > now());
  if v_foyer is null then
    raise exception 'tuteur non valide' using errcode = 'insufficient_privilege';
  end if;

  if not exists (
    select 1 from public.profiles e
     where e.id = p_eleve_id
       and e.role = 'student'
       and e.deleted_at is null
       and e.household_id = v_foyer
  ) then
    raise exception 'eleve hors du foyer' using errcode = 'insufficient_privilege';
  end if;

  if not exists (
    select 1 from public.session_participants sp
     where sp.session_id = p_session_id
       and sp.profile_id = p_eleve_id
       and sp.role = 'student'
       and sp.deleted_at is null
  ) then
    raise exception 'non inscrit a cette seance' using errcode = 'insufficient_privilege';
  end if;

  v_acces := public.autoriser_jeton_video(
    p_session_id, p_eleve_id, p_ws_url_cloud, p_ws_url_self_hosted
  );

  if v_acces->>'role' is distinct from 'student' then
    raise exception 'role refuse par ce chemin' using errcode = 'insufficient_privilege';
  end if;

  perform public.log_sensitive_access(
    'video_token_par_tuteur',
    'video_token_grants',
    p_session_id::text,
    jsonb_build_object(
      'profile_id', p_eleve_id,
      'demande_par', p_tuteur_id,
      'role', v_acces->>'role'
    )
  );

  return v_acces;
end;
$function$;

REVOKE EXECUTE ON FUNCTION public.autoriser_jeton_video_eleve(uuid, uuid, uuid, text, text)
  FROM PUBLIC, anon, authenticated, agent_ro;
GRANT EXECUTE ON FUNCTION public.autoriser_jeton_video_eleve(uuid, uuid, uuid, text, text)
  TO service_role;

-- D8 : l'enseignant de la seance sort aussi par quitter_salle.
CREATE OR REPLACE FUNCTION public.quitter_salle(p_session_id uuid)
RETURNS void
LANGUAGE plpgsql VOLATILE SECURITY DEFINER SET search_path = ''
AS $$
begin
  if not (
    public.session_has_participant(p_session_id, auth.uid())
    or exists (
      select 1 from public.sessions s
       where s.id = p_session_id and s.deleted_at is null
         and s.teacher_id = auth.uid()
    )
    or private.c29_enseignant_effectif_session(p_session_id) = auth.uid()
  ) then
    raise exception 'non inscrit a cette seance' using errcode = 'insufficient_privilege';
  end if;

  insert into public.session_events (session_id, profile_id, event_type, source)
  values (p_session_id, auth.uid(), 'left', 'user_action');
end;
$$;

COMMIT;
