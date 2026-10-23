-- COURRIELS-1 (23/10/2026) : file unique des e-mails. Migration 20261023120000.
--   1. une notification privee met un e-mail en file, categorie et alias justes ;
--      rejouer la meme cle n'en ajoute pas ;
--   2. un compte enfant (adresse technique) ne recoit jamais d'e-mail ;
--   3. une invitation au foyer part de la categorie « compte » ;
--   4. categorie non essentielle : jeton de desinscription, desinscription par
--      le jeton (anon), plus rien ensuite ; jeton inconnu : refus sans detail ;
--   5. envoi manuel : refuse a une famille, accepte pour la direction,
--      idempotent sur la cle ; categorie inconnue refusee ;
--   6. le travailleur reserve, consigne un succes, un echec puis l'abandon au
--      cinquieme essai ; la direction relance un echec ;
--   7. droits : aucun client sur la file ni sur les fonctions internes.
-- Tout est annule a la fin.
\o /dev/null
BEGIN;
ALTER TABLE auth.users ADD COLUMN IF NOT EXISTS raw_app_meta_data jsonb NOT NULL DEFAULT '{}'::jsonb;

CREATE FUNCTION pg_temp.qui(p_id uuid, p_role text, p_aal text DEFAULT 'aal2') RETURNS void LANGUAGE plpgsql AS $$
DECLARE v_jwt text := pg_catalog.json_build_object('aal', p_aal, 'app_metadata',
                        pg_catalog.json_build_object('role', p_role))::text;
BEGIN
  PERFORM pg_catalog.set_config('request.jwt.claim.sub', coalesce(p_id::text, ''), true);
  PERFORM pg_catalog.set_config('test.uid', coalesce(p_id::text, ''), true);
  PERFORM pg_catalog.set_config('request.jwt.claims', v_jwt, true);
  PERFORM pg_catalog.set_config('test.jwt', v_jwt, true);
END $$;
CREATE FUNCTION pg_temp.vrai(p_condition boolean, p_label text) RETURNS void LANGUAGE plpgsql AS $$
BEGIN
  IF p_condition IS NOT TRUE THEN
    RAISE EXCEPTION 'ROUGE : %', p_label;
  END IF;
  RAISE NOTICE 'OK %', p_label;
END $$;
CREATE FUNCTION pg_temp.refuse(p_sql text, p_label text) RETURNS void LANGUAGE plpgsql AS $$
BEGIN
  BEGIN
    EXECUTE p_sql;
  EXCEPTION WHEN OTHERS THEN
    RAISE NOTICE 'OK % (refuse : %)', p_label, SQLERRM;
    RETURN;
  END;
  RAISE EXCEPTION 'ROUGE : % (accepte)', p_label;
END $$;
GRANT EXECUTE ON FUNCTION pg_temp.qui(uuid, text, text), pg_temp.vrai(boolean, text), pg_temp.refuse(text, text)
  TO authenticated, anon;

-- Fixtures : une direction, une tutrice, un enfant de la tutrice.
INSERT INTO auth.users(id, email, raw_app_meta_data) VALUES
  ('c0e10000-0000-4000-8000-0000000000a1', 'direction@test.invalid', '{}'),
  ('c0e10000-0000-4000-8000-0000000000b1', 'Tutrice@Test.invalid', '{}'),
  ('c0e10000-0000-4000-8000-0000000000e1', 'eleve-e1@eleves.test.invalid',
   '{"child_of":"c0e10000-0000-4000-8000-0000000000b1"}');
INSERT INTO public.households(id, timezone) VALUES ('c0e10000-0000-4000-8000-0000000000f1', 'Europe/Paris');
INSERT INTO public.profiles(id, immutable_id, role, household_id, first_name, last_name, account_status, gender)
SELECT x.id::uuid, x.mat, x.role::public.app_role,
       CASE WHEN x.role <> 'admin' THEN 'c0e10000-0000-4000-8000-0000000000f1'::uuid END,
       x.prenom, 'CRL', 'active'::public.account_status, 'female'::public.gender
  FROM (VALUES
   ('c0e10000-0000-4000-8000-0000000000a1', 'CRL-ADM-01', 'admin', 'Direction'),
   ('c0e10000-0000-4000-8000-0000000000b1', 'CRL-TUT-01', 'guardian', 'Khadija'),
   ('c0e10000-0000-4000-8000-0000000000e1', 'CRL-ELV-01', 'student', 'Sara')) AS x(id, mat, role, prenom);

-- 1. Notification -> e-mail
INSERT INTO public.notifications(id, destinataire, evenement, destination)
VALUES ('c0e10000-0000-4000-8000-000000000d01', 'c0e10000-0000-4000-8000-0000000000b1', 'classe_validee', '/tuteur/demandes');
SELECT pg_temp.vrai((SELECT count(*) = 1 AND bool_and(categorie = 'inscription' AND modele = 'classe_validee'
                       AND destinataire_adresse = 'tutrice@test.invalid' AND donnees->>'prenom' = 'Khadija'
                       AND statut = 'en_attente' AND origine = 'auto')
                       FROM public.courriels_sortants), '1 notification mise en file, adresse normalisee, prenom joint');
INSERT INTO public.notifications(destinataire, evenement, destination)
VALUES ('c0e10000-0000-4000-8000-0000000000b1', 'enseignant_affecte', '/tuteur/demandes');
SELECT pg_temp.vrai((SELECT categorie FROM public.courriels_sortants WHERE modele = 'enseignant_affecte') = 'classes',
                    '1 enseignant affecte : categorie classes');
SELECT pg_temp.vrai(public.courriel_enfiler('inscription', 'classe_validee', 'x@test.invalid', NULL, '{}',
                      'notification:c0e10000-0000-4000-8000-000000000d01') IS NULL, '1 meme cle : rien de plus');

-- 2. Compte enfant
INSERT INTO public.notifications(destinataire, evenement, destination)
VALUES ('c0e10000-0000-4000-8000-0000000000e1', 'demande_recue', '/tuteur/demandes');
SELECT pg_temp.vrai(NOT EXISTS (SELECT 1 FROM public.courriels_sortants WHERE destinataire_adresse LIKE 'eleve-%'),
                    '2 compte enfant : aucun e-mail');

-- 3. Invitation au foyer
INSERT INTO public.invitations_foyer(id, foyer_id, email_invite, invite_par, cle_envoi)
VALUES ('c0e10000-0000-4000-8000-000000000c01', 'c0e10000-0000-4000-8000-0000000000f1', 'conjoint@test.invalid',
        'c0e10000-0000-4000-8000-0000000000b1', gen_random_uuid());
INSERT INTO public.email_outbox_invitation_foyer(invitation_id, recipient_email)
VALUES ('c0e10000-0000-4000-8000-000000000c01', 'conjoint@test.invalid');
SELECT pg_temp.vrai((SELECT categorie = 'compte' AND donnees->>'invite_par' = 'Khadija' AND donnees ? 'expire_le'
                       FROM public.courriels_sortants WHERE modele = 'invitation_foyer'), '3 invitation : compte, invitant nomme');

-- 4. Desinscription
SELECT pg_temp.vrai(public.courriel_enfiler('nouvelles', 'nouvelles', 'Lectrice@Test.invalid', NULL, '{}', 'n1') IS NOT NULL,
                    '4 nouvelles en file');
SELECT set_config('test.jeton', (SELECT donnees->>'jeton_desinscription' FROM public.courriels_sortants
                                  WHERE cle_idempotence = 'n1'), true);
SELECT pg_temp.vrai(pg_catalog.char_length(current_setting('test.jeton')) >= 30, '4 jeton porte par le message');
SELECT pg_temp.vrai(NOT EXISTS (SELECT 1 FROM public.courriel_jetons_desinscription
                                 WHERE empreinte = convert_to(current_setting('test.jeton'), 'UTF8')),
                    '4 jeton garde en empreinte seulement');
SET LOCAL ROLE anon;
SELECT pg_temp.vrai((public.courriel_desinscrire('inconnu-inconnu-inconnu-inconnu')->>'ok')::boolean = false,
                    '4 jeton inconnu : ok=false');
SELECT pg_temp.vrai((public.courriel_desinscrire(current_setting('test.jeton'))->>'ok')::boolean,
                    '4 desinscription par le lien, sans compte');
RESET ROLE;
SELECT pg_temp.vrai(public.courriel_enfiler('nouvelles', 'nouvelles', 'lectrice@test.invalid', NULL, '{}', 'n2') IS NULL,
                    '4 desinscrite : plus de nouvelles');
SELECT pg_temp.vrai(public.courriel_enfiler('compte', 'invitation_foyer', 'lectrice@test.invalid', NULL, '{}', 'n3') IS NOT NULL,
                    '4 un message essentiel part quand meme');

-- 5. Envoi manuel
SELECT pg_temp.qui('c0e10000-0000-4000-8000-0000000000b1', 'guardian');
SET LOCAL ROLE authenticated;
SELECT pg_temp.refuse($$SELECT public.admin_courriel_envoyer(NULL, 'a@test.invalid', 'direction', 'Sujet', 'Corps', gen_random_uuid())$$,
                      '5 une famille ne peut pas envoyer');
RESET ROLE;
SELECT pg_temp.qui('c0e10000-0000-4000-8000-0000000000a1', 'admin');
SET LOCAL ROLE authenticated;
SELECT set_config('test.cle', gen_random_uuid()::text, true);
SELECT pg_temp.vrai(public.admin_courriel_envoyer('c0e10000-0000-4000-8000-0000000000b1', NULL, 'direction',
                      'Votre classe', 'Bonjour', current_setting('test.cle')::uuid)
                    = public.admin_courriel_envoyer('c0e10000-0000-4000-8000-0000000000b1', NULL, 'direction',
                      'Votre classe', 'Bonjour', current_setting('test.cle')::uuid),
                    '5 direction : envoye, double clic idempotent');
SELECT pg_temp.refuse($$SELECT public.admin_courriel_envoyer(NULL, 'a@test.invalid', 'inconnue', 'S', 'C', gen_random_uuid())$$,
                      '5 categorie inconnue');
SELECT pg_temp.refuse($$SELECT public.admin_courriel_envoyer('c0e10000-0000-4000-8000-0000000000e1', NULL, 'direction', 'S', 'C', gen_random_uuid())$$,
                      '5 compte enfant exclu');
SELECT pg_temp.vrai(jsonb_array_length(public.admin_courriels_lister(NULL, 50)) >= 5, '5 la direction voit la file');
SELECT pg_temp.refuse($$SELECT * FROM public.courriels_sortants$$, '7 table illisible pour un client');
SELECT pg_temp.refuse($$SELECT public.courriels_reserver(5)$$, '7 reserver interdit a un client');
SELECT pg_temp.refuse($$SELECT public.courriel_enfiler('compte','x','a@b.cd',NULL,'{}','z')$$, '7 enfiler interdit a un client');
RESET ROLE;

-- 6. Travailleur
SET LOCAL ROLE service_role;
SELECT set_config('test.lot', public.courriels_reserver(100)::text, true);
SELECT pg_temp.vrai(jsonb_array_length(current_setting('test.lot')::jsonb) >= 5
                    AND (current_setting('test.lot')::jsonb->0) ?& ARRAY['de', 'repondre_a', 'a', 'modele'],
                    '6 lot reserve, alias joint');
SELECT pg_temp.vrai(jsonb_array_length(public.courriels_reserver(100)) = 0, '6 une ligne reservee ne repart pas');
SELECT public.courriel_consigner((current_setting('test.lot')::jsonb->0->>'id')::uuid, true, 'msg-1', NULL);
SELECT public.courriel_consigner((current_setting('test.lot')::jsonb->1->>'id')::uuid, false, NULL, 'smtp 421');
RESET ROLE;
SELECT pg_temp.vrai((SELECT statut = 'envoye' AND fournisseur_id = 'msg-1' FROM public.courriels_sortants
                      WHERE id = (current_setting('test.lot')::jsonb->0->>'id')::uuid), '6 succes consigne');
SELECT pg_temp.vrai((SELECT statut = 'en_attente' AND prochaine_tentative > now() AND derniere_erreur = 'smtp 421'
                       FROM public.courriels_sortants
                      WHERE id = (current_setting('test.lot')::jsonb->1->>'id')::uuid), '6 echec : nouvel essai plus tard');
UPDATE public.courriels_sortants SET statut = 'envoi', tentatives = 5
 WHERE id = (current_setting('test.lot')::jsonb->1->>'id')::uuid;
SELECT public.courriel_consigner((current_setting('test.lot')::jsonb->1->>'id')::uuid, false, NULL, 'smtp 550');
SELECT pg_temp.vrai((SELECT statut FROM public.courriels_sortants
                      WHERE id = (current_setting('test.lot')::jsonb->1->>'id')::uuid) = 'echec', '6 cinquieme echec : abandon');
SELECT pg_temp.qui('c0e10000-0000-4000-8000-0000000000a1', 'admin');
SET LOCAL ROLE authenticated;
SELECT public.admin_courriel_reessayer((current_setting('test.lot')::jsonb->1->>'id')::uuid);
RESET ROLE;
SELECT pg_temp.vrai((SELECT statut = 'en_attente' AND tentatives = 0 FROM public.courriels_sortants
                      WHERE id = (current_setting('test.lot')::jsonb->1->>'id')::uuid), '6 la direction relance un echec');

-- 7. Droits (chemins PUBLIC et anon)
SELECT pg_temp.vrai(NOT has_function_privilege('anon', 'public.courriel_enfiler(text,text,text,uuid,jsonb,text,text,uuid)', 'EXECUTE')
                    AND NOT has_function_privilege('authenticated', 'public.courriel_consigner(uuid,boolean,text,text)', 'EXECUTE')
                    AND NOT has_function_privilege('anon', 'public.admin_courriel_envoyer(uuid,text,text,text,text,uuid)', 'EXECUTE')
                    AND NOT has_table_privilege('agent_ro', 'public.courriels_sortants', 'SELECT'),
                    '7 droits bornes');
SELECT pg_temp.vrai((SELECT bool_and(c.relrowsecurity) FROM pg_class c
                      WHERE c.relname IN ('courriel_categories', 'courriels_sortants', 'courriel_desinscriptions',
                                          'courriel_jetons_desinscription')), '7 RLS active partout');

\o
SELECT 'COURRIELS-1 : tous les controles sont verts' AS resultat;
ROLLBACK;
