-- IMAGES-MESSAGERIE (16/11/2026), partie serveur, 5/5 : la lecture d'un fil rend,
-- pour chaque message et DANS LA MEME REQUETE (aucun appel de plus par message) :
--
--   image            : { id, largeur, hauteur, couleur_moyenne, etat } ou null.
--                      etat : en_attente (visible de son auteur seulement),
--                      confirmee, supprimee. Une image confirmee dont expire_le est
--                      passe est rendue « supprimee », meme avant la tache de purge.
--   coeurs           : le nombre de coeurs.
--   aime_par_moi     : vrai si l'appelant a donne le sien.
--
-- Retouche par ancre de private.com_fil_json (comme MESSAGERIE-LU) : une seule
-- ancre, `'texte', m.texte,` ; proprietaire, droits, volatilite et search_path
-- gardes ; rejouable (rien a faire si aime_par_moi y est deja). Une ancre trouvee
-- un autre nombre de fois qu'une arrete la migration. Aucune cle d'objet R2 n'est
-- rendue : les URL signees viennent de la fonction Edge message-images-lecture.
--
-- FICHIER SANS MOT D'EFFACEMENT, sans BEGIN ni COMMIT de premier niveau.
-- S'installe apres 20261129100000 et 20261125860000.

DO $fil$
DECLARE
  v_f regprocedure := 'private.com_fil_json(uuid,uuid,text,uuid)'::regprocedure;
  v_def text := pg_catalog.pg_get_functiondef(v_f);
  v_ancre constant text := '''texte'', m.texte,';
  v_n integer;
  v_avant record;
BEGIN
  IF pg_catalog.strpos(v_def, 'aime_par_moi') > 0 THEN
    RAISE NOTICE 'images messagerie : com_fil_json porte deja aime_par_moi';
    RETURN;
  END IF;
  v_n := (pg_catalog.length(v_def) - pg_catalog.length(pg_catalog.replace(v_def, v_ancre, '')))
         / pg_catalog.length(v_ancre);
  IF v_n <> 1 THEN
    RAISE EXCEPTION 'images messagerie : ancre de com_fil_json trouvee % fois (attendu 1)', v_n;
  END IF;
  SELECT p.prosecdef, p.proowner, p.proconfig, p.proacl, p.provolatile INTO v_avant
    FROM pg_catalog.pg_proc p WHERE p.oid = v_f;
  EXECUTE pg_catalog.replace(v_def, v_ancre,
    v_ancre || pg_catalog.chr(10)
    || '        ''image'', (SELECT pg_catalog.jsonb_build_object(' || pg_catalog.chr(10)
    || '            ''id'', i.id, ''largeur'', i.largeur, ''hauteur'', i.hauteur,' || pg_catalog.chr(10)
    || '            ''couleur_moyenne'', i.couleur_moyenne,' || pg_catalog.chr(10)
    || '            ''etat'', CASE WHEN i.etat = ''confirmee'' AND i.expire_le <= pg_catalog.clock_timestamp()' || pg_catalog.chr(10)
    || '                         THEN ''supprimee'' ELSE i.etat END)' || pg_catalog.chr(10)
    || '          FROM public.com_message_images i' || pg_catalog.chr(10)
    || '          WHERE i.message_id = m.id AND (i.etat <> ''en_attente'' OR i.auteur = p_moi)),' || pg_catalog.chr(10)
    || '        ''coeurs'', (SELECT pg_catalog.count(*) FROM public.com_message_coeurs c' || pg_catalog.chr(10)
    || '                      WHERE c.message_id = m.id AND c.retire_le IS NULL),' || pg_catalog.chr(10)
    || '        ''aime_par_moi'', EXISTS (SELECT 1 FROM public.com_message_coeurs c' || pg_catalog.chr(10)
    || '                                 WHERE c.message_id = m.id AND c.auteur = p_moi AND c.retire_le IS NULL),');
  IF NOT EXISTS (SELECT 1 FROM pg_catalog.pg_proc p
                  WHERE p.oid = v_f AND p.prosecdef = v_avant.prosecdef
                    AND p.proowner = v_avant.proowner
                    AND p.proconfig IS NOT DISTINCT FROM v_avant.proconfig
                    AND p.proacl IS NOT DISTINCT FROM v_avant.proacl
                    AND p.provolatile = v_avant.provolatile) THEN
    RAISE EXCEPTION 'images messagerie : proprietaire, droits ou attributs de com_fil_json modifies';
  END IF;
END
$fil$;

DO $postflight$
BEGIN
  IF pg_catalog.strpos(pg_catalog.pg_get_functiondef('private.com_fil_json(uuid,uuid,text,uuid)'::regprocedure),
                       'aime_par_moi') = 0 THEN
    RAISE EXCEPTION 'images messagerie : aime_par_moi absente de com_fil_json';
  END IF;
END
$postflight$;
