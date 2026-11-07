-- REMPLACEMENT-TEMPS-REEL : amorce de la pile LOCALE (donnees de test). Un titulaire
-- (homme, arabe), une collegue (femme, francais), une classe de femmes en arabe.
-- Idempotente. Lue par tool/e2e/remplacement_temps_reel.mjs.
INSERT INTO auth.users (id, email) VALUES ('7e5e0000-0000-4000-8000-000000000001','e2e-rt-t@example.com'),('7e5e0000-0000-4000-8000-000000000002','e2e-rt-r@example.com') ON CONFLICT DO NOTHING;
INSERT INTO public.profiles (id, immutable_id, role, household_id, first_name, last_name, account_status, gender) VALUES
 ('7e5e0000-0000-4000-8000-000000000001','E2E-RT-T','teacher',NULL,'Titulaire','Essai','provisional_active','male'),
 ('7e5e0000-0000-4000-8000-000000000002','E2E-RT-R','teacher',NULL,'Collegue','Essai','provisional_active','female') ON CONFLICT DO NOTHING;
INSERT INTO public.teacher_profiles (profile_id, kyc_status, languages) VALUES
 ('7e5e0000-0000-4000-8000-000000000001','approved','{ar}'),('7e5e0000-0000-4000-8000-000000000002','approved','{fr}') ON CONFLICT DO NOTHING;
DO $c$
DECLARE v record; v_nda text; v_notice text;
BEGIN
  SELECT version INTO v_nda FROM public.contract_texts WHERE contract_kind = 'teacher_nda' AND locale = 'fr' AND is_current;
  SELECT version INTO v_notice FROM public.contract_required_versions WHERE contract_kind = 'recording_and_control_notice';
  FOR v IN SELECT id FROM public.profiles WHERE immutable_id LIKE 'E2E-RT-%' AND account_status <> 'active' LOOP
    PERFORM set_config('request.jwt.claim.sub', v.id::text, true);
    PERFORM set_config('request.jwt.claims', '{"app_metadata":{"role":"teacher"},"sub":"' || v.id || '"}', true);
    PERFORM public.signer_contrat(v_nda, 'Essai remplacement');
    INSERT INTO public.contract_acceptances (profile_id, contract_kind, version) VALUES (v.id, 'recording_and_control_notice', v_notice) ON CONFLICT DO NOTHING;
    INSERT INTO public.contract_acceptances (profile_id, contract_kind, version) VALUES (v.id, 'teacher_conduct_code', public.code_conduite_version_requise()) ON CONFLICT DO NOTHING;
    UPDATE public.profiles SET account_status = 'active' WHERE id = v.id;
  END LOOP;
  PERFORM set_config('request.jwt.claim.sub', '', true); PERFORM set_config('request.jwt.claims', '', true);
END $c$;
INSERT INTO public.groupes (id, teacher_id, type_public, seuil_max, libelle, weekday, hour_local, timezone_iana, genre_public, langue_code)
VALUES ('7e5e0000-0000-4000-8000-000000000101','7e5e0000-0000-4000-8000-000000000001','adulte',6,'Essai remplacement',1,18,'Europe/Paris','femmes','ar') ON CONFLICT DO NOTHING;
