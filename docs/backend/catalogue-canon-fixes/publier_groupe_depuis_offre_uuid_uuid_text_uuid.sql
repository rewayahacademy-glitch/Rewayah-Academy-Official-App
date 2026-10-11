CREATE OR REPLACE FUNCTION public.publier_groupe_depuis_offre(p_offre_id uuid, p_teacher_profile_id uuid, p_libelle text, p_eleve_ids uuid[])
 RETURNS uuid
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare
  v_offre public.offres_horaires;
  v_groupe uuid;
  v_capacite smallint;
  v_minimum smallint := public.app_config_int('groupe.minimum_lancement', 3)::smallint;
  v_n int := coalesce(array_length(p_eleve_ids, 1), 0);
  v_eleve uuid;
  v_jour smallint;
begin
  if not coalesce(public.app_role() = 'admin' and public.app_account_valid(), false) then
    raise exception 'publication de groupe reservee a l''administration';
  end if;

  select * into v_offre from public.offres_horaires where id = p_offre_id and etat = 'publiee';
  if not found then
    raise exception 'offre introuvable ou non publiee';
  end if;

  v_capacite := case v_offre.type_public
    when 'adulte' then public.app_config_int('groupe.capacite_adulte', 6)::smallint
    else public.app_config_int('groupe.capacite_enfant', 5)::smallint
  end;

  if v_n < v_minimum then
    raise exception 'un groupe se lance a partir de % eleves, % fournis', v_minimum, v_n;
  end if;
  if v_n > v_capacite then
    raise exception 'la capacite de ce public est de %, % fournis', v_capacite, v_n;
  end if;

  -- `creer_groupe` verifie deja le role et l'etat du compte de l'enseignant :
  -- la reappeler evite de recopier ces controles, et donc de les laisser
  -- diverger.
  --
  -- **Arguments NOMMES, et ce n'est pas un ornement.** `creer_groupe` est
  -- surchargee : une version a 6 parametres dont 1 par defaut, une autre a 8
  -- dont 3 par defaut. Les six premiers portent les memes types dans les deux.
  -- Un appel positionnel a six arguments est donc AMBIGU, et PostgreSQL le
  -- refuse a l'execution -- c'est-a-dire au moment precis ou l'academie
  -- publierait son premier groupe. Nommer `p_timezone_iana`, qui n'existe que
  -- dans la version a huit, designe une seule candidate.
  v_groupe := public.creer_groupe(
    p_teacher_profile_id => p_teacher_profile_id,
    p_type_public        => v_offre.type_public,
    p_libelle            => p_libelle,
    p_weekday            => v_offre.jours[1]::smallint,
    p_hour_local         => v_offre.heure_locale,
    p_seuil_max          => v_capacite,
    p_timezone_iana      => v_offre.fuseau_iana
  );

  update public.groupes
  set offre_id = p_offre_id,
      langue_code = v_offre.langue_code
  where id = v_groupe;

  -- Le declencheur a deja pose l'ancre ; les autres jours s'ajoutent ici.
  foreach v_jour in array v_offre.jours loop
    insert into public.groupe_creneaux (groupe_id, weekday, hour_local)
    values (v_groupe, v_jour, v_offre.heure_locale)
    on conflict (groupe_id, weekday, hour_local) do nothing;
  end loop;

  foreach v_eleve in array p_eleve_ids loop
    if not exists (
      select 1 from public.intentions_horaire i
      where i.eleve_id = v_eleve and i.offre_id = p_offre_id
        and i.etat in ('enregistree', 'diagnostic_planifie', 'en_formation')
    ) then
      raise exception 'cet eleve n''a pas de preference vivante sur cette offre : %', v_eleve;
    end if;

    perform public.ajouter_eleve_groupe(
      v_groupe, v_eleve, 'groupe publie depuis l''offre ' || p_offre_id::text);

    update public.intentions_horaire
    set etat = 'affectee', groupe_id = v_groupe
    where eleve_id = v_eleve and offre_id = p_offre_id and etat <> 'retiree';
  end loop;

  -- Ce qui reste sous le minimum reste « en formation », et le dit.
  update public.intentions_horaire
  set etat = 'en_formation'
  where offre_id = p_offre_id and etat = 'enregistree';

  perform public.log_sensitive_access(
    'groupe_publie_depuis_offre', 'groupes', v_groupe::text,
    jsonb_build_object('offre_id', p_offre_id, 'teacher_id', p_teacher_profile_id,
                       'eleves', v_n, 'jours', v_offre.jours)
  );

  return v_groupe;
end;
$function$

