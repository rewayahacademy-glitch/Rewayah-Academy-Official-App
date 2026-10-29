-- ADMISSION lot B (directeur, 29/10/2026, par le pilote) : toutes les
-- questions de l'inscription viennent AVANT la creation du compte, la langue
-- du cours comprise. La liste des langues de cours actives est une donnee
-- publique : un visiteur sans compte la lit, et rien d'autre.
--
-- 0043 fermait langues_cours a anon (« anon n'a rien a faire ici »). On ne
-- l'ouvre pas : la RLS borne les lignes, pas les colonnes, et la lecture de
-- l'application filtre sur `actif` et trie sur `ordre`, que anon devrait
-- alors pouvoir lire. Une fonction en lecture seule rend exactement le code
-- et le libelle des langues actives, dans l'ordre publie ; la table reste
-- fermee a anon.

BEGIN;

CREATE FUNCTION public.langues_cours_publiques()
RETURNS TABLE (code text, nom_humain text)
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $function$
  SELECT l.code, l.nom_humain
    FROM public.langues_cours l
   WHERE l.actif
   ORDER BY l.ordre, l.code;
$function$;

ALTER FUNCTION public.langues_cours_publiques() OWNER TO postgres;
REVOKE ALL ON FUNCTION public.langues_cours_publiques() FROM PUBLIC, service_role;
GRANT EXECUTE ON FUNCTION public.langues_cours_publiques() TO anon, authenticated;
COMMENT ON FUNCTION public.langues_cours_publiques() IS
  'Admission lot B (29/10/2026) : code et libelle des langues de cours actives, lisibles sans compte (inscription avant le compte). Lecture seule ; langues_cours reste fermee a anon.';

DO $postflight$
BEGIN
  IF NOT pg_catalog.has_function_privilege('anon', 'public.langues_cours_publiques()', 'EXECUTE') THEN
    RAISE EXCEPTION 'langues_cours_publiques : anon doit pouvoir lire la liste';
  END IF;
  IF pg_catalog.has_table_privilege('anon', 'public.langues_cours', 'SELECT') THEN
    RAISE EXCEPTION 'langues_cours ne doit pas etre lisible directement par anon';
  END IF;
  IF (SELECT p.provolatile FROM pg_catalog.pg_proc p
       WHERE p.oid = 'public.langues_cours_publiques()'::pg_catalog.regprocedure) <> 's' THEN
    RAISE EXCEPTION 'langues_cours_publiques doit etre STABLE (lecture seule)';
  END IF;
END;
$postflight$;

COMMIT;
