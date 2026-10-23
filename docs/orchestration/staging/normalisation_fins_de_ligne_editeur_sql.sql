-- Base de test seulement (23/10/2026) : les fichiers colles dans l'editeur SQL
-- depuis Windows y ont garde un retour chariot a chaque fin de ligne. Ce bloc
-- recree chaque fonction concernee a l'identique, sans ces caracteres, et
-- reporte la nouvelle empreinte md5_functiondef dans son commentaire F86.
-- Ni objet retire, ni ligne effacee : CREATE OR REPLACE garde droits,
-- proprietaire et commentaire.
DO $normalisation$
DECLARE
  r record;
  v_definition text;
  v_ancienne text;
  v_nouvelle text;
  v_commentaire text;
  v_objet text;
BEGIN
  FOR r IN
    SELECT p.oid, p.prokind
      FROM pg_catalog.pg_proc p
      JOIN pg_catalog.pg_namespace n ON n.oid = p.pronamespace
     WHERE n.nspname NOT IN ('pg_catalog', 'information_schema')
       AND n.nspname NOT LIKE 'pg\_%'
       AND p.prokind IN ('f', 'p')
       AND pg_catalog.strpos(p.prosrc, pg_catalog.chr(13)) > 0
  LOOP
    v_definition := pg_catalog.pg_get_functiondef(r.oid);
    v_ancienne := pg_catalog.md5(v_definition);
    EXECUTE pg_catalog.replace(v_definition, pg_catalog.chr(13), '');
    v_nouvelle := pg_catalog.md5(pg_catalog.pg_get_functiondef(r.oid));
    v_commentaire := pg_catalog.obj_description(r.oid, 'pg_proc');
    IF v_commentaire IS NOT NULL
       AND pg_catalog.strpos(v_commentaire, 'md5_functiondef=' || v_ancienne) > 0 THEN
      v_objet := CASE r.prokind WHEN 'p' THEN 'PROCEDURE' ELSE 'FUNCTION' END;
      EXECUTE pg_catalog.format('COMMENT ON %s %s IS %L', v_objet,
        r.oid::pg_catalog.regprocedure,
        pg_catalog.replace(v_commentaire, 'md5_functiondef=' || v_ancienne,
                           'md5_functiondef=' || v_nouvelle));
    END IF;
  END LOOP;

  IF EXISTS (
    SELECT 1
      FROM pg_catalog.pg_proc p
      JOIN pg_catalog.pg_namespace n ON n.oid = p.pronamespace
     WHERE n.nspname NOT IN ('pg_catalog', 'information_schema')
       AND n.nspname NOT LIKE 'pg\_%'
       AND pg_catalog.strpos(p.prosrc, pg_catalog.chr(13)) > 0
  ) THEN
    RAISE EXCEPTION 'normalisation : une fonction garde un retour chariot';
  END IF;
END
$normalisation$;
