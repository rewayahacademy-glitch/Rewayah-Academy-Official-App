-- PARCOURS-BOUT-EN-BOUT, partie B1 (directeur, 22/11/2026 : « bien travailler
-- les fuseaux horaires, sinon ce sera dangereux ») : l'apercu d'une offre rend
-- aussi l'heure du premier creneau a l'heure de l'academie (`mecque`,
-- `jour_mecque`, lus dans `private.fuseau_academie()`, jamais ecrits en dur),
-- pour que la carte d'offre dise l'heure de la famille PUIS celle de La
-- Mecque.
--
-- Additif : meme signature, deux cles de plus. FICHIER SANS EFFACEMENT.

BEGIN;

CREATE OR REPLACE FUNCTION public.apercu_offre_horaire(
  p_offre_id uuid,
  p_fuseau text)
RETURNS jsonb
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  v_o record;
  v_maintenant timestamptz := pg_catalog.now();
  v_t_lecteur timestamptz;
  v_t_offre timestamptz;
  v_transition timestamptz;
  v_actuel timestamptz;
  v_avant timestamptz;
  v_apres timestamptz;
  v_heure_avant text;
  v_heure_apres text;
  v_jour_avant integer;
  v_jour_apres integer;
BEGIN
  IF NOT coalesce(public.app_account_valid(), false) THEN
    RAISE EXCEPTION 'apercu non autorise' USING ERRCODE = '42501';
  END IF;
  IF p_offre_id IS NULL OR p_fuseau IS NULL OR NOT app_private.fuseau_connu(p_fuseau) THEN
    RAISE EXCEPTION 'apercu : parametres invalides' USING ERRCODE = '22023';
  END IF;
  SELECT o.jours[1] AS jour, o.heure_locale AS heure, o.fuseau_iana AS fuseau
    INTO v_o
    FROM public.offres_horaires o
   WHERE o.id = p_offre_id
     AND o.etat = 'publiee'
     AND pg_catalog.cardinality(o.jours) > 0;
  IF NOT FOUND OR NOT app_private.fuseau_connu(v_o.fuseau) THEN
    RETURN NULL;
  END IF;
  v_actuel := public.instant_creneau_reference(v_o.jour::integer, v_o.heure::integer, v_o.fuseau, 0, v_maintenant);
  -- Une offre definie a l'heure d'un pays qui change d'heure bouge chez une
  -- personne qui, elle, ne change jamais : le premier des DEUX changements
  -- (celui du fuseau de la personne, celui du fuseau de l'offre) compte.
  v_t_lecteur := (private.fuseau_info(p_fuseau, v_maintenant) ->> 'prochain_changement')::timestamptz;
  v_t_offre := (private.fuseau_info(v_o.fuseau, v_maintenant) ->> 'prochain_changement')::timestamptz;
  v_transition := LEAST(v_t_lecteur, v_t_offre);
  IF v_transition IS NOT NULL THEN
    SELECT pg_catalog.max(x.debut) FILTER (WHERE x.debut < v_transition),
           pg_catalog.min(x.debut) FILTER (WHERE x.debut >= v_transition)
      INTO v_avant, v_apres
      FROM (SELECT public.instant_creneau_reference(v_o.jour::integer, v_o.heure::integer, v_o.fuseau, k, v_maintenant) AS debut
              FROM pg_catalog.generate_series(-1, 60) AS k) x;
    IF v_avant IS NOT NULL AND v_apres IS NOT NULL THEN
      v_jour_avant := pg_catalog.date_part('isodow', v_avant AT TIME ZONE p_fuseau)::integer;
      v_heure_avant := pg_catalog.to_char(v_avant AT TIME ZONE p_fuseau, 'HH24:MI');
      v_jour_apres := pg_catalog.date_part('isodow', v_apres AT TIME ZONE p_fuseau)::integer;
      v_heure_apres := pg_catalog.to_char(v_apres AT TIME ZONE p_fuseau, 'HH24:MI');
    END IF;
  END IF;
  IF v_heure_apres IS NULL OR (v_jour_avant = v_jour_apres AND v_heure_avant = v_heure_apres) THEN
    v_transition := NULL;
  END IF;
  RETURN pg_catalog.jsonb_build_object(
    'fuseau', p_fuseau,
    'academie', v_o.fuseau,
    'maintenant', pg_catalog.to_char(v_actuel AT TIME ZONE p_fuseau, 'HH24:MI'),
    'jour_maintenant', pg_catalog.date_part('isodow', v_actuel AT TIME ZONE p_fuseau)::integer,
    -- PARCOURS-BOUT-EN-BOUT : le meme instant a l'heure de l'academie (La
    -- Mecque), pour que la famille lise l'heure de La Mecque en second.
    'mecque', pg_catalog.to_char(v_actuel AT TIME ZONE private.fuseau_academie(), 'HH24:MI'),
    'jour_mecque', pg_catalog.date_part('isodow', v_actuel AT TIME ZONE private.fuseau_academie())::integer,
    'meme', v_transition IS NULL,
    'date_changement', CASE WHEN v_transition IS NULL THEN NULL
                            ELSE pg_catalog.to_char(v_transition AT TIME ZONE p_fuseau, 'YYYY-MM-DD') END,
    'jour_apres', CASE WHEN v_transition IS NULL THEN NULL ELSE v_jour_apres END,
    'heure_apres', CASE WHEN v_transition IS NULL THEN NULL ELSE v_heure_apres END);
END;
$function$;

REVOKE ALL ON FUNCTION public.apercu_offre_horaire(uuid, text) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.apercu_offre_horaire(uuid, text) TO authenticated;
COMMENT ON FUNCTION public.apercu_offre_horaire(uuid, text) IS
  'HORLOGE-ET-LIEU (13/11/2026) : l''apercu (heure chez soi aujourd''hui, puis apres le prochain changement d''heure) du premier creneau d''une offre publiee. Rien pour une offre non publiee. Compte valide exige. DEFINER, search_path vide.';

COMMIT;
