-- D1-ter (03/11/2026) : la famille lit ce qui lui est transmis.
--
-- Fichier SANS mot d'effacement (B5) : le pilote l'installe. Additif (B6).
--
-- 1. `public.concern_famille_v` (D1-bis, 20261106200000, fondee sur
--    `transmis_le`) gagne une colonne, `student_id`, en DERNIERE position
--    (CREATE OR REPLACE VIEW n'admet qu'un ajout en fin). Sans elle, l'ecran ne
--    peut pas ranger un message sous l'enfant qu'il concerne quand le foyer en
--    compte plusieurs. Le filtre ne change pas : transmis, avec un message pour
--    la famille, jamais « securite d'un enfant », et seulement pour le foyer de
--    l'eleve ou l'eleve lui-meme.
-- 2. FAILLE CORRIGEE (constatee le 03/11 sur Postgres 17 nu, toutes les
--    migrations) : la vue, sur une seule table, est modifiable automatiquement
--    par PostgreSQL ; `authenticated` y avait tous les droits d'ecriture, et la
--    vue s'execute avec les droits de son proprietaire (contourne la RLS de
--    `student_concern`). Un tuteur pouvait reecrire, par la vue, le message que
--    la direction lui avait transmis. Desormais : tous les droits retires, puis
--    la seule lecture rendue a `authenticated`. C'etait la seule vue
--    modifiable de `public` (information_schema.views, is_updatable).
--
-- 3. FUITE AUX MINEURS CORRIGEE : `public.est_du_foyer(id)` est vrai pour tout
--    profil du foyer, l'enfant connecte compris ; il lisait ses messages et
--    ceux de ses freres et soeurs. La vue n'admet plus que trois lecteurs :
--    un tuteur du foyer de l'eleve (role du jeton), le titulaire du foyer
--    (`households.primary_guardian_id`), et l'eleve lui-meme s'il est adulte
--    (`student_profiles.student_type = 'autonomous'`). Un mineur ne lit rien :
--    le resume est ecrit pour la famille, pas pour l'enfant (garde-cap, 03/11).
-- 4. `public.transmettre_student_concern` (meme signature) previent, apres la
--    transmission, un seul destinataire choisi ici, jamais par le client : le
--    titulaire du foyer (cible `tuteur_du_mineur`, vers `/tuteur/suivi`) ou
--    l'eleve adulte (cible `eleve_adulte`, vers `/eleve/suivi`). Evenement
--    `message_academie_eleve` ; params : l'eleve et son prenom, JAMAIS le
--    resume. Application seulement (DECISION-NOTIFICATIONS-COURRIEL du 01/11 :
--    aucun e-mail par defaut). L'evenement et les deux destinations entrent
--    dans les contraintes par 20261106600001 (B5), a installer AVANT ce
--    fichier ; ce fichier n'insere aucune notification a l'installation.
--
-- Securite d'un enfant : rien du tout pour la famille, ni carte, ni resume, ni
-- notification. Regle existante : `concern_famille_v` exclut
-- `securite_enfant`, et D1-bis interdit de rediger un resume ou de transmettre
-- un tel signalement.
--
-- Lecteurs de `concern_famille_v` (B1) : les scenarios
-- `scenarios_pe_protection_enfants`, `scenarios_d1bis_traiter_signalement`
-- (lisent `id`, `family_summary` par nom : la colonne ajoutee ne les change
-- pas), et l'ecran de ce lot (`lib/core/suivi/messages_academie_supabase.dart`).
-- Mots d'effacement dans ce fichier : aucun.
BEGIN;

CREATE OR REPLACE VIEW public.concern_famille_v
WITH (security_barrier = true)
AS
SELECT c.id, c.categorie, c.family_summary, c.transmis_le, c.transmis_a,
       -- D1-ter : l'enfant concerne, pour ranger le message sous lui.
       c.student_id
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

REVOKE ALL ON public.concern_famille_v FROM PUBLIC, anon, authenticated, agent_ro;
GRANT SELECT ON public.concern_famille_v TO authenticated;

CREATE OR REPLACE FUNCTION pg_temp.remplacer(p_f pg_catalog.regprocedure, p_avant text, p_apres text, p_n integer)
RETURNS void
LANGUAGE plpgsql
AS $function$
DECLARE
  v_def text := pg_catalog.pg_get_functiondef(p_f);
  v_n integer;
BEGIN
  v_n := (pg_catalog.length(v_def)
          - pg_catalog.length(pg_catalog.replace(v_def, p_avant, '')))
         / pg_catalog.length(p_avant);
  IF v_n <> p_n THEN
    RAISE EXCEPTION '% : passage trouve % fois au lieu de %, migration a revoir : %',
      p_f, v_n, p_n, pg_catalog.left(p_avant, 120);
  END IF;
  EXECUTE pg_catalog.replace(v_def, p_avant, p_apres);
END;
$function$;

-- La transmission previent son destinataire (une ancre, la fin du journal).
SELECT pg_temp.remplacer('public.transmettre_student_concern(uuid,text)',
  $a$    pg_catalog.jsonb_build_object('student_id', v_student_id, 'cible', p_cible)
  );
END;$a$,
  $b$    pg_catalog.jsonb_build_object('student_id', v_student_id, 'cible', p_cible)
  );

  -- D1-ter (03/11/2026) : un seul destinataire, choisi ici, jamais par le
  -- client ; le prenom de l'eleve, jamais le resume.
  INSERT INTO public.notifications (destinataire, foyer_id, evenement, params, destination)
  SELECT d.qui, p.household_id, 'message_academie_eleve',
         pg_catalog.jsonb_build_object('eleve_id', v_student_id, 'prenom', p.first_name,
                                       'portee', d.portee),
         d.chemin
    FROM public.profiles p
    LEFT JOIN public.households h ON h.id = p.household_id AND h.deleted_at IS NULL
    CROSS JOIN LATERAL (
      SELECT CASE WHEN p_cible = 'eleve_adulte' THEN p.id ELSE h.primary_guardian_id END AS qui,
             CASE WHEN p_cible = 'eleve_adulte' THEN 'soi' ELSE 'foyer' END AS portee,
             CASE WHEN p_cible = 'eleve_adulte' THEN '/eleve/suivi' ELSE '/tuteur/suivi' END AS chemin) d
   WHERE p.id = v_student_id AND d.qui IS NOT NULL;
END;$b$, 1);

COMMENT ON VIEW public.concern_famille_v IS
  'D1-bis puis D1-ter (03/11/2026) : ce que la direction a transmis a la famille d''un eleve (le resume seul, jamais la note interne, jamais la securite d''un enfant), lu par le foyer ou l''eleve. Lecture seule pour authenticated.';

DO $postflight$
DECLARE
  v_def text := pg_catalog.pg_get_viewdef('public.concern_famille_v'::regclass, true);
BEGIN
  IF pg_catalog.strpos(v_def, 'student_id') = 0
     OR pg_catalog.strpos(v_def, 'securite_enfant') = 0
     OR pg_catalog.strpos(v_def, 'transmis_le IS NOT NULL') = 0
     OR pg_catalog.strpos(v_def, 'family_summary IS NOT NULL') = 0
     OR pg_catalog.strpos(v_def, 'est_du_foyer') = 0 THEN
    RAISE EXCEPTION 'D1-ter : concern_famille_v incomplete : %', v_def;
  END IF;
  IF NOT pg_catalog.has_table_privilege('authenticated', 'public.concern_famille_v', 'SELECT')
     -- Aucun autre droit que la lecture pour authenticated.
     OR EXISTS (SELECT 1 FROM information_schema.role_table_grants g
                 WHERE g.table_schema = 'public' AND g.table_name = 'concern_famille_v'
                   AND g.grantee = 'authenticated' AND g.privilege_type <> 'SELECT')
     OR pg_catalog.has_table_privilege('anon', 'public.concern_famille_v', 'SELECT')
     OR pg_catalog.has_table_privilege('agent_ro', 'public.concern_famille_v', 'SELECT') THEN
    RAISE EXCEPTION 'D1-ter : droits de concern_famille_v invalides';
  END IF;
  IF pg_catalog.strpos(v_def, 'autonomous') = 0 OR pg_catalog.strpos(v_def, 'primary_guardian_id') = 0 THEN
    RAISE EXCEPTION 'D1-ter : concern_famille_v ouverte aux mineurs';
  END IF;
  IF pg_catalog.strpos(pg_catalog.pg_get_functiondef('public.transmettre_student_concern(uuid,text)'::regprocedure),
       'message_academie_eleve') = 0
     OR NOT EXISTS (SELECT 1 FROM pg_catalog.pg_proc p
                     WHERE p.oid = 'public.transmettre_student_concern(uuid,text)'::regprocedure
                       AND p.prosecdef AND p.proconfig @> ARRAY['search_path=""']) THEN
    RAISE EXCEPTION 'D1-ter : transmettre_student_concern incomplete';
  END IF;
  IF pg_catalog.strpos(
       (SELECT pg_catalog.pg_get_constraintdef(c.oid) FROM pg_catalog.pg_constraint c
         WHERE c.conrelid = 'public.notifications'::regclass
           AND c.conname = 'notifications_evenement_check'),
       '''message_academie_eleve''') = 0 THEN
    RAISE WARNING 'D1-ter : notifications_evenement_check ne connait pas message_academie_eleve ; installer 20261106600001';
  END IF;
END;
$postflight$;

COMMIT;
