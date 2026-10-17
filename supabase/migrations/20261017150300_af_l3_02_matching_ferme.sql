-- L3-02 (A-06, decision du directeur du 17/10/2026) : le matching individuel
-- est retire du parcours courant. Les classes precreees remplacent la prise
-- d'un eleve par un enseignant et l'attribution manuelle d'un enseignant a un
-- eleve. Les deux RPC sont fermees (revoke) et non supprimees : l'historique,
-- les scenarios anciens et la table teacher_student_assignments restent.
-- materialiser_seances est deja reservee a service_role (L1-01).
-- Un cours particulier est une classe de capacite 1 : groupes_seuil_max_check
-- accepte seuil_max = 1, creer_groupe n'a rien a changer.
begin;

revoke execute on function public.prendre_eleve(uuid, integer, integer)
  from public, anon, authenticated, agent_ro;
revoke execute on function public.attribuer_eleve(uuid, uuid, integer, integer, text)
  from public, anon, authenticated, agent_ro;

do $postflight$
begin
  if has_function_privilege('authenticated', 'public.prendre_eleve(uuid,integer,integer)', 'execute')
     or has_function_privilege('authenticated', 'public.attribuer_eleve(uuid,uuid,integer,integer,text)', 'execute')
     or has_function_privilege('anon', 'public.prendre_eleve(uuid,integer,integer)', 'execute')
     or has_function_privilege('anon', 'public.attribuer_eleve(uuid,uuid,integer,integer,text)', 'execute') then
    raise exception 'L3-02 postflight: prendre_eleve ou attribuer_eleve encore executable';
  end if;
end $postflight$;

commit;
