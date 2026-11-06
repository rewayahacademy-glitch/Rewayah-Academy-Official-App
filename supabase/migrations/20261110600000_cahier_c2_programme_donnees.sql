-- CAHIER-C2 (rang 22 f, ETUDE-CAHIER-2026-11.md §4.1 et §5) : le programme en
-- donnees.
--
-- Fichier SANS mot d'effacement (B5) : aucun des trois mots interdits n'y
-- figure en instruction. Migration additive (B6) : trois colonnes neuves sur
-- `programme_niveaux`, cinq fonctions neuves, une fonction existante
-- remplacee a signature identique (`creer_version_programme`, pour que la
-- copie d'une version emporte aussi le contenu neuf). Aucune colonne existante
-- ne change de sens (B1 sans objet).
--
-- Ce que fait le lot :
--   1. Chaque etape (`programme_niveaux`) porte ses objectifs observables (3 a
--      5), sa plage de support (support, page et ligne de debut et de fin,
--      facultatives tant que le livre de lecture Rewayah n'est pas numerote :
--      reponse du directeur du 05/11, registre 08) et, par tranche d'age
--      (`cohortes_age`), sa duree prevue et sa date limite en semaines.
--   2. La direction remplit ce contenu dans un brouillon
--      (`modifier_contenu_niveau`), ou d'un geste avec la proposition des
--      bases (`preremplir_bases_programme`) qu'elle relit avant publication.
--   3. La publication exige un contenu complet : 3 a 5 objectifs et une duree
--      pour chaque tranche d'age, sur chaque etape (`publier_version_programme`
--      reste celle de 0020 ; le controle est pose par un declencheur sur le
--      passage au statut publiee, `programme_c2_publication_complete`).
--   4. Lecture du contenu : la direction (`programme_contenu_admin`) ; et, pour
--      la fiche d'un eleve, l'etape en cours de chaque eleve d'une Classe
--      (`etapes_eleves_classe`), lue par la direction, le titulaire ou
--      l'enseignant effectif d'une seance proche (garde de CAHIER-C1,
--      `private.cahier_c1_peut_lire_classe`).
--
-- Ce que le lot NE fait PAS (dit au pilote) :
--   - il n'ecrit aucune ligne de programme en production : la proposition des
--     bases s'insere seulement quand la direction appuie, dans un brouillon ;
--   - les durees par etape de la proposition sont un DECOUPAGE PROPOSE du
--     total des bases decide le 14/10 (37, 28, 24, 15 semaines) : seul le
--     total est decide, le decoupage attend la relecture du directeur ;
--   - la position de la salle reste le Mushaf seul (C1) : le livre Rewayah
--     n'a pas encore de pages numerotees.
--
-- Lecteurs recenses (B1) : `programme_niveaux_admin` (0020, inchange) ;
-- `unite_curriculum` (0025, inchange) ; les jointures de 0021 a 0054 ne lisent
-- que `id`, `nom_humain`, `cycle`, `ordre`, `code_technique` : inchanges.

BEGIN;

-- ---------------------------------------------------------------------------
-- 1. Le contenu d'une etape
-- ---------------------------------------------------------------------------
ALTER TABLE public.programme_niveaux
  ADD COLUMN objectifs text[] NOT NULL DEFAULT '{}'::text[]
    CHECK (pg_catalog.cardinality(objectifs) <= 5),
  ADD COLUMN plage_support jsonb
    CHECK (plage_support IS NULL OR pg_catalog.jsonb_typeof(plage_support) = 'object'),
  ADD COLUMN durees jsonb NOT NULL DEFAULT '{}'::jsonb
    CHECK (pg_catalog.jsonb_typeof(durees) = 'object');

COMMENT ON COLUMN public.programme_niveaux.objectifs IS
  'CAHIER-C2 : les objectifs observables de l''etape, 3 a 5 a la publication, '
  'dans l''ordre. Ecrits par modifier_contenu_niveau seulement.';
COMMENT ON COLUMN public.programme_niveaux.plage_support IS
  'CAHIER-C2 : {support: livre_rewayah|mushaf, page_debut, ligne_debut, '
  'page_fin, ligne_fin}, pages et lignes facultatives. Nul = non renseignee.';
COMMENT ON COLUMN public.programme_niveaux.durees IS
  'CAHIER-C2 : par code de cohortes_age, {prevue, limite} en semaines '
  '(limite >= prevue). Complet pour chaque cohorte active a la publication.';

-- ---------------------------------------------------------------------------
-- 2. Validation (privee) d'un contenu
-- ---------------------------------------------------------------------------
-- Vrai quand [p_durees] porte une duree valide pour chaque cohorte active, et
-- rien d'autre.
CREATE FUNCTION private.programme_c2_durees_completes(p_durees jsonb)
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $function$
  SELECT coalesce(
    pg_catalog.jsonb_typeof(p_durees) = 'object'
    AND NOT EXISTS (
      SELECT 1 FROM public.cohortes_age c
       WHERE c.actif
         AND NOT (
           pg_catalog.jsonb_typeof(p_durees -> c.code) = 'object'
           AND pg_catalog.jsonb_typeof(p_durees -> c.code -> 'prevue') = 'number'
           AND pg_catalog.jsonb_typeof(p_durees -> c.code -> 'limite') = 'number'
           AND (p_durees -> c.code ->> 'prevue')::numeric BETWEEN 1 AND 260
           AND (p_durees -> c.code ->> 'limite')::numeric
               BETWEEN (p_durees -> c.code ->> 'prevue')::numeric AND 520
         )
    ),
    false
  );
$function$;

-- Le contenu d'une etape est-il publiable ?
CREATE FUNCTION private.programme_c2_niveau_complet(p_niveau public.programme_niveaux)
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $function$
  SELECT coalesce(
    pg_catalog.cardinality(p_niveau.objectifs) BETWEEN 3 AND 5
    AND private.programme_c2_durees_completes(p_niveau.durees),
    false
  );
$function$;

-- ---------------------------------------------------------------------------
-- 3. Le controle de publication : une version ne passe au statut publiee que
--    si chacune de ses etapes est complete. Pose en base, pas a l'ecran.
-- ---------------------------------------------------------------------------
CREATE FUNCTION private.programme_c2_publication_complete()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  v_incomplet text;
BEGIN
  IF NEW.statut = 'publiee' AND OLD.statut IS DISTINCT FROM 'publiee' THEN
    SELECT n.nom_humain INTO v_incomplet
      FROM public.programme_niveaux n
     WHERE n.version_id = NEW.id
       AND NOT private.programme_c2_niveau_complet(n)
     ORDER BY n.ordre
     LIMIT 1;
    IF v_incomplet IS NOT NULL THEN
      RAISE EXCEPTION 'programme_incomplet: %', v_incomplet
        USING errcode = 'P0001',
              hint = 'Chaque etape demande 3 a 5 objectifs et une duree pour chaque tranche d''age.';
    END IF;
  END IF;
  RETURN NEW;
END;
$function$;

CREATE TRIGGER programme_versions_c2_publication_complete
  BEFORE UPDATE OF statut ON public.programme_versions
  FOR EACH ROW EXECUTE FUNCTION private.programme_c2_publication_complete();

-- ---------------------------------------------------------------------------
-- 4. L'ecriture du contenu, dans un brouillon seulement
-- ---------------------------------------------------------------------------
CREATE FUNCTION public.modifier_contenu_niveau(
  p_niveau_id uuid,
  p_objectifs text[],
  p_plage_support jsonb,
  p_durees jsonb
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  v_statut text;
  v_objectifs text[];
  v_support text;
  v_cle text;
BEGIN
  IF NOT coalesce(public.app_role() = 'admin' AND public.app_account_valid(), false) THEN
    RAISE EXCEPTION 'modification du programme reservee a l''administration'
      USING errcode = '42501';
  END IF;

  SELECT pv.statut INTO v_statut
    FROM public.programme_niveaux pn
    JOIN public.programme_versions pv ON pv.id = pn.version_id
   WHERE pn.id = p_niveau_id;
  IF v_statut IS NULL THEN
    RAISE EXCEPTION 'niveau introuvable';
  END IF;
  IF v_statut <> 'brouillon' THEN
    RAISE EXCEPTION 'version publiee ou archivee : creez une nouvelle version pour modifier le programme';
  END IF;

  -- Objectifs : textes nettoyes, vides retires, 5 au plus.
  SELECT coalesce(pg_catalog.array_agg(pg_catalog.btrim(o) ORDER BY i), '{}'::text[])
    INTO v_objectifs
    FROM pg_catalog.unnest(coalesce(p_objectifs, '{}'::text[])) WITH ORDINALITY AS u(o, i)
   WHERE pg_catalog.btrim(coalesce(o, '')) <> '';
  IF pg_catalog.cardinality(v_objectifs) > 5 THEN
    RAISE EXCEPTION 'objectifs_trop_nombreux: 5 au plus';
  END IF;
  IF EXISTS (SELECT 1 FROM pg_catalog.unnest(v_objectifs) o WHERE pg_catalog.length(o) > 200) THEN
    RAISE EXCEPTION 'objectif_trop_long: 200 caracteres au plus';
  END IF;

  -- Plage de support : support connu, nombres positifs, fin apres debut.
  IF p_plage_support IS NOT NULL THEN
    IF pg_catalog.jsonb_typeof(p_plage_support) <> 'object' THEN
      RAISE EXCEPTION 'plage_support_invalide';
    END IF;
    v_support := p_plage_support ->> 'support';
    IF v_support IS NULL OR v_support NOT IN ('livre_rewayah', 'mushaf') THEN
      RAISE EXCEPTION 'plage_support_invalide: support inconnu';
    END IF;
    FOREACH v_cle IN ARRAY ARRAY['page_debut', 'ligne_debut', 'page_fin', 'ligne_fin'] LOOP
      IF p_plage_support ? v_cle
         AND pg_catalog.jsonb_typeof(p_plage_support -> v_cle) <> 'null'
         AND NOT (
           pg_catalog.jsonb_typeof(p_plage_support -> v_cle) = 'number'
           AND (p_plage_support ->> v_cle)::numeric BETWEEN 1 AND 2000
         ) THEN
        RAISE EXCEPTION 'plage_support_invalide: %', v_cle;
      END IF;
    END LOOP;
    IF v_support = 'mushaf' AND (
         (p_plage_support ->> 'page_debut')::numeric > 604
         OR (p_plage_support ->> 'page_fin')::numeric > 604
       ) THEN
      RAISE EXCEPTION 'plage_support_invalide: le Mushaf a 604 pages';
    END IF;
    IF (p_plage_support ->> 'page_fin')::numeric < (p_plage_support ->> 'page_debut')::numeric THEN
      RAISE EXCEPTION 'plage_support_invalide: la fin precede le debut';
    END IF;
  END IF;

  -- Durees : seulement des cohortes connues ; chaque entree complete et
  -- coherente. Une cohorte absente reste a remplir (refusee a la publication).
  IF p_durees IS NULL OR pg_catalog.jsonb_typeof(p_durees) <> 'object' THEN
    RAISE EXCEPTION 'durees_invalides';
  END IF;
  IF EXISTS (
    SELECT 1 FROM pg_catalog.jsonb_object_keys(p_durees) k
     WHERE NOT EXISTS (SELECT 1 FROM public.cohortes_age c WHERE c.code = k)
  ) THEN
    RAISE EXCEPTION 'durees_invalides: tranche d''age inconnue';
  END IF;
  IF EXISTS (
    SELECT 1 FROM pg_catalog.jsonb_each(p_durees) e(k, v)
     WHERE NOT (
       pg_catalog.jsonb_typeof(v) = 'object'
       AND pg_catalog.jsonb_typeof(v -> 'prevue') = 'number'
       AND pg_catalog.jsonb_typeof(v -> 'limite') = 'number'
       AND (v ->> 'prevue')::numeric BETWEEN 1 AND 260
       AND (v ->> 'limite')::numeric BETWEEN (v ->> 'prevue')::numeric AND 520
     )
  ) THEN
    RAISE EXCEPTION 'durees_invalides: semaines entre 1 et 260, date limite apres la duree prevue';
  END IF;

  UPDATE public.programme_niveaux
     SET objectifs = v_objectifs,
         plage_support = p_plage_support,
         durees = p_durees
   WHERE id = p_niveau_id;

  PERFORM public.log_sensitive_access(
    'contenu_niveau_programme_modifie', 'programme_niveaux', p_niveau_id::text,
    pg_catalog.jsonb_build_object(
      'objectifs', pg_catalog.cardinality(v_objectifs),
      'support', v_support,
      'tranches', (SELECT pg_catalog.count(*) FROM pg_catalog.jsonb_object_keys(p_durees))
    )
  );
END;
$function$;

COMMENT ON FUNCTION public.modifier_contenu_niveau(uuid, text[], jsonb, jsonb) IS
  'CAHIER-C2 (06/11/2026) : objectifs, plage de support et durees par tranche '
  'd''age d''une etape, dans une version brouillon. Direction seulement.';

-- ---------------------------------------------------------------------------
-- 5. La proposition des bases, inseree d'un geste dans un brouillon vide
-- ---------------------------------------------------------------------------
-- Les quatre etapes du Niveau 1 « Les bases » (programme-rewayah §2), avec
-- 3 a 5 objectifs rediges par un agent a partir du programme ecrit (reponse 2
-- du directeur du 05/11 : il les valide en une lecture) et un decoupage
-- PROPOSE des durees decidees pour les bases (14/10 : 37, 28, 24, 15 semaines
-- prevues). Date limite de chaque etape : duree prevue x 1,3, arrondie (regle
-- du 14/10). Tout reste modifiable tant que la version n'est pas publiee.
CREATE FUNCTION public.preremplir_bases_programme(p_version_id uuid)
RETURNS integer
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  v_statut text;
  v_etape record;
  v_durees jsonb;
BEGIN
  IF NOT coalesce(public.app_role() = 'admin' AND public.app_account_valid(), false) THEN
    RAISE EXCEPTION 'modification du programme reservee a l''administration'
      USING errcode = '42501';
  END IF;

  SELECT statut INTO v_statut FROM public.programme_versions
   WHERE id = p_version_id FOR UPDATE;
  IF v_statut IS NULL THEN
    RAISE EXCEPTION 'version introuvable';
  END IF;
  IF v_statut <> 'brouillon' THEN
    RAISE EXCEPTION 'version publiee ou archivee : creez une nouvelle version pour modifier le programme';
  END IF;
  IF EXISTS (SELECT 1 FROM public.programme_niveaux WHERE version_id = p_version_id) THEN
    RAISE EXCEPTION 'version_non_vide: la proposition ne remplit qu''une version sans etape';
  END IF;

  FOR v_etape IN
    SELECT * FROM (VALUES
      (1, 'BASES-1', 'Les lettres',
       ARRAY[
         'Reconnaît chaque lettre seule, dans le désordre',
         'Prononce chaque lettre depuis son point de sortie',
         'Distingue les lettres qui se ressemblent',
         'Reconnaît une lettre au début, au milieu et à la fin d''un mot'
       ],
       '{"support": "livre_rewayah"}'::jsonb,
       ARRAY[8, 6, 5, 3]),
      (2, 'BASES-2', 'Lire avec les voyelles',
       ARRAY[
         'Lit une lettre avec chacune des trois voyelles brèves',
         'Lit les voyelles longues et le soukoun',
         'Lit le tanwin',
         'Lit la chadda',
         'Lit un mot de plusieurs syllabes sans épeler'
       ],
       '{"support": "livre_rewayah"}'::jsonb,
       ARRAY[14, 11, 9, 6]),
      (3, 'BASES-3', 'Lire dans le Coran',
       ARRAY[
         'Lit les dernières pages du livre sans épeler',
         'Lit une page du Mushaf en suivant ses signes',
         'Lit d''un rythme régulier, sans revenir en arrière'
       ],
       '{"support": "livre_rewayah"}'::jsonb,
       ARRAY[8, 6, 5, 3]),
      (4, 'BASES-4', 'Les sourates courtes, d''Al-Masad à Az-Zalzalah',
       ARRAY[
         'Récite chaque sourate de l''étape de mémoire, sans erreur de mot',
         'Récite en respectant les voyelles et les lettres longues',
         'S''arrête aux fins de versets',
         'Garde les sourates déjà apprises'
       ],
       '{"support": "mushaf"}'::jsonb,
       ARRAY[7, 5, 5, 3])
    ) AS e(ordre, code, nom, objectifs, plage, prevues)
  LOOP
    -- prevues : dans l'ordre 6-9, 10-13, 14-17, 18+.
    SELECT pg_catalog.jsonb_object_agg(
             c.code,
             pg_catalog.jsonb_build_object(
               'prevue', v_etape.prevues[c.rang],
               'limite', pg_catalog.round(v_etape.prevues[c.rang] * 1.3)::int
             ))
      INTO v_durees
      FROM (VALUES ('enfant_6_9', 1), ('enfant_10_13', 2),
                   ('ado_14_17', 3), ('adulte_18_plus', 4)) AS c(code, rang)
     WHERE EXISTS (SELECT 1 FROM public.cohortes_age a WHERE a.code = c.code);

    INSERT INTO public.programme_niveaux
      (version_id, code_technique, nom_humain, cycle, ordre, objectifs, plage_support, durees)
    VALUES
      (p_version_id, v_etape.code, v_etape.nom, 'Les bases', v_etape.ordre,
       v_etape.objectifs, v_etape.plage, coalesce(v_durees, '{}'::jsonb));
  END LOOP;

  PERFORM public.log_sensitive_access(
    'programme_bases_preremplies', 'programme_versions', p_version_id::text,
    pg_catalog.jsonb_build_object('etapes', 4)
  );
  RETURN 4;
END;
$function$;

COMMENT ON FUNCTION public.preremplir_bases_programme(uuid) IS
  'CAHIER-C2 (06/11/2026) : insere dans un brouillon vide la proposition des '
  'quatre etapes des bases (objectifs rediges par un agent, durees par etape '
  'proposees), a relire par la direction avant publication.';

-- ---------------------------------------------------------------------------
-- 6. La copie d'une version emporte aussi le contenu (signature inchangee)
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.creer_version_programme(p_source_version_id uuid default null)
RETURNS uuid
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  v_id uuid;
  v_numero int;
BEGIN
  IF public.app_role() <> 'admin' OR NOT public.app_account_valid() THEN
    RAISE EXCEPTION 'creation de version de programme reservee a l''administration';
  END IF;

  IF p_source_version_id IS NOT NULL AND NOT EXISTS (
    SELECT 1 FROM public.programme_versions WHERE id = p_source_version_id
  ) THEN
    RAISE EXCEPTION 'version source introuvable';
  END IF;

  SELECT coalesce(max(numero_version), 0) + 1 INTO v_numero FROM public.programme_versions;

  INSERT INTO public.programme_versions (statut, numero_version, cree_par)
  VALUES ('brouillon', v_numero, auth.uid())
  RETURNING id INTO v_id;

  IF p_source_version_id IS NOT NULL THEN
    INSERT INTO public.programme_niveaux
      (version_id, code_technique, nom_humain, cycle, ordre, description,
       objectifs, plage_support, durees)
    SELECT v_id, code_technique, nom_humain, cycle, ordre, description,
           objectifs, plage_support, durees
    FROM public.programme_niveaux
    WHERE version_id = p_source_version_id;
  END IF;

  PERFORM public.log_sensitive_access(
    'programme_version_creee', 'programme_versions', v_id::text,
    jsonb_build_object('numero_version', v_numero, 'source_version_id', p_source_version_id)
  );

  RETURN v_id;
END;
$function$;

-- ---------------------------------------------------------------------------
-- 7. Les lectures
-- ---------------------------------------------------------------------------
-- Le contenu des etapes d'une version, pour l'ecran Programmes de la direction.
CREATE FUNCTION public.programme_contenu_admin(p_version_id uuid)
RETURNS TABLE (
  niveau_id uuid,
  code_technique text,
  nom_humain text,
  cycle text,
  ordre int,
  description text,
  objectifs text[],
  plage_support jsonb,
  durees jsonb,
  complet boolean
)
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $function$
#variable_conflict use_column
BEGIN
  IF NOT coalesce(public.app_role() = 'admin' AND public.app_account_valid(), false) THEN
    RAISE EXCEPTION 'lecture du programme reservee a l''administration'
      USING errcode = '42501';
  END IF;
  RETURN QUERY
    SELECT n.id, n.code_technique, n.nom_humain, n.cycle, n.ordre, n.description,
           n.objectifs, n.plage_support, n.durees,
           private.programme_c2_niveau_complet(n)
      FROM public.programme_niveaux n
     WHERE n.version_id = p_version_id
     ORDER BY n.ordre ASC;
END;
$function$;

COMMENT ON FUNCTION public.programme_contenu_admin(uuid) IS
  'CAHIER-C2 (06/11/2026) : les etapes d''une version avec leur contenu '
  '(objectifs, plage de support, durees) et si elles sont publiables.';

-- L'etape en cours de chaque eleve actif d'une Classe, depuis une version
-- PUBLIEE seulement : la derniere decision de niveau de l'eleve
-- (`progression_historique`), sinon l'etape de la Classe
-- (`groupes.programme_niveau_id`). La duree et la date limite sont celles de
-- la tranche d'age de l'eleve (`student_profiles.cohorte`) ; la date limite
-- se compte depuis la decision de niveau (nulle quand l'etape vient de la
-- Classe : aucun depart connu, rien n'est suppose). Aucune donnee privee :
-- prenom et identifiant restent dans la lecture de la Classe.
CREATE FUNCTION public.etapes_eleves_classe(p_groupe_id uuid)
RETURNS TABLE (
  student_id uuid,
  niveau_id uuid,
  etape_nom text,
  etape_ordre int,
  cycle text,
  objectifs text[],
  cohorte text,
  duree_prevue_semaines int,
  date_limite_semaines int,
  depuis timestamptz,
  date_limite date
)
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $function$
#variable_conflict use_column
BEGIN
  IF NOT private.cahier_c1_peut_lire_classe(p_groupe_id) THEN
    RAISE EXCEPTION 'etapes de la classe refusees' USING errcode = '42501';
  END IF;
  RETURN QUERY
    WITH membres AS (
      SELECT m.student_id
        FROM public.groupe_membres m
       WHERE m.groupe_id = p_groupe_id AND m.left_at IS NULL
    ),
    decision AS (
      SELECT DISTINCT ON (h.student_id) h.student_id, h.niveau_id, h.created_at
        FROM public.progression_historique h
        JOIN membres mb ON mb.student_id = h.student_id
       ORDER BY h.student_id, h.created_at DESC
    ),
    choisie AS (
      SELECT mb.student_id,
             CASE WHEN dv.statut = 'publiee' THEN d.niveau_id ELSE g.programme_niveau_id END AS niveau_id,
             CASE WHEN dv.statut = 'publiee' THEN d.created_at END AS depuis
        FROM membres mb
        JOIN public.groupes g ON g.id = p_groupe_id
        LEFT JOIN decision d ON d.student_id = mb.student_id
        LEFT JOIN public.programme_niveaux dn ON dn.id = d.niveau_id
        LEFT JOIN public.programme_versions dv ON dv.id = dn.version_id
    )
    SELECT ch.student_id,
           n.id,
           n.nom_humain,
           n.ordre,
           n.cycle,
           n.objectifs,
           sp.cohorte,
           (n.durees -> sp.cohorte ->> 'prevue')::int,
           (n.durees -> sp.cohorte ->> 'limite')::int,
           ch.depuis,
           CASE WHEN ch.depuis IS NOT NULL AND (n.durees -> sp.cohorte ->> 'limite') IS NOT NULL
                THEN (ch.depuis + pg_catalog.make_interval(
                        weeks => (n.durees -> sp.cohorte ->> 'limite')::int))::date
           END
      FROM choisie ch
      JOIN public.programme_niveaux n ON n.id = ch.niveau_id
      JOIN public.programme_versions v ON v.id = n.version_id AND v.statut = 'publiee'
      LEFT JOIN public.student_profiles sp ON sp.profile_id = ch.student_id;
END;
$function$;

COMMENT ON FUNCTION public.etapes_eleves_classe(uuid) IS
  'CAHIER-C2 (06/11/2026) : l''etape en cours (version publiee) de chaque eleve '
  'actif d''une Classe, ses objectifs, sa duree et sa date limite pour la tranche '
  'd''age de l''eleve. Memes droits que position_reprise_classe. 42501 sinon.';

-- ---------------------------------------------------------------------------
-- 8. Droits (deux chemins : PUBLIC et anon)
-- ---------------------------------------------------------------------------
REVOKE ALL ON FUNCTION private.programme_c2_durees_completes(jsonb)
  FROM PUBLIC, anon, authenticated, service_role, agent_ro;
REVOKE ALL ON FUNCTION private.programme_c2_niveau_complet(public.programme_niveaux)
  FROM PUBLIC, anon, authenticated, service_role, agent_ro;
REVOKE ALL ON FUNCTION private.programme_c2_publication_complete()
  FROM PUBLIC, anon, authenticated, service_role, agent_ro;
REVOKE ALL ON FUNCTION public.modifier_contenu_niveau(uuid, text[], jsonb, jsonb)
  FROM PUBLIC, anon, service_role, agent_ro;
REVOKE ALL ON FUNCTION public.preremplir_bases_programme(uuid)
  FROM PUBLIC, anon, service_role, agent_ro;
REVOKE ALL ON FUNCTION public.programme_contenu_admin(uuid)
  FROM PUBLIC, anon, service_role;
REVOKE ALL ON FUNCTION public.etapes_eleves_classe(uuid)
  FROM PUBLIC, anon, service_role, agent_ro;
GRANT EXECUTE ON FUNCTION public.modifier_contenu_niveau(uuid, text[], jsonb, jsonb) TO authenticated;
GRANT EXECUTE ON FUNCTION public.preremplir_bases_programme(uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION public.programme_contenu_admin(uuid) TO authenticated, agent_ro;
GRANT EXECUTE ON FUNCTION public.etapes_eleves_classe(uuid) TO authenticated;

-- ---------------------------------------------------------------------------
-- 9. Postflight
-- ---------------------------------------------------------------------------
DO $postflight$
BEGIN
  IF NOT (SELECT c.relrowsecurity FROM pg_catalog.pg_class c
           WHERE c.oid = 'public.programme_niveaux'::regclass) THEN
    RAISE EXCEPTION 'CAHIER-C2 : RLS absente sur programme_niveaux';
  END IF;
  IF pg_catalog.has_table_privilege('authenticated', 'public.programme_niveaux', 'UPDATE')
     OR pg_catalog.has_table_privilege('anon', 'public.programme_niveaux', 'SELECT')
  THEN
    RAISE EXCEPTION 'CAHIER-C2 : acces direct ouvert sur programme_niveaux';
  END IF;
  IF pg_catalog.has_function_privilege('anon', 'public.modifier_contenu_niveau(uuid, text[], jsonb, jsonb)', 'EXECUTE')
     OR pg_catalog.has_function_privilege('anon', 'public.preremplir_bases_programme(uuid)', 'EXECUTE')
     OR pg_catalog.has_function_privilege('anon', 'public.programme_contenu_admin(uuid)', 'EXECUTE')
     OR pg_catalog.has_function_privilege('anon', 'public.etapes_eleves_classe(uuid)', 'EXECUTE')
     OR pg_catalog.has_function_privilege('agent_ro', 'public.modifier_contenu_niveau(uuid, text[], jsonb, jsonb)', 'EXECUTE')
     OR pg_catalog.has_function_privilege('agent_ro', 'public.preremplir_bases_programme(uuid)', 'EXECUTE')
     OR pg_catalog.has_function_privilege('authenticated', 'private.programme_c2_niveau_complet(public.programme_niveaux)', 'EXECUTE')
     OR NOT pg_catalog.has_function_privilege('authenticated', 'public.etapes_eleves_classe(uuid)', 'EXECUTE')
  THEN
    RAISE EXCEPTION 'CAHIER-C2 : droits des fonctions incorrects';
  END IF;
END;
$postflight$;

COMMIT;
