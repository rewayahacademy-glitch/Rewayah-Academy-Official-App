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

-- 2. Le commentaire de la colonne dit la regle decidee.
COMMENT ON COLUMN public.politiques_commerciales.remboursement_delai_jours IS
  'Delai de retractation, en jours a compter du paiement (decision du directeur du 02/11/2026, 14 jours) : pendant ce delai, on rembourse ce qui a ete paye moins les seances suivies ; ensuite, une formule payee d''avance est remboursee du reste, mois commences au prix mensuel normal. Publie par tarifs_publics().';

-- 3. Postflight.
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
  v_com := pg_catalog.obj_description(f, 'pg_proc');
  IF v_com LIKE '%md5_functiondef=%'
     AND pg_catalog.strpos(v_com, pg_catalog.md5(pg_catalog.pg_get_functiondef(f))) = 0 THEN
    RAISE EXCEPTION 'REMB-14 : empreinte F86 perimee pour %', f;
  END IF;
END;
$postflight$;

COMMIT;
