-- PERSONNES-LECTURES (lot PERSONNES-PERF, besoins de la page unique « Personnes » du bureau de la direction, phase 1 de
-- l'agent des ecrans, 20-21/11/2026). Trois NOUVELLES lectures, a cote des anciennes : aucune forme existante ne change,
-- aucune fonction en place n'est remplacee. Installable seule (sans 20261130968000 ni 20261130968500).
--
--   1. public.comptes_admin_page(p_vue, p_recherche, p_filtre, p_tri, p_apres, p_limite, p_mince) : une page des comptes
--      d'une vue (eleves, familles, enseignants, direction), avec recherche, filtres, tri et curseur. Les lignes sont
--      CELLES de public.comptes_admin_par_role() (meme garde, meme portee, memes colonnes, memes valeurs : la fonction est
--      appelee telle quelle), rangees par vue comme l'ecran Comptes les range (liste_comptes.dart, VueComptes.de : un
--      apprenant guardian est aussi dans Eleves). p_mince = true rend des lignes minces (identifiant, matricule, prenom,
--      nom, role, etat du compte, etat de la piece, inscription, admission a traiter, apprenant) pour la liste + apercu.
--      Le serveur calcule toujours les ~700 comptes a chaque page (le cout de comptes_admin_par_role) ; ce qui baisse,
--      c'est ce qui voyage (une page au lieu de 440 Ko sur la base fictive).
--   2. public.voisins_enseignant(p_reference, p_filtre, p_tri) : le precedent et le suivant d'un enseignant dans la liste
--      de lister_enseignants, avec les MEMES filtres et le MEME tri (recopies a l'identique de son corps installe,
--      empreinte controlee), comme voisins_candidature le fait pour lister_candidatures. Rend
--      {precedent, suivant, rang, total} (references CAND-...), ou {erreur: absente | hors_liste}.
--   3. public.dossiers_en_attente_references() : les lignes de dossiers_en_attente(), telles quelles, plus la candidature
--      enseignante du compte (candidature_id, candidature_reference CAND-...) quand il en a une. dossiers_en_attente
--      n'est pas touchee (sa forme ne pourrait changer qu'en la recreant) ; l'ecran lit l'une OU l'autre (une seule ligne
--      de journal d'acces par lecture, celle de dossiers_en_attente).
-- Droits : EXECUTE a authenticated seulement (ni PUBLIC ni anon) ; SECURITY DEFINER, search_path vide ; chaque fonction
-- refuse (42501) qui n'est pas la direction active. MOTS D'EFFACEMENT : zero. Aucune donnee n'est ecrite.

DO $preflight$
DECLARE
  v record;
BEGIN
  FOR v IN SELECT * FROM (VALUES
      ('public.comptes_admin_par_role()'),
      ('public.lister_enseignants(jsonb,text,integer)'),
      ('public.dossiers_en_attente()'),
      ('private.cand_lecteur()'),
      ('private.lp_phase(public.candidatures)'),
      ('private.be_filtre_valider(jsonb)'),
      ('private.be_predicat(public.candidatures,jsonb,uuid)'),
      ('private.cand_normaliser(text)')) AS t(f) LOOP
    IF pg_catalog.to_regprocedure(v.f) IS NULL THEN
      RAISE EXCEPTION 'PERSONNES-LECTURES : % absente ; rien n''est modifie', v.f;
    END IF;
  END LOOP;
  -- Les filtres et le tri de voisins_enseignant sont recopies de ce corps-la.
  IF (SELECT pg_catalog.md5(p.prosrc) FROM pg_catalog.pg_proc p
       WHERE p.oid = pg_catalog.to_regprocedure('public.lister_enseignants(jsonb,text,integer)'))
     IS DISTINCT FROM '2e3ea409250919853641aabdbd915290' THEN
    RAISE EXCEPTION 'PERSONNES-LECTURES : lister_enseignants n''est pas celle attendue ; rien n''est modifie';
  END IF;
  IF pg_catalog.to_regprocedure('public.comptes_admin_page(text,text,jsonb,text,integer,integer,boolean)') IS NOT NULL
     OR pg_catalog.to_regprocedure('public.voisins_enseignant(text,jsonb,text)') IS NOT NULL
     OR pg_catalog.to_regprocedure('public.dossiers_en_attente_references()') IS NOT NULL THEN
    RAISE EXCEPTION 'PERSONNES-LECTURES : deja installe ; rien n''est modifie';
  END IF;
END
$preflight$;

-- 1. Une page des comptes d'une vue.
CREATE FUNCTION public.comptes_admin_page(
  p_vue text,
  p_recherche text DEFAULT NULL,
  p_filtre jsonb DEFAULT '{}'::jsonb,
  p_tri text DEFAULT 'defaut',
  p_apres integer DEFAULT 0,
  p_limite integer DEFAULT 50,
  p_mince boolean DEFAULT false)
 RETURNS jsonb
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO ''
AS $function$
DECLARE
  -- Les parametres ne sont lus qu'apres la garde et les controles (relecture du 21/11).
  v_filtre jsonb;
  v_fautives text;
  v_recherche text;
  v_etat_compte text;
  v_etat_piece text;
  v_admission boolean;
  v_echus boolean;
  v_resultat jsonb;
BEGIN
  IF NOT coalesce(public.app_role() = 'admin' AND public.app_account_valid(), false) THEN
    RAISE EXCEPTION 'comptes reserves a la direction active' USING ERRCODE = '42501';
  END IF;
  IF p_vue IS NULL OR p_vue NOT IN ('eleves', 'familles', 'enseignants', 'direction') THEN
    RAISE EXCEPTION 'vue de comptes invalide : eleves, familles, enseignants ou direction' USING ERRCODE = '22023';
  END IF;
  IF p_tri IS NULL OR p_tri NOT IN ('defaut', 'nom', 'nom_desc', 'recent', 'ancien') THEN
    RAISE EXCEPTION 'tri de comptes invalide : defaut, nom, nom_desc, recent ou ancien' USING ERRCODE = '22023';
  END IF;
  IF p_apres IS NULL OR p_apres < 0 OR p_apres > 100000 OR p_limite IS NULL OR p_limite < 1 OR p_limite > 200 THEN
    RAISE EXCEPTION 'page de comptes invalide : apres de 0 a 100000, limite de 1 a 200' USING ERRCODE = '22023';
  END IF;
  IF pg_catalog.length(p_recherche) > 200 THEN
    RAISE EXCEPTION 'recherche de comptes trop longue' USING ERRCODE = '22023';
  END IF;
  v_filtre := coalesce(p_filtre, '{}'::jsonb);
  IF pg_catalog.jsonb_typeof(v_filtre) IS DISTINCT FROM 'object' THEN
    RAISE EXCEPTION 'filtre de comptes invalide : objet attendu' USING ERRCODE = '22023';
  END IF;
  SELECT pg_catalog.string_agg(e.key, ', ' ORDER BY e.key) INTO v_fautives
    FROM pg_catalog.jsonb_each(v_filtre) e
   WHERE e.key <> ALL (ARRAY['etatCompte', 'etatPiece', 'admissionATraiter', 'echus'])
      OR (pg_catalog.jsonb_typeof(e.value) <> 'null'
          AND pg_catalog.jsonb_typeof(e.value)
              <> CASE WHEN e.key IN ('admissionATraiter', 'echus') THEN 'boolean' ELSE 'string' END);
  IF v_fautives IS NOT NULL THEN
    RAISE EXCEPTION 'filtre de comptes inconnu ou mal type : %', v_fautives USING ERRCODE = '22023';
  END IF;
  v_etat_compte := v_filtre ->> 'etatCompte';
  v_etat_piece := v_filtre ->> 'etatPiece';
  v_admission := (v_filtre ->> 'admissionATraiter')::boolean;
  v_echus := (v_filtre ->> 'echus')::boolean;
  v_recherche := nullif(private.cand_normaliser(p_recherche), '');
  IF (v_etat_compte IS NOT NULL AND v_etat_compte NOT IN ('pending_kyc', 'provisional_active', 'active', 'disabled'))
     OR (v_etat_piece IS NOT NULL AND v_etat_piece NOT IN ('a_verifier', 'validee', 'refusee', 'aucune')) THEN
    RAISE EXCEPTION 'valeur de filtre de comptes invalide' USING ERRCODE = '22023';
  END IF;

  WITH base AS MATERIALIZED (
    SELECT x AS ligne, x.role::text AS role, x.est_apprenant
      FROM public.comptes_admin_par_role() AS o
      CROSS JOIN LATERAL (SELECT o.profile_id, o.immutable_id, o.prenom, o.nom, o.role, o.etat_compte, o.inscrit_le,
             o.acces_jusqu_au, o.foyer_id, o.etat_piece, o.contrats, o.a_enseignant, o.enfants_du_foyer,
             o.teacher_country, o.tranche_age, o.classe_id, o.classe_libelle, o.classe_numero, o.classes_actives,
             o.tuteur_id, o.tuteur_prenom, o.tuteur_nom, o.admission_a_traiter, o.est_apprenant) AS x
  ), vues AS (
    -- Le rangement de VueComptes.de (liste_comptes.dart).
    SELECT b.*,
           (b.role = 'student' OR b.est_apprenant) AS eleves,
           b.role = 'guardian' AS familles,
           b.role = 'teacher' AS enseignants,
           b.role IN ('admin', 'accountant', 'associe', 'controller') AS direction
      FROM base b
  ), choisies AS MATERIALIZED (
    SELECT v.ligne,
           pg_catalog.row_number() OVER (ORDER BY
             -- 'defaut' : l'ordre de comptes_admin_par_role, cles explicites (en attente, provisoire, autres ;
             -- inscription la plus ancienne d'abord). Toujours departage par profile_id en dernier : deux
             -- inscriptions a la meme seconde gardent leur ordre d'une page a l'autre.
             CASE WHEN p_tri = 'defaut' THEN CASE (v.ligne).etat_compte::text WHEN 'pending_kyc' THEN 0
                                                  WHEN 'provisional_active' THEN 1 ELSE 2 END END ASC,
             CASE WHEN p_tri = 'defaut' THEN (v.ligne).inscrit_le END ASC,
             CASE WHEN p_tri = 'nom' THEN pg_catalog.lower(coalesce((v.ligne).prenom, '') || ' ' || coalesce((v.ligne).nom, '')) END ASC,
             CASE WHEN p_tri = 'nom_desc' THEN pg_catalog.lower(coalesce((v.ligne).prenom, '') || ' ' || coalesce((v.ligne).nom, '')) END DESC,
             CASE WHEN p_tri = 'recent' THEN (v.ligne).inscrit_le END DESC,
             CASE WHEN p_tri = 'ancien' THEN (v.ligne).inscrit_le END ASC,
             (v.ligne).profile_id ASC) AS rang
      FROM vues v
     WHERE CASE p_vue WHEN 'eleves' THEN v.eleves WHEN 'familles' THEN v.familles
                      WHEN 'enseignants' THEN v.enseignants ELSE v.direction END
       AND (v_etat_compte IS NULL OR (v.ligne).etat_compte::text = v_etat_compte)
       AND (v_etat_piece IS NULL OR (v.ligne).etat_piece = v_etat_piece)
       AND (v_admission IS NULL OR (v.ligne).admission_a_traiter = v_admission)
       AND (v_echus IS NULL OR ((v.ligne).acces_jusqu_au IS NOT NULL
                                AND (v.ligne).acces_jusqu_au < pg_catalog.now()) = v_echus)
       AND (v_recherche IS NULL
            OR pg_catalog.strpos(private.cand_normaliser(coalesce((v.ligne).prenom, '') || ' '
                                                         || coalesce((v.ligne).nom, '')), v_recherche) > 0
            OR pg_catalog.upper((v.ligne).immutable_id) = pg_catalog.upper(pg_catalog.btrim(p_recherche)))
  )
  SELECT pg_catalog.jsonb_build_object(
           'lignes', coalesce((
             SELECT pg_catalog.jsonb_agg(
                      CASE WHEN p_mince THEN pg_catalog.jsonb_build_object(
                             'profile_id', (c.ligne).profile_id, 'immutable_id', (c.ligne).immutable_id,
                             'prenom', (c.ligne).prenom, 'nom', (c.ligne).nom, 'role', (c.ligne).role,
                             'etat_compte', (c.ligne).etat_compte, 'etat_piece', (c.ligne).etat_piece,
                             'inscrit_le', (c.ligne).inscrit_le, 'admission_a_traiter', (c.ligne).admission_a_traiter,
                             'est_apprenant', (c.ligne).est_apprenant)
                           ELSE pg_catalog.to_jsonb(c.ligne) END
                      ORDER BY c.rang)
               FROM choisies c
              WHERE c.rang > p_apres AND c.rang <= p_apres::bigint + p_limite), '[]'::jsonb),
           'total', (SELECT pg_catalog.count(*) FROM choisies),
           'suivant', CASE WHEN (SELECT pg_catalog.count(*) FROM choisies) > p_apres::bigint + p_limite
                           THEN p_apres + p_limite END,
           'compteursVues', (SELECT pg_catalog.jsonb_build_object(
                               'eleves', pg_catalog.count(*) FILTER (WHERE v.eleves),
                               'familles', pg_catalog.count(*) FILTER (WHERE v.familles),
                               'enseignants', pg_catalog.count(*) FILTER (WHERE v.enseignants),
                               'direction', pg_catalog.count(*) FILTER (WHERE v.direction))
                               FROM vues v))
    INTO v_resultat;
  RETURN v_resultat;
END;
$function$;

REVOKE ALL ON FUNCTION public.comptes_admin_page(text, text, jsonb, text, integer, integer, boolean) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.comptes_admin_page(text, text, jsonb, text, integer, integer, boolean) TO authenticated;

-- 2. Le precedent et le suivant d'un enseignant, aux filtres et au tri de lister_enseignants (corps 2e3ea409...,
-- recopie a l'identique : garde, controle des filtres, base, filtres, tri ; seule la fin change).
CREATE FUNCTION public.voisins_enseignant(p_reference text, p_filtre jsonb DEFAULT '{}'::jsonb,
                                          p_tri text DEFAULT 'activite'::text)
 RETURNS jsonb
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO ''
AS $function$
DECLARE
  v_filtre jsonb := coalesce(p_filtre, '{}'::jsonb);
  v_lecteur uuid;
  v_genre public.gender;
  v_super boolean;
  v_fautives text;
  v_phase text;
  v_etat text;
  v_issue text;
  v_pays text;
  v_recherche text;
  v_recherche_nom text;
  v_en_pause boolean;
  v_avec_classe boolean;
  v_partis boolean;
  v_sous_filtre jsonb;
  v_ref text := pg_catalog.upper(pg_catalog.btrim(coalesce(p_reference, '')));
  v_cible public.candidatures;
  v_res jsonb;
BEGIN
  IF NOT coalesce(public.app_role() = 'admin' AND public.app_account_valid(), false) THEN
    RAISE EXCEPTION 'enseignants reserves a la direction active' USING ERRCODE = '42501';
  END IF;
  SELECT l.profile_id, l.genre, l.super_admin INTO v_lecteur, v_genre, v_super
  FROM private.cand_lecteur() l;
  IF v_lecteur IS NULL OR NOT (v_super OR v_genre IS NOT NULL) THEN
    RAISE EXCEPTION 'genre du lecteur inconnu : aucun enseignant lisible tant qu''il n''est pas renseigne'
      USING ERRCODE = '42501';
  END IF;

  IF pg_catalog.jsonb_typeof(v_filtre) IS DISTINCT FROM 'object' THEN
    RAISE EXCEPTION 'filtre d''enseignants invalide : objet attendu' USING ERRCODE = '22023';
  END IF;
  SELECT pg_catalog.string_agg(k.cle, ', ' ORDER BY k.cle) INTO v_fautives
  FROM pg_catalog.jsonb_object_keys(v_filtre) AS k(cle)
  WHERE k.cle <> ALL (ARRAY['phase', 'etat', 'issue', 'paysResidence', 'recherche', 'genre', 'enPause',
                            'avecClasse', 'partis', 'responsable', 'nouveau', 'pieceEnAttente']);
  IF v_fautives IS NOT NULL THEN
    RAISE EXCEPTION 'filtre d''enseignants inconnu : %', v_fautives USING ERRCODE = '22023';
  END IF;
  SELECT pg_catalog.string_agg(e.key, ', ' ORDER BY e.key) INTO v_fautives
  FROM pg_catalog.jsonb_each(v_filtre) e
  WHERE pg_catalog.jsonb_typeof(e.value) <> 'null'
    AND pg_catalog.jsonb_typeof(e.value)
        <> CASE WHEN e.key IN ('enPause', 'avecClasse', 'partis', 'nouveau', 'pieceEnAttente')
                THEN 'boolean' ELSE 'string' END;
  IF v_fautives IS NOT NULL THEN
    RAISE EXCEPTION 'filtre d''enseignants mal type : %', v_fautives USING ERRCODE = '22023';
  END IF;
  PERFORM private.be_filtre_valider(v_filtre);
  v_phase := v_filtre ->> 'phase';
  v_etat := v_filtre ->> 'etat';
  v_issue := v_filtre ->> 'issue';
  v_pays := v_filtre ->> 'paysResidence';
  v_en_pause := (v_filtre ->> 'enPause')::boolean;
  v_avec_classe := (v_filtre ->> 'avecClasse')::boolean;
  v_partis := coalesce((v_filtre ->> 'partis')::boolean, false);
  v_recherche := nullif(pg_catalog.btrim(v_filtre ->> 'recherche'), '');
  IF (v_phase IS NOT NULL AND v_phase NOT IN
        ('candidat', 'accueil', 'disponible', 'en_poste', 'absent', 'pause', 'suspendu', 'parti'))
     OR (v_etat IS NOT NULL AND v_etat NOT IN ('a_completer', 'en_examen', 'paiement_non_disponible',
        'entretien_a_planifier', 'entretien_planifie', 'decision_en_attente'))
     OR (v_issue IS NOT NULL AND v_issue NOT IN ('en_cours', 'refusee', 'retiree'))
     OR (v_pays IS NOT NULL AND v_pays !~ '^[A-Z]{2}$')
     OR (v_filtre ->> 'genre' IS NOT NULL AND v_filtre ->> 'genre' NOT IN ('male', 'female'))
     OR pg_catalog.length(v_recherche) > 200 THEN
    RAISE EXCEPTION 'valeur de filtre d''enseignants invalide' USING ERRCODE = '22023';
  END IF;
  IF p_tri IS NULL OR p_tri NOT IN ('activite', 'recente', 'nom') THEN
    RAISE EXCEPTION 'tri d''enseignants invalide : activite, recente ou nom' USING ERRCODE = '22023';
  END IF;
  v_recherche_nom := nullif(private.cand_normaliser(v_recherche), '');
  -- Les filtres que be_predicat sait deja lire.
  SELECT coalesce(pg_catalog.jsonb_object_agg(e.key, e.value), '{}'::jsonb) INTO v_sous_filtre
    FROM pg_catalog.jsonb_each(v_filtre) e
   WHERE e.key IN ('responsable', 'nouveau', 'pieceEnAttente') AND pg_catalog.jsonb_typeof(e.value) <> 'null';

  SELECT c.* INTO v_cible FROM public.candidatures c
   WHERE c.reference = v_ref AND c.type_code = 'enseignant';
  -- Absente ou hors de la portee de genre du lecteur : la meme reponse (rien n'est revele).
  IF v_cible.id IS NULL OR NOT (v_super OR v_cible.genre = v_genre) THEN
    RETURN pg_catalog.jsonb_build_object('erreur', 'absente');
  END IF;

  WITH base AS MATERIALIZED (
    SELECT c AS ligne, private.lp_phase(c) ->> 'phase' AS phase,
           EXISTS (SELECT 1 FROM public.groupes g
                    WHERE g.teacher_id = c.profile_id AND g.ended_at IS NULL) AS a_classe
      FROM public.candidatures c
     WHERE c.type_code = 'enseignant'
       AND (v_super OR c.genre = v_genre)
  ), filtrees AS MATERIALIZED (
    SELECT (b.ligne).reference AS reference,
           pg_catalog.row_number() OVER (ORDER BY
             CASE WHEN p_tri = 'activite' THEN (b.ligne).derniere_activite END DESC,
             CASE WHEN p_tri = 'recente' THEN (b.ligne).recue_le END DESC,
             CASE WHEN p_tri = 'nom' THEN coalesce((b.ligne).nom_latin, (b.ligne).nom_complet) END ASC,
             (b.ligne).id ASC) AS rang
      FROM base b
     WHERE (v_phase IS NULL AND (v_partis OR b.phase <> 'parti') OR b.phase = v_phase)
       AND (v_etat IS NULL OR (b.ligne).etat = v_etat)
       AND (v_issue IS NULL OR (b.ligne).issue = v_issue)
       AND (v_pays IS NULL OR (b.ligne).pays_residence = v_pays)
       AND (v_filtre ->> 'genre' IS NULL OR (b.ligne).genre::text = v_filtre ->> 'genre')
       AND (v_en_pause IS NULL OR (b.ligne).en_pause = v_en_pause)
       AND (v_avec_classe IS NULL OR b.a_classe = v_avec_classe)
       AND (v_sous_filtre = '{}'::jsonb OR private.be_predicat(b.ligne, v_sous_filtre, v_lecteur))
       AND (v_recherche IS NULL
            OR (b.ligne).reference = pg_catalog.upper(v_recherche)
            OR EXISTS (SELECT 1 FROM public.candidature_contacts k
                        WHERE k.candidature_id = (b.ligne).id
                          AND k.courriel = pg_catalog.lower(v_recherche))
            OR (v_recherche_nom IS NOT NULL
                AND (pg_catalog.strpos(private.cand_normaliser((b.ligne).nom_complet), v_recherche_nom) > 0
                     OR pg_catalog.strpos(private.cand_normaliser((b.ligne).nom_latin), v_recherche_nom) > 0)))
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

REVOKE ALL ON FUNCTION public.voisins_enseignant(text, jsonb, text) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.voisins_enseignant(text, jsonb, text) TO authenticated;

-- 3. Les pieces en attente, avec la reference de la candidature enseignante du compte.
CREATE FUNCTION public.dossiers_en_attente_references()
 RETURNS TABLE(profile_id uuid, immutable_id text, first_name text, last_name text, role public.app_role,
               account_status public.account_status, inscrit_le timestamp with time zone, document_id uuid,
               doc_type text, document_gender public.gender, object_key text, depose_le timestamp with time zone,
               etat_piece text, candidature_id uuid, candidature_reference text)
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
#variable_conflict use_column
BEGIN
  -- La garde, la portee et le journal d'acces sont ceux de dossiers_en_attente, appelee telle quelle.
  RETURN QUERY
    SELECT d.profile_id, d.immutable_id, d.first_name, d.last_name, d.role, d.account_status, d.inscrit_le,
           d.document_id, d.doc_type, d.document_gender, d.object_key, d.depose_le, d.etat_piece,
           c.id, c.reference
      FROM public.dossiers_en_attente() WITH ORDINALITY AS d(profile_id, immutable_id, first_name, last_name, role,
             account_status, inscrit_le, document_id, doc_type, document_gender, object_key, depose_le, etat_piece,
             ordre)
      LEFT JOIN public.candidatures c ON c.profile_id = d.profile_id AND c.type_code = 'enseignant'
     ORDER BY d.ordre;
END;
$function$;

REVOKE ALL ON FUNCTION public.dossiers_en_attente_references() FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.dossiers_en_attente_references() TO authenticated;

-- Controle final.
DO $controle$
DECLARE
  v text;
BEGIN
  FOREACH v IN ARRAY ARRAY['public.comptes_admin_page(text,text,jsonb,text,integer,integer,boolean)',
                           'public.voisins_enseignant(text,jsonb,text)',
                           'public.dossiers_en_attente_references()'] LOOP
    IF NOT EXISTS (SELECT 1 FROM pg_catalog.pg_proc p
                    WHERE p.oid = pg_catalog.to_regprocedure(v) AND p.prosecdef
                      AND p.proowner = 'postgres'::regrole AND p.proconfig = ARRAY['search_path=""']) THEN
      RAISE EXCEPTION 'PERSONNES-LECTURES : % : DEFINER, postgres, search_path vide attendus', v;
    END IF;
    -- Ni PUBLIC (une entree « =X/... ») ni anon ; authenticated oui.
    IF has_function_privilege('anon', v, 'EXECUTE')
       OR NOT has_function_privilege('authenticated', v, 'EXECUTE')
       OR EXISTS (SELECT 1 FROM pg_catalog.pg_proc p, pg_catalog.unnest(p.proacl) AS a(e)
                   WHERE p.oid = pg_catalog.to_regprocedure(v) AND a.e::text LIKE '=%') THEN
      RAISE EXCEPTION 'PERSONNES-LECTURES : droits de % inattendus', v;
    END IF;
  END LOOP;
  IF (SELECT pg_catalog.md5(p.prosrc) FROM pg_catalog.pg_proc p
       WHERE p.oid = pg_catalog.to_regprocedure('public.dossiers_en_attente()'))
     IS DISTINCT FROM '709acb93316205f4cb1900982b8d1896' THEN
    RAISE EXCEPTION 'PERSONNES-LECTURES : dossiers_en_attente ne doit pas changer';
  END IF;
END
$controle$;
