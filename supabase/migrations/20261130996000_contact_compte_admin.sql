-- APERCU-COMPTE (directeur, 22/11/2026 : « l'e-mail qui s'affichait ne s'affiche plus ») : la direction lit
-- le courriel d'un compte dans l'apercu de la page « Personnes ». Aucune lecture existante ne le rendait
-- (comptes_admin et comptes_admin_par_role ne portent pas de courriel) : cette migration ajoute une
-- fonction, sans toucher aux deux autres (additive, aucun effacement).
-- Meme garde que comptes_admin_par_role : direction seulement, compte valide, hors candidat hors portee
-- et hors comptes officiels ; sous masquage d'identite (agent), rien n'est rendu. anon n'a aucun droit.

CREATE OR REPLACE FUNCTION public.contact_compte_admin(p_profil uuid)
 RETURNS text
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO ''
AS $function$
  select case
           when (select public.agent_identite_masquee()) then null
           else nullif(pg_catalog.btrim(u.email), '')
         end
    from public.profiles p
    join auth.users u on u.id = p.id
   where p.id = p_profil
     and p.deleted_at is null
     and public.app_role() = 'admin'
     and public.app_account_valid()
     and not app_private.compte_candidat_hors_portee(p.id)
     and not exists (select 1 from private.comptes_officiels co where co.profile_id = p.id);
$function$;

ALTER FUNCTION public.contact_compte_admin(uuid) OWNER TO postgres;
REVOKE ALL ON FUNCTION public.contact_compte_admin(uuid) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.contact_compte_admin(uuid) FROM anon;
GRANT EXECUTE ON FUNCTION public.contact_compte_admin(uuid) TO authenticated;

DO $controle$
BEGIN
  IF NOT EXISTS (
       SELECT 1 FROM pg_catalog.pg_proc p
        WHERE p.oid = pg_catalog.to_regprocedure('public.contact_compte_admin(uuid)')
          AND p.provolatile = 's' AND p.prosecdef AND p.proowner = 'postgres'::regrole
          AND p.proconfig = ARRAY['search_path=""']
          AND pg_catalog.has_function_privilege('authenticated', p.oid, 'EXECUTE')) THEN
    RAISE EXCEPTION 'APERCU-COMPTE : contact_compte_admin : securite, proprietaire, search_path ou droits inattendus';
  END IF;
  IF has_function_privilege('anon', 'public.contact_compte_admin(uuid)', 'EXECUTE') THEN
    RAISE EXCEPTION 'APERCU-COMPTE : anon peut executer contact_compte_admin';
  END IF;
END
$controle$;
