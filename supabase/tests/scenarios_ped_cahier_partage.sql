-- PED-APRES-BACK (18/10/2026) : la famille ne lit que ce que la direction a
-- laisse partager pour sa classe.
-- Attendu ecrit avant la migration 20261018190000 :
--   * partage actif (defaut) : la famille de la classe lit le compte rendu publie ;
--   * une famille d'une autre classe ne lit rien, ni par RPC ni par la table ;
--   * partage coupe : tout est masque tout de suite (RPC, table, progression) ;
--   * la reactivation ne rend pas lisible un compte rendu publie pendant la coupure ;
--   * exception d'un eleve, publication et revocation ciblees par la direction ;
--   * un brouillon (non publie) n'est jamais lisible ;
--   * la projection ne porte jamais la note interne du cahier ;
--   * seule la direction active ecrit les reglages ; rejeu idempotent ; conflit 40001.
-- Se rejoue sur une base neuve (stub_auth.sql, migrations) : il insere ses fixtures.
BEGIN;

INSERT INTO auth.users (id, email) VALUES
  ('e5100000-0000-0000-0000-000000000001', 'pcp-admin@example.test'),
  ('e5100000-0000-0000-0000-000000000002', 'pcp-teacher@example.test'),
  ('e5100000-0000-0000-0000-000000000003', 'pcp-guardian-a@example.test'),
  ('e5100000-0000-0000-0000-000000000004', 'pcp-student-a1@example.test'),
  ('e5100000-0000-0000-0000-000000000005', 'pcp-student-a2@example.test'),
  ('e5100000-0000-0000-0000-000000000006', 'pcp-student-a3@example.test'),
  ('e5100000-0000-0000-0000-000000000007', 'pcp-guardian-a2@example.test'),
  ('e5100000-0000-0000-0000-000000000008', 'pcp-guardian-b@example.test'),
  ('e5100000-0000-0000-0000-000000000009', 'pcp-student-b@example.test'),
  ('e5100000-0000-0000-0000-00000000000a', 'pcp-teacher-b@example.test'),
  ('e5100000-0000-0000-0000-00000000000b', 'pcp-disabled-admin@example.test');

INSERT INTO public.households (id, timezone, status) VALUES
  ('e5100000-0000-0000-0000-000000000101', 'Europe/Paris', 'active'),
  ('e5100000-0000-0000-0000-000000000102', 'Europe/Paris', 'active'),
  ('e5100000-0000-0000-0000-000000000103', 'Europe/Paris', 'active');

INSERT INTO public.profiles
  (id, immutable_id, role, household_id, first_name, last_name, account_status, gender)
VALUES
  ('e5100000-0000-0000-0000-000000000001', 'PCP-ADMIN', 'admin', NULL, 'Direction', 'Test', 'active'::public.account_status, 'female'),
  ('e5100000-0000-0000-0000-000000000002', 'PCP-TEACHER', 'teacher', NULL, 'Enseignant', 'A', 'provisional_active'::public.account_status, 'male'),
  ('e5100000-0000-0000-0000-000000000003', 'PCP-GUARDIAN-A', 'guardian', 'e5100000-0000-0000-0000-000000000101', 'Parent', 'A', 'active'::public.account_status, 'female'),
  ('e5100000-0000-0000-0000-000000000004', 'PCP-STUDENT-A1', 'student', 'e5100000-0000-0000-0000-000000000101', 'Aya', 'A', 'active'::public.account_status, 'female'),
  ('e5100000-0000-0000-0000-000000000005', 'PCP-STUDENT-A2', 'student', 'e5100000-0000-0000-0000-000000000102', 'Bilal', 'A', 'active'::public.account_status, 'male'),
  ('e5100000-0000-0000-0000-000000000006', 'PCP-STUDENT-A3', 'student', 'e5100000-0000-0000-0000-000000000101', 'Cherif', 'A', 'active'::public.account_status, 'male'),
  ('e5100000-0000-0000-0000-000000000007', 'PCP-GUARDIAN-A2', 'guardian', 'e5100000-0000-0000-0000-000000000102', 'Parent', 'A2', 'active'::public.account_status, 'male'),
  ('e5100000-0000-0000-0000-000000000008', 'PCP-GUARDIAN-B', 'guardian', 'e5100000-0000-0000-0000-000000000103', 'Parent', 'B', 'active'::public.account_status, 'female'),
  ('e5100000-0000-0000-0000-000000000009', 'PCP-STUDENT-B', 'student', 'e5100000-0000-0000-0000-000000000103', 'Dina', 'B', 'active'::public.account_status, 'female'),
  ('e5100000-0000-0000-0000-00000000000a', 'PCP-TEACHER-B', 'teacher', NULL, 'Enseignant', 'B', 'provisional_active'::public.account_status, 'female'),
  ('e5100000-0000-0000-0000-00000000000b', 'PCP-DISABLED', 'admin', NULL, 'Direction', 'Desactivee', 'disabled'::public.account_status, 'male');

UPDATE public.households SET primary_guardian_id = 'e5100000-0000-0000-0000-000000000003'
 WHERE id = 'e5100000-0000-0000-0000-000000000101';
UPDATE public.households SET primary_guardian_id = 'e5100000-0000-0000-0000-000000000007'
 WHERE id = 'e5100000-0000-0000-0000-000000000102';
UPDATE public.households SET primary_guardian_id = 'e5100000-0000-0000-0000-000000000008'
 WHERE id = 'e5100000-0000-0000-0000-000000000103';

INSERT INTO public.student_profiles (profile_id, student_type, level) VALUES
  ('e5100000-0000-0000-0000-000000000004', 'minor', 'lecture_lente'),
  ('e5100000-0000-0000-0000-000000000005', 'minor', 'lecture_lente'),
  ('e5100000-0000-0000-0000-000000000006', 'minor', 'lecture_lente'),
  ('e5100000-0000-0000-0000-000000000009', 'minor', 'lecture_lente');
INSERT INTO public.teacher_profiles (profile_id, country) VALUES
  ('e5100000-0000-0000-0000-000000000002', 'FR'),
  ('e5100000-0000-0000-0000-00000000000a', 'SA');

INSERT INTO public.groupes
  (id, teacher_id, type_public, seuil_max, libelle, weekday, hour_local, timezone_iana)
VALUES
  ('e5100000-0000-0000-0000-000000000201', 'e5100000-0000-0000-0000-000000000002',
   'enfant', 5, 'PCP classe A', 1, 18, 'Europe/Paris'),
  ('e5100000-0000-0000-0000-000000000202', 'e5100000-0000-0000-0000-00000000000a',
   'enfant', 5, 'PCP classe B', 2, 18, 'Europe/Paris');
INSERT INTO public.groupe_membres (groupe_id, student_id, joined_at) VALUES
  ('e5100000-0000-0000-0000-000000000201', 'e5100000-0000-0000-0000-000000000004', now() - interval '3 hours'),
  ('e5100000-0000-0000-0000-000000000201', 'e5100000-0000-0000-0000-000000000005', now() - interval '3 hours'),
  ('e5100000-0000-0000-0000-000000000201', 'e5100000-0000-0000-0000-000000000006', now() - interval '3 hours'),
  ('e5100000-0000-0000-0000-000000000202', 'e5100000-0000-0000-0000-000000000009', now() - interval '3 hours');

INSERT INTO public.sessions
  (id, teacher_id, started_at, ended_at, status, session_type,
   credit_amount_minor, currency, prayer_pause_minutes, groupe_id)
VALUES
  ('e5100000-0000-0000-0000-000000000301', 'e5100000-0000-0000-0000-000000000002',
   now() - interval '2 hours', now() - interval '1 hour',
   'ended'::public.session_status, 'standard', 0, 'EUR', 0,
   'e5100000-0000-0000-0000-000000000201'),
  ('e5100000-0000-0000-0000-000000000302', 'e5100000-0000-0000-0000-00000000000a',
   now() - interval '2 hours', now() - interval '1 hour',
   'ended'::public.session_status, 'standard', 0, 'EUR', 0,
   'e5100000-0000-0000-0000-000000000202');

INSERT INTO public.lesson_reports (session_id, idempotency_key, author_profile_id, content) VALUES
  ('e5100000-0000-0000-0000-000000000301', 'pcp-cahier-a',
   'e5100000-0000-0000-0000-000000000002',
   '{"version":1,"note_groupe":"note de groupe interne","eleves":[
     {"student_id":"e5100000-0000-0000-0000-000000000004","confirme":true,"performance":"enProgres","faiblesses":["makharij","inconnue"],"travail_maison":"Relire la page 3\nApprendre Al-Fatiha","motif_exception":"secret interne A1"},
     {"student_id":"e5100000-0000-0000-0000-000000000005","confirme":true,"performance":"acquis","motif_exception":"secret interne A2"},
     {"student_id":"e5100000-0000-0000-0000-000000000006","confirme":true,"performance":"maitrise","motif_exception":"secret interne A3"}]}'),
  ('e5100000-0000-0000-0000-000000000302', 'pcp-cahier-b',
   'e5100000-0000-0000-0000-00000000000a',
   '{"version":1,"eleves":[{"student_id":"e5100000-0000-0000-0000-000000000009","confirme":true,"performance":"acquis"}]}');

CREATE FUNCTION pg_temp.agir(p_uid uuid, p_role text, p_foyer uuid DEFAULT NULL)
RETURNS void LANGUAGE sql AS $$
  SELECT set_config('request.jwt.claim.sub', p_uid::text, true),
         set_config('request.jwt.claims', jsonb_build_object('app_metadata',
           jsonb_strip_nulls(jsonb_build_object('role', p_role, 'household_id', p_foyer)))::text, true);
$$;

-- Lecture de la table sous le role de la famille (RLS reelle).
CREATE FUNCTION pg_temp.lisibles_famille() RETURNS integer LANGUAGE plpgsql AS $$
DECLARE v_n integer;
BEGIN
  EXECUTE 'set local role authenticated';
  SELECT count(*) INTO v_n FROM public.seance_resumes;
  EXECUTE 'reset role';
  RETURN v_n;
END;
$$;

DO $scenario$
DECLARE
  c_admin constant uuid := 'e5100000-0000-0000-0000-000000000001';
  c_ens constant uuid := 'e5100000-0000-0000-0000-000000000002';
  c_tuteur_a constant uuid := 'e5100000-0000-0000-0000-000000000003';
  c_a1 constant uuid := 'e5100000-0000-0000-0000-000000000004';
  c_a2 constant uuid := 'e5100000-0000-0000-0000-000000000005';
  c_a3 constant uuid := 'e5100000-0000-0000-0000-000000000006';
  c_tuteur_a2 constant uuid := 'e5100000-0000-0000-0000-000000000007';
  c_tuteur_b constant uuid := 'e5100000-0000-0000-0000-000000000008';
  c_b constant uuid := 'e5100000-0000-0000-0000-000000000009';
  c_admin_off constant uuid := 'e5100000-0000-0000-0000-00000000000b';
  c_foyer_a constant uuid := 'e5100000-0000-0000-0000-000000000101';
  c_foyer_a2 constant uuid := 'e5100000-0000-0000-0000-000000000102';
  c_foyer_b constant uuid := 'e5100000-0000-0000-0000-000000000103';
  c_classe_a constant uuid := 'e5100000-0000-0000-0000-000000000201';
  c_classe_b constant uuid := 'e5100000-0000-0000-0000-000000000202';
  c_seance_a constant uuid := 'e5100000-0000-0000-0000-000000000301';
  c_seance_b constant uuid := 'e5100000-0000-0000-0000-000000000302';
  v jsonb;
  v2 jsonb;
  v_version text;
  v_refuse boolean;
BEGIN
  -- 1. Un brouillon n'est lisible par personne ------------------------------
  PERFORM pg_temp.agir(c_ens, 'teacher');
  PERFORM public.enregistrer_resume_seance(c_seance_a, c_a1,
    'Lecture reguliere, liaisons a revoir.', NULL, false);
  PERFORM pg_temp.agir(c_tuteur_a, 'guardian', c_foyer_a);
  v := public.compte_rendu_famille(c_seance_a, c_a1);
  IF v ->> 'etat' <> 'aucunChamp' OR v ? 'travaille' OR pg_temp.lisibles_famille() <> 0
     OR public.resume_seance_famille(c_seance_a, c_a1) IS NOT NULL THEN
    RAISE EXCEPTION 'PCP-1: un brouillon est lisible par la famille (%)', v;
  END IF;

  -- 2. Publication par l'enseignant, partage actif par defaut ---------------
  PERFORM pg_temp.agir(c_ens, 'teacher');
  PERFORM public.enregistrer_resume_seance(c_seance_a, c_a1,
    'Lecture reguliere, liaisons a revoir.', NULL, true);
  PERFORM public.enregistrer_resume_seance(c_seance_a, c_a2, 'Bonne seance.', NULL, true);
  PERFORM pg_temp.agir(c_tuteur_a, 'guardian', c_foyer_a);
  v := public.compte_rendu_famille(c_seance_a, c_a1);
  IF v ->> 'etat' <> 'partage'
     OR v ->> 'travaille' <> 'Lecture reguliere, liaisons a revoir.'
     OR v ->> 'appreciation' <> 'a_renforcer'
     OR v -> 'a_renforcer' <> '["makharij"]'::jsonb
     OR v -> 'a_preparer' <> '["Relire la page 3", "Apprendre Al-Fatiha"]'::jsonb THEN
    RAISE EXCEPTION 'PCP-2: projection familiale inattendue (%)', v;
  END IF;
  IF v::text LIKE '%secret interne%' OR v::text LIKE '%note de groupe%'
     OR v::text LIKE '%' || c_a2::text || '%' OR v::text LIKE '%paie%' THEN
    RAISE EXCEPTION 'PCP-2: la projection porte un champ interne (%)', v;
  END IF;
  IF pg_temp.lisibles_famille() <> 1 THEN
    RAISE EXCEPTION 'PCP-2: la famille A doit lire exactement 1 resume';
  END IF;

  -- 3. Une famille d'une autre classe ou d'un autre foyer ne lit rien -------
  PERFORM pg_temp.agir(c_tuteur_b, 'guardian', c_foyer_b);
  IF pg_temp.lisibles_famille() <> 0 THEN
    RAISE EXCEPTION 'PCP-3: une famille d''une autre classe lit une table de resumes';
  END IF;
  v_refuse := false;
  BEGIN
    PERFORM public.compte_rendu_famille(c_seance_a, c_a1);
  EXCEPTION WHEN insufficient_privilege THEN v_refuse := true; END;
  IF NOT v_refuse THEN RAISE EXCEPTION 'PCP-3: famille B autorisee sur l''eleve A1'; END IF;
  v_refuse := false;
  BEGIN
    PERFORM public.compte_rendu_famille(c_seance_a, c_b);
  EXCEPTION WHEN insufficient_privilege THEN v_refuse := true; END;
  IF NOT v_refuse THEN RAISE EXCEPTION 'PCP-3: seance A lue pour l''eleve B'; END IF;
  PERFORM pg_temp.agir(c_tuteur_a, 'guardian', c_foyer_a);
  v_refuse := false;
  BEGIN
    PERFORM public.compte_rendu_famille(c_seance_a, c_a2);
  EXCEPTION WHEN insufficient_privilege THEN v_refuse := true; END;
  IF NOT v_refuse THEN RAISE EXCEPTION 'PCP-3: la famille A lit l''eleve A2 d''un autre foyer'; END IF;
  PERFORM pg_temp.agir(c_tuteur_b, 'guardian', c_foyer_b);
  v := public.compte_rendu_famille(c_seance_b, c_b);
  IF v ->> 'etat' <> 'aucunChamp' THEN
    RAISE EXCEPTION 'PCP-3: classe B sans resume publie, attendu aucunChamp (%)', v;
  END IF;

  -- 4. Les roles qui ne sont pas la direction active n'ecrivent pas ---------
  FOR v_version IN SELECT unnest(ARRAY['teacher', 'guardian', 'accountant', 'controller', 'student']) LOOP
    PERFORM pg_temp.agir(c_ens, v_version, c_foyer_a);
    v_refuse := false;
    BEGIN
      PERFORM public.definir_partage_classe(c_classe_a, false, '1', 'pcp-refus-' || v_version);
    EXCEPTION WHEN insufficient_privilege THEN v_refuse := true; END;
    IF NOT v_refuse THEN RAISE EXCEPTION 'PCP-4: le role % ecrit le partage', v_version; END IF;
    v_refuse := false;
    BEGIN
      PERFORM public.partage_classe(c_classe_a, 1, NULL);
    EXCEPTION WHEN insufficient_privilege THEN v_refuse := true; END;
    IF NOT v_refuse THEN RAISE EXCEPTION 'PCP-4: le role % lit le reglage', v_version; END IF;
  END LOOP;
  PERFORM pg_temp.agir(c_admin_off, 'admin');
  v_refuse := false;
  BEGIN
    PERFORM public.definir_partage_classe(c_classe_a, false, '1', 'pcp-refus-off');
  EXCEPTION WHEN insufficient_privilege THEN v_refuse := true; END;
  IF NOT v_refuse THEN RAISE EXCEPTION 'PCP-4: une direction desactivee ecrit le partage'; END IF;

  -- 5. Reglage de classe : lecture, ecriture, rejeu, conflit ----------------
  PERFORM pg_temp.agir(c_admin, 'admin');
  v := public.partage_classe(c_classe_a, 1, NULL);
  IF NOT (v ->> 'actif')::boolean OR v ->> 'version' <> '1' OR (v ->> 'total')::integer <> 3 THEN
    RAISE EXCEPTION 'PCP-5: reglage initial inattendu (%)', v;
  END IF;
  v := public.partage_classe(c_classe_a, 1, 'bil');
  IF (v ->> 'total')::integer <> 1 OR v -> 'eleves' -> 0 ->> 'eleve_id' <> c_a2::text THEN
    RAISE EXCEPTION 'PCP-5: recherche cote serveur (%)', v;
  END IF;
  v := public.definir_partage_classe(c_classe_a, false, '1', 'pcp-coupe');
  IF (v ->> 'actif')::boolean OR v ->> 'version' <> '2' THEN
    RAISE EXCEPTION 'PCP-5: coupure non confirmee (%)', v;
  END IF;
  v2 := public.definir_partage_classe(c_classe_a, false, '1', 'pcp-coupe');
  IF v2 IS DISTINCT FROM v THEN RAISE EXCEPTION 'PCP-5: le rejeu n''est pas idempotent'; END IF;
  v_refuse := false;
  BEGIN
    PERFORM public.definir_partage_classe(c_classe_a, true, '1', 'pcp-perime');
  EXCEPTION WHEN SQLSTATE '40001' THEN v_refuse := true; END;
  IF NOT v_refuse THEN RAISE EXCEPTION 'PCP-5: une version perimee a ecrit'; END IF;
  v_refuse := false;
  BEGIN
    PERFORM public.definir_partage_classe(c_classe_a, true, '2', 'pcp-coupe');
  EXCEPTION WHEN unique_violation THEN v_refuse := true; END;
  IF NOT v_refuse THEN RAISE EXCEPTION 'PCP-5: cle d''idempotence reutilisee pour autre chose'; END IF;
  v_refuse := false;
  BEGIN
    PERFORM public.definir_regle_partage_eleve(c_classe_a, c_b, 'toujours', '2', 'pcp-hors-classe');
  EXCEPTION WHEN no_data_found THEN v_refuse := true; END;
  IF NOT v_refuse THEN RAISE EXCEPTION 'PCP-5: exception posee pour un eleve hors de la classe'; END IF;

  -- 6. Partage coupe : masque tout de suite, partout ------------------------
  PERFORM pg_temp.agir(c_tuteur_a, 'guardian', c_foyer_a);
  v := public.compte_rendu_famille(c_seance_a, c_a1);
  IF v ->> 'etat' <> 'nonPartage' OR v ? 'travaille'
     OR pg_temp.lisibles_famille() <> 0
     OR public.resume_seance_famille(c_seance_a, c_a1) IS NOT NULL
     OR jsonb_array_length(public.progression_famille(c_a1) -> 'seances') <> 0 THEN
    RAISE EXCEPTION 'PCP-6: un compte rendu reste lisible apres la coupure (%)', v;
  END IF;

  -- 7. Publie pendant la coupure : pas de retroactif a la reactivation ------
  PERFORM pg_temp.agir(c_ens, 'teacher');
  PERFORM public.enregistrer_resume_seance(c_seance_a, c_a3, 'Publie pendant la coupure.', NULL, true);
  IF (SELECT auto_partage FROM public.seance_resumes
       WHERE session_id = c_seance_a AND student_id = c_a3) THEN
    RAISE EXCEPTION 'PCP-7: auto_partage pose alors que le partage etait coupe';
  END IF;
  PERFORM pg_temp.agir(c_admin, 'admin');
  v := public.definir_partage_classe(c_classe_a, true, '2', 'pcp-reactive');
  IF NOT (v ->> 'actif')::boolean OR v ->> 'version' <> '3' THEN
    RAISE EXCEPTION 'PCP-7: reactivation non confirmee (%)', v;
  END IF;
  PERFORM pg_temp.agir(c_tuteur_a, 'guardian', c_foyer_a);
  IF public.compte_rendu_famille(c_seance_a, c_a1) ->> 'etat' <> 'partage' THEN
    RAISE EXCEPTION 'PCP-7: A1, deja partage avant la coupure, doit redevenir lisible';
  END IF;
  IF public.compte_rendu_famille(c_seance_a, c_a3) ->> 'etat' <> 'nonPartage'
     OR pg_temp.lisibles_famille() <> 1 THEN
    RAISE EXCEPTION 'PCP-7: la reactivation a publie A3 retroactivement';
  END IF;

  -- 8. Publication manuelle puis revocation ciblee ---------------------------
  PERFORM pg_temp.agir(c_admin, 'admin');
  v := public.apercu_familial(c_seance_a, c_a3);
  IF v ->> 'etat' <> 'confirmeNonPartage' OR v::text LIKE '%secret interne%'
     OR v -> 'apercu' ->> 'travaille' <> 'Publie pendant la coupure.' THEN
    RAISE EXCEPTION 'PCP-8: apercu de A3 inattendu (%)', v;
  END IF;
  v2 := public.publier_resume_seance(c_seance_a, c_a3, v ->> 'version', 'pcp-publie-a3');
  IF v2 ->> 'etat' <> 'partageManuel' THEN
    RAISE EXCEPTION 'PCP-8: publication manuelle (%)', v2;
  END IF;
  PERFORM pg_temp.agir(c_tuteur_a, 'guardian', c_foyer_a);
  IF public.compte_rendu_famille(c_seance_a, c_a3) ->> 'etat' <> 'partage' THEN
    RAISE EXCEPTION 'PCP-8: la publication manuelle n''est pas lisible';
  END IF;
  PERFORM pg_temp.agir(c_admin, 'admin');
  v := public.apercu_familial(c_seance_a, c_a3);
  v2 := public.revoquer_resume_seance(c_seance_a, c_a3, v ->> 'version', 'pcp-revoque-a3');
  PERFORM pg_temp.agir(c_tuteur_a, 'guardian', c_foyer_a);
  IF public.compte_rendu_famille(c_seance_a, c_a3) ->> 'etat' <> 'nonPartage' THEN
    RAISE EXCEPTION 'PCP-8: la revocation ne masque pas A3';
  END IF;
  PERFORM pg_temp.agir(c_admin, 'admin');
  v := public.apercu_familial(c_seance_a, c_a3);
  IF v ->> 'etat' <> 'revoque' OR jsonb_array_length(v -> 'historique') < 2 THEN
    RAISE EXCEPTION 'PCP-8: etat ou historique de A3 inattendu (%)', v;
  END IF;

  -- 9. Exception d'un eleve --------------------------------------------------
  v := public.partage_classe(c_classe_a, 1, NULL);
  v := public.definir_regle_partage_eleve(c_classe_a, c_a1, 'jamais', v ->> 'version', 'pcp-a1-jamais');
  IF (SELECT e ->> 'visible' FROM jsonb_array_elements(v -> 'eleves') e
       WHERE e ->> 'eleve_id' = c_a1::text) <> 'false'
     OR (SELECT e ->> 'source' FROM jsonb_array_elements(v -> 'eleves') e
          WHERE e ->> 'eleve_id' = c_a1::text) <> 'exceptionEleve' THEN
    RAISE EXCEPTION 'PCP-9: exception non lue (%)', v;
  END IF;
  PERFORM pg_temp.agir(c_tuteur_a, 'guardian', c_foyer_a);
  IF public.compte_rendu_famille(c_seance_a, c_a1) ->> 'etat' <> 'nonPartage' THEN
    RAISE EXCEPTION 'PCP-9: A1 doit etre masque par son exception';
  END IF;
  PERFORM pg_temp.agir(c_admin, 'admin');
  v := public.partage_classe(c_classe_a, 1, NULL);
  v := public.definir_regle_partage_eleve(c_classe_a, c_a1, 'regleClasse', v ->> 'version', 'pcp-a1-classe');
  PERFORM pg_temp.agir(c_tuteur_a, 'guardian', c_foyer_a);
  IF public.compte_rendu_famille(c_seance_a, c_a1) ->> 'etat' <> 'partage' THEN
    RAISE EXCEPTION 'PCP-9: A1 doit suivre de nouveau la classe';
  END IF;

  -- 10. Listes de la direction ----------------------------------------------
  PERFORM pg_temp.agir(c_admin, 'admin');
  v := public.comptes_rendus_classe(c_classe_a, 1, NULL);
  IF (v ->> 'total')::integer <> 3 THEN RAISE EXCEPTION 'PCP-10: total de classe (%)', v; END IF;
  v := public.comptes_rendus_classe(c_classe_a, 1, 'revoque');
  IF (v ->> 'total')::integer <> 1 OR v -> 'lignes' -> 0 ->> 'eleve_id' <> c_a3::text THEN
    RAISE EXCEPTION 'PCP-10: filtre revoque (%)', v;
  END IF;
  v := public.comptes_rendus_eleve(c_classe_a, c_a2);
  IF jsonb_array_length(v -> 'lignes') <> 1 OR v -> 'lignes' -> 0 ->> 'etat' <> 'partageAuto' THEN
    RAISE EXCEPTION 'PCP-10: comptes rendus de A2 (%)', v;
  END IF;
  v := public.comptes_rendus_classe(c_classe_b, 1, NULL);
  IF v::text LIKE '%' || c_a1::text || '%' THEN
    RAISE EXCEPTION 'PCP-10: la classe B liste un eleve de la classe A';
  END IF;
  RAISE NOTICE 'OK PED-APRES-BACK : partage pedagogique (10 groupes de controles)';
END;
$scenario$;

ROLLBACK;
