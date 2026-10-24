-- CAND-NOM-LATIN (23/10/2026) : le nom de reference des listes est en lettres latines.
--
-- Decision du directeur : docs/current/DECISION-CANDIDATURES-2026-10-21.md, section
-- « Les noms dans une seule ecriture sur les listes (directeur, 23/10/2026) ». Le nom
-- d'origine (nom_complet, souvent en arabe) est garde tel quel et ne change jamais ; le
-- nom latin est une seconde ecriture, confirmee par la personne.
--
-- Choix de conception (le plus petit changement) :
-- * deux colonnes sur candidatures : nom_latin et nom_latin_confirme_le, nulles ensemble
--   ou posees ensemble. Une ligne n'a donc que deux etats ecrits : rien, ou confirme par
--   la personne. L'etat « a confirmer » n'est PAS ecrit, il se deduit (nom d'origine non
--   latin et nom latin absent) : le serveur ne translittere RIEN, ni en silence ni en
--   proposition ; la proposition est calculee par le client et n'est enregistree qu'une
--   fois confirmee ;
-- * private.nom_est_latin(texte) : vrai si le texte porte au moins une lettre latine et
--   aucun signe d'une autre ecriture (chiffres, espaces et ponctuation sont neutres) ; la
--   meme definition sert la contrainte, le calcul de l'etat et le refus d'une saisie non
--   latine ;
-- * ecriture par le titulaire seulement : public.confirmer_nom_latin(texte), sur sa propre
--   candidature (private.candidature_du_titulaire), jamais par la direction (c'est le nom
--   que la personne choisit pour ses attestations) ; lecture par le titulaire :
--   public.lire_nom_latin() ;
-- * lecture de la direction : private.cand_ligne_json (donc lister_candidatures et
--   lire_candidature) gagne deux cles, nomLatin (le nom latin confirme, ou le nom d'origine
--   quand il est deja latin, sinon nul) et nomLatinAConfirmer ;
-- * lister_candidatures redefinie : la recherche trouve par l'une ou l'autre ecriture, le
--   tri « nom » suit le nom latin quand il existe. Tout le reste du corps est repris de
--   20261022000500_cand_autres_competences.sql ;
-- * l'inscription (inscrire_candidat) ne change pas : le client confirme le nom latin par
--   un second appel, une fois la candidature creee. Un echec de ce second appel laisse le
--   nom « a confirmer » et la Salle d'examen le redemande.
--
-- Aucune table nouvelle : la RLS de candidatures, sans policy ni privilege de table pour un
-- client, couvre les colonnes ajoutees.
BEGIN;

ALTER TABLE public.candidatures
  ADD COLUMN nom_latin text NULL,
  ADD COLUMN nom_latin_confirme_le timestamptz NULL;

-- Vrai : au moins une lettre latine (basique, supplement latin-1, etendus A et B,
-- additionnels) et rien d'une autre ecriture. Les chiffres, espaces, signes de ponctuation
-- et accents combinants sont neutres.
CREATE FUNCTION private.nom_est_latin(p_texte text)
RETURNS boolean
LANGUAGE sql
IMMUTABLE
SECURITY INVOKER
SET search_path = ''
AS $function$
  SELECT coalesce(
    p_texte ~ '[A-Za-zÀ-ÖØ-öø-ɏḀ-ỿ]'
    AND p_texte !~ '[^[:space:][:digit:][:punct:]A-Za-zÀ-ÖØ-öø-ɏ̀-ͯḀ-ỿ]',
    false);
$function$;

ALTER TABLE public.candidatures
  ADD CONSTRAINT candidatures_nom_latin_forme CHECK (
    (nom_latin IS NULL) = (nom_latin_confirme_le IS NULL)
    AND (nom_latin IS NULL
         OR (pg_catalog.length(pg_catalog.btrim(nom_latin)) BETWEEN 1 AND 200
             AND nom_latin = pg_catalog.btrim(nom_latin)
             AND private.nom_est_latin(nom_latin))));

COMMENT ON COLUMN public.candidatures.nom_latin IS
  'CAND-NOM-LATIN : le nom en lettres latines, confirme par la personne (jamais calcule par le serveur) ; le nom d''origine reste dans nom_complet.';
COMMENT ON COLUMN public.candidatures.nom_latin_confirme_le IS
  'CAND-NOM-LATIN : l''instant de la confirmation du nom latin par la personne ; nul avec nom_latin.';

REVOKE ALL ON FUNCTION private.nom_est_latin(text) FROM PUBLIC, anon, authenticated, service_role, agent_ro;

-- La forme d'une ligne de liste : corps de 20261021200000_cand_l1_socle_candidatures.sql
-- recopie, avec deux cles de plus (nomLatin, nomLatinAConfirmer). Toujours ni courriel, ni
-- telephone, ni genre.
CREATE OR REPLACE FUNCTION private.cand_ligne_json(c public.candidatures)
RETURNS jsonb
LANGUAGE sql
STABLE
SECURITY INVOKER
SET search_path = ''
AS $function$
  SELECT pg_catalog.jsonb_build_object(
    'id', c.id,
    'reference', c.reference,
    'nomComplet', c.nom_complet,
    'nomLatin', CASE WHEN c.nom_latin IS NOT NULL THEN c.nom_latin
                     WHEN private.nom_est_latin(c.nom_complet) THEN c.nom_complet END,
    'nomLatinAConfirmer', c.nom_latin IS NULL AND NOT private.nom_est_latin(c.nom_complet),
    'type', c.type_code,
    'etape', c.etape,
    'etat', c.etat,
    'issue', c.issue,
    'enPause', c.en_pause,
    'repriseLe', c.reprise_le,
    'restreinte', c.restreinte,
    'indisponible', private.cand_indisponible(c),
    'indisponibleJusquAu', c.indisponible_jusqu_au,
    'paiement', c.paiement,
    'paysResidence', c.pays_residence,
    'responsableId', c.responsable_id,
    'courrielAObtenir', NOT EXISTS (
      SELECT 1 FROM public.candidature_contacts k
      WHERE k.candidature_id = c.id AND k.courriel IS NOT NULL),
    'indicatifAConfirmer', EXISTS (
      SELECT 1 FROM public.candidature_contacts k
      WHERE k.candidature_id = c.id AND k.telephone_brut IS NOT NULL),
    'derniereActivite', private.cand_instant(c.derniere_activite),
    'recueLe', private.cand_instant(c.recue_le));
$function$;

-- Le titulaire lit l'etat de son nom : son nom d'origine (pour proposer une ecriture
-- latine), le nom latin confirme, et ce qui reste a faire. Lecture seule ; sa propre
-- candidature, la plus recente, comme cand_ma_candidature().
CREATE FUNCTION public.lire_nom_latin()
RETURNS jsonb
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  v_id uuid := private.candidature_du_titulaire(false);
  v_c public.candidatures;
BEGIN
  IF NOT coalesce(auth.uid() IS NOT NULL AND v_id IS NOT NULL, false) THEN
    RAISE EXCEPTION 'nom latin reserve au titulaire d''une candidature' USING ERRCODE = '42501';
  END IF;
  SELECT c.* INTO v_c FROM public.candidatures c WHERE c.id = v_id;
  RETURN pg_catalog.jsonb_build_object(
    'nomComplet', v_c.nom_complet,
    'nomLatin', v_c.nom_latin,
    'dejaLatin', private.nom_est_latin(v_c.nom_complet),
    'aConfirmer', v_c.nom_latin IS NULL AND NOT private.nom_est_latin(v_c.nom_complet));
END;
$function$;

-- Le titulaire confirme son nom en lettres latines. Le nom saisi est celui de la personne :
-- le serveur ne le change que par ses blancs (de tete, de queue et repetes). Un texte vide
-- ou de plus de 200 signes : 22023. Un texte sans lettre latine ou portant une autre
-- ecriture : refus rendu nom_non_latin, sans ecriture. Une confirmation identique ne change
-- rien. Ni version ni activite de la candidature ne bougent (une confirmation n'invalide pas
-- un envoi en cours) ; l'audit ne porte pas le nom.
CREATE FUNCTION public.confirmer_nom_latin(p_nom_latin text)
RETURNS jsonb
LANGUAGE plpgsql
VOLATILE
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  v_id uuid := private.candidature_du_titulaire(false);
  v_c public.candidatures;
  v_nom text;
BEGIN
  IF NOT coalesce(auth.uid() IS NOT NULL AND v_id IS NOT NULL, false) THEN
    RAISE EXCEPTION 'nom latin reserve au titulaire d''une candidature' USING ERRCODE = '42501';
  END IF;
  IF p_nom_latin IS NULL OR pg_catalog.length(p_nom_latin) > 400 THEN
    RAISE EXCEPTION 'nom latin invalide : un texte de 1 a 200 signes' USING ERRCODE = '22023';
  END IF;
  v_nom := pg_catalog.btrim(pg_catalog.regexp_replace(p_nom_latin, '[[:space:]]+', ' ', 'g'));
  IF pg_catalog.length(v_nom) NOT BETWEEN 1 AND 200 THEN
    RAISE EXCEPTION 'nom latin invalide : un texte de 1 a 200 signes' USING ERRCODE = '22023';
  END IF;
  IF NOT private.nom_est_latin(v_nom) THEN
    RETURN pg_catalog.jsonb_build_object('erreur', 'nom_non_latin');
  END IF;

  SELECT c.* INTO v_c FROM public.candidatures c WHERE c.id = v_id FOR UPDATE;
  IF v_c.id IS NULL THEN
    RAISE EXCEPTION 'nom latin reserve au titulaire d''une candidature' USING ERRCODE = '42501';
  END IF;
  IF v_c.nom_latin IS DISTINCT FROM v_nom THEN
    UPDATE public.candidatures c
       SET nom_latin = v_nom, nom_latin_confirme_le = pg_catalog.clock_timestamp()
     WHERE c.id = v_c.id;
    PERFORM public.log_sensitive_access('candidature_nom_latin_confirme', 'candidatures', v_c.id::text,
      pg_catalog.jsonb_build_object('remplace', v_c.nom_latin IS NOT NULL));
  END IF;
  RETURN pg_catalog.jsonb_build_object('nomLatin', v_nom, 'aConfirmer', false);
END;
$function$;

-- lister_candidatures : corps de 20261022000500_cand_autres_competences.sql recopie (garde,
-- portee dans le WHERE, filtres, competences, tri, pages, compteurs, audit) ; deux
-- changements : la recherche cherche aussi dans le nom latin, et le tri « nom » suit le nom
-- latin quand il existe.
CREATE OR REPLACE FUNCTION public.lister_candidatures(
  p_filtre jsonb DEFAULT '{}'::jsonb,
  p_tri text DEFAULT 'activite',
  p_page integer DEFAULT 1
)
RETURNS jsonb
LANGUAGE plpgsql
VOLATILE
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  v_filtre jsonb := coalesce(p_filtre, '{}'::jsonb);
  v_lecteur uuid;
  v_genre public.gender;
  v_super boolean;
  v_fautives text;
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
  v_offset bigint;
  v_total integer;
  v_hors_genre integer;
  v_lignes jsonb;
  v_etapes jsonb;
  v_alertes jsonb;
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

  -- Le filtre : un objet, des cles connues, des valeurs du bon type.
  IF pg_catalog.jsonb_typeof(v_filtre) IS DISTINCT FROM 'object' THEN
    RAISE EXCEPTION 'filtre de candidatures invalide : objet attendu' USING ERRCODE = '22023';
  END IF;
  SELECT pg_catalog.string_agg(k.cle, ', ' ORDER BY k.cle) INTO v_fautives
  FROM pg_catalog.jsonb_object_keys(v_filtre) AS k(cle)
  WHERE k.cle <> ALL (ARRAY['type', 'etape', 'etat', 'issue', 'enPause', 'paiement',
                            'paysResidence', 'recherche', 'competenceDomaine',
                            'competenceNiveauMin', 'competenceDisponibilite', 'competenceAccord']);
  IF v_fautives IS NOT NULL THEN
    RAISE EXCEPTION 'filtre de candidatures inconnu : %', v_fautives USING ERRCODE = '22023';
  END IF;
  SELECT pg_catalog.string_agg(e.key, ', ' ORDER BY e.key) INTO v_fautives
  FROM pg_catalog.jsonb_each(v_filtre) e
  WHERE pg_catalog.jsonb_typeof(e.value) <> 'null'
    AND pg_catalog.jsonb_typeof(e.value)
        <> CASE WHEN e.key IN ('enPause', 'competenceAccord') THEN 'boolean' ELSE 'string' END;
  IF v_fautives IS NOT NULL THEN
    RAISE EXCEPTION 'filtre de candidatures mal type : %', v_fautives USING ERRCODE = '22023';
  END IF;

  v_type := v_filtre ->> 'type';
  v_etape := v_filtre ->> 'etape';
  v_etat := v_filtre ->> 'etat';
  v_issue := v_filtre ->> 'issue';
  v_pause := (v_filtre ->> 'enPause')::boolean;
  v_paiement := v_filtre ->> 'paiement';
  v_pays := v_filtre ->> 'paysResidence';
  v_comp_domaine := v_filtre ->> 'competenceDomaine';
  v_comp_niveau := v_filtre ->> 'competenceNiveauMin';
  v_comp_dispo := v_filtre ->> 'competenceDisponibilite';
  v_comp_accord := (v_filtre ->> 'competenceAccord')::boolean;
  v_comp := coalesce(v_comp_domaine, v_comp_niveau, v_comp_dispo) IS NOT NULL OR v_comp_accord IS NOT NULL;
  v_recherche := nullif(pg_catalog.btrim(v_filtre ->> 'recherche'), '');

  -- CAND-L2A2 (D15) : l'etat paiement_non_disponible de L6 se filtre.
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
  IF p_page IS NULL OR p_page < 1 THEN
    RAISE EXCEPTION 'page de candidatures invalide : 1 ou plus' USING ERRCODE = '22023';
  END IF;
  v_offset := (p_page::bigint - 1) * 50;
  -- Une recherche faite seulement de signes ne rapproche aucun nom (C3).
  v_recherche_nom := nullif(private.cand_normaliser(v_recherche), '');
  -- Un code du catalogue ou une famille : les codes cherches, actifs ou non
  -- (une reponse ancienne reste cherchable, C12).
  IF v_comp_domaine IS NOT NULL THEN
    SELECT coalesce(pg_catalog.array_agg(k.code), ARRAY[]::text[]) INTO v_comp_codes
      FROM public.competences_catalogue k
     WHERE k.code = v_comp_domaine OR k.famille = v_comp_domaine;
  END IF;

  -- La portee (genre ou exception super-admin) et les filtres, dans le WHERE.
  -- Le courriel cherche est le courriel valide seulement, jamais le brut (C9).
  WITH filtrees AS MATERIALIZED (
    SELECT c AS ligne,
           pg_catalog.row_number() OVER (ORDER BY
             CASE WHEN p_tri = 'activite' THEN c.derniere_activite END DESC,
             CASE WHEN p_tri = 'recente' THEN c.recue_le END DESC,
             CASE WHEN p_tri = 'nom' THEN coalesce(c.nom_latin, c.nom_complet) END ASC,
             c.id ASC) AS rang
    FROM public.candidatures c
    WHERE (v_super OR c.genre = v_genre)
      AND (v_type IS NULL OR c.type_code = v_type)
      AND (v_etape IS NULL OR c.etape = v_etape)
      AND (v_etat IS NULL OR c.etat = v_etat)
      AND (v_issue IS NULL OR c.issue = v_issue)
      AND (v_pause IS NULL OR c.en_pause = v_pause)
      AND (v_paiement IS NULL OR c.paiement = v_paiement)
      AND (v_pays IS NULL OR c.pays_residence = v_pays)
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
               AND (pg_catalog.strpos(private.cand_normaliser(c.nom_complet), v_recherche_nom) > 0
                    OR pg_catalog.strpos(private.cand_normaliser(c.nom_latin), v_recherche_nom) > 0)))
  )
  SELECT pg_catalog.count(*)::integer,
         pg_catalog.count(*) FILTER (WHERE f.rang > v_offset AND f.rang <= v_offset + 50
                                       AND (f.ligne).genre IS DISTINCT FROM v_genre)::integer,
         coalesce(pg_catalog.jsonb_agg(private.cand_ligne_json(f.ligne) ORDER BY f.rang)
                    FILTER (WHERE f.rang > v_offset AND f.rang <= v_offset + 50),
                  '[]'::jsonb)
    INTO v_total, v_hors_genre, v_lignes
  FROM filtrees f;

  -- Les compteurs : toute la portee, sans les autres filtres. CAND-L2A2
  -- (D15) : un complement en cours en salle 2 compte dans les informations
  -- manquantes, comme a_completer en salle 1.
  SELECT pg_catalog.jsonb_build_object(
           'recue', pg_catalog.count(*) FILTER (WHERE c.issue = 'en_cours' AND c.etape = 'recue'),
           'invitee', pg_catalog.count(*) FILTER (WHERE c.issue = 'en_cours' AND c.etape = 'invitee'),
           'prequalification', pg_catalog.count(*) FILTER (WHERE c.issue = 'en_cours' AND c.etape = 'prequalification'),
           'verifications', pg_catalog.count(*) FILTER (WHERE c.issue = 'en_cours' AND c.etape = 'verifications'),
           'confirmee', pg_catalog.count(*) FILTER (WHERE c.issue = 'en_cours' AND c.etape = 'confirmee')),
         pg_catalog.jsonb_build_object(
           'informationsManquantes', pg_catalog.count(*) FILTER (
             WHERE c.issue = 'en_cours' AND NOT c.en_pause
               AND (c.etat = 'a_completer'
                    OR CASE WHEN c.etape = 'verifications'
                            THEN pg_catalog.jsonb_array_length(private.candidature_complement_en_cours(c)) > 0
                            ELSE false END)),
           'confirmeesIndisponibles', pg_catalog.count(*) FILTER (
             WHERE c.issue = 'en_cours' AND NOT c.en_pause AND c.etape = 'confirmee'
               AND private.cand_indisponible(c)),
           'entretiensEnRetard', NULL::integer,
           'bloquees', NULL::integer)
    INTO v_etapes, v_alertes
  FROM public.candidatures c
  WHERE (v_super OR c.genre = v_genre);

  PERFORM public.log_sensitive_access('candidatures_liste', 'candidatures', NULL,
    pg_catalog.jsonb_build_object(
      'reader_gender', v_genre,
      'exception_active', v_super,
      'lignes_hors_genre', v_hors_genre,
      'total', v_total,
      'page', p_page,
      'recherche', v_recherche IS NOT NULL,
      'competences', v_comp));

  RETURN pg_catalog.jsonb_build_object(
    'lignes', v_lignes,
    'total', v_total,
    'page', p_page,
    'taillePage', 50,
    'compteursEtapes', v_etapes,
    'compteursAlertes', v_alertes);
END;
$function$;
-- ============================================================
-- Droits, empreintes F86, controle final
-- ============================================================

DO $acl$
DECLARE
  f text;
BEGIN
  FOREACH f IN ARRAY ARRAY[
    'public.lire_nom_latin()',
    'public.confirmer_nom_latin(text)',
    'public.lister_candidatures(jsonb,text,integer)'
  ] LOOP
    EXECUTE pg_catalog.format('ALTER FUNCTION %s OWNER TO postgres', f);
    EXECUTE pg_catalog.format('REVOKE ALL ON FUNCTION %s FROM PUBLIC, anon, service_role, agent_ro', f);
    EXECUTE pg_catalog.format('GRANT EXECUTE ON FUNCTION %s TO authenticated', f);
  END LOOP;
END;
$acl$;

DO $droits$
DECLARE
  v record;
BEGIN
  FOR v IN
    SELECT * FROM (VALUES
      ('public.lire_nom_latin()', 'POSITIVE_CANDIDATE_SELF',
       'Titulaire d une candidature au compte valide (private.candidature_du_titulaire), sinon 42501 ; lecture seule de sa propre ligne : nom d origine, nom latin confirme, dejaLatin, aConfirmer.'),
      ('public.confirmer_nom_latin(text)', 'POSITIVE_CANDIDATE_SELF',
       'Titulaire d une candidature au compte valide, sinon 42501 ; texte vide ou trop long 22023 ; texte non latin refus rendu nom_non_latin sans ecriture ; ligne verrouillee ; une confirmation identique ne change rien ; ni version ni activite de la candidature ; audit sans le nom ; jamais la direction.'),
      ('public.lister_candidatures(jsonb,text,integer)', 'ROLE_POSITIVE_ADMIN_GENDER_SCOPE',
       'Corps de CAND-AUTRES garde (portee par genre dans le WHERE, genre inconnu 42501, filtres 22023, aucune cle courriel, telephone ni genre, audit de chaque liste) ; CAND-NOM-LATIN : la recherche trouve par le nom d origine ou le nom latin, le tri nom suit le nom latin quand il existe.')
    ) AS t(signature, garde, note)
  LOOP
    EXECUTE pg_catalog.format('COMMENT ON FUNCTION %s IS %L', v.signature, pg_catalog.format(
      'F86 candidate allowlist: signature=%s; md5_functiondef=%s; guard_type=%s; owner=postgres; search_path=""; reviewer=Claude a relire; date=2026-10-23. CAND-NOM-LATIN.%s %s Must-pass: supabase/tests/scenarios_cand_nom_latin.sql%s.',
      v.signature,
      pg_catalog.md5(pg_catalog.pg_get_functiondef(v.signature::regprocedure)),
      v.garde,
      CASE WHEN v.signature = 'public.lister_candidatures(jsonb,text,integer)'
           THEN ' Repris de CAND-AUTRES (CAND-L2A2, CAND-L1 avant lui).' ELSE '' END,
      v.note,
      CASE WHEN v.signature = 'public.lister_candidatures(jsonb,text,integer)'
           THEN ', supabase/tests/scenarios_cand_autres_competences.sql, supabase/tests/scenarios_cand_l2a2_gestes_direction.sql, supabase/tests/scenarios_cand_l1_socle.sql'
           ELSE '' END));
  END LOOP;
END;
$droits$;

DO $postflight$
DECLARE
  v record;
  v_role text;
BEGIN
  FOR v IN
    SELECT e.signature, e.volatilite, p.*
    FROM (VALUES
      ('public.lire_nom_latin()', 's'),
      ('public.confirmer_nom_latin(text)', 'v'),
      ('public.lister_candidatures(jsonb,text,integer)', 'v')
    ) AS e(signature, volatilite)
    LEFT JOIN pg_catalog.pg_proc p ON p.oid = pg_catalog.to_regprocedure(e.signature)
  LOOP
    IF v.oid IS NULL
       OR NOT v.prosecdef
       OR pg_catalog.pg_get_userbyid(v.proowner) <> 'postgres'
       OR NOT coalesce(v.proconfig @> ARRAY['search_path=""'], false)
       OR v.provolatile::text <> v.volatilite
       OR coalesce(pg_catalog.obj_description(v.oid, 'pg_proc'), '')
          NOT LIKE '%md5_functiondef=' || pg_catalog.md5(pg_catalog.pg_get_functiondef(v.oid)) || '%'
       OR coalesce(pg_catalog.obj_description(v.oid, 'pg_proc'), '') NOT LIKE '%CAND-NOM-LATIN%'
       OR NOT pg_catalog.has_function_privilege('authenticated', v.oid, 'EXECUTE')
       OR pg_catalog.has_function_privilege('anon', v.oid, 'EXECUTE')
       OR pg_catalog.has_function_privilege('service_role', v.oid, 'EXECUTE')
       OR pg_catalog.has_function_privilege('agent_ro', v.oid, 'EXECUTE')
       OR app_private.has_unsafe_role_guard(v.prosrc) THEN
      RAISE EXCEPTION 'CAND-NOM-LATIN : DEFINER, proprietaire, search_path, volatilite, empreinte, ACL ou garde invalide : %',
        v.signature;
    END IF;
  END LOOP;

  -- La liste garde ses recherches par nom d'origine et par nom latin, et tout son corps.
  IF pg_catalog.strpos((SELECT p.prosrc FROM pg_catalog.pg_proc p
                         WHERE p.oid = 'public.lister_candidatures(jsonb,text,integer)'::regprocedure),
                       'c.nom_latin') = 0
     OR pg_catalog.strpos((SELECT p.prosrc FROM pg_catalog.pg_proc p
                            WHERE p.oid = 'public.lister_candidatures(jsonb,text,integer)'::regprocedure),
                          'competenceNiveauMin') = 0
     OR pg_catalog.strpos((SELECT p.prosrc FROM pg_catalog.pg_proc p
                            WHERE p.oid = 'public.lister_candidatures(jsonb,text,integer)'::regprocedure),
                          'paiement_non_disponible') = 0 THEN
    RAISE EXCEPTION 'CAND-NOM-LATIN : lister_candidatures a perdu son corps ou son ajout';
  END IF;

  -- L'aide interne : appelable par aucun compte ; les neuf aides cand_ restent neuf.
  FOREACH v_role IN ARRAY ARRAY['anon', 'authenticated', 'service_role', 'agent_ro'] LOOP
    IF pg_catalog.has_function_privilege(v_role, 'private.nom_est_latin(text)'::regprocedure, 'EXECUTE') THEN
      RAISE EXCEPTION 'CAND-NOM-LATIN : aide interne executable par %', v_role;
    END IF;
    IF pg_catalog.has_table_privilege(v_role, 'public.candidatures', 'SELECT,INSERT,UPDATE,REFERENCES,TRIGGER') THEN
      RAISE EXCEPTION 'CAND-NOM-LATIN : % garde un privilege sur candidatures', v_role;
    END IF;
  END LOOP;
  IF (SELECT pg_catalog.count(*) FROM pg_catalog.pg_proc p
      WHERE p.pronamespace = 'private'::regnamespace AND p.proname LIKE 'cand\_%') <> 9 THEN
    RAISE EXCEPTION 'CAND-NOM-LATIN : les aides cand_ de CAND-L1 doivent rester neuf';
  END IF;
  IF NOT (SELECT c.relrowsecurity FROM pg_catalog.pg_class c WHERE c.oid = 'public.candidatures'::regclass)
     OR EXISTS (SELECT 1 FROM pg_catalog.pg_policies
                 WHERE schemaname = 'public' AND tablename = 'candidatures') THEN
    RAISE EXCEPTION 'CAND-NOM-LATIN : RLS inactive sur candidatures, ou une policy l''ouvre';
  END IF;
  -- Aucune ligne existante ne viole la contrainte (elle est posee sur des colonnes neuves).
  IF EXISTS (SELECT 1 FROM public.candidatures c WHERE c.nom_latin IS NOT NULL) THEN
    RAISE EXCEPTION 'CAND-NOM-LATIN : un nom latin existe avant tout geste du titulaire';
  END IF;
END;
$postflight$;

COMMIT;
