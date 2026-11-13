-- PRIERE-1 (12/11/2026) : la priere a l'heure, calculee par le serveur.
-- Decision : docs/current/pedagogie/PRIERE.md (P1 a P11, arbitrage de l'architecte
-- pedagogique, sur delegation du directeur). Numero de migration reserve.
--
-- Ce fichier ne contient AUCUN des trois mots que le serveur Supabase fait
-- confirmer une seconde fois (effacement de ligne, suppression d'objet, vidage de
-- table) : il s'installe tel quel. Les lignes devenues inutiles ne sont jamais
-- retirees : elles sont marquees `retiree_le` et la vue du contrat les cache.
--
-- Contenu, dans l'ordre :
--   1. le contrat avec la salle : stock, vue `seance_pause_prevue`, lecture
--      `pause_prevue_seance(uuid)` ;
--   2. le calcul des cinq prieres en SQL pur (port de `adhan`, prouve par
--      comparaison) ;
--   3. les reglages de l'academie (`app_config`, cles `priere.*`) ;
--   4. le lieu et les reglages d'un enseignant (`prayer_settings`) ;
--   5. le placement de la pause ; 6. le remplissage (declencheurs, recalcul de nuit) ;
--   7. le lieu, les ajustements, l'apercu du jour ; 8. les lectures de la direction
--      (croisements sur 12 mois, heures sans priere, vendredi, incoherences) ;
--   9. les droits ; 10. le controle final.
--
-- Sans BEGIN ni COMMIT de premier niveau.

-- ===========================================================================
-- 1. Le contrat avec la salle
-- ===========================================================================

-- Le stock : une ligne par seance calculee. `retiree_le` non nul = aucune pause
-- de prière pour cette seance (aucune priere n'entre, pas de lieu, calcul
-- indefini...). Pas de cle etrangere : des operations et des tests retirent des
-- seances pour de bon, et la vue ne montre que les seances qui existent encore.
CREATE TABLE public.seance_pause_prevue_stock (
  session_id uuid PRIMARY KEY,
  debut_prevu_utc timestamptz,
  -- 5, 10, 15 ou 20 : le contrat de la salle ignore toute autre duree.
  duree_minutes integer CHECK (duree_minutes BETWEEN 5 AND 20 AND duree_minutes % 5 = 0),
  motif text CHECK (motif = 'priere'),
  priere text CHECK (priere IN ('fajr', 'dhuhr', 'asr', 'maghrib', 'isha')),
  calcule_le timestamptz NOT NULL DEFAULT pg_catalog.now(),
  retiree_le timestamptz,
  indefini boolean NOT NULL DEFAULT false,
  CONSTRAINT seance_pause_prevue_stock_complete CHECK (
    retiree_le IS NOT NULL
    OR (debut_prevu_utc IS NOT NULL AND duree_minutes IS NOT NULL
        AND motif IS NOT NULL AND priere IS NOT NULL)
  )
);

COMMENT ON TABLE public.seance_pause_prevue_stock IS
  'PRIERE-1 : stockage de la pause de priere prevue par seance. Rempli par le serveur seulement (private.priere_recalculer_seance). Jamais lu directement : la vue seance_pause_prevue (contrat avec la salle) et pause_prevue_seance() le montrent.';

ALTER TABLE public.seance_pause_prevue_stock ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON public.seance_pause_prevue_stock FROM PUBLIC, anon, authenticated, service_role;
-- Proprietaire : postgres (le role qui joue les migrations). RLS active, sans
-- aucune politique et sans FORCE : seul le proprietaire lit ou ecrit le stock,
-- et il le fait par les fonctions SECURITY DEFINER de ce fichier.
ALTER TABLE public.seance_pause_prevue_stock OWNER TO postgres;

-- Le contrat, tel que la salle le lit : une ligne quand une priere entre
-- pendant la seance, aucune sinon. Aucun droit direct.
CREATE VIEW public.seance_pause_prevue AS
  SELECT p.session_id,
         p.debut_prevu_utc,
         p.duree_minutes,
         p.motif,
         p.priere,
         p.calcule_le
    FROM public.seance_pause_prevue_stock p
    JOIN public.sessions s ON s.id = p.session_id AND s.deleted_at IS NULL
   WHERE p.retiree_le IS NULL;

COMMENT ON VIEW public.seance_pause_prevue IS
  'PRIERE-1, contrat avec la salle : la pause de priere prevue d''une seance. Aucune ligne quand aucune priere n''entre pendant la seance. Remplie par le serveur ; aucun droit direct ; lecture client par pause_prevue_seance(uuid).';

REVOKE ALL ON public.seance_pause_prevue FROM PUBLIC, anon, authenticated, service_role;
-- La vue appartient a postgres et n'est PAS `security_invoker` : elle lit le stock
-- avec les droits de son proprietaire. Cela n'ouvre aucune porte derobee autour
-- de la RLS du stock parce qu'aucun role de l'application (PUBLIC, anon,
-- authenticated, service_role, agent_ro) n'a de droit sur la vue ni sur le
-- stock : le controle final de ce fichier et le scenario (has_table_privilege,
-- liste des droits) le prouvent. Seules des fonctions SECURITY DEFINER
-- proprietaires de postgres la traversent : pause_prevue_seance, qui decide QUI
-- lit, et le declencheur de la salle, qui ne sert que le demarrage d'une seance.
ALTER VIEW public.seance_pause_prevue OWNER TO postgres;
ALTER VIEW public.seance_pause_prevue SET (security_invoker = false);
DO $acl$
BEGIN
  IF EXISTS (SELECT 1 FROM pg_catalog.pg_roles WHERE rolname = 'agent_ro') THEN
    EXECUTE 'REVOKE ALL ON public.seance_pause_prevue FROM agent_ro';
    EXECUTE 'REVOKE ALL ON public.seance_pause_prevue_stock FROM agent_ro';
  END IF;
END
$acl$;

-- Lecture : la direction, l'enseignant qui enseigne reellement (titulaire, ou
-- remplacant accepte), les eleves de la classe et leur foyer. Jamais un lieu :
-- la fonction ne rend que l'heure, la duree, le motif et le nom de la priere.
CREATE FUNCTION public.pause_prevue_seance(p_session_id uuid)
RETURNS TABLE (
  debut_prevu_utc timestamptz,
  duree_minutes integer,
  motif text,
  priere text
)
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  v_uid uuid := auth.uid();
  v_role public.app_role := public.app_role();
  v_menage uuid := public.app_household_id();
  v_groupe uuid;
  v_autorise boolean := false;
BEGIN
  IF NOT coalesce(public.app_account_valid(), false) OR v_uid IS NULL THEN
    RAISE EXCEPTION 'pause prevue : acces refuse' USING ERRCODE = '42501';
  END IF;

  SELECT s.groupe_id INTO v_groupe
    FROM public.sessions s
   WHERE s.id = p_session_id AND s.deleted_at IS NULL;

  IF FOUND THEN
    IF v_role = 'admin' THEN
      v_autorise := true;
    ELSIF v_role = 'teacher' THEN
      v_autorise := coalesce(
        private.c29_enseignant_effectif_session(p_session_id) = v_uid, false);
      -- Le titulaire d'une seance remplacee la voit toujours dans sa liste : zero ligne, pas
      -- d'erreur (il ne lit pas la pause de celui qui enseigne a sa place).
      IF NOT v_autorise AND EXISTS (SELECT 1 FROM public.sessions t
                                     WHERE t.id = p_session_id AND t.teacher_id = v_uid) THEN
        RETURN;
      END IF;
    ELSIF v_role IN ('student', 'guardian') THEN
      v_autorise := coalesce(
        EXISTS (
          SELECT 1
            FROM public.session_participants sp
            JOIN public.profiles pr ON pr.id = sp.profile_id
           WHERE sp.session_id = p_session_id
             AND sp.role = 'student'
             AND sp.deleted_at IS NULL
             AND pr.deleted_at IS NULL
             AND (pr.id = v_uid
                  OR (v_role = 'guardian' AND v_menage IS NOT NULL
                      AND pr.household_id = v_menage)))
        OR (v_groupe IS NOT NULL AND EXISTS (
          SELECT 1
            FROM public.groupe_membres gm
            JOIN public.profiles pr ON pr.id = gm.student_id
           WHERE gm.groupe_id = v_groupe
             AND gm.left_at IS NULL
             AND pr.deleted_at IS NULL
             AND (pr.id = v_uid
                  OR (v_role = 'guardian' AND v_menage IS NOT NULL
                      AND pr.household_id = v_menage)))),
        false);
    END IF;
  END IF;

  -- Exigence positive : tout ce qui n'est pas explicitement autorise est refuse
  -- (seance inconnue, role etranger, eleve d'une autre classe). Le refus est
  -- le meme dans tous les cas : aucun oracle sur l'existence d'une seance.
  IF NOT v_autorise THEN
    RAISE EXCEPTION 'pause prevue : acces refuse' USING ERRCODE = '42501';
  END IF;

  RETURN QUERY
    SELECT v.debut_prevu_utc, v.duree_minutes, v.motif, v.priere
      FROM public.seance_pause_prevue v
     WHERE v.session_id = p_session_id;
END;
$function$;

ALTER FUNCTION public.pause_prevue_seance(uuid) OWNER TO postgres;
REVOKE ALL ON FUNCTION public.pause_prevue_seance(uuid)
  FROM PUBLIC, anon, service_role, agent_ro;
GRANT EXECUTE ON FUNCTION public.pause_prevue_seance(uuid) TO authenticated;

COMMENT ON FUNCTION public.pause_prevue_seance(uuid) IS
  'PRIERE-1, contrat avec la salle : heure, duree, motif et priere de la pause prevue, sans aucun lieu. Direction, enseignant de la seance (titulaire ou remplacant accepte), eleves de la classe et leur foyer ; refus pour tout autre. Aucune ligne quand aucune priere n''entre pendant la seance.';

-- ===========================================================================
-- 2. Le calcul des cinq prieres, en SQL pur
-- ===========================================================================
-- Port de l'algorithme du paquet Dart `adhan` 2.0.0+1 (celui que l'application
-- employait), avec ses conventions : Meeus pour le soleil, interpolation sur trois
-- jours, repli de haute latitude « nuit partagee en deux », arrondi a la minute,
-- ajustements de methode. La preuve est la comparaison avec `adhan` sur une
-- matrice de lieux, de dates, de methodes et d'ecoles d'Asr
-- (supabase/tests/scenarios_priere_serveur.sql, ecart maximal admis : 2 minutes).
--
-- Une valeur impossible a calculer (le soleil ne se leve ni ne se couche) vaut
-- NULL, comme le NaN du paquet de reference : le calcul rend alors zero ligne.
-- Fonctions du schema private : aucun client n'y a acces.

CREATE FUNCTION private.priere_borne(p_valeur double precision, p_max double precision)
RETURNS double precision
LANGUAGE sql IMMUTABLE PARALLEL SAFE SET search_path = ''
AS $$ SELECT p_valeur - p_max * pg_catalog.floor(p_valeur / p_max) $$;

-- Arrondi « moitie vers l'exterieur » du paquet Dart (roundToDouble), pas celui de
-- Postgres (moitie vers le pair).
CREATE FUNCTION private.priere_arrondi(p_valeur double precision)
RETURNS double precision
LANGUAGE sql IMMUTABLE PARALLEL SAFE SET search_path = ''
AS $$ SELECT pg_catalog.sign(p_valeur) * pg_catalog.floor(pg_catalog.abs(p_valeur) + 0.5) $$;

CREATE FUNCTION private.priere_angle_proche(p_angle double precision)
RETURNS double precision
LANGUAGE sql IMMUTABLE PARALLEL SAFE SET search_path = ''
AS $$
  SELECT CASE WHEN p_angle >= -180 AND p_angle <= 180 THEN p_angle
              ELSE p_angle - 360 * private.priere_arrondi(p_angle / 360) END
$$;

CREATE FUNCTION private.priere_interpoler(
  p_y2 double precision, p_y1 double precision, p_y3 double precision, p_n double precision)
RETURNS double precision
LANGUAGE sql IMMUTABLE PARALLEL SAFE SET search_path = ''
AS $$
  SELECT p_y2 + ((p_n / 2) * ((p_y2 - p_y1) + (p_y3 - p_y2)
         + (p_n * ((p_y3 - p_y2) - (p_y2 - p_y1)))))
$$;

CREATE FUNCTION private.priere_interpoler_angles(
  p_y2 double precision, p_y1 double precision, p_y3 double precision, p_n double precision)
RETURNS double precision
LANGUAGE sql IMMUTABLE PARALLEL SAFE SET search_path = ''
AS $$
  SELECT p_y2 + ((p_n / 2) * (
    private.priere_borne(p_y2 - p_y1, 360) + private.priere_borne(p_y3 - p_y2, 360)
    + (p_n * (private.priere_borne(p_y3 - p_y2, 360) - private.priere_borne(p_y2 - p_y1, 360)))))
$$;

-- Jour julien a 0 h UTC d'une date civile (Meeus, p. 60), troncatures du paquet.
CREATE FUNCTION private.priere_jour_julien(p_date date)
RETURNS double precision
LANGUAGE sql IMMUTABLE PARALLEL SAFE SET search_path = ''
AS $$
  WITH c AS (
    SELECT pg_catalog.date_part('year', p_date)::int AS a,
           pg_catalog.date_part('month', p_date)::int AS m,
           pg_catalog.date_part('day', p_date)::int AS j
  ), d AS (
    SELECT CASE WHEN m > 2 THEN a ELSE a - 1 END AS yy,
           CASE WHEN m > 2 THEN m ELSE m + 12 END AS mm,
           j
      FROM c
  )
  SELECT pg_catalog.trunc(365.25 * (yy + 4716))
         + pg_catalog.trunc(30.6001 * (mm + 1))
         + j
         + pg_catalog.trunc(2 - (yy / 100) + ((yy / 100)::double precision / 4))
         - 1524.5
    FROM d
$$;

-- Declinaison, ascension droite et temps sideral apparent du soleil (degres).
CREATE FUNCTION private.priere_soleil(p_jd double precision)
RETURNS TABLE (declinaison double precision, ascension double precision, sideral double precision)
LANGUAGE plpgsql IMMUTABLE PARALLEL SAFE SET search_path = ''
AS $function$
DECLARE
  t double precision := (p_jd - 2451545.0) / 36525;
  l0 double precision;
  lp double precision;
  om double precision;
  m double precision;
  centre double precision;
  lambda double precision;
  theta0 double precision;
  d_psi double precision;
  d_eps double precision;
  eps0 double precision;
  eps_app double precision;
BEGIN
  l0 := private.priere_borne(280.4664567 + 36000.76983 * t + 0.0003032 * t * t, 360);
  lp := private.priere_borne(218.3165 + 481267.8813 * t, 360);
  om := private.priere_borne(125.04452 - 1934.136261 * t + 0.0020708 * t * t + (t * t * t) / 450000, 360);
  m := private.priere_borne(357.52911 + 35999.05029 * t - 0.0001537 * t * t, 360);
  centre := (1.914602 - 0.004817 * t - 0.000014 * t * t) * sin(radians(m))
          + (0.019993 - 0.000101 * t) * sin(2 * radians(m))
          + 0.000289 * sin(3 * radians(m));
  lambda := radians(private.priere_borne(
    l0 + centre - 0.00569 - 0.00478 * sin(radians(125.04 - 1934.136 * t)), 360));
  theta0 := private.priere_borne(
    280.46061837 + 360.98564736629 * ((t * 36525 + 2451545.0) - 2451545)
    + 0.000387933 * t * t - (t * t * t) / 38710000, 360);
  d_psi := (-17.2 / 3600) * sin(radians(om)) - (1.32 / 3600) * sin(2 * radians(l0))
         - (0.23 / 3600) * sin(2 * radians(lp)) + (0.21 / 3600) * sin(2 * radians(om));
  d_eps := (9.2 / 3600) * cos(radians(om)) + (0.57 / 3600) * cos(2 * radians(l0))
         + (0.10 / 3600) * cos(2 * radians(lp)) - (0.09 / 3600) * cos(2 * radians(om));
  eps0 := 23.439291 - 0.013004167 * t - 0.0000001639 * t * t + 0.0000005036 * t * t * t;
  eps_app := radians(eps0 + 0.00256 * cos(radians(125.04 - 1934.136 * t)));

  declinaison := degrees(asin(sin(eps_app) * sin(lambda)));
  ascension := private.priere_borne(degrees(atan2(cos(eps_app) * sin(lambda), cos(lambda))), 360);
  sideral := theta0 + (((d_psi * 3600) * cos(radians(eps0 + d_eps))) / 3600);
  RETURN NEXT;
END;
$function$;

-- Angle horaire corrige (Meeus, p. 102), en heures UT ; NULL quand le soleil
-- n'atteint pas l'angle demande (NaN du paquet de reference).
CREATE FUNCTION private.priere_angle_horaire(
  p_m0 double precision, p_h0 double precision, p_lat double precision, p_lon double precision,
  p_apres boolean, p_theta0 double precision,
  p_a2 double precision, p_a1 double precision, p_a3 double precision,
  p_d2 double precision, p_d1 double precision, p_d3 double precision)
RETURNS double precision
LANGUAGE plpgsql IMMUTABLE PARALLEL SAFE SET search_path = ''
AS $function$
DECLARE
  lw double precision := -p_lon;
  t1 double precision;
  t2 double precision;
  x double precision;
  h0r double precision;
  m double precision;
  theta double precision;
  alpha double precision;
  delta double precision;
  hh double precision;
  sinus double precision;
  haut double precision;
  t4 double precision;
BEGIN
  t1 := sin(radians(p_h0)) - (sin(radians(p_lat)) * sin(radians(p_d2)));
  t2 := cos(radians(p_lat)) * cos(radians(p_d2));
  IF t2 = 0 THEN RETURN NULL; END IF;
  x := t1 / t2;
  IF x > 1 OR x < -1 THEN RETURN NULL; END IF;
  h0r := degrees(acos(x));
  m := CASE WHEN p_apres THEN p_m0 + (h0r / 360) ELSE p_m0 - (h0r / 360) END;
  theta := private.priere_borne(p_theta0 + (360.985647 * m), 360);
  alpha := private.priere_borne(private.priere_interpoler_angles(p_a2, p_a1, p_a3, m), 360);
  delta := private.priere_interpoler(p_d2, p_d1, p_d3, m);
  hh := theta - lw - alpha;
  sinus := (sin(radians(p_lat)) * sin(radians(delta)))
         + (cos(radians(p_lat)) * cos(radians(delta)) * cos(radians(hh)));
  IF sinus > 1 OR sinus < -1 THEN RETURN NULL; END IF;
  haut := degrees(asin(sinus));
  t4 := 360 * cos(radians(delta)) * cos(radians(p_lat)) * sin(radians(hh));
  IF t4 = 0 THEN RETURN NULL; END IF;
  RETURN (m + ((haut - p_h0) / t4)) * 24;
END;
$function$;

-- Heures decimales -> secondes depuis minuit UTC du jour (NULL si NULL), avec les
-- troncatures heures / minutes / secondes du paquet.
CREATE FUNCTION private.priere_secondes(p_heures double precision)
RETURNS bigint
LANGUAGE sql IMMUTABLE PARALLEL SAFE SET search_path = ''
AS $$
  SELECT CASE WHEN p_heures IS NULL THEN NULL ELSE
    (pg_catalog.floor(p_heures) * 3600
     + pg_catalog.floor((p_heures - pg_catalog.floor(p_heures)) * 60.0) * 60
     + pg_catalog.floor((p_heures - (pg_catalog.floor(p_heures)
         + pg_catalog.floor((p_heures - pg_catalog.floor(p_heures)) * 60.0) / 60.0)) * 60.0 * 60.0)
    )::bigint END
$$;

-- Les parametres des douze methodes connues de la base (angles, intervalle de
-- l'Isha, ajustements propres a la methode, en minutes).
CREATE FUNCTION private.priere_methode(p_methode text)
RETURNS TABLE (
  angle_fajr double precision, angle_isha double precision, intervalle_isha integer,
  angle_maghrib double precision,
  aj_fajr integer, aj_dhuhr integer, aj_asr integer, aj_maghrib integer, aj_isha integer,
  aj_lever integer)
LANGUAGE sql IMMUTABLE PARALLEL SAFE SET search_path = ''
AS $$
  SELECT v.angle_fajr::double precision, v.angle_isha::double precision, v.intervalle_isha::integer,
         v.angle_maghrib::double precision, v.aj_fajr::integer, v.aj_dhuhr::integer, v.aj_asr::integer,
         v.aj_maghrib::integer, v.aj_isha::integer, v.aj_lever::integer FROM (VALUES
    ('muslim_world_league',    18.0, 17.0::numeric, 0, NULL::numeric, 0, 1, 0, 0, 0, 0),
    ('egyptian',               19.5, 17.5, 0, NULL, 0, 1, 0, 0, 0, 0),
    ('karachi',                18.0, 18.0, 0, NULL, 0, 1, 0, 0, 0, 0),
    ('umm_al_qura',            18.5, NULL, 90, NULL, 0, 0, 0, 0, 0, 0),
    ('dubai',                  18.2, 18.2, 0, NULL, 0, 3, 3, 3, 0, -3),
    ('moon_sighting_committee',18.0, 18.0, 0, NULL, 0, 5, 0, 3, 0, 0),
    ('north_america',          15.0, 15.0, 0, NULL, 0, 1, 0, 0, 0, 0),
    ('kuwait',                 18.0, 17.5, 0, NULL, 0, 0, 0, 0, 0, 0),
    ('qatar',                  18.0, NULL, 90, NULL, 0, 0, 0, 0, 0, 0),
    ('singapore',              20.0, 18.0, 0, NULL, 0, 1, 0, 0, 0, 0),
    ('turkey',                 18.0, 17.0, 0, NULL, 0, 5, 4, 7, 0, -7),
    ('tehran',                 17.7, 14.0, 0, 4.5,  0, 0, 0, 0, 0, 0)
  ) AS v(nom, angle_fajr, angle_isha, intervalle_isha, angle_maghrib,
         aj_fajr, aj_dhuhr, aj_asr, aj_maghrib, aj_isha, aj_lever)
  WHERE v.nom = p_methode
$$;

-- Ajustement saisonnier du Moon Sighting Committee (paquet adhan).
CREATE FUNCTION private.priere_msc_secondes(
  p_matin boolean, p_lat double precision, p_date date)
RETURNS bigint
LANGUAGE plpgsql IMMUTABLE PARALLEL SAFE SET search_path = ''
AS $function$
DECLARE
  a double precision; b double precision; c double precision; d double precision;
  la double precision := pg_catalog.abs(p_lat);
  an int := pg_catalog.date_part('year', p_date)::int;
  jour int := pg_catalog.date_part('doy', p_date)::int;
  bissextile boolean := (an % 4 = 0) AND NOT (an % 100 = 0 AND an % 400 <> 0);
  jours_an int;
  dys int;
  aj double precision;
BEGIN
  IF p_matin THEN
    a := 75 + ((28.65 / 55.0) * la); b := 75 + ((19.44 / 55.0) * la);
    c := 75 + ((32.74 / 55.0) * la); d := 75 + ((48.10 / 55.0) * la);
  ELSE
    a := 75 + ((25.60 / 55.0) * la); b := 75 + ((2.050 / 55.0) * la);
    c := 75 - ((9.210 / 55.0) * la); d := 75 + ((6.140 / 55.0) * la);
  END IF;
  jours_an := CASE WHEN bissextile THEN 366 ELSE 365 END;
  IF p_lat >= 0 THEN
    dys := jour + 10;
    IF dys >= jours_an THEN dys := dys - jours_an; END IF;
  ELSE
    dys := jour - CASE WHEN bissextile THEN 173 ELSE 172 END;
    IF dys < 0 THEN dys := dys + jours_an; END IF;
  END IF;
  IF dys < 91 THEN aj := a + (b - a) / 91.0 * dys;
  ELSIF dys < 137 THEN aj := b + (c - b) / 46.0 * (dys - 91);
  ELSIF dys < 183 THEN aj := c + (d - c) / 46.0 * (dys - 137);
  ELSIF dys < 229 THEN aj := d + (c - d) / 46.0 * (dys - 183);
  ELSIF dys < 275 THEN aj := c + (b - c) / 46.0 * (dys - 229);
  ELSE aj := b + (a - b) / 91.0 * (dys - 275);
  END IF;
  RETURN pg_catalog.floor(aj * 60.0 + 0.5)::bigint;
END;
$function$;

-- Les cinq heures d'entree d'une journee civile (UTC) pour un lieu.
-- Rend zero ligne quand le calcul n'existe pas (soleil sans lever ou sans
-- coucher). `approximee` : l'angle ne se definit pas (haute latitude, ete) ou
-- sort de la borne de la nuit : le repli « nuit partagee en deux » a servi.
CREATE FUNCTION private.priere_calculer(
  p_lat double precision, p_lon double precision, p_date date,
  p_methode text, p_ecole_asr text, p_ajustements jsonb)
RETURNS TABLE (priere text, instant_utc timestamptz, approximee boolean)
LANGUAGE plpgsql IMMUTABLE PARALLEL SAFE SET search_path = ''
AS $function$
DECLARE
  mt record;
  jd double precision := private.priere_jour_julien(p_date);
  s0 record; sp record; sn record;     -- aujourd'hui, hier, demain
  t1 record; t2 record;                -- demain : lui-meme et apres-demain
  m0 double precision; m0_dem double precision;
  alt double precision := -50.0 / 60.0;
  ombre double precision;
  tang double precision; angle_asr double precision;
  transit bigint; lever bigint; coucher bigint; asr bigint; lever_dem bigint;
  nuit bigint;
  fajr bigint; isha bigint; maghrib bigint;
  v double precision;
  sur_fajr bigint; sur_isha bigint;
  ap_fajr boolean := false; ap_isha boolean := false;
  base bigint := (p_date - DATE '1970-01-01')::bigint * 86400;
  msc boolean := (p_methode = 'moon_sighting_committee');
  adj_f integer; adj_d integer; adj_a integer; adj_m integer; adj_i integer;
  rv_f bigint; rv_d bigint; rv_a bigint; rv_m bigint; rv_i bigint;
BEGIN
  SELECT * INTO mt FROM private.priere_methode(p_methode);
  IF NOT FOUND THEN
    RAISE EXCEPTION 'methode de calcul inconnue : %', p_methode USING ERRCODE = '22023';
  END IF;
  IF p_ecole_asr NOT IN ('shafi', 'hanafi') THEN
    RAISE EXCEPTION 'ecole pour l''Asr inconnue : %', p_ecole_asr USING ERRCODE = '22023';
  END IF;
  ombre := CASE WHEN p_ecole_asr = 'hanafi' THEN 2.0 ELSE 1.0 END;

  SELECT * INTO sp FROM private.priere_soleil(jd - 1);
  SELECT * INTO s0 FROM private.priere_soleil(jd);
  SELECT * INTO sn FROM private.priere_soleil(jd + 1);
  SELECT * INTO t2 FROM private.priere_soleil(jd + 2);

  -- Aujourd'hui
  m0 := private.priere_borne((s0.ascension + (-p_lon) - s0.sideral) / 360, 1);
  transit := private.priere_secondes((m0 + (private.priere_angle_proche(
      private.priere_borne(s0.sideral + (360.985647 * m0), 360) - (-p_lon)
      - private.priere_borne(private.priere_interpoler_angles(s0.ascension, sp.ascension, sn.ascension, m0), 360))
      / -360)) * 24);
  lever := private.priere_secondes(private.priere_angle_horaire(m0, alt, p_lat, p_lon, false,
    s0.sideral, s0.ascension, sp.ascension, sn.ascension, s0.declinaison, sp.declinaison, sn.declinaison));
  coucher := private.priere_secondes(private.priere_angle_horaire(m0, alt, p_lat, p_lon, true,
    s0.sideral, s0.ascension, sp.ascension, sn.ascension, s0.declinaison, sp.declinaison, sn.declinaison));
  tang := pg_catalog.abs(p_lat - s0.declinaison);
  angle_asr := degrees(atan(1.0 / (ombre + tan(radians(tang)))));
  asr := private.priere_secondes(private.priere_angle_horaire(m0, angle_asr, p_lat, p_lon, true,
    s0.sideral, s0.ascension, sp.ascension, sn.ascension, s0.declinaison, sp.declinaison, sn.declinaison));

  -- Lever du soleil de demain (sert a la longueur de la nuit)
  m0_dem := private.priere_borne((sn.ascension + (-p_lon) - sn.sideral) / 360, 1);
  lever_dem := private.priere_secondes(private.priere_angle_horaire(m0_dem, alt, p_lat, p_lon, false,
    sn.sideral, sn.ascension, s0.ascension, t2.ascension, sn.declinaison, s0.declinaison, t2.declinaison));

  IF transit IS NULL OR lever IS NULL OR coucher IS NULL OR asr IS NULL OR lever_dem IS NULL THEN
    RETURN;
  END IF;
  nuit := (86400 + lever_dem) - coucher;

  -- Fajr
  v := private.priere_angle_horaire(m0, -mt.angle_fajr, p_lat, p_lon, false,
    s0.sideral, s0.ascension, sp.ascension, sn.ascension, s0.declinaison, sp.declinaison, sn.declinaison);
  fajr := private.priere_secondes(v);
  IF msc AND p_lat >= 55 THEN
    fajr := lever - (nuit * 1000) / 7000;
  END IF;
  IF msc THEN
    sur_fajr := lever - private.priere_msc_secondes(true, p_lat, p_date);
  ELSE
    sur_fajr := lever - pg_catalog.trunc(0.5 * nuit)::bigint;
  END IF;
  IF fajr IS NULL OR fajr < sur_fajr THEN
    fajr := sur_fajr; ap_fajr := true;
  END IF;

  -- Isha
  IF mt.intervalle_isha > 0 THEN
    isha := coucher + mt.intervalle_isha * 60;
  ELSE
    v := private.priere_angle_horaire(m0, -mt.angle_isha, p_lat, p_lon, true,
      s0.sideral, s0.ascension, sp.ascension, sn.ascension, s0.declinaison, sp.declinaison, sn.declinaison);
    isha := private.priere_secondes(v);
    IF msc AND p_lat >= 55 THEN
      isha := coucher + (nuit * 1000) / 7000;
    END IF;
    IF msc THEN
      sur_isha := coucher + private.priere_msc_secondes(false, p_lat, p_date);
    ELSE
      sur_isha := coucher + pg_catalog.trunc(0.5 * nuit)::bigint;
    END IF;
    IF isha IS NULL OR isha > sur_isha THEN
      isha := sur_isha; ap_isha := true;
    END IF;
  END IF;

  -- Maghrib
  maghrib := coucher;
  IF mt.angle_maghrib IS NOT NULL THEN
    v := private.priere_angle_horaire(m0, -mt.angle_maghrib, p_lat, p_lon, true,
      s0.sideral, s0.ascension, sp.ascension, sn.ascension, s0.declinaison, sp.declinaison, sn.declinaison);
    IF v IS NULL THEN RETURN; END IF;
    IF coucher < private.priere_secondes(v) AND isha > private.priere_secondes(v) THEN
      maghrib := private.priere_secondes(v);
    END IF;
  END IF;

  -- Ajustements : ceux de la personne, puis ceux de la methode ; arrondi a la minute
  adj_f := coalesce((p_ajustements ->> 'fajr')::numeric, 0)::int + mt.aj_fajr;
  adj_d := coalesce((p_ajustements ->> 'dhuhr')::numeric, 0)::int + mt.aj_dhuhr;
  adj_a := coalesce((p_ajustements ->> 'asr')::numeric, 0)::int + mt.aj_asr;
  adj_m := coalesce((p_ajustements ->> 'maghrib')::numeric, 0)::int + mt.aj_maghrib;
  adj_i := coalesce((p_ajustements ->> 'isha')::numeric, 0)::int + mt.aj_isha;
  rv_f := base + fajr + adj_f * 60;
  rv_d := base + transit + adj_d * 60;
  rv_a := base + asr + adj_a * 60;
  rv_m := base + maghrib + adj_m * 60;
  rv_i := base + isha + adj_i * 60;
  rv_f := rv_f - (rv_f % 60) + CASE WHEN rv_f % 60 >= 30 THEN 60 ELSE 0 END;
  rv_d := rv_d - (rv_d % 60) + CASE WHEN rv_d % 60 >= 30 THEN 60 ELSE 0 END;
  rv_a := rv_a - (rv_a % 60) + CASE WHEN rv_a % 60 >= 30 THEN 60 ELSE 0 END;
  rv_m := rv_m - (rv_m % 60) + CASE WHEN rv_m % 60 >= 30 THEN 60 ELSE 0 END;
  rv_i := rv_i - (rv_i % 60) + CASE WHEN rv_i % 60 >= 30 THEN 60 ELSE 0 END;

  priere := 'fajr';    instant_utc := pg_catalog.to_timestamp(rv_f); approximee := ap_fajr; RETURN NEXT;
  priere := 'dhuhr';   instant_utc := pg_catalog.to_timestamp(rv_d); approximee := false;   RETURN NEXT;
  priere := 'asr';     instant_utc := pg_catalog.to_timestamp(rv_a); approximee := false;   RETURN NEXT;
  priere := 'maghrib'; instant_utc := pg_catalog.to_timestamp(rv_m); approximee := false;   RETURN NEXT;
  priere := 'isha';    instant_utc := pg_catalog.to_timestamp(rv_i); approximee := ap_isha; RETURN NEXT;
END;
$function$;

-- Le lever du soleil d'une journee civile (UTC) : l'heure ou se ferme le temps du
-- Fajr. Meme algorithme et meme arrondi que `adhan` (sunrise) ; NULL quand le soleil
-- ne se leve pas ce jour-la. Preuve : la colonne `lever` de la reference adhan.
CREATE FUNCTION private.priere_lever(
  p_lat double precision, p_lon double precision, p_date date, p_methode text)
RETURNS timestamptz
LANGUAGE plpgsql IMMUTABLE PARALLEL SAFE SET search_path = ''
AS $function$
DECLARE
  mt record;
  jd double precision := private.priere_jour_julien(p_date);
  s0 record; sp record; sn record;
  m0 double precision;
  alt double precision := -50.0 / 60.0;
  lever bigint;
  rv bigint;
BEGIN
  SELECT * INTO mt FROM private.priere_methode(p_methode);
  IF NOT FOUND THEN
    RAISE EXCEPTION 'methode de calcul inconnue : %', p_methode USING ERRCODE = '22023';
  END IF;
  SELECT * INTO sp FROM private.priere_soleil(jd - 1);
  SELECT * INTO s0 FROM private.priere_soleil(jd);
  SELECT * INTO sn FROM private.priere_soleil(jd + 1);
  m0 := private.priere_borne((s0.ascension + (-p_lon) - s0.sideral) / 360, 1);
  lever := private.priere_secondes(private.priere_angle_horaire(m0, alt, p_lat, p_lon, false,
    s0.sideral, s0.ascension, sp.ascension, sn.ascension, s0.declinaison, sp.declinaison, sn.declinaison));
  IF lever IS NULL THEN
    RETURN NULL;
  END IF;
  rv := (p_date - DATE '1970-01-01')::bigint * 86400 + lever + mt.aj_lever * 60;
  rv := rv - (rv % 60) + CASE WHEN rv % 60 >= 30 THEN 60 ELSE 0 END;
  RETURN pg_catalog.to_timestamp(rv);
END;
$function$;

REVOKE ALL ON FUNCTION private.priere_borne(double precision, double precision),
  private.priere_arrondi(double precision), private.priere_angle_proche(double precision),
  private.priere_interpoler(double precision, double precision, double precision, double precision),
  private.priere_interpoler_angles(double precision, double precision, double precision, double precision),
  private.priere_jour_julien(date), private.priere_soleil(double precision),
  private.priere_angle_horaire(double precision, double precision, double precision, double precision,
    boolean, double precision, double precision, double precision, double precision,
    double precision, double precision, double precision),
  private.priere_secondes(double precision), private.priere_methode(text),
  private.priere_msc_secondes(boolean, double precision, date),
  private.priere_calculer(double precision, double precision, date, text, text, jsonb),
  private.priere_lever(double precision, double precision, date, text)
  FROM PUBLIC, anon, authenticated, service_role, agent_ro;

COMMENT ON FUNCTION private.priere_calculer(double precision, double precision, date, text, text, jsonb) IS
  'PRIERE-1 : les cinq heures d''entree (UTC) d''un jour civil pour un lieu, une methode, une ecole d''Asr et des ajustements. Immuable. Port de l''algorithme de adhan 2.0.0+1 ; zero ligne quand le soleil ne se leve ou ne se couche pas ; approximee = repli de haute latitude. Preuve : supabase/tests/scenarios_priere_serveur.sql.';

-- ===========================================================================
-- 3. Les reglages de l'academie (app_config, cles priere.*)
-- ===========================================================================
-- Valeurs par defaut en vigueur par arbitrage du 12/11/2026. La methode et
-- l'ecole d'Asr relevent du fiqh : A VALIDER PAR LE DIRECTEUR ET SES ASSOCIES.
INSERT INTO public.app_config (key, value) VALUES
  ('priere.methode_defaut', '"muslim_world_league"'::jsonb),
  ('priere.ecole_asr_defaut', '"shafi"'::jsonb),
  ('priere.pause_minutes', '10'::jsonb),
  ('priere.pause_ramadan_maghrib_minutes', '20'::jsonb),
  ('priere.ramadan_en_cours', 'false'::jsonb),
  ('priere.debut_marge_minutes', '5'::jsonb),
  ('priere.fin_marge_minutes', '15'::jsonb),
  ('priere.horizon_jours', '14'::jsonb),
  ('priere.marge_avant_cours_minutes', '20'::jsonb),
  ('priere.delai_fermeture_minutes', '10'::jsonb)
ON CONFLICT (key) DO NOTHING;

CREATE FUNCTION private.priere_reglages_valider()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  v_entier integer;
BEGIN
  IF NEW.key NOT LIKE 'priere.%' THEN
    RETURN NEW;
  END IF;
  CASE NEW.key
    WHEN 'priere.methode_defaut' THEN
      IF pg_catalog.jsonb_typeof(NEW.value) <> 'string'
         OR NOT EXISTS (SELECT 1 FROM private.priere_methode(NEW.value #>> '{}')) THEN
        RAISE EXCEPTION 'priere.methode_defaut : une des douze methodes connues' USING ERRCODE = '22023';
      END IF;
    WHEN 'priere.ecole_asr_defaut' THEN
      IF pg_catalog.jsonb_typeof(NEW.value) <> 'string'
         OR (NEW.value #>> '{}') NOT IN ('shafi', 'hanafi') THEN
        RAISE EXCEPTION 'priere.ecole_asr_defaut : shafi ou hanafi' USING ERRCODE = '22023';
      END IF;
    WHEN 'priere.pause_minutes', 'priere.pause_ramadan_maghrib_minutes' THEN
      IF pg_catalog.jsonb_typeof(NEW.value) <> 'number' THEN
        RAISE EXCEPTION '% : un nombre de minutes', NEW.key USING ERRCODE = '22023';
      END IF;
      v_entier := (NEW.value #>> '{}')::numeric::integer;
      IF (NEW.value #>> '{}')::numeric <> v_entier OR v_entier NOT BETWEEN 5 AND 20 OR v_entier % 5 <> 0 THEN
        RAISE EXCEPTION '% : de 5 a 20 minutes, par pas de 5', NEW.key USING ERRCODE = '22023';
      END IF;
    WHEN 'priere.ramadan_en_cours' THEN
      IF pg_catalog.jsonb_typeof(NEW.value) <> 'boolean' THEN
        RAISE EXCEPTION 'priere.ramadan_en_cours : vrai ou faux' USING ERRCODE = '22023';
      END IF;
    WHEN 'priere.debut_marge_minutes' THEN
      IF pg_catalog.jsonb_typeof(NEW.value) <> 'number'
         OR (NEW.value #>> '{}')::numeric NOT BETWEEN 0 AND 15
         OR (NEW.value #>> '{}')::numeric <> pg_catalog.floor((NEW.value #>> '{}')::numeric) THEN
        RAISE EXCEPTION 'priere.debut_marge_minutes : de 0 a 15 minutes' USING ERRCODE = '22023';
      END IF;
    WHEN 'priere.fin_marge_minutes' THEN
      IF pg_catalog.jsonb_typeof(NEW.value) <> 'number'
         OR (NEW.value #>> '{}')::numeric NOT BETWEEN 5 AND 30
         OR (NEW.value #>> '{}')::numeric <> pg_catalog.floor((NEW.value #>> '{}')::numeric) THEN
        RAISE EXCEPTION 'priere.fin_marge_minutes : de 5 a 30 minutes' USING ERRCODE = '22023';
      END IF;
    WHEN 'priere.marge_avant_cours_minutes' THEN
      IF pg_catalog.jsonb_typeof(NEW.value) <> 'number'
         OR (NEW.value #>> '{}')::numeric NOT BETWEEN 5 AND 60
         OR (NEW.value #>> '{}')::numeric <> pg_catalog.floor((NEW.value #>> '{}')::numeric) THEN
        RAISE EXCEPTION 'priere.marge_avant_cours_minutes : de 5 a 60 minutes' USING ERRCODE = '22023';
      END IF;
    WHEN 'priere.delai_fermeture_minutes' THEN
      IF pg_catalog.jsonb_typeof(NEW.value) <> 'number'
         OR (NEW.value #>> '{}')::numeric NOT BETWEEN 0 AND 30
         OR (NEW.value #>> '{}')::numeric <> pg_catalog.floor((NEW.value #>> '{}')::numeric) THEN
        RAISE EXCEPTION 'priere.delai_fermeture_minutes : de 0 a 30 minutes' USING ERRCODE = '22023';
      END IF;
    WHEN 'priere.horizon_jours' THEN
      IF pg_catalog.jsonb_typeof(NEW.value) <> 'number'
         OR (NEW.value #>> '{}')::numeric NOT BETWEEN 7 AND 30
         OR (NEW.value #>> '{}')::numeric <> pg_catalog.floor((NEW.value #>> '{}')::numeric) THEN
        RAISE EXCEPTION 'priere.horizon_jours : de 7 a 30 jours' USING ERRCODE = '22023';
      END IF;
    ELSE
      RAISE EXCEPTION 'reglage de priere inconnu : %', NEW.key USING ERRCODE = '22023';
  END CASE;
  RETURN NEW;
END;
$function$;

CREATE TRIGGER app_config_priere
BEFORE INSERT OR UPDATE ON public.app_config
FOR EACH ROW EXECUTE FUNCTION private.priere_reglages_valider();

-- Les reglages de l'academie, lus d'un seul geste (valeurs par defaut si une cle manque).
CREATE FUNCTION private.priere_cfg()
RETURNS TABLE (
  methode text, ecole text, pause integer, pause_ramadan integer, ramadan boolean,
  marge_debut integer, marge_fin integer, horizon integer,
  marge_avant integer, delai_fermeture integer)
LANGUAGE sql
STABLE
SET search_path = ''
AS $$
  SELECT
    coalesce((SELECT value #>> '{}' FROM public.app_config WHERE key = 'priere.methode_defaut'), 'muslim_world_league'),
    coalesce((SELECT value #>> '{}' FROM public.app_config WHERE key = 'priere.ecole_asr_defaut'), 'shafi'),
    coalesce((SELECT (value #>> '{}')::integer FROM public.app_config WHERE key = 'priere.pause_minutes'), 10),
    coalesce((SELECT (value #>> '{}')::integer FROM public.app_config WHERE key = 'priere.pause_ramadan_maghrib_minutes'), 20),
    coalesce((SELECT (value #>> '{}')::boolean FROM public.app_config WHERE key = 'priere.ramadan_en_cours'), false),
    coalesce((SELECT (value #>> '{}')::integer FROM public.app_config WHERE key = 'priere.debut_marge_minutes'), 5),
    coalesce((SELECT (value #>> '{}')::integer FROM public.app_config WHERE key = 'priere.fin_marge_minutes'), 15),
    coalesce((SELECT (value #>> '{}')::integer FROM public.app_config WHERE key = 'priere.horizon_jours'), 14),
    coalesce((SELECT (value #>> '{}')::integer FROM public.app_config WHERE key = 'priere.marge_avant_cours_minutes'), 20),
    coalesce((SELECT (value #>> '{}')::integer FROM public.app_config WHERE key = 'priere.delai_fermeture_minutes'), 10)
$$;

-- ===========================================================================
-- 4. Le lieu et les reglages d'un enseignant (prayer_settings)
-- ===========================================================================
-- La position d'un enseignant est une donnee personnelle : lue par lui et par la
-- direction seulement (jamais par un eleve ni un tuteur, que l'ancienne politique
-- admettait), ecrite par la direction seulement (le lieu) ou par lui (ses
-- ajustements, par la fonction priere_ajuster). Les colonnes method, madhab,
-- pause_minutes et alert_lead_minutes restent mais ne sont plus lues : la methode
-- et l'ecole d'Asr viennent de l'academie (surchargeables ci-dessous), la duree de la pause
-- aussi.
ALTER TABLE public.prayer_settings
  ADD COLUMN IF NOT EXISTS methode_surcharge text
    CHECK (methode_surcharge IS NULL OR methode_surcharge IN (
      'muslim_world_league', 'egyptian', 'karachi', 'umm_al_qura', 'dubai',
      'moon_sighting_committee', 'north_america', 'kuwait', 'qatar',
      'singapore', 'tehran', 'turkey')),
  ADD COLUMN IF NOT EXISTS ecole_asr_surcharge text
    CHECK (ecole_asr_surcharge IS NULL OR ecole_asr_surcharge IN ('shafi', 'hanafi')),
  ADD COLUMN IF NOT EXISTS assiste_vendredi boolean NOT NULL DEFAULT false,
  ADD COLUMN IF NOT EXISTS vendredi_debut time NOT NULL DEFAULT '12:30',
  ADD COLUMN IF NOT EXISTS vendredi_fin time NOT NULL DEFAULT '14:30',
  ADD COLUMN IF NOT EXISTS actif boolean NOT NULL DEFAULT true,
  ADD COLUMN IF NOT EXISTS defini_par uuid,
  ADD COLUMN IF NOT EXISTS defini_le timestamptz;

ALTER TABLE public.prayer_settings
  ADD CONSTRAINT prayer_settings_vendredi_plage CHECK (vendredi_debut < vendredi_fin);

COMMENT ON COLUMN public.prayer_settings.actif IS
  'PRIERE-1 : faux = lieu retire par la direction (la position est ecrasee) ; aucune pause de priere pour cet enseignant.';
COMMENT ON COLUMN public.prayer_settings.methode_surcharge IS
  'PRIERE-1 : methode propre a cet enseignant ; nul = celle de l''academie (app_config priere.methode_defaut). A valider par le directeur et ses associes.';
COMMENT ON COLUMN public.prayer_settings.ecole_asr_surcharge IS
  'PRIERE-1 : ecole d''Asr propre a cet enseignant ; nul = celle de l''academie (app_config priere.ecole_asr_defaut). A valider par le directeur et ses associes.';

-- Lecture : l'enseignant lui-meme et la direction. Ecriture directe fermee : le
-- lieu passe par priere_lieu_definir (direction), les ajustements par
-- priere_ajuster (enseignant).
ALTER POLICY prayer_settings_parties_read ON public.prayer_settings
  USING (coalesce(public.app_account_valid(), false)
         AND (teacher_id = auth.uid() OR public.app_role() = 'admin'));
ALTER POLICY prayer_settings_self_write ON public.prayer_settings
  USING (false) WITH CHECK (false);
REVOKE INSERT, UPDATE ON public.prayer_settings FROM PUBLIC, anon, authenticated;

-- Les reglages effectifs d'un enseignant ; aucune ligne s'il n'a pas de lieu.
CREATE FUNCTION private.priere_reglages(p_enseignant uuid)
RETURNS TABLE (
  lat double precision, lon double precision, fuseau text, lieu text,
  methode text, ecole text, ajustements jsonb,
  assiste_vendredi boolean, vendredi_debut time, vendredi_fin time)
LANGUAGE sql
STABLE
SET search_path = ''
AS $$
  SELECT ps.latitude::double precision, ps.longitude::double precision,
         ps.timezone_iana, ps.place_label,
         coalesce(ps.methode_surcharge, c.methode),
         coalesce(ps.ecole_asr_surcharge, c.ecole),
         ps.adjustments, ps.assiste_vendredi, ps.vendredi_debut, ps.vendredi_fin
    FROM public.prayer_settings ps
   CROSS JOIN private.priere_cfg() c
   WHERE ps.teacher_id = p_enseignant AND ps.actif
$$;

-- ===========================================================================
-- 5. Ou tombe la pause : croisements et placement (regle unique, PRIERE.md 3)
-- ===========================================================================
-- Une ligne par priere qui ENTRE dans [p_debut, p_fin), plus, au plus, une ligne
-- `indefini` quand le calcul n'existe pas pour l'un des trois jours (aucune pause
-- ne se place alors). `retenue` : la priere qui porte la pause (la plus courte
-- fenetre parmi celles qui ne tombent pas dans la marge de fin).
CREATE FUNCTION private.priere_placer(
  p_debut timestamptz, p_fin timestamptz,
  p_lat double precision, p_lon double precision,
  p_methode text, p_ecole text, p_ajust jsonb,
  p_pause integer, p_pause_ramadan integer, p_ramadan boolean,
  p_marge_debut integer, p_marge_fin integer,
  p_marge_avant integer DEFAULT 20, p_delai_fermeture integer DEFAULT 10)
RETURNS TABLE (
  priere text, entree_utc timestamptz, approximee boolean, zone text,
  retenue boolean, debut_prevu_utc timestamptz, duree_minutes integer, indefini boolean)
LANGUAGE plpgsql
STABLE
SET search_path = ''
AS $function$
DECLARE
  v_p text[]; v_t timestamptz[]; v_a boolean[]; v_d integer[];
  nn integer;
  w0 timestamptz; w1 timestamptz; v_indef boolean := false;
  d0 date := (p_debut AT TIME ZONE 'UTC')::date;
  v_long numeric := pg_catalog.date_part('epoch', p_fin - p_debut) / 60.0;
  i integer;
  n integer := 0;
  v_off numeric; v_dur integer; v_zone text; v_deb timestamptz;
  c_i integer[] := '{}'; c_zone text[] := '{}'; c_fen numeric[] := '{}';
  c_deb timestamptz[] := '{}'; c_dur integer[] := '{}';
  v_best integer := NULL;
  k integer;
  -- La priere qui se ferme (arbitrage du 13/11/2026) : entree moins de p_marge_avant
  -- minutes avant le debut du cours, temps ferme avant la fin du cours.
  v_ferm timestamptz; v_ferm_i integer := NULL; v_ferm_t timestamptz;
  v_fdur integer; v_fdeb timestamptz; v_fok boolean;
BEGIN
  SELECT pg_catalog.array_agg(c.priere ORDER BY c.instant_utc),
         pg_catalog.array_agg(c.instant_utc ORDER BY c.instant_utc),
         pg_catalog.array_agg(c.approximee ORDER BY c.instant_utc),
         pg_catalog.array_agg(j.k ORDER BY c.instant_utc)
    INTO v_p, v_t, v_a, v_d
    FROM pg_catalog.generate_series(-1, 1) AS j(k),
         LATERAL private.priere_calculer(p_lat, p_lon, d0 + j.k, p_methode, p_ecole, p_ajust) c;
  nn := coalesce(pg_catalog.cardinality(v_t), 0);

  -- Un jour sans calcul (haute latitude) ne rend indefinie QUE la seance qui le touche :
  -- la fenetre utile va de `marge_avant` minutes avant le debut a la fin du cours ; elle
  -- doit tenir entre des heures connues, sans trou de plus de 20 heures dedans.
  IF nn = 0 THEN
    v_indef := true;
  ELSE
    w0 := p_debut - pg_catalog.make_interval(mins => p_marge_avant);
    w1 := p_fin;
    v_indef := (w0 < v_t[1] OR w1 > v_t[nn]);
    IF NOT v_indef THEN
      FOR i IN 1..nn - 1 LOOP
        IF v_t[i + 1] - v_t[i] > INTERVAL '20 hours' AND v_t[i] < w1 AND v_t[i + 1] > w0 THEN
          v_indef := true;
          EXIT;
        END IF;
      END LOOP;
    END IF;
  END IF;

  IF v_indef THEN
    priere := NULL; entree_utc := NULL; approximee := NULL; zone := NULL;
    retenue := false; debut_prevu_utc := NULL; duree_minutes := NULL; indefini := true;
    RETURN NEXT;
    RETURN;
  END IF;

  FOR i IN 1..nn LOOP
    IF v_t[i] >= p_debut AND v_t[i] < p_fin THEN
      v_off := pg_catalog.date_part('epoch', v_t[i] - p_debut) / 60.0;
      v_dur := CASE WHEN v_p[i] = 'maghrib' AND p_ramadan THEN p_pause_ramadan ELSE p_pause END;
      v_zone := CASE
        WHEN v_off < p_marge_debut THEN 'debut'
        WHEN v_off > v_long - GREATEST(p_marge_fin, v_dur) THEN 'fin'
        ELSE 'milieu' END;
      v_deb := CASE WHEN v_zone = 'debut'
                    THEN p_debut + pg_catalog.make_interval(mins => p_marge_debut)
                    ELSE v_t[i] END;
      -- La pause ne depasse jamais l'heure de fin annoncee (P7).
      IF v_deb + pg_catalog.make_interval(mins => v_dur) > p_fin THEN
        v_zone := 'fin';
      END IF;
      n := n + 1;
      c_i[n] := i; c_zone[n] := v_zone; c_fen[n] := 0; c_deb[n] := v_deb; c_dur[n] := v_dur;
      -- La PREMIERE, dans l'ordre du temps, qui n'est pas en zone de fin : la priere qui
      -- risquerait de se fermer pendant le cours passe avant celle qui entre apres elle.
      IF v_zone <> 'fin' AND v_best IS NULL THEN
        v_best := n;
      END IF;
    END IF;
  END LOOP;

  -- La priere qui se ferme PENDANT le cours : le lever du soleil ferme le Fajr, l'entree
  -- de la priere suivante ferme les autres. La plus proche de se fermer est retenue.
  FOR i IN 1..nn - 1 LOOP
    IF v_t[i] < p_debut
       AND p_debut - v_t[i] < pg_catalog.make_interval(mins => p_marge_avant) THEN
      v_ferm := CASE WHEN v_p[i] = 'fajr'
                     THEN private.priere_lever(p_lat, p_lon, d0 + v_d[i], p_methode)
                     ELSE v_t[i + 1] END;
      IF v_ferm IS NOT NULL AND v_ferm > p_debut AND v_ferm < p_fin
         AND (v_ferm_t IS NULL OR v_ferm < v_ferm_t) THEN
        v_ferm_t := v_ferm; v_ferm_i := i;
      END IF;
    END IF;
  END LOOP;
  IF v_ferm_i IS NOT NULL THEN
    v_fdur := CASE WHEN v_p[v_ferm_i] = 'maghrib' AND p_ramadan THEN p_pause_ramadan ELSE p_pause END;
    v_fdeb := p_debut + pg_catalog.make_interval(mins => p_delai_fermeture);
    v_fok := v_fdeb + pg_catalog.make_interval(mins => v_fdur) <= p_fin
             AND p_delai_fermeture <= v_long - GREATEST(p_marge_fin, v_fdur);
    n := n + 1;
    c_i[n] := v_ferm_i; c_zone[n] := CASE WHEN v_fok THEN 'fermeture' ELSE 'fermeture_fin' END;
    c_fen[n] := 0; c_deb[n] := v_fdeb; c_dur[n] := v_fdur;
    -- Elle prime sur la priere qui entre pendant le cours (qui a tout son temps apres) ;
    -- si sa pause ne tient pas, la regle ordinaire reprend.
    IF v_fok THEN
      v_best := n;
    END IF;
  END IF;

  FOR k IN 1..n LOOP
    priere := v_p[c_i[k]]; entree_utc := v_t[c_i[k]]; approximee := v_a[c_i[k]];
    zone := c_zone[k]; retenue := coalesce(k = v_best, false);
    debut_prevu_utc := CASE WHEN k = v_best THEN c_deb[k] ELSE NULL END;
    duree_minutes := c_dur[k]; indefini := false;
    RETURN NEXT;
  END LOOP;
END;
$function$;

-- ===========================================================================
-- 6. Le remplissage : une seance, un enseignant, toutes les seances proches
-- ===========================================================================
-- Ecrit la ligne du stock (ou la retire en la marquant). Une ligne n'est creee
-- pour une seance sans pause que si une ligne existait deja ou si le calcul est
-- indefini (pour ne pas journaliser deux fois).
CREATE FUNCTION private.priere_ecrire_stock(
  p_session_id uuid, p_debut timestamptz, p_duree integer, p_priere text,
  p_indefini boolean, p_enseignant uuid, p_jour date)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  v_ancien public.seance_pause_prevue_stock%ROWTYPE;
BEGIN
  SELECT * INTO v_ancien FROM public.seance_pause_prevue_stock WHERE session_id = p_session_id;

  IF p_debut IS NOT NULL THEN
    INSERT INTO public.seance_pause_prevue_stock
      (session_id, debut_prevu_utc, duree_minutes, motif, priere, calcule_le, retiree_le, indefini)
    VALUES (p_session_id, p_debut, p_duree, 'priere', p_priere, pg_catalog.now(), NULL, false)
    ON CONFLICT (session_id) DO UPDATE
      SET debut_prevu_utc = EXCLUDED.debut_prevu_utc, duree_minutes = EXCLUDED.duree_minutes,
          motif = 'priere', priere = EXCLUDED.priere,
          calcule_le = EXCLUDED.calcule_le, retiree_le = NULL, indefini = false;
    RETURN;
  END IF;

  IF FOUND OR p_indefini THEN
    INSERT INTO public.seance_pause_prevue_stock
      (session_id, debut_prevu_utc, duree_minutes, motif, priere, calcule_le, retiree_le, indefini)
    VALUES (p_session_id, NULL, NULL, NULL, NULL, pg_catalog.now(), pg_catalog.now(), p_indefini)
    ON CONFLICT (session_id) DO UPDATE
      SET debut_prevu_utc = NULL, duree_minutes = NULL, motif = NULL, priere = NULL,
          calcule_le = pg_catalog.now(), retiree_le = pg_catalog.now(), indefini = p_indefini;
  END IF;

  -- Le journal de la direction : une seule fois par seance, jamais la position.
  IF p_indefini AND NOT coalesce(v_ancien.indefini, false) THEN
    PERFORM public.log_sensitive_access('priere_calcul_indefini', 'sessions', p_session_id::text,
      pg_catalog.jsonb_build_object('enseignant_id', p_enseignant, 'jour', p_jour,
        'effet', 'aucune pause de priere pour cette seance'));
  END IF;
END;
$function$;

CREATE FUNCTION private.priere_recalculer_seance(p_session_id uuid)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  s record;
  v_ens uuid;
  rg record;
  cfg record;
  r record;
  v_retenue boolean := false;
  v_indefini boolean := false;
BEGIN
  SELECT x.id, x.started_at, x.ended_at, x.status, x.deleted_at, x.groupe_id
    INTO s FROM public.sessions x WHERE x.id = p_session_id;
  IF NOT FOUND OR s.groupe_id IS NULL THEN
    RETURN;
  END IF;

  -- Seance annulee ou supprimee : la ligne eventuelle est retiree.
  IF s.deleted_at IS NOT NULL OR s.status IN
     ('canceled_late', 'canceled', 'teacher_absent', 'student_absent', 'tech_failure') THEN
    PERFORM private.priere_ecrire_stock(p_session_id, NULL, NULL, NULL, false, NULL, NULL);
    RETURN;
  END IF;
  -- Une seance commencee ou finie ne bouge plus (comme le reglage de la pause).
  IF s.status NOT IN ('planned', 'preflight') THEN
    RETURN;
  END IF;

  v_ens := private.c29_enseignant_effectif_session(p_session_id);
  SELECT * INTO rg FROM private.priere_reglages(v_ens);
  IF v_ens IS NULL OR NOT FOUND THEN
    PERFORM private.priere_ecrire_stock(p_session_id, NULL, NULL, NULL, false, v_ens, NULL);
    RETURN;
  END IF;
  SELECT * INTO cfg FROM private.priere_cfg();

  FOR r IN
    SELECT * FROM private.priere_placer(s.started_at, s.ended_at, rg.lat, rg.lon,
      rg.methode, rg.ecole, rg.ajustements, cfg.pause, cfg.pause_ramadan, cfg.ramadan,
      cfg.marge_debut, cfg.marge_fin, cfg.marge_avant, cfg.delai_fermeture)
  LOOP
    IF r.indefini THEN
      v_indefini := true;
    ELSIF r.retenue THEN
      v_retenue := true;
      PERFORM private.priere_ecrire_stock(p_session_id, r.debut_prevu_utc, r.duree_minutes,
        r.priere, false, v_ens, (s.started_at AT TIME ZONE 'UTC')::date);
    END IF;
  END LOOP;

  IF NOT v_retenue THEN
    PERFORM private.priere_ecrire_stock(p_session_id, NULL, NULL, NULL, v_indefini, v_ens,
      (s.started_at AT TIME ZONE 'UTC')::date);
  END IF;
END;
$function$;

-- Les seances a venir d'un enseignant (titulaire ou remplacant).
CREATE FUNCTION private.priere_recalculer_enseignant(p_enseignant uuid)
RETURNS integer
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  v_id uuid;
  v_n integer := 0;
BEGIN
  FOR v_id IN
    SELECT s.id FROM public.sessions s
     WHERE s.deleted_at IS NULL AND s.groupe_id IS NOT NULL
       AND s.status IN ('planned', 'preflight') AND s.started_at > pg_catalog.now()
       AND (s.teacher_id = p_enseignant
            OR EXISTS (SELECT 1 FROM public.remplacements_seance r
                        WHERE r.session_id = s.id AND r.enseignant_remplacant_id = p_enseignant))
  LOOP
    BEGIN
      PERFORM private.priere_recalculer_seance(v_id);
      v_n := v_n + 1;
    EXCEPTION WHEN OTHERS THEN
      RAISE WARNING 'PRIERE-1 : recalcul de la seance % impossible : %', v_id, SQLERRM;
    END;
  END LOOP;
  RETURN v_n;
END;
$function$;

-- Les seances de l'horizon (recalcul de nuit) ou, avec p_tout, toutes les seances a
-- venir (changement d'un reglage de l'academie : un reglage rare, une seule passe).
CREATE FUNCTION private.priere_recalculer_horizon(p_tout boolean DEFAULT false)
RETURNS integer
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  v_id uuid;
  v_n integer := 0;
  v_horizon integer := (SELECT horizon FROM private.priere_cfg());
BEGIN
  FOR v_id IN
    SELECT s.id FROM public.sessions s
     WHERE s.deleted_at IS NULL AND s.groupe_id IS NOT NULL
       AND s.status IN ('planned', 'preflight')
       AND s.started_at > pg_catalog.now()
       AND (p_tout OR s.started_at < pg_catalog.now() + pg_catalog.make_interval(days => v_horizon))
  LOOP
    BEGIN
      PERFORM private.priere_recalculer_seance(v_id);
      v_n := v_n + 1;
    EXCEPTION WHEN OTHERS THEN
      RAISE WARNING 'PRIERE-1 : recalcul de la seance % impossible : %', v_id, SQLERRM;
    END;
  END LOOP;
  RETURN v_n;
END;
$function$;

-- Declencheurs. Aucun ne peut empecher l'ecriture qui le declenche : une erreur de
-- calcul est signalee (avertissement) et la seance se cree quand meme.
CREATE FUNCTION private.priere_trg_seance()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $function$
BEGIN
  IF TG_OP = 'UPDATE'
     AND (OLD.started_at, OLD.ended_at, OLD.status, OLD.deleted_at, OLD.groupe_id, OLD.teacher_id)
         IS NOT DISTINCT FROM
         (NEW.started_at, NEW.ended_at, NEW.status, NEW.deleted_at, NEW.groupe_id, NEW.teacher_id) THEN
    RETURN NEW;
  END IF;
  BEGIN
    PERFORM private.priere_recalculer_seance(NEW.id);
  EXCEPTION WHEN OTHERS THEN
    RAISE WARNING 'PRIERE-1 : pause de priere de la seance % non calculee : %', NEW.id, SQLERRM;
  END;
  RETURN NEW;
END;
$function$;

CREATE TRIGGER priere_pause_prevue
AFTER INSERT OR UPDATE OF started_at, ended_at, status, deleted_at, groupe_id, teacher_id ON public.sessions
FOR EACH ROW EXECUTE FUNCTION private.priere_trg_seance();

CREATE FUNCTION private.priere_trg_remplacement()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $function$
BEGIN
  BEGIN
    PERFORM private.priere_recalculer_seance(NEW.session_id);
  EXCEPTION WHEN OTHERS THEN
    RAISE WARNING 'PRIERE-1 : pause de priere de la seance % non recalculee : %', NEW.session_id, SQLERRM;
  END;
  RETURN NEW;
END;
$function$;

CREATE TRIGGER priere_pause_prevue
AFTER INSERT ON public.remplacements_seance
FOR EACH ROW EXECUTE FUNCTION private.priere_trg_remplacement();

CREATE FUNCTION private.priere_trg_reglages_enseignant()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $function$
BEGIN
  BEGIN
    PERFORM private.priere_recalculer_enseignant(NEW.teacher_id);
  EXCEPTION WHEN OTHERS THEN
    RAISE WARNING 'PRIERE-1 : recalcul pour l''enseignant % impossible : %', NEW.teacher_id, SQLERRM;
  END;
  RETURN NEW;
END;
$function$;

CREATE TRIGGER priere_pause_prevue
AFTER INSERT OR UPDATE ON public.prayer_settings
FOR EACH ROW EXECUTE FUNCTION private.priere_trg_reglages_enseignant();

CREATE FUNCTION private.priere_trg_reglages_academie()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $function$
BEGIN
  BEGIN
    PERFORM private.priere_recalculer_horizon(true);
  EXCEPTION WHEN OTHERS THEN
    RAISE WARNING 'PRIERE-1 : recalcul apres changement de reglage impossible : %', SQLERRM;
  END;
  RETURN NEW;
END;
$function$;

CREATE TRIGGER app_config_priere_recalcul
AFTER INSERT OR UPDATE ON public.app_config
FOR EACH ROW WHEN (NEW.key LIKE 'priere.%')
EXECUTE FUNCTION private.priere_trg_reglages_academie();

-- Un compte desactive (suppression, anonymisation : private.cpt_anonymiser desactive le
-- profil AVANT de retirer ses reglages) : les pauses de ses seances a venir sont retirees
-- tout de suite, sans attendre le recalcul de nuit. Aucune ligne n'est effacee : elles
-- sont marquees retirees, comme le fait priere_lieu_retirer.
CREATE FUNCTION private.priere_trg_profil_desactive()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $function$
BEGIN
  BEGIN
    UPDATE public.seance_pause_prevue_stock st
       SET debut_prevu_utc = NULL, duree_minutes = NULL, motif = NULL, priere = NULL,
           calcule_le = pg_catalog.now(), retiree_le = pg_catalog.now(), indefini = false
     WHERE st.retiree_le IS NULL
       AND st.session_id IN (
         SELECT s.id FROM public.sessions s
          WHERE s.status IN ('planned', 'preflight') AND s.started_at > pg_catalog.now()
            AND private.c29_enseignant_effectif_session(s.id) = NEW.id);
  EXCEPTION WHEN OTHERS THEN
    RAISE WARNING 'PRIERE-1 : pauses de priere du compte % non retirees : %', NEW.id, SQLERRM;
  END;
  RETURN NEW;
END;
$function$;

CREATE TRIGGER priere_pause_prevue_compte
AFTER UPDATE OF account_status ON public.profiles
FOR EACH ROW WHEN (NEW.account_status = 'disabled' AND OLD.account_status IS DISTINCT FROM NEW.account_status)
EXECUTE FUNCTION private.priere_trg_profil_desactive();

-- Le recalcul planifie de chaque nuit (3 h 30, heure universelle), seulement si
-- pg_cron existe (comme SES-CLOTURE-AUTO) : la CI rejoue les migrations sur un
-- Postgres sans pg_cron.
DO $cron$
BEGIN
  IF EXISTS (SELECT 1 FROM pg_catalog.pg_extension WHERE extname = 'pg_cron') THEN
    BEGIN
      EXECUTE $q$SELECT cron.schedule('priere-recalcul-nuit', '30 3 * * *',
        'SELECT private.priere_recalculer_horizon()')$q$;
    EXCEPTION WHEN OTHERS THEN
      RAISE WARNING 'PRIERE-1 : planification pg_cron impossible (%) ; a faire a la main', SQLERRM;
    END;
  ELSE
    RAISE NOTICE 'PRIERE-1 : pg_cron absente, rien n''est planifie (appel manuel : priere_recalculer_maintenant)';
  END IF;
END;
$cron$;

-- Appel a la main par la direction (double authentification), comme la cloture
-- automatique des seances.
CREATE FUNCTION public.priere_recalculer_maintenant()
RETURNS integer
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $function$
BEGIN
  IF NOT coalesce(
       public.app_account_valid()
       AND public.app_role() = 'admin'
       AND auth.jwt() ->> 'aal' = 'aal2', false) THEN
    RAISE EXCEPTION 'recalcul des pauses de priere reserve a la direction (double authentification)'
      USING ERRCODE = '42501';
  END IF;
  RETURN private.priere_recalculer_horizon();
END;
$function$;

REVOKE ALL ON FUNCTION
  private.priere_reglages_valider(), private.priere_cfg(), private.priere_reglages(uuid),
  private.priere_placer(timestamptz, timestamptz, double precision, double precision, text, text, jsonb,
    integer, integer, boolean, integer, integer, integer, integer),
  private.priere_ecrire_stock(uuid, timestamptz, integer, text, boolean, uuid, date),
  private.priere_recalculer_seance(uuid), private.priere_recalculer_enseignant(uuid),
  private.priere_recalculer_horizon(boolean), private.priere_trg_seance(), private.priere_trg_remplacement(),
  private.priere_trg_reglages_enseignant(), private.priere_trg_reglages_academie(),
  private.priere_trg_profil_desactive()
  FROM PUBLIC, anon, authenticated, service_role, agent_ro;

ALTER FUNCTION public.priere_recalculer_maintenant() OWNER TO postgres;
REVOKE ALL ON FUNCTION public.priere_recalculer_maintenant() FROM PUBLIC, anon, service_role, agent_ro;
GRANT EXECUTE ON FUNCTION public.priere_recalculer_maintenant() TO authenticated;

-- ===========================================================================
-- 7. Le lieu, les ajustements et l'apercu du jour
-- ===========================================================================

-- La direction pose le lieu de priere d'un enseignant (P3). Les ajustements deja
-- poses sont conserves. Journal : qui, quand, pour qui ; jamais la position.
CREATE FUNCTION public.priere_lieu_definir(
  p_enseignant_id uuid, p_lieu text, p_latitude numeric, p_longitude numeric, p_fuseau text,
  p_methode text DEFAULT NULL, p_ecole_asr text DEFAULT NULL,
  p_assiste_vendredi boolean DEFAULT false,
  p_vendredi_debut time DEFAULT '12:30', p_vendredi_fin time DEFAULT '14:30')
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $function$
BEGIN
  IF NOT coalesce(public.app_account_valid() AND public.app_role() = 'admin', false) THEN
    RAISE EXCEPTION 'lieu de priere reserve a la direction' USING ERRCODE = '42501';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM public.profiles p
                  WHERE p.id = p_enseignant_id AND p.role = 'teacher' AND p.deleted_at IS NULL) THEN
    RAISE EXCEPTION 'enseignant inconnu' USING ERRCODE = '22023';
  END IF;
  IF p_lieu IS NULL OR pg_catalog.btrim(p_lieu) = '' OR pg_catalog.length(p_lieu) > 80 THEN
    RAISE EXCEPTION 'le nom du lieu est obligatoire (80 caracteres au plus)' USING ERRCODE = '22023';
  END IF;
  IF p_latitude IS NULL OR p_latitude NOT BETWEEN -90 AND 90
     OR p_longitude IS NULL OR p_longitude NOT BETWEEN -180 AND 180 THEN
    RAISE EXCEPTION 'latitude ou longitude hors bornes' USING ERRCODE = '22023';
  END IF;
  IF p_fuseau IS NULL OR NOT app_private.fuseau_connu(p_fuseau) THEN
    RAISE EXCEPTION 'fuseau inconnu' USING ERRCODE = '22023';
  END IF;
  IF p_methode IS NOT NULL AND NOT EXISTS (SELECT 1 FROM private.priere_methode(p_methode)) THEN
    RAISE EXCEPTION 'methode de calcul inconnue' USING ERRCODE = '22023';
  END IF;
  IF p_ecole_asr IS NOT NULL AND p_ecole_asr NOT IN ('shafi', 'hanafi') THEN
    RAISE EXCEPTION 'ecole pour l''Asr inconnue' USING ERRCODE = '22023';
  END IF;
  IF p_assiste_vendredi IS NULL OR p_vendredi_debut IS NULL OR p_vendredi_fin IS NULL
     OR p_vendredi_debut >= p_vendredi_fin THEN
    RAISE EXCEPTION 'plage du vendredi invalide' USING ERRCODE = '22023';
  END IF;

  INSERT INTO public.prayer_settings AS ps
    (teacher_id, latitude, longitude, timezone_iana, place_label, methode_surcharge,
     ecole_asr_surcharge, assiste_vendredi, vendredi_debut, vendredi_fin, actif, defini_par, defini_le)
  VALUES
    (p_enseignant_id, p_latitude, p_longitude, p_fuseau, pg_catalog.btrim(p_lieu), p_methode,
     p_ecole_asr, p_assiste_vendredi, p_vendredi_debut, p_vendredi_fin, true, auth.uid(), pg_catalog.now())
  ON CONFLICT (teacher_id) DO UPDATE
    SET latitude = EXCLUDED.latitude, longitude = EXCLUDED.longitude,
        timezone_iana = EXCLUDED.timezone_iana, place_label = EXCLUDED.place_label,
        methode_surcharge = EXCLUDED.methode_surcharge,
        ecole_asr_surcharge = EXCLUDED.ecole_asr_surcharge,
        assiste_vendredi = EXCLUDED.assiste_vendredi,
        vendredi_debut = EXCLUDED.vendredi_debut, vendredi_fin = EXCLUDED.vendredi_fin,
        actif = true, defini_par = EXCLUDED.defini_par, defini_le = EXCLUDED.defini_le;

  PERFORM public.log_sensitive_access('priere_lieu_defini', 'prayer_settings', p_enseignant_id::text,
    pg_catalog.jsonb_build_object('acteur', auth.uid()));
END;
$function$;

-- La direction retire le lieu : la position est ecrasee, aucune pause de priere ensuite.
CREATE FUNCTION public.priere_lieu_retirer(p_enseignant_id uuid)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $function$
BEGIN
  IF NOT coalesce(public.app_account_valid() AND public.app_role() = 'admin', false) THEN
    RAISE EXCEPTION 'lieu de priere reserve a la direction' USING ERRCODE = '42501';
  END IF;
  UPDATE public.prayer_settings
     SET actif = false, latitude = 0, longitude = 0, place_label = NULL,
         defini_par = auth.uid(), defini_le = pg_catalog.now()
   WHERE teacher_id = p_enseignant_id;
  IF FOUND THEN
    PERFORM public.log_sensitive_access('priere_lieu_retire', 'prayer_settings', p_enseignant_id::text,
      pg_catalog.jsonb_build_object('acteur', auth.uid()));
  END IF;
END;
$function$;

-- L'enseignant ajuste une priere de -30 a +30 minutes, pour lui seulement.
CREATE FUNCTION public.priere_ajuster(p_priere text, p_minutes integer)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $function$
BEGIN
  IF NOT coalesce(public.app_account_valid() AND public.app_role() = 'teacher', false) THEN
    RAISE EXCEPTION 'ajustement reserve a l''enseignant' USING ERRCODE = '42501';
  END IF;
  IF p_priere IS NULL OR p_priere NOT IN ('fajr', 'dhuhr', 'asr', 'maghrib', 'isha') THEN
    RAISE EXCEPTION 'priere inconnue' USING ERRCODE = '22023';
  END IF;
  IF p_minutes IS NULL OR p_minutes NOT BETWEEN -30 AND 30 THEN
    RAISE EXCEPTION 'un ajustement va de -30 a +30 minutes' USING ERRCODE = '22023';
  END IF;
  UPDATE public.prayer_settings
     SET adjustments = pg_catalog.jsonb_set(adjustments, ARRAY[p_priere], pg_catalog.to_jsonb(p_minutes))
   WHERE teacher_id = auth.uid() AND actif;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'aucun lieu de priere n''est pose pour cet enseignant' USING ERRCODE = '22023';
  END IF;
END;
$function$;

-- Les reglages d'un enseignant, pour lui et pour la direction seulement.
-- `p_enseignant_id` nul : l'appelant lui-meme. Nul rendu : pas de lieu.
CREATE FUNCTION public.priere_reglages_lire(p_enseignant_id uuid DEFAULT NULL)
RETURNS jsonb
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  v_cible uuid;
  v_ligne public.prayer_settings%ROWTYPE;
  c record;
BEGIN
  IF NOT coalesce(public.app_account_valid(), false) THEN
    RAISE EXCEPTION 'reglages de priere : acces refuse' USING ERRCODE = '42501';
  END IF;
  IF public.app_role() = 'admin' THEN
    v_cible := coalesce(p_enseignant_id, auth.uid());
  ELSIF public.app_role() = 'teacher' AND (p_enseignant_id IS NULL OR p_enseignant_id = auth.uid()) THEN
    v_cible := auth.uid();
  ELSE
    RAISE EXCEPTION 'reglages de priere : acces refuse' USING ERRCODE = '42501';
  END IF;

  SELECT * INTO v_ligne FROM public.prayer_settings WHERE teacher_id = v_cible AND actif;
  IF NOT FOUND THEN
    RETURN NULL;
  END IF;
  SELECT * INTO c FROM private.priere_cfg();
  RETURN pg_catalog.jsonb_build_object(
    'enseignant_id', v_ligne.teacher_id,
    'lieu', v_ligne.place_label,
    'latitude', v_ligne.latitude,
    'longitude', v_ligne.longitude,
    'fuseau', v_ligne.timezone_iana,
    'methode', coalesce(v_ligne.methode_surcharge, c.methode),
    'ecole_asr', coalesce(v_ligne.ecole_asr_surcharge, c.ecole),
    'methode_surcharge', v_ligne.methode_surcharge,
    'ecole_asr_surcharge', v_ligne.ecole_asr_surcharge,
    'ajustements', v_ligne.adjustments,
    'assiste_vendredi', v_ligne.assiste_vendredi,
    'vendredi_debut', pg_catalog.to_char(v_ligne.vendredi_debut, 'HH24:MI'),
    'vendredi_fin', pg_catalog.to_char(v_ligne.vendredi_fin, 'HH24:MI'));
END;
$function$;

-- Les cinq heures du jour local de l'enseignant (instants UTC ; l'ecran les met
-- dans le fuseau de la personne). Enseignant lui-meme et direction seulement.
CREATE FUNCTION public.priere_horaires_jour(p_enseignant_id uuid DEFAULT NULL, p_jour date DEFAULT NULL)
RETURNS TABLE (priere text, instant_utc timestamptz, approximee boolean, fuseau text)
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  v_cible uuid;
  rg record;
  v_jour date;
BEGIN
  IF NOT coalesce(public.app_account_valid(), false) THEN
    RAISE EXCEPTION 'heures de priere : acces refuse' USING ERRCODE = '42501';
  END IF;
  IF public.app_role() = 'admin' THEN
    v_cible := coalesce(p_enseignant_id, auth.uid());
  ELSIF public.app_role() = 'teacher' AND (p_enseignant_id IS NULL OR p_enseignant_id = auth.uid()) THEN
    v_cible := auth.uid();
  ELSE
    RAISE EXCEPTION 'heures de priere : acces refuse' USING ERRCODE = '42501';
  END IF;

  SELECT * INTO rg FROM private.priere_reglages(v_cible);
  IF NOT FOUND THEN
    RETURN;
  END IF;
  v_jour := coalesce(p_jour, (pg_catalog.now() AT TIME ZONE rg.fuseau)::date);

  RETURN QUERY
    SELECT c.priere, c.instant_utc, c.approximee, rg.fuseau
      FROM pg_catalog.generate_series(-1, 1) AS j(k),
           LATERAL private.priere_calculer(rg.lat, rg.lon, v_jour + j.k, rg.methode, rg.ecole,
                                           rg.ajustements) c
     WHERE (c.instant_utc AT TIME ZONE rg.fuseau)::date = v_jour
     ORDER BY c.instant_utc;
END;
$function$;

-- ===========================================================================
-- 8. Les lectures de la direction : le schema stable des horaires (P8, P9)
-- ===========================================================================

-- Les seances d'un creneau hebdomadaire sur les 12 mois a venir. L'heure locale
-- de la classe est fixe : l'instant UTC bouge au changement d'heure, et c'est
-- lui qu'on compare aux heures de priere.
CREATE FUNCTION private.priere_occurrences(p_weekday integer, p_hour integer, p_tz text)
RETURNS TABLE (jour_local date, debut_utc timestamptz)
LANGUAGE sql
STABLE
SET search_path = ''
AS $$
  SELECT d.jour,
         ((d.jour::timestamp + pg_catalog.make_interval(hours => p_hour)) AT TIME ZONE p_tz)
    FROM (SELECT (pg_catalog.date_trunc('week', pg_catalog.now() AT TIME ZONE p_tz)::date
                  + (p_weekday - 1) + 7 * i) AS jour
            FROM pg_catalog.generate_series(0, 53) AS g(i)) d
   WHERE ((d.jour::timestamp + pg_catalog.make_interval(hours => p_hour)) AT TIME ZONE p_tz) >= pg_catalog.now()
     AND ((d.jour::timestamp + pg_catalog.make_interval(hours => p_hour)) AT TIME ZONE p_tz)
         < pg_catalog.now() + pg_catalog.make_interval(days => 365)
$$;

-- Les heures de debut (dans le fuseau de la classe) classees sur les 12 mois :
-- `libres` = aucune priere n'entre pendant le cours ET aucune priere ne s'y ferme
-- (celle entree moins de `marge_avant` minutes avant le debut dont le temps se ferme
-- avant la fin) ; `fermeture` = au moins une seance dont une priere se ferme pendant
-- le cours (a deconseiller : l'enseignant n'a que la pause pour prier). NULL, NULL :
-- pas de lieu, ou calcul indefini.
CREATE FUNCTION private.priere_heures_classees(
  p_enseignant uuid, p_weekday integer, p_tz text, p_duree integer)
RETURNS TABLE (libres integer[], fermeture integer[])
LANGUAGE plpgsql
STABLE
SET search_path = ''
AS $function$
DECLARE
  rg record;
  cfg record;
  v_base date := pg_catalog.date_trunc('week', pg_catalog.now() AT TIME ZONE p_tz)::date + (p_weekday - 1);
  v_incomplet boolean;
BEGIN
  SELECT * INTO rg FROM private.priere_reglages(p_enseignant);
  IF NOT FOUND THEN
    RETURN;
  END IF;
  SELECT * INTO cfg FROM private.priere_cfg();

  SELECT pg_catalog.bool_or(n < 15) INTO v_incomplet
    FROM (SELECT (SELECT pg_catalog.count(*)
                    FROM pg_catalog.generate_series(-1, 1) AS j(k),
                         LATERAL private.priere_calculer(rg.lat, rg.lon, v_base + 7 * s.i + j.k,
                                                         rg.methode, rg.ecole, rg.ajustements)) AS n
            FROM pg_catalog.generate_series(0, 53) AS s(i)) q;
  IF coalesce(v_incomplet, true) THEN
    RETURN;
  END IF;

  RETURN QUERY
  WITH sem AS (
    SELECT s.i, v_base + 7 * s.i AS jour FROM pg_catalog.generate_series(0, 53) AS s(i)
  ), pr0 AS (
    SELECT sem.i, c.priere, c.instant_utc, sem.jour + j.k AS jour_pr
      FROM sem CROSS JOIN pg_catalog.generate_series(-1, 1) AS j(k)
      CROSS JOIN LATERAL private.priere_calculer(rg.lat, rg.lon, sem.jour + j.k,
                                                 rg.methode, rg.ecole, rg.ajustements) c
  ), pr AS (
    SELECT pr0.i, pr0.instant_utc,
           CASE WHEN pr0.priere = 'fajr'
                THEN private.priere_lever(rg.lat, rg.lon, pr0.jour_pr, rg.methode)
                ELSE pg_catalog.lead(pr0.instant_utc) OVER (PARTITION BY pr0.i ORDER BY pr0.instant_utc)
           END AS ferme_utc
      FROM pr0
  ), occ AS (
    SELECT sem.i, h.h,
           ((sem.jour::timestamp + pg_catalog.make_interval(hours => h.h)) AT TIME ZONE p_tz) AS debut
      FROM sem CROSS JOIN pg_catalog.generate_series(0, 23) AS h(h)
  ), occ_an AS (
    SELECT * FROM occ
     WHERE debut >= pg_catalog.now() AND debut < pg_catalog.now() + pg_catalog.make_interval(days => 365)
  ), heures AS (
    SELECT h.h,
           EXISTS (SELECT 1 FROM occ_an o JOIN pr ON pr.i = o.i
                    WHERE o.h = h.h AND pr.instant_utc >= o.debut
                      AND pr.instant_utc < o.debut + pg_catalog.make_interval(mins => p_duree)) AS entre,
           EXISTS (SELECT 1 FROM occ_an o JOIN pr ON pr.i = o.i
                    WHERE o.h = h.h AND pr.instant_utc < o.debut
                      AND o.debut - pr.instant_utc < pg_catalog.make_interval(mins => cfg.marge_avant)
                      AND pr.ferme_utc > o.debut
                      AND pr.ferme_utc < o.debut + pg_catalog.make_interval(mins => p_duree)) AS ferme
      FROM pg_catalog.generate_series(0, 23) AS h(h)
  )
  SELECT coalesce(pg_catalog.array_agg(heures.h ORDER BY heures.h) FILTER (WHERE NOT heures.entre AND NOT heures.ferme),
                  '{}'::integer[]),
         coalesce(pg_catalog.array_agg(heures.h ORDER BY heures.h) FILTER (WHERE heures.ferme),
                  '{}'::integer[])
    FROM heures;
END;
$function$;

-- Les heures sans priere (compatibilite de lecture : le premier tableau).
CREATE FUNCTION private.priere_heures_sans_priere(
  p_enseignant uuid, p_weekday integer, p_tz text, p_duree integer)
RETURNS integer[]
LANGUAGE sql
STABLE
SET search_path = ''
AS $$
  SELECT (SELECT c.libres FROM private.priere_heures_classees(p_enseignant, p_weekday, p_tz, p_duree) c)
$$;

-- Une ligne par priere qui croise une seance du creneau, sur 12 mois, avec sa
-- zone et la priere retenue ; une ligne `aucune` par seance sans croisement ; une
-- ligne `indefini` par seance dont le calcul n'existe pas.
CREATE FUNCTION private.priere_projection(
  p_enseignant uuid, p_weekday integer, p_hour integer, p_tz text, p_duree integer)
RETURNS TABLE (jour_local date, priere text, zone text, retenue boolean, indefini boolean)
LANGUAGE plpgsql
STABLE
SET search_path = ''
AS $function$
DECLARE
  rg record;
  cfg record;
  o record;
  r record;
  v_n integer;
BEGIN
  SELECT * INTO rg FROM private.priere_reglages(p_enseignant);
  IF NOT FOUND THEN
    RETURN;
  END IF;
  SELECT * INTO cfg FROM private.priere_cfg();
  FOR o IN SELECT * FROM private.priere_occurrences(p_weekday, p_hour, p_tz) LOOP
    v_n := 0;
    FOR r IN
      SELECT * FROM private.priere_placer(o.debut_utc, o.debut_utc + pg_catalog.make_interval(mins => p_duree),
        rg.lat, rg.lon, rg.methode, rg.ecole, rg.ajustements, cfg.pause, cfg.pause_ramadan, cfg.ramadan,
        cfg.marge_debut, cfg.marge_fin, cfg.marge_avant, cfg.delai_fermeture)
    LOOP
      v_n := v_n + 1;
      jour_local := o.jour_local; priere := r.priere; zone := CASE WHEN r.indefini THEN 'indefini' ELSE r.zone END;
      retenue := r.retenue; indefini := r.indefini;
      RETURN NEXT;
    END LOOP;
    IF v_n = 0 THEN
      jour_local := o.jour_local; priere := NULL; zone := 'aucune'; retenue := false; indefini := false;
      RETURN NEXT;
    END IF;
  END LOOP;
END;
$function$;

-- Ce que la direction lit sur un creneau : croisements (periodes, nombre de
-- seances, pause placee ou priere apres le cours), vendredi, heures sans priere.
-- Un AVERTISSEMENT, jamais un blocage (P8, P9).
CREATE FUNCTION private.priere_lecture_creneau(
  p_enseignant uuid, p_weekday integer, p_hour integer, p_tz text, p_duree integer)
RETURNS jsonb
LANGUAGE plpgsql
STABLE
SET search_path = ''
AS $function$
DECLARE
  rg record;
  v_croisements jsonb;
  v_seances integer;
  v_indefini integer;
  v_vendredi integer;
  v_libres integer[];
  v_fermeture integer[];
BEGIN
  SELECT * INTO rg FROM private.priere_reglages(p_enseignant);
  IF NOT FOUND THEN
    RETURN pg_catalog.jsonb_build_object('sans_lieu', true);
  END IF;

  WITH proj AS (
    SELECT * FROM private.priere_projection(p_enseignant, p_weekday, p_hour, p_tz, p_duree)
  ), croise AS (
    SELECT priere, jour_local, retenue, zone,
           ((jour_local - DATE '2026-01-05') / 7) AS semaine
      FROM proj WHERE priere IS NOT NULL
  ), serie AS (
    SELECT priere, jour_local, retenue, zone,
           semaine - pg_catalog.dense_rank() OVER (PARTITION BY priere ORDER BY semaine) AS groupe
      FROM croise
  ), periodes AS (
    SELECT priere, groupe,
           pg_catalog.min(jour_local) AS du, pg_catalog.max(jour_local) AS au,
           pg_catalog.count(*) AS nb_seances,
           pg_catalog.count(*) FILTER (WHERE retenue) AS nb_pause,
           pg_catalog.count(*) FILTER (WHERE NOT retenue) AS nb_apres_cours
      FROM serie GROUP BY priere, groupe
  )
  SELECT coalesce(pg_catalog.jsonb_agg(pg_catalog.jsonb_build_object(
           'priere', priere, 'du', du, 'au', au, 'nb_seances', nb_seances,
           'nb_pause', nb_pause, 'nb_apres_cours', nb_apres_cours) ORDER BY du, priere), '[]'::jsonb),
         (SELECT pg_catalog.count(DISTINCT jour_local) FROM proj),
         (SELECT pg_catalog.count(DISTINCT jour_local) FROM proj WHERE indefini)
    INTO v_croisements, v_seances, v_indefini
    FROM periodes;

  -- Les seances que le projection ignore (aucune ligne) ne comptent pas : le
  -- nombre de seances est celui des occurrences du creneau sur les 12 mois.
  SELECT pg_catalog.count(*) INTO v_seances
    FROM private.priere_occurrences(p_weekday, p_hour, p_tz);

  SELECT pg_catalog.count(*) INTO v_vendredi
    FROM private.priere_occurrences(p_weekday, p_hour, p_tz) o,
         LATERAL (SELECT o.debut_utc AT TIME ZONE rg.fuseau AS ls,
                         (o.debut_utc + pg_catalog.make_interval(mins => p_duree)) AT TIME ZONE rg.fuseau AS le) l
   WHERE rg.assiste_vendredi
     AND pg_catalog.date_part('isodow', l.ls) = 5
     AND l.ls < l.ls::date + rg.vendredi_fin
     AND l.le > l.ls::date + rg.vendredi_debut;

  SELECT c.libres, c.fermeture INTO v_libres, v_fermeture
    FROM private.priere_heures_classees(p_enseignant, p_weekday, p_tz, p_duree) c;

  RETURN pg_catalog.jsonb_build_object(
    'sans_lieu', false,
    'indefini', v_indefini > 0,
    'seances', v_seances,
    'croisements', v_croisements,
    'vendredi', pg_catalog.jsonb_build_object(
      'assiste', rg.assiste_vendredi, 'nb_seances', v_vendredi,
      'debut', pg_catalog.to_char(rg.vendredi_debut, 'HH24:MI'),
      'fin', pg_catalog.to_char(rg.vendredi_fin, 'HH24:MI')),
    'heures_sans_priere', CASE WHEN v_libres IS NULL THEN NULL ELSE pg_catalog.to_jsonb(v_libres) END,
    'heures_fermeture', CASE WHEN v_fermeture IS NULL THEN NULL ELSE pg_catalog.to_jsonb(v_fermeture) END);
END;
$function$;

-- La direction : un creneau et un enseignant.
CREATE FUNCTION public.priere_lecture_creneau(
  p_enseignant_id uuid, p_weekday integer, p_hour_local integer, p_timezone text, p_duree_minutes integer)
RETURNS jsonb
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $function$
BEGIN
  IF NOT coalesce(public.app_account_valid() AND public.app_role() = 'admin', false) THEN
    RAISE EXCEPTION 'lecture reservee a la direction' USING ERRCODE = '42501';
  END IF;
  IF p_weekday IS NULL OR p_weekday NOT BETWEEN 1 AND 7
     OR p_hour_local IS NULL OR p_hour_local NOT BETWEEN 0 AND 23
     OR p_duree_minutes IS NULL OR p_duree_minutes NOT BETWEEN 15 AND 240
     OR p_timezone IS NULL OR NOT app_private.fuseau_connu(p_timezone) THEN
    RAISE EXCEPTION 'creneau invalide' USING ERRCODE = '22023';
  END IF;
  RETURN private.priere_lecture_creneau(p_enseignant_id, p_weekday, p_hour_local, p_timezone, p_duree_minutes);
END;
$function$;

-- La direction : les heures de debut sans priere d'un jour de la semaine.
CREATE FUNCTION public.priere_creneaux_sans_priere(
  p_enseignant_id uuid, p_weekday integer, p_timezone text, p_duree_minutes integer)
RETURNS integer[]
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $function$
BEGIN
  IF NOT coalesce(public.app_account_valid() AND public.app_role() = 'admin', false) THEN
    RAISE EXCEPTION 'lecture reservee a la direction' USING ERRCODE = '42501';
  END IF;
  IF p_weekday IS NULL OR p_weekday NOT BETWEEN 1 AND 7
     OR p_duree_minutes IS NULL OR p_duree_minutes NOT BETWEEN 15 AND 240
     OR p_timezone IS NULL OR NOT app_private.fuseau_connu(p_timezone) THEN
    RAISE EXCEPTION 'creneau invalide' USING ERRCODE = '22023';
  END IF;
  RETURN private.priere_heures_sans_priere(p_enseignant_id, p_weekday, p_timezone, p_duree_minutes);
END;
$function$;

-- La direction : les heures de debut d'un jour de la semaine ou, au moins une fois
-- sur les 12 mois, une priere se ferme pendant le cours (a deconseiller : l'enseignant
-- n'a que la pause pour prier ; sert la creation de classe, lot FC-3).
CREATE FUNCTION public.priere_creneaux_fermeture(
  p_enseignant_id uuid, p_weekday integer, p_timezone text, p_duree_minutes integer)
RETURNS integer[]
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $function$
BEGIN
  IF NOT coalesce(public.app_account_valid() AND public.app_role() = 'admin', false) THEN
    RAISE EXCEPTION 'lecture reservee a la direction' USING ERRCODE = '42501';
  END IF;
  IF p_weekday IS NULL OR p_weekday NOT BETWEEN 1 AND 7
     OR p_duree_minutes IS NULL OR p_duree_minutes NOT BETWEEN 15 AND 240
     OR p_timezone IS NULL OR NOT app_private.fuseau_connu(p_timezone) THEN
    RAISE EXCEPTION 'creneau invalide' USING ERRCODE = '22023';
  END IF;
  RETURN (SELECT c.fermeture
            FROM private.priere_heures_classees(p_enseignant_id, p_weekday, p_timezone, p_duree_minutes) c);
END;
$function$;

-- La direction : le bloc « Prieres et creneau » d'une classe (un element par
-- creneau de la classe). La duree est celle de la prochaine seance, sinon celle
-- du reglage de l'academie pour ce public.
CREATE FUNCTION public.priere_lecture_classe(p_groupe_id uuid)
RETURNS jsonb
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  g record;
  v_duree integer;
  v_creneaux jsonb;
BEGIN
  IF NOT coalesce(public.app_account_valid() AND public.app_role() = 'admin', false) THEN
    RAISE EXCEPTION 'lecture reservee a la direction' USING ERRCODE = '42501';
  END IF;
  SELECT gr.id, gr.teacher_id, gr.weekday, gr.hour_local, gr.timezone_iana, gr.type_public
    INTO g FROM public.groupes gr WHERE gr.id = p_groupe_id;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'classe inconnue' USING ERRCODE = '22023';
  END IF;

  SELECT (pg_catalog.date_part('epoch', s.ended_at - s.started_at) / 60)::integer INTO v_duree
    FROM public.sessions s
   WHERE s.groupe_id = p_groupe_id AND s.deleted_at IS NULL AND s.started_at > pg_catalog.now()
   ORDER BY s.started_at LIMIT 1;
  IF v_duree IS NULL THEN
    SELECT (a.value #>> '{}')::integer INTO v_duree FROM public.app_config a
     WHERE a.key = CASE WHEN g.type_public = 'adulte' THEN 'seance.duree_minutes_adulte'
                        ELSE 'seance.duree_minutes_enfant' END;
  END IF;
  v_duree := coalesce(v_duree, CASE WHEN g.type_public = 'adulte' THEN 90 ELSE 60 END);

  -- La duree de chaque creneau est la sienne (groupe_creneaux.duree_minutes), a defaut celle
  -- de la classe ; l'ancre de la classe (groupes.weekday/hour_local) prend la duree de la classe.
  SELECT coalesce(pg_catalog.jsonb_agg(pg_catalog.jsonb_build_object(
           'weekday', c.weekday, 'hour_local', c.hour_local, 'timezone', g.timezone_iana,
           'duree_minutes', c.duree,
           'lecture', private.priere_lecture_creneau(g.teacher_id, c.weekday, c.hour_local,
                                                     g.timezone_iana, c.duree)) ORDER BY c.weekday, c.hour_local),
         '[]'::jsonb)
    INTO v_creneaux
    FROM (SELECT gc.weekday::integer AS weekday, gc.hour_local::integer AS hour_local,
                 coalesce(gc.duree_minutes, v_duree)::integer AS duree
            FROM public.groupe_creneaux gc WHERE gc.groupe_id = p_groupe_id
           UNION ALL
          SELECT g.weekday::integer, g.hour_local::integer, v_duree
           WHERE NOT EXISTS (SELECT 1 FROM public.groupe_creneaux gc
                              WHERE gc.groupe_id = p_groupe_id
                                AND gc.weekday = g.weekday AND gc.hour_local = g.hour_local)) c;

  RETURN pg_catalog.jsonb_build_object('enseignant_id', g.teacher_id, 'creneaux', v_creneaux);
END;
$function$;

-- La direction : les enseignants dont le fuseau du compte, le pays du compte et le
-- lieu de priere ne concordent pas. Un signalement : rien n'est corrige tout seul.
-- Le controle du pays est un controle de vraisemblance (boites englobantes de
-- quelques pays) : un pays que la table ne connait pas ne produit aucun signal.
CREATE FUNCTION public.priere_incoherences_enseignants()
RETURNS TABLE (enseignant_id uuid, prenom text, motif text, detail text)
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $function$
BEGIN
  IF NOT coalesce(public.app_account_valid() AND public.app_role() = 'admin', false) THEN
    RAISE EXCEPTION 'lecture reservee a la direction' USING ERRCODE = '42501';
  END IF;

  RETURN QUERY
  WITH base AS (
    SELECT ps.teacher_id, p.first_name, ps.latitude::double precision AS lat,
           ps.longitude::double precision AS lon, ps.timezone_iana AS tz_lieu,
           tp.timezone_iana AS tz_compte,
           CASE WHEN pg_catalog.length(pg_catalog.btrim(tp.country)) = 2
                  THEN pg_catalog.upper(pg_catalog.btrim(tp.country))
                ELSE (SELECT n.code FROM (VALUES
                        ('guinee', 'GN'), ('guinée', 'GN'), ('senegal', 'SN'), ('sénégal', 'SN'),
                        ('france', 'FR'), ('maroc', 'MA'), ('algerie', 'DZ'), ('algérie', 'DZ'),
                        ('tunisie', 'TN'), ('egypte', 'EG'), ('égypte', 'EG'), ('mali', 'ML'),
                        ('mauritanie', 'MR'), ('cote d''ivoire', 'CI'), ('côte d''ivoire', 'CI'),
                        ('arabie saoudite', 'SA'), ('royaume-uni', 'GB'), ('belgique', 'BE'),
                        ('canada', 'CA'), ('suisse', 'CH'), ('allemagne', 'DE'), ('gambie', 'GM'),
                        ('burkina faso', 'BF'), ('niger', 'NE'), ('etats-unis', 'US'), ('états-unis', 'US'))
                        AS n(nom, code)
                       WHERE n.nom = pg_catalog.lower(pg_catalog.btrim(tp.country))) END AS pays
      FROM public.prayer_settings ps
      JOIN public.profiles p ON p.id = ps.teacher_id AND p.deleted_at IS NULL
      LEFT JOIN public.teacher_profiles tp ON tp.profile_id = ps.teacher_id
     WHERE ps.actif
  ), comptes AS (
    SELECT tp.profile_id, p.first_name, tp.timezone_iana AS tz_compte,
           CASE WHEN pg_catalog.length(pg_catalog.btrim(tp.country)) = 2
                  THEN pg_catalog.upper(pg_catalog.btrim(tp.country))
                ELSE (SELECT n.code FROM (VALUES
                        ('guinee', 'GN'), ('guinée', 'GN'), ('senegal', 'SN'), ('sénégal', 'SN'),
                        ('france', 'FR'), ('maroc', 'MA'), ('algerie', 'DZ'), ('algérie', 'DZ'),
                        ('tunisie', 'TN'), ('egypte', 'EG'), ('égypte', 'EG'), ('mali', 'ML'),
                        ('mauritanie', 'MR'), ('cote d''ivoire', 'CI'), ('côte d''ivoire', 'CI'),
                        ('arabie saoudite', 'SA'), ('royaume-uni', 'GB'), ('belgique', 'BE'),
                        ('canada', 'CA'), ('suisse', 'CH'), ('allemagne', 'DE'), ('gambie', 'GM'),
                        ('burkina faso', 'BF'), ('niger', 'NE'), ('etats-unis', 'US'), ('états-unis', 'US'))
                        AS n(nom, code)
                       WHERE n.nom = pg_catalog.lower(pg_catalog.btrim(tp.country))) END AS pays
      FROM public.teacher_profiles tp
      JOIN public.profiles p ON p.id = tp.profile_id AND p.deleted_at IS NULL
     WHERE p.role = 'teacher' AND tp.timezone_iana IS NOT NULL
  ), boites(code, lat_min, lat_max, lon_min, lon_max) AS (VALUES
    ('GN', 7.19, 12.68, -15.08, -7.64), ('SN', 12.30, 16.69, -17.54, -11.35),
    ('FR', 41.30, 51.15, -5.15, 9.56), ('MA', 27.60, 35.93, -13.20, -0.99),
    ('DZ', 18.96, 37.10, -8.68, 11.99), ('TN', 30.23, 37.35, 7.52, 11.60),
    ('EG', 21.99, 31.67, 24.70, 36.90), ('ML', 10.14, 24.99, -12.25, 4.25),
    ('MR', 14.72, 27.30, -17.07, -4.83), ('CI', 4.36, 10.74, -8.60, -2.49),
    ('SA', 16.35, 32.16, 34.50, 55.67), ('GB', 49.86, 60.86, -8.65, 1.77),
    ('BE', 49.50, 51.50, 2.55, 6.41), ('CA', 41.68, 83.11, -141.0, -52.6),
    ('CH', 45.82, 47.81, 5.96, 10.49), ('DE', 47.27, 55.06, 5.87, 15.04),
    ('GM', 13.06, 13.83, -16.83, -13.80), ('BF', 9.40, 15.08, -5.52, 2.40),
    ('NE', 11.69, 23.52, 0.17, 15.99), ('US', 24.50, 49.40, -125.0, -66.9))
  SELECT b.teacher_id, b.first_name, 'fuseau_compte_different'::text,
         b.tz_compte || ' / ' || b.tz_lieu
    FROM base b
   WHERE b.tz_compte IS NOT NULL AND b.tz_compte <> b.tz_lieu
  UNION ALL
  SELECT b.teacher_id, b.first_name, 'fuseau_lieu_incoherent'::text,
         b.tz_lieu || ' / longitude ' || pg_catalog.round(b.lon::numeric, 1)::text
    FROM base b
   WHERE pg_catalog.abs(
           LEAST(
             pg_catalog.date_part('epoch', (TIMESTAMP '2027-01-15 12:00')
               - ((TIMESTAMP '2027-01-15 12:00' AT TIME ZONE b.tz_lieu) AT TIME ZONE 'UTC')) / 3600.0,
             pg_catalog.date_part('epoch', (TIMESTAMP '2027-07-15 12:00')
               - ((TIMESTAMP '2027-07-15 12:00' AT TIME ZONE b.tz_lieu) AT TIME ZONE 'UTC')) / 3600.0)
           - b.lon / 15.0) > 3
  UNION ALL
  SELECT b.teacher_id, b.first_name, 'pays_lieu_incoherent'::text, b.pays
    FROM base b JOIN boites x ON x.code = b.pays
   WHERE NOT (b.lat BETWEEN x.lat_min AND x.lat_max AND b.lon BETWEEN x.lon_min AND x.lon_max)
  UNION ALL
  -- Le pays et le fuseau du compte, meme sans lieu de priere pose : c'est le cas
  -- releve en production (pays Guinee, fuseau Europe/Paris). Seuls les pays qui
  -- tiennent dans une bande de 30 degres de longitude sont juges.
  SELECT c.profile_id, c.first_name, 'pays_fuseau_incoherent'::text,
         c.pays || ' / ' || c.tz_compte
    FROM comptes c JOIN boites x ON x.code = c.pays
   WHERE x.lon_max - x.lon_min <= 30
     AND pg_catalog.abs(
           LEAST(
             pg_catalog.date_part('epoch', (TIMESTAMP '2027-01-15 12:00')
               - ((TIMESTAMP '2027-01-15 12:00' AT TIME ZONE c.tz_compte) AT TIME ZONE 'UTC')) / 3600.0,
             pg_catalog.date_part('epoch', (TIMESTAMP '2027-07-15 12:00')
               - ((TIMESTAMP '2027-07-15 12:00' AT TIME ZONE c.tz_compte) AT TIME ZONE 'UTC')) / 3600.0)
           - ((x.lon_min + x.lon_max) / 2) / 15.0) > 1.5;
END;
$function$;

-- La direction : les enseignants et l'etat de leur lieu de priere (pour l'ecran
-- « Lieux de priere »). Un enseignant sans lieu y figure : c'est ce qu'il faut voir.
CREATE FUNCTION public.priere_enseignants_liste()
RETURNS TABLE (enseignant_id uuid, prenom text, lieu text, fuseau text,
               assiste_vendredi boolean, a_un_lieu boolean)
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $function$
BEGIN
  IF NOT coalesce(public.app_account_valid() AND public.app_role() = 'admin', false) THEN
    RAISE EXCEPTION 'lecture reservee a la direction' USING ERRCODE = '42501';
  END IF;
  RETURN QUERY
    SELECT p.id, p.first_name,
           CASE WHEN ps.actif THEN ps.place_label END,
           CASE WHEN ps.actif THEN ps.timezone_iana END,
           coalesce(ps.actif AND ps.assiste_vendredi, false),
           coalesce(ps.actif, false)
      FROM public.profiles p
      LEFT JOIN public.prayer_settings ps ON ps.teacher_id = p.id
     WHERE p.role = 'teacher' AND p.deleted_at IS NULL
       AND p.account_status IN ('active', 'provisional_active')
     ORDER BY p.first_name, p.id;
END;
$function$;

-- ===========================================================================
-- 9. Droits
-- ===========================================================================
ALTER FUNCTION public.priere_lieu_definir(uuid, text, numeric, numeric, text, text, text, boolean, time, time) OWNER TO postgres;
ALTER FUNCTION public.priere_lieu_retirer(uuid) OWNER TO postgres;
ALTER FUNCTION public.priere_ajuster(text, integer) OWNER TO postgres;
ALTER FUNCTION public.priere_reglages_lire(uuid) OWNER TO postgres;
ALTER FUNCTION public.priere_horaires_jour(uuid, date) OWNER TO postgres;
ALTER FUNCTION public.priere_lecture_creneau(uuid, integer, integer, text, integer) OWNER TO postgres;
ALTER FUNCTION public.priere_creneaux_sans_priere(uuid, integer, text, integer) OWNER TO postgres;
ALTER FUNCTION public.priere_creneaux_fermeture(uuid, integer, text, integer) OWNER TO postgres;
ALTER FUNCTION public.priere_lecture_classe(uuid) OWNER TO postgres;
ALTER FUNCTION public.priere_incoherences_enseignants() OWNER TO postgres;
ALTER FUNCTION public.priere_enseignants_liste() OWNER TO postgres;

REVOKE ALL ON FUNCTION
  public.priere_lieu_definir(uuid, text, numeric, numeric, text, text, text, boolean, time, time),
  public.priere_lieu_retirer(uuid), public.priere_ajuster(text, integer),
  public.priere_reglages_lire(uuid), public.priere_horaires_jour(uuid, date),
  public.priere_lecture_creneau(uuid, integer, integer, text, integer),
  public.priere_creneaux_sans_priere(uuid, integer, text, integer),
  public.priere_creneaux_fermeture(uuid, integer, text, integer),
  public.priere_lecture_classe(uuid), public.priere_incoherences_enseignants(),
  public.priere_enseignants_liste()
  FROM PUBLIC, anon, service_role, agent_ro;
GRANT EXECUTE ON FUNCTION
  public.priere_lieu_definir(uuid, text, numeric, numeric, text, text, text, boolean, time, time),
  public.priere_lieu_retirer(uuid), public.priere_ajuster(text, integer),
  public.priere_reglages_lire(uuid), public.priere_horaires_jour(uuid, date),
  public.priere_lecture_creneau(uuid, integer, integer, text, integer),
  public.priere_creneaux_sans_priere(uuid, integer, text, integer),
  public.priere_creneaux_fermeture(uuid, integer, text, integer),
  public.priere_lecture_classe(uuid), public.priere_incoherences_enseignants(),
  public.priere_enseignants_liste()
  TO authenticated;

REVOKE ALL ON FUNCTION
  private.priere_occurrences(integer, integer, text),
  private.priere_heures_sans_priere(uuid, integer, text, integer),
  private.priere_heures_classees(uuid, integer, text, integer),
  private.priere_projection(uuid, integer, integer, text, integer),
  private.priere_lecture_creneau(uuid, integer, integer, text, integer)
  FROM PUBLIC, anon, authenticated, service_role, agent_ro;

-- ===========================================================================
-- 10. Controle final : portes fermees, aucun droit direct, fonctions durcies
-- ===========================================================================
DO $postflight$
DECLARE
  v_oid regprocedure;
BEGIN
  FOREACH v_oid IN ARRAY ARRAY[
    'public.pause_prevue_seance(uuid)'::regprocedure,
    'public.priere_lieu_definir(uuid, text, numeric, numeric, text, text, text, boolean, time, time)'::regprocedure,
    'public.priere_lieu_retirer(uuid)'::regprocedure,
    'public.priere_ajuster(text, integer)'::regprocedure,
    'public.priere_reglages_lire(uuid)'::regprocedure,
    'public.priere_horaires_jour(uuid, date)'::regprocedure,
    'public.priere_lecture_creneau(uuid, integer, integer, text, integer)'::regprocedure,
    'public.priere_creneaux_sans_priere(uuid, integer, text, integer)'::regprocedure,
    'public.priere_creneaux_fermeture(uuid, integer, text, integer)'::regprocedure,
    'public.priere_lecture_classe(uuid)'::regprocedure,
    'public.priere_incoherences_enseignants()'::regprocedure,
    'public.priere_enseignants_liste()'::regprocedure,
    'public.priere_recalculer_maintenant()'::regprocedure] LOOP
    IF NOT EXISTS (SELECT 1 FROM pg_catalog.pg_proc p
                    WHERE p.oid = v_oid AND p.prosecdef
                      AND 'search_path=""' = ANY (coalesce(p.proconfig, ARRAY[]::text[])))
       OR pg_catalog.has_function_privilege('anon', v_oid, 'EXECUTE')
       OR pg_catalog.has_function_privilege('public', v_oid, 'EXECUTE')
       OR NOT pg_catalog.has_function_privilege('authenticated', v_oid, 'EXECUTE') THEN
      RAISE EXCEPTION 'PRIERE-1 : fonction % mal durcie', v_oid::text;
    END IF;
  END LOOP;

  IF pg_catalog.has_table_privilege('authenticated', 'public.seance_pause_prevue_stock', 'SELECT')
     OR pg_catalog.has_table_privilege('authenticated', 'public.seance_pause_prevue', 'SELECT')
     OR pg_catalog.has_table_privilege('anon', 'public.seance_pause_prevue', 'SELECT')
     OR pg_catalog.has_table_privilege('authenticated', 'public.prayer_settings', 'UPDATE')
     OR pg_catalog.has_table_privilege('authenticated', 'public.prayer_settings', 'INSERT') THEN
    RAISE EXCEPTION 'PRIERE-1 : un droit direct reste ouvert';
  END IF;

  -- Le contrat de la salle : proprietaire postgres, vue sans security_invoker,
  -- aucun droit pour personne d'autre que le proprietaire.
  IF EXISTS (SELECT 1
               FROM pg_catalog.pg_class c
               JOIN pg_catalog.pg_namespace n ON n.oid = c.relnamespace
              WHERE n.nspname = 'public'
                AND c.relname IN ('seance_pause_prevue', 'seance_pause_prevue_stock')
                AND (pg_catalog.pg_get_userbyid(c.relowner) <> 'postgres'
                     OR EXISTS (SELECT 1
                                  FROM pg_catalog.aclexplode(c.relacl) a
                                 WHERE a.grantee <> c.relowner)
                     OR (c.relkind = 'v'
                         AND 'security_invoker=true' = ANY (coalesce(c.reloptions, ARRAY[]::text[]))))) THEN
    RAISE EXCEPTION 'PRIERE-1 : proprietaire ou droits de la vue du contrat inattendus';
  END IF;
END;
$postflight$;
