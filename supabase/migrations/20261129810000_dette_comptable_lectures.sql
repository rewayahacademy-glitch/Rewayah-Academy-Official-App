-- DETTE-COMPTABLE (sécurité, suite de DETTE-CONTROLLER 20261129800000) : le rôle `accountant` lisait
-- `sessions` et `teacher_student_assignments` directement par l'API. Aucun DROP / DELETE / TRUNCATE :
-- deux ALTER POLICY, rôles cibles conservés.
--
-- Inventaire (lib/ et base) : aucun écran du comptable ne lit ces deux tables (lib/features/comptable
-- n'appelle ni .from ni .rpc sur elles) ; aucune fonction INVOKER ne les lit ; les huit vues qui les
-- joignent sont security_barrier (droits du propriétaire). La paie (47 %, élève présent par heure,
-- DECISION-TARIFS-2026-10-18) passe par releve_paie_mensuel / releve_paie_seances / pai_releve_seances,
-- toutes SECURITY DEFINER, gardées par pai_releve_autorise() (admin ou accountant) : elles lisent
-- `sessions` avec les droits du propriétaire et n'ont pas besoin de la politique.
-- Donc la branche accountant disparaît ; admin et contrôleur (capacité) inchangés.
ALTER POLICY sessions_read_privileged ON public.sessions
  USING (( SELECT app_account_valid() ) AND deleted_at IS NULL
         AND public.controleur_voit_session(id));

ALTER POLICY assignments_privileged_read ON public.teacher_student_assignments
  USING (COALESCE(( SELECT app_role() ) = 'admin'::app_role AND ( SELECT app_account_valid() ), false));
