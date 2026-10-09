-- 0061 — privilèges minimaux pour les assignations et annotations pédagogiques.
-- Les policies 0058 bornent les lignes; les privilèges limitent aussi les opérations.
begin;

revoke all on public.learning_assignment from public, anon, authenticated, agent_ro;
grant select, insert on public.learning_assignment to authenticated;
grant update (status) on public.learning_assignment to authenticated;

-- L'adaptateur crée/relit les couches et ajoute/retire des traits.
revoke all on public.annotation_layer from public, anon, authenticated, agent_ro;
grant select, insert on public.annotation_layer to authenticated;

revoke all on public.annotation_trait from public, anon, authenticated, agent_ro;
grant select, insert, delete on public.annotation_trait to authenticated;

-- La pose d'un marqueur reste atomique via RPC; retrait explicite permis à son auteur.
revoke all on public.annotation_marqueur from public, anon, authenticated, agent_ro;
grant select, delete on public.annotation_marqueur to authenticated;

commit;
