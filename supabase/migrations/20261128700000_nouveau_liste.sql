-- NOUVEAU-LISTE (directeur, 16/11/2026, SPEC-LISTE-PERSONNES §2.1 bis) : une candidature est « nouvelle »
-- si elle a ete recue il y a moins de 7 jours ET si personne de l'equipe n'a encore ouvert son dossier.
--
-- A installer APRES 20261128400000 et 20261128400100 (MAJEUR) : ce fichier ancre sur leur version de
-- lister_candidatures, voisins_candidature, be_filtre_valider et be_predicat. Ce fichier ne contient aucun
-- mot d'effacement, ni BEGIN ni COMMIT seul sur une ligne.
--
-- Il n'existait aucune trace de « dossier ouvert par un membre de l'equipe » : lire_candidature ne ne
-- journalise rien pour une lecture du cote du lecteur (seules les lectures hors portee et l'exception
-- super-admin sont tracees). Trace ajoutee, minimale et idempotente :
--   * candidatures.ouverte_par_equipe_le / ouverte_par_equipe_par : la PREMIERE ouverture seulement ;
--     un UPDATE gardé par « ouverte_par_equipe_le IS NULL » : les lectures suivantes n'ecrivent rien ;
--   * ecrite par lire_candidature quand une direction active ouvre un dossier de sa portee (une lecture
--     hors portee n'ecrit rien) ; ni version ni derniere_activite ne bougent (une lecture ne change pas
--     l'etat d'un dossier et n'invalide aucun geste en cours).
-- Aucune donnee passee n'est reconstituee : aucune trace d'ouverture n'existait avant ce fichier ; les
-- candidatures recues depuis moins de 7 jours sont donc « nouvelles » jusqu'a leur prochaine ouverture.
--
-- Effets :
--   1. private.be_nouvelle(candidatures) : la regle, en un seul endroit (7 jours, pas encore ouverte) ;
--   2. private.cand_ligne_json : une cle `nouveau` (booleen) dans chaque ligne de la liste, des voisins et
--      du dossier ;
--   3. lister_candidatures et voisins_candidature : filtre `nouveau` (booleen : vrai = nouvelles, faux =
--      pas nouvelles), via private.be_predicat comme les autres filtres de BE-S1 ;
--   4. lister_candidatures : compteurNouveaux (entier, au premier niveau de la reponse, hors de
--      compteursAlertes : ces quatre compteurs sont des alertes de blocage et leur scenario les fige), les
--      nouvelles candidatures en cours (memes types que la liste par defaut : ni famille ni eleve adulte),
--      dans la portee du lecteur.
--
-- Nom de la regle : private.be_nouvelle (prefixe be_, comme les aides de BE-S1) : les scenarios de CAND-L1 a
-- CAND-L6 figent les neuf aides internes de prefixe cand_.

-- ============================================================
-- 0. Outil d'ancres (echec si l'ancre n'est pas trouvee exactement une fois)
-- ============================================================
CREATE FUNCTION pg_temp.remplacer(p_def text, p_avant text, p_apres text, p_nom text)
RETURNS text
LANGUAGE plpgsql
AS $f$
DECLARE
  v_n integer;
BEGIN v_n := (pg_catalog.length(p_def) - pg_catalog.length(pg_catalog.replace(p_def, p_avant, '')))
         / pg_catalog.length(p_avant);
  IF v_n <> 1 THEN
    RAISE EXCEPTION 'NOUVEAU-LISTE : ancre % trouvee % fois (une attendue)', p_nom, v_n;
  END IF;
  RETURN pg_catalog.replace(p_def, p_avant, p_apres);
END;
$f$;

-- ============================================================
-- 1. La trace de la premiere ouverture et la regle
-- ============================================================
ALTER TABLE public.candidatures
  ADD COLUMN ouverte_par_equipe_le timestamptz NULL,
  ADD COLUMN ouverte_par_equipe_par uuid NULL REFERENCES public.profiles(id),
  ADD CONSTRAINT candidatures_ouverture_forme
    CHECK ((ouverte_par_equipe_le IS NULL) = (ouverte_par_equipe_par IS NULL));
COMMENT ON COLUMN public.candidatures.ouverte_par_equipe_le IS
  'NOUVEAU-LISTE : premiere ouverture du dossier par un membre de l''equipe (lire_candidature, dans sa portee). Ecrite une seule fois par lire_candidature ; aucune donnee passee.';

CREATE FUNCTION private.be_nouvelle(c public.candidatures)
RETURNS boolean
LANGUAGE sql
STABLE
SET search_path = ''
AS $function$
  SELECT c.recue_le > pg_catalog.now() - interval '7 days' AND c.ouverte_par_equipe_le IS NULL;
$function$;
ALTER FUNCTION private.be_nouvelle(public.candidatures) OWNER TO postgres;
REVOKE ALL ON FUNCTION private.be_nouvelle(public.candidatures)
  FROM PUBLIC, anon, authenticated, service_role, agent_ro;

-- ============================================================
-- 2. Les retouches par ancre
-- ============================================================
DO $retouches$
DECLARE
  v_def text;
BEGIN -- La ligne de candidature : la cle `nouveau`.
  v_def := pg_catalog.pg_get_functiondef('private.cand_ligne_json(public.candidatures)'::regprocedure);
  IF pg_catalog.strpos(v_def, '''nouveau''') = 0 THEN
    v_def := pg_temp.remplacer(v_def, '''recueLe'', private.cand_instant(c.recue_le));',
      '''recueLe'', private.cand_instant(c.recue_le),
    ''nouveau'', private.be_nouvelle(c));', 'ligne.nouveau');
    EXECUTE v_def;
  END IF;

  -- Le dossier : la premiere ouverture est tracee, la ligne rendue la dit deja ouverte.
  v_def := pg_catalog.pg_get_functiondef('public.lire_candidature(uuid)'::regprocedure);
  IF pg_catalog.strpos(v_def, 'ouverte_par_equipe_le') = 0 THEN
    v_def := pg_temp.remplacer(v_def,
      '  RETURN private.cand_ligne_json(v_c) || pg_catalog.jsonb_build_object(',
      '  -- NOUVEAU-LISTE : la premiere ouverture seulement ; les suivantes n''ecrivent rien.
  IF v_c.ouverte_par_equipe_le IS NULL THEN
    UPDATE public.candidatures
       SET ouverte_par_equipe_le = pg_catalog.clock_timestamp(), ouverte_par_equipe_par = v_lecteur
     WHERE id = p_id AND ouverte_par_equipe_le IS NULL;
    v_c.ouverte_par_equipe_le := pg_catalog.clock_timestamp();
    v_c.ouverte_par_equipe_par := v_lecteur;
  END IF;

  RETURN private.cand_ligne_json(v_c) || pg_catalog.jsonb_build_object(', 'lire.ouverture');
    EXECUTE v_def;
  END IF;

  -- La liste : filtre, type du filtre, compteur.
  v_def := pg_catalog.pg_get_functiondef('public.lister_candidatures(jsonb,text,integer)'::regprocedure);
  IF pg_catalog.strpos(v_def, '''nouveau''') = 0 THEN
    v_def := pg_temp.remplacer(v_def, '''majorite'']);', '''majorite'', ''nouveau'']);', 'lister.cles');
    v_def := pg_temp.remplacer(v_def, '''pieceEnAttente'', ''responsable'', ''majorite''])',
      '''pieceEnAttente'', ''responsable'', ''majorite'', ''nouveau''])', 'lister.predicat');
    v_def := pg_temp.remplacer(v_def,
      'WHEN e.key IN (''enPause'', ''competenceAccord'', ''pieceEnAttente'') THEN ''boolean''',
      'WHEN e.key IN (''enPause'', ''competenceAccord'', ''pieceEnAttente'', ''nouveau'') THEN ''boolean''',
      'lister.type');
    v_def := pg_temp.remplacer(v_def, '''compteursAlertes'', v_alertes);',
      '''compteursAlertes'', v_alertes,
    ''compteurNouveaux'', (SELECT pg_catalog.count(*)::integer FROM public.candidatures c
                         WHERE (v_super OR c.genre = v_genre) AND c.issue = ''en_cours''
                           AND c.type_code NOT IN (''famille'', ''eleve_adulte'')
                           AND private.be_nouvelle(c)));', 'lister.compteur');
    EXECUTE v_def;
  END IF;

  -- Les voisins : le meme filtre.
  v_def := pg_catalog.pg_get_functiondef('public.voisins_candidature(text,jsonb,text)'::regprocedure);
  IF pg_catalog.strpos(v_def, '''nouveau''') = 0 THEN
    v_def := pg_temp.remplacer(v_def, '''majorite'']);', '''majorite'', ''nouveau'']);', 'voisins.cles');
    v_def := pg_temp.remplacer(v_def, '''pieceEnAttente'', ''responsable'', ''majorite''])',
      '''pieceEnAttente'', ''responsable'', ''majorite'', ''nouveau''])', 'voisins.predicat');
    v_def := pg_temp.remplacer(v_def,
      'WHEN e.key IN (''enPause'', ''competenceAccord'', ''pieceEnAttente'') THEN ''boolean''',
      'WHEN e.key IN (''enPause'', ''competenceAccord'', ''pieceEnAttente'', ''nouveau'') THEN ''boolean''',
      'voisins.type');
    EXECUTE v_def;
  END IF;

  -- Le predicat commun : vrai = nouvelles, faux = pas nouvelles.
  v_def := pg_catalog.pg_get_functiondef('private.be_predicat(public.candidatures,jsonb,uuid)'::regprocedure);
  IF pg_catalog.strpos(v_def, '''nouveau''') = 0 THEN
    v_def := pg_temp.remplacer(v_def,
      '  IF p_filtre ->> ''majorite'' = ''attestee'' AND c.majorite_declaree IS NOT TRUE THEN',
      '  IF (p_filtre ->> ''nouveau'') IS NOT NULL
     AND private.be_nouvelle(c) IS DISTINCT FROM (p_filtre ->> ''nouveau'')::boolean THEN
    RETURN false;
  END IF;
  IF p_filtre ->> ''majorite'' = ''attestee'' AND c.majorite_declaree IS NOT TRUE THEN', 'predicat.nouveau');
    EXECUTE v_def;
  END IF;
END;
$retouches$;

-- ============================================================
-- 3. Empreintes F86 et controle final
-- ============================================================
DO $f86$
DECLARE
  f regprocedure;
  v_com text;
BEGIN FOREACH f IN ARRAY ARRAY['public.lire_candidature(uuid)'::regprocedure,
                           'public.lister_candidatures(jsonb,text,integer)'::regprocedure,
                           'public.voisins_candidature(text,jsonb,text)'::regprocedure] LOOP
    v_com := coalesce(pg_catalog.obj_description(f, 'pg_proc'), '');
    IF v_com LIKE '%md5_functiondef=%' THEN
      v_com := pg_catalog.regexp_replace(v_com, 'md5_functiondef=[0-9A-Za-z_]+',
        'md5_functiondef=' || pg_catalog.md5(pg_catalog.pg_get_functiondef(f)));
      IF pg_catalog.strpos(v_com, 'NOUVEAU-LISTE') = 0 THEN
        v_com := v_com || ' NOUVEAU-LISTE (16/11/2026) : cle nouveau, filtre nouveau, premiere ouverture du dossier tracee (lire_candidature).';
      END IF;
      EXECUTE pg_catalog.format('COMMENT ON FUNCTION %s IS %L', f, v_com);
    END IF;
  END LOOP;
END;
$f86$;

DO $postflight$
BEGIN IF pg_catalog.strpos(pg_catalog.pg_get_functiondef('private.cand_ligne_json(public.candidatures)'::regprocedure), '''nouveau''') = 0
     OR pg_catalog.strpos(pg_catalog.pg_get_functiondef('public.lire_candidature(uuid)'::regprocedure), 'ouverte_par_equipe_le') = 0
     OR pg_catalog.strpos(pg_catalog.pg_get_functiondef('public.lister_candidatures(jsonb,text,integer)'::regprocedure), '''compteurNouveaux''') = 0
     OR pg_catalog.strpos(pg_catalog.pg_get_functiondef('public.voisins_candidature(text,jsonb,text)'::regprocedure), '''nouveau''') = 0
     OR pg_catalog.strpos(pg_catalog.pg_get_functiondef('private.be_predicat(public.candidatures,jsonb,uuid)'::regprocedure), '''nouveau''') = 0 THEN
    RAISE EXCEPTION 'NOUVEAU-LISTE : retouche absente';
  END IF;
END;
$postflight$;
