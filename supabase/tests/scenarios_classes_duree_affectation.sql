-- CLASSES-DUREE (22/10/2026) : l'affectation d'un enseignant couvre TOUTE la
-- duree de la seance de la Classe (90 minutes pour les adultes).
-- Migration 20261022000400_classes_affectation_couvre_toute_la_duree.sql ;
-- defaut : CANDIDATURES/SPEC_CONSOLIDEE_CANDIDATURES_2026-10-21.md, 2.1 bis.
--
-- A rejouer sur une base NEUVE (stub_auth puis toutes les migrations). Le
-- scenario pose ses fixtures (aucune donnee personnelle), appelle le vrai
-- predicat (app_private.verifier_affectation_enseignant_base, son enveloppe,
-- tc_verifier_affectation_enseignant, creer_groupe, enseignants_pour_classe,
-- affecter_enseignant_classe_c11bis), et annule tout a la fin.
--   (a) la duree de la Classe : celle de son offre, sinon le reglage de son
--       public ; un public inconnu ou une duree absurde refusent ;
--   (b) cours d'enfants de 60 minutes : couvert par UNE heure ;
--   (c) cours d'adultes de 90 minutes : refuse avec UNE heure, avec une heure
--       qui commence trop tard, avec un trou ; accepte avec DEUX heures ;
--   (d) le cours qui passe minuit : le jour suivant, et la semaine suivante
--       apres le dimanche soir ;
--   (e) un fuseau different de celui de la Classe, les deux saisons, et une
--       grille decalee d'une demi-heure (Calcutta) : compares en instants ;
--   (f) la duree vient de l'offre ou du reglage, et suit un changement du
--       reglage par la direction ;
--   (g) collisions avec la duree propre a chaque Classe ;
--   (h) plafond horaire avec la duree propre a chaque Classe ;
--   (i) les refus nommes existants et le plafond de Classes restent intacts ;
--       le verrou par enseignant est pris ;
--   (j) par les vraies RPC : proposition d'enseignants, affectation, creation ;
--   (k) droits et forme des fonctions ;
--   (l) le moment de la verification : instant_creneau rend la PROCHAINE
--       occurrence apres maintenant, la ligne d'une grille decalee qui couvre le
--       debut de la prochaine seance a pu commencer il y a moins d'une heure ;
--       l'horloge est alors fixee (reprise du 22/10).
-- Chaque controle leve 'CLASSES-DUREE ROUGE : ...' s'il echoue.
\o /dev/null
BEGIN;

CREATE FUNCTION pg_temp.qui(p_id uuid, p_role text) RETURNS void
LANGUAGE plpgsql AS $$
DECLARE v_jwt text;
BEGIN
  v_jwt := CASE WHEN p_id IS NULL AND p_role IS NULL THEN '{}'
                ELSE pg_catalog.json_build_object(
                       'sub', p_id, 'role', 'authenticated', 'aal', 'aal2',
                       'app_metadata', CASE WHEN p_role IS NULL THEN pg_catalog.json_build_object()
                                            ELSE pg_catalog.json_build_object('role', p_role) END)::text END;
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
    RAISE EXCEPTION 'CLASSES-DUREE ROUGE : %', p_label;
  END IF;
  PERFORM pg_temp.ok(p_label);
END $$;

-- Un appel doit etre refuse avec ce SQLSTATE et un message qui commence ainsi.
CREATE FUNCTION pg_temp.refus(p_sql text, p_code text, p_message text, p_label text) RETURNS void
LANGUAGE plpgsql AS $$
BEGIN
  BEGIN
    EXECUTE p_sql;
    RAISE EXCEPTION 'CLASSES-DUREE ROUGE : % (aucun refus)', p_label USING ERRCODE = 'P0001';
  EXCEPTION WHEN OTHERS THEN
    IF SQLSTATE IS DISTINCT FROM p_code OR SQLERRM NOT LIKE p_message || '%' THEN
      RAISE EXCEPTION 'CLASSES-DUREE ROUGE : % (%, « % » au lieu de %, « % »)',
        p_label, SQLSTATE, SQLERRM, p_code, p_message;
    END IF;
  END;
  PERFORM pg_temp.ok(p_label);
END $$;

-- Les enseignants et les classes se nomment par un code court.
CREATE TEMP TABLE dur_t (code text PRIMARY KEY, id uuid NOT NULL) ON COMMIT DROP;
CREATE TEMP TABLE dur_c (code text PRIMARY KEY, id uuid NOT NULL) ON COMMIT DROP;
GRANT SELECT ON dur_t, dur_c TO authenticated;
CREATE FUNCTION pg_temp.t(p_code text) RETURNS uuid
LANGUAGE sql STABLE AS $$ SELECT id FROM dur_t WHERE code = p_code; $$;
CREATE FUNCTION pg_temp.c(p_code text) RETURNS uuid
LANGUAGE sql STABLE AS $$ SELECT id FROM dur_c WHERE code = p_code; $$;

-- Le verdict du predicat de base (message du refus, ou 'accepte') et celui de
-- l'enveloppe (base puis plafond de Classes).
CREATE FUNCTION pg_temp.verdict(p_classe text, p_teacher text, p_exiger boolean DEFAULT true) RETURNS text
LANGUAGE plpgsql AS $$
BEGIN
  PERFORM app_private.verifier_affectation_enseignant_base(pg_temp.c(p_classe), pg_temp.t(p_teacher), p_exiger);
  RETURN 'accepte';
EXCEPTION WHEN OTHERS THEN
  RETURN SQLERRM;
END $$;

CREATE FUNCTION pg_temp.verdict_enveloppe(p_classe text, p_teacher text, p_exiger boolean DEFAULT true) RETURNS text
LANGUAGE plpgsql AS $$
BEGIN
  PERFORM app_private.verifier_affectation_enseignant(pg_temp.c(p_classe), pg_temp.t(p_teacher), p_exiger);
  RETURN 'accepte';
EXCEPTION WHEN OTHERS THEN
  RETURN SQLERRM;
END $$;

-- Le DETAIL du refus d'indisponibilite (duree et premier instant non couvert).
CREATE FUNCTION pg_temp.detail(p_classe text, p_teacher text) RETURNS text
LANGUAGE plpgsql AS $$
DECLARE v_detail text;
BEGIN
  PERFORM app_private.verifier_affectation_enseignant_base(pg_temp.c(p_classe), pg_temp.t(p_teacher), true);
  RETURN NULL;
EXCEPTION WHEN OTHERS THEN
  GET STACKED DIAGNOSTICS v_detail = PG_EXCEPTION_DETAIL;
  RETURN v_detail;
END $$;

CREATE FUNCTION pg_temp.accepte(p_classe text, p_teacher text, p_label text, p_exiger boolean DEFAULT true) RETURNS void
LANGUAGE plpgsql AS $$
DECLARE v_verdict text := pg_temp.verdict(p_classe, p_teacher, p_exiger);
BEGIN
  IF v_verdict IS DISTINCT FROM 'accepte' THEN
    RAISE EXCEPTION 'CLASSES-DUREE ROUGE : % (refuse : « % »)', p_label, v_verdict;
  END IF;
  PERFORM pg_temp.ok(p_label);
END $$;

CREATE FUNCTION pg_temp.refuse(p_classe text, p_teacher text, p_prefixe text, p_label text, p_exiger boolean DEFAULT true) RETURNS void
LANGUAGE plpgsql AS $$
DECLARE v_verdict text := pg_temp.verdict(p_classe, p_teacher, p_exiger);
BEGIN
  IF v_verdict IS NULL OR v_verdict NOT LIKE p_prefixe || '%' THEN
    RAISE EXCEPTION 'CLASSES-DUREE ROUGE : % (verdict : « % » au lieu de « %... »)', p_label, v_verdict, p_prefixe;
  END IF;
  PERFORM pg_temp.ok(p_label);
END $$;

-- ------------------------------------------------------------------
-- Fixtures. Aucune donnee personnelle : des noms de fixture.
--   admin (direction active) ; enseignants tous aptes (compte, piece
--   approuvee, genre connu, francais, plafond horaire de 40 h sauf indication) ;
--   trois eleves (codes e_...) pour les affectations individuelles.
-- ------------------------------------------------------------------
INSERT INTO dur_t (code, id)
SELECT x.code, ('d0a10000-0000-4000-8000-' || lpad(to_hex(x.n), 12, '0'))::uuid
  FROM (VALUES
    ('admin', 1),
    ('te1', 16), ('ta2', 17), ('ta2h', 18), ('ta3', 19),
    ('tr1', 20), ('tr2', 21), ('tr3', 22),
    ('tk1', 23), ('tk2', 24), ('tk3', 25),
    ('tm1', 26), ('tm2', 27), ('tm3', 28), ('tm4', 29),
    ('ts1', 30), ('ts2', 31), ('ts3', 32),
    ('tu3', 33), ('tlock', 34), ('tx', 35),
    ('tc1', 36), ('tc2', 37),
    ('th1', 38), ('th2', 39),
    ('tp3', 40), ('tp2', 41), ('tp0', 42),
    ('te2e_ok', 43), ('te2e_ko', 44), ('te2e_trou', 45), ('tcreer', 46),
    ('tsans', 47), ('th3', 48), ('th4', 49), ('tses', 50),
    ('ti1', 51), ('ti2', 52),
    ('e_si1', 53), ('e_si2a', 54), ('e_si2b', 55)
  ) x(code, n);

INSERT INTO auth.users (id, email)
SELECT id, 'duree-' || code || '@example.test' FROM dur_t;

INSERT INTO public.profiles (id, immutable_id, role, first_name, last_name, account_status, gender)
SELECT t.id, 'DURTCH' || upper(right(t.id::text, 10)),
       (CASE WHEN t.code = 'admin' THEN 'admin' ELSE 'teacher' END)::public.app_role,
       'Fixture', t.code,
       (CASE WHEN t.code = 'admin' THEN 'active' ELSE 'provisional_active' END)::public.account_status,
       (CASE WHEN t.code = 'tx' THEN 'male' ELSE 'female' END)::public.gender
  FROM dur_t t WHERE t.code NOT LIKE 'e\_%';

INSERT INTO public.teacher_profiles (profile_id, country, languages, weekly_hours_cap, kyc_status, timezone_iana)
SELECT t.id, 'FR', ARRAY['francais'],
       CASE t.code WHEN 'th1' THEN 3 WHEN 'th2' THEN 4 WHEN 'th3' THEN 3 WHEN 'th4' THEN 4 WHEN 'ti2' THEN 4 ELSE 40 END,
       'approved', 'Europe/Paris'
  FROM dur_t t WHERE t.code <> 'admin' AND t.code NOT LIKE 'e\_%';

-- Les eleves des affectations individuelles : un foyer, trois profils d'eleve.
INSERT INTO public.households (id, timezone) VALUES ('d0a1b000-0000-4000-8000-000000000001', 'Europe/Paris');
INSERT INTO public.profiles (id, immutable_id, role, first_name, last_name, account_status, gender, household_id)
SELECT t.id, 'DURSTU' || upper(right(t.id::text, 10)), 'student'::public.app_role,
       'Fixture', t.code, 'active'::public.account_status, 'female'::public.gender,
       'd0a1b000-0000-4000-8000-000000000001'
  FROM dur_t t WHERE t.code LIKE 'e\_%';

-- Disponibilites declarees (une ligne par heure) : (enseignant, jour ISO, heures, fuseau).
INSERT INTO public.weekly_availability (profile_id, weekday, hour_local, timezone_iana)
SELECT pg_temp.t(a.code), a.jour, h, a.tz
  FROM (VALUES
    -- Paris, mercredi : une heure, deux heures, un trou, une heure trop tardive
    ('te1',  3, ARRAY[18],     'Europe/Paris'),
    ('ta2',  3, ARRAY[18, 19], 'Europe/Paris'),
    ('ta2h', 3, ARRAY[18, 20], 'Europe/Paris'),
    ('ta3',  3, ARRAY[19],     'Europe/Paris'),
    ('tu3',  3, ARRAY[18, 19, 20], 'Europe/Paris'),
    ('tlock', 3, ARRAY[18, 19], 'Europe/Paris'),
    ('te2e_ok',   3, ARRAY[18, 19], 'Europe/Paris'),
    ('te2e_ko',   3, ARRAY[18],     'Europe/Paris'),
    ('te2e_trou', 3, ARRAY[18, 20], 'Europe/Paris'),
    -- Riyad (UTC+3 toute l'annee) : le cours de 18 h a Paris est a 19 h en ete, 20 h en hiver
    ('tr1', 3, ARRAY[19, 20],     'Asia/Riyadh'),
    ('tr2', 3, ARRAY[19, 20, 21], 'Asia/Riyadh'),
    ('tr3', 3, ARRAY[20, 21],     'Asia/Riyadh'),
    -- Calcutta (UTC+5:30) : la grille tombe a la demi-heure des heures de Paris
    ('tk1', 3, ARRAY[21, 22],     'Asia/Kolkata'),
    ('tk2', 3, ARRAY[21, 22, 23], 'Asia/Kolkata'),
    ('tk3', 3, ARRAY[22, 23],     'Asia/Kolkata'),
    -- Minuit : mercredi soir, jeudi matin, dimanche soir, lundi matin
    ('tm1', 3, ARRAY[23],     'Europe/Paris'),
    ('tm2', 3, ARRAY[23],     'Europe/Paris'),
    ('tm2', 4, ARRAY[0],      'Europe/Paris'),
    ('tm3', 3, ARRAY[23, 0],  'Europe/Paris'),
    ('tm4', 4, ARRAY[0],      'Europe/Paris'),
    ('ts1', 7, ARRAY[23],     'Europe/Paris'),
    ('ts1', 1, ARRAY[0],      'Europe/Paris'),
    ('ts2', 7, ARRAY[23],     'Europe/Paris'),
    ('ts3', 7, ARRAY[23, 0],  'Europe/Paris'),
    -- Plafond de Classes : vendredi 8 h
    ('tp3', 5, ARRAY[8],      'Europe/Paris'),
    ('tp2', 5, ARRAY[8],      'Europe/Paris'),
    -- Affectations individuelles : ti1 declare 20 h et 21 h (un cours d'adultes de
    -- 20 h) ; ses eleves declarent, eux, les heures de leurs cours particuliers
    ('ti1', 3, ARRAY[20, 21],  'Europe/Paris'),
    ('e_si1',  3, ARRAY[19],   'Europe/Paris'),
    ('e_si2a', 1, ARRAY[9],    'Europe/Paris'),
    ('e_si2b', 2, ARRAY[9],    'Europe/Paris')
  ) a(code, jour, heures, tz)
  CROSS JOIN LATERAL unnest(a.heures) h;

-- Affectations individuelles recurrentes (anciennes) : elles gardent la duree
-- unique d'avant (session_duration_minutes, 60 minutes), qu'elles n'ont ni offre
-- ni public. ti1 : un eleve le mercredi 19 h ; ti2 : deux eleves (lundi 9 h, mardi 9 h).
INSERT INTO public.teacher_student_assignments (teacher_id, student_id, weekday, hour_local, timezone_iana)
VALUES (pg_temp.t('ti1'), pg_temp.t('e_si1'), 3, 19, 'Europe/Paris'),
       (pg_temp.t('ti2'), pg_temp.t('e_si2a'), 1, 9, 'Europe/Paris'),
       (pg_temp.t('ti2'), pg_temp.t('e_si2b'), 2, 9, 'Europe/Paris');

-- Deux offres : une offre d'enfants de 90 minutes, une offre d'adultes de 60.
INSERT INTO public.offres_horaires
  (id, type_public, langue_code, fuseau_iana, jours, heure_locale, duree_minutes, etat, created_by)
VALUES
  ('d0a1aaaa-0000-4000-8000-000000000090', 'enfant', 'francais', 'Europe/Paris', ARRAY[3]::smallint[], 18, 90, 'brouillon', pg_temp.t('admin')),
  ('d0a1aaaa-0000-4000-8000-000000000060', 'adulte', 'francais', 'Europe/Paris', ARRAY[3]::smallint[], 18, 60, 'brouillon', pg_temp.t('admin'));

-- Les classes en attente d'un enseignant : (code, public, jour, heure, fuseau, offre).
INSERT INTO dur_c (code, id)
SELECT x.code, ('d0a1ffff-0000-4000-8000-' || lpad(to_hex(x.n), 12, '0'))::uuid
  FROM (VALUES
    ('E18', 1), ('A18', 2), ('A23', 3), ('E23', 4), ('AS23', 5),
    ('A19', 6), ('E19', 7), ('A17', 8), ('A20', 9), ('E20', 10),
    ('OFF90', 11), ('OFF60', 12),
    ('A3x', 13), ('E3x', 14), ('Ac', 15), ('Ec', 16),
    ('Fv8', 17), ('Fa3', 18),
    ('A18_e2e', 19), ('A18_e2e_trou', 20), ('A18_creer', 21), ('F18', 22), ('E18_dur', 23)
  ) x(code, n);

INSERT INTO public.groupes
  (id, teacher_id, etat, type_public, seuil_max, libelle, weekday, hour_local, timezone_iana, offre_id, genre_public)
SELECT pg_temp.c(k.code), NULL, 'en_attente_enseignant', k.pub, 6, 'Duree ' || k.code, k.jour, k.heure,
       'Europe/Paris', k.offre, k.genre
  FROM (VALUES
    ('E18',   'enfant', 3, 18, NULL::uuid, 'indetermine'),
    ('A18',   'adulte', 3, 18, NULL, 'indetermine'),
    ('A23',   'adulte', 3, 23, NULL, 'indetermine'),
    ('E23',   'enfant', 3, 23, NULL, 'indetermine'),
    ('AS23',  'adulte', 7, 23, NULL, 'indetermine'),
    ('A19',   'adulte', 3, 19, NULL, 'indetermine'),
    ('E19',   'enfant', 3, 19, NULL, 'indetermine'),
    ('A17',   'adulte', 3, 17, NULL, 'indetermine'),
    ('A20',   'adulte', 3, 20, NULL, 'indetermine'),
    ('E20',   'enfant', 3, 20, NULL, 'indetermine'),
    ('OFF90', 'enfant', 3, 18, 'd0a1aaaa-0000-4000-8000-000000000090'::uuid, 'indetermine'),
    ('OFF60', 'adulte', 3, 18, 'd0a1aaaa-0000-4000-8000-000000000060'::uuid, 'indetermine'),
    ('A3x',   'adulte', 1, 10, NULL, 'indetermine'),
    ('E3x',   'enfant', 1, 10, NULL, 'indetermine'),
    ('Ac',    'adulte', 5, 14, NULL, 'indetermine'),
    ('Ec',    'enfant', 5, 14, NULL, 'indetermine'),
    ('Fv8',   'enfant', 5, 8,  NULL, 'indetermine'),
    ('Fa3',   'enfant', 5, 8,  NULL, 'femmes'),
    ('A18_e2e',      'adulte', 3, 18, NULL, 'indetermine'),
    ('A18_e2e_trou', 'adulte', 3, 18, NULL, 'indetermine'),
    ('A18_creer',    'adulte', 3, 18, NULL, 'indetermine'),
    ('F18',   'adulte', 3, 18, NULL, 'femmes'),
    ('E18_dur', 'enfant', 3, 18, NULL, 'indetermine')
  ) k(code, pub, jour, heure, offre, genre);
-- Les creneaux secondaires des classes de trois seances (lundi, mercredi, vendredi a 10 h).
INSERT INTO public.groupe_creneaux (groupe_id, weekday, hour_local)
SELECT pg_temp.c(k.code), s.jour, 10
  FROM (VALUES ('A3x'), ('E3x')) k(code) CROSS JOIN (VALUES (3), (5)) s(jour);

-- Classes deja actives (donnees anterieures) :
--   tc1 : une Classe d'adultes mercredi 18 h (jusqu'a 19 h 30) ;
--   tc2 : une Classe d'enfants mercredi 18 h (jusqu'a 19 h) ;
--   th2 : une Classe d'adultes deux fois par semaine (lundi et mardi 10 h) ;
--   th3 : la meme, avec un plafond de 3 heures ; th4 : une Classe d'ENFANTS
--   deux fois par semaine, avec un plafond de 4 heures ;
--   tp3 : trois Classes d'enfants ; tp2 : deux ; tp0 : trois (sans disponibilites).
INSERT INTO public.groupes (id, teacher_id, etat, type_public, seuil_max, libelle, weekday, hour_local, timezone_iana)
SELECT gen_random_uuid(), pg_temp.t(k.code), 'active', k.pub, 6, 'Active ' || k.code || ' ' || k.jour, k.jour, k.heure, 'Europe/Paris'
  FROM (VALUES
    ('tc1', 'adulte', 3, 18),
    ('tc2', 'enfant', 3, 18),
    ('th2', 'adulte', 1, 10), ('th3', 'adulte', 1, 10), ('th4', 'enfant', 1, 10),
    ('tp3', 'enfant', 1, 8), ('tp3', 'enfant', 2, 8), ('tp3', 'enfant', 4, 8),
    ('tp2', 'enfant', 1, 8), ('tp2', 'enfant', 2, 8),
    ('tp0', 'enfant', 1, 8), ('tp0', 'enfant', 2, 8), ('tp0', 'enfant', 4, 8)
  ) k(code, pub, jour, heure);
-- CLASSES-DUREE (23/10) : ces Classes sont des « donnees anterieures » sans
-- disponibilites declarees ; ecrire leur second creneau rejouerait le predicat
-- (groupe_creneaux_verifie_enseignant), qui exige la couverture. Le declencheur
-- est retire le temps de poser la fixture ; il est teste par
-- scenarios_classes_duree_bout_en_bout.sql.
ALTER TABLE public.groupe_creneaux DISABLE TRIGGER groupe_creneaux_verifie_enseignant;
INSERT INTO public.groupe_creneaux (groupe_id, weekday, hour_local)
SELECT g.id, 2, 10 FROM public.groupes g
 WHERE g.teacher_id IN (pg_temp.t('th2'), pg_temp.t('th3'), pg_temp.t('th4'));
ALTER TABLE public.groupe_creneaux ENABLE TRIGGER groupe_creneaux_verifie_enseignant;

-- tses : une seance ponctuelle (sans Classe) qui commence 70 minutes apres le
-- debut du mercredi 18 h de la semaine 1, et dure une heure.
INSERT INTO public.sessions (teacher_id, started_at, ended_at, status, groupe_id)
SELECT pg_temp.t('tses'),
       public.instant_creneau(3, 18, 'Europe/Paris', 1) + interval '70 minutes',
       public.instant_creneau(3, 18, 'Europe/Paris', 1) + interval '130 minutes',
       'planned', NULL;

-- Le reglage des durees est celui de 0043 : 90 minutes pour les adultes, 60 pour les enfants.
SELECT pg_temp.vrai(
  public.app_config_int('seance.duree_minutes_adulte', -1) = 90
  AND public.app_config_int('seance.duree_minutes_enfant', -1) = 60
  AND public.app_config_int('session_duration_minutes', -1) = 60,
  'fixtures : les reglages valent 90 (adultes), 60 (enfants) et 60 (duree unique d''avant)');

-- ------------------------------------------------------------------
-- (a) La duree de la Classe
-- ------------------------------------------------------------------
SELECT pg_temp.vrai(
  app_private.duree_seance_minutes(NULL, 'adulte') = 90
  AND app_private.duree_seance_minutes(NULL, 'enfant') = 60,
  '(a) sans offre, la duree est celle du public : 90 minutes pour les adultes, 60 pour les enfants');
SELECT pg_temp.vrai(
  app_private.duree_seance_minutes('d0a1aaaa-0000-4000-8000-000000000090', 'enfant') = 90
  AND app_private.duree_seance_minutes('d0a1aaaa-0000-4000-8000-000000000060', 'adulte') = 60,
  '(a) avec une offre, la duree est celle de l''offre (90 pour une offre d''enfants, 60 pour une offre d''adultes), pas celle du public');
SELECT pg_temp.vrai(
  app_private.duree_seance_minutes('d0a1aaaa-0000-4000-8000-0000000000ff', 'adulte') = 90,
  '(a) une offre inconnue ne porte aucune duree : repli sur le reglage du public');
SELECT pg_temp.refus($$SELECT app_private.duree_seance_minutes(NULL, 'inconnu')$$, 'P0001', 'public de classe inconnu',
  '(a) un public inconnu refuse (garde positive), il ne retombe pas sur 60');
SELECT pg_temp.refus($$SELECT app_private.duree_seance_minutes(NULL, NULL)$$, 'P0001', 'public de classe inconnu',
  '(a) un public nul refuse aussi (NULL ne passe pas la garde)');

-- ------------------------------------------------------------------
-- (b) Cours d'enfants de 60 minutes : couvert par UNE heure
-- ------------------------------------------------------------------
SELECT pg_temp.accepte('E18', 'te1', '(b) un cours d''enfants de 18 h a 19 h est couvert par la seule heure 18');
SELECT pg_temp.accepte('E18', 'ta2', '(b) ... et par deux heures (18 et 19) : la seconde est en trop, pas en moins');
SELECT pg_temp.refuse('E18', 'ta3', 'enseignant non disponible: jour 3, heure 18',
  '(b) un cours d''enfants de 18 h n''est pas couvert par la seule heure 19');
SELECT pg_temp.accepte('E23', 'tm1', '(b) un cours d''enfants de 23 h a minuit pile est couvert par la seule heure 23 (il ne touche pas le jour suivant)');

-- ------------------------------------------------------------------
-- (c) Cours d'adultes de 90 minutes : deux heures
-- ------------------------------------------------------------------
SELECT pg_temp.refuse('A18', 'te1', 'enseignant non disponible: jour 3, heure 18',
  '(c) un cours d''adultes de 18 h a 19 h 30 est REFUSE avec la seule heure 18 (il depasse sa fin de 30 minutes)');
SELECT pg_temp.accepte('A18', 'ta2', '(c) ... et ACCEPTE avec les heures 18 et 19 (la defaillance constatee : un enseignant disponible de 18 h a 20 h)');
SELECT pg_temp.accepte('A18', 'tu3', '(c) ... et avec trois heures consecutives (18, 19 et 20)');
SELECT pg_temp.refuse('A18', 'ta3', 'enseignant non disponible: jour 3, heure 18',
  '(c) une heure qui commence APRES le debut ne couvre pas : les heures 19 seule, pour un cours de 18 h a 19 h 30');
SELECT pg_temp.refuse('A18', 'ta2h', 'enseignant non disponible: jour 3, heure 18',
  '(c) un trou refuse : les heures 18 et 20, sans la 19, ne couvrent pas 18 h a 19 h 30');
SELECT pg_temp.vrai(
  pg_temp.detail('A18', 'te1') LIKE 'duree de la seance : 90 minutes ; premier instant non couvert : %'
  AND pg_temp.detail('A18', 'ta2h') LIKE 'duree de la seance : 90 minutes ; premier instant non couvert : %',
  '(c) le refus dit la duree retenue (90 minutes) et le premier instant non couvert dans son DETAIL');

-- ------------------------------------------------------------------
-- (d) La seance qui passe minuit
-- ------------------------------------------------------------------
SELECT pg_temp.refuse('A23', 'tm1', 'enseignant non disponible: jour 3, heure 23',
  '(d) un cours d''adultes de 23 h a 0 h 30 est refuse avec la seule heure 23 du mercredi');
SELECT pg_temp.accepte('A23', 'tm2', '(d) ... accepte avec l''heure 23 du mercredi et l''heure 0 du JEUDI');
SELECT pg_temp.refuse('A23', 'tm3', 'enseignant non disponible: jour 3, heure 23',
  '(d) ... refuse avec l''heure 0 du MERCREDI (le mauvais jour : celle d''avant la seance)');
SELECT pg_temp.refuse('A23', 'tm4', 'enseignant non disponible: jour 3, heure 23',
  '(d) ... refuse avec la seule heure 0 du jeudi (les 23 h a minuit ne sont pas couvertes)');
SELECT pg_temp.accepte('AS23', 'ts1', '(d) le dimanche soir passe au lundi : l''heure 23 du dimanche (7) et l''heure 0 du lundi (1) couvrent 23 h a 0 h 30');
SELECT pg_temp.refuse('AS23', 'ts2', 'enseignant non disponible: jour 7, heure 23',
  '(d) le dimanche 23 h seul ne couvre pas le cours d''adultes jusqu''au lundi');
SELECT pg_temp.refuse('AS23', 'ts3', 'enseignant non disponible: jour 7, heure 23',
  '(d) l''heure 0 du DIMANCHE n''est pas celle du lundi : refuse');

-- ------------------------------------------------------------------
-- (e) Un autre fuseau que celui de la Classe, les deux saisons, une grille a la demi-heure
-- ------------------------------------------------------------------
-- La Classe est mercredi 18 h a Paris. Riyad (UTC+3, sans changement d'heure) :
-- 19 h en ete (Paris UTC+2), 20 h en hiver (Paris UTC+1). Un cours d'adultes
-- de 90 minutes occupe donc 19 h-20 h 30 (lignes 19 et 20) en ete, 20 h-21 h 30
-- (lignes 20 et 21) en hiver : les trois heures 19, 20 et 21 couvrent l'annee.
SELECT pg_temp.accepte('A18', 'tr2', '(e) Riyad, heures 19, 20 et 21 : le cours d''adultes de 18 h a Paris est couvert ete comme hiver');
SELECT pg_temp.refuse('A18', 'tr1', 'enseignant non disponible: jour 3, heure 18, fuseau Europe/Paris',
  '(e) Riyad, heures 19 et 20 seulement : refuse (l''hiver n''est pas couvert)');
SELECT pg_temp.refuse('A18', 'tr3', 'enseignant non disponible: jour 3, heure 18, fuseau Europe/Paris',
  '(e) Riyad, heures 20 et 21 seulement : refuse (l''ete n''est pas couvert)');
-- Un cours d'enfants de 60 minutes : 19 h (ete) ou 20 h (hiver) a Riyad.
SELECT pg_temp.accepte('E18', 'tr1', '(e) Riyad, heures 19 et 20 : le cours d''enfants de 60 minutes est couvert ete (19 h) comme hiver (20 h)');
SELECT pg_temp.refuse('E18', 'tr3', 'enseignant non disponible: jour 3, heure 18, fuseau Europe/Paris',
  '(e) Riyad, heures 20 et 21 : le cours d''enfants n''est pas couvert l''ete (19 h-20 h : la ligne 19 manque)');
-- Calcutta (UTC+5:30) : 18 h a Paris = 21 h 30 (ete) ou 22 h 30 (hiver) a Calcutta.
-- Aucune ligne d'une heure de Calcutta ne contient seule le cours : seule l'UNION le couvre.
SELECT pg_temp.accepte('E18', 'tk2', '(e) Calcutta (grille a la demi-heure), heures 21, 22 et 23 : un cours d''enfants est couvert par l''union de deux lignes, ete comme hiver');
SELECT pg_temp.accepte('A18', 'tk2', '(e) Calcutta, heures 21, 22 et 23 : le cours d''adultes aussi (21 h 30-23 h en ete, 22 h 30-0 h en hiver)');
SELECT pg_temp.refuse('E18', 'tk1', 'enseignant non disponible: jour 3, heure 18, fuseau Europe/Paris',
  '(e) Calcutta, heures 21 et 22 seulement : l''hiver (22 h 30-23 h 30) n''est pas couvert');
SELECT pg_temp.refuse('E18', 'tk3', 'enseignant non disponible: jour 3, heure 18, fuseau Europe/Paris',
  '(e) Calcutta, heures 22 et 23 seulement : l''ete (21 h 30-22 h 30) n''est pas couvert');
-- Le premier instant non couvert dit la saison du refus : l'heure d'hiver de Paris
-- (UTC+1) pour les heures 19 et 20 de Riyad, l'heure d'ete (UTC+2) pour les 20 et 21.
SELECT pg_temp.vrai(
  (SELECT (t AT TIME ZONE 'Europe/Paris') - (t AT TIME ZONE 'UTC') = interval '1 hour'
     FROM (SELECT substring(pg_temp.detail('A18', 'tr1') from 'couvert : (.*)$')::timestamptz AS t) x),
  '(e) Riyad, heures 19 et 20 : le premier instant non couvert est un instant d''HIVER (Paris a UTC+1)');
SELECT pg_temp.vrai(
  (SELECT (t AT TIME ZONE 'Europe/Paris') - (t AT TIME ZONE 'UTC') = interval '2 hours'
     FROM (SELECT substring(pg_temp.detail('A18', 'tr3') from 'couvert : (.*)$')::timestamptz AS t) x),
  '(e) Riyad, heures 20 et 21 : le premier instant non couvert est un instant d''ETE (Paris a UTC+2)');
-- Ces refus-la sont de vrais refus d'indisponibilite, pas d'une autre cause.
SELECT pg_temp.vrai(
  pg_temp.verdict('A18', 'tr1') LIKE '%, semaine %, instant %'
  AND pg_temp.detail('A18', 'tr1') LIKE 'duree de la seance : 90 minutes ; premier instant non couvert : %',
  '(e) le message garde jour, heure, fuseau, semaine et instant ; le DETAIL la duree');

-- ------------------------------------------------------------------
-- (f) La duree vient de l'offre ou du reglage, et suit le reglage
-- ------------------------------------------------------------------
-- Une Classe d'enfants nee d'une offre de 90 minutes : deux heures.
SELECT pg_temp.refuse('OFF90', 'te1', 'enseignant non disponible: jour 3, heure 18',
  '(f) une Classe d''enfants nee d''une offre de 90 minutes est refusee avec la seule heure 18');
SELECT pg_temp.accepte('OFF90', 'ta2', '(f) ... et acceptee avec les heures 18 et 19 : la duree est celle de l''offre, pas celle du public');
-- Une Classe d'adultes nee d'une offre de 60 minutes : une heure.
SELECT pg_temp.accepte('OFF60', 'te1', '(f) une Classe d''adultes nee d''une offre de 60 minutes est acceptee avec la seule heure 18');
-- Le reglage des adultes passe a 120 minutes (direction), puis 150.
SELECT pg_temp.qui(pg_temp.t('admin'), 'admin');
SET LOCAL ROLE authenticated;
UPDATE public.app_config SET value = pg_catalog.to_jsonb(120), updated_by = auth.uid()
 WHERE key = 'seance.duree_minutes_adulte';
RESET ROLE;
SELECT pg_temp.vrai(app_private.duree_seance_minutes(NULL, 'adulte') = 120
    AND app_private.duree_seance_minutes(NULL, 'enfant') = 60,
  '(f) la direction passe les adultes a 120 minutes : la duree lue suit (les enfants restent a 60)');
SELECT pg_temp.accepte('A18', 'ta2', '(f) 120 minutes, heures 18 et 19 : 18 h a 20 h exactement, acceptees');
SELECT pg_temp.refuse('A18', 'te1', 'enseignant non disponible: jour 3, heure 18', '(f) 120 minutes, heure 18 seule : refusee');
SELECT pg_temp.accepte('OFF60', 'te1', '(f) la Classe nee d''une offre de 60 minutes garde 60 minutes quand le reglage des adultes change');
SELECT pg_temp.qui(pg_temp.t('admin'), 'admin');
SET LOCAL ROLE authenticated;
UPDATE public.app_config SET value = pg_catalog.to_jsonb(150), updated_by = auth.uid()
 WHERE key = 'seance.duree_minutes_adulte';
RESET ROLE;
SELECT pg_temp.refuse('A18', 'ta2', 'enseignant non disponible: jour 3, heure 18',
  '(f) 150 minutes : les heures 18 et 19 ne suffisent plus (18 h a 20 h 30)');
SELECT pg_temp.accepte('A18', 'tu3', '(f) 150 minutes : les heures 18, 19 et 20 couvrent 18 h a 20 h 30');
-- Une duree absurde refuse : jamais de repli silencieux. Depuis le lot de bout en bout
-- (23/10), app_config_duree_seance refuse deja l'ECRITURE d'une telle valeur
-- (scenarios_classes_duree_bout_en_bout.sql, G6) ; le temps de ce bloc, il est
-- desactive pour eprouver la garde de LECTURE de app_private.duree_seance_minutes
-- (une valeur ancienne ou ecrite autrement), qui reste la seconde ligne de defense.
ALTER TABLE public.app_config DISABLE TRIGGER app_config_duree_seance;
SELECT pg_temp.qui(pg_temp.t('admin'), 'admin');
SET LOCAL ROLE authenticated;
UPDATE public.app_config SET value = pg_catalog.to_jsonb(0), updated_by = auth.uid()
 WHERE key = 'seance.duree_minutes_adulte';
RESET ROLE;
SELECT pg_temp.refuse('A18', 'ta2', 'duree de seance inconnue ou hors de 15 a 240 minutes',
  '(f) un reglage a 0 minute refuse l''affectation d''une Classe d''adultes (aucun repli sur 60)');
-- Les bornes : 15 et 240 minutes passent, 14 et 241 refusent.
UPDATE public.app_config SET value = pg_catalog.to_jsonb(241) WHERE key = 'seance.duree_minutes_adulte';
SELECT pg_temp.refus($$SELECT app_private.duree_seance_minutes(NULL, 'adulte')$$, 'P0001',
  'duree de seance inconnue ou hors de 15 a 240 minutes', '(f) 241 minutes : hors de la borne haute, refuse');
UPDATE public.app_config SET value = pg_catalog.to_jsonb(240) WHERE key = 'seance.duree_minutes_adulte';
SELECT pg_temp.vrai(app_private.duree_seance_minutes(NULL, 'adulte') = 240, '(f) 240 minutes : la borne haute passe');
UPDATE public.app_config SET value = pg_catalog.to_jsonb(14) WHERE key = 'seance.duree_minutes_adulte';
SELECT pg_temp.refus($$SELECT app_private.duree_seance_minutes(NULL, 'adulte')$$, 'P0001',
  'duree de seance inconnue ou hors de 15 a 240 minutes', '(f) 14 minutes : sous la borne basse, refuse');
UPDATE public.app_config SET value = pg_catalog.to_jsonb(15) WHERE key = 'seance.duree_minutes_adulte';
SELECT pg_temp.vrai(app_private.duree_seance_minutes(NULL, 'adulte') = 15, '(f) 15 minutes : la borne basse passe');
UPDATE public.app_config SET value = pg_catalog.to_jsonb(0) WHERE key = 'seance.duree_minutes_adulte';
SELECT pg_temp.accepte('E18', 'te1', '(f) ... mais pas celle d''une Classe d''enfants, qui lit son propre reglage');
ALTER TABLE public.app_config ENABLE TRIGGER app_config_duree_seance;
SELECT pg_temp.qui(pg_temp.t('admin'), 'admin');
SET LOCAL ROLE authenticated;
UPDATE public.app_config SET value = pg_catalog.to_jsonb(90), updated_by = auth.uid()
 WHERE key = 'seance.duree_minutes_adulte';
RESET ROLE;
SELECT pg_temp.accepte('A18', 'ta2', '(f) reglage remis a 90 minutes : les heures 18 et 19 suffisent de nouveau');

-- ------------------------------------------------------------------
-- (g) Collisions avec la duree propre a chaque Classe (sans la couverture)
-- ------------------------------------------------------------------
-- tc1 tient une Classe d'adultes mercredi 18 h (jusqu'a 19 h 30).
SELECT pg_temp.refuse('E19', 'tc1', 'chevauchement avec une classe ou affectation active',
  '(g) un cours d''enfants de 19 h chevauche la Classe d''adultes de 18 h a 19 h 30', false);
SELECT pg_temp.accepte('E20', 'tc1', '(g) un cours d''enfants de 20 h ne la chevauche pas', false);
SELECT pg_temp.refuse('A19', 'tc1', 'chevauchement avec une classe ou affectation active',
  '(g) un cours d''adultes de 19 h (jusqu''a 20 h 30) chevauche aussi la Classe d''adultes de 18 h', false);
SELECT pg_temp.accepte('A20', 'tc1', '(g) un cours d''adultes de 20 h ne la chevauche pas', false);
-- tc2 tient une Classe d'enfants mercredi 18 h (jusqu'a 19 h).
SELECT pg_temp.refuse('A17', 'tc2', 'chevauchement avec une classe ou affectation active',
  '(g) un cours d''adultes de 17 h (jusqu''a 18 h 30) chevauche la Classe d''enfants de 18 h a 19 h', false);
SELECT pg_temp.accepte('A19', 'tc2', '(g) un cours d''adultes de 19 h ne chevauche pas la Classe d''enfants qui finit a 19 h (les bords se touchent)', false);
SELECT pg_temp.accepte('E19', 'tc2', '(g) un cours d''enfants de 19 h non plus', false);
SELECT pg_temp.accepte('A20', 'tc2', '(g) ni un cours d''adultes de 20 h', false);
-- ti1 tient un cours particulier (affectation individuelle) le mercredi 19 h : il
-- garde la duree d'avant, 60 minutes, quelle que soit la Classe visee.
SELECT pg_temp.accepte('A20', 'ti1', '(g) l''affectation individuelle de 19 h compte 60 minutes (jusqu''a 20 h) : un cours d''adultes de 20 h a 21 h 30 ne la touche pas, et ses heures 20 et 21 le couvrent');
SELECT pg_temp.accepte('A17', 'ti1', '(g) ... ni un cours d''adultes de 17 h a 18 h 30', false);
SELECT pg_temp.refuse('E19', 'ti1', 'chevauchement avec une classe ou affectation active',
  '(g) ... mais un cours d''enfants de 19 h la chevauche', false);
-- tses a une seance ponctuelle (sans Classe) qui commence 70 minutes apres le
-- mercredi 18 h de la semaine 1 : un cours d'adultes de 18 h (jusqu'a 19 h 30) la
-- touche, un cours d'enfants de 18 h (jusqu'a 19 h) non.
SELECT pg_temp.refuse('A18', 'tses', 'chevauchement avec une séance existante',
  '(g) une seance ponctuelle qui commence a 19 h 10 chevauche un cours d''adultes de 18 h a 19 h 30', false);
SELECT pg_temp.accepte('E18', 'tses', '(g) ... mais pas un cours d''enfants de 18 h a 19 h', false);

-- ------------------------------------------------------------------
-- (h) Plafond horaire avec la duree propre a chaque Classe (sans la couverture)
-- ------------------------------------------------------------------
-- th1 : plafond de 3 heures par semaine. Trois seances d'adultes = 4 h 30.
SELECT pg_temp.refuse('A3x', 'th1', 'plafond horaire enseignant dépassé',
  '(h) trois seances d''adultes (3 x 90 minutes = 4 h 30) depassent un plafond de 3 heures', false);
SELECT pg_temp.accepte('E3x', 'th1', '(h) trois seances d''enfants (3 x 60 minutes = 3 heures) tiennent dans un plafond de 3 heures', false);
-- th2 : plafond de 4 heures, deja 2 seances d'adultes (3 heures).
SELECT pg_temp.accepte('Ec', 'th2', '(h) une seance d''enfants (1 heure) s''ajoute aux 3 heures d''adultes : 4 heures, au plafond, accepte', false);
SELECT pg_temp.refuse('Ac', 'th2', 'plafond horaire enseignant dépassé',
  '(h) une seance d''adultes (1 h 30) s''ajoute aux 3 heures : 4 h 30 depasse le plafond de 4 heures', false);
-- th3 : plafond de 3 heures, deja 2 seances d'adultes (3 heures) : meme une seance
-- d'enfants depasse (4 heures). Les seances DEJA tenues comptent leur duree a elles.
SELECT pg_temp.refuse('Ec', 'th3', 'plafond horaire enseignant dépassé',
  '(h) les 2 seances d''adultes deja tenues comptent 90 minutes chacune (3 heures) : une seance d''enfants de plus (4 heures) depasse un plafond de 3 heures', false);
-- th4 : plafond de 4 heures, deja 2 seances d'enfants (2 heures) : une seance d'adultes tient.
SELECT pg_temp.accepte('Ac', 'th4', '(h) les 2 seances d''enfants deja tenues comptent 60 minutes chacune (2 heures) : une seance d''adultes de plus (3 h 30) tient dans un plafond de 4 heures', false);

-- ti2 : plafond de 4 heures, deux affectations individuelles (2 x 60 minutes = 2 heures,
-- la duree d'avant) : une seance d'adultes (1 h 30) fait 3 h 30, au plafond pres ; trois
-- seances d'adultes font 6 h 30.
SELECT pg_temp.accepte('Ac', 'ti2', '(h) deux affectations individuelles comptent 2 x 60 minutes : une seance d''adultes de plus fait 3 h 30, sous le plafond de 4 heures', false);
SELECT pg_temp.refuse('A3x', 'ti2', 'plafond horaire enseignant dépassé',
  '(h) ... et trois seances d''adultes de plus (6 h 30) depassent le plafond de 4 heures', false);

-- ------------------------------------------------------------------
-- (i) Refus nommes existants, plafond de Classes, verrou
-- ------------------------------------------------------------------
SELECT pg_temp.refuse('E18', 'tsans', 'enseignant non disponible: jour 3, heure 18',
  '(i) un enseignant sans disponibilite est refuse enseignant non disponible', true);
SELECT pg_temp.accepte('A18', 'tsans', '(i) ... mais la creation sans couverture (drapeau false) l''accepte, comme avant (D4)', false);
SELECT pg_temp.refuse('A18', 'te1', 'enseignant non disponible: jour 3, heure 18',
  '(i) un drapeau NULL vaut vrai : la couverture est exigee (NULL ne saute rien)', NULL::boolean);
-- Un compte inconnu, un genre incompatible, une Classe close ou absente.
SELECT pg_temp.refus($$SELECT app_private.verifier_affectation_enseignant_base(
    'd0a1ffff-0000-4000-8000-000000000001', 'd0a10000-0000-4000-8000-0000000000ff', true)$$,
  'P0001', 'enseignant indisponible ou genre inconnu', '(i) un enseignant inconnu : enseignant indisponible ou genre inconnu');
SELECT pg_temp.refuse('F18', 'tx', 'enseignant incompatible avec le public de la classe',
  '(i) un enseignant (homme) pour une Classe de femmes : enseignant incompatible avec le public de la classe');
SELECT pg_temp.refus($$SELECT app_private.verifier_affectation_enseignant_base(
    'd0a1ffff-0000-4000-8000-0000000000ff', 'd0a10000-0000-4000-8000-000000000011', true)$$,
  'P0001', 'classe indisponible', '(i) une Classe absente : classe indisponible');
SELECT pg_temp.refus($$SELECT app_private.verifier_affectation_enseignant_base(NULL, NULL, true)$$,
  'P0001', 'classe ou enseignant absent', '(i) sans classe ni enseignant : classe ou enseignant absent');
-- Le refus de genre garde la priorite sur la duree : meme avec un reglage absurde
-- (ecrit ici le declencheur de validation desactive : voir (f)).
ALTER TABLE public.app_config DISABLE TRIGGER app_config_duree_seance;
SELECT pg_temp.qui(pg_temp.t('admin'), 'admin');
SET LOCAL ROLE authenticated;
UPDATE public.app_config SET value = pg_catalog.to_jsonb(0), updated_by = auth.uid()
 WHERE key = 'seance.duree_minutes_adulte';
RESET ROLE;
SELECT pg_temp.refuse('F18', 'tx', 'enseignant incompatible avec le public de la classe',
  '(i) les refus de compte, de langue et de genre gardent la parole avant la duree (reglage a 0 minute)');
ALTER TABLE public.app_config ENABLE TRIGGER app_config_duree_seance;
SELECT pg_temp.qui(pg_temp.t('admin'), 'admin');
SET LOCAL ROLE authenticated;
UPDATE public.app_config SET value = pg_catalog.to_jsonb(90), updated_by = auth.uid()
 WHERE key = 'seance.duree_minutes_adulte';
RESET ROLE;
-- Le plafond de Classes (3 par defaut) est toujours applique, apres la base.
SELECT pg_temp.vrai(app_private.classes_max_par_enseignant() = 3 AND app_private.classes_actives_enseignant(pg_temp.t('tp3')) = 3,
  '(i) fixtures : le maximum est 3, tp3 tient trois Classes');
SELECT pg_temp.accepte('Fv8', 'tp3', '(i) la base accepte tp3 (couvert, aucune collision) : le plafond de Classes n''est pas la base', true);
SELECT pg_temp.vrai(pg_temp.verdict_enveloppe('Fv8', 'tp3') = 'plafond_classes_atteint',
  '(i) l''enveloppe refuse tp3 plafond_classes_atteint : la quatrieme Classe, meme couverte');
SELECT pg_temp.vrai(pg_temp.verdict_enveloppe('Fv8', 'tp2') = 'accepte',
  '(i) l''enveloppe accepte tp2 (deux Classes, couverte) : sa troisieme');
SELECT pg_temp.vrai(pg_temp.verdict_enveloppe('Fv8', 'tp0') LIKE 'enseignant non disponible: jour 5, heure 8%',
  '(i) tp0 (trois Classes, sans disponibilite) : la base parle d''abord (enseignant non disponible), le plafond ensuite');
SELECT pg_temp.refus(format($$SELECT public.tc_verifier_affectation_enseignant(%L, %L)$$, pg_temp.c('Fv8'), pg_temp.t('tp3')),
  'P0001', 'plafond_classes_atteint',
  '(i) tc_verifier_affectation_enseignant (deux arguments) passe aussi par l''enveloppe : plafond_classes_atteint pour tp3');
-- Le verrou par enseignant est pris par la base : avant, aucun ; apres, un.
SELECT pg_temp.vrai(NOT EXISTS (
  SELECT 1 FROM pg_catalog.pg_locks l
   WHERE l.locktype = 'advisory' AND l.pid = pg_catalog.pg_backend_pid()
     AND ((l.classid::bigint << 32) | l.objid::bigint)
         = pg_catalog.hashtextextended('teacher-schedule:' || pg_temp.t('tlock')::text, 0)),
  '(i) avant l''appel, la session ne tient pas le verrou de tlock');
SELECT pg_temp.accepte('A18', 'tlock', '(i) tlock (heures 18 et 19) est accepte pour le cours d''adultes');
SELECT pg_temp.vrai(EXISTS (
  SELECT 1 FROM pg_catalog.pg_locks l
   WHERE l.locktype = 'advisory' AND l.pid = pg_catalog.pg_backend_pid()
     AND ((l.classid::bigint << 32) | l.objid::bigint)
         = pg_catalog.hashtextextended('teacher-schedule:' || pg_temp.t('tlock')::text, 0)),
  '(i) apres l''appel, la session tient le verrou « teacher-schedule » de tlock : deux affectations du meme enseignant se suivent');

-- ------------------------------------------------------------------
-- (j) Par les vraies RPC
-- ------------------------------------------------------------------
-- La proposition d'enseignants pour une Classe d'adultes de mercredi 18 h :
-- seuls les enseignants couverts de 18 h a 19 h 30 y figurent.
SELECT pg_temp.qui(pg_temp.t('admin'), 'admin');
SET LOCAL ROLE authenticated;
CREATE TEMP TABLE dur_prop (etape text, teacher_id uuid) ON COMMIT DROP;
GRANT ALL ON dur_prop TO authenticated;
INSERT INTO dur_prop SELECT 'adulte', teacher_id FROM public.enseignants_pour_classe(pg_temp.c('A18_e2e'));
INSERT INTO dur_prop SELECT 'enfant', teacher_id FROM public.enseignants_pour_classe(pg_temp.c('E18_dur'));
RESET ROLE;
SELECT pg_temp.vrai(
  EXISTS (SELECT 1 FROM dur_prop WHERE etape = 'adulte' AND teacher_id = pg_temp.t('te2e_ok'))
  AND NOT EXISTS (SELECT 1 FROM dur_prop WHERE etape = 'adulte' AND teacher_id IN (pg_temp.t('te2e_ko'), pg_temp.t('te2e_trou'))),
  '(j) enseignants_pour_classe (adultes, 18 h) propose l''enseignant des heures 18 et 19, pas celui de la seule heure 18 ni celui au trou');
SELECT pg_temp.vrai(
  (SELECT pg_catalog.count(*) FROM dur_prop
    WHERE etape = 'enfant'
      AND teacher_id IN (pg_temp.t('te2e_ok'), pg_temp.t('te2e_ko'), pg_temp.t('te2e_trou'))) = 3,
  '(j) ... et pour une Classe d''enfants de 18 h, la seule heure 18 suffit : les trois enseignants (heures 18 et 19, heure 18 seule, heures 18 et 20) y figurent');
-- L'affectation (c11bis) : acceptee avec deux heures, refusee avec une.
SELECT pg_temp.qui(pg_temp.t('admin'), 'admin');
SET LOCAL ROLE authenticated;
SELECT pg_temp.refus(format($$SELECT public.affecter_enseignant_classe_c11bis(%L, %L)$$, pg_temp.c('A18_e2e'), pg_temp.t('te2e_ko')),
  'P0001', 'enseignant non disponible: jour 3, heure 18',
  '(j) affecter_enseignant_classe_c11bis refuse l''enseignant de la seule heure 18 pour une Classe d''adultes de 90 minutes');
SELECT pg_temp.refus(format($$SELECT public.affecter_enseignant_classe_c11bis(%L, %L)$$, pg_temp.c('A18_e2e_trou'), pg_temp.t('te2e_trou')),
  'P0001', 'enseignant non disponible: jour 3, heure 18',
  '(j) ... et l''enseignant des heures 18 et 20 (un trou)');
RESET ROLE;
SELECT pg_temp.vrai((SELECT teacher_id IS NULL AND etat = 'en_attente_enseignant' FROM public.groupes WHERE id = pg_temp.c('A18_e2e'))
  AND NOT EXISTS (SELECT 1 FROM public.sessions WHERE groupe_id IN (pg_temp.c('A18_e2e'), pg_temp.c('A18_e2e_trou'))),
  '(j) les refus ne laissent rien : la Classe attend toujours, sans enseignant ni seance');
SET LOCAL ROLE authenticated;
SELECT pg_temp.vrai(public.affecter_enseignant_classe_c11bis(pg_temp.c('A18_e2e'), pg_temp.t('te2e_ok')) = 'affecte',
  '(j) affecter_enseignant_classe_c11bis accepte l''enseignant des heures 18 et 19 : affecte');
RESET ROLE;
SELECT pg_temp.vrai((SELECT teacher_id = pg_temp.t('te2e_ok') AND etat = 'active' FROM public.groupes WHERE id = pg_temp.c('A18_e2e'))
  AND EXISTS (SELECT 1 FROM public.sessions WHERE groupe_id = pg_temp.c('A18_e2e')),
  '(j) la Classe est a l''enseignant, active, ses seances sont materialisees');
-- creer_groupe : sans disponibilites (D4), mais avec les collisions de duree.
SELECT pg_temp.qui(pg_temp.t('admin'), 'admin');
SET LOCAL ROLE authenticated;
SELECT pg_temp.vrai(public.creer_groupe(pg_temp.t('tcreer'), 'adulte', 'Duree creer', 3::smallint, 18::smallint,
                      6::smallint, 'Europe/Paris'::text, NULL::smallint) IS NOT NULL,
  '(j) creer_groupe cree une Classe d''adultes pour un enseignant sans disponibilite declaree : la couverture n''est qu''un avertissement (D4)');
SELECT pg_temp.refus(format($$SELECT public.creer_groupe(%L, 'enfant', 'Duree collision', 3::smallint, 19::smallint,
                       5::smallint, 'Europe/Paris'::text, NULL::smallint)$$, pg_temp.t('tcreer')),
  'P0001', 'chevauchement avec une classe ou affectation active',
  '(j) ... et refuse ensuite une Classe d''enfants de 19 h pour le meme enseignant : elle chevauche la Classe d''adultes de 18 h a 19 h 30');
SELECT pg_temp.vrai(public.creer_groupe(pg_temp.t('tcreer'), 'enfant', 'Duree sans collision', 3::smallint, 20::smallint,
                      5::smallint, 'Europe/Paris'::text, NULL::smallint) IS NOT NULL,
  '(j) ... mais accepte celle de 20 h');
RESET ROLE;

-- ------------------------------------------------------------------
-- (k) Droits et forme des fonctions
-- ------------------------------------------------------------------
DO $droits$
DECLARE
  v_f regprocedure;
  v_role text;
  v_p pg_catalog.pg_proc%ROWTYPE;
BEGIN
  FOREACH v_f IN ARRAY ARRAY[
      'app_private.duree_seance_minutes(uuid,text)'::regprocedure,
      'app_private.verifier_affectation_enseignant_base(uuid,uuid,boolean)'::regprocedure,
      'app_private.verifier_affectation_enseignant(uuid,uuid,boolean)'::regprocedure] LOOP
    SELECT * INTO v_p FROM pg_catalog.pg_proc WHERE oid = v_f::oid;
    IF v_p.prosecdef OR pg_catalog.pg_get_userbyid(v_p.proowner) <> 'postgres'
       OR NOT coalesce(v_p.proconfig @> ARRAY['search_path=""'], false) THEN
      RAISE EXCEPTION 'CLASSES-DUREE ROUGE : (k) % doit etre INVOKER, a postgres, search_path vide', v_f;
    END IF;
    FOREACH v_role IN ARRAY ARRAY['anon', 'authenticated', 'service_role', 'agent_ro'] LOOP
      IF pg_catalog.has_function_privilege(v_role, v_f, 'EXECUTE') THEN
        RAISE EXCEPTION 'CLASSES-DUREE ROUGE : (k) % peut executer %', v_role, v_f;
      END IF;
    END LOOP;
    IF coalesce(pg_catalog.obj_description(v_f::oid, 'pg_proc'), '') = '' THEN
      RAISE EXCEPTION 'CLASSES-DUREE ROUGE : (k) % : commentaire absent', v_f;
    END IF;
  END LOOP;
  -- Le predicat public garde sa signature et ses droits (lot c11bis).
  IF (SELECT p.proacl::text FROM pg_catalog.pg_proc p
       WHERE p.oid = 'public.tc_verifier_affectation_enseignant(uuid,uuid)'::regprocedure::oid)
       <> '{postgres=X/postgres,service_role=X/postgres}' THEN
    RAISE EXCEPTION 'CLASSES-DUREE ROUGE : (k) droits du predicat public changes';
  END IF;
  -- Aucune signature publique ajoutee : creer_groupe garde son empreinte F86.
  IF coalesce(pg_catalog.obj_description(
       'public.creer_groupe(uuid,text,text,smallint,smallint,smallint,text,smallint)'::regprocedure::oid, 'pg_proc'), '')
     NOT LIKE '%md5_functiondef=' || pg_catalog.md5(pg_catalog.pg_get_functiondef(
       'public.creer_groupe(uuid,text,text,smallint,smallint,smallint,text,smallint)'::regprocedure)) || '%' THEN
    RAISE EXCEPTION 'CLASSES-DUREE ROUGE : (k) empreinte F86 de creer_groupe';
  END IF;
END
$droits$;
SELECT pg_temp.ok('(k) trois fonctions INVOKER sans EXECUTE client, commentees ; predicat public et empreinte de creer_groupe inchanges');

-- ------------------------------------------------------------------
-- (l) Le moment de la verification
-- ------------------------------------------------------------------
-- instant_creneau rend la PROCHAINE occurrence d'un creneau apres maintenant. La
-- ligne d'un enseignant dont la grille tombe a la demi-heure de la Classe
-- (Calcutta) et qui couvre le debut de la prochaine seance a donc pu commencer
-- il y a moins d'une heure : sa derniere occurrence deja commencee (semaine -1)
-- compte, sinon l'enseignant etait refuse pendant cette demi-heure de la semaine.
-- Pour fixer l'horloge, instant_creneau lit l'heure de reference dans test.now
-- (vide : maintenant). Le remplacement est annule avec la transaction.
CREATE OR REPLACE FUNCTION public.instant_creneau(
  p_weekday integer, p_hour integer, p_tz text, p_semaine_offset integer DEFAULT 0)
RETURNS timestamp with time zone
LANGUAGE sql STABLE SET search_path TO ''
AS $f$
  SELECT public.instant_creneau_reference(
    p_weekday, p_hour, p_tz, p_semaine_offset,
    coalesce(nullif(pg_catalog.current_setting('test.now', true), '')::timestamptz, pg_catalog.now()));
$f$;

CREATE FUNCTION pg_temp.horloge(p_instant timestamptz) RETURNS void
LANGUAGE sql AS $$ SELECT pg_catalog.set_config('test.now', coalesce(p_instant::text, ''), true); $$;

-- L'horloge fixee est bien celle que lit le predicat : mercredi 21 octobre 2026,
-- 15 h UTC, la prochaine occurrence du mercredi 18 h de Paris (heure d'ete) est
-- a 16 h UTC le jour meme ; a 16 h 30 UTC elle est a la semaine suivante, en
-- heure d'hiver (le changement d'heure est le 25 octobre).
SELECT pg_temp.horloge('2026-10-21 15:00:00+00');
SELECT pg_temp.vrai(public.instant_creneau(3, 18, 'Europe/Paris', 0) = timestamptz '2026-10-21 16:00:00+00',
  '(l) fixture : a 15 h UTC, la prochaine occurrence du mercredi 18 h de Paris est le jour meme a 16 h UTC');
SELECT pg_temp.horloge('2026-10-21 16:30:00+00');
SELECT pg_temp.vrai(public.instant_creneau(3, 18, 'Europe/Paris', 0) = timestamptz '2026-10-28 17:00:00+00',
  '(l) fixture : a 16 h 30 UTC, c''est celle de la semaine suivante, en heure d''hiver (17 h UTC)');
SELECT pg_temp.horloge(NULL);

-- Calcutta (heures 21, 22, 23 : de 15 h 30 a 18 h 30 UTC) et la Classe d'enfants de
-- 18 h a Paris (16 h UTC en ete, 17 h UTC en hiver) : couvert a toute heure de la
-- semaine, y compris pendant la demi-heure ou la ligne de 15 h 30 a deja commence.
-- Le cours d'adultes de 90 minutes de la meme Classe est couvert aussi.
DO $balayage$
DECLARE
  v_t timestamptz;
  v_rouges text := '';
  v_n int := 0;
BEGIN
  FOR v_t IN SELECT pg_catalog.generate_series(timestamptz '2026-10-21 14:00:00+00',
                                                timestamptz '2026-10-21 18:45:00+00', interval '15 minutes') LOOP
    PERFORM pg_temp.horloge(v_t);
    v_n := v_n + 1;
    IF pg_temp.verdict('E18', 'tk2') IS DISTINCT FROM 'accepte' THEN
      v_rouges := v_rouges || ' E18/tk2@' || v_t::text || ' (' || pg_temp.verdict('E18', 'tk2') || ')';
    END IF;
    IF pg_temp.verdict('A18', 'tk2') IS DISTINCT FROM 'accepte' THEN
      v_rouges := v_rouges || ' A18/tk2@' || v_t::text || ' (' || pg_temp.verdict('A18', 'tk2') || ')';
    END IF;
  END LOOP;
  PERFORM pg_temp.horloge(NULL);
  IF v_rouges <> '' OR v_n <> 20 THEN
    RAISE EXCEPTION 'CLASSES-DUREE ROUGE : (l) Calcutta refuse a certaines heures de la semaine (% instants) :%', v_n, v_rouges;
  END IF;
END
$balayage$;
SELECT pg_temp.ok('(l) Calcutta (heures 21, 22, 23) couvre la Classe d''enfants de 18 h et le cours d''adultes a toute heure du mercredi, y compris quand la ligne de 15 h 30 UTC a deja commence (20 instants, de 14 h a 18 h 45 UTC)');

-- ... et la couverture refusee reste refusee a ces memes heures (le balayage ne
-- rend pas tout acceptable) : Calcutta, heures 21 et 22 seulement.
DO $balayage$
DECLARE
  v_t timestamptz;
  v_acceptes text := '';
BEGIN
  FOR v_t IN SELECT pg_catalog.generate_series(timestamptz '2026-10-21 14:00:00+00',
                                                timestamptz '2026-10-21 18:45:00+00', interval '15 minutes') LOOP
    PERFORM pg_temp.horloge(v_t);
    IF pg_temp.verdict('E18', 'tk1') = 'accepte' OR pg_temp.verdict('E18', 'tk3') = 'accepte' THEN
      v_acceptes := v_acceptes || ' ' || v_t::text;
    END IF;
  END LOOP;
  PERFORM pg_temp.horloge(NULL);
  IF v_acceptes <> '' THEN
    RAISE EXCEPTION 'CLASSES-DUREE ROUGE : (l) une couverture incomplete est acceptee a :%', v_acceptes;
  END IF;
END
$balayage$;
SELECT pg_temp.ok('(l) ... et Calcutta heures 21 et 22 seulement, ou 22 et 23 seulement, reste refusee a toute heure du mercredi');

-- La derniere semaine : a 16 h 30 UTC (18 h 30 a Paris), la prochaine occurrence
-- du mercredi 18 h est la semaine suivante, et la ligne de 19 h d'aujourd'hui a
-- deja sa prochaine occurrence ; la 52e occurrence de la Classe a besoin de la
-- ligne de 19 h de la semaine 52.
SELECT pg_temp.horloge('2026-10-21 16:30:00+00');
SELECT pg_temp.vrai(pg_temp.verdict('A18', 'ta2') = 'accepte' AND pg_temp.verdict('A18', 'tu3') = 'accepte'
                    AND pg_temp.verdict('A18', 'te1') LIKE 'enseignant non disponible: jour 3, heure 18%',
  '(l) a 18 h 30 a Paris, le cours d''adultes de 18 h est couvert par les heures 18 et 19 jusqu''a la derniere semaine examinee (la ligne de 19 h de la semaine 52 compte), et refuse avec la seule heure 18');
SELECT pg_temp.horloge(NULL);

-- Les deux saisons sont examinees quelle que soit la date de la verification. Au
-- 1er avril 2026 (heure d'ete depuis le 29 mars), Riyad (UTC+3 toute l'annee) avec
-- les heures 19 et 20 couvre le cours d'adultes de 18 h a Paris tout l'ete mais
-- pas l'hiver, qui ne commence que le 25 octobre : le refus est a la semaine 30
-- (mercredi 28 octobre), loin de la premiere.
SELECT pg_temp.horloge('2026-04-01 12:00:00+00');
SELECT pg_temp.vrai(pg_temp.verdict('A18', 'tr1') LIKE 'enseignant non disponible: jour 3, heure 18, fuseau Europe/Paris, semaine 30, instant %'
  AND substring(pg_temp.verdict('A18', 'tr1') from 'instant (.*)$')::timestamptz = timestamptz '2026-10-28 17:00:00+00',
  '(l) au 1er avril, l''hiver est a 30 semaines : Riyad heures 19 et 20 couvre l''ete, le refus tombe a la semaine 30 (28 octobre), jamais avant');
SELECT pg_temp.horloge(NULL);

-- Le dimanche soir qui passe au lundi : la ligne du lundi 0 h suit la seance du
-- dimanche 23 h, quel que soit le moment ou l'on verifie.
DO $balayage$
DECLARE
  v_t timestamptz;
  v_rouges text := '';
  v_n int := 0;
BEGIN
  FOR v_t IN SELECT pg_catalog.generate_series(timestamptz '2026-11-01 21:00:00+00',
                                                timestamptz '2026-11-02 00:45:00+00', interval '15 minutes') LOOP
    PERFORM pg_temp.horloge(v_t);
    v_n := v_n + 1;
    IF pg_temp.verdict('AS23', 'ts1') IS DISTINCT FROM 'accepte' THEN
      v_rouges := v_rouges || ' ts1@' || v_t::text || ' (' || pg_temp.verdict('AS23', 'ts1') || ')';
    END IF;
    IF pg_temp.verdict('AS23', 'ts2') NOT LIKE 'enseignant non disponible: jour 7, heure 23%' THEN
      v_rouges := v_rouges || ' ts2@' || v_t::text;
    END IF;
  END LOOP;
  PERFORM pg_temp.horloge(NULL);
  IF v_rouges <> '' OR v_n <> 16 THEN
    RAISE EXCEPTION 'CLASSES-DUREE ROUGE : (l) le dimanche 23 h vers le lundi 0 h change de verdict selon le moment (% instants) :%', v_n, v_rouges;
  END IF;
END
$balayage$;
SELECT pg_temp.ok('(l) le dimanche 23 h passe au lundi 0 h a toute heure de la verification (16 instants, du dimanche 22 h au lundi 1 h45 a Paris) : les heures 23 et 0 couvrent, la seule heure 23 refuse');

SELECT pg_temp.vrai(coalesce(nullif(pg_catalog.current_setting('test.n', true), ''), '0')::int >= 107,
  'au moins 107 controles ont passe (108 avec celui-ci)');

ROLLBACK;
