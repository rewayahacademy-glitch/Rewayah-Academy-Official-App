-- FRISE-HEURE, partie serveur (08/11/2026 ; option C du pilote et du
-- garde-cap ; plage reservee par le garde-cap : 20261121700000). N'est pas
-- installee cette nuit : le pilote l'installe apres le CONFORME du garde-cap.
--
-- Le defaut : la vue public.demande_evenements_foyer_v rend survenu_le_foyer
-- comme un instant (timestamptz), choix volontaire de la migration
-- 20261011183000_c20_utc_instants.sql (« C-20/C-28 : expose instants UTC and
-- keep the household IANA zone separate », decision Codex non documentee dans
-- docs/current). Le client Dart attendait une heure murale du foyer et levait
-- une FormatException : la frise de la famille tombait en erreur. La PR client
-- 363 l'a corrigee en n'affichant que le jour d'un instant, faute de pouvoir
-- convertir un fuseau IANA cote client (pubspec gele).
--
-- Ce que fait ce fichier, et rien d'autre : il AJOUTE en fin de vue une
-- colonne survenu_le_murale = (e.survenu_le AT TIME ZONE h.timezone), l'heure
-- murale du foyer (timestamp sans fuseau), calculee par le serveur qui
-- connait les fuseaux. survenu_le_foyer reste l'instant de C-28, tel quel ;
-- les autres colonnes, leur ordre, le filtre, security_barrier et les droits
-- sont inchanges (CREATE OR REPLACE VIEW garde les droits et n'accepte qu'un
-- ajout en fin de liste). Une petite PR client lira la nouvelle colonne apres
-- l'installation.
--
-- PREFLIGHT : md5(pg_get_viewdef) relu sur une base rejouee depuis le depot
-- (main 7abbe4b8, Postgres 17) : 1a59f17df15dd6a5ff414f5cbfc622a7. A verifier
-- en production par le pilote avant l'application (lecture seule) :
--   SELECT pg_catalog.md5(pg_catalog.pg_get_viewdef(
--            'public.demande_evenements_foyer_v'::regclass));
-- Une definition differente, sans la colonne de ce lot, arrete le fichier.
-- Rejouable : deja appliquee, rien n'est refait.
--
-- Sans BEGIN ni COMMIT de premier niveau. Aucun mot d'effacement :
-- applicable par apply_migration.

DO $migration$
DECLARE
  v_def text := pg_catalog.pg_get_viewdef('public.demande_evenements_foyer_v'::regclass);
BEGIN
  IF pg_catalog.strpos(v_def, 'survenu_le_murale') > 0 THEN
    RAISE NOTICE 'FRISE-HEURE : survenu_le_murale deja presente, rien n''est refait';
    RETURN;
  END IF;
  IF pg_catalog.md5(v_def) <> '1a59f17df15dd6a5ff414f5cbfc622a7' THEN
    RAISE EXCEPTION 'FRISE-HEURE : demande_evenements_foyer_v a change (md5 %), rien n''est change',
      pg_catalog.md5(v_def);
  END IF;

  EXECUTE $vue$
CREATE OR REPLACE VIEW public.demande_evenements_foyer_v
WITH (security_barrier = true)
AS
SELECT e.id,
       e.demande_id,
       e.eleve_id,
       e.type,
       e.motif_attente,
       e.survenu_le AS survenu_le_foyer,
       h.timezone AS fuseau_iana,
       (e.survenu_le AT TIME ZONE h.timezone) AS survenu_le_murale
  FROM public.demande_evenements e
  JOIN public.profiles p ON p.id = e.eleve_id AND p.deleted_at IS NULL
  JOIN public.households h ON h.id = p.household_id
 WHERE public.app_account_valid()
   AND (
     (
       e.household_id = public.app_household_id()
       AND p.household_id = public.app_household_id()
       AND h.deleted_at IS NULL
       AND h.status = 'active'
     )
     OR public.app_role() = 'admin'
   )
$vue$;
END
$migration$;

COMMENT ON COLUMN public.demande_evenements_foyer_v.survenu_le_murale IS
  'FRISE-HEURE (20261121700000) : heure murale du foyer (survenu_le AT TIME ZONE households.timezone), sans fuseau. survenu_le_foyer reste l''instant UTC de C-28.';

-- Postflight : colonne ajoutee en fin, colonnes de C-28 inchangees, filtre,
-- barriere et droits intacts.
DO $postflight$
DECLARE
  v_def text := pg_catalog.pg_get_viewdef('public.demande_evenements_foyer_v'::regclass);
  v_cols text;
BEGIN
  SELECT pg_catalog.string_agg(a.attname || ':' || pg_catalog.format_type(a.atttypid, a.atttypmod), ',' ORDER BY a.attnum)
    INTO v_cols
    FROM pg_catalog.pg_attribute a
   WHERE a.attrelid = 'public.demande_evenements_foyer_v'::regclass AND a.attnum > 0 AND NOT a.attisdropped;
  IF v_cols IS DISTINCT FROM
     'id:uuid,demande_id:uuid,eleve_id:uuid,type:text,motif_attente:text,survenu_le_foyer:timestamp with time zone,fuseau_iana:text,survenu_le_murale:timestamp without time zone' THEN
    RAISE EXCEPTION 'FRISE-HEURE postflight : colonnes inattendues : %', v_cols;
  END IF;
  IF pg_catalog.strpos(v_def, 'app_account_valid()') = 0
     OR pg_catalog.strpos(v_def, 'app_household_id()') = 0 THEN
    RAISE EXCEPTION 'FRISE-HEURE postflight : filtre de la vue absent';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_catalog.pg_class c
                  WHERE c.oid = 'public.demande_evenements_foyer_v'::regclass
                    AND c.reloptions @> array['security_barrier=true']) THEN
    RAISE EXCEPTION 'FRISE-HEURE postflight : security_barrier perdu';
  END IF;
  IF NOT pg_catalog.has_table_privilege('authenticated', 'public.demande_evenements_foyer_v', 'SELECT')
     OR pg_catalog.has_table_privilege('anon', 'public.demande_evenements_foyer_v', 'SELECT') THEN
    RAISE EXCEPTION 'FRISE-HEURE postflight : droits de lecture incorrects';
  END IF;
END
$postflight$;
