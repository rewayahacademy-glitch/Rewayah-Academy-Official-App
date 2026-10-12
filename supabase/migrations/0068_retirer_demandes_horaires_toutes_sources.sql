-- 0068 — retirer atomiquement une demande horaire quelle que soit sa source.
begin;

create or replace function public.retirer_demande_horaire(
  p_membre_id uuid,
  p_motif text
) returns void
language plpgsql
security definer
set search_path = ''
as $function$
declare
  v_demandes integer := 0;
  v_intentions integer := 0;
  v_personnalisees integer := 0;
  v_motif text := nullif(pg_catalog.btrim(coalesce(p_motif, '')), '');
begin
  if not coalesce(public.app_account_valid(), false)
     or not coalesce(public.peut_decrire_apprenant(p_membre_id), false) then
    raise exception 'ce profil n''est pas le votre ni celui de votre foyer';
  end if;
  if v_motif is null then
    raise exception 'un motif est requis pour retirer une demande horaire';
  end if;

  perform pg_catalog.pg_advisory_xact_lock(
    pg_catalog.hashtextextended('demande-horaire:' || p_membre_id::text, 0)
  );

  update public.demandes_horaires_famille
     set etat = 'retiree', motif = v_motif, updated_at = pg_catalog.now()
   where eleve_id = p_membre_id
     and etat = 'envoyee';
  get diagnostics v_demandes = row_count;

  -- Les anciennes intentions de vitrine et les demandes privées ont des
  -- sources de vérité distinctes. Les deux doivent cesser de bloquer le choix
  -- suivant et le quota. Une intention déjà affectée à un groupe est gardée.
  update public.intentions_horaire
     set etat = 'retiree',
         retiree_at = pg_catalog.now(),
         retiree_par = auth.uid(),
         retrait_motif = v_motif
   where eleve_id = p_membre_id
     and etat <> 'retiree'
     and groupe_id is null;
  get diagnostics v_intentions = row_count;

  update public.demandes_creneau_personnalise
     set etat = 'retiree', retiree_at = pg_catalog.now(), offre_id = null
   where eleve_id = p_membre_id
     and etat in ('en_attente_quota', 'offre_ouverte');
  get diagnostics v_personnalisees = row_count;

  if v_demandes + v_intentions + v_personnalisees = 0 then
    raise exception 'aucune demande horaire active pour cet apprenant';
  end if;

  perform public.log_sensitive_access(
    'demande_horaire_retiree', 'demandes_horaires_famille',
    p_membre_id::text,
    pg_catalog.jsonb_build_object(
      'motif', v_motif,
      'demandes', v_demandes,
      'intentions', v_intentions,
      'personnalisees', v_personnalisees
    )
  );
end;
$function$;
revoke all on function public.retirer_demande_horaire(uuid, text)
  from public, anon, agent_ro;
grant execute on function public.retirer_demande_horaire(uuid, text)
  to authenticated;

create or replace function public.renoncer_intention_horaire(
  p_membre_id uuid,
  p_motif text
) returns void
language plpgsql
security definer
set search_path = ''
as $function$
begin
  perform public.retirer_demande_horaire(p_membre_id, p_motif);
end;
$function$;
revoke all on function public.renoncer_intention_horaire(uuid, text)
  from public, anon, agent_ro;
grant execute on function public.renoncer_intention_horaire(uuid, text)
  to authenticated;

create or replace function public.retirer_creneau_personnalise(p_membre_id uuid)
returns void
language plpgsql
security definer
set search_path = ''
as $function$
begin
  perform public.retirer_demande_horaire(p_membre_id, 'retrait_famille');
end;
$function$;
revoke all on function public.retirer_creneau_personnalise(uuid)
  from public, anon, agent_ro;
grant execute on function public.retirer_creneau_personnalise(uuid)
  to authenticated;

commit;
