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
