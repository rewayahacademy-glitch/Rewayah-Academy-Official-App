-- I1 « Inviter quelqu'un » (migration 20261105300000) : l'e-mail de
-- l'invitation d'un enseignant, le code normalise (UX-016), et l'envoi des
-- invitations aux familles importees, sur geste de la direction seulement.
-- Chaque garde a un controle de refus. Donnees inventees, adresses en
-- test.invalid. A rejouer apres stub_auth.sql et toutes les migrations.
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
    RAISE EXCEPTION 'ROUGE : % (aucun refus)', p_label USING ERRCODE = 'XX999';
  EXCEPTION WHEN OTHERS THEN
    IF SQLSTATE = 'XX999' THEN RAISE; END IF;
    IF SQLSTATE <> p_code THEN
      RAISE EXCEPTION 'ROUGE : % (code % au lieu de % : %)', p_label, SQLSTATE, p_code, SQLERRM;
    END IF;
  END;
  PERFORM pg_temp.ok(p_label);
END $$;

GRANT EXECUTE ON FUNCTION pg_temp.qui(uuid, text), pg_temp.ok(text), pg_temp.vrai(boolean, text),
  pg_temp.refus(text, text, text) TO authenticated, anon;

-- ------------------------------------------------------------
-- Fixtures
-- ------------------------------------------------------------
INSERT INTO auth.users(id, email) VALUES
 ('11000000-0000-4000-8000-0000000000a1','i1-direction@test.invalid'),
 ('11000000-0000-4000-8000-0000000000b1','i1-enseignant@test.invalid'),
 ('11000000-0000-4000-8000-0000000000c1','i1-candidat@test.invalid'),
 ('11000000-0000-4000-8000-0000000000c2','i1-ancien@test.invalid');
INSERT INTO public.profiles(id, immutable_id, role, household_id, first_name, last_name, account_status, gender) VALUES
 ('11000000-0000-4000-8000-0000000000a1','I1-ADM-0001','admin',NULL,'Direction','Essai','active','female'),
 ('11000000-0000-4000-8000-0000000000b1','I1-ENS-0001','teacher',NULL,'Yusuf','Fictif','provisional_active','male');
-- Une invitation d'avant ce lot, active, sans e-mail.
INSERT INTO public.invitations_enseignant(code, email, cree_par, expire_le) VALUES
 ('ANCN-AAAA-2222','i1-ancien@test.invalid','11000000-0000-4000-8000-0000000000a1', now() + interval '5 days');
-- Trois foyers importes : deux confirmes a inviter, un deja reclame ; plus un
-- foyer en attente de confirmation et un foyer sans autre personne qu'un
-- enseignant (aucun des deux n'apparait).
INSERT INTO private.preinscription_households(id, email_normalise, status, created_at) VALUES
 ('11f00000-0000-4000-8000-000000000001','i1-famille-a@test.invalid','confirmed', now() - interval '3 hours'),
 ('11f00000-0000-4000-8000-000000000002','i1-famille-b@test.invalid','confirmed', now() - interval '2 hours'),
 ('11f00000-0000-4000-8000-000000000003','i1-famille-c@test.invalid','confirmed', now() - interval '1 hour'),
 ('11f00000-0000-4000-8000-000000000004','i1-famille-d@test.invalid','pre_registered', now()),
 ('11f00000-0000-4000-8000-000000000005','i1-enseignant-importe@test.invalid','confirmed', now());
INSERT INTO private.preinscription_persons(household_id, person_kind, first_name, source_row) VALUES
 ('11f00000-0000-4000-8000-000000000001','guardian','Amina',2),
 ('11f00000-0000-4000-8000-000000000001','student','Yanis',3),
 ('11f00000-0000-4000-8000-000000000002','adult','Karim',4),
 ('11f00000-0000-4000-8000-000000000003','guardian','Sara',5),
 ('11f00000-0000-4000-8000-000000000004','guardian','Nora',6),
 ('11f00000-0000-4000-8000-000000000005','teacher','Ilyas',7);
INSERT INTO auth.users(id, email, email_confirmed_at) VALUES
 ('11000000-0000-4000-8000-0000000000f3','i1-famille-c@test.invalid', now());
UPDATE private.preinscription_households
   SET linked_auth_user_id = '11000000-0000-4000-8000-0000000000f3', linked_at = now()
 WHERE id = '11f00000-0000-4000-8000-000000000003';

-- ------------------------------------------------------------
-- 1. Refus : anon, enseignant
-- ------------------------------------------------------------
SELECT pg_temp.qui(NULL, NULL);
SET LOCAL ROLE anon;
SELECT pg_temp.refus($$SELECT public.invitations_familles_importees()$$, '42501', 'anon : liste des familles refusee');
SELECT pg_temp.refus($$SELECT public.envoyer_invitation_famille_importee('11f00000-0000-4000-8000-000000000001')$$, '42501', 'anon : envoi a un foyer refuse');
SELECT pg_temp.refus($$SELECT public.envoyer_invitations_familles_importees(2)$$, '42501', 'anon : envoi a tous refuse');
RESET ROLE;

SELECT pg_temp.qui('11000000-0000-4000-8000-0000000000b1', 'teacher');
SET LOCAL ROLE authenticated;
SELECT pg_temp.refus($$SELECT public.invitations_familles_importees()$$, '42501', 'enseignant : liste des familles refusee');
SELECT pg_temp.refus($$SELECT public.envoyer_invitation_famille_importee('11f00000-0000-4000-8000-000000000001')$$, '42501', 'enseignant : envoi a un foyer refuse');
SELECT pg_temp.refus($$SELECT public.envoyer_invitations_familles_importees(2)$$, '42501', 'enseignant : envoi a tous refuse');
RESET ROLE;
SELECT pg_temp.vrai(NOT EXISTS (SELECT 1 FROM public.courriels_sortants WHERE modele = 'invitation_famille_importee'),
  'apres les refus : aucun e-mail de famille en file');

-- ------------------------------------------------------------
-- 2. L'invitation d'un enseignant part par e-mail
-- ------------------------------------------------------------
SELECT pg_temp.qui('11000000-0000-4000-8000-0000000000a1', 'admin');
SET LOCAL ROLE authenticated;
DO $ens$
DECLARE v jsonb; w jsonb;
BEGIN
  v := public.inviter_enseignant(' I1-Candidat@Test.INVALID ');
  PERFORM pg_temp.vrai(v ->> 'statut' = 'creee' AND (v -> 'courriel_en_file')::boolean,
    'direction : invitation creee, e-mail en file');
  PERFORM pg_catalog.set_config('test.code', v -> 'invitation' ->> 'code', true);
  w := public.inviter_enseignant('i1-candidat@test.invalid');
  PERFORM pg_temp.vrai(w ->> 'statut' = 'deja_invite' AND (w -> 'courriel_en_file')::boolean,
    'direction : deja invite, e-mail deja en file');
  w := public.inviter_enseignant('i1-ancien@test.invalid');
  PERFORM pg_temp.vrai(w ->> 'statut' = 'deja_invite' AND (w -> 'courriel_en_file')::boolean,
    'direction : invitation d''avant le lot, son premier e-mail part');
  -- Les refus metier d'avant restent identiques.
  PERFORM pg_temp.vrai(public.inviter_enseignant('pas-une-adresse') = '{"statut": "email_invalide", "invitation": null}'::jsonb,
    'adresse invalide : reponse inchangee, rien en file');
END $ens$;
RESET ROLE;

SELECT pg_temp.vrai((SELECT count(*) = 1 FROM public.courriels_sortants c
                      WHERE c.modele = 'invitation_enseignant'
                        AND c.destinataire_adresse = 'i1-candidat@test.invalid'
                        AND c.categorie = 'recrutement' AND c.statut = 'en_attente'
                        AND c.origine = 'manuel'
                        AND c.cree_par = '11000000-0000-4000-8000-0000000000a1'
                        AND c.donnees ->> 'code' = current_setting('test.code')
                        AND c.donnees ? 'expire_le'),
  'file : une seule ligne pour le candidat, avec son code et l''echeance');
SELECT pg_temp.vrai((SELECT count(*) = 1 FROM public.courriels_sortants c
                      WHERE c.modele = 'invitation_enseignant'
                        AND c.destinataire_adresse = 'i1-ancien@test.invalid'
                        AND c.donnees ->> 'code' = 'ANCN-AAAA-2222'),
  'file : l''invitation d''avant le lot a une ligne');
SELECT pg_temp.vrai(NOT EXISTS (SELECT 1 FROM public.courriels_sortants c
                                 WHERE c.modele = 'invitation_enseignant' AND c.destinataire_adresse LIKE 'pas-une%'),
  'file : rien pour une adresse invalide');

-- ------------------------------------------------------------
-- 3. UX-016 : le code recopie (casse, espaces, tirets)
-- ------------------------------------------------------------
SELECT pg_temp.qui('11000000-0000-4000-8000-0000000000c1', NULL);
SET LOCAL ROLE authenticated;
SELECT pg_temp.vrai((public.verifier_invitation_enseignant(
    '  ' || pg_catalog.lower(pg_catalog.replace(current_setting('test.code'), '-', ' ')) || ' ') ->> 'resultat') = 'valide',
  'code en minuscules, espaces au lieu des tirets : valide');
SELECT pg_temp.vrai((public.verifier_invitation_enseignant(
    pg_catalog.replace(current_setting('test.code'), '-', '')) ->> 'resultat') = 'valide',
  'code sans tirets : valide');
SELECT pg_temp.vrai((public.verifier_invitation_enseignant('ZZZZ-ZZZZ-ZZZZ') ->> 'resultat') = 'inconnue',
  'code faux : toujours inconnu');
-- La consommation normalise aussi : le code recopie inscrit le candidat.
SELECT pg_temp.vrai(public.inscrire_enseignant_invite(
    pg_catalog.lower(pg_catalog.replace(current_setting('test.code'), '-', ' ')),
    'Hafsa', 'Essai', 'female') ->> 'resultat' = 'consommee',
  'inscription avec le code en minuscules et espaces : consommee');
RESET ROLE;
SELECT pg_temp.vrai((SELECT role = 'teacher' FROM public.profiles WHERE id = '11000000-0000-4000-8000-0000000000c1'),
  'candidat : profil enseignant cree');

-- ------------------------------------------------------------
-- 4. Revoquer annule l'e-mail encore en attente
-- ------------------------------------------------------------
SELECT pg_temp.qui('11000000-0000-4000-8000-0000000000a1', 'admin');
SET LOCAL ROLE authenticated;
SELECT public.revoquer_invitation_enseignant('ancn aaaa 2222');
RESET ROLE;
SELECT pg_temp.vrai((SELECT statut = 'annule' FROM public.courriels_sortants
                      WHERE cle_idempotence = 'invitation_enseignant:'
                        || (SELECT id FROM public.invitations_enseignant WHERE code = 'ANCN-AAAA-2222')::text),
  'revocation (code recopie en minuscules) : l''e-mail en attente est annule');

-- ------------------------------------------------------------
-- 5. Familles importees : la liste, un foyer, puis tous
-- ------------------------------------------------------------
SELECT pg_temp.qui('11000000-0000-4000-8000-0000000000a1', 'admin');
SET LOCAL ROLE authenticated;
DO $fam$
DECLARE v jsonb;
BEGIN
  v := public.invitations_familles_importees();
  PERFORM pg_temp.vrai(pg_catalog.jsonb_array_length(v -> 'foyers') = 3,
    'liste : les trois foyers confirmes avec un eleve ou un adulte (ni en attente, ni enseignant seul)');
  PERFORM pg_temp.vrai((v ->> 'a_envoyer')::int = 2, 'liste : deux foyers a envoyer');
  PERFORM pg_temp.vrai(v -> 'foyers' -> 0 ->> 'email' = 'i1-famille-a@test.invalid'
                       AND (v -> 'foyers' -> 0 ->> 'personnes')::int = 2
                       AND v -> 'foyers' -> 0 ->> 'etat' = 'a_envoyer',
    'liste : le plus ancien d''abord, deux personnes, a envoyer');
  PERFORM pg_temp.vrai(v -> 'foyers' -> 2 ->> 'etat' = 'compte_cree', 'liste : le foyer reclame a son compte');
END $fam$;
RESET ROLE;
-- Rien n'est parti tout seul.
SELECT pg_temp.vrai(NOT EXISTS (SELECT 1 FROM public.courriels_sortants WHERE modele = 'invitation_famille_importee'),
  'lecture de la liste : aucun envoi');
SET LOCAL ROLE authenticated;
DO $fam2$
DECLARE v jsonb;
BEGIN

  PERFORM pg_temp.vrai(public.envoyer_invitation_famille_importee('11f00000-0000-4000-8000-000000000001') ->> 'statut' = 'en_file',
    'un foyer : invitation en file');
  PERFORM pg_temp.vrai(public.envoyer_invitation_famille_importee('11f00000-0000-4000-8000-000000000001') ->> 'statut' = 'deja_en_file',
    'un foyer, second geste : rien de plus');
  PERFORM pg_temp.vrai(public.envoyer_invitation_famille_importee('11f00000-0000-4000-8000-000000000003') ->> 'statut' = 'compte_cree',
    'foyer reclame : rien ne part');
  PERFORM pg_temp.vrai(public.envoyer_invitation_famille_importee('11f00000-0000-4000-8000-000000000004') ->> 'statut' = 'introuvable',
    'foyer non confirme : introuvable');

  -- Envoi a tous : il reste un foyer ; un nombre perime ne fait rien partir.
  v := public.envoyer_invitations_familles_importees(2);
  PERFORM pg_temp.vrai(v ->> 'statut' = 'nombre_change' AND (v ->> 'a_envoyer')::int = 1,
    'envoi a tous avec un nombre perime : refuse, nombre a jour rendu, rien de plus en file');
  v := public.envoyer_invitations_familles_importees(1);
  PERFORM pg_temp.vrai(v ->> 'statut' = 'en_file' AND (v ->> 'envoyees')::int = 1,
    'envoi a tous confirme : un foyer en file');
  v := public.invitations_familles_importees();
  PERFORM pg_temp.vrai((v ->> 'a_envoyer')::int = 0 AND v -> 'foyers' -> 1 ->> 'etat' = 'en_file',
    'liste apres envoi : plus rien a envoyer, foyer en file');
END $fam2$;
RESET ROLE;

SELECT pg_temp.vrai((SELECT count(*) = 1 FROM public.courriels_sortants c
                      WHERE c.modele = 'invitation_famille_importee'
                        AND c.destinataire_adresse = 'i1-famille-a@test.invalid'
                        AND c.categorie = 'inscription' AND c.origine = 'manuel'
                        AND c.cle_idempotence = 'invitation_famille_importee:11f00000-0000-4000-8000-000000000001:1'),
  'file : une ligne pour la famille A, categorie inscription');
SELECT pg_temp.vrai(NOT EXISTS (SELECT 1 FROM public.courriels_sortants c
                                 WHERE c.modele = 'invitation_famille_importee'
                                   AND c.destinataire_adresse IN ('i1-famille-c@test.invalid', 'i1-famille-d@test.invalid',
                                                                  'i1-enseignant-importe@test.invalid')),
  'file : rien pour le foyer reclame, le foyer non confirme ni l''enseignant importe');

-- Un echec d'envoi rouvre le foyer, avec une nouvelle cle.
UPDATE public.courriels_sortants SET statut = 'echec', tentatives = 10
 WHERE cle_idempotence = 'invitation_famille_importee:11f00000-0000-4000-8000-000000000002:1';
SELECT pg_temp.qui('11000000-0000-4000-8000-0000000000a1', 'admin');
SET LOCAL ROLE authenticated;
SELECT pg_temp.vrai((public.invitations_familles_importees() ->> 'a_envoyer')::int = 1,
  'apres un echec : le foyer est de nouveau a envoyer');
SELECT pg_temp.vrai(public.envoyer_invitation_famille_importee('11f00000-0000-4000-8000-000000000002') ->> 'statut' = 'en_file',
  'apres un echec : nouvel envoi en file');
RESET ROLE;
SELECT pg_temp.vrai(EXISTS (SELECT 1 FROM public.courriels_sortants
                             WHERE cle_idempotence = 'invitation_famille_importee:11f00000-0000-4000-8000-000000000002:2'),
  'nouvel envoi : nouvelle cle d''idempotence');

-- ------------------------------------------------------------
-- 6. ACL
-- ------------------------------------------------------------
SELECT pg_temp.vrai(
  NOT has_function_privilege('anon', 'public.invitations_familles_importees()', 'EXECUTE')
  AND NOT has_function_privilege('agent_ro', 'public.envoyer_invitations_familles_importees(integer)', 'EXECUTE')
  AND NOT has_function_privilege('authenticated', 'app_private.i1_envoyer_invitation_famille(uuid)', 'EXECUTE')
  AND NOT has_function_privilege('authenticated', 'app_private.i1_enfiler_invitation_enseignant(uuid)', 'EXECUTE'),
  'ACL : anon, agent_ro et aides privees fermes');

DO $fin$
BEGIN
  IF current_setting('test.n')::int <> 38 THEN
    RAISE EXCEPTION 'ROUGE : % controles executes, 38 attendus', current_setting('test.n');
  END IF;
  RAISE NOTICE 'I1 invitations : % controles verts', current_setting('test.n');
END $fin$;

ROLLBACK;
