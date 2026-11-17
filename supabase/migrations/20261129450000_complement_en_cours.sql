-- COMPLEMENT-EN-COURS (pilote, 16/11/2026, capture CAND-00068) : la direction ne peut pas savoir si une
-- demande de complement est ouverte, et l'ecran propose « Clore le complement » a tort (refus
-- aucun_complement). Le serveur le dit : chaque ligne de candidature porte `complementEnCours`.
--
-- FICHIER SANS EFFACEMENT : aucun des trois mots d'effacement. Additif : une cle de plus dans
-- private.cand_ligne_json (donc la liste, les voisins et le dossier), retouchee par ancrage, jamais copiee.
-- Sans BEGIN/COMMIT de premier niveau.
--
-- `complementEnCours` = vrai quand private.candidature_complement_en_cours(c) rend au moins un code, c'est-a-dire
-- exactement quand le geste de cloture du complement trouve quelque chose a clore. Les fonctions publiques qui
-- appellent cand_ligne_json ne changent pas : leurs empreintes F86 restent justes.

CREATE FUNCTION pg_temp.remplacer(p_def text, p_avant text, p_apres text, p_nom text)
RETURNS text
LANGUAGE plpgsql
AS $f$
DECLARE
  v_n integer;
BEGIN v_n := (pg_catalog.length(p_def) - pg_catalog.length(pg_catalog.replace(p_def, p_avant, '')))
         / pg_catalog.length(p_avant);
  IF v_n <> 1 THEN
    RAISE EXCEPTION 'COMPLEMENT-EN-COURS : ancre % trouvee % fois (une attendue)', p_nom, v_n;
  END IF;
  RETURN pg_catalog.replace(p_def, p_avant, p_apres);
END;
$f$;

DO $retouche$
DECLARE
  v_def text := pg_catalog.pg_get_functiondef('private.cand_ligne_json(public.candidatures)'::regprocedure);
BEGIN
  IF pg_catalog.strpos(v_def, '''complementEnCours''') = 0 THEN
    v_def := pg_temp.remplacer(v_def, '''nouveau'', private.be_nouvelle(c));',
      '''nouveau'', private.be_nouvelle(c),
    ''complementEnCours'', pg_catalog.jsonb_array_length(private.candidature_complement_en_cours(c)) > 0);',
      'ligne.complement');
    EXECUTE v_def;
  END IF;
END;
$retouche$;

DO $postflight$
BEGIN
  IF pg_catalog.strpos(pg_catalog.pg_get_functiondef('private.cand_ligne_json(public.candidatures)'::regprocedure),
                       '''complementEnCours''') = 0 THEN
    RAISE EXCEPTION 'COMPLEMENT-EN-COURS : retouche absente';
  END IF;
END
$postflight$;
