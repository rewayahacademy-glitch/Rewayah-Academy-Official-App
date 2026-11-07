-- INVITATIONS-PERSONNELLES (lot 7, 07/11/2026) : le lien personnel des candidats importes.
-- Migration 20261120000000_invitations_candidats_importes.sql.
--
-- Cas couverts (demandes du garde-cap du 07/11, point 7) :
-- (a) droits et empreintes : outils prives fermes, fonctions publiques a authenticated seul ;
-- (b) refus : sans session, tuteur, direction non super-admin, super-admin en aal1 (42501) ;
--     limite hors bornes (22023) ; nombre attendu change : refus rendu, rien d'ecrit ;
-- (c) l'apercu : les comptes par situation (a inviter, a renvoyer, deja invite, deja inscrit,
--     revoquee, desinscrit, sans adresse), aucune adresse rendue ;
-- (d) l'envoi : une invitation et son e-mail invitation_enseignant par personne, cle
--     invitation_candidat_importe:<reponse>:<n>, code de l'e-mail = code de l'invitation ; une
--     adresse une fois ; la limite ; aucun doublon au second appel ;
-- (e) l'arrivee par le code : inscription acceptee lien public FERME, invitation consommee,
--     reponse importee rattachee par courriel, brouillon de la salle 1 pre-rempli ;
-- (f) le renvoi apres expiration : nouveau code, cle :2 ;
-- (g) le plafond propre : 300 sur 24 h glissantes, refus rendu « plafond_atteint » ;
-- (h) revoquer annule l'e-mail en attente de ce lot ;
-- (i) « Copier le lien » : adresse requise sans adresse importee, invitation reutilisee, aucun
--     e-mail, journal sans code ni adresse ; compte existant refuse ;
-- (j) journal : des comptes, jamais une adresse ni un code.
-- Chaque controle leve 'INV-CAND ROUGE : ...' s'il echoue. A rejouer sur une base NEUVE
-- (stub_auth puis toutes les migrations) ; le scenario annule tout a la fin.
-- Donnees inventees, adresses en test.invalid.
BEGIN;

CREATE FUNCTION pg_temp.qui(p_id uuid, p_role text, p_aal text DEFAULT 'aal1') RETURNS void
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
    RAISE EXCEPTION 'INV-CAND ROUGE : %', p_label;
  END IF;
  RAISE NOTICE 'OK %', p_label;
END $$;

CREATE FUNCTION pg_temp.garde(p_nom text, p_valeur jsonb) RETURNS void
LANGUAGE sql AS $$
  SELECT pg_catalog.set_config('test.' || p_nom, coalesce(p_valeur::text, 'null'), true);
$$;
CREATE FUNCTION pg_temp.lu(p_nom text) RETURNS jsonb
LANGUAGE sql AS $$
  SELECT pg_catalog.current_setting('test.' || p_nom)::jsonb;
$$;

CREATE FUNCTION pg_temp.en(p_id uuid, p_role text, p_sql text, p_aal text DEFAULT 'aal1') RETURNS jsonb
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
                                 p_db_role text DEFAULT 'authenticated', p_aal text DEFAULT 'aal1') RETURNS void
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
  IF v_passe THEN
    RAISE EXCEPTION 'INV-CAND ROUGE : % (aucun refus)', p_label;
  END IF;
  IF v_code <> p_code THEN
    RAISE EXCEPTION 'INV-CAND ROUGE : % (code % au lieu de % : %)', p_label, v_code, p_code, v_msg;
  END IF;
  RAISE NOTICE 'OK %', p_label;
END $$;

CREATE FUNCTION pg_temp.p(p_n text) RETURNS uuid
LANGUAGE sql IMMUTABLE AS $$ SELECT ('c7a10000-0000-4000-8000-0000000000' || p_n)::uuid $$;
CREATE FUNCTION pg_temp.r(p_n text) RETURNS uuid
LANGUAGE sql IMMUTABLE AS $$ SELECT ('c7a17777-0000-4000-8000-0000000000' || p_n)::uuid $$;

-- Ce que le lot peut ecrire.
CREATE FUNCTION pg_temp.ecritures() RETURNS jsonb
LANGUAGE sql AS $$
  SELECT pg_catalog.jsonb_build_object(
    'invitations', (SELECT count(*) FROM public.invitations_enseignant),
    'file', (SELECT count(*) FROM public.courriels_sortants));
$$;
-- La ligne de file d'une reponse (cle :n).
CREATE FUNCTION pg_temp.file(p_reponse text, p_n integer) RETURNS public.courriels_sortants
LANGUAGE sql AS $$
  SELECT s FROM public.courriels_sortants s
   WHERE s.cle_idempotence = 'invitation_candidat_importe:' || pg_temp.r(p_reponse)::text || ':' || p_n::text;
$$;

GRANT EXECUTE ON FUNCTION pg_temp.qui(uuid, text, text), pg_temp.vrai(boolean, text), pg_temp.p(text),
  pg_temp.r(text) TO authenticated, anon;

-- Les appels de la super-admin, en aal2.
CREATE FUNCTION pg_temp.sa(p_sql text) RETURNS jsonb
LANGUAGE sql AS $$ SELECT pg_temp.en(pg_temp.p('a1'), 'admin', p_sql, 'aal2') $$;

-- ------------------------------------------------------------
-- Fixtures (donnees inventees)
-- ------------------------------------------------------------
-- a1 super-admin (homme), d1 direction non super-admin, b1 tuteur.
INSERT INTO auth.users (id, email, email_confirmed_at)
SELECT pg_temp.p(s), 'inv-cand-' || s || '@test.invalid', pg_catalog.clock_timestamp()
FROM unnest(ARRAY['a1', 'd1', 'b1', 'e3']) AS s;
INSERT INTO public.households (id, timezone) VALUES ('c7a1ffff-ffff-4fff-8fff-000000000001', 'Europe/Paris');
INSERT INTO public.profiles (id, immutable_id, role, household_id, first_name, last_name, account_status, gender)
VALUES
 (pg_temp.p('a1'), 'C7A1-ADM-0001', 'admin', NULL, 'Super', 'Admin', 'active', 'male'),
 (pg_temp.p('d1'), 'C7A1-ADM-0002', 'admin', NULL, 'Direction', 'Simple', 'active', 'male'),
 (pg_temp.p('b1'), 'C7A1-TUT-0001', 'guardian', 'c7a1ffff-ffff-4fff-8fff-000000000001', 'Tuteur', 'Essai',
  'active', 'female'),
 -- e3 : un compte deja inscrit a l'adresse de la reponse 03.
 (pg_temp.p('e3'), 'C7A1-ENS-0003', 'teacher', NULL, 'Deja', 'Inscrit', 'provisional_active', 'male');
UPDATE auth.users SET email = 'Inv-Rep03@Test.Invalid' WHERE id = pg_temp.p('e3');
INSERT INTO private.super_admin_kyc (profile_id) VALUES (pg_temp.p('a1'));
INSERT INTO public.app_config (key, value) VALUES ('kyc_exception_super_admin', 'true'::jsonb)
ON CONFLICT (key) DO UPDATE SET value = excluded.value;

INSERT INTO public.formulaires_lots (id, cle, auteur_id, classeur, onglet, empreinte, compteurs, rapport)
VALUES ('c7a15555-0000-4000-8000-000000000001', 'cle-lot-inv-cand-0001', pg_temp.p('a1'),
        'Candidature enseignants (réponses)', 'Réponses au formulaire 1', md5('lot'), '{}', '{}');

-- 02 homme a inviter (reponses utiles au pre-remplissage) ; 01 meme adresse, plus ancienne, en
-- historique (l'import garde la plus recente, CAND-Q16) ; 03 deja inscrit ; 04 sans adresse ;
-- 05 desinscrit ; 07 femme a inviter (la super-admin voit les deux cotes) ; 08 invitation revoquee ;
-- 09 invitation active ; 10 invitation expiree (a renvoyer) ; 12 et 13 deux « personnes distinctes »
-- au meme courriel (choix de la direction) : une seule invitation pour l'adresse.
INSERT INTO public.formulaires_reponses (id, reference_source, lot_id, recue_le, genre, nom_affiche, courriel,
                                         telephone, reponses, contenu_empreinte)
VALUES
 (pg_temp.r('01'), 'inv|r|01', 'c7a15555-0000-4000-8000-000000000001', '2026-10-14 09:30+00', 'male',
  'Reponse Un', 'inv-rep01@test.invalid', NULL, '{}', md5('01')),
 (pg_temp.r('02'), 'inv|r|02', 'c7a15555-0000-4000-8000-000000000001', '2026-10-16 09:30+00', 'male',
  'Reponse Deux', 'inv-rep01@test.invalid', NULL,
  '{"ijazaPresentable": "oui", "debutPossible": "immediat"}', md5('02')),
 (pg_temp.r('03'), 'inv|r|03', 'c7a15555-0000-4000-8000-000000000001', '2026-10-14 10:00+00', 'male',
  'Reponse Trois', 'inv-rep03@test.invalid', NULL, '{}', md5('03')),
 (pg_temp.r('04'), 'inv|r|04', 'c7a15555-0000-4000-8000-000000000001', '2026-10-14 11:00+00', 'male',
  'Reponse Quatre', NULL, '+33600000004', '{}', md5('04')),
 (pg_temp.r('05'), 'inv|r|05', 'c7a15555-0000-4000-8000-000000000001', '2026-10-14 12:00+00', 'male',
  'Reponse Cinq', 'inv-rep05@test.invalid', NULL, '{}', md5('05')),
 (pg_temp.r('07'), 'inv|r|07', 'c7a15555-0000-4000-8000-000000000001', '2026-10-15 08:00+00', 'female',
  'Reponse Sept', 'inv-rep07@test.invalid', NULL, '{}', md5('07')),
 (pg_temp.r('08'), 'inv|r|08', 'c7a15555-0000-4000-8000-000000000001', '2026-10-15 09:00+00', 'male',
  'Reponse Huit', 'inv-rep08@test.invalid', NULL, '{}', md5('08')),
 (pg_temp.r('09'), 'inv|r|09', 'c7a15555-0000-4000-8000-000000000001', '2026-10-15 10:00+00', 'male',
  'Reponse Neuf', 'inv-rep09@test.invalid', NULL, '{}', md5('09')),
 (pg_temp.r('10'), 'inv|r|10', 'c7a15555-0000-4000-8000-000000000001', '2026-10-13 10:00+00', 'male',
  'Reponse Dix', 'inv-rep10@test.invalid', NULL, '{}', md5('10')),
 (pg_temp.r('12'), 'inv|r|12', 'c7a15555-0000-4000-8000-000000000001', '2026-10-18 10:00+00', 'male',
  'Reponse Douze', 'inv-rep12@test.invalid', NULL, '{}', md5('12')),
 (pg_temp.r('13'), 'inv|r|13', 'c7a15555-0000-4000-8000-000000000001', '2026-10-18 11:00+00', 'male',
  'Reponse Treize', 'inv-rep12@test.invalid', NULL, '{}', md5('13'));
UPDATE public.formulaires_reponses SET etat = 'historique', remplacee_par = pg_temp.r('02')
 WHERE id = pg_temp.r('01');
INSERT INTO public.courriel_desinscriptions (adresse, categorie) VALUES ('inv-rep05@test.invalid', 'recrutement');
INSERT INTO public.invitations_enseignant (code, email, cree_par, cree_le, expire_le, revoquee_le, revoquee_par)
VALUES
 ('AAAA-BBBB-CCC8', 'inv-rep08@test.invalid', pg_temp.p('a1'), now() - interval '2 days', now() + interval '12 days',
  now() - interval '1 day', pg_temp.p('a1')),
 ('AAAA-BBBB-CCC9', 'inv-rep09@test.invalid', pg_temp.p('a1'), now() - interval '2 days', now() + interval '12 days',
  NULL, NULL),
 ('AAAA-BBBB-CCCA', 'inv-rep10@test.invalid', pg_temp.p('a1'), now() - interval '20 days', now() - interval '6 days',
  NULL, NULL);

-- Le lien public reste FERME : seul le code ouvre l'inscription.
SELECT pg_temp.vrai(
  coalesce((SELECT value = 'true'::jsonb FROM public.app_config
             WHERE key = 'candidatures.inscription_publique_ouverte'), false) = false,
  'fixtures : le lien public d''inscription est ferme');

-- ------------------------------------------------------------
-- (a) Droits
-- ------------------------------------------------------------
SELECT pg_temp.vrai(
  NOT has_function_privilege('authenticated', 'private.inv_cand_garde()', 'EXECUTE')
  AND NOT has_function_privilege('authenticated', 'private.inv_cand_personnes()', 'EXECUTE')
  AND NOT has_function_privilege('authenticated', 'private.inv_cand_envoyes_24h()', 'EXECUTE')
  AND NOT has_function_privilege('authenticated', 'private.inv_cand_emettre(text,uuid)', 'EXECUTE')
  AND has_function_privilege('authenticated', 'public.apercu_invitations_candidats_importes()', 'EXECUTE')
  AND has_function_privilege('authenticated', 'public.envoyer_invitations_candidats_importes(integer,integer)', 'EXECUTE')
  AND has_function_privilege('authenticated', 'public.lien_invitation_candidat_importe(uuid,text)', 'EXECUTE')
  AND NOT has_function_privilege('anon', 'public.apercu_invitations_candidats_importes()', 'EXECUTE')
  AND NOT has_function_privilege('anon', 'public.envoyer_invitations_candidats_importes(integer,integer)', 'EXECUTE')
  AND NOT has_function_privilege('anon', 'public.lien_invitation_candidat_importe(uuid,text)', 'EXECUTE')
  AND NOT has_function_privilege('agent_ro', 'public.envoyer_invitations_candidats_importes(integer,integer)', 'EXECUTE'),
  '(a) outils prives fermes ; les trois fonctions a authenticated seul (ni anon ni agent_ro)');

-- ------------------------------------------------------------
-- (b) Refus
-- ------------------------------------------------------------
SELECT pg_temp.garde('avant_refus', pg_temp.ecritures());
SELECT pg_temp.refus_en(NULL, NULL, $$SELECT public.envoyer_invitations_candidats_importes(3, 10)$$,
  '42501', '(b) sans session : refus', 'authenticated');
SELECT pg_temp.refus_en(NULL, NULL, $$SELECT public.envoyer_invitations_candidats_importes(3, 10)$$,
  '42501', '(b) anon : aucun droit d''execution', 'anon');
SELECT pg_temp.refus_en(pg_temp.p('b1'), 'guardian', $$SELECT public.apercu_invitations_candidats_importes()$$,
  '42501', '(b) un tuteur : refus', 'authenticated', 'aal2');
SELECT pg_temp.refus_en(pg_temp.p('d1'), 'admin', $$SELECT public.envoyer_invitations_candidats_importes(3, 10)$$,
  '42501', '(b) une direction non super-admin, meme en aal2 : refus', 'authenticated', 'aal2');
SELECT pg_temp.refus_en(pg_temp.p('d1'), 'admin', $$SELECT public.lien_invitation_candidat_importe(pg_temp.r('04'), 'x@test.invalid')$$,
  '42501', '(b) « Copier le lien » : direction non super-admin refusee', 'authenticated', 'aal2');
SELECT pg_temp.refus_en(pg_temp.p('a1'), 'admin', $$SELECT public.envoyer_invitations_candidats_importes(3, 10)$$,
  '42501', '(b) la super-admin en aal1 : refus (double verification)', 'authenticated', 'aal1');
SELECT pg_temp.refus_en(pg_temp.p('a1'), 'admin', $$SELECT public.apercu_invitations_candidats_importes()$$,
  '42501', '(b) l''apercu en aal1 : refus', 'authenticated', 'aal1');
SELECT pg_temp.refus_en(pg_temp.p('a1'), 'admin', $$SELECT public.envoyer_invitations_candidats_importes(3, 0)$$,
  '22023', '(b) limite 0 : 22023', 'authenticated', 'aal2');
SELECT pg_temp.refus_en(pg_temp.p('a1'), 'admin', $$SELECT public.envoyer_invitations_candidats_importes(3, 201)$$,
  '22023', '(b) limite 201 : 22023 (200 au plus par geste)', 'authenticated', 'aal2');
SELECT pg_temp.vrai(
  pg_temp.sa($$SELECT public.envoyer_invitations_candidats_importes(2, 10)$$)
    = '{"erreur": "nombre_change", "eligibles": 4}'::jsonb
  AND pg_temp.ecritures() = pg_temp.lu('avant_refus'),
  '(b) un nombre attendu qui a change : refus rendu, rien d''ecrit');

-- ------------------------------------------------------------
-- (c) L'apercu
-- ------------------------------------------------------------
SELECT pg_temp.garde('apercu1', pg_temp.sa($$SELECT public.apercu_invitations_candidats_importes()$$));
SELECT pg_temp.vrai(
  pg_temp.lu('apercu1') = '{"aInviter": 3, "aRenvoyer": 1, "dejaInvites": 1, "dejaInscrits": 1, "revoquees": 1,
                            "desinscrits": 1, "sansAdresse": 1, "plafondJour": 300, "envoyes24h": 0,
                            "resteAujourdhui": 300}'::jsonb
  AND pg_temp.lu('apercu1')::text NOT LIKE '%@%',
  '(c) apercu : 3 a inviter (02 seule active de son adresse ; une adresse pour 12 et 13), 1 a renvoyer, 1 deja invitee, 1 deja inscrite, 1 revoquee, 1 desinscrite, 1 sans adresse ; aucune adresse rendue');

-- ------------------------------------------------------------
-- (d) L'envoi
-- ------------------------------------------------------------
SELECT pg_temp.garde('envoi1', pg_temp.sa($$SELECT public.envoyer_invitations_candidats_importes(4, 2)$$));
SELECT pg_temp.vrai(
  pg_temp.lu('envoi1') = '{"misEnFile": 2, "restants": 2, "resteAujourdhui": 298}'::jsonb
  -- Les deux plus anciennes : 10 (13/10) puis 07 (15/10).
  AND (pg_temp.file('10', 1)).id IS NOT NULL AND (pg_temp.file('07', 1)).id IS NOT NULL
  AND (pg_temp.file('02', 1)).id IS NULL AND (pg_temp.file('12', 1)).id IS NULL,
  '(d) limite 2 : les deux plus anciennes (10 a renvoyer, 07) ; il en reste 2 ; reste du jour 298');
SELECT pg_temp.vrai(
  (SELECT s.modele = 'invitation_enseignant' AND s.categorie = 'recrutement' AND s.origine = 'manuel'
          AND s.cree_par = pg_temp.p('a1') AND s.statut = 'en_attente'
          AND s.destinataire_adresse = 'inv-rep07@test.invalid'
          AND (s.donnees ->> 'code') = i.code AND (s.donnees ? 'expire_le')
          AND i.cree_par = pg_temp.p('a1') AND i.utilisee_le IS NULL AND i.revoquee_le IS NULL
          AND i.expire_le > now() + interval '13 days'
     FROM pg_temp.file('07', 1) s JOIN public.invitations_enseignant i ON i.email = s.destinataire_adresse),
  '(d) la ligne de 07 : modele invitation_enseignant existant, categorie recrutement, son code est celui d''une invitation neuve de 14 jours');
SELECT pg_temp.garde('envoi2', pg_temp.sa($$SELECT public.envoyer_invitations_candidats_importes(2, 200)$$));
SELECT pg_temp.garde('envoi3', pg_temp.sa($$SELECT public.envoyer_invitations_candidats_importes(0, 200)$$));
SELECT pg_temp.vrai(
  pg_temp.lu('envoi2') = '{"misEnFile": 2, "restants": 0, "resteAujourdhui": 296}'::jsonb
  AND pg_temp.lu('envoi3') = '{"misEnFile": 0, "restants": 0, "resteAujourdhui": 296}'::jsonb
  AND (SELECT count(*) FROM public.courriels_sortants
        WHERE cle_idempotence LIKE 'invitation\_candidat\_importe:%') = 4
  AND (SELECT count(*) FROM public.courriels_sortants WHERE destinataire_adresse = 'inv-rep01@test.invalid') = 1
  AND (pg_temp.file('02', 1)).id IS NOT NULL AND (pg_temp.file('01', 1)).id IS NULL
  AND (SELECT count(*) FROM public.courriels_sortants WHERE destinataire_adresse = 'inv-rep12@test.invalid') = 1
  AND (SELECT count(*) FROM public.courriels_sortants
        WHERE destinataire_adresse IN ('inv-rep03@test.invalid', 'inv-rep05@test.invalid', 'inv-rep08@test.invalid',
                                       'inv-rep09@test.invalid')) = 0
  AND (SELECT count(*) FROM public.invitations_enseignant WHERE email = 'inv-rep09@test.invalid') = 1,
  '(d) 02 et l''adresse de 12-13 (une seule fois) partent au geste suivant ; puis plus rien : aucun doublon, ni deja inscrit, ni desinscrit, ni revoquee, ni deja invitee');

-- ------------------------------------------------------------
-- (e) L'arrivee par le code : reconnue et pre-remplie, lien public ferme
-- ------------------------------------------------------------
INSERT INTO auth.users (id, email, email_confirmed_at)
VALUES (pg_temp.p('c1'), 'inv-rep01@test.invalid', clock_timestamp());
SELECT pg_temp.garde('arrivee', pg_temp.en(pg_temp.p('c1'), NULL, pg_catalog.format(
  $q$SELECT public.inscrire_candidat(%L, 'Essai', 'Invite', 'male', '+966500000701', 'fr', '2026-11-v1')$q$,
  (pg_temp.file('02', 1)).donnees ->> 'code')));
SELECT pg_temp.vrai(
  pg_temp.lu('arrivee') = '{"resultat": "acceptee"}'::jsonb
  AND (SELECT i.utilisee_par = pg_temp.p('c1') FROM public.invitations_enseignant i
        WHERE i.code = (pg_temp.file('02', 1)).donnees ->> 'code')
  AND (SELECT r.candidature_id = c.id AND r.rattachement = 'courriel'
              AND r.prerempli_champs = ARRAY['debutPossible', 'ijazaPresentable']
         FROM public.formulaires_reponses r, public.candidatures c
        WHERE r.id = pg_temp.r('02') AND c.profile_id = pg_temp.p('c1'))
  AND (SELECT b.brouillon AND b.reponses @> '{"ijazaPresentable": "oui", "debutPossible": "immediat"}'::jsonb
         FROM public.candidature_reponses b JOIN public.candidatures c ON c.id = b.candidature_id
        WHERE c.profile_id = pg_temp.p('c1'))
  AND (SELECT r.candidature_id IS NULL FROM public.formulaires_reponses r WHERE r.id = pg_temp.r('01')),
  '(e) avec le code (lien public ferme) : inscription acceptee, invitation consommee, reponse importee rattachee par courriel, brouillon de la salle 1 pre-rempli');
SELECT pg_temp.vrai(
  (pg_temp.sa($$SELECT public.apercu_invitations_candidats_importes()$$) ->> 'aInviter')::int = 0
  AND (pg_temp.sa($$SELECT public.apercu_invitations_candidats_importes()$$) ->> 'aRenvoyer')::int = 0,
  '(e) la personne inscrite n''est plus a inviter');

-- ------------------------------------------------------------
-- (f) Le renvoi apres expiration
-- ------------------------------------------------------------
UPDATE public.invitations_enseignant
   SET cree_le = now() - interval '20 days', expire_le = now() - interval '6 days'
 WHERE email = 'inv-rep07@test.invalid';
SELECT pg_temp.vrai(
  (pg_temp.sa($$SELECT public.apercu_invitations_candidats_importes()$$) ->> 'aRenvoyer')::int = 1,
  '(f) un code expire, sans compte : la personne redevient « a renvoyer »');
SELECT pg_temp.garde('renvoi', pg_temp.sa($$SELECT public.envoyer_invitations_candidats_importes(1, 10)$$));
SELECT pg_temp.vrai(
  (pg_temp.lu('renvoi') ->> 'misEnFile')::int = 1
  AND (pg_temp.file('07', 2)).id IS NOT NULL
  AND (pg_temp.file('07', 2)).donnees ->> 'code' <> (pg_temp.file('07', 1)).donnees ->> 'code'
  AND (SELECT count(*) FROM public.invitations_enseignant
        WHERE email = 'inv-rep07@test.invalid' AND expire_le > now()) = 1,
  '(f) le renvoi : un nouveau code, cle :2, une seule invitation active');
-- Limite connue, inchangee par ce lot : deux « personnes distinctes » au meme courriel (12, 13)
-- recoivent une invitation ; l'inscription est acceptee mais n'est rattachee a aucune des deux
-- (jamais un choix entre deux personnes, CAND-L3) : la direction relie a la main.
INSERT INTO auth.users (id, email, email_confirmed_at)
VALUES (pg_temp.p('c2'), 'inv-rep12@test.invalid', clock_timestamp());
SELECT pg_temp.vrai(
  pg_temp.en(pg_temp.p('c2'), NULL, pg_catalog.format(
    $q$SELECT public.inscrire_candidat(%L, 'Essai', 'Distincte', 'male', '+966500000712', 'fr', '2026-11-v1')$q$,
    (pg_temp.file('12', 1)).donnees ->> 'code')) = '{"resultat": "acceptee"}'::jsonb
  AND (SELECT bool_and(r.candidature_id IS NULL) FROM public.formulaires_reponses r
        WHERE r.id IN (pg_temp.r('12'), pg_temp.r('13'))),
  '(f) deux personnes distinctes au meme courriel : inscription acceptee par le code, aucun rattachement automatique (regle CAND-L3 inchangee)');

-- ------------------------------------------------------------
-- (g) Le plafond propre : 300 sur 24 heures glissantes
-- ------------------------------------------------------------
INSERT INTO public.formulaires_reponses (id, reference_source, lot_id, recue_le, genre, nom_affiche, courriel,
                                         reponses, contenu_empreinte)
VALUES (pg_temp.r('11'), 'inv|r|11', 'c7a15555-0000-4000-8000-000000000001', '2026-10-17 10:00+00', 'male',
        'Reponse Onze', 'inv-rep11@test.invalid', '{}', md5('11'));
-- 295 envois de ce lot dans les 24 heures (5 deja faits) : il en reste 0.
INSERT INTO public.courriels_sortants (categorie, modele, destinataire_adresse, donnees, origine, cle_idempotence)
SELECT 'recrutement', 'invitation_enseignant', 'plafond-' || g || '@test.invalid', '{}', 'manuel',
       'invitation_candidat_importe:plafond:' || g
  FROM generate_series(1, 295) g;
-- Un envoi de ce lot d'il y a plus de 24 heures ne compte plus.
INSERT INTO public.courriels_sortants (categorie, modele, destinataire_adresse, donnees, origine, cle_idempotence, cree_le)
VALUES ('recrutement', 'invitation_enseignant', 'plafond-ancien@test.invalid', '{}', 'manuel',
        'invitation_candidat_importe:plafond:ancien', now() - interval '25 hours');
SELECT pg_temp.garde('avant_plafond', pg_temp.ecritures());
SELECT pg_temp.vrai(
  pg_temp.sa($$SELECT public.envoyer_invitations_candidats_importes(1, 200)$$)
    = '{"erreur": "plafond_atteint", "restants": 1, "resteAujourdhui": 0}'::jsonb
  AND pg_temp.ecritures() = pg_temp.lu('avant_plafond')
  AND (pg_temp.sa($$SELECT public.apercu_invitations_candidats_importes()$$) ->> 'resteAujourdhui')::int = 0
  AND (pg_temp.sa($$SELECT public.apercu_invitations_candidats_importes()$$) ->> 'envoyes24h')::int = 300,
  '(g) 300 envois de ce lot sur 24 h glissantes (l''ancien ne compte pas) : refus rendu « plafond_atteint », rien d''ecrit ; l''apercu dit 0 pour aujourd''hui');
-- Une invitation unitaire de la direction (inviter_enseignant) n'est pas retenue par ce plafond.
-- (Deux instructions : la ligne ecrite pendant l'appel n'est visible qu'a l'instruction suivante.)
SELECT pg_temp.garde('unitaire',
  pg_temp.en(pg_temp.p('a1'), 'admin', $$SELECT public.inviter_enseignant('unitaire@test.invalid')$$, 'aal2'));
SELECT pg_temp.vrai(
  pg_temp.lu('unitaire') ->> 'statut' = 'creee'
  AND EXISTS (SELECT 1 FROM public.courriels_sortants WHERE destinataire_adresse = 'unitaire@test.invalid'
                AND cle_idempotence LIKE 'invitation\_enseignant:%'),
  '(g) le plafond ne vaut que pour ce lot : une invitation unitaire de la direction part toujours');

-- ------------------------------------------------------------
-- (h) Revoquer annule l'e-mail en attente de ce lot
-- ------------------------------------------------------------
SELECT pg_temp.en(pg_temp.p('a1'), 'admin', pg_catalog.format(
  $q$SELECT pg_catalog.to_jsonb(public.revoquer_invitation_enseignant(%L))$q$,
  (pg_temp.file('07', 2)).donnees ->> 'code'), 'aal2');
SELECT pg_temp.vrai(
  (pg_temp.file('07', 2)).statut = 'annule'
  AND (pg_temp.file('10', 1)).statut = 'en_attente',
  '(h) revoquer une invitation de ce lot annule son e-mail en attente, et seulement le sien');

-- ------------------------------------------------------------
-- (i) « Copier le lien »
-- ------------------------------------------------------------
SELECT pg_temp.garde('avant_lien', pg_temp.ecritures());
SELECT pg_temp.vrai(
  pg_temp.sa($$SELECT public.lien_invitation_candidat_importe(pg_temp.r('04'))$$) = '{"statut": "adresse_requise"}'::jsonb
  AND pg_temp.sa($$SELECT public.lien_invitation_candidat_importe(pg_temp.r('04'), 'pas une adresse')$$)
        = '{"statut": "email_invalide"}'::jsonb
  AND pg_temp.sa($$SELECT public.lien_invitation_candidat_importe(pg_temp.r('03'))$$) = '{"statut": "deja_inscrit"}'::jsonb
  AND pg_temp.sa($$SELECT public.lien_invitation_candidat_importe(pg_temp.r('05'))$$) = '{"statut": "desinscrit"}'::jsonb
  AND pg_temp.sa($$SELECT public.lien_invitation_candidat_importe(pg_temp.r('02'))$$) = '{"statut": "reponse_introuvable"}'::jsonb
  AND pg_temp.ecritures() = pg_temp.lu('avant_lien'),
  '(i) sans adresse importee ni saisie : adresse requise ; adresse invalide, deja inscrit, desinscrit, reponse rattachee (02) : refus rendus, rien d''ecrit');
SELECT pg_temp.garde('lien1', pg_temp.sa(
  $$SELECT public.lien_invitation_candidat_importe(pg_temp.r('04'), ' Saisie-Quatre@Test.Invalid ')$$));
SELECT pg_temp.garde('lien2', pg_temp.sa(
  $$SELECT public.lien_invitation_candidat_importe(pg_temp.r('04'), 'saisie-quatre@test.invalid')$$));
SELECT pg_temp.vrai(
  pg_temp.lu('lien1') ->> 'statut' = 'pret'
  AND pg_temp.lu('lien1') ->> 'code' ~ '^[A-HJKMNP-Z2-9]{4}-[A-HJKMNP-Z2-9]{4}-[A-HJKMNP-Z2-9]{4}$'
  AND pg_temp.lu('lien2') ->> 'code' = pg_temp.lu('lien1') ->> 'code'
  AND (SELECT count(*) FROM public.invitations_enseignant WHERE email = 'saisie-quatre@test.invalid') = 1
  AND NOT EXISTS (SELECT 1 FROM public.courriels_sortants WHERE destinataire_adresse = 'saisie-quatre@test.invalid')
  AND (SELECT count(*) FROM public.audit_logs a WHERE a.action = 'invitation_candidat_lien_copie') = 2
  AND NOT EXISTS (SELECT 1 FROM public.audit_logs a WHERE a.action = 'invitation_candidat_lien_copie'
                    AND (a.payload::text LIKE '%' || (pg_temp.lu('lien1') ->> 'code') || '%'
                         OR a.payload::text LIKE '%@%'))
  AND (SELECT bool_and(a.payload ->> 'reponse' = pg_temp.r('04')::text AND a.actor = pg_temp.p('a1'))
         FROM public.audit_logs a WHERE a.action = 'invitation_candidat_lien_copie'),
  '(i) « Copier le lien » : adresse saisie normalisee, une invitation (reutilisee au second geste), aucun e-mail ; journal : qui et quelle reponse, sans code ni adresse');
-- Une adresse importee : son invitation active est reutilisee (10 a la sienne, en file).
SELECT pg_temp.vrai(
  pg_temp.sa($$SELECT public.lien_invitation_candidat_importe(pg_temp.r('10'))$$) ->> 'code'
    = (pg_temp.file('10', 1)).donnees ->> 'code',
  '(i) avec une adresse importee : le lien porte le code deja envoye, pas un second');

-- ------------------------------------------------------------
-- (j) Le journal : des comptes, jamais une adresse ni un code
-- ------------------------------------------------------------
SELECT pg_temp.vrai(
  (SELECT count(*) FROM public.audit_logs WHERE action = 'invitations_candidats_envoi') >= 3
  AND (SELECT count(*) FROM public.audit_logs WHERE action = 'invitations_candidats_apercu') >= 1
  AND NOT EXISTS (SELECT 1 FROM public.audit_logs
                   WHERE action IN ('invitations_candidats_envoi', 'invitations_candidats_apercu')
                     AND (payload::text LIKE '%@%' OR payload::text ~ '[A-HJKMNP-Z2-9]{4}-[A-HJKMNP-Z2-9]{4}')),
  '(j) journal de l''apercu et des envois : des comptes, aucune adresse, aucun code');

ROLLBACK;
