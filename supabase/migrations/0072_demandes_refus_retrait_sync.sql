-- 0072 — fermer les demandes quand l'administration refuse ou retire un membre.
begin;

create or replace function public.tc_demande_horaire_cloture_retrait_groupe()
returns trigger
language plpgsql
security definer
set search_path = ''
as $function$
begin
  if old.left_at is null and new.left_at is not null then
    update public.demandes_horaires_famille
       set etat = 'refusee',
           motif = case
             when new.left_reason like 'groupe cloture :%' then 'classe_non_constituee'
             else 'refus_direction'
           end,
           updated_at = pg_catalog.now()
     where groupe_id = new.groupe_id
       and eleve_id = new.student_id
       and etat in ('classe_validee', 'enseignant_affecte');
  end if;
  return new;
end;
$function$;
revoke all on function public.tc_demande_horaire_cloture_retrait_groupe()
  from public, anon, authenticated, agent_ro;

drop trigger if exists demandes_horaires_cloture_retrait_groupe
  on public.groupe_membres;
create trigger demandes_horaires_cloture_retrait_groupe
after update of left_at on public.groupe_membres
for each row execute function public.tc_demande_horaire_cloture_retrait_groupe();

create or replace function public.refuser_demande_horaire(
  p_demande_id uuid,
  p_motif text
) returns void
language plpgsql
security definer
set search_path = ''
as $function$
declare
  v_demande uuid;
begin
  if not coalesce(public.app_role() = 'admin' and public.app_account_valid(), false) then
    raise exception 'refus de demande reserve a l''administration';
  end if;
  if p_demande_id is null or p_motif is distinct from 'refus_direction' then
    raise exception 'motif de refus invalide';
  end if;

  select d.id into v_demande
    from public.demandes_horaires_famille d
   where d.id = p_demande_id and d.etat = 'envoyee'
   for update;
  if not found then
    raise exception 'demande absente ou deja traitee';
  end if;

  update public.demandes_horaires_famille
     set etat = 'refusee',
         motif = p_motif,
         updated_at = pg_catalog.now()
   where id = v_demande;

  perform public.log_sensitive_access(
    'demande_horaire_refusee',
    'demandes_horaires_famille',
    v_demande::text,
    pg_catalog.jsonb_build_object('motif', p_motif)
  );
end;
$function$;
revoke all on function public.refuser_demande_horaire(uuid, text)
  from public, anon, agent_ro;
grant execute on function public.refuser_demande_horaire(uuid, text)
  to authenticated;

commit;
