-- CAPACITE-DECIDER-PIECE (pilote, 17/11/2026, relecture de #574 PIECE-SUR-LA-FICHE) : « un widget lit une
-- capacite, jamais un role ni un cablage ». Valider ou refuser la piece sur la fiche (public.decider_dossier) n'avait
-- aucune capacite serveur : l'ecran ne pouvait lire que le branchement de la porte, vrai en production, y compris
-- pour un porteur de mission (BE-2a) qui ouvre la fiche sans pouvoir decider d'une piece.
--
-- La cle `gestes.deciderPiece` de public.capacites_candidatures() est vraie pour EXACTEMENT ce que decider_dossier
-- exige : administrateur valide (public.app_role() = 'admin', compte valide) et genre du lecteur connu
-- (read_kyc_documents), c'est-a-dire v_decider. Un porteur de mission recoit private.mission_capacites(), qui ne la
-- contient pas : cle absente, donc faux.
--
-- FICHIER SANS EFFACEMENT : aucun des trois mots d'effacement. Additif : une cle de plus, par ancrage (une ancre
-- trouvee une fois, sinon echec), jamais une copie entiere. Sans BEGIN/COMMIT de premier niveau.

DO $preflight$
BEGIN
  IF pg_catalog.to_regprocedure('public.capacites_candidatures()') IS NULL THEN
    RAISE EXCEPTION 'CAPACITE-DECIDER-PIECE : dependance absente (capacites_candidatures)';
  END IF;
END
$preflight$;

CREATE FUNCTION pg_temp.remplacer(p_def text, p_avant text, p_apres text, p_nom text)
RETURNS text
LANGUAGE plpgsql
AS $f$
DECLARE
  v_n integer;
BEGIN v_n := (pg_catalog.length(p_def) - pg_catalog.length(pg_catalog.replace(p_def, p_avant, '')))
         / pg_catalog.length(p_avant);
  IF v_n <> 1 THEN
    RAISE EXCEPTION 'CAPACITE-DECIDER-PIECE : ancre % trouvee % fois (une attendue)', p_nom, v_n;
  END IF;
  RETURN pg_catalog.replace(p_def, p_avant, p_apres);
END;
$f$;

DO $retouche$
DECLARE
  f regprocedure := 'public.capacites_candidatures()'::regprocedure;
  v_def text := pg_catalog.pg_get_functiondef(f);
  v_com text;
BEGIN
  IF pg_catalog.strpos(v_def, 'deciderPiece') = 0 THEN
    v_def := pg_temp.remplacer(v_def, '''consignerEntretien'', v_decider,',
      '''consignerEntretien'', v_decider,
      ''deciderPiece'', v_decider,', 'capacites.geste');
    EXECUTE v_def;
  END IF;
  -- F86 : l'empreinte du commentaire suit la fonction.
  v_com := coalesce(pg_catalog.obj_description(f, 'pg_proc'), '');
  IF v_com LIKE '%md5_functiondef=%' THEN
    v_com := pg_catalog.regexp_replace(v_com, 'md5_functiondef=[0-9A-Za-z_]+',
      'md5_functiondef=' || pg_catalog.md5(pg_catalog.pg_get_functiondef(f)));
    IF pg_catalog.strpos(v_com, 'CAPACITE-DECIDER-PIECE') = 0 THEN
      v_com := v_com || ' CAPACITE-DECIDER-PIECE (17/11/2026) : la cle deciderPiece (decider_dossier : direction valide, genre connu).';
    END IF;
    EXECUTE pg_catalog.format('COMMENT ON FUNCTION %s IS %L', f, v_com);
  END IF;
END;
$retouche$;

DO $postflight$
BEGIN
  IF pg_catalog.strpos(pg_catalog.pg_get_functiondef('public.capacites_candidatures()'::regprocedure),
                       'deciderPiece') = 0
     OR pg_catalog.has_function_privilege('anon', 'public.capacites_candidatures()', 'EXECUTE')
     OR NOT pg_catalog.has_function_privilege('authenticated', 'public.capacites_candidatures()', 'EXECUTE') THEN
    RAISE EXCEPTION 'CAPACITE-DECIDER-PIECE : retouche absente ou droits invalides';
  END IF;
END
$postflight$;
