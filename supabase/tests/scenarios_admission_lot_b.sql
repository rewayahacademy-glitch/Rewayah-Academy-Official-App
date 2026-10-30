-- ADMISSION lot B (decision du 27/10/2026) : une famille et un eleve adulte
-- naissent en attente avec leur demande ; l'e-mail « demande recue » est en
-- file ; la file des enseignants ne montre pas les familles.
-- Rejoue sur une base neuve, apres stub_auth.sql et toutes les migrations.
-- Fixtures sans donnee personnelle ; tout est annule a la fin. Un echec leve
-- 'ADM-B ROUGE : ...'.
BEGIN;

ALTER TABLE auth.users ADD COLUMN IF NOT EXISTS raw_app_meta_data jsonb NOT NULL DEFAULT '{}'::jsonb;
ALTER TABLE auth.users ADD COLUMN IF NOT EXISTS created_at timestamptz NOT NULL DEFAULT now();

INSERT INTO auth.users (id, email) VALUES
  ('ab000000-0000-4000-8000-000000000001', 'adm-b-famille@example.test'),
  ('ab000000-0000-4000-8000-000000000002', 'adm-b-adulte@example.test'),
  ('ab000000-0000-4000-8000-000000000003', 'adm-b-sansgenre@example.test');

-- Une famille s'inscrit.
SELECT set_config('request.jwt.claim.sub', 'ab000000-0000-4000-8000-000000000001', true);
SELECT set_config('test.uid', 'ab000000-0000-4000-8000-000000000001', true);
SELECT set_config('request.jwt.claims', '{}', true);
SELECT set_config('test.jwt', '{}', true);
SET LOCAL ROLE authenticated;
SELECT public.inscrire_titulaire('famille', 'Fixture', 'Famille', 'female', 'Europe/Paris', false);
RESET ROLE;

-- Un eleve adulte s'inscrit (« Moi »).
SELECT set_config('request.jwt.claim.sub', 'ab000000-0000-4000-8000-000000000002', true);
SELECT set_config('test.uid', 'ab000000-0000-4000-8000-000000000002', true);
SET LOCAL ROLE authenticated;
SELECT public.inscrire_titulaire('moi', 'Fixture', 'Adulte', 'male', 'Europe/Paris', false);
RESET ROLE;

DO $controles$
DECLARE
  v_n integer;
BEGIN
  IF (SELECT p.account_status FROM public.profiles p
       WHERE p.id = 'ab000000-0000-4000-8000-000000000001') <> 'pending_kyc' THEN
    RAISE EXCEPTION 'ADM-B ROUGE : la famille ne nait pas en attente';
  END IF;
  IF (SELECT p.account_status FROM public.profiles p
       WHERE p.id = 'ab000000-0000-4000-8000-000000000002') <> 'pending_kyc' THEN
    RAISE EXCEPTION 'ADM-B ROUGE : l''eleve adulte ne nait pas en attente';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM public.candidatures c
                  WHERE c.profile_id = 'ab000000-0000-4000-8000-000000000001'
                    AND c.type_code = 'famille' AND c.etape = 'recue'
                    AND c.issue = 'en_cours' AND c.source = 'lien_public'
                    AND c.genre = 'female') THEN
    RAISE EXCEPTION 'ADM-B ROUGE : la demande de la famille manque';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM public.candidatures c
                  WHERE c.profile_id = 'ab000000-0000-4000-8000-000000000002'
                    AND c.type_code = 'eleve_adulte' AND c.etape = 'recue') THEN
    RAISE EXCEPTION 'ADM-B ROUGE : la demande de l''eleve adulte manque ou n''a pas son type';
  END IF;
  SELECT count(*) INTO v_n FROM public.courriels_sortants s
   WHERE s.modele = 'admission_recue' AND s.categorie = 'inscription'
     AND s.destinataire_profil IN ('ab000000-0000-4000-8000-000000000001',
                                   'ab000000-0000-4000-8000-000000000002');
  IF v_n <> 2 THEN
    RAISE EXCEPTION 'ADM-B ROUGE : % e-mail(s) « demande recue » en file, 2 attendus', v_n;
  END IF;
  -- Un compte en attente avec sa demande ne s'active pas avant la decision.
  BEGIN
    UPDATE public.profiles SET account_status = 'active'
     WHERE id = 'ab000000-0000-4000-8000-000000000001';
    RAISE EXCEPTION 'ADM-B ROUGE : la famille a pu etre activee sans decision';
  EXCEPTION WHEN check_violation THEN
    NULL;
  END;
  RAISE NOTICE 'ADM-B OK : famille et eleve adulte en attente, demandes recues, e-mails en file, activation refusee';
END
$controles$;

-- Sans genre, l'inscription est refusee (la demande en exige un).
SELECT set_config('request.jwt.claim.sub', 'ab000000-0000-4000-8000-000000000003', true);
SELECT set_config('test.uid', 'ab000000-0000-4000-8000-000000000003', true);
DO $sans_genre$
BEGIN
  PERFORM public.inscrire_titulaire('famille', 'Fixture', 'SansGenre', NULL, 'Europe/Paris', false);
  RAISE EXCEPTION 'ADM-B ROUGE : inscription sans genre acceptee';
EXCEPTION WHEN invalid_parameter_value THEN
  RAISE NOTICE 'ADM-B OK : sans genre, refus net';
END
$sans_genre$;

-- La file des candidatures (sans type demande) ne montre pas les familles.
DO $file$
DECLARE
  v_def text := pg_catalog.pg_get_functiondef(
    'public.lister_candidatures(jsonb,text,integer)'::pg_catalog.regprocedure);
BEGIN
  IF pg_catalog.strpos(v_def, 'c.type_code NOT IN (''famille'', ''eleve_adulte'')') = 0 THEN
    RAISE EXCEPTION 'ADM-B ROUGE : lister_candidatures montre les demandes d''admission sans type demande';
  END IF;
  RAISE NOTICE 'ADM-B OK : la file sans type ne montre pas les demandes d''admission';
END
$file$;

ROLLBACK;
