-- REVENUS-DUREE-PAYEE (14/11/2026) : l'ecran des revenus de l'enseignant dit,
-- pour chaque seance, la DUREE PAYEE telle que le serveur la compte, et en
-- detail secondaire les minutes ou l'enseignant etait connecte DANS la
-- fenetre payable.
--
-- Constat (14/11/2026, code lu, rien mesure en production) : le champ `minutes`
-- de chaque seance rendu par public.mes_revenus_enseignant vient de
-- private.pai_releve_seances, donc de private.pai_minutes_enseignant : ce sont
-- les minutes CONNECTEES, pas la duree payee. Avec PAIE-FENETRE
-- (20261124900000) la duree payee d'une seance est, pour une seance dont la
-- duree due n'est pas atteinte, les minutes connectees (au plus la fenetre) et,
-- une fois la duree due atteinte (45 min enfants, 70 min adultes), toute la
-- fenetre. L'ecran affichait donc, par exemple, 47 min pour une seance payee
-- 60 min : un litige annonce.
--
-- Cette migration AJOUTE une lecture, rien d'autre : aucune fonction existante
-- n'est modifiee, aucune ligne de donnees non plus, aucun montant n'est
-- recalcule. Le montant de la seance reste celui ecrit par le serveur et rendu
-- par mes_revenus_enseignant ; l'application ne calcule ni minutes payees ni
-- montant.
--
-- public.mes_durees_payees_enseignant(p_mois date, p_enseignant uuid) -> jsonb
--   Un tableau, une entree par seance du mois de l'enseignant concerne :
--     seanceId         : l'identifiant de la seance ;
--     minutesPayees    : la duree payee, en minutes (arrondie), calculee par la
--                        MEME regle que private.pai_due_seance (duree due
--                        atteinte : toute la fenetre ; sinon les minutes
--                        connectees, jamais plus que la fenetre) ;
--                        null quand le serveur ne peut pas l'affirmer (voir
--                        garde de coherence) ;
--     minutesConnectees: les minutes de connexion dans la fenetre payable
--                        (private.pai_minutes_enseignant), null si la fenetre
--                        est inconnue ;
--     fenetreMinutes   : la longueur de la fenetre payable de la seance
--                        (private.pai_fenetre), null si elle est inconnue.
--   GARDE DE COHERENCE (verite d'abord) : la duree payee n'est affirmee que si
--   le montant que cette duree donnerait (taux de la politique en vigueur dans
--   le mois x eleves presents x duree payee / 60, arrondi comme
--   pai_due_seance) est EXACTEMENT le montant deja ecrit par le serveur. Sinon
--   (seance payee avant PAIE-FENETRE, duree tranchee par la direction, taux
--   change, presence corrigee depuis) minutesPayees est null : l'ecran le dit
--   et renvoie au releve de l'academie, il n'invente jamais une duree. Une
--   seance qui attend la direction (duree indeterminee) n'a pas de duree
--   payee : null.
--   Garde d'acces : compte valide ; l'enseignant ne lit que ses seances
--   (p_enseignant absent ou egal a lui-meme, sinon 42501) ; la direction
--   (role admin) lit celles de l'enseignant qu'elle designe (p_enseignant
--   obligatoire, sinon 22023). Tout autre role : 42501. Lecture seule.
--
-- PREREQUIS : 20261124800000_paie_minutes_reconnexion.sql et
-- 20261124900000_paie_fenetre.sql (fonctions private.pai_fenetre et
-- private.pai_minutes_enseignant), et 20261125310000 (private.pai_minutes_payees,
-- la regle de la duree payee, appelee ici). Le corps est en plpgsql : le fichier se
-- cree meme sans elles (une base rejouee avant leur fusion), mais la lecture
-- refuse alors avec un message clair au lieu de rendre un chiffre faux.
--
-- Fichier sans mot d'effacement (regle B5), sans BEGIN ni COMMIT, rejouable
-- (CREATE OR REPLACE) ; le pilote l'installe, aucun agent ne l'applique en
-- production. Scenario : supabase/tests/scenarios_revenus_duree_payee.sql.

CREATE OR REPLACE FUNCTION public.mes_durees_payees_enseignant(
  p_mois date DEFAULT NULL,
  p_enseignant uuid DEFAULT NULL)
RETURNS jsonb
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  v_uid uuid := auth.uid();
  v_role text;
  v_cible uuid;
  v_zone text;
  v_mois date;
  v_debut timestamptz;
  v_fin timestamptz;
  v_pol public.politiques_commerciales;
  v_res jsonb;
BEGIN
  IF NOT coalesce(v_uid IS NOT NULL AND public.app_account_valid(), false) THEN
    RAISE EXCEPTION 'durees payees reservees aux comptes valides' USING ERRCODE = '42501';
  END IF;
  v_role := public.app_role();
  IF v_role = 'teacher' THEN
    IF p_enseignant IS NOT NULL AND p_enseignant <> v_uid THEN
      RAISE EXCEPTION 'durees payees : seulement les siennes' USING ERRCODE = '42501';
    END IF;
    v_cible := v_uid;
  ELSIF v_role = 'admin' THEN
    IF p_enseignant IS NULL THEN
      RAISE EXCEPTION 'durees payees : enseignant a preciser' USING ERRCODE = '22023';
    END IF;
    v_cible := p_enseignant;
  ELSE
    RAISE EXCEPTION 'durees payees reservees a l''enseignant et a la direction'
      USING ERRCODE = '42501';
  END IF;

  IF pg_catalog.to_regprocedure('private.pai_fenetre(uuid)') IS NULL
     OR pg_catalog.to_regprocedure('private.pai_minutes_enseignant(uuid)') IS NULL
     OR pg_catalog.to_regprocedure('private.pai_minutes_payees(uuid,public.politiques_commerciales)') IS NULL THEN
    RAISE EXCEPTION 'durees payees : la fenetre payable (PAIE-FENETRE) ou 20261125310000 n''est pas installee'
      USING ERRCODE = '55000';
  END IF;

  v_zone := private.bf1_fuseau_comptable();
  v_mois := pg_catalog.date_trunc('month',
    coalesce(p_mois, (pg_catalog.now() AT TIME ZONE v_zone)::date))::date;
  v_debut := v_mois::timestamp AT TIME ZONE v_zone;
  v_fin := (v_mois + interval '1 month')::timestamp AT TIME ZONE v_zone;
  v_pol := private.fac_politique_au(v_mois);

  WITH base AS (
    SELECT r.seance, r.debut,
           f.minutes AS fenetre,
           private.pai_minutes_enseignant(r.seance) AS connectees
      FROM private.pai_releve_seances(v_debut, v_fin) r
      CROSS JOIN LATERAL private.pai_fenetre(r.seance) f
     WHERE r.enseignant = v_cible
  )
  SELECT coalesce(pg_catalog.jsonb_agg(pg_catalog.jsonb_build_object(
           'seanceId', b.seance,
           -- La regle est unique : private.pai_minutes_payees (20261125310000),
           -- garde de coherence comprise. null quand elle n'est pas affirmable.
           'minutesPayees', private.pai_minutes_payees(b.seance, v_pol),
           'minutesConnectees', b.connectees,
           'fenetreMinutes', pg_catalog.round(b.fenetre)::integer)
         ORDER BY b.debut DESC, b.seance), '[]'::jsonb)
    INTO v_res
    FROM base b;

  RETURN v_res;
END;
$function$;

ALTER FUNCTION public.mes_durees_payees_enseignant(date, uuid) OWNER TO postgres;
REVOKE ALL ON FUNCTION public.mes_durees_payees_enseignant(date, uuid) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.mes_durees_payees_enseignant(date, uuid) FROM anon;
REVOKE ALL ON FUNCTION public.mes_durees_payees_enseignant(date, uuid) FROM service_role;
GRANT EXECUTE ON FUNCTION public.mes_durees_payees_enseignant(date, uuid) TO authenticated;

COMMENT ON FUNCTION public.mes_durees_payees_enseignant(date, uuid) IS
  'REVENUS-DUREE-PAYEE (14/11/2026) : par seance du mois, la duree PAYEE (meme regle que private.pai_due_seance, affirmee seulement si elle redonne exactement le montant ecrit), les minutes connectees dans la fenetre payable (PAIE-FENETRE) et la longueur de la fenetre. Garde : compte valide ; enseignant = ses seances, direction = l''enseignant designe. Lecture seule, aucun calcul de montant. Prerequis : 20261124900000.';

DO $postflight$
BEGIN
  IF pg_catalog.has_function_privilege('anon', 'public.mes_durees_payees_enseignant(date,uuid)', 'EXECUTE')
     OR pg_catalog.has_function_privilege('service_role', 'public.mes_durees_payees_enseignant(date,uuid)', 'EXECUTE')
     OR NOT pg_catalog.has_function_privilege('authenticated', 'public.mes_durees_payees_enseignant(date,uuid)', 'EXECUTE') THEN
    RAISE EXCEPTION 'REVENUS-DUREE-PAYEE postflight : droits EXECUTE incorrects';
  END IF;
  IF NOT EXISTS (
       SELECT 1 FROM pg_catalog.pg_proc p
        WHERE p.oid = 'public.mes_durees_payees_enseignant(date,uuid)'::pg_catalog.regprocedure
          AND p.prosecdef
          AND p.proconfig @> ARRAY['search_path=""']::text[]
          AND pg_catalog.pg_get_userbyid(p.proowner) = 'postgres') THEN
    RAISE EXCEPTION 'REVENUS-DUREE-PAYEE postflight : SECURITY DEFINER, search_path ou proprietaire incorrect';
  END IF;
END;
$postflight$;
