-- TRANSPARENCE (31/10/2026) : la politique commerciale lue par une famille.
-- Migration 20261031100000_politique_commerciale_famille.sql.
--   1. un tuteur et un eleve adulte la lisent ; la fonction de la direction
--      leur reste refusee ;
--   2. aucune cle de paie, de marge ni de budget n'en sort ; seules les cles
--      prevues ;
--   3. la repartition : somme 1000, enseignant 470, version et date dites ;
--      avant le 1er novembre, celle de la prochaine version ;
--   4. anon refuse ; table illisible et non modifiable par un client ; une
--      repartition dont la somme n'est pas 1000 est refusee.
-- A rejouer sur une base NEUVE : fixtures inserees puis annulees.
\o /dev/null
BEGIN;

CREATE FUNCTION pg_temp.qui(p_id uuid, p_role text) RETURNS void
LANGUAGE plpgsql AS $$
DECLARE v_jwt text;
BEGIN
  v_jwt := CASE WHEN p_role IS NULL THEN '{}'
                ELSE pg_catalog.json_build_object('aal', 'aal1', 'app_metadata',
                       pg_catalog.json_build_object('role', p_role))::text END;
  PERFORM pg_catalog.set_config('request.jwt.claim.sub', coalesce(p_id::text, ''), true);
  PERFORM pg_catalog.set_config('test.uid', coalesce(p_id::text, ''), true);
  PERFORM pg_catalog.set_config('request.jwt.claims', v_jwt, true);
  PERFORM pg_catalog.set_config('test.jwt', v_jwt, true);
END $$;

CREATE FUNCTION pg_temp.vrai(p_condition boolean, p_label text) RETURNS void
LANGUAGE plpgsql AS $$
BEGIN
  IF p_condition IS NOT TRUE THEN
    RAISE EXCEPTION 'ROUGE : %', p_label;
  END IF;
  RAISE NOTICE 'OK %', p_label;
END $$;

CREATE FUNCTION pg_temp.refus(p_sql text, p_code text, p_label text) RETURNS void
LANGUAGE plpgsql AS $$
BEGIN
  BEGIN
    EXECUTE p_sql;
    RAISE EXCEPTION 'ROUGE : % (aucun refus)', p_label USING ERRCODE = 'XX999';
  EXCEPTION WHEN OTHERS THEN
    IF SQLSTATE = 'XX999' THEN RAISE; END IF;
    IF SQLSTATE <> p_code THEN
      RAISE EXCEPTION 'ROUGE : % (%, % au lieu de %)', p_label, SQLSTATE, SQLERRM, p_code;
    END IF;
  END;
  RAISE NOTICE 'OK %', p_label;
END $$;

GRANT EXECUTE ON FUNCTION pg_temp.qui(uuid, text), pg_temp.vrai(boolean, text),
  pg_temp.refus(text, text, text) TO authenticated, anon;

INSERT INTO auth.users(id, email) VALUES
 ('fb000000-0000-4000-8000-0000000000d1','pf-tuteur@test.invalid'),
 ('fb000000-0000-4000-8000-0000000000e1','pf-adulte@test.invalid');
INSERT INTO public.households(id, timezone) VALUES ('fb000000-0000-4000-8000-0000000000f1','Europe/Paris'),
 ('fb000000-0000-4000-8000-0000000000f2','Europe/Paris');
INSERT INTO public.profiles(id, immutable_id, role, household_id, first_name, last_name, account_status, gender) VALUES
 ('fb000000-0000-4000-8000-0000000000d1','PF-TUT-0001','guardian','fb000000-0000-4000-8000-0000000000f1','Tut','PF','active','female'),
 ('fb000000-0000-4000-8000-0000000000e1','PF-ELV-0001','student','fb000000-0000-4000-8000-0000000000f2','Adulte','PF','active','male');

-- ------------------------------------------------------------------
-- 1 et 2. Un tuteur la lit, sans paie, sans marge, sans budget.
-- ------------------------------------------------------------------
SET LOCAL ROLE authenticated;
SELECT pg_temp.qui('fb000000-0000-4000-8000-0000000000d1', 'guardian');
SELECT pg_temp.refus('SELECT public.politique_commerciale_active()', '42501',
  'tuteur : la fonction de la direction reste refusee');

CREATE TEMP TABLE lue AS SELECT public.politique_commerciale_famille() AS j;
SELECT pg_temp.vrai((SELECT j ->> 'version' FROM lue) IN ('v1.0.0', 'v2.0.0'),
  'tuteur : la version en vigueur est rendue');
SELECT pg_temp.vrai((SELECT j -> 'tarifEnfant' ? 'mineur' AND j -> 'tarifAdulte' ? 'mineur' FROM lue),
  'tuteur : tarifs enfant et adulte rendus');
SELECT pg_temp.vrai((SELECT pg_catalog.jsonb_typeof(j -> 'remisesParRang') = 'array'
                        AND pg_catalog.jsonb_typeof(j -> 'railsActifs') = 'array'
                        AND pg_catalog.jsonb_typeof(j -> 'essaiActif') = 'boolean'
                        AND pg_catalog.jsonb_typeof(j -> 'essaisMax') = 'number' FROM lue),
  'tuteur : essai, remises par rang et moyens de paiement rendus');
SELECT pg_temp.vrai((SELECT array_agg(k ORDER BY k) FROM lue, pg_catalog.jsonb_object_keys(j) AS k)
  = ARRAY['dateEffet','essaiActif','essaisMax','railsActifs','remisesParRang',
          'repartition','tarifAdulte','tarifEnfant','version'],
  'tuteur : seules les cles prevues sortent');
SELECT pg_temp.vrai(NOT EXISTS (
    SELECT 1 FROM lue WHERE j::text ~* '(horaire|taux|plafond|marge|budget|baseHoraire|capacite|allocation|parrainage|bourse|classes)'),
  'tuteur : aucune cle de paie, de marge ni de budget, a aucun niveau');

-- ------------------------------------------------------------------
-- 3. La repartition.
-- ------------------------------------------------------------------
SELECT pg_temp.vrai((SELECT sum((p ->> 'pourMille')::integer) = 1000
                       FROM lue, pg_catalog.jsonb_array_elements(j -> 'repartition' -> 'postes') AS p),
  'repartition : la somme fait 1000 pour mille');
SELECT pg_temp.vrai((SELECT (p ->> 'pourMille')::integer = 470
                       FROM lue, pg_catalog.jsonb_array_elements(j -> 'repartition' -> 'postes') AS p
                      WHERE p ->> 'poste' = 'enseignant'),
  'repartition : enseignant 47 %');
SELECT pg_temp.vrai((SELECT p ->> 'poste' = 'benefice'
                       FROM lue, pg_catalog.jsonb_array_elements(j -> 'repartition' -> 'postes')
                            WITH ORDINALITY AS x(p, o)
                      ORDER BY o DESC LIMIT 1),
  'repartition : le benefice en dernier');
SELECT pg_temp.vrai((SELECT j -> 'repartition' ->> 'politiqueVersion' = 'v2.0.0'
                        AND j -> 'repartition' ->> 'dateEffet' = '2026-11-01'
                        AND (j -> 'repartition' ->> 'baseElevesEnfants')::integer = 50
                        AND (j -> 'repartition' ->> 'baseElevesAdultes')::integer = 50 FROM lue),
  'repartition : version des prix, date d effet et base de calcul dites');

SELECT pg_temp.qui('fb000000-0000-4000-8000-0000000000e1', 'student');
SELECT pg_temp.vrai(public.politique_commerciale_famille() -> 'repartition' IS NOT NULL,
  'eleve adulte : la lit aussi');
SELECT pg_temp.refus('SELECT * FROM public.repartitions_paiement', '42501',
  'client : table illisible');
SELECT pg_temp.refus($q$INSERT INTO public.repartitions_paiement VALUES ('v1.0.0', 1, 1, '[]')$q$, '42501',
  'client : table non modifiable');
SELECT pg_temp.refus('SELECT private.rp_repartition_json(current_date)', '42501',
  'client : aide privee refusee');

-- ------------------------------------------------------------------
-- 4. Anon refuse.
-- ------------------------------------------------------------------
RESET ROLE;
SET LOCAL ROLE anon;
SELECT pg_temp.qui(NULL, NULL);
SELECT pg_temp.refus('SELECT public.politique_commerciale_famille()', '42501',
  'anon : refuse');
RESET ROLE;

SELECT pg_temp.vrai(private.rp_repartition_json(DATE '2026-10-30') ->> 'politiqueVersion' = 'v2.0.0',
  'repartition : avant le 1er novembre, celle de la prochaine version (v2.0.0)');
SELECT pg_temp.vrai(private.rp_repartition_json(DATE '2026-12-15') ->> 'politiqueVersion' = 'v2.0.0',
  'repartition : apres le 1er novembre, celle de la version en vigueur');
SELECT pg_temp.refus($q$INSERT INTO public.repartitions_paiement VALUES ('v1.0.0', 50, 50,
  '[{"poste":"enseignant","pour_mille":470},{"poste":"benefice","pour_mille":529}]')$q$, '23514',
  'forme : une somme de 999 est refusee');
SELECT pg_temp.refus($q$INSERT INTO public.repartitions_paiement VALUES ('v1.0.0', 50, 50,
  '[{"poste":"enseignant","pour_mille":470},{"poste":"loyer","pour_mille":530}]')$q$, '23514',
  'forme : un poste inconnu est refuse');

ROLLBACK;
\o
\echo 'scenarios_politique_famille : OK'
