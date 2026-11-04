-- Salle : le titulaire ecarte par l'absence automatique (A3) lit la vraie
-- raison du refus (prod du 01/11/2026 : « Ce cours ne vous est pas ouvert en
-- ce moment » alors que la seance etait en cours et la salle ouverte aux
-- eleves).
--
-- Remplace public.motif_refus_salle (20261103500000) : meme corps, un motif
-- de plus, « acces_perdu », servi au seul titulaire que
-- private.remplacement_titulaire_ecarte designe (le predicat qui fait refuser
-- son jeton). Rien d'autre ne change : droits, signature, autres motifs.
-- CREATE OR REPLACE garde les droits poses en 20261103500000 (EXECUTE pour
-- service_role seulement). Aucune suppression.

BEGIN;

CREATE OR REPLACE FUNCTION public.motif_refus_salle(
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

  -- A3 (31/10/2026, 20261102500000) : le titulaire qui n'est pas entre a
  -- temps perd l'acces a la seance de ce jour (absence automatique). Le
  -- jeton le refuse (« acces a cette seance perdu ») ; on le dit, au lieu du
  -- refus generique « la salle s'ouvre peu avant l'heure du cours » (prod du
  -- 01/11/2026, 18:16-18:24 UTC). Meme predicat que le refus du jeton.
  if p_eleve_id is null
     and private.remplacement_titulaire_ecarte(p_session_id, p_profile_id) then
    return jsonb_build_object(
      'motif', 'acces_perdu',
      'fin_utc', v_seance.ended_at,
      'ouverture_utc', null,
      'grace_minutes', v_grace
    );
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

COMMIT;
