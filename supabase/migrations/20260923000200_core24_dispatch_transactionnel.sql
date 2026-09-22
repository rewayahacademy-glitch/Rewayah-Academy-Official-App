-- Core24 Classes — dispatch transactionnel et idempotent.
--
-- Ce lot ne fabrique aucune equivalence academique : un niveau officiel exact
-- est requis apres diagnostic, et « Je debute » reste groupable uniquement sur
-- une offre generique. Les controles d'eligibilite titulaire appartiennent au
-- lot suivant, car ce checkout ne porte pas encore leur contrat de qualification.
begin;

-- Un groupe conserve la cle academique qui a permis son dispatch. Cela evite
-- qu'un groupe generique melange silencieusement deux niveaux valides.
alter table public.groupes
  add column if not exists niveau_id uuid references public.programme_niveaux(id);

create index if not exists groupes_dispatch_niveau_idx
  on public.groupes (offre_id, langue_code, cohorte, niveau_id, etat)
  where ended_at is null;

-- La compatibilite d'une offre specifique ne peut pas s'appuyer sur le champ
-- client `student_profiles.level` : seul le dernier placement academique est
-- une preuve suffisante pour un dispatch automatique.
create or replace function public.offres_compatibles(
  p_membre_id uuid,
  p_fuseau_vue text
)
returns table (
  offre_id uuid,
  type_public text,
  langue_code text,
  langue_nom text,
  jours_locaux smallint[],
  heures_locales smallint[],
  heure_source smallint,
  fuseau_source text,
  duree_minutes smallint,
  rythme text,
  pause_minutes smallint,
  capacite smallint,
  deja_choisie boolean
)
language sql stable security definer set search_path = ''
as $function$
  with fiche as (
    select
      sp.langue_cours,
      sp.cohorte,
      sp.diagnostic_statut,
      c.type_public,
      courant.niveau_id
    from public.student_profiles sp
    join public.cohortes_age c on c.code = sp.cohorte and c.actif
    left join lateral (
      select h.niveau_id
      from public.progression_historique h
      where h.student_id = p_membre_id
      order by h.created_at desc, h.id desc
      limit 1
    ) courant on true
    where sp.profile_id = p_membre_id
      and sp.deleted_at is null
      and public.peut_decrire_apprenant(p_membre_id)
      and exists (
        select 1 from pg_catalog.pg_timezone_names
        where name = p_fuseau_vue
      )
  )
  select
    o.id,
    o.type_public,
    o.langue_code,
    l.nom_humain,
    v.jours_locaux,
    v.heures_locales,
    o.heure_locale,
    o.fuseau_iana,
    o.duree_minutes,
    o.rythme::text,
    case o.type_public
      when 'adulte' then public.app_config_int('seance.pause_minutes_adulte', 0)::smallint
      else public.app_config_int('seance.pause_minutes_enfant', 6)::smallint
    end,
    case o.type_public
      when 'adulte' then public.app_config_int('groupe.capacite_adulte', 6)::smallint
      else public.app_config_int('groupe.capacite_enfant', 5)::smallint
    end,
    exists (
      select 1 from public.intentions_horaire i
      where i.eleve_id = p_membre_id and i.offre_id = o.id and i.etat <> 'retiree'
    )
  from public.offres_horaires o
  join public.langues_cours l on l.code = o.langue_code
  cross join fiche f
  cross join lateral (
    select
      array_agg(x.jour order by x.rang)::smallint[] as jours_locaux,
      array_agg(x.heure order by x.rang)::smallint[] as heures_locales
    from (
      select
        j.rang,
        extract(isodow from j.local)::smallint as jour,
        extract(hour from j.local)::smallint as heure
      from (
        select
          u.rang,
          public.instant_creneau(u.j::int, o.heure_locale::int, o.fuseau_iana)
            at time zone p_fuseau_vue as local
        from unnest(o.jours) with ordinality as u(j, rang)
      ) j
    ) x
  ) v
  where o.etat = 'publiee'
    and o.type_public = f.type_public
    and o.langue_code = f.langue_cours
    and (o.cohorte_code is null or o.cohorte_code = f.cohorte)
    and (
      o.programme_niveau_id is null
      or (
        f.diagnostic_statut = 'fait'
        and f.niveau_id = o.programme_niveau_id
      )
    )
  order by 2, 7, 4;
$function$;

-- Le choix d'offre est rejouable apres un timeout reseau. Il ne transforme
-- jamais « Je debute » en faux diagnostic : le statut non_requis reste intact.
create or replace function public.choisir_offre_horaire(
  p_membre_id uuid,
  p_offre_id uuid,
  p_fuseau_vue text
)
returns uuid
language plpgsql security definer set search_path = ''
as $function$
declare
  v_id uuid;
  v_compatible record;
  v_existante public.intentions_horaire;
begin
  if not public.peut_decrire_apprenant(p_membre_id) then
    raise exception 'ce profil n''est pas le votre ni celui de votre foyer';
  end if;

  select * into v_existante
  from public.intentions_horaire i
  where i.eleve_id = p_membre_id and i.etat <> 'retiree'
  for update;

  if found then
    if v_existante.offre_id = p_offre_id then
      return v_existante.id;
    end if;
    raise exception 'cet apprenant a deja une preference horaire enregistree';
  end if;

  select * into v_compatible
  from public.offres_compatibles(p_membre_id, p_fuseau_vue) o
  where o.offre_id = p_offre_id;

  if not found then
    raise exception 'cette offre n''est pas compatible avec ce profil, ou n''est plus publiee';
  end if;

  insert into public.intentions_horaire
    (eleve_id, offre_id, fuseau_affiche, heure_affichee, jours_affiches, created_by)
  values
    (p_membre_id, p_offre_id, p_fuseau_vue,
     v_compatible.heures_locales[1], v_compatible.jours_locaux, auth.uid())
  returning id into v_id;

  perform public.log_sensitive_access(
    'intention_horaire_enregistree', 'intentions_horaire', v_id::text,
    jsonb_build_object('eleve_id', p_membre_id, 'offre_id', p_offre_id,
                       'fuseau_affiche', p_fuseau_vue)
  );

  return v_id;
end;
$function$;

revoke execute on function public.choisir_offre_horaire(uuid, uuid, text)
  from public, anon, agent_ro;
grant execute on function public.choisir_offre_horaire(uuid, uuid, text)
  to authenticated;

-- Fabrique les Groupes DRAFT complets seulement quand le minimum est atteint.
-- Le verrou de l'offre sequentielise les workers pour une meme cle ; les
-- contraintes uniques existantes restent la derniere barriere anti-double
-- affectation.
create or replace function public.dispatcher_offre_horaire(p_offre_id uuid)
returns jsonb
language plpgsql security definer set search_path = ''
as $function$
declare
  v_offre public.offres_horaires;
  v_candidat record;
  v_groupe_id uuid;
  v_membres int;
  v_restants int;
  v_capacite smallint;
  v_groupe_nouveau boolean;
  v_eleves uuid[];
  v_intentions uuid[];
  v_minimum smallint := public.app_config_int('groupe.minimum_lancement', 3)::smallint;
  v_affectes int := 0;
  v_en_formation int := 0;
  v_nouveaux_groupes int := 0;
  v_jour smallint;
begin
  if not coalesce(public.app_role() = 'admin' and public.app_account_valid(), false) then
    raise exception 'dispatch reserve a l''administration';
  end if;

  select * into v_offre
  from public.offres_horaires
  where id = p_offre_id
  for update;

  if not found or v_offre.etat <> 'publiee' then
    raise exception 'offre introuvable ou non publiee';
  end if;

  v_capacite := case v_offre.type_public
    when 'adulte' then public.app_config_int('groupe.capacite_adulte', 6)::smallint
    else public.app_config_int('groupe.capacite_enfant', 5)::smallint
  end;

  if v_minimum < 1 or v_minimum > v_capacite then
    raise exception 'configuration de groupe incoherente';
  end if;

  for v_candidat in
    select
      i.id as intention_id,
      i.eleve_id,
      sp.cohorte,
      c.type_public,
      courant.niveau_id
    from public.intentions_horaire i
    join public.student_profiles sp on sp.profile_id = i.eleve_id
      and sp.deleted_at is null
    join public.cohortes_age c on c.code = sp.cohorte and c.actif
    left join lateral (
      select h.niveau_id
      from public.progression_historique h
      where h.student_id = i.eleve_id
      order by h.created_at desc, h.id desc
      limit 1
    ) courant on true
    where i.offre_id = p_offre_id
      and i.etat in ('enregistree', 'en_formation')
      and sp.langue_cours = v_offre.langue_code
      and (v_offre.cohorte_code is null or sp.cohorte = v_offre.cohorte_code)
      and (
        (
          sp.diagnostic_statut = 'non_requis'
          and sp.niveau_declare = 'debut_lettres'
          and courant.niveau_id is null
        )
        or (
          sp.diagnostic_statut = 'fait'
          and courant.niveau_id is not null
        )
      )
      and (
        v_offre.programme_niveau_id is null
        or courant.niveau_id = v_offre.programme_niveau_id
      )
    order by i.created_at asc, i.id asc
    for update of i
  loop
    -- Une creation de groupe peut avoir affecte en bloc des candidats deja
    -- presents dans le curseur. Le test rend le rejeu idempotent dans la meme
    -- transaction au lieu de tenter une seconde insertion.
    if not exists (
      select 1 from public.intentions_horaire i0
      where i0.id = v_candidat.intention_id
        and i0.etat in ('enregistree', 'en_formation')
    ) then
      continue;
    end if;

    v_groupe_nouveau := false;

    -- Un groupe DRAFT compatible est toujours rempli avant d'en creer un
    -- nouveau. `is not distinct from` separe explicitement debutants sans
    -- niveau officiel des eleves places sur un niveau reel.
    select g.id into v_groupe_id
    from public.groupes g
    where g.offre_id = p_offre_id
      and g.langue_code = v_offre.langue_code
      and g.cohorte = v_candidat.cohorte
      and g.type_public = v_candidat.type_public
      and g.niveau_id is not distinct from v_candidat.niveau_id
      and g.etat = 'brouillon'
      and g.ended_at is null
      and (
        select count(*) from public.groupe_membres m
        where m.groupe_id = g.id and m.left_at is null
      ) < g.seuil_max
    order by g.created_at asc, g.id asc
    limit 1
    for update;

    if v_groupe_id is null then
      -- Pas de nouveau groupe pour un reliquat sous le minimum.
      select count(*) into v_restants
      from public.intentions_horaire i2
      join public.student_profiles sp2 on sp2.profile_id = i2.eleve_id
        and sp2.deleted_at is null
      join public.cohortes_age c2 on c2.code = sp2.cohorte and c2.actif
      left join lateral (
        select h2.niveau_id
        from public.progression_historique h2
        where h2.student_id = i2.eleve_id
        order by h2.created_at desc, h2.id desc
        limit 1
      ) courant2 on true
      where i2.offre_id = p_offre_id
        and i2.etat in ('enregistree', 'en_formation')
        and sp2.langue_cours = v_offre.langue_code
        and sp2.cohorte = v_candidat.cohorte
        and c2.type_public = v_candidat.type_public
        and courant2.niveau_id is not distinct from v_candidat.niveau_id
        and (
          (
            sp2.diagnostic_statut = 'non_requis'
            and sp2.niveau_declare = 'debut_lettres'
            and courant2.niveau_id is null
          )
          or sp2.diagnostic_statut = 'fait'
        )
        and (
          v_offre.programme_niveau_id is null
          or courant2.niveau_id = v_offre.programme_niveau_id
        );

      if v_restants < v_minimum then
        update public.intentions_horaire
        set etat = 'en_formation'
        where id = v_candidat.intention_id
          and etat in ('enregistree', 'en_formation');
        v_en_formation := v_en_formation + 1;
        continue;
      end if;

      insert into public.groupes
        (teacher_id, type_public, seuil_max, libelle, weekday, hour_local,
         timezone_iana, offre_id, langue_code, cohorte, niveau_id, etat)
      values
        (null, v_candidat.type_public, v_capacite,
         'Brouillon ' || v_candidat.cohorte,
         v_offre.jours[1], v_offre.heure_locale, v_offre.fuseau_iana,
         p_offre_id, v_offre.langue_code, v_candidat.cohorte,
         v_candidat.niveau_id, 'brouillon')
      returning id into v_groupe_id;
      v_nouveaux_groupes := v_nouveaux_groupes + 1;
      v_groupe_nouveau := true;

      foreach v_jour in array v_offre.jours loop
        insert into public.groupe_creneaux (groupe_id, weekday, hour_local)
        values (v_groupe_id, v_jour, v_offre.heure_locale)
        on conflict (groupe_id, weekday, hour_local) do nothing;
      end loop;
    end if;

    if v_groupe_nouveau then
      -- Les candidats precedemment observes alors que le pool etait sous le
      -- minimum doivent rejoindre ce premier groupe eux aussi (cas 8 = 5+3,
      -- et non 1+1+1). Le verrou de l'offre rend cette selection atomique
      -- vis-a-vis d'un second worker du meme dispatch.
      select
        coalesce(array_agg(x.eleve_id order by x.created_at, x.intention_id), '{}'),
        coalesce(array_agg(x.intention_id order by x.created_at, x.intention_id), '{}')
      into v_eleves, v_intentions
      from (
        select
          i3.eleve_id,
          i3.id as intention_id,
          i3.created_at
        from public.intentions_horaire i3
        join public.student_profiles sp3 on sp3.profile_id = i3.eleve_id
          and sp3.deleted_at is null
        join public.cohortes_age c3 on c3.code = sp3.cohorte and c3.actif
        left join lateral (
          select h3.niveau_id
          from public.progression_historique h3
          where h3.student_id = i3.eleve_id
          order by h3.created_at desc, h3.id desc
          limit 1
        ) courant3 on true
        where i3.offre_id = p_offre_id
          and i3.etat in ('enregistree', 'en_formation')
          and sp3.langue_cours = v_offre.langue_code
          and sp3.cohorte = v_candidat.cohorte
          and c3.type_public = v_candidat.type_public
          and courant3.niveau_id is not distinct from v_candidat.niveau_id
          and (
            (
              sp3.diagnostic_statut = 'non_requis'
              and sp3.niveau_declare = 'debut_lettres'
              and courant3.niveau_id is null
            )
            or sp3.diagnostic_statut = 'fait'
          )
          and (
            v_offre.programme_niveau_id is null
            or courant3.niveau_id = v_offre.programme_niveau_id
          )
        order by i3.created_at, i3.id
        limit v_capacite
      ) x;

      insert into public.groupe_membres (groupe_id, student_id)
      select v_groupe_id, unnest(v_eleves);

      update public.intentions_horaire
      set etat = 'affectee', groupe_id = v_groupe_id
      where id = any(v_intentions)
        and etat in ('enregistree', 'en_formation');

      v_affectes := v_affectes + coalesce(array_length(v_eleves, 1), 0);
      continue;
    end if;

    select count(*) into v_membres
    from public.groupe_membres m
    where m.groupe_id = v_groupe_id and m.left_at is null;

    if v_membres >= v_capacite then
      raise exception 'capacite de groupe depassee pendant le dispatch';
    end if;

    insert into public.groupe_membres (groupe_id, student_id)
    values (v_groupe_id, v_candidat.eleve_id);

    update public.intentions_horaire
    set etat = 'affectee', groupe_id = v_groupe_id
    where id = v_candidat.intention_id and etat <> 'retiree';
    v_affectes := v_affectes + 1;
  end loop;

  perform public.log_sensitive_access(
    'dispatch_offre_horaire', 'offres_horaires', p_offre_id::text,
    jsonb_build_object('affectes', v_affectes,
                       'en_formation', v_en_formation,
                       'groupes_crees', v_nouveaux_groupes)
  );

  return jsonb_build_object(
    'offre_id', p_offre_id,
    'affectes', v_affectes,
    'en_formation', v_en_formation,
    'groupes_crees', v_nouveaux_groupes
  );
end;
$function$;

revoke execute on function public.dispatcher_offre_horaire(uuid)
  from public, anon, agent_ro;
grant execute on function public.dispatcher_offre_horaire(uuid) to authenticated;

notify pgrst, 'reload schema';
commit;
