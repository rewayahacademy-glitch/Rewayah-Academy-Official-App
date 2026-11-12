-- SEC-GARDE-5, point c (11/11/2026, arbitrage du garde-cap relaye par le
-- pilote). Trois choses, et rien d'autre :
--
-- 1. Cinq fonctions de declencheur passent de SECURITY DEFINER a SECURITY
--    INVOKER (ALTER FUNCTION : corps, search_path et droits inchanges).
--    Verifie avant : aucune ne lit une table ni n'appelle une fonction ; elles
--    ne regardent que OLD, NEW et TG_OP, et levent une exception. Les droits
--    du proprietaire ne leur servent a rien :
--      guard_audit_logs_immutable, guard_contract_acceptances_immutable,
--      guard_profile_immutable_id, guard_rule_override_immutable,
--      guard_prayer_adjustments.
--    RESTE DEFINER, et c'est voulu : guard_session_state_transition. Elle lit
--    public.groupes et public.session_events (deux tables sous RLS) et
--    appelle private.c29_enseignant_effectif_session (schema private, sans
--    USAGE pour authenticated). En INVOKER, une transition demandee par un
--    client verrait des lignes filtrees ou serait refusee a tort.
--
-- 2. Les droits d'execution restants de service_role sont retires de
--    creer_profil_eleve_titulaire(), geler_archive_seance(uuid, text,
--    boolean) et autoriser_ecoute_archive(uuid). Verifie : aucune fonction
--    Edge ne les appelle avec la cle de service (archive-seance-acces appelle
--    autoriser_ecoute_archive avec le jeton de l'appelant).
--
--    agent_ro GARDE l'execution de etat_presence(uuid, uuid), et c'est voulu
--    (decision du pilote, 11/11/2026, option i) : la vue presence_seance_v,
--    lisible par agent_ro, appelle etat_presence, et PostgreSQL verifie le
--    droit d'executer une fonction d'une vue avec les droits du LECTEUR.
--    Prouve sur une base rejouee : sans ce droit, « SELECT etat FROM
--    presence_seance_v » en agent_ro leve « permission denied for function
--    etat_presence ». C'est une lecture : NE PAS « corriger ».
--    service_role sur etat_presence n'est pas touche (hors arbitrage).
--
-- 3. Alignement de 0091 : verdict_acces_dossier_kyc(uuid) n'a pas de droit
--    pour service_role en production (relu par le pilote le 11/11, md5
--    61ed9bcca53f67f946d1bf44f3a2398b, identique au depot rejoue). Le depot
--    l'avait deja retire (20261011190004) ; ce REVOKE ne change donc rien et
--    sert de preuve explicite, verifiee par le postflight.
--
-- PREFLIGHT : md5(pg_get_functiondef) des cinq fonctions relus sur une base
-- rejouee depuis le depot (PostgreSQL 16, main du 11/11) ; a recalibrer en
-- production par le pilote (lecture seule). Un ecart, sans que la fonction
-- soit deja INVOKER, arrete le fichier.
--
-- SEC-GARDE-5-C-RECALIBRAGE (12/11/2026) : guard_profile_immutable_id()
-- accepte DEUX empreintes. 7c0dc793... est celle de la base rejouee depuis
-- le depot ; 1fff46e3... est celle de la production (mesure du pilote,
-- 11/11/2026). Constat du garde-cap, lecture du corps de production : meme
-- logique que le depot, SECURITY DEFINER, search_path vide, sans retour
-- chariot ; seul le message d'erreur differe, ses accents abimes a
-- l'installation (« ne peut pas ?tre modifi? » : le caractere de
-- remplacement U+FFFD a la place des lettres accentuees). Ce fichier ne
-- reecrit pas le corps (ALTER FUNCTION ... SECURITY INVOKER seulement) :
-- les accents du message de production restent abimes, a reparer dans un
-- lot a part s'il le faut.
--
-- Sans BEGIN ni COMMIT de premier niveau. Aucun mot d'effacement :
-- applicable par apply_migration.

DO $preflight$
DECLARE
  v record;
BEGIN
  FOR v IN
    SELECT f.sig, f.attendu, p.prosecdef, pg_catalog.pg_get_functiondef(f.sig::regprocedure) AS def
      FROM (VALUES
        ('public.guard_audit_logs_immutable()', ARRAY['a582efceb101d5541fd511cb7c0c7a91']),
        ('public.guard_contract_acceptances_immutable()', ARRAY['572baa09d163a0b386a7a98d7006b02b']),
        ('public.guard_profile_immutable_id()', ARRAY['7c0dc793af8980d6a630e54d8ca2d2ac',
                                                    '1fff46e37cbb5c465e4109b910b76d1d']),
        ('public.guard_rule_override_immutable()', ARRAY['624f5c6506008961e77bca25fec678df']),
        ('public.guard_prayer_adjustments()', ARRAY['fd9e6e37ca557cfc4a79f1c86f0fd7d4'])
      ) AS f(sig, attendu)
      JOIN pg_catalog.pg_proc p ON p.oid = f.sig::regprocedure
  LOOP
    IF v.prosecdef AND NOT (pg_catalog.md5(v.def) = ANY (v.attendu)) THEN
      RAISE EXCEPTION 'SEC-GARDE-5 c : % a change (md5 %), rien n''est change',
        v.sig, pg_catalog.md5(v.def);
    END IF;
  END LOOP;
  IF to_regprocedure('public.creer_profil_eleve_titulaire()') IS NULL
     OR to_regprocedure('public.geler_archive_seance(uuid,text,boolean)') IS NULL
     OR to_regprocedure('public.autoriser_ecoute_archive(uuid)') IS NULL
     OR to_regprocedure('public.verdict_acces_dossier_kyc(uuid)') IS NULL
     OR to_regprocedure('public.etat_presence(uuid,uuid)') IS NULL THEN
    RAISE EXCEPTION 'SEC-GARDE-5 c : une fonction attendue manque, rien n''est change';
  END IF;
END
$preflight$;

-- 1. INVOKER
ALTER FUNCTION public.guard_audit_logs_immutable() SECURITY INVOKER;
ALTER FUNCTION public.guard_contract_acceptances_immutable() SECURITY INVOKER;
ALTER FUNCTION public.guard_profile_immutable_id() SECURITY INVOKER;
ALTER FUNCTION public.guard_rule_override_immutable() SECURITY INVOKER;
ALTER FUNCTION public.guard_prayer_adjustments() SECURITY INVOKER;

-- 2. Droits restants de service_role (agent_ro garde etat_presence : voir
--    l'en-tete, c'est voulu).
REVOKE EXECUTE ON FUNCTION public.creer_profil_eleve_titulaire() FROM service_role;
REVOKE EXECUTE ON FUNCTION public.geler_archive_seance(uuid, text, boolean) FROM service_role;
REVOKE EXECUTE ON FUNCTION public.autoriser_ecoute_archive(uuid) FROM service_role;

-- 3. Alignement de 0091 (deja vrai en production : sans effet).
REVOKE EXECUTE ON FUNCTION public.verdict_acces_dossier_kyc(uuid) FROM service_role;

-- POSTFLIGHT
DO $postflight$
DECLARE
  v_n integer;
BEGIN
  SELECT count(*) INTO v_n FROM pg_catalog.pg_proc p
   WHERE p.oid IN ('public.guard_audit_logs_immutable()'::regprocedure,
                   'public.guard_contract_acceptances_immutable()'::regprocedure,
                   'public.guard_profile_immutable_id()'::regprocedure,
                   'public.guard_rule_override_immutable()'::regprocedure,
                   'public.guard_prayer_adjustments()'::regprocedure)
     AND NOT p.prosecdef;
  IF v_n <> 5 THEN
    RAISE EXCEPTION 'SEC-GARDE-5 c : % fonctions INVOKER sur 5', v_n;
  END IF;
  IF NOT (SELECT p.prosecdef FROM pg_catalog.pg_proc p
           WHERE p.oid = 'public.guard_session_state_transition()'::regprocedure) THEN
    RAISE EXCEPTION 'SEC-GARDE-5 c : guard_session_state_transition doit rester DEFINER';
  END IF;
  IF has_function_privilege('service_role', 'public.creer_profil_eleve_titulaire()', 'EXECUTE')
     OR has_function_privilege('service_role', 'public.geler_archive_seance(uuid,text,boolean)', 'EXECUTE')
     OR has_function_privilege('service_role', 'public.autoriser_ecoute_archive(uuid)', 'EXECUTE')
     OR has_function_privilege('service_role', 'public.verdict_acces_dossier_kyc(uuid)', 'EXECUTE') THEN
    RAISE EXCEPTION 'SEC-GARDE-5 c : service_role garde un droit retire';
  END IF;
  IF NOT has_function_privilege('agent_ro', 'public.etat_presence(uuid,uuid)', 'EXECUTE') THEN
    RAISE EXCEPTION 'SEC-GARDE-5 c : agent_ro a perdu etat_presence (presence_seance_v casserait)';
  END IF;
  IF NOT has_function_privilege('authenticated', 'public.autoriser_ecoute_archive(uuid)', 'EXECUTE')
     OR NOT has_function_privilege('authenticated', 'public.creer_profil_eleve_titulaire()', 'EXECUTE') THEN
    RAISE EXCEPTION 'SEC-GARDE-5 c : authenticated a perdu un droit qu''il doit garder';
  END IF;
END
$postflight$;
