-- 0026 — Durcissement des droits d'execution du lot Enseignant
--
-- Correction de `0025_role_enseignant.sql`. Cette migration-la est deja
-- appliquee : elle n'est pas modifiee, le correctif passe par ce fichier, car
-- la CI rejoue les migrations dans l'ordre sur une base neuve et un fichier
-- retouche apres coup donnerait deux histoires differentes de la meme base.
--
-- DEUX DEFAUTS MESURES SUR LA BASE APRES APPLICATION DE 0025.
--
-- 1. `revoke all on function ... from anon` ne retire RIEN. PostgreSQL accorde
--    EXECUTE a `PUBLIC` par defaut sur toute fonction creee ; `anon` en herite
--    en tant que membre de PUBLIC, et revoquer nominativement un droit qu'il ne
--    detient pas nominativement le laisse intact. Mesure : les quatre
--    fonctions de 0025 portaient un `grantee = 0` (PUBLIC) dans leur ACL, et
--    `has_function_privilege('anon', ..., 'execute')` rendait `true`. Les
--    fonctions maison comparables (`groupe_detail`, `personnes_observables`,
--    `dossiers_en_attente`) revoquent `from public` depuis `0016` : c'est la
--    seule formule qui ferme la porte. Les vues ne sont pas concernees : une
--    vue ne recoit aucun droit PUBLIC par defaut, et la mesure l'a confirme.
--
-- 2. La porte de `brouillon_cahier` se fermait par accident. Elle s'ecrivait
--    « si l'une de ces trois conditions est fausse, refuse ». Pour un appelant
--    anonyme, `teacher_id <> auth.uid()` et `app_role() <> 'teacher'` valent
--    tous deux NULL, et `NULL or NULL or X` ne vaut `true` que si X le vaut :
--    tout reposait donc sur `app_account_valid()` rendant un `false` franc.
--    C'est le cas aujourd'hui (mesure faite en role `anon`), mais un garde-fou
--    qui depend du fait qu'une AUTRE fonction ne rende jamais NULL n'est pas un
--    garde-fou. La condition est reecrite en exigence positive enveloppee de
--    `coalesce(..., false)` : toute inconnue ferme la porte au lieu de
--    l'ouvrir.
--
-- Rien d'autre de 0025 n'est touche : les deux vues, la colonne
-- `sessions.groupe_id`, son index et la policy d'ecriture durcie de
-- `lesson_reports` ont ete verifies conformes sur la base.

-- ============================================================
-- 1. Retirer le droit herite de PUBLIC
-- ============================================================
--
-- Cible visee, identique a `groupe_detail(uuid)` : postgres (proprietaire),
-- service_role, authenticated, agent_ro. Le `grant to service_role` est
-- necessaire APRES le revoke : sur les fonctions de 0025, service_role ne
-- tenait son EXECUTE que de PUBLIC.

revoke all on function public.mon_groupe_detail(uuid) from public;
grant execute on function public.mon_groupe_detail(uuid) to service_role;

revoke all on function public.brouillon_cahier(uuid) from public;
grant execute on function public.brouillon_cahier(uuid) to service_role;

revoke all on function public.mes_rapports_en_attente() from public;
grant execute on function public.mes_rapports_en_attente() to service_role;

-- `unite_curriculum(uuid)` redevient un auxiliaire PRIVE. Elle n'a aucune
-- porte a elle : elle rend l'unite de curriculum de n'importe quel eleve a
-- quiconque connait son identifiant. C'etait sans consequence tant qu'elle
-- n'etait appelee que depuis `brouillon_cahier`, qui verifie l'enseignant --
-- et c'est son seul appelant, verifie : aucun code Dart ne la nomme, le client
-- lit l'unite dans la cle `unite_curriculum` du brouillon. Elle n'est donc pas
-- corrigee mais fermee : `brouillon_cahier` etant `security definer`, l'appel
-- interne est autorise au titre du proprietaire, pas de l'appelant.
revoke all on function public.unite_curriculum(uuid) from public;
revoke all on function public.unite_curriculum(uuid) from authenticated;
revoke all on function public.unite_curriculum(uuid) from agent_ro;
grant execute on function public.unite_curriculum(uuid) to service_role;

comment on function public.unite_curriculum(uuid) is
  'L''unite de curriculum courante d''un eleve, ou null quand le programme '
  'pedagogique (migrations 0020-0024) n''est pas applique sur cette base. '
  'Lecture dynamique gardee par to_regclass, volontairement : l''ecran doit '
  'taire ce qu''il ne sait pas, jamais afficher un tiret a la place. '
  'AUXILIAIRE PRIVE depuis 0026 : elle ne porte aucune verification '
  'd''appelant, son unique appelant legitime est brouillon_cahier(uuid) qui '
  'porte la sienne. Ne jamais lui rendre execute a authenticated sans lui '
  'donner d''abord sa propre porte.';

-- ============================================================
-- 2. La porte de brouillon_cahier ferme sur l'inconnu
-- ============================================================
--
-- Corps identique a 0025 hormis la condition de refus.

create or replace function public.brouillon_cahier(p_session_id uuid)
returns jsonb
language plpgsql
stable
security definer
set search_path to ''
as $function$
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
$function$;

-- `create or replace` conserve l'ACL et l'oid, donc le commentaire de 0025 et
-- les droits corriges ci-dessus survivent. Le revoke est malgre tout rejoue
-- apres le remplacement : si un jour ce fichier est rejoue seul sur une base
-- ou la fonction vient d'etre recreee, l'ordre ne doit pas dependre du hasard.
revoke all on function public.brouillon_cahier(uuid) from public;
grant execute on function public.brouillon_cahier(uuid) to authenticated, agent_ro, service_role;
