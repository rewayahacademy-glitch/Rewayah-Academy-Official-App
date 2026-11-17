-- PRAXIS-PLAFOND-REFUS : `public.praxis_noter_refus` n'avait aucun plafond. Une cle (meme valide) pouvait
-- remplir `private.praxis_journal` sans limite, une ligne par appel. Ce fichier ajoute un plafond PAR CLE,
-- sur une fenetre glissante d'une heure : 60 notes de refus ; au-dela, la fonction rend {"ok": false}
-- SANS ecrire, comme pour une cle inconnue ou un outil hors liste.
--
-- Additif : un index partiel (le journal reste a ajout seul), et CREATE OR REPLACE a signature identique
-- de la seule fonction, apres verification de l'empreinte de la definition en vigueur (la production et
-- le depot ont la meme : celle que 20261129840000 a installee). Aucune modification de table existante.
-- Aucun mot d'effacement, aucun BEGIN ni COMMIT de premier niveau.
--
-- Le compte se fait sous un verrou de transaction pris sur la cle : deux appels simultanes ne depassent pas
-- le plafond de plus d'une note chacun. Le verrou ne vaut que pour la transaction de l'appel.

DO $preflight$
BEGIN
  IF pg_catalog.to_regprocedure('public.praxis_noter_refus(text,text)') IS NULL THEN
    RAISE EXCEPTION 'PRAXIS-PLAFOND-REFUS : public.praxis_noter_refus(text,text) est absente ; rien n''est modifie';
  END IF;
  IF (SELECT pg_catalog.md5(p.prosrc) FROM pg_catalog.pg_proc p
       WHERE p.oid = 'public.praxis_noter_refus(text,text)'::pg_catalog.regprocedure)
     IS DISTINCT FROM '56b32c7ea66f04c5aec9773f5bbc5a28' THEN
    RAISE EXCEPTION 'PRAXIS-PLAFOND-REFUS : la definition de public.praxis_noter_refus n''est pas celle attendue ; rien n''est modifie';
  END IF;
END
$preflight$;

-- Le compte par cle et par heure, sans balayer le journal entier.
CREATE INDEX praxis_journal_refus_cle_idx ON private.praxis_journal (cle_id, cree_le DESC) WHERE issue = 'parametre';

CREATE OR REPLACE FUNCTION public.praxis_noter_refus(p_cle text, p_outil text)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
DECLARE
  v_debut timestamptz := pg_catalog.clock_timestamp();
  v_p record;
BEGIN
  SELECT * INTO v_p FROM private.praxis_porte(p_cle);
  IF v_p.cle_id IS NULL OR v_p.cause_interne IN ('cle_revoquee', 'cle_expiree', 'emetteur_invalide', 'emetteur_sans_cote') THEN
    RETURN pg_catalog.jsonb_build_object('ok', false);
  END IF;
  IF p_outil IS NULL OR p_outil NOT IN ('etat', 'boite', 'fil', 'ecrire', 'annoncer', 'calendrier_lire',
                                        'calendrier_ajouter', 'rendre_compte', 'lire', 'preparer') THEN
    RETURN pg_catalog.jsonb_build_object('ok', false);
  END IF;
  -- Plafond : 60 notes de refus par cle et par heure glissante ; au-dela, rien n'est ecrit.
  PERFORM pg_catalog.pg_advisory_xact_lock(pg_catalog.hashtextextended(v_p.cle_id::text, 0));
  IF (SELECT pg_catalog.count(*) FROM private.praxis_journal j
       WHERE j.cle_id = v_p.cle_id AND j.issue = 'parametre'
         AND j.cree_le > pg_catalog.clock_timestamp() - interval '1 hour') >= 60 THEN
    RETURN pg_catalog.jsonb_build_object('ok', false);
  END IF;
  PERFORM private.praxis_noter(v_p.cle_id, v_p.emise_par, p_outil, 'parametre', NULL, NULL, NULL, v_debut);
  RETURN pg_catalog.jsonb_build_object('ok', true);
END;
$function$;
