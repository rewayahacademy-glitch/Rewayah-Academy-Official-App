-- HORLOGE-ET-LIEU, partie A : conversion des classes vers l'heure de l'academie
-- (La Mecque) sans deplacer aucun instant (migration
-- 20261123940000_horloge_lieu.sql ; decision H1 et H4,
-- docs/current/pedagogie/HORLOGE-ET-LIEU.md).
--
-- Rejoue sur une base neuve, apres stub_auth.sql et toutes les migrations.
-- Fixtures sans donnee personnelle ; tout est annule a la fin. Chaque controle
-- reussi ecrit une ligne "HL OK" ; un echec leve 'HL ROUGE : ...' (ON_ERROR_STOP).
--
-- Independant de la date d'execution : le cas Paris rejoue l'etat reel de la
-- production du 12/11/2026 a un instant de reference FIXE (2026-11-12 22:00 UTC,
-- seances posees a la main) ; les cas qui suivent l'horloge reelle utilisent
-- des fuseaux sans changement d'heure.
BEGIN;

INSERT INTO auth.users (id, email) VALUES
  ('d1000000-0000-4000-8000-000000000001', 'hl-admin@example.test'),
  ('d1000000-0000-4000-8000-0000000000e1', 'hl-e1@example.test'),
  ('d1000000-0000-4000-8000-0000000000e2', 'hl-e2@example.test'),
  ('d1000000-0000-4000-8000-000000000a01', 'hl-tuteur@example.test'),
  ('d1000000-0000-4000-8000-000000000a02', 'hl-eleve@example.test'),
  ('d1000000-0000-4000-8000-000000000a03', 'hl-eleve2@example.test');

INSERT INTO public.profiles
  (id, immutable_id, role, first_name, last_name, account_status, gender, access_until)
VALUES
  ('d1000000-0000-4000-8000-000000000001', 'HLADMIN000000001', 'admin',
   'Fixture', 'Direction', 'active', 'female', NULL),
  ('d1000000-0000-4000-8000-0000000000e1', 'HLTEACHER0000E01', 'teacher',
   'Fixture', 'Enseignante', 'provisional_active', 'female', NULL),
  ('d1000000-0000-4000-8000-0000000000e2', 'HLTEACHER0000E02', 'teacher',
   'Fixture', 'Enseignant', 'provisional_active', 'male', NULL);

INSERT INTO public.teacher_profiles
  (profile_id, country, languages, weekly_hours_cap, kyc_status, timezone_iana, deleted_at)
VALUES
  ('d1000000-0000-4000-8000-0000000000e1', 'FR', ARRAY['francais'], 40, 'approved', 'Europe/Paris', NULL),
  ('d1000000-0000-4000-8000-0000000000e2', 'FR', ARRAY['francais'], 40, 'approved', 'Europe/Paris', NULL);

-- La grille complete, comme la seule enseignante de la production (7 x 24).
INSERT INTO public.weekly_availability (profile_id, weekday, hour_local, timezone_iana)
SELECT 'd1000000-0000-4000-8000-0000000000e1'::uuid, j, h, 'Europe/Paris'
  FROM pg_catalog.generate_series(1, 7) AS j, pg_catalog.generate_series(0, 23) AS h;

-- Un foyer, un tuteur et un eleve inscrit aux classes, pour que les notifications
-- aient de vrais destinataires (famille et enseignante).
INSERT INTO public.households (id, timezone) VALUES
  ('d1000000-0000-4000-8000-0000000000f1', 'Europe/Paris');
INSERT INTO public.profiles
  (id, immutable_id, role, first_name, last_name, account_status, gender, household_id, access_until)
VALUES
  ('d1000000-0000-4000-8000-000000000a01', 'HLTUTEUR00000A01', 'guardian',
   'Fixture', 'Tuteur', 'active', 'male', 'd1000000-0000-4000-8000-0000000000f1', NULL),
  ('d1000000-0000-4000-8000-000000000a02', 'HLELEVE000000A02', 'student',
   'Fixture', 'Eleve', 'active', 'female', 'd1000000-0000-4000-8000-0000000000f1', NULL),
  ('d1000000-0000-4000-8000-000000000a03', 'HLELEVE000000A03', 'student',
   'Fixture', 'Eleve2', 'active', 'male', 'd1000000-0000-4000-8000-0000000000f1', NULL);
UPDATE public.households SET primary_guardian_id = 'd1000000-0000-4000-8000-000000000a01'
 WHERE id = 'd1000000-0000-4000-8000-0000000000f1';

SELECT set_config('hl.t0', pg_catalog.now()::text, true);

-- =====================================================================
-- (A) L'etat reel de la production du 12/11/2026, a un instant FIXE
-- =====================================================================
-- Classe adultes : mercredi 19 h et jeudi 18 h (75 min) ; classe enfants :
-- vendredi 19 h (90 min) ; tout a Paris. Seances de l'horizon, posees a la main
-- (aucune materialisation : l'horizon est mis a zero dans cette transaction).
UPDATE public.app_config SET value = '0'::jsonb WHERE key = 'matching_horizon_weeks';

INSERT INTO public.groupes
  (id, teacher_id, etat, type_public, seuil_max, libelle, weekday, hour_local, timezone_iana,
   genre_public, created_at)
VALUES
  ('d1000000-0000-4000-8000-0000000000c1', 'd1000000-0000-4000-8000-0000000000e1', 'active', 'adulte', 6,
   'HL classe adultes', 3, 19, 'Europe/Paris', 'indetermine', pg_catalog.now() - interval '40 days'),
  ('d1000000-0000-4000-8000-0000000000c2', 'd1000000-0000-4000-8000-0000000000e1', 'active', 'enfant', 5,
   'HL classe enfants', 5, 19, 'Europe/Paris', 'indetermine', pg_catalog.now() - interval '40 days');
-- (l'ancre de chaque classe est ecrite par le declencheur de l'ancre)
INSERT INTO public.groupe_creneaux (groupe_id, weekday, hour_local, duree_minutes)
VALUES ('d1000000-0000-4000-8000-0000000000c1', 4, 18, 75);
UPDATE public.groupe_creneaux SET duree_minutes = 75
 WHERE groupe_id = 'd1000000-0000-4000-8000-0000000000c1' AND weekday = 3 AND hour_local = 19;
UPDATE public.groupe_creneaux SET duree_minutes = 90
 WHERE groupe_id = 'd1000000-0000-4000-8000-0000000000c2' AND weekday = 5 AND hour_local = 19;

INSERT INTO public.groupe_membres (groupe_id, student_id)
VALUES ('d1000000-0000-4000-8000-0000000000c1', 'd1000000-0000-4000-8000-000000000a02'),
       ('d1000000-0000-4000-8000-0000000000c2', 'd1000000-0000-4000-8000-000000000a03');

-- Les seances de l'horizon : mercredis 19 h Paris = 18:00 UTC, jeudis 18 h Paris
-- = 17:00 UTC, vendredis 19 h Paris = 18:00 UTC (novembre : heure d'hiver).
INSERT INTO public.sessions (teacher_id, started_at, ended_at, session_type, groupe_id, status, join_opens_at)
SELECT 'd1000000-0000-4000-8000-0000000000e1', d.debut, d.debut + make_interval(mins => d.duree),
       d.type, d.groupe, d.statut::public.session_status, d.debut - interval '20 minutes'
  FROM (VALUES
    ('2026-11-18 18:00:00+00'::timestamptz, 75, 'standard', 'd1000000-0000-4000-8000-0000000000c1'::uuid, 'planned'),
    ('2026-11-25 18:00:00+00', 75, 'standard', 'd1000000-0000-4000-8000-0000000000c1', 'planned'),
    ('2026-12-02 18:00:00+00', 75, 'standard', 'd1000000-0000-4000-8000-0000000000c1', 'planned'),
    ('2026-12-09 18:00:00+00', 75, 'standard', 'd1000000-0000-4000-8000-0000000000c1', 'planned'),
    ('2026-11-19 17:00:00+00', 75, 'standard', 'd1000000-0000-4000-8000-0000000000c1', 'planned'),
    ('2026-11-26 17:00:00+00', 75, 'standard', 'd1000000-0000-4000-8000-0000000000c1', 'planned'),
    ('2026-12-03 17:00:00+00', 75, 'standard', 'd1000000-0000-4000-8000-0000000000c1', 'planned'),
    ('2026-12-10 17:00:00+00', 75, 'standard', 'd1000000-0000-4000-8000-0000000000c1', 'planned'),
    -- l'ancien creneau du jeudi 19 h : annule (comme en production), il ne compte pas
    ('2026-11-19 18:00:00+00', 75, 'standard', 'd1000000-0000-4000-8000-0000000000c1', 'canceled'),
    ('2026-11-13 18:00:00+00', 90, 'child',    'd1000000-0000-4000-8000-0000000000c2', 'planned'),
    ('2026-11-20 18:00:00+00', 90, 'child',    'd1000000-0000-4000-8000-0000000000c2', 'planned'),
    ('2026-11-27 18:00:00+00', 90, 'child',    'd1000000-0000-4000-8000-0000000000c2', 'planned'),
    ('2026-12-04 18:00:00+00', 90, 'child',    'd1000000-0000-4000-8000-0000000000c2', 'planned')
  ) AS d(debut, duree, type, groupe, statut);

-- Les declencheurs differes des fixtures (classe creee, eleve inscrit) parlent
-- maintenant : la photographie qui suit ne compte que ce que la conversion ecrit.
SET CONSTRAINTS ALL IMMEDIATE;
SET CONSTRAINTS ALL DEFERRED;
-- Ces notifications des fixtures sont vieillies d'un jour : le notifieur ne
-- repete pas, dans une meme transaction (meme now()), un evenement equivalent
-- (classe_creee pour creneau_change). Sans cela, un notifieur qui parlerait
-- pendant la conversion serait masque par ces lignes, et la preuve de silence
-- serait creuse.
UPDATE public.notifications SET cree_le = cree_le - interval '1 day';

-- Photographie avant : sessions, notifications, push, courriels, creneaux.
CREATE TEMP TABLE hl_avant AS
SELECT s.id, s.started_at, s.ended_at, s.status::text AS status, s.groupe_id,
       s.teacher_id, s.deleted_at IS NOT NULL AS supprimee
  FROM public.sessions s
 WHERE s.groupe_id IN ('d1000000-0000-4000-8000-0000000000c1', 'd1000000-0000-4000-8000-0000000000c2');
CREATE TEMP TABLE hl_compteurs AS
SELECT (SELECT pg_catalog.count(*) FROM public.notifications) AS notifications,
       (SELECT pg_catalog.count(*) FROM public.push_sortants) AS push,
       (SELECT pg_catalog.count(*) FROM public.courriels_sortants) AS courriels,
       (SELECT pg_catalog.count(*) FROM public.sessions) AS sessions;

DO $a$
DECLARE
  v_n integer;
  v_avant integer;
  v_ref constant timestamptz := '2026-11-12 22:00:00+00';
BEGIN
  -- La conversion : deux classes, rien d'autre.
  v_n := private.convertir_classes_hors_academie(v_ref);
  IF v_n <> 2 THEN
    RAISE EXCEPTION 'HL ROUGE : % classes converties au lieu de 2', v_n;
  END IF;
  RAISE NOTICE 'HL OK : deux classes converties';

  -- Classe adultes : mercredi 21 h et jeudi 20 h a La Mecque ; enfants : vendredi 21 h.
  IF NOT EXISTS (SELECT 1 FROM public.groupes g
                  WHERE g.id = 'd1000000-0000-4000-8000-0000000000c1'
                    AND g.timezone_iana = 'Asia/Riyadh' AND g.weekday = 3 AND g.hour_local = 21) THEN
    RAISE EXCEPTION 'HL ROUGE : la classe adultes n''est pas a Asia/Riyadh mercredi 21 h';
  END IF;
  IF (SELECT pg_catalog.array_agg(gc.weekday::text || ':' || gc.hour_local::text || ':' || coalesce(gc.duree_minutes::text, '-')
                                  ORDER BY gc.weekday)
        FROM public.groupe_creneaux gc WHERE gc.groupe_id = 'd1000000-0000-4000-8000-0000000000c1')
     IS DISTINCT FROM ARRAY['3:21:75', '4:20:75'] THEN
    RAISE EXCEPTION 'HL ROUGE : creneaux adultes apres conversion : %',
      (SELECT pg_catalog.array_agg(gc.weekday::text || ':' || gc.hour_local::text ORDER BY gc.weekday)
         FROM public.groupe_creneaux gc WHERE gc.groupe_id = 'd1000000-0000-4000-8000-0000000000c1');
  END IF;
  IF NOT EXISTS (SELECT 1 FROM public.groupes g
                  WHERE g.id = 'd1000000-0000-4000-8000-0000000000c2'
                    AND g.timezone_iana = 'Asia/Riyadh' AND g.weekday = 5 AND g.hour_local = 21)
     OR (SELECT pg_catalog.array_agg(gc.weekday::text || ':' || gc.hour_local::text || ':' || coalesce(gc.duree_minutes::text, '-'))
           FROM public.groupe_creneaux gc WHERE gc.groupe_id = 'd1000000-0000-4000-8000-0000000000c2')
        IS DISTINCT FROM ARRAY['5:21:90'] THEN
    RAISE EXCEPTION 'HL ROUGE : la classe enfants n''est pas a vendredi 21 h (90 min) a La Mecque';
  END IF;
  RAISE NOTICE 'HL OK : mercredi 19 h / jeudi 18 h / vendredi 19 h Paris deviennent mercredi 21 h / jeudi 20 h / vendredi 21 h a La Mecque, durees gardees';

  -- Aucune seance n'a bouge : memes lignes, memes instants, meme nombre.
  IF EXISTS (
       SELECT 1 FROM hl_avant a
        FULL JOIN public.sessions s ON s.id = a.id
        WHERE (a.id IS NULL AND s.groupe_id IN ('d1000000-0000-4000-8000-0000000000c1',
                                                'd1000000-0000-4000-8000-0000000000c2'))
           OR (s.id IS NULL AND a.id IS NOT NULL)
           OR (a.id IS NOT NULL AND s.id IS NOT NULL AND
               (a.started_at, a.ended_at, a.status, a.groupe_id, a.teacher_id, a.supprimee)
               IS DISTINCT FROM
               (s.started_at, s.ended_at, s.status::text, s.groupe_id, s.teacher_id, s.deleted_at IS NOT NULL))) THEN
    RAISE EXCEPTION 'HL ROUGE : une seance a ete creee, supprimee ou deplacee par la conversion';
  END IF;
  SELECT pg_catalog.count(*) INTO v_avant FROM hl_avant;
  IF v_avant <> 13 THEN
    RAISE EXCEPTION 'HL ROUGE : % seances de depart au lieu de 13', v_avant;
  END IF;
  RAISE NOTICE 'HL OK : les 13 seances (dont une annulee) sont inchangees, instant par instant';

  -- Les instants a La Mecque : mercredi 21 h, jeudi 20 h, vendredi 21 h.
  IF EXISTS (SELECT 1 FROM public.sessions s
              WHERE s.groupe_id = 'd1000000-0000-4000-8000-0000000000c1' AND s.status = 'planned'
                AND NOT ((pg_catalog.date_part('isodow', s.started_at AT TIME ZONE 'Asia/Riyadh') = 3
                          AND pg_catalog.date_part('hour', s.started_at AT TIME ZONE 'Asia/Riyadh') = 21)
                         OR (pg_catalog.date_part('isodow', s.started_at AT TIME ZONE 'Asia/Riyadh') = 4
                          AND pg_catalog.date_part('hour', s.started_at AT TIME ZONE 'Asia/Riyadh') = 20))) THEN
    RAISE EXCEPTION 'HL ROUGE : une seance adultes ne tombe pas sur mercredi 21 h ou jeudi 20 h a La Mecque';
  END IF;
  RAISE NOTICE 'HL OK : chaque seance prevue tombe sur un creneau de La Mecque';

  -- Aucune notification, aucun push, aucun courriel, aucune seance creee.
  IF (SELECT pg_catalog.count(*) FROM public.notifications) <> (SELECT notifications FROM hl_compteurs)
     OR (SELECT pg_catalog.count(*) FROM public.push_sortants) <> (SELECT push FROM hl_compteurs)
     OR (SELECT pg_catalog.count(*) FROM public.courriels_sortants) <> (SELECT courriels FROM hl_compteurs)
     OR (SELECT pg_catalog.count(*) FROM public.sessions) <> (SELECT sessions FROM hl_compteurs) THEN
    RAISE EXCEPTION 'HL ROUGE : la conversion a cree une notification, un push, un courriel ou une seance';
  END IF;
  -- Les declencheurs de notification sont differes : ils parlent a la section (B).
  RAISE NOTICE 'HL OK : 0 notification, 0 push, 0 courriel, 0 seance creee (avant le commit simule)';

  -- Les disponibilites de l'enseignante (lignes a l'heure de Paris, instants
  -- inchanges) couvrent toujours les classes converties : le predicat qui exige
  -- la couverture passe, avant comme apres (aucune ligne n'a ete touchee).
  PERFORM app_private.verifier_affectation_enseignant_base(
    'd1000000-0000-4000-8000-0000000000c1', 'd1000000-0000-4000-8000-0000000000e1', true);
  PERFORM app_private.verifier_affectation_enseignant_base(
    'd1000000-0000-4000-8000-0000000000c2', 'd1000000-0000-4000-8000-0000000000e1', true);
  IF (SELECT pg_catalog.count(*) FROM public.weekly_availability
       WHERE profile_id = 'd1000000-0000-4000-8000-0000000000e1' AND timezone_iana = 'Europe/Paris') <> 168 THEN
    RAISE EXCEPTION 'HL ROUGE : les disponibilites de l''enseignante ont change pendant la conversion';
  END IF;
  RAISE NOTICE 'HL OK : les 168 disponibilites gardent leurs instants (lignes a l''heure de Paris) et couvrent les classes converties';

  -- Rejouer la conversion : rien a faire.
  IF private.convertir_classes_hors_academie(v_ref) <> 0 THEN
    RAISE EXCEPTION 'HL ROUGE : la conversion rejouee a converti quelque chose';
  END IF;
  -- La materialisation, rejouee, ne cree rien (l'horizon reel est a zero ici).
  RAISE NOTICE 'HL OK : conversion rejouee : rien a faire';
END
$a$;

-- Le journal a ecrit une ligne par classe, avec les anciennes et nouvelles valeurs.
DO $b$
BEGIN
  IF (SELECT pg_catalog.count(*) FROM private.conversions_horloge) <> 2
     OR NOT EXISTS (SELECT 1 FROM private.conversions_horloge c
                     WHERE c.groupe_id = 'd1000000-0000-4000-8000-0000000000c1'
                       AND c.fuseau_avant = 'Europe/Paris' AND c.fuseau_apres = 'Asia/Riyadh'
                       AND c.weekday_avant = 3 AND c.hour_avant = 19
                       AND c.weekday_apres = 3 AND c.hour_apres = 21
                       AND c.nb_seances = 9) THEN
    RAISE EXCEPTION 'HL ROUGE : journal incomplet (% lignes)',
      (SELECT pg_catalog.count(*) FROM private.conversions_horloge);
  END IF;
  RAISE NOTICE 'HL OK : journal : deux lignes, anciennes et nouvelles valeurs, 9 seances photographiees pour la classe adultes';
END
$b$;

-- =====================================================================
-- (B) La conversion a la validation du commit : les notifications differees
--     ne se declenchent pas non plus (les declencheurs sont differes)
-- =====================================================================
SET CONSTRAINTS ALL IMMEDIATE;
DO $b1$
BEGIN
  IF (SELECT pg_catalog.count(*) FROM public.notifications) <> (SELECT notifications FROM hl_compteurs)
     OR (SELECT pg_catalog.count(*) FROM public.push_sortants) <> (SELECT push FROM hl_compteurs)
     OR (SELECT pg_catalog.count(*) FROM public.courriels_sortants) <> (SELECT courriels FROM hl_compteurs) THEN
    RAISE EXCEPTION 'HL ROUGE : les notifications differees ont parle apres la conversion (notifications % / push % / courriels %)',
      (SELECT pg_catalog.count(*) FROM public.notifications) - (SELECT notifications FROM hl_compteurs),
      (SELECT pg_catalog.count(*) FROM public.push_sortants) - (SELECT push FROM hl_compteurs),
      (SELECT pg_catalog.count(*) FROM public.courriels_sortants) - (SELECT courriels FROM hl_compteurs);
  END IF;
  RAISE NOTICE 'HL OK : declencheurs differes executes : toujours 0 notification, 0 push, 0 courriel';
END
$b1$;
SET CONSTRAINTS ALL DEFERRED;

-- (B2) CONTROLE NEGATIF : la preuve de silence n'est valable que si, sans la
-- reconnaissance de la conversion, la meme conversion aurait notifie. Une classe
-- de plus, un enseignant destinataire ; on convertit, on brouille le journal
-- (la reconnaissance echoue), puis on laisse parler les declencheurs differes.
UPDATE public.app_config SET value = '0'::jsonb WHERE key = 'matching_horizon_weeks';
INSERT INTO public.groupes (id, teacher_id, etat, type_public, seuil_max, libelle, weekday, hour_local,
                            timezone_iana, genre_public, created_at)
VALUES ('d1000000-0000-4000-8000-0000000000c6', 'd1000000-0000-4000-8000-0000000000e2', 'active', 'adulte', 6,
        'HL controle negatif', 2, 12, 'Africa/Abidjan', 'indetermine', pg_catalog.now() - interval '40 days');
SET CONSTRAINTS ALL IMMEDIATE;
SET CONSTRAINTS ALL DEFERRED;
UPDATE public.notifications SET cree_le = cree_le - interval '1 day';
CREATE TEMP TABLE hl_neg AS SELECT (SELECT pg_catalog.count(*) FROM public.notifications) AS n;
SELECT private.convertir_classe_vers_academie('d1000000-0000-4000-8000-0000000000c6', '2026-11-12 22:00:00+00');
UPDATE private.conversions_horloge
   SET fuseau_avant = 'x', creneaux = '[]'::jsonb
 WHERE groupe_id = 'd1000000-0000-4000-8000-0000000000c6';
SET CONSTRAINTS ALL IMMEDIATE;
DO $b2$
DECLARE
  v_en_plus bigint;
BEGIN
  SELECT pg_catalog.count(*) - (SELECT n FROM hl_neg) INTO v_en_plus FROM public.notifications;
  IF v_en_plus <= 0 THEN
    RAISE EXCEPTION 'HL ROUGE : controle negatif creux : sans la reconnaissance, la conversion ne notifie pas non plus';
  END IF;
  RAISE NOTICE 'HL OK : controle negatif : sans la reconnaissance, la meme conversion aurait cree % notification(s)', v_en_plus;
END
$b2$;
SET CONSTRAINTS ALL DEFERRED;

-- =====================================================================
-- (C) Un vrai changement de creneau, apres la migration, notifie comme avant
-- =====================================================================
SELECT set_config('request.jwt.claim.sub', 'd1000000-0000-4000-8000-000000000001', true);
SELECT set_config('request.jwt.claims', '{"app_metadata":{"role":"admin"}}', true);
SELECT set_config('test.uid', 'd1000000-0000-4000-8000-000000000001', true);
SELECT set_config('test.jwt', '{"app_metadata":{"role":"admin"}}', true);

-- Le test de la partie C a besoin de seances a venir reelles : l'horizon revient.
UPDATE public.app_config SET value = '4'::jsonb WHERE key = 'matching_horizon_weeks';

DO $c$
DECLARE
  v_avant bigint;
  v_apres bigint;
  v_creneau_avant bigint;
BEGIN
  SELECT pg_catalog.count(*) INTO v_creneau_avant FROM public.notifications WHERE evenement = 'creneau_change';
  -- La direction deplace le creneau du jeudi (20 h a La Mecque) a 19 h : un vrai changement.
  SET LOCAL ROLE authenticated;
  PERFORM public.modifier_creneau_classe_admin(
    'd1000000-0000-4000-8000-0000000000c1', 4, 20, 4, 19, NULL, 'scenario HL : vrai changement');
  RESET ROLE;
  SET CONSTRAINTS ALL IMMEDIATE;
  SELECT pg_catalog.count(*) INTO v_apres FROM public.notifications WHERE evenement = 'creneau_change';
  IF v_apres <= v_creneau_avant THEN
    RAISE EXCEPTION 'HL ROUGE : un vrai changement de creneau, apres la migration, ne notifie plus (% -> %)',
      v_creneau_avant, v_apres;
  END IF;
  RAISE NOTICE 'HL OK : un vrai changement de creneau notifie comme avant (% notification(s) creneau_change de plus)',
    v_apres - v_creneau_avant;
  SET CONSTRAINTS ALL DEFERRED;
END
$c$;

-- =====================================================================
-- (D) Un utilisateur ne peut ni lire ni ecrire le journal, ni se faire passer
--     pour la conversion
-- =====================================================================
SET LOCAL ROLE authenticated;
DO $d$
BEGIN
  BEGIN
    PERFORM 1 FROM private.conversions_horloge;
    RAISE EXCEPTION 'HL ROUGE : le journal est lisible par un client';
  EXCEPTION WHEN insufficient_privilege THEN
    RAISE NOTICE 'HL OK : le journal n''est pas lisible par un client';
  END;
  BEGIN
    INSERT INTO private.conversions_horloge
      (txid, groupe_id, convertie_le, fuseau_avant, fuseau_apres, weekday_avant, hour_avant,
       weekday_apres, hour_apres, creneaux, nb_seances, empreinte_seances)
    VALUES (pg_catalog.txid_current(), 'd1000000-0000-4000-8000-0000000000c1', pg_catalog.transaction_timestamp(),
            'x', 'y', 1, 1, 1, 1, '[]'::jsonb, 0, '');
    RAISE EXCEPTION 'HL ROUGE : un client a ecrit dans le journal';
  EXCEPTION WHEN insufficient_privilege THEN
    RAISE NOTICE 'HL OK : un client ne peut pas ecrire dans le journal';
  END;
  BEGIN
    PERFORM private.convertir_classe_vers_academie('d1000000-0000-4000-8000-0000000000c1');
    RAISE EXCEPTION 'HL ROUGE : un client a appele la conversion';
  EXCEPTION WHEN insufficient_privilege THEN
    RAISE NOTICE 'HL OK : un client ne peut pas appeler la conversion';
  END;
  BEGIN
    PERFORM private.conversion_horloge_groupe('d1000000-0000-4000-8000-0000000000c1', 1, 1, 'x', 1, 1, 'y');
    RAISE EXCEPTION 'HL ROUGE : un client a appele la reconnaissance de la conversion';
  EXCEPTION WHEN insufficient_privilege THEN
    RAISE NOTICE 'HL OK : un client ne peut pas appeler la reconnaissance de la conversion';
  END;
END
$d$;
RESET ROLE;

-- =====================================================================
-- (E) L'ancien client : memes arguments qu'aujourd'hui, memes instants reels
-- =====================================================================
SET LOCAL ROLE authenticated;
DO $e$
DECLARE
  v_classe uuid;
  v_attendu timestamptz;
  v_premiere timestamptz;
  v_n integer;
  v_converti integer;
  v_changement timestamptz;
BEGIN
  -- creer_classe_creneaux_admin avec ses arguments exacts d'aujourd'hui :
  -- l'heure murale est celle du fuseau recu (Paris).
  v_classe := public.creer_classe_creneaux_admin(
    'd1000000-0000-4000-8000-0000000000e1', 'adulte', 'HL ancien client', 6::smallint, 'Europe/Paris',
    '[{"jour": 6, "heure": 10, "duree": 60}]'::jsonb, 'femmes');
  IF NOT EXISTS (SELECT 1 FROM public.groupes g WHERE g.id = v_classe
                  AND g.timezone_iana = 'Europe/Paris' AND g.weekday = 6 AND g.hour_local = 10) THEN
    RAISE EXCEPTION 'HL ROUGE : l''ancien client ne trouve plus sa classe a l''heure murale de Paris';
  END IF;
  v_attendu := public.instant_creneau_reference(6, 10, 'Europe/Paris', 0, pg_catalog.now());
  SELECT pg_catalog.min(s.started_at) INTO v_premiere FROM public.sessions s
   WHERE s.groupe_id = v_classe AND s.status = 'planned' AND s.deleted_at IS NULL;
  IF v_premiere IS DISTINCT FROM v_attendu THEN
    RAISE EXCEPTION 'HL ROUGE : l''ancien client obtient la premiere seance % au lieu de % (samedi 10 h Paris)',
      v_premiere, v_attendu;
  END IF;
  SELECT pg_catalog.count(*) INTO v_n FROM public.sessions s
   WHERE s.groupe_id = v_classe AND s.status = 'planned' AND s.deleted_at IS NULL;
  RAISE NOTICE 'HL OK : ancien client, creer_classe_creneaux_admin : samedi 10 h Paris, % seances, memes instants qu''avant', v_n;

  -- creer_groupe (8 arguments), avec un fuseau explicite, comme aujourd'hui.
  v_classe := public.creer_groupe(
    'd1000000-0000-4000-8000-0000000000e2', 'enfant', 'HL ancien client enfants', 6::smallint,
    7::smallint, 5::smallint, 'Europe/Paris', NULL);
  v_attendu := public.instant_creneau_reference(6, 7, 'Europe/Paris', 0, pg_catalog.now());
  IF NOT EXISTS (SELECT 1 FROM public.groupes g WHERE g.id = v_classe
                  AND g.timezone_iana = 'Europe/Paris' AND g.weekday = 6 AND g.hour_local = 7) THEN
    RAISE EXCEPTION 'HL ROUGE : creer_groupe a change de sens pour l''ancien client';
  END IF;
  RAISE NOTICE 'HL OK : ancien client, creer_groupe (8 arguments) : meme sens qu''avant';

  -- La tache de nuit convertit ces classes... sauf a moins de 28 jours d'un
  -- changement d'heure de Paris, ou elle refuse sans rien casser (WARNING).
  RESET ROLE;
  v_changement := (private.fuseau_info('Europe/Paris') ->> 'prochain_changement')::timestamptz;
  v_converti := private.convertir_classes_hors_academie();
  IF v_changement < pg_catalog.now() + interval '28 days' THEN
    IF v_converti <> 0
       OR EXISTS (SELECT 1 FROM public.groupes g WHERE g.libelle LIKE 'HL ancien client%'
                   AND g.timezone_iana <> 'Europe/Paris') THEN
      RAISE EXCEPTION 'HL ROUGE : conversion faite a moins de 28 jours d''un changement d''heure';
    END IF;
    RAISE NOTICE 'HL OK : a moins de 28 jours du changement d''heure de Paris, la conversion est refusee et rien n''est casse';
  ELSE
    IF v_converti < 2 OR EXISTS (SELECT 1 FROM public.groupes g WHERE g.libelle LIKE 'HL ancien client%'
                                  AND g.timezone_iana <> 'Asia/Riyadh') THEN
      RAISE EXCEPTION 'HL ROUGE : la tache de nuit n''a pas converti les classes de l''ancien client (% converties)', v_converti;
    END IF;
    RAISE NOTICE 'HL OK : la tache de nuit convertit les classes de l''ancien client (% converties), sans deplacer une seance', v_converti;
  END IF;
END
$e$;
RESET ROLE;

-- =====================================================================
-- (F) Les refus : une seance hors occurrence, un fuseau a demi-heure, la
--     fenetre de 28 jours : la classe n'est pas touchee
-- =====================================================================
-- Seances posees a la main : l'horizon de materialisation repasse a zero.
UPDATE public.app_config SET value = '0'::jsonb WHERE key = 'matching_horizon_weeks';

DO $f$
DECLARE
  v_classe uuid;
  v_avant text;
  v_apres text;
  v_msg text;
  v_res jsonb;
  v_ref constant timestamptz := '2026-11-12 22:00:00+00';
BEGIN
  -- Une classe sans changement d'heure (Abidjan, UTC) avec une seance a venir
  -- posee hors de son creneau : conversion refusee, rien ne bouge.
  INSERT INTO public.groupes (id, teacher_id, etat, type_public, seuil_max, libelle, weekday, hour_local,
                              timezone_iana, genre_public, created_at)
  VALUES ('d1000000-0000-4000-8000-0000000000c3', 'd1000000-0000-4000-8000-0000000000e1', 'active', 'adulte', 6,
          'HL hors occurrence', 2, 9, 'Africa/Abidjan', 'indetermine', pg_catalog.now() - interval '40 days');
  v_classe := 'd1000000-0000-4000-8000-0000000000c3';
  INSERT INTO public.sessions (teacher_id, started_at, ended_at, session_type, groupe_id, status, join_opens_at)
  VALUES ('d1000000-0000-4000-8000-0000000000e1', '2026-11-17 09:00:00+00', '2026-11-17 09:45:00+00', 'standard', v_classe, 'planned', '2026-11-17 08:40:00+00'),
         ('d1000000-0000-4000-8000-0000000000e1', '2026-11-24 09:30:00+00', '2026-11-24 10:15:00+00', 'standard', v_classe, 'planned', '2026-11-24 09:10:00+00');
  SELECT pg_catalog.md5(pg_catalog.string_agg(s.id::text || s.started_at::text, ',' ORDER BY s.id)) INTO v_avant
    FROM public.sessions s WHERE s.groupe_id = v_classe;
  v_msg := NULL;
  BEGIN
    PERFORM private.convertir_classe_vers_academie(v_classe, v_ref);
  EXCEPTION WHEN SQLSTATE 'P0001' THEN
    GET STACKED DIAGNOSTICS v_msg = MESSAGE_TEXT;
  END;
  IF v_msg IS NULL THEN
    RAISE EXCEPTION 'HL ROUGE : une classe avec une seance hors occurrence a ete convertie';
  ELSIF v_msg NOT LIKE '%ne tombent pas sur une occurrence%' THEN
    RAISE EXCEPTION 'HL ROUGE : mauvais refus : %', v_msg;
  END IF;
  SELECT pg_catalog.md5(pg_catalog.string_agg(s.id::text || s.started_at::text, ',' ORDER BY s.id)) INTO v_apres
    FROM public.sessions s WHERE s.groupe_id = v_classe;
  IF v_avant <> v_apres
     OR NOT EXISTS (SELECT 1 FROM public.groupes g WHERE g.id = v_classe AND g.timezone_iana = 'Africa/Abidjan'
                       AND g.weekday = 2 AND g.hour_local = 9)
     OR EXISTS (SELECT 1 FROM private.conversions_horloge c WHERE c.groupe_id = v_classe) THEN
    RAISE EXCEPTION 'HL ROUGE : le refus a laisse des traces (classe, seances ou journal)';
  END IF;
  RAISE NOTICE 'HL OK : une seance a venir hors occurrence : conversion refusee, classe, seances et journal intacts';

  -- Un fuseau a demi-heure (Kolkata) : 19 h a Delhi = 16 h 30 a La Mecque, sans
  -- heure pleine : refus net.
  INSERT INTO public.groupes (id, teacher_id, etat, type_public, seuil_max, libelle, weekday, hour_local,
                              timezone_iana, genre_public, created_at)
  VALUES ('d1000000-0000-4000-8000-0000000000c4', 'd1000000-0000-4000-8000-0000000000e1', 'active', 'adulte', 6,
          'HL Delhi', 1, 19, 'Asia/Kolkata', 'indetermine', pg_catalog.now() - interval '40 days');
  v_msg := NULL;
  BEGIN
    PERFORM private.convertir_classe_vers_academie('d1000000-0000-4000-8000-0000000000c4', v_ref);
  EXCEPTION WHEN SQLSTATE 'P0001' THEN
    GET STACKED DIAGNOSTICS v_msg = MESSAGE_TEXT;
  END;
  IF v_msg IS NULL THEN
    RAISE EXCEPTION 'HL ROUGE : un creneau sans heure pleine a La Mecque a ete converti';
  ELSIF v_msg NOT LIKE '%pas d''heure pleine%' THEN
    RAISE EXCEPTION 'HL ROUGE : mauvais refus pour Delhi : %', v_msg;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM public.groupes g WHERE g.id = 'd1000000-0000-4000-8000-0000000000c4'
                    AND g.timezone_iana = 'Asia/Kolkata' AND g.hour_local = 19) THEN
    RAISE EXCEPTION 'HL ROUGE : la classe de Delhi a ete touchee malgre le refus';
  END IF;
  RAISE NOTICE 'HL OK : un creneau sans heure pleine a La Mecque (Delhi) : conversion refusee, classe intacte';

  -- La fenetre de 28 jours : une classe de Paris, a 18 jours du changement
  -- d'heure du 28 mars 2027.
  INSERT INTO public.groupes (id, teacher_id, etat, type_public, seuil_max, libelle, weekday, hour_local,
                              timezone_iana, genre_public, created_at)
  VALUES ('d1000000-0000-4000-8000-0000000000c5', 'd1000000-0000-4000-8000-0000000000e2', 'active', 'adulte', 6,
          'HL fenetre', 7, 16, 'Europe/Paris', 'indetermine', pg_catalog.now() - interval '40 days');
  v_msg := NULL;
  BEGIN
    PERFORM private.convertir_classe_vers_academie('d1000000-0000-4000-8000-0000000000c5', '2027-03-10 12:00:00+00');
  EXCEPTION WHEN SQLSTATE 'P0001' THEN
    GET STACKED DIAGNOSTICS v_msg = MESSAGE_TEXT;
  END;
  IF v_msg IS NULL THEN
    RAISE EXCEPTION 'HL ROUGE : conversion acceptee a 18 jours d''un changement d''heure';
  ELSIF v_msg NOT LIKE '%a moins de 28 jours d''un changement d''heure%' THEN
    RAISE EXCEPTION 'HL ROUGE : mauvais refus pour la fenetre de 28 jours : %', v_msg;
  END IF;
  -- Et la meme classe, loin d'un changement d'heure, est convertie.
  v_res := private.convertir_classe_vers_academie('d1000000-0000-4000-8000-0000000000c5', '2026-11-12 22:00:00+00');
  IF v_res IS NULL
     OR NOT EXISTS (SELECT 1 FROM public.groupes g WHERE g.id = 'd1000000-0000-4000-8000-0000000000c5'
                       AND g.timezone_iana = 'Asia/Riyadh' AND g.weekday = 7 AND g.hour_local = 18) THEN
    RAISE EXCEPTION 'HL ROUGE : la meme classe n''est pas convertie loin d''un changement d''heure (dimanche 16 h Paris = 18 h a La Mecque) : %',
      (SELECT pg_catalog.row_to_json(g)::text FROM public.groupes g WHERE g.id = 'd1000000-0000-4000-8000-0000000000c5');
  END IF;
  RAISE NOTICE 'HL OK : a 18 jours d''un changement d''heure : conversion refusee ; loin d''un changement : convertie (dimanche 16 h Paris = 18 h a La Mecque)';
END
$f$;

-- =====================================================================
-- (G) Les minutes : un cours a 21 h a La Mecque s'affiche 23 h 30 a Delhi,
--     et 17 h 30 a Paris l'ete comme 19 h l'hiver
-- =====================================================================
DO $g$
DECLARE
  v_delhi text;
  v_paris_hiver text;
  v_paris_ete text;
  v_katmandou text;
BEGIN
  v_delhi := pg_catalog.to_char('2026-11-18 18:00:00+00'::timestamptz AT TIME ZONE 'Asia/Kolkata', 'HH24:MI');
  v_katmandou := pg_catalog.to_char('2026-11-18 18:00:00+00'::timestamptz AT TIME ZONE 'Asia/Kathmandu', 'HH24:MI');
  v_paris_hiver := pg_catalog.to_char('2026-11-18 18:00:00+00'::timestamptz AT TIME ZONE 'Europe/Paris', 'HH24:MI');
  v_paris_ete := pg_catalog.to_char('2027-04-07 18:00:00+00'::timestamptz AT TIME ZONE 'Europe/Paris', 'HH24:MI');
  IF pg_catalog.to_char('2026-11-18 18:00:00+00'::timestamptz AT TIME ZONE 'Asia/Riyadh', 'HH24:MI') <> '21:00'
     OR v_delhi <> '23:30' OR v_katmandou <> '23:45'
     OR v_paris_hiver <> '19:00' OR v_paris_ete <> '20:00' THEN
    RAISE EXCEPTION 'HL ROUGE : heures % / % / % / %', v_delhi, v_katmandou, v_paris_hiver, v_paris_ete;
  END IF;
  -- L'horloge de l'academie rend un decalage fixe de 3 h, sans changement d'heure.
  IF (private.fuseau_info(private.fuseau_academie()) ->> 'decalage_secondes')::integer <> 10800
     OR (private.fuseau_info(private.fuseau_academie()) ->> 'prochain_changement') IS NOT NULL THEN
    RAISE EXCEPTION 'HL ROUGE : l''horloge de l''academie n''est pas fixe a +3 h';
  END IF;
  RAISE NOTICE 'HL OK : 21 h a La Mecque = 23 h 30 a Delhi, 23 h 45 a Katmandou, 19 h a Paris l''hiver, 20 h l''ete ; academie fixe a +3 h';
END
$g$;

-- =====================================================================
-- (H) mon_horloge rend l'horloge de l'academie, sans toucher au reste
-- =====================================================================
SELECT set_config('request.jwt.claim.sub', 'd1000000-0000-4000-8000-000000000a01', true);
SELECT set_config('request.jwt.claims',
  '{"app_metadata":{"role":"guardian","household_id":"d1000000-0000-4000-8000-0000000000f1"}}', true);
SELECT set_config('test.uid', 'd1000000-0000-4000-8000-000000000a01', true);
SELECT set_config('test.jwt',
  '{"app_metadata":{"role":"guardian","household_id":"d1000000-0000-4000-8000-0000000000f1"}}', true);
SET LOCAL ROLE authenticated;
DO $h$
DECLARE
  v_h jsonb;
BEGIN
  v_h := public.mon_horloge();
  IF v_h -> 'academie' ->> 'fuseau' IS DISTINCT FROM 'Asia/Riyadh'
     OR (v_h -> 'academie' ->> 'decalage_secondes')::integer <> 10800
     OR v_h -> 'moi' ->> 'fuseau' IS DISTINCT FROM 'Europe/Paris'
     OR v_h ->> 'maintenant' IS NULL THEN
    RAISE EXCEPTION 'HL ROUGE : mon_horloge : %', v_h;
  END IF;
  RAISE NOTICE 'HL OK : mon_horloge rend moi (Paris), maintenant et academie (Asia/Riyadh, +3 h)';
END
$h$;
RESET ROLE;

-- =====================================================================
-- (I) Droits et propriete
-- =====================================================================
DO $i$
DECLARE
  v_f text;
  v_r text;
BEGIN
  FOREACH v_f IN ARRAY ARRAY[
    'private.fuseau_academie()',
    'private.convertir_classe_vers_academie(uuid,timestamp with time zone)',
    'private.convertir_classes_hors_academie(timestamp with time zone)',
    'private.conversion_horloge_groupe(uuid,integer,integer,text,integer,integer,text)',
    'private.conversion_horloge_creneau(uuid,integer,integer,integer,integer)']
  LOOP
    FOREACH v_r IN ARRAY ARRAY['anon', 'authenticated', 'service_role', 'agent_ro'] LOOP
      IF pg_catalog.has_function_privilege(v_r, v_f::pg_catalog.regprocedure, 'EXECUTE') THEN
        RAISE EXCEPTION 'HL ROUGE : % peut executer %', v_r, v_f;
      END IF;
    END LOOP;
    IF NOT (SELECT p.prosecdef AND p.proconfig @> ARRAY['search_path=""']
              FROM pg_catalog.pg_proc p WHERE p.oid = v_f::pg_catalog.regprocedure) THEN
      RAISE EXCEPTION 'HL ROUGE : % n''est pas DEFINER a search_path vide', v_f;
    END IF;
  END LOOP;
  IF NOT (SELECT c.relrowsecurity FROM pg_catalog.pg_class c WHERE c.oid = 'private.conversions_horloge'::pg_catalog.regclass) THEN
    RAISE EXCEPTION 'HL ROUGE : RLS absente du journal';
  END IF;
  RAISE NOTICE 'HL OK : aucun EXECUTE client, DEFINER a search_path vide, RLS sur le journal';
END
$i$;

ROLLBACK;
