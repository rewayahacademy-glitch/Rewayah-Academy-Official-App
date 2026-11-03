-- COURRIELS-UX (rang 18 de PLAN-LOTS, garde-cap, 03/11/2026) : UX-026 et FN-108.
--
-- Constat (captures/E2E/courriels/exemplaires.md, 31/10/2026) :
--   * UX-026 : aucun e-mail de classe ne nomme la classe ni l'enfant ; « La
--     seance du 22 novembre 2026 a 10:00 est annulee » ne dit pas dans quel
--     fuseau est cette heure ; « Votre classe est creee » ne dit ni laquelle
--     ni quand ;
--   * FN-108 : « Un eleve rejoint votre classe », ecrit pour l'enseignant,
--     part a la famille. Depuis la decision du 01/11/2026
--     (DECISION-NOTIFICATIONS-COURRIEL), `eleve_inscrit` ne part par e-mail
--     qu'a l'eleve et a sa famille (portees `soi` et `foyer`) et
--     `enseignant_affecte` ne part plus par e-mail a personne : la cible des
--     e-mails est deja juste, c'est le texte qui ne l'etait pas. Le texte
--     suit desormais la portee (supabase/functions/_shared/courriel/).
--
-- Ce que cette migration change, et rien d'autre : private.notifier_classe
-- (20261027120000, seule definition jusqu'ici) pose quatre informations de
-- plus dans `params`, lues par les modeles d'e-mail :
--   * `classe` : le nom de la classe (`groupes.libelle`) ;
--   * `eleves` : pour la portee `foyer`, les prenoms des eleves de ce foyer
--     concernes par le fait (un tuteur dont deux enfants sont dans la classe
--     recoit une seule ligne, avec les deux prenoms) ;
--   * `fuseau` : le fuseau IANA dans lequel `debut_local` et
--     `prochaine_local` sont ecrits (celui du foyer, de l'enseignant, sinon
--     de la classe, comme avant) ;
--   * `prochaine_local` : pour `classe_creee` et `eleve_inscrit`, le debut de
--     la prochaine seance prevue de la classe, dans ce meme fuseau.
-- Les cles existantes, les destinataires, les destinations, l'idempotence et
-- la regle « courriel ou application » (private.notification_courriel) ne
-- changent pas. Signature et droits identiques (CREATE OR REPLACE).
--
-- Donnees personnelles : seul le prenom d'un enfant part, et seulement vers
-- les tuteurs de son propre foyer (portee `foyer`), qui le voient deja dans
-- l'application ; rien de plus pour l'enseignant (portee `classe`).
--
-- FICHIER SANS EFFACEMENT (regle B5) : une fonction remplacee a l'identique
-- de signature ; aucune table, ligne, contrainte ni declencheur retire.

BEGIN;

CREATE OR REPLACE FUNCTION private.notifier_classe(
  p_groupe_id uuid,
  p_evenement text,
  p_session uuid DEFAULT NULL,
  p_instant timestamptz DEFAULT NULL,
  p_eleves uuid[] DEFAULT NULL,
  p_enseignants uuid[] DEFAULT NULL,
  p_sans_enseignant boolean DEFAULT false
)
RETURNS integer
LANGUAGE plpgsql
VOLATILE
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  v_groupe public.groupes%ROWTYPE;
  v_equivalents text[];
  v_prochaine timestamptz;
  v_n integer;
BEGIN
  IF p_groupe_id IS NULL OR p_evenement IS NULL THEN
    RETURN 0;
  END IF;
  SELECT * INTO v_groupe FROM public.groupes g WHERE g.id = p_groupe_id;

  -- Les evenements d'un chemin plus ancien qui disent deja le meme fait.
  v_equivalents := CASE p_evenement
    WHEN 'classe_creee'       THEN ARRAY['classe_validee', 'classe_changee']
    WHEN 'eleve_inscrit'      THEN ARRAY['classe_creee', 'classe_validee', 'classe_changee']
    WHEN 'eleve_retire'       THEN ARRAY['classe_changee', 'classe_supprimee']
    WHEN 'creneau_change'     THEN ARRAY['classe_creee', 'classe_validee']
    WHEN 'seance_annulee'     THEN ARRAY['classe_supprimee', 'classe_changee']
    WHEN 'enseignante_absente' THEN ARRAY['remplacement_propose']
    WHEN 'classe_supprimee'   THEN ARRAY['classe_changee']
    ELSE ARRAY[]::text[]
  END;

  -- COURRIELS-UX : une classe creee, ou un eleve qui la rejoint, se dit avec
  -- sa prochaine seance prevue (les declencheurs sont differes : les seances
  -- materialisees dans la meme transaction sont deja la).
  IF p_instant IS NULL AND p_evenement IN ('classe_creee', 'eleve_inscrit') THEN
    SELECT pg_catalog.min(s.started_at) INTO v_prochaine
      FROM public.sessions s
     WHERE s.groupe_id = p_groupe_id
       AND s.deleted_at IS NULL
       AND s.status = 'planned'
       AND s.started_at > pg_catalog.now();
  END IF;

  WITH eleves AS (
    SELECT gm.student_id
      FROM public.groupe_membres gm
     WHERE gm.groupe_id = p_groupe_id
       AND p_eleves IS NULL
       AND (gm.left_at IS NULL
            -- Une classe fermee : ses membres sortent dans la meme
            -- transaction (cloturer_groupe) ; ils sont prevenus.
            OR (p_evenement = 'classe_supprimee' AND gm.left_at >= pg_catalog.now()))
    UNION
    SELECT e FROM pg_catalog.unnest(coalesce(p_eleves, ARRAY[]::uuid[])) AS e
  ),
  personnes AS (
    -- L'eleve lui-meme.
    SELECT p.id AS destinataire, p.household_id AS foyer, 'soi'::text AS portee,
           h.timezone AS fuseau, 1 AS rang, p.first_name AS prenom
      FROM eleves e
      JOIN public.profiles p ON p.id = e.student_id AND p.deleted_at IS NULL
      LEFT JOIN public.households h ON h.id = p.household_id
    UNION ALL
    -- Les tuteurs de son foyer.
    SELECT t.id, p.household_id, 'foyer', h.timezone, 2, p.first_name
      FROM eleves e
      JOIN public.profiles p ON p.id = e.student_id AND p.deleted_at IS NULL
      JOIN public.households h ON h.id = p.household_id AND h.deleted_at IS NULL
      JOIN public.profiles t ON t.deleted_at IS NULL
                            AND t.role = 'guardian'
                            AND (t.id = h.primary_guardian_id OR t.household_id = h.id)
     WHERE t.id <> e.student_id
    UNION ALL
    -- L'enseignante de la classe, et celles donnees (l'ancienne).
    SELECT x.id, NULL::uuid, 'classe', coalesce(tp.timezone_iana, v_groupe.timezone_iana), 3, NULL::text
      FROM (SELECT v_groupe.teacher_id AS id
            UNION
            SELECT e FROM pg_catalog.unnest(coalesce(p_enseignants, ARRAY[]::uuid[])) AS e) x
      JOIN public.profiles p ON p.id = x.id AND p.deleted_at IS NULL
      LEFT JOIN public.teacher_profiles tp ON tp.profile_id = x.id
     WHERE NOT p_sans_enseignant
  ),
  destinataires AS (
    -- Une personne, une ligne : l'eleve avant le tuteur avant l'enseignante.
    SELECT DISTINCT ON (destinataire) destinataire, foyer, portee, fuseau
      FROM personnes
     ORDER BY destinataire, rang
  ),
  -- COURRIELS-UX : les prenoms des eleves concernes, pour un tuteur seulement.
  prenoms AS (
    SELECT x.destinataire,
           pg_catalog.jsonb_agg(DISTINCT x.prenom ORDER BY x.prenom) AS eleves
      FROM personnes x
      JOIN destinataires d ON d.destinataire = x.destinataire AND d.portee = x.portee
     WHERE x.portee = 'foyer' AND x.prenom IS NOT NULL AND pg_catalog.btrim(x.prenom) <> ''
     GROUP BY x.destinataire
  )
  INSERT INTO public.notifications (destinataire, foyer_id, evenement, params, destination)
  SELECT d.destinataire, d.foyer, p_evenement,
         pg_catalog.jsonb_strip_nulls(pg_catalog.jsonb_build_object(
           'groupe_id', p_groupe_id,
           'session_id', p_session,
           'portee', d.portee,
           'debut_local', CASE WHEN p_instant IS NULL THEN NULL
                               ELSE pg_catalog.to_char(
                                 p_instant AT TIME ZONE coalesce(d.fuseau, v_groupe.timezone_iana, 'UTC'),
                                 'YYYY-MM-DD"T"HH24:MI:SS') END,
           'prochaine_local', CASE WHEN v_prochaine IS NULL THEN NULL
                                   ELSE pg_catalog.to_char(
                                     v_prochaine AT TIME ZONE coalesce(d.fuseau, v_groupe.timezone_iana, 'UTC'),
                                     'YYYY-MM-DD"T"HH24:MI:SS') END,
           'fuseau', CASE WHEN p_instant IS NULL AND v_prochaine IS NULL THEN NULL
                          ELSE coalesce(d.fuseau, v_groupe.timezone_iana, 'UTC') END,
           'classe', nullif(pg_catalog.btrim(v_groupe.libelle), ''),
           'eleves', pr.eleves)),
         CASE d.portee
           WHEN 'soi' THEN '/eleve'
           WHEN 'foyer' THEN
             CASE
               WHEN p_evenement IN ('eleve_retire', 'classe_supprimee') THEN '/tuteur'
               WHEN p_session IS NOT NULL THEN '/tuteur/classes/' || p_groupe_id::text || '/planning'
               ELSE '/tuteur/classes/' || p_groupe_id::text
             END
           ELSE
             CASE WHEN p_session IS NOT NULL THEN '/enseignant/journee'
                  ELSE '/enseignant/classes' END
         END
    FROM destinataires d
    LEFT JOIN prenoms pr ON pr.destinataire = d.destinataire
   WHERE NOT EXISTS (
     SELECT 1 FROM public.notifications n
      WHERE n.destinataire = d.destinataire
        AND n.cree_le = pg_catalog.now()
        AND (n.evenement = p_evenement OR n.evenement = ANY (v_equivalents))
        AND (n.params ->> 'groupe_id' IS NULL OR n.params ->> 'groupe_id' = p_groupe_id::text)
        AND (p_session IS NULL
             OR n.params ->> 'session_id' IS NULL
             OR n.params ->> 'session_id' = p_session::text)
   );
  GET DIAGNOSTICS v_n = ROW_COUNT;
  RETURN v_n;
END;
$function$;

-- Postflight ----------------------------------------------------------------
-- Aucun nombre ecrit en dur : on lit la fonction installee et ses droits.
DO $postflight$
DECLARE
  v_f pg_catalog.regprocedure :=
    'private.notifier_classe(uuid,text,uuid,timestamptz,uuid[],uuid[],boolean)'::pg_catalog.regprocedure;
  v_p record;
BEGIN
  SELECT p.prosrc, p.prosecdef, p.proconfig INTO v_p FROM pg_catalog.pg_proc p WHERE p.oid = v_f;
  IF NOT v_p.prosecdef OR NOT ('search_path=""' = ANY (v_p.proconfig)) THEN
    RAISE EXCEPTION 'COURRIELS-UX : notifier_classe doit rester SECURITY DEFINER, search_path vide';
  END IF;
  IF pg_catalog.strpos(v_p.prosrc, '''prochaine_local''') = 0
     OR pg_catalog.strpos(v_p.prosrc, '''fuseau''') = 0
     OR pg_catalog.strpos(v_p.prosrc, '''classe''') = 0
     OR pg_catalog.strpos(v_p.prosrc, '''eleves''') = 0 THEN
    RAISE EXCEPTION 'COURRIELS-UX : notifier_classe ne pose pas les quatre nouvelles cles';
  END IF;
  IF pg_catalog.has_function_privilege('anon', v_f, 'EXECUTE')
     OR pg_catalog.has_function_privilege('authenticated', v_f, 'EXECUTE') THEN
    RAISE EXCEPTION 'COURRIELS-UX : notifier_classe exposee a un role client';
  END IF;
END;
$postflight$;

COMMIT;
