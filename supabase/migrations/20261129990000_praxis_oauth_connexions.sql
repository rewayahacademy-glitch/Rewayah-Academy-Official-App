-- PX-OAUTH 2e (Pilote Equipe, 19/11/2026) : la liste des CONNEXIONS de claude.ai a Praxis, pour la section Praxis d'« Acces des agents » :
-- UNE ligne par connexion (et non une par cle d'une heure), revocable. Additif :
--   * `direction_praxis_oauth_connexions()` : lecture de la direction (administrateur valide), 50 connexions au plus, l'etat vient de la
--     base ; aucun secret, aucune empreinte ;
--   * `direction_praxis_oauth_revoquer(uuid, text)` : la direction avec double verification (aal2), motif obligatoire ; revoque la connexion
--     et toutes ses cles (aide privee de 2b) ; une ligne d'audit ;
--   * retouche ancree de `direction_praxis_etat()` : la liste des cles ne montre plus les cles nees d'une connexion (il y en a une par heure
--     et par renouvellement : elles noieraient les vraies cles) ; elles restent revocables par leur connexion.
-- Aucun mot d'effacement dans ce fichier ; preflight sur l'empreinte de la fonction retouchee, postflight sur le resultat.

DO $pre$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_attribute a WHERE a.attrelid = 'private.praxis_cles'::regclass AND a.attname = 'connexion_id' AND NOT a.attisdropped) THEN
    RAISE EXCEPTION 'PX-OAUTH 2e : la migration 20261129980000 (2b) doit etre installee avant';
  END IF;
  IF pg_catalog.md5((SELECT p.prosrc FROM pg_proc p WHERE p.oid = 'public.direction_praxis_etat()'::regprocedure)) <> '9749fca23079af45d5b099e56e7b8435' THEN
    RAISE EXCEPTION 'PX-OAUTH 2e : public.direction_praxis_etat() n''a pas l''empreinte attendue ; relire avant de la retoucher';
  END IF;
END
$pre$;

CREATE FUNCTION public.direction_praxis_oauth_connexions()
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
  RETURN coalesce((
    SELECT pg_catalog.jsonb_agg(pg_catalog.jsonb_build_object(
             'id', c.id,
             'client', cl.nom,
             'creeLe', c.cree_le,
             'derniereUtilisationLe', greatest(c.derniere_utilisation_le,
               (SELECT pg_catalog.max(k.derniere_utilisation_le) FROM private.praxis_cles k WHERE k.connexion_id = c.id)),
             'expireLe', c.absolue_expire_le,
             'revoqueeLe', c.revoquee_le,
             'motifRevocation', c.motif_revocation,
             -- L'etat vient de la base (son horloge), jamais d'une comparaison faite sur le poste.
             'etat', CASE WHEN c.revoquee_le IS NOT NULL THEN 'revoquee'
                          WHEN c.absolue_expire_le <= pg_catalog.clock_timestamp() THEN 'expiree' ELSE 'active' END)
           ORDER BY c.cree_le DESC, c.id)
      FROM (SELECT * FROM private.praxis_oauth_connexions x ORDER BY x.cree_le DESC, x.id LIMIT 50) c
      JOIN private.praxis_oauth_clients cl ON cl.client_id = c.client_id), '[]'::jsonb);
END;
$f$;

CREATE FUNCTION public.direction_praxis_oauth_revoquer(p_id uuid, p_motif text)
RETURNS boolean
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $f$
DECLARE
  v_motif text := pg_catalog.btrim(coalesce(p_motif, ''));
  v_c private.praxis_oauth_connexions%ROWTYPE;
BEGIN
  IF NOT coalesce(public.app_account_valid() AND public.app_role() = 'admin'
                  AND auth.jwt() ->> 'aal' = 'aal2', false) THEN
    RAISE EXCEPTION 'autorisation direction avec MFA requise' USING ERRCODE = '42501';
  END IF;
  IF p_id IS NULL OR pg_catalog.length(v_motif) NOT BETWEEN 1 AND 240 THEN
    RAISE EXCEPTION 'motif de revocation invalide' USING ERRCODE = '22023';
  END IF;
  SELECT c.* INTO v_c FROM private.praxis_oauth_connexions c WHERE c.id = p_id FOR UPDATE;
  IF NOT FOUND OR v_c.revoquee_le IS NOT NULL THEN
    RETURN false;
  END IF;
  PERFORM private.praxis_oauth_revoquer_connexion(p_id, auth.uid(), v_motif);
  -- Le motif est un texte de la direction : il reste au registre de la connexion, pas dans l'audit.
  PERFORM public.log_sensitive_access('praxis_oauth_revocation', 'private.praxis_oauth_connexions', p_id::text,
    pg_catalog.jsonb_build_object('client', v_c.client_id));
  RETURN true;
END;
$f$;

REVOKE ALL ON FUNCTION public.direction_praxis_oauth_connexions(), public.direction_praxis_oauth_revoquer(uuid, text)
  FROM PUBLIC, anon, authenticated, service_role, agent_ro;
GRANT EXECUTE ON FUNCTION public.direction_praxis_oauth_connexions(), public.direction_praxis_oauth_revoquer(uuid, text) TO authenticated;

-- Retouche ancree de direction_praxis_etat() : les cles nees d'une connexion ne figurent plus dans la liste des cles.
CREATE OR REPLACE FUNCTION public.direction_praxis_etat()
 RETURNS jsonb
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO ''
AS $f$
BEGIN
  IF NOT coalesce(public.app_account_valid() AND public.app_role() = 'admin', false) THEN
    RAISE EXCEPTION 'autorisation direction requise' USING ERRCODE = '42501';
  END IF;
  RETURN (SELECT pg_catalog.jsonb_build_object(
    'actif', r.actif,
    'autonome', r.autonome,
    'envoisParHeure', r.envois_par_heure,
    'appelsParHeure', r.appels_par_heure,
    'modifieLe', r.modifie_le,
    'essaiFils', pg_catalog.to_jsonb(r.essai_fils),
    'donneesReelles', r.donnees_reelles,
    'derniereRoutine', (
      SELECT pg_catalog.jsonb_build_object(
               'termineLe', t.termine_le, 'issue', t.issue, 'filsLus', t.fils_lus,
               'messagesEnvoyes', t.messages_envoyes, 'passesEquipe', t.passes_equipe,
               'refus', t.refus, 'note', t.note)
        FROM private.praxis_tirs t ORDER BY t.termine_le DESC, t.id DESC LIMIT 1),
    'cles', coalesce((
      SELECT pg_catalog.jsonb_agg(pg_catalog.jsonb_build_object(
               'id', c.id, 'libelle', c.libelle, 'prefixe', c.prefixe, 'usage', c.usage,
               'emiseLe', c.emise_le, 'expireLe', c.expire_le, 'derniereUtilisationLe', c.derniere_utilisation_le,
               'revoqueeLe', c.revoquee_le, 'motifRevocation', c.motif_revocation,
               -- L'etat vient de la base (son horloge), jamais d'une comparaison faite sur le poste (meme regle que jetons_agent_actifs).
               'etat', CASE WHEN c.revoquee_le IS NOT NULL THEN 'revoquee'
                            WHEN c.expire_le <= pg_catalog.clock_timestamp() THEN 'expiree' ELSE 'active' END)
             ORDER BY c.emise_le DESC, c.id)
        FROM (SELECT * FROM private.praxis_cles x WHERE x.connexion_id IS NULL ORDER BY x.emise_le DESC, x.id LIMIT 100) c), '[]'::jsonb))
    FROM private.praxis_reglages r);
END;
$f$
;

-- Controle apres coup.
DO $post$
BEGIN
  IF (SELECT p.prosrc FROM pg_proc p WHERE p.oid = 'public.direction_praxis_etat()'::regprocedure) NOT LIKE '%x.connexion_id IS NULL%' THEN
    RAISE EXCEPTION 'PX-OAUTH 2e : retouche de direction_praxis_etat absente';
  END IF;
  IF has_function_privilege('anon', 'public.direction_praxis_oauth_revoquer(uuid,text)', 'EXECUTE')
     OR has_function_privilege('service_role', 'public.direction_praxis_oauth_revoquer(uuid,text)', 'EXECUTE')
     OR NOT has_function_privilege('authenticated', 'public.direction_praxis_oauth_revoquer(uuid,text)', 'EXECUTE')
     OR has_function_privilege('anon', 'public.direction_praxis_oauth_connexions()', 'EXECUTE') THEN
    RAISE EXCEPTION 'PX-OAUTH 2e : droits inattendus';
  END IF;
END
$post$;
