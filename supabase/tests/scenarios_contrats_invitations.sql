-- CONTRATS-MANQUANTS : invitations d'enseignant (PortInvitationsEnseignant,
-- PortVerificationInvitation ; C-13, C-14).
-- Chaque garde a un controle de refus. A rejouer sur une base NEUVE.
\o /dev/null
BEGIN;

CREATE FUNCTION pg_temp.qui(p_id uuid, p_role text) RETURNS void
LANGUAGE plpgsql AS $$
DECLARE v_jwt text;
BEGIN
  v_jwt := CASE WHEN p_role IS NULL THEN '{}'
                ELSE pg_catalog.json_build_object('app_metadata',
                       pg_catalog.json_build_object('role', p_role))::text END;
  PERFORM pg_catalog.set_config('request.jwt.claim.sub', coalesce(p_id::text, ''), true);
  PERFORM pg_catalog.set_config('test.uid', coalesce(p_id::text, ''), true);
  PERFORM pg_catalog.set_config('request.jwt.claims', v_jwt, true);
  PERFORM pg_catalog.set_config('test.jwt', v_jwt, true);
END $$;

CREATE FUNCTION pg_temp.ok(p_label text) RETURNS void
LANGUAGE plpgsql AS $$
BEGIN
  PERFORM pg_catalog.set_config('test.n',
    (coalesce(nullif(pg_catalog.current_setting('test.n', true), ''), '0')::int + 1)::text, true);
  RAISE NOTICE 'OK %', p_label;
END $$;

CREATE FUNCTION pg_temp.vrai(p_condition boolean, p_label text) RETURNS void
LANGUAGE plpgsql AS $$
BEGIN
  IF p_condition IS NOT TRUE THEN
    RAISE EXCEPTION 'ROUGE : %', p_label;
  END IF;
  PERFORM pg_temp.ok(p_label);
END $$;

CREATE FUNCTION pg_temp.refus(p_sql text, p_code text, p_label text) RETURNS void
LANGUAGE plpgsql AS $$
BEGIN
  BEGIN
    EXECUTE p_sql;
    RAISE EXCEPTION 'ROUGE : % (aucun refus)', p_label USING ERRCODE = 'P0001';
  EXCEPTION WHEN OTHERS THEN
    IF SQLSTATE <> p_code THEN
      RAISE EXCEPTION 'ROUGE : % (code % au lieu de % : %)', p_label, SQLSTATE, p_code, SQLERRM;
    END IF;
  END;
  PERFORM pg_temp.ok(p_label);
END $$;

GRANT EXECUTE ON FUNCTION pg_temp.qui(uuid, text), pg_temp.ok(text), pg_temp.vrai(boolean, text),
  pg_temp.refus(text, text, text) TO authenticated, anon;

-- ------------------------------------------------------------
-- Fixtures (donnees inventees)
-- ------------------------------------------------------------
INSERT INTO auth.users(id, email) VALUES
 ('ce000000-0000-4000-8000-0000000000a1','ce-admin@test.invalid'),
 ('ce000000-0000-4000-8000-0000000000a2','ce-admin-off@test.invalid'),
 ('ce000000-0000-4000-8000-0000000000b1','ce-ens@test.invalid'),
 ('ce000000-0000-4000-8000-0000000000c1','candidat@test.invalid'),
 ('ce000000-0000-4000-8000-0000000000c2','autre-candidat@test.invalid'),
 ('ce000000-0000-4000-8000-0000000000c3','deja-inscrit@test.invalid');
INSERT INTO public.profiles(id, immutable_id, role, household_id, first_name, last_name, account_status, gender) VALUES
 ('ce000000-0000-4000-8000-0000000000a1','CE-ADM-0001','admin',NULL,'Direction','Essai','active','female'),
 ('ce000000-0000-4000-8000-0000000000a2','CE-ADM-0002','admin',NULL,'Direction','Desactivee','disabled','male'),
 ('ce000000-0000-4000-8000-0000000000b1','CE-ENS-0001','teacher',NULL,'Yusuf','Fictif','provisional_active','male'),
 ('ce000000-0000-4000-8000-0000000000c3','CE-ENS-0003','teacher',NULL,'Bilal','Essai','provisional_active','male');
-- Une invitation echue (autre-candidat) et une invitation deja utilisee.
INSERT INTO public.invitations_enseignant(code, email, cree_par, cree_le, expire_le) VALUES
 ('EXPR-AAAA-2222','autre-candidat@test.invalid','ce000000-0000-4000-8000-0000000000a1', now() - interval '20 days', now() - interval '6 days');
INSERT INTO public.invitations_enseignant(code, email, cree_par, expire_le, utilisee_le, utilisee_par) VALUES
 ('UTTT-BBBB-3333','deja-inscrit@test.invalid','ce000000-0000-4000-8000-0000000000a1', now() + interval '3 days', now(), 'ce000000-0000-4000-8000-0000000000c3');

-- ------------------------------------------------------------
-- 1. ACL et F86
-- ------------------------------------------------------------
DO $acl$
DECLARE f regprocedure;
BEGIN
  FOREACH f IN ARRAY ARRAY['public.inviter_enseignant(text)'::regprocedure,
                           'public.revoquer_invitation_enseignant(text)'::regprocedure,
                           'public.verifier_invitation_enseignant(text)'::regprocedure] LOOP
    IF NOT (SELECT prosecdef AND proconfig @> ARRAY['search_path=""'] FROM pg_proc WHERE oid = f)
       OR coalesce(obj_description(f, 'pg_proc'), '') NOT LIKE '%md5_functiondef=' || md5(pg_get_functiondef(f)) || '%'
       OR NOT has_function_privilege('authenticated', f, 'EXECUTE')
       OR has_function_privilege('anon', f, 'EXECUTE')
       OR has_function_privilege('service_role', f, 'EXECUTE')
       OR has_function_privilege('agent_ro', f, 'EXECUTE') THEN
      RAISE EXCEPTION 'ROUGE : DEFINER, empreinte ou ACL de %', f;
    END IF;
  END LOOP;
  PERFORM pg_temp.ok('trois RPC DEFINER : search_path vide, empreinte reelle, authenticated seul');
  IF (SELECT prosecdef FROM pg_proc WHERE oid = 'public.invitations_enseignant_admin()'::regprocedure)
     OR has_function_privilege('anon', 'public.invitations_enseignant_admin()', 'EXECUTE') THEN
    RAISE EXCEPTION 'ROUGE : la liste doit etre INVOKER et fermee a anon';
  END IF;
  PERFORM pg_temp.ok('liste INVOKER fermee a anon');
  IF NOT (SELECT relrowsecurity FROM pg_class WHERE oid = 'public.invitations_enseignant'::regclass)
     OR has_table_privilege('authenticated', 'public.invitations_enseignant', 'INSERT,UPDATE,DELETE')
     OR has_table_privilege('anon', 'public.invitations_enseignant', 'SELECT') THEN
    RAISE EXCEPTION 'ROUGE : table des invitations sans RLS ou ecrivable';
  END IF;
  PERFORM pg_temp.ok('table des invitations : RLS, aucune ecriture directe');
END $acl$;

SET LOCAL ROLE anon;
SELECT pg_temp.refus($$SELECT public.inviter_enseignant('x@test.invalid')$$, '42501', 'anon : invitation refusee');
SELECT pg_temp.refus($$SELECT public.verifier_invitation_enseignant('EXPR-AAAA-2222')$$, '42501', 'anon : verification refusee');
RESET ROLE;

-- ------------------------------------------------------------
-- 2. Gardes
-- ------------------------------------------------------------
SELECT pg_temp.qui('ce000000-0000-4000-8000-0000000000b1','teacher');
SET LOCAL ROLE authenticated;
SELECT pg_temp.refus($$SELECT public.inviter_enseignant('x@test.invalid')$$, '42501', 'enseignant : invitation refusee (garde direction)');
SELECT pg_temp.refus($$SELECT public.invitations_enseignant_admin()$$, '42501', 'enseignant : liste refusee');
SELECT pg_temp.refus($$SELECT public.revoquer_invitation_enseignant('EXPR-AAAA-2222')$$, '42501', 'enseignant : revocation refusee');
SELECT pg_temp.vrai((SELECT count(*) FROM public.invitations_enseignant) = 0, 'enseignant : aucune ligne lisible (RLS)');
SELECT pg_temp.refus($$INSERT INTO public.invitations_enseignant(code, email, cree_par, expire_le)
  VALUES ('AAAA-AAAA-AAAA','y@test.invalid','ce000000-0000-4000-8000-0000000000b1', now() + interval '1 day')$$,
  '42501', 'aucune ecriture directe dans la table');
RESET ROLE;

SELECT pg_temp.qui('ce000000-0000-4000-8000-0000000000a2','admin');
SET LOCAL ROLE authenticated;
SELECT pg_temp.refus($$SELECT public.inviter_enseignant('x@test.invalid')$$, '42501', 'direction desactivee : invitation refusee');
SELECT pg_temp.refus($$SELECT public.revoquer_invitation_enseignant('EXPR-AAAA-2222')$$, '42501', 'direction desactivee : revocation refusee');
RESET ROLE;

SELECT pg_temp.qui(NULL, NULL);
SET LOCAL ROLE authenticated;
SELECT pg_temp.refus($$SELECT public.verifier_invitation_enseignant('EXPR-AAAA-2222')$$, '42501',
  'verification sans session refusee (garde session)');
RESET ROLE;

-- ------------------------------------------------------------
-- 3. Emettre, lister
-- ------------------------------------------------------------
SELECT pg_temp.qui('ce000000-0000-4000-8000-0000000000a1','admin');
SET LOCAL ROLE authenticated;
DO $emettre$
DECLARE v jsonb; w jsonb;
BEGIN
  v := public.inviter_enseignant('  Candidat@Test.INVALID ');
  PERFORM pg_temp.vrai(v ->> 'statut' = 'creee'
    AND v -> 'invitation' ->> 'email' = 'candidat@test.invalid'
    AND v -> 'invitation' ->> 'etat' = 'active'
    AND v -> 'invitation' ->> 'code' ~ '^[A-HJKMNP-Z2-9]{4}-[A-HJKMNP-Z2-9]{4}-[A-HJKMNP-Z2-9]{4}$'
    AND (v -> 'invitation' ->> 'expire_le')::timestamptz BETWEEN now() + interval '13 days' AND now() + interval '15 days',
    'invitation creee : adresse normalisee, code a 12 signes, echeance a 14 jours');
  PERFORM set_config('test.code', v -> 'invitation' ->> 'code', true);
  w := public.inviter_enseignant('candidat@test.invalid');
  PERFORM pg_temp.vrai(w ->> 'statut' = 'deja_invite' AND w -> 'invitation' ->> 'code' = v -> 'invitation' ->> 'code',
    'deja invite : l''invitation active est rendue, aucune seconde');
  PERFORM pg_temp.vrai(public.inviter_enseignant('pas-une-adresse') = '{"statut": "email_invalide", "invitation": null}'::jsonb,
    'adresse invalide');
  PERFORM pg_temp.vrai(public.inviter_enseignant('deja-inscrit@test.invalid') = '{"statut": "compte_existant", "invitation": null}'::jsonb,
    'compte existant');
  w := public.invitations_enseignant_admin();
  PERFORM pg_temp.vrai(jsonb_array_length(w) = 3 AND w -> 0 ->> 'code' = v -> 'invitation' ->> 'code'
    AND w -> 1 ->> 'etat' = 'utilisee' AND w -> 1 ->> 'utilisee_le' IS NOT NULL
    AND w -> 2 ->> 'etat' = 'expiree',
    'liste : la plus recente d''abord, etats calcules par le serveur');
END $emettre$;
RESET ROLE;
SELECT pg_temp.vrai((SELECT count(*) FROM public.audit_logs WHERE action = 'invitation_enseignant_emise') = 1,
  'emission auditee une fois');

-- ------------------------------------------------------------
-- 4. Verifier (candidat en session d'inscription, sans profil)
-- ------------------------------------------------------------
SELECT pg_temp.qui('ce000000-0000-4000-8000-0000000000c1', NULL);
SET LOCAL ROLE authenticated;
SELECT pg_temp.vrai((public.verifier_invitation_enseignant(current_setting('test.code')) ->> 'resultat') = 'valide'
  AND (public.verifier_invitation_enseignant(current_setting('test.code')) ->> 'expire_le') IS NOT NULL,
  'code valide pour l''adresse de la session');
SELECT pg_temp.vrai((public.verifier_invitation_enseignant('  ' || lower(current_setting('test.code')) || ' ') ->> 'resultat') = 'valide',
  'code saisi en minuscules et avec espaces : valide');
SELECT pg_temp.vrai(public.verifier_invitation_enseignant('ZZZZ-ZZZZ-ZZZZ') = '{"resultat": "inconnue", "expire_le": null}'::jsonb,
  'code inconnu');
SELECT pg_temp.vrai((public.verifier_invitation_enseignant('EXPR-AAAA-2222') ->> 'resultat') = 'inconnue',
  'code d''une autre adresse : inconnu, aucune fuite');
RESET ROLE;
SELECT pg_temp.qui('ce000000-0000-4000-8000-0000000000c2', NULL);
SET LOCAL ROLE authenticated;
SELECT pg_temp.vrai((public.verifier_invitation_enseignant('EXPR-AAAA-2222') ->> 'resultat') = 'expiree'
  AND (public.verifier_invitation_enseignant('EXPR-AAAA-2222') ->> 'expire_le') IS NOT NULL,
  'code echu : expiree, avec l''echeance');
RESET ROLE;
SELECT pg_temp.qui('ce000000-0000-4000-8000-0000000000c3', 'teacher');
SET LOCAL ROLE authenticated;
SELECT pg_temp.vrai(public.verifier_invitation_enseignant('UTTT-BBBB-3333') = '{"resultat": "deja_utilisee", "expire_le": null}'::jsonb,
  'code deja utilise');
RESET ROLE;

-- ------------------------------------------------------------
-- 5. Revoquer
-- ------------------------------------------------------------
SELECT pg_temp.qui('ce000000-0000-4000-8000-0000000000a1','admin');
SET LOCAL ROLE authenticated;
SELECT public.revoquer_invitation_enseignant(current_setting('test.code'));
SELECT pg_temp.vrai((SELECT e ->> 'etat' FROM jsonb_array_elements(public.invitations_enseignant_admin()) e
                      WHERE e ->> 'code' = current_setting('test.code')) = 'revoquee', 'revocation faite');
SELECT public.revoquer_invitation_enseignant(current_setting('test.code'));
SELECT public.revoquer_invitation_enseignant('UTTT-BBBB-3333');
SELECT pg_temp.vrai((SELECT e ->> 'etat' FROM jsonb_array_elements(public.invitations_enseignant_admin()) e
                      WHERE e ->> 'code' = 'UTTT-BBBB-3333') = 'utilisee',
  'revoquer une invitation revoquee ou utilisee : sans effet ni erreur');
SELECT pg_temp.refus($$SELECT public.revoquer_invitation_enseignant('ZZZZ-ZZZZ-ZZZZ')$$, 'P0002', 'revoquer un code inconnu : introuvable');
SELECT pg_temp.vrai((public.inviter_enseignant('candidat@test.invalid') ->> 'statut') = 'creee',
  'apres revocation, une nouvelle invitation peut etre emise');
RESET ROLE;
SELECT pg_temp.qui('ce000000-0000-4000-8000-0000000000c1', NULL);
SET LOCAL ROLE authenticated;
SELECT pg_temp.vrai((public.verifier_invitation_enseignant(current_setting('test.code')) ->> 'resultat') = 'inconnue',
  'code revoque : inconnu (on ne distingue pas)');
RESET ROLE;

DO $fin$
BEGIN
  IF current_setting('test.n')::int <> 30 THEN
    RAISE EXCEPTION 'ROUGE : % controles executes, 30 attendus', current_setting('test.n');
  END IF;
  RAISE NOTICE 'CONTRATS invitations : % controles verts', current_setting('test.n');
END $fin$;

ROLLBACK;
