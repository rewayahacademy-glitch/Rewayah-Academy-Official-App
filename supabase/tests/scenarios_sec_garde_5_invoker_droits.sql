-- SEC-GARDE-5 point c (11/11/2026), migration
-- 20261123400200_sec_garde_5_invoker_droits.sql. Rouge sans la migration,
-- vert avec :
--   1. cinq fonctions de declencheur sont INVOKER, guard_session_state_transition
--      reste DEFINER ;
--   2. les gardes tiennent toujours quand un client ecrit lui-meme :
--      immutable_id d'un profil, ajustements de priere, journal d'audit ;
--   3. service_role n'execute plus creer_profil_eleve_titulaire,
--      geler_archive_seance, autoriser_ecoute_archive ni
--      verdict_acces_dossier_kyc ; agent_ro garde etat_presence et lit
--      toujours presence_seance_v ; authenticated garde ses droits.
-- Tout est annule a la fin.
\o /dev/null
BEGIN;

CREATE FUNCTION pg_temp.vrai(p_condition boolean, p_label text) RETURNS void
LANGUAGE plpgsql AS $$
BEGIN
  IF p_condition IS NOT TRUE THEN
    RAISE EXCEPTION 'SEC-GARDE-5 c ROUGE : %', p_label;
  END IF;
  RAISE NOTICE 'ok : %', p_label;
END $$;

CREATE FUNCTION pg_temp.etre(p_id uuid, p_role text, p_foyer uuid) RETURNS void
LANGUAGE plpgsql AS $$
BEGIN
  PERFORM set_config('request.jwt.claim.sub', p_id::text, true);
  PERFORM set_config('request.jwt.claims',
    jsonb_build_object('sub', p_id, 'role', 'authenticated',
                       'app_metadata', jsonb_strip_nulls(jsonb_build_object(
                         'role', p_role, 'household_id', p_foyer)))::text, true);
END $$;

-- Rend 'ok' ou le message de l'erreur levee par la commande.
CREATE FUNCTION pg_temp.essai(p_sql text) RETURNS text
LANGUAGE plpgsql AS $$
BEGIN
  EXECUTE p_sql;
  RETURN 'ok';
EXCEPTION WHEN OTHERS THEN
  RETURN SQLERRM;
END $$;
GRANT EXECUTE ON FUNCTION pg_temp.essai(text) TO authenticated, agent_ro;

-- 1. INVOKER et DEFINER
SELECT pg_temp.vrai(
  (SELECT count(*) FROM pg_proc p
    WHERE p.oid IN ('public.guard_audit_logs_immutable()'::regprocedure,
                    'public.guard_contract_acceptances_immutable()'::regprocedure,
                    'public.guard_profile_immutable_id()'::regprocedure,
                    'public.guard_rule_override_immutable()'::regprocedure,
                    'public.guard_prayer_adjustments()'::regprocedure)
      AND NOT p.prosecdef) = 5,
  '1 : cinq fonctions de declencheur en INVOKER');
SELECT pg_temp.vrai(
  (SELECT prosecdef FROM pg_proc WHERE oid = 'public.guard_session_state_transition()'::regprocedure),
  '1 : guard_session_state_transition reste DEFINER');

-- Fixtures
SET LOCAL session_replication_role = replica;
INSERT INTO auth.users (id) VALUES ('5e5c0000-0000-0000-0000-000000000001'),
  ('5e5c0000-0000-0000-0000-000000000002'), ('5e5c0000-0000-0000-0000-000000000003');
INSERT INTO public.households (id, timezone) VALUES ('5e5c0000-0000-0000-0000-0000000000f1', 'Europe/Paris');
INSERT INTO public.profiles (id, immutable_id, role, household_id, first_name, last_name, account_status, gender) VALUES
  ('5e5c0000-0000-0000-0000-000000000001', 'SG5C-ENS', 'teacher', NULL, 'Ens', 'Un', 'active', 'male'),
  ('5e5c0000-0000-0000-0000-000000000002', 'SG5C-TUT', 'guardian', '5e5c0000-0000-0000-0000-0000000000f1', 'Tut', 'Un', 'active', 'male'),
  ('5e5c0000-0000-0000-0000-000000000003', 'SG5C-ELV', 'student', '5e5c0000-0000-0000-0000-0000000000f1', 'Elv', 'Un', 'active', 'male');
INSERT INTO public.sessions (id, teacher_id, started_at, ended_at) VALUES
  ('5e5c0000-0000-0000-0000-0000000000b1', '5e5c0000-0000-0000-0000-000000000001',
   now() - interval '2 hours', now() - interval '1 hour');
INSERT INTO public.session_participants (session_id, profile_id, role) VALUES
  ('5e5c0000-0000-0000-0000-0000000000b1', '5e5c0000-0000-0000-0000-000000000003', 'student');
SET LOCAL session_replication_role = origin;

-- 2. Les gardes tiennent quand un client ecrit lui-meme
SELECT pg_temp.etre('5e5c0000-0000-0000-0000-000000000002', 'guardian', '5e5c0000-0000-0000-0000-0000000000f1');
SET LOCAL ROLE authenticated;
SELECT pg_temp.vrai(
  pg_temp.essai($$UPDATE public.profiles SET immutable_id = 'SG5C-AUTRE'
                   WHERE id = '5e5c0000-0000-0000-0000-000000000002'$$) <> 'ok'
  AND (SELECT immutable_id FROM public.profiles WHERE id = '5e5c0000-0000-0000-0000-000000000002') = 'SG5C-TUT',
  '2 : un tuteur ne change toujours pas son immutable_id');
RESET ROLE;

-- PRIERE-1 (12/11/2026) : un client ne pose plus un lieu de priere lui-meme (la
-- direction passe par priere_lieu_definir). Le garde d'ajustement tient encore :
-- l'enseignant ajuste par priere_ajuster, dans les bornes seulement.
INSERT INTO public.prayer_settings (teacher_id, latitude, longitude, place_label)
  VALUES ('5e5c0000-0000-0000-0000-000000000001', 48.85, 2.35, 'Paris');
SELECT pg_temp.etre('5e5c0000-0000-0000-0000-000000000001', 'teacher', NULL);
SET LOCAL ROLE authenticated;
SELECT pg_temp.vrai(
  pg_temp.essai($$INSERT INTO public.prayer_settings (teacher_id, latitude, longitude, adjustments)
                   VALUES ('5e5c0000-0000-0000-0000-000000000001', 48.85, 2.35,
                           '{"fajr": 2, "dhuhr": 0, "asr": 0, "maghrib": 0, "isha": 0}'::jsonb)$$) <> 'ok',
  '2 : un enseignant ne pose plus un lieu de priere lui-meme (priere_lieu_definir est a la direction)');
SELECT pg_temp.vrai(
  pg_temp.essai($$SELECT public.priere_ajuster('fajr', 99)$$) LIKE '%de -30 a +30%',
  '2 : un enseignant ne pose toujours pas un ajustement de priere hors bornes');
SELECT pg_temp.vrai(
  pg_temp.essai($$SELECT public.priere_ajuster('fajr', 2)$$) = 'ok',
  '2 : un ajustement dans les bornes passe toujours');
RESET ROLE;

INSERT INTO public.audit_logs (action, table_name, payload, prev_hash, hash)
  VALUES ('sg5c_temoin', 'sg5c', '{}'::jsonb, '', 'sg5c');
SELECT pg_temp.vrai(
  pg_temp.essai($$UPDATE public.audit_logs SET action = 'modifie' WHERE action = 'sg5c_temoin'$$)
  LIKE '%append-only%',
  '2 : le journal d''audit reste en ajout seul');

-- 3. Droits
SELECT pg_temp.vrai(
  NOT has_function_privilege('service_role', 'public.creer_profil_eleve_titulaire()', 'EXECUTE')
  AND NOT has_function_privilege('service_role', 'public.geler_archive_seance(uuid,text,boolean)', 'EXECUTE')
  AND NOT has_function_privilege('service_role', 'public.autoriser_ecoute_archive(uuid)', 'EXECUTE')
  AND NOT has_function_privilege('service_role', 'public.verdict_acces_dossier_kyc(uuid)', 'EXECUTE'),
  '3 : service_role n''execute plus les quatre fonctions');
SELECT pg_temp.vrai(
  has_function_privilege('authenticated', 'public.creer_profil_eleve_titulaire()', 'EXECUTE')
  AND has_function_privilege('authenticated', 'public.geler_archive_seance(uuid,text,boolean)', 'EXECUTE')
  AND has_function_privilege('authenticated', 'public.autoriser_ecoute_archive(uuid)', 'EXECUTE')
  AND has_function_privilege('authenticated', 'public.verdict_acces_dossier_kyc(uuid)', 'EXECUTE'),
  '3 : authenticated garde ses droits');
SELECT pg_temp.vrai(
  has_function_privilege('agent_ro', 'public.etat_presence(uuid,uuid)', 'EXECUTE')
  AND has_function_privilege('service_role', 'public.etat_presence(uuid,uuid)', 'EXECUTE'),
  '3 : agent_ro garde etat_presence ; service_role sur etat_presence non touche');
SET LOCAL ROLE agent_ro;
SELECT pg_temp.vrai(
  pg_temp.essai($$SELECT etat FROM public.presence_seance_v$$) = 'ok',
  '3 : agent_ro lit toujours la colonne etat de presence_seance_v');
RESET ROLE;

\o
ROLLBACK;
