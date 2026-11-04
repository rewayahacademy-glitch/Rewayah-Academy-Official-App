-- DRAPEAUX (directeur, 03/11/2026 ; fiche PLAN-LOTS §12, ENS-PAYS-1_BR.md:15-26)
--
-- Le pays de l'enseignant pour les familles et les eleves : une colonne
-- `teacher_country` ajoutee, EN DERNIER, a deux projections deja lues par le
-- client (`select()` sans liste, lecture de `teacher_country` deja presente :
-- `groupes_supabase.dart:55`, `service_planning.dart:139`) :
--   * public.mes_groupes_famille_v (cartes de classe, Accueil, fiche de la
--     classe, salle) ;
--   * public.mes_seances_v (seances de la famille et de l'eleve).
--
-- Meme masquage que le prenom : nul quand `agent_identite_masquee()` (un pays
-- parmi quelques enseignants peut suffire a reconnaitre la personne). Le pays
-- seul (`teacher_profiles.country`), jamais une adresse ni une ville. Aucune
-- ligne nouvelle n'est rendue : la colonne s'ajoute a des lignes deja permises.
--
-- RECOPIE DECLAREE : les deux definitions sont celles lues en production le
-- 04/11/2026 (pg_get_viewdef, PostgreSQL 17.6, lecture seule), identiques a
-- leur derniere definition du depot (`0033_tc_vues_rpc.sql:140` et
-- `20261107500000_fn_serveur.sql:193`). Seuls changent : la colonne ajoutee,
-- `tp.country` dans le GROUP BY de la premiere, et la jointure
-- `teacher_profiles` (cle primaire `profile_id`, une ligne au plus) de la
-- seconde. Les droits ne changent pas (CREATE OR REPLACE VIEW les garde) :
-- authenticated et service_role, jamais anon.
--
-- Aucun effacement de ligne ni d'objet. Pas de BEGIN/COMMIT de premier niveau.

-- Preflight : la forme attendue des deux vues, sinon rien ne change. ---------

DO $preflight$
DECLARE
  v_groupes text;
  v_seances text;
BEGIN
  SELECT pg_catalog.string_agg(a.attname, ',' ORDER BY a.attnum) INTO v_groupes
    FROM pg_catalog.pg_attribute a
   WHERE a.attrelid = 'public.mes_groupes_famille_v'::pg_catalog.regclass
     AND a.attnum > 0 AND NOT a.attisdropped;
  IF v_groupes IS DISTINCT FROM
     'groupe_id,libelle,type_public,seuil_max,weekday,hour_local,timezone_iana,couleur_jeton,nom_cours,programme_niveau_id,teacher_id,teacher_prenom,teacher_titre,teacher_photo_cle,nb_membres' THEN
    RAISE EXCEPTION 'DRAPEAUX : mes_groupes_famille_v n''a pas la forme attendue (%)', v_groupes;
  END IF;
  SELECT pg_catalog.string_agg(a.attname, ',' ORDER BY a.attnum) INTO v_seances
    FROM pg_catalog.pg_attribute a
   WHERE a.attrelid = 'public.mes_seances_v'::pg_catalog.regclass
     AND a.attnum > 0 AND NOT a.attisdropped;
  IF v_seances IS DISTINCT FROM
     'session_id,started_at,ended_at,status,session_type,prayer_pause_minutes,student_id,student_first_name,student_immutable_id,teacher_id,teacher_first_name,teacher_immutable_id' THEN
    RAISE EXCEPTION 'DRAPEAUX : mes_seances_v n''a pas la forme attendue (%)', v_seances;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_catalog.pg_views v
                  WHERE v.schemaname = 'public' AND v.viewname = 'mes_groupes_famille_v'
                    AND v.definition LIKE '%est_du_foyer%'
                    AND v.definition LIKE '%agent_identite_masquee%') THEN
    RAISE EXCEPTION 'DRAPEAUX : mes_groupes_famille_v n''est pas la definition attendue (foyer, masquage)';
  END IF;
END;
$preflight$;

-- 1. mes_groupes_famille_v ------------------------------------------------------

CREATE OR REPLACE VIEW public.mes_groupes_famille_v
WITH (security_barrier = true)
AS
SELECT
  g.id AS groupe_id,
  g.libelle,
  g.type_public,
  g.seuil_max,
  g.weekday,
  g.hour_local,
  g.timezone_iana,
  g.couleur_jeton,
  g.nom_cours,
  g.programme_niveau_id,
  g.teacher_id,
  CASE WHEN public.agent_identite_masquee() THEN NULL::text
       ELSE tp_p.first_name END AS teacher_prenom,
  tp.titre AS teacher_titre,
  tp.photo_storage_key AS teacher_photo_cle,
  (count(m2.id) FILTER (WHERE m2.left_at IS NULL))::integer AS nb_membres,
  -- DRAPEAUX : le pays seul, masque comme le prenom.
  CASE WHEN public.agent_identite_masquee() THEN NULL::text
       ELSE tp.country END AS teacher_country
FROM public.groupes g
JOIN public.groupe_membres m ON m.groupe_id = g.id AND m.left_at IS NULL
JOIN public.profiles tp_p ON tp_p.id = g.teacher_id
LEFT JOIN public.teacher_profiles tp ON tp.profile_id = g.teacher_id
LEFT JOIN public.groupe_membres m2 ON m2.groupe_id = g.id
WHERE g.ended_at IS NULL
  AND public.app_account_valid()
  AND (m.student_id = auth.uid() OR public.est_du_foyer(m.student_id))
GROUP BY g.id, g.libelle, g.type_public, g.seuil_max, g.weekday, g.hour_local,
         g.timezone_iana, g.couleur_jeton, g.nom_cours, g.programme_niveau_id,
         g.teacher_id, tp_p.first_name, tp.titre, tp.photo_storage_key, tp.country;

COMMENT ON COLUMN public.mes_groupes_famille_v.teacher_country IS
  'DRAPEAUX (04/11/2026) : le pays de l''enseignant (teacher_profiles.country), nul quand l''identite est masquee a un agent. Le pays seul, jamais une adresse ni une ville.';

-- 2. mes_seances_v ---------------------------------------------------------------

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
       ELSE tp.country END AS teacher_country
FROM public.sessions s
JOIN public.session_participants spe
  ON spe.session_id = s.id AND spe.role = 'student' AND spe.deleted_at IS NULL
JOIN public.profiles eleve ON eleve.id = spe.profile_id AND eleve.deleted_at IS NULL
JOIN public.profiles ens ON ens.id = s.teacher_id AND ens.deleted_at IS NULL
LEFT JOIN public.teacher_profiles tp ON tp.profile_id = ens.id AND tp.deleted_at IS NULL
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

COMMENT ON COLUMN public.mes_seances_v.teacher_country IS
  'DRAPEAUX (04/11/2026) : le pays de l''enseignant (teacher_profiles.country), nul quand l''identite est masquee a un agent. Le pays seul, jamais une adresse ni une ville.';

-- Postflight ----------------------------------------------------------------------

DO $postflight$
DECLARE
  v_vue text;
BEGIN
  FOREACH v_vue IN ARRAY ARRAY['mes_groupes_famille_v', 'mes_seances_v'] LOOP
    IF NOT EXISTS (SELECT 1 FROM pg_catalog.pg_class c
                    WHERE c.oid = ('public.' || v_vue)::pg_catalog.regclass
                      AND coalesce(c.reloptions, '{}') @> ARRAY['security_barrier=true']) THEN
      RAISE EXCEPTION 'DRAPEAUX : % a perdu security_barrier', v_vue;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_catalog.pg_attribute a
                    WHERE a.attrelid = ('public.' || v_vue)::pg_catalog.regclass
                      AND a.attname = 'teacher_country' AND NOT a.attisdropped
                      AND a.atttypid = 'pg_catalog.text'::pg_catalog.regtype) THEN
      RAISE EXCEPTION 'DRAPEAUX : % sans teacher_country text', v_vue;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_catalog.pg_views v
                    WHERE v.schemaname = 'public' AND v.viewname = v_vue
                      AND v.definition LIKE '%app_account_valid%'
                      AND v.definition LIKE '%agent_identite_masquee%') THEN
      RAISE EXCEPTION 'DRAPEAUX : % a perdu sa garde ou son masquage', v_vue;
    END IF;
    IF pg_catalog.has_table_privilege('anon', 'public.' || v_vue, 'SELECT') THEN
      RAISE EXCEPTION 'DRAPEAUX : % lisible sans compte', v_vue;
    END IF;
    IF NOT pg_catalog.has_table_privilege('authenticated', 'public.' || v_vue, 'SELECT') THEN
      RAISE EXCEPTION 'DRAPEAUX : % n''est plus lisible par authenticated', v_vue;
    END IF;
  END LOOP;
END;
$postflight$;
