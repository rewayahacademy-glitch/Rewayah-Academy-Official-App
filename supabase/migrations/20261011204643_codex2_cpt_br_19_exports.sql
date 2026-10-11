-- CPT-BR-19: exports comptables stockes en texte dans un journal append-only.
BEGIN;

CREATE TABLE public.exports_comptables (
  reference text PRIMARY KEY,
  perimetre text NOT NULL CHECK (perimetre IN ('rapport', 'selection')),
  periode_debut date,
  periode_fin date,
  identifiants uuid[],
  nb_lignes integer NOT NULL CHECK (nb_lignes BETWEEN 0 AND 5000),
  csv text NOT NULL,
  cree_par uuid NOT NULL DEFAULT auth.uid(),
  cree_le timestamptz NOT NULL DEFAULT now(),
  cle_idempotence text NOT NULL CHECK (char_length(cle_idempotence) BETWEEN 1 AND 200),
  UNIQUE (cree_par, cle_idempotence),
  CHECK (
    (perimetre = 'rapport' AND periode_debut IS NOT NULL
      AND periode_fin IS NOT NULL AND identifiants IS NULL)
    OR
    (perimetre = 'selection' AND periode_debut IS NULL
      AND periode_fin IS NULL AND identifiants IS NOT NULL)
  )
);

CREATE INDEX exports_comptables_cree_le_idx
  ON public.exports_comptables (cree_par, cree_le DESC);

ALTER TABLE public.exports_comptables ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON TABLE public.exports_comptables
  FROM PUBLIC, anon, authenticated, service_role;
GRANT SELECT, INSERT ON TABLE public.exports_comptables TO authenticated;

CREATE POLICY exports_comptables_own_read
  ON public.exports_comptables FOR SELECT TO authenticated
  USING (
    coalesce(public.app_account_valid() AND (
      public.app_role() = 'admin' OR
      (public.app_role() = 'accountant' AND cree_par = auth.uid())
    ), false)
  );
CREATE POLICY exports_comptables_finance_insert
  ON public.exports_comptables FOR INSERT TO authenticated
  WITH CHECK (
    coalesce(public.app_account_valid()
      AND public.app_role() IN ('admin', 'accountant')
      AND cree_par = auth.uid(), false)
  );

CREATE FUNCTION public.refuser_modification_exports_comptables()
RETURNS trigger
LANGUAGE plpgsql
SECURITY INVOKER
SET search_path = ''
AS $function$
BEGIN
  RAISE EXCEPTION 'exports_comptables_append_only' USING ERRCODE = '55000';
END;
$function$;
CREATE TRIGGER exports_comptables_no_update
  BEFORE UPDATE ON public.exports_comptables
  FOR EACH ROW EXECUTE FUNCTION public.refuser_modification_exports_comptables();
CREATE TRIGGER exports_comptables_no_delete
  BEFORE DELETE ON public.exports_comptables
  FOR EACH ROW EXECUTE FUNCTION public.refuser_modification_exports_comptables();
REVOKE ALL ON FUNCTION public.refuser_modification_exports_comptables()
  FROM PUBLIC, anon, authenticated, service_role;

CREATE FUNCTION public.csv_comptable_cell(p_value text)
RETURNS text
LANGUAGE plpgsql
IMMUTABLE
SECURITY INVOKER
SET search_path = ''
AS $function$
DECLARE
  v_value text := coalesce(p_value, '');
BEGIN
  IF left(v_value, 1) = ANY (ARRAY['=', '+', '-', '@', E'\t', E'\r', E'\n']) THEN
    v_value := '''' || v_value;
  END IF;
  RETURN '"' || replace(v_value, '"', '""') || '"';
END;
$function$;
REVOKE ALL ON FUNCTION public.csv_comptable_cell(text) FROM PUBLIC, anon, service_role;
GRANT EXECUTE ON FUNCTION public.csv_comptable_cell(text) TO authenticated;

CREATE FUNCTION public.montant_comptable_decimal(p_minor bigint, p_currency text)
RETURNS text
LANGUAGE plpgsql
IMMUTABLE
SECURITY INVOKER
SET search_path = ''
AS $function$
DECLARE
  v_decimals integer := CASE p_currency
    WHEN 'JPY' THEN 0 WHEN 'XOF' THEN 0 WHEN 'XAF' THEN 0 WHEN 'KMF' THEN 0
    WHEN 'KWD' THEN 3 WHEN 'BHD' THEN 3 WHEN 'TND' THEN 3 WHEN 'OMR' THEN 3
    ELSE 2 END;
  v_scale numeric;
  v_absolute numeric := abs(p_minor::numeric);
  v_whole text;
  v_fraction text;
BEGIN
  v_scale := power(10::numeric, v_decimals);
  v_whole := trunc(v_absolute / v_scale)::text;
  IF v_decimals = 0 THEN
    RETURN CASE WHEN p_minor < 0 THEN '-' ELSE '' END || v_whole;
  END IF;
  v_fraction := lpad(mod(v_absolute, v_scale)::bigint::text, v_decimals, '0');
  RETURN (CASE WHEN p_minor < 0 THEN '-' ELSE '' END)
      || v_whole || '.' || v_fraction;
END;
$function$;
REVOKE ALL ON FUNCTION public.montant_comptable_decimal(bigint, text)
  FROM PUBLIC, anon, service_role;
GRANT EXECUTE ON FUNCTION public.montant_comptable_decimal(bigint, text)
  TO authenticated;

CREATE FUNCTION public.exporter_rapport_comptable(p_cle text)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY INVOKER
SET search_path = ''
AS $function$
DECLARE
  v_existing public.exports_comptables%ROWTYPE;
  v_reference text;
  v_today date;
  v_tz text;
  v_start date;
  v_end date;
  v_count integer;
  v_csv text;
  v_created public.exports_comptables%ROWTYPE;
BEGIN
  IF NOT coalesce(public.app_account_valid()
      AND public.app_role() IN ('admin', 'accountant'), false) THEN
    RAISE EXCEPTION 'export_comptable_interdit' USING ERRCODE = '42501';
  END IF;
  IF p_cle IS NULL OR char_length(p_cle) NOT BETWEEN 1 AND 200 THEN
    RAISE EXCEPTION 'cle_idempotence_invalide' USING ERRCODE = '22023';
  END IF;

  SELECT * INTO v_existing FROM public.exports_comptables e
   WHERE e.cree_par = auth.uid() AND e.cle_idempotence = p_cle;
  IF FOUND THEN
    RETURN jsonb_build_object('reference', v_existing.reference, 'lignes', v_existing.nb_lignes);
  END IF;

  SELECT coalesce(c.value #>> '{}', 'Europe/Paris') INTO v_tz
    FROM public.app_config c WHERE c.key = 'fuseau_comptable';
  v_tz := coalesce(v_tz, 'Europe/Paris');
  IF NOT EXISTS (SELECT 1 FROM pg_catalog.pg_timezone_names z WHERE z.name = v_tz) THEN
    RAISE EXCEPTION 'fuseau_comptable_invalide' USING ERRCODE = '22023';
  END IF;
  v_today := (statement_timestamp() AT TIME ZONE v_tz)::date;
  v_start := date_trunc('month', v_today::timestamp)::date;
  v_end := v_today;

  WITH scoped AS MATERIALIZED (
    SELECT m.*
      FROM public.tresorerie_mouvements m
     WHERE m.survenu_le >= (v_start::timestamp AT TIME ZONE v_tz)
       AND m.survenu_le < ((v_end + 1)::timestamp AT TIME ZONE v_tz)
     ORDER BY m.survenu_le, m.id
     LIMIT 5001
  ),
  stats AS (SELECT count(*)::integer AS n FROM scoped),
  content AS (
    SELECT string_agg(
      public.csv_comptable_cell(to_char(m.survenu_le AT TIME ZONE v_tz, 'YYYY-MM-DD"T"HH24:MI:SS')) || ';' ||
      public.csv_comptable_cell(m.coffre) || ';' ||
      public.csv_comptable_cell(m.sens) || ';' ||
      public.csv_comptable_cell(public.montant_comptable_decimal(m.montant_minor, m.devise)) || ';' ||
      public.csv_comptable_cell(m.montant_minor::text) || ';' ||
      public.csv_comptable_cell(m.devise) || ';' ||
      public.csv_comptable_cell(public.montant_comptable_decimal(m.montant_ref_minor, m.devise_ref)) || ';' ||
      public.csv_comptable_cell(m.montant_ref_minor::text) || ';' ||
      public.csv_comptable_cell(m.devise_ref) || ';' ||
      public.csv_comptable_cell((m.transfert_id IS NOT NULL)::text) || ';' ||
      public.csv_comptable_cell(m.source_type) || ';' ||
      public.csv_comptable_cell(m.source_id) || ';' ||
      public.csv_comptable_cell(m.note), E'\r\n' ORDER BY m.survenu_le, m.id
    ) AS rows_csv FROM scoped m
  )
  SELECT s.n,
         chr(65279) ||
         'date;coffre;sens;montant;montant_mineur;devise;montant_ref;montant_ref_mineur;devise_ref;transfert;source_type;source_id;note' || E'\r\n' ||
         coalesce(c.rows_csv, '')
    INTO v_count, v_csv
    FROM stats s CROSS JOIN content c;
  IF v_count > 5000 THEN
    RAISE EXCEPTION 'export_trop_volumineux' USING ERRCODE = '54000';
  END IF;

  v_reference := 'EXP-' || to_char(statement_timestamp() AT TIME ZONE v_tz, 'YYYYMMDD')
    || '-' || upper(substr(md5(gen_random_uuid()::text), 1, 6));
  INSERT INTO public.exports_comptables (
    reference, perimetre, periode_debut, periode_fin, nb_lignes, csv, cree_par, cle_idempotence
  ) VALUES (
    v_reference, 'rapport', v_start, v_end, v_count, v_csv, auth.uid(), p_cle
  ) ON CONFLICT (cree_par, cle_idempotence) DO NOTHING
  RETURNING * INTO v_created;
  IF NOT FOUND THEN
    SELECT * INTO v_created FROM public.exports_comptables e
     WHERE e.cree_par = auth.uid() AND e.cle_idempotence = p_cle;
  END IF;
  RETURN jsonb_build_object('reference', v_created.reference, 'lignes', v_created.nb_lignes);
END;
$function$;

CREATE FUNCTION public.exporter_selection_comptable(p_ids uuid[], p_cle text)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY INVOKER
SET search_path = ''
AS $function$
DECLARE
  v_existing public.exports_comptables%ROWTYPE;
  v_reference text;
  v_tz text;
  v_count integer;
  v_csv text;
  v_created public.exports_comptables%ROWTYPE;
BEGIN
  IF NOT coalesce(public.app_account_valid()
      AND public.app_role() IN ('admin', 'accountant'), false) THEN
    RAISE EXCEPTION 'export_comptable_interdit' USING ERRCODE = '42501';
  END IF;
  IF p_cle IS NULL OR char_length(p_cle) NOT BETWEEN 1 AND 200 THEN
    RAISE EXCEPTION 'cle_idempotence_invalide' USING ERRCODE = '22023';
  END IF;
  IF p_ids IS NULL OR cardinality(p_ids) NOT BETWEEN 1 AND 500
     OR array_position(p_ids, NULL) IS NOT NULL
     OR (SELECT count(DISTINCT id) FROM unnest(p_ids) AS x(id)) <> cardinality(p_ids) THEN
    RAISE EXCEPTION 'selection_invalide' USING ERRCODE = '22023';
  END IF;

  SELECT * INTO v_existing FROM public.exports_comptables e
   WHERE e.cree_par = auth.uid() AND e.cle_idempotence = p_cle;
  IF FOUND THEN
    RETURN jsonb_build_object('reference', v_existing.reference, 'lignes', v_existing.nb_lignes);
  END IF;

  SELECT coalesce(c.value #>> '{}', 'Europe/Paris') INTO v_tz
    FROM public.app_config c WHERE c.key = 'fuseau_comptable';
  v_tz := coalesce(v_tz, 'Europe/Paris');
  IF NOT EXISTS (SELECT 1 FROM pg_catalog.pg_timezone_names z WHERE z.name = v_tz) THEN
    RAISE EXCEPTION 'fuseau_comptable_invalide' USING ERRCODE = '22023';
  END IF;

  WITH scoped AS MATERIALIZED (
    SELECT p.id, p.created_at, p.status, p.amount_minor, w.currency,
           pm.kind, pm.profile_id
      FROM public.payouts p
      JOIN public.wallets w ON w.id = p.wallet_id
      JOIN public.payout_methods pm ON pm.id = p.payout_method_id
     WHERE p.id = ANY (p_ids)
     ORDER BY p.id
     LIMIT 501
  ),
  stats AS (SELECT count(*)::integer AS n FROM scoped),
  content AS (
    SELECT string_agg(
      public.csv_comptable_cell(p.id::text) || ';' ||
      public.csv_comptable_cell(to_char(p.created_at AT TIME ZONE v_tz, 'YYYY-MM-DD"T"HH24:MI:SS')) || ';' ||
      public.csv_comptable_cell(p.status) || ';' ||
      public.csv_comptable_cell(public.montant_comptable_decimal(p.amount_minor, p.currency)) || ';' ||
      public.csv_comptable_cell(p.amount_minor::text) || ';' ||
      public.csv_comptable_cell(p.currency) || ';' ||
      public.csv_comptable_cell(p.kind) || ';' ||
      public.csv_comptable_cell(p.profile_id::text), E'\r\n' ORDER BY p.id
    ) AS rows_csv FROM scoped p
  )
  SELECT s.n,
         chr(65279) ||
         'paiement_id;cree_le;statut;montant;montant_mineur;devise;methode_type;beneficiaire_profil_id' || E'\r\n' ||
         coalesce(c.rows_csv, '')
    INTO v_count, v_csv
    FROM stats s CROSS JOIN content c;
  IF v_count <> cardinality(p_ids) THEN
    RAISE EXCEPTION 'selection_invalide' USING ERRCODE = '22023';
  END IF;

  v_reference := 'EXP-' || to_char(statement_timestamp() AT TIME ZONE v_tz, 'YYYYMMDD')
    || '-' || upper(substr(md5(gen_random_uuid()::text), 1, 6));
  INSERT INTO public.exports_comptables (
    reference, perimetre, identifiants, nb_lignes, csv, cree_par, cle_idempotence
  ) VALUES (
    v_reference, 'selection', p_ids, v_count, v_csv, auth.uid(), p_cle
  ) ON CONFLICT (cree_par, cle_idempotence) DO NOTHING
  RETURNING * INTO v_created;
  IF NOT FOUND THEN
    SELECT * INTO v_created FROM public.exports_comptables e
     WHERE e.cree_par = auth.uid() AND e.cle_idempotence = p_cle;
  END IF;
  RETURN jsonb_build_object('reference', v_created.reference, 'lignes', v_created.nb_lignes);
END;
$function$;

REVOKE ALL ON FUNCTION public.exporter_rapport_comptable(text)
  FROM PUBLIC, anon, service_role;
REVOKE ALL ON FUNCTION public.exporter_selection_comptable(uuid[], text)
  FROM PUBLIC, anon, service_role;
GRANT EXECUTE ON FUNCTION public.exporter_rapport_comptable(text) TO authenticated;
GRANT EXECUTE ON FUNCTION public.exporter_selection_comptable(uuid[], text) TO authenticated;

COMMIT;
