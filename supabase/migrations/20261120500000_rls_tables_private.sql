-- RLS-PRIVATE (08/11/2026), signale par le garde-cap, demande du pilote : quatre
-- tables du schema private n'avaient pas la RLS active, contre la regle « RLS
-- activee sur toutes les tables, sans exception » (supabase/CLAUDE.md) :
--   private.remplacements_prets_candidats   (20261120300200, HARMONISATION-A)
--   private.remplacements_acceptations      (20261119300000, REMPLACEMENT)
--   private.entretien_avis_envoyes          (20261119200000, SALLE-2)
--   private.rech_d1_curseurs                (20261012130003, recherche D1)
--
-- Ce fichier active la RLS, sans policy et sans FORCE : aucun compte client ne
-- lit ni n'ecrit ces tables directement (aucun privilege accorde hors du
-- proprietaire). Les fonctions qui les lisent et les ecrivent sont SECURITY
-- DEFINER et appartiennent a postgres, proprietaire des quatre tables : sans
-- FORCE, le proprietaire n'est pas soumis a la RLS, leur comportement ne change
-- pas. Releve du 08/11 sur une base neuve (toutes les migrations) :
--   se_declarer_pret_remplacement, prendre_remplacement,
--   private.remplacement_fenetres_passer, private.remplacement_choisir,
--   private.remplacement_choisir_pret, private.entretien_avis_passer,
--   private.rech_d1_curseur_creer, private.rech_d1_curseur_lire.
-- Preuve : supabase/tests/scenarios_rls_tables_private.sql.
--
-- Aucun BEGIN/COMMIT au premier niveau, aucun mot d'effacement, aucune policy.

DO $preflight$
DECLARE
  t text;
BEGIN
  FOREACH t IN ARRAY ARRAY['remplacements_prets_candidats', 'remplacements_acceptations',
                           'entretien_avis_envoyes', 'rech_d1_curseurs'] LOOP
    IF pg_catalog.to_regclass('private.' || t) IS NULL THEN
      RAISE EXCEPTION 'RLS-PRIVATE : la table private.% manque', t;
    END IF;
  END LOOP;
END;
$preflight$;

ALTER TABLE private.remplacements_prets_candidats ENABLE ROW LEVEL SECURITY;
ALTER TABLE private.remplacements_acceptations ENABLE ROW LEVEL SECURITY;
ALTER TABLE private.entretien_avis_envoyes ENABLE ROW LEVEL SECURITY;
ALTER TABLE private.rech_d1_curseurs ENABLE ROW LEVEL SECURITY;

DO $postflight$
DECLARE
  v record;
BEGIN
  FOR v IN
    SELECT c.relname, c.relrowsecurity, c.relforcerowsecurity
      FROM pg_catalog.pg_class c
      JOIN pg_catalog.pg_namespace n ON n.oid = c.relnamespace
     WHERE n.nspname = 'private'
       AND c.relname IN ('remplacements_prets_candidats', 'remplacements_acceptations',
                         'entretien_avis_envoyes', 'rech_d1_curseurs')
  LOOP
    IF NOT v.relrowsecurity OR v.relforcerowsecurity THEN
      RAISE EXCEPTION 'RLS-PRIVATE : private.% : RLS absente ou FORCE pose', v.relname;
    END IF;
  END LOOP;
  IF (SELECT pg_catalog.count(*)
        FROM pg_catalog.pg_class c
        JOIN pg_catalog.pg_namespace n ON n.oid = c.relnamespace
       WHERE n.nspname = 'private' AND c.relrowsecurity
         AND c.relname IN ('remplacements_prets_candidats', 'remplacements_acceptations',
                           'entretien_avis_envoyes', 'rech_d1_curseurs')) <> 4 THEN
    RAISE EXCEPTION 'RLS-PRIVATE : les quatre tables n''ont pas toutes la RLS';
  END IF;
END;
$postflight$;
