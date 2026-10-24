-- D3 (24/10/2026) : la cloture d'une classe annule ses seances futures.
--
-- Constat en production (lecture seule, 24/10) : cloturer_groupe mettait
-- ended_at sur la classe et fermait ses membres, mais laissait ses seances
-- futures en 'planned'. La contrainte sessions_no_teacher_overlap (enseignant
-- et plage horaire, statuts planned, preflight, in_progress) refusait alors
-- toute nouvelle classe du meme enseignant au meme instant : creer_groupe
-- rendait une erreur pour des seances fantomes.
--
-- 1. cloturer_groupe, recree a l'identique (garde positive de 0067), annule
--    en plus les seances prevues, a venir et non supprimees de la classe
--    close, comme le fait deja fusionner_classes (R9). planned -> canceled est
--    une transition admise par guard_session_state_transition (0001).
-- 2. Rattrapage : les seances prevues, a venir et non supprimees de toute
--    classe deja close passent a 'canceled'.
--
-- Aucune suppression. CREATE OR REPLACE garde les droits existants.

BEGIN;

CREATE OR REPLACE FUNCTION public.cloturer_groupe(
  p_groupe_id uuid,
  p_motif text
)
RETURNS void
LANGUAGE plpgsql SECURITY DEFINER SET search_path = ''
AS $function$
begin
  if not coalesce(public.app_role() = 'admin' and public.app_account_valid(), false) then
    raise exception 'cloture de groupe reservee a l''administration';
  end if;

  if coalesce(btrim(p_motif), '') = '' then
    raise exception 'un motif est requis pour cloturer un groupe';
  end if;

  update public.groupe_membres
  set left_at = now(), left_by = auth.uid(), left_reason = 'groupe cloture : ' || p_motif
  where groupe_id = p_groupe_id and left_at is null;

  update public.groupes
  set ended_at = now(), ended_by = auth.uid(), end_reason = p_motif
  where id = p_groupe_id and ended_at is null;

  if not found then
    raise exception 'groupe introuvable ou deja cloture';
  end if;

  -- D3 : l'enseignant redevient libre a cet horaire (comme R9 de la fusion).
  update public.sessions s
  set status = 'canceled', updated_at = now()
  where s.groupe_id = p_groupe_id and s.deleted_at is null
    and s.status = 'planned' and s.started_at > now();

  perform public.log_sensitive_access('groupe_cloture', 'groupes', p_groupe_id::text, jsonb_build_object('motif', p_motif));
end;
$function$;

-- Rattrapage des classes deja closes.
UPDATE public.sessions s
   SET status = 'canceled', updated_at = pg_catalog.now()
  FROM public.groupes g
 WHERE g.id = s.groupe_id AND g.ended_at IS NOT NULL
   AND s.deleted_at IS NULL AND s.status = 'planned'
   AND s.started_at > pg_catalog.now();

COMMIT;
