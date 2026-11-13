-- PARCOURS-INSCRITS, correctif (13/11/2026) : la classe rendue par la vue du
-- parcours vient de l'ADHESION, pas de l'inscription.
--
-- Le defaut : 20261123810000 (deja installee, jamais modifiee) dit « affectee »
-- parce que l'apprenant est membre actif d'une classe, mais rend la classe de
-- son inscription (COALESCE(i.groupe_id, gm.groupe_id)). Un membre actif de la
-- classe A dont l'inscription pointe la classe B recevait donc l'etat
-- « affectee » avec la classe B. Cas prouve par le scenario
-- scenarios_parcours_inscrits.sql (eleve e8).
--
-- Ce que fait ce fichier, et rien d'autre : la colonne groupe_id lit d'abord
-- l'adhesion, puis, sans adhesion, l'inscription. Memes colonnes, memes types,
-- meme ordre, memes droits, toujours security_invoker. Aucune donnee n'est
-- ecrite ni modifiee.
--
-- ATTENTION A L'INSTALLATION : CREATE OR REPLACE VIEW remplace la definition
-- installee par 20261123810000. Le pre-controle ci-dessous refuse tout ecart de
-- noms et d'ordre de colonnes et verifie que l'etat « affectee » y figure ; il ne
-- compare pas le reste de la definition : lire pg_get_viewdef en production avant.

DO $preflight$
DECLARE
  v_attendues text[] := ARRAY['eleve_id', 'prenom', 'cohorte', 'cohorte_nom', 'type_public',
    'langue_code', 'langue_nom', 'niveau_declare', 'objectif', 'diagnostic_statut',
    'onboarding_fait_le', 'fuseau_foyer', 'intention_id', 'intention_etat', 'offre_id',
    'fuseau_affiche', 'heure_affichee', 'jours_affiches', 'groupe_id', 'offre_etat',
    'offre_indisponible', 'fuseau_change'];
  v_lues text[];
BEGIN
  IF pg_catalog.to_regclass('public.v_parcours_onboarding') IS NULL
     OR pg_catalog.to_regclass('public.groupe_membres') IS NULL
     OR pg_catalog.to_regclass('public.groupes') IS NULL THEN
    RAISE EXCEPTION 'PARCOURS-INSCRITS (classe de l''adhesion) : vue, membres ou classes absents';
  END IF;
  SELECT pg_catalog.array_agg(k.column_name::text ORDER BY k.ordinal_position) INTO v_lues
    FROM information_schema.columns k
   WHERE k.table_schema = 'public' AND k.table_name = 'v_parcours_onboarding';
  IF v_lues IS DISTINCT FROM v_attendues THEN
    RAISE EXCEPTION 'PARCOURS-INSCRITS (classe de l''adhesion) : colonnes de la vue inattendues (%), rien n''est change', v_lues;
  END IF;
  -- La vue doit etre celle de 20261123810000 (etat « affectee » lu sur l'adhesion).
  IF pg_catalog.strpos(pg_catalog.pg_get_viewdef('public.v_parcours_onboarding'::pg_catalog.regclass),
                       'affectee') = 0 THEN
    RAISE EXCEPTION 'PARCOURS-INSCRITS (classe de l''adhesion) : la vue n''est pas celle de 20261123810000, rien n''est change';
  END IF;
END
$preflight$;

CREATE OR REPLACE VIEW public.v_parcours_onboarding
WITH (security_invoker = true) AS
SELECT
  sp.profile_id                                   AS eleve_id,
  p.first_name                                    AS prenom,
  sp.cohorte,
  c.nom_humain                                    AS cohorte_nom,
  c.type_public,
  sp.langue_cours                                 AS langue_code,
  l.nom_humain                                    AS langue_nom,
  sp.niveau_declare,
  sp.objectif,
  sp.diagnostic_statut,
  sp.onboarding_fait_le,
  h.timezone                                      AS fuseau_foyer,
  i.id                                            AS intention_id,
  -- Membre actif d'une classe : affectee, quelle que soit l'intention.
  CASE WHEN gm.groupe_id IS NOT NULL THEN 'affectee' ELSE i.etat END AS intention_etat,
  i.offre_id,
  i.fuseau_affiche,
  i.heure_affichee,
  i.jours_affiches,
  -- La classe suit l'etat : celle de l'adhesion d'abord, puis celle de l'inscription.
  COALESCE(gm.groupe_id, i.groupe_id)             AS groupe_id,
  o.etat                                          AS offre_etat,
  (gm.groupe_id IS NULL AND i.id IS NOT NULL AND o.etat <> 'publiee') AS offre_indisponible,
  (gm.groupe_id IS NULL AND i.id IS NOT NULL AND h.timezone IS NOT NULL
     AND h.timezone <> i.fuseau_affiche)          AS fuseau_change
FROM public.student_profiles sp
JOIN public.profiles p ON p.id = sp.profile_id
LEFT JOIN public.cohortes_age c ON c.code = sp.cohorte
LEFT JOIN public.langues_cours l ON l.code = sp.langue_cours
LEFT JOIN public.households h ON h.id = p.household_id
LEFT JOIN public.intentions_horaire i
  ON i.eleve_id = sp.profile_id AND i.etat <> 'retiree'
LEFT JOIN public.offres_horaires o ON o.id = i.offre_id
LEFT JOIN LATERAL (
  SELECT m.groupe_id
    FROM public.groupe_membres m
    JOIN public.groupes g ON g.id = m.groupe_id
   WHERE m.student_id = sp.profile_id AND m.left_at IS NULL AND g.ended_at IS NULL
   ORDER BY m.joined_at DESC, m.groupe_id
   LIMIT 1
) gm ON true
WHERE sp.deleted_at IS NULL AND p.deleted_at IS NULL;

-- Les droits d'avant : lecture pour authenticated et agent_ro, rien pour anon.
GRANT SELECT ON public.v_parcours_onboarding TO authenticated, agent_ro;
REVOKE ALL ON public.v_parcours_onboarding FROM anon, PUBLIC;

DO $postflight$
DECLARE
  v_options text[];
BEGIN
  SELECT c.reloptions INTO v_options FROM pg_catalog.pg_class c
   WHERE c.oid = 'public.v_parcours_onboarding'::pg_catalog.regclass;
  IF v_options IS NULL OR NOT ('security_invoker=true' = ANY (v_options)) THEN
    RAISE EXCEPTION 'PARCOURS-INSCRITS (classe de l''adhesion) : la vue n''est plus security_invoker';
  END IF;
  IF pg_catalog.has_table_privilege('anon', 'public.v_parcours_onboarding', 'SELECT')
     OR NOT pg_catalog.has_table_privilege('authenticated', 'public.v_parcours_onboarding', 'SELECT') THEN
    RAISE EXCEPTION 'PARCOURS-INSCRITS (classe de l''adhesion) : droits de la vue inattendus';
  END IF;
END
$postflight$;
