-- PARCOURS-INSCRITS (12/11/2026, numero attribue par le garde-cap : 20261123810000).
--
-- Le defaut : un apprenant deja membre actif d'une classe, entre par l'import des
-- inscrits actuels ou par l'administration (donc sans intention d'horaire), etait
-- lu par l'Accueil de la famille comme « Horaire a choisir » : le Parcours de sa
-- famille proposait de choisir un horaire pour un enfant qui a deja sa classe.
-- La cause est la vue public.v_parcours_onboarding : son etat d'intention ne
-- venait que de public.intentions_horaire.
--
-- Ce que fait ce fichier, et rien d'autre : la vue dit « affectee » (et rend la
-- classe) pour un apprenant membre actif d'une classe non terminee, quelle que
-- soit son intention. Memes colonnes, memes types, meme ordre, memes droits,
-- toujours security_invoker (la RLS de groupe_membres et de groupes borne la
-- lecture au foyer, comme avant). Un membre sorti (left_at) ou une classe
-- terminee (ended_at) ne comptent pas. Pour un membre actif, l'offre retiree et
-- le changement de fuseau ne sont plus signales : ils ne le concernent plus.
-- Aucune donnee n'est ecrite ni modifiee ; la comparaison avec la production
-- n'a pas ete faite (pas de lecture en production cette nuit-la).
--
-- ATTENTION A L'INSTALLATION : CREATE OR REPLACE VIEW ecrase la definition de
-- production. AVANT d'installer, lire pg_get_viewdef('public.v_parcours_onboarding')
-- en production et la comparer a celle d'une base rejouee depuis le depot AVANT
-- ce fichier ; tout ecart autre que la mise en forme = ARRETER. Le preflight des
-- 22 colonnes ne voit que les noms et l'ordre, pas la definition.
--
-- Le choix de la classe est deterministe (entree la plus recente, puis
-- l'identifiant de la classe) ; l'index unique groupe_membres_actif_uidx interdit
-- deja deux adhesions actives pour un meme eleve, ce tri n'est qu'une ceinture.

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
    RAISE EXCEPTION 'PARCOURS-INSCRITS : vue, membres ou classes absents';
  END IF;
  SELECT pg_catalog.array_agg(k.column_name::text ORDER BY k.ordinal_position) INTO v_lues
    FROM information_schema.columns k
   WHERE k.table_schema = 'public' AND k.table_name = 'v_parcours_onboarding';
  IF v_lues IS DISTINCT FROM v_attendues THEN
    RAISE EXCEPTION 'PARCOURS-INSCRITS : colonnes de la vue inattendues (%), rien n''est change', v_lues;
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
  COALESCE(i.groupe_id, gm.groupe_id)             AS groupe_id,
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
    RAISE EXCEPTION 'PARCOURS-INSCRITS : la vue n''est plus security_invoker';
  END IF;
  IF pg_catalog.has_table_privilege('anon', 'public.v_parcours_onboarding', 'SELECT')
     OR NOT pg_catalog.has_table_privilege('authenticated', 'public.v_parcours_onboarding', 'SELECT') THEN
    RAISE EXCEPTION 'PARCOURS-INSCRITS : droits de la vue inattendus';
  END IF;
END
$postflight$;
