-- LP-1 serveur (SPEC-LISTE-PERSONNES, 16/11/2026) : migration 20261129400000_lp1_liste_enseignants.sql.
--
-- Cas couverts : (a) la phase de chaque enseignant (candidat, accueil, disponible, en_poste, absent,
-- pause, suspendu, parti) et ce qui manque en accueil ; (b) les compteurs par phase, sans les autres
-- filtres ; (c) les filtres (phase, partis, recherche) ; (d) la vie de l'enseignant sur la ligne (classes,
-- heures, prochaine seance, remplacements sur 30 jours, coordonnees de versement) ; (e) qui attend quoi ;
-- (f) les gestes permis par ligne (moteur des candidatures) et ceux qui se groupent, et les actions de
-- phase ; (g) la portee par genre ; (h) les refus (role, filtres, tri, page) ; (i) aucune ecriture sur les
-- candidatures, un audit par liste ; (j) droits et empreinte F86.
-- Chaque controle leve 'LP1 ROUGE : ...' s'il echoue. A rejouer sur une base NEUVE ; le scenario annule tout.
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
    RAISE EXCEPTION 'LP1 ROUGE : %', p_label;
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
    RAISE EXCEPTION 'LP1 ROUGE : % (aucun refus)', p_label;
  END IF;
  IF v_code <> p_code THEN
    RAISE EXCEPTION 'LP1 ROUGE : % (code % au lieu de % : %)', p_label, v_code, p_code, v_msg;
  END IF;
  PERFORM pg_temp.ok(p_label);
END $$;

CREATE FUNCTION pg_temp.p(p_n text) RETURNS uuid
LANGUAGE sql IMMUTABLE AS $$ SELECT ('1e100000-0000-4000-8000-0000000000' || p_n)::uuid $$;
CREATE FUNCTION pg_temp.c(p_n text) RETURNS uuid
LANGUAGE sql IMMUTABLE AS $$ SELECT ('1e10cccc-0000-4000-8000-0000000000' || p_n)::uuid $$;
CREATE FUNCTION pg_temp.liste(p_filtre jsonb, p_qui text DEFAULT 'a1') RETURNS jsonb
LANGUAGE sql AS $$
  SELECT pg_temp.en(pg_temp.p(p_qui), 'admin',
    pg_catalog.format('SELECT public.lister_enseignants(%L::jsonb, ''recente'', 1)', p_filtre::text));
$$;
CREATE FUNCTION pg_temp.refs(p_page jsonb) RETURNS text[]
LANGUAGE sql AS $$
  SELECT coalesce(array_agg(right(t.l ->> 'id', 2) ORDER BY right(t.l ->> 'id', 2)), ARRAY[]::text[])
    FROM jsonb_array_elements(p_page -> 'lignes') AS t(l);
$$;
CREATE FUNCTION pg_temp.ligne(p_n text, p_filtre jsonb DEFAULT '{"partis": true}') RETURNS jsonb
LANGUAGE sql AS $$
  SELECT l FROM jsonb_array_elements(pg_temp.liste(p_filtre) -> 'lignes') AS t(l) WHERE right(l ->> 'id', 2) = p_n;
$$;
GRANT EXECUTE ON FUNCTION pg_temp.qui(uuid, text, text), pg_temp.ok(text), pg_temp.vrai(boolean, text),
  pg_temp.p(text), pg_temp.c(text), pg_temp.refs(jsonb), pg_temp.liste(jsonb, text), pg_temp.ligne(text, jsonb)
  TO authenticated, anon;

-- ------------------------------------------------------------
-- Fixtures (donnees inventees)
-- ------------------------------------------------------------
-- a1 direction (homme), a2 direction (femme). Enseignants (hommes sauf 08) :
-- 01 candidat en examen ; 02 candidature refusee ; 03 confirme et pret, sans classe (disponible) ;
-- 04 confirme sans photo (accueil) ; 05 en poste (une classe d'une heure par semaine, une seance a venir) ;
-- 06 confirme en pause ; 07 compte desactive ; 08 une enseignante prete (autre genre) ; 09 en poste avec une
-- absence declaree sans remplacant (absent) ; 10 compte supprime (parti).
SET LOCAL session_replication_role = replica;
INSERT INTO auth.users (id, email)
SELECT pg_temp.p(s), 'lp1-' || s || '@test.invalid'
FROM unnest(ARRAY['a1', 'a2', '01', '02', '03', '04', '05', '06', '07', '08', '09', '10']) AS s;
INSERT INTO public.profiles (id, immutable_id, role, first_name, last_name, account_status, gender)
VALUES (pg_temp.p('a1'), 'LP1-ADM-0001', 'admin', 'Direction', 'Un', 'active', 'male'),
       (pg_temp.p('a2'), 'LP1-ADM-0002', 'admin', 'Direction', 'Deux', 'active', 'female');
INSERT INTO public.profiles (id, immutable_id, role, first_name, last_name, account_status, gender, deleted_at)
SELECT pg_temp.p(s), 'LP1-ENS-00' || s, 'teacher', 'Essai' || s, 'Fictif',
       CASE WHEN s = '07' THEN 'disabled'::public.account_status WHEN s IN ('01', '02') THEN 'pending_kyc'::public.account_status ELSE 'active'::public.account_status END,
       CASE WHEN s = '08' THEN 'female'::gender ELSE 'male'::gender END,
       CASE WHEN s = '10' THEN now() ELSE NULL END
FROM unnest(ARRAY['01', '02', '03', '04', '05', '06', '07', '08', '09', '10']) AS s;
INSERT INTO public.teacher_profiles (profile_id, languages, weekly_hours_cap, kyc_status, timezone_iana, photo_storage_key)
SELECT pg_temp.p(s), ARRAY['francais'], 10, 'approved', 'Europe/Paris', CASE WHEN s = '04' THEN NULL ELSE 'photo-' || s END
FROM unnest(ARRAY['03', '04', '05', '06', '07', '08', '09', '10']) AS s;
INSERT INTO public.weekly_availability (profile_id, weekday, hour_local, timezone_iana)
SELECT pg_temp.p(s), 1, 18, 'Europe/Paris' FROM unnest(ARRAY['03', '04', '05', '06', '07', '08', '09', '10']) AS s;
INSERT INTO public.candidatures (id, type_code, profile_id, genre, nom_complet, etape, etat, issue, en_pause, source, recue_le)
SELECT pg_temp.c(v.s), 'enseignant', pg_temp.p(v.s), v.g::gender, 'Fixture ' || v.s,
       v.etape, v.etat, v.issue, v.pause, 'lien_public', now() - interval '20 days'
FROM (VALUES
  ('01', 'male', 'prequalification', 'en_examen', 'en_cours', false),
  ('02', 'male', 'prequalification', 'en_examen', 'refusee', false),
  ('03', 'male', 'confirmee', NULL, 'en_cours', false),
  ('04', 'male', 'confirmee', NULL, 'en_cours', false),
  ('05', 'male', 'confirmee', NULL, 'en_cours', false),
  ('06', 'male', 'confirmee', NULL, 'en_cours', true),
  ('07', 'male', 'confirmee', NULL, 'en_cours', false),
  ('08', 'female', 'confirmee', NULL, 'en_cours', false),
  ('09', 'male', 'confirmee', NULL, 'en_cours', false),
  ('10', 'male', 'confirmee', NULL, 'en_cours', false)) AS v(s, g, etape, etat, issue, pause);
INSERT INTO public.groupes (id, teacher_id, type_public, seuil_max, libelle, weekday, hour_local, timezone_iana, langue_code, genre_public, niveau, etat)
VALUES ('1e100000-0000-4000-8000-000000000201', pg_temp.p('05'), 'enfant', 5, 'LP1 G5', 1, 18, 'Europe/Paris', 'francais', 'hommes', 'debut_lettres', 'active'),
       ('1e100000-0000-4000-8000-000000000202', pg_temp.p('09'), 'enfant', 5, 'LP1 G9', 2, 18, 'Europe/Paris', 'francais', 'hommes', 'debut_lettres', 'active');
INSERT INTO public.groupe_creneaux (groupe_id, weekday, hour_local, duree_minutes)
VALUES ('1e100000-0000-4000-8000-000000000201', 1, 18, 60), ('1e100000-0000-4000-8000-000000000202', 2, 18, 30);
INSERT INTO public.sessions (id, teacher_id, started_at, ended_at, status, session_type, groupe_id) VALUES
 ('1e100000-0000-4000-8000-000000000301', pg_temp.p('05'), now() + interval '2 days', now() + interval '2 days 1 hour', 'planned', 'standard', '1e100000-0000-4000-8000-000000000201'),
 ('1e100000-0000-4000-8000-000000000302', pg_temp.p('09'), now() + interval '3 days', now() + interval '3 days 1 hour', 'planned', 'standard', '1e100000-0000-4000-8000-000000000202'),
 ('1e100000-0000-4000-8000-000000000303', pg_temp.p('09'), now() + interval '4 days', now() + interval '4 days 1 hour', 'planned', 'standard', '1e100000-0000-4000-8000-000000000202');
-- 09 : une absence sans remplacant (302) et une absence remplacee par 05 (303).
INSERT INTO public.remplacements_seance (session_id, evenement, enseignant_titulaire_id, enseignant_remplacant_id, acteur_id, cle_idempotence, origine)
VALUES ('1e100000-0000-4000-8000-000000000302', 'absence_declaree', pg_temp.p('09'), NULL, pg_temp.p('09'), gen_random_uuid(), 'manuelle'),
       ('1e100000-0000-4000-8000-000000000303', 'absence_declaree', pg_temp.p('09'), NULL, pg_temp.p('09'), gen_random_uuid(), 'manuelle'),
       ('1e100000-0000-4000-8000-000000000303', 'remplacement_pris', pg_temp.p('09'), pg_temp.p('05'), pg_temp.p('05'), gen_random_uuid(), 'manuelle');
SET LOCAL session_replication_role = origin;
SELECT set_config('test.versions', (SELECT sum(version)::text FROM public.candidatures WHERE id::text LIKE '1e10cccc%'), true);
SELECT set_config('test.audits', (SELECT count(*)::text FROM public.audit_logs WHERE action = 'enseignants_liste'), true);

-- ------------------------------------------------------------
-- (a) Les phases
-- ------------------------------------------------------------
SELECT pg_temp.vrai(
  pg_temp.ligne('01') ->> 'phase' = 'candidat' AND pg_temp.ligne('02') ->> 'phase' = 'candidat'
  AND pg_temp.ligne('03') ->> 'phase' = 'disponible' AND pg_temp.ligne('04') ->> 'phase' = 'accueil'
  AND pg_temp.ligne('05') ->> 'phase' = 'en_poste' AND pg_temp.ligne('06') ->> 'phase' = 'pause'
  AND pg_temp.ligne('07') ->> 'phase' = 'suspendu' AND pg_temp.ligne('09') ->> 'phase' = 'absent'
  AND pg_temp.ligne('10') ->> 'phase' = 'parti',
  'a1 : chaque enseignant a sa phase (candidat, refuse reste candidat, disponible, accueil, en poste, pause, suspendu, absent, parti)');
SELECT pg_temp.vrai(
  (pg_temp.ligne('04') -> 'manque') = '["photo_absente"]'::jsonb
  AND (pg_temp.ligne('03') -> 'manque') = '[]'::jsonb,
  'a2 : en accueil, la ligne dit ce qui manque (la photo) ; un enseignant disponible n''a rien a lui');
SELECT pg_temp.vrai(
  pg_temp.refs(pg_temp.liste('{}')) = ARRAY['01', '02', '03', '04', '05', '06', '07', '09'],
  'a3 : par defaut, ni l''enseignant parti ni l''enseignante de l''autre genre');

-- ------------------------------------------------------------
-- (b) Les compteurs, toute la portee, sans les autres filtres
-- ------------------------------------------------------------
SELECT pg_temp.vrai(
  pg_temp.liste('{"phase": "disponible"}') -> 'compteursPhases'
  = '{"candidat": 2, "accueil": 1, "disponible": 1, "en_poste": 1, "absent": 1, "pause": 1, "suspendu": 1, "parti": 1,
      "nouveaux": 0, "sansDossier": 0}'::jsonb,
  'b1 : compteurs par phase (a1 ne compte pas l''enseignante de l''autre genre), identiques quel que soit le filtre');

-- ------------------------------------------------------------
-- (c) Les filtres
-- ------------------------------------------------------------
SELECT pg_temp.vrai(
  pg_temp.refs(pg_temp.liste('{"phase": "disponible"}')) = ARRAY['03']
  AND pg_temp.refs(pg_temp.liste('{"phase": "parti"}')) = ARRAY['10']
  AND pg_temp.refs(pg_temp.liste('{"partis": true}')) = ARRAY['01', '02', '03', '04', '05', '06', '07', '09', '10']
  AND pg_temp.refs(pg_temp.liste('{"avecClasse": true}')) = ARRAY['05', '09']
  AND pg_temp.refs(pg_temp.liste('{"enPause": true}')) = ARRAY['06']
  AND pg_temp.refs(pg_temp.liste('{"issue": "refusee"}')) = ARRAY['02'],
  'c1 : filtres phase, partis, avecClasse, enPause, issue');
SELECT pg_temp.vrai(
  pg_temp.refs(pg_temp.liste(pg_catalog.jsonb_build_object('recherche',
     (SELECT reference FROM public.candidatures WHERE id = pg_temp.c('03'))))) = ARRAY['03']
  AND pg_temp.refs(pg_temp.liste('{"recherche": "fixture 04"}')) = ARRAY['04'],
  'c2 : la recherche trouve par reference et par nom');

-- ------------------------------------------------------------
-- (d) La vie de l'enseignant sur la ligne
-- ------------------------------------------------------------
SELECT pg_temp.vrai(
  pg_temp.ligne('05') #>> '{classes,nombre}' = '1' AND (pg_temp.ligne('05') #>> '{classes,heuresSemaine}')::numeric = 1
  AND pg_temp.ligne('05') ->> 'prochaineSeance' IS NOT NULL
  AND pg_temp.ligne('03') #>> '{classes,nombre}' = '0' AND pg_temp.ligne('03') ->> 'prochaineSeance' IS NULL,
  'd1 : classes (nombre, heures par semaine) et prochaine seance');
SELECT pg_temp.vrai(
  pg_temp.ligne('05') #>> '{remplacements30j,donnes}' = '1' AND pg_temp.ligne('05') #>> '{remplacements30j,recus}' = '0'
  AND pg_temp.ligne('09') #>> '{remplacements30j,recus}' = '1' AND pg_temp.ligne('09') #>> '{remplacements30j,donnes}' = '0',
  'd2 : remplacements donnes et recus sur 30 jours');
SELECT pg_temp.vrai(pg_temp.ligne('03') ->> 'coordonneesVersement' = 'false'
  AND pg_temp.ligne('03') ? 'derniereActivite' AND pg_temp.ligne('03') ? 'nouveau' AND pg_temp.ligne('03') ? 'reference',
  'd3 : la ligne garde les cles de la ligne de candidature, plus la vie de l''enseignant');

-- ------------------------------------------------------------
-- (e) Qui attend quoi
-- ------------------------------------------------------------
SELECT pg_temp.vrai(
  pg_temp.ligne('01') ->> 'quiAttend' = 'direction' AND pg_temp.ligne('04') ->> 'quiAttend' = 'enseignant'
  AND pg_temp.ligne('03') ->> 'quiAttend' = 'direction' AND pg_temp.ligne('05') ->> 'quiAttend' IS NULL
  AND pg_temp.ligne('02') ->> 'quiAttend' IS NULL,
  'e1 : un candidat en examen attend la direction, un enseignant en accueil attend l''enseignant, un disponible attend une classe, un candidat refuse n''attend personne');

-- ------------------------------------------------------------
-- (f) Les gestes par ligne et les actions de phase
-- ------------------------------------------------------------
SELECT pg_temp.vrai(
  (pg_temp.ligne('01') -> 'gestes') @> '["refuser", "demander_complement", "mettre_en_pause", "definir_responsable"]'::jsonb
  AND NOT (pg_temp.ligne('01') -> 'gestes') @> '["lever_pause"]'::jsonb
  AND (pg_temp.ligne('01') -> 'gestesGroupables') @> '["refuser", "mettre_en_pause"]'::jsonb
  AND NOT (pg_temp.ligne('01') -> 'gestesGroupables') @> '["demander_complement"]'::jsonb
  AND (pg_temp.ligne('06') -> 'gestes') @> '["lever_pause"]'::jsonb
  AND (pg_temp.ligne('02') -> 'gestes') @> '["rouvrir"]'::jsonb,
  'f1 : les gestes viennent du moteur des candidatures, par etape et par etat ; la pause propose lever_pause, un refus propose rouvrir ; les gestes groupables sont ceux que le moteur marque groupables');
SELECT pg_temp.vrai(
  pg_temp.ligne('03') -> 'actionsPhase' = '["affecter_classe"]'::jsonb
  AND pg_temp.ligne('05') -> 'actionsPhase' = '["reaffecter_classe"]'::jsonb
  AND pg_temp.ligne('01') -> 'actionsPhase' = '[]'::jsonb,
  'f2 : l''action de phase est affecter pour un disponible, reaffecter pour un enseignant en poste ou absent');

-- ------------------------------------------------------------
-- (g) La portee par genre
-- ------------------------------------------------------------
SELECT pg_temp.vrai(
  pg_temp.refs(pg_temp.liste('{}', 'a2')) = ARRAY['08']
  AND (pg_temp.liste('{}', 'a2') #>> '{compteursPhases,disponible}') = '1'
  AND (pg_temp.liste('{}', 'a2') #>> '{compteursPhases,candidat}') = '0',
  'g1 : la direction d''un genre ne voit, ne compte et ne trouve que les enseignants de son genre');

-- ------------------------------------------------------------
-- (h) Les refus
-- ------------------------------------------------------------
SELECT pg_temp.refus_en(pg_temp.p('03'), 'teacher', $$SELECT public.lister_enseignants('{}'::jsonb, 'recente', 1)$$, '42501',
  'h1 : un enseignant ne lit pas la liste');
SELECT pg_temp.refus_en(NULL, NULL, $$SELECT public.lister_enseignants('{}'::jsonb, 'recente', 1)$$, '42501',
  'h2 : sans session, refus');
SELECT pg_temp.refus_en(pg_temp.p('a1'), 'admin', $$SELECT public.lister_enseignants('{"inconnu": 1}'::jsonb, 'recente', 1)$$, '22023',
  'h3 : une cle de filtre inconnue est refusee');
SELECT pg_temp.refus_en(pg_temp.p('a1'), 'admin', $$SELECT public.lister_enseignants('{"nouveau": "oui"}'::jsonb, 'recente', 1)$$, '22023',
  'h4 : un filtre mal type est refuse');
SELECT pg_temp.refus_en(pg_temp.p('a1'), 'admin', $$SELECT public.lister_enseignants('{"phase": "retraite"}'::jsonb, 'recente', 1)$$, '22023',
  'h5 : une phase inconnue est refusee');
SELECT pg_temp.refus_en(pg_temp.p('a1'), 'admin', $$SELECT public.lister_enseignants('{}'::jsonb, 'au_hasard', 1)$$, '22023',
  'h6 : un tri inconnu est refuse');
SELECT pg_temp.refus_en(pg_temp.p('a1'), 'admin', $$SELECT public.lister_enseignants('{}'::jsonb, 'recente', 0)$$, '22023',
  'h7 : la page 0 est refusee');
SELECT pg_temp.vrai(pg_temp.refs(pg_temp.en(pg_temp.p('a1'), 'admin',
    $$SELECT public.lister_enseignants('{}'::jsonb, 'nom', 2)$$)) = ARRAY[]::text[]
  AND (pg_temp.liste('{}') ->> 'taillePage') = '50',
  'h8 : la page 2 est vide, la taille de page est 50');

-- ------------------------------------------------------------
-- (i) Aucune ecriture sur les candidatures, un audit par liste
-- ------------------------------------------------------------
SELECT pg_temp.vrai(
  (SELECT sum(version)::text FROM public.candidatures WHERE id::text LIKE '1e10cccc%') = current_setting('test.versions')
  AND (SELECT count(*) FROM public.audit_logs WHERE action = 'enseignants_liste') > current_setting('test.audits')::int,
  'i1 : lire la liste ne change aucune candidature ; chaque liste est tracee');

-- ------------------------------------------------------------
-- (j) Droits et empreinte
-- ------------------------------------------------------------
SELECT pg_temp.vrai(
  NOT has_function_privilege('anon', 'public.lister_enseignants(jsonb,text,integer)', 'EXECUTE')
  AND has_function_privilege('authenticated', 'public.lister_enseignants(jsonb,text,integer)', 'EXECUTE')
  AND (SELECT bool_and(NOT has_function_privilege(r, f::regprocedure, 'EXECUTE'))
         FROM unnest(ARRAY['anon', 'authenticated', 'service_role', 'agent_ro']) AS r,
              unnest(ARRAY['private.lp_phase(public.candidatures)', 'private.lp_gestes(public.candidatures,boolean)',
                           'private.lp_qui_attend(public.candidatures,text)', 'private.lp_ligne_json(public.candidatures,boolean)']) AS f),
  'j1 : la liste est pour les comptes connectes, jamais pour anon ; les aides privees ne sont executables par personne');
SELECT pg_temp.vrai(
  obj_description('public.lister_enseignants(jsonb,text,integer)'::regprocedure, 'pg_proc')
    LIKE '%md5_functiondef=' || md5(pg_get_functiondef('public.lister_enseignants(jsonb,text,integer)'::regprocedure)) || ';%',
  'j2 : l''empreinte F86 est celle de la definition installee');

SELECT pg_temp.vrai(coalesce(nullif(current_setting('test.n', true), ''), '0')::int >= 22,
  'z : au moins 22 controles passes');
ROLLBACK;
