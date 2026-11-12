-- CORRIGER-SOURATE (directeur, 11/11/2026 ; decisions du garde-cap, 11/11) :
-- une sourate validee par erreur se retire. Migration 20261123820000.
-- a1 direction ; b1 titulaire de la Classe c1 ; b3 enseignant d'une autre
-- Classe c2 (et remplacant auteur d'un cahier de c1) ; t1 tuteur du foyer
-- f1 ; e1, e2 eleves de f1 dans c1.
--   1. l'auteur dans les 24 h : oui ; la ligne reste, marquee ; journalise ;
--   2. les lecteurs ecartent la sourate retiree (sourates_eleve,
--      sourates_bases_classe) ;
--   3. l'auteur au-dela de 24 h : refus ;
--   4. un autre enseignant : refus ; le remplacant auteur : oui ;
--   5. la direction, sans limite de temps : oui ; deux fois : non validee ;
--      tuteur et eleve : refus ; motif trop long : refus ;
--   6. ce que chacun peut retirer (sourates_retirables_classe) ;
--   7. la modification du cahier ne reactive pas ;
--   8. decocher puis recocher reactive ; un nouveau cahier reactive ;
--   9. droits.
-- Echoue sans la migration (premier ROUGE : la colonne retiree_le n'existe
-- pas). Tout est annule a la fin.
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
  IF p_condition IS NOT TRUE THEN
    RAISE EXCEPTION 'ROUGE : %', p_label;
  END IF;
  RAISE NOTICE 'OK %', p_label;
END $$;

CREATE FUNCTION pg_temp.u(p text) RETURNS uuid LANGUAGE sql AS
  $$ SELECT pg_catalog.md5('corriger-sourate-' || p)::uuid $$;

-- Retire et rend 'ok', 'refus', ou le message d'erreur.
CREATE FUNCTION pg_temp.retirer(p_eleve uuid, p_sourate int, p_motif text DEFAULT NULL) RETURNS text
LANGUAGE plpgsql AS $$
BEGIN
  PERFORM public.retirer_sourate_validee(p_eleve, p_sourate, p_motif);
  RETURN 'ok';
EXCEPTION
  WHEN insufficient_privilege THEN RETURN 'refus';
  WHEN OTHERS THEN RETURN SQLERRM;
END $$;

-- « validees/total » que rend sourates_eleve pour [p_eleve], ou 'refus'.
CREATE FUNCTION pg_temp.suivi(p_eleve uuid) RETURNS text
LANGUAGE plpgsql AS $$
DECLARE r jsonb;
BEGIN
  r := public.sourates_eleve(p_eleve);
  RETURN (r ->> 'sourates_validees') || '/' || (r ->> 'sourates_total');
EXCEPTION
  WHEN insufficient_privilege THEN RETURN 'refus';
END $$;

-- Les sourates de la Classe [p_groupe] : « lignes/validees », ou 'refus'.
CREATE FUNCTION pg_temp.classe(p_groupe uuid) RETURNS text
LANGUAGE plpgsql AS $$
DECLARE v text;
BEGIN
  SELECT pg_catalog.count(*) || '/' || pg_catalog.count(*) FILTER (WHERE c.validee) INTO v
    FROM public.sourates_bases_classe(p_groupe) c;
  RETURN v;
EXCEPTION
  WHEN insufficient_privilege THEN RETURN 'refus';
END $$;

-- Ce que la personne connectee peut retirer dans [p_groupe] :
-- « eleve:numero:limite » tries, limite 'sans' ou 'jour', ou 'refus'.
CREATE FUNCTION pg_temp.retirables(p_groupe uuid) RETURNS text
LANGUAGE plpgsql AS $$
DECLARE v text;
BEGIN
  SELECT coalesce(pg_catalog.string_agg(
           CASE r.student_id WHEN pg_temp.u('e1') THEN 'e1' WHEN pg_temp.u('e2') THEN 'e2' ELSE '?' END
           || ':' || r.numero || ':'
           || CASE WHEN r.retirable_jusqua IS NULL THEN 'sans' ELSE 'jour' END,
           ',' ORDER BY 1), '') INTO v
    FROM public.sourates_retirables_classe(p_groupe) r;
  RETURN v;
EXCEPTION
  WHEN insufficient_privilege THEN RETURN 'refus';
END $$;

GRANT EXECUTE ON FUNCTION pg_temp.qui(uuid, text, uuid), pg_temp.vrai(boolean, text), pg_temp.u(text),
  pg_temp.retirer(uuid, int, text), pg_temp.suivi(uuid), pg_temp.classe(uuid),
  pg_temp.retirables(uuid) TO authenticated, anon;

CREATE TEMP TABLE cs_ids(cle text PRIMARY KEY, id uuid);
GRANT ALL ON cs_ids TO authenticated;

-- ------------------------------------------------------------------
-- Fixtures
-- ------------------------------------------------------------------
INSERT INTO auth.users(id, email)
SELECT pg_temp.u(x), 'cs-' || x || '@test.invalid'
  FROM unnest(ARRAY['a1','b1','b3','t1','e1','e2']) AS x;
INSERT INTO public.households(id, timezone) VALUES (pg_temp.u('f1'), 'Europe/Paris');
INSERT INTO public.profiles(id, immutable_id, role, household_id, first_name, last_name, account_status, gender)
SELECT pg_temp.u(x.id), x.mat, x.role::public.app_role,
       CASE WHEN x.foyer IS NOT NULL THEN pg_temp.u(x.foyer) END,
       x.prenom, 'CS', (CASE x.role WHEN 'teacher' THEN 'provisional_active' ELSE 'active' END)::public.account_status,
       'female'::public.gender
  FROM (VALUES
   ('a1','CS-ADM-01','admin',NULL,'Direction'),
   ('b1','CS-ENS-01','teacher',NULL,'Titulaire'),
   ('b3','CS-ENS-03','teacher',NULL,'Autre'),
   ('t1','CS-TUT-01','guardian','f1','Tutrice'),
   ('e1','CS-ELV-01','student','f1','Eleve un'),
   ('e2','CS-ELV-02','student','f1','Eleve deux')) AS x(id, mat, role, foyer, prenom);
INSERT INTO public.student_profiles(profile_id, student_type, interface_mode, cohorte)
SELECT pg_temp.u(x), 'minor'::public.student_type, 'standard'::public.interface_mode, 'enfant_10_13'
  FROM unnest(ARRAY['e1','e2']) AS x;
INSERT INTO public.groupes(id, teacher_id, type_public, seuil_max, libelle, weekday, hour_local, timezone_iana) VALUES
 (pg_temp.u('c1'), pg_temp.u('b1'), 'enfant', 6, 'An-Nour CS', 1, 18, 'Europe/Paris'),
 (pg_temp.u('c2'), pg_temp.u('b3'), 'enfant', 6, 'Al-Fajr CS', 2, 18, 'Europe/Paris');
INSERT INTO public.groupe_membres(groupe_id, student_id)
SELECT pg_temp.u('c1'), pg_temp.u(x) FROM unnest(ARRAY['e1','e2']) AS x;

SELECT pg_temp.qui(pg_temp.u('a1'), 'admin');
SET LOCAL ROLE authenticated;
INSERT INTO cs_ids VALUES ('v1', public.creer_version_programme(NULL));
SELECT public.preremplir_bases_programme((SELECT id FROM cs_ids WHERE cle = 'v1'));
INSERT INTO cs_ids
SELECT 'n' || c.ordre, c.niveau_id
  FROM public.programme_contenu_admin((SELECT id FROM cs_ids WHERE cle = 'v1')) c;
SELECT public.publier_version_programme((SELECT id FROM cs_ids WHERE cle = 'v1'), 'Version 1 des bases');
RESET ROLE;
UPDATE public.groupes SET programme_niveau_id = (SELECT id FROM cs_ids WHERE cle = 'n1')
 WHERE id IN (pg_temp.u('c1'), pg_temp.u('c2'));

INSERT INTO public.sessions(id, teacher_id, started_at, ended_at, status, groupe_id)
VALUES (pg_temp.u('s1'), pg_temp.u('b1'), pg_catalog.now() - interval '2 hours',
        pg_catalog.now() - interval '1 hour', 'ended', pg_temp.u('c1'));
INSERT INTO public.session_participants(session_id, profile_id, role)
SELECT pg_temp.u('s1'), pg_temp.u(e), 'student'::public.participant_role
  FROM unnest(ARRAY['e1','e2']) AS e;

-- Le cahier du titulaire : 1, 99 et 114 pour e1 ; 1 pour e2.
INSERT INTO public.lesson_reports(id, session_id, idempotency_key, content, author_profile_id)
VALUES (pg_temp.u('r1'), pg_temp.u('s1'), 'cs-r1', pg_catalog.jsonb_build_object(
  'version', 1, 'position_reprise', 'Page 3',
  'eleves', pg_catalog.jsonb_build_array(
    pg_catalog.jsonb_build_object('student_id', pg_temp.u('e1'), 'confirme', true,
      'sourates_validees', pg_catalog.jsonb_build_array(1, 99, 114)),
    pg_catalog.jsonb_build_object('student_id', pg_temp.u('e2'), 'confirme', true,
      'sourates_validees', pg_catalog.jsonb_build_array(1)))),
  pg_temp.u('b1'));
SELECT pg_temp.vrai(
  (SELECT pg_catalog.count(*) FROM public.sourates_validees WHERE retiree_le IS NULL) = 4,
  'depart : quatre sourates validees, aucune retiree');

-- ------------------------------------------------------------------
-- 1. L'auteur dans les 24 h : oui
-- ------------------------------------------------------------------
SELECT pg_temp.qui(pg_temp.u('b1'), 'teacher');
SET LOCAL ROLE authenticated;
SELECT pg_temp.vrai(pg_temp.retirer(pg_temp.u('e1'), 114, '  Cochee par erreur  ') = 'ok',
  'auteur dans les 24 h : retrait accepte');
RESET ROLE;
SELECT pg_temp.vrai(
  (SELECT pg_catalog.count(*) FROM public.sourates_validees WHERE student_id = pg_temp.u('e1')) = 3
  AND (SELECT retiree_le IS NOT NULL AND retiree_par = pg_temp.u('b1')
              AND motif_retrait = 'Cochee par erreur' AND validee_par = pg_temp.u('b1')
         FROM public.sourates_validees
        WHERE student_id = pg_temp.u('e1') AND sourate_numero = 114),
  'auteur : la ligne reste, marquee retiree par l''auteur, motif sans espaces autour');
SELECT pg_temp.vrai(
  EXISTS (SELECT 1 FROM public.audit_logs
           WHERE action = 'sourate_retiree' AND table_name = 'sourates_validees'
             AND row_id = pg_temp.u('e1')::text || ':114' AND actor = pg_temp.u('b1')
             AND payload ->> 'motif' = 'Cochee par erreur'),
  'auteur : le retrait est journalise');

-- ------------------------------------------------------------------
-- 2. Les lecteurs ecartent la sourate retiree
-- ------------------------------------------------------------------
SELECT pg_temp.qui(pg_temp.u('t1'), 'guardian', pg_temp.u('f1'));
SET LOCAL ROLE authenticated;
SELECT pg_temp.vrai(pg_temp.suivi(pg_temp.u('e1')) = '2/17'
  AND (SELECT (s ->> 'validee')::boolean FROM pg_catalog.jsonb_array_elements(
         public.sourates_eleve(pg_temp.u('e1')) -> 'sourates') AS s
        WHERE (s ->> 'numero')::int = 114) = false,
  'sourates_eleve : 2 sur 17, An-Nas n''est plus validee');
RESET ROLE;
SELECT pg_temp.qui(pg_temp.u('b1'), 'teacher');
SET LOCAL ROLE authenticated;
SELECT pg_temp.vrai(pg_temp.classe(pg_temp.u('c1')) = '34/3'
  AND NOT EXISTS (SELECT 1 FROM public.sourates_bases_classe(pg_temp.u('c1')) c
                   WHERE c.student_id = pg_temp.u('e1') AND c.numero = 114 AND c.validee),
  'sourates_bases_classe : 3 validees sur 34, An-Nas a nouveau a valider pour e1');
RESET ROLE;

-- ------------------------------------------------------------------
-- 3. L'auteur au-dela de 24 h : refus
-- ------------------------------------------------------------------
UPDATE public.sourates_validees SET valide_le = pg_catalog.now() - interval '25 hours'
 WHERE student_id = pg_temp.u('e1') AND sourate_numero = 99;
SELECT pg_temp.qui(pg_temp.u('b1'), 'teacher');
SET LOCAL ROLE authenticated;
SELECT pg_temp.vrai(pg_temp.retirer(pg_temp.u('e1'), 99) = 'refus',
  'auteur au-dela de 24 h : refus');
-- La meme reponse pour une sourate jamais validee : rien ne se devine.
SELECT pg_temp.vrai(pg_temp.retirer(pg_temp.u('e1'), 113) = 'refus',
  'auteur, sourate jamais validee : refus, comme le reste');
RESET ROLE;
SELECT pg_temp.vrai(
  (SELECT retiree_le IS NULL FROM public.sourates_validees
    WHERE student_id = pg_temp.u('e1') AND sourate_numero = 99),
  'au-dela de 24 h : la sourate reste validee');

-- ------------------------------------------------------------------
-- 4. Un autre enseignant : refus ; le remplacant auteur : oui
-- ------------------------------------------------------------------
SELECT pg_temp.qui(pg_temp.u('b3'), 'teacher');
SET LOCAL ROLE authenticated;
SELECT pg_temp.vrai(pg_temp.retirer(pg_temp.u('e2'), 1) = 'refus',
  'autre enseignant : refus');
RESET ROLE;
-- b3 remplace le titulaire et depose un cahier de la seance : Al-Falaq pour e2.
INSERT INTO public.lesson_reports(id, session_id, idempotency_key, content, author_profile_id, created_at)
VALUES (pg_temp.u('r3'), pg_temp.u('s1'), 'cs-r3', pg_catalog.jsonb_build_object(
  'version', 1, 'eleves', pg_catalog.jsonb_build_array(
    pg_catalog.jsonb_build_object('student_id', pg_temp.u('e2'), 'confirme', true,
      'sourates_validees', pg_catalog.jsonb_build_array(113)))),
  pg_temp.u('b3'), pg_catalog.now() + interval '1 minute');
SELECT pg_temp.qui(pg_temp.u('b3'), 'teacher');
SET LOCAL ROLE authenticated;
SELECT pg_temp.vrai(pg_temp.retirer(pg_temp.u('e2'), 113) = 'ok',
  'remplacant auteur de la validation, dans les 24 h : oui');
RESET ROLE;
SELECT pg_temp.qui(pg_temp.u('b1'), 'teacher');
SET LOCAL ROLE authenticated;
SELECT pg_temp.vrai(pg_temp.retirer(pg_temp.u('e2'), 1) = 'ok',
  'titulaire auteur : oui (e2, Al-Fatiha)');
RESET ROLE;

-- ------------------------------------------------------------------
-- 5. La direction, sans limite de temps
-- ------------------------------------------------------------------
SELECT pg_temp.qui(pg_temp.u('a1'), 'admin');
SET LOCAL ROLE authenticated;
SELECT pg_temp.vrai(pg_temp.retirer(pg_temp.u('e1'), 99, NULL) = 'ok',
  'direction, validation de plus de 24 h : oui');
SELECT pg_temp.vrai(pg_temp.retirer(pg_temp.u('e1'), 99) = 'sourate non validee',
  'direction, deja retiree : non validee');
RESET ROLE;
SELECT pg_temp.vrai(
  (SELECT retiree_par = pg_temp.u('a1') AND motif_retrait IS NULL FROM public.sourates_validees
    WHERE student_id = pg_temp.u('e1') AND sourate_numero = 99)
  AND EXISTS (SELECT 1 FROM public.audit_logs
               WHERE action = 'sourate_retiree' AND actor = pg_temp.u('a1')
                 AND (payload ->> 'par_la_direction')::boolean),
  'direction : marquee par la direction, sans motif, journalisee');
SELECT pg_temp.qui(pg_temp.u('t1'), 'guardian', pg_temp.u('f1'));
SET LOCAL ROLE authenticated;
SELECT pg_temp.vrai(pg_temp.retirer(pg_temp.u('e1'), 1) = 'refus', 'tuteur : refus');
RESET ROLE;
SELECT pg_temp.qui(pg_temp.u('e1'), 'student', pg_temp.u('f1'));
SET LOCAL ROLE authenticated;
SELECT pg_temp.vrai(pg_temp.retirer(pg_temp.u('e1'), 1) = 'refus', 'eleve : refus');
RESET ROLE;
SELECT pg_temp.qui(pg_temp.u('b1'), 'teacher');
SET LOCAL ROLE authenticated;
SELECT pg_temp.vrai(pg_temp.retirer(pg_temp.u('e1'), 1, pg_catalog.repeat('x', 501)) = 'motif trop long',
  'motif de plus de 500 signes : refus');
RESET ROLE;

-- ------------------------------------------------------------------
-- 6. Ce que chacun peut retirer
-- ------------------------------------------------------------------
-- Restent validees : e1 Al-Fatiha (b1, aujourd'hui).
SELECT pg_temp.qui(pg_temp.u('b1'), 'teacher');
SET LOCAL ROLE authenticated;
SELECT pg_temp.vrai(pg_temp.retirables(pg_temp.u('c1')) = 'e1:1:jour',
  'titulaire : ses validations des dernieres 24 h, avec leur limite');
RESET ROLE;
SELECT pg_temp.qui(pg_temp.u('a1'), 'admin');
SET LOCAL ROLE authenticated;
SELECT pg_temp.vrai(pg_temp.retirables(pg_temp.u('c1')) = 'e1:1:sans',
  'direction : toutes, sans limite');
RESET ROLE;
SELECT pg_temp.qui(pg_temp.u('b3'), 'teacher');
SET LOCAL ROLE authenticated;
SELECT pg_temp.vrai(pg_temp.retirables(pg_temp.u('c1')) = 'refus',
  'autre enseignant : la Classe d''un autre est refusee');
RESET ROLE;
SELECT pg_temp.qui(pg_temp.u('t1'), 'guardian', pg_temp.u('f1'));
SET LOCAL ROLE authenticated;
SELECT pg_temp.vrai(pg_temp.retirables(pg_temp.u('c1')) = 'refus', 'tuteur : refus');
RESET ROLE;

-- ------------------------------------------------------------------
-- 7. La modification du cahier ne reactive pas
-- ------------------------------------------------------------------
-- r1 contient toujours 99 et 114 pour e1 : une modification du cahier
-- (la page de reprise) ne les fait pas revenir.
SELECT pg_temp.qui(pg_temp.u('b1'), 'teacher');
SET LOCAL ROLE authenticated;
UPDATE public.lesson_reports
   SET content = pg_catalog.jsonb_set(content, '{position_reprise}', '"Page 4"'::jsonb)
 WHERE id = pg_temp.u('r1');
RESET ROLE;
SELECT pg_temp.vrai(
  (SELECT pg_catalog.bool_and(retiree_le IS NOT NULL) FROM public.sourates_validees
    WHERE student_id = pg_temp.u('e1') AND sourate_numero IN (99, 114)),
  'cahier modifie, sourates encore cochees : pas de reactivation');

-- ------------------------------------------------------------------
-- 8. Decocher puis recocher reactive ; un nouveau cahier reactive
-- ------------------------------------------------------------------
UPDATE public.sourates_validees SET valide_le = pg_catalog.now() - interval '2 hours'
 WHERE student_id = pg_temp.u('e1') AND sourate_numero = 114;
SELECT pg_temp.qui(pg_temp.u('b1'), 'teacher');
SET LOCAL ROLE authenticated;
UPDATE public.lesson_reports
   SET content = pg_catalog.jsonb_set(content, '{eleves,0,sourates_validees}',
                                      pg_catalog.jsonb_build_array(1, 99))
 WHERE id = pg_temp.u('r1');
RESET ROLE;
SELECT pg_temp.vrai(
  (SELECT retiree_le IS NOT NULL FROM public.sourates_validees
    WHERE student_id = pg_temp.u('e1') AND sourate_numero = 114),
  'decochee : An-Nas reste retiree');
SELECT pg_temp.qui(pg_temp.u('b1'), 'teacher');
SET LOCAL ROLE authenticated;
UPDATE public.lesson_reports
   SET content = pg_catalog.jsonb_set(content, '{eleves,0,sourates_validees}',
                                      pg_catalog.jsonb_build_array(1, 99, '114'))
 WHERE id = pg_temp.u('r1');
RESET ROLE;
SELECT pg_temp.vrai(
  (SELECT retiree_le IS NULL AND retiree_par IS NULL AND motif_retrait IS NULL
          AND validee_par = pg_temp.u('b1') AND valide_le = pg_catalog.now()
     FROM public.sourates_validees
    WHERE student_id = pg_temp.u('e1') AND sourate_numero = 114)
  AND (SELECT retiree_le IS NOT NULL FROM public.sourates_validees
        WHERE student_id = pg_temp.u('e1') AND sourate_numero = 99)
  AND EXISTS (SELECT 1 FROM public.audit_logs
               WHERE action = 'sourate_reactivee' AND row_id = pg_temp.u('e1')::text || ':114'),
  'recochee : An-Nas revient (marquage remis a vide, auteur et date a jour, journalise) ; '
  'Al-Zalzalah, restee cochee, reste retiree');
-- Un nouveau cahier (INSERT) : toutes ses sourates apparaissent.
INSERT INTO public.lesson_reports(id, session_id, idempotency_key, content, author_profile_id, created_at)
VALUES (pg_temp.u('r4'), pg_temp.u('s1'), 'cs-r4', pg_catalog.jsonb_build_object(
  'version', 1, 'eleves', pg_catalog.jsonb_build_array(
    pg_catalog.jsonb_build_object('student_id', pg_temp.u('e1'), 'confirme', true,
      'sourates_validees', pg_catalog.jsonb_build_array(99)))),
  pg_temp.u('b1'), pg_catalog.now() + interval '2 minutes');
SELECT pg_temp.vrai(
  (SELECT retiree_le IS NULL AND lesson_report_id = pg_temp.u('r4') FROM public.sourates_validees
    WHERE student_id = pg_temp.u('e1') AND sourate_numero = 99),
  'nouveau cahier : Al-Zalzalah revient');
-- Une validation active ne bouge pas quand un autre cahier la recoche.
SELECT pg_temp.vrai(
  (SELECT lesson_report_id = pg_temp.u('r1') FROM public.sourates_validees
    WHERE student_id = pg_temp.u('e1') AND sourate_numero = 1),
  'validation active : inchangee');
SELECT pg_temp.qui(pg_temp.u('t1'), 'guardian', pg_temp.u('f1'));
SET LOCAL ROLE authenticated;
SELECT pg_temp.vrai(pg_temp.suivi(pg_temp.u('e1')) = '3/17', 'apres reactivation : 3 sur 17');
RESET ROLE;

-- ------------------------------------------------------------------
-- 9. Droits
-- ------------------------------------------------------------------
SELECT pg_temp.vrai(
  NOT has_table_privilege('authenticated', 'public.sourates_validees', 'SELECT')
  AND NOT has_table_privilege('authenticated', 'public.sourates_validees', 'UPDATE')
  AND NOT has_function_privilege('anon', 'public.retirer_sourate_validee(uuid,integer,text)', 'EXECUTE')
  AND NOT has_function_privilege('anon', 'public.sourates_retirables_classe(uuid)', 'EXECUTE')
  AND NOT has_function_privilege('agent_ro', 'public.retirer_sourate_validee(uuid,integer,text)', 'EXECUTE')
  AND NOT has_function_privilege('agent_ro', 'public.sourates_retirables_classe(uuid)', 'EXECUTE')
  AND has_function_privilege('authenticated', 'public.retirer_sourate_validee(uuid,integer,text)', 'EXECUTE')
  AND NOT has_function_privilege('authenticated', 'private.cahier_sourates_validees()', 'EXECUTE')
  AND (SELECT p.prosecdef AND p.proconfig @> ARRAY['search_path=""']
         FROM pg_catalog.pg_proc p
        WHERE p.oid = 'public.retirer_sourate_validee(uuid,integer,text)'::pg_catalog.regprocedure),
  'droits : table fermee, retrait par la RPC seule, rien pour anon ni agent_ro');

\o
ROLLBACK;
