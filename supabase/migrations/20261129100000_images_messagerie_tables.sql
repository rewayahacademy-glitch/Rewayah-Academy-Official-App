-- IMAGES-MESSAGERIE (16/11/2026), partie serveur, 1/5 : les deux tables et la
-- porte de participation.
--
--   * public.com_message_images : UNE image par message (miniature comprise),
--     deposee dans le seau de la messagerie (domaine R2 « pieceJointeMessage »,
--     secrets R2_MESSAGING_*, aucun seau ni secret nouveau). La ligne reste
--     apres l'expiration des 90 jours : seul le fichier part, l'etat passe a
--     « supprimee » pour que l'ecran dise « Image retiree apres 90 jours ».
--   * public.com_message_coeurs : un « J'aime » par personne et par message.
--     Retirer un coeur ne supprime pas la ligne : `retire_le` est pose, pour
--     qu'aucune migration ni fonction n'ait besoin d'un mot d'effacement.
--
-- FICHIER SANS MOT D'EFFACEMENT (compte : 0), sans BEGIN ni COMMIT de premier
-- niveau. Aucune ecriture directe par un client : les RPC des fichiers
-- suivants (SECURITY DEFINER, search_path vide) sont la seule voie d'ecriture.
-- S'installe apres 20261127000300 ; premier fichier de la serie.

-- 1. Participation ---------------------------------------------------------------
-- Les droits de l'appelant sur un fil, lus dans private.com_fil_json (la seule
-- definition de « qui lit, qui ecrit ») : un fil que com_fil_json ne rend pas
-- n'est pas lisible ; `peut_ecrire` y est la paire autorisee maintenant. Aucune
-- seconde copie de la regle : si elle change (candidat, acces paye), les images
-- et les coeurs la suivent.
CREATE OR REPLACE FUNCTION private.com_image_droits(
  p_fil_id uuid, OUT p_lire boolean, OUT p_ecrire boolean, OUT p_moi uuid)
LANGUAGE plpgsql STABLE SECURITY INVOKER SET search_path = '' AS $function$
DECLARE
  moi record;
  v_json jsonb;
BEGIN
  p_lire := false;
  p_ecrire := false;
  p_moi := NULL;
  IF p_fil_id IS NULL THEN RETURN; END IF;
  SELECT * INTO moi FROM private.com_appelant();
  IF moi.id IS NULL THEN RETURN; END IF;
  p_moi := moi.id;
  v_json := private.com_fil_json(p_fil_id, moi.id, moi.role, moi.foyer);
  IF v_json IS NULL THEN RETURN; END IF;
  p_lire := true;
  p_ecrire := coalesce((v_json ->> 'peut_ecrire')::boolean, false);
END;
$function$;

-- Le predicat des policies : l'appelant lit-il ce fil ? Public parce qu'une
-- policy s'evalue avec les droits du client, qui n'a pas acces au schema private.
CREATE OR REPLACE FUNCTION public.com_fil_lisible(p_fil_id uuid)
RETURNS boolean LANGUAGE sql STABLE SECURITY DEFINER SET search_path = '' AS $function$
  SELECT coalesce((SELECT d.p_lire FROM private.com_image_droits(p_fil_id) d), false);
$function$;

CREATE OR REPLACE FUNCTION public.com_message_lisible(p_message_id uuid)
RETURNS boolean LANGUAGE sql STABLE SECURITY DEFINER SET search_path = '' AS $function$
  SELECT coalesce((
    SELECT d.p_lire
      FROM public.com_messages m,
           LATERAL private.com_image_droits(m.fil_id) d
     WHERE m.id = p_message_id), false);
$function$;

REVOKE ALL ON FUNCTION private.com_image_droits(uuid) FROM PUBLIC, anon, authenticated, service_role;
REVOKE ALL ON FUNCTION public.com_fil_lisible(uuid), public.com_message_lisible(uuid)
  FROM PUBLIC, anon, service_role;
GRANT EXECUTE ON FUNCTION public.com_fil_lisible(uuid), public.com_message_lisible(uuid) TO authenticated;

-- 2. Les images ------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.com_message_images (
  id uuid PRIMARY KEY DEFAULT extensions.gen_random_uuid(),
  message_id uuid NOT NULL REFERENCES public.com_messages(id),
  fil_id uuid NOT NULL REFERENCES public.com_fils(id),
  auteur uuid NOT NULL REFERENCES public.profiles(id),
  cle_r2 text NOT NULL,
  cle_miniature text NOT NULL,
  mime text NOT NULL CHECK (mime IN ('image/jpeg', 'image/png', 'image/webp')),
  mime_miniature text NOT NULL CHECK (mime_miniature IN ('image/jpeg', 'image/png', 'image/webp')),
  largeur integer NOT NULL CHECK (largeur BETWEEN 1 AND 20000),
  hauteur integer NOT NULL CHECK (hauteur BETWEEN 1 AND 20000),
  octets bigint NOT NULL CHECK (octets BETWEEN 1 AND 2097152),
  octets_miniature bigint NOT NULL CHECK (octets_miniature BETWEEN 1 AND 102400),
  couleur_moyenne text CHECK (couleur_moyenne IS NULL OR couleur_moyenne ~ '^#[0-9a-f]{6}$'),
  cree_le timestamptz NOT NULL DEFAULT pg_catalog.clock_timestamp(),
  expire_le timestamptz NOT NULL DEFAULT (pg_catalog.clock_timestamp() + interval '90 days'),
  supprimee_le timestamptz,
  etat text NOT NULL DEFAULT 'en_attente' CHECK (etat IN ('en_attente', 'confirmee', 'supprimee')),
  CONSTRAINT com_message_images_un_par_message UNIQUE (message_id),
  CONSTRAINT com_message_images_suppression_dite CHECK ((etat = 'supprimee') = (supprimee_le IS NOT NULL)),
  CONSTRAINT com_message_images_cle_fil CHECK (
    cle_r2 LIKE 'fils/' || fil_id::text || '/%' AND cle_miniature LIKE 'fils/' || fil_id::text || '/%')
);
CREATE INDEX IF NOT EXISTS com_message_images_fil_idx
  ON public.com_message_images (fil_id, cree_le DESC);
CREATE INDEX IF NOT EXISTS com_message_images_auteur_idx
  ON public.com_message_images (auteur, cree_le DESC);
CREATE INDEX IF NOT EXISTS com_message_images_a_purger_idx
  ON public.com_message_images (expire_le) WHERE etat <> 'supprimee';

ALTER TABLE public.com_message_images ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON public.com_message_images FROM PUBLIC, anon, authenticated, service_role;
-- Les cles des objets ne sont jamais lues par un client : il recoit des URL signees.
GRANT SELECT (id, message_id, fil_id, auteur, mime, mime_miniature, largeur, hauteur, octets,
              octets_miniature, couleur_moyenne, cree_le, expire_le, supprimee_le, etat)
  ON public.com_message_images TO authenticated;

DO $policy$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_catalog.pg_policy p
                  WHERE p.polrelid = 'public.com_message_images'::regclass
                    AND p.polname = 'com_message_images_lecture_participants') THEN
    CREATE POLICY com_message_images_lecture_participants ON public.com_message_images
      FOR SELECT TO authenticated
      USING (public.com_fil_lisible(fil_id));
  END IF;
END
$policy$;

COMMENT ON TABLE public.com_message_images IS
  'IMAGES-MESSAGERIE : une image (et sa miniature) par message, seau R2_MESSAGING. '
  'Lecture : participants du fil (hors cles). Ecriture : RPC message_image_* seulement. '
  'Expire 90 jours apres le depot : la ligne reste, etat = supprimee.';

-- 3. Les coeurs ------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.com_message_coeurs (
  message_id uuid NOT NULL REFERENCES public.com_messages(id),
  auteur uuid NOT NULL REFERENCES public.profiles(id),
  cree_le timestamptz NOT NULL DEFAULT pg_catalog.clock_timestamp(),
  -- Pose quand la personne retire son coeur ; nul tant qu'il est donne.
  retire_le timestamptz,
  PRIMARY KEY (message_id, auteur)
);

ALTER TABLE public.com_message_coeurs ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON public.com_message_coeurs FROM PUBLIC, anon, authenticated, service_role;
GRANT SELECT ON public.com_message_coeurs TO authenticated;

DO $policy$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_catalog.pg_policy p
                  WHERE p.polrelid = 'public.com_message_coeurs'::regclass
                    AND p.polname = 'com_message_coeurs_lecture_participants') THEN
    CREATE POLICY com_message_coeurs_lecture_participants ON public.com_message_coeurs
      FOR SELECT TO authenticated
      USING (public.com_message_lisible(message_id));
  END IF;
END
$policy$;

COMMENT ON TABLE public.com_message_coeurs IS
  'IMAGES-MESSAGERIE : un coeur par personne et par message. Lecture : participants du fil. '
  'Pose et retrait : aimer_message / ne_plus_aimer_message seulement.';

DO $agent$
BEGIN
  IF EXISTS (SELECT 1 FROM pg_catalog.pg_roles WHERE rolname = 'agent_ro') THEN
    EXECUTE 'REVOKE ALL ON public.com_message_images, public.com_message_coeurs FROM agent_ro';
    EXECUTE 'REVOKE ALL ON FUNCTION private.com_image_droits(uuid), public.com_fil_lisible(uuid), '
         || 'public.com_message_lisible(uuid) FROM agent_ro';
  END IF;
END
$agent$;

DO $postflight$
BEGIN
  IF NOT (SELECT c.relrowsecurity FROM pg_catalog.pg_class c WHERE c.oid = 'public.com_message_images'::regclass)
     OR NOT (SELECT c.relrowsecurity FROM pg_catalog.pg_class c WHERE c.oid = 'public.com_message_coeurs'::regclass) THEN
    RAISE EXCEPTION 'images messagerie : RLS absente';
  END IF;
  IF pg_catalog.has_table_privilege('authenticated', 'public.com_message_images', 'insert')
     OR pg_catalog.has_table_privilege('authenticated', 'public.com_message_images', 'update')
     OR pg_catalog.has_table_privilege('authenticated', 'public.com_message_coeurs', 'insert')
     OR pg_catalog.has_table_privilege('authenticated', 'public.com_message_coeurs', 'update')
     OR pg_catalog.has_table_privilege('anon', 'public.com_message_images', 'select')
     OR pg_catalog.has_table_privilege('anon', 'public.com_message_coeurs', 'select')
     OR pg_catalog.has_column_privilege('authenticated', 'public.com_message_images', 'cle_r2', 'select') THEN
    RAISE EXCEPTION 'images messagerie : droits de table inattendus';
  END IF;
END
$postflight$;
