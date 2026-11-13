-- PRIERE-2 (13/11/2026) : la priere sans formulaire.
-- Retour du directeur : « Je ne vais jamais remplir ces formulaires moches et anciens. Si
-- l'app ne peut pas calculer elle-meme tout ca alors a toi de regler cela. » Arbitrage de
-- l'architecte pedagogique : l'application calcule tout ; la direction lit et, rarement,
-- corrige une exception. Decision : docs/current/pedagogie/PRIERE.md (amendement de P3).
-- Ne modifie PAS 20261123930000 (installee) : tout passe par CREATE OR REPLACE ou par ajout.
--
-- Ce fichier ne contient aucun des trois mots que le serveur Supabase fait confirmer une
-- seconde fois (effacement de ligne, suppression d'objet, vidage de table).
--
--   1. le reglage `priere.methode_selon_pays` (vrai) et son validateur ;
--   2. la source du lieu (`prayer_settings.lieu_source`) : direction, enseignant, auto ;
--   3. la methode usuelle du pays, deduite du fuseau du lieu, jamais saisie ;
--   4. `priere_lieu_definir` marque le lieu « direction » ;
--   5. `priere_ma_position` : l'enseignant partage sa position, arrondie au centieme de degre ;
--   6. `private.priere_lieu_auto` : le lieu pose depuis la ville (lot HORLOGE-ET-LIEU) ;
--   7. `priere_reglages_lire` rend la methode appliquee et son origine ;
--   8. `priere_enseignants_vue` : la liste a lire de la direction ;
--   9. droits et controle final.
--
-- Sans BEGIN ni COMMIT de premier niveau.

-- ===========================================================================
-- 1. Le reglage « methode selon le pays »
-- ===========================================================================
CREATE OR REPLACE FUNCTION private.priere_reglages_valider()
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
    WHEN 'priere.methode_selon_pays' THEN
      IF pg_catalog.jsonb_typeof(NEW.value) <> 'boolean' THEN
        RAISE EXCEPTION 'priere.methode_selon_pays : vrai ou faux' USING ERRCODE = '22023';
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

INSERT INTO public.app_config (key, value) VALUES
  ('priere.methode_selon_pays', 'true'::jsonb)
ON CONFLICT (key) DO NOTHING;

-- ===========================================================================
-- 2. D'ou vient le lieu
-- ===========================================================================
-- `direction` : pose par la direction (tout lieu d'avant ce lot) ; `enseignant` : partage
-- par l'enseignant depuis son appareil ; `auto` : pose depuis la ville de l'enseignant.
ALTER TABLE public.prayer_settings
  ADD COLUMN IF NOT EXISTS lieu_source text NOT NULL DEFAULT 'direction'
    CHECK (lieu_source IN ('direction', 'enseignant', 'auto'));

COMMENT ON COLUMN public.prayer_settings.lieu_source IS
  'PRIERE-2 : qui a pose le lieu. direction = a la main par la direction (jamais ecrase par un automatisme ni par l''enseignant) ; enseignant = position partagee par l''enseignant (arrondie au centieme de degre) ; auto = ville de l''enseignant (lot HORLOGE-ET-LIEU).';

-- ===========================================================================
-- 3. La methode usuelle du pays, deduite du fuseau
-- ===========================================================================
-- Seuls les pays dont la methode porte le nom de leur institution ou de leur region, dans la
-- documentation du paquet `adhan` (ligne par ligne dans PRIERE.md, § « Methode selon le pays »).
-- Tout autre fuseau : NULL, donc la methode de l'academie. La methode ISNA n'est pas deduite
-- (le paquet la dit « non recommandee ») ni le Moon Sighting Committee (pas un pays).
CREATE FUNCTION private.priere_methode_zone(p_fuseau text)
RETURNS text
LANGUAGE sql
IMMUTABLE
PARALLEL SAFE
SET search_path = ''
AS $$
  SELECT CASE p_fuseau
    WHEN 'Asia/Riyadh'     THEN 'umm_al_qura'   -- Arabie saoudite : Universite Umm al-Qura, La Mecque
    WHEN 'Asia/Qatar'      THEN 'qatar'         -- Qatar : la methode porte le nom du pays
    WHEN 'Asia/Kuwait'     THEN 'kuwait'        -- Koweit : la methode porte le nom du pays
    WHEN 'Asia/Dubai'      THEN 'dubai'         -- Emirats arabes unis : region du Golfe, Dubai
    WHEN 'Africa/Cairo'    THEN 'egyptian'      -- Egypte : Egyptian General Authority of Survey
    WHEN 'Asia/Karachi'    THEN 'karachi'       -- Pakistan : Universite des sciences islamiques de Karachi
    WHEN 'Asia/Singapore'  THEN 'singapore'     -- Singapour : la methode porte le nom du pays
    WHEN 'Europe/Istanbul' THEN 'turkey'        -- Turquie : Diyanet
    WHEN 'Asia/Tehran'     THEN 'tehran'        -- Iran : Institut de geophysique, Universite de Teheran
    ELSE NULL
  END
$$;

-- D'ou vient la methode d'un enseignant : sa surcharge (posee par la direction), le pays de
-- son lieu, ou la methode de l'academie.
CREATE FUNCTION private.priere_methode_origine(p_enseignant uuid)
RETURNS text
LANGUAGE sql
STABLE
SET search_path = ''
AS $$
  SELECT CASE
    WHEN ps.methode_surcharge IS NOT NULL THEN 'enseignant'
    WHEN coalesce((SELECT (a.value #>> '{}')::boolean FROM public.app_config a
                    WHERE a.key = 'priere.methode_selon_pays'), true)
         AND private.priere_methode_zone(ps.timezone_iana) IS NOT NULL THEN 'pays'
    ELSE 'academie' END
    FROM public.prayer_settings ps
   WHERE ps.teacher_id = p_enseignant AND ps.actif
$$;

-- Les reglages effectifs d'un enseignant : meme forme que dans 20261123930000, la methode
-- devient surcharge > pays du lieu > academie. Aucune ligne s'il n'a pas de lieu.
CREATE OR REPLACE FUNCTION private.priere_reglages(p_enseignant uuid)
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
         coalesce(ps.methode_surcharge,
                  CASE WHEN coalesce((SELECT (a.value #>> '{}')::boolean FROM public.app_config a
                                       WHERE a.key = 'priere.methode_selon_pays'), true)
                       THEN private.priere_methode_zone(ps.timezone_iana) END,
                  c.methode),
         coalesce(ps.ecole_asr_surcharge, c.ecole),
         ps.adjustments, ps.assiste_vendredi, ps.vendredi_debut, ps.vendredi_fin
    FROM public.prayer_settings ps
   CROSS JOIN private.priere_cfg() c
   WHERE ps.teacher_id = p_enseignant AND ps.actif
$$;

-- ===========================================================================
-- 4. Le lieu pose par la direction est marque « direction »
-- ===========================================================================
CREATE OR REPLACE FUNCTION public.priere_lieu_definir(
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
     ecole_asr_surcharge, assiste_vendredi, vendredi_debut, vendredi_fin, actif, defini_par, defini_le,
     lieu_source)
  VALUES
    (p_enseignant_id, p_latitude, p_longitude, p_fuseau, pg_catalog.btrim(p_lieu), p_methode,
     p_ecole_asr, p_assiste_vendredi, p_vendredi_debut, p_vendredi_fin, true, auth.uid(), pg_catalog.now(),
     'direction')
  ON CONFLICT (teacher_id) DO UPDATE
    SET latitude = EXCLUDED.latitude, longitude = EXCLUDED.longitude,
        timezone_iana = EXCLUDED.timezone_iana, place_label = EXCLUDED.place_label,
        methode_surcharge = EXCLUDED.methode_surcharge,
        ecole_asr_surcharge = EXCLUDED.ecole_asr_surcharge,
        assiste_vendredi = EXCLUDED.assiste_vendredi,
        vendredi_debut = EXCLUDED.vendredi_debut, vendredi_fin = EXCLUDED.vendredi_fin,
        actif = true, defini_par = EXCLUDED.defini_par, defini_le = EXCLUDED.defini_le,
        lieu_source = 'direction';

  PERFORM public.log_sensitive_access('priere_lieu_defini', 'prayer_settings', p_enseignant_id::text,
    pg_catalog.jsonb_build_object('acteur', auth.uid()));
END;
$function$;

-- ===========================================================================
-- 5. L'enseignant partage sa position, en un geste, pour LUI-MEME
-- ===========================================================================
-- Reserve a l'enseignant connecte, pour son propre profil (aucun parametre ne designe une
-- autre personne), refus pour tout autre role et pour un mineur. La position est ARRONDIE au
-- centieme de degre (environ un kilometre) avant d'etre ecrite : la position exacte n'est ni
-- stockee ni affichee. Le fuseau est celui de l'appareil (IANA), verifie par le serveur. Le nom
-- est lisible sans service externe. Un lieu pose par la direction n'est jamais ecrase.
-- Le journal garde qui et quand, jamais la position.
CREATE FUNCTION public.priere_ma_position(
  p_latitude numeric, p_longitude numeric, p_fuseau text)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  v_uid uuid := auth.uid();
  v_lat numeric;
  v_lon numeric;
  v_nom text;
BEGIN
  IF NOT coalesce(public.app_account_valid() AND public.app_role() = 'teacher' AND v_uid IS NOT NULL, false)
     OR coalesce(private.com_est_mineur(v_uid), true) THEN
    RAISE EXCEPTION 'position de priere : reservee a l''enseignant, pour lui-meme' USING ERRCODE = '42501';
  END IF;
  IF p_latitude IS NULL OR p_latitude NOT BETWEEN -90 AND 90
     OR p_longitude IS NULL OR p_longitude NOT BETWEEN -180 AND 180 THEN
    RAISE EXCEPTION 'latitude ou longitude hors bornes' USING ERRCODE = '22023';
  END IF;
  IF p_fuseau IS NULL OR NOT app_private.fuseau_connu(p_fuseau) THEN
    RAISE EXCEPTION 'fuseau inconnu' USING ERRCODE = '22023';
  END IF;
  IF EXISTS (SELECT 1 FROM public.prayer_settings ps
              WHERE ps.teacher_id = v_uid AND ps.actif AND ps.lieu_source = 'direction') THEN
    RAISE EXCEPTION 'lieu_pose_par_la_direction' USING ERRCODE = '42501';
  END IF;

  v_lat := pg_catalog.round(p_latitude, 2);
  v_lon := pg_catalog.round(p_longitude, 2);
  v_nom := 'Votre position, fuseau ' || p_fuseau;

  INSERT INTO public.prayer_settings AS ps
    (teacher_id, latitude, longitude, timezone_iana, place_label, actif, defini_par, defini_le, lieu_source)
  VALUES (v_uid, v_lat, v_lon, p_fuseau, v_nom, true, v_uid, pg_catalog.now(), 'enseignant')
  ON CONFLICT (teacher_id) DO UPDATE
    SET latitude = EXCLUDED.latitude, longitude = EXCLUDED.longitude,
        timezone_iana = EXCLUDED.timezone_iana, place_label = EXCLUDED.place_label,
        actif = true, defini_par = EXCLUDED.defini_par, defini_le = EXCLUDED.defini_le,
        lieu_source = 'enseignant';

  PERFORM public.log_sensitive_access('priere_position_partagee', 'prayer_settings', v_uid::text,
    pg_catalog.jsonb_build_object('acteur', v_uid));
END;
$function$;

-- ===========================================================================
-- 6. Le lieu pose depuis la ville de l'enseignant (lot HORLOGE-ET-LIEU)
-- ===========================================================================
-- Pose le lieu SEULEMENT si la direction n'en a pas pose un a la main et si l'enseignant n'a
-- pas partage sa propre position (la sienne, plus precise, l'emporte) ; remplace un lieu
-- `auto` plus ancien (changement de ville) ; recalcule les pauses (declencheur de
-- prayer_settings). Rend vrai quand le lieu a ete pose. Aucune table du lot horloge n'est lue.
CREATE FUNCTION private.priere_lieu_auto(
  p_enseignant uuid, p_nom text, p_lat numeric, p_lng numeric, p_fuseau text)
RETURNS boolean
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $function$
BEGIN
  IF p_enseignant IS NULL OR p_nom IS NULL OR pg_catalog.btrim(p_nom) = '' OR pg_catalog.length(p_nom) > 80
     OR p_lat IS NULL OR p_lat NOT BETWEEN -90 AND 90
     OR p_lng IS NULL OR p_lng NOT BETWEEN -180 AND 180
     OR p_fuseau IS NULL OR NOT app_private.fuseau_connu(p_fuseau) THEN
    RETURN false;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM public.profiles p
                  WHERE p.id = p_enseignant AND p.role = 'teacher' AND p.deleted_at IS NULL) THEN
    RETURN false;
  END IF;
  IF EXISTS (SELECT 1 FROM public.prayer_settings ps
              WHERE ps.teacher_id = p_enseignant AND ps.actif AND ps.lieu_source IN ('direction', 'enseignant')) THEN
    RETURN false;
  END IF;

  INSERT INTO public.prayer_settings AS ps
    (teacher_id, latitude, longitude, timezone_iana, place_label, actif, defini_par, defini_le, lieu_source)
  VALUES (p_enseignant, pg_catalog.round(p_lat, 3), pg_catalog.round(p_lng, 3), p_fuseau,
          pg_catalog.btrim(p_nom), true, NULL, pg_catalog.now(), 'auto')
  ON CONFLICT (teacher_id) DO UPDATE
    SET latitude = EXCLUDED.latitude, longitude = EXCLUDED.longitude,
        timezone_iana = EXCLUDED.timezone_iana, place_label = EXCLUDED.place_label,
        actif = true, defini_par = NULL, defini_le = EXCLUDED.defini_le, lieu_source = 'auto';

  PERFORM public.log_sensitive_access('priere_lieu_auto', 'prayer_settings', p_enseignant::text,
    pg_catalog.jsonb_build_object('source', 'ville'));
  RETURN true;
END;
$function$;

-- Si le lot HORLOGE-ET-LIEU est deja la, la ligne a brancher est dans la fiche
-- (docs/current/pedagogie/lots/LOT-PRIERE-2.md) : ses colonnes ne sont pas lues ici.
DO $lieux$
BEGIN
  IF pg_catalog.to_regclass('public.lieux') IS NOT NULL THEN
    RAISE NOTICE 'PRIERE-2 : public.lieux existe ; brancher private.priere_lieu_auto comme dit dans LOT-PRIERE-2.md';
  END IF;
END
$lieux$;

-- ===========================================================================
-- 7. Les reglages lus : la methode appliquee et son origine
-- ===========================================================================
CREATE OR REPLACE FUNCTION public.priere_reglages_lire(p_enseignant_id uuid DEFAULT NULL)
RETURNS jsonb
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  v_cible uuid;
  v_ligne public.prayer_settings%ROWTYPE;
  rg record;
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
  SELECT * INTO rg FROM private.priere_reglages(v_cible);
  RETURN pg_catalog.jsonb_build_object(
    'enseignant_id', v_ligne.teacher_id,
    'lieu', v_ligne.place_label,
    'latitude', v_ligne.latitude,
    'longitude', v_ligne.longitude,
    'fuseau', v_ligne.timezone_iana,
    'methode', rg.methode,
    'methode_origine', private.priere_methode_origine(v_cible),
    'ecole_asr', rg.ecole,
    'methode_surcharge', v_ligne.methode_surcharge,
    'ecole_asr_surcharge', v_ligne.ecole_asr_surcharge,
    'lieu_source', v_ligne.lieu_source,
    'ajustements', v_ligne.adjustments,
    'assiste_vendredi', v_ligne.assiste_vendredi,
    'vendredi_debut', pg_catalog.to_char(v_ligne.vendredi_debut, 'HH24:MI'),
    'vendredi_fin', pg_catalog.to_char(v_ligne.vendredi_fin, 'HH24:MI'));
END;
$function$;

-- ===========================================================================
-- 8. La liste a lire de la direction
-- ===========================================================================
-- Par enseignant : sa zone (nom), ses cinq heures du jour (jour local de son lieu), la
-- methode appliquee et d'ou elle vient, d'ou vient le lieu, le vendredi. Jamais une
-- coordonnee. Un enseignant sans lieu : `a_un_lieu` faux, rien d'autre.
CREATE FUNCTION public.priere_enseignants_vue()
RETURNS TABLE (
  enseignant_id uuid, prenom text, a_un_lieu boolean, lieu text, fuseau text,
  lieu_source text, methode text, methode_origine text, ecole_asr text,
  assiste_vendredi boolean, vendredi_debut text, vendredi_fin text, horaires jsonb)
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
    SELECT p.id, p.first_name, coalesce(ps.actif, false),
           CASE WHEN ps.actif THEN ps.place_label END,
           CASE WHEN ps.actif THEN ps.timezone_iana END,
           CASE WHEN ps.actif THEN ps.lieu_source END,
           rg.methode,
           CASE WHEN ps.actif THEN private.priere_methode_origine(p.id) END,
           rg.ecole,
           coalesce(ps.actif AND ps.assiste_vendredi, false),
           CASE WHEN ps.actif THEN pg_catalog.to_char(ps.vendredi_debut, 'HH24:MI') END,
           CASE WHEN ps.actif THEN pg_catalog.to_char(ps.vendredi_fin, 'HH24:MI') END,
           CASE WHEN ps.actif THEN (
             SELECT coalesce(pg_catalog.jsonb_agg(pg_catalog.jsonb_build_object(
                      'priere', h.priere, 'instant_utc', h.instant_utc, 'approximee', h.approximee)
                      ORDER BY h.instant_utc), '[]'::jsonb)
               FROM (SELECT c.priere, c.instant_utc, c.approximee
                       FROM pg_catalog.generate_series(-1, 1) AS j(k),
                            LATERAL private.priere_calculer(rg.lat, rg.lon,
                              (pg_catalog.now() AT TIME ZONE rg.fuseau)::date + j.k,
                              rg.methode, rg.ecole, rg.ajustements) c
                      WHERE (c.instant_utc AT TIME ZONE rg.fuseau)::date
                            = (pg_catalog.now() AT TIME ZONE rg.fuseau)::date) h)
           END
      FROM public.profiles p
      LEFT JOIN public.prayer_settings ps ON ps.teacher_id = p.id
      LEFT JOIN LATERAL private.priere_reglages(p.id) rg ON true
     WHERE p.role = 'teacher' AND p.deleted_at IS NULL
       AND p.account_status IN ('active', 'provisional_active')
     ORDER BY p.first_name, p.id;
END;
$function$;

-- ===========================================================================
-- 9. Droits et controle final
-- ===========================================================================
ALTER FUNCTION public.priere_ma_position(numeric, numeric, text) OWNER TO postgres;
ALTER FUNCTION public.priere_enseignants_vue() OWNER TO postgres;
REVOKE ALL ON FUNCTION public.priere_ma_position(numeric, numeric, text),
  public.priere_enseignants_vue()
  FROM PUBLIC, anon, service_role, agent_ro;
GRANT EXECUTE ON FUNCTION public.priere_ma_position(numeric, numeric, text),
  public.priere_enseignants_vue()
  TO authenticated;
REVOKE ALL ON FUNCTION
  private.priere_methode_zone(text), private.priere_methode_origine(uuid),
  private.priere_lieu_auto(uuid, text, numeric, numeric, text)
  FROM PUBLIC, anon, authenticated, service_role, agent_ro;

DO $postflight$
DECLARE
  v_oid regprocedure;
BEGIN
  FOREACH v_oid IN ARRAY ARRAY[
    'public.priere_ma_position(numeric, numeric, text)'::regprocedure,
    'public.priere_enseignants_vue()'::regprocedure,
    'public.priere_reglages_lire(uuid)'::regprocedure,
    'public.priere_lieu_definir(uuid, text, numeric, numeric, text, text, text, boolean, time, time)'::regprocedure] LOOP
    IF NOT EXISTS (SELECT 1 FROM pg_catalog.pg_proc p
                    WHERE p.oid = v_oid AND p.prosecdef
                      AND 'search_path=""' = ANY (coalesce(p.proconfig, ARRAY[]::text[])))
       OR pg_catalog.has_function_privilege('anon', v_oid, 'EXECUTE')
       OR pg_catalog.has_function_privilege('public', v_oid, 'EXECUTE')
       OR NOT pg_catalog.has_function_privilege('authenticated', v_oid, 'EXECUTE') THEN
      RAISE EXCEPTION 'PRIERE-2 : fonction % mal durcie', v_oid::text;
    END IF;
  END LOOP;
  IF pg_catalog.has_function_privilege('authenticated',
       'private.priere_lieu_auto(uuid, text, numeric, numeric, text)'::regprocedure, 'EXECUTE')
     OR pg_catalog.has_function_privilege('anon',
       'private.priere_lieu_auto(uuid, text, numeric, numeric, text)'::regprocedure, 'EXECUTE') THEN
    RAISE EXCEPTION 'PRIERE-2 : private.priere_lieu_auto ne doit etre appelable par personne d''autre que le serveur';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns c
                  WHERE c.table_schema = 'public' AND c.table_name = 'prayer_settings'
                    AND c.column_name = 'lieu_source') THEN
    RAISE EXCEPTION 'PRIERE-2 : prayer_settings.lieu_source manque';
  END IF;
END;
$postflight$;
