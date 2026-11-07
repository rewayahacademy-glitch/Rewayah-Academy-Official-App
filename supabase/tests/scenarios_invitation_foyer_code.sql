-- INVITATION-SECOND-ADULTE (07/11/2026) : code de l'invitation d'un foyer,
-- creation du compte de la seule adresse invitee, renvoi par le titulaire.
-- A executer apres toutes les migrations, sur une base jetable.
BEGIN;

INSERT INTO auth.users (id, email, email_confirmed_at)
VALUES
  ('c6000000-0000-0000-0000-000000000001', 'c6-titulaire@example.test', now()),
  ('c6000000-0000-0000-0000-000000000002', 'c6-autre@example.test', now()),
  ('c6000000-0000-0000-0000-000000000003', 'c6-existant@example.test', now()),
  ('c6000000-0000-0000-0000-000000000004', 'c6-direction@example.test', now());

INSERT INTO public.households (id, timezone, status)
VALUES
  ('c6000000-0000-0000-0000-000000000101', 'Europe/Paris', 'active'),
  ('c6000000-0000-0000-0000-000000000102', 'Europe/Paris', 'active');

INSERT INTO public.profiles
  (id, immutable_id, role, household_id, first_name, last_name, account_status, gender)
VALUES
  ('c6000000-0000-0000-0000-000000000001', 'C6-TITULAIRE', 'guardian',
   'c6000000-0000-0000-0000-000000000101', 'Nour', 'Titulaire',
   'active'::public.account_status, 'female'),
  ('c6000000-0000-0000-0000-000000000002', 'C6-AUTRE', 'guardian',
   'c6000000-0000-0000-0000-000000000102', 'Samir', 'Autre',
   'active'::public.account_status, 'male'),
  ('c6000000-0000-0000-0000-000000000004', 'C6-DIRECTION', 'admin',
   NULL, 'Direction', 'Essai', 'active'::public.account_status, 'female');

UPDATE public.households SET primary_guardian_id = 'c6000000-0000-0000-0000-000000000001'
WHERE id = 'c6000000-0000-0000-0000-000000000101';
UPDATE public.households SET primary_guardian_id = 'c6000000-0000-0000-0000-000000000002'
WHERE id = 'c6000000-0000-0000-0000-000000000102';

-- Droits : anon n'atteint rien ; authenticated n'atteint ni la creation de
-- compte (service_role seul) ni les codes.
DO $droits$
BEGIN
  IF has_function_privilege('anon', 'public.renvoyer_invitation_conjoint(uuid)', 'EXECUTE')
     OR has_function_privilege('anon', 'public.invitation_foyer_pour_moi(text)', 'EXECUTE')
     OR has_function_privilege('anon', 'public.mon_invitation_envoyee()', 'EXECUTE')
     OR has_function_privilege('anon', 'public.invitation_compte_autoriser(text,text,text)', 'EXECUTE')
     OR has_function_privilege('authenticated', 'public.invitation_compte_autoriser(text,text,text)', 'EXECUTE')
     OR NOT has_function_privilege('service_role', 'public.invitation_compte_autoriser(text,text,text)', 'EXECUTE')
     OR has_function_privilege('anon', 'public.invitation_compte_debit(text,text)', 'EXECUTE')
     OR has_function_privilege('authenticated', 'public.invitation_compte_debit(text,text)', 'EXECUTE')
     OR NOT has_function_privilege('service_role', 'public.invitation_compte_debit(text,text)', 'EXECUTE')
     OR has_table_privilege('authenticated', 'app_private.demandes_invitation_compte', 'SELECT')
     OR has_table_privilege('authenticated', 'app_private.codes_invitation_foyer', 'SELECT')
     OR has_table_privilege('service_role', 'app_private.codes_invitation_foyer', 'SELECT') THEN
    RAISE EXCEPTION 'INVITATION-FOYER : droits invalides';
  END IF;
END
$droits$;

DO $scenario$
DECLARE
  v_titulaire uuid := 'c6000000-0000-0000-0000-000000000001';
  v_autre uuid := 'c6000000-0000-0000-0000-000000000002';
  v_invitee constant text := 'c6-invite@example.test';
  v_invitation uuid;
  v_code text;
  v_ancien text;
  v_r jsonb;
  v_expire timestamptz;
  v_n integer;
BEGIN
  -- Le titulaire invite une adresse sans compte.
  PERFORM set_config('request.jwt.claim.sub', v_titulaire::text, true);
  PERFORM set_config('request.jwt.claims', jsonb_build_object('sub', v_titulaire,
    'app_metadata', jsonb_build_object('role', 'guardian',
      'household_id', 'c6000000-0000-0000-0000-000000000101'))::text, true);
  v_r := public.inviter_conjoint('C6-Invite@Example.test', 'c6000000-0000-0000-0000-000000000201');
  v_invitation := (v_r->>'invitation_id')::uuid;
  IF v_invitation IS NULL THEN
    RAISE EXCEPTION 'C6 : invitation non creee (%)', v_r;
  END IF;
  -- L'e-mail porte le code ; la table ne garde que son empreinte.
  SELECT s.donnees->>'code' INTO v_code FROM public.courriels_sortants s
   WHERE s.modele = 'invitation_foyer' AND s.destinataire_adresse = v_invitee
     AND s.statut = 'en_attente';
  IF v_code IS NULL OR v_code !~ '^[A-HJKMNP-Z2-9]{4}-[A-HJKMNP-Z2-9]{4}-[A-HJKMNP-Z2-9]{4}$' THEN
    RAISE EXCEPTION 'C6 : aucun code AAAA-BBBB-CCCC dans l''e-mail (%)', v_code;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM app_private.codes_invitation_foyer c
                  WHERE c.invitation_id = v_invitation AND c.remplace_le IS NULL
                    AND c.code_sha256 = encode(sha256(convert_to(v_code, 'UTF8')), 'hex')) THEN
    RAISE EXCEPTION 'C6 : l''empreinte du code n''est pas gardee';
  END IF;

  -- Le titulaire lit son invitation en attente.
  v_r := public.mon_invitation_envoyee();
  IF v_r->>'etat' <> 'en_attente' OR v_r->>'courriel' <> v_invitee
     OR (v_r->>'renvois_restants')::integer <> 3 THEN
    RAISE EXCEPTION 'C6 : lecture du titulaire inattendue (%)', v_r;
  END IF;

  -- Refus : une adresse non invitee, avec un bon code.
  IF (public.invitation_compte_autoriser('foyer', v_code, 'intrus@example.test')->>'autorise')::boolean THEN
    RAISE EXCEPTION 'C6 : compte autorise pour une adresse non invitee';
  END IF;
  -- Refus : un code inconnu pour la bonne adresse.
  IF (public.invitation_compte_autoriser('foyer', 'AAAA-BBBB-CCCC', v_invitee)->>'autorise')::boolean THEN
    RAISE EXCEPTION 'C6 : compte autorise avec un code inconnu';
  END IF;
  -- Le code recopie sans tirets ni majuscules sert (et se consomme : le
  -- renvoi plus bas en emet un neuf).
  IF NOT (public.invitation_compte_autoriser('foyer', lower(replace(v_code, '-', '')), ' ' || upper(v_invitee))->>'autorise')::boolean THEN
    RAISE EXCEPTION 'C6 : le bon code, recopie librement, est refuse';
  END IF;

  SELECT count(*) INTO v_n FROM app_private.codes_invitation_foyer c WHERE c.utilise_le IS NOT NULL;
  -- Une autre session lit « autre_adresse » et ne consomme rien.
  PERFORM set_config('request.jwt.claim.sub', v_autre::text, true);
  PERFORM set_config('request.jwt.claims', jsonb_build_object('sub', v_autre,
    'app_metadata', jsonb_build_object('role', 'guardian',
      'household_id', 'c6000000-0000-0000-0000-000000000102'))::text, true);
  IF public.invitation_foyer_pour_moi(v_code)->>'etat' <> 'autre_adresse' THEN
    RAISE EXCEPTION 'C6 : une autre adresse ne lit pas « autre_adresse »';
  END IF;
  IF public.invitation_foyer_pour_moi('ZZZZ-ZZZZ-ZZZZ')->>'etat' <> 'inconnue' THEN
    RAISE EXCEPTION 'C6 : un code inconnu ne lit pas « inconnue »';
  END IF;
  -- Le second adulte d'un autre foyer ne renvoie rien.
  IF public.renvoyer_invitation_conjoint('c6000000-0000-0000-0000-000000000301')->>'etat' <> 'aucune' THEN
    RAISE EXCEPTION 'C6 : un autre titulaire renvoie l''invitation';
  END IF;
  IF (SELECT count(*) FROM app_private.codes_invitation_foyer c WHERE c.utilise_le IS NOT NULL) <> v_n THEN
    RAISE EXCEPTION 'C6 : une lecture a consomme un code';
  END IF;

  -- Renvoi par le titulaire : nouveau code, l'ancien ne sert plus, echeance
  -- inchangee, idempotent par cle.
  PERFORM set_config('request.jwt.claim.sub', v_titulaire::text, true);
  PERFORM set_config('request.jwt.claims', jsonb_build_object('sub', v_titulaire,
    'app_metadata', jsonb_build_object('role', 'guardian',
      'household_id', 'c6000000-0000-0000-0000-000000000101'))::text, true);
  SELECT i.expire_le INTO v_expire FROM public.invitations_foyer i WHERE i.id = v_invitation;
  v_ancien := v_code;
  v_r := public.renvoyer_invitation_conjoint('c6000000-0000-0000-0000-000000000401');
  IF v_r->>'etat' <> 'renvoyee' OR (v_r->>'renvois_restants')::integer <> 2 THEN
    RAISE EXCEPTION 'C6 : premier renvoi inattendu (%)', v_r;
  END IF;
  v_r := public.renvoyer_invitation_conjoint('c6000000-0000-0000-0000-000000000401');
  IF v_r->>'etat' <> 'renvoyee' OR (v_r->>'renvois_restants')::integer <> 2 THEN
    RAISE EXCEPTION 'C6 : la meme cle a compte un second renvoi (%)', v_r;
  END IF;
  SELECT s.donnees->>'code' INTO v_code FROM public.courriels_sortants s
   WHERE s.modele = 'invitation_foyer' AND s.destinataire_adresse = v_invitee
     AND s.statut = 'en_attente';
  IF v_code IS NULL OR v_code = v_ancien THEN
    RAISE EXCEPTION 'C6 : le renvoi garde l''ancien code';
  END IF;
  IF (SELECT i.expire_le FROM public.invitations_foyer i WHERE i.id = v_invitation) <> v_expire THEN
    RAISE EXCEPTION 'C6 : le renvoi a change l''echeance';
  END IF;
  IF (public.invitation_compte_autoriser('foyer', v_ancien, v_invitee)->>'autorise')::boolean THEN
    RAISE EXCEPTION 'C6 : l''ancien code sert encore apres le renvoi';
  END IF;
  SELECT count(*) INTO v_n FROM public.courriels_sortants s
   WHERE s.modele = 'invitation_foyer' AND s.destinataire_adresse = v_invitee
     AND s.donnees->>'code' = v_code AND s.statut = 'en_attente';
  IF v_n <> 1 THEN
    RAISE EXCEPTION 'C6 : le renvoi n''a pas enfile un e-mail avec le nouveau code (%)', v_n;
  END IF;
  IF EXISTS (SELECT 1 FROM public.courriels_sortants s
              WHERE s.modele = 'invitation_foyer' AND s.destinataire_adresse = v_invitee
                AND s.donnees->>'code' = v_ancien AND s.statut = 'en_attente') THEN
    RAISE EXCEPTION 'C6 : l''e-mail de l''ancien code part encore';
  END IF;

  -- Trois renvois au plus.
  PERFORM public.renvoyer_invitation_conjoint('c6000000-0000-0000-0000-000000000402');
  v_r := public.renvoyer_invitation_conjoint('c6000000-0000-0000-0000-000000000403');
  IF v_r->>'etat' <> 'renvoyee' OR (v_r->>'renvois_restants')::integer <> 0 THEN
    RAISE EXCEPTION 'C6 : troisieme renvoi inattendu (%)', v_r;
  END IF;
  v_r := public.renvoyer_invitation_conjoint('c6000000-0000-0000-0000-000000000404');
  IF v_r->>'etat' <> 'limite' THEN
    RAISE EXCEPTION 'C6 : un quatrieme renvoi est accepte (%)', v_r;
  END IF;
  SELECT s.donnees->>'code' INTO v_code FROM public.courriels_sortants s
   WHERE s.modele = 'invitation_foyer' AND s.destinataire_adresse = v_invitee
     AND s.statut = 'en_attente';

  -- Usage unique : la consommation sert une fois.
  IF NOT (public.invitation_compte_autoriser('foyer', v_code, v_invitee)->>'autorise')::boolean THEN
    RAISE EXCEPTION 'C6 : la premiere consommation est refusee';
  END IF;
  IF (public.invitation_compte_autoriser('foyer', v_code, v_invitee)->>'autorise')::boolean THEN
    RAISE EXCEPTION 'C6 : le code sert deux fois';
  END IF;

  -- Une adresse qui a deja un compte : rien a creer.
  UPDATE public.invitations_foyer SET statut = 'annulee', updated_at = now() WHERE id = v_invitation;
  v_r := public.inviter_conjoint('c6-existant@example.test', 'c6000000-0000-0000-0000-000000000202');
  SELECT s.donnees->>'code' INTO v_code FROM public.courriels_sortants s
   WHERE s.modele = 'invitation_foyer' AND s.destinataire_adresse = 'c6-existant@example.test'
     AND s.statut = 'en_attente';
  v_r := public.invitation_compte_autoriser('foyer', v_code, 'c6-existant@example.test');
  IF (v_r->>'autorise')::boolean OR v_r ? 'compte_existant' THEN
    RAISE EXCEPTION 'C6 : compte autorise pour une adresse qui en a deja un (%)', v_r;
  END IF;

  -- L'echeance court du temps, jamais du clic : echue, plus rien ne sert.
  UPDATE public.invitations_foyer SET expire_le = now() - interval '1 minute'
   WHERE email_invite = 'c6-existant@example.test' AND statut = 'en_attente';
  IF (public.invitation_compte_autoriser('foyer', v_code, 'c6-existant@example.test')->>'autorise')::boolean THEN
    RAISE EXCEPTION 'C6 : une invitation echue autorise un compte';
  END IF;
  IF public.renvoyer_invitation_conjoint('c6000000-0000-0000-0000-000000000405')->>'etat' <> 'perimee' THEN
    RAISE EXCEPTION 'C6 : une invitation echue se renvoie';
  END IF;
  IF public.mon_invitation_envoyee()->>'etat' <> 'aucune' THEN
    RAISE EXCEPTION 'C6 : une invitation echue reste lue en attente';
  END IF;
END
$scenario$;

-- Le code quitte la file des que l'envoi est clos ; le debit ; l'enseignant.
DO $suite$
DECLARE
  v_id uuid;
  v_i integer;
BEGIN
  SELECT s.id INTO v_id FROM public.courriels_sortants s
   WHERE s.modele = 'invitation_foyer' AND s.donnees ? 'code' AND s.statut = 'en_attente'
   LIMIT 1;
  IF v_id IS NULL THEN
    RAISE EXCEPTION 'C6 : aucun e-mail en file avec un code';
  END IF;
  UPDATE public.courriels_sortants SET statut = 'envoi' WHERE id = v_id;
  PERFORM public.courriel_consigner(v_id, true, 'essai', NULL);
  IF (SELECT s.donnees ? 'code' FROM public.courriels_sortants s WHERE s.id = v_id) THEN
    RAISE EXCEPTION 'C6 : le code reste dans la file apres l''envoi';
  END IF;

  -- Seconde lecture (07/11) : 'echec' n'est pas definitif. Le code reste
  -- apres un echec, et au nouvel envoi que relance la direction ; il ne
  -- quitte la file qu'a l'envoi fait.
  SELECT s.id INTO v_id FROM public.courriels_sortants s
   WHERE s.modele = 'invitation_foyer' AND s.donnees ? 'code' AND s.statut = 'en_attente'
   LIMIT 1;
  IF v_id IS NULL THEN
    RAISE EXCEPTION 'C6 : aucun e-mail en file avec un code (echec)';
  END IF;
  UPDATE public.courriels_sortants SET statut = 'envoi', tentatives = 5 WHERE id = v_id;
  PERFORM public.courriel_consigner(v_id, false, NULL, 'panne du fournisseur');
  IF (SELECT s.statut FROM public.courriels_sortants s WHERE s.id = v_id) <> 'echec'
     OR NOT (SELECT s.donnees ? 'code' FROM public.courriels_sortants s WHERE s.id = v_id) THEN
    RAISE EXCEPTION 'C6 : apres un echec, le code doit rester dans la file';
  END IF;
  PERFORM set_config('request.jwt.claim.sub', 'c6000000-0000-0000-0000-000000000004', true);
  PERFORM set_config('request.jwt.claims', jsonb_build_object('sub', 'c6000000-0000-0000-0000-000000000004',
    'app_metadata', jsonb_build_object('role', 'admin'))::text, true);
  PERFORM public.admin_courriel_reessayer(v_id);
  IF (SELECT s.statut FROM public.courriels_sortants s WHERE s.id = v_id) <> 'en_attente'
     OR NOT (SELECT s.donnees ? 'code' FROM public.courriels_sortants s WHERE s.id = v_id) THEN
    RAISE EXCEPTION 'C6 : au nouvel envoi relance par la direction, le code doit etre la';
  END IF;
  UPDATE public.courriels_sortants SET statut = 'envoi' WHERE id = v_id;
  PERFORM public.courriel_consigner(v_id, true, 'essai-2', NULL);
  IF (SELECT s.donnees ? 'code' FROM public.courriels_sortants s WHERE s.id = v_id) THEN
    RAISE EXCEPTION 'C6 : apres l''envoi fait, le code reste dans la file';
  END IF;

  -- Cinq demandes par heure, par adresse : la sixieme est refusee.
  FOR v_i IN 1..5 LOOP
    IF NOT public.invitation_compte_debit('debit@example.test', '198.51.100.' || v_i) THEN
      RAISE EXCEPTION 'C6 : demande % refusee trop tot (adresse)', v_i;
    END IF;
  END LOOP;
  IF public.invitation_compte_debit('Debit@Example.test ', '198.51.100.99') THEN
    RAISE EXCEPTION 'C6 : sixieme demande acceptee pour la meme adresse';
  END IF;
  -- Et par IP.
  FOR v_i IN 1..5 LOOP
    IF NOT public.invitation_compte_debit('ip' || v_i || '@example.test', '203.0.113.7') THEN
      RAISE EXCEPTION 'C6 : demande % refusee trop tot (IP)', v_i;
    END IF;
  END LOOP;
  IF public.invitation_compte_debit('ip6@example.test', '203.0.113.7') THEN
    RAISE EXCEPTION 'C6 : sixieme demande acceptee pour la meme IP';
  END IF;
  IF EXISTS (SELECT 1 FROM app_private.demandes_invitation_compte d
              WHERE d.cle LIKE '%debit%' OR d.cle LIKE '%203.0.113%') THEN
    RAISE EXCEPTION 'C6 : le journal garde une valeur claire';
  END IF;

  -- L'enseignant invite : son adresse seule, son code seul, non revoque.
  INSERT INTO public.invitations_enseignant (code, email, cree_par, expire_le)
  VALUES ('C6AB-CDEF-GHJK', 'c6-prof@example.test', 'c6000000-0000-0000-0000-000000000001',
          now() + interval '14 days');
  IF NOT (public.invitation_compte_autoriser('enseignant', 'c6ab cdef ghjk', 'c6-prof@example.test')->>'autorise')::boolean THEN
    RAISE EXCEPTION 'C6 : l''enseignant invite ne peut pas creer son compte';
  END IF;
  IF (public.invitation_compte_autoriser('enseignant', 'C6AB-CDEF-GHJK', 'intrus@example.test')->>'autorise')::boolean
     OR (public.invitation_compte_autoriser('comptable', 'C6AB-CDEF-GHJK', 'c6-prof@example.test')->>'autorise')::boolean
     OR (public.invitation_compte_autoriser('autre', 'C6AB-CDEF-GHJK', 'c6-prof@example.test')->>'autorise')::boolean
     OR NOT (public.invitation_compte_autoriser('equipe', 'C6AB-CDEF-GHJK', 'c6-prof@example.test')->>'autorise')::boolean THEN
    RAISE EXCEPTION 'C6 : un code enseignant sert a une autre adresse ou un autre type, ou pas en equipe';
  END IF;
  UPDATE public.invitations_enseignant SET revoquee_le = now(), revoquee_par = 'c6000000-0000-0000-0000-000000000001'
   WHERE code = 'C6AB-CDEF-GHJK';
  IF (public.invitation_compte_autoriser('enseignant', 'C6AB-CDEF-GHJK', 'c6-prof@example.test')->>'autorise')::boolean THEN
    RAISE EXCEPTION 'C6 : un code enseignant revoque sert encore';
  END IF;
END
$suite$;

-- Le candidat d'un formulaire importe : son courriel lien_inscription porte un
-- code lie a son adresse, 30 jours, usage unique ; le code quitte la file a
-- l'envoi.
INSERT INTO public.formulaires_lots (id, cle, auteur_id, classeur, onglet, empreinte, compteurs, rapport)
VALUES ('c6000000-0000-0000-0000-000000000501', 'cle-lot-c6', 'c6000000-0000-0000-0000-000000000001',
        'Candidature (réponses)', 'Réponses', md5('c6'), '{}', '{}');
INSERT INTO public.formulaires_reponses (id, reference_source, lot_id, recue_le, genre, nom_affiche, courriel,
                                         telephone, reponses, contenu_empreinte, suivi_id)
VALUES ('c6000000-0000-0000-0000-000000000502', 'c6|r|01', 'c6000000-0000-0000-0000-000000000501',
        '2026-10-14 09:30+00', 'male', 'Candidat C6', 'c6-candidat@example.test', NULL, '{}', md5('c6r'), NULL);

DO $candidat$
DECLARE
  v_code text;
  v_ancien text;
  v_id uuid;
BEGIN
  v_id := public.courriel_enfiler('recrutement', 'lien_inscription', 'c6-candidat@example.test', NULL,
    '{}'::jsonb, 'lien_inscription:c6-candidat@example.test', 'manuel', NULL);
  SELECT s.donnees->>'code' INTO v_code FROM public.courriels_sortants s WHERE s.id = v_id;
  IF v_code IS NULL OR v_code !~ '^[A-HJKMNP-Z2-9]{4}-[A-HJKMNP-Z2-9]{4}-[A-HJKMNP-Z2-9]{4}$' THEN
    RAISE EXCEPTION 'C6 : le courriel du candidat ne porte pas de code (%)', v_code;
  END IF;
  IF (SELECT c.expire_le FROM app_private.codes_invitation_candidat c
       WHERE c.adresse = 'c6-candidat@example.test' AND c.remplace_le IS NULL)
     NOT BETWEEN now() + interval '29 days' AND now() + interval '31 days' THEN
    RAISE EXCEPTION 'C6 : l''echeance du code candidat n''est pas de 30 jours';
  END IF;
  -- Meme cle d'idempotence : rien n'est insere, le code reste le meme.
  PERFORM public.courriel_enfiler('recrutement', 'lien_inscription', 'c6-candidat@example.test', NULL,
    '{}'::jsonb, 'lien_inscription:c6-candidat@example.test', 'manuel', NULL);
  IF (SELECT count(*) FROM app_private.codes_invitation_candidat c
       WHERE c.adresse = 'c6-candidat@example.test') <> 1 THEN
    RAISE EXCEPTION 'C6 : un envoi ignore a remplace le code du candidat';
  END IF;
  -- Refus : adresse non invitee, mauvais type, code faux.
  IF (public.invitation_compte_autoriser('candidat', v_code, 'intrus@example.test')->>'autorise')::boolean
     OR (public.invitation_compte_autoriser('foyer', v_code, 'c6-candidat@example.test')->>'autorise')::boolean
     OR (public.invitation_compte_autoriser('candidat', 'AAAA-BBBB-CCCC', 'c6-candidat@example.test')->>'autorise')::boolean THEN
    RAISE EXCEPTION 'C6 : code candidat accepte hors de son adresse ou de son type';
  END IF;
  -- Le bon code, une fois.
  IF NOT (public.invitation_compte_autoriser('candidat', lower(v_code), 'C6-Candidat@Example.test')->>'autorise')::boolean THEN
    RAISE EXCEPTION 'C6 : le candidat ne peut pas creer son compte';
  END IF;
  IF (public.invitation_compte_autoriser('candidat', v_code, 'c6-candidat@example.test')->>'autorise')::boolean THEN
    RAISE EXCEPTION 'C6 : le code candidat sert deux fois';
  END IF;
  -- Echu : refuse (un code neuf, puis l'echeance passee).
  v_ancien := v_code;
  v_id := public.courriel_enfiler('recrutement', 'lien_inscription', 'c6-candidat@example.test', NULL,
    '{}'::jsonb, 'lien_inscription:c6-candidat@example.test:2', 'manuel', NULL);
  SELECT s.donnees->>'code' INTO v_code FROM public.courriels_sortants s WHERE s.id = v_id;
  UPDATE app_private.codes_invitation_candidat SET expire_le = now() - interval '1 minute'
   WHERE adresse = 'c6-candidat@example.test' AND remplace_le IS NULL;
  IF (public.invitation_compte_autoriser('candidat', v_code, 'c6-candidat@example.test')->>'autorise')::boolean THEN
    RAISE EXCEPTION 'C6 : un code candidat echu sert encore';
  END IF;
  -- Le code quitte la file a l'envoi.
  UPDATE public.courriels_sortants SET statut = 'annule' WHERE id = v_id;
  IF (SELECT s.donnees ? 'code' FROM public.courriels_sortants s WHERE s.id = v_id) THEN
    RAISE EXCEPTION 'C6 : le code du candidat reste dans la file';
  END IF;
END
$candidat$;

-- La session authenticated ne peut pas appeler la creation de compte.
SET LOCAL ROLE authenticated;
DO $refus$
BEGIN
  BEGIN
    PERFORM public.invitation_compte_autoriser('foyer', 'AAAA-BBBB-CCCC', 'x@example.test');
    RAISE EXCEPTION 'C6 : authenticated atteint invitation_compte_autoriser';
  EXCEPTION WHEN insufficient_privilege THEN
    NULL;
  END;
END
$refus$;
RESET ROLE;

ROLLBACK;
