-- L1 des listes (directeur, 01/11/2026 : « maintenant, il faut masquer les
-- classes cloturees »), DECISION-LISTES-2026-10-23.md §5 quater : la liste
-- Operations > Classes s'ouvre sur les classes actives et en attente
-- d'enseignant ; « Cloturees » reste un filtre. Rien n'est efface en base.
--
-- public.classes_admin_page recoit une quatrieme valeur de p_etat,
-- « ouvertes » = tout sauf « cloturee ». Les trois autres valeurs, les
-- compteurs et tous les autres axes sont inchanges.
--
-- Meme methode que 20261030100000_classe_plusieurs_creneaux.sql, section 7 :
-- le corps en place (pg_get_functiondef) est rejoue avec deux expressions
-- remplacees, et le bloc refuse de continuer s'il ne trouve pas l'une d'elles
-- telle quelle. Les droits ne bougent pas (CREATE OR REPLACE). L'empreinte
-- F86 du commentaire suit.
--
--   avant : p_etat NOT IN ('active', 'attente_enseignant', 'cloturee')
--   apres : p_etat NOT IN ('active', 'attente_enseignant', 'cloturee', 'ouvertes')
--
--   avant : WHERE p_etat IS NULL OR a.etat_liste = p_etat
--   apres : WHERE p_etat IS NULL OR a.etat_liste = p_etat
--                 OR (p_etat = 'ouvertes' AND a.etat_liste <> 'cloturee')
--
-- Aucun mot de suppression (compte : 0). Un seul BEGIN; et un seul COMMIT;.

BEGIN;

DO $liste$
DECLARE
  v_f pg_catalog.regprocedure :=
    'public.classes_admin_page(integer,integer,text,text,text,integer,integer,text,text,uuid,boolean,text)'::pg_catalog.regprocedure;
  v_def text := pg_catalog.pg_get_functiondef(v_f);
  v_valide_avant text := 'p_etat NOT IN (''active'', ''attente_enseignant'', ''cloturee'')';
  v_valide_apres text := 'p_etat NOT IN (''active'', ''attente_enseignant'', ''cloturee'', ''ouvertes'')';
  v_filtre_avant text := 'WHERE p_etat IS NULL OR a.etat_liste = p_etat';
  v_filtre_apres text := 'WHERE p_etat IS NULL OR a.etat_liste = p_etat'
    || ' OR (p_etat = ''ouvertes'' AND a.etat_liste <> ''cloturee'')';
BEGIN
  IF pg_catalog.strpos(v_def, v_valide_avant) = 0
     OR pg_catalog.strpos(v_def, v_filtre_avant) = 0 THEN
    RAISE EXCEPTION 'classes_admin_page : le filtre d''etat a change, migration a revoir';
  END IF;
  EXECUTE pg_catalog.replace(pg_catalog.replace(v_def, v_valide_avant, v_valide_apres),
                             v_filtre_avant, v_filtre_apres);
  EXECUTE pg_catalog.format('COMMENT ON FUNCTION %s IS %L', v_f,
    pg_catalog.regexp_replace(pg_catalog.obj_description(v_f, 'pg_proc'),
      'md5_functiondef=[0-9a-f]{32}',
      'md5_functiondef=' || pg_catalog.md5(pg_catalog.pg_get_functiondef(v_f))));
END;
$liste$;

-- Controle : les deux expressions nouvelles sont en place, les droits n'ont
-- pas bouge (direction par authenticated, jamais anon).
DO $postflight$
DECLARE
  v_def text := pg_catalog.pg_get_functiondef(
    'public.classes_admin_page(integer,integer,text,text,text,integer,integer,text,text,uuid,boolean,text)'::pg_catalog.regprocedure);
BEGIN
  IF pg_catalog.strpos(v_def, '''cloturee'', ''ouvertes'')') = 0
     OR pg_catalog.strpos(v_def, 'p_etat = ''ouvertes'' AND a.etat_liste <> ''cloturee''') = 0 THEN
    RAISE EXCEPTION 'L1 : classes_admin_page ne connait pas « ouvertes »';
  END IF;
  IF has_function_privilege('anon',
       'public.classes_admin_page(integer,integer,text,text,text,integer,integer,text,text,uuid,boolean,text)', 'EXECUTE')
     OR NOT has_function_privilege('authenticated',
       'public.classes_admin_page(integer,integer,text,text,text,integer,integer,text,text,uuid,boolean,text)', 'EXECUTE') THEN
    RAISE EXCEPTION 'L1 : les droits de classes_admin_page ont change';
  END IF;
END;
$postflight$;

COMMIT;
