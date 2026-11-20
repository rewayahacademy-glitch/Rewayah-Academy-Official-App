-- PE-LISTE-CANDIDATURES (PE-C4, vague 2 du parcours enseignant, 20/11/2026) : la liste des candidatures cote direction,
-- pour traiter pres de 600 dossiers par groupes.
--
-- MOTS D'EFFACEMENT : ZERO (comptes a la main et par tool/ : aucun des trois mots SQL qui retirent des lignes, une table ou son
-- contenu, commentaires compris). Aucune contrainte reecrite : la table des rapports de lot garde sa liste de gestes ; les gestes
-- neufs ecrivent leur rapport dans une table privee neuve (point 5).
--
-- LIVRE ICI :
--   1. Le TRI PAR ANCIENNETE : `p_tri = 'ancienne'` dans lister_candidatures et voisins_candidature : la derniere activite la plus
--      ANCIENNE d'abord (la candidature qui attend depuis le plus longtemps), puis l'identifiant. C'est l'inverse exact de
--      `activite` : le tableau de bord rangeait deja « les plus anciens » sur cette meme colonne.
--   2. Trois FILTRES, comme des cles de `p_filtre` (la signature ne change pas, voir plus bas) :
--        dossierComplet  (booleen)  : le candidat n'a plus rien a fournir (private.praxis_dossier_manques(c) ->> 'complet', la
--                                     lecture que Praxis emploie deja) ; faux : il lui manque au moins une chose ;
--        pilePraxis      (texte)    : la pile courante ou Praxis a range le dossier (pret_a_decider, incomplet, a_regarder,
--                                     sans_nouvelles) ;
--        etiquettePraxis (texte)    : l'etiquette de l'impression courante de Praxis (pepite, solide, a_creuser, reserve).
--   3. selection_resultats_file(p_filtre, p_tri) : « Selectionner les N resultats » : le nombre exact et les identifiants (1 000 au
--      plus) du filtre en cours, dans l'ordre de la liste. Son corps est ENGENDRE ICI depuis celui de lister_candidatures (meme
--      garde, meme portee de genre, meme validation, meme WHERE, meme tri), seule la fin change : il ne peut pas diverger de la
--      liste au moment de l'installation.
--   4. direction_praxis_du_dossier(p_reference) : le rangement et l'impression courants de Praxis pour UN dossier, dans les formes
--      de direction_praxis_rangements et direction_praxis_impressions (la carte du dossier n'a plus a lire toutes les pages).
--   5. Trois GESTES GROUPES neufs dans le moteur de lot existant (apercu_lot_candidats, executer_lot_candidats : meme jeton, meme
--      nombre saisi, meme cle d'idempotence, meme rapport ligne par ligne) :
--        admettre            -> admettre_verifications : chaque ligne passe par public.admettre_salle_verification (controles
--                               d'admission, courriel « retenu pour un entretien », notification) ; l'apercu EXCLUT deja, avec
--                               leur raison, les dossiers dont un controle d'admission est faux ;
--                               La cle passee a la fonction est courte (`lot-<md5 de la cle de ligne>`) : la fonction en derive
--                               la cle de son courriel, bornee a 120 signes (relecture adverse de la PR 658) ;
--        demanderComplement  -> demander_complement : chaque ligne passe par public.demander_complement_candidat, avec UN element
--                               pour tout le lot (porte par p_modele, comme la categorie de la dispense, BE-1g) et le motif ;
--                               l'apercu rend pour chaque eligible les elements que son etape accepte ; a l'execution, un
--                               element que l'un d'eux n'accepte pas rend le lot perime (jeton_perime) : le nombre annonce est
--                               celui qui reussira ;
--        ecrire              -> un message de la direction dans la conversation de candidature de chaque personne
--                               (public.com_ouvrir_conversation puis public.com_envoyer_message). La cle du message derive du
--                               fil, du jour et du texte normalise, jamais de la cle du lot : le meme texte au meme candidat le
--                               meme jour ne part qu'une fois, quels que soient le lot, l'onglet ou l'auteur (ligne
--                               `deja_envoye`) ; l'apercu exclut qui n'a pas de conversation possible (sans compte, en pause,
--                               hors etape).
--      Pour ces trois gestes, l'empreinte de la cle du lot couvre aussi le motif et le modele : la meme cle avec un autre texte
--      est refusee (cle_idempotence_reutilisee), jamais rejouee en silence.
--      Aucun de ces gestes n'existait en lot : ils sont ecrits ici (rien dans main, rien sur une branche du bureau : la vague 3 du
--      bureau n'a pas d'ordre). Les gestes groupes d'avant (pause, reprise, refus, dispense) ne changent pas d'un octet de
--      comportement.
--
-- POURQUOI LA SIGNATURE DE lister_candidatures NE CHANGE PAS : les filtres neufs sont des cles de `p_filtre` (jsonb) et le tri une
-- valeur de plus de `p_tri` (text). Ajouter des parametres p_pile / p_etiquette aurait cree une seconde fonction du meme nom
-- (CREATE OR REPLACE ne change pas une liste de parametres) ; PostgREST et Postgres refusent alors tout appel ambigu, et l'ancienne
-- n'aurait pu etre retiree que par un mot d'effacement. Les appelants actuels (lib/core/candidature/candidatures_direction_supabase.dart,
-- tableau de bord, scenarios) envoient exactement les memes parametres qu'avant et recoivent la meme reponse. Meme raison pour la
-- lecture d'un dossier de Praxis : une fonction NEUVE (point 4) plutot qu'un p_reference ajoute a deux fonctions en service.
--
-- FONCTIONS EXISTANTES REMPLACEES (CREATE OR REPLACE a signature identique : proprietaire, droits et commentaire conserves), par
-- ancrage sur pg_get_functiondef, apres controle de l'empreinte md5(prosrc) relevee sur une base rejouee de main :
--   * public.lister_candidatures(jsonb, text, integer)                                    c14aed6dcbdd70a3452efa59bae9207b
--   * public.voisins_candidature(text, jsonb, text)                                       c59d85012de2ca2c2b36fec489999e8a
--   * public.apercu_lot_candidats(text, uuid[])                                           1541470d425668c3d3579096567b6264
--   * public.executer_lot_candidats(text, uuid[], text, integer, text, text, text, date)  ea9fbf622d09ff3ea852db058664acd0
-- Lecteurs recenses : lister_candidatures et voisins_candidature ne sont appeles que par lib/core/candidature/
-- candidatures_direction_supabase.dart et les scenarios cand_* / be_* ; apercu et executer, par le meme adaptateur. Aucun outil de
-- Praxis (praxis_*) n'est touche ; praxis_dossier_manques est LU, pas modifie.
-- Sans BEGIN ni COMMIT de premier niveau.

DO $preflight$
DECLARE
  v record;
BEGIN
  IF pg_catalog.to_regprocedure('public.selection_resultats_file(jsonb,text)') IS NOT NULL
     OR pg_catalog.to_regclass('private.candidature_lots_suite') IS NOT NULL THEN
    RAISE EXCEPTION 'PE-LISTE-CANDIDATURES : deja installe ; rien n''est modifie';
  END IF;
  IF pg_catalog.to_regprocedure('private.praxis_dossier_manques(public.candidatures)') IS NULL
     OR pg_catalog.to_regclass('private.praxis_rangements') IS NULL
     OR pg_catalog.to_regclass('private.praxis_impressions') IS NULL
     OR pg_catalog.to_regprocedure('private.candidature_lot_examiner(text,uuid[],uuid,public.gender)') IS NULL
     OR pg_catalog.to_regprocedure('private.candidature_geste_groupe(uuid,text,uuid,integer,text,text,text,date,jsonb)') IS NULL
     OR pg_catalog.to_regprocedure('private.candidature_controles_entree(public.candidatures,text)') IS NULL
     OR pg_catalog.to_regprocedure('private.candidature_controles_faux(jsonb)') IS NULL
     OR pg_catalog.to_regprocedure('public.admettre_salle_verification(uuid,integer,text)') IS NULL
     OR pg_catalog.to_regprocedure('public.demander_complement_candidat(uuid,text[],text,integer,text)') IS NULL
     OR pg_catalog.to_regprocedure('public.com_ouvrir_conversation(text,uuid,text)') IS NULL
     OR pg_catalog.to_regprocedure('public.com_envoyer_message(uuid,text,uuid)') IS NULL
     OR pg_catalog.to_regprocedure('private.cand_lecteur()') IS NULL
     OR pg_catalog.to_regclass('private.candidature_lot_secret') IS NULL
     OR pg_catalog.to_regclass('public.candidature_lots') IS NULL THEN
    RAISE EXCEPTION 'PE-LISTE-CANDIDATURES : dependances absentes (PX-3, PX-4, CAND-L2A2, messagerie) ; rien n''est modifie';
  END IF;
  FOR v IN SELECT * FROM (VALUES
      ('public.lister_candidatures(jsonb,text,integer)', 'c14aed6dcbdd70a3452efa59bae9207b'),
      ('public.voisins_candidature(text,jsonb,text)', 'c59d85012de2ca2c2b36fec489999e8a'),
      ('public.apercu_lot_candidats(text,uuid[])', '1541470d425668c3d3579096567b6264'),
      ('public.executer_lot_candidats(text,uuid[],text,integer,text,text,text,date)', 'ea9fbf622d09ff3ea852db058664acd0'))
      AS t(f, md5) LOOP
    IF (SELECT pg_catalog.md5(p.prosrc) FROM pg_catalog.pg_proc p WHERE p.oid = v.f::pg_catalog.regprocedure)
       IS DISTINCT FROM v.md5 THEN
      RAISE EXCEPTION 'PE-LISTE-CANDIDATURES : la definition de % n''est pas celle attendue ; rien n''est modifie', v.f;
    END IF;
  END LOOP;
END
$preflight$;

CREATE FUNCTION pg_temp.remplacer(p_def text, p_avant text, p_apres text, p_nom text)
RETURNS text
LANGUAGE plpgsql
AS $f$
DECLARE
  v_n integer;
BEGIN
  v_n := (pg_catalog.length(p_def) - pg_catalog.length(pg_catalog.replace(p_def, p_avant, ''))) / pg_catalog.length(p_avant);
  IF v_n <> 1 THEN
    RAISE EXCEPTION 'PE-LISTE-CANDIDATURES : ancre % trouvee % fois (une attendue)', p_nom, v_n;
  END IF;
  RETURN pg_catalog.replace(p_def, p_avant, p_apres);
END;
$f$;

-- ====================================================================================================================
-- 1. Aides privees des filtres.
-- ====================================================================================================================

-- Les valeurs des trois filtres neufs : refus 22023 si elles sont mal formees (le type est controle par la liste des types).
CREATE FUNCTION private.pelc_filtre_valider(p_filtre jsonb)
RETURNS void
LANGUAGE plpgsql
STABLE
SET search_path = ''
AS $f$
BEGIN
  IF (p_filtre ->> 'pilePraxis' IS NOT NULL
      AND p_filtre ->> 'pilePraxis' NOT IN ('pret_a_decider', 'incomplet', 'a_regarder', 'sans_nouvelles'))
     OR (p_filtre ->> 'etiquettePraxis' IS NOT NULL
         AND p_filtre ->> 'etiquettePraxis' NOT IN ('pepite', 'solide', 'a_creuser', 'reserve')) THEN
    RAISE EXCEPTION 'valeur de filtre de candidatures invalide' USING ERRCODE = '22023';
  END IF;
END;
$f$;

-- Les trois filtres neufs, pour une candidature. Une cle absente ou nulle ne filtre pas.
CREATE FUNCTION private.pelc_predicat(c public.candidatures, p_filtre jsonb)
RETURNS boolean
LANGUAGE plpgsql
STABLE
SET search_path = ''
AS $f$
BEGIN
  IF p_filtre ->> 'dossierComplet' IS NOT NULL
     AND coalesce((private.praxis_dossier_manques(c) ->> 'complet')::boolean, false)
         IS DISTINCT FROM (p_filtre ->> 'dossierComplet')::boolean THEN
    RETURN false;
  END IF;
  IF p_filtre ->> 'pilePraxis' IS NOT NULL AND NOT EXISTS (
       SELECT 1 FROM private.praxis_rangements x
        WHERE x.candidature_id = c.id AND x.courant AND x.pile = p_filtre ->> 'pilePraxis') THEN
    RETURN false;
  END IF;
  IF p_filtre ->> 'etiquettePraxis' IS NOT NULL AND NOT EXISTS (
       SELECT 1 FROM private.praxis_impressions x
        WHERE x.candidature_id = c.id AND x.courant AND x.etiquette = p_filtre ->> 'etiquettePraxis') THEN
    RETURN false;
  END IF;
  RETURN true;
END;
$f$;

ALTER FUNCTION private.pelc_filtre_valider(jsonb) OWNER TO postgres;
ALTER FUNCTION private.pelc_predicat(public.candidatures, jsonb) OWNER TO postgres;
REVOKE ALL ON FUNCTION private.pelc_filtre_valider(jsonb) FROM PUBLIC, anon, authenticated, service_role, agent_ro;
REVOKE ALL ON FUNCTION private.pelc_predicat(public.candidatures, jsonb) FROM PUBLIC, anon, authenticated, service_role, agent_ro;

-- ====================================================================================================================
-- 2. lister_candidatures et voisins_candidature : tri `ancienne`, trois cles de filtre (memes ancres dans les deux).
-- ====================================================================================================================
DO $retouche_liste$
DECLARE
  v_f text;
  v_def text;
BEGIN
  FOREACH v_f IN ARRAY ARRAY['public.lister_candidatures(jsonb,text,integer)', 'public.voisins_candidature(text,jsonb,text)'] LOOP
    v_def := pg_catalog.pg_get_functiondef(v_f::pg_catalog.regprocedure);
    v_def := pg_temp.remplacer(v_def,
      '''majorite'', ''nouveau'']);',
      '''majorite'', ''nouveau'', ''dossierComplet'', ''pilePraxis'', ''etiquettePraxis'']);',
      v_f || ' cles');
    v_def := pg_temp.remplacer(v_def,
      'WHEN e.key IN (''enPause'', ''competenceAccord'', ''pieceEnAttente'', ''nouveau'') THEN ''boolean''',
      'WHEN e.key IN (''enPause'', ''competenceAccord'', ''pieceEnAttente'', ''nouveau'', ''dossierComplet'') THEN ''boolean''',
      v_f || ' types');
    v_def := pg_temp.remplacer(v_def,
      'PERFORM private.be_filtre_valider(v_filtre);',
      'PERFORM private.be_filtre_valider(v_filtre);
  -- PE-LISTE-CANDIDATURES : dossier complet, pile et etiquette de Praxis.
  PERFORM private.pelc_filtre_valider(v_filtre);',
      v_f || ' validation');
    v_def := pg_temp.remplacer(v_def,
      'IF p_tri IS NULL OR p_tri NOT IN (''activite'', ''recente'', ''nom'') THEN
    RAISE EXCEPTION ''tri de candidatures invalide : activite, recente ou nom''',
      'IF p_tri IS NULL OR p_tri NOT IN (''activite'', ''recente'', ''nom'', ''ancienne'') THEN
    RAISE EXCEPTION ''tri de candidatures invalide : activite, recente, nom ou ancienne''',
      v_f || ' tri');
    v_def := pg_temp.remplacer(v_def,
      'CASE WHEN p_tri = ''nom'' THEN coalesce(c.nom_latin, c.nom_complet) END ASC,',
      'CASE WHEN p_tri = ''nom'' THEN coalesce(c.nom_latin, c.nom_complet) END ASC,
             -- PE-LISTE-CANDIDATURES : celle qui attend depuis le plus longtemps d''abord.
             CASE WHEN p_tri = ''ancienne'' THEN c.derniere_activite END ASC,',
      v_f || ' ordre');
    v_def := pg_temp.remplacer(v_def,
      'OR private.be_predicat(c, v_filtre, v_lecteur))',
      'OR private.be_predicat(c, v_filtre, v_lecteur))
      AND (NOT (v_filtre ?| ARRAY[''dossierComplet'', ''pilePraxis'', ''etiquettePraxis''])
           OR private.pelc_predicat(c, v_filtre))',
      v_f || ' predicat');
    EXECUTE v_def;
  END LOOP;
END
$retouche_liste$;

-- ====================================================================================================================
-- 3. selection_resultats_file : le corps de lister_candidatures (retouche ci-dessus), seule la fin change.
-- ====================================================================================================================
DO $selection$
DECLARE
  v_def text := pg_catalog.pg_get_functiondef('public.lister_candidatures(jsonb,text,integer)'::pg_catalog.regprocedure);
  v_debut integer;
BEGIN
  v_def := pg_temp.remplacer(v_def,
    'CREATE OR REPLACE FUNCTION public.lister_candidatures(p_filtre jsonb DEFAULT ''{}''::jsonb, p_tri text DEFAULT ''activite''::text, p_page integer DEFAULT 1)',
    'CREATE FUNCTION public.selection_resultats_file(p_filtre jsonb DEFAULT ''{}''::jsonb, p_tri text DEFAULT ''activite''::text)',
    'selection en-tete');
  -- La page n'existe pas ici : une constante, pour que la validation recopiee reste vraie.
  v_def := pg_temp.remplacer(v_def,
    E'DECLARE\n',
    E'DECLARE\n  p_page integer := 1;\n',
    'selection page');
  v_debut := pg_catalog.strpos(v_def, E'  SELECT pg_catalog.count(*)::integer,\n');
  IF v_debut = 0 OR pg_catalog.strpos(pg_catalog.substr(v_def, v_debut + 1), E'  SELECT pg_catalog.count(*)::integer,\n') <> 0 THEN
    RAISE EXCEPTION 'PE-LISTE-CANDIDATURES : ancre de fin de selection introuvable ou en double';
  END IF;
  v_def := pg_catalog.substr(v_def, 1, v_debut - 1) || $fin$  -- PE-LISTE-CANDIDATURES : le nombre exact et les identifiants (1 000 au plus), dans l'ordre de la liste.
  SELECT pg_catalog.count(*)::integer,
         pg_catalog.count(*) FILTER (WHERE f.rang <= 1000 AND (f.ligne).genre IS DISTINCT FROM v_genre)::integer,
         coalesce(pg_catalog.jsonb_agg(pg_catalog.to_jsonb((f.ligne).id) ORDER BY f.rang) FILTER (WHERE f.rang <= 1000),
                  '[]'::jsonb)
    INTO v_total, v_hors_genre, v_lignes
  FROM filtrees f;

  PERFORM public.log_sensitive_access('candidatures_selection', 'candidatures', NULL,
    pg_catalog.jsonb_build_object(
      'reader_gender', v_genre,
      'exception_active', v_super,
      'lignes_hors_genre', v_hors_genre,
      'total', v_total,
      'recherche', v_recherche IS NOT NULL,
      'competences', v_comp));

  RETURN pg_catalog.jsonb_build_object('total', v_total, 'ids', v_lignes, 'plafond', 1000);
END;
$function$
$fin$;
  EXECUTE v_def;
END
$selection$;

ALTER FUNCTION public.selection_resultats_file(jsonb, text) OWNER TO postgres;
REVOKE ALL ON FUNCTION public.selection_resultats_file(jsonb, text) FROM PUBLIC, anon, service_role, agent_ro;
GRANT EXECUTE ON FUNCTION public.selection_resultats_file(jsonb, text) TO authenticated;
COMMENT ON FUNCTION public.selection_resultats_file(jsonb, text) IS
  'PE-LISTE-CANDIDATURES : « Selectionner les N resultats ». Meme garde, meme portee, memes filtres et meme tri que '
  'lister_candidatures (corps engendre depuis elle a l''installation) ; rend total (exact), ids (1 000 au plus, ordre de la liste) '
  'et plafond. Aucun nom, aucun contact. Journalise (candidatures_selection).';

-- ====================================================================================================================
-- 4. direction_praxis_du_dossier : le rangement et l'impression courants de Praxis pour un dossier.
-- ====================================================================================================================
CREATE FUNCTION public.direction_praxis_du_dossier(p_reference text)
RETURNS jsonb
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $f$
DECLARE
  v_ref text := pg_catalog.upper(pg_catalog.btrim(coalesce(p_reference, '')));
  v_c public.candidatures;
  v_rangement jsonb;
  v_impression jsonb;
BEGIN
  IF NOT coalesce(public.app_account_valid() AND public.app_role() = 'admin', false) THEN
    RAISE EXCEPTION 'autorisation direction requise' USING ERRCODE = '42501';
  END IF;
  IF v_ref = '' OR pg_catalog.length(v_ref) > 40 THEN
    RAISE EXCEPTION 'reference de candidature attendue' USING ERRCODE = '22023';
  END IF;
  -- Les memes conditions que les deux lectures de la direction : un dossier d'enseignant en cours, du cote du lecteur. Hors de ces
  -- conditions, la meme reponse vide : rien ne dit qu'un dossier de l'autre cote existe.
  SELECT c.* INTO v_c FROM public.candidatures c
   WHERE c.reference = v_ref AND c.type_code = 'enseignant' AND c.issue = 'en_cours'
     AND EXISTS (SELECT 1 FROM private.cand_lecteur() l WHERE l.super_admin OR l.genre = c.genre);
  IF v_c.id IS NOT NULL THEN
    SELECT pg_catalog.jsonb_build_object(
             'reference', v_c.reference, 'nom', v_c.nom_complet, 'cote', v_c.genre, 'etape', v_c.etape, 'etat', v_c.etat,
             'enPause', v_c.en_pause, 'pile', x.pile, 'raison', x.raison, 'rangeLe', x.range_le)
      INTO v_rangement
      FROM private.praxis_rangements x
     WHERE x.candidature_id = v_c.id AND x.courant
     ORDER BY x.range_le DESC, x.id DESC
     LIMIT 1;
    SELECT pg_catalog.jsonb_build_object(
             'reference', v_c.reference, 'nom', v_c.nom_complet, 'cote', v_c.genre, 'etape', v_c.etape, 'etat', v_c.etat,
             'enPause', v_c.en_pause, 'etiquette', x.etiquette, 'confiance', x.confiance, 'texte', x.texte,
             'notes', pg_catalog.jsonb_build_object('maitrise', x.maitrise, 'pedagogie', x.pedagogie, 'vision', x.vision,
                                                    'comportement', x.comportement, 'disponibilite', x.disponibilite),
             'contexte', x.contexte, 'synthese', x.synthese, 'noteeLe', x.notee_le)
      INTO v_impression
      FROM private.praxis_impressions x
     WHERE x.candidature_id = v_c.id AND x.courant
     ORDER BY x.notee_le DESC, x.id DESC
     LIMIT 1;
  END IF;
  RETURN pg_catalog.jsonb_build_object('rangement', v_rangement, 'impression', v_impression);
END;
$f$;

ALTER FUNCTION public.direction_praxis_du_dossier(text) OWNER TO postgres;
REVOKE ALL ON FUNCTION public.direction_praxis_du_dossier(text) FROM PUBLIC, anon, service_role, agent_ro;
GRANT EXECUTE ON FUNCTION public.direction_praxis_du_dossier(text) TO authenticated;
COMMENT ON FUNCTION public.direction_praxis_du_dossier(text) IS
  'PE-LISTE-CANDIDATURES : le rangement et l''impression courants de Praxis pour UN dossier (formes de direction_praxis_rangements '
  'et direction_praxis_impressions), memes conditions de lecture ; direction seulement.';

-- ====================================================================================================================
-- 5. Trois gestes groupes neufs dans le moteur de lot.
-- ====================================================================================================================

-- Les rapports des gestes neufs : la table publique garde sa liste de gestes (sa contrainte n'est pas reecrite). Memes colonnes,
-- dans le meme ordre (le moteur lit les deux tables dans la meme variable), en ajout seul, sans aucun privilege client.
CREATE TABLE private.candidature_lots_suite (
  cle text PRIMARY KEY CHECK (pg_catalog.length(cle) BETWEEN 8 AND 200),
  auteur_id uuid NOT NULL REFERENCES public.profiles(id),
  geste text NOT NULL CHECK (geste IN ('admettre_verifications', 'demander_complement', 'ecrire')),
  empreinte text NOT NULL CHECK (empreinte ~ '^[0-9a-f]{32}$'),
  jeton text NOT NULL CHECK (jeton ~ '^[0-9a-f]{32}$'),
  resultat jsonb NOT NULL CHECK (pg_catalog.jsonb_typeof(resultat) = 'object'),
  cree_le timestamptz NOT NULL DEFAULT pg_catalog.clock_timestamp()
);
CREATE INDEX candidature_lots_suite_auteur_idx ON private.candidature_lots_suite (auteur_id, cree_le DESC);
-- Une modification est refusee par le meme declencheur que la table publique ; aucun compte client n'a de privilege sur la
-- table (ni lecture, ni ecriture, ni retrait de ligne) : seul le moteur de lot, proprietaire, y ajoute.
CREATE TRIGGER candidature_lots_suite_ajout_seul
  BEFORE UPDATE ON private.candidature_lots_suite
  FOR EACH ROW EXECUTE FUNCTION private.cand_evenements_refuser_mutation();
REVOKE ALL ON private.candidature_lots_suite FROM PUBLIC, anon, authenticated, service_role, agent_ro;
ALTER TABLE private.candidature_lots_suite ENABLE ROW LEVEL SECURITY;
COMMENT ON TABLE private.candidature_lots_suite IS
  'PE-LISTE-CANDIDATURES : rapport de chaque lot admettre, demander un complement, ecrire, sous sa cle d''idempotence, en ajout '
  'seul ; memes colonnes que public.candidature_lots ; aucune policy, aucun privilege client.';

-- L'examen d'un lot. Les gestes d'avant : l'examen d'avant, tel quel.
--   Admettre : l'examen d'avant, puis les dossiers dont un controle d'admission est faux passent dans les exclus (raison
--     controles_non_satisfaits, detail = le premier controle faux) ; le jeton couvre ces exclusions.
--   Demander un complement : chaque eligible porte `elementsPermis`, les elements que son etape accepte (l'ecran ne propose
--     que ceux de TOUS les eligibles) ; avec un element ([p_element], celui de l'execution), les dossiers qui ne l'acceptent
--     pas passent dans les exclus (element_non_permis) et le jeton change : un lot dont l'element n'est pas accepte par tous
--     les eligibles de l'apercu ne part pas (jeton_perime), le nombre annonce est donc celui qui reussira.
--   Ecrire : une ligne est eligible quand la conversation de candidature est possible (dossier d'enseignant en cours, hors
--     pause, avant la salle des prets, avec un compte : les conditions de private.com_paires).
CREATE FUNCTION private.pelc_lot_examiner(p_geste text, p_ids uuid[], p_auteur uuid, p_genre public.gender,
                                          p_element text DEFAULT NULL)
RETURNS jsonb
LANGUAGE plpgsql
STABLE
SET search_path = ''
AS $f$
DECLARE
  v_ex jsonb;
  v_secret text;
  v_i record;
  v_c public.candidatures;
  v_l jsonb;
  v_lignes jsonb := '[]'::jsonb;
  v_part_e text[] := ARRAY[]::text[];
  v_part_x text[] := ARRAY[]::text[];
  v_n integer := 0;
  v_raison text;
  v_faux jsonb;
  v_permis text[];
  v_message text;
BEGIN
  SELECT s.secret INTO v_secret FROM private.candidature_lot_secret s;
  IF v_secret IS NULL OR pg_catalog.length(v_secret) < 64 THEN
    RAISE EXCEPTION 'CAND-L2A2 : cle des jetons de lot absente' USING ERRCODE = 'P0001';
  END IF;

  IF p_geste = 'ecrire' THEN
    FOR v_i IN
      SELECT x.id, pg_catalog.min(x.o) AS o FROM pg_catalog.unnest(p_ids) WITH ORDINALITY AS x(id, o) GROUP BY x.id ORDER BY 2
    LOOP
      SELECT c.* INTO v_c FROM public.candidatures c WHERE c.id = v_i.id;
      IF v_c.id IS NULL THEN
        v_l := pg_catalog.jsonb_build_object('id', v_i.id, 'eligible', false, 'raison', 'absente');
        v_part_x := v_part_x || (v_i.id::text || ':absente');
      ELSIF v_c.genre IS DISTINCT FROM p_genre AND NOT coalesce(public.kyc_super_admin_exception_active(), false) THEN
        v_l := pg_catalog.jsonb_build_object('id', v_i.id, 'eligible', false, 'raison', 'hors_portee');
        v_part_x := v_part_x || (v_i.id::text || ':hors_portee');
      ELSE
        v_l := pg_catalog.jsonb_build_object(
          'id', v_c.id, 'reference', v_c.reference, 'nomComplet', v_c.nom_complet,
          'etape', v_c.etape, 'etat', v_c.etat, 'issue', v_c.issue, 'enPause', v_c.en_pause, 'version', v_c.version);
        v_raison := CASE
          WHEN v_c.type_code IS DISTINCT FROM 'enseignant' OR v_c.issue IS DISTINCT FROM 'en_cours'
               OR v_c.etape = 'confirmee' THEN 'etat'
          WHEN v_c.en_pause THEN 'pause'
          WHEN v_c.profile_id IS NULL THEN 'sans_compte'
        END;
        IF v_raison IS NULL THEN
          v_l := v_l || '{"eligible": true}'::jsonb;
          v_part_e := v_part_e || (v_c.id::text || ':' || v_c.version::text);
          v_n := v_n + 1;
        ELSE
          v_l := v_l || pg_catalog.jsonb_build_object('eligible', false, 'raison', 'sans_conversation', 'detail', v_raison);
          v_part_x := v_part_x || (v_c.id::text || ':sans_conversation:' || v_raison);
        END IF;
      END IF;
      v_lignes := v_lignes || pg_catalog.jsonb_build_array(v_l);
    END LOOP;
    v_message := coalesce(p_auteur::text, '') || '|ecrire|'
      || pg_catalog.array_to_string(ARRAY(SELECT e FROM pg_catalog.unnest(v_part_e) AS e ORDER BY e), ',') || '|'
      || pg_catalog.array_to_string(ARRAY(SELECT e FROM pg_catalog.unnest(v_part_x) AS e ORDER BY e), ',');
    RETURN pg_catalog.jsonb_build_object('lignes', v_lignes, 'nombre', v_n,
      'jeton', pg_catalog.substr(pg_catalog.encode(extensions.hmac(pg_catalog.convert_to(v_message, 'UTF8'),
                                                                   pg_catalog.convert_to(v_secret, 'UTF8'), 'sha256'), 'hex'), 1, 32));
  END IF;

  v_ex := private.candidature_lot_examiner(p_geste, p_ids, p_auteur, p_genre);
  IF p_geste IS DISTINCT FROM 'admettre_verifications' AND p_geste IS DISTINCT FROM 'demander_complement' THEN
    RETURN v_ex;
  END IF;
  FOR v_l IN SELECT x.e FROM pg_catalog.jsonb_array_elements(v_ex -> 'lignes') WITH ORDINALITY AS x(e, o) ORDER BY x.o LOOP
    IF (v_l ->> 'eligible')::boolean THEN
      SELECT c.* INTO v_c FROM public.candidatures c WHERE c.id = (v_l ->> 'id')::uuid;
      IF p_geste = 'admettre_verifications' THEN
        v_faux := private.candidature_controles_faux(private.candidature_controles_entree(v_c, 'admission'));
        IF pg_catalog.jsonb_array_length(v_faux) > 0 THEN
          v_l := v_l || pg_catalog.jsonb_build_object('eligible', false, 'raison', 'controles_non_satisfaits',
                                                      'detail', v_faux -> 0 ->> 'nom');
          v_part_x := v_part_x || ((v_l ->> 'id') || ':' || coalesce(v_faux -> 0 ->> 'nom', '?'));
        ELSE
          v_n := v_n + 1;
        END IF;
      ELSE
        -- Les elements que demander_complement_candidat accepte pour ce dossier (memes regles : la variante 4, paiement
        -- non disponible, ne porte que sur le versement ; la cloture n'est pas un element a demander en lot).
        v_permis := CASE WHEN v_c.etape = 'prequalification' AND v_c.etat = 'paiement_non_disponible'
                         THEN ARRAY['versement']::text[]
                         ELSE ARRAY(SELECT x FROM pg_catalog.unnest(private.candidature_complement_codes(v_c.etape, v_c.type_code)) AS x
                                     WHERE x <> 'complement_clos') END;
        v_l := v_l || pg_catalog.jsonb_build_object('elementsPermis', pg_catalog.to_jsonb(v_permis));
        IF p_element IS NOT NULL AND NOT (p_element = ANY (v_permis)) THEN
          v_l := v_l || pg_catalog.jsonb_build_object('eligible', false, 'raison', 'element_non_permis');
          v_part_x := v_part_x || ((v_l ->> 'id') || ':element_non_permis');
        ELSE
          v_n := v_n + 1;
        END IF;
      END IF;
    END IF;
    v_lignes := v_lignes || pg_catalog.jsonb_build_array(v_l);
  END LOOP;
  IF pg_catalog.cardinality(v_part_x) = 0 THEN
    RETURN pg_catalog.jsonb_build_object('lignes', v_lignes, 'nombre', v_n, 'jeton', v_ex ->> 'jeton');
  END IF;
  v_message := (v_ex ->> 'jeton') || '|' || p_geste || '|'
    || pg_catalog.array_to_string(ARRAY(SELECT e FROM pg_catalog.unnest(v_part_x) AS e ORDER BY e), ',');
  RETURN pg_catalog.jsonb_build_object('lignes', v_lignes, 'nombre', v_n,
    'jeton', pg_catalog.substr(pg_catalog.encode(extensions.hmac(pg_catalog.convert_to(v_message, 'UTF8'),
                                                                 pg_catalog.convert_to(v_secret, 'UTF8'), 'sha256'), 'hex'), 1, 32));
END;
$f$;

-- Ecrire a une personne : sa conversation de candidature (ouverte au besoin), un message de la direction. La cle du message
-- derive du FIL, du JOUR (UTC) et du TEXTE normalise (casse et blancs), jamais de la cle du lot : le meme texte au meme
-- candidat le meme jour par un lot ne part qu'une fois, quel que soit le lot, l'onglet ou l'auteur ; la ligne le dit alors
-- (`deja_envoye`).
CREATE FUNCTION private.pelc_ecrire_un(p_id uuid, p_texte text)
RETURNS jsonb
LANGUAGE plpgsql
SET search_path = ''
AS $f$
DECLARE
  v_c public.candidatures;
  v_fil jsonb;
  v_fil_id uuid;
  v_cle uuid;
  v_m jsonb;
BEGIN
  SELECT c.* INTO v_c FROM public.candidatures c WHERE c.id = p_id;
  IF v_c.id IS NULL OR v_c.profile_id IS NULL THEN
    RETURN pg_catalog.jsonb_build_object('erreur', 'sans_conversation');
  END IF;
  v_fil := public.com_ouvrir_conversation('candidature', p_id, v_c.profile_id::text);
  IF v_fil IS NULL OR v_fil ->> 'id' IS NULL THEN
    RETURN pg_catalog.jsonb_build_object('erreur', 'sans_conversation');
  END IF;
  v_fil_id := (v_fil ->> 'id')::uuid;
  v_cle := pg_catalog.md5('pelc-ecrire|' || v_fil_id::text || '|'
                          || (pg_catalog.now() AT TIME ZONE 'UTC')::date::text || '|'
                          || pg_catalog.lower(pg_catalog.regexp_replace(pg_catalog.btrim(p_texte), '\s+', ' ', 'g')))::uuid;
  -- Deux lots concurrents pour le meme fil se suivent.
  PERFORM pg_catalog.pg_advisory_xact_lock(pg_catalog.hashtextextended('pelc-ecrire:' || v_cle::text, 0));
  IF EXISTS (SELECT 1 FROM public.com_messages m WHERE m.fil_id = v_fil_id AND m.cle_idempotence = v_cle) THEN
    RETURN pg_catalog.jsonb_build_object('erreur', 'deja_envoye');
  END IF;
  v_m := public.com_envoyer_message(v_fil_id, p_texte, v_cle);
  IF v_m IS NOT NULL AND pg_catalog.jsonb_typeof(v_m) = 'object' AND v_m ? 'erreur' THEN
    RETURN pg_catalog.jsonb_build_object('erreur', coalesce(v_m ->> 'erreur', 'message_refuse'));
  END IF;
  RETURN pg_catalog.jsonb_build_object('candidature', private.candidature_etat_direction(p_id));
END;
$f$;

-- Une ligne d'un lot : les gestes neufs par leur fonction publique (memes controles, memes courriels, meme journal que le geste
-- fait sur la fiche) ; les gestes d'avant par le coeur d'avant, inchange. [p_cle] est la cle de LIGNE du moteur
-- (`lot-<md5 de la cle du lot>-<identifiant>`, 73 signes, unique par lot et par ligne) : admettre et le complement recoivent
-- `lot-<md5 de cette cle de ligne>` (36 signes, toujours unique par lot et par ligne), car admettre_salle_verification en
-- derive la cle de son courriel (`retenu_entretien:<id>:<cle>`, 120 signes au plus).
CREATE FUNCTION private.pelc_geste_de_lot(p_id uuid, p_geste text, p_auteur uuid, p_version integer, p_cle text, p_motif text,
                                          p_modele text, p_reprise_le date, p_details jsonb)
RETURNS jsonb
LANGUAGE plpgsql
SET search_path = ''
AS $f$
BEGIN
  CASE p_geste
    WHEN 'admettre_verifications' THEN
      RETURN public.admettre_salle_verification(p_id, p_version, 'lot-' || pg_catalog.md5(p_cle));
    WHEN 'demander_complement' THEN
      RETURN public.demander_complement_candidat(p_id, ARRAY[p_modele]::text[], p_motif, p_version,
                                                 'lot-' || pg_catalog.md5(p_cle));
    WHEN 'ecrire' THEN
      RETURN private.pelc_ecrire_un(p_id, p_motif);
    ELSE
      RETURN private.candidature_geste_groupe(p_id, p_geste, p_auteur, p_version, p_cle, p_motif, p_modele, p_reprise_le,
                                              p_details);
  END CASE;
END;
$f$;

ALTER FUNCTION private.pelc_lot_examiner(text, uuid[], uuid, public.gender, text) OWNER TO postgres;
ALTER FUNCTION private.pelc_ecrire_un(uuid, text) OWNER TO postgres;
ALTER FUNCTION private.pelc_geste_de_lot(uuid, text, uuid, integer, text, text, text, date, jsonb) OWNER TO postgres;
REVOKE ALL ON FUNCTION private.pelc_lot_examiner(text, uuid[], uuid, public.gender, text) FROM PUBLIC, anon, authenticated, service_role, agent_ro;
REVOKE ALL ON FUNCTION private.pelc_ecrire_un(uuid, text) FROM PUBLIC, anon, authenticated, service_role, agent_ro;
REVOKE ALL ON FUNCTION private.pelc_geste_de_lot(uuid, text, uuid, integer, text, text, text, date, jsonb)
  FROM PUBLIC, anon, authenticated, service_role, agent_ro;

DO $retouche_lot$
DECLARE
  v_def text;
BEGIN
  -- L'apercu.
  v_def := pg_catalog.pg_get_functiondef('public.apercu_lot_candidats(text,uuid[])'::pg_catalog.regprocedure);
  v_def := pg_temp.remplacer(v_def,
    'WHEN ''dispenserEntretien'' THEN ''dispenser_entretien''',
    'WHEN ''dispenserEntretien'' THEN ''dispenser_entretien''
                          WHEN ''admettre'' THEN ''admettre_verifications'' WHEN ''demanderComplement'' THEN ''demander_complement''',
    'apercu noms');
  v_def := pg_temp.remplacer(v_def,
    'IF v_geste NOT IN (''mettre_en_pause'', ''lever_pause'', ''refuser'', ''dispenser_entretien'') THEN',
    'IF v_geste NOT IN (''mettre_en_pause'', ''lever_pause'', ''refuser'', ''dispenser_entretien'',
                      ''admettre_verifications'', ''demander_complement'', ''ecrire'') THEN',
    'apercu groupables');
  v_def := pg_temp.remplacer(v_def,
    'v_ex := private.candidature_lot_examiner(v_geste, p_ids, v_lecteur, v_genre);',
    'v_ex := private.pelc_lot_examiner(v_geste, p_ids, v_lecteur, v_genre);',
    'apercu examen');
  v_def := pg_temp.remplacer(v_def,
    '''motifRequis'', v_geste IN (''mettre_en_pause'', ''refuser'', ''dispenser_entretien''),',
    '''motifRequis'', v_geste IN (''mettre_en_pause'', ''refuser'', ''dispenser_entretien'', ''demander_complement'', ''ecrire''),',
    'apercu motif');
  EXECUTE v_def;

  -- L'execution.
  v_def := pg_catalog.pg_get_functiondef(
    'public.executer_lot_candidats(text,uuid[],text,integer,text,text,text,date)'::pg_catalog.regprocedure);
  v_def := pg_temp.remplacer(v_def,
    'WHEN ''dispenserEntretien'' THEN ''dispenser_entretien''',
    'WHEN ''dispenserEntretien'' THEN ''dispenser_entretien''
                          WHEN ''admettre'' THEN ''admettre_verifications'' WHEN ''demanderComplement'' THEN ''demander_complement''',
    'executer noms');
  v_def := pg_temp.remplacer(v_def,
    'v_groupable := v_geste IN (''mettre_en_pause'', ''lever_pause'', ''refuser'', ''dispenser_entretien'');',
    'v_groupable := v_geste IN (''mettre_en_pause'', ''lever_pause'', ''refuser'', ''dispenser_entretien'',
                              ''admettre_verifications'', ''demander_complement'', ''ecrire'');',
    'executer groupables');
  v_def := pg_temp.remplacer(v_def,
    'SELECT l.* INTO v_lot FROM public.candidature_lots l WHERE l.cle = p_cle_idempotence;',
    '-- PE-LISTE-CANDIDATURES : pour les gestes neufs, l''empreinte couvre aussi le motif (le message d''ecrire) et le modele
  -- (l''element du complement) : la meme cle rejouee avec un autre texte est refusee (cle_idempotence_reutilisee), jamais
  -- rejouee en silence. L''empreinte des gestes d''avant ne change pas.
  IF v_geste IN (''admettre_verifications'', ''demander_complement'', ''ecrire'') THEN
    v_empreinte := pg_catalog.md5(v_empreinte || ''|'' || coalesce(v_motif, '''') || ''|'' || coalesce(p_modele, ''''));
  END IF;
  SELECT l.* INTO v_lot
    FROM (SELECT * FROM public.candidature_lots UNION ALL SELECT * FROM private.candidature_lots_suite) l
   WHERE l.cle = p_cle_idempotence;',
    'executer rejeu');
  v_def := pg_temp.remplacer(v_def,
    '  -- Le lot n''a pas change depuis l''apercu, et la direction a saisi son',
    '  -- PE-LISTE-CANDIDATURES : admettre et ecrire ne portent aucun modele ; le complement porte UN element (p_modele) et un
  -- motif ; ecrire porte son message (p_motif).
  IF v_geste IN (''admettre_verifications'', ''ecrire'') AND p_modele IS NOT NULL THEN
    RAISE EXCEPTION ''lot : aucun modele pour ce geste'' USING ERRCODE = ''22023'';
  END IF;
  IF v_geste IN (''demander_complement'', ''ecrire'') AND v_motif IS NULL THEN
    RETURN pg_catalog.jsonb_build_object(''erreur'', ''motif_requis'', ''geste'', v_geste);
  END IF;
  IF v_geste = ''demander_complement'' AND p_modele IS NULL THEN
    RETURN pg_catalog.jsonb_build_object(''erreur'', ''elements_requis'', ''geste'', v_geste);
  END IF;

  -- Le lot n''a pas change depuis l''apercu, et la direction a saisi son',
    'executer exigences');
  v_def := pg_temp.remplacer(v_def,
    'v_ex := private.candidature_lot_examiner(v_geste, p_ids, v_lecteur, v_genre);',
    'v_ex := private.pelc_lot_examiner(v_geste, p_ids, v_lecteur, v_genre,
                                     CASE WHEN v_geste = ''demander_complement'' THEN p_modele END);',
    'executer examen');
  v_def := pg_temp.remplacer(v_def,
    'v_r := private.candidature_geste_groupe(',
    'v_r := private.pelc_geste_de_lot(',
    'executer ligne');
  v_def := pg_temp.remplacer(v_def,
    '  INSERT INTO public.candidature_lots (cle, auteur_id, geste, empreinte, jeton, resultat)
  VALUES (p_cle_idempotence, v_uid, v_geste, v_empreinte, p_jeton, v_resultat);',
    '  IF v_geste IN (''admettre_verifications'', ''demander_complement'', ''ecrire'') THEN
    INSERT INTO private.candidature_lots_suite (cle, auteur_id, geste, empreinte, jeton, resultat)
    VALUES (p_cle_idempotence, v_uid, v_geste, v_empreinte, p_jeton, v_resultat);
  ELSE
    INSERT INTO public.candidature_lots (cle, auteur_id, geste, empreinte, jeton, resultat)
    VALUES (p_cle_idempotence, v_uid, v_geste, v_empreinte, p_jeton, v_resultat);
  END IF;',
    'executer rapport');
  EXECUTE v_def;
END
$retouche_lot$;

-- ====================================================================================================================
-- 6. Empreintes F86 : le commentaire des fonctions retouchees qui en portent une suit leur nouveau corps.
-- ====================================================================================================================
DO $f86$
DECLARE
  f regprocedure;
  v_com text;
BEGIN
  FOREACH f IN ARRAY ARRAY['public.lister_candidatures(jsonb,text,integer)'::regprocedure,
                           'public.voisins_candidature(text,jsonb,text)'::regprocedure,
                           'public.apercu_lot_candidats(text,uuid[])'::regprocedure,
                           'public.executer_lot_candidats(text,uuid[],text,integer,text,text,text,date)'::regprocedure] LOOP
    v_com := coalesce(pg_catalog.obj_description(f, 'pg_proc'), '');
    IF v_com LIKE '%md5_functiondef=%' THEN
      v_com := pg_catalog.regexp_replace(v_com, 'md5_functiondef=[0-9A-Za-z_]+',
        'md5_functiondef=' || pg_catalog.md5(pg_catalog.pg_get_functiondef(f)));
      IF pg_catalog.strpos(v_com, 'PE-LISTE-CANDIDATURES') = 0 THEN
        v_com := v_com || ' PE-LISTE-CANDIDATURES (20/11/2026) : tri ancienne, filtres dossierComplet, pilePraxis, etiquettePraxis ;'
                       || ' lots admettre, demander un complement, ecrire.';
      END IF;
      EXECUTE pg_catalog.format('COMMENT ON FUNCTION %s IS %L', f, v_com);
    END IF;
  END LOOP;
END
$f86$;

-- ====================================================================================================================
-- 7. Controle final.
-- ====================================================================================================================
DO $postflight$
DECLARE
  v_f text;
BEGIN
  FOREACH v_f IN ARRAY ARRAY['public.lister_candidatures(jsonb,text,integer)', 'public.voisins_candidature(text,jsonb,text)',
                             'public.selection_resultats_file(jsonb,text)'] LOOP
    IF pg_catalog.strpos(pg_catalog.pg_get_functiondef(v_f::pg_catalog.regprocedure), 'private.pelc_predicat(c, v_filtre)') = 0
       OR pg_catalog.strpos(pg_catalog.pg_get_functiondef(v_f::pg_catalog.regprocedure), 'p_tri = ''ancienne''') = 0 THEN
      RAISE EXCEPTION 'PE-LISTE-CANDIDATURES : retouche absente dans %', v_f;
    END IF;
  END LOOP;
  IF pg_catalog.strpos(pg_catalog.pg_get_functiondef('public.apercu_lot_candidats(text,uuid[])'::pg_catalog.regprocedure),
                       'private.pelc_lot_examiner') = 0
     OR pg_catalog.strpos(pg_catalog.pg_get_functiondef(
          'public.executer_lot_candidats(text,uuid[],text,integer,text,text,text,date)'::pg_catalog.regprocedure),
          'private.pelc_geste_de_lot') = 0 THEN
    RAISE EXCEPTION 'PE-LISTE-CANDIDATURES : retouche du lot absente';
  END IF;
  -- Les fonctions publiques : direction (authenticated, controle dans le corps), jamais anon.
  FOREACH v_f IN ARRAY ARRAY['public.selection_resultats_file(jsonb,text)', 'public.direction_praxis_du_dossier(text)',
                             'public.lister_candidatures(jsonb,text,integer)', 'public.apercu_lot_candidats(text,uuid[])',
                             'public.executer_lot_candidats(text,uuid[],text,integer,text,text,text,date)'] LOOP
    IF pg_catalog.has_function_privilege('anon', v_f, 'EXECUTE')
       OR NOT pg_catalog.has_function_privilege('authenticated', v_f, 'EXECUTE')
       OR (SELECT NOT p.prosecdef OR p.proconfig IS DISTINCT FROM ARRAY['search_path=""']
             FROM pg_catalog.pg_proc p WHERE p.oid = v_f::pg_catalog.regprocedure) THEN
      RAISE EXCEPTION 'PE-LISTE-CANDIDATURES : droits ou reglages inattendus sur %', v_f;
    END IF;
  END LOOP;
  -- Les aides privees : aucun compte client.
  FOREACH v_f IN ARRAY ARRAY['private.pelc_filtre_valider(jsonb)', 'private.pelc_predicat(public.candidatures,jsonb)',
                             'private.pelc_lot_examiner(text,uuid[],uuid,public.gender,text)', 'private.pelc_ecrire_un(uuid,text)',
                             'private.pelc_geste_de_lot(uuid,text,uuid,integer,text,text,text,date,jsonb)'] LOOP
    IF pg_catalog.has_function_privilege('anon', v_f, 'EXECUTE')
       OR pg_catalog.has_function_privilege('authenticated', v_f, 'EXECUTE') THEN
      RAISE EXCEPTION 'PE-LISTE-CANDIDATURES : droits d''execution trop larges sur %', v_f;
    END IF;
  END LOOP;
  IF pg_catalog.has_table_privilege('authenticated', 'private.candidature_lots_suite', 'SELECT')
     OR NOT (SELECT c.relrowsecurity FROM pg_catalog.pg_class c WHERE c.oid = 'private.candidature_lots_suite'::pg_catalog.regclass) THEN
    RAISE EXCEPTION 'PE-LISTE-CANDIDATURES : table des rapports trop ouverte';
  END IF;
END
$postflight$;
