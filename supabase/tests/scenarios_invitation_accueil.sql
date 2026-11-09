-- INVITATION-ACCUEIL (09/11/2026) : accueil des personnes invitees, profil de la
-- personne invitee dans un foyer, consommation du code APRES la creation du
-- compte. ROUGE sans la migration 20261122600000 (fonctions absentes, ou code
-- consomme a l'autorisation) ; VERT avec. Base NEUVE apres toutes les
-- migrations ; tout est annule a la fin. Donnees fictives (@test.invalid).
BEGIN;
CREATE FUNCTION pg_temp.qui(p_id uuid, p_role text) RETURNS void
LANGUAGE plpgsql AS $$
BEGIN
  PERFORM pg_catalog.set_config('request.jwt.claim.sub', coalesce(p_id::text, ''), true);
  PERFORM pg_catalog.set_config('request.jwt.claims', pg_catalog.json_build_object(
    'sub', p_id, 'role', 'authenticated', 'aal', 'aal1',
    'app_metadata', CASE WHEN p_role IS NULL THEN pg_catalog.json_build_object()
                         ELSE pg_catalog.json_build_object('role', p_role) END)::text, true);
END $$;
CREATE FUNCTION pg_temp.vrai(p_condition boolean, p_label text) RETURNS void
LANGUAGE plpgsql AS $$
BEGIN
  IF p_condition IS NOT TRUE THEN RAISE EXCEPTION 'INVITATION-ACCUEIL ROUGE : %', p_label; END IF;
  RAISE NOTICE 'OK %', p_label;
END $$;
CREATE FUNCTION pg_temp.p(p_n text) RETURNS uuid
LANGUAGE sql IMMUTABLE AS $$ SELECT ('ac900000-0000-4000-8000-0000000000' || p_n)::uuid $$;
-- Appelle une fonction de l'accueil en `authenticated`, sous l'identite donnee.
CREATE FUNCTION pg_temp.accueil(p_id uuid) RETURNS jsonb
LANGUAGE plpgsql AS $$
DECLARE v jsonb;
BEGIN
  PERFORM pg_temp.qui(p_id, NULL);
  EXECUTE 'SET LOCAL ROLE authenticated';
  v := public.mon_invitation_accueil();
  EXECUTE 'RESET ROLE';
  RETURN v;
END $$;
CREATE FUNCTION pg_temp.inscrire(p_id uuid, p_prenom text, p_nom text, p_genre public.gender) RETURNS jsonb
LANGUAGE plpgsql AS $$
DECLARE v jsonb;
BEGIN
  PERFORM pg_temp.qui(p_id, NULL);
  EXECUTE 'SET LOCAL ROLE authenticated';
  v := public.inscrire_conjoint_invite(p_prenom, p_nom, p_genre);
  EXECUTE 'RESET ROLE';
  RETURN v;
END $$;

-- 01 titulaire du foyer (invite) ; 02 invitee au foyer, sans profil ;
-- 03 sans invitation, sans profil ; 04 invitee au foyer, adresse NON confirmee ;
-- 05 invite enseignant, sans profil ; 06 invite comptable, sans profil ;
-- 07 direction ; 08 invitee dont l'invitation est echue.
SET LOCAL session_replication_role = replica;
INSERT INTO auth.users (id, email, email_confirmed_at) VALUES
  (pg_temp.p('01'), 'acc-01@test.invalid', now()),
  (pg_temp.p('02'), 'acc-02@test.invalid', now()),
  (pg_temp.p('03'), 'acc-03@test.invalid', now()),
  (pg_temp.p('04'), 'acc-04@test.invalid', NULL),
  (pg_temp.p('05'), 'acc-05@test.invalid', now()),
  (pg_temp.p('06'), 'acc-06@test.invalid', now()),
  (pg_temp.p('07'), 'acc-07@test.invalid', now()),
  (pg_temp.p('08'), 'acc-08@test.invalid', now());
INSERT INTO public.households (id, timezone, status) VALUES
  (pg_temp.p('90'), 'Europe/Paris', 'active'),
  (pg_temp.p('91'), 'Europe/Paris', 'active'),
  (pg_temp.p('92'), 'Europe/Paris', 'active');
INSERT INTO public.profiles (id, immutable_id, role, household_id, first_name, last_name, account_status, gender) VALUES
  (pg_temp.p('01'), 'ACC-01', 'guardian', pg_temp.p('90'), 'Titulaire', 'Essai', 'active', 'male'),
  (pg_temp.p('07'), 'ACC-07', 'admin', NULL, 'Direction', 'Essai', 'active', 'female');
UPDATE public.households SET primary_guardian_id = pg_temp.p('01') WHERE id = pg_temp.p('90');
INSERT INTO public.invitations_foyer (id, foyer_id, email_invite, invite_par, cle_envoi, expire_le) VALUES
  (pg_temp.p('a2'), pg_temp.p('90'), 'acc-02@test.invalid', pg_temp.p('01'), gen_random_uuid(), now() + interval '5 days'),
  (pg_temp.p('a4'), pg_temp.p('91'), 'acc-04@test.invalid', pg_temp.p('01'), gen_random_uuid(), now() + interval '5 days'),
  (pg_temp.p('a8'), pg_temp.p('92'), 'acc-08@test.invalid', pg_temp.p('01'), gen_random_uuid(), now() + interval '5 days');
UPDATE public.invitations_foyer SET expire_le = now() - interval '1 minute', created_at = now() - interval '8 days'
 WHERE id = pg_temp.p('a8');
INSERT INTO public.invitations_enseignant (code, email, cree_par, expire_le)
VALUES ('ACCA-2345-6789', 'acc-05@test.invalid', pg_temp.p('07'), now() + interval '14 days');
INSERT INTO public.invitations_comptable (code, email, cree_par, expire_le)
VALUES ('ACCB-2345-6789', 'acc-06@test.invalid', pg_temp.p('07'), now() + interval '14 days');
SET LOCAL session_replication_role = origin;

-- ---------------------------------------------------------------------------
-- Droits : anon n'atteint rien ; authenticated n'atteint ni l'autorisation ni
-- la consommation (service_role seul).
-- ---------------------------------------------------------------------------
SELECT pg_temp.vrai(NOT has_function_privilege('anon', 'public.mon_invitation_accueil()', 'EXECUTE')
  AND NOT has_function_privilege('anon', 'public.inscrire_conjoint_invite(text,text,public.gender)', 'EXECUTE')
  AND NOT has_function_privilege('anon', 'public.invitation_compte_consommer(text,text,text)', 'EXECUTE')
  AND NOT has_function_privilege('authenticated', 'public.invitation_compte_consommer(text,text,text)', 'EXECUTE')
  AND NOT has_function_privilege('authenticated', 'public.invitation_compte_autoriser(text,text,text)', 'EXECUTE')
  AND has_function_privilege('service_role', 'public.invitation_compte_consommer(text,text,text)', 'EXECUTE')
  AND has_function_privilege('authenticated', 'public.mon_invitation_accueil()', 'EXECUTE')
  AND has_function_privilege('authenticated', 'public.inscrire_conjoint_invite(text,text,public.gender)', 'EXECUTE'),
  'droits : anon refuse, consommation et autorisation au seul service_role');

DO $anon$
BEGIN
  SET LOCAL ROLE anon;
  BEGIN
    PERFORM public.mon_invitation_accueil();
    RAISE EXCEPTION 'INVITATION-ACCUEIL ROUGE : anon lit l''accueil';
  EXCEPTION WHEN insufficient_privilege THEN NULL;
  END;
  BEGIN
    PERFORM public.inscrire_conjoint_invite('A', 'B', 'female');
    RAISE EXCEPTION 'INVITATION-ACCUEIL ROUGE : anon cree un profil';
  EXCEPTION WHEN insufficient_privilege THEN NULL;
  END;
  RESET ROLE;
END $anon$;
SELECT pg_temp.vrai(true, 'anon : accueil et inscription refuses (42501)');

-- ---------------------------------------------------------------------------
-- mon_invitation_accueil
-- ---------------------------------------------------------------------------
SELECT pg_temp.vrai(pg_temp.accueil(pg_temp.p('02')) =
  '{"etat": "invite", "role": "foyer", "prenom_invitant": "Titulaire"}'::jsonb,
  'invitee au foyer : role foyer et prenom de la personne qui invite, rien d''autre');
SELECT pg_temp.vrai(pg_temp.accueil(pg_temp.p('03')) = '{"etat": "aucune"}'::jsonb,
  'session sans invitation : aucune');
SELECT pg_temp.vrai(pg_temp.accueil(pg_temp.p('04')) = '{"etat": "aucune"}'::jsonb,
  'adresse non confirmee : aucune');
SELECT pg_temp.vrai(pg_temp.accueil(pg_temp.p('08')) = '{"etat": "aucune"}'::jsonb,
  'invitation echue : aucune');
SELECT pg_temp.vrai(pg_temp.accueil(pg_temp.p('05')) = '{"etat": "invite", "role": "enseignant"}'::jsonb,
  'invite enseignant : role enseignant');
SELECT pg_temp.vrai(pg_temp.accueil(pg_temp.p('06')) = '{"etat": "invite", "role": "comptable"}'::jsonb,
  'invite comptable : role comptable');
SELECT pg_temp.vrai(pg_temp.accueil(pg_temp.p('01')) = '{"etat": "aucune"}'::jsonb,
  'session qui a deja un profil : aucune');
DO $sans_session$
BEGIN
  PERFORM pg_temp.qui(NULL, NULL);
  SET LOCAL ROLE authenticated;
  BEGIN
    PERFORM public.mon_invitation_accueil();
    RAISE EXCEPTION 'INVITATION-ACCUEIL ROUGE : accueil lu sans session';
  EXCEPTION WHEN insufficient_privilege THEN NULL;
  END;
  RESET ROLE;
END $sans_session$;
SELECT pg_temp.vrai(true, 'sans session : accueil refuse (42501)');

-- ---------------------------------------------------------------------------
-- inscrire_conjoint_invite
-- ---------------------------------------------------------------------------
SELECT pg_temp.vrai(pg_temp.inscrire(pg_temp.p('03'), 'Sans', 'Invitation', 'female') =
  '{"resultat": "aucune_invitation"}'::jsonb, 'session sans invitation : refusee, aucun profil');
SELECT pg_temp.vrai(NOT EXISTS (SELECT 1 FROM public.profiles WHERE id = pg_temp.p('03')),
  'session sans invitation : aucun profil cree');
SELECT pg_temp.vrai(pg_temp.inscrire(pg_temp.p('04'), 'Non', 'Confirmee', 'female') =
  '{"resultat": "non_acceptable"}'::jsonb, 'adresse non confirmee : refusee');
SELECT pg_temp.vrai(pg_temp.inscrire(pg_temp.p('08'), 'Echue', 'Essai', 'female') =
  '{"resultat": "aucune_invitation"}'::jsonb, 'invitation echue : refusee');
SELECT pg_temp.vrai(pg_temp.inscrire(pg_temp.p('05'), 'Invite', 'Enseignant', 'male') =
  '{"resultat": "aucune_invitation"}'::jsonb, 'invite enseignant : pas de profil de foyer');
SELECT pg_temp.vrai(pg_temp.inscrire(pg_temp.p('01'), 'Deja', 'Inscrit', 'male') =
  '{"resultat": "deja_inscrit"}'::jsonb, 'session qui a deja un profil : deja_inscrit');
DO $champs$
BEGIN
  PERFORM pg_temp.inscrire(pg_temp.p('02'), '  ', 'Essai', 'female');
  RAISE EXCEPTION 'INVITATION-ACCUEIL ROUGE : prenom vide accepte';
EXCEPTION WHEN invalid_parameter_value THEN RESET ROLE;
END $champs$;
SELECT pg_temp.vrai(true, 'prenom vide : refuse (22023)');
SELECT pg_temp.vrai(pg_temp.inscrire(pg_temp.p('02'), ' Invitee ', 'Foyer', 'female') =
  '{"resultat": "cree"}'::jsonb, 'invitee au foyer : profil cree');
SELECT pg_temp.vrai(EXISTS (SELECT 1 FROM public.profiles p
    JOIN public.households h ON h.id = p.household_id
   WHERE p.id = pg_temp.p('02')
    AND p.role = 'guardian' AND p.account_status = 'active'
    AND p.first_name = 'Invitee' AND p.last_name = 'Foyer' AND p.gender = 'female'
    AND h.primary_guardian_id = p.id AND h.id <> pg_temp.p('90')
    AND NOT EXISTS (SELECT 1 FROM public.profiles e WHERE e.household_id = h.id AND e.role = 'student')),
  'profil guardian actif, nom nettoye, dans un foyer d''attente vide dont il est titulaire');
SELECT pg_temp.vrai((SELECT statut FROM public.invitations_foyer WHERE id = pg_temp.p('a2')) = 'en_attente',
  'l''invitation n''est pas acceptee par l''inscription');
SELECT pg_temp.vrai(pg_temp.inscrire(pg_temp.p('02'), 'Invitee', 'Foyer', 'female') =
  '{"resultat": "deja_inscrit"}'::jsonb, 'seconde inscription : deja_inscrit');
SELECT pg_temp.vrai(pg_temp.accueil(pg_temp.p('02')) = '{"etat": "aucune"}'::jsonb,
  'profil cree : plus d''accueil');

-- C corrige : avec son profil, l'invitee voit l'invitation a accepter.
DO $c$
DECLARE v jsonb;
BEGIN
  PERFORM pg_temp.qui(pg_temp.p('02'), 'guardian');
  SET LOCAL ROLE authenticated;
  v := public.mon_invitation_en_cours();
  RESET ROLE;
  IF v->>'etat' <> 'a_repondre' THEN
    RAISE EXCEPTION 'INVITATION-ACCUEIL ROUGE : l''invitee ne voit pas l''invitation (%)', v;
  END IF;
END $c$;
SELECT pg_temp.vrai(true, 'avec son profil, l''invitee lit l''invitation « a_repondre »');

-- Et l'accepte : elle passe dans le foyer qui l'invite.
DO $accepte$
DECLARE v jsonb;
BEGIN
  PERFORM pg_temp.qui(pg_temp.p('02'), 'guardian');
  SET LOCAL ROLE authenticated;
  v := public.repondre_invitation_conjoint('accepter', gen_random_uuid());
  RESET ROLE;
  IF v->>'etat' <> 'acceptee'
     OR (SELECT household_id FROM public.profiles WHERE id = pg_temp.p('02')) <> pg_temp.p('90') THEN
    RAISE EXCEPTION 'INVITATION-ACCUEIL ROUGE : l''invitee ne rejoint pas le foyer (%)', v;
  END IF;
END $accepte$;
SELECT pg_temp.vrai(true, 'l''invitee accepte et rejoint le foyer qui l''invite');

-- ---------------------------------------------------------------------------
-- invitation_compte_consommer : le code ne sert qu'apres la creation du compte
-- ---------------------------------------------------------------------------
DO $b$
DECLARE
  v_code text;
BEGIN
  -- Un code connu pour une adresse SANS compte (createUser n'a pas abouti).
  v_code := app_private.emettre_code_invitation_foyer(pg_temp.p('a4'));
  UPDATE auth.users SET email = 'acc-04-autre@test.invalid' WHERE id = pg_temp.p('04');
  UPDATE public.invitations_foyer SET email_invite = 'acc-sans-compte@test.invalid' WHERE id = pg_temp.p('a4');
  IF NOT (public.invitation_compte_autoriser('foyer', v_code, 'acc-sans-compte@test.invalid')->>'autorise')::boolean THEN
    RAISE EXCEPTION 'INVITATION-ACCUEIL ROUGE : le bon code est refuse';
  END IF;
  -- Echec de createUser : la consommation ne trouve aucun compte, rien ne change.
  IF public.invitation_compte_consommer('foyer', v_code, 'acc-sans-compte@test.invalid') THEN
    RAISE EXCEPTION 'INVITATION-ACCUEIL ROUGE : code consomme sans compte';
  END IF;
  IF EXISTS (SELECT 1 FROM app_private.codes_invitation_foyer c
              WHERE c.invitation_id = pg_temp.p('a4') AND c.utilise_le IS NOT NULL) THEN
    RAISE EXCEPTION 'INVITATION-ACCUEIL ROUGE : le code est brule apres un echec de createUser';
  END IF;
  -- Nouvel essai : le code sert toujours.
  IF NOT (public.invitation_compte_autoriser('foyer', v_code, 'acc-sans-compte@test.invalid')->>'autorise')::boolean THEN
    RAISE EXCEPTION 'INVITATION-ACCUEIL ROUGE : le code ne sert plus apres un echec de createUser';
  END IF;
  -- createUser reussit : consomme une fois.
  INSERT INTO auth.users (id, email, email_confirmed_at)
  VALUES (pg_temp.p('09'), 'acc-sans-compte@test.invalid', now());
  IF NOT public.invitation_compte_consommer('foyer', v_code, 'acc-sans-compte@test.invalid')
     OR public.invitation_compte_consommer('foyer', v_code, 'acc-sans-compte@test.invalid') THEN
    RAISE EXCEPTION 'INVITATION-ACCUEIL ROUGE : consommation pas exactement une fois';
  END IF;
  -- Un code faux, un type inconnu, ou un enseignant : rien.
  IF public.invitation_compte_consommer('foyer', 'ZZZZ-ZZZZ-ZZZZ', 'acc-sans-compte@test.invalid')
     OR public.invitation_compte_consommer('autre', v_code, 'acc-sans-compte@test.invalid')
     OR public.invitation_compte_consommer('enseignant', 'ACCA-2345-6789', 'acc-05@test.invalid') THEN
    RAISE EXCEPTION 'INVITATION-ACCUEIL ROUGE : consommation hors foyer et candidat';
  END IF;
END $b$;
SELECT pg_temp.vrai(true, 'code non consomme si createUser echoue ; consomme une fois apres la creation');

ROLLBACK;
