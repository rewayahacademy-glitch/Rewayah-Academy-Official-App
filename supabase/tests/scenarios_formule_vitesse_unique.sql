-- FORMULE-VITESSE-UNIQUE (08/11/2026) : private.vitesse_eleve est la seule regle de
-- vitesse, appelee par suivi_pedagogique_eleve et rythme_classe. Aucun changement de
-- comportement : la fonction rend, sur une grille de frontieres (a la microseconde),
-- exactement ce que rendait l'ancienne formule ecrite en ligne (recopiee ci-dessous).
-- ROUGE sans la migration (la fonction n'existe pas) ; VERT avec. Tout est annule.
-- Les deux lectures publiques sont eprouvees par scenarios_suivi_eleve_pedagogique.sql et
-- scenarios_rythme_lecture.sql, a rejouer apres cette migration.
BEGIN;
CREATE FUNCTION pg_temp.vrai(p_condition boolean, p_label text) RETURNS void
LANGUAGE plpgsql AS $$
BEGIN
  IF p_condition IS NOT TRUE THEN RAISE EXCEPTION 'FORMULE-VITESSE ROUGE : %', p_label; END IF;
  RAISE NOTICE 'OK %', p_label;
END $$;

-- L'ancienne formule, recopiee telle qu'elle etait dans les deux fonctions.
CREATE FUNCTION pg_temp.ancienne(p_depuis timestamptz, p_duree int, p_limite date, p_now timestamptz)
RETURNS text LANGUAGE sql AS $$
  SELECT CASE
           WHEN p_depuis IS NULL OR p_duree IS NULL THEN 'inconnu'
           WHEN p_now <= p_depuis + pg_catalog.make_interval(weeks => p_duree) THEN 'dans_les_temps'
           WHEN p_limite IS NULL OR p_now::date <= p_limite THEN 'au_dela_du_prevu'
           ELSE 'date_limite_depassee'
         END $$;

-- Grille : depuis (null ou fixe) x duree (null, 0, 14) x limite (null, avant/pendant/apres)
-- x maintenant (frontieres de la duree : -1 us, pile, +1 us ; frontieres de la date limite).
CREATE TEMP TABLE grille AS
WITH d AS (SELECT * FROM (VALUES (NULL::timestamptz), ('2026-06-01 10:00:00+00'::timestamptz)) x(depuis)),
     u AS (SELECT * FROM (VALUES (NULL::int), (0), (14)) x(duree)),
     l AS (SELECT * FROM (VALUES (NULL::date), ('2026-08-31'::date), ('2026-09-07'::date), ('2026-09-08'::date)) x(limite)),
     n AS (
       SELECT '2026-06-01 10:00:00+00'::timestamptz + b.delta AS maintenant
         FROM (VALUES (interval '-1 microsecond'), (interval '0'), (interval '1 microsecond'),
                      (interval '14 weeks -1 microsecond'), (interval '14 weeks'), (interval '14 weeks 1 microsecond'),
                      (interval '13 weeks 6 days 23 hours 59 minutes 59 seconds'),
                      (interval '3 months 6 days 23 hours 59 minutes 59.999999 seconds'),
                      (interval '3 months 7 days'), (interval '3 months 7 days 1 microsecond'),
                      (interval '3 months 8 days'), (interval '3 months 8 days 1 microsecond'),
                      (interval '1 year')) b(delta)
     )
SELECT d.depuis, u.duree, l.limite, n.maintenant FROM d, u, l, n;

SELECT pg_temp.vrai((SELECT count(*) FROM grille) = 2 * 3 * 4 * 13, 'grille : 312 cas');
SELECT pg_temp.vrai(
  NOT EXISTS (SELECT 1 FROM grille g
               WHERE private.vitesse_eleve(g.depuis, g.duree, g.limite, g.maintenant)
                     IS DISTINCT FROM pg_temp.ancienne(g.depuis, g.duree, g.limite, g.maintenant)),
  'la nouvelle fonction rend, sur les 312 cas, exactement ce que rendait l''ancienne formule');
SELECT pg_temp.vrai(
  (SELECT count(DISTINCT private.vitesse_eleve(g.depuis, g.duree, g.limite, g.maintenant)) FROM grille g) = 4,
  'la grille atteint les quatre etats (aucun cas mort)');
SELECT pg_temp.vrai(
  private.vitesse_eleve('2026-06-01 10:00:00+00', 14, '2026-09-07', '2026-09-07 23:59:59.999999+00') = 'au_dela_du_prevu'
  AND private.vitesse_eleve('2026-06-01 10:00:00+00', 14, '2026-09-07', '2026-09-08 00:00:00+00') = 'date_limite_depassee',
  'frontiere de la date limite : le dernier jour compte, le lendemain non');
-- Droits : personne ne l'appelle directement.
SELECT pg_temp.vrai(
  NOT pg_catalog.has_function_privilege('authenticated', 'private.vitesse_eleve(timestamptz, integer, date, timestamptz)', 'EXECUTE')
  AND NOT pg_catalog.has_function_privilege('anon', 'private.vitesse_eleve(timestamptz, integer, date, timestamptz)', 'EXECUTE')
  AND NOT pg_catalog.has_function_privilege('agent_ro', 'private.vitesse_eleve(timestamptz, integer, date, timestamptz)', 'EXECUTE'),
  'private.vitesse_eleve : aucun droit direct');
-- Les deux fonctions publiques appellent la source unique et gardent leurs droits.
SELECT pg_temp.vrai(
  pg_catalog.strpos(pg_catalog.pg_get_functiondef('public.suivi_pedagogique_eleve(uuid)'::pg_catalog.regprocedure), 'private.vitesse_eleve') > 0
  AND pg_catalog.strpos(pg_catalog.pg_get_functiondef('public.rythme_classe(uuid)'::pg_catalog.regprocedure), 'private.vitesse_eleve') > 0
  AND pg_catalog.strpos(pg_catalog.pg_get_functiondef('public.suivi_pedagogique_eleve(uuid)'::pg_catalog.regprocedure), 'date_limite_depassee') = 0
  AND pg_catalog.strpos(pg_catalog.pg_get_functiondef('public.rythme_classe(uuid)'::pg_catalog.regprocedure), 'date_limite_depassee') = 0,
  'les deux lectures appellent la source unique, plus aucune formule en ligne');
ROLLBACK;
