CREATE OR REPLACE FUNCTION public.autoriser_ecoute_archive(p_recording_id uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare
  v_archive public.session_recordings;
  v_role public.app_role := public.app_role();
  v_foyers int;
begin
  if not coalesce(public.app_account_valid(), false) then
    raise exception 'compte non valide' using errcode = '42501';
  end if;

  if p_recording_id is null then
    raise exception 'archive non precisee' using errcode = '22023';
  end if;

  select r.* into v_archive
  from public.session_recordings r
  where r.id = p_recording_id;

  if not found or v_archive.deleted_at is not null then
    raise exception 'archive introuvable' using errcode = '42501';
  end if;

  -- Combien de foyers distincts ont un participant dans cette seance ?
  --
  -- La question n'est pas rhetorique. `session_in_household()` (0001) rend vrai
  -- des qu'UN SEUL participant appartient au foyer interroge. Elle a ete ecrite
  -- quand une seance comptait deux personnes (`max_participants_per_session`
  -- valait 2, `allow_multi_participant_sessions` valait false) : elle voulait
  -- alors dire << le foyer de l'eleve de ce cours >>. Depuis le pivot du 19
  -- septembre, `0017` porte le plafond a 7 et ouvre le multi-participant : une
  -- seance de groupe reunit cinq enfants de cinq foyers.
  --
  -- Appliquee telle quelle a une archive de groupe, cette relation donnerait a
  -- CHAQUE tuteur l'audio complet de la seance -- ou recitent aussi les enfants
  -- des quatre autres familles, qui n'ont consenti qu'a l'enregistrement de la
  -- leur. La policy `session_recordings_teacher_family` (0001) porte la meme
  -- forme, mais elle n'avait jamais servi : rien n'alimentait ni ne lisait
  -- cette table avant ce fichier. Ouvrir la lecture, c'est l'activer.
  --
  -- Tant que l'operateur n'a pas tranche ce que la famille peut reecouter d'une
  -- seance collective, la branche famille reste bornee aux seances d'un seul
  -- foyer. L'enseignant de la seance, l'administration et le controle gardent
  -- leur acces dans tous les cas.
  select count(distinct p.household_id) into v_foyers
  from public.session_participants sp
  join public.profiles p on p.id = sp.profile_id
  where sp.session_id = v_archive.session_id
    and sp.deleted_at is null
    and p.deleted_at is null
    and p.household_id is not null;

  -- Exigence POSITIVE : toute inconnue ferme. Un appelant sans role tombe ici,
  -- et non plus loin.
  if not coalesce(
    v_role in ('admin', 'controller')
    or public.session_belongs_to_teacher(v_archive.session_id, auth.uid())
    or (
      v_foyers <= 1
      and public.session_in_household(v_archive.session_id, public.app_household_id())
    ),
    false
  ) then
    raise exception 'ecoute refusee : aucune relation avec cette seance'
      using errcode = '42501';
  end if;

  -- L'etat de l'archive est une condition d'acces a part entiere : une piece
  -- revoquee ou expiree ne s'ecoute pas, meme par qui en avait le droit hier.
  -- Un gel de conservation, lui, garde la piece accessible a l'administration
  -- et au controle -- c'est sa raison d'etre.
  if v_archive.status = 'revoked' then
    raise exception 'archive revoquee' using errcode = '42501';
  end if;

  if v_archive.expires_at <= now() or v_archive.status = 'expired' then
    if not coalesce(
      v_archive.legal_hold_since is not null and v_role in ('admin', 'controller'),
      false
    ) then
      raise exception 'archive expiree' using errcode = '42501';
    end if;
  end if;

  perform public.log_sensitive_access(
    'recording_listen',
    'session_recordings',
    v_archive.id::text,
    jsonb_build_object(
      'session_id', v_archive.session_id,
      'legal_hold', v_archive.legal_hold_since is not null,
      'status', v_archive.status
    )
  );

  return jsonb_build_object(
    'recording_id', v_archive.id,
    'session_id', v_archive.session_id,
    'object_key', v_archive.object_key,
    'duration_seconds', v_archive.duration_seconds,
    'expires_at', v_archive.expires_at
  );
end;
$function$

