-- PARTAGE-GENERIQUE (directeur, 11/11/2026 ; CAHIER-SALLE §7) : la page de
-- reprise d'un support qui n'est pas le Coran, par Classe ET par support.
--
-- BROUILLON NON APPLIQUE (11/11/2026). Ni staging ni production. A relire par
-- le garde-cap, a installer par le pilote sur decision du directeur.
--
-- Fichier SANS mot d'effacement (B5) : aucune des trois instructions
-- interdites n'y figure. Un comptage brut des trois mots trouve seulement le
-- nom de la colonne lue `deleted_at` (un nom de colonne, jamais une
-- instruction). Migration additive (B6) : une table neuve et deux fonctions
-- neuves ; aucune fonction existante n'est retouchee (B4 sans objet), aucune
-- colonne existante ne change de sens (B1 sans objet).
--
-- Pourquoi une table neuve plutot que l'elargissement de la contrainte
-- `support = 'mushaf'` de `classe_position_reprise` (20261110100000) :
--   1. cette table a UNE ligne par Classe (cle primaire `groupe_id`). Avec une
--      contrainte elargie, partager le livre des lettres ecraserait la page du
--      Coran de la Classe, et « On reprend page 14 » (le Coran) disparaitrait
--      des que l'enseignant ouvre un autre livre. Il faut une page par Classe
--      ET par support ;
--   2. elargir une contrainte, c'est la retirer puis la reposer : un mot
--      d'effacement, donc une page a coller par le directeur. Une table neuve
--      n'en demande aucun ;
--   3. les trois fonctions du Coran et leurs lecteurs (salle, preparation de
--      seance, cahier de transmission) restent exactement ce qu'ils sont.
-- Le Coran reste dans `classe_position_reprise`. Cette table-ci ne porte
-- jamais le Coran (sa contrainte refuse les deux identifiants du Coran).
--
-- Qui ecrit, qui lit : les memes regles que CAHIER-C1, par les memes gardes.
--   Ecrire : SEUL l'enseignant effectif de la seance
--   (`private.c29_enseignant_effectif_session`), de 60 minutes avant le debut
--   a 60 minutes apres la fin.
--   Lire : la direction, le titulaire de la Classe, l'enseignant effectif
--   d'une seance de la Classe pas encore passee de plus d'un jour
--   (`private.cahier_c1_peut_lire_classe`).
-- Aucun droit n'est elargi : l'eleve et sa famille ne lisent ni n'ecrivent.
--
-- L'identifiant du support est un texte : celui que la salle fait voyager
-- dans son message de presentation. Quand les supports reels existeront dans
-- la Bibliotheque (`library_resource`), ce sera l'identifiant de la
-- ressource ; une cle etrangere pourra alors s'ajouter (decision a prendre
-- avec le directeur, pas ici : 0 support en production le 11/11/2026).
--
-- Lecteurs recenses (B1) : aucun lecteur existant, la table est neuve.
-- Dart : `lib/features/salle/reprise_support_supabase.dart` seul. Tant que ce
-- fichier n'est pas installe, l'application recoit « fonction absente » et dit
-- a l'enseignant, par une phrase, que la page n'est pas encore retenue d'une
-- seance a l'autre.
--
-- Preflight a calibrer par le pilote avant l'installation : existence de
-- `private.c29_enseignant_effectif_session(uuid)`,
-- `private.cahier_c1_peut_lire_classe(uuid)`, `public.app_account_valid()`,
-- `public.app_role()` (verifiee ci-dessous, sans md5 : a ajouter en
-- production).

BEGIN;

-- ---------------------------------------------------------------------------
-- 0. Preflight : les gardes reutilisees existent
-- ---------------------------------------------------------------------------
DO $preflight$
BEGIN
  IF pg_catalog.to_regprocedure('private.c29_enseignant_effectif_session(uuid)') IS NULL
     OR pg_catalog.to_regprocedure('private.cahier_c1_peut_lire_classe(uuid)') IS NULL
     OR pg_catalog.to_regprocedure('public.app_account_valid()') IS NULL
     OR pg_catalog.to_regprocedure('public.app_role()') IS NULL
  THEN
    RAISE EXCEPTION 'PARTAGE-GENERIQUE : une garde reutilisee est absente';
  END IF;
END;
$preflight$;

-- ---------------------------------------------------------------------------
-- 1. La table : une ligne par Classe et par support, l'etat courant
-- ---------------------------------------------------------------------------
CREATE TABLE public.classe_position_support (
  groupe_id     uuid NOT NULL REFERENCES public.groupes(id),
  support       text NOT NULL
                  CHECK (pg_catalog.char_length(support) BETWEEN 1 AND 120
                         AND support NOT IN ('mushaf', 'mushaf-madina-15')),
  version       text NOT NULL
                  CHECK (pg_catalog.char_length(version) BETWEEN 1 AND 120),
  page          integer NOT NULL CHECK (page >= 1),
  pages         integer NOT NULL CHECK (pages >= 1 AND pages <= 5000),
  session_id    uuid NOT NULL REFERENCES public.sessions(id),
  presentee_par uuid NOT NULL REFERENCES public.profiles(id),
  presentee_le  timestamptz NOT NULL DEFAULT pg_catalog.now(),
  PRIMARY KEY (groupe_id, support),
  CHECK (page <= pages)
);

COMMENT ON TABLE public.classe_position_support IS
  'PARTAGE-GENERIQUE (11/11/2026) : la derniere page presentee dans la salle, par '
  'Classe et par support, pour tout support qui n''est pas le Coran (le Coran reste '
  'dans classe_position_reprise). Ecrite par enregistrer_position_support, lue par '
  'positions_reprise_supports_seance. Aucun acces direct.';

ALTER TABLE public.classe_position_support ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON public.classe_position_support FROM PUBLIC, anon, authenticated;
-- Aucune politique : ni lecture ni ecriture directes. Tout passe par les
-- fonctions ci-dessous, qui portent leur garde.

-- ---------------------------------------------------------------------------
-- 2. L'ecriture : la page presentee, par l'enseignant effectif de la seance
-- ---------------------------------------------------------------------------
CREATE FUNCTION public.enregistrer_position_support(
  p_session_id uuid,
  p_support text,
  p_version text,
  p_page integer,
  p_pages integer
)
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

  IF p_support IS NULL
     OR pg_catalog.char_length(p_support) NOT BETWEEN 1 AND 120
     OR p_support IN ('mushaf', 'mushaf-madina-15')
     OR p_version IS NULL
     OR pg_catalog.char_length(p_version) NOT BETWEEN 1 AND 120
  THEN
    RAISE EXCEPTION 'support inattendu' USING errcode = '22023';
  END IF;

  IF p_page IS NULL OR p_pages IS NULL
     OR p_pages < 1 OR p_pages > 5000
     OR p_page < 1 OR p_page > p_pages
  THEN
    RAISE EXCEPTION 'page hors du support' USING errcode = '22023';
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

  INSERT INTO public.classe_position_support AS c
    (groupe_id, support, version, page, pages, session_id, presentee_par,
     presentee_le)
  VALUES
    (v_seance.groupe_id, p_support, p_version, p_page, p_pages, p_session_id,
     auth.uid(), pg_catalog.now())
  ON CONFLICT (groupe_id, support) DO UPDATE
    SET version = excluded.version,
        page = excluded.page,
        pages = excluded.pages,
        session_id = excluded.session_id,
        presentee_par = excluded.presentee_par,
        presentee_le = excluded.presentee_le
    WHERE c.presentee_le <= excluded.presentee_le;
END;
$function$;

COMMENT ON FUNCTION public.enregistrer_position_support(uuid, text, text, integer, integer) IS
  'PARTAGE-GENERIQUE (11/11/2026) : retient la page presentee d''un support (hors '
  'Coran) pour la Classe de la seance. Seul l''enseignant effectif (C-29) ecrit, de '
  '60 min avant le debut a 60 min apres la fin. 42501 sinon.';

-- ---------------------------------------------------------------------------
-- 3. La lecture : les pages retenues de la Classe d'une seance
-- ---------------------------------------------------------------------------
CREATE FUNCTION public.positions_reprise_supports_seance(p_session_id uuid)
RETURNS TABLE (
  support text,
  version text,
  page integer,
  pages integer,
  presentee_le timestamptz
)
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
    SELECT c.support, c.version, c.page, c.pages, c.presentee_le
      FROM public.classe_position_support c
     WHERE c.groupe_id = v_groupe;
END;
$function$;

COMMENT ON FUNCTION public.positions_reprise_supports_seance(uuid) IS
  'PARTAGE-GENERIQUE (11/11/2026) : les pages de reprise des supports (hors Coran) de '
  'la Classe d''une seance. Memes droits que position_reprise_seance. 42501 sinon.';

-- ---------------------------------------------------------------------------
-- 4. Droits (deux chemins : PUBLIC et anon)
-- ---------------------------------------------------------------------------
REVOKE ALL ON FUNCTION public.enregistrer_position_support(uuid, text, text, integer, integer)
  FROM PUBLIC, anon, service_role, agent_ro;
REVOKE ALL ON FUNCTION public.positions_reprise_supports_seance(uuid)
  FROM PUBLIC, anon, service_role, agent_ro;
GRANT EXECUTE ON FUNCTION public.enregistrer_position_support(uuid, text, text, integer, integer)
  TO authenticated;
GRANT EXECUTE ON FUNCTION public.positions_reprise_supports_seance(uuid) TO authenticated;

-- ---------------------------------------------------------------------------
-- 5. Postflight
-- ---------------------------------------------------------------------------
DO $postflight$
BEGIN
  IF NOT (SELECT c.relrowsecurity FROM pg_catalog.pg_class c
           WHERE c.oid = 'public.classe_position_support'::regclass) THEN
    RAISE EXCEPTION 'PARTAGE-GENERIQUE : RLS absente sur classe_position_support';
  END IF;
  IF pg_catalog.has_table_privilege('authenticated', 'public.classe_position_support', 'SELECT')
     OR pg_catalog.has_table_privilege('anon', 'public.classe_position_support', 'SELECT')
     OR pg_catalog.has_table_privilege('authenticated', 'public.classe_position_support', 'INSERT')
  THEN
    RAISE EXCEPTION 'PARTAGE-GENERIQUE : acces direct ouvert sur classe_position_support';
  END IF;
  IF pg_catalog.has_function_privilege(
       'anon', 'public.enregistrer_position_support(uuid, text, text, integer, integer)', 'EXECUTE')
     OR pg_catalog.has_function_privilege(
       'anon', 'public.positions_reprise_supports_seance(uuid)', 'EXECUTE')
     OR NOT pg_catalog.has_function_privilege(
       'authenticated', 'public.enregistrer_position_support(uuid, text, text, integer, integer)', 'EXECUTE')
     OR NOT pg_catalog.has_function_privilege(
       'authenticated', 'public.positions_reprise_supports_seance(uuid)', 'EXECUTE')
  THEN
    RAISE EXCEPTION 'PARTAGE-GENERIQUE : droits des fonctions incorrects';
  END IF;
END;
$postflight$;

COMMIT;
