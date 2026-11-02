-- NOTIFS-L6 (pilote, 02/11/2026 ; migration 20261104500000) : la section
-- « A faire » des notifications.
--
-- Ce que le scenario prouve :
--   1. geste_requis est pose par le serveur a l'insertion, selon l'evenement,
--      quoi que l'auteur de l'insertion ait voulu ecrire ; un litige_ouvert ne
--      l'est que pour la direction ;
--   2. « geste fait » : paiement_recu clot les relances du meme destinataire
--      (pas d'un autre) ; remplacement_pris clot les propositions de la meme
--      seance pour tous (pas d'une autre seance) ; litige_clos clot le litige
--      de la meme commande (pas d'une autre) ;
--   3. « Ecarter » : le destinataire seul, a l'heure du serveur, sans retour ;
--      geste_requis et geste_fait_le restent hors de sa portee.
--
-- Base PostgreSQL jetable apres stub_auth.sql et toutes les migrations. Tout
-- est annule a la fin.
BEGIN;

CREATE FUNCTION pg_temp.vrai(p_condition boolean, p_label text) RETURNS void
LANGUAGE plpgsql AS $$
BEGIN
  IF p_condition IS NOT TRUE THEN
    RAISE EXCEPTION 'NOTIFS-L6 ROUGE : %', p_label;
  END IF;
  RAISE NOTICE 'OK %', p_label;
END $$;

CREATE FUNCTION pg_temp.id(p text) RETURNS uuid
LANGUAGE sql IMMUTABLE AS $$
  SELECT pg_catalog.md5('notifs-l6-' || p)::uuid
$$;

CREATE FUNCTION pg_temp.qui(p_id uuid, p_role text) RETURNS void
LANGUAGE plpgsql AS $$
DECLARE v_jwt text;
BEGIN
  v_jwt := pg_catalog.json_build_object('aal', 'aal1', 'app_metadata',
             pg_catalog.json_build_object('role', p_role))::text;
  PERFORM pg_catalog.set_config('request.jwt.claim.sub', p_id::text, true);
  PERFORM pg_catalog.set_config('request.jwt.claims', v_jwt, true);
END $$;

CREATE FUNCTION pg_temp.notifier(p_qui text, p_evenement text, p_params jsonb,
                                 p_destination text)
RETURNS uuid LANGUAGE sql AS $$
  INSERT INTO public.notifications (destinataire, evenement, params, destination)
  VALUES (pg_temp.id(p_qui), p_evenement, p_params, p_destination)
  RETURNING id
$$;

CREATE FUNCTION pg_temp.etat(p_id uuid) RETURNS text
LANGUAGE sql AS $$
  SELECT CASE
           WHEN NOT n.geste_requis THEN 'information'
           WHEN n.ecartee_le IS NOT NULL THEN 'ecartee'
           WHEN n.geste_fait_le IS NOT NULL THEN 'faite'
           ELSE 'a_faire' END
    FROM public.notifications n WHERE n.id = p_id
$$;

-- Fixtures : une famille (deux tuteurs), deux enseignants, la direction.
INSERT INTO auth.users (id, email)
SELECT pg_temp.id(x), 'notifs-l6-' || x || '@test.invalid'
  FROM unnest(ARRAY['t1', 't2', 'p1', 'p2', 'a1']) AS x;
INSERT INTO public.households (id, timezone)
SELECT pg_temp.id(x), 'Europe/Paris' FROM unnest(ARRAY['f1', 'f2']) AS x;
INSERT INTO public.profiles (id, immutable_id, role, household_id, first_name,
                             last_name, account_status, gender)
SELECT pg_temp.id(x.id), x.mat, x.role::public.app_role,
       CASE WHEN x.foyer IS NULL THEN NULL ELSE pg_temp.id(x.foyer) END,
       x.prenom, 'L6',
       -- Un enseignant actif exige ses contrats signes ; les declencheurs des
       -- notifications ne regardent pas le statut du destinataire.
       (CASE WHEN x.role = 'teacher' THEN 'pending_kyc' ELSE 'active' END)::public.account_status,
       x.genre::public.gender
  FROM (VALUES
    ('t1', 'L6-TUT-0001', 'guardian', 'f1', 'Amina', 'female'),
    ('t2', 'L6-TUT-0002', 'guardian', 'f2', 'Karim', 'male'),
    ('p1', 'L6-ENS-0001', 'teacher', NULL, 'Maryam', 'female'),
    ('p2', 'L6-ENS-0002', 'teacher', NULL, 'Salma', 'female'),
    ('a1', 'L6-ADM-0001', 'admin', NULL, 'Direction', 'female'))
    AS x(id, mat, role, foyer, prenom, genre);

-- 1. geste_requis pose par le serveur.
DO $$
DECLARE v_relance uuid; v_info uuid; v_force uuid; v_lit_famille uuid; v_lit_dir uuid;
BEGIN
  v_relance := pg_temp.notifier('t1', 'paiement_relance', '{}'::jsonb, '/tuteur/foyer/recharge');
  v_info := pg_temp.notifier('t1', 'paiement_recu', '{}'::jsonb, '/tuteur/foyer/recharge');
  PERFORM pg_temp.vrai(pg_temp.etat(v_info) = 'information',
    'un paiement recu ne demande aucun geste');
  -- Meme si l'insertion pretend le contraire : le serveur decide.
  INSERT INTO public.notifications (destinataire, evenement, params, destination,
                                    geste_requis, geste_fait_le, ecartee_le)
  VALUES (pg_temp.id('t2'), 'classe_creee', '{}'::jsonb, '/tuteur', true,
          pg_catalog.now(), pg_catalog.now())
  RETURNING id INTO v_force;
  PERFORM pg_temp.vrai(pg_temp.etat(v_force) = 'information',
    'geste_requis, geste_fait_le et ecartee_le ne viennent jamais de l insertion');
  v_lit_famille := pg_temp.notifier('t2', 'litige_ouvert',
    '{"portee": "foyer", "commande_id": "c1"}'::jsonb, '/tuteur/foyer/recharge');
  v_lit_dir := pg_temp.notifier('a1', 'litige_ouvert',
    '{"portee": "direction", "commande_id": "c1"}'::jsonb, '/admin/finance');
  PERFORM pg_temp.vrai(pg_temp.etat(v_lit_famille) = 'information',
    'la famille est informee d une contestation, sans geste');
  PERFORM pg_temp.vrai(pg_temp.etat(v_lit_dir) = 'a_faire',
    'la direction doit traiter la contestation');
END $$;

-- 2. « Geste fait ».
DO $$
DECLARE
  v_r1 uuid; v_r2 uuid; v_s1 uuid; v_autre uuid;
  v_p1 uuid; v_p2 uuid; v_p_autre uuid;
  v_l1 uuid; v_l2 uuid;
BEGIN
  -- Paiement : le meme destinataire seulement.
  v_r1 := pg_temp.notifier('t1', 'paiement_relance', '{}'::jsonb, '/tuteur/foyer/recharge');
  v_s1 := pg_temp.notifier('t1', 'acces_suspendu_paiement', '{}'::jsonb, '/tuteur/foyer/recharge');
  v_autre := pg_temp.notifier('t2', 'paiement_relance', '{}'::jsonb, '/tuteur/foyer/recharge');
  PERFORM pg_temp.notifier('t1', 'acces_retabli_paiement', '{}'::jsonb, '/tuteur/foyer/recharge');
  PERFORM pg_temp.vrai(pg_temp.etat(v_r1) = 'faite' AND pg_temp.etat(v_s1) = 'faite',
    'le paiement recu clot la relance et la suspension du destinataire');
  PERFORM pg_temp.vrai(pg_temp.etat(v_autre) = 'a_faire',
    'la relance d un autre destinataire reste a faire');

  -- Remplacement : la meme seance, pour tous les enseignants.
  v_p1 := pg_temp.notifier('p1', 'remplacement_propose', '{"session_id": "s1"}'::jsonb,
    '/enseignant/journee/remplacements');
  v_p2 := pg_temp.notifier('p2', 'remplacement_pre_alerte', '{"session_id": "s1"}'::jsonb,
    '/enseignant/journee/remplacements');
  v_p_autre := pg_temp.notifier('p2', 'remplacement_propose', '{"session_id": "s2"}'::jsonb,
    '/enseignant/journee/remplacements');
  PERFORM pg_temp.notifier('p1', 'remplacement_pris', '{"session_id": "s1"}'::jsonb,
    '/enseignant/journee/remplacements');
  PERFORM pg_temp.vrai(pg_temp.etat(v_p1) = 'faite' AND pg_temp.etat(v_p2) = 'faite',
    'remplacement_pris clot les propositions de la seance, pour tous');
  PERFORM pg_temp.vrai(pg_temp.etat(v_p_autre) = 'a_faire',
    'une autre seance reste a faire');

  -- Contestation : la meme commande.
  v_l1 := pg_temp.notifier('a1', 'litige_ouvert',
    '{"portee": "direction", "commande_id": "c2"}'::jsonb, '/admin/finance');
  v_l2 := pg_temp.notifier('a1', 'litige_ouvert',
    '{"portee": "direction", "commande_id": "c3"}'::jsonb, '/admin/finance');
  PERFORM pg_temp.notifier('a1', 'litige_clos',
    '{"portee": "direction", "commande_id": "c2", "issue": "gagne"}'::jsonb, '/admin/finance');
  PERFORM pg_temp.vrai(pg_temp.etat(v_l1) = 'faite',
    'litige_clos clot le litige de la meme commande');
  PERFORM pg_temp.vrai(pg_temp.etat(v_l2) = 'a_faire',
    'le litige d une autre commande reste a faire');
END $$;

-- 3. « Ecarter » : le destinataire seul, heure du serveur, sans retour.
SELECT set_config('test.ecart', pg_temp.notifier('t2', 'paiement_relance', '{}'::jsonb,
  '/tuteur/foyer/recharge')::text, true);
SELECT set_config('test.ecart_t1', pg_temp.notifier('t1', 'paiement_relance', '{}'::jsonb,
  '/tuteur/foyer/recharge')::text, true);

SELECT pg_temp.qui(pg_temp.id('t2'), 'guardian');
SET LOCAL ROLE authenticated;
-- Une heure fausse envoyee par l'application est remplacee par celle du serveur.
UPDATE public.notifications SET ecartee_le = '2000-01-01T00:00:00Z'
 WHERE id = current_setting('test.ecart')::uuid;
-- La notification d'un autre destinataire est invisible : rien ne change.
UPDATE public.notifications SET ecartee_le = pg_catalog.now()
 WHERE id = current_setting('test.ecart_t1')::uuid;
RESET ROLE;

DO $$
DECLARE v_le timestamptz;
BEGIN
  SELECT ecartee_le INTO v_le FROM public.notifications
   WHERE id = current_setting('test.ecart')::uuid;
  PERFORM pg_temp.vrai(v_le IS NOT NULL AND v_le > '2001-01-01'::timestamptz,
    'ecarter pose l heure du serveur');
  PERFORM pg_temp.vrai(pg_temp.etat(current_setting('test.ecart_t1')::uuid) = 'a_faire',
    'un autre destinataire ne peut pas ecarter');
END $$;

SELECT pg_temp.qui(pg_temp.id('t2'), 'guardian');
SET LOCAL ROLE authenticated;
-- Revenir en arriere est sans effet.
UPDATE public.notifications SET ecartee_le = NULL
 WHERE id = current_setting('test.ecart')::uuid;
RESET ROLE;
DO $$
BEGIN
  PERFORM pg_temp.vrai(pg_temp.etat(current_setting('test.ecart')::uuid) = 'ecartee',
    'une notification ecartee le reste');
END $$;

-- geste_requis et geste_fait_le : jamais modifiables par le destinataire.
DO $$
BEGIN
  PERFORM pg_temp.vrai(
    NOT pg_catalog.has_column_privilege('authenticated', 'public.notifications',
                                        'geste_requis', 'UPDATE')
    AND NOT pg_catalog.has_column_privilege('authenticated', 'public.notifications',
                                            'geste_fait_le', 'UPDATE')
    AND pg_catalog.has_column_privilege('authenticated', 'public.notifications',
                                        'ecartee_le', 'UPDATE'),
    'seule ecartee_le (et lu_le) est ouverte au destinataire');
END $$;

ROLLBACK;
