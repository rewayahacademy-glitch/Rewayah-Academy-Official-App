-- BE-1j DEPLACER-ENTRETIEN (carte des gestes, lot 3, T8) : migration 20261129760000_deplacer_entretien.sql.
--
-- Cas couverts : (a) la direction deplace le creneau d'un entretien planifie : l'ancien entretien est annule
-- (issue annule, seance canceled, rien n'est efface), un nouvel entretien aux memes participants au nouveau
-- creneau est cree, le dossier reste « entretien planifie », une version de plus, un evenement du dossier ;
-- (b) les avis existants : le candidat et les participants lisent « entretien_reserve » pour la NOUVELLE
-- seance, et jamais « entretien_a_replanifier » pour l'ancienne ; (c) motif, debut, duree, meme creneau, rejeu,
-- version ; (d) entretien deja commence, sans entretien ouvert, autre cote, personne occupee, role, sans session ;
-- (e) capacite, droits, empreinte F86.
-- Chaque controle leve 'DEPLACER ROUGE : ...' s'il echoue. A rejouer sur une base NEUVE ; le scenario annule tout.
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
    RAISE EXCEPTION 'DEPLACER ROUGE : %', p_label;
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

CREATE FUNCTION pg_temp.refus_en(p_id uuid, p_role text, p_sql text, p_code text, p_label text) RETURNS void
LANGUAGE plpgsql AS $$
DECLARE
  v_passe boolean := false;
  v_code text;
  v_msg text;
BEGIN
  PERFORM pg_temp.qui(p_id, p_role);
  BEGIN
    EXECUTE 'SET LOCAL ROLE authenticated';
    EXECUTE p_sql;
    v_passe := true;
    EXECUTE 'RESET ROLE';
  EXCEPTION WHEN OTHERS THEN
    v_code := SQLSTATE;
    v_msg := SQLERRM;
    EXECUTE 'RESET ROLE';
  END;
  IF v_passe THEN
    RAISE EXCEPTION 'DEPLACER ROUGE : % (aucun refus)', p_label;
  END IF;
  IF v_code <> p_code THEN
    RAISE EXCEPTION 'DEPLACER ROUGE : % (code % au lieu de % : %)', p_label, v_code, p_code, v_msg;
  END IF;
  PERFORM pg_temp.ok(p_label);
END $$;

CREATE FUNCTION pg_temp.p(p_n text) RETURNS uuid
LANGUAGE sql IMMUTABLE AS $$ SELECT ('de300000-0000-4000-8000-0000000000' || p_n)::uuid $$;
CREATE FUNCTION pg_temp.c(p_n text) RETURNS uuid
LANGUAGE sql IMMUTABLE AS $$ SELECT ('de30cccc-0000-4000-8000-0000000000' || p_n)::uuid $$;
CREATE FUNCTION pg_temp.s(p_n text) RETURNS uuid
LANGUAGE sql IMMUTABLE AS $$ SELECT ('de300000-0000-4000-8000-0000000003' || p_n)::uuid $$;
CREATE FUNCTION pg_temp.v(p_n text) RETURNS integer
LANGUAGE sql AS $$ SELECT version FROM public.candidatures WHERE id = pg_temp.c(p_n) $$;
CREATE FUNCTION pg_temp.etat(p_n text) RETURNS text
LANGUAGE sql AS $$ SELECT coalesce(etat, '-') FROM public.candidatures WHERE id = pg_temp.c(p_n) $$;
CREATE FUNCTION pg_temp.dep(p_n text, p_debut timestamptz, p_duree integer, p_motif text, p_version integer, p_cle text) RETURNS jsonb
LANGUAGE sql AS $$
  SELECT pg_temp.en(pg_temp.p('a1'), 'admin', pg_catalog.format(
    'SELECT public.deplacer_entretien(%L, %L, %s, %L, %s, %L)', pg_temp.c(p_n), p_debut, p_duree, p_motif, p_version, p_cle));
$$;
GRANT EXECUTE ON FUNCTION pg_temp.qui(uuid, text, text), pg_temp.ok(text), pg_temp.vrai(boolean, text),
  pg_temp.p(text), pg_temp.c(text), pg_temp.s(text), pg_temp.v(text), pg_temp.etat(text),
  pg_temp.dep(text, timestamptz, integer, text, integer, text), pg_temp.refus_en(uuid, text, text, text, text)
  TO authenticated, anon;

-- Fixtures (donnees inventees). a1 direction (homme) ; i1 et i2 menent les entretiens (direction, hommes).
-- 01 entretien planifie dans 2 jours (i1, i2) ; 02 entretien DEJA COMMENCE ; 03 entretien a planifier, sans
-- entretien ; 04 candidate (femme), entretien planifie ; 05 entretien planifie (i1) ; 06 occupe i1 plus tard.
SET LOCAL session_replication_role = replica;
INSERT INTO auth.users (id, email)
SELECT pg_temp.p(s), 'dp-' || s || '@test.invalid' FROM unnest(ARRAY['a1', 'b1', 'b2', '01', '02', '03', '04', '05', '06', '07']) AS s;
INSERT INTO public.profiles (id, immutable_id, role, first_name, last_name, account_status, gender)
SELECT pg_temp.p(s), 'DP-ADM-00' || s, 'admin', 'Direction', s, 'active', 'male' FROM unnest(ARRAY['a1', 'b1', 'b2']) AS s;
INSERT INTO public.profiles (id, immutable_id, role, first_name, last_name, account_status, gender)
SELECT pg_temp.p(s), 'DP-ENS-00' || s, 'teacher', 'Essai' || s, 'Fictif', 'pending_kyc',
       CASE WHEN s = '04' THEN 'female'::gender ELSE 'male'::gender END
FROM unnest(ARRAY['01', '02', '03', '04', '05', '06', '07']) AS s;
INSERT INTO public.candidatures (id, type_code, profile_id, genre, nom_complet, etape, etat, issue, source)
SELECT pg_temp.c(v.s), 'enseignant', pg_temp.p(v.s), v.g::gender, 'Fixture ' || v.s, 'verifications', v.etat, 'en_cours', 'lien_public'
FROM (VALUES ('01', 'male', 'entretien_planifie'), ('02', 'male', 'entretien_planifie'),
             ('03', 'male', 'entretien_a_planifier'), ('04', 'female', 'entretien_planifie'),
             ('05', 'male', 'entretien_planifie'), ('06', 'male', 'entretien_a_planifier'),
             ('07', 'male', 'entretien_planifie')) AS v(s, g, etat);
INSERT INTO public.sessions (id, teacher_id, started_at, ended_at, status, session_type, join_opens_at)
SELECT pg_temp.s(x.s), pg_temp.p('a1'), x.d, x.d + interval '30 minutes', 'planned', 'entretien', x.d - interval '10 minutes'
FROM (VALUES ('01', now() + interval '2 days'), ('02', now() - interval '1 hour'), ('04', now() + interval '2 days'),
             ('05', now() + interval '2 days'), ('07', now() + interval '2 days')) AS x(s, d);
INSERT INTO public.entretiens (session_id, candidature_id, candidat_id, planifie_par)
SELECT pg_temp.s(s), pg_temp.c(s), pg_temp.p(s), pg_temp.p('a1') FROM unnest(ARRAY['01', '02', '04', '05', '07']) AS s;
INSERT INTO public.entretien_participants (session_id, profile_id, fondateur, ajoute_par)
SELECT pg_temp.s(s), pg_temp.p(q), false, pg_temp.p('a1')
FROM (VALUES ('01', 'b1'), ('01', 'b2'), ('02', 'b1'), ('04', 'b1'), ('05', 'b1'), ('05', 'b2'), ('07', 'b1'), ('07', 'b2')) AS v(s, q);
INSERT INTO public.session_participants (session_id, profile_id, role)
SELECT pg_temp.s(s), pg_temp.p(q), 'intervieweur'::public.participant_role
FROM (VALUES ('01', 'b1'), ('01', 'b2'), ('02', 'b1'), ('04', 'b1'), ('05', 'b1'), ('05', 'b2'), ('07', 'b1'), ('07', 'b2')) AS v(s, q)
UNION ALL
SELECT pg_temp.s(s), pg_temp.p(s), 'candidat'::public.participant_role FROM unnest(ARRAY['01', '02', '04', '05', '07']) AS s;
-- 06 n'a pas d'entretien, mais i1 est pris dans 4 jours par un cours fictif (une seance d'entretien de 05 deplacee).
INSERT INTO public.sessions (id, teacher_id, started_at, ended_at, status, session_type, join_opens_at)
VALUES (pg_temp.s('90'), pg_temp.p('a1'), now() + interval '4 days', now() + interval '4 days 30 minutes', 'planned', 'entretien',
        now() + interval '4 days' - interval '10 minutes');
INSERT INTO public.session_participants (session_id, profile_id, role)
VALUES (pg_temp.s('90'), pg_temp.p('b1'), 'intervieweur');
-- Deux creneaux reserves par un candidat : celui de 01 est a venir, celui de 07 est (par fixture) deja passe.
INSERT INTO public.entretien_creneaux (id, cote, debut, duree_minutes, langues, ouvert_par, session_id, reserve_le)
VALUES (pg_temp.s('c1'), 'male', now() + interval '2 days', 30, ARRAY['ar'], pg_temp.p('a1'), pg_temp.s('01'), now()),
       (pg_temp.s('c7'), 'male', now() - interval '1 day', 30, ARRAY['ar'], pg_temp.p('a1'), pg_temp.s('07'), now());
INSERT INTO public.personnel_fondateurs (profile_id, fondateur, modifie_par)
SELECT pg_temp.p(q), true, pg_temp.p('a1') FROM unnest(ARRAY['b1', 'b2']) AS q;
SET LOCAL session_replication_role = origin;

-- (a) Le deplacement
SELECT set_config('test.v01', pg_temp.v('01')::text, true);
SELECT set_config('test.d01', (now() + interval '3 days')::text, true);
SELECT set_config('test.r01', pg_temp.dep('01', current_setting('test.d01')::timestamptz, 45,
  'Le candidat a demande un autre jour.', pg_temp.v('01'), 'cle-deplacer-01')::text, true);
SELECT pg_temp.vrai(
  current_setting('test.r01')::jsonb ? 'candidature' AND NOT current_setting('test.r01')::jsonb ? 'erreur'
  AND pg_temp.etat('01') = 'entretien_planifie' AND pg_temp.v('01') = current_setting('test.v01')::int + 1,
  'a1 : le deplacement reussit, le dossier reste entretien planifie, une version de plus');
SELECT pg_temp.vrai(
  (SELECT issue FROM public.entretiens WHERE session_id = pg_temp.s('01')) = 'annule'
  AND (SELECT status::text FROM public.sessions WHERE id = pg_temp.s('01')) = 'canceled'
  AND (SELECT count(*) FROM public.entretiens WHERE candidature_id = pg_temp.c('01')) = 2
  AND (SELECT count(*) FROM public.entretiens WHERE candidature_id = pg_temp.c('01') AND issue IS NULL) = 1,
  'a2 : l''ancien entretien est annule (seance canceled), rien n''est efface, un seul entretien reste ouvert');
SELECT pg_temp.vrai(
  (SELECT s.started_at = current_setting('test.d01')::timestamptz
          AND s.ended_at = current_setting('test.d01')::timestamptz + interval '45 minutes'
          AND s.status::text = 'planned' AND s.session_type = 'entretien'
          AND s.join_opens_at = s.started_at - interval '10 minutes'
     FROM public.entretiens e JOIN public.sessions s ON s.id = e.session_id
    WHERE e.candidature_id = pg_temp.c('01') AND e.issue IS NULL),
  'a3 : le nouvel entretien est au nouveau creneau (45 minutes), seance planifiee, ouverture 10 minutes avant');
SELECT pg_temp.vrai(
  (SELECT count(*) FROM public.entretien_participants ep JOIN public.entretiens e ON e.session_id = ep.session_id
    WHERE e.candidature_id = pg_temp.c('01') AND e.issue IS NULL AND ep.retire_le IS NULL
      AND ep.profile_id IN (pg_temp.p('b1'), pg_temp.p('b2'))) = 2
  AND (SELECT count(*) FROM public.session_participants sp JOIN public.entretiens e ON e.session_id = sp.session_id
        WHERE e.candidature_id = pg_temp.c('01') AND e.issue IS NULL) = 3
  AND (SELECT count(*) FROM public.session_participants sp JOIN public.entretiens e ON e.session_id = sp.session_id
        WHERE e.candidature_id = pg_temp.c('01') AND e.issue IS NULL AND sp.role = 'candidat') = 1,
  'a4 : les memes participants (deux intervieweurs) et le candidat sont inscrits a la nouvelle seance');
SELECT pg_temp.vrai(
  EXISTS (SELECT 1 FROM public.candidature_evenements e
           WHERE e.candidature_id = pg_temp.c('01') AND e.type = 'entretien'
             AND e.etat_avant = 'entretien_planifie' AND e.etat_apres = 'entretien_planifie'
             AND e.auteur_id = pg_temp.p('a1')
             AND e.details @> pg_catalog.jsonb_build_object('geste', 'deplacer_entretien', 'transition', 48,
                                                            'sessionAvant', pg_temp.s('01'))
             AND e.motif_interne LIKE 'Le candidat a demande%'),
  'a5 : un evenement du dossier garde l''ancienne et la nouvelle seance, le motif interne, l''auteur');
SELECT pg_temp.vrai(
  EXISTS (SELECT 1 FROM private.entretien_avis_envoyes WHERE session_id = pg_temp.s('01') AND sorte = 'a_replanifier'),
  'a6 : l''ancienne seance est marquee « a replanifier deja envoye » (le candidat ne lira pas « n''a pas eu lieu »)');

-- (a bis) Le creneau reserve de l'ancienne seance : a venir, il est rouvert ; passe, il reste tel quel
SELECT pg_temp.vrai(
  (SELECT session_id IS NULL AND reserve_le IS NULL AND annule_le IS NULL FROM public.entretien_creneaux WHERE id = pg_temp.s('c1'))
  AND current_setting('test.r01')::jsonb IS NOT NULL
  AND EXISTS (SELECT 1 FROM public.candidature_evenements e WHERE e.candidature_id = pg_temp.c('01')
               AND e.details ->> 'creneauRouvert' = pg_temp.s('c1')::text),
  'a7 : le creneau reserve de l''ancienne seance, a venir, est rouvert (libre pour un autre) et l''evenement le dit');
SELECT pg_temp.dep('07', now() + interval '3 days 2 hours', 30, 'Autre jour', pg_temp.v('07'), 'cle-deplacer-07');
SELECT pg_temp.vrai(
  (SELECT session_id FROM public.entretien_creneaux WHERE id = pg_temp.s('c7')) = pg_temp.s('07')
  AND (SELECT issue FROM public.entretiens WHERE session_id = pg_temp.s('07')) = 'annule',
  'a8 : un creneau deja passe reste lie a l''ancienne seance (le deplacement reussit quand meme)');

-- (b) Les avis existants, pour la nouvelle seance seulement
SELECT private.entretien_avis_passer(pg_catalog.now());
SELECT pg_temp.vrai(
  (SELECT count(*) FROM public.notifications n WHERE n.destinataire = pg_temp.p('01')
     AND n.evenement = 'entretien_reserve') = 1
  AND NOT EXISTS (SELECT 1 FROM public.notifications n WHERE n.destinataire = pg_temp.p('01')
                   AND n.evenement = 'entretien_a_replanifier'),
  'b1 : le candidat lit « entretien reserve » pour la nouvelle seance et jamais « entretien a replanifier »');
SELECT pg_temp.vrai(
  (SELECT count(*) FROM public.notifications n WHERE n.destinataire IN (pg_temp.p('b1'), pg_temp.p('b2'))
     AND n.evenement = 'entretien_reserve'
     AND n.params ->> 'session_id' = (SELECT e.session_id::text FROM public.entretiens e
                                       WHERE e.candidature_id = pg_temp.c('01') AND e.issue IS NULL)) >= 2,
  'b2 : les deux intervieweurs lisent l''avis de la nouvelle seance');

-- (c) Les exigences
SELECT pg_temp.vrai(
  pg_temp.dep('05', now() + interval '3 days', 30, '   ', pg_temp.v('05'), 'cle-deplacer-05a') ->> 'erreur' = 'motif_requis'
  AND (SELECT issue FROM public.entretiens WHERE session_id = pg_temp.s('05')) IS NULL,
  'c1 : sans motif ecrit, rien n''est ecrit (motif_requis)');
SELECT pg_temp.vrai(
  pg_temp.dep('05', now() + interval '1 minute', 30, 'Motif', pg_temp.v('05'), 'cle-deplacer-05b') ->> 'erreur' = 'debut_invalide'
  AND pg_temp.dep('05', now() + interval '200 days', 30, 'Motif', pg_temp.v('05'), 'cle-deplacer-05c') ->> 'erreur' = 'debut_invalide',
  'c2 : un debut dans moins de 5 minutes ou au-dela de 90 jours est refuse');
SELECT pg_temp.vrai(
  pg_temp.dep('05', now() + interval '3 days', 10, 'Motif', pg_temp.v('05'), 'cle-deplacer-05d') ->> 'erreur' = 'duree_invalide'
  AND pg_temp.dep('05', now() + interval '3 days', 30, 'Motif', pg_temp.v('05') + 9, 'cle-deplacer-05e') ->> 'erreur' = 'conflit_candidature',
  'c3 : une duree hors 15 a 120 minutes et une version perimee sont refusees');
SELECT pg_temp.vrai(
  pg_temp.dep('05', (SELECT started_at FROM public.sessions WHERE id = pg_temp.s('05')), 30, 'Motif', pg_temp.v('05'), 'cle-deplacer-05f') ->> 'erreur' = 'meme_creneau',
  'c4 : le meme creneau est refuse (meme_creneau)');
SELECT pg_temp.vrai(
  (pg_temp.dep('01', current_setting('test.d01')::timestamptz, 45, 'Le candidat a demande un autre jour.', 1, 'cle-deplacer-01') - 'rejoue')
    = (current_setting('test.r01')::jsonb - 'rejoue')
  AND (SELECT count(*) FROM public.entretiens WHERE candidature_id = pg_temp.c('01')) = 2,
  'c5 : rejouer la meme cle rend le meme resultat sans nouvel entretien');

-- (d) Les refus de portee
SELECT pg_temp.vrai(
  pg_temp.dep('02', now() + interval '3 days', 30, 'Motif', pg_temp.v('02'), 'cle-deplacer-02') ->> 'erreur' = 'entretien_commence'
  AND (SELECT issue FROM public.entretiens WHERE session_id = pg_temp.s('02')) IS NULL,
  'd1 : un entretien deja commence ne se deplace pas');
SELECT pg_temp.vrai(
  pg_temp.dep('03', now() + interval '3 days', 30, 'Motif', pg_temp.v('03'), 'cle-deplacer-03') ->> 'erreur' = 'transition_interdite',
  'd2 : sans entretien planifie (entretien a planifier), le geste est interdit');
SELECT pg_temp.vrai(
  pg_temp.dep('04', now() + interval '3 days', 30, 'Motif', pg_temp.v('04'), 'cle-deplacer-04') ->> 'erreur' = 'hors_portee',
  'd3 : une candidate de l''autre cote est hors de portee');
SELECT pg_temp.vrai(
  pg_temp.dep('05', (SELECT started_at FROM public.sessions WHERE id = pg_temp.s('90')) + interval '10 minutes', 30, 'Motif',
              pg_temp.v('05'), 'cle-deplacer-05g') ->> 'erreur' = 'personne_occupee'
  AND (SELECT issue FROM public.entretiens WHERE session_id = pg_temp.s('05')) IS NULL,
  'd4 : un intervieweur deja pris sur la nouvelle periode bloque le deplacement, rien n''est annule');
SELECT pg_temp.refus_en(pg_temp.p('01'), 'teacher',
  pg_catalog.format($q$SELECT public.deplacer_entretien(%L, now() + interval '3 days', 30, 'Motif', 1, 'cle-deplacer-x')$q$, pg_temp.c('05')),
  '42501', 'd5 : un enseignant ne deplace pas un entretien');
SELECT pg_temp.refus_en(NULL, NULL,
  pg_catalog.format($q$SELECT public.deplacer_entretien(%L, now() + interval '3 days', 30, 'Motif', 1, 'cle-deplacer-y')$q$, pg_temp.c('05')),
  '42501', 'd6 : sans session, refus');

-- (e) Capacite, droits, empreinte
SELECT pg_temp.vrai(
  (pg_temp.en(pg_temp.p('a1'), 'admin', 'SELECT public.capacites_candidatures()') #>> '{gestes,deplacerEntretien}') = 'true',
  'e1 : capacites_candidatures dit deplacerEntretien');
SELECT pg_temp.vrai(
  NOT has_function_privilege('anon', 'public.deplacer_entretien(uuid,timestamptz,integer,text,integer,text)', 'EXECUTE')
  AND has_function_privilege('authenticated', 'public.deplacer_entretien(uuid,timestamptz,integer,text,integer,text)', 'EXECUTE')
  AND (SELECT bool_and(NOT has_function_privilege(r, 'private.candidature_geste_deplacer_entretien(uuid,timestamptz,integer,uuid,integer,text,text)', 'EXECUTE'))
         FROM unnest(ARRAY['anon', 'authenticated', 'service_role', 'agent_ro']) AS r),
  'e2 : la porte est pour les comptes connectes ; le coeur prive n''est ouvert a personne');
SELECT pg_temp.vrai(
  (SELECT obj_description(f, 'pg_proc') LIKE '%md5_functiondef=' || md5(pg_get_functiondef(f)) || ';%'
     FROM (SELECT 'public.deplacer_entretien(uuid,timestamptz,integer,text,integer,text)'::regprocedure AS f) x),
  'e3 : l''empreinte F86 est celle de la definition installee');

SELECT pg_temp.vrai(coalesce(nullif(current_setting('test.n', true), ''), '0')::int >= 24,
  'z : au moins 24 controles passes');
ROLLBACK;
