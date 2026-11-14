-- REVENUS-DUREE-PAYEE, volet 2 (14/11/2026, decision du pilote : « fais-la dans
-- #465 ») : les heures assurees, les heures par Classe et le taux horaire
-- effectif de l'ecran des revenus se calculent sur la duree PAYEE, plus sur
-- les minutes connectees.
--
-- Constat mesure (base rejouee, 5 seances) : mes_revenus_enseignant sommait
-- private.bf1_prestations.minutes, donc private.pai_minutes_enseignant (minutes
-- connectees dans la fenetre) : total 265 min, alors que la regle de paie
-- (duree due atteinte : toute la fenetre) en compte 270. Le taux effectif
-- (montant x 60 / minutes) en etait surestime.
--
-- Ce fichier, additif et rejouable (CREATE OR REPLACE) :
--   1. cree private.pai_minutes_payees(seance, politique) : la duree payee, par
--      la MEME regle que private.pai_due_seance (duree due atteinte : toute la
--      fenetre ; sinon les minutes tenues, jamais plus que la fenetre ; les
--      minutes tenues sont celles de la direction quand elle a tranche la
--      duree), affirmee SEULEMENT si elle redonne exactement le montant ecrit
--      par le serveur ; sinon null (seance payee avant PAIE-FENETRE, montant
--      decide, taux change, presence corrigee, reprise ouverte). Source unique,
--      aussi appelee par public.mes_durees_payees_enseignant (20261125300000) ;
--   2. retouche PAR ANCRES (regle B4) public.mes_revenus_enseignant(date), rien
--      d'autre : les minutes par Classe (donc le total, la moyenne et le taux
--      effectif) prennent la duree payee quand elle est affirmable, sinon les
--      minutes connectees d'avant ; un champ s'AJOUTE (regle B6) en tete,
--      'seancesSansDureePayee' : le nombre de seances comptees faute de mieux
--      au temps de connexion, pour que l'ecran le dise. Aucun chiffre invente.
--   private.bf1_prestations et son test (scenarios_paie_fenetre.sql) ne
--   changent pas ; aucun montant n'est recalcule ni reecrit.
--
-- Une ancre qui ne tient plus fait echouer le fichier (RAISE dans
-- pg_temp.remplacer) ; les retouches sont dans un seul bloc DO : tout ou rien.
-- Rejeu : retouche deja la (marqueur 'seancesSansDureePayee'), rien reapplique.
-- Sans mot d'effacement (regle B5), sans BEGIN ni COMMIT ; le pilote
-- l'installe. PREREQUIS : 20261124800000 et 20261124900000.
-- Scenario : supabase/tests/scenarios_revenus_duree_payee.sql.

-- ---------------------------------------------------------------------------
-- 1. La duree payee d'une seance
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION private.pai_minutes_payees(p_seance uuid, p public.politiques_commerciales)
RETURNS integer
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  v_type text;
  v_fenetre numeric;
  v_tenues numeric;
  v_taux bigint;
  v_due integer;
  v_ecrit bigint;
  v_presents integer;
  v_payees numeric;
  v_debut timestamptz;
  v_fin timestamptz;
BEGIN
  IF p.version IS NULL THEN
    RETURN NULL;
  END IF;
  IF pg_catalog.to_regprocedure('private.pai_fenetre(uuid)') IS NULL
     OR pg_catalog.to_regprocedure('private.pai_minutes_enseignant(uuid)') IS NULL THEN
    RAISE EXCEPTION 'duree payee : la fenetre payable (PAIE-FENETRE) n''est pas installee'
      USING ERRCODE = '55000';
  END IF;
  SELECT g.type_public INTO v_type
    FROM public.sessions s JOIN public.groupes g ON g.id = s.groupe_id
   WHERE s.id = p_seance;
  IF NOT FOUND THEN
    RETURN NULL;
  END IF;
  SELECT m.montant_minor INTO v_ecrit
    FROM public.tresorerie_mouvements m
   WHERE m.source_type = 'prestation' AND m.source_id = p_seance::text
     AND m.regle = 'remuneration_due' AND m.coffre = 'paie_a_decaisser' AND m.sens = 'entree';
  -- Rien d'ecrit et la direction doit trancher : pas de duree payee.
  IF v_ecrit IS NULL AND EXISTS (
       SELECT 1 FROM public.tresorerie_a_reprendre a
        WHERE a.source_type = 'prestation' AND a.source_id = p_seance::text
          AND a.traite_le IS NULL) THEN
    RETURN NULL;
  END IF;
  SELECT f.minutes INTO v_fenetre FROM private.pai_fenetre(p_seance) f;
  IF NOT coalesce(v_fenetre > 0, false) THEN
    RETURN NULL;
  END IF;
  -- Les minutes tenues : la duree tranchee par la direction, sinon la
  -- connexion de l'enseignant effectif dans la fenetre (comme pai_due_seance).
  SELECT a.decision_debut, a.decision_fin INTO v_debut, v_fin
    FROM public.tresorerie_a_reprendre a
   WHERE a.source_type = 'prestation' AND a.source_id = p_seance::text
     AND a.raison = 'duree_indeterminee' AND a.decision_debut IS NOT NULL
   ORDER BY a.id DESC LIMIT 1;
  IF v_debut IS NOT NULL THEN
    IF v_fin IS NULL OR v_fin <= v_debut THEN
      RETURN NULL;
    END IF;
    v_tenues := extract(epoch FROM (v_fin - v_debut)) / 60;
  ELSE
    v_tenues := private.pai_minutes_enseignant(p_seance);
    IF coalesce(v_tenues, 0) <= 0 THEN
      RETURN NULL;
    END IF;
  END IF;
  v_taux := CASE v_type WHEN 'adulte' THEN p.taux_eleve_heure_adulte_mineur
                        ELSE p.taux_eleve_heure_enfant_mineur END;
  v_due := CASE v_type WHEN 'adulte' THEN p.duree_due_adulte_minutes
                       ELSE p.duree_due_enfant_minutes END;
  IF v_taux IS NULL THEN
    RETURN NULL;
  END IF;
  v_payees := CASE WHEN v_due IS NULL OR v_tenues >= v_due THEN v_fenetre
                   ELSE least(v_tenues, v_fenetre) END;
  v_presents := private.pai_eleves_presents(p_seance);
  -- Garde de coherence : la duree n'est affirmee que si elle redonne le
  -- montant que le serveur a ecrit.
  IF pg_catalog.round(v_taux * v_presents * v_payees / 60)::bigint
       IS DISTINCT FROM coalesce(v_ecrit, 0) THEN
    RETURN NULL;
  END IF;
  RETURN pg_catalog.round(v_payees)::integer;
END;
$function$;

ALTER FUNCTION private.pai_minutes_payees(uuid, public.politiques_commerciales) OWNER TO postgres;
REVOKE ALL ON FUNCTION private.pai_minutes_payees(uuid, public.politiques_commerciales)
  FROM PUBLIC, anon, authenticated, service_role;
COMMENT ON FUNCTION private.pai_minutes_payees(uuid, public.politiques_commerciales) IS
  'REVENUS-DUREE-PAYEE (14/11/2026) : duree payee d''une seance, meme regle que private.pai_due_seance (fenetre PAIE-FENETRE), affirmee seulement si elle redonne exactement le montant ecrit ; sinon null. Privee, lecture seule.';

-- ---------------------------------------------------------------------------
-- 2. Retouche par ancres de mes_revenus_enseignant
-- ---------------------------------------------------------------------------
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

DO $retouches$
DECLARE
  v_f constant pg_catalog.regprocedure := 'public.mes_revenus_enseignant(date)'::regprocedure;
BEGIN
  IF pg_catalog.strpos(pg_catalog.pg_get_functiondef(v_f), '''seancesSansDureePayee''') > 0 THEN
    RAISE NOTICE 'REVENUS-DUREE-PAYEE : retouches deja presentes, rien n''est reapplique';
    RETURN;
  END IF;

  -- 2.1 Les minutes par Classe : la duree payee quand elle est affirmable.
  PERFORM pg_temp.remplacer(v_f,
    $a$sum(p.minutes)::bigint AS minutes, sum(p.montant)::bigint AS montant$a$,
    $b$sum(coalesce(private.pai_minutes_payees(p.seance, v_pol), p.minutes))::bigint AS minutes, sum(p.montant)::bigint AS montant$b$, 1);

  -- 2.2 Le nombre de seances comptees au temps de connexion, faute de mieux.
  PERFORM pg_temp.remplacer(v_f,
    $a$  v_a_recevoir bigint;$a$,
    $b$  v_a_recevoir bigint;
  v_sans_duree integer;$b$, 1);

  PERFORM pg_temp.remplacer(v_f,
    $a$  -- Le jour de paie : du jourDebut au jourFin du mois suivant.$a$,
    $b$  -- REVENUS-DUREE-PAYEE : seances dont la duree payee n'est pas affirmable
  -- (comptees au temps de connexion), pour que l'ecran le dise.
  SELECT count(*) FILTER (WHERE private.pai_minutes_payees(p.seance, v_pol) IS NULL)::integer
    INTO v_sans_duree
    FROM private.bf1_prestations(v_uid, v_debut, v_fin) p;

  -- Le jour de paie : du jourDebut au jourFin du mois suivant.$b$, 1);

  PERFORM pg_temp.remplacer(v_f,
    $a$    'totalEstime', private.bf1_montant(v_total, v_devise),$a$,
    $b$    'totalEstime', private.bf1_montant(v_total, v_devise),
    'seancesSansDureePayee', v_sans_duree,$b$, 1);
END;
$retouches$;

ALTER FUNCTION public.mes_revenus_enseignant(date) OWNER TO postgres;
REVOKE ALL ON FUNCTION public.mes_revenus_enseignant(date) FROM PUBLIC, anon, service_role;
GRANT EXECUTE ON FUNCTION public.mes_revenus_enseignant(date) TO authenticated;

DO $postflight$
DECLARE
  v_def text := pg_catalog.pg_get_functiondef('public.mes_revenus_enseignant(date)'::regprocedure);
BEGIN
  IF pg_catalog.strpos(v_def, 'private.pai_minutes_payees(p.seance, v_pol)') = 0
     OR pg_catalog.strpos(v_def, '''seancesSansDureePayee''') = 0
     OR pg_catalog.strpos(v_def, 'remuneration_due') = 0
     OR pg_catalog.strpos(v_def, '''totalARecevoir''') = 0 THEN
    RAISE EXCEPTION 'REVENUS-DUREE-PAYEE postflight : retouches ou calcul absents';
  END IF;
  IF pg_catalog.has_function_privilege('anon', 'public.mes_revenus_enseignant(date)', 'EXECUTE')
     OR pg_catalog.has_function_privilege('service_role', 'public.mes_revenus_enseignant(date)', 'EXECUTE')
     OR NOT pg_catalog.has_function_privilege('authenticated', 'public.mes_revenus_enseignant(date)', 'EXECUTE')
     OR pg_catalog.has_function_privilege('authenticated', 'private.pai_minutes_payees(uuid,public.politiques_commerciales)', 'EXECUTE')
     OR pg_catalog.has_function_privilege('anon', 'private.pai_minutes_payees(uuid,public.politiques_commerciales)', 'EXECUTE') THEN
    RAISE EXCEPTION 'REVENUS-DUREE-PAYEE postflight : droits EXECUTE incorrects';
  END IF;
  IF NOT EXISTS (
       SELECT 1 FROM pg_catalog.pg_proc p
        WHERE p.oid = 'public.mes_revenus_enseignant(date)'::regprocedure
          AND p.prosecdef
          AND p.proconfig @> ARRAY['search_path=""']::text[]
          AND pg_catalog.pg_get_userbyid(p.proowner) = 'postgres') THEN
    RAISE EXCEPTION 'REVENUS-DUREE-PAYEE postflight : SECURITY DEFINER, search_path ou proprietaire incorrect';
  END IF;
END;
$postflight$;
