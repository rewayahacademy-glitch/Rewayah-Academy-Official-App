-- CALENDRIER-ET-PAUSES (lot 2) : le calcul du recul ne suppose ni programme publie
-- ni fait « etape en cours » present. Base nue apres les migrations : aucune version
-- publiee, aucun eleve rattache (le lot 1 ne publie plus a l'installation).
--   1. publier, modifier, retirer une fermeture : aucune erreur, aucun eleve a reculer ;
--   2. un eleve sans etape demande une pause d'un mois, la direction en accorde une
--      d'exception, la famille la lit : aucune erreur, aucun fait cree ;
--   3. le calendrier se lit par chacun ;
--   4. un eleve qui recoit ensuite son etape (programme publie apres coup) a son recul
--      calcule des l'ecriture du fait.
-- Echoue sans les migrations. Tout est annule.
\o /dev/null
BEGIN;
SET CONSTRAINTS ALL IMMEDIATE;

CREATE FUNCTION pg_temp.qui(p_id uuid, p_role text, p_foyer uuid DEFAULT NULL) RETURNS void
LANGUAGE plpgsql AS $$
DECLARE v_jwt text := pg_catalog.json_build_object('aal', 'aal1', 'app_metadata',
                        pg_catalog.json_build_object('role', p_role, 'household_id', p_foyer))::text;
BEGIN
  PERFORM pg_catalog.set_config('request.jwt.claim.sub', p_id::text, true);
  PERFORM pg_catalog.set_config('test.uid', p_id::text, true);
  PERFORM pg_catalog.set_config('request.jwt.claims', v_jwt, true);
  PERFORM pg_catalog.set_config('test.jwt', v_jwt, true);
END $$;
CREATE FUNCTION pg_temp.vrai(p_condition boolean, p_label text) RETURNS void
LANGUAGE plpgsql AS $$
BEGIN
  IF p_condition IS NOT TRUE THEN RAISE EXCEPTION 'ROUGE : %', p_label; END IF;
  RAISE NOTICE 'OK %', p_label;
END $$;
CREATE FUNCTION pg_temp.u(p text) RETURNS uuid LANGUAGE sql AS
  $$ SELECT pg_catalog.md5('calendrier-sans-programme-' || p)::uuid $$;
CREATE FUNCTION pg_temp.auj() RETURNS date LANGUAGE sql AS $$ SELECT (pg_catalog.now() AT TIME ZONE 'Asia/Riyadh')::date $$;
CREATE FUNCTION pg_temp.mois(k integer) RETURNS date LANGUAGE sql AS
  $$ SELECT (pg_catalog.date_trunc('month', pg_temp.auj()::timestamp) + pg_catalog.make_interval(months => k))::date $$;
GRANT EXECUTE ON FUNCTION pg_temp.qui(uuid, text, uuid), pg_temp.vrai(boolean, text), pg_temp.u(text),
  pg_temp.auj(), pg_temp.mois(integer) TO authenticated, anon;

SELECT pg_temp.vrai(NOT EXISTS (SELECT 1 FROM public.programme_versions WHERE statut = 'publiee')
                    AND NOT EXISTS (SELECT 1 FROM public.eleve_etape_en_cours),
  'base de depart : aucun programme publie, aucun fait « etape en cours »');

INSERT INTO auth.users(id, email)
SELECT pg_temp.u(x), 'csp-' || x || '@test.invalid' FROM unnest(ARRAY['a1','t1','e1']) AS x;
INSERT INTO public.households(id, timezone) VALUES (pg_temp.u('f1'), 'UTC');
INSERT INTO public.profiles(id, immutable_id, role, household_id, first_name, last_name, account_status, gender)
SELECT pg_temp.u(x.id), x.mat, x.role::public.app_role,
       CASE WHEN x.foyer IS NOT NULL THEN pg_temp.u(x.foyer) END, x.prenom, 'CSP', 'active'::public.account_status, 'female'::public.gender
  FROM (VALUES ('a1','CSP-ADM-01','admin',NULL,'Direction'), ('t1','CSP-TUT-01','guardian','f1','Tutrice'),
               ('e1','CSP-ELV-01','student','f1','Eleve')) AS x(id, mat, role, foyer, prenom);
INSERT INTO public.student_profiles(profile_id, student_type, interface_mode, cohorte)
VALUES (pg_temp.u('e1'), 'minor', 'child', 'enfant_6_9');

-- 1 et 2 : les gestes de la direction et de la famille, sans programme.
SELECT pg_temp.qui(pg_temp.u('a1'), 'admin');
SET LOCAL ROLE authenticated;
SELECT public.calendrier_ecole_enregistrer(NULL, 'fermeture', 'autre', 'Fermeture', pg_temp.auj() + 3, pg_temp.auj() + 22, 'ecole', NULL, NULL) AS f \gset r1_
SELECT public.calendrier_ecole_publier(:'r1_f'::uuid, true);
SELECT public.calendrier_ecole_enregistrer(:'r1_f'::uuid, 'fermeture', 'autre', 'Fermeture changee', pg_temp.auj() + 3, pg_temp.auj() + 9, 'ecole', NULL, NULL);
SELECT public.calendrier_ecole_publier(:'r1_f'::uuid, false);
SELECT public.calendrier_ecole_publier(:'r1_f'::uuid, true);
RESET ROLE;
SELECT pg_temp.vrai(NOT EXISTS (SELECT 1 FROM public.eleve_etape_en_cours),
  'publier, modifier, retirer puis republier une fermeture sans programme : aucune erreur, aucun fait cree');

UPDATE public.app_config SET value = pg_catalog.to_jsonb(true) WHERE key = 'pause.demande_famille_ouverte';
SELECT pg_temp.qui(pg_temp.u('t1'), 'guardian', pg_temp.u('f1'));
SET LOCAL ROLE authenticated;
SELECT public.pause_demander(pg_temp.u('e1'), pg_temp.mois(2)) ->> 'statut' AS statut \gset r2_
SELECT public.pauses_eleve_lecture(pg_temp.u('e1')) -> 'mois_proposes' AS proposes \gset r3_
RESET ROLE;
SELECT pg_temp.qui(pg_temp.u('a1'), 'admin');
SET LOCAL ROLE authenticated;
SELECT public.pause_exception_accorder(pg_temp.u('e1'), NULL, pg_temp.auj() + 5, 'Maladie soudaine');
SELECT public.pauses_a_traiter() AS file \gset r4_
RESET ROLE;
SELECT pg_temp.vrai(:'r2_statut' = 'acceptee' AND pg_catalog.jsonb_array_length(:'r3_proposes'::jsonb) = 12
                    AND NOT EXISTS (SELECT 1 FROM public.eleve_etape_en_cours),
  'un eleve sans etape : la pause d''un mois et l''exception se demandent, se lisent, sans erreur ni fait cree');

-- 3 : la lecture du calendrier, sans programme.
SELECT pg_temp.qui(pg_temp.u('t1'), 'guardian', pg_temp.u('f1'));
SET LOCAL ROLE authenticated;
SELECT pg_catalog.jsonb_array_length(public.calendrier_ecole_lecture()) AS n \gset r5_
RESET ROLE;
SELECT pg_temp.vrai(:'r5_n'::int = 1, 'la lecture du calendrier fonctionne sans programme');

-- 4 : le fait arrive apres coup (programme publie ensuite) : son recul est calcule des l'ecriture.
SELECT pg_temp.qui(pg_temp.u('a1'), 'admin');
SET LOCAL ROLE authenticated;
SELECT public.creer_version_programme(NULL) AS v \gset prog_
SELECT public.preremplir_bases_programme(:'prog_v'::uuid);
SELECT public.publier_version_programme(:'prog_v'::uuid, 'Version 1 des bases');
RESET ROLE;
INSERT INTO public.eleve_etape_en_cours(student_id, niveau_id, cohorte, entree_etape_le, entree_niveau_le, origine)
VALUES (pg_temp.u('e1'), private.etape_par_defaut(), 'enfant_6_9', pg_temp.auj(), pg_temp.auj(), 'classe');
SELECT pg_temp.vrai(
  (SELECT recul_jours FROM public.eleve_etape_en_cours WHERE student_id = pg_temp.u('e1')) > 0,
  'un fait ecrit apres coup recoit tout de suite son recul (fermeture publiee et pauses acceptees deja la)');

\o
SELECT 'scenarios_calendrier_pauses_sans_programme : tous les controles sont verts' AS resultat;
ROLLBACK;
