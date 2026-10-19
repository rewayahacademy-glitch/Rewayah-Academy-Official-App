-- AVIS-PUBLICS (19/10/2026) : avis des familles et des eleves, recueillis par un lien
-- que la direction cree, publies apres lecture par la direction.
-- Contrat : docs/current/DECISION-AVIS-2026-10-19.md, section « Contrat serveur ».
--
-- * `public.avis_liens` : un lien de collecte. Le jeton (24 octets au hasard, base64url
--   sans remplissage) n'est rendu qu'une fois, a la creation ; la base ne garde que
--   son empreinte sha256.
-- * `public.avis` : un avis depose, avec son statut de moderation.
-- * Les deux tables ont la RLS active et AUCUNE politique : l'acces passe par les
--   fonctions SECURITY DEFINER ci-dessous, et par elles seules.
-- * `avis_lien_etat` et `avis_deposer` sont ouvertes a anon (formulaire sans compte).
--   Un jeton inconnu, ferme, expire ou plein donne la MEME erreur (P0002) : aucun
--   moyen de deviner quels jetons existent.
-- * `avis_publics` ne rend que les avis publies, en liste blanche de cles : jamais un
--   identifiant, le lien, le motif de moderation ni l'auteur de la moderation.
-- * La direction ne modifie jamais le texte d'un avis : elle publie, refuse ou retire.
BEGIN;

CREATE TABLE public.avis_liens (
  id              uuid        PRIMARY KEY DEFAULT gen_random_uuid(),
  libelle         text        NOT NULL CHECK (char_length(libelle) BETWEEN 1 AND 80),
  jeton_empreinte bytea       NOT NULL UNIQUE,
  cree_par        uuid        NOT NULL,
  cree_le         timestamptz NOT NULL DEFAULT now(),
  expire_le       timestamptz NOT NULL,
  avis_max        integer     NOT NULL CHECK (avis_max BETWEEN 1 AND 2000),
  avis_recus      integer     NOT NULL DEFAULT 0 CHECK (avis_recus >= 0),
  ferme_le        timestamptz,
  CHECK (avis_recus <= avis_max),
  CHECK (expire_le > cree_le)
);
COMMENT ON TABLE public.avis_liens IS
  'AVIS-PUBLICS : lien de collecte d''avis. Seule l''empreinte sha256 du jeton est gardee. RLS sans politique : fonctions DEFINER seulement.';

CREATE TABLE public.avis (
  id               uuid        PRIMARY KEY DEFAULT gen_random_uuid(),
  lien_id          uuid        NOT NULL REFERENCES public.avis_liens (id),
  nom_affiche      text        NOT NULL CHECK (char_length(nom_affiche) BETWEEN 2 AND 60),
  qualite          text        NOT NULL CHECK (qualite IN ('parent', 'eleve_adulte')),
  pays             char(2)     NOT NULL CHECK (pays ~ '^[A-Z]{2}$'),
  depuis           date        NOT NULL CHECK (depuis >= DATE '2015-01-01'
                                           AND depuis = date_trunc('month', depuis)::date),
  note             smallint    NOT NULL CHECK (note BETWEEN 1 AND 5),
  titre            text        CHECK (titre IS NULL OR char_length(titre) BETWEEN 1 AND 80),
  texte            text        NOT NULL CHECK (char_length(texte) BETWEEN 20 AND 1500),
  accord_public_le timestamptz NOT NULL,
  statut           text        NOT NULL DEFAULT 'en_attente'
                               CHECK (statut IN ('en_attente', 'publie', 'refuse', 'retire')),
  motif            text        CHECK (motif IS NULL OR char_length(motif) BETWEEN 3 AND 300),
  depose_le        timestamptz NOT NULL DEFAULT now(),
  modere_le        timestamptz,
  modere_par       uuid,
  publie_le        timestamptz
);
CREATE INDEX avis_statut_publie ON public.avis (statut, publie_le DESC);
CREATE INDEX avis_lien ON public.avis (lien_id);
COMMENT ON TABLE public.avis IS
  'AVIS-PUBLICS : avis depose par lien, statut de moderation. RLS sans politique : fonctions DEFINER seulement.';

ALTER TABLE public.avis_liens ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.avis ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON public.avis_liens FROM PUBLIC, anon, authenticated, service_role, agent_ro;
REVOKE ALL ON public.avis FROM PUBLIC, anon, authenticated, service_role, agent_ro;

-- ------------------------------------------------------------------
-- Direction : creer, lister, fermer un lien
-- ------------------------------------------------------------------
CREATE FUNCTION public.avis_lien_creer(p_libelle text, p_jours integer DEFAULT 90, p_avis_max integer DEFAULT 200)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  v_libelle text := pg_catalog.btrim(p_libelle);
  v_jeton   text;
  v_id      uuid;
  v_expire  timestamptz;
BEGIN
  IF NOT coalesce(public.app_role() = 'admin' AND public.app_account_valid(), false) THEN
    RAISE EXCEPTION 'acces refuse' USING ERRCODE = '42501';
  END IF;
  IF v_libelle IS NULL OR pg_catalog.char_length(v_libelle) NOT BETWEEN 1 AND 80 THEN
    RAISE EXCEPTION 'libelle' USING ERRCODE = '22023';
  END IF;
  IF p_jours IS NULL OR p_jours NOT BETWEEN 1 AND 365 THEN
    RAISE EXCEPTION 'jours' USING ERRCODE = '22023';
  END IF;
  IF p_avis_max IS NULL OR p_avis_max NOT BETWEEN 1 AND 2000 THEN
    RAISE EXCEPTION 'avis_max' USING ERRCODE = '22023';
  END IF;

  v_jeton := pg_catalog.translate(
               pg_catalog.encode(extensions.gen_random_bytes(24), 'base64'), '+/=', '-_');
  v_expire := pg_catalog.now() + pg_catalog.make_interval(days => p_jours);

  INSERT INTO public.avis_liens (libelle, jeton_empreinte, cree_par, expire_le, avis_max)
  VALUES (v_libelle, extensions.digest(v_jeton, 'sha256'), auth.uid(), v_expire, p_avis_max)
  RETURNING id INTO v_id;

  RETURN pg_catalog.jsonb_build_object('id', v_id, 'jeton', v_jeton, 'expire_le', v_expire);
END;
$function$;

CREATE FUNCTION public.avis_liens_lister()
RETURNS jsonb
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $function$
BEGIN
  IF NOT coalesce(public.app_role() = 'admin' AND public.app_account_valid(), false) THEN
    RAISE EXCEPTION 'acces refuse' USING ERRCODE = '42501';
  END IF;
  RETURN coalesce((
    SELECT pg_catalog.jsonb_agg(pg_catalog.jsonb_build_object(
             'id', l.id,
             'libelle', l.libelle,
             'cree_le', l.cree_le,
             'expire_le', l.expire_le,
             'avis_max', l.avis_max,
             'avis_recus', l.avis_recus,
             'ferme', l.ferme_le IS NOT NULL,
             'actif', l.ferme_le IS NULL AND l.expire_le > pg_catalog.now() AND l.avis_recus < l.avis_max)
           ORDER BY l.cree_le DESC)
      FROM public.avis_liens l), '[]'::jsonb);
END;
$function$;

CREATE FUNCTION public.avis_lien_fermer(p_id uuid)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $function$
BEGIN
  IF NOT coalesce(public.app_role() = 'admin' AND public.app_account_valid(), false) THEN
    RAISE EXCEPTION 'acces refuse' USING ERRCODE = '42501';
  END IF;
  UPDATE public.avis_liens
     SET ferme_le = coalesce(ferme_le, pg_catalog.now())
   WHERE id = p_id;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'lien introuvable' USING ERRCODE = 'P0002';
  END IF;
END;
$function$;

-- ------------------------------------------------------------------
-- Formulaire public : etat du lien, depot
-- ------------------------------------------------------------------
CREATE FUNCTION public.avis_lien_etat(p_jeton text)
RETURNS jsonb
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $function$
BEGIN
  -- Seule information rendue : le lien accepte-t-il un avis maintenant ?
  RETURN pg_catalog.jsonb_build_object('ouvert', coalesce((
    SELECT l.ferme_le IS NULL AND l.expire_le > pg_catalog.now() AND l.avis_recus < l.avis_max
      FROM public.avis_liens l
     WHERE p_jeton IS NOT NULL
       AND pg_catalog.char_length(p_jeton) <= 200
       AND l.jeton_empreinte = extensions.digest(p_jeton, 'sha256')), false));
END;
$function$;

CREATE FUNCTION public.avis_deposer(
  p_jeton text, p_nom text, p_qualite text, p_pays text, p_depuis date,
  p_note integer, p_titre text, p_texte text, p_accord boolean)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  v_nom    text := pg_catalog.btrim(p_nom);
  v_pays   text := pg_catalog.upper(pg_catalog.btrim(p_pays));
  v_depuis date;
  v_titre  text := pg_catalog.btrim(p_titre);
  v_texte  text := pg_catalog.btrim(pg_catalog.replace(p_texte, E'\r\n', E'\n'));
  v_mois   date := pg_catalog.date_trunc('month', (pg_catalog.now() AT TIME ZONE 'Europe/Paris'))::date;
  v_lien   public.avis_liens;
BEGIN
  -- Champs, dans l'ordre du formulaire. Le message de l'erreur est le nom du champ.
  IF v_nom IS NULL OR pg_catalog.char_length(v_nom) NOT BETWEEN 2 AND 60
     OR v_nom ~ E'[\\x01-\\x1f\\x7f]' THEN
    RAISE EXCEPTION 'nom' USING ERRCODE = '22023';
  END IF;
  IF p_qualite IS NULL OR p_qualite NOT IN ('parent', 'eleve_adulte') THEN
    RAISE EXCEPTION 'qualite' USING ERRCODE = '22023';
  END IF;
  IF v_pays IS NULL OR v_pays !~ '^[A-Z]{2}$' THEN
    RAISE EXCEPTION 'pays' USING ERRCODE = '22023';
  END IF;
  IF p_depuis IS NULL THEN
    RAISE EXCEPTION 'depuis' USING ERRCODE = '22023';
  END IF;
  v_depuis := pg_catalog.date_trunc('month', p_depuis)::date;
  IF v_depuis < DATE '2015-01-01' OR v_depuis > v_mois THEN
    RAISE EXCEPTION 'depuis' USING ERRCODE = '22023';
  END IF;
  IF p_note IS NULL OR p_note NOT BETWEEN 1 AND 5 THEN
    RAISE EXCEPTION 'note' USING ERRCODE = '22023';
  END IF;
  IF v_titre = '' THEN
    v_titre := NULL;
  END IF;
  IF v_titre IS NOT NULL AND (pg_catalog.char_length(v_titre) > 80 OR v_titre ~ E'[\\x01-\\x1f\\x7f]') THEN
    RAISE EXCEPTION 'titre' USING ERRCODE = '22023';
  END IF;
  -- Le saut de ligne (x0a) reste permis dans le texte ; tout autre caractere de controle est refuse.
  IF v_texte IS NULL OR pg_catalog.char_length(v_texte) NOT BETWEEN 20 AND 1500
     OR v_texte ~ E'[\\x01-\\x09\\x0b-\\x1f\\x7f]' THEN
    RAISE EXCEPTION 'texte' USING ERRCODE = '22023';
  END IF;
  IF p_accord IS NOT TRUE THEN
    RAISE EXCEPTION 'accord' USING ERRCODE = '22023';
  END IF;

  -- Le lien : verrouille, puis controle. Meme erreur pour tout echec (aucun oracle).
  IF p_jeton IS NOT NULL AND pg_catalog.char_length(p_jeton) <= 200 THEN
    SELECT l.* INTO v_lien
      FROM public.avis_liens l
     WHERE l.jeton_empreinte = extensions.digest(p_jeton, 'sha256')
       FOR UPDATE;
  END IF;
  IF v_lien.id IS NULL
     OR v_lien.ferme_le IS NOT NULL
     OR v_lien.expire_le <= pg_catalog.now()
     OR v_lien.avis_recus >= v_lien.avis_max THEN
    RAISE EXCEPTION 'lien indisponible' USING ERRCODE = 'P0002';
  END IF;

  INSERT INTO public.avis (lien_id, nom_affiche, qualite, pays, depuis, note, titre, texte, accord_public_le)
  VALUES (v_lien.id, v_nom, p_qualite, v_pays, v_depuis, p_note, v_titre, v_texte, pg_catalog.now());

  UPDATE public.avis_liens SET avis_recus = avis_recus + 1 WHERE id = v_lien.id;
END;
$function$;

-- ------------------------------------------------------------------
-- Direction : lire et moderer
-- ------------------------------------------------------------------
CREATE FUNCTION public.avis_lister_admin(p_statut text DEFAULT NULL)
RETURNS jsonb
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $function$
BEGIN
  IF NOT coalesce(public.app_role() = 'admin' AND public.app_account_valid(), false) THEN
    RAISE EXCEPTION 'acces refuse' USING ERRCODE = '42501';
  END IF;
  IF p_statut IS NOT NULL AND p_statut NOT IN ('en_attente', 'publie', 'refuse', 'retire') THEN
    RAISE EXCEPTION 'statut' USING ERRCODE = '22023';
  END IF;
  RETURN coalesce((
    SELECT pg_catalog.jsonb_agg(pg_catalog.jsonb_build_object(
             'id', a.id,
             'lien_id', a.lien_id,
             'lien_libelle', l.libelle,
             'nom_affiche', a.nom_affiche,
             'qualite', a.qualite,
             'pays', a.pays,
             'depuis', a.depuis,
             'note', a.note,
             'titre', a.titre,
             'texte', a.texte,
             'accord_public_le', a.accord_public_le,
             'statut', a.statut,
             'motif', a.motif,
             'depose_le', a.depose_le,
             'modere_le', a.modere_le,
             'modere_par', a.modere_par,
             'publie_le', a.publie_le)
           ORDER BY a.depose_le DESC)
      FROM public.avis a
      JOIN public.avis_liens l ON l.id = a.lien_id
     WHERE p_statut IS NULL OR a.statut = p_statut), '[]'::jsonb);
END;
$function$;

CREATE FUNCTION public.avis_moderer(p_id uuid, p_statut text, p_motif text DEFAULT NULL)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  v_motif   text := pg_catalog.btrim(p_motif);
  v_courant text;
BEGIN
  IF NOT coalesce(public.app_role() = 'admin' AND public.app_account_valid(), false) THEN
    RAISE EXCEPTION 'acces refuse' USING ERRCODE = '42501';
  END IF;
  IF p_statut IS NULL OR p_statut NOT IN ('publie', 'refuse', 'retire') THEN
    RAISE EXCEPTION 'statut' USING ERRCODE = '22023';
  END IF;
  IF v_motif = '' THEN
    v_motif := NULL;
  END IF;
  IF p_statut IN ('refuse', 'retire')
     AND (v_motif IS NULL OR pg_catalog.char_length(v_motif) NOT BETWEEN 3 AND 300) THEN
    RAISE EXCEPTION 'motif' USING ERRCODE = '22023';
  END IF;

  SELECT a.statut INTO v_courant FROM public.avis a WHERE a.id = p_id FOR UPDATE;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'avis introuvable' USING ERRCODE = 'P0002';
  END IF;
  IF NOT ((p_statut IN ('publie', 'refuse') AND v_courant = 'en_attente')
          OR (p_statut = 'retire' AND v_courant = 'publie')) THEN
    RAISE EXCEPTION 'statut' USING ERRCODE = '22023';
  END IF;

  UPDATE public.avis
     SET statut     = p_statut,
         motif      = CASE WHEN p_statut = 'publie' THEN NULL ELSE v_motif END,
         modere_le  = pg_catalog.now(),
         modere_par = auth.uid(),
         publie_le  = CASE WHEN p_statut = 'publie' THEN pg_catalog.now() ELSE publie_le END
   WHERE id = p_id;
END;
$function$;

-- ------------------------------------------------------------------
-- Site public : avis publies (liste blanche de cles)
-- ------------------------------------------------------------------
CREATE FUNCTION public.avis_publics()
RETURNS jsonb
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $function$
  SELECT pg_catalog.jsonb_build_object(
    'nombre', (SELECT pg_catalog.count(*) FROM public.avis a WHERE a.statut = 'publie'),
    -- Sans avis publie, la moyenne est nulle (et non 0) : le site l'attend ainsi.
    'moyenne_dixiemes', (
      SELECT pg_catalog.round(pg_catalog.avg(a.note) * 10)::integer
        FROM public.avis a WHERE a.statut = 'publie'),
    'avis', coalesce((
      SELECT pg_catalog.jsonb_agg(pg_catalog.jsonb_build_object(
               'nom', r.nom_affiche,
               'qualite', r.qualite,
               'pays', r.pays,
               'depuis', r.depuis,
               'note', r.note,
               'titre', r.titre,
               'texte', r.texte,
               'publie_le', r.publie_le) ORDER BY r.publie_le DESC, r.id)
        FROM (SELECT a.* FROM public.avis a
               WHERE a.statut = 'publie'
               ORDER BY a.publie_le DESC, a.id
               LIMIT 200) r), '[]'::jsonb));
$function$;

-- ------------------------------------------------------------------
-- Droits, liste blanche des fonctions DEFINER, controle final
-- ------------------------------------------------------------------
DO $droits$
DECLARE
  v_oid regprocedure;
BEGIN
  FOREACH v_oid IN ARRAY ARRAY[
    'public.avis_lien_creer(text,integer,integer)'::regprocedure,
    'public.avis_liens_lister()'::regprocedure,
    'public.avis_lien_fermer(uuid)'::regprocedure,
    'public.avis_lister_admin(text)'::regprocedure,
    'public.avis_moderer(uuid,text,text)'::regprocedure] LOOP
    EXECUTE pg_catalog.format('ALTER FUNCTION %s OWNER TO postgres', v_oid);
    EXECUTE pg_catalog.format('REVOKE ALL ON FUNCTION %s FROM PUBLIC, anon, authenticated, service_role, agent_ro', v_oid);
    EXECUTE pg_catalog.format('GRANT EXECUTE ON FUNCTION %s TO authenticated', v_oid);
    EXECUTE pg_catalog.format('COMMENT ON FUNCTION %s IS %L', v_oid, pg_catalog.format(
      'F86 candidate allowlist: signature=%s; md5_functiondef=%s; guard_type=ROLE_POSITIVE_ADMIN; owner=postgres; search_path=""; reviewer=Claude a relire; date=2026-10-19. AVIS-PUBLICS.',
      v_oid::text, pg_catalog.md5(pg_catalog.pg_get_functiondef(v_oid))));
  END LOOP;

  FOREACH v_oid IN ARRAY ARRAY[
    'public.avis_lien_etat(text)'::regprocedure,
    'public.avis_deposer(text,text,text,text,date,integer,text,text,boolean)'::regprocedure,
    'public.avis_publics()'::regprocedure] LOOP
    EXECUTE pg_catalog.format('ALTER FUNCTION %s OWNER TO postgres', v_oid);
    EXECUTE pg_catalog.format('REVOKE ALL ON FUNCTION %s FROM PUBLIC, anon, authenticated, service_role, agent_ro', v_oid);
    EXECUTE pg_catalog.format('GRANT EXECUTE ON FUNCTION %s TO anon, authenticated', v_oid);
    EXECUTE pg_catalog.format('COMMENT ON FUNCTION %s IS %L', v_oid, pg_catalog.format(
      'F86 candidate allowlist: signature=%s; md5_functiondef=%s; guard_type=%s; owner=postgres; search_path=""; reviewer=Claude a relire; date=2026-10-19. AVIS-PUBLICS : ouverte a anon par choix (formulaire sans compte).',
      v_oid::text, pg_catalog.md5(pg_catalog.pg_get_functiondef(v_oid)),
      CASE WHEN v_oid::text LIKE 'avis_publics%' THEN 'PUBLIC_READ_WHITELIST'
           WHEN v_oid::text LIKE 'avis_lien_etat%' THEN 'PUBLIC_TOKEN_READ_BOOLEAN'
           ELSE 'PUBLIC_TOKEN_WRITE_VALIDATED' END));
  END LOOP;
END;
$droits$;

DO $postflight$
DECLARE
  v_oid regprocedure;
BEGIN
  FOREACH v_oid IN ARRAY ARRAY[
    'public.avis_lien_creer(text,integer,integer)'::regprocedure,
    'public.avis_liens_lister()'::regprocedure,
    'public.avis_lien_fermer(uuid)'::regprocedure,
    'public.avis_lister_admin(text)'::regprocedure,
    'public.avis_moderer(uuid,text,text)'::regprocedure,
    'public.avis_lien_etat(text)'::regprocedure,
    'public.avis_deposer(text,text,text,text,date,integer,text,text,boolean)'::regprocedure,
    'public.avis_publics()'::regprocedure] LOOP
    IF NOT EXISTS (SELECT 1 FROM pg_catalog.pg_proc p WHERE p.oid = v_oid AND p.prosecdef
                     AND p.proowner = 'postgres'::regrole
                     AND p.proconfig @> ARRAY['search_path=""'])
       OR NOT pg_catalog.has_function_privilege('authenticated', v_oid, 'EXECUTE')
       OR pg_catalog.has_function_privilege('service_role', v_oid, 'EXECUTE')
       OR pg_catalog.has_function_privilege('agent_ro', v_oid, 'EXECUTE') THEN
      RAISE EXCEPTION 'AVIS-PUBLICS : DEFINER ou ACL invalide pour %', v_oid;
    END IF;
  END LOOP;
  -- anon : exactement les trois portes publiques, pas une de plus.
  IF NOT pg_catalog.has_function_privilege('anon', 'public.avis_lien_etat(text)'::regprocedure, 'EXECUTE')
     OR NOT pg_catalog.has_function_privilege('anon', 'public.avis_deposer(text,text,text,text,date,integer,text,text,boolean)'::regprocedure, 'EXECUTE')
     OR NOT pg_catalog.has_function_privilege('anon', 'public.avis_publics()'::regprocedure, 'EXECUTE')
     OR pg_catalog.has_function_privilege('anon', 'public.avis_lien_creer(text,integer,integer)'::regprocedure, 'EXECUTE')
     OR pg_catalog.has_function_privilege('anon', 'public.avis_liens_lister()'::regprocedure, 'EXECUTE')
     OR pg_catalog.has_function_privilege('anon', 'public.avis_lien_fermer(uuid)'::regprocedure, 'EXECUTE')
     OR pg_catalog.has_function_privilege('anon', 'public.avis_lister_admin(text)'::regprocedure, 'EXECUTE')
     OR pg_catalog.has_function_privilege('anon', 'public.avis_moderer(uuid,text,text)'::regprocedure, 'EXECUTE') THEN
    RAISE EXCEPTION 'AVIS-PUBLICS : droits anon incorrects';
  END IF;
  IF NOT (SELECT c.relrowsecurity FROM pg_catalog.pg_class c WHERE c.oid = 'public.avis'::regclass)
     OR NOT (SELECT c.relrowsecurity FROM pg_catalog.pg_class c WHERE c.oid = 'public.avis_liens'::regclass) THEN
    RAISE EXCEPTION 'AVIS-PUBLICS : RLS inactive';
  END IF;
  IF EXISTS (SELECT 1 FROM pg_catalog.pg_policies WHERE schemaname = 'public' AND tablename IN ('avis', 'avis_liens')) THEN
    RAISE EXCEPTION 'AVIS-PUBLICS : aucune politique attendue sur les tables d''avis';
  END IF;
  IF pg_catalog.has_table_privilege('anon', 'public.avis', 'SELECT')
     OR pg_catalog.has_table_privilege('anon', 'public.avis_liens', 'SELECT')
     OR pg_catalog.has_table_privilege('authenticated', 'public.avis', 'SELECT')
     OR pg_catalog.has_table_privilege('authenticated', 'public.avis_liens', 'SELECT')
     OR pg_catalog.has_table_privilege('authenticated', 'public.avis', 'INSERT')
     OR pg_catalog.has_table_privilege('authenticated', 'public.avis', 'UPDATE')
     OR pg_catalog.has_table_privilege('service_role', 'public.avis', 'SELECT')
     OR pg_catalog.has_table_privilege('agent_ro', 'public.avis', 'SELECT')
     OR pg_catalog.has_table_privilege('agent_ro', 'public.avis_liens', 'SELECT') THEN
    RAISE EXCEPTION 'AVIS-PUBLICS : droits de table trop larges';
  END IF;
END;
$postflight$;

COMMIT;
