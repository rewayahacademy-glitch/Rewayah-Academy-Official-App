-- PREVENIR-TOUS (13/11/2026) : « Prevenir » couvre les deux genres pour le
-- super-admin. Prevenir n'est pas lire un dossier : le message part sans
-- qu'aucune donnee de la candidate soit montree (arbitrage de l'architecte).
--
-- Constat en production : le directeur est le seul compte de direction (homme,
-- super-admin) ; les deux fonctions filtraient par `r.genre = v_genre` (genre du
-- lecteur) : 1 219 hommes joignables, 389 femmes jamais.
--
-- Ce qui change, et seulement cela :
--   * public.prevenir_par_courriel(integer) et public.apercu_prevenir_par_courriel() :
--     le filtre devient `(coalesce(v_super, false) OR r.genre = v_genre)`. v_super est la
--     colonne super_admin de private.cand_lecteur() (kyc_super_admin_exception_active(),
--     la meme que l'import ADM-23, 20261120000000). Tout autre compte de direction :
--     son genre seulement, comme avant.
--   * Apercu : ajoute aPrevenirHommes et aPrevenirFemmes (comptes d'adresses, jamais un
--     nom ni une adresse) ; aucune cle retiree ; aPrevenir, desinscrits, dejaPrevenus,
--     dejaInscrits sont comptes sur les deux genres pour le super-admin.
--   * Journal : reader_gender et exception_active gardes ; l'apercu ajoute les deux
--     comptes (via son resultat), l'envoi ajoute mis_en_file_hommes et mis_en_file_femmes.
-- Rien d'autre : meme anti-doublon (cle lien_inscription:<adresse>), memes exclusions,
-- meme verrou, meme plafond (1 a 2000), meme calcul de la langue, memes droits
-- (CREATE OR REPLACE conserve proprietaire et ACL ; postflight par has_function_privilege).
-- Sans BEGIN ni COMMIT de premier niveau, rejouable, collable en un bloc.
-- Mots d'effacement : aucun.

-- ---------------------------------------------------------------------------
-- 0. Preflight : les definitions remplacees sont celles du depot rejoue
-- (20261024010000 puis 20261110300000), installees en production.
-- ---------------------------------------------------------------------------
DO $preflight$
DECLARE
  v record;
BEGIN
  -- Deux empreintes acceptees par fonction : la definition relevee (avant) et celle
  -- que pose cette migration (apres), pour qu'elle reste rejouable.
  FOR v IN
    SELECT e.signature, pg_catalog.md5(p.prosrc) AS lu,
           (pg_catalog.md5(p.prosrc) = ANY (e.attendues)) AS ok
      FROM (VALUES
        ('public.apercu_prevenir_par_courriel()',
         ARRAY['34b4269acf4e9334a05754184af6edcc', '6144f96bb42105d9b9e6529de3403437']),
        ('public.prevenir_par_courriel(integer)',
         ARRAY['6e1536955ed5be06cc4cfff7429dbf91', '49777f4782af31df92de10e31372e276'])
      ) AS e(signature, attendues)
      LEFT JOIN pg_catalog.pg_proc p ON p.oid = pg_catalog.to_regprocedure(e.signature)
  LOOP
    IF v.ok IS NOT TRUE THEN
      RAISE EXCEPTION 'PREVENIR-TOUS : % differe des definitions relevees (md5 %), migration a revoir',
        v.signature, v.lu;
    END IF;
  END LOOP;
END;
$preflight$;

CREATE OR REPLACE FUNCTION public.apercu_prevenir_par_courriel()
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
DECLARE
  v_lecteur uuid;
  v_genre public.gender;
  v_super boolean;
  v_ouverte boolean;
  v_r jsonb;
BEGIN
  IF NOT coalesce(public.app_role() = 'admin' AND public.app_account_valid(), false) THEN
    RAISE EXCEPTION 'personnes a prevenir reservees a la direction active' USING ERRCODE = '42501';
  END IF;
  SELECT l.profile_id, l.genre, l.super_admin INTO v_lecteur, v_genre, v_super FROM private.cand_lecteur() l;
  IF v_lecteur IS NULL OR v_genre IS NULL THEN
    RAISE EXCEPTION 'genre du lecteur inconnu : aucune personne a prevenir tant qu''il n''est pas renseigne'
      USING ERRCODE = '42501';
  END IF;
  v_ouverte := coalesce((SELECT c.value = 'true'::jsonb FROM public.app_config c
                          WHERE c.key = 'candidatures.inscription_publique_ouverte'), false);

  WITH cote AS (
    SELECT r.id, r.courriel, r.recue_le, r.suivi_id, r.genre
      FROM public.formulaires_reponses r
     WHERE (coalesce(v_super, false) OR r.genre = v_genre) AND r.etat = 'active' AND r.candidature_id IS NULL AND r.courriel IS NOT NULL
  ), classees AS (
    SELECT k.*,
           EXISTS (SELECT 1 FROM auth.users u WHERE pg_catalog.lower(u.email) = k.courriel) AS inscrit,
           EXISTS (SELECT 1 FROM public.courriel_desinscriptions d
                    WHERE d.adresse = k.courriel AND d.categorie = 'recrutement') AS desinscrit,
           (EXISTS (SELECT 1 FROM public.candidature_evenements e
                     WHERE e.candidature_id = k.suivi_id AND e.type = 'prevenu')
            OR EXISTS (SELECT 1 FROM public.courriels_sortants s
                        WHERE s.modele = 'lien_inscription' AND s.destinataire_adresse = k.courriel
                          AND (s.statut <> 'annule' OR s.cle_idempotence = 'lien_inscription:' || k.courriel))) AS prevenu
      FROM cote k
  )
  SELECT pg_catalog.jsonb_build_object(
           'aPrevenir', pg_catalog.count(DISTINCT c.courriel)
                          FILTER (WHERE NOT c.inscrit AND NOT c.prevenu AND NOT c.desinscrit),
           'aPrevenirHommes', pg_catalog.count(DISTINCT c.courriel)
                          FILTER (WHERE NOT c.inscrit AND NOT c.prevenu AND NOT c.desinscrit AND c.genre = 'male'),
           'aPrevenirFemmes', pg_catalog.count(DISTINCT c.courriel)
                          FILTER (WHERE NOT c.inscrit AND NOT c.prevenu AND NOT c.desinscrit AND c.genre = 'female'),
           'desinscrits', pg_catalog.count(DISTINCT c.courriel)
                          FILTER (WHERE NOT c.inscrit AND NOT c.prevenu AND c.desinscrit),
           'dejaPrevenus', pg_catalog.count(DISTINCT c.courriel) FILTER (WHERE NOT c.inscrit AND c.prevenu),
           'dejaInscrits', pg_catalog.count(DISTINCT c.courriel) FILTER (WHERE c.inscrit),
           'inscriptionOuverte', v_ouverte)
    INTO v_r
    FROM classees c;

  PERFORM public.log_sensitive_access('prevenir_courriel_apercu', 'candidatures', NULL,
    pg_catalog.jsonb_build_object('reader_gender', v_genre, 'exception_active', v_super) || v_r);
  RETURN v_r;
END;
$function$;

CREATE OR REPLACE FUNCTION public.prevenir_par_courriel(p_limite integer DEFAULT 200)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
DECLARE
  v_uid uuid := auth.uid();
  v_lecteur uuid;
  v_genre public.gender;
  v_super boolean;
  v_r record;
  v_formulaire text;
  v_id uuid;
  v_mis integer := 0;
  v_mis_h integer := 0;
  v_mis_f integer := 0;
  v_restants integer;
BEGIN
  IF NOT coalesce(public.app_role() = 'admin' AND public.app_account_valid(), false) THEN
    RAISE EXCEPTION 'gestes des candidatures reserves a la direction active' USING ERRCODE = '42501';
  END IF;
  SELECT l.profile_id, l.genre, l.super_admin INTO v_lecteur, v_genre, v_super FROM private.cand_lecteur() l;
  IF v_lecteur IS NULL OR v_genre IS NULL THEN
    RAISE EXCEPTION 'genre du lecteur inconnu : aucun envoi tant qu''il n''est pas renseigne'
      USING ERRCODE = '42501';
  END IF;
  -- CANDIDATS-FLUX (06/11/2026) : la file etale l'envoi, la limite par appel
  -- peut couvrir toutes les personnes a prevenir.
  IF p_limite IS NULL OR p_limite < 1 OR p_limite > 2000 THEN
    RAISE EXCEPTION 'limite invalide : de 1 a 2000' USING ERRCODE = '22023';
  END IF;
  IF NOT coalesce((SELECT c.value = 'true'::jsonb FROM public.app_config c
                    WHERE c.key = 'candidatures.inscription_publique_ouverte'), false) THEN
    RETURN pg_catalog.jsonb_build_object('erreur', 'inscription_fermee');
  END IF;

  -- Deux directions qui envoient en meme temps ne previennent pas deux fois
  -- la meme adresse : un seul envoi a la fois.
  PERFORM pg_catalog.pg_advisory_xact_lock(pg_catalog.hashtext('cand_prevenir_par_courriel'));

  FOR v_r IN
    SELECT DISTINCT ON (r.courriel) r.id, r.courriel, r.recue_le, l.classeur, r.nom_affiche, r.genre
      FROM public.formulaires_reponses r
      JOIN public.formulaires_lots l ON l.id = r.lot_id
     WHERE (coalesce(v_super, false) OR r.genre = v_genre) AND r.etat = 'active' AND r.candidature_id IS NULL AND r.courriel IS NOT NULL
       AND NOT EXISTS (SELECT 1 FROM auth.users u WHERE pg_catalog.lower(u.email) = r.courriel)
       AND NOT EXISTS (SELECT 1 FROM public.candidature_evenements e
                        WHERE e.candidature_id = r.suivi_id AND e.type = 'prevenu')
       AND NOT EXISTS (SELECT 1 FROM public.courriels_sortants s
                        WHERE s.modele = 'lien_inscription' AND s.destinataire_adresse = r.courriel
                          AND (s.statut <> 'annule' OR s.cle_idempotence = 'lien_inscription:' || r.courriel))
       AND NOT EXISTS (SELECT 1 FROM public.courriel_desinscriptions d
                        WHERE d.adresse = r.courriel AND d.categorie = 'recrutement')
     ORDER BY r.courriel, r.recue_le ASC, r.id ASC
  LOOP
    EXIT WHEN v_mis >= p_limite;
    v_formulaire := nullif(pg_catalog.btrim(pg_catalog.regexp_replace(
                      v_r.classeur, '\s*\((r[ée]ponses|responses)\)\s*$', '', 'i')), '');
    v_id := public.courriel_enfiler(
      'recrutement',
      'lien_inscription',
      v_r.courriel,
      NULL,
      pg_catalog.jsonb_strip_nulls(pg_catalog.jsonb_build_object(
        'date_reponse', v_r.recue_le,
        'formulaire', v_formulaire,
        -- La langue du candidat : celle du message d'attente deja recu a cette
        -- adresse, sinon l'arabe si son nom ou le formulaire est ecrit en
        -- arabe ; absente, le declencheur courriel_langue met le francais.
        'langue', coalesce(
          (SELECT s.langue FROM public.courriels_sortants s
            WHERE s.destinataire_adresse = v_r.courriel AND s.modele = 'attente_candidat'
              AND s.langue IS NOT NULL
            ORDER BY s.cree_le DESC LIMIT 1),
          CASE WHEN coalesce(v_r.nom_affiche, '') || ' ' || coalesce(v_r.classeur, '')
                    ~ '[؀-ۿ]' THEN 'ar' END))),
      -- Une invitation par adresse, jamais deux (S3).
      'lien_inscription:' || v_r.courriel,
      'manuel',
      v_uid);
    IF v_id IS NOT NULL THEN
      v_mis := v_mis + 1;
      IF v_r.genre = 'male' THEN v_mis_h := v_mis_h + 1; ELSE v_mis_f := v_mis_f + 1; END IF;
    END IF;
  END LOOP;

  SELECT pg_catalog.count(DISTINCT r.courriel)::integer INTO v_restants
    FROM public.formulaires_reponses r
   WHERE (coalesce(v_super, false) OR r.genre = v_genre) AND r.etat = 'active' AND r.candidature_id IS NULL AND r.courriel IS NOT NULL
     AND NOT EXISTS (SELECT 1 FROM auth.users u WHERE pg_catalog.lower(u.email) = r.courriel)
     AND NOT EXISTS (SELECT 1 FROM public.candidature_evenements e
                      WHERE e.candidature_id = r.suivi_id AND e.type = 'prevenu')
     AND NOT EXISTS (SELECT 1 FROM public.courriels_sortants s
                      WHERE s.modele = 'lien_inscription' AND s.destinataire_adresse = r.courriel
                        AND (s.statut <> 'annule' OR s.cle_idempotence = 'lien_inscription:' || r.courriel))
     AND NOT EXISTS (SELECT 1 FROM public.courriel_desinscriptions d
                      WHERE d.adresse = r.courriel AND d.categorie = 'recrutement');

  PERFORM public.log_sensitive_access('prevenir_courriel_envoi', 'candidatures', NULL,
    pg_catalog.jsonb_build_object(
      'reader_gender', v_genre,
      'exception_active', v_super,
      'mis_en_file', v_mis,
      'mis_en_file_hommes', v_mis_h,
      'mis_en_file_femmes', v_mis_f,
      'restants', v_restants,
      'limite', p_limite));
  RETURN pg_catalog.jsonb_build_object('misEnFile', v_mis, 'restants', v_restants);
END;
$function$;


-- ---------------------------------------------------------------------------
-- Empreintes F86 rafraichies, puis controle final.
-- ---------------------------------------------------------------------------
DO $droits$
DECLARE
  v record;
BEGIN
  FOR v IN
    SELECT * FROM (VALUES
      ('public.apercu_prevenir_par_courriel()',
       'Direction active, genre connu, sinon 42501 ; son cote, ou les deux cotes pour le super-admin (prevenir n est pas lire un dossier) ; compteurs par adresse dont aPrevenirHommes et aPrevenirFemmes ; aucune adresse rendue ; audit des compteurs.'),
      ('public.prevenir_par_courriel(integer)',
       'Direction active, genre connu, sinon 42501 ; limite 1 a 2000 sinon 22023 ; inscription fermee : refus rendu sans ecriture ; verrou consultatif ; son cote, ou les deux cotes pour le super-admin ; une adresse une fois (compte existant, WhatsApp consigne, lien_inscription deja en file, desinscrit : exclus) ; courriel_enfiler recrutement/lien_inscription, cle lien_inscription:<adresse>, origine manuel ; donnees date, formulaire, langue ; audit des compteurs dont par genre.')
    ) AS t(signature, note)
  LOOP
    EXECUTE pg_catalog.format('COMMENT ON FUNCTION %s IS %L', v.signature, pg_catalog.format(
      'F86 candidate allowlist: signature=%s; md5_functiondef=%s; guard_type=ROLE_POSITIVE_ADMIN_GENDER_SCOPE; owner=postgres; search_path=""; reviewer=Claude a relire; date=2026-11-13. CAND-PREVENIR, PREVENIR-TOUS. %s Must-pass: supabase/tests/scenarios_cand_prevenir_courriel.sql, supabase/tests/scenarios_prevenir_tous_genres.sql.',
      v.signature,
      pg_catalog.md5(pg_catalog.pg_get_functiondef(v.signature::regprocedure)),
      v.note));
  END LOOP;
END;
$droits$;

DO $postflight$
DECLARE
  v record;
BEGIN
  FOR v IN
    SELECT e.signature, p.*
      FROM (VALUES
        ('public.apercu_prevenir_par_courriel()'),
        ('public.prevenir_par_courriel(integer)')
      ) AS e(signature)
      LEFT JOIN pg_catalog.pg_proc p ON p.oid = pg_catalog.to_regprocedure(e.signature)
  LOOP
    IF v.oid IS NULL
       OR NOT v.prosecdef
       OR pg_catalog.pg_get_userbyid(v.proowner) <> 'postgres'
       OR NOT coalesce(v.proconfig @> ARRAY['search_path=""'], false)
       OR v.provolatile::text <> 'v'
       OR coalesce(pg_catalog.obj_description(v.oid, 'pg_proc'), '')
          NOT LIKE '%md5_functiondef=' || pg_catalog.md5(pg_catalog.pg_get_functiondef(v.oid)) || '%'
       OR NOT pg_catalog.has_function_privilege('authenticated', v.oid, 'EXECUTE')
       OR pg_catalog.has_function_privilege('anon', v.oid, 'EXECUTE')
       OR pg_catalog.has_function_privilege('service_role', v.oid, 'EXECUTE')
       OR pg_catalog.has_function_privilege('agent_ro', v.oid, 'EXECUTE')
       OR pg_catalog.has_function_privilege('public', v.oid, 'EXECUTE')
       OR app_private.has_unsafe_role_guard(v.prosrc) THEN
      RAISE EXCEPTION 'PREVENIR-TOUS : DEFINER, proprietaire, search_path, volatilite, empreinte ou ACL invalide : %',
        v.signature;
    END IF;
  END LOOP;
END;
$postflight$;
