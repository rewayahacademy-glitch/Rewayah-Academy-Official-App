CREATE OR REPLACE FUNCTION public.brouillon_cahier(p_session_id uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare
  v_seance      public.sessions%rowtype;
  v_participants jsonb;
  v_evenements  jsonb;
begin
  select * into v_seance
    from public.sessions s
   where s.id = p_session_id and s.deleted_at is null;

  if not found then
    return null;
  end if;

  -- La porte : seul l'enseignant de la seance prepare son cahier. L'admin et
  -- le controleur lisent le cahier depose, ils n'en redigent pas.
  --
  -- Exigence POSITIVE enveloppee de coalesce : chacun des quatre termes peut
  -- valoir NULL pour un appelant anonyme ou sans role, et une conjonction
  -- indeterminee doit refuser, jamais laisser passer. Ecrite en refus
  -- (« si l'une est fausse alors refuse »), la porte restait ouverte sur NULL.
  if not coalesce(
       auth.uid() is not null
       and v_seance.teacher_id = auth.uid()
       and public.app_role() = 'teacher'
       and public.app_account_valid(),
       false
     ) then
    raise exception 'cahier refuse' using errcode = '42501';
  end if;

  select coalesce(jsonb_agg(ligne order by ligne ->> 'prenom'), '[]'::jsonb)
    into v_participants
    from (
      select jsonb_build_object(
               'student_id',           p.id,
               'prenom',               p.first_name,
               'identifiant_immuable', p.immutable_id,
               'niveau',               sp.level,
               'riwaya',               sp.riwaya,
               'presence',             public.etat_presence(p_session_id, p.id),
               'entre_le',             (
                 select min(e.server_ts) from public.session_events e
                  where e.session_id = p_session_id
                    and e.profile_id = p.id
                    and e.event_type = 'joined'
               ),
               'derniere_trace_le',    (
                 select max(e.server_ts) from public.session_events e
                  where e.session_id = p_session_id and e.profile_id = p.id
               ),
               -- Memes cles que `student_reading_position`, volontairement :
               -- `PositionLecture.depuisJson` (core/coran/service_coran.dart)
               -- les lit deja, et un second jeu de noms imposerait un second
               -- modele Dart pour le meme fait.
               --
               -- La position d'un eleve LUI APPARTIENT (invariant J2) : aucune
               -- policy ne laisse un enseignant l'ecrire, et ce n'est pas ce
               -- qui se passe ici. Cette fonction la LIT, pour le seul
               -- enseignant de la seance, afin de preremplir « ce qui a ete
               -- travaille » -- ce que le protocole exige de deduire plutot que
               -- de redemander. Une page tournee par l'enseignant n'ecrase
               -- jamais l'endroit ou l'eleve en etait.
               'position',             (
                 select jsonb_build_object(
                          'page_mushaf', r.page_mushaf,
                          'sourate',     r.sourate,
                          'verset',      r.verset,
                          'zoom_level',  r.zoom_level,
                          'updated_at',  r.updated_at
                        )
                   from public.student_reading_position r
                  where r.student_profile_id = p.id
               ),
               'unite_curriculum',     public.unite_curriculum(p.id)
             ) as ligne
        from public.session_participants spart
        join public.profiles p on p.id = spart.profile_id
        left join public.student_profiles sp on sp.profile_id = p.id
       where spart.session_id = p_session_id
         and spart.role = 'student'
         and spart.deleted_at is null
         and p.deleted_at is null
    ) lignes;

  select coalesce(
           jsonb_agg(
             jsonb_build_object(
               'type',       e.event_type,
               'instant',    e.server_ts,
               'profile_id', e.profile_id
             ) order by e.server_ts
           ),
           '[]'::jsonb
         )
    into v_evenements
    from public.session_events e
   where e.session_id = p_session_id;

  return jsonb_build_object(
    'session_id',           v_seance.id,
    'groupe_id',            v_seance.groupe_id,
    'debut',                v_seance.started_at,
    'fin',                  v_seance.ended_at,
    'statut',               v_seance.status,
    'duree_minutes',
      greatest(
        0,
        (extract(epoch from (v_seance.ended_at - v_seance.started_at)) / 60)::int
      ),
    'minutes_interruption', v_seance.prayer_pause_minutes,
    'deja_depose',          exists (
      select 1 from public.lesson_reports lr
       where lr.session_id = p_session_id and lr.deleted_at is null
    ),
    'participants',         v_participants,
    'evenements',           v_evenements
  );
end;
$function$

