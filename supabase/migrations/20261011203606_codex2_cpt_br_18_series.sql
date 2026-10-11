-- CPT-BR-18: registre en lecture et series serveur.
-- L'alimentation automatique est distincte: le schema de base ne contient
-- ni source fiable de remuneration par seance, ni evenement de paiement
-- confirme pouvant etre lie sans ambiguite a wallet_entries. Voir X2-17-BLOQUE.
BEGIN;

CREATE TABLE public.tresorerie_mouvements (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  coffre text NOT NULL CHECK (coffre IN (
    'fonds_clients_engages', 'paie_a_decaisser', 'charges_essentielles',
    'taxes_obligations', 'reserve_strategique', 'en_transit', 'tresorerie_libre'
  )),
  sens text NOT NULL CHECK (sens IN ('entree', 'sortie')),
  montant_minor bigint NOT NULL CHECK (montant_minor > 0),
  devise text NOT NULL CHECK (devise ~ '^[A-Z]{3}$'),
  montant_ref_minor bigint NOT NULL CHECK (montant_ref_minor > 0),
  devise_ref text NOT NULL CHECK (devise_ref = 'USD'),
  survenu_le timestamptz NOT NULL,
  transfert_id uuid,
  source_type text NOT NULL CHECK (source_type IN (
    'encaissement', 'prestation', 'remboursement', 'payout',
    'transfert_interne', 'correction'
  )),
  regle text NOT NULL,
  source_id text,
  note text CHECK (char_length(note) <= 500),
  motif text,
  cree_par uuid,
  cree_le timestamptz NOT NULL DEFAULT now(),
  UNIQUE (source_type, source_id, regle, coffre, sens),
  CHECK (source_type NOT IN ('transfert_interne', 'correction') OR nullif(btrim(motif), '') IS NOT NULL)
);

CREATE INDEX tresorerie_mouvements_survenu_idx
  ON public.tresorerie_mouvements (survenu_le, id);
CREATE INDEX tresorerie_mouvements_coffre_idx
  ON public.tresorerie_mouvements (coffre, survenu_le);

CREATE FUNCTION public.refuser_modification_tresorerie()
RETURNS trigger
LANGUAGE plpgsql
SECURITY INVOKER
SET search_path = ''
AS $function$
BEGIN
  RAISE EXCEPTION 'tresorerie_mouvements_append_only' USING ERRCODE = '55000';
END;
$function$;

CREATE TRIGGER tresorerie_mouvements_no_update
  BEFORE UPDATE ON public.tresorerie_mouvements
  FOR EACH ROW EXECUTE FUNCTION public.refuser_modification_tresorerie();
CREATE TRIGGER tresorerie_mouvements_no_delete
  BEFORE DELETE ON public.tresorerie_mouvements
  FOR EACH ROW EXECUTE FUNCTION public.refuser_modification_tresorerie();

ALTER TABLE public.tresorerie_mouvements ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON TABLE public.tresorerie_mouvements
  FROM PUBLIC, anon, authenticated, service_role;
GRANT SELECT ON TABLE public.tresorerie_mouvements TO authenticated;
REVOKE ALL ON FUNCTION public.refuser_modification_tresorerie()
  FROM PUBLIC, anon, authenticated, service_role;
CREATE POLICY tresorerie_mouvements_finance_read
  ON public.tresorerie_mouvements FOR SELECT TO authenticated
  USING (
    coalesce(public.app_account_valid()
      AND public.app_role() IN ('admin', 'accountant'), false)
  );

-- Valeurs de référence explicites du contrat v2. Le fuseau peut être changé
-- par l'administration; la devise USD est la décision datée du directeur.
INSERT INTO public.app_config (key, value)
VALUES ('fuseau_comptable', '"Europe/Paris"'::jsonb)
ON CONFLICT (key) DO NOTHING;
INSERT INTO public.app_config (key, value)
VALUES ('devise_reference', '"USD"'::jsonb)
ON CONFLICT (key) DO UPDATE SET value = EXCLUDED.value, updated_at = now();

CREATE POLICY app_config_finance_read
  ON public.app_config FOR SELECT TO authenticated
  USING (
    key IN ('fuseau_comptable', 'devise_reference')
    AND coalesce(public.app_account_valid()
      AND public.app_role() IN ('admin', 'accountant'), false)
  );

CREATE FUNCTION public.series_tresorerie()
RETURNS jsonb
LANGUAGE plpgsql
STABLE
SECURITY INVOKER
SET search_path = ''
AS $function$
DECLARE
  v_now timestamptz := statement_timestamp();
  v_tz text;
  v_today date;
BEGIN
  IF NOT coalesce(
    public.app_account_valid()
      AND public.app_role() IN ('admin', 'accountant'), false
  ) THEN
    RAISE EXCEPTION 'series_tresorerie_interdite' USING ERRCODE = '42501';
  END IF;

  SELECT coalesce(c.value #>> '{}', 'Europe/Paris')
    INTO v_tz
    FROM public.app_config c
   WHERE c.key = 'fuseau_comptable';
  v_tz := coalesce(v_tz, 'Europe/Paris');
  IF NOT EXISTS (SELECT 1 FROM pg_catalog.pg_timezone_names z WHERE z.name = v_tz) THEN
    RAISE EXCEPTION 'fuseau_comptable_invalide' USING ERRCODE = '22023';
  END IF;
  v_today := (v_now AT TIME ZONE v_tz)::date;

  RETURN (
    WITH coffres(coffre, ordre) AS (
      VALUES
        ('fonds_clients_engages', 1), ('paie_a_decaisser', 2),
        ('charges_essentielles', 3), ('taxes_obligations', 4),
        ('reserve_strategique', 5), ('en_transit', 6), ('tresorerie_libre', 7)
    ),
    mois AS (
      SELECT (date_trunc('month', v_today::timestamp) -
              make_interval(months => 5 - n))::date AS debut
        FROM generate_series(0, 5) AS g(n)
    ),
    jours AS (
      SELECT v_today - (29 - n) AS jour FROM generate_series(0, 29) AS g(n)
    ),
    balances AS (
      SELECT m.coffre,
             coalesce(sum(CASE WHEN m.sens = 'entree'
                               THEN m.montant_ref_minor ELSE -m.montant_ref_minor END), 0) AS solde
        FROM public.tresorerie_mouvements m
       GROUP BY m.coffre
    ),
    mensuel AS (
      SELECT d.debut,
             coalesce(sum(m.montant_ref_minor) FILTER (WHERE m.sens = 'entree'), 0) AS entrees,
             coalesce(sum(m.montant_ref_minor) FILTER (WHERE m.sens = 'sortie'), 0) AS sorties
        FROM mois d
        LEFT JOIN public.tresorerie_mouvements m
          ON m.transfert_id IS NULL
         AND m.survenu_le >= (d.debut::timestamp AT TIME ZONE v_tz)
         AND m.survenu_le < ((d.debut + interval '1 month') AT TIME ZONE v_tz)
       GROUP BY d.debut
    ),
    flux AS (
      SELECT d.jour,
             coalesce(sum(m.montant_ref_minor) FILTER (WHERE m.sens = 'entree'), 0) AS entrees,
             coalesce(sum(m.montant_ref_minor) FILTER (WHERE m.sens = 'sortie'), 0) AS sorties
        FROM jours d
        LEFT JOIN public.tresorerie_mouvements m
          ON m.transfert_id IS NULL
         AND m.survenu_le >= (d.jour::timestamp AT TIME ZONE v_tz)
         AND m.survenu_le < ((d.jour + 1)::timestamp AT TIME ZONE v_tz)
       GROUP BY d.jour
    ),
    evolution AS (
      SELECT d.debut,
             coalesce(sum(CASE WHEN m.sens = 'entree'
                               THEN m.montant_ref_minor ELSE -m.montant_ref_minor END), 0) AS detenue
        FROM mois d
        LEFT JOIN public.tresorerie_mouvements m
          ON m.survenu_le < CASE
               WHEN d.debut = date_trunc('month', v_today::timestamp)::date THEN v_now
               ELSE ((d.debut + interval '1 month') AT TIME ZONE v_tz)
             END
       GROUP BY d.debut
    ),
    totaux AS (
      SELECT
        coalesce(sum(m.montant_ref_minor) FILTER (
          WHERE m.transfert_id IS NULL AND m.sens = 'entree'
            AND m.survenu_le >= ((v_today - 29)::timestamp AT TIME ZONE v_tz)
            AND m.survenu_le < ((v_today + 1)::timestamp AT TIME ZONE v_tz)
        ), 0) AS entrees_30,
        coalesce(sum(m.montant_ref_minor) FILTER (
          WHERE m.transfert_id IS NULL AND m.sens = 'sortie'
            AND m.survenu_le >= ((v_today - 29)::timestamp AT TIME ZONE v_tz)
            AND m.survenu_le < ((v_today + 1)::timestamp AT TIME ZONE v_tz)
        ), 0) AS sorties_30,
        coalesce(sum(m.montant_ref_minor) FILTER (
          WHERE m.transfert_id IS NULL AND m.sens = 'entree'
            AND m.survenu_le >= ((v_today - 59)::timestamp AT TIME ZONE v_tz)
            AND m.survenu_le < ((v_today - 29)::timestamp AT TIME ZONE v_tz)
        ), 0) AS entrees_precedentes,
        coalesce(sum(m.montant_ref_minor) FILTER (
          WHERE m.transfert_id IS NULL AND m.sens = 'sortie'
            AND m.survenu_le >= ((v_today - 59)::timestamp AT TIME ZONE v_tz)
            AND m.survenu_le < ((v_today - 29)::timestamp AT TIME ZONE v_tz)
        ), 0) AS sorties_precedentes
      FROM public.tresorerie_mouvements m
    )
    SELECT jsonb_build_object(
      'repartition', (SELECT jsonb_agg(jsonb_build_object(
        'coffre', c.coffre,
        'montant', jsonb_build_object('mineur', coalesce(b.solde, 0), 'devise', 'USD')
      ) ORDER BY c.ordre) FROM coffres c LEFT JOIN balances b USING (coffre)),
      'mensuel', (SELECT jsonb_agg(jsonb_build_object(
        'mois', to_char(x.debut, 'YYYY-MM-DD'),
        'entrees', jsonb_build_object('mineur', x.entrees, 'devise', 'USD'),
        'sorties', jsonb_build_object('mineur', x.sorties, 'devise', 'USD')
      ) ORDER BY x.debut) FROM mensuel x),
      'flux30Jours', (SELECT jsonb_agg(jsonb_build_object(
        'jour', to_char(x.jour, 'YYYY-MM-DD'),
        'encaissements', jsonb_build_object('mineur', x.entrees, 'devise', 'USD'),
        'decaissements', jsonb_build_object('mineur', x.sorties, 'devise', 'USD')
      ) ORDER BY x.jour) FROM flux x),
      'evolution', (SELECT jsonb_agg(jsonb_build_object(
        'mois', to_char(x.debut, 'YYYY-MM-DD'),
        'detenue', jsonb_build_object('mineur', x.detenue, 'devise', 'USD')
      ) ORDER BY x.debut) FROM evolution x),
      'entrees30Jours', jsonb_build_object('mineur', t.entrees_30, 'devise', 'USD'),
      'sorties30Jours', jsonb_build_object('mineur', t.sorties_30, 'devise', 'USD'),
      'variationEntreesPourMille', CASE WHEN t.entrees_precedentes = 0 THEN NULL
        ELSE round((t.entrees_30 - t.entrees_precedentes) * 1000 / t.entrees_precedentes)::bigint END,
      'variationSortiesPourMille', CASE WHEN t.sorties_precedentes = 0 THEN NULL
        ELSE round((t.sorties_30 - t.sorties_precedentes) * 1000 / t.sorties_precedentes)::bigint END
    ) FROM totaux t
  );
END;
$function$;

REVOKE ALL ON FUNCTION public.series_tresorerie() FROM PUBLIC, anon, service_role;
GRANT EXECUTE ON FUNCTION public.series_tresorerie() TO authenticated;

COMMIT;
