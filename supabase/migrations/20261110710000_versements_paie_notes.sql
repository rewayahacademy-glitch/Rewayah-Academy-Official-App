-- FINANCE-ENSEIGNANT (lot 9, 06/11/2026), socle commun demande par le
-- garde-cap : la direction NOTE un versement de paie fait hors de
-- l'application (virement, mobile money), et l'enseignant le voit.
--
-- Aucun prestataire ici (ni Stripe Connect ni Global Payouts) : c'est le socle
-- des deux options posees au directeur. Le seul enseignant en production vit en
-- Guinee, qu'aucun prestataire tout pret ne couvre.
--
-- Regles :
--   * la direction (admin) ou la comptabilite (accountant), compte valide,
--     note : enseignant, montant en unite mineure, devise, date du versement,
--     moyen, reference de l'operation, mois de paie, note ; une cle
--     d'idempotence (double clic = un seul versement) ;
--   * la reference est celle de l'OPERATION (numero de transaction), jamais un
--     numero de compte : bornee a 60 caracteres, sans espace ; la note a 500 ;
--   * tresorerie : sortie de `paie_a_decaisser` (source `payout`, regle
--     `versement_note`), au montant de reference USD du jour ; sans taux de
--     change, la ligne part en reprise (`tresorerie_a_reprendre`), comme les
--     autres alimentations (X2-17) ;
--   * une erreur s'annule avec un motif, jamais par effacement : la ligne
--     reste, marquee annulee, et la tresorerie recoit l'ecriture inverse ;
--   * l'enseignant lit SES versements (`mes_versements_paie`), sans note
--     interne ni auteur ;
--   * aucun calcul de paie ici : le montant du est celui de la tresorerie
--     (`releve_paie_mensuel`), non recalcule, non compare.
-- RLS active, aucun droit direct ; SECURITY DEFINER, search_path vide ; aucune
-- instruction d'effacement.

BEGIN;

CREATE TABLE public.versements_paie (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  enseignant_id uuid NOT NULL REFERENCES public.profiles(id),
  montant_minor bigint NOT NULL CHECK (montant_minor > 0),
  devise text NOT NULL CHECK (devise ~ '^[A-Z]{3}$'),
  verse_le date NOT NULL,
  mois date NOT NULL CHECK (mois = date_trunc('month', mois)::date),
  moyen text NOT NULL CHECK (moyen IN ('virement_bancaire', 'mobile_money', 'autre')),
  reference text CHECK (reference IS NULL OR reference ~ '^[A-Za-z0-9_\-:./#]{1,60}$'),
  note text CHECK (note IS NULL OR pg_catalog.char_length(note) <= 500),
  cle uuid NOT NULL UNIQUE,
  saisi_par uuid NOT NULL REFERENCES public.profiles(id),
  saisi_le timestamptz NOT NULL DEFAULT now(),
  annule_le timestamptz,
  annule_par uuid REFERENCES public.profiles(id),
  annule_motif text,
  CHECK ((annule_le IS NULL) = (annule_par IS NULL)
     AND (annule_le IS NULL OR pg_catalog.char_length(pg_catalog.btrim(annule_motif)) BETWEEN 3 AND 500))
);
CREATE INDEX versements_paie_enseignant ON public.versements_paie (enseignant_id, verse_le DESC);
CREATE INDEX versements_paie_mois ON public.versements_paie (mois);

ALTER TABLE public.versements_paie ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON public.versements_paie FROM PUBLIC, anon, authenticated, service_role;

-- Vrai pour la direction ou la comptabilite, compte valide.
CREATE FUNCTION private.versement_note_autorise()
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $function$
  SELECT coalesce(public.app_role() IN ('admin', 'accountant') AND public.app_account_valid(), false);
$function$;
REVOKE ALL ON FUNCTION private.versement_note_autorise() FROM PUBLIC, anon, authenticated, service_role;

-- Une ligne, vue par la direction.
CREATE FUNCTION private.versement_note_json(p public.versements_paie)
RETURNS jsonb
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $function$
  SELECT pg_catalog.jsonb_build_object(
    'id', p.id, 'enseignant', p.enseignant_id,
    'prenom', e.first_name, 'nom', e.last_name,
    'montant', pg_catalog.jsonb_build_object('mineur', p.montant_minor, 'devise', p.devise),
    'verseLe', p.verse_le, 'mois', p.mois, 'moyen', p.moyen,
    'reference', p.reference, 'note', p.note,
    'saisiLe', p.saisi_le, 'annuleLe', p.annule_le, 'annuleMotif', p.annule_motif)
    FROM public.profiles e WHERE e.id = p.enseignant_id;
$function$;
REVOKE ALL ON FUNCTION private.versement_note_json(public.versements_paie)
  FROM PUBLIC, anon, authenticated, service_role;

-- Noter un versement.
CREATE FUNCTION public.versement_paie_noter(
  p_enseignant uuid, p_montant_minor bigint, p_devise text, p_verse_le date,
  p_moyen text, p_reference text, p_mois date, p_note text, p_cle uuid)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  v_ligne public.versements_paie%ROWTYPE;
  v_ref bigint;
  v_at timestamptz := pg_catalog.clock_timestamp();
BEGIN
  IF NOT private.versement_note_autorise() THEN
    RAISE EXCEPTION 'reserve a la direction et a la comptabilite' USING ERRCODE = '42501';
  END IF;
  IF p_cle IS NULL THEN
    RAISE EXCEPTION 'cle absente' USING ERRCODE = '22023';
  END IF;
  -- Idempotence : la meme cle rend le meme versement, sans rien ecrire.
  SELECT * INTO v_ligne FROM public.versements_paie v WHERE v.cle = p_cle;
  IF FOUND THEN
    RETURN private.versement_note_json(v_ligne);
  END IF;
  IF NOT EXISTS (SELECT 1 FROM public.profiles p
                  WHERE p.id = p_enseignant AND p.role = 'teacher' AND p.deleted_at IS NULL) THEN
    RAISE EXCEPTION 'enseignant introuvable' USING ERRCODE = 'P0002';
  END IF;
  IF p_montant_minor IS NULL OR p_montant_minor <= 0 THEN
    RAISE EXCEPTION 'montant invalide' USING ERRCODE = '22023';
  END IF;
  IF p_verse_le IS NULL OR p_verse_le > (now() AT TIME ZONE 'UTC')::date + 1 THEN
    RAISE EXCEPTION 'date de versement invalide' USING ERRCODE = '22023';
  END IF;
  IF p_mois IS NULL THEN
    RAISE EXCEPTION 'mois de paie absent' USING ERRCODE = '22023';
  END IF;
  INSERT INTO public.versements_paie
    (enseignant_id, montant_minor, devise, verse_le, mois, moyen, reference, note, cle, saisi_par)
  VALUES (p_enseignant, p_montant_minor, p_devise, p_verse_le,
          date_trunc('month', p_mois)::date, p_moyen,
          nullif(pg_catalog.btrim(p_reference), ''), nullif(pg_catalog.btrim(p_note), ''),
          p_cle, auth.uid())
  RETURNING * INTO v_ligne;

  v_ref := public.x217_montant_ref(p_montant_minor, p_devise, v_at);
  IF v_ref IS NULL OR v_ref <= 0 THEN
    PERFORM public.x217_mettre_en_file('payout', v_ligne.id::text, 'taux_change_absent');
  ELSE
    INSERT INTO public.tresorerie_mouvements
      (coffre, sens, montant_minor, devise, montant_ref_minor, devise_ref, survenu_le,
       source_type, regle, source_id, cree_par)
    VALUES ('paie_a_decaisser', 'sortie', p_montant_minor, p_devise, v_ref, 'USD', v_at,
            'payout', 'versement_note', v_ligne.id::text, auth.uid())
    ON CONFLICT (source_type, source_id, regle, coffre, sens) DO NOTHING;
  END IF;
  RETURN private.versement_note_json(v_ligne);
END;
$function$;
REVOKE ALL ON FUNCTION public.versement_paie_noter(uuid, bigint, text, date, text, text, date, text, uuid)
  FROM PUBLIC, anon, service_role;
GRANT EXECUTE ON FUNCTION public.versement_paie_noter(uuid, bigint, text, date, text, text, date, text, uuid)
  TO authenticated;

-- Annuler un versement note par erreur : la ligne reste, l'ecriture inverse
-- rend le montant a `paie_a_decaisser`.
CREATE FUNCTION public.versement_paie_annuler(p_versement uuid, p_motif text)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  v_ligne public.versements_paie%ROWTYPE;
  v_sortie public.tresorerie_mouvements%ROWTYPE;
BEGIN
  IF NOT private.versement_note_autorise() THEN
    RAISE EXCEPTION 'reserve a la direction et a la comptabilite' USING ERRCODE = '42501';
  END IF;
  IF pg_catalog.char_length(pg_catalog.btrim(coalesce(p_motif, ''))) < 3 THEN
    RAISE EXCEPTION 'motif requis' USING ERRCODE = '22023';
  END IF;
  SELECT * INTO v_ligne FROM public.versements_paie v WHERE v.id = p_versement FOR UPDATE;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'versement introuvable' USING ERRCODE = 'P0002';
  END IF;
  IF v_ligne.annule_le IS NOT NULL THEN
    RETURN private.versement_note_json(v_ligne);
  END IF;
  UPDATE public.versements_paie
     SET annule_le = now(), annule_par = auth.uid(), annule_motif = pg_catalog.btrim(p_motif)
   WHERE id = p_versement
  RETURNING * INTO v_ligne;
  SELECT * INTO v_sortie FROM public.tresorerie_mouvements m
   WHERE m.source_type = 'payout' AND m.source_id = p_versement::text
     AND m.regle = 'versement_note' AND m.coffre = 'paie_a_decaisser' AND m.sens = 'sortie';
  IF FOUND THEN
    INSERT INTO public.tresorerie_mouvements
      (coffre, sens, montant_minor, devise, montant_ref_minor, devise_ref, survenu_le,
       source_type, regle, source_id, cree_par)
    VALUES ('paie_a_decaisser', 'entree', v_sortie.montant_minor, v_sortie.devise,
            v_sortie.montant_ref_minor, 'USD', pg_catalog.clock_timestamp(),
            'payout', 'versement_note_annule', p_versement::text, auth.uid())
    ON CONFLICT (source_type, source_id, regle, coffre, sens) DO NOTHING;
  END IF;
  RETURN private.versement_note_json(v_ligne);
END;
$function$;
REVOKE ALL ON FUNCTION public.versement_paie_annuler(uuid, text) FROM PUBLIC, anon, service_role;
GRANT EXECUTE ON FUNCTION public.versement_paie_annuler(uuid, text) TO authenticated;

-- La liste de la direction, par mois de paie (tous les mois si nul).
CREATE FUNCTION public.versements_paie_direction(p_mois date DEFAULT NULL)
RETURNS jsonb
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $function$
BEGIN
  IF NOT private.versement_note_autorise() THEN
    RAISE EXCEPTION 'reserve a la direction et a la comptabilite' USING ERRCODE = '42501';
  END IF;
  RETURN coalesce((
    SELECT pg_catalog.jsonb_agg(private.versement_note_json(v) ORDER BY v.verse_le DESC, v.saisi_le DESC)
      FROM public.versements_paie v
     WHERE p_mois IS NULL OR v.mois = date_trunc('month', p_mois)::date),
    '[]'::jsonb);
END;
$function$;
REVOKE ALL ON FUNCTION public.versements_paie_direction(date) FROM PUBLIC, anon, service_role;
GRANT EXECUTE ON FUNCTION public.versements_paie_direction(date) TO authenticated;

-- Ce que l'enseignant voit de SES versements : ni note interne, ni auteur.
CREATE FUNCTION public.mes_versements_paie()
RETURNS jsonb
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $function$
BEGIN
  IF NOT coalesce(public.app_role() = 'teacher' AND public.app_account_valid(), false) THEN
    RAISE EXCEPTION 'reserve a l''enseignant' USING ERRCODE = '42501';
  END IF;
  RETURN coalesce((
    SELECT pg_catalog.jsonb_agg(pg_catalog.jsonb_build_object(
             'id', v.id,
             'montant', pg_catalog.jsonb_build_object('mineur', v.montant_minor, 'devise', v.devise),
             'verseLe', v.verse_le, 'mois', v.mois, 'moyen', v.moyen,
             'reference', v.reference, 'annule', v.annule_le IS NOT NULL)
           ORDER BY v.verse_le DESC, v.saisi_le DESC)
      FROM public.versements_paie v
     WHERE v.enseignant_id = auth.uid()),
    '[]'::jsonb);
END;
$function$;
REVOKE ALL ON FUNCTION public.mes_versements_paie() FROM PUBLIC, anon, service_role;
GRANT EXECUTE ON FUNCTION public.mes_versements_paie() TO authenticated;

COMMIT;
