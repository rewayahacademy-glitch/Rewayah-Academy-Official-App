-- BE-1i NOTIF-ENTRETIEN-ANNULE (pilote, 16/11/2026) : migration 20261129750000_notif_entretien_annule.sql.
--
-- Cas couverts : (a) la pause, (b) le refus et (c) le retrait d'une candidature a entretien ouvert posent une
-- notification `entretien_annule` a chaque personne qui menait l'entretien (participants actifs), jamais a
-- l'auteur du geste, ni a un participant retire, avec la cause, la reference et la destination permise ;
-- (d) un dossier sans entretien ouvert ne notifie personne ; (e) la notification qui echoue n'annule pas
-- l'annulation de l'entretien ; (f) la contrainte des evenements : les 62 valeurs, aucune retiree.
-- Chaque controle leve 'NOTIF ROUGE : ...' s'il echoue. A rejouer sur une base NEUVE ; le scenario annule tout.
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
    RAISE EXCEPTION 'NOTIF ROUGE : %', p_label;
  END IF;
  PERFORM pg_temp.ok(p_label);
END $$;

CREATE FUNCTION pg_temp.en(p_id uuid, p_role text, p_sql text) RETURNS jsonb
LANGUAGE plpgsql AS $$
DECLARE v jsonb;
BEGIN
  PERFORM pg_temp.qui(p_id, p_role);
  EXECUTE 'SET LOCAL ROLE authenticated';
  EXECUTE p_sql INTO v;
  EXECUTE 'RESET ROLE';
  RETURN v;
END $$;

CREATE FUNCTION pg_temp.p(p_n text) RETURNS uuid
LANGUAGE sql IMMUTABLE AS $$ SELECT ('e5200000-0000-4000-8000-0000000000' || p_n)::uuid $$;
CREATE FUNCTION pg_temp.c(p_n text) RETURNS uuid
LANGUAGE sql IMMUTABLE AS $$ SELECT ('e520cccc-0000-4000-8000-0000000000' || p_n)::uuid $$;
CREATE FUNCTION pg_temp.s(p_n text) RETURNS uuid
LANGUAGE sql IMMUTABLE AS $$ SELECT ('e5200000-0000-4000-8000-0000000003' || p_n)::uuid $$;
CREATE FUNCTION pg_temp.v(p_n text) RETURNS integer
LANGUAGE sql AS $$ SELECT version FROM public.candidatures WHERE id = pg_temp.c(p_n) $$;
CREATE FUNCTION pg_temp.issue_entretien(p_n text) RETURNS text
LANGUAGE sql AS $$ SELECT coalesce(issue, 'ouvert') FROM public.entretiens WHERE session_id = pg_temp.s(p_n) $$;
CREATE FUNCTION pg_temp.nb(p_n text, p_dest text) RETURNS bigint
LANGUAGE sql AS $$
  SELECT count(*) FROM public.notifications n
   WHERE n.evenement = 'entretien_annule' AND n.params ->> 'session_id' = pg_temp.s(p_n)::text
     AND n.destinataire = pg_temp.p(p_dest)
$$;
CREATE FUNCTION pg_temp.total(p_n text) RETURNS bigint
LANGUAGE sql AS $$
  SELECT count(*) FROM public.notifications n
   WHERE n.evenement = 'entretien_annule' AND n.params ->> 'session_id' = pg_temp.s(p_n)::text
$$;
GRANT EXECUTE ON FUNCTION pg_temp.qui(uuid, text, text), pg_temp.ok(text), pg_temp.vrai(boolean, text),
  pg_temp.en(uuid, text, text), pg_temp.p(text), pg_temp.c(text), pg_temp.s(text), pg_temp.v(text),
  pg_temp.issue_entretien(text), pg_temp.nb(text, text), pg_temp.total(text) TO authenticated, anon;

-- Fixtures (donnees inventees). a1 direction qui agit ; b1 et b2 dirigent des entretiens ; b3 a ete retire.
-- 01 pause, 02 refus, 03 retrait : entretien ouvert, participants b1, b2 (et a1 pour 02), b3 retire pour 01.
-- 04 : entretien a planifier, sans entretien. 05 : entretien ouvert, mais la notification est rendue impossible (e).
SET LOCAL session_replication_role = replica;
INSERT INTO auth.users (id, email)
SELECT pg_temp.p(s), 'na-' || s || '@test.invalid' FROM unnest(ARRAY['a1', 'b1', 'b2', 'b3', '01', '02', '03', '04', '05']) AS s;
INSERT INTO public.profiles (id, immutable_id, role, first_name, last_name, account_status, gender)
SELECT pg_temp.p(s), 'NA-ADM-00' || s, 'admin', 'Direction', s, 'active', 'male'
FROM unnest(ARRAY['a1', 'b1', 'b2', 'b3']) AS s;
INSERT INTO public.profiles (id, immutable_id, role, first_name, last_name, account_status, gender)
SELECT pg_temp.p(s), 'NA-ENS-00' || s, 'teacher', 'Essai' || s, 'Fictif', 'pending_kyc', 'male'
FROM unnest(ARRAY['01', '02', '03', '04', '05']) AS s;
INSERT INTO public.candidatures (id, type_code, profile_id, genre, nom_complet, etape, etat, issue, source)
SELECT pg_temp.c(v.s), 'enseignant', pg_temp.p(v.s), 'male', 'Fixture ' || v.s, 'verifications', v.etat, 'en_cours', 'lien_public'
FROM (VALUES ('01', 'entretien_planifie'), ('02', 'entretien_planifie'), ('03', 'entretien_planifie'),
             ('04', 'entretien_a_planifier'), ('05', 'entretien_planifie')) AS v(s, etat);
INSERT INTO public.sessions (id, teacher_id, started_at, ended_at, status, session_type, join_opens_at)
SELECT pg_temp.s(s), pg_temp.p('a1'), now() + interval '2 days', now() + interval '2 days 30 minutes',
       'planned', 'entretien', now() + interval '2 days' - interval '10 minutes'
FROM unnest(ARRAY['01', '02', '03', '05']) AS s;
INSERT INTO public.entretiens (session_id, candidature_id, candidat_id, planifie_par)
SELECT pg_temp.s(s), pg_temp.c(s), pg_temp.p(s), pg_temp.p('a1') FROM unnest(ARRAY['01', '02', '03', '05']) AS s;
INSERT INTO public.entretien_participants (session_id, profile_id, fondateur, ajoute_par)
SELECT pg_temp.s(s), pg_temp.p(q), false, pg_temp.p('a1')
FROM unnest(ARRAY['01', '02', '03', '05']) AS s, unnest(ARRAY['b1', 'b2']) AS q;
INSERT INTO public.entretien_participants (session_id, profile_id, fondateur, ajoute_par)
VALUES (pg_temp.s('02'), pg_temp.p('a1'), false, pg_temp.p('a1'));
INSERT INTO public.entretien_participants (session_id, profile_id, fondateur, ajoute_par, retire_par, retire_le)
VALUES (pg_temp.s('01'), pg_temp.p('b3'), false, pg_temp.p('a1'), pg_temp.p('a1'), now());
SET LOCAL session_replication_role = origin;

-- (a) La pause
SELECT pg_temp.vrai(pg_temp.total('01') = 0 AND pg_temp.issue_entretien('01') = 'ouvert',
  'a0 : avant la pause, personne n''est prevenu et l''entretien est ouvert');
SELECT pg_temp.en(pg_temp.p('a1'), 'admin', pg_catalog.format(
  'SELECT public.mettre_en_pause_candidat(%L, %L, %L, NULL, %s, %L)',
  pg_temp.c('01'), 'Pause demandee', 'pause_general', pg_temp.v('01'), 'cle-notif-01'));
SELECT pg_temp.vrai(pg_temp.issue_entretien('01') = 'annule' AND pg_temp.nb('01', 'b1') = 1 AND pg_temp.nb('01', 'b2') = 1,
  'a1 : la pause annule l''entretien et previent chaque personne qui le menait, une fois');
SELECT pg_temp.vrai(pg_temp.nb('01', 'b3') = 0 AND pg_temp.nb('01', 'a1') = 0 AND pg_temp.total('01') = 2,
  'a2 : un participant retire n''est pas prevenu, ni personne d''autre');
SELECT pg_temp.vrai(
  (SELECT count(*) FROM public.notifications n
    WHERE n.evenement = 'entretien_annule' AND n.destinataire = pg_temp.p('b1')
      AND n.params ->> 'cause' = 'pause' AND n.params ->> 'portee' = 'direction'
      AND n.params ->> 'reference' = (SELECT reference FROM public.candidatures WHERE id = pg_temp.c('01'))
      AND n.destination = '/admin/personnes/candidatures' AND n.foyer_id IS NULL) = 1,
  'a3 : la notification porte la cause (pause), la reference, la portee direction et la destination permise');
SELECT pg_temp.vrai(
  NOT EXISTS (SELECT 1 FROM public.notifications n WHERE n.evenement = 'entretien_annule'
                AND n.params::text ~* '(Fixture|Essai|Fictif|Pause demandee)'),
  'a4 : aucun nom ni motif dans la notification');

-- (b) Le refus : l'auteur, participant, n'est pas prevenu de son propre geste
SELECT pg_temp.en(pg_temp.p('a1'), 'admin', pg_catalog.format(
  'SELECT public.refuser_candidat(%L, %L, %L, %s, %L)',
  pg_temp.c('02'), 'Niveau', 'refus_niveau', pg_temp.v('02'), 'cle-notif-02'));
SELECT pg_temp.vrai(pg_temp.issue_entretien('02') = 'annule'
  AND pg_temp.nb('02', 'b1') = 1 AND pg_temp.nb('02', 'b2') = 1 AND pg_temp.nb('02', 'a1') = 0
  AND (SELECT n.params ->> 'cause' FROM public.notifications n
        WHERE n.evenement = 'entretien_annule' AND n.destinataire = pg_temp.p('b1')
          AND n.params ->> 'session_id' = pg_temp.s('02')::text) = 'refus',
  'b1 : le refus previent les autres participants (cause refus), pas l''auteur du geste meme s''il menait l''entretien');

-- (c) Le retrait
UPDATE public.candidatures SET issue = 'retiree' WHERE id = pg_temp.c('03');
SELECT pg_temp.vrai(pg_temp.issue_entretien('03') = 'annule' AND pg_temp.total('03') = 2
  AND (SELECT n.params ->> 'cause' FROM public.notifications n
        WHERE n.evenement = 'entretien_annule' AND n.destinataire = pg_temp.p('b2')
          AND n.params ->> 'session_id' = pg_temp.s('03')::text) = 'retrait',
  'c1 : un retrait previent aussi (cause retrait)');

-- (d) Sans entretien ouvert
UPDATE public.candidatures SET en_pause = true WHERE id = pg_temp.c('04');
SELECT pg_temp.vrai((SELECT count(*) FROM public.notifications WHERE evenement = 'entretien_annule'
                      AND params ->> 'session_id' IS NULL) = 0
  AND (SELECT count(*) FROM public.notifications WHERE evenement = 'entretien_annule') = 6,
  'd1 : un dossier sans entretien ouvert ne previent personne (6 notifications en tout)');

-- (e) La notification qui echoue n'annule pas l'annulation
SELECT pg_temp.qui(pg_temp.p('a1'), 'admin');
CREATE FUNCTION pg_temp.echec() RETURNS trigger LANGUAGE plpgsql AS $$
BEGIN RAISE EXCEPTION 'echec simule de la notification'; END $$;
GRANT EXECUTE ON FUNCTION pg_temp.echec() TO PUBLIC;
CREATE TRIGGER notif_echec BEFORE INSERT ON public.notifications
  FOR EACH ROW WHEN (NEW.evenement = 'entretien_annule') EXECUTE FUNCTION pg_temp.echec();
UPDATE public.candidatures SET en_pause = true WHERE id = pg_temp.c('05');
DROP TRIGGER notif_echec ON public.notifications;
SELECT pg_temp.vrai(pg_temp.issue_entretien('05') = 'annule' AND pg_temp.total('05') = 0
  AND (SELECT etat FROM public.candidatures WHERE id = pg_temp.c('05')) = 'entretien_a_planifier',
  'e1 : si la notification echoue, l''entretien est tout de meme annule et le dossier revient a planifier');

-- (f) La contrainte des evenements
SELECT pg_temp.vrai(
  (SELECT pg_get_constraintdef(oid) FROM pg_constraint WHERE conname = 'notifications_evenement_check')
    LIKE '%''entretien_annule''%'
  AND (SELECT count(*) FROM regexp_matches((SELECT pg_get_constraintdef(oid) FROM pg_constraint
        WHERE conname = 'notifications_evenement_check'), '''[a-z_]+''::text', 'g')) = 62
  AND (SELECT pg_get_constraintdef(oid) FROM pg_constraint WHERE conname = 'notifications_evenement_check')
        LIKE '%''annonce_direction''%',
  'f1 : la contrainte compte les 62 evenements, dont annonce_direction et entretien_annule');
SELECT pg_temp.vrai(
  NOT pg_catalog.has_function_privilege('authenticated', 'private.candidatures_entretien_suit()', 'EXECUTE')
  AND NOT pg_catalog.has_function_privilege('anon', 'private.candidatures_entretien_suit()', 'EXECUTE'),
  'g1 : le declencheur n''est executable par aucun client');

SELECT pg_temp.vrai(coalesce(nullif(current_setting('test.n', true), ''), '0')::int >= 11,
  'z : au moins 11 controles passes');
ROLLBACK;
