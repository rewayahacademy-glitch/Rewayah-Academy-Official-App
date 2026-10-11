CREATE OR REPLACE FUNCTION public.geler_archive_seance(p_recording_id uuid, p_motif text, p_gel boolean DEFAULT true)
 RETURNS boolean
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare
  v_touche int;
begin
  if not coalesce(public.app_role() = 'admin', false) then
    raise exception 'gel de conservation reserve a l''administration'
      using errcode = '42501';
  end if;

  if p_recording_id is null then
    raise exception 'archive non precisee' using errcode = '22023';
  end if;

  -- `p_gel` a NULL doit ECHOUER, jamais degeler. Sans ce refus, `if p_gel and
  -- ...` ne se declenche pas (NULL and true vaut NULL, donc aucun motif n'est
  -- exige) et `case when p_gel then ... else null end` tombe dans le ELSE :
  -- une archive retenue pour un litige perdrait sa protection sur un argument
  -- omis, ce qu'un client qui serialise un booleen nullable produit sans le
  -- vouloir. C'est le meme renversement que `0029` a corrige ailleurs --
  -- l'inconnue doit fermer, pas ouvrir.
  if p_gel is null then
    raise exception 'sens du gel non precise' using errcode = '22023';
  end if;

  if p_gel and coalesce(btrim(p_motif), '') = '' then
    raise exception 'un gel de conservation exige un motif' using errcode = '22023';
  end if;

  update public.session_recordings r
  set legal_hold_since = case when p_gel then coalesce(r.legal_hold_since, now()) else null end
  where r.id = p_recording_id and r.deleted_at is null;

  get diagnostics v_touche = row_count;
  if v_touche = 0 then
    raise exception 'archive introuvable' using errcode = '42501';
  end if;

  -- Le motif entre ICI, et nulle part ailleurs : `audit_logs` est reserve a
  -- l'administration, quand la ligne d'archive est lisible par l'enseignant de
  -- la seance et par les familles.
  perform public.log_sensitive_access(
    case when p_gel then 'recording_legal_hold_set' else 'recording_legal_hold_lift' end,
    'session_recordings',
    p_recording_id::text,
    jsonb_build_object('gel', p_gel, 'motif', nullif(btrim(coalesce(p_motif, '')), ''))
  );

  return true;
end;
$function$

