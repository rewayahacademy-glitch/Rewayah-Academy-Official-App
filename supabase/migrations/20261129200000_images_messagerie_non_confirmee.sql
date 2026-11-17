-- IMAGES-CORRECTIF (16/11/2026) : un message dont l'image n'est pas confirmee n'est
-- montre a personne d'autre que son auteur.
--
--   1. com_message_images.confirmee_le (nullable) : pose par message_image_confirmer.
--      Les images confirmees avant cette migration n'ont pas de date : la regle
--      ci-dessous ne regarde que les images « supprimee », et la purge des 90 jours
--      n'a encore touche aucune image confirmee (lot livre le 16/11/2026).
--   2. private.com_fil_json (lue par com_lire_fil ET com_lister_fils) : un message
--      dont l'image est en_attente n'est rendu qu'a son auteur ; un message dont
--      l'image est supprimee SANS confirmee_le (depot annule ou refuse) n'est rendu
--      a personne. Meme regle dans le compte des non lus, donc dans le dernier
--      message de la liste des fils.
--
-- Retouche par ancre, comme 20261129100400 : proprietaire, droits, volatilite et
-- search_path gardes ; rejouable ; une ancre trouvee un autre nombre de fois
-- qu'une arrete la migration. FICHIER SANS MOT D'EFFACEMENT, sans BEGIN ni COMMIT.
-- S'installe apres 20261129100400.

ALTER TABLE public.com_message_images ADD COLUMN IF NOT EXISTS confirmee_le timestamptz;
GRANT SELECT (confirmee_le) ON public.com_message_images TO authenticated;

DO $confirmer$
DECLARE
  v_f regprocedure := 'public.message_image_confirmer(uuid,text,text,text,text)'::regprocedure;
  v_def text := pg_catalog.pg_get_functiondef(v_f);
  v_ancre constant text := 'SET etat = ''confirmee'' WHERE i.id = v_ligne.id';
  v_n integer;
  v_avant record;
BEGIN
  IF pg_catalog.strpos(v_def, 'confirmee_le') > 0 THEN
    RAISE NOTICE 'images correctif : message_image_confirmer pose deja confirmee_le';
    RETURN;
  END IF;
  v_n := (pg_catalog.length(v_def) - pg_catalog.length(pg_catalog.replace(v_def, v_ancre, '')))
         / pg_catalog.length(v_ancre);
  IF v_n <> 1 THEN
    RAISE EXCEPTION 'images correctif : ancre de message_image_confirmer trouvee % fois (attendu 1)', v_n;
  END IF;
  SELECT p.prosecdef, p.proowner, p.proconfig, p.proacl, p.provolatile INTO v_avant
    FROM pg_catalog.pg_proc p WHERE p.oid = v_f;
  EXECUTE pg_catalog.replace(v_def, v_ancre,
    'SET etat = ''confirmee'', confirmee_le = pg_catalog.clock_timestamp() WHERE i.id = v_ligne.id');
  IF NOT EXISTS (SELECT 1 FROM pg_catalog.pg_proc p
                  WHERE p.oid = v_f AND p.prosecdef = v_avant.prosecdef
                    AND p.proowner = v_avant.proowner
                    AND p.proconfig IS NOT DISTINCT FROM v_avant.proconfig
                    AND p.proacl IS NOT DISTINCT FROM v_avant.proacl
                    AND p.provolatile = v_avant.provolatile) THEN
    RAISE EXCEPTION 'images correctif : proprietaire, droits ou attributs de message_image_confirmer modifies';
  END IF;
END
$confirmer$;

DO $fil$
DECLARE
  v_f regprocedure := 'private.com_fil_json(uuid,uuid,text,uuid)'::regprocedure;
  v_def text := pg_catalog.pg_get_functiondef(v_f);
  v_ancre_lus constant text := 'AND m.auteur_id <> p_moi';
  v_ancre_msg constant text := 'WHERE m.fil_id = f.id), ''[]''::jsonb));';
  v_regle constant text :=
    'AND NOT EXISTS (SELECT 1 FROM public.com_message_images ix'
    || ' WHERE ix.message_id = m.id'
    || ' AND ((ix.etat = ''en_attente'' AND ix.auteur <> p_moi)'
    || ' OR (ix.etat = ''supprimee'' AND ix.confirmee_le IS NULL)))';
  v_n integer;
  v_avant record;
BEGIN
  IF pg_catalog.strpos(v_def, 'ix.confirmee_le') > 0 THEN
    RAISE NOTICE 'images correctif : com_fil_json porte deja la regle';
    RETURN;
  END IF;
  v_n := (pg_catalog.length(v_def) - pg_catalog.length(pg_catalog.replace(v_def, v_ancre_lus, '')))
         / pg_catalog.length(v_ancre_lus);
  IF v_n <> 1 THEN
    RAISE EXCEPTION 'images correctif : ancre des non lus trouvee % fois (attendu 1)', v_n;
  END IF;
  v_n := (pg_catalog.length(v_def) - pg_catalog.length(pg_catalog.replace(v_def, v_ancre_msg, '')))
         / pg_catalog.length(v_ancre_msg);
  IF v_n <> 1 THEN
    RAISE EXCEPTION 'images correctif : ancre des messages trouvee % fois (attendu 1)', v_n;
  END IF;
  SELECT p.prosecdef, p.proowner, p.proconfig, p.proacl, p.provolatile INTO v_avant
    FROM pg_catalog.pg_proc p WHERE p.oid = v_f;
  v_def := pg_catalog.replace(v_def, v_ancre_lus, v_ancre_lus || ' ' || v_regle);
  v_def := pg_catalog.replace(v_def, v_ancre_msg,
    'WHERE m.fil_id = f.id ' || v_regle || '), ''[]''::jsonb));');
  EXECUTE v_def;
  IF NOT EXISTS (SELECT 1 FROM pg_catalog.pg_proc p
                  WHERE p.oid = v_f AND p.prosecdef = v_avant.prosecdef
                    AND p.proowner = v_avant.proowner
                    AND p.proconfig IS NOT DISTINCT FROM v_avant.proconfig
                    AND p.proacl IS NOT DISTINCT FROM v_avant.proacl
                    AND p.provolatile = v_avant.provolatile) THEN
    RAISE EXCEPTION 'images correctif : proprietaire, droits ou attributs de com_fil_json modifies';
  END IF;
END
$fil$;

DO $postflight$
BEGIN
  IF pg_catalog.strpos(pg_catalog.pg_get_functiondef('private.com_fil_json(uuid,uuid,text,uuid)'::regprocedure),
                       'ix.confirmee_le') = 0
     OR pg_catalog.strpos(pg_catalog.pg_get_functiondef('public.message_image_confirmer(uuid,text,text,text,text)'::regprocedure),
                       'confirmee_le') = 0 THEN
    RAISE EXCEPTION 'images correctif : regle absente apres installation';
  END IF;
END
$postflight$;
