CREATE OR REPLACE FUNCTION public.tc_demande_horaire_cloture_retrait_groupe()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
begin
  if old.left_at is null and new.left_at is not null then
    update public.demandes_horaires_famille
       set etat = 'refusee',
           motif = case
             when new.left_reason like 'groupe cloture :%' then 'classe_non_constituee'
             else 'refus_direction'
           end,
           updated_at = pg_catalog.now()
     where groupe_id = new.groupe_id
       and eleve_id = new.student_id
       and etat in ('classe_validee', 'enseignant_affecte');
  end if;
  return new;
end;
$function$

