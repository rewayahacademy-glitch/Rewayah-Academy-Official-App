-- HISTORIQUE-CLASSE (pilote, 07/11/2026, point 4)
--
-- Constat : l'Historique du tuteur affichait « Classe non disponible » sur ses
-- lignes. Le client cherchait le nom de la classe d'une seance parmi les
-- classes COURANTES du foyer (`mes_groupes_famille_v`, qui ne rend que les
-- Classes non closes et les inscriptions en cours) : une seance d'une Classe
-- quittee ou close perdait son nom, alors que chaque seance porte son
-- `groupe_id`.
--
-- Correction : `public.mes_seances_v` rend, EN DERNIER, deux colonnes lues
-- avec la seance, sous la MEME garde que la lecture actuelle de l'Historique
-- (aucune ligne nouvelle, aucune condition changee) :
--   * groupe_id      : `sessions.groupe_id` (nul pour une seance sans Classe) ;
--   * groupe_libelle : `groupes.libelle` de cette Classe, close ou non.
-- La jointure `groupes` se fait sur sa cle primaire, a gauche : une ligne au
-- plus, aucune ligne dupliquee, aucune ligne perdue.
--
-- RECOPIE DECLAREE : la definition est celle du depot
-- (`20261109400000_drapeaux_pays_enseignant.sql`, section 2), derniere en
-- date. Seuls changent : les deux colonnes ajoutees et la jointure a gauche
-- `groupes`. Le pilote compare a la definition de PRODUCTION avant
-- d'installer (aucune fonction n'est remplacee : pas de md5(prosrc) ; la vue
-- se compare par pg_get_viewdef). Les droits ne changent pas (CREATE OR
-- REPLACE VIEW les garde) : authenticated et service_role, jamais anon.
--
-- Aucun effacement de ligne ni d'objet. Aucune fonction d'ecriture. Pas de
-- BEGIN/COMMIT de premier niveau.

-- Preflight : la forme attendue de la vue, sinon rien ne change. -------------

DO $preflight$
DECLARE
  v_colonnes text;
BEGIN
  SELECT pg_catalog.string_agg(a.attname, ',' ORDER BY a.attnum) INTO v_colonnes
    FROM pg_catalog.pg_attribute a
   WHERE a.attrelid = 'public.mes_seances_v'::pg_catalog.regclass
     AND a.attnum > 0 AND NOT a.attisdropped;
  -- La forme d'avant, ou deja la forme finale (migration rejouee).
  IF v_colonnes IS DISTINCT FROM
     'session_id,started_at,ended_at,status,session_type,prayer_pause_minutes,student_id,student_first_name,student_immutable_id,teacher_id,teacher_first_name,teacher_immutable_id,teacher_country'
     AND v_colonnes IS DISTINCT FROM
     'session_id,started_at,ended_at,status,session_type,prayer_pause_minutes,student_id,student_first_name,student_immutable_id,teacher_id,teacher_first_name,teacher_immutable_id,teacher_country,groupe_id,groupe_libelle' THEN
    RAISE EXCEPTION 'HISTORIQUE-CLASSE : mes_seances_v n''a pas la forme attendue (%)', v_colonnes;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_catalog.pg_views v
                  WHERE v.schemaname = 'public' AND v.viewname = 'mes_seances_v'
                    AND v.definition LIKE '%app_account_valid%'
                    AND v.definition LIKE '%agent_identite_masquee%'
                    AND v.definition LIKE '%app_household_id%'
                    AND v.definition LIKE '%left_at%'
                    AND v.definition LIKE '%ended_at <= s.started_at%'
                    AND v.definition LIKE '%teacher_profiles%') THEN
    RAISE EXCEPTION 'HISTORIQUE-CLASSE : mes_seances_v n''est pas la definition attendue (garde, FN-106, DRAPEAUX)';
  END IF;
END;
$preflight$;

-- mes_seances_v ----------------------------------------------------------------

CREATE OR REPLACE VIEW public.mes_seances_v
WITH (security_barrier = true)
AS
SELECT
  s.id AS session_id,
  s.started_at,
  s.ended_at,
  s.status,
  s.session_type,
  s.prayer_pause_minutes,
  eleve.id AS student_id,
  CASE WHEN public.agent_identite_masquee()
       THEN eleve.immutable_id ELSE eleve.first_name END AS student_first_name,
  eleve.immutable_id AS student_immutable_id,
  ens.id AS teacher_id,
  CASE WHEN public.agent_identite_masquee()
       THEN ens.immutable_id ELSE ens.first_name END AS teacher_first_name,
  ens.immutable_id AS teacher_immutable_id,
  -- DRAPEAUX : le pays seul, masque comme le prenom.
  CASE WHEN public.agent_identite_masquee() THEN NULL::text
       ELSE tp.country END AS teacher_country,
  -- HISTORIQUE-CLASSE : la Classe de la seance, close ou quittee comprise.
  s.groupe_id AS groupe_id,
  cl.libelle AS groupe_libelle
FROM public.sessions s
JOIN public.session_participants spe
  ON spe.session_id = s.id AND spe.role = 'student' AND spe.deleted_at IS NULL
JOIN public.profiles eleve ON eleve.id = spe.profile_id AND eleve.deleted_at IS NULL
JOIN public.profiles ens ON ens.id = s.teacher_id AND ens.deleted_at IS NULL
LEFT JOIN public.teacher_profiles tp ON tp.profile_id = ens.id AND tp.deleted_at IS NULL
LEFT JOIN public.groupes cl ON cl.id = s.groupe_id
WHERE s.deleted_at IS NULL
  AND public.app_account_valid()
  AND (
    (public.app_role() = 'teacher' AND s.teacher_id = auth.uid())
    OR (
      (
        (public.app_role() = 'student' AND spe.profile_id = auth.uid())
        OR (
          public.app_role() = 'guardian'
          AND eleve.household_id IS NOT NULL
          AND eleve.household_id = public.app_household_id()
        )
      )
      -- FN-106 : pas de seance d'une Classe quittee ou cloturee avant son
      -- debut ; les seances d'avant le depart restent (historique).
      AND NOT EXISTS (
        SELECT 1 FROM public.groupe_membres gm
         WHERE gm.groupe_id = s.groupe_id AND gm.student_id = eleve.id
           AND gm.left_at IS NOT NULL AND gm.left_at <= s.started_at
           AND NOT EXISTS (SELECT 1 FROM public.groupe_membres gm2
                            WHERE gm2.groupe_id = s.groupe_id AND gm2.student_id = eleve.id
                              AND gm2.left_at IS NULL))
      AND NOT EXISTS (
        SELECT 1 FROM public.groupes g
         WHERE g.id = s.groupe_id AND g.ended_at IS NOT NULL AND g.ended_at <= s.started_at)
    )
    OR public.app_role() IN ('admin', 'controller')
  );

COMMENT ON COLUMN public.mes_seances_v.groupe_id IS
  'HISTORIQUE-CLASSE (07/11/2026) : la Classe de la seance (sessions.groupe_id), nulle pour une seance sans Classe.';
COMMENT ON COLUMN public.mes_seances_v.groupe_libelle IS
  'HISTORIQUE-CLASSE (07/11/2026) : le nom de la Classe de la seance (groupes.libelle), lu avec la seance sous la meme garde, Classe close ou quittee comprise.';

-- Postflight ----------------------------------------------------------------------

DO $postflight$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_catalog.pg_class c
                  WHERE c.oid = 'public.mes_seances_v'::pg_catalog.regclass
                    AND coalesce(c.reloptions, '{}') @> ARRAY['security_barrier=true']) THEN
    RAISE EXCEPTION 'HISTORIQUE-CLASSE : mes_seances_v a perdu security_barrier';
  END IF;
  IF (SELECT pg_catalog.string_agg(a.attname, ',' ORDER BY a.attnum)
        FROM pg_catalog.pg_attribute a
       WHERE a.attrelid = 'public.mes_seances_v'::pg_catalog.regclass
         AND a.attnum > 0 AND NOT a.attisdropped)
     IS DISTINCT FROM
     'session_id,started_at,ended_at,status,session_type,prayer_pause_minutes,student_id,student_first_name,student_immutable_id,teacher_id,teacher_first_name,teacher_immutable_id,teacher_country,groupe_id,groupe_libelle' THEN
    RAISE EXCEPTION 'HISTORIQUE-CLASSE : mes_seances_v n''a pas la forme finale attendue';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_catalog.pg_views v
                  WHERE v.schemaname = 'public' AND v.viewname = 'mes_seances_v'
                    AND v.definition LIKE '%app_account_valid%'
                    AND v.definition LIKE '%agent_identite_masquee%'
                    AND v.definition LIKE '%app_household_id%'
                    AND v.definition LIKE '%left_at%') THEN
    RAISE EXCEPTION 'HISTORIQUE-CLASSE : mes_seances_v a perdu sa garde';
  END IF;
  IF pg_catalog.has_table_privilege('anon', 'public.mes_seances_v', 'SELECT') THEN
    RAISE EXCEPTION 'HISTORIQUE-CLASSE : mes_seances_v lisible sans compte';
  END IF;
  IF NOT pg_catalog.has_table_privilege('authenticated', 'public.mes_seances_v', 'SELECT') THEN
    RAISE EXCEPTION 'HISTORIQUE-CLASSE : mes_seances_v n''est plus lisible par authenticated';
  END IF;
END;
$postflight$;
