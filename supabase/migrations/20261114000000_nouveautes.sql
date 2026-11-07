-- NOUVEAUTES (demande du directeur du 07/11/2026, conception du garde-cap ;
-- plage reservee par le pilote : 20261114000000-20261114999999).
--
-- FICHIER SANS EFFACEMENT (regle B5) : aucun des trois mots d'effacement.
-- Migration additive (B6) : deux tables, deux fonctions, rien de retire.
--
-- Le directeur : « un systeme de badge qui va montrer les nouvelles
-- fonctionnalites... discret... tu as ajoute beaucoup de choses que je ne
-- peux pas remarquer ».
--
-- 1. `public.nouveautes` : une ligne par fonctionnalite visible (cle, date de
--    sortie, roles qui la voient). Aucune ecriture client.
-- 2. `public.nouveautes_vues` : ce que chaque compte a ouvert (une ligne par
--    compte et par cle, jamais effacee). Suivi PAR COMPTE, donc vu une fois
--    sur un appareil, plus rien sur un second.
-- 3. `mes_nouveautes()` : les cles a signaler a la personne connectee : son
--    role est dans la ligne, la sortie a eu lieu, il y a moins de 14 jours,
--    et elle ne l'a pas encore ouverte. Lecture seule.
-- 4. `marquer_nouveaute_vue(p_cle)` : la personne a ouvert la fonctionnalite.
--    Garde positive (compte valide, role de la ligne) ; idempotent.
-- Regle du lot : tout lot qui ajoute une fonctionnalite visible declare sa
-- nouveaute (cle, roles, sortie) dans le meme train, par une ligne de sa
-- propre migration ; sinon il n'est pas CONFORME.

BEGIN;

DO $preflight$
BEGIN
  IF pg_catalog.to_regclass('public.nouveautes') IS NOT NULL
     OR pg_catalog.to_regclass('public.nouveautes_vues') IS NOT NULL THEN
    RAISE EXCEPTION 'NOUVEAUTES : deja installee';
  END IF;
END
$preflight$;

CREATE TABLE public.nouveautes (
  cle text PRIMARY KEY CHECK (cle ~ '^[a-z][a-z0-9_]{2,59}$'),
  sortie_le timestamptz NOT NULL,
  roles public.app_role[] NOT NULL CHECK (pg_catalog.cardinality(roles) >= 1),
  -- Pour la direction et les agents, jamais affiche : ce que la cle designe.
  description text NOT NULL CHECK (pg_catalog.length(description) BETWEEN 3 AND 300)
);
ALTER TABLE public.nouveautes ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON public.nouveautes FROM PUBLIC, anon, authenticated, service_role, agent_ro;
GRANT SELECT ON public.nouveautes TO authenticated;
-- Chacun lit les lignes de son role ; aucune ecriture client.
CREATE POLICY nouveautes_lecture ON public.nouveautes
  FOR SELECT TO authenticated
  USING (public.app_role() = ANY (roles));
COMMENT ON TABLE public.nouveautes IS
  'NOUVEAUTES (07/11/2026) : fonctionnalites visibles signalees par le badge « Nouveau » pendant 14 jours '
  'apres sortie_le, aux roles de la ligne. Ecrite par les migrations des lots seulement.';

CREATE TABLE public.nouveautes_vues (
  profile_id uuid NOT NULL REFERENCES public.profiles(id),
  cle text NOT NULL REFERENCES public.nouveautes(cle),
  vue_le timestamptz NOT NULL DEFAULT pg_catalog.clock_timestamp(),
  PRIMARY KEY (profile_id, cle)
);
ALTER TABLE public.nouveautes_vues ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON public.nouveautes_vues FROM PUBLIC, anon, authenticated, service_role, agent_ro;
GRANT SELECT ON public.nouveautes_vues TO authenticated;
CREATE POLICY nouveautes_vues_lecture ON public.nouveautes_vues
  FOR SELECT TO authenticated
  USING (profile_id = auth.uid());
COMMENT ON TABLE public.nouveautes_vues IS
  'NOUVEAUTES (07/11/2026) : la personne a ouvert la fonctionnalite ; le badge ne revient plus, sur aucun '
  'appareil. Ecrite par marquer_nouveaute_vue seulement.';

CREATE FUNCTION public.mes_nouveautes()
RETURNS text[]
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $function$
  SELECT coalesce(pg_catalog.array_agg(n.cle ORDER BY n.cle), ARRAY[]::text[])
    FROM public.nouveautes n
   WHERE auth.uid() IS NOT NULL
     AND coalesce(public.app_account_valid(), false)
     AND public.app_role() = ANY (n.roles)
     AND n.sortie_le <= pg_catalog.now()
     AND n.sortie_le > pg_catalog.now() - interval '14 days'
     AND NOT EXISTS (SELECT 1 FROM public.nouveautes_vues v
                      WHERE v.profile_id = auth.uid() AND v.cle = n.cle);
$function$;
ALTER FUNCTION public.mes_nouveautes() OWNER TO postgres;
REVOKE ALL ON FUNCTION public.mes_nouveautes() FROM PUBLIC, anon, service_role, agent_ro;
GRANT EXECUTE ON FUNCTION public.mes_nouveautes() TO authenticated;

CREATE FUNCTION public.marquer_nouveaute_vue(p_cle text)
RETURNS boolean
LANGUAGE plpgsql
VOLATILE
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  v_moi uuid := auth.uid();
BEGIN
  IF v_moi IS NULL OR NOT coalesce(public.app_account_valid(), false) THEN
    RAISE EXCEPTION 'nouveautes reservees a un compte valide' USING ERRCODE = '42501';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM public.nouveautes n
                  WHERE n.cle = p_cle AND public.app_role() = ANY (n.roles)) THEN
    -- Une cle inconnue, ou d'un autre role : rien a marquer.
    RETURN false;
  END IF;
  INSERT INTO public.nouveautes_vues (profile_id, cle)
  VALUES (v_moi, p_cle)
  ON CONFLICT (profile_id, cle) DO NOTHING;
  RETURN true;
END;
$function$;
ALTER FUNCTION public.marquer_nouveaute_vue(text) OWNER TO postgres;
REVOKE ALL ON FUNCTION public.marquer_nouveaute_vue(text) FROM PUBLIC, anon, service_role, agent_ro;
GRANT EXECUTE ON FUNCTION public.marquer_nouveaute_vue(text) TO authenticated;

-- Liste de depart (proposee au garde-cap le 07/11 ; deja en production et
-- visible). Les lots suivants declarent leurs lignes dans leur migration.
INSERT INTO public.nouveautes (cle, sortie_le, roles, description) VALUES
  ('couleur_profil', '2026-11-06 12:00+00', ARRAY['guardian']::public.app_role[],
   'Fiche eleve : ligne « Couleur du profil » (COULEUR-PROFIL).'),
  ('moyen_paiement', '2026-11-06 12:00+00', ARRAY['guardian']::public.app_role[],
   'Fiche eleve : « Recharger », qui mene au choix du moyen de paiement (PAY-UX).'),
  ('historique_classe', '2026-11-07 10:00+00', ARRAY['guardian']::public.app_role[],
   'Onglet « Historique » : presence mesuree et nom de la classe (train D).'),
  ('recevoir_paiements', '2026-11-06 12:00+00', ARRAY['teacher']::public.app_role[],
   'Profil de l''enseignant : « Mes coordonnees de versement » (FINANCE-ENSEIGNANT).'),
  ('export_wise', '2026-11-06 12:00+00', ARRAY['admin']::public.app_role[],
   'Paie : « Preparer le fichier Wise du mois » (FINANCE-ENSEIGNANT).');

COMMENT ON FUNCTION public.mes_nouveautes() IS
  'F86: signature=public.mes_nouveautes(); guard_type=SESSION_POSITIVE; owner=postgres; search_path=""; date=2026-11-07. Lecture seule : compte valide, role de la ligne, sortie depuis moins de 14 jours, pas encore ouverte.';
COMMENT ON FUNCTION public.marquer_nouveaute_vue(text) IS
  'F86: signature=public.marquer_nouveaute_vue(text); guard_type=SESSION_POSITIVE; owner=postgres; search_path=""; date=2026-11-07. Garde : compte valide, role de la ligne ; idempotent.';

DO $postflight$
DECLARE
  v_oid regprocedure;
BEGIN
  FOREACH v_oid IN ARRAY ARRAY['public.mes_nouveautes()'::regprocedure,
                               'public.marquer_nouveaute_vue(text)'::regprocedure] LOOP
    IF NOT EXISTS (SELECT 1 FROM pg_catalog.pg_proc p
                    WHERE p.oid = v_oid AND p.prosecdef AND p.proowner = 'postgres'::regrole
                      AND p.proconfig @> ARRAY['search_path=""'])
       OR pg_catalog.has_function_privilege('anon', v_oid, 'EXECUTE')
       OR NOT pg_catalog.has_function_privilege('authenticated', v_oid, 'EXECUTE') THEN
      RAISE EXCEPTION 'NOUVEAUTES : DEFINER ou ACL invalide pour %', v_oid;
    END IF;
  END LOOP;
  IF pg_catalog.has_table_privilege('authenticated', 'public.nouveautes', 'INSERT')
     OR pg_catalog.has_table_privilege('authenticated', 'public.nouveautes_vues', 'INSERT') THEN
    RAISE EXCEPTION 'NOUVEAUTES : ecriture client ouverte';
  END IF;
END
$postflight$;

COMMIT;
