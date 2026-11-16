-- BE-S1 (Bureau de l'equipe, vagues 0 et 1, ordre du directeur du 16/11/2026) :
-- les lectures du serveur pour la file et le dossier des candidatures.
--
-- Ce fichier est SANS aucun mot d'effacement : le pilote l'installe. Aucun autre
-- fichier n'accompagne ce lot.
--
-- Additif (B6) : l'ancien code lit toujours les memes champs ; seuls des champs
-- sont ajoutes a l'historique et au dossier, et des cles de filtre sont acceptees.
-- Aucune politique RLS, aucune machine a etats, aucun geste ne change. Aucun
-- index : les filtres sur les reponses lisent la derniere ligne de
-- candidature_reponses par l'index existant (candidature_id, soumis_le DESC) et
-- la derniere piece par kyc_documents ; une liste est deja bornee a la portee de
-- genre du lecteur.
--
-- 1. historique_candidature : `details` (liste blanche de cles, jamais de contact
--    ni de piece) et, pour un evenement « responsable », le nom du responsable
--    avant et apres.
-- 2. lire_candidature : `responsableNom`.
-- 3. lister_candidatures : filtres ijaza, langueExplication, riwaya, public,
--    jours, heureMin, heureMax, joursMin (reponses), pieceEnAttente, responsable
--    (file). Cle inconnue : refusee 22023 comme aujourd'hui.
-- 4. voisins_candidature : precedent, suivant, rang, total, dans le meme filtre,
--    le meme tri et la meme portee que la liste.
--
-- Lecteurs recenses (B1) : aucune colonne ne change de sens. Les trois fonctions
-- retouchees (historique_candidature, lire_candidature, lister_candidatures) ne
-- sont lues que par lib/core/candidature/*_supabase.dart (ajout de champs
-- facultatifs) et par les scenarios supabase/tests/scenarios_cand_*.sql.


CREATE FUNCTION pg_temp.remplacer(p_def text, p_avant text, p_apres text, p_nom text)
RETURNS text
LANGUAGE plpgsql
AS $f$
DECLARE
  v_n integer;
BEGIN
  v_n := (pg_catalog.length(p_def) - pg_catalog.length(pg_catalog.replace(p_def, p_avant, '')))
         / pg_catalog.length(p_avant);
  IF v_n <> 1 THEN
    RAISE EXCEPTION 'BE-S1 : ancre % trouvee % fois (une attendue)', p_nom, v_n;
  END IF;
  RETURN pg_catalog.replace(p_def, p_avant, p_apres);
END;
$f$;

-- ============================================================
-- 1. Fonctions privees
-- ============================================================

-- Le nom affichable d'un membre de la direction, ou nul.
CREATE FUNCTION private.be_nom_membre(p_id uuid)
RETURNS text
LANGUAGE sql
STABLE
SECURITY INVOKER
SET search_path = ''
AS $function$
  SELECT nullif(pg_catalog.btrim(pg_catalog.concat_ws(' ', p.first_name, p.last_name)), '')
  FROM public.profiles p
  WHERE p.id = p_id;
$function$;

-- Le contenu utile d'un evenement, par liste blanche : ni contact, ni piece, ni
-- identifiant de personne, ni cle de rattachement.
CREATE FUNCTION private.be_details_lisibles(p_details jsonb)
RETURNS jsonb
LANGUAGE sql
STABLE
SECURITY INVOKER
SET search_path = ''
AS $function$
  SELECT coalesce((
           SELECT pg_catalog.jsonb_object_agg(e.key, e.value)
           FROM pg_catalog.jsonb_each(coalesce(p_details, '{}'::jsonb)) e
           WHERE e.key = ANY (ARRAY['geste', 'transition', 'auteur', 'modele', 'controle',
                                    'valeurAvant', 'valeurApres', 'cause',
                                    'paiementAvant', 'paiementApres', 'paysAvant', 'paysApres',
                                    'restrictionCause', 'entretienPlanifie', 'pauseLevee'])), '{}'::jsonb)
         || coalesce((
           SELECT pg_catalog.jsonb_build_object('changements', t.a)
           FROM (SELECT pg_catalog.jsonb_object_agg(c.key, c.value) AS a
                 FROM pg_catalog.jsonb_each(CASE WHEN pg_catalog.jsonb_typeof(p_details -> 'changements') = 'object'
                                                 THEN p_details -> 'changements' ELSE '{}'::jsonb END) c
                 WHERE c.key = ANY (ARRAY['reprise_le', 'indisponible_jusqu_au', 'pays_residence', 'fuseau_iana'])) t
           WHERE t.a IS NOT NULL),
           '{}'::jsonb);
$function$;

-- Le responsable d'un evenement « responsable » : nom avant et nom apres.
CREATE FUNCTION private.be_responsable_evenement(p_details jsonb)
RETURNS jsonb
LANGUAGE sql
STABLE
SECURITY INVOKER
SET search_path = ''
AS $function$
  SELECT pg_catalog.jsonb_build_object(
    'responsableAvantNom',
      private.be_nom_membre(CASE WHEN p_details #>> '{changements,responsable_id,avant}'
                                        ~ '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$'
                                   THEN (p_details #>> '{changements,responsable_id,avant}')::uuid END),
    'responsableNom',
      private.be_nom_membre(CASE WHEN p_details #>> '{changements,responsable_id,apres}'
                                        ~ '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$'
                                   THEN (p_details #>> '{changements,responsable_id,apres}')::uuid END));
$function$;

-- Les valeurs des nouveaux filtres : refus 22023 si elles sont mal formees.
CREATE FUNCTION private.be_filtre_valider(p_filtre jsonb)
RETURNS void
LANGUAGE plpgsql
STABLE
SECURITY INVOKER
SET search_path = ''
AS $function$
DECLARE
  v_min integer;
  v_max integer;
BEGIN
  IF p_filtre ->> 'jours' IS NOT NULL AND (
       pg_catalog.jsonb_array_length(p_filtre -> 'jours') NOT BETWEEN 1 AND 7
       OR EXISTS (SELECT 1 FROM pg_catalog.jsonb_array_elements(p_filtre -> 'jours') j
                   WHERE pg_catalog.jsonb_typeof(j) <> 'number' OR j::text !~ '^[1-7]$')) THEN
    RAISE EXCEPTION 'filtre de candidatures mal type : jours' USING ERRCODE = '22023';
  END IF;
  IF (p_filtre ->> 'heureMin' IS NOT NULL AND p_filtre ->> 'heureMin' !~ '^([0-9]|1[0-9]|2[0-3])$')
     OR (p_filtre ->> 'heureMax' IS NOT NULL AND p_filtre ->> 'heureMax' !~ '^([1-9]|1[0-9]|2[0-4])$') THEN
    RAISE EXCEPTION 'filtre de candidatures mal type : heures' USING ERRCODE = '22023';
  END IF;
  v_min := coalesce((p_filtre ->> 'heureMin')::integer, 0);
  v_max := coalesce((p_filtre ->> 'heureMax')::integer, 24);
  IF v_min >= v_max THEN
    RAISE EXCEPTION 'filtre de candidatures mal type : heureMin avant heureMax' USING ERRCODE = '22023';
  END IF;
  IF p_filtre ->> 'joursMin' IS NOT NULL AND p_filtre ->> 'joursMin' !~ '^[1-7]$' THEN
    RAISE EXCEPTION 'filtre de candidatures mal type : joursMin' USING ERRCODE = '22023';
  END IF;
  IF p_filtre ->> 'ijaza' IS NOT NULL AND p_filtre ->> 'ijaza' NOT IN ('oui', 'pret_test', 'non') THEN
    RAISE EXCEPTION 'filtre de candidatures mal type : ijaza' USING ERRCODE = '22023';
  END IF;
  IF (p_filtre ->> 'langueExplication' IS NOT NULL AND p_filtre ->> 'langueExplication' !~ '^[a-z0-9_]{1,40}$')
     OR (p_filtre ->> 'riwaya' IS NOT NULL AND p_filtre ->> 'riwaya' !~ '^[a-z0-9_]{1,40}$')
     OR (p_filtre ->> 'public' IS NOT NULL
         AND p_filtre ->> 'public' NOT IN ('6_9', '10_13', '14_17', 'adultes'))
     OR (p_filtre ->> 'responsable' IS NOT NULL
         AND p_filtre ->> 'responsable' NOT IN ('moi', 'aucun')
         AND p_filtre ->> 'responsable'
             !~ '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$') THEN
    RAISE EXCEPTION 'valeur de filtre de candidatures invalide' USING ERRCODE = '22023';
  END IF;
END;
$function$;

-- Les nouveaux filtres, pour une candidature. Une cle absente ou nulle ne filtre
-- pas. Les reponses lues sont les plus recentes ; les heures sont celles du
-- fuseau du candidat, jamais converties ; les plages sont lues en HH:MM et
-- comparees en minutes ; un jour compte s'il a au moins une plage qui recouvre
-- [heureMin, heureMax[.
CREATE FUNCTION private.be_predicat(c public.candidatures, p_filtre jsonb, p_lecteur uuid)
RETURNS boolean
LANGUAGE plpgsql
STABLE
SECURITY INVOKER
SET search_path = ''
AS $function$
DECLARE
  v_rep jsonb;
  v_ijaza text := p_filtre ->> 'ijaza';
  v_piece boolean := (p_filtre ->> 'pieceEnAttente')::boolean;
  v_resp text := p_filtre ->> 'responsable';
  v_a_dispo boolean := coalesce(p_filtre ->> 'jours', p_filtre ->> 'heureMin',
                                p_filtre ->> 'heureMax', p_filtre ->> 'joursMin') IS NOT NULL;
  v_a_rep boolean := coalesce(p_filtre ->> 'ijaza', p_filtre ->> 'langueExplication',
                              p_filtre ->> 'riwaya', p_filtre ->> 'public') IS NOT NULL OR v_a_dispo;
  v_jours integer[];
  v_hmin integer := coalesce((p_filtre ->> 'heureMin')::integer, 0);
  v_hmax integer := coalesce((p_filtre ->> 'heureMax')::integer, 24);
  v_requis integer := coalesce((p_filtre ->> 'joursMin')::integer, 1);
  v_n integer;
  v_derniere pg_catalog.text;
BEGIN
  IF v_resp IS NOT NULL THEN
    IF v_resp = 'moi' THEN
      IF c.responsable_id IS DISTINCT FROM p_lecteur THEN RETURN false; END IF;
    ELSIF v_resp = 'aucun' THEN
      IF c.responsable_id IS NOT NULL THEN RETURN false; END IF;
    ELSIF c.responsable_id IS DISTINCT FROM v_resp::uuid THEN
      RETURN false;
    END IF;
  END IF;

  IF v_piece IS NOT NULL THEN
    SELECT k.status::text INTO v_derniere
      FROM public.kyc_documents k
     WHERE k.profile_id = c.profile_id AND k.deleted_at IS NULL
     ORDER BY k.created_at DESC, k.id DESC
     LIMIT 1;
    IF (v_derniere IS NOT DISTINCT FROM 'pending') IS DISTINCT FROM v_piece THEN
      RETURN false;
    END IF;
  END IF;

  IF NOT v_a_rep THEN
    RETURN true;
  END IF;
  SELECT r.reponses INTO v_rep
    FROM public.candidature_reponses r
   WHERE r.candidature_id = c.id
   ORDER BY r.soumis_le DESC, r.id DESC
   LIMIT 1;
  IF v_rep IS NULL THEN
    RETURN false;
  END IF;

  IF v_ijaza IS NOT NULL
     AND (v_rep ->> 'ijazaPresentable') IS DISTINCT FROM v_ijaza THEN
    RETURN false;
  END IF;
  IF p_filtre ->> 'langueExplication' IS NOT NULL
     AND NOT coalesce(pg_catalog.jsonb_typeof(v_rep -> 'languesExplication') = 'array'
                      AND (v_rep -> 'languesExplication') ? (p_filtre ->> 'langueExplication'), false) THEN
    RETURN false;
  END IF;
  IF p_filtre ->> 'riwaya' IS NOT NULL
     AND NOT coalesce(pg_catalog.jsonb_typeof(v_rep -> 'riwayat') = 'array'
                      AND (v_rep -> 'riwayat') ? (p_filtre ->> 'riwaya'), false) THEN
    RETURN false;
  END IF;
  IF p_filtre ->> 'public' IS NOT NULL
     AND NOT coalesce(pg_catalog.jsonb_typeof(v_rep -> 'publics') = 'array'
                      AND (v_rep -> 'publics') ? (p_filtre ->> 'public'), false) THEN
    RETURN false;
  END IF;

  IF v_a_dispo THEN
    IF p_filtre ->> 'jours' IS NOT NULL THEN
      SELECT pg_catalog.array_agg(j::text::integer) INTO v_jours
        FROM pg_catalog.jsonb_array_elements(p_filtre -> 'jours') j;
    END IF;
    IF pg_catalog.jsonb_typeof(v_rep -> 'disponibilitesDeclarees') IS DISTINCT FROM 'array' THEN
      RETURN false;
    END IF;
    SELECT pg_catalog.count(DISTINCT (x ->> 'jour')::integer) INTO v_n
      FROM pg_catalog.jsonb_array_elements(v_rep -> 'disponibilitesDeclarees') x
     WHERE CASE WHEN pg_catalog.jsonb_typeof(x) = 'object'
                     AND x ->> 'jour' ~ '^[1-7]$'
                     AND x ->> 'debut' ~ '^([01]?[0-9]|2[0-3]):[0-5][0-9]$'
                     AND x ->> 'fin' ~ '^(([01]?[0-9]|2[0-3]):[0-5][0-9]|24:00)$'
                THEN (v_jours IS NULL OR (x ->> 'jour')::integer = ANY (v_jours))
                     AND pg_catalog.split_part(x ->> 'debut', ':', 1)::integer * 60
                         + pg_catalog.split_part(x ->> 'debut', ':', 2)::integer < v_hmax * 60
                     AND pg_catalog.split_part(x ->> 'fin', ':', 1)::integer * 60
                         + pg_catalog.split_part(x ->> 'fin', ':', 2)::integer > v_hmin * 60
                ELSE false END;
    IF v_n < v_requis THEN
      RETURN false;
    END IF;
  END IF;
  RETURN true;
END;
$function$;

REVOKE ALL ON FUNCTION private.be_nom_membre(uuid) FROM PUBLIC, anon, authenticated, service_role, agent_ro;
REVOKE ALL ON FUNCTION private.be_details_lisibles(jsonb) FROM PUBLIC, anon, authenticated, service_role, agent_ro;
REVOKE ALL ON FUNCTION private.be_responsable_evenement(jsonb) FROM PUBLIC, anon, authenticated, service_role, agent_ro;
REVOKE ALL ON FUNCTION private.be_filtre_valider(jsonb) FROM PUBLIC, anon, authenticated, service_role, agent_ro;
REVOKE ALL ON FUNCTION private.be_predicat(public.candidatures, jsonb, uuid) FROM PUBLIC, anon, authenticated, service_role, agent_ro;

-- ============================================================
-- 2. Retouches par ancre (B4)
-- ============================================================

DO $retouches$
DECLARE
  f_hist regprocedure := 'public.historique_candidature(uuid,bigint,integer)'::regprocedure;
  f_lire regprocedure := 'public.lire_candidature(uuid)'::regprocedure;
  f_liste regprocedure := 'public.lister_candidatures(jsonb,text,integer)'::regprocedure;
  v_def text;
  f regprocedure;
  v_com text;
BEGIN
  -- historique_candidature
  v_def := pg_catalog.pg_get_functiondef(f_hist);
  v_def := pg_temp.remplacer(v_def, '''motif'', p.motif_interne)',
    '''motif'', p.motif_interne,' || E'\n'
    || '             ''details'', private.be_details_lisibles(p.details))' || E'\n'
    || '           || CASE WHEN p.type = ''responsable''' || E'\n'
    || '                   THEN private.be_responsable_evenement(p.details)' || E'\n'
    || '                   ELSE ''{}''::jsonb END', 'historique.motif');
  EXECUTE v_def;

  -- lire_candidature
  v_def := pg_catalog.pg_get_functiondef(f_lire);
  v_def := pg_temp.remplacer(v_def, '''restrictionCause'', v_c.restriction_cause,',
    '''restrictionCause'', v_c.restriction_cause,' || E'\n'
    || '    ''responsableNom'', private.be_nom_membre(v_c.responsable_id),', 'lire.restrictionCause');
  EXECUTE v_def;

  -- lister_candidatures
  v_def := pg_catalog.pg_get_functiondef(f_liste);
  v_def := pg_temp.remplacer(v_def,
    '''competenceNiveauMin'', ''competenceDisponibilite'', ''competenceAccord'']);',
    '''competenceNiveauMin'', ''competenceDisponibilite'', ''competenceAccord'',' || E'\n'
    || '                            ''ijaza'', ''langueExplication'', ''riwaya'', ''public'', ''jours'',' || E'\n'
    || '                            ''heureMin'', ''heureMax'', ''joursMin'', ''pieceEnAttente'', ''responsable'']);',
    'liste.cles');
  v_def := pg_temp.remplacer(v_def,
    '<> CASE WHEN e.key IN (''enPause'', ''competenceAccord'') THEN ''boolean'' ELSE ''string'' END;',
    '<> CASE WHEN e.key IN (''enPause'', ''competenceAccord'', ''pieceEnAttente'') THEN ''boolean''' || E'\n'
    || '                WHEN e.key IN (''heureMin'', ''heureMax'', ''joursMin'') THEN ''number''' || E'\n'
    || '                WHEN e.key = ''jours'' THEN ''array'' ELSE ''string'' END;',
    'liste.types');
  v_def := pg_temp.remplacer(v_def, '  v_type := v_filtre ->> ''type'';',
    '  PERFORM private.be_filtre_valider(v_filtre);' || E'\n'
    || '  v_type := v_filtre ->> ''type'';', 'liste.type');
  v_def := pg_temp.remplacer(v_def,
    '      AND (v_filtre ->> ''genre'' IS NULL OR c.genre::text = v_filtre ->> ''genre'')',
    '      AND (v_filtre ->> ''genre'' IS NULL OR c.genre::text = v_filtre ->> ''genre'')' || E'\n'
    || '      AND (NOT (v_filtre ?| ARRAY[''ijaza'', ''langueExplication'', ''riwaya'', ''public'', ''jours'',' || E'\n'
    || '                                  ''heureMin'', ''heureMax'', ''joursMin'', ''pieceEnAttente'', ''responsable''])' || E'\n'
    || '           OR private.be_predicat(c, v_filtre, v_lecteur))', 'liste.where');
  EXECUTE v_def;

  FOREACH f IN ARRAY ARRAY[f_hist, f_lire, f_liste] LOOP
    v_com := pg_catalog.obj_description(f, 'pg_proc');
    IF v_com LIKE '%md5_functiondef=%' THEN
      v_com := pg_catalog.regexp_replace(v_com, 'md5_functiondef=[0-9A-Za-z_]+',
        'md5_functiondef=' || pg_catalog.md5(pg_catalog.pg_get_functiondef(f)));
      IF pg_catalog.strpos(v_com, 'BE-S1') = 0 THEN
        v_com := v_com || ' BE-S1 (16/11/2026) : lectures du Bureau de l''equipe (details, responsable, filtres sur les reponses et la file).';
      END IF;
      EXECUTE pg_catalog.format('COMMENT ON FUNCTION %s IS %L', f, v_com);
    END IF;
  END LOOP;
END;
$retouches$;

-- ============================================================
-- 3. voisins_candidature
-- ============================================================

-- Meme garde, meme portee, memes filtres, meme tri que lister_candidatures.
-- Rend precedent et suivant (references), rang (a partir de 1) et total. Une
-- reference de l'autre cote : hors_portee, tracee sans donnee ; une reference
-- absente : absente ; une reference lisible mais hors du filtre : hors_liste.
-- Aucun contact, aucun nom : des references seulement.
CREATE FUNCTION public.voisins_candidature(
  p_reference text,
  p_filtre jsonb DEFAULT '{}'::jsonb,
  p_tri text DEFAULT 'activite'
)
RETURNS jsonb
LANGUAGE plpgsql
VOLATILE
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  v_filtre jsonb := coalesce(p_filtre, '{}'::jsonb);
  v_ref text := pg_catalog.upper(pg_catalog.btrim(coalesce(p_reference, '')));
  v_lecteur uuid;
  v_genre public.gender;
  v_super boolean;
  v_fautives text;
  v_cible public.candidatures;
  v_type text;
  v_etape text;
  v_etat text;
  v_issue text;
  v_pause boolean;
  v_paiement text;
  v_pays text;
  v_comp_domaine text;
  v_comp_codes text[];
  v_comp_niveau text;
  v_comp_dispo text;
  v_comp_accord boolean;
  v_comp boolean;
  v_recherche text;
  v_recherche_nom text;
  v_res jsonb;
BEGIN
  IF NOT coalesce(public.app_role() = 'admin' AND public.app_account_valid(), false) THEN
    RAISE EXCEPTION 'candidatures reservees a la direction active' USING ERRCODE = '42501';
  END IF;
  SELECT l.profile_id, l.genre, l.super_admin INTO v_lecteur, v_genre, v_super
  FROM private.cand_lecteur() l;
  IF v_lecteur IS NULL OR NOT (v_super OR v_genre IS NOT NULL) THEN
    RAISE EXCEPTION 'genre du lecteur inconnu : aucune candidature lisible tant qu''il n''est pas renseigne'
      USING ERRCODE = '42501';
  END IF;
  IF v_ref = '' THEN
    RAISE EXCEPTION 'candidature attendue' USING ERRCODE = '22023';
  END IF;

  -- Le filtre : les memes regles que lister_candidatures.
  IF pg_catalog.jsonb_typeof(v_filtre) IS DISTINCT FROM 'object' THEN
    RAISE EXCEPTION 'filtre de candidatures invalide : objet attendu' USING ERRCODE = '22023';
  END IF;
  SELECT pg_catalog.string_agg(k.cle, ', ' ORDER BY k.cle) INTO v_fautives
  FROM pg_catalog.jsonb_object_keys(v_filtre) AS k(cle)
  WHERE k.cle <> ALL (ARRAY['type', 'etape', 'etat', 'issue', 'enPause', 'paiement',
                            'paysResidence', 'recherche', 'competenceDomaine', 'genre',
                            'competenceNiveauMin', 'competenceDisponibilite', 'competenceAccord',
                            'ijaza', 'langueExplication', 'riwaya', 'public', 'jours',
                            'heureMin', 'heureMax', 'joursMin', 'pieceEnAttente', 'responsable']);
  IF v_fautives IS NOT NULL THEN
    RAISE EXCEPTION 'filtre de candidatures inconnu : %', v_fautives USING ERRCODE = '22023';
  END IF;
  SELECT pg_catalog.string_agg(e.key, ', ' ORDER BY e.key) INTO v_fautives
  FROM pg_catalog.jsonb_each(v_filtre) e
  WHERE pg_catalog.jsonb_typeof(e.value) <> 'null'
    AND pg_catalog.jsonb_typeof(e.value)
        <> CASE WHEN e.key IN ('enPause', 'competenceAccord', 'pieceEnAttente') THEN 'boolean'
                WHEN e.key IN ('heureMin', 'heureMax', 'joursMin') THEN 'number'
                WHEN e.key = 'jours' THEN 'array' ELSE 'string' END;
  IF v_fautives IS NOT NULL THEN
    RAISE EXCEPTION 'filtre de candidatures mal type : %', v_fautives USING ERRCODE = '22023';
  END IF;
  PERFORM private.be_filtre_valider(v_filtre);

  v_type := v_filtre ->> 'type';
  v_etape := v_filtre ->> 'etape';
  v_etat := v_filtre ->> 'etat';
  v_issue := v_filtre ->> 'issue';
  v_pause := (v_filtre ->> 'enPause')::boolean;
  v_paiement := v_filtre ->> 'paiement';
  v_pays := v_filtre ->> 'paysResidence';
  IF v_filtre ->> 'genre' IS NOT NULL AND v_filtre ->> 'genre' NOT IN ('male', 'female') THEN
    RAISE EXCEPTION 'filtre de candidatures mal type : genre' USING ERRCODE = '22023';
  END IF;
  v_comp_domaine := v_filtre ->> 'competenceDomaine';
  v_comp_niveau := v_filtre ->> 'competenceNiveauMin';
  v_comp_dispo := v_filtre ->> 'competenceDisponibilite';
  v_comp_accord := (v_filtre ->> 'competenceAccord')::boolean;
  v_comp := coalesce(v_comp_domaine, v_comp_niveau, v_comp_dispo) IS NOT NULL OR v_comp_accord IS NOT NULL;
  v_recherche := nullif(pg_catalog.btrim(v_filtre ->> 'recherche'), '');

  IF (v_type IS NOT NULL AND NOT EXISTS (
        SELECT 1 FROM public.candidature_types t WHERE t.code = v_type))
     OR (v_etape IS NOT NULL AND v_etape NOT IN
        ('recue', 'invitee', 'prequalification', 'verifications', 'confirmee'))
     OR (v_etat IS NOT NULL AND v_etat NOT IN ('a_completer', 'en_examen', 'paiement_non_disponible',
        'entretien_a_planifier', 'entretien_planifie', 'decision_en_attente'))
     OR (v_issue IS NOT NULL AND v_issue NOT IN ('en_cours', 'refusee', 'retiree'))
     OR (v_paiement IS NOT NULL AND v_paiement NOT IN
        ('inconnu', 'compatible', 'incompatible', 'a_verifier'))
     OR (v_pays IS NOT NULL AND v_pays !~ '^[A-Z]{2}$')
     OR (v_comp_domaine IS NOT NULL AND NOT (
           v_comp_domaine = ANY (private.competences_codes('familles'))
           OR EXISTS (SELECT 1 FROM public.competences_catalogue k WHERE k.code = v_comp_domaine)))
     OR (v_comp_niveau IS NOT NULL AND v_comp_niveau <> ALL (private.competences_codes('niveaux')))
     OR (v_comp_dispo IS NOT NULL AND v_comp_dispo <> ALL (private.competences_codes('disponibilites')))
     OR pg_catalog.length(v_recherche) > 200 THEN
    RAISE EXCEPTION 'valeur de filtre de candidatures invalide' USING ERRCODE = '22023';
  END IF;
  IF p_tri IS NULL OR p_tri NOT IN ('activite', 'recente', 'nom') THEN
    RAISE EXCEPTION 'tri de candidatures invalide : activite, recente ou nom' USING ERRCODE = '22023';
  END IF;
  v_recherche_nom := nullif(private.cand_normaliser(v_recherche), '');
  IF v_comp_domaine IS NOT NULL THEN
    SELECT coalesce(pg_catalog.array_agg(k.code), ARRAY[]::text[]) INTO v_comp_codes
      FROM public.competences_catalogue k
     WHERE k.code = v_comp_domaine OR k.famille = v_comp_domaine;
  END IF;

  -- La reference demandee, dans la portee de genre du lecteur.
  SELECT c.* INTO v_cible FROM public.candidatures c WHERE c.reference = v_ref;
  IF v_cible.id IS NULL THEN
    RETURN pg_catalog.jsonb_build_object('erreur', 'absente');
  END IF;
  IF NOT (v_super OR v_cible.genre = v_genre) THEN
    RETURN private.cand_hors_portee(v_cible.id, v_lecteur, 'voisins');
  END IF;

  -- Le meme WHERE et le meme tri que lister_candidatures.
  WITH filtrees AS MATERIALIZED (
    SELECT c.reference AS reference,
           pg_catalog.row_number() OVER (ORDER BY
             CASE WHEN p_tri = 'activite' THEN c.derniere_activite END DESC,
             CASE WHEN p_tri = 'recente' THEN c.recue_le END DESC,
             CASE WHEN p_tri = 'nom' THEN coalesce(c.nom_latin, c.nom_complet) END ASC,
             c.id ASC) AS rang
    FROM public.candidatures c
    WHERE (v_super OR c.genre = v_genre)
      AND (CASE WHEN v_type IS NULL THEN c.type_code NOT IN ('famille', 'eleve_adulte') ELSE c.type_code = v_type END)
      AND (v_etape IS NULL OR c.etape = v_etape)
      AND (v_etat IS NULL OR c.etat = v_etat)
      AND (v_issue IS NULL OR c.issue = v_issue)
      AND (v_pause IS NULL OR c.en_pause = v_pause)
      AND (v_paiement IS NULL OR c.paiement = v_paiement)
      AND (v_pays IS NULL OR c.pays_residence = v_pays)
      AND (v_filtre ->> 'genre' IS NULL OR c.genre::text = v_filtre ->> 'genre')
      AND (NOT (v_filtre ?| ARRAY['ijaza', 'langueExplication', 'riwaya', 'public', 'jours',
                                  'heureMin', 'heureMax', 'joursMin', 'pieceEnAttente', 'responsable'])
           OR private.be_predicat(c, v_filtre, v_lecteur))
      AND (NOT v_comp OR EXISTS (
             SELECT 1 FROM public.candidature_autres_competences a
              WHERE a.candidature_id = c.id
                AND (v_comp_accord IS NULL OR a.accord_contact = v_comp_accord)
                AND (v_comp_dispo IS NULL OR a.disponibilite = v_comp_dispo)
                AND ((v_comp_domaine IS NULL AND v_comp_niveau IS NULL) OR EXISTS (
                       SELECT 1 FROM pg_catalog.jsonb_each_text(a.domaines) d
                        WHERE (v_comp_domaine IS NULL OR d.key = ANY (v_comp_codes))
                          AND (v_comp_niveau IS NULL
                               OR private.competences_rang_niveau(d.value)
                                  >= private.competences_rang_niveau(v_comp_niveau))))))
      AND (v_recherche IS NULL
           OR c.reference = pg_catalog.upper(v_recherche)
           OR EXISTS (SELECT 1 FROM public.candidature_contacts k
                      WHERE k.candidature_id = c.id
                        AND k.courriel = pg_catalog.lower(v_recherche))
           OR (v_recherche_nom IS NOT NULL
               AND pg_catalog.strpos(private.cand_normaliser(c.nom_complet), v_recherche_nom) > 0))
  ), voisines AS (
    SELECT f.reference, f.rang,
           pg_catalog.lag(f.reference) OVER (ORDER BY f.rang) AS precedent,
           pg_catalog.lead(f.reference) OVER (ORDER BY f.rang) AS suivant,
           pg_catalog.count(*) OVER () AS total
    FROM filtrees f
  )
  SELECT pg_catalog.jsonb_build_object('precedent', v.precedent, 'suivant', v.suivant,
                                       'rang', v.rang, 'total', v.total)
    INTO v_res
  FROM voisines v
  WHERE v.reference = v_ref;

  IF v_res IS NULL THEN
    RETURN pg_catalog.jsonb_build_object('erreur', 'hors_liste');
  END IF;
  RETURN v_res;
END;
$function$;

-- ============================================================
-- 4. Droits, empreinte F86, controle final
-- ============================================================

ALTER FUNCTION public.voisins_candidature(text, jsonb, text) OWNER TO postgres;
REVOKE ALL ON FUNCTION public.voisins_candidature(text, jsonb, text) FROM PUBLIC, anon, service_role, agent_ro;
GRANT EXECUTE ON FUNCTION public.voisins_candidature(text, jsonb, text) TO authenticated;

DO $f86$
BEGIN
  EXECUTE pg_catalog.format('COMMENT ON FUNCTION public.voisins_candidature(text,jsonb,text) IS %L',
    pg_catalog.format(
      'F86 candidate allowlist: signature=public.voisins_candidature(text,jsonb,text); md5_functiondef=%s; guard_type=ROLE_POSITIVE_ADMIN_GENDER_SCOPE; owner=postgres; search_path=""; reviewer=Claude a relire; date=2026-11-16. BE-S1 : direction active seule, genre inconnu 42501, filtre et tri comme lister_candidatures (22023), portee de genre dans le WHERE ; rend precedent, suivant, rang, total (references seulement) ; absente, hors_portee (tracee sans donnee) ou hors_liste rendus. Must-pass: supabase/tests/scenarios_be_s1.sql.',
      pg_catalog.md5(pg_catalog.pg_get_functiondef('public.voisins_candidature(text,jsonb,text)'::regprocedure))));
END;
$f86$;

DO $postflight$
BEGIN
  IF pg_catalog.strpos(pg_catalog.pg_get_functiondef('public.historique_candidature(uuid,bigint,integer)'::regprocedure),
                       'be_details_lisibles') = 0
     OR pg_catalog.strpos(pg_catalog.pg_get_functiondef('public.lire_candidature(uuid)'::regprocedure),
                          'responsableNom') = 0
     OR pg_catalog.strpos(pg_catalog.pg_get_functiondef('public.lister_candidatures(jsonb,text,integer)'::regprocedure),
                          'be_predicat') = 0 THEN
    RAISE EXCEPTION 'BE-S1 : retouche absente';
  END IF;
  IF pg_catalog.has_function_privilege('anon', 'public.voisins_candidature(text,jsonb,text)', 'EXECUTE')
     OR pg_catalog.has_function_privilege('agent_ro', 'public.voisins_candidature(text,jsonb,text)', 'EXECUTE')
     OR NOT pg_catalog.has_function_privilege('authenticated', 'public.voisins_candidature(text,jsonb,text)', 'EXECUTE')
     OR pg_catalog.has_function_privilege('authenticated', 'private.be_predicat(public.candidatures,jsonb,uuid)', 'EXECUTE') THEN
    RAISE EXCEPTION 'BE-S1 : droits inattendus';
  END IF;
END;
$postflight$;

