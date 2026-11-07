-- SUIVI-ELEVE (agent I, 07/11/2026, feu vert du garde-cap) : l'eleve, et le
-- tuteur pour son enfant, lisent ou en est l'eleve sur le programme.
--
-- Fichier SANS mot d'effacement (B5) : aucun des trois mots interdits n'y
-- figure en instruction. Migration additive (B6) : une fonction privee neuve,
-- une fonction publique neuve, une fonction existante remplacee a signature,
-- droits et resultat identiques (`etapes_eleves_classe`, CAHIER-C2).
--
-- Ce que fait le lot :
--   1. Le calcul de l'etape en cours d'un eleve (decision de niveau publiee,
--      sinon etape de la Classe ; duree prevue et date limite de sa tranche
--      d'age) sort de `etapes_eleves_classe` dans `private.etape_eleve`. Les
--      deux lectures l'appellent : une seule source, aucune recopie.
--   2. `suivi_pedagogique_eleve(p_eleve_id)` rend, pour la Classe active de
--      l'eleve : l'etape en cours et ses objectifs, la duree prevue, la date
--      limite (prochaine echeance), la vitesse calculee ici (jamais dans
--      Flutter) et la derniere page presentee (CAHIER-C1).
--   3. Vitesse, tranchee par le garde-cap le 07/11 sur les regles deja
--      decidees (programme-rewayah §3) ; aucun etat « en avance » :
--        ecoule <= duree prevue               : dans_les_temps ;
--        duree prevue < ecoule <= date limite : au_dela_du_prevu ;
--        ecoule > date limite                 : date_limite_depassee ;
--        sans « depuis » ou sans duree         : inconnu.
--
-- Ce que le lot NE fait PAS (dit au garde-cap et au pilote) :
--   - la date limite NE recule PAS pour une pause accordee ni pour une
--     fermeture : la regle est decidee (programme-rewayah, 30/09) mais aucune
--     donnee de pause ni de fermeture n'existe en base, et C2 ne la porte pas
--     non plus. Le calcul reste celui de C2, au meme endroit : le jour ou les
--     pauses existent, `private.etape_eleve` est le seul point a changer ;
--   - aucune saisie nouvelle pour l'enseignant : tout est lu.
--
-- Garde : l'eleve lui-meme (compte valide) ; le titulaire de son propre profil
-- eleve (role guardian, `titulaire_profile_id` = son id) ; le tuteur du foyer
-- de l'eleve. Tout autre appelant : 42501. Garde positive (B18).
--
-- Preflight : md5(pg_get_functiondef) de `etapes_eleves_classe`,
-- 0ea3e0b8270b0d3cdd4b4832aaa3dcb7, relu sur la base rejouee depuis le depot
-- (a confirmer en production par le pilote avant installation). Rejeu : la
-- fonction appelle deja `private.etape_eleve`, rien n'est reapplique.

BEGIN;

-- ---------------------------------------------------------------------------
-- 1. Preflight
-- ---------------------------------------------------------------------------
DO $preflight$
DECLARE
  v_def text := pg_catalog.pg_get_functiondef(
    'public.etapes_eleves_classe(uuid)'::pg_catalog.regprocedure);
BEGIN
  IF pg_catalog.md5(v_def) <> '0ea3e0b8270b0d3cdd4b4832aaa3dcb7'
     AND pg_catalog.strpos(v_def, 'private.etape_eleve') = 0 THEN
    RAISE EXCEPTION 'SUIVI-ELEVE : etapes_eleves_classe a change depuis la lecture du 07/11 (md5 %)',
      pg_catalog.md5(v_def);
  END IF;
  IF pg_catalog.to_regclass('public.classe_position_reprise') IS NULL THEN
    RAISE EXCEPTION 'SUIVI-ELEVE : CAHIER-C1 absent (classe_position_reprise)';
  END IF;
END;
$preflight$;

-- ---------------------------------------------------------------------------
-- 2. L'etape en cours d'un eleve, une seule source
-- ---------------------------------------------------------------------------
-- Meme regle que CAHIER-C2 : la derniere decision de niveau compte si son
-- etape est dans une version publiee ; sinon l'etape de la Classe, sans
-- « depuis » ni date limite supposes. Aucune ligne si l'etape retenue n'est
-- pas dans une version publiee.
CREATE OR REPLACE FUNCTION private.etape_eleve(p_student_id uuid, p_groupe_id uuid)
RETURNS TABLE (
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
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $function$
  WITH decision AS (
    SELECT h.niveau_id, h.created_at
      FROM public.progression_historique h
     WHERE h.student_id = p_student_id
     ORDER BY h.created_at DESC
     LIMIT 1
  ),
  choisie AS (
    SELECT CASE WHEN dv.statut = 'publiee' THEN d.niveau_id ELSE g.programme_niveau_id END AS niveau_id,
           CASE WHEN dv.statut = 'publiee' THEN d.created_at END AS depuis
      FROM public.groupes g
      LEFT JOIN decision d ON true
      LEFT JOIN public.programme_niveaux dn ON dn.id = d.niveau_id
      LEFT JOIN public.programme_versions dv ON dv.id = dn.version_id
     WHERE g.id = p_groupe_id
  )
  SELECT n.id,
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
    LEFT JOIN public.student_profiles sp ON sp.profile_id = p_student_id;
$function$;

COMMENT ON FUNCTION private.etape_eleve(uuid, uuid) IS
  'SUIVI-ELEVE (07/11/2026) : l''etape en cours d''un eleve dans une Classe, sa '
  'duree prevue et sa date limite (regle de CAHIER-C2). Seule source, appelee '
  'par etapes_eleves_classe et suivi_pedagogique_eleve. Aucun droit direct.';

-- ---------------------------------------------------------------------------
-- 3. etapes_eleves_classe appelle la source unique (resultat inchange)
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.etapes_eleves_classe(p_groupe_id uuid)
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
    SELECT m.student_id, e.*
      FROM public.groupe_membres m
     CROSS JOIN LATERAL private.etape_eleve(m.student_id, p_groupe_id) e
     WHERE m.groupe_id = p_groupe_id AND m.left_at IS NULL;
END;
$function$;

-- ---------------------------------------------------------------------------
-- 4. Le suivi pedagogique d'un eleve, pour lui ou sa famille
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.suivi_pedagogique_eleve(p_eleve_id uuid)
RETURNS TABLE (
  etape_nom text,
  etape_ordre int,
  cycle text,
  objectifs text[],
  duree_prevue_semaines int,
  date_limite date,
  depuis timestamptz,
  semaines_ecoulees int,
  rythme text,
  page_reprise int,
  page_reprise_le timestamptz
)
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $function$
#variable_conflict use_column
DECLARE
  v_user uuid := auth.uid();
  v_groupe uuid;
BEGIN
  IF NOT coalesce(
    v_user IS NOT NULL AND p_eleve_id IS NOT NULL AND public.app_account_valid()
    AND (
      -- L'eleve lui-meme.
      (public.app_role() = 'student' AND p_eleve_id = v_user)
      -- Le titulaire de son propre profil eleve (0052).
      OR (public.app_role() = 'guardian' AND p_eleve_id = v_user
          AND EXISTS (SELECT 1 FROM public.student_profiles sp
                       WHERE sp.profile_id = v_user AND sp.titulaire_profile_id = v_user
                         AND sp.deleted_at IS NULL))
      -- Le tuteur du foyer de l'eleve : son enfant seulement.
      OR (public.app_role() = 'guardian'
          AND EXISTS (SELECT 1 FROM public.profiles p
                       WHERE p.id = p_eleve_id AND p.role = 'student' AND p.deleted_at IS NULL
                         AND p.household_id IS NOT NULL
                         AND p.household_id = public.app_household_id()))
    ), false) THEN
    RAISE EXCEPTION 'suivi pedagogique refuse' USING errcode = '42501';
  END IF;

  SELECT m.groupe_id INTO v_groupe
    FROM public.groupe_membres m
   WHERE m.student_id = p_eleve_id AND m.left_at IS NULL;
  IF v_groupe IS NULL THEN
    RETURN;
  END IF;

  RETURN QUERY
    WITH e AS (
      SELECT * FROM private.etape_eleve(p_eleve_id, v_groupe)
    ),
    calcul AS (
      SELECT e.*,
             CASE WHEN e.depuis IS NOT NULL
                  THEN pg_catalog.floor(
                         EXTRACT(epoch FROM pg_catalog.now() - e.depuis) / 604800)::int
             END AS semaines
        FROM e
    )
    SELECT c.etape_nom,
           c.etape_ordre,
           c.cycle,
           c.objectifs,
           c.duree_prevue_semaines,
           c.date_limite,
           c.depuis,
           c.semaines,
           CASE
             WHEN c.depuis IS NULL OR c.duree_prevue_semaines IS NULL THEN 'inconnu'
             WHEN pg_catalog.now() <= c.depuis + pg_catalog.make_interval(weeks => c.duree_prevue_semaines)
               THEN 'dans_les_temps'
             WHEN c.date_limite IS NULL OR pg_catalog.now()::date <= c.date_limite
               THEN 'au_dela_du_prevu'
             ELSE 'date_limite_depassee'
           END,
           r.page::int,
           r.presentee_le
      FROM calcul c
      LEFT JOIN public.classe_position_reprise r ON r.groupe_id = v_groupe;
END;
$function$;

COMMENT ON FUNCTION public.suivi_pedagogique_eleve(uuid) IS
  'SUIVI-ELEVE (07/11/2026) : etape en cours, objectifs, duree prevue, date '
  'limite, vitesse (dans_les_temps, au_dela_du_prevu, date_limite_depassee, '
  'inconnu) et derniere page presentee de la Classe active d''un eleve. Lue par '
  'l''eleve lui-meme, le titulaire de son profil ou le tuteur de son foyer. '
  '42501 sinon. Aucune ligne sans Classe active ni etape publiee.';

-- ---------------------------------------------------------------------------
-- 5. Droits (deux chemins : PUBLIC et anon)
-- ---------------------------------------------------------------------------
REVOKE ALL ON FUNCTION private.etape_eleve(uuid, uuid)
  FROM PUBLIC, anon, authenticated, service_role, agent_ro;
REVOKE ALL ON FUNCTION public.suivi_pedagogique_eleve(uuid)
  FROM PUBLIC, anon, service_role, agent_ro;
GRANT EXECUTE ON FUNCTION public.suivi_pedagogique_eleve(uuid) TO authenticated;

-- ---------------------------------------------------------------------------
-- 6. Postflight
-- ---------------------------------------------------------------------------
DO $postflight$
BEGIN
  IF pg_catalog.strpos(
       pg_catalog.pg_get_functiondef('public.etapes_eleves_classe(uuid)'::pg_catalog.regprocedure),
       'private.etape_eleve') = 0 THEN
    RAISE EXCEPTION 'SUIVI-ELEVE : etapes_eleves_classe n''appelle pas la source unique';
  END IF;
  IF NOT has_function_privilege('authenticated', 'public.etapes_eleves_classe(uuid)', 'EXECUTE')
     OR has_function_privilege('anon', 'public.etapes_eleves_classe(uuid)', 'EXECUTE')
     OR has_function_privilege('anon', 'public.suivi_pedagogique_eleve(uuid)', 'EXECUTE')
     OR has_function_privilege('authenticated', 'private.etape_eleve(uuid, uuid)', 'EXECUTE') THEN
    RAISE EXCEPTION 'SUIVI-ELEVE : droits inattendus';
  END IF;
END;
$postflight$;

COMMIT;
