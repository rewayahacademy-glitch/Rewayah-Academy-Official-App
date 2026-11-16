-- PX-3 (pilote, 16/11/2026, etape 9 de la checklist) : les deux LECTURES de la direction pour l'ecran « Praxis » de « Acces des
-- agents IA ». Les portes d'ECRITURE existent (20261129600000 : emettre / revoquer une cle, regler) ; l'ecran avait besoin de lire.
--   * public.direction_praxis_etat()     : l'interrupteur, le mode, le plafond par heure, et la liste des cles (100 au plus, les plus
--                                          recentes) : id, libelle, prefixe, usage, emise le, expire le, derniere utilisation, revoquee.
--                                          Jamais l'empreinte ni le secret (montre une seule fois a l'emission).
--   * public.direction_praxis_journal(p_limite, p_avant) : « ce que Praxis a envoye » : les lignes de l'outil ecrire et annoncer du journal
--                                          (outil, issue, heure, fil, extrait de 300 signes au plus du texte QUE PRAXIS A ENVOYE), les plus
--                                          recentes d'abord, par curseur (p_avant = l'identifiant de la derniere ligne recue). Le journal ne
--                                          contient jamais le texte d'un tiers (R11) : aucune autre colonne n'est rendue.
-- Garde (exigence positive) : administrateur au compte valide. La double verification (aal2) n'est PAS exigee pour LIRE (decision du pilote) ;
-- elle reste exigee par les portes d'ecriture. Executables par `authenticated` seul ; ni anon, ni service_role, ni agent_ro.
-- Aucune ecriture, aucun journal d'acces (lecture de ce que Praxis a lui-meme ecrit : aucune donnee de tiers).
-- FICHIER SANS EFFACEMENT. Additif. Sans BEGIN/COMMIT de premier niveau.

CREATE FUNCTION public.direction_praxis_etat()
RETURNS jsonb
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $f$
BEGIN
  IF NOT coalesce(public.app_account_valid() AND public.app_role() = 'admin', false) THEN
    RAISE EXCEPTION 'autorisation direction requise' USING ERRCODE = '42501';
  END IF;
  RETURN (SELECT pg_catalog.jsonb_build_object(
    'actif', r.actif,
    'autonome', r.autonome,
    'envoisParHeure', r.envois_par_heure,
    'modifieLe', r.modifie_le,
    'cles', coalesce((
      SELECT pg_catalog.jsonb_agg(pg_catalog.jsonb_build_object(
               'id', c.id, 'libelle', c.libelle, 'prefixe', c.prefixe, 'usage', c.usage,
               'emiseLe', c.emise_le, 'expireLe', c.expire_le, 'derniereUtilisationLe', c.derniere_utilisation_le,
               'revoqueeLe', c.revoquee_le, 'motifRevocation', c.motif_revocation)
             ORDER BY c.emise_le DESC, c.id)
        FROM (SELECT * FROM private.praxis_cles x ORDER BY x.emise_le DESC, x.id LIMIT 100) c), '[]'::jsonb))
    FROM private.praxis_reglages r);
END;
$f$;

CREATE FUNCTION public.direction_praxis_journal(p_limite integer DEFAULT 50, p_avant bigint DEFAULT NULL)
RETURNS jsonb
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $f$
DECLARE
  v_lignes jsonb;
  v_suite bigint;
BEGIN
  IF NOT coalesce(public.app_account_valid() AND public.app_role() = 'admin', false) THEN
    RAISE EXCEPTION 'autorisation direction requise' USING ERRCODE = '42501';
  END IF;
  IF p_limite IS NULL OR p_limite NOT BETWEEN 1 AND 100 THEN
    RAISE EXCEPTION 'limite invalide : 1 a 100' USING ERRCODE = '22023';
  END IF;
  SELECT coalesce(pg_catalog.jsonb_agg(pg_catalog.jsonb_build_object(
           'id', j.id, 'outil', j.outil, 'issue', j.issue, 'heure', j.cree_le, 'fil', j.fil_id,
           'extrait', pg_catalog.left(j.texte_envoye, 300)) ORDER BY j.id DESC), '[]'::jsonb),
         CASE WHEN pg_catalog.count(*) = p_limite THEN pg_catalog.min(j.id) END
    INTO v_lignes, v_suite
    FROM (SELECT x.* FROM private.praxis_journal x
           WHERE x.outil IN ('ecrire', 'annoncer') AND (p_avant IS NULL OR x.id < p_avant)
           ORDER BY x.id DESC LIMIT p_limite) j;
  RETURN pg_catalog.jsonb_build_object('lignes', v_lignes, 'suite', v_suite);
END;
$f$;

REVOKE ALL ON FUNCTION public.direction_praxis_etat(), public.direction_praxis_journal(integer, bigint)
  FROM PUBLIC, anon, authenticated, service_role, agent_ro;
GRANT EXECUTE ON FUNCTION public.direction_praxis_etat(), public.direction_praxis_journal(integer, bigint) TO authenticated;

DO $postflight$
BEGIN
  IF NOT pg_catalog.has_function_privilege('authenticated', 'public.direction_praxis_etat()', 'EXECUTE')
     OR NOT pg_catalog.has_function_privilege('authenticated', 'public.direction_praxis_journal(integer,bigint)', 'EXECUTE')
     OR pg_catalog.has_function_privilege('anon', 'public.direction_praxis_etat()', 'EXECUTE')
     OR pg_catalog.has_function_privilege('anon', 'public.direction_praxis_journal(integer,bigint)', 'EXECUTE')
     OR pg_catalog.has_function_privilege('service_role', 'public.direction_praxis_etat()', 'EXECUTE')
     OR pg_catalog.has_function_privilege('agent_ro', 'public.direction_praxis_journal(integer,bigint)', 'EXECUTE') THEN
    RAISE EXCEPTION 'PRAXIS-LECTURES : droits incorrects apres installation';
  END IF;
END
$postflight$;
