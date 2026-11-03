-- REMB-14 (02/11/2026, lot attribue par le pilote) : le delai de retractation
-- se lit dans la politique, jamais dans un texte.
--
-- Decision du directeur du 02/11/2026 (DECISION-TARIFS-2026-10-18.md) :
-- pendant le delai de retractation (14 jours a compter du paiement), la
-- famille est remboursee de ce qu'elle a paye, moins les seances suivies ;
-- ensuite, arreter une formule payee d'avance reste un droit (mois commences
-- au prix mensuel normal, sans la remise, le reste rendu). « Rien en dur : le
-- delai est la valeur remboursement_delai_jours de la politique en vigueur ».
--
-- Le calcul du montant (private.fn115c_montant_propose, FN-115c) suit deja
-- cette regle et lit deja le delai dans la politique : il ne change pas.
-- Ce fichier :
--   1. publie le delai dans tarifs_publics() (ouverte sans connexion, aucune
--      donnee de personne) : la page « Annulation et remboursement » de
--      l'application l'affiche ;
--   2. met a jour le commentaire de la colonne, qui disait la regle « en
--      attente du directeur ».
-- La valeur elle-meme (7 aujourd'hui, 14 selon la decision) se regle par une
-- nouvelle version publiee de la politique, par la direction : une version
-- publiee ne se modifie pas (fac_politique_immuable), et ce fichier n'y
-- touche pas.
--   3. repare la publication d'une nouvelle politique, cassee depuis FN-115c
--      (20261105100000) : private.fac_politique_lue ne lisait ni
--      seances_par_mois ni remboursement_delai_jours, la ligne les laissait a
--      NULL et « INSERT ... SELECT v.* » echouait sur NOT NULL (prouve sur une
--      base neuve : « null value in column "seances_par_mois" »). Un
--      declencheur reprend les deux valeurs de la version precedente quand
--      elles manquent (modele de pub_age_formule_herite) ;
--   4. fac_politique_lue lit la cle facultative `remboursementDelaiJours`
--      (0 a 60) et fac_politique_json l'ecrit : la direction peut publier le
--      delai decide.
--   5. decision du directeur du 02/11/2026 (« Migration, puis code ») : la
--      version v2.1.0, copie de toutes les colonnes de v2.0.0 avec
--      remboursement_delai_jours = 14, est inseree ici, publiee_par NULL comme
--      v1.0.0 et v2.0.0. Sa date d'effet est le jour de l'installation :
--      la version en vigueur un jour donne est celle de plus grande
--      date_effet <= ce jour (private.fac_politique_au), et « aujourd'hui »
--      est private.fac_aujourdhui() (fuseau comptable). v2.1.0 est donc en
--      vigueur des l'installation ; un paiement d'un jour precedent garde la
--      politique de son jour (fn115c_montant_propose lit la politique du jour
--      du paiement), les factures du mois en cours (politique du 1er) aussi.
--      Les prix sont ceux de v2.0.0 : rien d'autre ne change. Idempotent :
--      ON CONFLICT DO NOTHING, et rien n'est insere si une version a deja la
--      date du jour ou une date posterieure.
--
-- FICHIER SANS EFFACEMENT (regle B5). Migration additive (B6) : une cle de
-- plus dans tarifs_publics(), les lecteurs actuels l'ignorent.
-- Lecteurs recenses (B1) : tarifs_publics() est lue par l'application
-- (lib/core/finance/delai_retractation.dart) et par la construction du site
-- public ; aucune cle ne change de sens.

BEGIN;

-- Outil de la migration (detruit avec la session ; OR REPLACE : une autre
-- migration jouee dans la meme session peut avoir le meme outil) : remplace [p_ancre] par
-- [p_neuf] dans la definition actuelle de [p_fonction], exactement une fois,
-- puis rafraichit l'empreinte F86 de son commentaire.
CREATE OR REPLACE FUNCTION pg_temp.remplacer(p_fonction regprocedure, p_ancre text, p_neuf text)
RETURNS void LANGUAGE plpgsql AS $$
DECLARE
  v_def text := pg_catalog.pg_get_functiondef(p_fonction);
  v_n integer;
  v_com text;
BEGIN
  v_n := (pg_catalog.length(v_def) - pg_catalog.length(pg_catalog.replace(v_def, p_ancre, '')))
         / pg_catalog.length(p_ancre);
  IF v_n <> 1 THEN
    RAISE EXCEPTION 'REMB-14 : ancre trouvee % fois dans % : %', v_n, p_fonction, pg_catalog.left(p_ancre, 120);
  END IF;
  EXECUTE pg_catalog.replace(v_def, p_ancre, p_neuf);
  v_com := pg_catalog.obj_description(p_fonction, 'pg_proc');
  IF v_com LIKE '%md5_functiondef=%' THEN
    v_com := pg_catalog.regexp_replace(v_com, 'md5_functiondef=[0-9A-Za-z_]+',
      'md5_functiondef=' || pg_catalog.md5(pg_catalog.pg_get_functiondef(p_fonction)));
    EXECUTE pg_catalog.format('COMMENT ON FUNCTION %s IS %L', p_fonction, v_com);
  END IF;
END;
$$;

-- 1. Le delai dans les tarifs publics.
SELECT pg_temp.remplacer('private.pub_tarifs_politique(public.politiques_commerciales)'::regprocedure,
$a$'essaisMax', p.essais_max,$a$,
$b$'essaisMax', p.essais_max,
    -- REMB-14 : le delai de retractation, en jours a compter du paiement.
    'remboursementDelaiJours', p.remboursement_delai_jours,$b$);

-- 3. La publication reprend les valeurs de la version precedente.
CREATE OR REPLACE FUNCTION private.remb14_politique_herite()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  v_prec public.politiques_commerciales;
BEGIN
  IF NEW.seances_par_mois IS NULL OR NEW.remboursement_delai_jours IS NULL THEN
    SELECT p.* INTO v_prec FROM public.politiques_commerciales p
     WHERE p.date_effet <= NEW.date_effet
     ORDER BY p.date_effet DESC
     LIMIT 1;
    -- Sans version precedente : les valeurs du bareme du 18/10 (defauts de
    -- la colonne).
    NEW.seances_par_mois := coalesce(NEW.seances_par_mois, v_prec.seances_par_mois, 13);
    NEW.remboursement_delai_jours := coalesce(NEW.remboursement_delai_jours,
                                              v_prec.remboursement_delai_jours, 7);
  END IF;
  RETURN NEW;
END;
$function$;
ALTER FUNCTION private.remb14_politique_herite() OWNER TO postgres;
REVOKE ALL ON FUNCTION private.remb14_politique_herite() FROM PUBLIC, anon, authenticated, service_role;
CREATE TRIGGER politiques_remb14_herite
  BEFORE INSERT ON public.politiques_commerciales
  FOR EACH ROW EXECUTE FUNCTION private.remb14_politique_herite();

-- 4. Le delai se lit et s'ecrit dans le JSON de la politique.
SELECT pg_temp.remplacer('private.fac_politique_lue(jsonb)'::regprocedure,
$a$  r.jour_suspension := private.fac_entier_facultatif(p, 'jourSuspension');$a$,
$b$  r.jour_suspension := private.fac_entier_facultatif(p, 'jourSuspension');
  -- REMB-14 : le delai de retractation, facultatif (absent : celui de la
  -- version precedente, par le declencheur politiques_remb14_herite).
  r.remboursement_delai_jours := private.fac_entier_facultatif(p, 'remboursementDelaiJours');
  IF r.remboursement_delai_jours IS NOT NULL AND r.remboursement_delai_jours NOT BETWEEN 0 AND 60 THEN
    RAISE EXCEPTION 'remboursementDelaiJours invalide (0 a 60)' USING ERRCODE = '22023';
  END IF;$b$);
SELECT pg_temp.remplacer('private.fac_politique_json(public.politiques_commerciales,text)'::regprocedure,
$a$'jourSuspension', p.jour_suspension);$a$,
$b$'jourSuspension', p.jour_suspension,
    -- REMB-14 : le delai de retractation, en jours a compter du paiement.
    'remboursementDelaiJours', p.remboursement_delai_jours);$b$);

-- 5. v2.1.0 : le delai de 14 jours, en vigueur des l'installation.
INSERT INTO public.politiques_commerciales
SELECT (pg_catalog.jsonb_populate_record(NULL::public.politiques_commerciales,
          pg_catalog.to_jsonb(p) || pg_catalog.jsonb_build_object(
            'version', 'v2.1.0',
            'date_effet', private.fac_aujourdhui(),
            'remboursement_delai_jours', 14,
            'publiee_par', NULL,
            'publiee_le', pg_catalog.clock_timestamp()))).*
  FROM public.politiques_commerciales p
 WHERE p.version = 'v2.0.0'
   AND private.fac_aujourdhui() > (SELECT max(q.date_effet) FROM public.politiques_commerciales q)
ON CONFLICT DO NOTHING;
-- Les deux tables lues par version de politique suivent : sans elles, la
-- part de l'enseignant (private.cand_part_enseignant_*, lue par version) se
-- lirait NULL et la repartition montree aux familles resterait celle de
-- v2.0.0. Memes valeurs que v2.0.0 (memes prix).
INSERT INTO public.politique_part_enseignant
  (politique_version, part_enfant_pour_mille, part_adulte_pour_mille, decision_ref)
SELECT 'v2.1.0', x.part_enfant_pour_mille, x.part_adulte_pour_mille,
       pg_catalog.left(x.decision_ref || ' ; reprise pour v2.1.0 (REMB-14, decision du directeur du 02/11/2026)', 300)
  FROM public.politique_part_enseignant x
 WHERE x.politique_version = 'v2.0.0'
   AND EXISTS (SELECT 1 FROM public.politiques_commerciales p WHERE p.version = 'v2.1.0')
ON CONFLICT DO NOTHING;
INSERT INTO public.repartitions_paiement
  (politique_version, base_eleves_enfants, base_eleves_adultes, postes)
SELECT 'v2.1.0', r.base_eleves_enfants, r.base_eleves_adultes, r.postes
  FROM public.repartitions_paiement r
 WHERE r.politique_version = 'v2.0.0'
   AND EXISTS (SELECT 1 FROM public.politiques_commerciales p WHERE p.version = 'v2.1.0')
ON CONFLICT DO NOTHING;

-- 6. Le commentaire de la colonne dit la regle decidee.
COMMENT ON COLUMN public.politiques_commerciales.remboursement_delai_jours IS
  'Delai de retractation, en jours a compter du paiement (decision du directeur du 02/11/2026, 14 jours) : pendant ce delai, on rembourse ce qui a ete paye moins les seances suivies ; ensuite, une formule payee d''avance est remboursee du reste, mois commences au prix mensuel normal. Publie par tarifs_publics().';

-- 7. Postflight.
DO $postflight$
DECLARE
  v_com text;
  f regprocedure := 'private.pub_tarifs_politique(public.politiques_commerciales)'::regprocedure;
BEGIN
  IF pg_catalog.strpos(pg_catalog.pg_get_functiondef(f),
                       '''remboursementDelaiJours'', p.remboursement_delai_jours') = 0 THEN
    RAISE EXCEPTION 'REMB-14 : ancre de pub_tarifs_politique non posee';
  END IF;
  IF EXISTS (SELECT 1 FROM pg_catalog.pg_proc p WHERE p.oid = f
              AND (NOT p.prosecdef OR NOT (p.proconfig @> ARRAY['search_path=""']))) THEN
    RAISE EXCEPTION 'REMB-14 : % sans DEFINER ou search_path', f;
  END IF;
  IF pg_catalog.has_function_privilege('anon', f, 'EXECUTE')
     OR pg_catalog.has_function_privilege('authenticated', f, 'EXECUTE') THEN
    RAISE EXCEPTION 'REMB-14 : % doit rester privee', f;
  END IF;
  IF NOT pg_catalog.has_function_privilege('anon', 'public.tarifs_publics()', 'EXECUTE')
     OR NOT pg_catalog.has_function_privilege('authenticated', 'public.tarifs_publics()', 'EXECUTE') THEN
    RAISE EXCEPTION 'REMB-14 : droits de tarifs_publics() changes';
  END IF;
  IF pg_catalog.strpos(pg_catalog.pg_get_functiondef('private.fac_politique_lue(jsonb)'::regprocedure),
                       'remboursementDelaiJours') = 0
     OR pg_catalog.strpos(pg_catalog.pg_get_functiondef(
          'private.fac_politique_json(public.politiques_commerciales,text)'::regprocedure),
                       '''remboursementDelaiJours'', p.remboursement_delai_jours') = 0 THEN
    RAISE EXCEPTION 'REMB-14 : ancres de fac_politique_lue ou fac_politique_json non posees';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_catalog.pg_trigger
                  WHERE tgname = 'politiques_remb14_herite'
                    AND tgrelid = 'public.politiques_commerciales'::regclass) THEN
    RAISE EXCEPTION 'REMB-14 : declencheur d''heritage absent';
  END IF;
  IF pg_catalog.has_function_privilege('authenticated', 'private.remb14_politique_herite()', 'EXECUTE')
     OR pg_catalog.has_function_privilege('anon', 'private.remb14_politique_herite()', 'EXECUTE') THEN
    RAISE EXCEPTION 'REMB-14 : declencheur d''heritage ouvert';
  END IF;
  -- La version en vigueur (v2.1.0, ou une version publiee plus tard) porte
  -- le delai decide, avec les prix de v2.0.0 pour v2.1.0.
  IF EXISTS (SELECT 1 FROM public.politiques_commerciales WHERE version = 'v2.0.0')
     AND (private.fac_politique_au(private.fac_aujourdhui())).version = 'v2.1.0'
     AND (private.fac_politique_au(private.fac_aujourdhui())).remboursement_delai_jours <> 14 THEN
    RAISE EXCEPTION 'REMB-14 : v2.1.0 en vigueur sans le delai de 14 jours';
  END IF;
  IF EXISTS (SELECT 1 FROM public.politiques_commerciales WHERE version = 'v2.0.0')
     AND NOT EXISTS (SELECT 1 FROM public.politiques_commerciales WHERE version = 'v2.1.0') THEN
    RAISE EXCEPTION 'REMB-14 : v2.1.0 non inseree (une version occupe deja la date du jour ou une date posterieure)';
  END IF;
  IF EXISTS (
    SELECT 1 FROM public.politiques_commerciales a, public.politiques_commerciales b
     WHERE a.version = 'v2.0.0' AND b.version = 'v2.1.0'
       AND (pg_catalog.to_jsonb(a) - ARRAY['version','date_effet','remboursement_delai_jours','publiee_par','publiee_le'])
           IS DISTINCT FROM
           (pg_catalog.to_jsonb(b) - ARRAY['version','date_effet','remboursement_delai_jours','publiee_par','publiee_le'])) THEN
    RAISE EXCEPTION 'REMB-14 : v2.1.0 differe de v2.0.0 hors version, date, delai et publication';
  END IF;
  IF EXISTS (SELECT 1 FROM public.politique_part_enseignant WHERE politique_version = 'v2.0.0')
     AND NOT EXISTS (SELECT 1 FROM public.politique_part_enseignant WHERE politique_version = 'v2.1.0') THEN
    RAISE EXCEPTION 'REMB-14 : part de l''enseignant absente pour v2.1.0';
  END IF;
  IF EXISTS (SELECT 1 FROM public.repartitions_paiement WHERE politique_version = 'v2.0.0')
     AND NOT EXISTS (SELECT 1 FROM public.repartitions_paiement WHERE politique_version = 'v2.1.0') THEN
    RAISE EXCEPTION 'REMB-14 : repartition du paiement absente pour v2.1.0';
  END IF;
  v_com := pg_catalog.obj_description(f, 'pg_proc');
  IF v_com LIKE '%md5_functiondef=%'
     AND pg_catalog.strpos(v_com, pg_catalog.md5(pg_catalog.pg_get_functiondef(f))) = 0 THEN
    RAISE EXCEPTION 'REMB-14 : empreinte F86 perimee pour %', f;
  END IF;
END;
$postflight$;

COMMIT;
