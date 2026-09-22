-- Scenarios de forme et de securite du lot titulaire/remplacement/Admin.
-- Les fixtures metier completes restent chargees par le harness Core24.

do $$
begin
  if to_regprocedure('core24_private.enseignant_autorise(uuid)') is null then
    raise exception 'TEACHER : helper de conformite absent';
  end if;
  if to_regprocedure('public.affecter_titulaire_groupe(uuid,uuid,text)') is null then
    raise exception 'TEACHER : affectation titulaire absente';
  end if;
  if to_regprocedure('public.demander_remplacement_session(uuid)') is null
     or to_regprocedure('public.accepter_invitation_remplacement(uuid)') is null then
    raise exception 'SESSION : flux de remplacement incomplet';
  end if;
  if to_regprocedure('public.intentions_pool_admin(uuid)') is null
     or to_regprocedure('public.offres_horaires_admin()') is null then
    raise exception 'ADMIN : surface offres/pool absente';
  end if;
end $$;

do $$
begin
  if has_function_privilege(
    'anon', 'public.affecter_titulaire_groupe(uuid,uuid,text)', 'EXECUTE'
  ) then
    raise exception 'TEACHER SECURITE : anon peut affecter un titulaire';
  end if;
  if has_function_privilege(
    'agent_ro', 'public.accepter_invitation_remplacement(uuid)', 'EXECUTE'
  ) then
    raise exception 'SESSION SECURITE : agent_ro peut accepter une invitation';
  end if;
  if has_table_privilege(
    'authenticated', 'public.session_teacher_invitations', 'INSERT'
  ) then
    raise exception 'SESSION SECURITE : ecriture directe des invitations';
  end if;
  if has_table_privilege(
    'authenticated', 'public.teacher_qualifications', 'UPDATE'
  ) then
    raise exception 'TEACHER SECURITE : modification directe des qualifications';
  end if;
end $$;

do $$
begin
  if not has_function_privilege(
    'authenticated', 'public.enseignants_admissibles_groupe(uuid)', 'EXECUTE'
  ) then
    raise exception 'ADMIN : lecture des enseignants admissibles absente';
  end if;
  if not has_function_privilege(
    'authenticated', 'public.publier_offre_horaire_admin(uuid)', 'EXECUTE'
  ) then
    raise exception 'ADMIN : publication des offres absente';
  end if;
end $$;
