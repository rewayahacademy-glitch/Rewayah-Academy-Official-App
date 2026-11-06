-- CAHIER-C1 (rang 22 e, ETUDE-CAHIER-2026-11.md §5) : la position de reprise
-- automatique d'une Classe.
--
-- Fichier SANS mot d'effacement (B5) : aucun des trois mots interdits n'y
-- figure ; le pilote l'installe (un comptage brut trouve trois fois la
-- colonne `deleted_at`, un nom de colonne lu, jamais une instruction). Migration additive (B6) : une table neuve et
-- trois fonctions neuves ; aucune fonction existante n'est retouchee (B4 sans
-- objet), aucune colonne existante ne change de sens (B1 sans objet).
--
-- Ce que fait le lot :
--   1. La salle enregistre au serveur la derniere page du Coran presentee,
--      une ligne par Classe (`classe_position_reprise`), a chaque changement
--      de page (`enregistrer_page_presentee`).
--   2. La preparation de seance la lit : par la Classe
--      (`position_reprise_classe`, fiche de la Classe) et par la seance
--      (`position_reprise_seance`, preparation d'entree dans la salle, qui
--      sert aussi le remplacant).
--
-- Qui ecrit : SEUL l'enseignant effectif de la seance
-- (`private.c29_enseignant_effectif_session`, C-29 : le remplacant quand la
-- seance est remplacee, sinon le titulaire), pendant la seance (de 60 minutes
-- avant son debut a 60 minutes apres sa fin). Le titulaire ecarte par un
-- remplacement n'ecrit pas ; la direction n'ecrit pas (elle n'enseigne pas).
--
-- Qui lit : la direction ; le titulaire de la Classe ; l'enseignant effectif
-- d'une seance de la Classe qui n'est pas encore passee de plus d'un jour
-- (le remplacant, avant et pendant la seance qui lui est confiee).
--
-- Pourquoi une table neuve plutot que `session_shared_content.group_resume_position`
-- (0032, relu le 06/11) : cette table est PAR SEANCE (cle `session_id`),
-- son etat est efface apres la cloture (`effacer_etat_partage`, 0060), et
-- elle exige une ressource de Bibliotheque (`resource_id` non nul, cle
-- etrangere vers `library_resource`) que le Coran de la salle n'a pas
-- (0 support en production le 05/11). La position d'une Classe doit
-- survivre a la seance et se relire a la seance suivante : une ligne par
-- Classe. `support` ne vaut que 'mushaf' aujourd'hui ; le livre de lecture
-- Rewayah (page et ligne) viendra avec C2, par une contrainte elargie.
--
-- Lecteurs recenses (B1) : aucun lecteur existant, la table est neuve.
-- Dart : `lib/features/salle/position_reprise_supabase.dart` seul.

BEGIN;

-- ---------------------------------------------------------------------------
-- 1. La table : une ligne par Classe, l'etat courant (pas un journal)
-- ---------------------------------------------------------------------------
CREATE TABLE public.classe_position_reprise (
  groupe_id     uuid PRIMARY KEY REFERENCES public.groupes(id),
  support       text NOT NULL DEFAULT 'mushaf' CHECK (support = 'mushaf'),
  page          smallint NOT NULL CHECK (page BETWEEN 1 AND 604),
  session_id    uuid NOT NULL REFERENCES public.sessions(id),
  presentee_par uuid NOT NULL REFERENCES public.profiles(id),
  presentee_le  timestamptz NOT NULL DEFAULT pg_catalog.now()
);

COMMENT ON TABLE public.classe_position_reprise IS
  'CAHIER-C1 (06/11/2026) : la derniere page presentee dans la salle, par Classe. '
  'Ecrite par enregistrer_page_presentee (enseignant effectif de la seance), lue '
  'par position_reprise_classe et position_reprise_seance. Aucun acces direct.';

ALTER TABLE public.classe_position_reprise ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON public.classe_position_reprise FROM PUBLIC, anon, authenticated;
-- Aucune politique : ni lecture ni ecriture directes. Tout passe par les
-- fonctions ci-dessous, qui portent leur garde.

-- ---------------------------------------------------------------------------
-- 2. L'ecriture : la page presentee, par l'enseignant effectif de la seance
-- ---------------------------------------------------------------------------
CREATE FUNCTION public.enregistrer_page_presentee(p_session_id uuid, p_page integer)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  v_seance public.sessions;
BEGIN
  IF NOT coalesce(
    public.app_account_valid()
    AND public.app_role() = 'teacher'
    AND private.c29_enseignant_effectif_session(p_session_id) = auth.uid(),
    false
  ) THEN
    RAISE EXCEPTION 'page presentee refusee' USING errcode = '42501';
  END IF;

  IF p_page IS NULL OR p_page < 1 OR p_page > 604 THEN
    RAISE EXCEPTION 'page hors du Coran' USING errcode = '22023';
  END IF;

  SELECT * INTO v_seance
    FROM public.sessions s
   WHERE s.id = p_session_id AND s.deleted_at IS NULL;

  IF v_seance.groupe_id IS NULL THEN
    RAISE EXCEPTION 'seance sans Classe' USING errcode = '22023';
  END IF;

  IF NOT coalesce(
    pg_catalog.now() BETWEEN v_seance.started_at - interval '60 minutes'
                         AND v_seance.ended_at + interval '60 minutes',
    false
  ) THEN
    RAISE EXCEPTION 'page presentee hors de la seance' USING errcode = '42501';
  END IF;

  INSERT INTO public.classe_position_reprise AS c
    (groupe_id, support, page, session_id, presentee_par, presentee_le)
  VALUES
    (v_seance.groupe_id, 'mushaf', p_page::smallint, p_session_id, auth.uid(),
     pg_catalog.now())
  ON CONFLICT (groupe_id) DO UPDATE
    SET support = excluded.support,
        page = excluded.page,
        session_id = excluded.session_id,
        presentee_par = excluded.presentee_par,
        presentee_le = excluded.presentee_le
    WHERE c.presentee_le <= excluded.presentee_le;
END;
$function$;

COMMENT ON FUNCTION public.enregistrer_page_presentee(uuid, integer) IS
  'CAHIER-C1 (06/11/2026) : retient la page du Coran presentee pour la Classe de la '
  'seance. Seul l''enseignant effectif (C-29 : le remplacant si la seance est '
  'remplacee) ecrit, de 60 min avant le debut a 60 min apres la fin. 42501 sinon.';

-- ---------------------------------------------------------------------------
-- 3. Les lectures
-- ---------------------------------------------------------------------------
-- Vrai quand l'appelant peut lire la position de la Classe [p_groupe_id].
CREATE FUNCTION private.cahier_c1_peut_lire_classe(p_groupe_id uuid)
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $function$
  SELECT coalesce(
    public.app_account_valid()
    AND (
      public.app_role() = 'admin'
      OR (
        public.app_role() = 'teacher'
        AND (
          EXISTS (SELECT 1 FROM public.groupes g
                   WHERE g.id = p_groupe_id AND g.teacher_id = auth.uid())
          OR EXISTS (
            SELECT 1 FROM public.sessions s
             WHERE s.groupe_id = p_groupe_id
               AND s.deleted_at IS NULL
               AND s.ended_at > pg_catalog.now() - interval '1 day'
               AND private.c29_enseignant_effectif_session(s.id) = auth.uid()
          )
        )
      )
    ),
    false
  );
$function$;

CREATE FUNCTION public.position_reprise_classe(p_groupe_id uuid)
RETURNS TABLE (page integer, presentee_le timestamptz)
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $function$
BEGIN
  IF NOT private.cahier_c1_peut_lire_classe(p_groupe_id) THEN
    RAISE EXCEPTION 'position de reprise refusee' USING errcode = '42501';
  END IF;
  RETURN QUERY
    SELECT c.page::integer, c.presentee_le
      FROM public.classe_position_reprise c
     WHERE c.groupe_id = p_groupe_id;
END;
$function$;

COMMENT ON FUNCTION public.position_reprise_classe(uuid) IS
  'CAHIER-C1 (06/11/2026) : la derniere page presentee dans la Classe (aucune ligne '
  'si rien n''a ete presente). Direction, titulaire, ou enseignant effectif d''une '
  'seance de la Classe pas encore passee de plus d''un jour. 42501 sinon.';

CREATE FUNCTION public.position_reprise_seance(p_session_id uuid)
RETURNS TABLE (page integer, presentee_le timestamptz)
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  v_groupe uuid;
BEGIN
  SELECT s.groupe_id INTO v_groupe
    FROM public.sessions s
   WHERE s.id = p_session_id AND s.deleted_at IS NULL;
  IF v_groupe IS NULL OR NOT private.cahier_c1_peut_lire_classe(v_groupe) THEN
    RAISE EXCEPTION 'position de reprise refusee' USING errcode = '42501';
  END IF;
  RETURN QUERY
    SELECT c.page::integer, c.presentee_le
      FROM public.classe_position_reprise c
     WHERE c.groupe_id = v_groupe;
END;
$function$;

COMMENT ON FUNCTION public.position_reprise_seance(uuid) IS
  'CAHIER-C1 (06/11/2026) : la position de reprise de la Classe d''une seance, pour '
  'la preparation d''entree dans la salle (le remplacant compris). Memes droits que '
  'position_reprise_classe. 42501 sinon.';

-- ---------------------------------------------------------------------------
-- 4. Droits (deux chemins : PUBLIC et anon)
-- ---------------------------------------------------------------------------
REVOKE ALL ON FUNCTION private.cahier_c1_peut_lire_classe(uuid)
  FROM PUBLIC, anon, authenticated, service_role, agent_ro;
REVOKE ALL ON FUNCTION public.enregistrer_page_presentee(uuid, integer)
  FROM PUBLIC, anon, service_role, agent_ro;
REVOKE ALL ON FUNCTION public.position_reprise_classe(uuid)
  FROM PUBLIC, anon, service_role, agent_ro;
REVOKE ALL ON FUNCTION public.position_reprise_seance(uuid)
  FROM PUBLIC, anon, service_role, agent_ro;
GRANT EXECUTE ON FUNCTION public.enregistrer_page_presentee(uuid, integer) TO authenticated;
GRANT EXECUTE ON FUNCTION public.position_reprise_classe(uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION public.position_reprise_seance(uuid) TO authenticated;

-- ---------------------------------------------------------------------------
-- 5. Postflight
-- ---------------------------------------------------------------------------
DO $postflight$
BEGIN
  IF NOT (SELECT c.relrowsecurity FROM pg_catalog.pg_class c
           WHERE c.oid = 'public.classe_position_reprise'::regclass) THEN
    RAISE EXCEPTION 'CAHIER-C1 : RLS absente sur classe_position_reprise';
  END IF;
  IF pg_catalog.has_table_privilege('authenticated', 'public.classe_position_reprise', 'SELECT')
     OR pg_catalog.has_table_privilege('anon', 'public.classe_position_reprise', 'SELECT')
     OR pg_catalog.has_table_privilege('authenticated', 'public.classe_position_reprise', 'INSERT')
  THEN
    RAISE EXCEPTION 'CAHIER-C1 : acces direct ouvert sur classe_position_reprise';
  END IF;
  IF pg_catalog.has_function_privilege('anon', 'public.enregistrer_page_presentee(uuid, integer)', 'EXECUTE')
     OR pg_catalog.has_function_privilege('anon', 'public.position_reprise_classe(uuid)', 'EXECUTE')
     OR pg_catalog.has_function_privilege('anon', 'public.position_reprise_seance(uuid)', 'EXECUTE')
     OR pg_catalog.has_function_privilege('authenticated', 'private.cahier_c1_peut_lire_classe(uuid)', 'EXECUTE')
     OR NOT pg_catalog.has_function_privilege('authenticated', 'public.enregistrer_page_presentee(uuid, integer)', 'EXECUTE')
  THEN
    RAISE EXCEPTION 'CAHIER-C1 : droits des fonctions incorrects';
  END IF;
END;
$postflight$;

COMMIT;
