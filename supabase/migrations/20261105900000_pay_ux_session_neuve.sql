-- PAY-UX (02/11/2026, lot attribue par le pilote) : un formulaire de paiement
-- neuf a chaque nouveau depart, et des lignes qui disent ce qu'on paie.
--
-- FICHIER SANS EFFACEMENT (regle B5) : aucun des trois mots d'effacement ; le
-- pilote l'installe tel quel. Migration additive (B6) : l'ancien code de
-- production continue de marcher. `recharge_payer` garde sa signature et
-- toutes ses cles ; ses lignes de paiement gagnent `formule` et `mois` (le
-- prenom reste, l'ancienne fonction Edge le lit encore).
--
-- 1. public.recharge_remplacer_session (service_role seulement, appelee par
--    la fonction Edge `recharge-payer`) : une commande qui attend deja le
--    prestataire recoit une nouvelle session, a condition que l'ancienne soit
--    bien celle notee sur la commande. La fonction Edge n'appelle ce
--    remplacement qu'APRES avoir expire l'ancienne session chez Stripe (une
--    session `complete` n'est jamais expiree ni remplacee).
--
--    Pourquoi aucun double credit n'est possible : `recharge_evenement_stripe`
--    ne credite que l'evenement dont la session est celle notee sur la
--    commande, et une seule fois (etat `completed`, evenements dedoublonnes).
--    Une ancienne session, expiree avant d'etre remplacee, ne peut plus etre
--    payee ; si elle l'avait ete juste avant, la fonction Edge la lit
--    `complete` et ne remplace rien.
-- 2. recharge_payer : chaque ligne de paiement porte la formule de la part
--    (`libre`, `mois`, `trimestriel`, `annuel`) et le mois courant de la
--    facturation (`private.fac_mois_courant()`) : la fonction Edge en fait
--    le nom de la ligne chez Stripe (« Mensualite de novembre 2026 »), sans
--    prenom.
--
-- Lecteurs recenses (B1) : aucune colonne ne change de sens. Les lecteurs de
-- `lignesPaiement` : la fonction Edge `recharge-payer` seulement (cles en
-- plus, ignorees par l'ancienne version).

BEGIN;

-- Outil de la migration (detruit avec la session) : remplace [p_ancre] par
-- [p_neuf] dans la definition actuelle de [p_fonction], exactement une fois,
-- puis rafraichit l'empreinte F86 de son commentaire.
CREATE FUNCTION pg_temp.remplacer(p_fonction regprocedure, p_ancre text, p_neuf text)
RETURNS void LANGUAGE plpgsql AS $$
DECLARE
  v_def text := pg_catalog.pg_get_functiondef(p_fonction);
  v_n integer;
  v_com text;
BEGIN
  v_n := (pg_catalog.length(v_def) - pg_catalog.length(pg_catalog.replace(v_def, p_ancre, '')))
         / pg_catalog.length(p_ancre);
  IF v_n <> 1 THEN
    RAISE EXCEPTION 'PAY-UX : ancre trouvee % fois dans % : %', v_n, p_fonction, pg_catalog.left(p_ancre, 120);
  END IF;
  EXECUTE pg_catalog.replace(v_def, p_ancre, p_neuf);
  v_com := pg_catalog.obj_description(p_fonction, 'pg_proc');
  IF v_com LIKE '%md5_functiondef=%' THEN
    v_com := pg_catalog.regexp_replace(v_com, 'md5_functiondef=[0-9A-Za-z_]+',
      'md5_functiondef=' || pg_catalog.md5(pg_catalog.pg_get_functiondef(p_fonction)));
    EXECUTE pg_catalog.format('COMMENT ON FUNCTION %s IS %L', p_fonction, v_com);
  END IF;
END;
$$;

-- 1. Remplacer la session d'une commande qui attend le prestataire.
CREATE FUNCTION public.recharge_remplacer_session(
  p_commande uuid, p_titulaire uuid, p_ancienne text, p_session text, p_url text, p_environnement text)
RETURNS void
LANGUAGE plpgsql
VOLATILE
SECURITY DEFINER
SET search_path = ''
AS $function$
BEGIN
  IF p_ancienne IS NULL OR p_session IS NULL OR p_url IS NULL
     OR p_environnement NOT IN ('test', 'live') THEN
    RAISE EXCEPTION 'session invalide' USING ERRCODE = '22023';
  END IF;
  UPDATE public.commandes_recharge
     SET session_prestataire = p_session, url_paiement = p_url, environnement = p_environnement
   WHERE id = p_commande AND titulaire = p_titulaire
     AND etat = 'awaiting_confirmation' AND session_prestataire = p_ancienne;
  -- Un second appel avec la meme nouvelle session (reprise apres coupure) ne
  -- change rien et n'echoue pas.
  IF NOT FOUND AND NOT EXISTS (SELECT 1 FROM public.commandes_recharge
                                WHERE id = p_commande AND session_prestataire = p_session
                                  AND etat = 'awaiting_confirmation') THEN
    RAISE EXCEPTION 'commande introuvable ou deja partie' USING ERRCODE = 'P0002';
  END IF;
END;
$function$;

-- 2. Les lignes de paiement disent la formule et le mois.
SELECT pg_temp.remplacer('public.recharge_payer(uuid,uuid)'::regprocedure,
$a$'prenom', p.first_name, 'mineur', a.montant_mineur) ORDER BY a.rang)$a$,
$b$'prenom', p.first_name, 'mineur', a.montant_mineur,
                         'formule', a.formule, 'mois', private.fac_mois_courant()) ORDER BY a.rang)$b$);

-- 3. Droits et empreinte F86 de la fonction nouvelle.
DO $droits$
DECLARE
  v_oid regprocedure := 'public.recharge_remplacer_session(uuid,uuid,text,text,text,text)'::regprocedure;
BEGIN
  EXECUTE pg_catalog.format('ALTER FUNCTION %s OWNER TO postgres', v_oid);
  EXECUTE pg_catalog.format('REVOKE ALL ON FUNCTION %s FROM PUBLIC, anon, authenticated, agent_ro', v_oid);
  EXECUTE pg_catalog.format('GRANT EXECUTE ON FUNCTION %s TO service_role', v_oid);
  EXECUTE pg_catalog.format('COMMENT ON FUNCTION %s IS %L', v_oid, pg_catalog.format(
    'F86 candidate allowlist: signature=%s; md5_functiondef=%s; guard_type=SERVICE_ROLE_ONLY_EDGE; owner=postgres; search_path=""; reviewer=Claude a relire; date=2026-11-02. PAY-UX : nouvelle session apres expiration de l''ancienne. Must-pass: supabase/tests/scenarios_pay_ux_session_neuve.sql.',
    v_oid::text, pg_catalog.md5(pg_catalog.pg_get_functiondef(v_oid))));
END;
$droits$;

-- 4. Postflight.
DO $postflight$
DECLARE
  v_com text;
  f regprocedure;
BEGIN
  f := 'public.recharge_remplacer_session(uuid,uuid,text,text,text,text)'::regprocedure;
  IF pg_catalog.has_function_privilege('authenticated', f, 'EXECUTE')
     OR pg_catalog.has_function_privilege('anon', f, 'EXECUTE')
     OR pg_catalog.has_function_privilege('agent_ro', f, 'EXECUTE')
     OR NOT pg_catalog.has_function_privilege('service_role', f, 'EXECUTE') THEN
    RAISE EXCEPTION 'PAY-UX : % doit rester au serveur', f;
  END IF;
  IF EXISTS (SELECT 1 FROM pg_catalog.pg_proc p WHERE p.oid = f
              AND (NOT p.prosecdef OR NOT (p.proconfig @> ARRAY['search_path=""']))) THEN
    RAISE EXCEPTION 'PAY-UX : % sans DEFINER ou search_path', f;
  END IF;
  IF pg_catalog.strpos(pg_catalog.pg_get_functiondef('public.recharge_payer(uuid,uuid)'::regprocedure),
                       '''formule'', a.formule, ''mois'', private.fac_mois_courant()') = 0 THEN
    RAISE EXCEPTION 'PAY-UX : ancre de recharge_payer non posee';
  END IF;
  IF NOT pg_catalog.has_function_privilege('authenticated', 'public.recharge_payer(uuid,uuid)', 'EXECUTE')
     OR pg_catalog.has_function_privilege('anon', 'public.recharge_payer(uuid,uuid)', 'EXECUTE') THEN
    RAISE EXCEPTION 'PAY-UX : droits de recharge_payer changes';
  END IF;
  FOREACH f IN ARRAY ARRAY['public.recharge_payer(uuid,uuid)'::regprocedure,
    'public.recharge_remplacer_session(uuid,uuid,text,text,text,text)'::regprocedure] LOOP
    v_com := pg_catalog.obj_description(f, 'pg_proc');
    IF v_com LIKE '%md5_functiondef=%'
       AND pg_catalog.strpos(v_com, pg_catalog.md5(pg_catalog.pg_get_functiondef(f))) = 0 THEN
      RAISE EXCEPTION 'PAY-UX : empreinte F86 perimee pour %', f;
    END IF;
  END LOOP;
END;
$postflight$;

COMMIT;
