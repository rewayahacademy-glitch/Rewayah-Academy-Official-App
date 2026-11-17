-- DETTE-CONTROLLER (sécurité) : un compte `controller` sans capacité de contrôle lisait par l'API
-- neuf tables. Aucune écriture, aucun DROP : uniquement CREATE FUNCTION + ALTER POLICY (les rôles
-- cibles restent ceux de chaque politique).
--
-- Ce qu'il lui faut réellement : ses écrans n'utilisent que des RPC SECURITY DEFINER
-- (ma_mission_controle, controleur_*, capacites_tirage_controle) et des vues security_barrier
-- exécutées avec les droits du propriétaire (mes_seances_v, presence_seance_v, session_peers_v).
-- Aucune ne dépend de ces lectures. Donc :
--  - sessions, session_participants, session_events, session_recordings : le contrôleur ne lit
--    que la séance d'une mission qui lui est attribuée, ouverte, dans sa capacité active (aal2,
--    non révoquée, dans sa fenêtre, dans son périmètre) ;
--  - matching_requests, intentions_horaire, offres_horaires (hors publiées), availability_slots,
--    teacher_student_assignments : rien ne justifie une lecture de contrôle ; la branche
--    controller disparaît. Admin (et comptable là où il l'avait) inchangés.
CREATE OR REPLACE FUNCTION public.controleur_voit_session(p_session_id uuid)
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path TO ''
AS $f$
  SELECT coalesce(
    public.app_account_valid()
    AND public.app_role() = 'controller'
    AND auth.uid() IS NOT NULL
    AND auth.jwt() ->> 'aal' = 'aal2'
    AND EXISTS (
      SELECT 1
        FROM private.controle_missions m
        JOIN private.controle_capacites c ON c.profile_id = m.controleur_id
        JOIN public.profiles p ON p.id = m.controleur_id
       WHERE m.session_id = p_session_id
         AND m.controleur_id = auth.uid()
         AND m.statut IN ('attribuee', 'en_cours')
         AND m.echeance > pg_catalog.clock_timestamp()
         AND c.revoked_at IS NULL
         AND c.active_from <= pg_catalog.clock_timestamp()
         AND c.expires_at > pg_catalog.clock_timestamp()
         AND (c.scope_all_groups
              OR m.groupe_id = ANY (c.scope_group_ids)
              OR m.enseignant_effectif_id = ANY (c.scope_teacher_ids))
         AND p.role = 'controller'
         AND p.account_status = 'active' AND p.deleted_at IS NULL
         AND (p.access_until IS NULL OR p.access_until > pg_catalog.clock_timestamp())
    ),
    false);
$f$;
REVOKE ALL ON FUNCTION public.controleur_voit_session(uuid) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.controleur_voit_session(uuid) TO authenticated;

ALTER POLICY sessions_read_privileged ON public.sessions
  USING (( SELECT app_account_valid() ) AND deleted_at IS NULL
         AND (( SELECT app_role() ) = 'accountant'::app_role
              OR public.controleur_voit_session(id)));

ALTER POLICY session_participants_controller_read ON public.session_participants
  USING (( SELECT app_account_valid() ) AND ( SELECT app_role() ) = 'controller'::app_role
         AND deleted_at IS NULL
         AND role <> ALL (ARRAY['masked_controller'::participant_role, 'admin_masked'::participant_role])
         AND public.controleur_voit_session(session_id));

ALTER POLICY session_events_controller_read ON public.session_events
  USING (( SELECT app_account_valid() ) AND ( SELECT app_role() ) = 'controller'::app_role
         AND NOT est_observateur_masque(session_id, profile_id)
         AND public.controleur_voit_session(session_id));

ALTER POLICY session_recordings_admin_controller ON public.session_recordings
  USING (( SELECT app_account_valid() ) AND deleted_at IS NULL
         AND (( SELECT app_role() ) = 'admin'::app_role
              OR public.controleur_voit_session(session_id)));

ALTER POLICY matching_requests_privileged_read ON public.matching_requests
  USING (COALESCE((( SELECT app_role() ) = 'admin'::app_role) AND ( SELECT app_account_valid() ), false));

ALTER POLICY intentions_horaire_parties ON public.intentions_horaire
  USING ((partie_concernee(eleve_id) AND ( SELECT app_role() ) IS DISTINCT FROM 'controller'::app_role)
         OR COALESCE((( SELECT app_role() ) = 'admin'::app_role) AND ( SELECT app_account_valid() ), false));

ALTER POLICY offres_horaires_vitrine ON public.offres_horaires
  USING (etat = 'publiee'
         OR COALESCE((( SELECT app_role() ) = 'admin'::app_role) AND ( SELECT app_account_valid() ), false));

ALTER POLICY availability_slots_reader ON public.availability_slots
  USING (( SELECT app_account_valid() ) AND deleted_at IS NULL
         AND partie_concernee(teacher_id) AND ( SELECT app_role() ) IS DISTINCT FROM 'controller'::app_role);

ALTER POLICY assignments_privileged_read ON public.teacher_student_assignments
  USING (COALESCE((( SELECT app_role() ) = ANY (ARRAY['admin'::app_role, 'accountant'::app_role]))
                  AND ( SELECT app_account_valid() ), false));

-- Deuxième voie de lecture : partie_concernee() rend vrai pour tout admin ou contrôleur au compte
-- valide (GARDE-COMPTE-DESACTIVE). On ne la modifie pas (elle sert aussi à regle_effective, demander,
-- rechercher_personne_par_matricule et deux vues) ; on exclut le contrôleur dans les politiques.
ALTER POLICY matching_requests_parties_read ON public.matching_requests
  USING (requested_by = ( SELECT auth.uid() )
         OR (partie_concernee(subject_profile_id) AND ( SELECT app_role() ) IS DISTINCT FROM 'controller'::app_role));

ALTER POLICY assignments_parties_read ON public.teacher_student_assignments
  USING ((partie_concernee(student_id) AND ( SELECT app_role() ) IS DISTINCT FROM 'controller'::app_role)
         OR teacher_id = ( SELECT auth.uid() ));

-- Deux autres tables ouvertes au contrôleur par la même voie (arbitrage du pilote, 17/11).
ALTER POLICY weekly_availability_parties_read ON public.weekly_availability
  USING (partie_concernee(profile_id) AND ( SELECT app_role() ) IS DISTINCT FROM 'controller'::app_role);

ALTER POLICY rule_overrides_parties_read ON public.rule_overrides
  USING (partie_concernee(profile_id) AND ( SELECT app_role() ) IS DISTINCT FROM 'controller'::app_role);

-- mes_seances_v (planning global du contrôleur) : vue security_barrier, exécutée avec les droits du
-- propriétaire, donc elle n'héritait pas du resserrement de `sessions`. Seule la branche
-- « admin ou controller » change : admin garde tout, le contrôleur ne voit que la séance de sa mission.
-- Colonnes, options et droits inchangés (définition de production relue : même empreinte que le local).
CREATE OR REPLACE VIEW public.mes_seances_v WITH (security_barrier = true) AS
SELECT s.id AS session_id,
    s.started_at,
    s.ended_at,
    s.status,
    s.session_type,
    s.prayer_pause_minutes,
    eleve.id AS student_id,
        CASE
            WHEN agent_identite_masquee() THEN eleve.immutable_id
            ELSE eleve.first_name
        END AS student_first_name,
    eleve.immutable_id AS student_immutable_id,
    ens.id AS teacher_id,
        CASE
            WHEN agent_identite_masquee() THEN ens.immutable_id
            ELSE ens.first_name
        END AS teacher_first_name,
    ens.immutable_id AS teacher_immutable_id,
        CASE
            WHEN agent_identite_masquee() THEN NULL::text
            ELSE tp.country
        END AS teacher_country,
    s.groupe_id,
    cl.libelle AS groupe_libelle
   FROM sessions s
     JOIN session_participants spe ON spe.session_id = s.id AND spe.role = 'student'::participant_role AND spe.deleted_at IS NULL
     JOIN profiles eleve ON eleve.id = spe.profile_id AND eleve.deleted_at IS NULL
     JOIN profiles ens ON ens.id = s.teacher_id AND ens.deleted_at IS NULL
     LEFT JOIN teacher_profiles tp ON tp.profile_id = ens.id AND tp.deleted_at IS NULL
     LEFT JOIN groupes cl ON cl.id = s.groupe_id
  WHERE s.deleted_at IS NULL AND app_account_valid() AND (app_role() = 'teacher'::app_role AND s.teacher_id = auth.uid() OR (app_role() = 'student'::app_role AND spe.profile_id = auth.uid() OR app_role() = 'guardian'::app_role AND eleve.household_id IS NOT NULL AND eleve.household_id = app_household_id()) AND NOT (EXISTS ( SELECT 1
           FROM groupe_membres gm
          WHERE gm.groupe_id = s.groupe_id AND gm.student_id = eleve.id AND gm.left_at IS NOT NULL AND gm.left_at <= s.started_at AND NOT (EXISTS ( SELECT 1
                   FROM groupe_membres gm2
                  WHERE gm2.groupe_id = s.groupe_id AND gm2.student_id = eleve.id AND gm2.left_at IS NULL)))) AND NOT (EXISTS ( SELECT 1
           FROM groupes g
          WHERE g.id = s.groupe_id AND g.ended_at IS NOT NULL AND g.ended_at <= s.started_at)) OR app_role() = 'admin'::app_role OR public.controleur_voit_session(s.id));
