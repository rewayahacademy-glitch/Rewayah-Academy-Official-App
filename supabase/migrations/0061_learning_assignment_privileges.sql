-- 0061 — privilèges minimaux pour les assignations pédagogiques.
-- Les policies 0058 bornent les lignes; les privilèges limitent aussi les colonnes mutables.
begin;

revoke all on public.learning_assignment from public, anon, authenticated, agent_ro;
grant select, insert on public.learning_assignment to authenticated;
grant update (status) on public.learning_assignment to authenticated;

commit;
