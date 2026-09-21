-- Core24 P0.1 : 0033 a ajoute des surcharges au lieu de remplacer 0019.
-- Les signatures etendues conservent les arguments historiques et leurs
-- valeurs par defaut : aucun changement obligatoire pour les anciens clients.
-- Pas de CASCADE : une dependance inattendue doit interrompre la migration.
begin;

drop function if exists public.creer_groupe(uuid, text, text, smallint, smallint, smallint);
drop function if exists public.modifier_groupe(uuid, text, smallint, smallint, smallint);

revoke all on function public.creer_groupe(uuid, text, text, smallint, smallint, smallint, text, smallint)
  from public, anon, agent_ro;
revoke all on function public.modifier_groupe(uuid, text, smallint, smallint, smallint, text, smallint)
  from public, anon, agent_ro;
grant execute on function public.creer_groupe(uuid, text, text, smallint, smallint, smallint, text, smallint)
  to authenticated, service_role;
grant execute on function public.modifier_groupe(uuid, text, smallint, smallint, smallint, text, smallint)
  to authenticated, service_role;

notify pgrst, 'reload schema';
commit;
