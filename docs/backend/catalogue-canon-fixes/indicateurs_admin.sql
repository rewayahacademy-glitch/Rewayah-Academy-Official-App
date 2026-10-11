CREATE OR REPLACE FUNCTION public.indicateurs_admin()
 RETURNS TABLE(dossiers_en_attente integer, foyers_sans_enseignant integer, rapports_manquants integer, incidents_24h integer, comptes_echus integer, demandes_en_attente integer)
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
begin
  if NOT coalesce(public.app_role() = 'admin' AND public.app_account_valid(), false) then
    raise exception 'centre de commande reserve a l''administration';
  end if;

  return query
  select
    -- Des **personnes** en attente de validation, plus des documents deposes.
    -- L'ancien compte lisait `kyc_documents where status='pending'` et
    -- affichait donc zero pendant que trois enseignants attendaient.
    (select count(*)::int from public.profiles p
      where p.deleted_at is null
        and p.account_status = 'pending_kyc'),
    (select count(distinct p.household_id)::int
       from public.profiles p
      where p.role = 'student' and p.deleted_at is null
        and p.account_status in ('active', 'provisional_active')
        and not exists (
          select 1 from public.teacher_student_assignments a
          where a.student_id = p.id and a.ended_at is null)),
    (select count(*)::int from public.sessions s
      where s.status = 'ended' and s.deleted_at is null
        and not exists (
          select 1 from public.lesson_reports r
          where r.session_id = s.id and r.deleted_at is null)),
    (select count(*)::int from public.sessions s
      where s.deleted_at is null
        and s.status in ('tech_failure', 'teacher_absent', 'student_absent')
        and s.updated_at > now() - interval '24 hours'),
    (select count(*)::int from public.profiles p
      where p.deleted_at is null
        and p.account_status = 'provisional_active'
        and p.access_until is not null and p.access_until < now()),
    (select count(*)::int from public.matching_requests m
      where m.status = 'pending');
end;
$function$

