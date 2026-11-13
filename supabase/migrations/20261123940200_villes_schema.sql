-- HORLOGE-ET-LIEU, partie B (architecte pedagogique, 12/11/2026 ; decision H5,
-- docs/current/pedagogie/HORLOGE-ET-LIEU.md) : la liste des villes.
--
-- Une table de reference des villes de plus de 15 000 habitants (GeoNames,
-- licence CC BY 4.0, telechargee le 12/11/2026), chargee par migration, en
-- LECTURE SEULE pour tout le monde : personne ne l'ecrit en dehors d'une
-- migration, et on ne la lit que par les deux recherches ci-dessous. Le serveur
-- recopie le nom, le pays, le fuseau et les coordonnees de la ligne choisie : un
-- client n'envoie jamais qu'un identifiant de ville.
--
--   * public.rechercher_villes : par le debut du nom (latin sans accent, ou
--     arabe pour les pays arabes), jamais plus de 30 lignes ;
--   * public.villes_proposees : les plus grandes villes dont le fuseau a, en ce
--     moment, le decalage de l'appareil (le client ne connait que ce decalage,
--     jamais le nom IANA hors web).
--
-- Les donnees arrivent dans les fichiers qui suivent (six morceaux), puis un
-- controle d'effectif. Fichier sans effacement : des objets crees, aucun retire.

BEGIN;

-- Le texte cherche et le texte de la ligne sont ramenes a la meme forme : minuscules,
-- sans accent, tirets et apostrophes en espaces.
CREATE FUNCTION private.normaliser_recherche(p_texte text)
RETURNS text
LANGUAGE sql
IMMUTABLE
SET search_path = ''
AS $function$
  SELECT pg_catalog.btrim(pg_catalog.regexp_replace(
    pg_catalog.translate(
      pg_catalog.lower(coalesce(p_texte, '')),
      'àáâãäåāăąçćčďđèéêëēėęěğìíîïīįıłñńňòóôõöøōőœšşśșťţùúûüūůűųýÿžźżñ',
      'aaaaaaaaacccddeeeeeeeegiiiiiiilnnnooooooooosssstttuuuuuuuuyyzzzn'),
    '[-''’`.,/()]+', ' ', 'g'));
$function$;

CREATE TABLE public.villes_ref (
  id           bigint        PRIMARY KEY,
  nom          text          NOT NULL CHECK (pg_catalog.length(nom) BETWEEN 1 AND 120),
  nom_ascii    text          NULL,
  nom_ar       text          NULL,
  pays_code    char(2)       NOT NULL CHECK (pays_code ~ '^[A-Z]{2}$'),
  region       text          NULL,
  fuseau_iana  text          NOT NULL CHECK (pg_catalog.length(fuseau_iana) BETWEEN 3 AND 64),
  latitude     numeric(6,3)  NOT NULL CHECK (latitude BETWEEN -90 AND 90),
  longitude    numeric(7,3)  NOT NULL CHECK (longitude BETWEEN -180 AND 180),
  milliers     integer       NOT NULL DEFAULT 0 CHECK (milliers >= 0),
  nom_recherche text GENERATED ALWAYS AS (private.normaliser_recherche(coalesce(nom_ascii, nom))) STORED
);

CREATE INDEX villes_ref_recherche_idx ON public.villes_ref (nom_recherche text_pattern_ops);
CREATE INDEX villes_ref_nom_ar_idx ON public.villes_ref (nom_ar text_pattern_ops) WHERE nom_ar IS NOT NULL;
CREATE INDEX villes_ref_fuseau_idx ON public.villes_ref (fuseau_iana);

ALTER TABLE public.villes_ref ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON TABLE public.villes_ref FROM PUBLIC, anon, authenticated, service_role;
COMMENT ON TABLE public.villes_ref IS
  'HORLOGE-ET-LIEU (12/11/2026) : villes de plus de 15 000 habitants, GeoNames (CC BY 4.0, 12/11/2026). Ecrite par migration seulement ; lue par rechercher_villes, villes_proposees et les fonctions du lieu. RLS sans politique, aucun droit client.';

-- La recherche : le debut du nom, jamais plus de 30 lignes. Tout compte connecte
-- (meme sans profil : l'etape de la ville s'ouvre avant la creation du profil).
CREATE FUNCTION public.rechercher_villes(
  p_texte text,
  p_pays text DEFAULT NULL,
  p_limite integer DEFAULT 20)
RETURNS TABLE (
  id bigint, nom text, nom_ar text, pays_code text, region text,
  fuseau_iana text, milliers integer)
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  v_q text;
  v_limite integer := least(greatest(coalesce(p_limite, 20), 1), 30);
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'recherche non autorisee' USING ERRCODE = '42501';
  END IF;
  v_q := private.normaliser_recherche(p_texte);
  IF pg_catalog.length(v_q) < 2 OR pg_catalog.length(v_q) > 60 THEN
    RETURN;
  END IF;
  RETURN QUERY
  SELECT v.id, v.nom, v.nom_ar, v.pays_code::text, v.region, v.fuseau_iana, v.milliers
    FROM public.villes_ref v
   WHERE (v.nom_recherche LIKE v_q || '%' OR (v.nom_ar IS NOT NULL AND v.nom_ar LIKE pg_catalog.btrim(p_texte) || '%'))
     AND (p_pays IS NULL OR v.pays_code = upper(pg_catalog.btrim(p_pays)))
   ORDER BY (v.nom_recherche = v_q) DESC, v.milliers DESC, v.nom, v.id
   LIMIT v_limite;
END;
$function$;

-- Les plus grandes villes dont le fuseau a, aujourd'hui, ce decalage (en minutes) :
-- la proposition de depart, avant toute recherche. Jamais plus de 20 lignes.
CREATE FUNCTION public.villes_proposees(
  p_decalage_minutes integer,
  p_limite integer DEFAULT 12)
RETURNS TABLE (
  id bigint, nom text, nom_ar text, pays_code text, region text,
  fuseau_iana text, milliers integer)
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  v_limite integer := least(greatest(coalesce(p_limite, 12), 1), 20);
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'proposition non autorisee' USING ERRCODE = '42501';
  END IF;
  IF p_decalage_minutes IS NULL OR p_decalage_minutes NOT BETWEEN -840 AND 840 THEN
    RETURN;
  END IF;
  RETURN QUERY
  WITH fuseaux AS (
    SELECT f.fuseau_iana
      FROM (SELECT DISTINCT x.fuseau_iana FROM public.villes_ref x) f
     WHERE app_private.fuseau_connu(f.fuseau_iana)
       AND (pg_catalog.date_part('epoch',
              (pg_catalog.now() AT TIME ZONE f.fuseau_iana) - (pg_catalog.now() AT TIME ZONE 'UTC')) / 60)::integer
           = p_decalage_minutes)
  SELECT v.id, v.nom, v.nom_ar, v.pays_code::text, v.region, v.fuseau_iana, v.milliers
    FROM public.villes_ref v
    JOIN fuseaux f ON f.fuseau_iana = v.fuseau_iana
   ORDER BY v.milliers DESC, v.nom, v.id
   LIMIT v_limite;
END;
$function$;

REVOKE ALL ON FUNCTION private.normaliser_recherche(text) FROM PUBLIC, anon, authenticated, service_role;
REVOKE ALL ON FUNCTION public.rechercher_villes(text, text, integer) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.rechercher_villes(text, text, integer) TO authenticated;
REVOKE ALL ON FUNCTION public.villes_proposees(integer, integer) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.villes_proposees(integer, integer) TO authenticated;
COMMENT ON FUNCTION public.rechercher_villes(text, text, integer) IS
  'HORLOGE-ET-LIEU (12/11/2026) : recherche d''une ville par le debut de son nom (latin sans accent ou arabe), 30 lignes au plus ; tout compte connecte. DEFINER, search_path vide.';
COMMENT ON FUNCTION public.villes_proposees(integer, integer) IS
  'HORLOGE-ET-LIEU (12/11/2026) : les plus grandes villes dont le fuseau a, aujourd''hui, le decalage donne (minutes) ; 20 lignes au plus ; tout compte connecte. DEFINER, search_path vide.';

DO $postflight$
BEGIN
  IF pg_catalog.has_table_privilege('authenticated', 'public.villes_ref', 'SELECT')
     OR pg_catalog.has_table_privilege('anon', 'public.villes_ref', 'SELECT')
     OR pg_catalog.has_table_privilege('service_role', 'public.villes_ref', 'INSERT')
     OR pg_catalog.has_table_privilege('authenticated', 'public.villes_ref', 'INSERT')
     OR NOT (SELECT c.relrowsecurity FROM pg_catalog.pg_class c WHERE c.oid = 'public.villes_ref'::pg_catalog.regclass) THEN
    RAISE EXCEPTION 'HORLOGE-ET-LIEU : villes_ref doit etre fermee (RLS, aucun droit client)';
  END IF;
  IF pg_catalog.has_function_privilege('anon', 'public.rechercher_villes(text,text,integer)'::pg_catalog.regprocedure, 'EXECUTE')
     OR pg_catalog.has_function_privilege('anon', 'public.villes_proposees(integer,integer)'::pg_catalog.regprocedure, 'EXECUTE')
     OR NOT pg_catalog.has_function_privilege('authenticated', 'public.rechercher_villes(text,text,integer)'::pg_catalog.regprocedure, 'EXECUTE') THEN
    RAISE EXCEPTION 'HORLOGE-ET-LIEU : droits des recherches de villes';
  END IF;
END
$postflight$;

COMMIT;
