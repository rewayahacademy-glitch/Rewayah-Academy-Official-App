-- Verdict 1b : ma_capacite_eleve() (A81 / C-24) sur canon-fixes ea1a0da9.
BEGIN;
INSERT INTO auth.users (id,email) VALUES
 ('c2400000-0000-0000-0000-000000000001','adulte@example.test'),
 ('c2400000-0000-0000-0000-000000000002','tuteur@example.test'),
 ('c2400000-0000-0000-0000-000000000003','suspendu@example.test'),
 ('c2400000-0000-0000-0000-000000000004','supprime@example.test'),
 ('c2400000-0000-0000-0000-000000000005','mineur@example.test');
INSERT INTO public.households (id,timezone,status) VALUES ('c2400000-0000-0000-0000-000000000101','Europe/Paris','active');
INSERT INTO public.profiles (id,immutable_id,role,household_id,first_name,last_name,account_status,gender) VALUES
 ('c2400000-0000-0000-0000-000000000001','C24-ADULTE','guardian','c2400000-0000-0000-0000-000000000101','A','A','active','female'),
 ('c2400000-0000-0000-0000-000000000002','C24-TUTEUR','guardian','c2400000-0000-0000-0000-000000000101','B','B','active','male'),
 ('c2400000-0000-0000-0000-000000000003','C24-SUSP','guardian','c2400000-0000-0000-0000-000000000101','C','C','disabled','male'),
 ('c2400000-0000-0000-0000-000000000004','C24-SUPPR','guardian','c2400000-0000-0000-0000-000000000101','D','D','active','male'),
 ('c2400000-0000-0000-0000-000000000005','C24-MINEUR','student','c2400000-0000-0000-0000-000000000101','E','E','active','male');
INSERT INTO public.student_profiles (profile_id,student_type,titulaire_profile_id,deleted_at) VALUES
 ('c2400000-0000-0000-0000-000000000001','autonomous','c2400000-0000-0000-0000-000000000001',NULL),
 ('c2400000-0000-0000-0000-000000000003','autonomous','c2400000-0000-0000-0000-000000000003',NULL),
 ('c2400000-0000-0000-0000-000000000004','autonomous','c2400000-0000-0000-0000-000000000004',now()),
 ('c2400000-0000-0000-0000-000000000005','minor',NULL,NULL);
CREATE TEMP TABLE res(who text, r boolean);
GRANT ALL ON res TO authenticated, anon;
DO $t$
DECLARE u text; exp boolean; v boolean; r record;
BEGIN
 FOR r IN SELECT * FROM (VALUES
   ('c2400000-0000-0000-0000-000000000001','guardian',true),
   ('c2400000-0000-0000-0000-000000000002','guardian',false),
   ('c2400000-0000-0000-0000-000000000003','guardian',false),
   ('c2400000-0000-0000-0000-000000000004','guardian',false),
   ('c2400000-0000-0000-0000-000000000005','student',false)) x(u,role,exp) LOOP
   PERFORM set_config('request.jwt.claim.sub', r.u, true);
   PERFORM set_config('request.jwt.claims', json_build_object('app_metadata', json_build_object('role', r.role))::text, true);
   SET LOCAL ROLE authenticated;
   v := public.ma_capacite_eleve();
   RESET ROLE;
   IF v IS DISTINCT FROM r.exp THEN RAISE EXCEPTION 'ma_capacite_eleve % attendu % obtenu %', r.u, r.exp, v; END IF;
 END LOOP;
 -- anon : refuse
 BEGIN
   SET LOCAL ROLE anon; PERFORM public.ma_capacite_eleve(); RESET ROLE;
   RAISE EXCEPTION 'anon a pu appeler ma_capacite_eleve';
 EXCEPTION WHEN insufficient_privilege THEN RESET ROLE; END;
 -- sans sub : false (jamais d erreur ouverte)
 PERFORM set_config('request.jwt.claim.sub','',true);
 PERFORM set_config('request.jwt.claims','',true);
 SET LOCAL ROLE authenticated;
 v := public.ma_capacite_eleve();
 RESET ROLE;
 IF v IS DISTINCT FROM false THEN RAISE EXCEPTION 'sans sub doit etre false, obtenu %', v; END IF;
 RAISE NOTICE 'ma_capacite_eleve : 5 profils, anon refuse, sans sub false : OK';
END $t$;
ROLLBACK;
