-- WHATSAPP-FAMILLE (directeur, 23/11/2026) : le numero WhatsApp de la famille.
--   1. inscrire_titulaire range le numero (candidature_contacts.telephone) ; absent : la demande part quand meme ;
--      mal forme : refuse (22023), aucun profil cree ;
--   2. la famille lit et corrige son numero (mon_whatsapp, definir_mon_whatsapp) ; un compte sans demande : possible = faux ;
--   3. la direction lit le numero par la demande ou par le profil, un autre rôle est refuse, anon n'a rien ;
--   4. l'ancienne forme (neuf arguments) n'est plus appelable par un client, la nouvelle sert les anciens appels.
-- Rejoue sur une base neuve, apres stub_auth.sql et toutes les migrations. Tout est annule a la fin.
-- Un echec leve 'WHATSAPP ROUGE : ...'.
BEGIN;

ALTER TABLE auth.users ADD COLUMN IF NOT EXISTS raw_app_meta_data jsonb NOT NULL DEFAULT '{}'::jsonb;
ALTER TABLE auth.users ADD COLUMN IF NOT EXISTS created_at timestamptz NOT NULL DEFAULT now();

CREATE FUNCTION pg_temp.vrai(p_condition boolean, p_label text) RETURNS void
LANGUAGE plpgsql AS $$
BEGIN
  IF p_condition IS NOT TRUE THEN
    RAISE EXCEPTION 'WHATSAPP ROUGE : %', p_label;
  END IF;
  RAISE NOTICE 'OK %', p_label;
END $$;
CREATE FUNCTION pg_temp.en_tant_que(p_qui text, p_role text) RETURNS void
LANGUAGE plpgsql AS $$
DECLARE v_jwt text := pg_catalog.json_build_object('app_metadata',
  pg_catalog.json_build_object('role', p_role))::text;
BEGIN
  PERFORM set_config('request.jwt.claim.sub', p_qui, true);
  PERFORM set_config('test.uid', p_qui, true);
  PERFORM set_config('request.jwt.claims', v_jwt, true);
  PERFORM set_config('test.jwt', v_jwt, true);
END $$;
CREATE FUNCTION pg_temp.refus(p_sql text) RETURNS text
LANGUAGE plpgsql AS $$
BEGIN
  EXECUTE p_sql;
  RETURN NULL;
EXCEPTION WHEN OTHERS THEN
  RETURN SQLSTATE || ' ' || SQLERRM;
END $$;
GRANT EXECUTE ON FUNCTION pg_temp.vrai(boolean, text), pg_temp.en_tant_que(text, text),
  pg_temp.refus(text) TO authenticated, anon;

INSERT INTO auth.users (id, email) VALUES
  ('ab000000-0000-4000-8000-000000000001', 'wa-direction@example.test'),
  ('ab000000-0000-4000-8000-000000000002', 'wa-avec@example.test'),
  ('ab000000-0000-4000-8000-000000000003', 'wa-sans@example.test'),
  ('ab000000-0000-4000-8000-000000000004', 'wa-mauvais@example.test'),
  ('ab000000-0000-4000-8000-000000000005', 'wa-autre@example.test'),
  ('ab000000-0000-4000-8000-000000000006', 'wa-sans-demande@example.test');
INSERT INTO public.households (id, timezone) VALUES ('ab000000-0000-4000-8000-0000000000f6', 'Europe/Paris');
INSERT INTO public.profiles
  (id, immutable_id, role, household_id, first_name, last_name, account_status, gender, access_until)
VALUES
  ('ab000000-0000-4000-8000-000000000001', 'WHATSAPPADMIN001', 'admin', NULL,
   'Fixture', 'Direction', 'active', 'male', NULL),
  ('ab000000-0000-4000-8000-000000000006', 'WHATSAPPSANS0001', 'guardian', 'ab000000-0000-4000-8000-0000000000f6',
   'Fixture', 'SansDemande', 'active', 'female', NULL);

-- 1. L'inscription range le numero.
SELECT pg_temp.en_tant_que('ab000000-0000-4000-8000-000000000002', 'guardian');
SET LOCAL ROLE authenticated;
SELECT public.inscrire_titulaire('famille', 'Fixture', 'Avec', 'female', 'Europe/Paris', false,
  '[{"prenom": "Enfant", "age": 9, "genre": "female", "niveau": "debut_lettres",
     "objectif": "apprendre_a_lire", "moments": ["soir"], "langue": "francais"}]'::jsonb,
  NULL, 'fr', '+33 6 12 34 56 78');
RESET ROLE;
SELECT pg_temp.en_tant_que('ab000000-0000-4000-8000-000000000003', 'guardian');
SET LOCAL ROLE authenticated;
SELECT public.inscrire_titulaire('famille', 'Fixture', 'Sans', 'female', 'Europe/Paris', false,
  '[{"prenom": "Enfant", "age": 9, "genre": "female", "niveau": "debut_lettres",
     "objectif": "apprendre_a_lire", "moments": ["soir"], "langue": "francais"}]'::jsonb);
RESET ROLE;
SELECT pg_temp.en_tant_que('ab000000-0000-4000-8000-000000000004', 'guardian');
SET LOCAL ROLE authenticated;
SELECT pg_temp.vrai(
  pg_temp.refus($q$SELECT public.inscrire_titulaire('famille', 'Fixture', 'Mauvais', 'female', 'Europe/Paris', false,
    '[{"prenom": "Enfant", "age": 9, "genre": "female", "niveau": "debut_lettres",
       "objectif": "apprendre_a_lire", "moments": ["soir"], "langue": "francais"}]'::jsonb,
    NULL, 'fr', '0612')$q$) LIKE '22023%',
  '1. un numero mal forme est refuse (22023)');
RESET ROLE;

SELECT pg_temp.vrai(
  (SELECT k.telephone FROM public.candidature_contacts k JOIN public.candidatures c ON c.id = k.candidature_id
    WHERE c.profile_id = 'ab000000-0000-4000-8000-000000000002') = '+33612345678'
  AND (SELECT k.telephone_brut FROM public.candidature_contacts k JOIN public.candidatures c ON c.id = k.candidature_id
    WHERE c.profile_id = 'ab000000-0000-4000-8000-000000000002') IS NULL,
  '1. le numero est range au format E.164, espaces retires');
SELECT pg_temp.vrai(
  EXISTS (SELECT 1 FROM public.candidatures WHERE profile_id = 'ab000000-0000-4000-8000-000000000003')
  AND NOT EXISTS (SELECT 1 FROM public.candidature_contacts k JOIN public.candidatures c ON c.id = k.candidature_id
    WHERE c.profile_id = 'ab000000-0000-4000-8000-000000000003'),
  '1. sans numero (client d''avant), la demande part et rien n''est invente');
SELECT pg_temp.vrai(
  NOT EXISTS (SELECT 1 FROM public.profiles WHERE id = 'ab000000-0000-4000-8000-000000000004'),
  '1. le refus n''a laisse aucun profil');

-- 2. La famille lit et corrige.
SELECT pg_temp.en_tant_que('ab000000-0000-4000-8000-000000000002', 'guardian');
SET LOCAL ROLE authenticated;
SELECT pg_temp.vrai((public.mon_whatsapp() ->> 'numero') = '+33612345678'
  AND (public.mon_whatsapp() ->> 'possible') = 'true', '2. la famille lit son numero');
SELECT public.definir_mon_whatsapp('+44 7700 900123');
SELECT pg_temp.vrai((public.mon_whatsapp() ->> 'numero') = '+447700900123', '2. la famille corrige son numero');
SELECT pg_temp.vrai(pg_temp.refus('SELECT public.definir_mon_whatsapp(''abc'')') LIKE '22023%',
  '2. un numero illisible est refuse');
SELECT pg_temp.vrai(pg_temp.refus('SELECT public.definir_mon_whatsapp('''')') LIKE '22023%',
  '2. un numero vide est refuse');
RESET ROLE;
SELECT pg_temp.en_tant_que('ab000000-0000-4000-8000-000000000003', 'guardian');
SET LOCAL ROLE authenticated;
SELECT pg_temp.vrai((public.mon_whatsapp() ->> 'possible') = 'true' AND (public.mon_whatsapp() ->> 'numero') IS NULL,
  '2. une famille sans numero : possible, numero nul');
SELECT public.definir_mon_whatsapp('+212600000000');
SELECT pg_temp.vrai((public.mon_whatsapp() ->> 'numero') = '+212600000000', '2. un compte deja inscrit ajoute son numero');
RESET ROLE;
SELECT pg_temp.en_tant_que('ab000000-0000-4000-8000-000000000006', 'guardian');
SET LOCAL ROLE authenticated;
SELECT pg_temp.vrai((public.mon_whatsapp() ->> 'possible') = 'false', '2. un compte sans demande : possible = faux');
SELECT pg_temp.vrai(pg_temp.refus('SELECT public.definir_mon_whatsapp(''+33612345678'')') LIKE '42501%',
  '2. un compte sans demande ne peut rien ecrire');
RESET ROLE;

-- 3. La direction lit.
SELECT set_config('test.cand', (SELECT id::text FROM public.candidatures WHERE profile_id = 'ab000000-0000-4000-8000-000000000002'), true);
SELECT pg_temp.en_tant_que('ab000000-0000-4000-8000-000000000001', 'admin');
SET LOCAL ROLE authenticated;
SELECT pg_temp.vrai(
  public.whatsapp_famille_direction(current_setting('test.cand')::uuid, NULL) = '+447700900123',
  '3. la direction lit le numero par la demande');
SELECT pg_temp.vrai(
  public.whatsapp_famille_direction(NULL, 'ab000000-0000-4000-8000-000000000002') = '+447700900123',
  '3. la direction lit le numero par le profil du titulaire');
SELECT pg_temp.vrai(public.whatsapp_famille_direction(NULL, NULL) IS NULL, '3. sans cible : rien');
RESET ROLE;
SELECT pg_temp.vrai(
  EXISTS (SELECT 1 FROM public.audit_logs WHERE action = 'whatsapp_famille_lu'),
  '3. la lecture est journalisee');
SELECT pg_temp.en_tant_que('ab000000-0000-4000-8000-000000000002', 'guardian');
SET LOCAL ROLE authenticated;
SELECT pg_temp.vrai(
  pg_temp.refus('SELECT public.whatsapp_famille_direction(NULL, ''ab000000-0000-4000-8000-000000000002'')') LIKE '42501%',
  '3. une famille ne lit pas par la porte de la direction');
RESET ROLE;
SET LOCAL ROLE anon;
SELECT pg_temp.vrai(
  NOT has_function_privilege('anon', 'public.whatsapp_famille_direction(uuid,uuid)', 'execute')
  AND NOT has_function_privilege('anon', 'public.mon_whatsapp()', 'execute')
  AND NOT has_function_privilege('anon', 'public.definir_mon_whatsapp(text)', 'execute')
  AND NOT has_function_privilege('anon', 'public.inscrire_titulaire(text,text,text,public.gender,text,boolean,jsonb,text,text,text)', 'execute'),
  '3. anon n''a aucune de ces portes');
RESET ROLE;

-- 4. Une seule forme dans public ; l'ancienne est fermee.
SELECT pg_temp.vrai(
  (SELECT count(*) FROM pg_proc p JOIN pg_namespace n ON n.oid = p.pronamespace
    WHERE n.nspname = 'public' AND p.proname = 'inscrire_titulaire') = 1
  AND NOT has_function_privilege('authenticated',
    'private.inscrire_titulaire_avant_whatsapp(text,text,text,public.gender,text,boolean,jsonb,text,text)', 'execute'),
  '4. une seule forme publique, l''ancienne est fermee aux clients');

SELECT 'WHATSAPP VERT' AS resultat;
ROLLBACK;
