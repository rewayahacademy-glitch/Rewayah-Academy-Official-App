-- Lot N3, D3 (03/11/2026) : la mission du controleur et l'envoi de son
-- compte rendu.
--
-- FICHIER SANS MOT D'EFFACEMENT (B5) : le pilote l'installe. Additif (B6) :
-- une table nouvelle, une fonction nouvelle, une fonction remplacee a
-- signature et type de retour identiques ; rien n'est retire. Aucune
-- transaction de premier niveau : l'installateur l'enveloppe.
--
-- 1. public.ma_mission_controle() garde ses gardes (seconde etape de
--    connexion, capacite active, autorisation fraiche RECH-BACK-4, echeance)
--    et ses cles, et rend en plus ce que l'ecran « Controle » affiche
--    (P-CTR-02 point 3, le strict necessaire) : le nom de la Classe, le
--    prenom et le titre public de l'enseignant, le debut et la fin prevus,
--    l'etat de la seance et le nombre d'eleves attendus. Ni nom de famille
--    d'eleve, ni contact.
-- 2. private.controle_comptes_rendus : une ligne par mission, ecrite par la
--    seule fonction ci-dessous ; RLS active, aucun droit direct.
-- 3. public.controleur_envoyer_compte_rendu(p_seance_id, p_choix,
--    p_observation, p_cle) :
--      - p_choix nul : la visite est transmise (decision C2 du 27/09/2026 :
--        des la sortie de la salle, sans geste du controleur) ; idempotent ;
--      - p_choix 'rien_a_signaler', 'ajouter_observation' ou
--        'point_important' : la reponse du controleur est jointe, une seule
--        fois ; la mission passe a rapport_envoye. La meme cle avec la meme
--        reponse rend le meme resultat ; toute autre reponse ensuite est
--        refusee (55000).
--      - une observation (CTR-03A) : nature, domaine, personne, texte, et
--        l'eleve s'il est choisi (un eleve de CETTE seance). Le texte est
--        obligatoire pour un point important ou une intervention de la
--        direction (texteObligatoire, cote client).
--    Seul le controleur de la mission, connexion en deux etapes, capacite
--    active, apres avoir commence la visite (mission en_cours ou controlee).
--    Tout autre role est refuse (42501).
-- 4. public.controleur_lister_rapports() a signature identique : l'Historique
--    rend la reponse choisie, l'observation et l'eleve concerne (prenom et
--    initiale).
-- 5. public.controleur_roster_visite(p_seance_id) : les eleves de la seance
--    observee (prenom et initiale), pour le controleur de la mission.
--
-- Lecteurs recenses (B1) : controle_missions.rapport_envoye est lu par
-- controleur_lister_rapports (statut « envoye ») et historique_tirages ; il
-- prend ici le sens qu'il avait deja (le compte rendu est parti).

-- 1. La mission, avec ce que l'ecran affiche.
CREATE OR REPLACE FUNCTION public.ma_mission_controle()
 RETURNS jsonb
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO ''
AS $function$
BEGIN
  IF public.app_role() = 'controller' AND coalesce(public.app_aal(), 'aal1') <> 'aal2' THEN
    RAISE EXCEPTION 'seconde étape de connexion requise' USING ERRCODE = 'insufficient_privilege';
  END IF;
  RETURN coalesce((
      select pg_catalog.jsonb_build_object(
        'id', m.id,
        'session_id', m.session_id,
        'groupe_id', m.groupe_id,
        'enseignant_effectif_id', m.enseignant_effectif_id,
        'echeance', m.echeance,
        'statut', m.statut,
        'commencee_le', m.commencee_le,
        'classe', g.libelle,
        'enseignant_prenom', t.first_name,
        'enseignant_titre', tp.titre,
        'debut', s.started_at,
        'fin_prevue', s.ended_at,
        'seance_statut', s.status,
        'nombre_eleves', (
          select pg_catalog.count(*)
            from public.session_participants sp
           where sp.session_id = m.session_id
             and sp.role = 'student'
             and sp.deleted_at is null)
      )
        from private.controle_missions m
        join private.controle_capacites c on c.profile_id = m.controleur_id
        join public.profiles p on p.id = auth.uid()
        join public.sessions s on s.id = m.session_id
        join public.groupes g on g.id = m.groupe_id
        join public.profiles t on t.id = m.enseignant_effectif_id
        left join public.teacher_profiles tp on tp.profile_id = m.enseignant_effectif_id
       where m.controleur_id = auth.uid()
         and m.statut in ('attribuee', 'en_cours')
         and m.echeance > pg_catalog.statement_timestamp()
         and c.revoked_at is null
         and c.active_from <= pg_catalog.statement_timestamp()
         and c.expires_at > pg_catalog.statement_timestamp()
         and (c.scope_all_groups
              or m.groupe_id = any(c.scope_group_ids)
              or m.enseignant_effectif_id = any(c.scope_teacher_ids))
         and p.role = 'controller'
         and p.account_status = 'active'
         and p.deleted_at is null
         and (p.access_until is null or p.access_until > pg_catalog.statement_timestamp())
         and public.rech_session_autorisee()
         and public.app_account_valid()
         and public.app_role() = 'controller'
       order by m.affectee_le desc, m.id
       limit 1
    ), '{}'::jsonb);
END;
$function$;
ALTER FUNCTION public.ma_mission_controle() OWNER TO postgres;
REVOKE ALL ON FUNCTION public.ma_mission_controle()
  FROM PUBLIC, anon, service_role, agent_ro;
GRANT EXECUTE ON FUNCTION public.ma_mission_controle() TO authenticated;
COMMENT ON FUNCTION public.ma_mission_controle() IS
  'F86 candidate allowlist: signature=public.ma_mission_controle(); md5_functiondef=A_CALCULER; guard_type=ROLE_POSITIVE_TEMPLATE; owner=postgres; search_path=""; reviewer=Claude a relire; date=2026-11-03. N3 D3 : memes gardes que L1-10 et RECH-BACK-4, projection de l''ecran Controle en plus.';

-- 2. Le compte rendu d'une mission.
CREATE TABLE private.controle_comptes_rendus (
  mission_id uuid PRIMARY KEY REFERENCES private.controle_missions(id),
  controleur_id uuid NOT NULL REFERENCES public.profiles(id),
  transmise_le timestamptz NOT NULL DEFAULT pg_catalog.clock_timestamp(),
  choix text CHECK (choix IS NULL OR choix IN
    ('rien_a_signaler', 'ajouter_observation', 'point_important')),
  observation jsonb CHECK (observation IS NULL OR pg_catalog.jsonb_typeof(observation) = 'object'),
  cle uuid,
  envoye_le timestamptz,
  CONSTRAINT controle_comptes_rendus_envoi CHECK (
    (choix IS NULL AND envoye_le IS NULL AND cle IS NULL AND observation IS NULL)
    OR (choix IS NOT NULL AND envoye_le IS NOT NULL AND cle IS NOT NULL)
  ),
  CONSTRAINT controle_comptes_rendus_observation CHECK (
    observation IS NULL OR choix IN ('ajouter_observation', 'point_important')
  )
);
ALTER TABLE private.controle_comptes_rendus ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON private.controle_comptes_rendus
  FROM PUBLIC, anon, authenticated, service_role, agent_ro;

-- 3. L'envoi.
CREATE FUNCTION public.controleur_envoyer_compte_rendu(
  p_seance_id uuid, p_choix text, p_observation jsonb, p_cle uuid
)
RETURNS jsonb
LANGUAGE plpgsql VOLATILE SECURITY DEFINER SET search_path = ''
AS $function$
DECLARE
  v_mission private.controle_missions%ROWTYPE;
  v_cr private.controle_comptes_rendus%ROWTYPE;
  v_obs jsonb;
  v_texte text;
  v_nature text;
  v_personne text;
  v_eleve uuid;
BEGIN
  IF NOT coalesce(public.app_account_valid() AND public.app_role() = 'controller'
       AND public.app_aal() = 'aal2', false) THEN
    RAISE EXCEPTION 'compte rendu reserve au controleur de la visite' USING ERRCODE = '42501';
  END IF;
  IF p_seance_id IS NULL
     OR (p_choix IS NOT NULL AND p_choix NOT IN
         ('rien_a_signaler', 'ajouter_observation', 'point_important'))
     OR (p_choix IS NOT NULL AND p_cle IS NULL)
     OR (p_observation IS NOT NULL AND coalesce(p_choix, '') NOT IN
         ('ajouter_observation', 'point_important'))
     OR (p_choix IN ('ajouter_observation', 'point_important') AND p_observation IS NULL) THEN
    RAISE EXCEPTION 'compte rendu invalide' USING ERRCODE = '22023';
  END IF;

  SELECT m.* INTO v_mission FROM private.controle_missions m
   WHERE m.session_id = p_seance_id AND m.controleur_id = auth.uid()
   FOR UPDATE;
  IF NOT FOUND OR v_mission.statut NOT IN ('en_cours', 'controlee')
     OR NOT private.b12_mission_autorisee(v_mission.id, false) THEN
    RAISE EXCEPTION 'compte rendu indisponible' USING ERRCODE = '42501';
  END IF;

  IF p_observation IS NOT NULL THEN
    IF pg_catalog.jsonb_typeof(p_observation) <> 'object' THEN
      RAISE EXCEPTION 'observation invalide' USING ERRCODE = '22023';
    END IF;
    v_nature := p_observation ->> 'nature';
    v_personne := p_observation ->> 'personne';
    v_texte := pg_catalog.btrim(coalesce(p_observation ->> 'texte', ''));
    IF v_nature IS NULL OR v_nature NOT IN ('point_positif', 'a_suivre', 'intervention_admin')
       OR coalesce(p_observation ->> 'domaine', '') NOT IN
          ('pedagogie', 'interaction', 'gestion_classe', 'respect_cadre', 'climat', 'autre')
       OR v_personne IS NULL OR v_personne NOT IN
          ('enseignant', 'classe_entiere', 'eleve_precis', 'aucun')
       OR pg_catalog.length(v_texte) > 5000
       OR ((p_choix = 'point_important' OR v_nature = 'intervention_admin') AND v_texte = '')
       OR (v_personne = 'eleve_precis') <> (p_observation ->> 'eleve_id' IS NOT NULL) THEN
      RAISE EXCEPTION 'observation invalide' USING ERRCODE = '22023';
    END IF;
    IF v_personne = 'eleve_precis' THEN
      BEGIN
        v_eleve := (p_observation ->> 'eleve_id')::uuid;
      EXCEPTION WHEN invalid_text_representation THEN
        RAISE EXCEPTION 'observation invalide' USING ERRCODE = '22023';
      END;
      IF NOT EXISTS (SELECT 1 FROM public.session_participants sp
                      WHERE sp.session_id = p_seance_id AND sp.profile_id = v_eleve
                        AND sp.role = 'student' AND sp.deleted_at IS NULL) THEN
        RAISE EXCEPTION 'eleve hors de la seance' USING ERRCODE = '22023';
      END IF;
    END IF;
    v_obs := pg_catalog.jsonb_build_object(
      'important', p_choix = 'point_important',
      'nature', v_nature,
      'domaine', p_observation ->> 'domaine',
      'personne', v_personne,
      'eleve_id', v_eleve,
      'texte', v_texte);
  END IF;

  SELECT cr.* INTO v_cr FROM private.controle_comptes_rendus cr
   WHERE cr.mission_id = v_mission.id FOR UPDATE;
  IF NOT FOUND THEN
    INSERT INTO private.controle_comptes_rendus (mission_id, controleur_id)
    VALUES (v_mission.id, auth.uid())
    RETURNING * INTO v_cr;
  END IF;

  IF p_choix IS NOT NULL THEN
    IF v_cr.choix IS NOT NULL THEN
      IF v_cr.cle IS DISTINCT FROM p_cle OR v_cr.choix IS DISTINCT FROM p_choix
         OR v_cr.observation IS DISTINCT FROM v_obs THEN
        RAISE EXCEPTION 'compte_rendu_deja_envoye' USING ERRCODE = '55000';
      END IF;
    ELSE
      UPDATE private.controle_comptes_rendus
         SET choix = p_choix, observation = v_obs, cle = p_cle,
             envoye_le = pg_catalog.clock_timestamp()
       WHERE mission_id = v_mission.id
       RETURNING * INTO v_cr;
      UPDATE private.controle_missions
         SET rapport_envoye = true, rapport_envoye_le = v_cr.envoye_le
       WHERE id = v_mission.id;
      PERFORM public.log_sensitive_access('n3_compte_rendu_envoye',
        'controle_comptes_rendus', v_mission.id::text,
        pg_catalog.jsonb_build_object('choix', p_choix));
    END IF;
  END IF;

  RETURN pg_catalog.jsonb_build_object(
    'mission_id', v_cr.mission_id,
    'seance_id', p_seance_id,
    'transmise_le', v_cr.transmise_le,
    'choix', v_cr.choix,
    'envoye_le', v_cr.envoye_le);
END;
$function$;
ALTER FUNCTION public.controleur_envoyer_compte_rendu(uuid, text, jsonb, uuid) OWNER TO postgres;
REVOKE ALL ON FUNCTION public.controleur_envoyer_compte_rendu(uuid, text, jsonb, uuid)
  FROM PUBLIC, anon, service_role, agent_ro;
GRANT EXECUTE ON FUNCTION public.controleur_envoyer_compte_rendu(uuid, text, jsonb, uuid)
  TO authenticated;
COMMENT ON FUNCTION public.controleur_envoyer_compte_rendu(uuid, text, jsonb, uuid) IS
  'F86 candidate allowlist: signature=public.controleur_envoyer_compte_rendu(uuid,text,jsonb,uuid); md5_functiondef=A_CALCULER; guard_type=ROLE_POSITIVE_TEMPLATE; owner=postgres; search_path=""; reviewer=Claude a relire; date=2026-11-03. N3 D3 : controleur de la mission, aal2, capacite active, visite commencee.';

-- 4. L'Historique rend la reponse choisie et l'observation jointe (N3) :
--    controleur_lister_rapports, a signature identique, lit
--    private.controle_comptes_rendus ; l'eleve concerne n'est rendu que par
--    son prenom et l'initiale de son nom (C8), comme les presents.
CREATE OR REPLACE FUNCTION public.controleur_lister_rapports()
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
DECLARE v_result jsonb;
BEGIN
  IF NOT coalesce(public.app_account_valid() AND (
    public.app_role()='admin' OR EXISTS(SELECT 1 FROM private.controle_capacites c
      JOIN public.profiles p ON p.id=c.profile_id WHERE c.profile_id=auth.uid()
        AND c.revoked_at IS NULL AND c.active_from<=pg_catalog.clock_timestamp()
        AND c.expires_at>pg_catalog.clock_timestamp() AND p.role='controller'
        AND p.account_status='active' AND p.deleted_at IS NULL
        AND (p.access_until IS NULL OR p.access_until>pg_catalog.clock_timestamp()))),false) THEN
    RAISE EXCEPTION 'B12 non autorise' USING ERRCODE='42501';
  END IF;
  IF public.app_role() = 'controller' AND coalesce(public.app_aal(), 'aal1') <> 'aal2' THEN
    RAISE EXCEPTION 'seconde étape de connexion requise' USING ERRCODE = 'insufficient_privilege';
  END IF;
  SELECT coalesce(pg_catalog.jsonb_agg(pg_catalog.jsonb_build_object(
    'id',r.id,'mission_id',r.mission_id,'seance_id',r.session_id,'classe',r.classe,
    'enseignant',r.enseignant,'debut',r.debut,'duree_observee_secondes',r.duree_observee_secondes,
    'statut',CASE WHEN c.id IS NOT NULL THEN 'complement_ajoute'
                  WHEN m.rapport_envoye THEN 'envoye' ELSE 'a_terminer' END,
    'faits',r.faits,'choix',cr.choix,'observation',cr.observation,
    'eleve',CASE WHEN ev.id IS NULL THEN null ELSE pg_catalog.concat_ws(' ',ev.first_name,
      CASE WHEN pg_catalog.btrim(coalesce(ev.last_name,''))='' THEN NULL
           ELSE pg_catalog.upper(pg_catalog.left(pg_catalog.btrim(ev.last_name),1))||'.' END) END,
    'presents',to_jsonb(r.presents),
    'complements',coalesce(cpl.liste,'[]'::jsonb)
  ) ORDER BY r.debut DESC), '[]'::jsonb) INTO v_result
  FROM public.rapports_mission r
  JOIN private.controle_missions m ON m.id=r.mission_id
  LEFT JOIN private.controle_comptes_rendus cr ON cr.mission_id=r.mission_id
  LEFT JOIN public.profiles ev ON ev.id=(cr.observation->>'eleve_id')::uuid
  LEFT JOIN LATERAL (SELECT c.id FROM public.rapport_complements c WHERE c.rapport_id=r.id
    ORDER BY c.cree_le DESC,c.id DESC LIMIT 1) c ON true
  LEFT JOIN LATERAL (SELECT pg_catalog.jsonb_agg(pg_catalog.jsonb_build_object(
    'date',c.cree_le,'texte',c.texte,'motif',c.motif,
    'auteur',CASE WHEN c.auteur_id=auth.uid() THEN null ELSE 'Administration' END
  ) ORDER BY c.cree_le,c.id) AS liste FROM public.rapport_complements c WHERE c.rapport_id=r.id) cpl ON true
  WHERE (r.controleur_id=auth.uid() OR public.app_role()='admin')
    AND private.b12_mission_autorisee(r.mission_id,true);
  PERFORM public.log_sensitive_access('b12_lire_rapports','rapports_mission',auth.uid()::text,'{}'::jsonb);
  RETURN v_result;
END;
$function$;
COMMENT ON FUNCTION public.controleur_lister_rapports() IS
  'B12 + N3 D3 (03/11/2026) : la reponse du controleur et son observation, lues dans private.controle_comptes_rendus ; memes gardes que L1-10.';

-- 5. Le roster de la visite (CTR-03A) : les eleves de CETTE seance, prenom et
--    initiale du nom (decision C7 = a, minimum C8), pour le seul controleur
--    de la mission, apres le debut de la visite. Jamais le nom de famille
--    entier, jamais un contact.
CREATE FUNCTION public.controleur_roster_visite(p_seance_id uuid)
RETURNS jsonb
LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path = ''
AS $function$
DECLARE v_mission private.controle_missions%ROWTYPE;
BEGIN
  IF NOT coalesce(public.app_account_valid() AND public.app_role() = 'controller'
       AND public.app_aal() = 'aal2', false) THEN
    RAISE EXCEPTION 'roster reserve au controleur de la visite' USING ERRCODE = '42501';
  END IF;
  SELECT m.* INTO v_mission FROM private.controle_missions m
   WHERE m.session_id = p_seance_id AND m.controleur_id = auth.uid();
  IF NOT FOUND OR v_mission.statut NOT IN ('en_cours', 'controlee')
     OR NOT private.b12_mission_autorisee(v_mission.id, false) THEN
    RAISE EXCEPTION 'roster indisponible' USING ERRCODE = '42501';
  END IF;
  RETURN coalesce((
    SELECT pg_catalog.jsonb_agg(pg_catalog.jsonb_build_object(
      'id', p.id,
      'prenom', p.first_name,
      'initiale', CASE WHEN pg_catalog.btrim(coalesce(p.last_name, '')) = '' THEN NULL
                       ELSE pg_catalog.upper(pg_catalog.left(pg_catalog.btrim(p.last_name), 1)) END
    ) ORDER BY p.first_name, p.id)
      FROM public.session_participants sp
      JOIN public.profiles p ON p.id = sp.profile_id
     WHERE sp.session_id = p_seance_id AND sp.role = 'student' AND sp.deleted_at IS NULL
  ), '[]'::jsonb);
END;
$function$;
ALTER FUNCTION public.controleur_roster_visite(uuid) OWNER TO postgres;
REVOKE ALL ON FUNCTION public.controleur_roster_visite(uuid)
  FROM PUBLIC, anon, service_role, agent_ro;
GRANT EXECUTE ON FUNCTION public.controleur_roster_visite(uuid) TO authenticated;
COMMENT ON FUNCTION public.controleur_roster_visite(uuid) IS
  'F86 candidate allowlist: signature=public.controleur_roster_visite(uuid); md5_functiondef=A_CALCULER; guard_type=ROLE_POSITIVE_TEMPLATE; owner=postgres; search_path=""; reviewer=Claude a relire; date=2026-11-03. N3 D3 : roster de la visite, prenom et initiale.';

-- Postflight.
DO $postflight$
DECLARE
  v_f regprocedure := 'public.controleur_envoyer_compte_rendu(uuid,text,jsonb,uuid)'::regprocedure;
  v_m regprocedure := 'public.ma_mission_controle()'::regprocedure;
  v_r regprocedure := 'public.controleur_roster_visite(uuid)'::regprocedure;
  v_l regprocedure := 'public.controleur_lister_rapports()'::regprocedure;
BEGIN
  IF NOT has_function_privilege('authenticated', v_f, 'EXECUTE')
     OR has_function_privilege('anon', v_f, 'EXECUTE')
     OR has_function_privilege('service_role', v_f, 'EXECUTE')
     OR has_function_privilege('agent_ro', v_f, 'EXECUTE')
     OR NOT has_function_privilege('authenticated', v_m, 'EXECUTE')
     OR has_function_privilege('anon', v_m, 'EXECUTE')
     OR NOT has_function_privilege('authenticated', v_r, 'EXECUTE')
     OR has_function_privilege('anon', v_r, 'EXECUTE')
     OR has_function_privilege('agent_ro', v_r, 'EXECUTE')
     OR NOT has_function_privilege('authenticated', v_l, 'EXECUTE')
     OR has_function_privilege('anon', v_l, 'EXECUTE') THEN
    RAISE EXCEPTION 'N3 postflight : droits EXECUTE inattendus';
  END IF;
  IF (SELECT count(*) FROM pg_catalog.pg_proc p
       WHERE p.oid IN (v_f, v_m, v_r, v_l) AND p.prosecdef
         AND 'search_path=""' = ANY(coalesce(p.proconfig, ARRAY[]::text[]))
         AND pg_catalog.strpos(p.prosrc, 'app_aal()') > 0) <> 4 THEN
    RAISE EXCEPTION 'N3 postflight : garde, definer ou search_path absent';
  END IF;
  IF NOT (SELECT c.relrowsecurity FROM pg_catalog.pg_class c
           WHERE c.oid = 'private.controle_comptes_rendus'::regclass)
     OR has_table_privilege('authenticated', 'private.controle_comptes_rendus', 'SELECT')
     OR has_table_privilege('anon', 'private.controle_comptes_rendus', 'SELECT')
     OR has_table_privilege('agent_ro', 'private.controle_comptes_rendus', 'SELECT') THEN
    RAISE EXCEPTION 'N3 postflight : table des comptes rendus exposee';
  END IF;
END;
$postflight$;
