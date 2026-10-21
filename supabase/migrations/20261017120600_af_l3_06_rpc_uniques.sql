-- AF L3-06 (audit final 16/10/2026, rapport section 5.1) : une seule signature
-- par intention. Quatre surcharges sont fermees (revoke, pas drop : l'historique
-- des migrations et des scenarios les cite). Le client passe aux signatures
-- gardees dans lib/core/admin/service_groupes.dart.
--
--   creer_groupe (6 arguments)        -> creer_groupe (8 arguments, fuseau et couleur)
--   modifier_groupe (5 arguments)     -> modifier_groupe (7 arguments, fuseau et couleur)
--   affecter_enseignant_classe        -> affecter_enseignant_classe_c11bis (verrou par enseignant)
--   publier_groupe_depuis_offre       -> creer_classe_depuis_regroupement (idempotent)
--
-- Aucun appelant vivant : lib/, supabase/functions/ et les migrations ne
-- l'appellent plus (seuls des tests historiques de regprocedure la citent).
-- ============================================================================

revoke execute on function public.creer_groupe(uuid, text, text, smallint, smallint, smallint)
  from public, anon, authenticated, agent_ro, service_role;
revoke execute on function public.modifier_groupe(uuid, text, smallint, smallint, smallint)
  from public, anon, authenticated, agent_ro, service_role;
revoke execute on function public.affecter_enseignant_classe(uuid, uuid)
  from public, anon, authenticated, agent_ro, service_role;
revoke execute on function public.publier_groupe_depuis_offre(uuid, uuid, text, uuid[])
  from public, anon, authenticated, agent_ro, service_role;

comment on function public.creer_groupe(uuid, text, text, smallint, smallint, smallint) is
  'Surcharge retiree : remplacee par creer_groupe(uuid,text,text,smallint,smallint,smallint,text,smallint), audit final L3-06.';
comment on function public.modifier_groupe(uuid, text, smallint, smallint, smallint) is
  'Surcharge retiree : remplacee par modifier_groupe(uuid,text,smallint,smallint,smallint,text,smallint), audit final L3-06.';
comment on function public.affecter_enseignant_classe(uuid, uuid) is
  'Fonction retiree : remplacee par affecter_enseignant_classe_c11bis(uuid,uuid), audit final L3-06.';
comment on function public.publier_groupe_depuis_offre(uuid, uuid, text, uuid[]) is
  'Fonction retiree : remplacee par creer_classe_depuis_regroupement(uuid,uuid,text), audit final L3-06.';

-- Postflight : les quatre retirees ne sont executables par aucun role
-- connecte ou de service ; les quatre gardees le restent pour authenticated.
do $postflight$
declare
  v_retirees text[] := array[
    'public.creer_groupe(uuid,text,text,smallint,smallint,smallint)',
    'public.modifier_groupe(uuid,text,smallint,smallint,smallint)',
    'public.affecter_enseignant_classe(uuid,uuid)',
    'public.publier_groupe_depuis_offre(uuid,uuid,text,uuid[])'
  ];
  v_gardees text[] := array[
    'public.creer_groupe(uuid,text,text,smallint,smallint,smallint,text,smallint)',
    'public.modifier_groupe(uuid,text,smallint,smallint,smallint,text,smallint)',
    'public.affecter_enseignant_classe_c11bis(uuid,uuid)',
    'public.creer_classe_depuis_regroupement(uuid,uuid,text)'
  ];
  v_fn text;
begin
  foreach v_fn in array v_retirees loop
    if pg_catalog.has_function_privilege('authenticated', v_fn, 'execute')
       or pg_catalog.has_function_privilege('anon', v_fn, 'execute')
       or pg_catalog.has_function_privilege('agent_ro', v_fn, 'execute')
       or pg_catalog.has_function_privilege('service_role', v_fn, 'execute') then
      raise exception 'AF-L3-06 postflight : % reste executable', v_fn;
    end if;
  end loop;
  foreach v_fn in array v_gardees loop
    if not pg_catalog.has_function_privilege('authenticated', v_fn, 'execute') then
      raise exception 'AF-L3-06 postflight : % n''est plus executable par authenticated', v_fn;
    end if;
  end loop;
end
$postflight$;
