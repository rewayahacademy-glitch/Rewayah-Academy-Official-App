-- FAC-E-03 (19/10/2026) : l'enseignant recoit 47 % du prix, enfants et adultes.
--
-- Source : docs/current/DECISION-TARIFS-2026-10-18.md, section « Decision du
-- directeur du 19/10/2026 » (valeurs : docs/current/tarifs-2026-10-18.json).
-- Le directeur : « ramener le prof adulte a 47 % comme l'enfant ; tu rends le
-- nouveau le standard partout ».
--
-- * Paie par eleve present et par heure : 1,99 $ (enfant, 55 $ pour 13 h) et
--   1,57 $ (adulte, 65 $ pour 19,5 h), au lieu de 0,95 $ et 1,00 $. Le plafond
--   est le taux lui-meme : le palier de fidelite du 18/10 est abandonne.
-- * La contrainte « taux enfant <= taux adulte » tombe : a l'heure, l'enfant
--   vaut desormais plus que l'adulte (meme part d'un prix plus bas sur moins
--   d'heures).
-- * La v2.0.0 (en vigueur le 1er novembre 2026) porte ces valeurs. Une version
--   publiee ne change pas (`politiques_commerciales_immuable`) ; cette
--   migration la corrige une seule fois, avant qu'elle ait servi : elle refuse
--   de s'appliquer si une facture la cite ou si une paie a ete ecrite a partir
--   de sa date d'effet. Sinon, publier la version suivante depuis l'ecran
--   Finance > Politiques commerciales.
BEGIN;

ALTER TABLE public.politiques_commerciales
  DROP CONSTRAINT politiques_commerciales_taux_enfant_sous_adulte;

DO $correction$
DECLARE
  v_effet date;
BEGIN
  SELECT p.date_effet INTO v_effet FROM public.politiques_commerciales p WHERE p.version = 'v2.0.0';
  IF v_effet IS NULL THEN
    RAISE EXCEPTION 'FAC-E-03 : la politique v2.0.0 est absente';
  END IF;
  IF EXISTS (SELECT 1 FROM public.factures_mensuelles f WHERE f.politique_version = 'v2.0.0') THEN
    RAISE EXCEPTION 'FAC-E-03 : une facture cite deja la v2.0.0 ; publier la version suivante';
  END IF;
  IF EXISTS (SELECT 1 FROM public.tresorerie_mouvements m
              WHERE m.regle = 'remuneration_due'
                AND m.survenu_le >= v_effet::timestamp AT TIME ZONE 'Europe/Paris') THEN
    RAISE EXCEPTION 'FAC-E-03 : une paie a deja ete ecrite sous la v2.0.0 ; publier la version suivante';
  END IF;

  ALTER TABLE public.politiques_commerciales DISABLE TRIGGER politiques_commerciales_immuable;
  UPDATE public.politiques_commerciales
     SET taux_eleve_heure_enfant_mineur = 199,
         taux_eleve_heure_adulte_mineur = 157,
         plafond_eleve_heure_enfant_mineur = 199,
         plafond_eleve_heure_adulte_mineur = 157
   WHERE version = 'v2.0.0';
  ALTER TABLE public.politiques_commerciales ENABLE TRIGGER politiques_commerciales_immuable;
END;
$correction$;

COMMENT ON COLUMN public.politiques_commerciales.taux_eleve_heure_enfant_mineur IS
  'FAC-E-01, FAC-E-03 : paie de l''enseignant par eleve present et par heure, classe enfant (1,99 $ au 19/10/2026, 47 % du prix). Remplace base_horaire_mineur pour les versions qui le portent.';

DO $postflight$
BEGIN
  IF (SELECT (p.taux_eleve_heure_enfant_mineur, p.taux_eleve_heure_adulte_mineur,
              p.plafond_eleve_heure_enfant_mineur, p.plafond_eleve_heure_adulte_mineur)
        FROM public.politiques_commerciales p WHERE p.version = 'v2.0.0')
     IS DISTINCT FROM (199::bigint, 157::bigint, 199::bigint, 157::bigint) THEN
    RAISE EXCEPTION 'FAC-E-03 : la v2.0.0 ne porte pas la paie du 19/10';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_catalog.pg_trigger t
                  WHERE t.tgname = 'politiques_commerciales_immuable'
                    AND t.tgrelid = 'public.politiques_commerciales'::regclass
                    AND t.tgenabled = 'O') THEN
    RAISE EXCEPTION 'FAC-E-03 : la politique publiee doit rester immuable';
  END IF;
END;
$postflight$;

COMMIT;
