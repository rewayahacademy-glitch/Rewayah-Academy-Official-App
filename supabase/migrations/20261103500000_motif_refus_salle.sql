-- FN-025 (lot « Fin de seance », etape 2, arbitrage du pilote du 01/11/2026) :
-- dire pourquoi la salle est refusee, a qui y a droit, et a personne d'autre.
--
-- `create-room-token` change toute exception de `autoriser_jeton_video` en
-- un seul 403 « acces a la salle refuse ». C'est voulu : un appelant ne doit
-- pas apprendre qu'une salle qui n'est pas la sienne existe, est commencee ou
-- close. Or `autoriser_jeton_video` teste le statut (« seance close ») AVANT
-- l'inscription : renvoyer son message dirait a un inconnu qu'une seance est
-- close. La regle d'appartenance reste donc dans la base, ici.
--
-- `public.motif_refus_salle(p_session_id, p_profile_id, p_eleve_id)` :
--   * lecture seule (STABLE), SECURITY DEFINER, search_path vide ;
--   * appelee par la fonction Edge APRES un refus, avec la cle de service
--     seule (EXECUTE retire a PUBLIC, anon, authenticated, agent_ro) ; elle est
--     dans `public` parce que PostgREST n'expose que ce schema (config.toml) ;
--   * ne rend un motif qu'a qui pouvait entrer : participant de la seance
--     (eleve, enseignant, observateur...), enseignant effectif
--     (`private.c29_enseignant_effectif_session`), ou tuteur qui demande pour
--     un eleve de SON foyer inscrit a la seance (chemin de
--     `autoriser_jeton_video_eleve`). Sinon NULL : le refus reste generique ;
--   * motifs : `pas_encore_ouverte` (avant l'ouverture), `terminee` (seance
--     close par son statut `ended`, ou fenetre depassee : fin plus
--     `grace_after_end_minutes`), `annulee` (statut `canceled`,
--     `canceled_late`). Seance ouverte (le refus a une autre cause) : NULL ;
--   * rend aussi `fin_utc` (fin prevue), `ouverture_utc` et `grace_minutes`,
--     valeurs du serveur : le client n'ecrit aucun nombre fige.
--
-- Aucune ecriture, aucun mot de suppression. Les droits sont prouves en fin
-- de fichier par `has_function_privilege`.

BEGIN;

CREATE FUNCTION public.motif_refus_salle(
  p_session_id uuid,
  p_profile_id uuid,
  p_eleve_id uuid DEFAULT NULL
)
RETURNS jsonb
LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path = ''
AS $function$
declare
  v_seance    record;
  v_fenetre   int := public.app_config_int('join_window_minutes', 20);
  v_grace     int := public.app_config_int('grace_after_end_minutes', 15);
  v_foyer     uuid;
  v_qui       uuid;
  v_ouverture timestamptz;
  v_autorise  boolean := false;
  v_motif     text;
begin
  if p_session_id is null or p_profile_id is null then
    return null;
  end if;

  select s.id, s.status, s.started_at, s.ended_at, s.join_opens_at
    into v_seance
    from public.sessions s
   where s.id = p_session_id
     and s.deleted_at is null;
  if not found then
    return null;
  end if;

  -- Qui pouvait entrer. Exigence positive : sans preuve, aucun motif.
  if p_eleve_id is not null then
    -- Chemin du tuteur pour un eleve : meme preuve que
    -- `autoriser_jeton_video_eleve` (tuteur valide, eleve de son foyer).
    select p.household_id into v_foyer
      from public.profiles p
     where p.id = p_profile_id
       and p.role = 'guardian'
       and p.deleted_at is null
       and p.account_status in ('active', 'provisional_active');
    if v_foyer is not null and exists (
      select 1 from public.profiles e
       where e.id = p_eleve_id
         and e.role = 'student'
         and e.deleted_at is null
         and e.household_id = v_foyer
    ) then
      v_qui := p_eleve_id;
    end if;
  else
    v_qui := p_profile_id;
  end if;

  if v_qui is not null then
    v_autorise := exists (
      select 1 from public.session_participants sp
       where sp.session_id = p_session_id
         and sp.profile_id = v_qui
         and sp.deleted_at is null
    ) or (
      p_eleve_id is null
      and private.c29_enseignant_effectif_session(p_session_id) = p_profile_id
    );
  end if;
  if not v_autorise then
    return null;
  end if;

  v_ouverture := coalesce(
    v_seance.join_opens_at,
    v_seance.started_at - make_interval(mins => v_fenetre)
  );

  if v_seance.status in ('canceled', 'canceled_late') then
    v_motif := 'annulee';
  elsif v_seance.status = 'ended'
     or now() > v_seance.ended_at + make_interval(mins => v_grace) then
    v_motif := 'terminee';
  elsif now() < v_ouverture then
    v_motif := 'pas_encore_ouverte';
  else
    return null;
  end if;

  return jsonb_build_object(
    'motif', v_motif,
    'fin_utc', v_seance.ended_at,
    'ouverture_utc', v_ouverture,
    'grace_minutes', v_grace
  );
end;
$function$;

ALTER FUNCTION public.motif_refus_salle(uuid, uuid, uuid) OWNER TO postgres;

REVOKE EXECUTE ON FUNCTION public.motif_refus_salle(uuid, uuid, uuid)
  FROM PUBLIC, anon, authenticated;
DO $agent$
BEGIN
  IF EXISTS (SELECT 1 FROM pg_catalog.pg_roles WHERE rolname = 'agent_ro') THEN
    REVOKE EXECUTE ON FUNCTION public.motif_refus_salle(uuid, uuid, uuid) FROM agent_ro;
  END IF;
END;
$agent$;
GRANT EXECUTE ON FUNCTION public.motif_refus_salle(uuid, uuid, uuid)
  TO service_role;

DO $postflight$
BEGIN
  IF has_function_privilege('anon', 'public.motif_refus_salle(uuid, uuid, uuid)', 'EXECUTE')
     OR has_function_privilege('authenticated', 'public.motif_refus_salle(uuid, uuid, uuid)', 'EXECUTE') THEN
    RAISE EXCEPTION 'FN-025 : motif_refus_salle est ouverte au client';
  END IF;
  IF NOT has_function_privilege('service_role', 'public.motif_refus_salle(uuid, uuid, uuid)', 'EXECUTE') THEN
    RAISE EXCEPTION 'FN-025 : motif_refus_salle est fermee au role de service';
  END IF;
END;
$postflight$;

COMMIT;
