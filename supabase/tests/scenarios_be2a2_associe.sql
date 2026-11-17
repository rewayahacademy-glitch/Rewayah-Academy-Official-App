-- BE-2a-2 (pilote, 16/11/2026) : le role `associe` et son invitation (migrations 20261129770000 et 20261129780000).
-- Cahier : docs/current/BUREAU-EQUIPE/CAHIER-BE-2A-2-ASSOCIE.md §3. Cas couverts :
--  i : l'invitation (direction active en aal2 seulement, idempotente par cle, revocable, un code ne sert qu'une fois,
--      lie a l'adresse de la session) ; c : le compte cree (role associe, actif, sans foyer, genre requis) ;
--  h : le crochet de jeton rend toujours l'evenement, jamais null, pour un associe ;
--  t : un associe SANS mission ne lit aucune ligne de personne : chaque table de `public` est essayee sous son jeton,
--      la liste des tables lisibles est EXPLICITE (exigence positive) ; la couverture (tables qui avaient des lignes
--      dans ce scenario) est dite en NOTICE : une table vide n'est pas une preuve ;
--  m : avec une mission « lire » sur les dossiers en anglais, il ne voit que ces dossiers ; la mission retiree, il ne
--      voit plus rien et son compte n'a pas change ; `controller` n'est plus admis par accorder_mission ;
--  d : anon n'a aucun droit sur les portes nouvelles ni sur la table.
-- Chaque controle leve 'ASSOCIE ROUGE : ...' s'il echoue. A rejouer sur une base NEUVE ; le scenario annule tout.
\o /dev/null
BEGIN;

CREATE FUNCTION pg_temp.qui(p_id uuid, p_role text, p_aal text DEFAULT 'aal2') RETURNS void
LANGUAGE plpgsql AS $$
DECLARE v_jwt text;
BEGIN
  v_jwt := CASE WHEN p_id IS NULL AND p_role IS NULL THEN '{}'
                ELSE pg_catalog.json_build_object(
                       'sub', p_id, 'role', 'authenticated', 'aal', p_aal,
                       'app_metadata', CASE WHEN p_role IS NULL THEN pg_catalog.json_build_object()
                                            ELSE pg_catalog.json_build_object('role', p_role) END)::text END;
  PERFORM pg_catalog.set_config('request.jwt.claim.sub', coalesce(p_id::text, ''), true);
  PERFORM pg_catalog.set_config('request.jwt.claims', v_jwt, true);
END $$;

CREATE FUNCTION pg_temp.vrai(p_condition boolean, p_label text) RETURNS void
LANGUAGE plpgsql AS $$
BEGIN
  IF p_condition IS NOT TRUE THEN
    RAISE EXCEPTION 'ASSOCIE ROUGE : %', p_label;
  END IF;
  PERFORM pg_catalog.set_config('test.n',
    (coalesce(nullif(pg_catalog.current_setting('test.n', true), ''), '0')::int + 1)::text, true);
  RAISE NOTICE 'OK %', p_label;
END $$;

CREATE FUNCTION pg_temp.garde(p_nom text, p_valeur jsonb) RETURNS void
LANGUAGE sql AS $$ SELECT pg_catalog.set_config('test.' || p_nom, coalesce(p_valeur::text, 'null'), true); $$;
CREATE FUNCTION pg_temp.lu(p_nom text) RETURNS jsonb
LANGUAGE sql AS $$ SELECT pg_catalog.current_setting('test.' || p_nom)::jsonb; $$;

CREATE FUNCTION pg_temp.en(p_id uuid, p_role text, p_sql text, p_aal text DEFAULT 'aal2') RETURNS jsonb
LANGUAGE plpgsql AS $$
DECLARE v jsonb;
BEGIN
  PERFORM pg_temp.qui(p_id, p_role, p_aal);
  EXECUTE 'SET LOCAL ROLE authenticated';
  EXECUTE p_sql INTO v;
  EXECUTE 'RESET ROLE';
  RETURN v;
END $$;

CREATE FUNCTION pg_temp.refus_en(p_id uuid, p_role text, p_sql text, p_code text, p_label text,
                                 p_aal text DEFAULT 'aal2', p_db_role text DEFAULT 'authenticated') RETURNS void
LANGUAGE plpgsql AS $$
DECLARE
  v_passe boolean := false;
  v_code text;
  v_msg text;
BEGIN
  PERFORM pg_temp.qui(p_id, p_role, p_aal);
  BEGIN
    EXECUTE pg_catalog.format('SET LOCAL ROLE %I', p_db_role);
    EXECUTE p_sql;
    v_passe := true;
    EXECUTE 'RESET ROLE';
  EXCEPTION WHEN OTHERS THEN
    v_code := SQLSTATE;
    v_msg := SQLERRM;
  END;
  EXECUTE 'RESET ROLE';
  IF v_passe THEN
    RAISE EXCEPTION 'ASSOCIE ROUGE : % (aucun refus)', p_label;
  END IF;
  IF v_code <> p_code THEN
    RAISE EXCEPTION 'ASSOCIE ROUGE : % (code % au lieu de % : %)', p_label, v_code, p_code, v_msg;
  END IF;
  PERFORM pg_catalog.set_config('test.n',
    (coalesce(nullif(pg_catalog.current_setting('test.n', true), ''), '0')::int + 1)::text, true);
  RAISE NOTICE 'OK %', p_label;
END $$;

CREATE FUNCTION pg_temp.u(p_n text) RETURNS uuid LANGUAGE sql IMMUTABLE AS $$
  SELECT ('5b2b0000-0000-4000-8000-0000000000' || CASE p_n WHEN 'a1' THEN '01' WHEN 't1' THEN '02' WHEN 'g1' THEN '03'
    WHEN 's1' THEN '04' WHEN 'x' THEN '11' WHEN 'y' THEN '12' WHEN 'c1' THEN '13' WHEN 'z' THEN '14' END)::uuid $$;
CREATE FUNCTION pg_temp.d(p_n text) RETURNS uuid LANGUAGE sql IMMUTABLE AS $$
  SELECT ('5b2bcccc-0000-4000-8000-0000000000' || CASE p_n WHEN 'E1' THEN '01' WHEN 'E2' THEN '02' END)::uuid $$;
GRANT EXECUTE ON FUNCTION pg_temp.qui(uuid, text, text), pg_temp.vrai(boolean, text), pg_temp.garde(text, jsonb),
  pg_temp.lu(text), pg_temp.en(uuid, text, text, text), pg_temp.refus_en(uuid, text, text, text, text, text, text),
  pg_temp.u(text), pg_temp.d(text) TO authenticated, anon;

-- ------------------------------------------------------------
-- Fixtures (donnees inventees) : a1 direction (homme) ; t1 enseignant ; g1 tuteur et s1 eleve (un foyer) ;
-- x, y : invites sans profil ; c1 : un compte controller (ecarte) ; E1 dossier en anglais, E2 en francais.
-- ------------------------------------------------------------
INSERT INTO auth.users (id, email) VALUES
  (pg_temp.u('a1'), 'be2a2-a1@test.invalid'), (pg_temp.u('t1'), 'be2a2-t1@test.invalid'),
  (pg_temp.u('g1'), 'be2a2-g1@test.invalid'), (pg_temp.u('s1'), 'be2a2-s1@test.invalid'),
  (pg_temp.u('x'), 'ami@invite.test'), (pg_temp.u('y'), 'refuse@invite.test'),
  (pg_temp.u('c1'), 'be2a2-c1@test.invalid'), (pg_temp.u('z'), 'intrus@invite.test');
INSERT INTO public.households (id, timezone) VALUES ('5b2bffff-ffff-4fff-8fff-000000000001', 'Europe/Paris');
INSERT INTO public.profiles (id, immutable_id, role, household_id, first_name, last_name, account_status, gender) VALUES
 (pg_temp.u('a1'), 'B2B-ADM-0001', 'admin', NULL, 'Direction', 'Homme', 'active', 'male'),
 (pg_temp.u('t1'), 'B2B-ENS-0001', 'teacher', NULL, 'Enseignant', 'Essai', 'pending_kyc', 'male'),
 (pg_temp.u('g1'), 'B2B-TUT-0001', 'guardian', '5b2bffff-ffff-4fff-8fff-000000000001', 'Tuteur', 'Essai', 'active', 'female'),
 (pg_temp.u('s1'), 'B2B-ELE-0001', 'student', '5b2bffff-ffff-4fff-8fff-000000000001', 'Eleve', 'Essai', 'active', 'male'),
 (pg_temp.u('c1'), 'B2B-CTL-0001', 'controller', NULL, 'Controleur', 'Ecarte', 'active', 'male');
INSERT INTO public.notifications (destinataire, evenement, params, destination)
VALUES (pg_temp.u('t1'), 'bienvenue_equipe', '{}'::jsonb, '/enseignant/journee'),
       (pg_temp.u('g1'), 'tout_est_pret', '{}'::jsonb, '/enseignant/journee');
INSERT INTO auth.users (id, email) SELECT ('5b2b0000-0000-4000-8000-0000000000' || (20 + i))::uuid, 'be2a2-c' || i || '@test.invalid'
  FROM generate_series(1, 2) i;
INSERT INTO public.profiles (id, immutable_id, role, first_name, last_name, account_status, gender)
SELECT ('5b2b0000-0000-4000-8000-0000000000' || (20 + i))::uuid, 'B2B-ENS-000' || (i + 1), 'teacher', 'Candidat', 'N' || i,
       'pending_kyc', 'male'::public.gender FROM generate_series(1, 2) i;
INSERT INTO public.teacher_profiles (profile_id, country, languages, kyc_status)
SELECT ('5b2b0000-0000-4000-8000-0000000000' || (20 + i))::uuid, 'SA', ARRAY[]::text[], 'pending' FROM generate_series(1, 2) i
ON CONFLICT (profile_id) DO NOTHING;
INSERT INTO public.candidatures (id, profile_id, type_code, genre, nom_complet, etape, etat, issue, en_pause, source)
SELECT pg_temp.d(n), ('5b2b0000-0000-4000-8000-0000000000' || (20 + right(n, 1)::int))::uuid, 'enseignant', 'male',
       'Fixture ASSOCIE ' || n, 'prequalification', 'en_examen', 'en_cours', false, 'lien_public'
  FROM unnest(ARRAY['E1', 'E2']) n;
INSERT INTO public.candidature_reponses (candidature_id, questionnaire_version, reponses, source, brouillon, envoye_le)
SELECT pg_temp.d(n), 'salle-examen-2', pg_catalog.jsonb_build_object('languesExplication', l, 'langueMaternelle', 'ar'),
       'candidat', false, pg_catalog.clock_timestamp()
  FROM (VALUES ('E1', '["anglais"]'::jsonb), ('E2', '["francais"]'::jsonb)) v(n, l);
INSERT INTO public.candidature_contacts (candidature_id, courriel, telephone)
SELECT pg_temp.d(n), lower(n) || '@exemple.invalid', '+33600000000' FROM unnest(ARRAY['E1', 'E2']) n;

-- ------------------------------------------------------------
-- (i) L'invitation
-- ------------------------------------------------------------
SELECT pg_temp.refus_en(pg_temp.u('c1'), 'controller',
  $$SELECT public.inviter_associe('ami@invite.test', 'Ami', '5b2b1111-0000-4000-8000-000000000001'::uuid)$$,
  '42501', 'i1 : un enseignant n''invite pas un associe');
SELECT pg_temp.refus_en(pg_temp.u('g1'), 'guardian',
  $$SELECT public.inviter_associe('ami@invite.test', 'Ami', '5b2b1111-0000-4000-8000-000000000001'::uuid)$$,
  '42501', 'i1b : un tuteur n''invite pas un associe');
SELECT pg_temp.refus_en(pg_temp.u('a1'), 'admin',
  $$SELECT public.inviter_associe('ami@invite.test', 'Ami', '5b2b1111-0000-4000-8000-000000000001'::uuid)$$,
  '42501', 'i2 : la direction sans double verification (aal1) n''invite pas', 'aal1');
SELECT pg_temp.refus_en(NULL, NULL,
  $$SELECT public.inviter_associe('ami@invite.test', 'Ami', '5b2b1111-0000-4000-8000-000000000001'::uuid)$$,
  '42501', 'i3 : sans session, refus', 'aal1', 'anon');
SELECT pg_temp.garde('inv_x', pg_temp.en(pg_temp.u('a1'), 'admin',
  $$SELECT public.inviter_associe('Ami@Invite.test ', ' Un ami ', '5b2b1111-0000-4000-8000-000000000001'::uuid)$$));
SELECT pg_temp.vrai(pg_temp.lu('inv_x') ->> 'statut' = 'creee'
  AND pg_temp.lu('inv_x') #>> '{invitation,email}' = 'ami@invite.test'
  AND pg_temp.lu('inv_x') #>> '{invitation,nom}' = 'Un ami'
  AND pg_temp.lu('inv_x') #>> '{invitation,etat}' = 'active'
  AND pg_temp.lu('inv_x') #>> '{invitation,code}' ~ '^[A-HJKMNP-Z2-9]{4}-[A-HJKMNP-Z2-9]{4}-[A-HJKMNP-Z2-9]{4}$',
  'i4 : la direction en aal2 invite : adresse normalisee, code a trois groupes, invitation active');
SELECT pg_temp.garde('inv_x2', pg_temp.en(pg_temp.u('a1'), 'admin',
  $$SELECT public.inviter_associe('ami@invite.test', 'Un ami', '5b2b1111-0000-4000-8000-000000000001'::uuid)$$));
SELECT pg_temp.vrai(pg_temp.lu('inv_x2') ->> 'rejoue' = 'true'
  AND pg_temp.lu('inv_x2') #>> '{invitation,code}' = pg_temp.lu('inv_x') #>> '{invitation,code}'
  AND (SELECT count(*) FROM public.invitations_associe WHERE email = 'ami@invite.test') = 1,
  'i5 : rejouer la meme cle rend la meme invitation, rien n''est ecrit une seconde fois');
SELECT pg_temp.vrai(
  pg_temp.en(pg_temp.u('a1'), 'admin',
    $$SELECT public.inviter_associe('ami@invite.test', 'Un ami', '5b2b1111-0000-4000-8000-000000000009'::uuid)$$) ->> 'statut' = 'deja_invite'
  AND pg_temp.en(pg_temp.u('a1'), 'admin',
    $$SELECT public.inviter_associe('pas-une-adresse', NULL, '5b2b1111-0000-4000-8000-000000000008'::uuid)$$) ->> 'statut' = 'email_invalide'
  AND pg_temp.en(pg_temp.u('a1'), 'admin',
    $$SELECT public.inviter_associe('be2a2-t1@test.invalid', NULL, '5b2b1111-0000-4000-8000-000000000007'::uuid)$$) ->> 'statut' = 'compte_existant',
  'i6 : une autre cle pour la meme adresse : deja_invite ; adresse illisible : email_invalide ; adresse d''un compte : compte_existant');
SELECT pg_temp.refus_en(pg_temp.u('a1'), 'admin',
  $$SELECT public.inviter_associe('ami2@invite.test', NULL, NULL::uuid)$$,
  '22023', 'i7 : sans cle d''idempotence, refus (22023)');
SELECT pg_temp.vrai(
  (SELECT count(*) FROM public.invitations_associe) = 1
  AND (pg_temp.en(pg_temp.u('a1'), 'admin', $$SELECT public.invitations_associe_admin()$$) -> 0 ->> 'code')
      = pg_temp.lu('inv_x') #>> '{invitation,code}',
  'i8 : la direction lit la liste des invitations (une seule, jamais de doublon)');

-- Le code est lie a l'adresse de la session : un autre compte (z) ne le consomme pas ; x le consomme une fois.
SELECT pg_temp.garde('code_x', to_jsonb(pg_temp.lu('inv_x') #>> '{invitation,code}'));
CREATE FUNCTION pg_temp.verifier(p_qui text, p_code text) RETURNS jsonb LANGUAGE sql AS $$
  SELECT pg_temp.en(pg_temp.u(p_qui), NULL, pg_catalog.format('SELECT public.verifier_invitation_associe(%L)', p_code), 'aal1') $$;
CREATE FUNCTION pg_temp.inscrire(p_qui text, p_code text, p_genre text) RETURNS jsonb LANGUAGE sql AS $$
  SELECT pg_temp.en(pg_temp.u(p_qui), NULL, pg_catalog.format(
    'SELECT public.inscrire_associe_invite(%L, ''Un'', ''Ami'', %s)', p_code,
    CASE WHEN p_genre IS NULL THEN 'NULL::public.gender' ELSE pg_catalog.quote_literal(p_genre) || '::public.gender' END), 'aal1') $$;
GRANT EXECUTE ON FUNCTION pg_temp.verifier(text, text), pg_temp.inscrire(text, text, text) TO authenticated, anon;

SELECT pg_temp.vrai(pg_temp.verifier('z', pg_temp.lu('code_x') #>> '{}') ->> 'resultat' = 'inconnue'
  AND pg_temp.inscrire('z', pg_temp.lu('code_x') #>> '{}', 'male') ->> 'resultat' = 'inconnue'
  AND NOT EXISTS (SELECT 1 FROM public.profiles WHERE id = pg_temp.u('z')),
  'c1 : le code est lie a l''adresse : un autre compte ne le consomme pas, aucun profil cree');
SELECT pg_temp.vrai(pg_temp.verifier('x', pg_temp.lu('code_x') #>> '{}') ->> 'resultat' = 'valide',
  'c2 : le bon compte voit le code valide');
SELECT pg_temp.refus_en(pg_temp.u('x'), NULL,
  pg_catalog.format($q$SELECT public.inscrire_associe_invite(%L, 'Un', 'Ami', NULL::public.gender)$q$, pg_temp.lu('code_x') #>> '{}'),
  '22023', 'c3 : sans genre, l''inscription est refusee (une mission se porte du cote de la personne)', 'aal1');
SELECT pg_temp.vrai(NOT EXISTS (SELECT 1 FROM public.profiles WHERE id = pg_temp.u('x')),
  'c3b : le refus n''a rien ecrit (aucun profil, invitation intacte)');
SELECT pg_temp.garde('insc_x', pg_temp.inscrire('x', pg_temp.lu('code_x') #>> '{}', 'male'));
SELECT pg_temp.vrai(pg_temp.lu('insc_x') ->> 'resultat' = 'consommee'
  AND (SELECT role::text || '/' || account_status::text || '/' || coalesce(household_id::text, 'sans-foyer') || '/' || gender::text
         FROM public.profiles WHERE id = pg_temp.u('x')) = 'associe/active/sans-foyer/male'
  AND (SELECT utilisee_par FROM public.invitations_associe WHERE email = 'ami@invite.test') = pg_temp.u('x'),
  'c4 : le compte associe est cree, actif, sans foyer ; l''invitation est consommee par lui');
SELECT pg_temp.refus_en(pg_temp.u('x'), 'associe',
  pg_catalog.format($q$SELECT public.inscrire_associe_invite(%L, 'Un', 'Ami', 'male'::public.gender)$q$, pg_temp.lu('code_x') #>> '{}'),
  '42501', 'c5 : un jeton ne sert qu''une fois : le compte a deja un profil, un second usage est refuse (42501)', 'aal1');
SELECT pg_temp.vrai(
  pg_temp.en(pg_temp.u('a1'), 'admin',
    pg_catalog.format('SELECT public.revoquer_invitation_associe(%L::uuid, %L, %L::uuid)',
      (SELECT id FROM public.invitations_associe WHERE email = 'ami@invite.test'), 'Trop tard',
      '5b2b2222-0000-4000-8000-000000000001')) ->> 'statut' = 'deja_utilisee',
  'c6 : une invitation consommee ne se revoque plus (deja_utilisee)');

-- Revocation : y est invite puis revoque ; il ne peut plus s'inscrire.
SELECT pg_temp.garde('inv_y', pg_temp.en(pg_temp.u('a1'), 'admin',
  $$SELECT public.inviter_associe('refuse@invite.test', NULL, '5b2b1111-0000-4000-8000-0000000000a1'::uuid)$$));
SELECT pg_temp.garde('id_y', to_jsonb(pg_temp.lu('inv_y') #>> '{invitation,id}'));
SELECT pg_temp.refus_en(pg_temp.u('c1'), 'controller',
  pg_catalog.format('SELECT public.revoquer_invitation_associe(%L::uuid, ''Motif'', ''5b2b2222-0000-4000-8000-000000000002''::uuid)',
    pg_temp.lu('id_y') #>> '{}'),
  '42501', 'r1 : seule la direction revoque');
SELECT pg_temp.refus_en(pg_temp.u('a1'), 'admin',
  pg_catalog.format('SELECT public.revoquer_invitation_associe(%L::uuid, ''  '', ''5b2b2222-0000-4000-8000-000000000003''::uuid)',
    pg_temp.lu('id_y') #>> '{}'),
  '22023', 'r2 : sans motif ecrit, la revocation est refusee (22023)');
SELECT pg_temp.garde('rev_y', pg_temp.en(pg_temp.u('a1'), 'admin',
  pg_catalog.format('SELECT public.revoquer_invitation_associe(%L::uuid, ''Plus necessaire'', ''5b2b2222-0000-4000-8000-000000000004''::uuid)',
    pg_temp.lu('id_y') #>> '{}')));
SELECT pg_temp.vrai(pg_temp.lu('rev_y') ->> 'statut' = 'revoquee'
  AND pg_temp.lu('rev_y') #>> '{invitation,etat}' = 'revoquee'
  AND pg_temp.en(pg_temp.u('a1'), 'admin',
    pg_catalog.format('SELECT public.revoquer_invitation_associe(%L::uuid, ''Plus necessaire'', ''5b2b2222-0000-4000-8000-000000000004''::uuid)',
      pg_temp.lu('id_y') #>> '{}')) ->> 'rejoue' = 'true',
  'r3 : une invitation est revocable ; rejouer la meme cle rend la meme reponse');
SELECT pg_temp.vrai(
  pg_temp.verifier('y', (SELECT code FROM public.invitations_associe WHERE email = 'refuse@invite.test')) ->> 'resultat' = 'inconnue'
  AND pg_temp.inscrire('y', (SELECT code FROM public.invitations_associe WHERE email = 'refuse@invite.test'), 'male') ->> 'resultat' = 'inconnue'
  AND NOT EXISTS (SELECT 1 FROM public.profiles WHERE id = pg_temp.u('y')),
  'r4 : l''invitation revoquee ne sert plus : inconnue, aucun profil cree');

-- ------------------------------------------------------------
-- (h) Le crochet de jeton ne rend jamais null
-- ------------------------------------------------------------
SELECT pg_temp.vrai(
  public.custom_access_token_hook(pg_catalog.jsonb_build_object('user_id', pg_temp.u('x'),
    'claims', pg_catalog.jsonb_build_object('sub', pg_temp.u('x')))) IS NOT NULL
  AND public.custom_access_token_hook(pg_catalog.jsonb_build_object('user_id', pg_temp.u('x'),
    'claims', pg_catalog.jsonb_build_object('sub', pg_temp.u('x')))) #>> '{claims,app_metadata,role}' = 'associe'
  AND public.custom_access_token_hook(pg_catalog.jsonb_build_object('user_id', pg_temp.u('x'),
    'claims', pg_catalog.jsonb_build_object('sub', pg_temp.u('x')))) #> '{claims,app_metadata,household_id}' = 'null'::jsonb,
  'h1 : le jeton d''un associe porte le role associe, sans foyer, et n''est jamais null');
SELECT pg_temp.vrai(
  public.custom_access_token_hook(pg_catalog.jsonb_build_object('user_id', pg_temp.u('z'),
    'claims', pg_catalog.jsonb_build_object('sub', pg_temp.u('z')))) IS NOT NULL
  AND public.custom_access_token_hook(pg_catalog.jsonb_build_object('user_id', pg_temp.u('x'))) IS NOT NULL,
  'h2 : sans profil, ou sans claims : le crochet rend encore un evenement (jamais null)');

-- ------------------------------------------------------------
-- (t) Un associe SANS mission : aucune ligne de personne
-- ------------------------------------------------------------
-- Chaque table de `public` est essayee sous le role authenticated, au nom de x (jeton associe). Une table sans droit
-- SELECT compte pour 0. La liste des tables lisibles est EXPLICITE.
CREATE FUNCTION pg_temp.lisibles(p_qui text) RETURNS text
LANGUAGE plpgsql AS $$
DECLARE
  v_t record;
  v_n bigint;
  v_liste text[] := ARRAY[]::text[];
BEGIN
  PERFORM pg_temp.qui(pg_temp.u(p_qui), 'associe', 'aal1');
  FOR v_t IN SELECT c.relname FROM pg_catalog.pg_class c JOIN pg_catalog.pg_namespace n ON n.oid = c.relnamespace
              WHERE n.nspname = 'public' AND c.relkind IN ('r', 'p', 'v', 'm') ORDER BY c.relname LOOP
    BEGIN
      EXECUTE 'SET LOCAL ROLE authenticated';
      EXECUTE pg_catalog.format('SELECT count(*) FROM public.%I', v_t.relname) INTO v_n;
      EXECUTE 'RESET ROLE';
      IF v_n > 0 THEN
        v_liste := v_liste || (v_t.relname || ':' || v_n);
      END IF;
    EXCEPTION WHEN OTHERS THEN
      EXECUTE 'RESET ROLE';
    END;
  END LOOP;
  RETURN pg_catalog.array_to_string(v_liste, ',');
END $$;
GRANT EXECUTE ON FUNCTION pg_temp.lisibles(text) TO authenticated, anon;

-- Ce qui a des lignes dans ce scenario (la couverture) : dit, pas suppose.
DO $couverture$
DECLARE
  v_t record;
  v_n bigint;
  v_pleines text[] := ARRAY[]::text[];
  v_vides integer := 0;
BEGIN
  FOR v_t IN SELECT c.relname FROM pg_catalog.pg_class c JOIN pg_catalog.pg_namespace n ON n.oid = c.relnamespace
              WHERE n.nspname = 'public' AND c.relkind IN ('r', 'p') ORDER BY c.relname LOOP
    EXECUTE pg_catalog.format('SELECT count(*) FROM public.%I', v_t.relname) INTO v_n;
    IF v_n > 0 THEN v_pleines := v_pleines || v_t.relname; ELSE v_vides := v_vides + 1; END IF;
  END LOOP;
  PERFORM pg_catalog.set_config('test.pleines', pg_catalog.array_to_string(v_pleines, ','), true);
  RAISE NOTICE 'COUVERTURE : % tables avec des lignes dans ce scenario (%) ; % tables vides (preuve vide)',
    pg_catalog.cardinality(v_pleines), pg_catalog.array_to_string(v_pleines, ', '), v_vides;
END
$couverture$;

SELECT pg_catalog.set_config('test.lisibles_x', pg_temp.lisibles('x'), true);
-- Exigence positive : ce qu'un associe sans mission peut lire, ni plus ni moins que cette liste. profiles : sa propre
-- ligne ; les autres sont des contenus communs sans personne (Coran, langues, tranches d'age, textes publies, regles
-- de recurrence, rayons de la bibliotheque).
DO $liste$
DECLARE
  v_lues text[] := pg_catalog.string_to_array(pg_catalog.current_setting('test.lisibles_x'), ',');
  v_attendues constant text[] := ARRAY['cohortes_age', 'contract_texts', 'juz', 'langues_cours', 'library_rayon', 'mushaf',
                                       'page_mushaf', 'profiles', 'recurrence_rules', 'sourate', 'verset'];
  v_extra text[];
  v_nom text;
BEGIN
  SELECT pg_catalog.array_agg(split_part(e, ':', 1) ORDER BY split_part(e, ':', 1)) INTO v_extra
    FROM pg_catalog.unnest(v_lues) e
   WHERE e <> '' AND NOT (split_part(e, ':', 1) = ANY (v_attendues));
  IF v_extra IS NOT NULL THEN
    RAISE EXCEPTION 'ASSOCIE ROUGE : t1 : un associe sans mission lit des tables hors de la liste : % (lues : %)',
      v_extra, pg_catalog.current_setting('test.lisibles_x');
  END IF;
  RAISE NOTICE 'OK t1 : un associe sans mission ne lit que la liste explicite (%)', pg_catalog.current_setting('test.lisibles_x');
  PERFORM pg_catalog.set_config('test.n',
    (coalesce(nullif(pg_catalog.current_setting('test.n', true), ''), '0')::int + 1)::text, true);
END
$liste$;
SELECT pg_temp.vrai('profiles:1' = ANY (pg_catalog.string_to_array(pg_catalog.current_setting('test.lisibles_x'), ',')),
  't2 : dans profiles, un associe ne lit qu''UNE ligne (la sienne), jamais celles des autres');
SELECT pg_temp.vrai(
  pg_temp.en(pg_temp.u('x'), 'associe', $$SELECT to_jsonb((SELECT id FROM public.profiles LIMIT 1))$$, 'aal1') #>> '{}' = pg_temp.u('x')::text,
  't2b : cette ligne est celle de l''associe');
SELECT pg_temp.vrai(
  pg_catalog.strpos(pg_catalog.current_setting('test.pleines'), 'candidatures') > 0
  AND pg_catalog.strpos(pg_catalog.current_setting('test.pleines'), 'profiles') > 0
  AND pg_catalog.strpos(pg_catalog.current_setting('test.pleines'), 'notifications') > 0
  AND pg_catalog.strpos(pg_catalog.current_setting('test.pleines'), 'households') > 0,
  't3 : la preuve n''est pas vide pour les tables de personnes de base : candidatures, profiles, notifications, foyers ont des lignes');
-- Audit structurel (les tables vides ne prouvent rien) : les politiques de lecture PERMISSIVES offertes a tout compte
-- connecte dont la condition ne nomme ni un role, ni l'identite de la personne, ni son foyer, ni une porte privee. Un
-- role nouveau les heriterait : la liste est fermee, une politique de plus fait rougir ce controle.
-- (controleur_voit_session, ajoutee par #590 : porte POSITIVE, role controller en aal2 et mission attribuee.)
DO $structure$
DECLARE
  v_trouvees text[];
  v_attendues constant text[] := ARRAY[
    'annotation_marqueur_lecture', 'annotation_trait_lecture', 'cohortes_age_lecture',
    'com_message_coeurs_lecture_participants', 'com_message_images_lecture_participants', 'contract_texts_published_read',
    'groupe_creneaux_lecture', 'juz_lecture', 'kyc_client_read_block', 'langues_cours_lecture', 'library_rayon_lecture',
    'mushaf_lecture', 'page_mushaf_lecture', 'prayer_settings_self_write', 'recurrence_rules_teacher_read',
    'rule_overrides_parties_read', 'sourate_lecture', 'srp_eleve_tout', 'verset_lecture', 'weekly_availability_parties_read'];
  v_en_trop text[];
BEGIN
  SELECT pg_catalog.array_agg(p.policyname::text ORDER BY p.policyname) INTO v_trouvees
    FROM pg_catalog.pg_policies p
   WHERE p.schemaname = 'public' AND p.permissive = 'PERMISSIVE' AND p.cmd IN ('SELECT', 'ALL')
     AND p.roles::text ~ 'authenticated|public'
     AND coalesce(p.qual, '') !~* '(app_role|auth\.uid|uid\(\)|app_household|jwt|est_direction|cand_lecteur|controleur_voit_|mission_|private\.|app_private\.|session_belongs|household)';
  SELECT pg_catalog.array_agg(e ORDER BY e) INTO v_en_trop
    FROM pg_catalog.unnest(coalesce(v_trouvees, ARRAY[]::text[])) e WHERE NOT (e = ANY (v_attendues));
  IF v_en_trop IS NOT NULL THEN
    RAISE EXCEPTION 'ASSOCIE ROUGE : t7 : politiques de lecture ouvertes a tout compte, hors de la liste relue : %', v_en_trop;
  END IF;
  IF EXISTS (SELECT 1 FROM pg_catalog.pg_class c JOIN pg_catalog.pg_namespace n ON n.oid = c.relnamespace
              WHERE n.nspname = 'public' AND c.relkind IN ('r', 'p') AND NOT c.relrowsecurity
                AND pg_catalog.has_table_privilege('authenticated', c.oid, 'SELECT')) THEN
    RAISE EXCEPTION 'ASSOCIE ROUGE : t8 : une table lisible par authenticated n''a pas de securite par ligne';
  END IF;
  RAISE NOTICE 'OK t7 : les politiques de lecture ouvertes a tout compte sont celles de la liste relue (%) ; t8 : toute table lisible a la securite par ligne',
    pg_catalog.cardinality(v_trouvees);
  PERFORM pg_catalog.set_config('test.n',
    (coalesce(nullif(pg_catalog.current_setting('test.n', true), ''), '0')::int + 2)::text, true);
END
$structure$;
SELECT pg_temp.refus_en(pg_temp.u('x'), 'associe', $$SELECT public.lister_candidatures('{}'::jsonb, 'recente', 1)$$,
  '42501', 't4 : sans mission, la liste des candidatures est refusee (42501)', 'aal1');
SELECT pg_temp.refus_en(pg_temp.u('x'), 'associe', $$SELECT public.lire_candidature(pg_temp.d('E1'))$$,
  '42501', 't5 : sans mission, lire un dossier est refuse (42501)', 'aal1');
SELECT pg_temp.refus_en(pg_temp.u('x'), 'associe', $$SELECT public.invitations_associe_admin()$$,
  '42501', 't6 : un associe ne lit pas les invitations (42501)', 'aal1');

-- ------------------------------------------------------------
-- (m) Une mission « lire » sur les dossiers en anglais, puis retiree
-- ------------------------------------------------------------
SELECT pg_temp.garde('m1', pg_temp.en(pg_temp.u('a1'), 'admin', $$SELECT pg_catalog.to_jsonb(public.creer_mission(
  'Candidatures en anglais', ARRAY['lire'], '11111111-0000-4000-8000-0000000000b1'::uuid))$$));
SELECT pg_temp.refus_en(pg_temp.u('a1'), 'admin', pg_catalog.format(
  'SELECT public.accorder_mission(%L::uuid, %L::uuid, ''{}''::jsonb, NULL, NULL, ''22222222-0000-4000-8000-0000000000b0''::uuid)',
  pg_temp.u('c1'), pg_temp.lu('m1') #>> '{}'),
  '22023', 'm0 : accorder_mission n''admet plus controller (compte de personnel indisponible)');
SELECT pg_temp.garde('att', pg_temp.en(pg_temp.u('a1'), 'admin', pg_catalog.format(
  'SELECT pg_catalog.to_jsonb(public.accorder_mission(%L::uuid, %L::uuid, ''{"langues": ["anglais"]}''::jsonb, NULL, NULL, ''22222222-0000-4000-8000-0000000000b1''::uuid))',
  pg_temp.u('x'), pg_temp.lu('m1') #>> '{}')));
SELECT pg_catalog.set_config('test.compte_avant',
  (SELECT role::text || '/' || account_status::text || '/' || coalesce(gender::text, '-') || '/' || coalesce(household_id::text, '-')
     FROM public.profiles WHERE id = pg_temp.u('x')), true);
SELECT pg_temp.garde('liste', pg_temp.en(pg_temp.u('x'), 'associe', $$SELECT public.lister_candidatures('{}'::jsonb, 'recente', 1)$$, 'aal1'));
SELECT pg_temp.vrai((SELECT array_agg(l ->> 'nomComplet' ORDER BY l ->> 'nomComplet') FROM jsonb_array_elements(pg_temp.lu('liste') -> 'lignes') l)
    = ARRAY['Fixture ASSOCIE E1'] AND (pg_temp.lu('liste') ->> 'total')::int = 1,
  'm1 : avec la mission, l''associe ne voit que le dossier en anglais (E1) ; E2 en francais est absent');
SELECT pg_temp.garde('lire_e2', pg_temp.en(pg_temp.u('x'), 'associe', $$SELECT public.lire_candidature(pg_temp.d('E2'))$$, 'aal1'));
SELECT pg_temp.vrai(pg_temp.lu('lire_e2') = '{"erreur": "hors_portee"}'::jsonb
  AND NOT (pg_temp.en(pg_temp.u('x'), 'associe', $$SELECT public.lire_candidature(pg_temp.d('E1'))$$, 'aal1') ? 'erreur'),
  'm2 : le dossier du perimetre est lu, celui en francais est hors_portee');
SELECT pg_catalog.set_config('test.lisibles_m', pg_temp.lisibles('x'), true);
SELECT pg_temp.vrai(pg_catalog.current_setting('test.lisibles_m') = pg_catalog.current_setting('test.lisibles_x'),
  'm3 : meme avec une mission, les tables lisibles directement sont les memes (la mission passe par les portes du moteur)');
SELECT pg_temp.vrai(pg_temp.en(pg_temp.u('a1'), 'admin', pg_catalog.format(
  'SELECT to_jsonb(public.retirer_mission(%L::uuid, ''fin de mission'', ''33333333-0000-4000-8000-0000000000b1''::uuid))',
  pg_temp.lu('att') #>> '{}')) = 'true'::jsonb, 'm4 : la direction retire la mission');
SELECT pg_temp.refus_en(pg_temp.u('x'), 'associe', $$SELECT public.lister_candidatures('{}'::jsonb, 'recente', 1)$$,
  '42501', 'm5 : la mission retiree, l''associe ne voit plus rien (42501)', 'aal1');
SELECT pg_temp.refus_en(pg_temp.u('x'), 'associe', $$SELECT public.lire_candidature(pg_temp.d('E1'))$$,
  '42501', 'm6 : la mission retiree, le dossier n''est plus lisible (42501)', 'aal1');
SELECT pg_temp.vrai(
  (SELECT role::text || '/' || account_status::text || '/' || coalesce(gender::text, '-') || '/' || coalesce(household_id::text, '-')
     FROM public.profiles WHERE id = pg_temp.u('x')) = pg_catalog.current_setting('test.compte_avant')
  AND pg_catalog.current_setting('test.lisibles_x') = pg_temp.lisibles('x'),
  'm7 : le compte (role, statut, genre, foyer) est inchange, et les tables lisibles sont celles d''avant la mission');

-- ------------------------------------------------------------
-- (d) anon : aucun droit
-- ------------------------------------------------------------
SELECT pg_temp.vrai(
  NOT has_function_privilege('anon', 'public.inviter_associe(text,text,uuid)', 'EXECUTE')
  AND NOT has_function_privilege('anon', 'public.revoquer_invitation_associe(uuid,text,uuid)', 'EXECUTE')
  AND NOT has_function_privilege('anon', 'public.verifier_invitation_associe(text)', 'EXECUTE')
  AND NOT has_function_privilege('anon', 'public.inscrire_associe_invite(text,text,text,gender)', 'EXECUTE')
  AND NOT has_function_privilege('anon', 'public.invitations_associe_admin()', 'EXECUTE')
  AND NOT has_table_privilege('anon', 'public.invitations_associe', 'SELECT')
  AND NOT has_table_privilege('authenticated', 'public.invitations_associe', 'INSERT')
  AND NOT has_table_privilege('authenticated', 'public.invitations_associe', 'UPDATE')
  AND NOT has_table_privilege('authenticated', 'public.invitations_associe', 'DELETE')
  AND (SELECT bool_and(NOT has_function_privilege(r, 'public.inviter_associe(text,text,uuid)', 'EXECUTE'))
         FROM unnest(ARRAY['service_role', 'agent_ro']) r)
  AND (SELECT relrowsecurity FROM pg_class WHERE oid = 'public.invitations_associe'::regclass),
  'd1 : anon n''a aucun droit sur les portes nouvelles ni sur la table ; authenticated ne peut qu''y lire ; RLS active');

-- ------------------------------------------------------------
-- (e) Bibliotheque : l'associe ne lit aucun document `inscrits` (audit du pilote, 17/11/2026)
-- ------------------------------------------------------------
SET LOCAL session_replication_role = replica;
INSERT INTO public.resource_version (id, resource_id, numero_version, statut) VALUES
  ('be2a2000-0000-0000-0000-0000000000b2', 'be2a2000-0000-0000-0000-0000000000b1', 1, 'publiee'),
  ('be2a2000-0000-0000-0000-0000000000c2', 'be2a2000-0000-0000-0000-0000000000c1', 1, 'publiee');
INSERT INTO public.library_resource (id, title, short_title, resource_type, access_policy, offline_policy, current_version_id) VALUES
  ('be2a2000-0000-0000-0000-0000000000b1', 'BE-2a-2 inscrits', 'B2A2-I', 'pdf', 'inscrits', 'jamais', 'be2a2000-0000-0000-0000-0000000000b2'),
  ('be2a2000-0000-0000-0000-0000000000c1', 'BE-2a-2 publique', 'B2A2-P', 'pdf', 'publique', 'jamais', 'be2a2000-0000-0000-0000-0000000000c2');
SET LOCAL session_replication_role = origin;

SELECT pg_temp.vrai(
  (pg_temp.en(pg_temp.u('x'), 'associe',
     $$SELECT pg_catalog.to_jsonb((SELECT count(*) FROM public.library_resource WHERE id = 'be2a2000-0000-0000-0000-0000000000b1'))$$))::text = '0',
  'e1 : un associe ne lit aucun document `inscrits` (0 ligne)');
SELECT pg_temp.qui(pg_temp.u('x'), 'associe');
SELECT pg_temp.vrai(
  private.n4_ressource_lisible('be2a2000-0000-0000-0000-0000000000b1'::uuid) IS NOT TRUE,
  'e2 : n4_ressource_lisible refuse le document `inscrits` a un associe');
SELECT pg_temp.refus_en(pg_temp.u('x'), 'associe',
  $$SELECT public.autoriser_lecture_version('be2a2000-0000-0000-0000-0000000000b2'::uuid)$$,
  '42501', 'e3 : aucun telechargement d''un document `inscrits` pour un associe (42501)');
SELECT pg_temp.qui(pg_temp.u('c1'), 'controller');
SELECT pg_temp.vrai(
  private.n4_ressource_lisible('be2a2000-0000-0000-0000-0000000000b1'::uuid) IS TRUE
  AND (pg_temp.en(pg_temp.u('c1'), 'controller',
     $$SELECT pg_catalog.to_jsonb((SELECT count(*) FROM public.library_resource WHERE id = 'be2a2000-0000-0000-0000-0000000000b1'))$$))::text = '1',
  'e4 : controle positif : un compte des six roles (controleur) lit toujours le document `inscrits`');
SELECT pg_temp.vrai(
  (pg_temp.en(pg_temp.u('x'), 'associe',
     $$SELECT pg_catalog.to_jsonb((SELECT count(*) FROM public.library_resource WHERE id = 'be2a2000-0000-0000-0000-0000000000c1'))$$))::text IN ('0', '1'),
  'e5 : la lecture d''un document `publique` par l''associe est dite (aucune erreur) : voir la sortie du scenario');

SELECT pg_temp.vrai(coalesce(nullif(current_setting('test.n', true), ''), '0')::int >= 43,
  'z : au moins 43 controles passes');
ROLLBACK;
