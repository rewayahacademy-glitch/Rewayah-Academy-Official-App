-- 0069 — exclure et clôturer les demandes d'élèves déjà en classe.
begin;

do $migration$
declare
  v_oid oid;
  v_definition text;
  v_cleanup text;
  v_filtered text;
begin
  v_oid := 'public.creer_classe_depuis_regroupement(text, uuid, text)'::regprocedure;
  if v_oid is null then
    raise exception 'M2 : fonction canonique creer_classe_depuis_regroupement absente';
  end if;

  v_definition := pg_catalog.pg_get_functiondef(v_oid);
  v_cleanup := pg_catalog.replace(
    v_definition,
    '  FOR v_student IN',
    $replacement$
  -- Un élève déjà membre actif ne peut pas être réinséré. Sa demande orpheline
  -- est close et notifiée avant de sélectionner les membres de cette classe.
  UPDATE public.demandes_horaires_famille d
     SET etat = 'refusee', motif = 'refus_direction', updated_at = pg_catalog.now()
   WHERE d.etat = 'envoyee'
     AND d.type_public = v_type AND d.langue_code = v_langue
     AND d.fuseau_iana = v_fuseau AND d.jours = v_jours
     AND d.heures_locales = v_heures
     AND EXISTS (
       SELECT 1 FROM public.groupe_membres gm
       WHERE gm.student_id = d.eleve_id AND gm.left_at IS NULL
     );

  FOR v_student IN
$replacement$
  );
  if v_cleanup = v_definition then
    raise exception 'M2 : point de remplacement du nettoyage absent';
  end if;

  v_filtered := pg_catalog.replace(
    v_cleanup,
    '      AND c.type_public = d.type_public',
    $replacement$
      AND NOT EXISTS (
        SELECT 1 FROM public.groupe_membres gm
        WHERE gm.student_id = d.eleve_id AND gm.left_at IS NULL
      )
      AND c.type_public = d.type_public
$replacement$
  );
  if v_filtered = v_cleanup then
    raise exception 'M2 : filtre des membres actifs absent';
  end if;

  execute v_filtered;
end
$migration$;

commit;
