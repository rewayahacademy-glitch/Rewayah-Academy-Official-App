-- SECU-ANON (accord du directeur, 07/11/2026 : « lance les petites dettes de securite »)
--
-- Constat mesure en production par le garde-cap : `anon` a EXECUTE sur
--   public.groupes_admin(), public.personnes_observables(), public.profil_de_mon_foyer(text).
-- Les trois sont gardees a l'interieur et ne rendent rien a `anon` : c'est de
-- l'hygiene, pas une fuite. Cause : `revoke ... from public` (0033, 0016) ne
-- retire pas le droit accorde directement a `anon` par les privileges par
-- defaut du projet.
--
-- Appels avant connexion : aucun (lib/ et supabase/functions/ relus). Les trois
-- ne servent qu'apres connexion ; profil_de_mon_foyer n'est evaluee que par des
-- politiques de stockage `to authenticated` (0004), donc jamais pour `anon`.
--
-- Rejouable : les revoke et le grant sont idempotents. Aucune table touchee.

do $preflight$
declare
  v_sig text;
  begin
  foreach v_sig in array array[
    'public.groupes_admin()',
    'public.personnes_observables()',
    'public.profil_de_mon_foyer(text)'
  ] loop
    if pg_catalog.to_regprocedure(v_sig) is null then
      raise exception 'SECU-ANON preflight : la fonction % n''existe pas', v_sig;
    end if;
  end loop;
  end
$preflight$;

revoke execute on function public.groupes_admin() from public, anon;
revoke execute on function public.personnes_observables() from public, anon;
revoke execute on function public.profil_de_mon_foyer(text) from public, anon;

-- `authenticated` garde ses droits : on les ecrit explicitement, au cas ou ils
-- n'auraient tenu qu'au droit de `public`. `agent_ro` et `service_role` ne sont
-- pas touches.
grant execute on function public.groupes_admin() to authenticated;
grant execute on function public.personnes_observables() to authenticated;
grant execute on function public.profil_de_mon_foyer(text) to authenticated;

do $postflight$
declare
  v_sig text;
  begin
  foreach v_sig in array array[
    'public.groupes_admin()',
    'public.personnes_observables()',
    'public.profil_de_mon_foyer(text)'
  ] loop
    if pg_catalog.has_function_privilege('anon', v_sig, 'EXECUTE') then
      raise exception 'SECU-ANON postflight : anon peut encore executer %', v_sig;
    end if;
    if not pg_catalog.has_function_privilege('authenticated', v_sig, 'EXECUTE') then
      raise exception 'SECU-ANON postflight : authenticated a perdu l''acces a %', v_sig;
    end if;
  end loop;
  end
$postflight$;
