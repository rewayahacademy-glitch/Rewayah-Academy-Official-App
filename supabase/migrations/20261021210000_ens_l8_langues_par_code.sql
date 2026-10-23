-- ENS-L8 (CAND-Q15, lot langue, 21/10/2026) : teacher_profiles.languages porte
-- des CODES de public.langues_cours, comme groupes.langue_code (0043:450)
-- auquel tc_verifier_affectation_enseignant (0082:64) et
-- enseignants_pour_classe (0083:111) le comparent.
--
-- Constat : FORM-L8 (declaration_choix.dart) y ecrivait le nom affiche
-- (nom_humain, le francais avec sa cedille), que maj_profil_enseignant
-- (0027:66) stocke tel quel. Un nom
-- n'egale aucun code : aucun enseignant declare par ENS-05 ne pouvait etre
-- propose ni affecte a une classe nee d'un regroupement (langue_code jamais
-- nul, 20261012100000:144-149). Les scenarios passaient parce que leurs
-- fixtures stockent des codes.
--
-- Correction cote serveur, par un declencheur qui normalise a l'ecriture :
-- * il couvre tous les ecrivains : maj_profil_enseignant, le futur import des
--   candidatures, une ecriture directe de la direction, et les clients PWA
--   encore en cache qui enverront des noms ;
-- * il ne redefinit aucune fonction : maj_profil_enseignant,
--   tc_verifier_affectation_enseignant, enseignants_pour_classe et leurs
--   empreintes F86 restent tels quels ;
-- * code connu -> lui-meme ; nom connu (casse et espaces ignores) -> son
--   code, un code exact passant avant un nom homonyme (relecture) ; autre
--   texte -> garde tel quel (saisie "Autre", decision du 18/10). Une saisie
--   libre n'egale aucun code : elle ne rend l'enseignant eligible a aucune
--   classe tant que la direction n'a pas ajoute la langue au referentiel. On
--   refuse plutot que d'affecter a tort ;
-- * vides et doublons retires, ordre de saisie conserve. Un tableau NULL
--   reste NULL : la contrainte NOT NULL de la colonne garde le dernier mot.
--
-- Fonction de declenchement SECURITY INVOKER (idiome de
-- remplacements_seance_immutable, b09:31-37) : elle lit langues_cours avec
-- les droits de l'ecrivain (SELECT accorde a authenticated, 0043:140, policy
-- langues_cours_lecture using (true), 0043:126). EXECUTE est revoque a tous
-- les roles : ce droit n'est verifie qu'a la creation du declencheur, pas a
-- son execution. La liste blanche des fonctions volatiles
-- (scenarios_af_liste_blanche_volatiles.sql) ne change donc pas.
--
-- Reprise : le declencheur reecrit chaque ligne non vide (0 ligne sur une
-- base neuve) ; NOTICE des valeurs hors referentiel avec leur nombre, sans
-- identite. Ordre de deploiement : cette migration avant le client qui
-- envoie des codes ; un ancien client qui envoie des noms reste sans
-- consequence.
BEGIN;

CREATE FUNCTION public.teacher_profiles_langues_par_code()
RETURNS trigger
LANGUAGE plpgsql
SECURITY INVOKER
SET search_path = ''
AS $function$
BEGIN
  IF NEW.languages IS NULL THEN
    RETURN NEW;
  END IF;
  NEW.languages := coalesce((
    SELECT pg_catalog.array_agg(n.valeur ORDER BY n.rang)
      FROM (
        SELECT DISTINCT ON (r.valeur) r.valeur, r.rang
          FROM (
            SELECT coalesce(
                     (SELECT lc.code
                        FROM public.langues_cours lc
                       WHERE lc.code = pg_catalog.lower(pg_catalog.btrim(v.brut))
                          OR pg_catalog.lower(pg_catalog.btrim(lc.nom_humain))
                             = pg_catalog.lower(pg_catalog.btrim(v.brut))
                       -- (relecture) un code exact passe avant un nom homonyme.
                       ORDER BY (lc.code = pg_catalog.lower(pg_catalog.btrim(v.brut))) DESC,
                                lc.ordre, lc.code
                       LIMIT 1),
                     pg_catalog.btrim(v.brut)) AS valeur,
                   v.rang
              FROM pg_catalog.unnest(NEW.languages) WITH ORDINALITY AS v(brut, rang)
             WHERE pg_catalog.btrim(coalesce(v.brut, '')) <> ''
          ) r
         ORDER BY r.valeur, r.rang
      ) n
  ), '{}'::text[]);
  RETURN NEW;
END;
$function$;

ALTER FUNCTION public.teacher_profiles_langues_par_code() OWNER TO postgres;
REVOKE ALL ON FUNCTION public.teacher_profiles_langues_par_code()
  FROM PUBLIC, anon, authenticated, service_role, agent_ro;
COMMENT ON FUNCTION public.teacher_profiles_langues_par_code() IS
  'ENS-L8 (CAND-Q15, 2026-10-21): declencheur BEFORE INSERT OR UPDATE OF languages sur teacher_profiles. Nom ou code du referentiel -> code de langues_cours (code exact prioritaire), saisie libre conservee, vides et doublons retires, ordre conserve. SECURITY INVOKER, aucun droit EXECUTE client.';

CREATE TRIGGER teacher_profiles_langues_par_code
  BEFORE INSERT OR UPDATE OF languages ON public.teacher_profiles
  FOR EACH ROW EXECUTE FUNCTION public.teacher_profiles_langues_par_code();

COMMENT ON COLUMN public.teacher_profiles.languages IS
  'Codes de public.langues_cours. Une valeur hors referentiel est une saisie libre conservee, qui ne correspond a aucune classe. Apres ajout d''une langue au referentiel, rejouer : update public.teacher_profiles set languages = languages where languages <> ''{}''.';

-- Reprise des lignes existantes : le declencheur reecrit chaque ligne non
-- vide. Les valeurs hors referentiel sont signalees avec leur nombre, sans
-- aucune identite.
DO $reprise$
DECLARE
  v_lignes integer;
  v_hors text;
BEGIN
  UPDATE public.teacher_profiles
     SET languages = languages
   WHERE languages <> '{}'::text[];
  GET DIAGNOSTICS v_lignes = ROW_COUNT;

  SELECT pg_catalog.string_agg(x.valeur || ' (' || x.nombre || ')', ', ' ORDER BY x.valeur)
    INTO v_hors
    FROM (
      SELECT v.valeur, pg_catalog.count(*) AS nombre
        FROM public.teacher_profiles tp
        CROSS JOIN LATERAL pg_catalog.unnest(tp.languages) AS v(valeur)
       WHERE NOT EXISTS (
               SELECT 1 FROM public.langues_cours lc WHERE lc.code = v.valeur
             )
       GROUP BY v.valeur
    ) x;

  RAISE NOTICE 'ENS-L8 : % ligne(s) de teacher_profiles normalisee(s)', v_lignes;
  IF v_hors IS NOT NULL THEN
    RAISE NOTICE 'ENS-L8 : langues hors referentiel conservees : %', v_hors;
  END IF;
END;
$reprise$;

DO $postflight$
DECLARE
  v_oid regprocedure := 'public.teacher_profiles_langues_par_code()'::regprocedure;
  v_p pg_catalog.pg_proc%ROWTYPE;
BEGIN
  SELECT * INTO v_p FROM pg_catalog.pg_proc WHERE oid = v_oid::oid;
  IF v_p.prosecdef
     OR pg_catalog.pg_get_userbyid(v_p.proowner) <> 'postgres'
     OR NOT coalesce(v_p.proconfig @> ARRAY['search_path=""'], false)
     OR pg_catalog.has_function_privilege('anon', v_oid, 'EXECUTE')
     OR pg_catalog.has_function_privilege('authenticated', v_oid, 'EXECUTE')
     OR pg_catalog.has_function_privilege('service_role', v_oid, 'EXECUTE')
     OR pg_catalog.has_function_privilege('agent_ro', v_oid, 'EXECUTE') THEN
    RAISE EXCEPTION 'ENS-L8 : droits de teacher_profiles_langues_par_code invalides';
  END IF;

  IF NOT EXISTS (
    SELECT 1
      FROM pg_catalog.pg_trigger t
     WHERE t.tgrelid = 'public.teacher_profiles'::regclass
       AND t.tgname = 'teacher_profiles_langues_par_code'
       AND t.tgfoid = v_oid::oid
       AND t.tgenabled = 'O'
       AND NOT t.tgisinternal
  ) THEN
    RAISE EXCEPTION 'ENS-L8 : declencheur teacher_profiles_langues_par_code absent ou inactif';
  END IF;

  -- Aucun nom du referentiel (ni code mal ecrit) encore stocke a la place de
  -- son code.
  IF EXISTS (
    SELECT 1
      FROM public.teacher_profiles tp
      CROSS JOIN LATERAL pg_catalog.unnest(tp.languages) AS v(valeur)
     WHERE NOT EXISTS (
             SELECT 1 FROM public.langues_cours c WHERE c.code = v.valeur
           )
       AND EXISTS (
             SELECT 1
               FROM public.langues_cours c
              WHERE c.code = pg_catalog.lower(pg_catalog.btrim(v.valeur))
                 OR pg_catalog.lower(pg_catalog.btrim(c.nom_humain))
                    = pg_catalog.lower(pg_catalog.btrim(v.valeur))
           )
  ) THEN
    RAISE EXCEPTION 'ENS-L8 : un nom de langue est encore stocke a la place de son code';
  END IF;
END;
$postflight$;

COMMIT;
