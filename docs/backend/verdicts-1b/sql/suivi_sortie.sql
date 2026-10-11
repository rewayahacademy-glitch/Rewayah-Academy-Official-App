BEGIN;
INSERT INTO auth.users (id,email) VALUES
 ('c1000000-0000-0000-0000-000000000001','g@example.test'),
 ('c1000000-0000-0000-0000-000000000002','e@example.test'),
 ('c1000000-0000-0000-0000-000000000003','g2@example.test');
INSERT INTO public.households (id,timezone,status) VALUES
 ('c1000000-0000-0000-0000-000000000101','America/New_York','active'),
 ('c1000000-0000-0000-0000-000000000102','Europe/Paris','active');
INSERT INTO public.profiles (id,immutable_id,role,household_id,first_name,last_name,account_status,gender) VALUES
 ('c1000000-0000-0000-0000-000000000001','C10-G','guardian','c1000000-0000-0000-0000-000000000101','Parent','A','active','female'),
 ('c1000000-0000-0000-0000-000000000002','C10-E','student','c1000000-0000-0000-0000-000000000101','Amine','A','active','male'),
 ('c1000000-0000-0000-0000-000000000003','C10-G2','guardian','c1000000-0000-0000-0000-000000000102','Autre','B','active','male');
UPDATE public.households SET primary_guardian_id='c1000000-0000-0000-0000-000000000001' WHERE id='c1000000-0000-0000-0000-000000000101';
UPDATE public.households SET primary_guardian_id='c1000000-0000-0000-0000-000000000003' WHERE id='c1000000-0000-0000-0000-000000000102';
INSERT INTO public.student_profiles (profile_id,student_type) VALUES ('c1000000-0000-0000-0000-000000000002','minor');
INSERT INTO public.demandes_horaires_famille (eleve_id,type_public,langue_code,fuseau_iana,jours,heures_locales,source,etat,motif)
 SELECT 'c1000000-0000-0000-0000-000000000002','enfant',(SELECT code FROM public.langues_cours LIMIT 1),'America/New_York','{2,4}'::smallint[],'{17,17}'::smallint[],'personnalisee','envoyee',NULL;
INSERT INTO public.demandes_horaires_famille (eleve_id,type_public,langue_code,fuseau_iana,jours,heures_locales,source,etat,motif)
 SELECT 'c1000000-0000-0000-0000-000000000002','enfant',(SELECT code FROM public.langues_cours LIMIT 1),'America/New_York','{6}'::smallint[],'{9}'::smallint[],'personnalisee','refusee','refus_direction';
SELECT set_config('request.jwt.claim.sub','c1000000-0000-0000-0000-000000000001',true);
SELECT set_config('request.jwt.claims','{"app_metadata":{"role":"guardian","household_id":"c1000000-0000-0000-0000-000000000101"}}',true);
SET LOCAL ROLE authenticated;
SELECT jsonb_pretty(coalesce(jsonb_agg(to_jsonb(r)),'[]')) FROM public.suivi_demandes_horaires_foyer() r;
SELECT set_config('request.jwt.claim.sub','c1000000-0000-0000-0000-000000000003',true);
SELECT set_config('request.jwt.claims','{"app_metadata":{"role":"guardian","household_id":"c1000000-0000-0000-0000-000000000102"}}',true);
SELECT count(*) AS autre_foyer FROM public.suivi_demandes_horaires_foyer();
ROLLBACK;
