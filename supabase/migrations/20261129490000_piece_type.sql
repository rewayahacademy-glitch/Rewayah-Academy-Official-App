-- PIECE-TYPE (pilote, 16/11/2026) : la fiche ouvre la piece d'identite d'un candidat dans le bon lecteur.
-- piece_dossier_candidat rend le vrai type du fichier, tire du type MIME enregistre au depot
-- (private.kyc_contenus_confirmes.type_contenu, ecrit par kyc_confirmer_contenu quand le depot est confirme) :
--   typeContenu  : le type MIME enregistre (application/pdf, image/jpeg, image/png, image/heic), ou NULL ;
--   genreFichier : 'pdf', 'image' ou NULL.
-- NULL quand aucun type n'est enregistre (une piece sans confirmation du contenu : en production, 2 pieces sur 338
-- le 16/11/2026) ou quand aucune piece n'est deposee : le serveur ne devine pas, l'ecran decide quoi montrer.
--
-- FICHIER SANS EFFACEMENT : aucun des trois mots d'effacement. Additif : deux cles de plus dans la reponse, par
-- ancrage de la fonction en vigueur (jamais une copie entiere). Sans BEGIN/COMMIT de premier niveau. La lecture qui
-- signe la piece (autoriser_lecture_piece_identite) n'est pas touchee.

CREATE FUNCTION pg_temp.remplacer(p_def text, p_avant text, p_apres text, p_nom text)
RETURNS text
LANGUAGE plpgsql
AS $f$
DECLARE
  v_n integer;
BEGIN v_n := (pg_catalog.length(p_def) - pg_catalog.length(pg_catalog.replace(p_def, p_avant, '')))
         / pg_catalog.length(p_avant);
  IF v_n <> 1 THEN
    RAISE EXCEPTION 'PIECE-TYPE : ancre % trouvee % fois (une attendue)', p_nom, v_n;
  END IF;
  RETURN pg_catalog.replace(p_def, p_avant, p_apres);
END;
$f$;

DO $retouche$
DECLARE
  v_f regprocedure := 'public.piece_dossier_candidat(uuid)'::regprocedure;
  v_def text := pg_catalog.pg_get_functiondef(v_f);
  v_com text;
BEGIN
  IF pg_catalog.strpos(v_def, '''genreFichier''') = 0 THEN
    v_def := pg_temp.remplacer(v_def, '    ''decideLe'', v_doc.verified_at);',
      '    ''decideLe'', v_doc.verified_at,
    ''typeContenu'', (SELECT c.type_contenu FROM private.kyc_contenus_confirmes c
                       WHERE c.object_key = v_doc.object_key),
    ''genreFichier'', (SELECT CASE WHEN c.type_contenu = ''application/pdf'' THEN ''pdf''
                                  WHEN c.type_contenu LIKE ''image/%'' THEN ''image'' END
                        FROM private.kyc_contenus_confirmes c WHERE c.object_key = v_doc.object_key));',
      'piece.type');
    EXECUTE v_def;
  END IF;
  v_com := coalesce(pg_catalog.obj_description(v_f, 'pg_proc'), '');
  IF v_com LIKE '%md5_functiondef=%' THEN
    v_com := pg_catalog.regexp_replace(v_com, 'md5_functiondef=[0-9A-Za-z_]+',
      'md5_functiondef=' || pg_catalog.md5(pg_catalog.pg_get_functiondef(v_f)));
    IF pg_catalog.strpos(v_com, 'PIECE-TYPE') = 0 THEN
      v_com := v_com || ' PIECE-TYPE (16/11/2026) : typeContenu et genreFichier (pdf, image ou NULL), tires du type MIME enregistre au depot.';
    END IF;
    EXECUTE pg_catalog.format('COMMENT ON FUNCTION %s IS %L', v_f, v_com);
  END IF;
END;
$retouche$;

DO $postflight$
BEGIN
  IF pg_catalog.strpos(pg_catalog.pg_get_functiondef('public.piece_dossier_candidat(uuid)'::regprocedure),
                       '''genreFichier''') = 0 THEN
    RAISE EXCEPTION 'PIECE-TYPE : retouche absente';
  END IF;
END
$postflight$;
