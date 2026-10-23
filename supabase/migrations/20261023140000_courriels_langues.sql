-- COURRIELS-2 (directeur, 23/10/2026) : chaque personne recoit ses e-mails dans
-- sa langue. « Beaucoup de langues sont prevues [...]. Lorsque la direction
-- ecrit un message, le destinataire le recoit dans sa propre langue. [...] Si la
-- direction doit ecrire chaque message separement pour chaque langue, ca va
-- etre super complique. » Moteur de traduction choisi : Google Traduction.
--
-- - La langue de communication se lit sur le profil (choisie dans
--   l'application) ; sans profil (invitation, candidat), la donnee `langue` de
--   l'e-mail ; sinon le francais.
-- - Chaque e-mail de la file porte sa langue, fixee a l'entree par un
--   declencheur : tous les appelants de `courriel_enfiler` en profitent sans
--   changement.
-- - La traduction se fait a l'envoi, dans `courriels-envoi` : modele ecrit a la
--   main dans la langue s'il existe, sinon traduction du francais par Google ;
--   un message de la direction est traduit de sa langue d'ecriture.

CREATE TABLE public.langues_communication (
  code text PRIMARY KEY CHECK (code ~ '^[a-z]{2,3}$'),
  libelle text NOT NULL CHECK (pg_catalog.char_length(libelle) BETWEEN 1 AND 40),
  droite_a_gauche boolean NOT NULL DEFAULT false,
  -- Modeles ecrits a la main dans cette langue (sinon : traduits a l'envoi).
  modeles_ecrits boolean NOT NULL DEFAULT false,
  active boolean NOT NULL DEFAULT true,
  ordre integer NOT NULL DEFAULT 100
);

INSERT INTO public.langues_communication (code, libelle, droite_a_gauche, modeles_ecrits, ordre) VALUES
  ('fr', 'Français', false, true, 1),
  ('en', 'English', false, true, 2),
  ('ar', 'العربية', true, true, 3),
  ('es', 'Español', false, true, 4),
  ('pt', 'Português', false, true, 5),
  ('ff', 'Pulaar', false, false, 6);

ALTER TABLE public.langues_communication ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON public.langues_communication FROM PUBLIC, anon, authenticated, service_role, agent_ro;

ALTER TABLE public.profiles
  ADD COLUMN langue_communication text REFERENCES public.langues_communication(code);
COMMENT ON COLUMN public.profiles.langue_communication IS
  'COURRIELS-2 : langue des e-mails et messages de la personne ; NULL = francais.';

ALTER TABLE public.courriels_sortants
  ADD COLUMN langue text NOT NULL DEFAULT 'fr' CHECK (langue ~ '^[a-z]{2,3}$');

-- ------------------------------------------------------------------
-- La langue d'un e-mail, fixee a son entree dans la file
-- ------------------------------------------------------------------
CREATE FUNCTION public.courriel_langue_a_l_entree()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  v_langue text;
BEGIN
  IF NEW.destinataire_profil IS NOT NULL THEN
    SELECT p.langue_communication INTO v_langue FROM public.profiles p WHERE p.id = NEW.destinataire_profil;
  END IF;
  IF v_langue IS NULL AND NEW.donnees ? 'langue' THEN
    v_langue := pg_catalog.lower(NEW.donnees->>'langue');
  END IF;
  IF v_langue IS NULL OR NOT EXISTS (SELECT 1 FROM public.langues_communication l
                                      WHERE l.code = v_langue AND l.active) THEN
    v_langue := 'fr';
  END IF;
  NEW.langue := v_langue;
  RETURN NEW;
END;
$function$;

CREATE TRIGGER courriel_langue
  BEFORE INSERT ON public.courriels_sortants
  FOR EACH ROW EXECUTE FUNCTION public.courriel_langue_a_l_entree();

-- ------------------------------------------------------------------
-- La personne choisit sa langue ; tout le monde lit la liste
-- ------------------------------------------------------------------
CREATE FUNCTION public.langues_communication_lister()
RETURNS jsonb
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $function$
  SELECT coalesce(pg_catalog.jsonb_agg(pg_catalog.jsonb_build_object(
           'code', l.code, 'libelle', l.libelle, 'droite_a_gauche', l.droite_a_gauche) ORDER BY l.ordre, l.code), '[]'::jsonb)
    FROM public.langues_communication l WHERE l.active;
$function$;

CREATE FUNCTION public.ma_langue_communication()
RETURNS text
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $function$
  SELECT p.langue_communication FROM public.profiles p WHERE p.id = auth.uid();
$function$;

CREATE FUNCTION public.ma_langue_communication_regler(p_code text)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  v_code text := pg_catalog.lower(pg_catalog.btrim(p_code));
BEGIN
  IF auth.uid() IS NULL OR NOT EXISTS (SELECT 1 FROM public.profiles p WHERE p.id = auth.uid()) THEN
    RAISE EXCEPTION 'acces refuse' USING ERRCODE = '42501';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM public.langues_communication l WHERE l.code = v_code AND l.active) THEN
    RAISE EXCEPTION 'langue' USING ERRCODE = '22023';
  END IF;
  UPDATE public.profiles SET langue_communication = v_code WHERE id = auth.uid();
END;
$function$;

-- ------------------------------------------------------------------
-- Le travailleur recoit la langue ; la direction la voit dans la file
-- ------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.courriels_reserver(p_lot integer DEFAULT 20)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  v_ids uuid[];
BEGIN
  -- Une ligne restee « envoi » plus de dix minutes (travailleur tombe) redevient
  -- disponible ; l'envoi peut alors partir deux fois, jamais zero.
  WITH choisis AS (
    SELECT s.id FROM public.courriels_sortants s
     WHERE (s.statut = 'en_attente' AND s.prochaine_tentative <= pg_catalog.now())
        OR (s.statut = 'envoi' AND s.reserve_le < pg_catalog.now() - interval '10 minutes')
     ORDER BY s.prochaine_tentative
     LIMIT LEAST(GREATEST(coalesce(p_lot, 20), 1), 100)
     FOR UPDATE SKIP LOCKED
  ), pris AS (
    UPDATE public.courriels_sortants s
       SET statut = 'envoi', reserve_le = pg_catalog.now(), tentatives = s.tentatives + 1
      FROM choisis WHERE s.id = choisis.id
    RETURNING s.id
  )
  SELECT pg_catalog.array_agg(pris.id) INTO v_ids FROM pris;

  RETURN coalesce((
    SELECT pg_catalog.jsonb_agg(pg_catalog.jsonb_build_object(
             'id', p.id, 'modele', p.modele, 'categorie', p.categorie,
             'a', p.destinataire_adresse, 'donnees', p.donnees, 'tentatives', p.tentatives,
             'de', c.expediteur_adresse, 'de_nom', c.expediteur_nom, 'repondre_a', c.repondre_a,
             'essentielle', c.essentielle, 'langue', p.langue,
             'langue_ecrite', coalesce(l.modeles_ecrits, false),
             'droite_a_gauche', coalesce(l.droite_a_gauche, false)) ORDER BY p.prochaine_tentative)
      FROM public.courriels_sortants p
      JOIN public.courriel_categories c ON c.code = p.categorie
      LEFT JOIN public.langues_communication l ON l.code = p.langue
     WHERE p.id = ANY (v_ids)), '[]'::jsonb);
END;
$function$;

CREATE OR REPLACE FUNCTION public.admin_courriels_lister(p_statut text DEFAULT NULL, p_limite integer DEFAULT 100)
RETURNS jsonb
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $function$
BEGIN
  IF NOT coalesce(public.app_role() = 'admin' AND public.app_account_valid(), false) THEN
    RAISE EXCEPTION 'acces refuse' USING ERRCODE = '42501';
  END IF;
  RETURN coalesce((
    SELECT pg_catalog.jsonb_agg(r ORDER BY r.cree_le DESC) FROM (
      SELECT s.id, s.categorie, s.modele, s.destinataire_adresse, s.origine, s.statut,
             s.tentatives, s.derniere_erreur, s.cree_le, s.envoye_le, s.langue,
             CASE WHEN s.modele = 'message_libre' THEN s.donnees->>'sujet' END AS sujet
        FROM public.courriels_sortants s
       WHERE p_statut IS NULL OR s.statut = p_statut
       ORDER BY s.cree_le DESC
       LIMIT LEAST(GREATEST(coalesce(p_limite, 100), 1), 500)) r), '[]'::jsonb);
END;
$function$;

-- ------------------------------------------------------------------
-- Droits, liste blanche des fonctions DEFINER
-- ------------------------------------------------------------------
DO $droits$
DECLARE
  v_oid regprocedure;
  v_garde text;
BEGIN
  FOREACH v_oid IN ARRAY ARRAY[
    'public.courriel_langue_a_l_entree()'::regprocedure,
    'public.langues_communication_lister()'::regprocedure,
    'public.ma_langue_communication()'::regprocedure,
    'public.ma_langue_communication_regler(text)'::regprocedure,
    'public.courriels_reserver(integer)'::regprocedure,
    'public.admin_courriels_lister(text,integer)'::regprocedure] LOOP
    EXECUTE pg_catalog.format('ALTER FUNCTION %s OWNER TO postgres', v_oid);
    EXECUTE pg_catalog.format('REVOKE ALL ON FUNCTION %s FROM PUBLIC, anon, authenticated, service_role, agent_ro', v_oid);
    v_garde := CASE
      WHEN v_oid::text LIKE '%courriel_langue_a_l_entree%' THEN 'INTERNAL_NO_EXECUTE'
      WHEN v_oid::text LIKE '%langues_communication_lister%' THEN 'PUBLIC_READ_WHITELIST'
      WHEN v_oid::text LIKE '%courriels_reserver%' THEN 'SERVICE_ROLE_ONLY'
      WHEN v_oid::text LIKE '%admin_courriels_lister%' THEN 'ROLE_POSITIVE_ADMIN'
      ELSE 'SELF_ONLY_AUTH_UID' END;
    EXECUTE pg_catalog.format('COMMENT ON FUNCTION %s IS %L', v_oid, pg_catalog.format(
      'F86 candidate allowlist: signature=%s; md5_functiondef=%s; guard_type=%s; owner=postgres; search_path=""; reviewer=Claude a relire; date=2026-10-23. COURRIELS-2.',
      v_oid::text, pg_catalog.md5(pg_catalog.pg_get_functiondef(v_oid)), v_garde));
  END LOOP;
  GRANT EXECUTE ON FUNCTION public.langues_communication_lister() TO anon, authenticated;
  GRANT EXECUTE ON FUNCTION public.ma_langue_communication() TO authenticated;
  GRANT EXECUTE ON FUNCTION public.ma_langue_communication_regler(text) TO authenticated;
  GRANT EXECUTE ON FUNCTION public.courriels_reserver(integer) TO service_role;
  GRANT EXECUTE ON FUNCTION public.admin_courriels_lister(text,integer) TO authenticated;
END;
$droits$;

DO $postflight$
BEGIN
  IF pg_catalog.has_function_privilege('anon', 'public.ma_langue_communication_regler(text)'::regprocedure, 'EXECUTE')
     OR pg_catalog.has_function_privilege('authenticated', 'public.courriel_langue_a_l_entree()'::regprocedure, 'EXECUTE')
     OR pg_catalog.has_function_privilege('authenticated', 'public.courriels_reserver(integer)'::regprocedure, 'EXECUTE')
     OR NOT pg_catalog.has_function_privilege('anon', 'public.langues_communication_lister()'::regprocedure, 'EXECUTE')
     OR pg_catalog.has_table_privilege('authenticated', 'public.langues_communication', 'SELECT') THEN
    RAISE EXCEPTION 'COURRIELS-2 : droits inattendus';
  END IF;
END;
$postflight$;
