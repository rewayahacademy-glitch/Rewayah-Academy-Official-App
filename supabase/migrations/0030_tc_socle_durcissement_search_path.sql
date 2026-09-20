-- 0030_tc_socle_durcissement_search_path.sql
-- Correction relevee par get_advisors juste apres 0030 : le declencheur de
-- revision de la politique d'observation par groupe n'avait pas de
-- `search_path` fige, a la difference des trois autres fonctions du meme
-- fichier. Meme motif que 0011 -> 0011_..._controleur_invisible : un
-- correctif au meme prefixe, une migration a part parce que 0030 est deja
-- appliquee.

create or replace function public.tc_groupes_observation_bump_revision()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  if (new.observation_source, new.observation_max_visites, new.observation_max_secondes,
      new.observation_max_secondes_par_visite)
     is distinct from
     (old.observation_source, old.observation_max_visites, old.observation_max_secondes,
      old.observation_max_secondes_par_visite)
  then
    new.observation_revision := old.observation_revision + 1;
  end if;
  return new;
end;
$$;
