-- ACCENT-GUARD (12/11/2026, ordre du garde-cap ; lecture de production faite
-- le 12/11/2026, en lecture seule).
--
-- Le defaut : en production, deux fonctions gardent un message d'erreur aux
-- accents abimes a l'installation (le caractere de remplacement U+FFFD a la
-- place des lettres accentuees) :
--   public.guard_profile_immutable_id()      " immutable_id ne peut pas ?tre modifi? "
--   public.guard_session_state_transition()  " transition de session non autoris?e: % -> % "
-- Le depot (0001_fondations.sql) porte les bons accents ; seule la base de
-- production est abimee.
--
-- Ce que fait ce fichier, et rien d'autre : il relit la definition EN PLACE
-- (pg_get_functiondef) et n'y remplace que ces deux messages. Tout le reste
-- est garde a l'identique : corps, SECURITY (INVOKER pour la premiere apres
-- 20261123400200, DEFINER pour la seconde), search_path, proprietaire, droits.
-- Sur une base dont les messages sont deja justes (base rejouee depuis le
-- depot), il ne change rien.
--
-- ORDRE : APRES 20261123400200. Celle-ci controle l'empreinte md5 de
-- guard_profile_immutable_id() en production ; corriger le message avant
-- ferait echouer son preflight.
--
-- Ce fichier ne contient AUCUNE lettre accentuee : les accents sont ecrits en
-- echappements Unicode (U&'\00E9'), pour qu'un collage dans un editeur qui
-- ne parle pas UTF-8 ne les abime pas une seconde fois.
--
-- Sans BEGIN ni COMMIT de premier niveau. Aucun mot d'effacement :
-- applicable par apply_migration.

DO $accent_garde$
DECLARE
  v_ffd constant text := U&'\FFFD';
  v_e_aigu constant text := U&'\00E9';
  v_e_circ constant text := U&'\00EA';
  v_cas record;
  v_def text;
  v_neuve text;
  v_definer_avant boolean;
  v_config_avant text[];
BEGIN
  FOR v_cas IN
    SELECT *
      FROM (VALUES
        ('public.guard_profile_immutable_id()',
         'ne peut pas ' || v_ffd || 'tre modifi' || v_ffd,
         'ne peut pas ' || v_e_circ || 'tre modifi' || v_e_aigu),
        ('public.guard_session_state_transition()',
         'non autoris' || v_ffd || 'e',
         'non autoris' || v_e_aigu || 'e')
      ) AS c(sig, abime, juste)
  LOOP
    IF pg_catalog.to_regprocedure(v_cas.sig) IS NULL THEN
      RAISE EXCEPTION 'ACCENT-GUARD : % absente', v_cas.sig;
    END IF;
    SELECT p.prosecdef, p.proconfig INTO v_definer_avant, v_config_avant
      FROM pg_catalog.pg_proc p WHERE p.oid = v_cas.sig::regprocedure;
    v_def := pg_catalog.pg_get_functiondef(v_cas.sig::regprocedure);
    IF pg_catalog.strpos(v_def, v_ffd) = 0 THEN
      CONTINUE; -- deja juste : rien a faire
    END IF;
    IF pg_catalog.strpos(v_def, v_cas.abime) = 0 THEN
      RAISE EXCEPTION 'ACCENT-GUARD : % porte un U+FFFD hors du message attendu, rien n''est change', v_cas.sig;
    END IF;
    v_neuve := pg_catalog.replace(v_def, v_cas.abime, v_cas.juste);
    IF pg_catalog.strpos(v_neuve, v_ffd) > 0 THEN
      RAISE EXCEPTION 'ACCENT-GUARD : % garderait un U+FFFD, rien n''est change', v_cas.sig;
    END IF;
    EXECUTE v_neuve;
    IF (SELECT p.prosecdef IS DISTINCT FROM v_definer_avant
               OR p.proconfig IS DISTINCT FROM v_config_avant
          FROM pg_catalog.pg_proc p WHERE p.oid = v_cas.sig::regprocedure) THEN
      RAISE EXCEPTION 'ACCENT-GUARD : % a change de SECURITY ou de search_path', v_cas.sig;
    END IF;
  END LOOP;
END
$accent_garde$;

-- POSTFLIGHT
DO $postflight$
BEGIN
  IF EXISTS (
    SELECT 1 FROM pg_catalog.pg_proc p
     WHERE p.oid IN ('public.guard_profile_immutable_id()'::regprocedure,
                     'public.guard_session_state_transition()'::regprocedure)
       AND pg_catalog.strpos(p.prosrc, U&'\FFFD') > 0) THEN
    RAISE EXCEPTION 'ACCENT-GUARD : un message garde ses accents abimes';
  END IF;
  IF NOT (SELECT p.prosecdef FROM pg_catalog.pg_proc p
           WHERE p.oid = 'public.guard_session_state_transition()'::regprocedure) THEN
    RAISE EXCEPTION 'ACCENT-GUARD : guard_session_state_transition doit rester DEFINER';
  END IF;
END
$postflight$;
