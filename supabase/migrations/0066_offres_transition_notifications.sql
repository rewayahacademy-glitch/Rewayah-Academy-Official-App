-- 0066 — notifier les transitions familiales et aligner l'etat apres affectation.
begin;

create or replace function public.tc_demande_horaire_notification()
returns trigger
language plpgsql
security definer
set search_path = ''
as $function$
declare
  v_evenement text;
  v_foyer uuid;
  v_destinataire uuid;
begin
  if tg_op = 'INSERT' then
    v_evenement := 'demande_recue';
  elsif old.etat is distinct from new.etat and new.etat in ('refusee', 'retiree') then
    v_evenement := 'demande_close';
  else
    return new;
  end if;

  select p.household_id, h.primary_guardian_id
    into v_foyer, v_destinataire
  from public.profiles p
  join public.households h on h.id = p.household_id
  where p.id = new.eleve_id
    and p.deleted_at is null
    and h.deleted_at is null
    and h.status = 'active'
    and h.primary_guardian_id is not null;
  if v_destinataire is null then return new; end if;

  insert into public.notifications
    (destinataire, foyer_id, evenement, params, destination)
  values (
    v_destinataire, v_foyer, v_evenement,
    pg_catalog.jsonb_build_object('demande_id', new.id, 'etat', new.etat),
    '/tuteur/demandes'
  );
  return new;
end;
$function$;
revoke all on function public.tc_demande_horaire_notification()
  from public, anon, authenticated, agent_ro;

drop trigger if exists demandes_horaires_notification on public.demandes_horaires_famille;
create trigger demandes_horaires_notification
after insert or update of etat on public.demandes_horaires_famille
for each row execute function public.tc_demande_horaire_notification();

-- La transition de groupe active met aussi a jour les demandes rattachees;
-- 0055 materialise les seances et notifie deja chaque foyer a la meme transaction.
create or replace function public.tc_demandes_horaires_enseignant_affecte()
returns trigger
language plpgsql
security definer
set search_path = ''
as $function$
begin
  if old.teacher_id is null and new.teacher_id is not null and new.etat = 'active' then
    update public.demandes_horaires_famille
       set etat = 'enseignant_affecte', updated_at = pg_catalog.now()
     where groupe_id = new.id and etat = 'classe_validee';
  end if;
  return new;
end;
$function$;
revoke all on function public.tc_demandes_horaires_enseignant_affecte()
  from public, anon, authenticated, agent_ro;

drop trigger if exists demandes_horaires_enseignant_affecte on public.groupes;
create trigger demandes_horaires_enseignant_affecte
after update of teacher_id, etat on public.groupes
for each row execute function public.tc_demandes_horaires_enseignant_affecte();

commit;
