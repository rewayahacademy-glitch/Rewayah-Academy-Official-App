-- D1-bis, correctif (03/11/2026) : `public.concern_famille_v` en lecture seule,
-- et fermee aux mineurs.
--
-- DEUX FAILLES EN PRODUCTION depuis 20261106200000 (D1-bis), constatees le
-- 03/11 sur Postgres 17 nu avec toutes les migrations, et confirmees en
-- lecture en production par le pilote (aucun resume famille en production a
-- cette date : aucun degat).
--
-- 1. Ecriture par la vue. La vue porte sur une seule table : PostgreSQL la
--    rend modifiable automatiquement. `authenticated` y avait tous les droits
--    d'ecriture, et la vue s'execute avec les droits de son proprietaire, ce
--    qui contourne la RLS de `student_concern`. Un tuteur pouvait reecrire,
--    par la vue, le message transmis (une ligne modifiee), et le meme chemin
--    ouvrait le retrait de lignes. C'etait la seule vue de `public` modifiable
--    et ouverte en ecriture. Correctif : tous les droits retires, puis la
--    seule lecture rendue a `authenticated`.
-- 2. Lecture par un mineur. Le filtre lisait `public.est_du_foyer(student_id)`,
--    vrai pour TOUT profil du foyer : un enfant connecte (jeton `student` du
--    foyer) lisait ses messages et ceux de ses freres et soeurs, alors que le
--    resume est ecrit pour la famille. Correctif : la vue est recreee par
--    CREATE OR REPLACE (memes colonnes, meme `security_barrier`) avec trois
--    lecteurs seulement : un tuteur du foyer de l'eleve (role du jeton), le
--    titulaire du foyer (`households.primary_guardian_id`), et l'eleve lui-meme
--    s'il est adulte (`student_profiles.student_type = 'autonomous'`).
--    Inchange : transmis, avec un message pour la famille, jamais
--    « securite d'un enfant ».
--
-- Sans BEGIN ni COMMIT de premier niveau (consigne du pilote, 03/11).
-- Lecteurs (B1) : aucun ecran ni fonction ne lit ni n'ecrit par cette vue ;
-- les scenarios `scenarios_pe_protection_enfants` et
-- `scenarios_d1bis_traiter_signalement` la lisent sous un jeton de tuteur,
-- toujours admis.
-- Mots d'effacement dans ce fichier : aucun.

CREATE OR REPLACE VIEW public.concern_famille_v
WITH (security_barrier = true)
AS
SELECT c.id, c.categorie, c.family_summary, c.transmis_le, c.transmis_a
  FROM public.student_concern c
 WHERE c.transmis_le IS NOT NULL
   AND c.family_summary IS NOT NULL
   AND c.categorie::text <> 'securite_enfant'
   AND (
     -- Un tuteur du foyer de l'eleve.
     (public.app_role() = 'guardian' AND public.est_du_foyer(c.student_id))
     -- Le titulaire du foyer de l'eleve.
     OR EXISTS (SELECT 1 FROM public.profiles p
                  JOIN public.households h ON h.id = p.household_id AND h.deleted_at IS NULL
                 WHERE p.id = c.student_id AND h.primary_guardian_id = auth.uid())
     -- L'eleve lui-meme, s'il est adulte ; jamais un mineur.
     OR (c.student_id = auth.uid()
         AND EXISTS (SELECT 1 FROM public.student_profiles sp
                      WHERE sp.profile_id = c.student_id AND sp.deleted_at IS NULL
                        AND sp.student_type = 'autonomous')));

REVOKE ALL ON public.concern_famille_v FROM PUBLIC, anon, authenticated;
DO $agent_ro$
BEGIN
  IF EXISTS (SELECT 1 FROM pg_catalog.pg_roles WHERE rolname = 'agent_ro') THEN
    EXECUTE 'REVOKE ALL ON public.concern_famille_v FROM agent_ro';
  END IF;
END;
$agent_ro$;
GRANT SELECT ON public.concern_famille_v TO authenticated;

COMMENT ON VIEW public.concern_famille_v IS
  'D1-bis (03/11/2026, correctif 20261107100000) : ce que la direction a transmis a la famille d''un eleve (le resume seul, jamais la note interne, jamais la securite d''un enfant), lu par un tuteur du foyer, son titulaire ou l''eleve adulte lui-meme ; jamais un mineur. Lecture seule pour authenticated.';

DO $postflight$
DECLARE
  v_def text := pg_catalog.pg_get_viewdef('public.concern_famille_v'::regclass, true);
BEGIN
  -- Aucun droit d'ecriture (ni aucun autre que la lecture) ne reste, pour
  -- personne parmi PUBLIC, anon, authenticated, agent_ro. Lu dans
  -- information_schema.role_table_grants, qui couvre tous les droits sans
  -- les nommer un par un.
  IF NOT pg_catalog.has_table_privilege('authenticated', 'public.concern_famille_v', 'SELECT')
     OR pg_catalog.has_table_privilege('authenticated', 'public.concern_famille_v', 'UPDATE')
     OR pg_catalog.has_table_privilege('authenticated', 'public.concern_famille_v', 'INSERT')
     OR EXISTS (SELECT 1 FROM information_schema.role_table_grants g
                 WHERE g.table_schema = 'public' AND g.table_name = 'concern_famille_v'
                   AND g.grantee IN ('PUBLIC', 'anon', 'authenticated', 'agent_ro')
                   AND NOT (g.grantee = 'authenticated' AND g.privilege_type = 'SELECT')) THEN
    RAISE EXCEPTION 'D1-bis correctif : concern_famille_v garde un droit d''ecriture';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_catalog.pg_class c
                  WHERE c.oid = 'public.concern_famille_v'::regclass
                    AND c.reloptions @> ARRAY['security_barrier=true']) THEN
    RAISE EXCEPTION 'D1-bis correctif : security_barrier perdu';
  END IF;
  IF pg_catalog.strpos(v_def, 'autonomous') = 0
     OR pg_catalog.strpos(v_def, 'primary_guardian_id') = 0
     OR pg_catalog.strpos(v_def, 'securite_enfant') = 0
     OR pg_catalog.strpos(v_def, 'transmis_le IS NOT NULL') = 0 THEN
    RAISE EXCEPTION 'D1-bis correctif : filtre de concern_famille_v incomplet : %', v_def;
  END IF;
END;
$postflight$;
